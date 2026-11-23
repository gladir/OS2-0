{ @author: Sylvain Maltais (support@gladir.com)
  @created: 1992 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: PATIENCE - La Patience, jeu de cartes en solitaire pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program PATIENCE;

{$R-,S-,I-}

{ Compilation : OS2PC PATIENCE.PAS   (produit PATIENCE.EXE)

  Portage vers OS/2-0 du prototype PATIENCE.PAS du depot 7iles (Turbo
  Pascal, mode texte de 80 colonnes, cartes en caracteres, clavier
  seulement) : fenetre de Presentation Manager avec menus, tapis de
  feutre en degrade dans une image en memoire recopiee par GpiDrawBits
  (seules les zones qui changent sont recopiees), cartes dessinees (coins
  arrondis, ombre, index et enseignes, points disposes comme sur les
  vraies cartes, Valets, Dames et Rois en portraits, dos bordeaux a
  treillis dore et rosace), cartes qui glissent vers leur place, tableau
  des rangees, barre d'etat et apparence d'OS/2 Warp 3.

  Le jeu (comme le prototype) : une carte retournee au depart donne le
  rang de base ; quatre reserves de trois cartes (seule celle du dessus
  se joue) ; la pioche de 39 cartes se retourne trois par trois sur la
  defausse, autant de fois qu'on le veut. Le tableau compte quatre
  rangees, une par couleur : une rangee commence par une carte du rang
  de base, la carte de depart ouvrant la premiere ; une carte va dans la
  rangee de sa couleur, la premiere rangee la recoit toujours, les
  suivantes seulement si la rangee du dessus contient deja ce rang. Il
  faut placer les 52 cartes.
  Ce qui est corrige : les cartes s'empilaient dans l'ordre d'arrivee
  (elles sont maintenant rangees par colonnes de rang a partir du rang
  de base) ; la defausse s'effacait mal quand il restait moins de trois
  cartes ; la partie bloquee n'etait jamais detectee ; la victoire etait
  annoncee sans attendre (et le programme s'arretait) ; aucune
  annulation, aucun moyen de recommencer.
  Ce qui s'ajoute : souris, detection d'une partie sans issue, annulation
  sans limite, indice, recommencer la meme donne, pioche une carte a la
  fois (plus facile), demonstration, statistiques de la seance,
  bruitages.

  Souris : cliquer une reserve, la defausse (pour placer sa carte) ou la
  pioche (pour retourner des cartes). Clavier (comme le prototype) : 1 a
  4 (reserves), 5 (retourner la pioche), 6 (placer la carte de la
  defausse) ; Espace (pioche), U ou Retour arriere (annuler), I (indice),
  R (recommencer la donne), F2 (nouvelle donne), F1 (regles).
  Parametres : /SEED:n ; /DRAW:1 (une carte a la fois) ; /AUTO
  (demonstration) ; /NOSOUND ; /TEST (essais de la donne et des regles,
  puis donnes jouees par l'ordinateur sans fenetre, resultat sur le port
  serie COM1). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_SPACE = $10; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_RESTART = 102; CM_UNDO = 103; CM_HINT = 104; CM_DEAL = 105; CM_QUIT = 106;
  CM_DRAW3 = 201; CM_DRAW1 = 202; CM_AUTO = 203; CM_SOUND = 204;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : tapis de 464 x 400 }
  BW = 464; BH = 400; OX = 8; OY = 8;
  PnX = 484; PW = 132;
  CWant = 624; CHWant = 436;
  { cartes (0..51 : couleur = C div 13 : coeur, carreau, trefle, pique ;
    rang = C mod 13 : As .. Roi) }
  KW = 46; KH = 64;
  ResX = 14; GridX = 74; GridStep = 28; RowY0 = 12; RowStep = 78;
  StockX = 74; WasteX = 146; BotY = 326; FanStep = 18;
  NStock = 39; MaxUndo = 400; SnapSz = 128;
  { emplacements : 0..3 reserves, 4 pioche, 5 defausse, 10 + rangee * 13 + colonne : tableau }
  SL_STOCK = 4; SL_WASTE = 5; SL_GRID = 10;
  { couleurs de l'image }
  C_FELT = 0;                                  { 0..15 : tapis (sombre -> clair) }
  C_CARD = 16; C_CARDE = 17; C_BORDER = 18; C_RED = 19; C_BLACK = 20; C_BACK1 = 21; C_BACK2 = 22;
  C_GOLD = 23; C_HILITE = 24; C_SHADOW = 25; C_SLOT = 26; C_SLOTE = 27; C_WHITE = 28; C_TEXT = 29;
  C_BANNER = 30; C_BANNERE = 31; C_YELLOW = 32; C_GREEN = 33; C_SKIN = 34; C_HAIR = 35; C_ROBER = 36;
  C_ROBEB = 37; C_FACE = 38; C_GOLDD = 39; C_GRAY = 40; C_TEXTD = 41;
  { etats }
  G_PLAY = 0; G_WON = 1; G_LOST = 2;
  SndRate = 11025;

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { partie }
  ResC : Array[0..11] Of LongInt;               { reserves : pile P, carte K (0 : dessous) }
  ResN : Array[0..3] Of LongInt;
  RowS : Array[0..3] Of LongInt;                { couleur de chaque rangee (-1 : vide) }
  Grid : Array[0..51] Of LongInt;               { rangee * 13 + colonne (rang depuis la base) }
  Stk : Array[0..NStock - 1] Of LongInt;        { 0..Pos-1 : defausse ; Pos..StkN-1 : pioche }
  StkN, Pos, Passes, Base, Placed, State, DrawN, DealSeed, Seed, SoundOn, TestMode, AutoAll, Tick, Wait : LongInt;
  Games, Wins, BestPlaced, HintSl, Moves : LongInt;
  Snap : Array[0..MaxUndo * SnapSz - 1] Of Byte;
  NSnap : LongInt;
  { carte qui glisse }
  FlyOn, FlyC, FlyX0, FlyY0, FlyX1, FlyY1, FlyK, FlyN, FlySl : LongInt;
  DX1, DY1, DX2, DY2, FullBlit : LongInt;
  Banner, Banner2, Banner3, Msg, LastMsg : String;
  BannerC, LastSig : LongInt;
  SndBuf : Array[0..29999] Of Byte;
  SndOfs, SndLen, SndPri : Array[0..15] Of LongInt;
  NSndBuf, SndPrio, SndCur, SndEnd : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  Shade : Array[0..255] Of Byte;

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
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function VioGetFont(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMPLAY';

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

Procedure WrL(A, V : LongInt);
Begin
  WrW(A, V And $FFFF);
  WrW(A + 2, (V Shr 16) And $FFFF);
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

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Inc(InDlg);
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
  Dec(InDlg);
End;

{ journal : port serie COM1 (mode /TEST) }
Procedure Log(S : String);
Var I, C : LongInt;
Begin
  S := S + Chr(13) + Chr(10);
  For I := 1 To Length(S) Do
  Begin
    C := Ord(S[I]);
    asm
      mov dx,3FDh
      mov ecx,100000
    @w:
      in al,dx
      test al,20h
      jnz @ok
      dec ecx
      jnz @w
    @ok:
      mov dx,3F8h
      mov eax,C
      out dx,al
    end;
  End;
End;

{ messages de plus de 255 caracteres : texte cumule dans LBuf }
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
  Inc(InDlg);
  LMsgBox := WinMessageBox(HWND_DESKTOP, Frame, LongInt(@LBuf), Z2(Cap), 0, Fl Or MB_MOVEABLE);
  Dec(InDlg);
End;

{ ==================================================================== }
{ Cartes et regles                                                      }
{ ==================================================================== }

Function Rank(C : LongInt) : LongInt;
Begin
  Rank := C Mod 13;
End;

Function SuitOf(C : LongInt) : LongInt;
Begin
  SuitOf := C Div 13;
End;

Function IsRed(C : LongInt) : Boolean;
Begin
  IsRed := (C Div 13) <= 1;
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

Function SuitName(Su : LongInt) : String;
Begin
  Case Su Of
    0 : SuitName := 'coeur';
    1 : SuitName := 'carreau';
    2 : SuitName := 'tr' + Chr(138) + 'fle';
  Else
    SuitName := 'pique';
  End;
End;

Function RankLong(R : LongInt) : String;
Begin
  Case R Of
    0 : RankLong := 'As';
    10 : RankLong := 'Valet';
    11 : RankLong := 'Dame';
    12 : RankLong := 'Roi';
  Else
    RankLong := IStr(R + 1);
  End;
End;

Function CardName(C : LongInt) : String;
Begin
  CardName := RankLong(Rank(C)) + ' de ' + SuitName(SuitOf(C));
End;

{ colonne d'une carte dans sa rangee : rang compte depuis le rang de base }
Function ColOf(C : LongInt) : LongInt;
Begin
  ColOf := (Rank(C) - Base + 13) Mod 13;
End;

{ rangee qui peut recevoir la carte C (-1 : aucune) }
Function CanPlace(C : LongInt) : LongInt;
Var J, R : LongInt;
Begin
  R := -1;
  If C < 0 Then
  Begin
    CanPlace := -1;
    Exit;
  End;
  If Rank(C) = Base Then
  Begin
    { carte du rang de base : ouvre la premiere rangee libre }
    For J := 3 Downto 0 Do
      If RowS[J] < 0 Then R := J;
  End
  Else
    For J := 0 To 3 Do
      If RowS[J] = SuitOf(C) Then
      Begin
        R := J;
        { rangees suivantes : le rang doit deja etre dans la rangee du dessus }
        If J > 0 Then
          If Grid[(J - 1) * 13 + ColOf(C)] < 0 Then R := -1;
      End;
  CanPlace := R;
End;

Function ResTop(P : LongInt) : LongInt;
Begin
  If ResN[P] > 0 Then ResTop := ResC[P * 3 + ResN[P] - 1] Else ResTop := -1;
End;

Function WasteTop : LongInt;
Begin
  If Pos > 0 Then WasteTop := Stk[Pos - 1] Else WasteTop := -1;
End;

{ plus aucune carte ne pourra etre placee : ni les reserves, ni aucune des
  cartes que la pioche montrera (de la position courante a la fin, puis
  depuis le debut apres l'avoir retournee) }
Function Blocked : Boolean;
Var P, K, R : LongInt; B : Boolean;
Begin
  B := True;
  For P := 0 To 3 Do
    If CanPlace(ResTop(P)) >= 0 Then B := False;
  If CanPlace(WasteTop) >= 0 Then B := False;
  K := Pos;
  While B And (K < StkN) Do
  Begin
    K := MinI(K + DrawN, StkN);
    If CanPlace(Stk[K - 1]) >= 0 Then B := False;
  End;
  K := 0;
  While B And (K < StkN) Do
  Begin
    K := MinI(K + DrawN, StkN);
    If CanPlace(Stk[K - 1]) >= 0 Then B := False;
  End;
  R := Ord(B);
  Blocked := R <> 0;
End;

{ donne : 4 reserves de 3 cartes, la carte de base, la pioche de 39 }
Procedure Deal(Sd : LongInt);
Var D : Array[0..51] Of LongInt; K, J, T : LongInt;
Begin
  Seed := Sd;
  For K := 0 To 51 Do D[K] := K;
  For K := 51 Downto 1 Do
  Begin
    J := Rnd(K + 1);
    T := D[K]; D[K] := D[J]; D[J] := T;
  End;
  For K := 0 To 11 Do ResC[K] := D[K];
  For K := 0 To 3 Do ResN[K] := 3;
  For K := 0 To 51 Do Grid[K] := -1;
  For K := 0 To 3 Do RowS[K] := -1;
  Base := Rank(D[12]);
  RowS[0] := SuitOf(D[12]); Grid[0] := D[12];
  Placed := 1;
  For K := 0 To NStock - 1 Do Stk[K] := D[13 + K];
  StkN := NStock; Pos := 0; Passes := 0; Moves := 0;
  State := G_PLAY;
End;

{ place la carte C dans sa rangee J }
Procedure PutGrid(C, J : LongInt);
Begin
  If RowS[J] < 0 Then RowS[J] := SuitOf(C);
  Grid[J * 13 + ColOf(C)] := C;
  Inc(Placed);
End;

{ joue la carte du dessus de l'emplacement S (reserve 0..3 ou defausse) ;
  rend la rangee (-1 : refuse) }
Function PlayFrom(S : LongInt) : LongInt;
Var C, J, K : LongInt;
Begin
  If S < 4 Then C := ResTop(S) Else C := WasteTop;
  J := CanPlace(C);
  If J >= 0 Then
  Begin
    If S < 4 Then Dec(ResN[S])
    Else
    Begin
      For K := Pos - 1 To StkN - 2 Do Stk[K] := Stk[K + 1];
      Dec(StkN); Dec(Pos);
    End;
    PutGrid(C, J);
    Inc(Moves);
  End;
  PlayFrom := J;
End;

{ retourne des cartes de la pioche (ou la remet en place quand elle est vide) }
Procedure TurnStock;
Begin
  If StkN = 0 Then Exit;
  If Pos >= StkN Then
  Begin
    Pos := 0;
    Inc(Passes);
  End
  Else Pos := MinI(Pos + DrawN, StkN);
  Inc(Moves);
End;

{ ==================================================================== }
{ Annulation : etat complet copie avant chaque coup                     }
{ ==================================================================== }

Procedure SaveSnap;
Var A, K : LongInt;
Begin
  If NSnap >= MaxUndo Then
  Begin
    Move(Snap[SnapSz], Snap[0], (MaxUndo - 1) * SnapSz);
    Dec(NSnap);
  End;
  A := NSnap * SnapSz;
  For K := 0 To 11 Do Snap[A + K] := ResC[K] + 1;
  For K := 0 To 3 Do Snap[A + 12 + K] := ResN[K];
  For K := 0 To 3 Do Snap[A + 16 + K] := RowS[K] + 1;
  For K := 0 To 51 Do Snap[A + 20 + K] := Grid[K] + 1;
  For K := 0 To NStock - 1 Do Snap[A + 72 + K] := Stk[K] + 1;
  Snap[A + 111] := StkN; Snap[A + 112] := Pos; Snap[A + 113] := MinI(Passes, 255); Snap[A + 114] := Placed;
  Snap[A + 115] := MinI(Moves, 255);
  Inc(NSnap);
End;

Procedure LoadSnap;
Var A, K : LongInt;
Begin
  If NSnap = 0 Then Exit;
  Dec(NSnap);
  A := NSnap * SnapSz;
  For K := 0 To 11 Do ResC[K] := Snap[A + K] - 1;
  For K := 0 To 3 Do ResN[K] := Snap[A + 12 + K];
  For K := 0 To 3 Do RowS[K] := Snap[A + 16 + K] - 1;
  For K := 0 To 51 Do Grid[K] := Snap[A + 20 + K] - 1;
  For K := 0 To NStock - 1 Do Stk[K] := Snap[A + 72 + K] - 1;
  StkN := Snap[A + 111]; Pos := Snap[A + 112]; Passes := Snap[A + 113]; Placed := Snap[A + 114];
  Moves := Snap[A + 115];
End;

{ ==================================================================== }
{ Dessin dans la fenetre (panneau, barre d'etat)                        }
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

{ ==================================================================== }
{ Image en memoire (8 bits, palette en vraies couleurs)                 }
{ ==================================================================== }

Procedure SetPal(I, C : LongInt);
Var A : LongInt;
Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, C And 255); WrB(A + 1, (C Shr 8) And 255); WrB(A + 2, (C Shr 16) And 255);
End;

Function Mix(C1, C2, N, D : LongInt) : LongInt;
Var R, G, B : LongInt;
Begin
  R := ((C1 Shr 16) And 255) + (((C2 Shr 16) And 255) - ((C1 Shr 16) And 255)) * N Div D;
  G := ((C1 Shr 8) And 255) + (((C2 Shr 8) And 255) - ((C1 Shr 8) And 255)) * N Div D;
  B := (C1 And 255) + ((C2 And 255) - (C1 And 255)) * N Div D;
  Mix := (R Shl 16) Or (G Shl 8) Or B;
End;

Procedure InitBmi;
Var I : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  { tapis : vert bleute sombre (bords) vers clair (centre) }
  For I := 0 To 15 Do SetPal(C_FELT + I, Mix($0A3A30, $2C8C6C, I, 15));
  SetPal(C_CARD, $FFFFFC); SetPal(C_CARDE, $E4E2D8); SetPal(C_BORDER, $3A3A3A); SetPal(C_RED, $CC1820);
  SetPal(C_BLACK, $141414); SetPal(C_BACK1, $6A1020); SetPal(C_BACK2, $C8962C); SetPal(C_GOLD, $E8B830);
  SetPal(C_HILITE, $FFE040); SetPal(C_SHADOW, $04201A); SetPal(C_SLOT, $0E4A3C); SetPal(C_SLOTE, $5CA88C);
  SetPal(C_WHITE, $FFFFFF); SetPal(C_TEXT, $E4F4EC); SetPal(C_BANNER, $0A3028); SetPal(C_BANNERE, $A8E8C8);
  SetPal(C_YELLOW, $FFDC46); SetPal(C_GREEN, $78F0A0); SetPal(C_SKIN, $F8D0A8); SetPal(C_HAIR, $7A4A1C);
  SetPal(C_ROBER, $C02028); SetPal(C_ROBEB, $203C9C); SetPal(C_FACE, $FFF6DC); SetPal(C_GOLDD, $9C7010);
  SetPal(C_GRAY, $9A9A9A); SetPal(C_TEXTD, $9CCCB8);
  For I := 0 To 255 Do Shade[I] := C_SHADOW;
End;

Procedure Pix(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Fb[(BH - 1 - Y) * BW + X] := C;
End;

Procedure Rect(X1, Y1, X2, Y2, C : LongInt);
Var X, Y, B : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := X1 To X2 Do Fb[B + X] := C;
  End;
End;

Procedure Disc(Cx, Cy, R, C : LongInt);
Var Dy, W : LongInt;
Begin
  For Dy := -R To R Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) + Dy * Dy <= R * R + R Do Inc(W);
    Rect(Cx - W, Cy + Dy, Cx + W, Cy + Dy, C);
  End;
End;

{ anneau de rayon R1 a R2 }
Procedure Ring(Cx, Cy, R1, R2, C : LongInt);
Var X, Y, D2 : LongInt;
Begin
  For Y := -R2 To R2 Do
    For X := -R2 To R2 Do
    Begin
      D2 := X * X + Y * Y;
      If (D2 <= R2 * R2 + R2) And (D2 > R1 * R1 - R1) Then Pix(Cx + X, Cy + Y, C);
    End;
End;

{ assombrit un disque (ombre) }
Procedure ShadeDisc(Cx, Cy, R : LongInt);
Var X, Y, A : LongInt;
Begin
  For Y := -R To R Do
    For X := -R To R Do
      If X * X + Y * Y <= R * R + R Then
        If (Cx + X >= 0) And (Cx + X < BW) And (Cy + Y >= 0) And (Cy + Y < BH) Then
        Begin
          A := (BH - 1 - (Cy + Y)) * BW + Cx + X;
          Fb[A] := Shade[Fb[A]];
        End;
End;

{ trait d'une epaisseur de T + 1 points }
Procedure TLine(X1, Y1, X2, Y2, T, C : LongInt);
Var N, K, Dx, Dy, X, Y : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  N := AbsI(Dx);
  If AbsI(Dy) > N Then N := AbsI(Dy);
  If N = 0 Then N := 1;
  For K := 0 To N Do
  Begin
    X := X1 + (Dx * K) Div N; Y := Y1 + (Dy * K) Div N;
    Rect(X, Y, X + T, Y + T, C);
  End;
End;

{ texte dans l'image (police 8 x FontH du VGA ; Sc : 1 ou 2) }
Procedure FbText(X, Y : LongInt; S : String; C, Sc : LongInt);
Var I, R, K, B : LongInt;
Begin
  If FontH = 0 Then Exit;
  For I := 1 To Length(S) Do
    For R := 0 To FontH - 1 Do
    Begin
      B := Font[Ord(S[I]) * FontH + R];
      For K := 0 To 7 Do
        If (B And ($80 Shr K)) <> 0 Then
        Begin
          If Sc = 1 Then Pix(X + (I - 1) * 8 + K, Y + R, C)
          Else Rect(X + (I - 1) * 16 + K * 2, Y + R * 2, X + (I - 1) * 16 + K * 2 + 1, Y + R * 2 + 1, C);
        End;
    End;
End;

Procedure FbTextSh(X, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(X + Sc, Y + Sc, S, C_SHADOW, Sc);
  FbText(X, Y, S, C, Sc);
End;

{ ==================================================================== }
{ Dessin des cartes                                                     }
{ ==================================================================== }

{ rectangle aux coins arrondis (rayon 3) }
Procedure RRect(X1, Y1, X2, Y2, C : LongInt);
Begin
  Rect(X1 + 3, Y1, X2 - 3, Y2, C);
  Rect(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, C);
  Rect(X1, Y1 + 3, X2, Y2 - 3, C);
End;

{ contour arrondi ; Th : 1 fin, 2 epais }
Procedure Outline(X, Y, C, Th : LongInt);
Begin
  Rect(X + 3, Y, X + KW - 4, Y, C); Rect(X + 3, Y + KH - 1, X + KW - 4, Y + KH - 1, C);
  Rect(X, Y + 3, X, Y + KH - 4, C); Rect(X + KW - 1, Y + 3, X + KW - 1, Y + KH - 4, C);
  Pix(X + 1, Y + 2, C); Pix(X + 2, Y + 1, C); Pix(X + KW - 2, Y + 2, C); Pix(X + KW - 3, Y + 1, C);
  Pix(X + 1, Y + KH - 3, C); Pix(X + 2, Y + KH - 2, C); Pix(X + KW - 2, Y + KH - 3, C); Pix(X + KW - 3, Y + KH - 2, C);
  If Th > 1 Then
  Begin
    Rect(X + 2, Y - 2, X + KW - 3, Y - 1, C); Rect(X + 2, Y + KH, X + KW - 3, Y + KH + 1, C);
    Rect(X - 2, Y + 2, X - 1, Y + KH - 3, C); Rect(X + KW, Y + 2, X + KW + 1, Y + KH - 3, C);
    Rect(X - 1, Y - 1, X + 1, Y + 1, C); Rect(X + KW - 2, Y - 1, X + KW, Y + 1, C);
    Rect(X - 1, Y + KH - 2, X + 1, Y + KH, C); Rect(X + KW - 2, Y + KH - 2, X + KW, Y + KH, C);
  End;
End;

{ triangle plein, sommet en haut (Down : en bas) }
Procedure Tri(Cx, Y1, Y2, W, C : LongInt; Down : Boolean);
Var Y, H, Hw : LongInt;
Begin
  H := Y2 - Y1;
  If H <= 0 Then Exit;
  For Y := Y1 To Y2 Do
  Begin
    If Down Then Hw := W * (Y2 - Y) Div H Else Hw := W * (Y - Y1) Div H;
    Rect(Cx - Hw, Y, Cx + Hw, Y, C);
  End;
End;

{ enseigne centree en (Cx, Cy), demi-hauteur S }
Procedure Pip(Cx, Cy, S, Su, C : LongInt);
Var R, Y, Hw : LongInt;
Begin
  R := (S + 1) Div 2;
  Case Su Of
    0 :
      Begin
        { coeur }
        Disc(Cx - R + 1, Cy - R Div 2, R, C);
        Disc(Cx + R - 1, Cy - R Div 2, R, C);
        Tri(Cx, Cy - R Div 3, Cy + S, S, C, True);
      End;
    1 :
      { carreau }
      For Y := -S To S Do
      Begin
        Hw := (S - AbsI(Y)) * 4 Div 5;
        Rect(Cx - Hw, Cy + Y, Cx + Hw, Cy + Y, C);
      End;
    2 :
      Begin
        { trefle : trois feuilles et un pied }
        Disc(Cx, Cy - R + 1, R, C);
        Disc(Cx - R, Cy + R Div 2, R, C);
        Disc(Cx + R, Cy + R Div 2, R, C);
        Tri(Cx, Cy + 1, Cy + S, R, C, False);
      End;
    3 :
      Begin
        { pique : coeur renverse et un pied }
        Tri(Cx, Cy - S, Cy + R Div 2, S, C, False);
        Disc(Cx - R + 1, Cy + R Div 2, R, C);
        Disc(Cx + R - 1, Cy + R Div 2, R, C);
        Tri(Cx, Cy + R Div 2, Cy + S, R, C, False);
      End;
  End;
End;

{ dos : bordeaux, treillis dore, cadre et rosace }
Procedure DrawBack(X, Y : LongInt);
Var I, J, Cx, Cy : LongInt;
Begin
  RRect(X, Y, X + KW - 1, Y + KH - 1, C_CARD);
  Rect(X + 3, Y + 3, X + KW - 4, Y + KH - 4, C_BACK1);
  For J := Y + 5 To Y + KH - 6 Do
    For I := X + 5 To X + KW - 6 Do
      If ((I - X + J - Y) Mod 7 = 0) Or ((I - X - (J - Y) + 70) Mod 7 = 0) Then Pix(I, J, C_GOLDD);
  Rect(X + 5, Y + 5, X + KW - 6, Y + 5, C_BACK2); Rect(X + 5, Y + KH - 6, X + KW - 6, Y + KH - 6, C_BACK2);
  Rect(X + 5, Y + 5, X + 5, Y + KH - 6, C_BACK2); Rect(X + KW - 6, Y + 5, X + KW - 6, Y + KH - 6, C_BACK2);
  Cx := X + KW Div 2; Cy := Y + KH Div 2;
  Disc(Cx, Cy, 9, C_BACK2);
  Disc(Cx, Cy, 7, C_BACK1);
  For I := -1 To 1 Do
  Begin
    Rect(Cx - 5, Cy + I, Cx + 5, Cy + I, C_GOLD);
    Rect(Cx + I, Cy - 5, Cx + I, Cy + 5, C_GOLD);
  End;
  For I := -3 To 3 Do
  Begin
    Pix(Cx + I, Cy + I, C_GOLD); Pix(Cx + I, Cy - I, C_GOLD);
  End;
  Disc(Cx, Cy, 1, C_BACK1);
End;

{ portraits des figures (Valet, Dame, Roi), dans le cadre (X1..X2, Y1..Y2) }
Procedure Figure(X1, Y1, X2, Y2, R, Su, Fg : LongInt);
Var Cx, Robe, K : LongInt;
Begin
  Cx := (X1 + X2) Div 2;
  If Su <= 1 Then Robe := C_ROBER Else Robe := C_ROBEB;
  Rect(X1, Y1, X2, Y2, C_GOLD);
  Rect(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, C_FACE);
  { robe et col }
  Tri(Cx, Y1 + 26, Y2 - 1, (X2 - X1) Div 2 - 1, Robe, False);
  Rect(X1 + 2, Y2 - 9, X2 - 2, Y2 - 1, Robe);
  Rect(Cx - 1, Y1 + 27, Cx + 1, Y2 - 1, C_GOLD);
  { visage }
  If R = 11 Then
  Begin
    { Dame : longs cheveux }
    Rect(Cx - 7, Y1 + 13, Cx + 7, Y1 + 30, C_HAIR);
  End;
  Disc(Cx, Y1 + 19, 6, C_SKIN);
  Pix(Cx - 2, Y1 + 18, C_BLACK); Pix(Cx + 2, Y1 + 18, C_BLACK);
  Rect(Cx - 1, Y1 + 22, Cx + 1, Y1 + 22, C_ROBER);
  Case R Of
    12 :
      Begin
        { Roi : couronne a trois pointes et barbe }
        Rect(Cx - 6, Y1 + 9, Cx + 6, Y1 + 12, C_GOLD);
        For K := -1 To 1 Do Tri(Cx + K * 5, Y1 + 4, Y1 + 9, 2, C_GOLD, False);
        Pix(Cx, Y1 + 10, C_ROBER); Pix(Cx - 4, Y1 + 10, C_ROBEB); Pix(Cx + 4, Y1 + 10, C_ROBEB);
        Rect(Cx - 4, Y1 + 23, Cx + 4, Y1 + 26, C_GRAY);
        Tri(Cx, Y1 + 26, Y1 + 29, 3, C_GRAY, True);
      End;
    11 :
      Begin
        { Dame : diademe }
        Rect(Cx - 5, Y1 + 11, Cx + 5, Y1 + 12, C_GOLD);
        Tri(Cx, Y1 + 7, Y1 + 11, 2, C_GOLD, False);
        Pix(Cx, Y1 + 10, C_ROBER);
      End;
  Else
    Begin
      { Valet : toque et plume }
      Rect(Cx - 7, Y1 + 10, Cx + 6, Y1 + 13, Robe);
      Rect(Cx - 5, Y1 + 8, Cx + 4, Y1 + 9, Robe);
      For K := 0 To 4 Do Pix(Cx + 5 + K Div 2, Y1 + 8 - K, C_GOLD);
    End;
  End;
  { petite enseigne dans le coin du cadre }
  Pip(X1 + 6, Y1 + 7, 3, Su, Fg);
End;

{ position des points des cartes 2 a 10 : colonne (0 gauche, 1 milieu,
  2 droite) et hauteur en douziemes }
Const
  PipN : Array[1..9] Of LongInt = (2, 3, 4, 5, 6, 7, 8, 9, 10);
  PipCol : Array[0..53] Of Byte = (
    1, 1,  1, 1, 1,  0, 2, 0, 2,  0, 2, 0, 2, 1,  0, 2, 0, 2, 0, 2,  0, 2, 0, 2, 0, 2, 1,
    0, 2, 0, 2, 0, 2, 1, 1,  0, 2, 0, 2, 0, 2, 0, 2, 1,  0, 2, 0, 2, 0, 2, 0, 2, 1, 1);
  PipRow : Array[0..53] Of Byte = (
    0, 12,  0, 6, 12,  0, 0, 12, 12,  0, 0, 12, 12, 6,  0, 0, 6, 6, 12, 12,  0, 0, 6, 6, 12, 12, 3,
    0, 0, 6, 6, 12, 12, 3, 9,  0, 0, 4, 4, 8, 8, 12, 12, 6,  0, 0, 4, 4, 8, 8, 12, 12, 2, 10);
  PipFirst : Array[1..9] Of Byte = (0, 2, 5, 9, 14, 20, 27, 35, 44);

{ face : index (rang et enseigne) en haut a gauche et en bas a droite,
  points, grande enseigne de l'As ou portrait }
Procedure DrawFace(X, Y, C : LongInt);
Var R, Su, Fg, K, A, Px, Py : LongInt; S : String;
Begin
  RRect(X, Y, X + KW - 1, Y + KH - 1, C_CARD);
  Rect(X + 3, Y + KH - 3, X + KW - 4, Y + KH - 2, C_CARDE);
  R := Rank(C); Su := SuitOf(C);
  If IsRed(C) Then Fg := C_RED Else Fg := C_BLACK;
  S := RankName(R);
  { index en gras (deux passages decales) }
  FbText(X + 3, Y + 2, S, Fg, 1);
  FbText(X + 4, Y + 2, S, Fg, 1);
  Pip(X + 3 + Length(S) * 4, Y + 24, 4, Su, Fg);
  If R >= 10 Then Figure(X + 18, Y + 5, X + KW - 5, Y + KH - 6, R, Su, Fg)
  Else If R = 0 Then
  Begin
    { As : grande enseigne dans un anneau dore }
    Ring(X + 29, Y + 34, 14, 15, C_GOLD);
    Pip(X + 29, Y + 33, 9, Su, Fg);
  End
  Else
  Begin
    A := PipFirst[R];
    For K := 0 To PipN[R] - 1 Do
    Begin
      Px := X + 25 + PipCol[A + K] * 7;
      Py := Y + 11 + PipRow[A + K] * 42 Div 12;
      Pip(Px, Py, 4, Su, Fg);
    End;
  End;
End;

{ une carte (C < 0 : rien), avec ombre ; Hl : couleur du contour epais (-1 aucun) }
Procedure DrawCard(X, Y, C, Up, Hl : LongInt);
Begin
  If C < 0 Then Exit;
  RRect(X + 2, Y + 3, X + KW + 1, Y + KH + 2, C_SHADOW);
  If Up <> 0 Then DrawFace(X, Y, C) Else DrawBack(X, Y);
  Outline(X, Y, C_BORDER, 1);
  If Hl >= 0 Then Outline(X, Y, Hl, 2);
End;

{ emplacement vide : creux du tapis et texte au centre }
Procedure DrawSlot(X, Y : LongInt; S : String; Hl : LongInt);
Begin
  RRect(X, Y, X + KW - 1, Y + KH - 1, C_SLOT);
  Outline(X, Y, C_SLOTE, 1);
  If S <> '' Then FbText(X + (KW - Length(S) * 8) Div 2, Y + (KH - FontH) Div 2, S, C_SLOTE, 1);
  If Hl >= 0 Then Outline(X, Y, Hl, 2);
End;

{ ==================================================================== }
{ Positions et image                                                    }
{ ==================================================================== }

Function RowY(J : LongInt) : LongInt;
Begin
  RowY := RowY0 + J * RowStep;
End;

Function GridCX(Col : LongInt) : LongInt;
Begin
  GridCX := GridX + Col * GridStep;
End;

{ position de la carte du dessus d'un emplacement }
Function SlotX(S : LongInt) : LongInt;
Begin
  If S < 4 Then SlotX := ResX + MaxI(0, ResN[S] - 1) * 2
  Else If S = SL_STOCK Then SlotX := StockX
  Else If S = SL_WASTE Then SlotX := WasteX + MaxI(0, MinI(Pos, DrawN) - 1) * FanStep
  Else SlotX := GridCX((S - SL_GRID) Mod 13);
End;

Function SlotY(S : LongInt) : LongInt;
Begin
  If S < 4 Then SlotY := RowY(S) + MaxI(0, ResN[S] - 1) * 2
  Else If S < SL_GRID Then SlotY := BotY
  Else SlotY := RowY((S - SL_GRID) Div 13);
End;

Procedure Touch(X1, Y1, X2, Y2 : LongInt);
Begin
  If DX2 < DX1 Then
  Begin
    DX1 := X1; DY1 := Y1; DX2 := X2; DY2 := Y2;
  End
  Else
  Begin
    DX1 := MinI(DX1, X1); DY1 := MinI(DY1, Y1); DX2 := MaxI(DX2, X2); DY2 := MaxI(DY2, Y2);
  End;
End;

Procedure RenderBack;
Var X, Y, D, Cx, Cy, B : LongInt;
Begin
  Cx := BW Div 2; Cy := BH Div 2;
  For Y := 0 To BH - 1 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := 0 To BW - 1 Do
    Begin
      D := ((X - Cx) * (X - Cx) + (Y - Cy) * (Y - Cy) * 2) Div 2400;
      If D > 15 Then D := 15;
      If ((X * 5 + Y * 11) Mod 13 = 0) And (D < 15) Then Inc(D);
      Fb[B + X] := C_FELT + 15 - D;
    End;
  End;
  Move(Fb, Back, SizeOf(Fb));
End;

Procedure DrawBanner;
Var W, X, Y, H : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(Length(Banner) * 16, MaxI(Length(Banner2), Length(Banner3)) * 8) + 32;
  If W > BW - 16 Then W := BW - 16;
  H := 96; X := (BW - W) Div 2; Y := 140;
  Rect(X + 5, Y + 5, X + W + 4, Y + H + 4, C_SHADOW);
  Rect(X, Y, X + W - 1, Y + H - 1, C_BANNER);
  Rect(X, Y, X + W - 1, Y + 1, C_BANNERE); Rect(X, Y + H - 2, X + W - 1, Y + H - 1, C_BANNERE);
  Rect(X, Y, X + 1, Y + H - 1, C_BANNERE); Rect(X + W - 2, Y, X + W - 1, Y + H - 1, C_BANNERE);
  FbTextSh((BW - Length(Banner) * 16) Div 2, Y + 12, Banner, BannerC, 2);
  FbTextSh((BW - Length(Banner2) * 8) Div 2, Y + 50, Banner2, C_WHITE, 1);
  FbTextSh((BW - Length(Banner3) * 8) Div 2, Y + 70, Banner3, C_GREEN, 1);
End;

Function HlOf(S : LongInt) : LongInt;
Begin
  If S = HintSl Then HlOf := C_HILITE Else HlOf := -1;
End;

Procedure Render;
Var J, K, C, X, Y, N, Hide : LongInt;
Begin
  Move(Back, Fb, SizeOf(Fb));
  Hide := -1;
  If FlyOn <> 0 Then Hide := FlySl;
  { reserves (dos des cartes du dessous, decalees) }
  For J := 0 To 3 Do
  Begin
    FbTextSh(3, RowY(J) + 24, IStr(J + 1), C_TEXTD, 1);
    If ResN[J] = 0 Then DrawSlot(ResX, RowY(J), '', HlOf(J))
    Else
    Begin
      For K := 0 To ResN[J] - 2 Do DrawCard(ResX + K * 2, RowY(J) + K * 2, ResC[J * 3 + K], 0, -1);
      DrawCard(SlotX(J), SlotY(J), ResTop(J), 1, HlOf(J));
    End;
  End;
  { tableau : rangees par colonnes de rang a partir du rang de base ;
    d'abord les places vides (creux marques du rang), puis les cartes }
  For J := 0 To 3 Do
    For K := 0 To 12 Do
    Begin
      X := GridCX(K); Y := RowY(J);
      If (RowS[J] >= 0) Or (K = 0) Then
      Begin
        If (K = 0) And (RowS[J] < 0) Then DrawSlot(X, Y, RankName(Base), -1)
        Else If Grid[J * 13 + K] < 0 Then
        Begin
          If K = 12 Then DrawSlot(X, Y, RankName((Base + K) Mod 13), -1)
          Else
          Begin
            RRect(X, Y, X + GridStep - 2, Y + KH - 1, C_SLOT);
            FbText(X + 4, Y + 4, RankName((Base + K) Mod 13), C_SLOTE, 1);
          End;
        End;
      End;
    End;
  For J := 0 To 3 Do
    For K := 0 To 12 Do
    Begin
      C := Grid[J * 13 + K];
      If (C >= 0) And (SL_GRID + J * 13 + K <> Hide) Then DrawCard(GridCX(K), RowY(J), C, 1, -1);
    End;
  { pioche et defausse }
  FbTextSh(StockX - 12, BotY + 24, '5', C_TEXTD, 1);
  FbTextSh(WasteX - 13, BotY + 24, '6', C_TEXTD, 1);
  If Pos < StkN Then
  Begin
    N := MinI(3, (StkN - Pos + 6) Div 7);
    For K := N - 1 Downto 1 Do DrawCard(StockX + K * 2, BotY + K * 2, 0, 0, -1);
    DrawCard(StockX, BotY, 0, 0, HlOf(SL_STOCK));
  End
  Else If StkN > 0 Then DrawSlot(StockX, BotY, Chr(30), HlOf(SL_STOCK))
  Else DrawSlot(StockX, BotY, '', -1);
  If Pos = 0 Then DrawSlot(WasteX, BotY, '', -1)
  Else
  Begin
    N := MinI(Pos, DrawN);
    For K := 0 To N - 1 Do
      If (K < N - 1) Or (Hide <> -2) Then
      Begin
        If K = N - 1 Then DrawCard(WasteX + K * FanStep, BotY, Stk[Pos - N + K], 1, HlOf(SL_WASTE))
        Else DrawCard(WasteX + K * FanStep, BotY, Stk[Pos - N + K], 1, -1);
      End;
  End;
  { renseignements sous le tableau }
  FbTextSh(250, BotY + 4, 'Rang de base : ' + RankLong(Base), C_TEXT, 1);
  FbTextSh(250, BotY + 22, 'Pioche : ' + IStr(StkN - Pos) + ', d' + Chr(130) + 'fausse : ' + IStr(Pos), C_TEXT, 1);
  FbTextSh(250, BotY + 40, 'Tours de pioche : ' + IStr(Passes + 1), C_TEXT, 1);
  { carte qui glisse }
  If FlyOn <> 0 Then
  Begin
    X := FlyX0 + (FlyX1 - FlyX0) * FlyK Div FlyN;
    Y := FlyY0 + (FlyY1 - FlyY0) * FlyK Div FlyN;
    RRect(X + 5, Y + 6, X + KW + 4, Y + KH + 5, C_SHADOW);
    DrawFace(X, Y, FlyC);
    Outline(X, Y, C_BORDER, 1);
  End;
  DrawBanner;
End;

Procedure BlitRect(H, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  P[0] := OX + X1; P[1] := CH - OY - 1 - Y2; P[2] := OX + X2 + 1; P[3] := CH - OY - Y1;
  P[4] := X1; P[5] := BH - 1 - Y2; P[6] := X2 + 1; P[7] := BH - Y1;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure DrawInfo;
Var Y : LongInt;
Begin
  FBar(PnX, 56, PnX + PW - 1, 150, CLR_PALEGRAY);
  OutTxt(PnX, 56, 'Plac' + Chr(130) + 'es :', CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX + 8, 74, IStr(Placed) + ' / 52', CLR_DARKBLUE, CLR_PALEGRAY);
  { jauge }
  Edge(PnX, 94, PnX + PW - 1, 104, CLR_DARKGRAY, CLR_WHITE);
  FBar(PnX + 1, 95, PnX + PW - 2, 103, CLR_WHITE);
  If Placed > 0 Then FBar(PnX + 1, 95, PnX + 1 + (PW - 3) * Placed Div 52, 103, CLR_DARKGREEN);
  Y := 112;
  OutTxt(PnX, Y, 'Coups : ' + IStr(Moves), CLR_BLACK, CLR_PALEGRAY);
  If Games > 0 Then OutTxt(PnX, Y + 18, 'Gagn' + Chr(130) + 'es : ' + IStr(Wins) + '/' + IStr(Games), CLR_DARKRED,
                           CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 8 * 16) Div 2, 2, 'Patience', CLR_DARKGREEN, CLR_PALEGRAY);
  OutTxt(PnX + (PW - 13 * 8) Div 2, 34, 'jeu de cartes', CLR_DARKGRAY, CLR_PALEGRAY);
  DrawInfo;
  Button(PnX, 158, PW, 26, 'Nouvelle donne');
  Button(PnX, 190, PW, 26, 'Retourner');
  Button(PnX, 222, (PW - 4) Div 2, 26, 'Annuler');
  Button(PnX + (PW + 4) Div 2, 222, (PW - 4) Div 2, 26, 'Indice');
  OutTxt(PnX, 262, '1-4 : r' + Chr(130) + 'serves', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 278, '5 : pioche', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 294, '6 : d' + Chr(130) + 'fausse', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 310, 'U : annuler', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 326, 'I : indice', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 342, 'R : m' + Chr(136) + 'me donne', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 358, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Function Sig : LongInt;
Begin
  Sig := Placed * 7 + Moves * 131 + State * 1009 + Games * 10007 + Wins * 77;
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, OX - 3, CH - 1, CLR_PALEGRAY);
  FBar(OX + BW + 2, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  FBar(0, 0, CW - 1, OY - 3, CLR_PALEGRAY);
  FBar(0, OY + BH + 2, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(OX - 1, OY - 1, OX + BW, OY + BH, CLR_BLACK, CLR_PALEGRAY);
  Render;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1; FullBlit := 0;
  DrawPanel;
  DrawStatus;
  LastMsg := Msg; LastSig := Sig;
  Dummy := WinEndPaint(Hps);
End;

Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  If (FullBlit = 0) And (DX2 < DX1) And (Sig = LastSig) And (Msg = LastMsg) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If (FullBlit <> 0) Or (DX2 >= DX1) Then Render;
  If FullBlit <> 0 Then BlitRect(Hps, 0, 0, BW - 1, BH - 1)
  Else If DX2 >= DX1 Then BlitRect(Hps, DX1, DY1, DX2, DY2);
  FullBlit := 0;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1;
  If Sig <> LastSig Then
  Begin
    LastSig := Sig;
    DrawInfo;
  End;
  If Msg <> LastMsg Then
  Begin
    LastMsg := Msg;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Bruitages                                                             }
{ ==================================================================== }

Procedure MakeTone(N, F1, F2, Ms, Vol : LongInt);
Var K, Len, F, Ph, V, Env : LongInt;
Begin
  Len := SndRate * Ms Div 1000;
  If NSndBuf + Len > SizeOf(SndBuf) Then Exit;
  SndOfs[N] := NSndBuf; SndLen[N] := Len; SndPri[N] := SndPrio;
  Ph := 0;
  For K := 0 To Len - 1 Do
  Begin
    F := F1 + (F2 - F1) * K Div Len;
    Ph := (Ph + F * 65536 Div SndRate) And $FFFF;
    If K < 40 Then Env := K * 255 Div 40 Else Env := 255 * (Len - K) Div (Len - 40 + 1);
    If Ph < 32768 Then V := Vol Else V := -Vol;
    If (Ph < 2048) Or ((Ph >= 32768) And (Ph < 34816)) Then V := V Div 2;
    SndBuf[NSndBuf + K] := 128 + V * Env Div 255;
  End;
  NSndBuf := NSndBuf + Len;
End;

{ claquement de bois : bruit tres court qui s'eteint vite }
Procedure MakeClack(N, Ms, Vol, Hold : LongInt);
Var K, Len, V, Env, R, H : LongInt;
Begin
  Len := SndRate * Ms Div 1000;
  If NSndBuf + Len > SizeOf(SndBuf) Then Exit;
  SndOfs[N] := NSndBuf; SndLen[N] := Len; SndPri[N] := SndPrio;
  R := 4321; V := 0; H := 0;
  For K := 0 To Len - 1 Do
  Begin
    If H <= 0 Then
    Begin
      R := (R * 1103515245 + 12345) And $7FFFFFFF;
      V := ((R Shr 16) And 255) - 128;
      H := Hold;
    End;
    Dec(H);
    If K < 8 Then Env := K * 255 Div 8 Else Env := 255 * (Len - K) Div (Len - 8 + 1);
    Env := Env * Env Div 255 * Env Div 255;
    SndBuf[NSndBuf + K] := 128 + V * Vol Div 128 * Env Div 255;
  End;
  NSndBuf := NSndBuf + Len;
End;

Function SndNow : LongInt;
Var T : Array[0..15] Of Byte;
Begin
  Dummy := DosGetDateTime(LongInt(@T));
  SndNow := ((T[0] * 60 + T[1]) * 60 + T[2]) * 1000 + T[3] * 10;
End;

Procedure PlaySnd(N : LongInt);
Var T : LongInt;
Begin
  If (SoundOn = 0) Or (TestMode <> 0) Or (SndLen[N] = 0) Then Exit;
  T := SndNow;
  If (SndPri[N] < SndCur) And (T < SndEnd) And (T >= SndEnd - 60000) Then Exit;
  SndCur := SndPri[N];
  SndEnd := T + SndLen[N] * 1000 Div SndRate;
  Dummy := MdmPlay(LongInt(@SndBuf[SndOfs[N]]), SndLen[N], SndRate, 8, 1);
End;

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 0; MakeClack(0, 60, 40, 3);                  { carte qui glisse }
  SndPrio := 0; MakeClack(1, 35, 45, 1);                  { cartes retournees }
  SndPrio := 1; MakeTone(2, 900, 1400, 60, 30);           { carte placee }
  SndPrio := 3; MakeTone(3, 520, 1560, 800, 50);          { partie gagnee }
  SndPrio := 3; MakeTone(4, 420, 140, 700, 45);           { partie bloquee }
  SndPrio := 1; MakeTone(5, 300, 260, 90, 30);            { coup refuse }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Deroulement de la partie                                              }
{ ==================================================================== }

Procedure PlayMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue (Options).'
  Else Msg := 'Placez les cartes des r' + Chr(130) + 'serves et de la d' + Chr(130) + 'fausse ; cliquez la ' +
              'pioche pour retourner.';
End;

Procedure CheckEnd;
Begin
  If State <> G_PLAY Then Exit;
  If Placed = 52 Then
  Begin
    State := G_WON;
    Inc(Games); Inc(Wins);
    Banner := 'Bravo !'; BannerC := C_YELLOW;
    Banner2 := 'Les 52 cartes sont plac' + Chr(130) + 'es en ' + IStr(Moves) + ' coups.';
    Banner3 := 'F2 ou clic : nouvelle donne';
    Msg := 'Patience r' + Chr(130) + 'ussie !';
    PlaySnd(3);
    FullBlit := 1;
  End
  Else If Blocked Then
  Begin
    State := G_LOST;
    Inc(Games);
    If Placed > BestPlaced Then BestPlaced := Placed;
    Banner := 'Partie bloqu' + Chr(130) + 'e'; BannerC := C_TEXTD;
    Banner2 := 'Aucune carte ne pourra plus ' + Chr(136) + 'tre plac' + Chr(130) + 'e (' + IStr(Placed) + '/52).';
    Banner3 := 'U : annuler   F2 : nouvelle donne';
    Msg := 'Plus aucune carte ne peut ' + Chr(136) + 'tre plac' + Chr(130) + 'e : la patience est perdue.';
    PlaySnd(4);
    FullBlit := 1;
  End;
End;

Procedure NewDeal(Sd : LongInt);
Begin
  DealSeed := Sd;
  Deal(Sd);
  NSnap := 0; FlyOn := 0; HintSl := -1; Wait := 0;
  Banner := ''; Banner2 := ''; Banner3 := '';
  PlayMsg;
  Msg := 'Nouvelle donne : rang de base ' + RankLong(Base) + '. ' + Msg;
  CheckEnd;
  FullBlit := 1;
End;

Procedure NewGame;
Begin
  NewDeal(Rnd(1000000) + 1);
End;

{ joue depuis la reserve P (0..3) ou la defausse (SL_WASTE) }
Procedure DoPlay(S : LongInt);
Var C, X, Y, J : LongInt;
Begin
  If (State <> G_PLAY) Or (FlyOn <> 0) Then Exit;
  If S < 4 Then C := ResTop(S) Else C := WasteTop;
  If C < 0 Then
  Begin
    If S < 4 Then Msg := 'La r' + Chr(130) + 'serve ' + IStr(S + 1) + ' est vide.'
    Else Msg := 'La d' + Chr(130) + 'fausse est vide : cliquez la pioche.';
    PlaySnd(5);
    Exit;
  End;
  J := CanPlace(C);
  If J < 0 Then
  Begin
    If (RowS[0] >= 0) And (SuitOf(C) <> RowS[0]) And (Rank(C) <> Base) Then
    Begin
      For J := 1 To 3 Do
        If RowS[J] = SuitOf(C) Then
          Msg := 'Le ' + CardName(C) + ' attend le ' + RankLong(Rank(C)) + ' dans la rang' + Chr(130) + 'e du dessus.';
      If (RowS[1] <> SuitOf(C)) And (RowS[2] <> SuitOf(C)) And (RowS[3] <> SuitOf(C)) Then
        Msg := 'Pas encore de rang' + Chr(130) + 'e ' + SuitName(SuitOf(C)) + ' : il faut d''abord un ' +
               RankLong(Base) + ' de ' + SuitName(SuitOf(C)) + '.';
    End
    Else Msg := 'Le ' + CardName(C) + ' ne peut pas ' + Chr(136) + 'tre plac' + Chr(130) + '.';
    PlaySnd(5);
    Exit;
  End;
  SaveSnap;
  X := SlotX(S); Y := SlotY(S);
  J := PlayFrom(S);
  HintSl := -1;
  If (TestMode = 0) And (Client <> 0) Then
  Begin
    FlyOn := 1; FlyC := C; FlyX0 := X; FlyY0 := Y; FlySl := SL_GRID + J * 13 + ColOf(C);
    FlyX1 := GridCX(ColOf(C)); FlyY1 := RowY(J); FlyK := 0;
    FlyN := MaxI(5, MinI(10, (AbsI(FlyX1 - X) + AbsI(FlyY1 - Y)) Div 30));
    PlaySnd(0);
  End;
  Msg := CardName(C) + ' plac' + Chr(130) + ' dans la rang' + Chr(130) + 'e ' + IStr(J + 1) + '.';
  If FlyOn = 0 Then CheckEnd;
  FullBlit := 1;
End;

Procedure DoTurn;
Begin
  If (State <> G_PLAY) Or (FlyOn <> 0) Then Exit;
  If StkN = 0 Then
  Begin
    Msg := 'La pioche est ' + Chr(130) + 'puis' + Chr(130) + 'e.';
    Exit;
  End;
  SaveSnap;
  If Pos >= StkN Then Msg := 'Pioche remise en place (tour ' + IStr(Passes + 2) + ').'
  Else PlayMsg;
  TurnStock;
  HintSl := -1;
  PlaySnd(1);
  CheckEnd;
  FullBlit := 1;
End;

Procedure UndoMove;
Begin
  If (NSnap = 0) Or (FlyOn <> 0) Or (AutoAll <> 0) Then Exit;
  If State = G_LOST Then Dec(Games);
  If State = G_WON Then Exit;
  LoadSnap;
  State := G_PLAY; Banner := ''; Banner2 := ''; Banner3 := ''; HintSl := -1;
  Msg := 'Coup annul' + Chr(130) + '.';
  PlaySnd(5);
  FullBlit := 1;
End;

{ coup conseille : une carte placable, sinon la pioche (-1 : aucun) }
Function BestSlot : LongInt;
Var P, R : LongInt;
Begin
  R := -1;
  For P := 3 Downto 0 Do
    If CanPlace(ResTop(P)) >= 0 Then R := P;
  If (R < 0) And (CanPlace(WasteTop) >= 0) Then R := SL_WASTE;
  If (R < 0) And (StkN > 0) Then R := SL_STOCK;
  BestSlot := R;
End;

Procedure Hint;
Begin
  If (State <> G_PLAY) Or (FlyOn <> 0) Then Exit;
  HintSl := BestSlot;
  If HintSl < 4 Then Msg := 'Indice : la carte de la r' + Chr(130) + 'serve ' + IStr(HintSl + 1) + ' (' +
                            CardName(ResTop(HintSl)) + ') peut ' + Chr(136) + 'tre plac' + Chr(130) + 'e.'
  Else If HintSl = SL_WASTE Then Msg := 'Indice : placez la carte de la d' + Chr(130) + 'fausse (' +
                                        CardName(WasteTop) + ').'
  Else Msg := 'Indice : retournez des cartes de la pioche.';
  FullBlit := 1;
End;

{ un pas de l'ordinateur (demonstration et essais) }
Procedure AutoStep;
Var S : LongInt;
Begin
  S := BestSlot;
  If S < 0 Then Exit;
  If S = SL_STOCK Then DoTurn Else DoPlay(S);
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If FlyOn <> 0 Then
  Begin
    Touch(FlyX0 + (FlyX1 - FlyX0) * FlyK Div FlyN - 4, FlyY0 + (FlyY1 - FlyY0) * FlyK Div FlyN - 4,
          FlyX0 + (FlyX1 - FlyX0) * FlyK Div FlyN + KW + 6, FlyY0 + (FlyY1 - FlyY0) * FlyK Div FlyN + KH + 6);
    Inc(FlyK);
    If FlyK >= FlyN Then
    Begin
      FlyOn := 0;
      PlaySnd(2);
      CheckEnd;
      FullBlit := 1;
    End
    Else
      Touch(FlyX0 + (FlyX1 - FlyX0) * FlyK Div FlyN - 4, FlyY0 + (FlyY1 - FlyY0) * FlyK Div FlyN - 4,
            FlyX0 + (FlyX1 - FlyX0) * FlyK Div FlyN + KW + 6, FlyY0 + (FlyY1 - FlyY0) * FlyK Div FlyN + KH + 6);
  End
  Else If AutoAll <> 0 Then
  Begin
    Inc(Wait);
    If (State = G_PLAY) And (Wait > 6) Then
    Begin
      Wait := 0;
      AutoStep;
    End
    Else If (State <> G_PLAY) And (Wait > 90) Then NewGame;
  End;
  Frame1;
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
  SetMark(CM_DRAW3, DrawN = 3); SetMark(CM_DRAW1, DrawN = 1);
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0);
End;

Procedure ShowRules;
Begin
  LClr;
  LAdd('La carte retourn' + Chr(130) + 'e au d' + Chr(130) + 'but donne le rang de base et ouvre la premi' +
       Chr(138) + 're rang' + Chr(130) + 'e du tableau. Quatre r' + Chr(130) + 'serves de trois cartes sont ' +
       ' ' + Chr(133) + ' gauche (seule la carte du dessus se joue) ; la pioche de 39 cartes se retourne ' +
       'trois par trois sur la d' + Chr(130) + 'fausse, autant de fois que l''on veut (Options : une ' +
       Chr(133) + ' la fois).' + Chr(10) + Chr(10));
  LAdd('Le tableau a quatre rang' + Chr(130) + 'es, une par couleur. Chaque carte du rang de base ouvre la ' +
       'rang' + Chr(130) + 'e libre suivante, pour sa couleur. Une autre carte va dans la rang' + Chr(130) +
       'e de sa couleur, dans la colonne de son rang : la premi' + Chr(138) + 're rang' + Chr(130) + 'e la re' +
       Chr(135) + 'oit toujours, les suivantes seulement si la rang' + Chr(130) + 'e du dessus contient d' +
       Chr(130) + 'j' + Chr(133) + ' ce rang.' + Chr(10) + Chr(10));
  LAdd('La patience est r' + Chr(130) + 'ussie quand les 52 cartes sont plac' + Chr(130) + 'es ; elle est ' +
       'perdue quand plus aucune carte ne peut l''' + Chr(136) + 'tre (le jeu le d' + Chr(130) + 'tecte).' +
       Chr(10) + Chr(10));
  LAdd('Souris : cliquer une r' + Chr(130) + 'serve, la d' + Chr(130) + 'fausse ou la pioche. Clavier : 1 ' +
       Chr(133) + ' 4 (r' + Chr(130) + 'serves), 5 ou Espace (pioche), 6 (d' + Chr(130) + 'fausse), U ' +
       '(annuler), I (indice), R (m' + Chr(136) + 'me donne), F2 (nouvelle donne).');
  Dummy := LMsgBox('Patience - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_RESTART : Begin NewDeal(DealSeed); Msg := 'M' + Chr(136) + 'me donne recommenc' + Chr(130) + 'e.'; End;
    CM_UNDO : UndoMove;
    CM_HINT : Hint;
    CM_DEAL : DoTurn;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_DRAW3, CM_DRAW1 :
      Begin
        If Id = CM_DRAW3 Then DrawN := 3 Else DrawN := 1;
        SetMarks; NewGame;
        If DrawN = 1 Then Msg := 'La pioche se retourne une carte ' + Chr(133) + ' la fois (plus facile).'
        Else Msg := 'La pioche se retourne trois cartes ' + Chr(133) + ' la fois.';
      End;
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; Wait := 0; PlayMsg; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES : ShowRules;
    CM_ABOUT : Dummy := Ask('Patience pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            'e du prototype PATIENCE.PAS de 7iles (1992).' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

Procedure Pick(S : LongInt);
Begin
  If State <> G_PLAY Then
  Begin
    If State = G_WON Then NewGame;
    Exit;
  End;
  If AutoAll <> 0 Then Exit;
  If S = SL_STOCK Then DoTurn
  Else If (S < 4) Or (S = SL_WASTE) Then DoPlay(S);
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And (KC_KEYUP Or KC_ALT)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_CTRL) <> 0 Then
  Begin
    If (Ch = 26) Or (UpCase(Chr(Ch)) = 'Z') Then Command(CM_UNDO) Else KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_BACKSPACE Then Begin Command(CM_UNDO); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Pick(SL_STOCK); Frame1; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      '1'..'4' : Pick(Ch - Ord('1'));
      '5', ' ' : Pick(SL_STOCK);
      '6' : Pick(SL_WASTE);
      'U' : Command(CM_UNDO);
      'I' : Command(CM_HINT);
      'R' : Command(CM_RESTART);
    Else
      KeyChar := False;
    End;
    Frame1;
    Exit;
  End;
  KeyChar := False;
End;

Function SlotAt(X, Y : LongInt) : LongInt;
Var J, R : LongInt;
Begin
  R := -1;
  For J := 0 To 3 Do
    If (X >= ResX) And (X < ResX + KW + 6) And (Y >= RowY(J)) And (Y < RowY(J) + KH + 6) Then R := J;
  If (Y >= BotY) And (Y < BotY + KH + 4) Then
  Begin
    If (X >= StockX) And (X < StockX + KW + 4) Then R := SL_STOCK;
    If (X >= WasteX) And (X < WasteX + 2 * FanStep + KW) Then R := SL_WASTE;
  End;
  SlotAt := R;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 158) And (Y < 184) Then Command(CM_NEW)
    Else If (Y >= 190) And (Y < 216) Then Command(CM_DEAL)
    Else If (Y >= 222) And (Y < 248) Then
    Begin
      If X < PnX + PW Div 2 Then Command(CM_UNDO) Else Command(CM_HINT);
    End;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If State = G_WON Then
    Begin
      NewGame;
      Frame1;
      Exit;
    End;
    Pick(SlotAt(X - OX, Y - OY));
    Frame1;
  End;
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
{ Essais (/TEST)                                                        }
{ ==================================================================== }

Function Card(R, Su : LongInt) : LongInt;
Begin
  Card := Su * 13 + R;
End;

{ joue la donne jusqu'au bout (coups de l'ordinateur) ; rend les cartes placees }
Function PlayOut : LongInt;
Var Guard : LongInt;
Begin
  Guard := 0;
  While (State = G_PLAY) And (Guard < 5000) Do
  Begin
    AutoStep;
    Inc(Guard);
  End;
  PlayOut := Placed;
End;

Procedure RunTests;
Var Ok, K, A, B, C, D, E, Sum, Bad, Won1, Won3, Tot1, Tot3, G : LongInt;
    Seen : Array[0..51] Of LongInt;
Begin
  Ok := 0; Client := 0; AutoAll := 0; Games := 0; Wins := 0;
  { 1 : la donne : 12 cartes en reserve, la base, 39 a la pioche, toutes differentes }
  DrawN := 3;
  Deal(12345);
  For K := 0 To 51 Do Seen[K] := 0;
  For K := 0 To 11 Do Inc(Seen[ResC[K]]);
  Inc(Seen[Grid[0]]);
  For K := 0 To StkN - 1 Do Inc(Seen[Stk[K]]);
  Bad := 0;
  For K := 0 To 51 Do
    If Seen[K] <> 1 Then Inc(Bad);
  Log('PATIENCE : TEST1 donne reserves ' + IStr(ResN[0] + ResN[1] + ResN[2] + ResN[3]) + ' pioche ' + IStr(StkN) +
      ' base ' + IStr(Placed) + ' doublons ' + IStr(Bad));
  If (Bad = 0) And (StkN = 39) And (Placed = 1) Then Inc(Ok);
  { 2 : regles : rang de base 7, premiere rangee coeur }
  For K := 0 To 51 Do Grid[K] := -1;
  For K := 0 To 3 Do RowS[K] := -1;
  Base := 6; RowS[0] := 0; Grid[0] := Card(6, 0); Placed := 1;
  A := CanPlace(Card(6, 3));                     { 7 de pique : rangee 2 (1) }
  B := CanPlace(Card(8, 0));                     { 9 de coeur : rangee 1 (0), dans n'importe quel ordre }
  PutGrid(Card(6, 3), A);
  C := CanPlace(Card(8, 3));                     { 9 de pique : refuse, pas de 9 au-dessus (-1) }
  PutGrid(Card(8, 0), B);
  D := CanPlace(Card(8, 3));                     { maintenant accepte (1) }
  E := CanPlace(Card(2, 2));                     { 3 de trefle : pas de rangee trefle (-1) }
  Log('PATIENCE : TEST2 base ' + IStr(A) + ' coeur ' + IStr(B) + ' pique refuse ' + IStr(C) + ' puis ' + IStr(D) +
      ' trefle ' + IStr(E) + ' colonne ' + IStr(ColOf(Card(8, 0))));
  If (A = 1) And (B = 0) And (C = -1) And (D = 1) And (E = -1) And (ColOf(Card(8, 0)) = 2) Then Inc(Ok);
  { 3 : annulation et partie bloquee }
  NewDeal(777);
  Sum := Placed * 1000 + StkN * 10 + Pos;
  For K := 1 To 25 Do AutoStep;
  A := Moves;
  While NSnap > 0 Do LoadSnap;
  B := Ord((Placed * 1000 + StkN * 10 + Pos = Sum) And (ResN[0] + ResN[1] + ResN[2] + ResN[3] = 12));
  { reserves et pioche sans aucune carte placable : bloquee }
  For K := 0 To 51 Do Grid[K] := -1;
  For K := 0 To 3 Do RowS[K] := -1;
  Base := 0; RowS[0] := 0; Grid[0] := Card(0, 0); Placed := 1;
  For K := 0 To 11 Do ResC[K] := Card(1 + K Mod 12, 1);
  For K := 0 To 3 Do ResN[K] := 3;
  StkN := 3; Pos := 0; Stk[0] := Card(5, 2); Stk[1] := Card(6, 2); Stk[2] := Card(7, 3);
  C := Ord(Blocked);
  Stk[1] := Card(9, 0);                          { 10 de coeur, mais cache sous le paquet de trois }
  D := Ord(Blocked);
  DrawN := 1;
  E := Ord(Blocked);                             { une a la fois : il devient accessible }
  DrawN := 3;
  Log('PATIENCE : TEST3 coups ' + IStr(A) + ' annules ' + IStr(B) + ' bloquee ' + IStr(C) + ' cachee ' + IStr(D) +
      ' une a la fois ' + IStr(E));
  If (A >= 20) And (B = 1) And (C = 1) And (D = 1) And (E = 0) Then Inc(Ok);
  { donnes jouees par l'ordinateur : 100 trois par trois, 100 une a la fois }
  Games := 0; Wins := 0;
  Won1 := 0; Won3 := 0; Tot1 := 0; Tot3 := 0;
  For G := 1 To 100 Do
  Begin
    DrawN := 3;
    NewDeal(G * 7919);
    Tot3 := Tot3 + PlayOut;
    If State = G_WON Then Inc(Won3);
    DrawN := 1;
    NewDeal(G * 7919);
    Tot1 := Tot1 + PlayOut;
    If State = G_WON Then Inc(Won1);
  End;
  Log('PATIENCE : PARTIE 100 donnes trois par trois : ' + IStr(Won3) + ' reussies, cartes ' + IStr(Tot3) +
      ' ; une a la fois : ' + IStr(Won1) + ' reussies, cartes ' + IStr(Tot1));
  If (Won3 > 0) And (Won1 > Won3) And (Games = 200) Then Inc(Ok);
  Log('PATIENCE : ' + IStr(Ok) + '/4 essais reussis');
End;

{ ==================================================================== }
{ Menus et programme principal                                          }
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

{ police 8 x 16 du VGA (VIOCALLS) }
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
  InDlg := 0;
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Banner3 := ''; Tick := 0;
  Client := 0; Frame := 0; SoundOn := 1; DrawN := 3; SndCur := 0; SndEnd := 0; TestMode := 0;
  Games := 0; Wins := 0; BestPlaced := 0; FlyOn := 0; HintSl := -1; BannerC := C_YELLOW; NSnap := 0;
  CW := CWant; CH := CHWant;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1; FullBlit := 1;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If S = '/DRAW:1' Then DrawN := 1;
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
    If S = '/TEST' Then TestMode := 1;
  End;
  If TestMode <> 0 Then
  Begin
    RunTests;
    Halt(0);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  RenderBack;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('PATIENCE'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('PATIENCE'), Z2('Patience'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle donne' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_RESTART, '~Recommencer la donne' + Chr(9) + 'R');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_DEAL, 'Retourner la ~pioche' + Chr(9) + '5');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'U');
  MItem(MIS_TEXT, 0, CM_HINT, '~Indice' + Chr(9) + 'I');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 8);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_DRAW3, 'Pioche ~trois par trois');
  MItem(MIS_TEXT, 0, CM_DRAW1, 'Pioche ~une ' + Chr(133) + ' la fois');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Patience');
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
  SetMarks;
  NewGame;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
