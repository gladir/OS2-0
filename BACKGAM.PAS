{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BACKGAM - jeu de backgammon contre l'ordinateur pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program BACKGAM;

{$R-,S-,I-}

{ Compilation : OS2PC BACKGAM.PAS   (produit BACKGAM.EXE)

  Portage vers OS/2-0 du prototype BACKGAM.PAS du depot 7iles (Turbo
  Pascal et BGI, coups tapes au clavier par lettres de fleches) : fenetre
  de Presentation Manager avec menus, souris, plateau en bois, des, panneau
  des joueurs, barre d'etat et apparence d'OS/2. Les regles completes y
  sont : barre, entree, pions frappes, sortie (bear off), obligation de
  jouer le plus de des possible (ou le plus fort), doubles joues quatre
  fois, gammon et backgammon.

  Vous jouez les pions blancs, de la case 24 vers votre jan interieur
  (cases 1 a 6, en bas a droite) puis vous les sortez dans le plateau de
  droite ; l'ordinateur joue les noirs en sens inverse. Le premier qui a
  sorti ses quinze pions gagne (gammon : l'autre n'en a sorti aucun,
  points doubles ; backgammon : il lui en reste en plus sur la barre ou
  dans le jan interieur du gagnant, points triples).

  Souris : Lancer les des (bouton, ou clic sur le plateau), puis cliquer
  un de ses pions (les cases ou il peut aller sont marquees d'un point
  jaune) et la case d'arrivee (ou le plateau de sortie). Clavier : Espace
  ou Entree (lancer les des), Ctrl+Z (annuler les pions joues dans le
  tour), Echap (deselectionner), F2 (nouvelle partie), F1 (regles).
  Niveaux de l'ordinateur : Facile (coups au hasard) et Normal (evaluation
  de toutes les suites de coups : course, pions exposes, cases faites,
  barrages).
  Parametres : /SEED:n (hasard reproductible, pour les essais) ; /AUTO
  (l'ordinateur joue les deux couleurs : demonstration et essais). }

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
  VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_UNDO = 102; CM_ROLL = 103; CM_QUIT = 104;
  CM_EASY = 121; CM_NORMAL = 122;
  CM_RULES = 301; CM_ABOUT = 302;
  { joueurs }
  SH = 1; SC = 2;                   { vous (blancs), l'ordinateur (noirs) }
  IBarH = 25; IBarC = 26; IOffH = 27; IOffC = 28;
  { plateau (zone client, Y vers le bas) }
  BdL = 8; BdT = 8; BdR = 459; BdB = 379;
  FL = 18; FR = 228; BarX = 198; PtW = 30;
  FT = 26; FB = 361; PtH = 136; MidY = 193;
  TrayX = 418;
  Rad = 13;
  PnX = 472; PW = 142;
  CWant = 624; CHWant = 412;
  Inf = 100000000;

Type
  TBg = Array[0..28] Of LongInt;    { 1..24 cases (> 0 blancs, < 0 noirs) ; barres ; sortis }
  TDc = Array[0..4] Of LongInt;     { des restants ([4] = nombre) }

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Bd, TurnB : TBg;                  { position ; position au debut du tour }
  Dc, TurnDc : TDc;
  Turn, Phase, Wait, Over, Level, Seed, AutoAll, Sel, CurMax, Roll1, Roll2 : LongInt;
  WinsH, WinsC : LongInt;
  QR, QD : Array[0..3] Of LongInt;  { coups prevus de l'ordinateur }
  NQ, IQ : LongInt;
  LastTo : Array[0..3] Of LongInt;  { cases d'arrivee du dernier tour de l'ordinateur }
  NLast : LongInt;
  { recherche }
  PathR, PathD, BestR, BestD : Array[0..3] Of LongInt;
  BestV, BestN, SearchS, HiDie, HiReq, NLeaf : LongInt;
  BHit, CpuHit : Boolean;
  ShownSig : Array[0..40] Of LongInt;
  DestA : Array[0..25] Of LongInt;  { cases d'arrivee permises du pion choisi (0 : sortie) }
  Msg, LMsg : String;
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

Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

Function Opp(S : LongInt) : LongInt;
Begin
  Opp := 3 - S;
End;

{ ==================================================================== }
{ Regles. Chaque joueur compte ses cases a sa facon : R = 1..24 est la   }
{ distance a la sortie (R = 25 : la barre ; R <= 0 : sorti).             }
{ ==================================================================== }

{ case reelle de la case relative R du joueur S }
Function Act(S, R : LongInt) : LongInt;
Begin
  If S = SH Then Act := R Else Act := 25 - R;
End;

Function BarIx(S : LongInt) : LongInt;
Begin
  If S = SH Then BarIx := IBarH Else BarIx := IBarC;
End;

Function OffIx(S : LongInt) : LongInt;
Begin
  If S = SH Then OffIx := IOffH Else OffIx := IOffC;
End;

{ pions du joueur S sur la case reelle P }
Function OwnP(Var B : TBg; S, P : LongInt) : LongInt;
Begin
  OwnP := 0;
  If (S = SH) And (B[P] > 0) Then OwnP := B[P];
  If (S = SC) And (B[P] < 0) Then OwnP := -B[P];
End;

{ pions de S sur sa case relative R (25 : la barre) }
Function Own(Var B : TBg; S, R : LongInt) : LongInt;
Begin
  If R = 25 Then Own := B[BarIx(S)]
  Else If (R < 1) Or (R > 24) Then Own := 0
  Else Own := OwnP(B, S, Act(S, R));
End;

Function OppAt(Var B : TBg; S, R : LongInt) : LongInt;
Begin
  OppAt := OwnP(B, Opp(S), Act(S, R));
End;

Function AllHome(Var B : TBg; S : LongInt) : Boolean;
Var R : LongInt;
Begin
  AllHome := False;
  If B[BarIx(S)] > 0 Then Exit;
  For R := 7 To 24 Do If Own(B, S, R) > 0 Then Exit;
  AllHome := True;
End;

{ le pion de la case R peut-il avancer de D ? }
Function CanMv(Var B : TBg; S, R, D : LongInt) : Boolean;
Var T, K : LongInt;
Begin
  CanMv := False;
  If Own(B, S, R) = 0 Then Exit;
  If (B[BarIx(S)] > 0) And (R <> 25) Then Exit;
  T := R - D;
  If T >= 1 Then
  Begin
    CanMv := OppAt(B, S, T) <= 1;
    Exit;
  End;
  If Not AllHome(B, S) Then Exit;
  If T < 0 Then
    For K := R + 1 To 6 Do If Own(B, S, K) > 0 Then Exit;
  CanMv := True;
End;

{ joue le pion ; resultat : True s'il a frappe un pion adverse }
Function DoMv(Var B : TBg; S, R, D : LongInt) : Boolean;
Var T, P : LongInt;
Begin
  DoMv := False;
  If R = 25 Then Dec(B[BarIx(S)])
  Else
  Begin
    P := Act(S, R);
    If S = SH Then Dec(B[P]) Else Inc(B[P]);
  End;
  T := R - D;
  If T <= 0 Then
  Begin
    Inc(B[OffIx(S)]);
    Exit;
  End;
  P := Act(S, T);
  If OwnP(B, Opp(S), P) = 1 Then
  Begin
    B[P] := 0;
    Inc(B[BarIx(Opp(S))]);
    DoMv := True;
  End;
  If S = SH Then Inc(B[P]) Else Dec(B[P]);
End;

Procedure DropDie(Var Src, Dst : TDc; I : LongInt);
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To Src[4] - 1 Do
    If K <> I Then
    Begin
      Dst[N] := Src[K];
      Inc(N);
    End;
  Dst[4] := N;
End;

Function DieIx(Var D : TDc; V : LongInt) : LongInt;
Var K : LongInt;
Begin
  DieIx := -1;
  For K := D[4] - 1 DownTo 0 Do If D[K] = V Then DieIx := K;
End;

{ nombre maximal de des que S peut jouer }
Function MaxUse(Var B : TBg; S : LongInt; Var D : TDc) : LongInt;
Var I, R, V, Best : LongInt; T : TBg; Nd : TDc;
Begin
  Best := 0;
  I := 0;
  While (I < D[4]) And (Best < D[4]) Do
  Begin
    If (I = 0) Or (D[I] <> D[I - 1]) Then
    Begin
      R := 25;
      While (R >= 1) And (Best < D[4]) Do
      Begin
        If CanMv(B, S, R, D[I]) Then
        Begin
          T := B;
          BHit := DoMv(T, S, R, D[I]);
          DropDie(D, Nd, I);
          V := 1 + MaxUse(T, S, Nd);
          If V > Best Then Best := V;
        End;
        Dec(R);
      End;
    End;
    Inc(I);
  End;
  MaxUse := Best;
End;

{ le de le plus fort, si un seul de deux des differents peut etre joue }
Function HigherRule(Var B : TBg; S : LongInt; Var D : TDc; Mx : LongInt) : LongInt;
Var R, Hi : LongInt;
Begin
  HigherRule := 0;
  If (Mx <> 1) Or (D[4] <> 2) Or (D[0] = D[1]) Then Exit;
  Hi := D[0];
  If D[1] > Hi Then Hi := D[1];
  For R := 1 To 25 Do If CanMv(B, S, R, Hi) Then HigherRule := Hi;
End;

{ coup permis : le pion de R avance de V (en respectant les obligations) }
Function Legal(Var B : TBg; S : LongInt; Var D : TDc; Mx, R, V : LongInt) : Boolean;
Var I, H : LongInt; T : TBg; Nd : TDc;
Begin
  Legal := False;
  I := DieIx(D, V);
  If (I < 0) Or (Mx = 0) Then Exit;
  If Not CanMv(B, S, R, V) Then Exit;
  H := HigherRule(B, S, D, Mx);
  If (H <> 0) And (V <> H) Then Exit;
  T := B;
  BHit := DoMv(T, S, R, V);
  DropDie(D, Nd, I);
  Legal := 1 + MaxUse(T, S, Nd) = Mx;
End;

Function Pips(Var B : TBg; S : LongInt) : LongInt;
Var R, N : LongInt;
Begin
  N := B[BarIx(S)] * 25;
  For R := 1 To 24 Do N := N + Own(B, S, R) * R;
  Pips := N;
End;

{ ==================================================================== }
{ Ordinateur : evaluation de la position pour S                         }
{ ==================================================================== }

Function Eval(Var B : TBg; S : LongInt) : LongInt;
Var O, R, X, V, MaxS, MaxO, Dir, Ind, Dist, Run, BestRun, N, C : LongInt;
    OppX : Array[0..24] Of LongInt;
Begin
  O := Opp(S);
  V := (Pips(B, O) - Pips(B, S)) * 8;
  V := V + B[OffIx(S)] * 4;
  { le pion le plus en arriere de chacun }
  MaxS := 0;
  If B[BarIx(S)] > 0 Then MaxS := 25
  Else For R := 1 To 24 Do If Own(B, S, R) > 0 Then MaxS := R;
  MaxO := 0;
  If B[BarIx(O)] > 0 Then MaxO := 25
  Else For R := 1 To 24 Do If Own(B, O, R) > 0 Then MaxO := R;
  If MaxS <= 25 - MaxO Then
  Begin
    { course pure : plus de contact }
    Eval := V;
    Exit;
  End;
  { pions adverses vus dans les cases de S : X = 25 - case relative adverse }
  For X := 0 To 24 Do OppX[X] := 0;
  OppX[0] := B[BarIx(O)];
  For R := 1 To 24 Do OppX[25 - R] := Own(B, O, R);
  BestRun := 0; Run := 0;
  For R := 1 To 24 Do
  Begin
    N := Own(B, S, R);
    If N = 1 Then
    Begin
      { pion expose : coups directs (1 a 6) et indirects (7 a 12) }
      Dir := 0; Ind := 0;
      For X := 0 To R - 1 Do
        If OppX[X] > 0 Then
        Begin
          Dist := R - X;
          If Dist <= 6 Then Inc(Dir) Else If Dist <= 12 Then Inc(Ind);
        End;
      C := Dir * 4 + Ind;
      If C > 12 Then C := 12;
      V := V - C * (25 - R + 8) * 2;
    End;
    If N >= 2 Then
    Begin
      If R <= 6 Then V := V + 40
      Else If R = 7 Then V := V + 32
      Else If R <= 12 Then V := V + 14
      Else If R >= 18 Then V := V + 18
      Else V := V + 8;
      If N > 4 Then V := V - (N - 4) * 6;
      Inc(Run);
      If Run > BestRun Then BestRun := Run;
    End
    Else Run := 0;
  End;
  V := V + BestRun * BestRun * 6;
  V := V + B[BarIx(O)] * 40 - B[BarIx(S)] * 40;
  Eval := V;
End;

{ toutes les suites de coups (le plus de des possible) ; garde la
  meilleure (Normal) ou une au hasard (Facile) }
Procedure Gen(Var B : TBg; Var D : TDc; Depth, LastR : LongInt);
Var I, R, V, Lim, K : LongInt; T : TBg; Nd : TDc; Any : Boolean;
Begin
  Any := False;
  If Depth < CurMax Then
  Begin
    I := 0;
    While I < D[4] Do
    Begin
      If ((I = 0) Or (D[I] <> D[I - 1])) And ((Depth > 0) Or (HiReq = 0) Or (D[I] = HiReq)) Then
      Begin
        { doubles : sources dans l'ordre (evite les permutations) }
        Lim := 25;
        If (Roll1 = Roll2) And (LastR > 0) Then Lim := LastR;
        For R := Lim DownTo 1 Do
          If CanMv(B, SearchS, R, D[I]) Then
          Begin
            T := B;
            BHit := DoMv(T, SearchS, R, D[I]);
            DropDie(D, Nd, I);
            PathR[Depth] := R; PathD[Depth] := D[I];
            Any := True;
            Gen(T, Nd, Depth + 1, R);
          End;
      End;
      Inc(I);
    End;
  End;
  If Any Or (Depth < CurMax) Then Exit;
  Inc(NLeaf);
  If Level = 0 Then V := Rnd(1000) Else V := Eval(B, SearchS);
  If V > BestV Then
  Begin
    BestV := V; BestN := Depth;
    For K := 0 To Depth - 1 Do
    Begin
      BestR[K] := PathR[K]; BestD[K] := PathD[K];
    End;
  End;
End;

{ prepare les coups de S (file QR, QD) }
Procedure Think(S : LongInt);
Var K : LongInt;
Begin
  SearchS := S;
  BestV := -Inf; BestN := 0; NLeaf := 0;
  HiReq := HigherRule(Bd, S, Dc, CurMax);
  If CurMax > 0 Then Gen(Bd, Dc, 0, 0);
  NQ := BestN; IQ := 0;
  For K := 0 To NQ - 1 Do
  Begin
    QR[K] := BestR[K]; QD[K] := BestD[K];
  End;
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
{ Plateau                                                               }
{ ==================================================================== }

Function PtX(P : LongInt) : LongInt;
Begin
  If P >= 19 Then PtX := FR + (P - 19) * PtW
  Else If P >= 13 Then PtX := FL + (P - 13) * PtW
  Else If P >= 7 Then PtX := FL + (12 - P) * PtW
  Else PtX := FR + (6 - P) * PtW;
End;

{ pion (blanc ou noir) centre en (X, Y) ; Ring : anneau jaune (choisi) }
Procedure Checker(X, Y, S : LongInt; Ring : Boolean);
Begin
  If Ring Then Disc(X, Y, Rad + 2, CLR_YELLOW)
  Else Disc(X + 1, Y + 1, Rad, CLR_BLACK);
  Disc(X, Y, Rad, CLR_BLACK);
  If S = SH Then
  Begin
    Disc(X, Y, Rad - 1, CLR_PALEGRAY);
    Disc(X - 1, Y - 1, Rad - 3, CLR_WHITE);
    Disc(X, Y, 4, CLR_PALEGRAY);
  End
  Else
  Begin
    Disc(X, Y, Rad - 1, CLR_DARKGRAY);
    Disc(X + 1, Y + 1, Rad - 3, CLR_BLACK);
    Disc(X, Y, 4, CLR_DARKGRAY);
  End;
End;

{ etat affiche d'une case (pour ne redessiner que ce qui change) }
Function DestOf(S, P : LongInt) : Boolean;
Begin
  DestOf := DestA[P] <> 0;
End;

Function PtSig(P : LongInt) : LongInt;
Var F, K : LongInt;
Begin
  F := 0;
  If (Sel > 0) And (Sel <= 24) And (Sel = P) Then F := F Or 2;
  If DestOf(SH, P) Then F := F Or 1;
  For K := 0 To NLast - 1 Do If LastTo[K] = P Then F := F Or 4;
  PtSig := (Bd[P] + 20) * 8 + F;
End;

Procedure DrawPoint(P : LongInt);
Var X, I, W, C, N, K, Y, Cx, S, F, Y1, Y2 : LongInt; T : String;
Begin
  F := PtSig(P) Mod 8;
  X := PtX(P); Cx := X + PtW Div 2;
  If P >= 13 Then
  Begin
    Y1 := FT; Y2 := MidY - 18;
  End
  Else
  Begin
    Y1 := MidY + 19; Y2 := FB;
  End;
  FBar(X, Y1, X + PtW - 1, Y2, CLR_DARKGREEN);
  If P Mod 2 = 0 Then C := CLR_DARKRED Else C := CLR_PALEGRAY;
  For I := 0 To PtH - 1 Do
  Begin
    W := (PtW Div 2 - 1) * (PtH - I) Div PtH;
    If P >= 13 Then Y := FT + I Else Y := FB - I;
    FBar(Cx - W, Y, Cx + W - 1, Y, C);
  End;
  N := Abs(Bd[P]);
  If Bd[P] > 0 Then S := SH Else S := SC;
  For K := 0 To N - 1 Do
    If K < 5 Then
    Begin
      If P >= 13 Then Y := FT + Rad + 1 + K * 27 Else Y := FB - Rad - 1 - K * 27;
      Checker(Cx, Y, S, ((F And 2) <> 0) And ((K = N - 1) Or (K = 4)));
      If (K = 4) And (N > 5) Then
      Begin
        T := IStr(N);
        If S = SH Then OutTxt(Cx - Length(T) * 4, Y - 8, T, CLR_BLACK, CLR_WHITE)
        Else OutTxt(Cx - Length(T) * 4, Y - 8, T, CLR_WHITE, CLR_BLACK);
      End;
    End;
  If P >= 13 Then Y := FT + PtH + 6 Else Y := FB - PtH - 6;
  If (F And 1) <> 0 Then
  Begin
    Disc(Cx, Y, 5, CLR_BLACK);
    Disc(Cx, Y, 4, CLR_YELLOW);
  End
  Else If (F And 4) <> 0 Then Disc(Cx, Y, 3, CLR_CYAN);
End;

Function BarSig : LongInt;
Begin
  If Sel = 25 Then BarSig := Bd[IBarH] * 64 + Bd[IBarC] * 2 + 1
  Else BarSig := Bd[IBarH] * 64 + Bd[IBarC] * 2;
End;

Procedure DrawBar;
Var K, Y, Cx : LongInt;
Begin
  FBar(BarX, FT, BarX + PtW - 1, FB, CLR_BROWN);
  FBar(BarX, FT, BarX, FB, CLR_BLACK);
  FBar(BarX + PtW - 1, FT, BarX + PtW - 1, FB, CLR_BLACK);
  Cx := BarX + PtW Div 2;
  For K := 0 To Bd[IBarH] - 1 Do
    If K < 4 Then
    Begin
      Y := MidY - 20 - K * 27;
      Checker(Cx, Y, SH, (Sel = 25) And (K = Bd[IBarH] - 1));
    End;
  If Bd[IBarH] > 1 Then OutTxt(Cx - 4, MidY - 28, IStr(Bd[IBarH]), CLR_BLACK, CLR_WHITE);
  For K := 0 To Bd[IBarC] - 1 Do
    If K < 4 Then
    Begin
      Y := MidY + 20 + K * 27;
      Checker(Cx, Y, SC, False);
    End;
  If Bd[IBarC] > 1 Then OutTxt(Cx - 4, MidY + 12, IStr(Bd[IBarC]), CLR_WHITE, CLR_BLACK);
End;

Function TraySig : LongInt;
Begin
  If DestOf(SH, 0) Then TraySig := Bd[IOffH] * 64 + Bd[IOffC] * 2 + 1
  Else TraySig := Bd[IOffH] * 64 + Bd[IOffC] * 2;
End;

{ plateau de sortie : pions sortis vus de profil }
Procedure DrawTray;
Var K, Y : LongInt;
Begin
  FBar(TrayX, FT, TrayX + 33, FB, CLR_DARKGREEN);
  FBar(TrayX, MidY - 1, TrayX + 33, MidY, CLR_BROWN);
  For K := 0 To Bd[IOffC] - 1 Do
  Begin
    Y := FT + 2 + K * 8;
    FBar(TrayX + 3, Y, TrayX + 30, Y + 6, CLR_BLACK);
    FBar(TrayX + 4, Y + 1, TrayX + 29, Y + 2, CLR_DARKGRAY);
  End;
  For K := 0 To Bd[IOffH] - 1 Do
  Begin
    Y := FB - 8 - K * 8;
    FBar(TrayX + 3, Y, TrayX + 30, Y + 6, CLR_BLACK);
    FBar(TrayX + 4, Y + 1, TrayX + 29, Y + 5, CLR_WHITE);
    FBar(TrayX + 4, Y + 5, TrayX + 29, Y + 5, CLR_PALEGRAY);
  End;
  If DestOf(SH, 0) Then
  Begin
    Edge(TrayX, MidY + 2, TrayX + 33, FB, CLR_YELLOW, CLR_YELLOW);
    Edge(TrayX + 1, MidY + 3, TrayX + 32, FB - 1, CLR_YELLOW, CLR_YELLOW);
  End;
End;

{ un de (V points) ; Used : deja joue (grise) }
Procedure Die(X, Y, V : LongInt; Used : Boolean);
Var Bg, Fg, C : LongInt;
Begin
  If Used Then
  Begin
    Bg := CLR_PALEGRAY; Fg := CLR_DARKGRAY;
  End
  Else
  Begin
    Bg := CLR_WHITE; Fg := CLR_BLACK;
  End;
  FBar(X + 2, Y + 2, X + 29, Y + 29, CLR_BLACK);
  FBar(X + 1, Y, X + 26, Y + 27, Bg);
  FBar(X, Y + 1, X + 27, Y + 26, Bg);
  Edge(X, Y + 1, X + 27, Y + 26, Bg, CLR_DARKGRAY);
  C := 14;
  If (V = 1) Or (V = 3) Or (V = 5) Then Disc(X + C, Y + C, 2, Fg);
  If V >= 2 Then
  Begin
    Disc(X + C - 7, Y + C - 7, 2, Fg); Disc(X + C + 7, Y + C + 7, 2, Fg);
  End;
  If V >= 4 Then
  Begin
    Disc(X + C + 7, Y + C - 7, 2, Fg); Disc(X + C - 7, Y + C + 7, 2, Fg);
  End;
  If V = 6 Then
  Begin
    Disc(X + C - 7, Y + C, 2, Fg); Disc(X + C + 7, Y + C, 2, Fg);
  End;
End;

Function DiceSig(Half : LongInt) : LongInt;
Var K, V : LongInt;
Begin
  V := Half * 7 + Turn * 3 + Phase + Over * 5;
  V := V * 8 + Roll1; V := V * 8 + Roll2; V := V * 8 + Dc[4];
  For K := 0 To Dc[4] - 1 Do V := V * 8 + Dc[K];
  DiceSig := V;
End;

{ des au milieu de la moitie Half (0 gauche : ordinateur ; 1 droite : vous) }
Procedure DrawDice(Half : LongInt);
Var X0, N, K, X, Y : LongInt; Used : Boolean; S : String;
Begin
  If Half = 0 Then X0 := FL Else X0 := FR;
  FBar(X0, MidY - 17, X0 + 6 * PtW - 1, MidY + 18, CLR_DARKGREEN);
  Y := MidY - 14;
  If (Over <> 0) Or (Turn = 0) Then Exit;
  If (Half = 1) <> (Turn = SH) Then Exit;
  If Phase = 0 Then
  Begin
    If (Turn = SH) And (AutoAll = 0) Then
    Begin
      S := 'Lancez les d' + Chr(130) + 's';
      OutTxt(X0 + (6 * PtW - Length(S) * 8) Div 2, MidY - 8, S, CLR_YELLOW, CLR_DARKGREEN);
    End;
    Exit;
  End;
  If Roll1 = Roll2 Then N := 4 Else N := 2;
  X := X0 + (6 * PtW - N * 36 + 6) Div 2;
  For K := 0 To N - 1 Do
  Begin
    If N = 4 Then Used := K < 4 - Dc[4]
    Else If K = 0 Then Used := DieIx(Dc, Roll1) < 0
    Else Used := DieIx(Dc, Roll2) < 0;
    If (N = 2) And (K = 1) Then Die(X + K * 36, Y, Roll2, Used) Else Die(X + K * 36, Y, Roll1, Used);
  End;
End;

{ cadre en bois avec les numeros des cases (vus des blancs) }
Procedure DrawFrame;
Var P, X : LongInt; S : String;
Begin
  FBar(BdL, BdT, BdR, BdB, CLR_BROWN);
  Edge(BdL, BdT, BdR, BdB, CLR_YELLOW, CLR_BLACK);
  Edge(FL - 1, FT - 1, FL + 6 * PtW, FB + 1, CLR_BLACK, CLR_YELLOW);
  Edge(FR - 1, FT - 1, FR + 6 * PtW, FB + 1, CLR_BLACK, CLR_YELLOW);
  Edge(TrayX - 1, FT - 1, TrayX + 34, FB + 1, CLR_BLACK, CLR_YELLOW);
  For P := 1 To 24 Do
  Begin
    S := IStr(P);
    X := PtX(P) + (PtW - Length(S) * 8) Div 2;
    If P >= 13 Then OutTxt(X, BdT + 1, S, CLR_YELLOW, CLR_BROWN)
    Else OutTxt(X, FB + 1, S, CLR_YELLOW, CLR_BROWN);
  End;
End;

{ ==================================================================== }
{ Panneau                                                               }
{ ==================================================================== }

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

Function CanRoll : Boolean;
Begin
  CanRoll := (Over = 0) And (Turn = SH) And (Phase = 0) And (AutoAll = 0);
End;

Function BoxSig(S : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := Pips(Bd, S) * 32 + Bd[OffIx(S)] * 2;
  If (Turn = S) And (Over = 0) Then Inc(V);
  BoxSig := V;
End;

Procedure PlayerBox(Y, S : LongInt);
Begin
  FBar(PnX, Y, PnX + PW - 1, Y + 54, CLR_WHITE);
  Edge(PnX, Y, PnX + PW - 1, Y + 54, CLR_DARKGRAY, CLR_WHITE);
  If (Turn = S) And (Over = 0) Then
  Begin
    Edge(PnX + 1, Y + 1, PnX + PW - 2, Y + 53, CLR_BLUE, CLR_BLUE);
    Edge(PnX + 2, Y + 2, PnX + PW - 3, Y + 52, CLR_BLUE, CLR_BLUE);
  End;
  Checker(PnX + 20, Y + 27, S, False);
  If S = SH Then OutTxt(PnX + 40, Y + 4, 'Vous', CLR_BLACK, CLR_WHITE)
  Else OutTxt(PnX + 40, Y + 4, 'Ordinateur', CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 40, Y + 20, 'Course : ' + IStr(Pips(Bd, S)), CLR_DARKBLUE, CLR_WHITE);
  OutTxt(PnX + 40, Y + 36, 'Sortis : ' + IStr(Bd[OffIx(S)]), CLR_DARKBLUE, CLR_WHITE);
End;

Function MiscSig : LongInt;
Var V : LongInt;
Begin
  V := WinsH * 1000 + WinsC * 10 + Level * 2;
  If CanRoll Then Inc(V);
  MiscSig := V;
End;

Procedure DrawMisc;
Var S : String;
Begin
  FBar(PnX, 156, PnX + PW - 1, 211, CLR_PALEGRAY);
  OutTxt(PnX, 156, 'Parties gagn' + Chr(130) + 'es', CLR_BLACK, CLR_PALEGRAY);
  S := 'Vous ' + IStr(WinsH) + ' - Ordi ' + IStr(WinsC);
  OutTxt(PnX, 174, S, CLR_DARKBLUE, CLR_PALEGRAY);
  If Level = 0 Then S := 'Niveau : Facile' Else S := 'Niveau : Normal';
  OutTxt(PnX, 194, S, CLR_BLACK, CLR_PALEGRAY);
  Button(PnX, 222, PW, 30, 'Lancer les d' + Chr(130) + 's', CanRoll);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
  LMsg := Msg;
End;

{ redessine tout ce dont l'etat a change }
Procedure SyncAll;
Var P, V : LongInt;
Begin
  For P := 1 To 24 Do
  Begin
    V := PtSig(P);
    If V <> ShownSig[P] Then
    Begin
      DrawPoint(P);
      ShownSig[P] := V;
    End;
  End;
  V := BarSig;
  If V <> ShownSig[25] Then Begin DrawBar; ShownSig[25] := V; End;
  V := TraySig;
  If V <> ShownSig[26] Then Begin DrawTray; ShownSig[26] := V; End;
  V := DiceSig(0);
  If V <> ShownSig[27] Then Begin DrawDice(0); ShownSig[27] := V; End;
  V := DiceSig(1);
  If V <> ShownSig[28] Then Begin DrawDice(1); ShownSig[28] := V; End;
  V := BoxSig(SH);
  If V <> ShownSig[29] Then Begin PlayerBox(32, SH); ShownSig[29] := V; End;
  V := BoxSig(SC);
  If V <> ShownSig[30] Then Begin PlayerBox(94, SC); ShownSig[30] := V; End;
  V := MiscSig;
  If V <> ShownSig[31] Then Begin DrawMisc; ShownSig[31] := V; End;
  If Msg <> LMsg Then DrawStatus;
End;

Procedure Sync;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  SyncAll;
  Dummy := WinReleasePS(Hps);
End;

Procedure PaintAll(H : LongInt);
Var K : LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  DrawFrame;
  FBar(FL, MidY - 17, FL + 6 * PtW - 1, MidY + 18, CLR_DARKGREEN);
  FBar(FR, MidY - 17, FR + 6 * PtW - 1, MidY + 18, CLR_DARKGREEN);
  OutTxt(PnX + (PW - 80) Div 2, 10, 'BACKGAMMON', CLR_DARKBLUE, CLR_PALEGRAY);
  FBar(PnX + (PW - 80) Div 2, 26, PnX + (PW - 80) Div 2 + 79, 26, CLR_DARKBLUE);
  Button(PnX, 258, PW, 30, 'Annuler', True);
  Button(PnX, 294, PW, 30, 'Nouvelle partie', True);
  For K := 0 To 40 Do ShownSig[K] := -1;
  DrawStatus;
  SyncAll;
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
  SetMark(CM_EASY, Level = 0); SetMark(CM_NORMAL, Level = 1);
End;

Function HumanMoving : Boolean;
Begin
  HumanMoving := (Over = 0) And (Turn = SH) And (Phase = 1) And (AutoAll = 0);
End;

{ cases d'arrivee permises du pion choisi (le plus petit de qui y mene) }
Procedure CalcDest;
Var K, V, T : LongInt;
Begin
  For K := 0 To 25 Do DestA[K] := 0;
  If (Sel <= 0) Or Not HumanMoving Then Exit;
  For K := Dc[4] - 1 DownTo 0 Do
  Begin
    V := Dc[K];
    If Legal(Bd, SH, Dc, CurMax, Sel, V) Then
    Begin
      T := Sel - V;
      If T < 0 Then T := 0;
      If DestA[T] = 0 Then DestA[T] := V;
    End;
  End;
End;

Function HasMoves(R : LongInt) : Boolean;
Var K : LongInt;
Begin
  HasMoves := False;
  For K := 0 To Dc[4] - 1 Do
    If Legal(Bd, SH, Dc, CurMax, R, Dc[K]) Then HasMoves := True;
End;

Procedure SetDice(A, B : LongInt);
Begin
  If A >= B Then Begin Roll1 := A; Roll2 := B; End Else Begin Roll1 := B; Roll2 := A; End;
  If A = B Then
  Begin
    Dc[0] := A; Dc[1] := A; Dc[2] := A; Dc[3] := A; Dc[4] := 4;
  End
  Else
  Begin
    Dc[0] := Roll1; Dc[1] := Roll2; Dc[4] := 2;
  End;
  CurMax := MaxUse(Bd, Turn, Dc);
  TurnB := Bd; TurnDc := Dc;
  Phase := 1;
End;

Function DiceText : String;
Begin
  If Roll1 = Roll2 Then DiceText := 'double ' + IStr(Roll1)
  Else DiceText := IStr(Roll1) + ' et ' + IStr(Roll2);
End;

Procedure StartTurn(S : LongInt);
Var K : LongInt;
Begin
  Turn := S; Phase := 0; Sel := 0;
  For K := 0 To 25 Do DestA[K] := 0;
  If (S = SC) Or (AutoAll <> 0) Then Wait := 2
  Else
  Begin
    If CurMax = 0 Then Msg := 'L''ordinateur ne peut pas jouer (' + DiceText + ').'
    Else
    Begin
      Msg := 'L''ordinateur a jou' + Chr(130) + ' ' + DiceText;
      If CpuHit Then Msg := Msg + ' et frapp' + Chr(130) + ' un pion';
      Msg := Msg + '.';
    End;
    Msg := Msg + ' A vous : lancez les d' + Chr(130) + 's.';
  End;
End;

Procedure NewGame;
Var K, A, B : LongInt;
Begin
  For K := 0 To 28 Do Bd[K] := 0;
  Bd[24] := 2; Bd[13] := 5; Bd[8] := 3; Bd[6] := 5;
  Bd[1] := -2; Bd[12] := -5; Bd[17] := -3; Bd[19] := -5;
  Over := 0; Sel := 0; NLast := 0; Wait := 0; NQ := 0; IQ := 0;
  For K := 0 To 25 Do DestA[K] := 0;
  { lancer d'ouverture : un de chacun, le plus fort commence avec les deux }
  Repeat
    A := 1 + Rnd(6); B := 1 + Rnd(6);
  Until A <> B;
  Msg := 'Ouverture : vous ' + IStr(A) + ', ordinateur ' + IStr(B) + '. ';
  If A > B Then
  Begin
    Turn := SH;
    SetDice(A, B);
    If AutoAll = 0 Then
      Msg := Msg + 'Vous commencez : cliquez un pion blanc.'
    Else
    Begin
      Think(SH);
      Wait := 2;
    End;
  End
  Else
  Begin
    Turn := SC;
    SetDice(A, B);
    Msg := Msg + 'L''ordinateur commence.';
    Think(SC);
    Wait := 3;
  End;
  Redraw;
End;

Procedure GameOver(S : LongInt);
Var L, Pts, R : LongInt; T : String;
Begin
  Over := 1; Sel := 0;
  L := Opp(S);
  Pts := 1;
  If Bd[OffIx(L)] = 0 Then
  Begin
    Pts := 2;
    If Bd[BarIx(L)] > 0 Then Pts := 3;
    For R := 19 To 24 Do If Own(Bd, L, R) > 0 Then Pts := 3;
  End;
  If S = SH Then WinsH := WinsH + Pts Else WinsC := WinsC + Pts;
  If S = SH Then T := 'Vous gagnez' Else T := 'L''ordinateur gagne';
  If Pts = 2 Then T := T + ' par gammon (2 points)'
  Else If Pts = 3 Then T := T + ' par backgammon (3 points)'
  Else T := T + ' (1 point)';
  Msg := T + ' !  F2 : nouvelle partie.';
  Wait := 0;
  Sync;
  If AutoAll = 0 Then
    If Ask(T + ' !' + Chr(10) + 'Parties : vous ' + IStr(WinsH) + ', l''ordinateur ' + IStr(WinsC) + '.' +
           Chr(10) + Chr(10) + 'Une nouvelle partie ?', 'Backgammon', MB_YESNO Or MB_QUERY) = MBID_YES Then
      NewGame;
End;

Procedure HumanRoll;
Begin
  If Not CanRoll Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  SetDice(1 + Rnd(6), 1 + Rnd(6));
  If CurMax = 0 Then
  Begin
    Msg := 'Vous avez obtenu ' + DiceText + ' : aucun coup possible, vous passez votre tour.';
    Phase := 2; Wait := 5;
  End
  Else
  Begin
    Msg := 'Vous avez obtenu ' + DiceText + ' : cliquez un pion blanc, puis sa case d''arriv' + Chr(130) + 'e.';
    If Bd[IBarH] > 0 Then
    Begin
      Sel := 25;
      Msg := 'Vous avez obtenu ' + DiceText + ' : entrez d''abord votre pion de la barre.';
    End;
    CalcDest;
  End;
  Sync;
End;

Procedure HumanMove(R, V : LongInt);
Var I : LongInt;
Begin
  If Not Legal(Bd, SH, Dc, CurMax, R, V) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  BHit := DoMv(Bd, SH, R, V);
  I := DieIx(Dc, V);
  DropDie(Dc, Dc, I);
  Dec(CurMax);
  Sel := 0;
  If R = 25 Then Msg := 'Pion entr' + Chr(130) + ' en ' + IStr(R - V) + '.'
  Else If R - V <= 0 Then Msg := 'Pion sorti.'
  Else Msg := 'Pion jou' + Chr(130) + ' de ' + IStr(R) + ' ' + Chr(133) + ' ' + IStr(R - V) + '.';
  If BHit Then Msg := 'Pion noir frapp' + Chr(130) + ' en ' + IStr(R - V) + ' !';
  If Bd[IOffH] = 15 Then
  Begin
    GameOver(SH);
    Exit;
  End;
  If (Dc[4] = 0) Or (CurMax <= 0) Then
  Begin
    Phase := 2; Wait := 3;
    Msg := Msg + ' Fin de votre tour (Ctrl+Z : annuler).';
  End
  Else If Bd[IBarH] > 0 Then Sel := 25;
  CalcDest;
  Sync;
End;

Procedure Undo;
Begin
  If (Over <> 0) Or (Turn <> SH) Or (Phase = 0) Or (AutoAll <> 0) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  Bd := TurnB; Dc := TurnDc;
  CurMax := MaxUse(Bd, SH, Dc);
  Phase := 1; Wait := 0; Sel := 0;
  If Bd[IBarH] > 0 Then Sel := 25;
  CalcDest;
  Msg := 'Pions du tour remis en place : rejouez ' + DiceText + '.';
  Sync;
End;

{ un pas de l'ordinateur (ou des deux joueurs en /AUTO) }
Procedure CpuStep;
Var R, V, T : LongInt; Who : String;
Begin
  If Turn = SC Then Who := 'L''ordinateur' Else Who := 'Les blancs';
  If Phase = 0 Then
  Begin
    SetDice(1 + Rnd(6), 1 + Rnd(6));
    If Turn = SC Then
    Begin
      NLast := 0; CpuHit := False;
    End;
    If CurMax = 0 Then
    Begin
      Msg := Who + ' a obtenu ' + DiceText + ' et ne peut pas jouer.';
      Phase := 2; Wait := 4;
    End
    Else
    Begin
      Msg := Who + ' a obtenu ' + DiceText + '.';
      Think(Turn);
      Wait := 2;
    End;
    Exit;
  End;
  If Phase = 1 Then
  Begin
    If IQ < NQ Then
    Begin
      R := QR[IQ]; V := QD[IQ];
      Inc(IQ);
      If Not CanMv(Bd, Turn, R, V) Then Exit;
      BHit := DoMv(Bd, Turn, R, V);
      DropDie(Dc, Dc, DieIx(Dc, V));
      T := R - V;
      If (Turn = SC) And (T >= 1) And (NLast < 4) Then
      Begin
        LastTo[NLast] := Act(SC, T);
        Inc(NLast);
      End;
      If BHit Then
      Begin
        CpuHit := Turn = SC;
        If Turn = SC Then Msg := 'L''ordinateur frappe votre pion : il va sur la barre !'
        Else Msg := 'Les blancs frappent un pion noir !';
      End;
      If Bd[OffIx(Turn)] = 15 Then
      Begin
        GameOver(Turn);
        Exit;
      End;
      Wait := 1;
    End;
    If IQ >= NQ Then
    Begin
      Phase := 2; Wait := 2;
    End;
    Exit;
  End;
  StartTurn(Opp(Turn));
End;

Procedure TimerTick;
Begin
  If Over <> 0 Then
  Begin
    If AutoAll <> 0 Then
    Begin
      Inc(Wait);
      If Wait > 8 Then NewGame;
    End;
    Exit;
  End;
  If Wait > 0 Then
  Begin
    Dec(Wait);
    Exit;
  End;
  If (Turn = SC) Or (AutoAll <> 0) Then CpuStep
  Else If Phase = 2 Then StartTurn(SC);
  Sync;
End;

Procedure SetLevel(L : LongInt);
Begin
  Level := L;
  SetMarks;
  Sync;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : Undo;
    CM_ROLL : HumanRoll;
    CM_EASY : SetLevel(0);
    CM_NORMAL : SetLevel(1);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Dummy := Ask('Vous avez les pions blancs et les menez de la case 24 vers votre jan ' +
                            'int' + Chr(130) + 'rieur (cases 1 ' + Chr(133) + ' 6, en bas ' + Chr(133) +
                            ' droite), puis les sortez. Chaque d' + Chr(130) + ' fait avancer un pion ' +
                            'd''autant de cases (un double se joue quatre fois) ; il faut jouer le plus de ' +
                            'd' + Chr(130) + 's possible. On ne peut pas aller sur une case tenue par deux ' +
                            'pions adverses ou plus ; un pion adverse seul est frapp' + Chr(130) +
                            ' et va sur la barre, d''o' + Chr(151) + ' il doit rentrer avant tout autre coup. ' +
                            'On sort ses pions quand ils sont tous dans le jan int' + Chr(130) + 'rieur. ' +
                            'Le premier ' + Chr(133) + ' tout sortir gagne (gammon, backgammon : 2 ou 3 points).' +
                            Chr(10) + Chr(10) +
                            'Souris : Lancer les d' + Chr(130) + 's, puis un pion blanc et sa case ' +
                            'd''arriv' + Chr(130) + 'e (point jaune). Clavier : Espace (lancer), ' +
                            'Ctrl+Z (annuler le tour), ' + Chr(144) + 'chap, F2 (nouvelle partie).',
                            'Backgammon - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    CM_ABOUT : Dummy := Ask('Backgammon pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du ' +
                            'prototype BACKGAM.PAS de 7iles, avec les r' + Chr(138) + 'gles compl' + Chr(138) +
                            'tes et un adversaire qui ' + Chr(130) + 'value toutes ses suites de coups.' +
                            Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) +
                            ' par OS2PC.', 'A propos de Backgammon', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

{ case visee : 1..24, 25 (barre), 0 (sortie), -1 (rien) }
Function Target(X, Y : LongInt) : LongInt;
Var C : LongInt;
Begin
  Target := -1;
  If (Y < FT) Or (Y > FB) Then Exit;
  If (X >= BarX) And (X < BarX + PtW) Then Begin Target := 25; Exit; End;
  If (X >= TrayX) And (X < TrayX + 34) Then Begin Target := 0; Exit; End;
  If (X >= FL) And (X < FL + 6 * PtW) Then
  Begin
    C := (X - FL) Div PtW;
    If Y < MidY Then Target := 13 + C Else Target := 12 - C;
  End;
  If (X >= FR) And (X < FR + 6 * PtW) Then
  Begin
    C := (X - FR) Div PtW;
    If Y < MidY Then Target := 19 + C Else Target := 6 - C;
  End;
End;

Procedure BoardClick(T : LongInt);
Begin
  If CanRoll Then
  Begin
    HumanRoll;
    Exit;
  End;
  If Not HumanMoving Then Exit;
  If T < 0 Then Exit;
  If (Sel > 0) And (T = Sel) Then
  Begin
    Sel := 0;
    CalcDest;
    Sync;
    Exit;
  End;
  If (Sel > 0) And (T <= 24) And (DestA[T] <> 0) Then
  Begin
    HumanMove(Sel, DestA[T]);
    Exit;
  End;
  If (T >= 1) And (Own(Bd, SH, T) > 0) Then
  Begin
    If (Bd[IBarH] > 0) And (T <> 25) Then
    Begin
      Dummy := WinAlarm(HWND_DESKTOP, 0);
      Msg := 'Entrez d''abord votre pion de la barre.';
      Sel := 25;
    End
    Else If HasMoves(T) Then
    Begin
      Sel := T;
      Msg := 'Cliquez la case d''arriv' + Chr(130) + 'e (point jaune) ou la sortie.';
    End
    Else
    Begin
      Dummy := WinAlarm(HWND_DESKTOP, 0);
      Msg := 'Ce pion ne peut pas jouer avec ces d' + Chr(130) + 's.';
    End;
    CalcDest;
    Sync;
    Exit;
  End;
  Dummy := WinAlarm(HWND_DESKTOP, 0);
End;

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= BdL) And (X <= BdR) And (Y >= BdT) And (Y <= BdB) Then
  Begin
    BoardClick(Target(X, Y));
    Exit;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 222) And (Y < 252) Then HumanRoll
    Else If (Y >= 258) And (Y < 288) Then Undo
    Else If (Y >= 294) And (Y < 324) Then NewGame;
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
  If (Fl And KC_CTRL) <> 0 Then
  Begin
    If (Ch = 26) Or (Ch = Ord('z')) Or (Ch = Ord('Z')) Then Undo Else KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin HumanRoll; Exit; End;
    If Vk = VK_ESC Then
    Begin
      If (Sel > 0) And (Bd[IBarH] = 0) Then Sel := 0;
      CalcDest;
      Sync;
      Exit;
    End;
  End;
  If ((Fl And KC_CHAR) <> 0) And ((Fl And KC_ALT) = 0) And (Ch = 32) Then
  Begin
    HumanRoll;
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
  FcF, H0, H1, H2, ScrW, ScrH, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LMsg := ''; AutoAll := 0; Level := 1; WinsH := 0; WinsC := 0; Turn := 0; Over := 0;
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
  Dummy := WinRegisterClass(Hab, Z('BACKGAM'), LongInt(@MainProc), 0, 0);
  FcF := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@FcF), Z('BACKGAM'), Z2('Backgammon'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_ROLL, '~Lancer les d' + Chr(130) + 's' + Chr(9) + 'Espace');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le tour' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_EASY, '~Facile');
  MItem(MIS_TEXT, MIA_CHECKED, CM_NORMAL, 'N~ormal');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 8);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Backgammon');
  MenuClose(H2, 2);
  MenuClose(H0, 2);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CWant; Rc[3] := CHWant;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (ScrW - Fw) Div 2; Y := (ScrH - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := ScrH - Fh;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  SetMarks;
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 450);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
