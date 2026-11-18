{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: TILEMAN - jeu de conquete de territoire pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program TILEMAN;

{$R-,S-,I-}

{ Compilation : OS2PC TILEMAN.PAS   (produit TILEMAN.EXE)

  Portage vers OS/2-0 du prototype TILEMAN.PAS du depot 7iles (Turbo
  Pascal et BGI, clavier seulement, ecrans de titre et de fin) : fenetre
  de Presentation Manager avec menus, panneau du pointage, barre d'etat
  et apparence d'OS/2.

  But : conquerir le terrain. Le joueur (disque jaune) part de son
  territoire (tuiles bleues) ; en sortant, il laisse une trace (cyan).
  En revenant dans son territoire, la trace devient territoire et toutes
  les zones fermees ou il n'y a pas d'ennemi sont conquises. Les ennemis
  (rouges) rebondissent sur les murs et le territoire : s'ils touchent le
  joueur ou sa trace, ou si le joueur recoupe sa propre trace, il perd
  une vie et repart du point ou il etait sorti. Un niveau est termine a
  75 % du terrain (bonus) ; chaque niveau ajoute un ennemi plus rapide.

  Clavier : fleches (direction), Espace (s'arreter dans son territoire),
  P ou Pause (pause), F2 (nouvelle partie), F1 (regles). Le jeu s'arrete
  de lui-meme pendant qu'un menu ou une boite de message est ouvert.
  Parametres : /SEED:n (hasard reproductible, pour les essais) ; /AUTO
  (le joueur est conduit par l'ordinateur : demonstration et essais). }

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
  VK_PAUSE = $0D; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_PAUSE = 102; CM_QUIT = 104;
  CM_SLOW = 111; CM_NORMAL = 112; CM_FAST = 113;
  CM_RULES = 301; CM_ABOUT = 302;
  { terrain : 35 x 25 cases (bords = murs), comme le prototype }
  GW = 35; GH = 25; NCell = 875; Inner = 759;
  TEmpty = 0; TOwned = 1; TTrail = 2; TWall = 3;
  { disposition (zone client, Y vers le bas) }
  Cs = 13; GX = 10; GY = 10;
  PnX = 479; PW = 134;
  CWant = 623; CHWant = 369;
  MaxEn = 6;
  Target = 750;                     { 75,0 % (en dixiemes) }
  PPeriod = 2;                      { le joueur avance tous les 2 tops }

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  G, Shown, Mk, Qu, Prev : Array[0..NCell - 1] Of LongInt;
  Px, Py, PDir, NextDir, TrailLen, SafeX, SafeY, Drawing : LongInt;
  Ex, Ey, EDx, EDy : Array[0..MaxEn - 1] Of LongInt;
  NEn, Score, Lives, Level, Owned, State, Paused, Freeze, Blnk, Tick, Seed, AutoAll, BotLen, Speed : LongInt;
  Msg, Banner, Banner2, LMsg : String;
  BnX1, BnY1, BnX2, BnY2, BnShown, NewBn : LongInt;
  LScore, LLevel, LLives, LTrail, LOwned, LPaused : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;    { police 8 x 16 du VGA (textes agrandis) }
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
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';

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

Function Idx(X, Y : LongInt) : LongInt;
Begin
  Idx := Y * GW + X;
End;

Function PctStr(V : LongInt) : String;
Begin
  PctStr := IStr(V Div 10) + ',' + IStr(V Mod 10) + ' %';
End;

{ deplacement d'une direction (1 haut, 2 bas, 3 gauche, 4 droite) }
Function DirX(D : LongInt) : LongInt;
Begin
  If D = 3 Then DirX := -1 Else If D = 4 Then DirX := 1 Else DirX := 0;
End;

Function DirY(D : LongInt) : LongInt;
Begin
  If D = 1 Then DirY := -1 Else If D = 2 Then DirY := 1 Else DirY := 0;
End;

Function Reverse(D : LongInt) : LongInt;
Begin
  Case D Of
    1 : Reverse := 2;
    2 : Reverse := 1;
    3 : Reverse := 4;
    4 : Reverse := 3;
  Else
    Reverse := 0;
  End;
End;

Function Cell(X, Y : LongInt) : LongInt;
Begin
  If (X < 0) Or (X >= GW) Or (Y < 0) Or (Y >= GH) Then Cell := TWall Else Cell := G[Idx(X, Y)];
End;

{ case bloquante pour un ennemi : mur ou territoire }
Function EBlock(X, Y : LongInt) : Boolean;
Var C : LongInt;
Begin
  C := Cell(X, Y);
  EBlock := (C = TWall) Or (C = TOwned);
End;

Function CountOwned : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NCell - 1 Do If G[K] = TOwned Then Inc(N);
  CountOwned := N;
End;

Function EnemyAt(X, Y : LongInt) : Boolean;
Var K : LongInt;
Begin
  EnemyAt := False;
  For K := 0 To NEn - 1 Do If (Ex[K] = X) And (Ey[K] = Y) Then EnemyAt := True;
End;

{ ==================================================================== }
{ Niveau                                                                }
{ ==================================================================== }

Procedure InitGrid;
Var X, Y : LongInt;
Begin
  For Y := 0 To GH - 1 Do
    For X := 0 To GW - 1 Do
      If (X = 0) Or (X = GW - 1) Or (Y = 0) Or (Y = GH - 1) Then G[Idx(X, Y)] := TWall
      Else G[Idx(X, Y)] := TEmpty;
  { zone de depart au centre (5 x 5) }
  For Y := GH Div 2 - 2 To GH Div 2 + 2 Do
    For X := GW Div 2 - 2 To GW Div 2 + 2 Do G[Idx(X, Y)] := TOwned;
  Owned := CountOwned;
End;

Procedure PlaceEnemy(K : LongInt);
Begin
  Case K Of
    0 : Begin Ex[K] := 5; Ey[K] := 5; End;
    1 : Begin Ex[K] := GW - 6; Ey[K] := GH - 6; End;
    2 : Begin Ex[K] := GW - 6; Ey[K] := 5; End;
    3 : Begin Ex[K] := 5; Ey[K] := GH - 6; End;
    4 : Begin Ex[K] := GW Div 2; Ey[K] := 4; End;
  Else
    Begin Ex[K] := GW Div 2; Ey[K] := GH - 5; End;
  End;
  If Rnd(2) = 0 Then EDx[K] := -1 Else EDx[K] := 1;
  If Rnd(2) = 0 Then EDy[K] := -1 Else EDy[K] := 1;
End;

{ periode des ennemis (en tops) : de plus en plus rapides }
Function EPeriod : LongInt;
Begin
  If Level <= 1 Then EPeriod := 4
  Else If Level <= 3 Then EPeriod := 3
  Else EPeriod := 2;
End;

Procedure SetBanner(S1, S2 : String);
Begin
  Banner := S1; Banner2 := S2; NewBn := 1;
End;

Procedure StartLevel;
Var K : LongInt;
Begin
  InitGrid;
  Px := GW Div 2; Py := GH Div 2; SafeX := Px; SafeY := Py;
  PDir := 0; NextDir := 0; TrailLen := 0; Drawing := 0;
  NEn := Level + 1;
  If NEn > MaxEn Then NEn := MaxEn;
  For K := 0 To NEn - 1 Do PlaceEnemy(K);
  State := 0; Freeze := 0; Tick := 0; BotLen := 0;
  SetBanner('NIVEAU ' + IStr(Level), 'Appuyez sur une fl' + Chr(138) + 'che pour partir');
  Msg := 'Niveau ' + IStr(Level) + ' : ' + IStr(NEn) + ' ennemis. Conqu' + Chr(130) +
         'rez 75 % du terrain.';
End;

{ ==================================================================== }
{ Conquete                                                              }
{ ==================================================================== }

{ marque (Mk = 1) la zone vide atteignable depuis (X, Y) }
Procedure MarkZone(X, Y : LongInt);
Var H, T, I, Cx, Cy, D, Nx, Ny, J : LongInt;
Begin
  I := Idx(X, Y);
  If (G[I] <> TEmpty) Or (Mk[I] <> 0) Then Exit;
  Mk[I] := 1; Qu[0] := I; H := 0; T := 1;
  While H < T Do
  Begin
    I := Qu[H]; Inc(H);
    Cx := I Mod GW; Cy := I Div GW;
    For D := 1 To 4 Do
    Begin
      Nx := Cx + DirX(D); Ny := Cy + DirY(D);
      If (Nx >= 0) And (Nx < GW) And (Ny >= 0) And (Ny < GH) Then
      Begin
        J := Idx(Nx, Ny);
        If (G[J] = TEmpty) And (Mk[J] = 0) Then
        Begin
          Mk[J] := 1; Qu[T] := J; Inc(T);
        End;
      End;
    End;
  End;
End;

Procedure Capture;
Var K, N, Old, Gain : LongInt;
Begin
  Old := Owned;
  { la trace devient territoire }
  For K := 0 To NCell - 1 Do If G[K] = TTrail Then G[K] := TOwned;
  { les zones ou se trouve un ennemi restent libres ; les autres sont
    conquises }
  For K := 0 To NCell - 1 Do Mk[K] := 0;
  For K := 0 To NEn - 1 Do MarkZone(Ex[K], Ey[K]);
  N := 0;
  For K := 0 To NCell - 1 Do
    If (G[K] = TEmpty) And (Mk[K] = 0) Then
    Begin
      G[K] := TOwned;
      Inc(N);
    End;
  Owned := CountOwned;
  Gain := (TrailLen + N) * 10;
  Score := Score + Gain;
  Msg := 'Zone conquise : ' + IStr(Owned - Old) + ' cases, ' + IStr(Gain) + ' points.';
  TrailLen := 0; Drawing := 0; SafeX := Px; SafeY := Py;
  If Owned * 1000 Div Inner >= Target Then
  Begin
    K := (Owned * 1000 Div Inner) * 10 + Lives * 500;
    Score := Score + K;
    State := 3; Freeze := 40;
    SetBanner('BRAVO !', 'Niveau ' + IStr(Level) + ' termin' + Chr(130) + ' : bonus de ' + IStr(K) + ' points');
    Msg := 'Niveau ' + IStr(Level) + ' termin' + Chr(130) + ' avec ' + PctStr(Owned * 1000 Div Inner) +
           ' du terrain ; bonus de ' + IStr(K) + ' points.';
  End;
End;

{ le joueur est touche : une vie de moins, la trace s'efface }
Procedure Hit(Why : String);
Var K : LongInt;
Begin
  If State <> 1 Then Exit;
  For K := 0 To NCell - 1 Do If G[K] = TTrail Then G[K] := TEmpty;
  Dec(Lives);
  TrailLen := 0; Drawing := 0;
  If Lives <= 0 Then
  Begin
    Lives := 0;
    State := 4; Freeze := 0;
    SetBanner('PARTIE TERMIN' + Chr(144) + 'E', 'Pointage : ' + IStr(Score) + '   F2 : nouvelle partie');
    Msg := Why + ' Partie termin' + Chr(130) + 'e au niveau ' + IStr(Level) + ' avec ' + IStr(Score) + ' points.';
    Exit;
  End;
  State := 2; Freeze := 24;
  SetBanner('A' + Chr(130) + 'E !', Why);
  Msg := Why + ' Il vous reste ' + IStr(Lives) + ' vie(s).';
End;

Procedure MovePlayer;
Var Nx, Ny, C : LongInt;
Begin
  If (NextDir <> 0) Then
  Begin
    { pas de demi-tour sur sa propre trace }
    If (Drawing = 0) Or (NextDir <> Reverse(PDir)) Then PDir := NextDir;
    NextDir := 0;
  End;
  If PDir = 0 Then Exit;
  Nx := Px + DirX(PDir); Ny := Py + DirY(PDir);
  C := Cell(Nx, Ny);
  If C = TWall Then
  Begin
    PDir := 0;
    Exit;
  End;
  If C = TTrail Then
  Begin
    Hit('Vous avez recoup' + Chr(130) + ' votre trace !');
    Exit;
  End;
  If (Drawing = 0) And (C = TOwned) Then
  Begin
    SafeX := Nx; SafeY := Ny;
  End;
  Px := Nx; Py := Ny;
  If EnemyAt(Px, Py) And (C <> TOwned) Then
  Begin
    Hit('Un ennemi vous a touch' + Chr(130) + ' !');
    Exit;
  End;
  If C = TOwned Then
  Begin
    If (Drawing <> 0) And (TrailLen > 0) Then Capture
    Else Begin SafeX := Px; SafeY := Py; End;
  End
  Else
  Begin
    Drawing := 1;
    G[Idx(Px, Py)] := TTrail;
    Inc(TrailLen);
  End;
End;

Procedure MoveEnemies;
Var K, X, Y, Bx, By : LongInt;
Begin
  For K := 0 To NEn - 1 Do
  Begin
    X := Ex[K]; Y := Ey[K];
    { rebond (comme une bille) sur les murs et le territoire }
    If EBlock(X + EDx[K], Y + EDy[K]) Then
    Begin
      Bx := 0; By := 0;
      If EBlock(X + EDx[K], Y) Then Bx := 1;
      If EBlock(X, Y + EDy[K]) Then By := 1;
      If (Bx = 0) And (By = 0) Then
      Begin
        Bx := 1; By := 1;
      End;
      If Bx <> 0 Then EDx[K] := -EDx[K];
      If By <> 0 Then EDy[K] := -EDy[K];
    End;
    If Not EBlock(X + EDx[K], Y + EDy[K]) Then
    Begin
      Ex[K] := X + EDx[K]; Ey[K] := Y + EDy[K];
    End;
    If State = 1 Then
    Begin
      If (Ex[K] = Px) And (Ey[K] = Py) And (Cell(Px, Py) <> TOwned) Then
        Hit('Un ennemi vous a touch' + Chr(130) + ' !')
      Else If Cell(Ex[K], Ey[K]) = TTrail Then
        Hit('Un ennemi a coup' + Chr(130) + ' votre trace !');
    End;
  End;
End;

{ ==================================================================== }
{ Pilote automatique (/AUTO)                                            }
{ ==================================================================== }

{ premier pas du plus court chemin vers le territoire (sans la trace) }
Function PathHome : LongInt;
Var H, T, I, J, D, Nx, Ny, S : LongInt;
Begin
  PathHome := 0;
  For I := 0 To NCell - 1 Do Prev[I] := -1;
  S := Idx(Px, Py);
  Prev[S] := S; Qu[0] := S; H := 0; T := 1;
  While H < T Do
  Begin
    I := Qu[H]; Inc(H);
    If (I <> S) And (G[I] = TOwned) Then
    Begin
      While Prev[I] <> S Do I := Prev[I];
      For D := 1 To 4 Do
        If Idx(Px + DirX(D), Py + DirY(D)) = I Then PathHome := D;
      Exit;
    End;
    For D := 1 To 4 Do
    Begin
      Nx := I Mod GW + DirX(D); Ny := I Div GW + DirY(D);
      If (Cell(Nx, Ny) = TEmpty) Or (Cell(Nx, Ny) = TOwned) Then
      Begin
        J := Idx(Nx, Ny);
        If Prev[J] < 0 Then
        Begin
          Prev[J] := I; Qu[T] := J; Inc(T);
        End;
      End;
    End;
  End;
End;

Function EnemyNear(X, Y : LongInt) : Boolean;
Var K : LongInt;
Begin
  EnemyNear := False;
  For K := 0 To NEn - 1 Do
    If (Abs(Ex[K] - X) <= 2) And (Abs(Ey[K] - Y) <= 2) Then EnemyNear := True;
End;

Procedure BotThink;
Var D, C, N, K : LongInt; Ok : Array[1..4] Of LongInt;
Begin
  If Drawing = 0 Then
  Begin
    C := TWall;
    If PDir <> 0 Then C := Cell(Px + DirX(PDir), Py + DirY(PDir));
    If (PDir = 0) Or (C = TWall) Or (Rnd(5) = 0) Then
    Begin
      N := 0;
      For D := 1 To 4 Do
        If Cell(Px + DirX(D), Py + DirY(D)) <> TWall Then
        Begin
          Inc(N); Ok[N] := D;
        End;
      If N > 0 Then PDir := Ok[1 + Rnd(N)];
      BotLen := 2 + Rnd(7);
    End;
  End
  Else
  Begin
    C := Cell(Px + DirX(PDir), Py + DirY(PDir));
    If (TrailLen >= BotLen) Or (C = TWall) Or (C = TTrail) Or EnemyNear(Px, Py) Then
    Begin
      K := PathHome;
      If K <> 0 Then PDir := K;
    End;
  End;
  NextDir := 0;
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

{ case de terrain (code : 0..3 = tuile ; + 10 joueur ; + 20 ennemi) }
Procedure DrawCell(I, Code : LongInt);
Var X, Y, T, Cx, Cy : LongInt;
Begin
  X := GX + (I Mod GW) * Cs; Y := GY + (I Div GW) * Cs;
  T := Code Mod 10;
  Case T Of
    TEmpty :
      Begin
        FBar(X, Y, X + Cs - 2, Y + Cs - 2, CLR_DARKGRAY);
        FBar(X + Cs - 1, Y, X + Cs - 1, Y + Cs - 1, CLR_BLACK);
        FBar(X, Y + Cs - 1, X + Cs - 2, Y + Cs - 1, CLR_BLACK);
      End;
    TOwned :
      Begin
        FBar(X, Y, X + Cs - 1, Y + Cs - 1, CLR_BLUE);
        FBar(X + Cs - 1, Y, X + Cs - 1, Y + Cs - 1, CLR_DARKBLUE);
        FBar(X, Y + Cs - 1, X + Cs - 1, Y + Cs - 1, CLR_DARKBLUE);
        FBar(X + 3, Y + 3, X + 4, Y + 4, CLR_CYAN);
      End;
    TTrail :
      Begin
        FBar(X, Y, X + Cs - 1, Y + Cs - 1, CLR_CYAN);
        FBar(X + Cs - 1, Y, X + Cs - 1, Y + Cs - 1, CLR_DARKCYAN);
        FBar(X, Y + Cs - 1, X + Cs - 1, Y + Cs - 1, CLR_DARKCYAN);
      End;
  Else
    Begin
      FBar(X, Y, X + Cs - 1, Y + Cs - 1, CLR_PALEGRAY);
      Edge(X, Y, X + Cs - 1, Y + Cs - 1, CLR_WHITE, CLR_DARKGRAY);
    End;
  End;
  Cx := X + Cs Div 2; Cy := Y + Cs Div 2;
  If Code >= 20 Then
  Begin
    { ennemi : bille rouge avec deux yeux }
    Disc(Cx, Cy, 5, CLR_BLACK);
    Disc(Cx, Cy, 4, CLR_RED);
    FBar(Cx - 3, Cy - 2, Cx - 2, Cy - 1, CLR_WHITE);
    FBar(Cx + 1, Cy - 2, Cx + 2, Cy - 1, CLR_WHITE);
  End
  Else If Code >= 10 Then
  Begin
    { joueur : disque jaune avec reflet }
    Disc(Cx, Cy, 5, CLR_BLACK);
    Disc(Cx, Cy, 4, CLR_YELLOW);
    FBar(Cx - 2, Cy - 2, Cx - 1, Cy - 1, CLR_WHITE);
  End;
End;

Function CodeOf(I : LongInt) : LongInt;
Var C, K : LongInt;
Begin
  C := G[I];
  If (I = Idx(Px, Py)) And ((State <> 2) Or (Blnk = 0)) Then C := C + 10;
  For K := 0 To NEn - 1 Do
    If I = Idx(Ex[K], Ey[K]) Then C := (C Mod 10) + 20;
  CodeOf := C;
End;

{ bandeau au milieu du terrain (pause, niveau, vie perdue, fin) }
Procedure DrawBanner;
Var W, X, Y, L1, L2 : LongInt;
Begin
  L1 := Length(Banner) * 16; L2 := Length(Banner2) * 8;
  W := L1;
  If L2 > W Then W := L2;
  W := W + 32;
  X := GX + (GW * Cs - W) Div 2; Y := GY + (GH * Cs - 68) Div 2;
  BnX1 := X; BnY1 := Y; BnX2 := X + W - 1; BnY2 := Y + 67; BnShown := 1;
  FBar(X + 3, Y + 3, X + W + 2, Y + 70, CLR_BLACK);
  FBar(X, Y, X + W - 1, Y + 67, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + 67, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + 66, CLR_PALEGRAY, CLR_DARKGRAY);
  BigText(X + (W - L1) Div 2, Y + 8, Banner, CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(X + (W - L2) Div 2, Y + 44, Banner2, CLR_BLACK, CLR_PALEGRAY);
End;

{ le bandeau disparait : les cases dessous seront redessinees }
Procedure ClearBanner;
Var X, Y, X1, Y1, X2, Y2 : LongInt;
Begin
  If BnShown = 0 Then Exit;
  BnShown := 0;
  X1 := (BnX1 - GX) Div Cs - 1; X2 := (BnX2 + 4 - GX) Div Cs + 1;
  Y1 := (BnY1 - GY) Div Cs - 1; Y2 := (BnY2 + 4 - GY) Div Cs + 1;
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > GW - 1 Then X2 := GW - 1;
  If Y2 > GH - 1 Then Y2 := GH - 1;
  For Y := Y1 To Y2 Do
    For X := X1 To X2 Do Shown[Idx(X, Y)] := -1;
End;

{ bouton poussoir de PM }
Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ parties du panneau qui changent (redessinees si besoin) }
Procedure DrawDyn(All : Boolean);
Var S : String; K, W : LongInt;
Begin
  If All Or (LScore <> Score) Then
  Begin
    FBar(PnX + 3, GY + 66, PnX + PW - 4, GY + 98, CLR_WHITE);
    S := IStr(Score);
    BigText(PnX + PW - 8 - Length(S) * 16, GY + 66, S, CLR_DARKBLUE, CLR_WHITE);
    LScore := Score;
  End;
  If All Or (LLevel <> Level) Then
  Begin
    S := 'Niveau : ' + IStr(Level) + '   ';
    OutTxt(PnX, GY + 112, S, CLR_BLACK, CLR_PALEGRAY);
    LLevel := Level;
  End;
  If All Or (LLives <> Lives) Then
  Begin
    OutTxt(PnX, GY + 132, 'Vies :', CLR_BLACK, CLR_PALEGRAY);
    FBar(PnX + 52, GY + 132, PnX + PW - 1, GY + 147, CLR_PALEGRAY);
    For K := 0 To Lives - 1 Do
      If K < 6 Then
      Begin
        Disc(PnX + 60 + K * 14, GY + 140, 5, CLR_BLACK);
        Disc(PnX + 60 + K * 14, GY + 140, 4, CLR_YELLOW);
      End;
    LLives := Lives;
  End;
  If All Or (LTrail <> TrailLen) Then
  Begin
    S := 'Trace : ' + IStr(TrailLen) + '    ';
    OutTxt(PnX, GY + 152, S, CLR_BLACK, CLR_PALEGRAY);
    LTrail := TrailLen;
  End;
  If All Or (LOwned <> Owned) Then
  Begin
    K := Owned * 1000 Div Inner;
    S := 'Terrain : ' + PctStr(K) + '  ';
    OutTxt(PnX, GY + 180, S, CLR_BLACK, CLR_PALEGRAY);
    { barre de progression (le trait rouge marque l'objectif de 75 %) }
    Edge(PnX, GY + 200, PnX + PW - 1, GY + 215, CLR_DARKGRAY, CLR_WHITE);
    FBar(PnX + 1, GY + 201, PnX + PW - 2, GY + 214, CLR_WHITE);
    W := (PW - 2) * K Div 1000;
    If W > 0 Then FBar(PnX + 1, GY + 201, PnX + W, GY + 214, CLR_BLUE);
    W := (PW - 2) * Target Div 1000;
    FBar(PnX + 1 + W, GY + 199, PnX + 2 + W, GY + 216, CLR_RED);
    LOwned := Owned;
  End;
  If All Or (LPaused <> Paused) Then
  Begin
    If Paused <> 0 Then Button(PnX, GY + 274, PW, 28, 'Reprendre')
    Else Button(PnX, GY + 274, PW, 28, 'Pause');
    LPaused := Paused;
  End;
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 7 * 16) Div 2, GY + 2, 'TILEMAN', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, GY + 44, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, GY + 62, PnX + PW - 1, GY + 102, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, GY + 63, PnX + PW - 2, GY + 101, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, GY + 64, PnX + PW - 3, GY + 100, CLR_WHITE);
  Button(PnX, GY + 238, PW, 28, 'Nouvelle partie');
  DrawDyn(True);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
  LMsg := Msg;
End;

{ met l'ecran a jour : seulement ce qui a change }
Procedure SyncAll;
Var K, C : LongInt;
Begin
  For K := 0 To NCell - 1 Do
  Begin
    C := CodeOf(K);
    If C <> Shown[K] Then
    Begin
      DrawCell(K, C);
      Shown[K] := C;
    End;
  End;
  If (Banner <> '') And (BnShown = 0) Then DrawBanner;
  DrawDyn(False);
  If Msg <> LMsg Then DrawStatus;
End;

Procedure Sync;
Begin
  If Client = 0 Then Exit;
  If (Banner = '') Or (NewBn <> 0) Then ClearBanner;
  NewBn := 0;
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
  Edge(GX - 2, GY - 2, GX + GW * Cs + 1, GY + GH * Cs + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(GX - 1, GY - 1, GX + GW * Cs, GY + GH * Cs, CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To NCell - 1 Do Shown[K] := -1;
  BnShown := 0;
  DrawPanel;
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
  SetMark(CM_PAUSE, Paused <> 0);
  SetMark(CM_SLOW, Speed = 0); SetMark(CM_NORMAL, Speed = 1); SetMark(CM_FAST, Speed = 2);
End;

Procedure NewGame;
Begin
  Score := 0; Lives := 3; Level := 1; Paused := 0;
  StartLevel;
  SetMarks;
  Redraw;
End;

Procedure GameOverBox;
Var S : String;
Begin
  S := 'Partie termin' + Chr(130) + 'e au niveau ' + IStr(Level) + ' avec ' + IStr(Score) + ' points (' +
       PctStr(Owned * 1000 Div Inner) + ' du terrain).' + Chr(10) + Chr(10) + 'Une nouvelle partie ?';
  If Ask(S, 'TileMan', MB_YESNO Or MB_QUERY) = MBID_YES Then NewGame;
End;

Procedure SetPause(P : LongInt);
Begin
  If (P <> 0) And (State <> 1) Then Exit;
  If P = Paused Then Exit;
  Paused := P;
  If P <> 0 Then
  Begin
    SetBanner('PAUSE', 'P ou Pause : reprendre la partie');
    Msg := 'Partie en pause.';
  End
  Else
  Begin
    SetBanner('', '');
    Msg := 'Partie reprise.';
  End;
  SetMarks;
  Sync;
End;

{ un top de la minuterie }
Procedure GameTick;
Begin
  If Paused <> 0 Then Exit;
  If (State = 0) And (AutoAll <> 0) Then
  Begin
    State := 1;
    SetBanner('', '');
  End;
  If (State = 0) Or (State = 4) Then
  Begin
    If (State = 4) And (AutoAll <> 0) Then
    Begin
      Inc(Freeze);
      If Freeze > 40 Then NewGame;
    End;
    Exit;
  End;
  Inc(Tick);
  If (State = 2) Or (State = 3) Then
  Begin
    Dec(Freeze);
    Blnk := (Freeze Div 3) Mod 2;
    If Freeze <= 0 Then
    Begin
      Blnk := 0;
      If State = 2 Then
      Begin
        { on repart du point de sortie du territoire }
        Px := SafeX; Py := SafeY; PDir := 0; NextDir := 0;
        State := 1;
        SetBanner('', '');
      End
      Else
      Begin
        Inc(Level);
        StartLevel;
      End;
    End;
    Sync;
    Exit;
  End;
  If Tick Mod PPeriod = 0 Then
  Begin
    If AutoAll <> 0 Then BotThink;
    MovePlayer;
  End;
  If (State = 1) And (Tick Mod EPeriod = 0) Then MoveEnemies;
  Sync;
  If (State = 4) And (AutoAll = 0) Then GameOverBox;
End;

Procedure SetSpeed(S : LongInt);
Begin
  Speed := S;
  Case S Of
    0 : Dummy := WinStartTimer(Hab, Client, 1, 75);
    2 : Dummy := WinStartTimer(Hab, Client, 1, 35);
  Else
    Dummy := WinStartTimer(Hab, Client, 1, 50);
  End;
  SetMarks;
End;

Procedure Steer(D : LongInt);
Begin
  If (Paused <> 0) Or (State = 4) Then Exit;
  If State = 0 Then
  Begin
    State := 1;
    SetBanner('', '');
    Msg := 'Sortez de votre territoire (bleu) et revenez-y pour conqu' + Chr(130) + 'rir du terrain.';
  End;
  NextDir := D;
  Sync;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PAUSE : SetPause(1 - Paused);
    CM_SLOW : SetSpeed(0);
    CM_NORMAL : SetSpeed(1);
    CM_FAST : SetSpeed(2);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Begin
      LClr;
      LAdd('' + 'Conqu' + Chr(130) + 'rez 75 % du terrain pour passer au niveau suivant. ' +
           'Votre disque jaune part de votre territoire (bleu) ; en dehors, il laisse ');
      LAdd('' + 'une trace (cyan). Revenez dans votre territoire : la trace et toutes les ' + 'zones ferm' +
           Chr(130) + 'es sans ennemi deviennent ' + Chr(133) + ' vous.' + Chr(10) +
           'Une vie de moins si un ennemi (rouge) vous touche ou touche votre trace, ou ');
      LAdd('' + 'si vous recoupez votre trace. Trois vies ; chaque niveau ajoute un ennemi ' + 'plus rapide.' +
           Chr(10) + Chr(10) + 'Clavier : fl' + Chr(138) + 'ches (direction), Espace (s''arr' + Chr(136) +
           'ter dans son territoire), P ou Pause, F2 (nouvelle partie).');
      Dummy := LMsgBox('TileMan - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    End;
    CM_ABOUT : Dummy := Ask('TileMan pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'TILEMAN.PAS de 7iles.' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos de TileMan', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= GY + 238) And (Y < GY + 266) Then NewGame
    Else If (Y >= GY + 274) And (Y < GY + 302) Then SetPause(1 - Paused);
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
    If Vk = VK_UP Then Begin Steer(1); Exit; End;
    If Vk = VK_DOWN Then Begin Steer(2); Exit; End;
    If Vk = VK_LEFT Then Begin Steer(3); Exit; End;
    If Vk = VK_RIGHT Then Begin Steer(4); Exit; End;
    If Vk = VK_PAUSE Then Begin SetPause(1 - Paused); Exit; End;
  End;
  If ((Fl And KC_CHAR) = 0) Or ((Fl And KC_ALT) <> 0) Or ((Fl And KC_CTRL) <> 0) Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Ch = 80) Or (Ch = 112) Then SetPause(1 - Paused)    { P }
  Else If (Ch = 78) Or (Ch = 110) Then NewGame            { N (comme le prototype) }
  Else If Ch = 32 Then
  Begin
    { Espace : s'arreter (seulement dans son territoire) }
    If Drawing = 0 Then
    Begin
      PDir := 0; NextDir := 0;
    End;
  End
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
    WM_TIMER :
      If Lo16(Mp1) = 1 Then
        { arret de fait pendant les menus et les boites de message }
        If WinQueryFocus(HWND_DESKTOP) = Client Then GameTick;
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
  Msg := ''; LMsg := ''; AutoAll := 0; Speed := 1; Banner := ''; Banner2 := ''; BnShown := 0; NewBn := 0;
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
  Dummy := WinRegisterClass(Hab, Z('TILEMAN'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Score := 0; Lives := 3; Level := 1; Paused := 0;
  StartLevel;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('TILEMAN'), Z2('TileMan'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_PAUSE, '~Pause' + Chr(9) + 'P');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_SLOW, 'Vitesse ~lente');
  MItem(MIS_TEXT, MIA_CHECKED, CM_NORMAL, 'Vitesse n~ormale');
  MItem(MIS_TEXT, 0, CM_FAST, 'Vitesse ~rapide');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 8);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de TileMan');
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
  SetMarks;
  SetSpeed(1);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
