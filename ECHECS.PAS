{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: ECHECS - jeu d'echecs contre l'ordinateur pour le
                Presentation Manager d'OS/2-0.
}

Program ECHECS;

{$R-,S-,I-}

{ Compilation : OS2PC ECHECS.PAS   (produit ECHECS.EXE)

  Jeu d'echecs du dossier Jeux du bureau (Systeme OS/2, Jeux). Toutes les
  regles : deplacements, prises, roque (petit et grand), prise en
  passant, promotion (en dame), echec, echec et mat, pat, regle des
  50 coups et materiel insuffisant.

  L'ordinateur joue les noirs (ou les blancs : Options, Jouer avec les
  noirs ; ou personne : Deux joueurs). Recherche alpha-beta (negamax) a
  profondeur 1, 2 ou 3 selon le niveau, suivie d'une recherche des prises
  (quiescence) ; evaluation : materiel et position des pieces.

  Souris : cliquer une piece (ses cases d'arrivee sont marquees), puis la
  case d'arrivee. Clavier : F2 nouvelle partie, Ctrl+Z annuler le dernier
  coup (et la reponse de l'ordinateur).
  Notation des coups (francaise) : R roi, D dame, T tour, F fou,
  C cavalier ; "Cg1-f3", "e5xd6", "O-O", "+" echec, "#" mat. }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A; WM_THINK = $1001;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_KEYUP = $40; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4; CLR_YELLOW = 6; CLR_DARKGRAY = 8;
  CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12; CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  CM_NEW = 101; CM_UNDO = 102; CM_QUIT = 103; CM_LEVEL1 = 201; CM_LEVEL2 = 202; CM_LEVEL3 = 203;
  CM_BLACK = 210; CM_TWO = 211; CM_RULES = 301; CM_ABOUT = 302;
  { pieces : 1 pion, 2 cavalier, 3 fou, 4 tour, 5 dame, 6 roi (noir < 0) }
  PAWN = 1; KNIGHT = 2; BISHOP = 3; ROOK = 4; QUEEN = 5; KING = 6;
  Sq = 46;                       { taille d'une case (pels) }
  MaxPly = 32;                   { profondeur de la recherche (avec les prises) }
  MaxHist = 600;                 { demi-coups de la partie }
  MaxMoves = 256;
  Inf = 1000000; MateVal = 100000;
  PieceVal : Array[0..6] Of LongInt = (0, 100, 320, 330, 500, 900, 0);
  { tables de position (pour les blancs, case a1 = 0) }
  PstPawn : Array[0..63] Of LongInt = (
     0,  0,  0,  0,  0,  0,  0,  0,
     5, 10, 10,-20,-20, 10, 10,  5,
     5, -5,-10,  0,  0,-10, -5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5,  5, 10, 25, 25, 10,  5,  5,
    10, 10, 20, 30, 30, 20, 10, 10,
    50, 50, 50, 50, 50, 50, 50, 50,
     0,  0,  0,  0,  0,  0,  0,  0);
  PstKnight : Array[0..63] Of LongInt = (
   -50,-40,-30,-30,-30,-30,-40,-50,
   -40,-20,  0,  5,  5,  0,-20,-40,
   -30,  5, 10, 15, 15, 10,  5,-30,
   -30,  0, 15, 20, 20, 15,  0,-30,
   -30,  5, 15, 20, 20, 15,  5,-30,
   -30,  0, 10, 15, 15, 10,  0,-30,
   -40,-20,  0,  0,  0,  0,-20,-40,
   -50,-40,-30,-30,-30,-30,-40,-50);
  PstBishop : Array[0..63] Of LongInt = (
   -20,-10,-10,-10,-10,-10,-10,-20,
   -10,  5,  0,  0,  0,  0,  5,-10,
   -10, 10, 10, 10, 10, 10, 10,-10,
   -10,  0, 10, 10, 10, 10,  0,-10,
   -10,  5,  5, 10, 10,  5,  5,-10,
   -10,  0,  5, 10, 10,  5,  0,-10,
   -10,  0,  0,  0,  0,  0,  0,-10,
   -20,-10,-10,-10,-10,-10,-10,-20);
  PstKing : Array[0..63] Of LongInt = (
    20, 30, 10,  0,  0, 10, 30, 20,
    20, 20,  0,  0,  0,  0, 20, 20,
   -10,-20,-20,-20,-20,-20,-20,-10,
   -20,-30,-30,-40,-40,-30,-30,-20,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30,
   -30,-40,-40,-50,-50,-40,-40,-30);
  KnightD : Array[0..7] Of LongInt = (-17, -15, -10, -6, 6, 10, 15, 17);
  KnightF : Array[0..7] Of LongInt = (-1, 1, -2, 2, -2, 2, -1, 1);
  KingD : Array[0..7] Of LongInt = (-9, -8, -7, -1, 1, 7, 8, 9);
  KingF : Array[0..7] Of LongInt = (-1, 0, 1, -1, 1, -1, 0, 1);

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH : LongInt;
  { position : Bd (a1 = 0, h8 = 63), trait (1 blancs, -1 noirs), roques
    (1 petit blanc, 2 grand blanc, 4 petit noir, 8 grand noir), case de
    prise en passant (-1), demi-coups sans prise ni pion }
  Bd : Array[0..63] Of LongInt;
  Side, Castle, EpSq, Fifty : LongInt;
  { pile de la recherche (copie de la position a chaque demi-coup) }
  SBd : Array[0..MaxPly * 64 - 1] Of LongInt;
  SSide, SCastle, SEp, SFifty : Array[0..MaxPly - 1] Of LongInt;
  Ply : LongInt;
  { coups generes : par niveau de la recherche }
  MvList : Array[0..MaxPly * MaxMoves - 1] Of LongInt;
  MvScore : Array[0..MaxPly * MaxMoves - 1] Of LongInt;
  LegL : Array[0..MaxMoves - 1] Of LongInt;      { coups legaux (LegalMoves) }
  { partie : positions et coups joues }
  HBd : Array[0..MaxHist * 64 - 1] Of Byte;          { piece + 8 }
  HSide, HCastle, HEp, HFifty, HMove : Array[0..MaxHist - 1] Of LongInt;
  HText : Array[0..MaxHist - 1] Of String[12];
  NHist : LongInt;
  Level, CompSide, TwoPlayers : LongInt;
  Sel : LongInt;                      { case choisie (-1) }
  LastFrom, LastTo : LongInt;
  Over : LongInt;                     { 0 en cours, 1 mat, 2 pat, 3 nulle }
  Thinking : LongInt;
  Nodes : LongInt;
  Status : String;
  NameZ, NameZ2, TxtBuf : Array[0..511] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Qmsg : Array[0..7] Of LongInt;

{ --- PMWIN.DLL, PMGPI.DLL --- }
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
Function WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';

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

Function AbsI(A : LongInt) : LongInt;
Begin
  If A < 0 Then AbsI := -A Else AbsI := A;
End;

Procedure ShowMsg(Text, Cap : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure GBox(Hps, X1, Y1, X2, Y2, C, Fl, R : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiBox(Hps, Fl, LongInt(@P), R, R);
End;

{ rectangle plein (Fill) borde (Edge), coins arrondis R }
Procedure Shape(Hps, X1, Y1, X2, Y2, Fill, Edge, R : LongInt);
Begin
  GBox(Hps, X1, Y1, X2, Y2, Fill, DRO_FILL, R);
  GBox(Hps, X1, Y1, X2, Y2, Edge, DRO_OUTLINE, R);
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

Procedure TextXY(Hps, X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := Y; Rc[2] := X + Length(S) * 8; Rc[3] := Y + 16;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

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

Procedure CheckItem(Id : LongInt; On : Boolean);
Var M : LongInt;
Begin
  M := WinWindowFromID(Frame, $8005);
  If On Then Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED);
End;

{ ==================================================================== }
{ Regles : coups, echecs                                                }
{ ==================================================================== }
{ coup : depart + arrivee * 64 + promotion * 4096 + drapeaux * 32768
  (1 prise en passant, 2 roque, 4 avance de deux cases) }

Function MvFrom(M : LongInt) : LongInt;
Begin
  MvFrom := M And 63;
End;

Function MvTo(M : LongInt) : LongInt;
Begin
  MvTo := (M Shr 6) And 63;
End;

Function MvPromo(M : LongInt) : LongInt;
Begin
  MvPromo := (M Shr 12) And 7;
End;

Function MvFlags(M : LongInt) : LongInt;
Begin
  MvFlags := (M Shr 15) And 7;
End;

Function Mk(F, T, P, Fl : LongInt) : LongInt;
Begin
  Mk := F + T * 64 + P * 4096 + Fl * 32768;
End;

{ la case Sq est-elle attaquee par le camp By (1 ou -1) ? }
Function Attacked(Sq, By : LongInt) : Boolean;
Var K, T, F, R, Df, Dr, P, Dir : LongInt;
Begin
  Attacked := True;
  F := Sq And 7; R := Sq Shr 3;
  { pions }
  If By = 1 Then
  Begin
    If (R > 0) And (F > 0) And (Bd[Sq - 9] = PAWN) Then Exit;
    If (R > 0) And (F < 7) And (Bd[Sq - 7] = PAWN) Then Exit;
  End
  Else
  Begin
    If (R < 7) And (F > 0) And (Bd[Sq + 7] = -PAWN) Then Exit;
    If (R < 7) And (F < 7) And (Bd[Sq + 9] = -PAWN) Then Exit;
  End;
  { cavaliers et roi }
  For K := 0 To 7 Do
  Begin
    T := Sq + KnightD[K];
    If (T >= 0) And (T < 64) And (AbsI((T And 7) - F) <= 2) And (Bd[T] = By * KNIGHT) Then Exit;
    T := Sq + KingD[K];
    If (T >= 0) And (T < 64) And (AbsI((T And 7) - F) <= 1) And (Bd[T] = By * KING) Then Exit;
  End;
  { lignes et diagonales }
  For Dir := 0 To 7 Do
  Begin
    Case Dir Of
      0 : Begin Df := 1; Dr := 0; End;
      1 : Begin Df := -1; Dr := 0; End;
      2 : Begin Df := 0; Dr := 1; End;
      3 : Begin Df := 0; Dr := -1; End;
      4 : Begin Df := 1; Dr := 1; End;
      5 : Begin Df := -1; Dr := 1; End;
      6 : Begin Df := 1; Dr := -1; End;
    Else
      Begin Df := -1; Dr := -1; End;
    End;
    T := F + Df; P := R + Dr;
    While (T >= 0) And (T < 8) And (P >= 0) And (P < 8) Do
    Begin
      K := Bd[P * 8 + T];
      If K <> 0 Then
      Begin
        If K = By * QUEEN Then Exit;
        If (Dir < 4) And (K = By * ROOK) Then Exit;
        If (Dir >= 4) And (K = By * BISHOP) Then Exit;
        T := 99;
      End
      Else
      Begin
        T := T + Df; P := P + Dr;
      End;
    End;
  End;
  Attacked := False;
End;

Function KingSq(S : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To 63 Do
    If Bd[K] = S * KING Then R := K;
  KingSq := R;
End;

Function InCheck(S : LongInt) : Boolean;
Var K : LongInt;
Begin
  K := KingSq(S);
  InCheck := (K >= 0) And Attacked(K, -S);
End;

{ coups pseudo-legaux du camp au trait, a partir de Base dans MvList ;
  Caps : prises (et promotions) seulement ; rend le nombre }
Var GN, GBase : LongInt; GCaps : Boolean;

Procedure Add(Fr, To_, Pr, Fl : LongInt);
Begin
  If GN < MaxMoves Then
  Begin
    MvList[GBase + GN] := Mk(Fr, To_, Pr, Fl);
    Inc(GN);
  End;
End;

Procedure AddPawn(Fr, To_, Fl : LongInt);
Begin
  If ((To_ Shr 3) = 7) Or ((To_ Shr 3) = 0) Then
  Begin
    Add(Fr, To_, QUEEN, Fl);
    If Not GCaps Then
    Begin
      Add(Fr, To_, KNIGHT, Fl); Add(Fr, To_, ROOK, Fl); Add(Fr, To_, BISHOP, Fl);
    End;
  End
  Else Add(Fr, To_, 0, Fl);
End;

Function GenMoves(Base : LongInt; Caps : Boolean) : LongInt;
Var Sq, P, A, F, R, T, K, Df, Dr, Tf, Tr, Dir, Fwd, Start, Last : LongInt;
Begin
  GN := 0; GBase := Base; GCaps := Caps;
  For Sq := 0 To 63 Do
  Begin
    P := Bd[Sq];
    If P * Side <= 0 Then Continue;
    A := AbsI(P); F := Sq And 7; R := Sq Shr 3;
    Case A Of
      PAWN :
        Begin
          Fwd := Side * 8;
          If Side = 1 Then
          Begin
            Start := 1; Last := 6;
          End
          Else
          Begin
            Start := 6; Last := 1;
          End;
          T := Sq + Fwd;
          If (T >= 0) And (T < 64) And (Bd[T] = 0) Then
          Begin
            If (Not Caps) Or (R = Last) Then AddPawn(Sq, T, 0);
            If (Not Caps) And (R = Start) And (Bd[T + Fwd] = 0) Then Add(Sq, T + Fwd, 0, 4);
          End;
          For K := 0 To 1 Do
          Begin
            If K = 0 Then Df := -1 Else Df := 1;
            If (F + Df >= 0) And (F + Df < 8) Then
            Begin
              T := Sq + Fwd + Df;
              If (T >= 0) And (T < 64) Then
              Begin
                If Bd[T] * Side < 0 Then AddPawn(Sq, T, 0)
                Else If T = EpSq Then Add(Sq, T, 0, 1);
              End;
            End;
          End;
        End;
      KNIGHT, KING :
        For K := 0 To 7 Do
        Begin
          If A = KNIGHT Then
          Begin
            T := Sq + KnightD[K]; Df := 2;
          End
          Else
          Begin
            T := Sq + KingD[K]; Df := 1;
          End;
          If (T >= 0) And (T < 64) And (AbsI((T And 7) - F) <= Df) Then
            If Bd[T] * Side <= 0 Then
              If (Bd[T] <> 0) Or Not Caps Then Add(Sq, T, 0, 0);
        End;
    Else
      For Dir := 0 To 7 Do
      Begin
        If (A = ROOK) And (Dir >= 4) Then Continue;
        If (A = BISHOP) And (Dir < 4) Then Continue;
        Case Dir Of
          0 : Begin Df := 1; Dr := 0; End;
          1 : Begin Df := -1; Dr := 0; End;
          2 : Begin Df := 0; Dr := 1; End;
          3 : Begin Df := 0; Dr := -1; End;
          4 : Begin Df := 1; Dr := 1; End;
          5 : Begin Df := -1; Dr := 1; End;
          6 : Begin Df := 1; Dr := -1; End;
        Else
          Begin Df := -1; Dr := -1; End;
        End;
        Tf := F + Df; Tr := R + Dr;
        While (Tf >= 0) And (Tf < 8) And (Tr >= 0) And (Tr < 8) Do
        Begin
          T := Tr * 8 + Tf;
          If Bd[T] = 0 Then
          Begin
            If Not Caps Then Add(Sq, T, 0, 0);
          End
          Else
          Begin
            If Bd[T] * Side < 0 Then Add(Sq, T, 0, 0);
            Tf := 99;
          End;
          Tf := Tf + Df; Tr := Tr + Dr;
        End;
      End;
    End;
  End;
  { roques (le roi n'est pas en echec et ne traverse pas une case attaquee) }
  If Not Caps Then
  Begin
    If Side = 1 Then
    Begin
      If ((Castle And 1) <> 0) And (Bd[5] = 0) And (Bd[6] = 0) And (Bd[4] = KING) And (Bd[7] = ROOK) Then
        If Not Attacked(4, -1) And Not Attacked(5, -1) And Not Attacked(6, -1) Then Add(4, 6, 0, 2);
      If ((Castle And 2) <> 0) And (Bd[3] = 0) And (Bd[2] = 0) And (Bd[1] = 0) And (Bd[4] = KING) And (Bd[0] = ROOK) Then
        If Not Attacked(4, -1) And Not Attacked(3, -1) And Not Attacked(2, -1) Then Add(4, 2, 0, 2);
    End
    Else
    Begin
      If ((Castle And 4) <> 0) And (Bd[61] = 0) And (Bd[62] = 0) And (Bd[60] = -KING) And (Bd[63] = -ROOK) Then
        If Not Attacked(60, 1) And Not Attacked(61, 1) And Not Attacked(62, 1) Then Add(60, 62, 0, 2);
      If ((Castle And 8) <> 0) And (Bd[59] = 0) And (Bd[58] = 0) And (Bd[57] = 0) And (Bd[60] = -KING) And
         (Bd[56] = -ROOK) Then
        If Not Attacked(60, 1) And Not Attacked(59, 1) And Not Attacked(58, 1) Then Add(60, 58, 0, 2);
    End;
  End;
  GenMoves := GN;
End;

{ sauvegarde et restauration de la position (pile de la recherche) }
Procedure PushPos;
Var K : LongInt;
Begin
  For K := 0 To 63 Do SBd[Ply * 64 + K] := Bd[K];
  SSide[Ply] := Side; SCastle[Ply] := Castle; SEp[Ply] := EpSq; SFifty[Ply] := Fifty;
  Inc(Ply);
End;

Procedure PopPos;
Var K : LongInt;
Begin
  Dec(Ply);
  For K := 0 To 63 Do Bd[K] := SBd[Ply * 64 + K];
  Side := SSide[Ply]; Castle := SCastle[Ply]; EpSq := SEp[Ply]; Fifty := SFifty[Ply];
End;

{ jouer le coup M (sans verifier) }
Procedure DoMove(M : LongInt);
Var F, T, P, Pr, Fl : LongInt;
Begin
  F := MvFrom(M); T := MvTo(M); Pr := MvPromo(M); Fl := MvFlags(M);
  P := Bd[F];
  If (AbsI(P) = PAWN) Or (Bd[T] <> 0) Then Fifty := 0 Else Inc(Fifty);
  Bd[T] := P; Bd[F] := 0;
  If (Fl And 1) <> 0 Then Bd[T - Side * 8] := 0;           { prise en passant }
  If Pr <> 0 Then Bd[T] := Side * Pr;
  If (Fl And 2) <> 0 Then
  Begin
    { roque : la tour suit }
    Case T Of
      6 : Begin Bd[5] := Bd[7]; Bd[7] := 0; End;
      2 : Begin Bd[3] := Bd[0]; Bd[0] := 0; End;
      62 : Begin Bd[61] := Bd[63]; Bd[63] := 0; End;
      58 : Begin Bd[59] := Bd[56]; Bd[56] := 0; End;
    End;
  End;
  If (Fl And 4) <> 0 Then EpSq := (F + T) Div 2 Else EpSq := -1;
  { droits de roque }
  If (F = 4) Or (T = 4) Then Castle := Castle And Not 3;
  If (F = 60) Or (T = 60) Then Castle := Castle And Not 12;
  If (F = 7) Or (T = 7) Then Castle := Castle And Not 1;
  If (F = 0) Or (T = 0) Then Castle := Castle And Not 2;
  If (F = 63) Or (T = 63) Then Castle := Castle And Not 4;
  If (F = 56) Or (T = 56) Then Castle := Castle And Not 8;
  Side := -Side;
End;

{ coup legal (le roi du camp qui joue n'est pas en echec ensuite) }
Function MakeLegal(M : LongInt) : Boolean;
Begin
  PushPos;
  DoMove(M);
  If InCheck(-Side) Then
  Begin
    PopPos;
    MakeLegal := False;
  End
  Else MakeLegal := True;
End;

{ coups legaux dans L (rend le nombre) }
Function LegalMoves : LongInt;
Var N, K, C, Base : LongInt;
Begin
  Base := Ply * MaxMoves;
  N := GenMoves(Base, False);
  C := 0;
  For K := 0 To N - 1 Do
    If MakeLegal(MvList[Base + K]) Then
    Begin
      PopPos;
      LegL[C] := MvList[Base + K];
      Inc(C);
    End;
  LegalMoves := C;
End;

{ materiel insuffisant (roi seul, ou roi et une piece mineure) }
Function Insufficient : Boolean;
Var K, Minor, Other : LongInt;
Begin
  Minor := 0; Other := 0;
  For K := 0 To 63 Do
    Case AbsI(Bd[K]) Of
      KNIGHT, BISHOP : Inc(Minor);
      PAWN, ROOK, QUEEN : Inc(Other);
    End;
  Insufficient := (Other = 0) And (Minor <= 1);
End;

{ ==================================================================== }
{ Recherche                                                             }
{ ==================================================================== }

Function Evaluate : LongInt;
Var K, P, A, S, V : LongInt;
Begin
  V := 0;
  For K := 0 To 63 Do
  Begin
    P := Bd[K];
    If P <> 0 Then
    Begin
      A := AbsI(P);
      If P > 0 Then S := K Else S := (7 - (K Shr 3)) * 8 + (K And 7);
      Case A Of
        PAWN : S := PieceVal[A] + PstPawn[S];
        KNIGHT : S := PieceVal[A] + PstKnight[S];
        BISHOP : S := PieceVal[A] + PstBishop[S];
        KING : S := PstKing[S];
      Else
        S := PieceVal[A];
      End;
      If P > 0 Then V := V + S Else V := V - S;
    End;
  End;
  Evaluate := V * Side;
End;

{ ordre : prises (victime chere, attaquant bon marche) puis promotions }
Procedure OrderMoves(Base, N : LongInt);
Var K, J, M, S, T : LongInt;
Begin
  For K := 0 To N - 1 Do
  Begin
    M := MvList[Base + K];
    S := 0;
    If Bd[MvTo(M)] <> 0 Then S := 10 * PieceVal[AbsI(Bd[MvTo(M)])] - PieceVal[AbsI(Bd[MvFrom(M)])] + 1000;
    If MvPromo(M) = QUEEN Then S := S + 800;
    MvScore[Base + K] := S;
  End;
  For K := 1 To N - 1 Do
  Begin
    M := MvList[Base + K]; S := MvScore[Base + K]; J := K - 1;
    While (J >= 0) And (MvScore[Base + J] < S) Do
    Begin
      MvList[Base + J + 1] := MvList[Base + J]; MvScore[Base + J + 1] := MvScore[Base + J];
      Dec(J);
    End;
    MvList[Base + J + 1] := M; MvScore[Base + J + 1] := S;
  End;
  T := 0;
End;

Function Quiesce(Alpha, Beta : LongInt) : LongInt;
Var Stand, N, K, Base, V : LongInt;
Begin
  Inc(Nodes);
  Stand := Evaluate;
  If (Stand >= Beta) Or (Ply >= MaxPly - 2) Then
  Begin
    Quiesce := Stand;
    Exit;
  End;
  If Stand > Alpha Then Alpha := Stand;
  Base := Ply * MaxMoves;
  N := GenMoves(Base, True);
  OrderMoves(Base, N);
  { While et non For : OS2PC garde la borne d'un For dans une variable
    statique, qu'un appel recursif ecraserait }
  K := 0;
  While K < N Do
  Begin
    If MakeLegal(MvList[Base + K]) Then
    Begin
      V := -Quiesce(-Beta, -Alpha);
      PopPos;
      If V >= Beta Then
      Begin
        Quiesce := V;
        Exit;
      End;
      If V > Alpha Then Alpha := V;
    End;
    Inc(K);
  End;
  Quiesce := Alpha;
End;

Function Search(Depth, Alpha, Beta : LongInt) : LongInt;
Var N, K, Base, V, Legal : LongInt;
Begin
  If Depth <= 0 Then
  Begin
    Search := Quiesce(Alpha, Beta);
    Exit;
  End;
  Inc(Nodes);
  Base := Ply * MaxMoves;
  N := GenMoves(Base, False);
  OrderMoves(Base, N);
  Legal := 0;
  K := 0;
  While K < N Do
  Begin
    If MakeLegal(MvList[Base + K]) Then
    Begin
      Inc(Legal);
      V := -Search(Depth - 1, -Beta, -Alpha);
      PopPos;
      If V >= Beta Then
      Begin
        Search := V;
        Exit;
      End;
      If V > Alpha Then Alpha := V;
    End;
    Inc(K);
  End;
  If Legal = 0 Then
  Begin
    If InCheck(Side) Then Search := -MateVal + Ply Else Search := 0;
    Exit;
  End;
  Search := Alpha;
End;

{ meilleur coup du camp au trait (profondeur D) }
Function BestMove(D : LongInt) : LongInt;
Var N, K, Base, V, Best, BestV, Alpha : LongInt;
Begin
  Nodes := 0;
  Base := Ply * MaxMoves;
  N := GenMoves(Base, False);
  OrderMoves(Base, N);
  Best := 0; BestV := -Inf; Alpha := -Inf;
  For K := 0 To N - 1 Do
    If MakeLegal(MvList[Base + K]) Then
    Begin
      V := -Search(D - 1, -Inf, -Alpha);
      PopPos;
      If (V > BestV) Or (Best = 0) Then
      Begin
        BestV := V; Best := MvList[Base + K];
      End;
      If V > Alpha Then Alpha := V;
    End;
  BestMove := Best;
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Function PieceLetter(A : LongInt) : String;
Begin
  Case A Of
    KNIGHT : PieceLetter := 'C';
    BISHOP : PieceLetter := 'F';
    ROOK : PieceLetter := 'T';
    QUEEN : PieceLetter := 'D';
    KING : PieceLetter := 'R';
  Else
    PieceLetter := '';
  End;
End;

Function SqName(S : LongInt) : String;
Begin
  SqName := Chr(97 + (S And 7)) + Chr(49 + (S Shr 3));
End;

{ notation du coup M (position avant le coup) }
Function MoveText(M : LongInt) : String;
Var S : String; F, T, P : LongInt;
Begin
  F := MvFrom(M); T := MvTo(M); P := AbsI(Bd[F]);
  If (MvFlags(M) And 2) <> 0 Then
  Begin
    If (T And 7) = 6 Then S := 'O-O' Else S := 'O-O-O';
  End
  Else
  Begin
    S := PieceLetter(P) + SqName(F);
    If (Bd[T] <> 0) Or ((MvFlags(M) And 1) <> 0) Then S := S + 'x' Else S := S + '-';
    S := S + SqName(T);
    If MvPromo(M) <> 0 Then S := S + '=' + PieceLetter(MvPromo(M));
  End;
  MoveText := S;
End;

Procedure SaveHist(M : LongInt; T : String);
Var K : LongInt;
Begin
  If NHist >= MaxHist Then Exit;
  For K := 0 To 63 Do HBd[NHist * 64 + K] := Bd[K] + 8;
  HSide[NHist] := Side; HCastle[NHist] := Castle; HEp[NHist] := EpSq; HFifty[NHist] := Fifty;
  HMove[NHist] := M; HText[NHist] := T;
  Inc(NHist);
End;

Procedure UpdateStatus;
Var N : LongInt; Who : String;
Begin
  N := LegalMoves;
  If Side = 1 Then Who := 'blancs' Else Who := 'noirs';
  Over := 0;
  If N = 0 Then
  Begin
    If InCheck(Side) Then
    Begin
      Over := 1;
      If Side = 1 Then Status := 'Echec et mat : les noirs gagnent.' Else Status := 'Echec et mat : les blancs gagnent.';
      If NHist > 0 Then HText[NHist - 1] := HText[NHist - 1] + '#';
    End
    Else
    Begin
      Over := 2;
      Status := 'Pat : partie nulle.';
    End;
  End
  Else If Fifty >= 100 Then
  Begin
    Over := 3; Status := 'Nulle (50 coups sans prise ni pion).';
  End
  Else If Insufficient Then
  Begin
    Over := 3; Status := 'Nulle (materiel insuffisant).';
  End
  Else If InCheck(Side) Then
  Begin
    Status := 'Echec ! Aux ' + Who + ' de jouer.';
    If NHist > 0 Then HText[NHist - 1] := HText[NHist - 1] + '+';
  End
  Else Status := 'Aux ' + Who + ' de jouer.';
End;

Procedure PlayMove(M : LongInt);
Var T : String;
Begin
  T := MoveText(M);
  SaveHist(M, T);
  DoMove(M);
  LastFrom := MvFrom(M); LastTo := MvTo(M);
  Sel := -1;
  UpdateStatus;
  Dummy := WinInvalidateRect(Client, 0, 1);
  If Over <> 0 Then ShowMsg(Status, 'Echecs')
  Else If (TwoPlayers = 0) And (Side = CompSide) Then
  Begin
    Thinking := 1;
    Status := 'L''ordinateur reflechit...';
    Dummy := WinPostMsg(Client, WM_THINK, 0, 0);
  End;
End;

Procedure NewGame;
Const Back : Array[0..7] Of LongInt = (ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK);
Var K : LongInt;
Begin
  For K := 0 To 63 Do Bd[K] := 0;
  For K := 0 To 7 Do
  Begin
    Bd[K] := Back[K]; Bd[8 + K] := PAWN;
    Bd[48 + K] := -PAWN; Bd[56 + K] := -Back[K];
  End;
  Side := 1; Castle := 15; EpSq := -1; Fifty := 0; Ply := 0;
  NHist := 0; Sel := -1; LastFrom := -1; LastTo := -1; Thinking := 0;
  UpdateStatus;
  Dummy := WinInvalidateRect(Client, 0, 1);
  If (TwoPlayers = 0) And (CompSide = 1) Then
  Begin
    Thinking := 1;
    Status := 'L''ordinateur reflechit...';
    Dummy := WinPostMsg(Client, WM_THINK, 0, 0);
  End;
End;

Procedure ComputerMove;
Var M : LongInt;
Begin
  Thinking := 0;
  If (Over <> 0) Or (Side <> CompSide) Or (TwoPlayers <> 0) Then Exit;
  Ply := 0;
  M := BestMove(Level);
  If M <> 0 Then PlayMove(M) Else UpdateStatus;
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

Procedure UndoMove;
Var N, K : LongInt;
Begin
  If (NHist = 0) Or (Thinking <> 0) Then Exit;
  { le coup du joueur (et la reponse de l'ordinateur) }
  If (TwoPlayers = 0) And (Side <> CompSide) And (NHist >= 2) Then N := 2 Else N := 1;
  If (TwoPlayers = 0) And (Side <> CompSide) And (NHist = 1) Then Exit;
  NHist := NHist - N;
  For K := 0 To 63 Do Bd[K] := LongInt(HBd[NHist * 64 + K]) - 8;
  Side := HSide[NHist]; Castle := HCastle[NHist]; EpSq := HEp[NHist]; Fifty := HFifty[NHist];
  If NHist > 0 Then
  Begin
    LastFrom := MvFrom(HMove[NHist - 1]); LastTo := MvTo(HMove[NHist - 1]);
  End
  Else
  Begin
    LastFrom := -1; LastTo := -1;
  End;
  Sel := -1;
  UpdateStatus;
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Procedure BoardOrigin(Var X0, Y0 : LongInt);
Begin
  X0 := 24; Y0 := (CH - 8 * Sq) Div 2 + 4;
End;

{ case -> coin bas gauche (l'echiquier se retourne quand l'ordinateur a
  les blancs) }
Procedure SqXY(S : LongInt; Var X, Y : LongInt);
Var X0, Y0, F, R : LongInt;
Begin
  BoardOrigin(X0, Y0);
  F := S And 7; R := S Shr 3;
  If (CompSide = 1) And (TwoPlayers = 0) Then
  Begin
    F := 7 - F; R := 7 - R;
  End;
  X := X0 + F * Sq; Y := Y0 + R * Sq;
End;

Function SqAt(X, Y : LongInt) : LongInt;
Var X0, Y0, F, R : LongInt;
Begin
  BoardOrigin(X0, Y0);
  SqAt := -1;
  If (X < X0) Or (Y < Y0) Or (X >= X0 + 8 * Sq) Or (Y >= Y0 + 8 * Sq) Then Exit;
  F := (X - X0) Div Sq; R := (Y - Y0) Div Sq;
  If (CompSide = 1) And (TwoPlayers = 0) Then
  Begin
    F := 7 - F; R := 7 - R;
  End;
  SqAt := R * 8 + F;
End;

{ piece P dans la case de coin bas gauche (X, Y) : dessins vectoriels }
Procedure DrawPiece(Hps, X, Y, P : LongInt);
Var A, Fill, Edge, Cx : LongInt;
Begin
  A := AbsI(P);
  If P > 0 Then
  Begin
    Fill := CLR_WHITE; Edge := CLR_BLACK;
  End
  Else
  Begin
    Fill := CLR_BLACK; Edge := CLR_PALEGRAY;
  End;
  Cx := X + Sq Div 2;
  { socle }
  Shape(Hps, Cx - 14, Y + 5, Cx + 14, Y + 10, Fill, Edge, 4);
  Case A Of
    PAWN :
      Begin
        Shape(Hps, Cx - 8, Y + 10, Cx + 8, Y + 22, Fill, Edge, 6);
        Shape(Hps, Cx - 7, Y + 21, Cx + 7, Y + 35, Fill, Edge, 14);
      End;
    ROOK :
      Begin
        Shape(Hps, Cx - 9, Y + 10, Cx + 9, Y + 30, Fill, Edge, 0);
        Shape(Hps, Cx - 12, Y + 30, Cx + 12, Y + 35, Fill, Edge, 0);
        Shape(Hps, Cx - 12, Y + 35, Cx - 7, Y + 40, Fill, Edge, 0);
        Shape(Hps, Cx - 2, Y + 35, Cx + 2, Y + 40, Fill, Edge, 0);
        Shape(Hps, Cx + 7, Y + 35, Cx + 12, Y + 40, Fill, Edge, 0);
      End;
    KNIGHT :
      Begin
        Shape(Hps, Cx - 7, Y + 10, Cx + 9, Y + 28, Fill, Edge, 6);
        Shape(Hps, Cx - 13, Y + 24, Cx + 7, Y + 36, Fill, Edge, 8);
        Shape(Hps, Cx + 1, Y + 34, Cx + 7, Y + 41, Fill, Edge, 0);
        GBox(Hps, Cx - 3, Y + 30, Cx - 1, Y + 32, Edge, DRO_FILL, 0);
        GLn(Hps, Cx + 9, Y + 30, Cx + 9, Y + 14, Edge);
      End;
    BISHOP :
      Begin
        Shape(Hps, Cx - 9, Y + 10, Cx + 9, Y + 15, Fill, Edge, 0);
        Shape(Hps, Cx - 8, Y + 14, Cx + 8, Y + 36, Fill, Edge, 16);
        Shape(Hps, Cx - 3, Y + 35, Cx + 3, Y + 41, Fill, Edge, 6);
        GLn(Hps, Cx - 3, Y + 28, Cx + 4, Y + 22, Edge);
      End;
    QUEEN :
      Begin
        Shape(Hps, Cx - 10, Y + 10, Cx + 10, Y + 16, Fill, Edge, 0);
        Shape(Hps, Cx - 8, Y + 15, Cx + 8, Y + 30, Fill, Edge, 0);
        Shape(Hps, Cx - 13, Y + 28, Cx + 13, Y + 33, Fill, Edge, 0);
        Shape(Hps, Cx - 14, Y + 33, Cx - 9, Y + 38, Fill, Edge, 5);
        Shape(Hps, Cx - 7, Y + 33, Cx - 2, Y + 41, Fill, Edge, 5);
        Shape(Hps, Cx + 2, Y + 33, Cx + 7, Y + 41, Fill, Edge, 5);
        Shape(Hps, Cx + 9, Y + 33, Cx + 14, Y + 38, Fill, Edge, 5);
      End;
    KING :
      Begin
        Shape(Hps, Cx - 10, Y + 10, Cx + 10, Y + 16, Fill, Edge, 0);
        Shape(Hps, Cx - 8, Y + 15, Cx + 8, Y + 31, Fill, Edge, 0);
        Shape(Hps, Cx - 11, Y + 29, Cx + 11, Y + 34, Fill, Edge, 0);
        Shape(Hps, Cx - 2, Y + 33, Cx + 2, Y + 43, Fill, Edge, 0);
        Shape(Hps, Cx - 6, Y + 36, Cx + 6, Y + 40, Fill, Edge, 0);
      End;
  End;
End;

Procedure PaintAll(H : LongInt);
Var Hps, S, X, Y, X0, Y0, K, N, Base, C, Row : LongInt; Rc : Array[0..3] Of LongInt; T : String;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  BoardOrigin(X0, Y0);
  Shape(Hps, X0 - 4, Y0 - 4, X0 + 8 * Sq + 3, Y0 + 8 * Sq + 3, CLR_BROWN, CLR_BLACK, 0);
  { coups possibles de la piece choisie }
  N := 0;
  If Sel >= 0 Then N := LegalMoves;
  For S := 0 To 63 Do
  Begin
    SqXY(S, X, Y);
    If Odd((S And 7) + (S Shr 3)) Then C := CLR_PALEGRAY Else C := CLR_DARKCYAN;
    If S = Sel Then C := CLR_YELLOW;
    Rc[0] := X; Rc[1] := Y; Rc[2] := X + Sq; Rc[3] := Y + Sq;
    Dummy := WinFillRect(Hps, LongInt(@Rc), C);
    If (S = LastFrom) Or (S = LastTo) Then
    Begin
      GBox(Hps, X + 1, Y + 1, X + Sq - 2, Y + Sq - 2, CLR_BLUE, DRO_OUTLINE, 0);
      GBox(Hps, X + 2, Y + 2, X + Sq - 3, Y + Sq - 3, CLR_BLUE, DRO_OUTLINE, 0);
    End;
    If Bd[S] <> 0 Then DrawPiece(Hps, X, Y, Bd[S]);
  End;
  For K := 0 To N - 1 Do
    If MvFrom(LegL[K]) = Sel Then
    Begin
      SqXY(MvTo(LegL[K]), X, Y);
      Shape(Hps, X + Sq Div 2 - 5, Y + Sq Div 2 - 5, X + Sq Div 2 + 5, Y + Sq Div 2 + 5, CLR_GREEN, CLR_DARKGREEN, 10);
    End;
  { coordonnees }
  For K := 0 To 7 Do
  Begin
    SqXY(K, X, Y);
    TextXY(Hps, X + Sq Div 2 - 4, Y0 - 22, Chr(97 + K), CLR_BLACK, CLR_PALEGRAY);
    SqXY(K * 8, X, Y);
    TextXY(Hps, X0 - 18, Y + Sq Div 2 - 8, Chr(49 + K), CLR_BLACK, CLR_PALEGRAY);
  End;
  { panneau : etat et coups joues }
  X := X0 + 8 * Sq + 20;
  TextXY(Hps, X, CH - 24, 'Echecs', CLR_DARKBLUE, CLR_PALEGRAY);
  If TwoPlayers <> 0 Then T := 'Deux joueurs'
  Else
  Begin
    Case Level Of
      1 : T := 'Niveau : facile';
      2 : T := 'Niveau : moyen';
    Else
      T := 'Niveau : difficile';
    End;
  End;
  TextXY(Hps, X, CH - 42, T, CLR_BLACK, CLR_PALEGRAY);
  { etat sur deux lignes au besoin }
  T := Status;
  If Length(T) > 26 Then
  Begin
    K := 26;
    While (K > 1) And (T[K] <> ' ') Do Dec(K);
    TextXY(Hps, X, CH - 66, Copy(T, 1, K - 1), CLR_DARKRED, CLR_PALEGRAY);
    TextXY(Hps, X, CH - 82, Copy(T, K + 1, 255), CLR_DARKRED, CLR_PALEGRAY);
  End
  Else TextXY(Hps, X, CH - 66, T, CLR_DARKRED, CLR_PALEGRAY);
  TextXY(Hps, X, CH - 108, 'Coups :', CLR_DARKBLUE, CLR_PALEGRAY);
  Base := MaxI(0, ((NHist + 1) Div 2) - 16);
  Row := 0;
  K := Base * 2;
  While K < NHist Do
  Begin
    T := IStr(K Div 2 + 1) + '. ' + HText[K];
    If K + 1 < NHist Then
    Begin
      While Length(T) < 15 Do T := T + ' ';
      T := T + HText[K + 1];
    End;
    TextXY(Hps, X, CH - 126 - Row * 16, T, CLR_BLACK, CLR_PALEGRAY);
    Inc(Row);
    K := K + 2;
  End;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Procedure ClickSquare(S : LongInt);
Var N, K, M : LongInt;
Begin
  If (S < 0) Or (Over <> 0) Or (Thinking <> 0) Then Exit;
  If (TwoPlayers = 0) And (Side = CompSide) Then Exit;
  If Bd[S] * Side > 0 Then
  Begin
    { piece du camp au trait : choisie }
    If Sel = S Then Sel := -1 Else Sel := S;
    Dummy := WinInvalidateRect(Client, 0, 1);
    Exit;
  End;
  If Sel < 0 Then Exit;
  N := LegalMoves;
  M := 0;
  For K := 0 To N - 1 Do
    If (MvFrom(LegL[K]) = Sel) And (MvTo(LegL[K]) = S) Then
      If (M = 0) Or (MvPromo(LegL[K]) = QUEEN) Then M := LegL[K];
  If M <> 0 Then PlayMove(M)
  Else
  Begin
    Sel := -1;
    Dummy := WinInvalidateRect(Client, 0, 1);
  End;
End;

Procedure SetLevel(N : LongInt);
Begin
  Level := N;
  CheckItem(CM_LEVEL1, N = 1); CheckItem(CM_LEVEL2, N = 2); CheckItem(CM_LEVEL3, N = 3);
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

Procedure Command(Id : LongInt);
Begin
  If Thinking <> 0 Then Exit;
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : UndoMove;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_LEVEL1 : SetLevel(1);
    CM_LEVEL2 : SetLevel(2);
    CM_LEVEL3 : SetLevel(3);
    CM_BLACK :
      Begin
        CompSide := -CompSide;
        CheckItem(CM_BLACK, CompSide = 1);
        NewGame;
      End;
    CM_TWO :
      Begin
        TwoPlayers := 1 - TwoPlayers;
        CheckItem(CM_TWO, TwoPlayers <> 0);
        NewGame;
      End;
    CM_RULES : ShowMsg('Cliquez une de vos pieces : ses cases d''arrivee sont marquees ; cliquez ensuite la case ' +
                       'choisie. Roque : deplacez le roi de deux cases. Un pion qui atteint la derniere rangee ' +
                       'devient une dame. F2 : nouvelle partie, Ctrl+Z : annuler le dernier coup.', 'Echecs - Regles');
    CM_ABOUT : ShowMsg('Echecs pour OS/2-0 (Presentation Manager) : regles completes, recherche alpha-beta. ' +
                       'Programme ecrit en Pascal et compile par OS2PC.', 'A propos des Echecs');
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
    WM_BUTTON1DOWN :
      Begin
        ClickSquare(SqAt(S16(Mp1), S16(Mp1 Shr 16)));
        MainProc := 1;
      End;
    WM_THINK :
      Begin
        Dummy := WinUpdateWindow(H);
        ComputerMove;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      If (Lo16(Mp1) And KC_KEYUP) = 0 Then
      Begin
        If ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And (Hi16(Mp2) = VK_F2) Then Command(CM_NEW)
        Else If ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And (Hi16(Mp2) = VK_F1) Then Command(CM_RULES)
        Else If ((Lo16(Mp1) And KC_CTRL) <> 0) And ((Lo16(Mp2) = 26) Or (Lo16(Mp2) = Ord('z')) Or
                (Lo16(Mp2) = Ord('Z'))) Then Command(CM_UNDO)
        Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, H0, H1, H2, H3, Sw, Sh, M : LongInt;

BEGIN
  Level := 2; CompSide := -1; TwoPlayers := 0; Status := ''; Ply := 0;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('ECHECS'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('ECHECS'), Z2('Echecs'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_LEVEL1, 'Niveau ~facile');
  MItem(MIS_TEXT, MIA_CHECKED, CM_LEVEL2, 'Niveau ~moyen');
  MItem(MIS_TEXT, 0, CM_LEVEL3, 'Niveau ~difficile');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_BLACK, 'Jouer avec les ~noirs');
  MItem(MIS_TEXT, 0, CM_TWO, '~Deux joueurs');
  MenuClose(H2, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~Comment jouer' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos des Echecs');
  MenuClose(H3, 2);
  MenuClose(H0, 3);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - 640) Div 2), MaxI(0, Sh - 470), MinI(Sw, 640),
                           MinI(Sh, 470), SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  NewGame;
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
