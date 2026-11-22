{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BINGO - Bingo a 75 boules pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau).
}

Program BINGO;

{$R-,S-,I-}

{ Compilation : OS2PC BINGO.PAS   (produit BINGO.EXE)

  Portage vers OS/2-0 du prototype BINGO.PAS du depot 7iles (Turbo
  Pascal, BGI en 640 x 480, clavier seulement) : fenetre de Presentation
  Manager avec menus, salle de bingo dessinee dans une image en memoire
  recopiee par GpiDrawBits (seules les zones qui changent sont
  recopiees), carton de papier avec les lettres B I N G O sur des
  boules de couleur, case libre etoilee, marques d'encreur, boule tiree
  qui roule jusqu'a sa place, dernieres boules, tableau des 75 numeros,
  cartons des adversaires, bandeau du resultat, boutons, barre d'etat et
  apparence d'OS/2 Warp 3.

  Comme le prototype : bingo a 75 boules, colonnes B (1 a 15), I (16 a
  30), N (31 a 45), G (46 a 60) et O (61 a 75), case centrale libre ; le
  premier carton qui complete une ligne, une colonne ou une diagonale
  gagne ; tirage a la demande (Espace) ou automatique (A).
  Ce qui est corrige : le joueur n'avait rien a faire (ses numeros etaient
  marques pour lui : c'est maintenant une option) ; quand les deux
  cartons gagnaient sur la meme boule, le joueur l'emportait toujours
  (le bingo est maintenant partage) ; le tirage au hasard par essais
  successifs pouvait echouer et finir la partie avant la 75e boule (les
  boules sont melangees une fois) ; le mode automatique bloquait le
  programme deux secondes par boule ; le curseur du carton ne servait a
  rien.
  Ce qui s'ajoute : on marque soi-meme ses numeros (clic ou Entree) et on
  crie BINGO (bouton ou touche B) ; un faux bingo est refuse ; les
  ordinateurs crient bingo apres un court delai (on peut les prendre de
  vitesse) ; de 1 a 3 adversaires ; tableau des numeros sortis ;
  manches successives et score de la seance ; demonstration ; bruitages.

  Souris : cliquer une case de son carton pour la marquer, les boutons
  sous la salle. Clavier : Espace (tirer une boule), fleches (curseur),
  Entree (marquer la case), B (bingo !), A (tirage automatique), N ou F2
  (nouvelle manche), F1 (regles).
  Parametres : /SEED:n ; /AUTO (demonstration) ; /NOSOUND ; /TEST (essais
  des cartons, des lignes gagnantes, du marquage et du tirage, puis 60
  manches jouees par l'ordinateur, resultat sur le port serie COM1). }

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
  VK_NEWLINE = $08; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_DRAW = 102; CM_BINGO = 103; CM_QUIT = 104;
  CM_AUTODRAW = 201; CM_AUTODAUB = 202; CM_OPP1 = 203; CM_OPP2 = 204; CM_OPP3 = 205; CM_SOUND = 206; CM_AUTO = 207;
  CM_RULES = 301; CM_ABOUT = 302;
  { image de la salle }
  BW = 608; BH = 368; OX = 8; OY = 8;
  CWant = 624; CHWant = 436;
  BtnY = 382; BtnW = 148; BtnH = 26;
  { carton du joueur }
  GX = 30; GY = 70; Cell = 48;
  { boule tiree, dernieres boules, tableau, adversaires }
  BallX = 338; BallY = 60; BallR = 36;
  RecX = 414; RecY = 82; RecR = 15;
  BdX = 300; BdY = 118; BdRow = 21; BdCol = 18;
  OpY = 236; OpW = 98; OpCell = 15;
  NBall = 75; NCard = 4;
  { couleurs de l'image }
  C_BG = 0;                                   { 0..15 : fond de la salle }
  C_WHITE = 16; C_BLACK = 17; C_SHADOW = 18; C_PAPER = 19; C_PAPER2 = 20; C_GRID = 21; C_INK = 22; C_GOLD = 23;
  C_GOLD2 = 24; C_TEXT = 25; C_DIM = 26; C_DAUB = 27; C_DAUB2 = 28; C_DAUBT = 29; C_CURSOR = 30; C_BANNER = 31;
  C_SLOT = 32; C_SLOTT = 33; C_LIT = 34; C_LITT = 35; C_RED = 36; C_GREEN = 37; C_YEL = 38; C_HEAD = 39;
  C_GRAY = 40; C_STAR = 41; C_WOOD = 42; C_WOOD2 = 43;
  C_BALL = 48;                                { 48 + lettre * 8 + nuance (0 sombre .. 7 reflet) }
  { etats }
  S_PLAY = 0; S_OVER = 1;
  SndRate = 11025;
  ClaimDelay = 50;                            { delai des ordinateurs (x 30 ms) }
  DrawDelay = 100;                            { tirage automatique (x 30 ms) }
  LetterS : String[5] = 'BINGO';
  BallBase : Array[0..4] Of LongInt = ($2462D0, $D43030, $E8E8E8, $2C9C44, $F0B020);

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Prv : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { cartons : Card[c * 25 + rangee * 5 + colonne] ; 0 = case libre }
  Card : Array[0..NCard * 25 - 1] Of LongInt;
  Dab, WinM : Array[0..NCard - 1] Of LongInt;       { cases marquees, ligne gagnante : masques de 25 bits }
  Bag : Array[0..NBall - 1] Of LongInt;
  Called : Array[0..NBall] Of Byte;
  Lines : Array[0..11] Of LongInt;
  NDrawn, CurBall, State, NOpp, Seed, AutoDaub, AutoDraw, AutoAll, SoundOn, TestMode, Tick : LongInt;
  CurX, CurY, ClaimAt, DrawAt, Winners, PlayerWon, FalseBingos, Missed : LongInt;
  Rounds, WinsP, WinsC, Shared, BallsSum : LongInt;
  AnimF, DaubCell, DaubF, Dirty, LastBtn, OverWait : LongInt;
  Banner, Banner2, Banner3, Msg, LastMsg : String;
  BannerC : LongInt;
  { bruitages }
  SndBuf : Array[0..39999] Of Byte;
  SndOfs, SndLen, SndPri : Array[0..15] Of LongInt;
  NSndBuf, SndPrio, SndCur, SndEnd : LongInt;
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
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';
Function VioGetFont(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMPLAY';

Type
  PByte = ^Byte;
  PLong = ^LongInt;

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
{ Regles : cartons, tirage, lignes gagnantes                            }
{ ==================================================================== }

Function Bit(M, I : LongInt) : LongInt;
Begin
  Bit := (M Shr I) And 1;
End;

Function PopCount(M : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  While M <> 0 Do
  Begin
    If (M And 1) <> 0 Then Inc(N);
    M := M Shr 1;
  End;
  PopCount := N;
End;

{ lettre (0..4) du numero N }
Function ColOf(N : LongInt) : LongInt;
Begin
  If (N < 1) Or (N > NBall) Then ColOf := 0 Else ColOf := (N - 1) Div 15;
End;

Function BallName(N : LongInt) : String;
Begin
  BallName := LetterS[ColOf(N) + 1] + '-' + IStr(N);
End;

{ les 12 lignes gagnantes : 5 rangees, 5 colonnes, 2 diagonales }
Procedure InitLines;
Var I, K : LongInt;
Begin
  For I := 0 To 4 Do
  Begin
    Lines[I] := 0; Lines[5 + I] := 0;
    For K := 0 To 4 Do
    Begin
      Lines[I] := Lines[I] Or (1 Shl (I * 5 + K));
      Lines[5 + I] := Lines[5 + I] Or (1 Shl (K * 5 + I));
    End;
  End;
  Lines[10] := 0; Lines[11] := 0;
  For K := 0 To 4 Do
  Begin
    Lines[10] := Lines[10] Or (1 Shl (K * 5 + K));
    Lines[11] := Lines[11] Or (1 Shl (K * 5 + 4 - K));
  End;
End;

{ cases gagnantes (union des lignes completes) du masque M ; 0 : aucune }
Function BingoMask(M : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  For I := 0 To 11 Do
    If (M And Lines[I]) = Lines[I] Then R := R Or Lines[I];
  BingoMask := R;
End;

{ nombre minimal de numeros qui manquent pour une ligne }
Function Missing(M : LongInt) : LongInt;
Var I, B, K : LongInt;
Begin
  B := 5;
  For I := 0 To 11 Do
  Begin
    K := 5 - PopCount(M And Lines[I]);
    If K < B Then B := K;
  End;
  Missing := B;
End;

{ carton C : 5 numeros distincts par colonne dans la plage de sa lettre,
  tries de haut en bas ; case centrale libre }
Procedure MakeCard(C : LongInt);
Var Col, Row, K, N, T, Ok : LongInt;
Begin
  For Col := 0 To 4 Do
  Begin
    For Row := 0 To 4 Do
    Begin
      Repeat
        N := Col * 15 + 1 + Rnd(15);
        Ok := 1;
        For K := 0 To Row - 1 Do
          If Card[C * 25 + K * 5 + Col] = N Then Ok := 0;
      Until Ok = 1;
      Card[C * 25 + Row * 5 + Col] := N;
    End;
    { tri de la colonne (comme les vrais cartons) }
    For Row := 0 To 3 Do
      For K := Row + 1 To 4 Do
        If Card[C * 25 + K * 5 + Col] < Card[C * 25 + Row * 5 + Col] Then
        Begin
          T := Card[C * 25 + K * 5 + Col];
          Card[C * 25 + K * 5 + Col] := Card[C * 25 + Row * 5 + Col];
          Card[C * 25 + Row * 5 + Col] := T;
        End;
  End;
  Card[C * 25 + 12] := 0;
  Dab[C] := 1 Shl 12;
  WinM[C] := 0;
End;

{ melange des 75 boules (une fois par manche) }
Procedure ShuffleBag;
Var K, J, T : LongInt;
Begin
  For K := 0 To NBall - 1 Do Bag[K] := K + 1;
  For K := NBall - 1 DownTo 1 Do
  Begin
    J := Rnd(K + 1);
    T := Bag[K]; Bag[K] := Bag[J]; Bag[J] := T;
  End;
  For K := 0 To NBall Do Called[K] := 0;
  NDrawn := 0; CurBall := 0;
End;

{ case du numero N sur le carton C ; -1 : absent }
Function FindNum(C, N : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To 24 Do
    If (K <> 12) And (Card[C * 25 + K] = N) Then R := K;
  FindNum := R;
End;

{ marquage automatique du carton du joueur (option, ou demonstration) }
Function AutoMark : Boolean;
Begin
  AutoMark := (AutoDaub <> 0) Or (AutoAll <> 0);
End;

{ tire la boule suivante ; les ordinateurs (et le joueur avec le
  marquage automatique) la marquent tout de suite }
Function DrawBall : LongInt;
Var N, C, K, R : LongInt;
Begin
  R := 0;
  If NDrawn < NBall Then
  Begin
    N := Bag[NDrawn];
    Inc(NDrawn);
    Called[N] := 1;
    CurBall := N;
    For C := 0 To NOpp Do
      If (C > 0) Or AutoMark Then
      Begin
        K := FindNum(C, N);
        If K >= 0 Then Dab[C] := Dab[C] Or (1 Shl K);
      End;
    R := N;
  End;
  DrawBall := R;
End;

{ le joueur marque la case K de son carton : 1 fait, 0 deja marquee,
  -1 numero pas encore sorti }
Function Daub(K : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If (K >= 0) And (K <= 24) And (Bit(Dab[0], K) = 0) Then
  Begin
    If Called[Card[K]] <> 0 Then
    Begin
      Dab[0] := Dab[0] Or (1 Shl K);
      R := 1;
    End
    Else R := -1;
  End;
  Daub := R;
End;

{ ordinateurs qui ont un bingo : masque des cartons 1..NOpp (bit C) }
Function CpuBingos : LongInt;
Var C, R : LongInt;
Begin
  R := 0;
  For C := 1 To NOpp Do
    If BingoMask(Dab[C]) <> 0 Then R := R Or (1 Shl C);
  CpuBingos := R;
End;

{ ==================================================================== }
{ Dessin dans la fenetre (boutons, barre d'etat)                        }
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

Procedure InitPal;
Var I, K, C : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 15 Do SetPal(C_BG + I, Mix($10163A, $2E3E86, I, 15));
  SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $101010); SetPal(C_SHADOW, $070A1C); SetPal(C_PAPER, $FFF8E6);
  SetPal(C_PAPER2, $F0E4C8); SetPal(C_GRID, $B8A47C); SetPal(C_INK, $1C2448); SetPal(C_GOLD, $F0C83C);
  SetPal(C_GOLD2, $A0801C); SetPal(C_TEXT, $D4DCFF); SetPal(C_DIM, $5A68A8); SetPal(C_DAUB, $F07CB4);
  SetPal(C_DAUB2, $D8488C); SetPal(C_DAUBT, $5A0A34); SetPal(C_CURSOR, $1C8CFF); SetPal(C_BANNER, $141C48);
  SetPal(C_SLOT, $1A2250); SetPal(C_SLOTT, $56628E); SetPal(C_LIT, $FFD84A); SetPal(C_LITT, $3A2A00);
  SetPal(C_RED, $E8463C); SetPal(C_GREEN, $6CE890); SetPal(C_YEL, $FFE04A); SetPal(C_HEAD, $22306E);
  SetPal(C_GRAY, $9098B8); SetPal(C_STAR, $F2B418); SetPal(C_WOOD, $6A3A16); SetPal(C_WOOD2, $9C5E2A);
  For K := 0 To 4 Do
  Begin
    C := BallBase[K];
    For I := 0 To 7 Do
      If I <= 5 Then SetPal(C_BALL + K * 8 + I, Mix(Mix(C, $000000, 6, 10), C, I, 5))
      Else SetPal(C_BALL + K * 8 + I, Mix(C, $FFFFFF, (I - 5) * 4, 10));
  End;
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

Procedure Frame2(X1, Y1, X2, Y2, C : LongInt);
Begin
  Rect(X1, Y1, X2, Y1, C); Rect(X1, Y2, X2, Y2, C);
  Rect(X1, Y1, X1, Y2, C); Rect(X2, Y1, X2, Y2, C);
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

Procedure RRect(X1, Y1, X2, Y2, R, C : LongInt);
Var Y, D, W : LongInt;
Begin
  For Y := Y1 To Y2 Do
  Begin
    D := 0;
    If Y < Y1 + R Then D := Y1 + R - Y;
    If Y > Y2 - R Then D := Y - (Y2 - R);
    If D > 0 Then W := R - Round(Sqrt(R * R - D * D + 0.0)) Else W := 0;
    Rect(X1 + W, Y, X2 - W, Y, C);
  End;
End;

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
          Else Rect(X + ((I - 1) * 8 + K) * Sc, Y + R * Sc, X + ((I - 1) * 8 + K) * Sc + Sc - 1, Y + R * Sc + Sc - 1, C);
        End;
    End;
End;

Procedure FbTextSh(X, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(X + 1, Y + 1, S, C_SHADOW, Sc);
  If Sc > 1 Then FbText(X + 2, Y + 2, S, C_SHADOW, Sc);
  FbText(X, Y, S, C, Sc);
End;

Procedure FbCenter(Cx, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbTextSh(Cx - Length(S) * 4 * Sc, Y, S, C, Sc);
End;

{ chiffres etroits (colonnes 1 a 6 de la police, 7 points par chiffre),
  centres en Cx : pour le tableau des numeros }
Procedure FbNarrow(Cx, Y : LongInt; S : String; C : LongInt);
Var I, R, K, B, X : LongInt;
Begin
  If FontH = 0 Then Exit;
  X := Cx - (Length(S) * 7 - 1) Div 2;
  For I := 1 To Length(S) Do
    For R := 0 To FontH - 1 Do
    Begin
      B := Font[Ord(S[I]) * FontH + R];
      For K := 1 To 6 Do
        If (B And ($80 Shr K)) <> 0 Then Pix(X + (I - 1) * 7 + K - 1, Y + R, C);
    End;
End;

{ texte centre sans ombre }
Procedure FbMid(Cx, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(Cx - Length(S) * 4 * Sc, Y, S, C, Sc);
End;

{ ==================================================================== }
{ Boules, carton, tableau                                               }
{ ==================================================================== }

{ boule de la lettre L (0..4) : sphere eclairee en haut a gauche,
  etiquette blanche au centre avec le numero N (0 : la lettre seule) }
Procedure PaintBall(Cx, Cy, R, L, N : LongInt);
Var X, Y, D2, S, Hx, Hy, Lr : LongInt; D : Real; T : String;
Begin
  Disc(Cx + R Div 6, Cy + R Div 5, R, C_SHADOW);
  Hx := Cx - R Div 3; Hy := Cy - R Div 3;
  For Y := -R To R Do
    For X := -R To R Do
    Begin
      D2 := X * X + Y * Y;
      If D2 <= R * R + R Then
      Begin
        D := Sqrt((Cx + X - Hx) * (Cx + X - Hx) + (Cy + Y - Hy) * (Cy + Y - Hy) + 0.0) / (R * 1.5);
        S := 7 - Round(D * 8);
        If S < 0 Then S := 0;
        If S > 7 Then S := 7;
        If D2 > (R - 1) * (R - 1) Then S := MaxI(0, S - 2);
        Pix(Cx + X, Cy + Y, C_BALL + L * 8 + S);
      End;
    End;
  { reflet }
  Disc(Hx, Hy, MaxI(1, R Div 7), C_WHITE);
  { etiquette }
  Lr := R * 11 Div 20;
  If N = 0 Then Lr := R * 13 Div 20;
  Disc(Cx, Cy, Lr + 1, C_GRAY);
  Disc(Cx, Cy, Lr, C_WHITE);
  If N = 0 Then
  Begin
    T := LetterS[L + 1];
    If R >= 16 Then FbMid(Cx + 1, Cy - 15, T, C_INK, 2) Else FbMid(Cx + 1, Cy - 7, T, C_INK, 1);
  End
  Else If R >= 30 Then
  Begin
    T := LetterS[L + 1];
    FbMid(Cx + 1, Cy - 18, T, C_INK, 1);
    T := IStr(N);
    FbMid(Cx + 1, Cy - 4, T, C_INK, 2);
  End
  Else
  Begin
    T := IStr(N);
    FbMid(Cx + 1, Cy - 7, T, C_INK, 1);
  End;
End;

{ etoile a cinq branches (case libre) : test du point dans le polygone
  de 10 sommets }
Procedure DrawStar(Cx, Cy, R, C : LongInt);
Var X, Y, K, J, Inside : LongInt; Px, Py, A, Rr : Real; Vx, Vy : Array[0..9] Of Real;
Begin
  For K := 0 To 9 Do
  Begin
    A := -Pi / 2 + K * Pi / 5;
    If Odd(K) Then Rr := R * 0.42 Else Rr := R;
    Vx[K] := Cos(A) * Rr; Vy[K] := Sin(A) * Rr;
  End;
  For Y := -R To R Do
    For X := -R To R Do
    Begin
      Px := X; Py := Y + 0.01;
      Inside := 0;
      J := 9;
      For K := 0 To 9 Do
      Begin
        If ((Vy[K] > Py) <> (Vy[J] > Py)) And
           (Px < (Vx[J] - Vx[K]) * (Py - Vy[K]) / (Vy[J] - Vy[K]) + Vx[K]) Then Inside := 1 - Inside;
        J := K;
      End;
      If Inside <> 0 Then Pix(Cx + X, Cy + Y, C);
    End;
End;

Function CellX(K : LongInt) : LongInt;
Begin
  CellX := GX + (K Mod 5) * Cell;
End;

Function CellY(K : LongInt) : LongInt;
Begin
  CellY := GY + (K Div 5) * Cell;
End;

{ le carton du joueur }
Procedure DrawCard;
Var K, X, Y, N, R, C, Wm : LongInt; S : String;
Begin
  { papier avec ombre, coins arrondis }
  RRect(GX - 8, 16, GX + 5 * Cell + 12, GY + 5 * Cell + 14, 10, C_SHADOW);
  RRect(GX - 12, 12, GX + 5 * Cell + 8, GY + 5 * Cell + 10, 10, C_PAPER2);
  RRect(GX - 11, 13, GX + 5 * Cell + 7, GY + 5 * Cell + 9, 9, C_PAPER);
  { en-tete : bandeau et lettres sur des boules }
  RRect(GX - 4, 20, GX + 5 * Cell + 0, GY - 6, 7, C_HEAD);
  For K := 0 To 4 Do PaintBall(GX + K * Cell + Cell Div 2, 42, 18, K, 0);
  { cases }
  Wm := WinM[0];
  For K := 0 To 24 Do
  Begin
    X := CellX(K); Y := CellY(K);
    N := Card[K];
    If Odd(K Div 5) Then C := C_PAPER2 Else C := C_PAPER;
    Rect(X + 1, Y + 1, X + Cell - 1, Y + Cell - 1, C);
    If K = 12 Then
    Begin
      DrawStar(X + Cell Div 2, Y + 21, 17, C_STAR);
      FbMid(X + Cell Div 2, Y + 32, 'LIBRE', C_INK, 1);
    End;
    If (Bit(Dab[0], K) <> 0) And (K <> 12) Then
    Begin
      { encre de l'encreur : disque translucide, plus soutenu au bord }
      R := 20;
      If (K = DaubCell) And (DaubF > 0) Then R := 20 - DaubF * 3;
      Disc(X + Cell Div 2, Y + Cell Div 2, R, C_DAUB2);
      Disc(X + Cell Div 2, Y + Cell Div 2, R - 2, C_DAUB);
    End;
    If K <> 12 Then
    Begin
      S := IStr(N);
      If Bit(Dab[0], K) <> 0 Then C := C_DAUBT Else C := C_INK;
      FbMid(X + Cell Div 2 + 1, Y + 8, S, C, 2);
    End;
  End;
  { grille }
  For K := 0 To 5 Do
  Begin
    Rect(GX + K * Cell, GY, GX + K * Cell, GY + 5 * Cell, C_GRID);
    Rect(GX, GY + K * Cell, GX + 5 * Cell, GY + K * Cell, C_GRID);
  End;
  { ligne gagnante }
  If Wm <> 0 Then
    For K := 0 To 24 Do
      If Bit(Wm, K) <> 0 Then
      Begin
        X := CellX(K); Y := CellY(K);
        Frame2(X + 1, Y + 1, X + Cell - 1, Y + Cell - 1, C_GOLD);
        Frame2(X + 2, Y + 2, X + Cell - 2, Y + Cell - 2, C_GOLD);
        Frame2(X + 3, Y + 3, X + Cell - 3, Y + Cell - 3, C_GOLD2);
      End;
  { curseur du clavier }
  If (State = S_PLAY) And (AutoDaub = 0) And (AutoAll = 0) Then
  Begin
    K := CurY * 5 + CurX;
    X := CellX(K); Y := CellY(K);
    Frame2(X + 1, Y + 1, X + Cell - 1, Y + Cell - 1, C_CURSOR);
    Frame2(X + 2, Y + 2, X + Cell - 2, Y + Cell - 2, C_CURSOR);
  End;
End;

{ tableau des 75 numeros }
Procedure DrawBoard;
Var L, I, N, X, Y : LongInt; S : String;
Begin
  RRect(BdX - 6, BdY - 6, BdX + 22 + 15 * BdCol + 5, BdY + 5 * BdRow + 4, 8, C_GOLD2);
  RRect(BdX - 5, BdY - 5, BdX + 22 + 15 * BdCol + 4, BdY + 5 * BdRow + 3, 7, C_SHADOW);
  For L := 0 To 4 Do
  Begin
    Y := BdY + L * BdRow;
    PaintBall(BdX + 9, Y + 9, 9, L, 0);
    For I := 0 To 14 Do
    Begin
      N := L * 15 + I + 1;
      X := BdX + 22 + I * BdCol;
      S := IStr(N);
      If Called[N] <> 0 Then
      Begin
        Rect(X, Y, X + BdCol - 2, Y + BdRow - 3, C_LIT);
        If N = CurBall Then Frame2(X, Y, X + BdCol - 2, Y + BdRow - 3, C_WHITE);
        FbNarrow(X + BdCol Div 2 - 1, Y + 1, S, C_LITT);
      End
      Else
      Begin
        Rect(X, Y, X + BdCol - 2, Y + BdRow - 3, C_SLOT);
        FbNarrow(X + BdCol Div 2 - 1, Y + 1, S, C_SLOTT);
      End;
    End;
  End;
End;

{ carton reduit d'un adversaire (C : 1..3) }
Procedure DrawOpp(C : LongInt);
Var X0, Y0, K, X, Y, M : LongInt; S : String;
Begin
  X0 := BdX + (C - 1) * OpW + 4; Y0 := OpY;
  FbTextSh(X0, Y0, 'Ordi ' + IStr(C), C_TEXT, 1);
  Y0 := Y0 + 18;
  RRect(X0 + 2, Y0 + 2, X0 + 5 * OpCell + 6, Y0 + 5 * OpCell + 14, 5, C_SHADOW);
  RRect(X0 - 2, Y0 - 2, X0 + 5 * OpCell + 2, Y0 + 5 * OpCell + 10, 5, C_PAPER);
  For K := 0 To 4 Do Rect(X0 + K * OpCell + 1, Y0, X0 + K * OpCell + OpCell - 1, Y0 + 6, C_BALL + K * 8 + 4);
  Y0 := Y0 + 8;
  For K := 0 To 24 Do
  Begin
    X := X0 + (K Mod 5) * OpCell; Y := Y0 + (K Div 5) * OpCell;
    Frame2(X, Y, X + OpCell, Y + OpCell, C_GRID);
    If K = 12 Then Disc(X + OpCell Div 2, Y + OpCell Div 2, 3, C_STAR)
    Else If Bit(Dab[C], K) <> 0 Then
    Begin
      If Bit(WinM[C], K) <> 0 Then Disc(X + OpCell Div 2, Y + OpCell Div 2, 5, C_GOLD2)
      Else Disc(X + OpCell Div 2, Y + OpCell Div 2, 5, C_DAUB2);
      Disc(X + OpCell Div 2, Y + OpCell Div 2, 3, C_DAUB);
    End
    Else Pix(X + OpCell Div 2, Y + OpCell Div 2, C_GRID);
  End;
  M := Missing(Dab[C]);
  If WinM[C] <> 0 Then S := 'BINGO !'
  Else If M = 1 Then S := 'manque 1'
  Else S := 'manque ' + IStr(M);
  If (WinM[C] <> 0) Or (M = 1) Then FbTextSh(X0, Y0 + 5 * OpCell + 6, S, C_YEL, 1)
  Else FbTextSh(X0, Y0 + 5 * OpCell + 6, S, C_DIM, 1);
End;

{ bandeau du resultat, sur la moitie droite (la ligne gagnante du
  carton reste visible) }
Procedure DrawBanner;
Var W, X1, Y1, Sc, Cx : LongInt;
Begin
  If Banner = '' Then Exit;
  Sc := 3;
  If Length(Banner) * 24 > 270 Then Sc := 2;
  W := 300; Cx := BdX + 146;
  X1 := Cx - W Div 2;
  Y1 := 108;
  RRect(X1 + 5, Y1 + 6, X1 + W + 5, Y1 + 112, 14, C_SHADOW);
  RRect(X1, Y1, X1 + W, Y1 + 106, 14, C_GOLD);
  RRect(X1 + 4, Y1 + 4, X1 + W - 4, Y1 + 102, 11, C_BANNER);
  If Sc = 3 Then FbCenter(Cx, Y1 + 10, Banner, BannerC, 3) Else FbCenter(Cx, Y1 + 18, Banner, BannerC, 2);
  FbCenter(Cx, Y1 + 62, Banner2, C_TEXT, 1);
  FbCenter(Cx, Y1 + 80, Banner3, C_GRAY, 1);
End;

{ la salle entiere dans Fb }
Procedure RenderScene;
Var Y, K, X, N, P, Xb : LongInt; S : String;
Begin
  { fond : degrade et motif discret de losanges }
  For Y := 0 To BH - 1 Do
  Begin
    K := C_BG + 2 + Y * 12 Div BH;
    Rect(0, Y, BW - 1, Y, K);
    If (Y Mod 16) = 0 Then
      For X := 0 To BW - 1 Do
        If ((X + Y) Mod 32) < 2 Then Pix(X, Y, K + 2);
  End;
  For X := 0 To BW - 1 Do
    For Y := 0 To 2 Do
    Begin
      Pix(X, Y, C_WOOD2); Pix(X, BH - 1 - Y, C_WOOD);
    End;
  DrawCard;
  { boule tiree (qui roule depuis la droite) }
  If CurBall > 0 Then
  Begin
    If AnimF > 0 Then Xb := BallX + (BW - 40 - BallX) * AnimF * AnimF Div 196 Else Xb := BallX;
    PaintBall(Xb, BallY, BallR, ColOf(CurBall), CurBall);
  End
  Else
  Begin
    Disc(BallX, BallY, BallR, C_SLOT);
    Disc(BallX, BallY, BallR - 3, C_BG + 1);
    FbMid(BallX, BallY - 8, '?', C_DIM, 1);
  End;
  FbTextSh(RecX - 16, 16, 'Boule ' + IStr(NDrawn) + ' sur 75', C_WHITE, 1);
  If NDrawn >= 2 Then FbTextSh(RecX - 16, 40, 'Pr' + Chr(130) + 'c' + Chr(130) + 'dentes :', C_GRAY, 1);
  { boules precedentes (les plus recentes a gauche) }
  For K := 0 To 3 Do
  Begin
    P := NDrawn - 2 - K;
    If P >= 0 Then
    Begin
      N := Bag[P];
      PaintBall(RecX + K * 42 + 8, RecY, RecR, ColOf(N), N);
    End;
  End;
  DrawBoard;
  For K := 1 To NOpp Do DrawOpp(K);
  { score de la seance sous le carton }
  S := 'Manches : ' + IStr(Rounds) + '   Vous : ' + IStr(WinsP) + '   Ordis : ' + IStr(WinsC);
  FbTextSh(GX - 6, GY + 5 * Cell + 20, S, C_TEXT, 1);
  N := Missing(Dab[0]);
  If (State = S_PLAY) And (N = 0) Then
    FbTextSh(GX - 6, GY + 5 * Cell + 38, 'Ligne compl' + Chr(138) + 'te : criez BINGO !', C_YEL, 1)
  Else If (State = S_PLAY) And (N <= 2) And (NDrawn > 0) Then
    FbTextSh(GX - 6, GY + 5 * Cell + 38, 'Il vous manque ' + IStr(N) + ' num' + Chr(130) + 'ro(s).', C_GREEN, 1)
  Else If State = S_OVER Then FbTextSh(GX - 6, GY + 5 * Cell + 38, 'Espace ou clic : manche suivante', C_DIM, 1)
  Else If AutoMark Then FbTextSh(GX - 6, GY + 5 * Cell + 38, 'Marquage automatique', C_DIM, 1)
  Else FbTextSh(GX - 6, GY + 5 * Cell + 38, 'Marquez vos num' + Chr(130) + 'ros, puis BINGO !', C_DIM, 1);
  DrawBanner;
End;

{ ==================================================================== }
{ Recopie : seule la zone qui a change depuis la derniere recopie       }
{ ==================================================================== }

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

{ compare Fb a Prv (par mots de 4 octets) et recopie le rectangle qui
  englobe les changements }
Procedure BlitChanged(H : LongInt);
Var R, K, A, B, NW, X1, X2, R1, R2, F, L : LongInt; P, Q : PLong;
Begin
  NW := BW Div 4;
  X1 := NW; X2 := -1; R1 := -1; R2 := -1;
  A := LongInt(@Fb); B := LongInt(@Prv);
  For R := 0 To BH - 1 Do
  Begin
    F := -1; L := -1;
    For K := 0 To NW - 1 Do
    Begin
      P := Pointer(A + K * 4); Q := Pointer(B + K * 4);
      If P^ <> Q^ Then
      Begin
        If F < 0 Then F := K;
        L := K;
        Q^ := P^;
      End;
    End;
    If F >= 0 Then
    Begin
      If R1 < 0 Then R1 := R;
      R2 := R;
      If F < X1 Then X1 := F;
      If L > X2 Then X2 := L;
    End;
    A := A + BW; B := B + BW;
  End;
  If R1 < 0 Then Exit;
  BlitRect(H, X1 * 4, BH - 1 - R2, X2 * 4 + 3, BH - 1 - R1);
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

Procedure MakeNoise(N, Ms, Vol, Hold : LongInt);
Var K, Len, V, Env, R, H : LongInt;
Begin
  Len := SndRate * Ms Div 1000;
  If NSndBuf + Len > SizeOf(SndBuf) Then Exit;
  SndOfs[N] := NSndBuf; SndLen[N] := Len; SndPri[N] := SndPrio;
  R := 12345; V := 0; H := 0;
  For K := 0 To Len - 1 Do
  Begin
    If H <= 0 Then
    Begin
      R := (R * 1103515245 + 12345) And $7FFFFFFF;
      V := ((R Shr 16) And 255) - 128;
      H := Hold + K * Hold Div Len;
    End;
    Dec(H);
    If K < 30 Then Env := K * 255 Div 30 Else Env := 255 * (Len - K) Div (Len - 30 + 1);
    Env := Env * Env Div 255;
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
  SndPrio := 0; MakeNoise(0, 260, 50, 3);                { boule qui roule }
  SndPrio := 0; MakeTone(1, 180, 120, 60, 40);           { encreur }
  SndPrio := 3; MakeTone(2, 520, 1560, 700, 45);         { bingo du joueur }
  SndPrio := 2; MakeTone(3, 500, 220, 500, 40);          { bingo d'un ordinateur }
  SndPrio := 0; MakeTone(4, 300, 260, 100, 30);          { refus }
  SndPrio := 1; MakeTone(5, 1200, 1200, 60, 25);         { boule en place }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Fenetre : boutons et barre d'etat                                     }
{ ==================================================================== }

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Var Fg : LongInt;
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then Fg := CLR_BLACK Else Fg := CLR_DARKGRAY;
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, Fg, CLR_PALEGRAY);
End;

Function CanDraw : Boolean;
Begin
  CanDraw := (State = S_PLAY) And (AutoAll = 0) And (NDrawn < NBall);
End;

Function CanClaim : Boolean;
Begin
  CanClaim := (State = S_PLAY) And (AutoAll = 0) And (AutoDaub = 0) And (NDrawn > 0);
End;

Function BtnSig : LongInt;
Begin
  BtnSig := Ord(CanDraw) + 2 * Ord(CanClaim) + 4 * AutoDraw + 8 * Ord(State = S_OVER);
End;

Function BtnX(I : LongInt) : LongInt;
Begin
  BtnX := 8 + I * 152;
End;

Procedure DrawButtons;
Var S : String;
Begin
  If State = S_OVER Then Button(BtnX(0), BtnY, BtnW, BtnH, 'Manche suivante', AutoAll = 0)
  Else Button(BtnX(0), BtnY, BtnW, BtnH, 'Tirer une boule', CanDraw);
  Button(BtnX(1), BtnY, BtnW, BtnH, 'BINGO !', CanClaim);
  If AutoDraw <> 0 Then S := 'Tirage auto : oui' Else S := 'Tirage auto : non';
  Button(BtnX(2), BtnY, BtnW, BtnH, S, AutoAll = 0);
  Button(BtnX(3), BtnY, BtnW, BtnH, 'Nouvelle partie', True);
  LastBtn := BtnSig;
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
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(OX - 1, OY - 1, OX + BW, OY + BH, CLR_BLACK, CLR_PALEGRAY);
  RenderScene;
  Move(Fb, Prv, SizeOf(Fb));
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawButtons;
  DrawStatus;
  LastMsg := Msg; Dirty := 0;
  Dummy := WinEndPaint(Hps);
End;

Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  If (Dirty = 0) And (Msg = LastMsg) And (BtnSig = LastBtn) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If Dirty <> 0 Then
  Begin
    RenderScene;
    BlitChanged(Hps);
    Dirty := 0;
  End;
  If BtnSig <> LastBtn Then DrawButtons;
  If Msg <> LastMsg Then
  Begin
    LastMsg := Msg;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure PlayMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur tire les boules et joue pour vous.'
  Else If NDrawn = 0 Then Msg := 'Espace ou bouton : tirer la premi' + Chr(138) + 're boule.'
  Else If AutoMark Then Msg := 'Boule ' + BallName(CurBall) + '. Espace : boule suivante.'
  Else Msg := 'Boule ' + BallName(CurBall) + ' : marquez-la si elle est sur votre carton.';
End;

{ nouvelle manche : nouveaux cartons, boules melangees }
Procedure NewRound;
Var C : LongInt;
Begin
  For C := 0 To NCard - 1 Do MakeCard(C);
  ShuffleBag;
  State := S_PLAY; Banner := ''; Banner2 := ''; Banner3 := '';
  ClaimAt := 0; DrawAt := 0; Winners := 0; PlayerWon := 0; Missed := 0; AnimF := 0; DaubF := 0; OverWait := 0;
  CurX := 2; CurY := 2;
  PlayMsg;
  Dirty := 1;
End;

Procedure NewGame;
Begin
  Rounds := 0; WinsP := 0; WinsC := 0; Shared := 0; BallsSum := 0; FalseBingos := 0;
  NewRound;
End;

Function NameList(M : LongInt) : String;
Var C : LongInt; S : String;
Begin
  S := '';
  For C := 1 To NOpp Do
    If Bit(M, C) <> 0 Then
    Begin
      If S <> '' Then S := S + ', ';
      S := S + 'Ordi ' + IStr(C);
    End;
  NameList := S;
End;

{ fin de la manche : Pl (1 : le joueur gagne), Cpu (masque des ordis) }
Procedure EndRound(Pl, Cpu : LongInt);
Var C : LongInt;
Begin
  State := S_OVER;
  Inc(Rounds);
  BallsSum := BallsSum + NDrawn;
  If Pl <> 0 Then WinM[0] := BingoMask(Dab[0]);
  For C := 1 To NOpp Do
    If Bit(Cpu, C) <> 0 Then WinM[C] := BingoMask(Dab[C]);
  If (Pl <> 0) And (Cpu <> 0) Then
  Begin
    Inc(Shared); Inc(WinsP); Inc(WinsC);
    Banner := 'BINGO partag' + Chr(130);
    Banner2 := 'Vous et ' + NameList(Cpu);
    BannerC := C_YEL;
    PlaySnd(2);
  End
  Else If Pl <> 0 Then
  Begin
    Inc(WinsP);
    Banner := 'BINGO !';
    Banner2 := 'Vous gagnez la manche';
    BannerC := C_GOLD;
    PlaySnd(2);
  End
  Else
  Begin
    Inc(WinsC);
    Banner := 'Perdu';
    If PopCount(Cpu) > 1 Then Banner2 := NameList(Cpu) + ' crient BINGO'
    Else Banner2 := NameList(Cpu) + ' crie BINGO';
    BannerC := C_RED;
    PlaySnd(3);
  End;
  Banner3 := 'en ' + IStr(NDrawn) + ' boules (Espace : suite)';
  Msg := Banner2 + ' en ' + IStr(NDrawn) + ' boules. Espace : manche suivante.';
  If (Pl = 0) And (BingoMask(Dab[0]) <> 0) Then
    Msg := 'Vous aviez un bingo, mais vous ne l''avez pas cri' + Chr(130) + ' ! Espace : manche suivante.'
  Else If (Pl = 0) And Not AutoMark Then
  Begin
    { un bingo dont les numeros n'etaient pas tous marques }
    Missed := 0;
    For C := 0 To 24 Do
      If (C <> 12) And (Called[Card[C]] <> 0) Then Missed := Missed Or (1 Shl C);
    If BingoMask(Missed Or (1 Shl 12)) <> 0 Then
      Msg := 'Vous aviez un bingo sans le marquer ! Espace : manche suivante.';
  End;
  Dirty := 1;
End;

{ les ordinateurs qui ont un bingo le crient }
Procedure CpuClaim;
Var M : LongInt;
Begin
  ClaimAt := 0;
  M := CpuBingos;
  If (M <> 0) And (State = S_PLAY) Then EndRound(0, M);
End;

{ tire une boule (et lance son animation) }
Procedure NextBall;
Var N, M : LongInt;
Begin
  If State <> S_PLAY Then Exit;
  If ClaimAt > 0 Then
  Begin
    { on passe a la suite : les ordinateurs crient leur bingo }
    CpuClaim;
    If State <> S_PLAY Then Exit;
  End;
  N := DrawBall;
  If N = 0 Then Exit;
  If TestMode = 0 Then AnimF := 14;
  DrawAt := 0;
  PlaySnd(0);
  PlayMsg;
  M := CpuBingos;
  If AutoMark Then
  Begin
    { marquage automatique : le joueur crie en meme temps que les ordis }
    If BingoMask(Dab[0]) <> 0 Then EndRound(1, M)
    Else If M <> 0 Then EndRound(0, M);
  End
  Else If M <> 0 Then
  Begin
    ClaimAt := ClaimDelay;
    Msg := 'Boule ' + BallName(N) + '... un ordinateur s''appr' + Chr(136) + 'te ' + Chr(133) + ' crier BINGO !';
  End;
  Dirty := 1;
End;

{ le joueur crie BINGO }
Procedure Claim;
Var Cpu : LongInt;
Begin
  If State <> S_PLAY Then Exit;
  If BingoMask(Dab[0]) <> 0 Then
  Begin
    { un ordinateur qui a aussi un bingo partage la manche }
    Cpu := CpuBingos;
    EndRound(1, Cpu);
  End
  Else
  Begin
    Inc(FalseBingos);
    PlaySnd(4);
    Msg := 'Faux bingo : il faut une ligne, une colonne ou une diagonale enti' + Chr(138) + 'rement marqu' + Chr(130) + 'e.';
  End;
  Dirty := 1;
End;

Procedure DaubAt(K : LongInt);
Var R : LongInt;
Begin
  If (State <> S_PLAY) Or (AutoAll <> 0) Then Exit;
  If K = 12 Then Exit;
  CurX := K Mod 5; CurY := K Div 5;
  If AutoDaub <> 0 Then
  Begin
    Msg := 'Le marquage est automatique (Options).';
    Dirty := 1;
    Exit;
  End;
  R := Daub(K);
  If R = 1 Then
  Begin
    DaubCell := K; DaubF := 5;
    PlaySnd(1);
    If BingoMask(Dab[0]) <> 0 Then Msg := 'Ligne compl' + Chr(138) + 'te : criez BINGO (bouton ou touche B) !'
    Else Msg := BallName(Card[K]) + ' marqu' + Chr(130) + '.';
  End
  Else If R = -1 Then
  Begin
    PlaySnd(4);
    Msg := 'Le ' + BallName(Card[K]) + ' n''est pas encore sorti.';
  End;
  Dirty := 1;
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If AnimF > 0 Then
  Begin
    Dec(AnimF);
    If AnimF = 0 Then PlaySnd(5);
    Dirty := 1;
  End;
  If DaubF > 0 Then
  Begin
    Dec(DaubF);
    Dirty := 1;
  End;
  If State = S_PLAY Then
  Begin
    If ClaimAt > 0 Then
    Begin
      Dec(ClaimAt);
      If ClaimAt = 0 Then
      Begin
        ClaimAt := 1;
        CpuClaim;
      End;
    End
    Else If ((AutoDraw <> 0) Or (AutoAll <> 0)) And (AnimF = 0) Then
    Begin
      Inc(DrawAt);
      If DrawAt >= DrawDelay Div (1 + AutoAll) Then NextBall;
    End;
  End
  Else If AutoAll <> 0 Then
  Begin
    Inc(OverWait);
    If OverWait > 120 Then NewRound;
  End;
  Frame1;
End;

{ ==================================================================== }
{ Commandes, clavier, souris                                            }
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
  SetMark(CM_AUTODRAW, AutoDraw <> 0); SetMark(CM_AUTODAUB, AutoDaub <> 0); SetMark(CM_SOUND, SoundOn <> 0);
  SetMark(CM_AUTO, AutoAll <> 0);
  SetMark(CM_OPP1, NOpp = 1); SetMark(CM_OPP2, NOpp = 2); SetMark(CM_OPP3, NOpp = 3);
End;

Procedure Rules;
Begin
  LClr;
  LAdd('Bingo ' + Chr(133) + ' 75 boules. Chaque carton a 5 colonnes : B (1 ' + Chr(133) + ' 15), I (16 ' +
       Chr(133) + ' 30), N (31 ' + Chr(133) + ' 45), G (46 ' + Chr(133) + ' 60) et O (61 ' + Chr(133) +
       ' 75) ; la case du centre est libre (d' + Chr(130) + 'j' + Chr(133) + ' marqu' + Chr(130) + 'e).' + Chr(10) +
       Chr(10));
  LAdd('Les boules sont tir' + Chr(130) + 'es une ' + Chr(133) + ' une (Espace, ou tirage automatique). Quand ' +
       'le num' + Chr(130) + 'ro est sur votre carton, marquez-le (clic sur la case, ou fl' + Chr(138) +
       'ches et Entr' + Chr(130) + 'e). Le premier qui compl' + Chr(138) + 'te une ligne, une colonne ou une ' +
       'diagonale et crie BINGO (bouton ou touche B) gagne la manche.' + Chr(10) + Chr(10));
  LAdd('Les ordinateurs marquent leurs cartons tout de suite et crient BINGO apr' + Chr(138) + 's un court ' +
       'd' + Chr(130) + 'lai, ou d' + Chr(138) + 's que vous tirez la boule suivante : soyez plus rapide ! Si ' +
       'vous criez sur la m' + Chr(136) + 'me boule qu''eux, le bingo est partag' + Chr(130) + '. Un faux ' +
       'bingo est refus' + Chr(130) + '. Options : marquage automatique de votre carton (comme le prototype), ' +
       'nombre d''adversaires (1 ' + Chr(133) + ' 3), tirage automatique.' + Chr(10) + Chr(10));
  LAdd('Clavier : Espace (tirer), fl' + Chr(138) + 'ches et Entr' + Chr(130) + 'e (marquer), B (bingo), A ' +
       '(tirage automatique), N ou F2 (nouvelle manche).');
  Dummy := LMsgBox('Bingo - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
End;

Procedure SetOpp(N : LongInt);
Begin
  NOpp := N;
  SetMarks;
  NewRound;
  Msg := IStr(N) + ' adversaire(s) : nouvelle manche.';
End;

{ marquage automatique active en cours de manche : les numeros deja
  sortis sont marques sur le carton du joueur }
Procedure MarkCalled;
Var K : LongInt;
Begin
  If (State <> S_PLAY) Or Not AutoMark Then Exit;
  For K := 0 To 24 Do
    If (K <> 12) And (Called[Card[K]] <> 0) Then Dab[0] := Dab[0] Or (1 Shl K);
  If BingoMask(Dab[0]) <> 0 Then EndRound(1, CpuBingos);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_DRAW :
      If AutoAll = 0 Then
      Begin
        If State = S_OVER Then NewRound Else NextBall;
      End;
    CM_BINGO : If CanClaim Then Claim;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTODRAW : Begin AutoDraw := 1 - AutoDraw; DrawAt := 0; SetMarks; End;
    CM_AUTODAUB :
      Begin
        AutoDaub := 1 - AutoDaub;
        SetMarks;
        MarkCalled;
        If State = S_PLAY Then PlayMsg;
        Dirty := 1;
      End;
    CM_OPP1 : SetOpp(1);
    CM_OPP2 : SetOpp(2);
    CM_OPP3 : SetOpp(3);
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll;
        SetMarks; DrawAt := 0; OverWait := 0;
        MarkCalled;
        If State = S_PLAY Then PlayMsg;
        Dirty := 1;
      End;
    CM_RULES : Rules;
    CM_ABOUT : Dummy := Ask('Bingo pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype BINGO.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

Procedure MoveCur(Dx, Dy : LongInt);
Begin
  If (State <> S_PLAY) Or (AutoDaub <> 0) Then Exit;
  CurX := (CurX + Dx + 5) Mod 5; CurY := (CurY + Dy + 5) Mod 5;
  Dirty := 1;
  Frame1;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And (KC_KEYUP Or KC_ALT Or KC_CTRL)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_LEFT Then Begin MoveCur(-1, 0); Exit; End;
    If Vk = VK_RIGHT Then Begin MoveCur(1, 0); Exit; End;
    If Vk = VK_UP Then Begin MoveCur(0, -1); Exit; End;
    If Vk = VK_DOWN Then Begin MoveCur(0, 1); Exit; End;
    If Vk = VK_SPACE Then Begin Command(CM_DRAW); Exit; End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      If State = S_OVER Then Command(CM_DRAW)
      Else
      Begin
        DaubAt(CurY * 5 + CurX);
        Frame1;
      End;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'B' : Command(CM_BINGO);
      'A' : Command(CM_AUTODRAW);
      'N' : Command(CM_NEW);
      ' ' : Command(CM_DRAW);
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (Y >= BtnY) And (Y < BtnY + BtnH) Then
  Begin
    If (X >= BtnX(0)) And (X < BtnX(0) + BtnW) Then Command(CM_DRAW)
    Else If (X >= BtnX(1)) And (X < BtnX(1) + BtnW) Then Command(CM_BINGO)
    Else If (X >= BtnX(2)) And (X < BtnX(2) + BtnW) And (AutoAll = 0) Then Command(CM_AUTODRAW)
    Else If (X >= BtnX(3)) And (X < BtnX(3) + BtnW) Then Command(CM_NEW);
    Exit;
  End;
  X := X - OX; Y := Y - OY;
  If State = S_OVER Then
  Begin
    If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Command(CM_DRAW);
    Exit;
  End;
  If (X >= GX) And (X < GX + 5 * Cell) And (Y >= GY) And (Y < GY + 5 * Cell) Then
  Begin
    DaubAt(((Y - GY) Div Cell) * 5 + (X - GX) Div Cell);
    Frame1;
  End
  Else If (X - BallX) * (X - BallX) + (Y - BallY) * (Y - BallY) <= BallR * BallR Then Command(CM_DRAW);
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

Procedure RunTests;
Var Ok, C, K, N, Good, Bad, A, B, D, E, M : LongInt; S : String;
Begin
  Ok := 0;
  InitLines;
  Seed := 77;
  { TEST1 : 300 cartons (plages des colonnes, numeros distincts et
    tries, case libre) }
  Good := 0;
  For N := 1 To 300 Do
  Begin
    MakeCard(1);
    Bad := 0;
    For K := 0 To 24 Do
      If K = 12 Then
      Begin
        If Card[25 + K] <> 0 Then Inc(Bad);
      End
      Else
      Begin
        If ColOf(Card[25 + K]) <> K Mod 5 Then Inc(Bad);
        If (K >= 5) And (K - 5 <> 12) And (Card[25 + K] <= Card[25 + K - 5]) Then Inc(Bad);
        If (K = 17) And (Card[25 + K] <= Card[25 + 7]) Then Inc(Bad);
      End;
    If (Bad = 0) And (Dab[1] = 1 Shl 12) Then Inc(Good);
  End;
  Log('BINGO : TEST1 cartons ' + IStr(Good) + '/300 valides');
  If Good = 300 Then Inc(Ok);
  { TEST2 : lignes gagnantes (rangee, colonne N avec la case libre,
    diagonale, quatre coins qui ne suffisent pas) }
  A := BingoMask(Lines[1]);
  B := BingoMask((1 Shl 2) Or (1 Shl 7) Or (1 Shl 12) Or (1 Shl 17) Or (1 Shl 22));
  D := BingoMask(Lines[11] Or (1 Shl 3));
  E := BingoMask(1 Or (1 Shl 4) Or (1 Shl 20) Or (1 Shl 24) Or (1 Shl 12));
  M := Missing((1 Shl 12) Or 1 Or (1 Shl 6));
  S := 'TEST2 rangee ' + IStr(PopCount(A)) + ' colonne ' + IStr(PopCount(B)) + ' diagonale ' + IStr(PopCount(D)) +
       ' coins ' + IStr(PopCount(E)) + ' manque ' + IStr(M);
  Log('BINGO : ' + S);
  If (A = Lines[1]) And (B = Lines[7]) And (D = Lines[11]) And (E = 0) And (M = 2) Then Inc(Ok);
  { TEST3 : tirage (75 boules distinctes), marquage refuse avant la
    sortie, faux bingo, bingo partage }
  NOpp := 3; AutoDaub := 0; State := S_PLAY;
  For C := 0 To NCard - 1 Do MakeCard(C);
  ShuffleBag;
  For K := 0 To NBall Do Called[K] := 0;
  Good := 0;
  For K := 1 To NBall Do
  Begin
    N := DrawBall;
    If (N >= 1) And (N <= NBall) Then Inc(Good);
  End;
  A := 0;
  For K := 1 To NBall Do A := A + Called[K];
  B := Ord((BingoMask(Dab[1]) <> 0) And (Dab[1] = $1FFFFFF));
  ShuffleBag;
  Dab[0] := 1 Shl 12;
  D := Daub(0);
  N := Card[0];
  Called[N] := 1;
  E := Daub(0);
  E := E * 10 + Daub(0);
  S := 'TEST3 boules ' + IStr(Good) + ' distinctes ' + IStr(A) + ' plein ' + IStr(B) + ' marquage ' + IStr(D) +
       ' puis ' + IStr(E);
  Log('BINGO : ' + S);
  If (Good = NBall) And (A = NBall) And (B = 1) And (D = -1) And (E = 10) Then Inc(Ok);
  { PARTIE : 60 manches contre 3 ordinateurs, marquage automatique,
    graine fixe }
  Seed := 2026; NOpp := 3; AutoDaub := 1; AutoAll := 0;
  Rounds := 0; WinsP := 0; WinsC := 0; Shared := 0; BallsSum := 0; FalseBingos := 0;
  Bad := 0;
  For K := 1 To 60 Do
  Begin
    NewRound;
    While (State = S_PLAY) And (NDrawn < NBall) Do NextBall;
    If State = S_PLAY Then Inc(Bad);
  End;
  Log('BINGO : PARTIE manches ' + IStr(Rounds) + ' joueur ' + IStr(WinsP) + ' ordinateurs ' + IStr(WinsC) +
      ' partagees ' + IStr(Shared) + ' boules ' + IStr(BallsSum) + ' sans fin ' + IStr(Bad));
  Log('BINGO : ' + IStr(Ok) + '/3 essais reussis');
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
  Msg := ''; LastMsg := '-'; AutoAll := 0; Banner := ''; Banner2 := ''; Banner3 := ''; Tick := 0; Client := 0;
  Frame := 0; SoundOn := 1; SndCur := 0; SndEnd := 0; TestMode := 0; Dirty := 1; LastBtn := -1;
  CW := CWant; CH := CHWant; State := S_PLAY; NOpp := 3; AutoDaub := 0; AutoDraw := 0; BannerC := C_GOLD;
  DaubCell := -1; DaubF := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
    If S = '/TEST' Then TestMode := 1;
  End;
  If TestMode <> 0 Then
  Begin
    RunTests;
    Halt(0);
  End;
  InitLines;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitPal;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('BINGO'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('BINGO'), Z2('Bingo'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_DRAW, '~Tirer une boule' + Chr(9) + 'Espace');
  MItem(MIS_TEXT, 0, CM_BINGO, '~Bingo !' + Chr(9) + 'B');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_AUTODRAW, '~Tirage automatique' + Chr(9) + 'A');
  MItem(MIS_TEXT, 0, CM_AUTODAUB, '~Marquage automatique');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_OPP1, '~1 adversaire');
  MItem(MIS_TEXT, 0, CM_OPP2, '~2 adversaires');
  MItem(MIS_TEXT, 0, CM_OPP3, '~3 adversaires');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MenuClose(H3, 9);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Bingo');
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
  Dummy := WinStartTimer(Hab, Client, 1, 30);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
