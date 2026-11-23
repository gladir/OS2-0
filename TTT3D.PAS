{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: TTT3D - Tic-Tac-Toe en trois dimensions (cube de 4 x 4 x 4
                ou de 3 x 3 x 3) pour le Presentation Manager d'OS/2-0
                (dossier Jeux du bureau).
}

Program TTT3D;

{$R-,S-,I-}

{ Compilation : OS2PC TTT3D.PAS   (produit TTT3D.EXE)

  Portage vers OS/2-0 du prototype TTT3D.PAS du depot 7iles (Turbo
  Pascal, BGI en 640 x 480, clavier seulement) : fenetre de Presentation
  Manager avec menus, image en memoire recopiee par GpiDrawBits (seules
  les zones qui changent sont recopiees), le cube dessine en perspective
  comme quatre plateaux de verre empiles et relies par les aretes du
  cube, billes rouges et bleues en relief qui tombent sur leur case avec
  leur ombre, niveau courant eclaire, ligne gagnante doree, panneau du
  pointage, barre d'etat et apparence d'OS/2 Warp 3.

  Comme le prototype : un cube de 4 x 4 x 4 cases en quatre niveaux ; le
  rouge (X, vous) et le bleu (O, l'ordinateur) posent chacun leur tour
  une bille ; il faut aligner quatre billes dans n'importe quelle
  direction.
  Ce qui est corrige : la verification ne connaissait que 44 des 76
  lignes gagnantes du cube (il manquait les 16 colonnes verticales et
  les 16 diagonales des plans verticaux) ; la vue en perspective
  superposait les quatre niveaux (billes difficiles a situer) ;
  l'ordinateur jouait simplement la premiere case libre ; le curseur
  clignotait en redessinant tout ; la souris n'etait pas prise en
  charge ; la partie s'arretait apres un seul resultat.
  Ce qui s'ajoute : ordinateur en trois niveaux (gain, parade, fourchette,
  suites de menaces forcees au niveau expert), cube de 3 x 3 x 3 (49
  lignes), premier joueur en alternance, partie a deux, annulation,
  indice, demonstration, pointage de la seance, bruitages.

  Souris : cliquer une case d'un des plateaux. Clavier : fleches (case
  du niveau courant), Pg Prec et Pg Suiv (niveau du dessus et du
  dessous), Espace ou Entree (poser), U ou Retour arriere (annuler), I
  (indice), F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /LEVEL:n (1 a 3) ; /SIZE:3 (petit cube) ;
  /AUTO (demonstration) ; /NOSOUND ; /TEST (essais des lignes, du gain et
  de l'ordinateur, puis parties jouees sans fenetre, resultat sur le
  port serie COM1). }

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
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_SPACE = $10; VK_PAGEUP = $11; VK_PAGEDOWN = $12;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_UNDO = 102; CM_HINT = 103; CM_QUIT = 104;
  CM_LEVEL1 = 201; CM_LEVEL2 = 202; CM_LEVEL3 = 203; CM_CUBE4 = 204; CM_CUBE3 = 205; CM_TWO = 206;
  CM_AUTO = 207; CM_SOUND = 208;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : 400 x 400 }
  BW = 400; BH = 400; OX = 8; OY = 8;
  PnX = 424; PW = 192;
  CWant = 624; CHWant = 436;
  MaxN = 4; MaxCell = 64; MaxLine = 76; MaxPerCell = 16;
  { couleurs de l'image }
  C_BG = 0;                                  { 0..15 : fond (haut -> bas) }
  C_GLASS = 16;                              { 16..31 : fond vu a travers le verre }
  C_GLASSH = 32;                             { 32..47 : verre du niveau courant }
  C_GLASSD = 48;                             { 48..63 : ombre sur le verre }
  C_RED = 64; C_BLUE = 80;                   { 64..79 et 80..95 : billes (sombre -> reflet) }
  C_GRID = 96; C_PILLAR = 97; C_FRAME = 98; C_CURSOR = 99; C_HINT = 100; C_WIN = 101; C_TEXT = 102;
  C_TEXTD = 103; C_BANNER = 104; C_BANNERE = 105; C_YELLOW = 106; C_WHITE = 107; C_SHADOW = 108;
  C_GREEN = 109; C_WIND = 110; C_EDGEH = 111;
  { joueurs : 1 rouge (X), 2 bleu (O) }
  O_PLAY = 0; O_RED = 1; O_BLUE = 2; O_DRAW = 3;
  SndRate = 11025;

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  Shade : Array[0..255] Of Byte;
  BallS : Array[0..2 * 32 * 32 - 1] Of Byte;     { billes rouge et bleue (255 : transparent) }
  { cube }
  N, NCell, NLine : LongInt;
  LineC : Array[0..MaxLine * MaxN - 1] Of LongInt;
  CellL : Array[0..MaxCell * MaxPerCell - 1] Of LongInt;
  CellN : Array[0..MaxCell - 1] Of LongInt;
  Bd : Array[0..MaxCell - 1] Of LongInt;
  { geometrie de la vue }
  DXu, DXv, DYv, X0, PlaneGap, BallR, BallSz : LongInt;
  PlaneY : Array[0..MaxN - 1] Of LongInt;
  { partie }
  Cur, Starter, Over, WinL, Level, CompP, AutoAll, Seed, SoundOn, TestMode, Tick, Wait : LongInt;
  Hist : Array[0..MaxCell] Of LongInt;
  NH, CurC, CurZ, KbdUsed, HintC, LastC, WinsR, WinsB, Draws : LongInt;
  { chute d'une bille }
  AnOn, AnC, AnK, AnN : LongInt;
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
  { recherche des suites forcees }
  FNodes, FLimit : LongInt;

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
{ Le cube et ses lignes                                                 }
{ ==================================================================== }

Function CellOf(X, Y, Zz : LongInt) : LongInt;
Begin
  CellOf := (Zz * N + Y) * N + X;
End;

Function InCube(X, Y, Zz : LongInt) : Boolean;
Begin
  InCube := (X >= 0) And (X < N) And (Y >= 0) And (Y < N) And (Zz >= 0) And (Zz < N);
End;

{ toutes les lignes : 13 directions, chaque ligne partant d'une case dont
  la voisine en arriere sort du cube et dont la N-ieme case est dedans }
Procedure MakeLines;
Var D, Dx, Dy, Dz, X, Y, Zz, K, C : LongInt;
Begin
  NCell := N * N * N; NLine := 0;
  For C := 0 To MaxCell - 1 Do CellN[C] := 0;
  For D := 0 To 26 Do
  Begin
    Dx := D Mod 3 - 1; Dy := (D Div 3) Mod 3 - 1; Dz := D Div 9 - 1;
    { une direction sur deux (premiere composante non nulle positive) }
    If (Dz > 0) Or ((Dz = 0) And (Dy > 0)) Or ((Dz = 0) And (Dy = 0) And (Dx > 0)) Then
      For Zz := 0 To N - 1 Do
        For Y := 0 To N - 1 Do
          For X := 0 To N - 1 Do
            If Not InCube(X - Dx, Y - Dy, Zz - Dz) And InCube(X + (N - 1) * Dx, Y + (N - 1) * Dy, Zz + (N - 1) * Dz) Then
            Begin
              For K := 0 To N - 1 Do
              Begin
                C := CellOf(X + K * Dx, Y + K * Dy, Zz + K * Dz);
                LineC[NLine * MaxN + K] := C;
                If CellN[C] < MaxPerCell Then
                Begin
                  CellL[C * MaxPerCell + CellN[C]] := NLine;
                  Inc(CellN[C]);
                End;
              End;
              Inc(NLine);
            End;
  End;
End;

{ nombre de billes du joueur P sur la ligne L }
Function LCount(L, P : LongInt) : LongInt;
Var K, R : LongInt;
Begin
  R := 0;
  For K := 0 To N - 1 Do
    If Bd[LineC[L * MaxN + K]] = P Then Inc(R);
  LCount := R;
End;

{ ligne complete du joueur P (-1 : aucune) }
Function WinLine(P : LongInt) : LongInt;
Var L, R : LongInt;
Begin
  R := -1;
  For L := 0 To NLine - 1 Do
    If (R < 0) And (LCount(L, P) = N) Then R := L;
  WinLine := R;
End;

Function Empties : LongInt;
Var C, R : LongInt;
Begin
  R := 0;
  For C := 0 To NCell - 1 Do
    If Bd[C] = 0 Then Inc(R);
  Empties := R;
End;

{ lignes encore possibles pour P (sans bille adverse) }
Function OpenLines(P : LongInt) : LongInt;
Var L, R : LongInt;
Begin
  R := 0;
  For L := 0 To NLine - 1 Do
    If LCount(L, 3 - P) = 0 Then Inc(R);
  OpenLines := R;
End;

{ ==================================================================== }
{ L'ordinateur                                                          }
{ ==================================================================== }

{ case vide qui complete une ligne de P (-1 : aucune) }
Function WinCell(P : LongInt) : LongInt;
Var L, K, R, C : LongInt;
Begin
  R := -1;
  For L := 0 To NLine - 1 Do
    If (R < 0) And (LCount(L, P) = N - 1) And (LCount(L, 3 - P) = 0) Then
      For K := 0 To N - 1 Do
      Begin
        C := LineC[L * MaxN + K];
        If Bd[C] = 0 Then R := C;
      End;
  WinCell := R;
End;

{ nombre de cases gagnantes distinctes de P (menaces) }
Function ThreatCells(P : LongInt; Var First : LongInt) : LongInt;
Var L, K, C, R : LongInt; Seen : Array[0..MaxCell - 1] Of Byte;
Begin
  For C := 0 To NCell - 1 Do Seen[C] := 0;
  R := 0; First := -1;
  For L := 0 To NLine - 1 Do
    If (LCount(L, P) = N - 1) And (LCount(L, 3 - P) = 0) Then
      For K := 0 To N - 1 Do
      Begin
        C := LineC[L * MaxN + K];
        If (Bd[C] = 0) And (Seen[C] = 0) Then
        Begin
          Seen[C] := 1; Inc(R);
          If First < 0 Then First := C;
        End;
      End;
  ThreatCells := R;
End;

{ la case C cree-t-elle une nouvelle menace pour P ? (ligne de N - 2 billes
  de P sans bille adverse) }
Function MakesThreat(C, P : LongInt) : Boolean;
Var K, L : LongInt; R : Boolean;
Begin
  R := False;
  For K := 0 To CellN[C] - 1 Do
  Begin
    L := CellL[C * MaxPerCell + K];
    If (LCount(L, P) = N - 2) And (LCount(L, 3 - P) = 0) Then R := True;
  End;
  MakesThreat := R;
End;

{ case qui donne a P deux menaces a la fois (fourchette) }
Function ForkCell(P : LongInt) : LongInt;
Var C, R, F : LongInt;
Begin
  R := -1;
  For C := 0 To NCell - 1 Do
    If (R < 0) And (Bd[C] = 0) Then
      If MakesThreat(C, P) Then
      Begin
        Bd[C] := P;
        If ThreatCells(P, F) >= 2 Then R := C;
        Bd[C] := 0;
      End;
  ForkCell := R;
End;

{ suite de menaces forcees : P menace, l'adversaire doit parer, jusqu'a
  une fourchette. Rend la premiere case de la suite (-1 : aucune) }
Function ForcedWin(P, Depth : LongInt) : LongInt;
Var C, R, T, B, F, Q : LongInt;
Begin
  R := -1; Q := 3 - P;
  Inc(FNodes);
  If (Depth <= 0) Or (FNodes > FLimit) Then
  Begin
    ForcedWin := -1;
    Exit;
  End;
  For C := 0 To NCell - 1 Do
    If (R < 0) And (Bd[C] = 0) Then
      If MakesThreat(C, P) Then
      Begin
        Bd[C] := P;
        T := ThreatCells(P, B);
        If T >= 2 Then
        Begin
          If WinCell(Q) < 0 Then R := C;
        End
        Else If (T = 1) And (WinCell(Q) < 0) Then
        Begin
          { l'adversaire doit parer en B ; s'il menace a son tour, on abandonne }
          Bd[B] := Q;
          If WinCell(Q) < 0 Then
            If ForcedWin(P, Depth - 1) >= 0 Then R := C;
          Bd[B] := 0;
        End;
        Bd[C] := 0;
      End;
  F := R;
  ForcedWin := F;
End;

{ note d'une case pour P : lignes encore ouvertes qui y passent }
Function CellScore(C, P : LongInt) : LongInt;
Var K, L, Mine, His, S : LongInt;
Begin
  S := 0;
  For K := 0 To CellN[C] - 1 Do
  Begin
    L := CellL[C * MaxPerCell + K];
    Mine := LCount(L, P); His := LCount(L, 3 - P);
    If His = 0 Then
    Begin
      Case Mine Of
        0 : S := S + 2;
        1 : S := S + 9;
        2 : S := S + 30;
      Else
        S := S + 40;
      End;
    End
    Else If Mine = 0 Then
    Begin
      Case His Of
        1 : S := S + 6;
        2 : S := S + 22;
      Else
        S := S + 30;
      End;
    End;
  End;
  CellScore := S;
End;

Function BestScoreCell(P, Noise : LongInt) : LongInt;
Var C, S, Best, BestS : LongInt;
Begin
  Best := -1; BestS := -1;
  For C := 0 To NCell - 1 Do
    If Bd[C] = 0 Then
    Begin
      S := CellScore(C, P) * 8 + Rnd(Noise + 1);
      If S > BestS Then
      Begin
        BestS := S; Best := C;
      End;
    End;
  BestScoreCell := Best;
End;

{ apres un coup en C, l'adversaire Q a-t-il un gain force (gain
  immediat, fourchette ou suite de menaces) ? }
Function Unsafe(C, P : LongInt) : Boolean;
Var Q, R : LongInt;
Begin
  Q := 3 - P;
  Bd[C] := P;
  R := 0;
  If WinCell(P) < 0 Then
  Begin
    { si P menace, Q doit parer : pas de danger immediat a evaluer ici }
    If ForkCell(Q) >= 0 Then R := 1
    Else
    Begin
      FNodes := 0; FLimit := 700;
      If ForcedWin(Q, 2 * N) >= 0 Then R := 1;
    End;
  End;
  Bd[C] := 0;
  Unsafe := R <> 0;
End;

{ coup de l'ordinateur pour P au niveau L }
Function AiMove(P, L : LongInt) : LongInt;
Var C, Q, K, J, S, T, NC : LongInt;
    CandC, CandS : Array[0..MaxCell - 1] Of LongInt;
Begin
  Q := 3 - P;
  C := WinCell(P);
  If (C < 0) And ((L > 1) Or (Rnd(100) < 75)) Then C := WinCell(Q);
  If (C < 0) And (L >= 3) Then
  Begin
    FNodes := 0; FLimit := 6000;
    C := ForcedWin(P, 2 * N + 2);
  End;
  If (C < 0) And (L >= 2) Then C := ForkCell(P);
  If (C < 0) And (L = 2) Then C := ForkCell(Q);
  If C < 0 Then
  Begin
    { cases rangees par leur note (avec un peu de hasard selon le niveau) }
    NC := 0;
    For K := 0 To NCell - 1 Do
      If Bd[K] = 0 Then
      Begin
        Case L Of
          1 : S := CellScore(K, P) * 8 + Rnd(401);
          2 : S := CellScore(K, P) * 8 + Rnd(25);
        Else
          S := CellScore(K, P) * 8 + Rnd(7);
        End;
        J := NC;
        While (J > 0) And (CandS[J - 1] < S) Do
        Begin
          CandS[J] := CandS[J - 1]; CandC[J] := CandC[J - 1];
          Dec(J);
        End;
        CandS[J] := S; CandC[J] := K;
        Inc(NC);
      End;
    If NC > 0 Then C := CandC[0];
    { expert : la premiere des meilleures cases qui ne laisse pas de gain
      force a l'adversaire }
    If L >= 3 Then
    Begin
      T := -1;
      For K := 0 To MinI(NC, 10) - 1 Do
        If T < 0 Then
          If Not Unsafe(CandC[K], P) Then T := CandC[K];
      If T >= 0 Then C := T;
    End;
  End;
  AiMove := C;
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
Var I, C : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 15 Do
  Begin
    C := Mix($243A5E, $0C1424, I, 15);
    SetPal(C_BG + I, C);
    SetPal(C_GLASS + I, Mix(C, $8CB8E8, 30, 100));
    SetPal(C_GLASSH + I, Mix(C, $C8E4FF, 46, 100));
    SetPal(C_GLASSD + I, Mix(C, $000008, 30, 100));
  End;
  { billes : bord sombre, couleur, reflet presque blanc }
  For I := 0 To 15 Do
  Begin
    If I <= 11 Then
    Begin
      SetPal(C_RED + I, Mix($3C0404, $E8282C, I, 11));
      SetPal(C_BLUE + I, Mix($040C40, $2C6CF0, I, 11));
    End
    Else
    Begin
      SetPal(C_RED + I, Mix($E8282C, $FFF0F0, I - 11, 4));
      SetPal(C_BLUE + I, Mix($2C6CF0, $F0F6FF, I - 11, 4));
    End;
  End;
  SetPal(C_GRID, $B4D4F4); SetPal(C_PILLAR, $4C6C94); SetPal(C_FRAME, $FFFFFF); SetPal(C_CURSOR, $FFD43C);
  SetPal(C_HINT, $50F090); SetPal(C_WIN, $FFD700); SetPal(C_TEXT, $D8E8FF); SetPal(C_TEXTD, $7890B4);
  SetPal(C_BANNER, $101C38); SetPal(C_BANNERE, $A0B4FF); SetPal(C_YELLOW, $FFDC46); SetPal(C_WHITE, $FFFFFF);
  SetPal(C_SHADOW, $04060C); SetPal(C_GREEN, $64E68C); SetPal(C_WIND, $8A6A00); SetPal(C_EDGEH, $E0F0FF);
  For I := 0 To 255 Do Shade[I] := C_SHADOW;
  For I := 0 To 15 Do
  Begin
    Shade[C_BG + I] := C_GLASSD + I;
    Shade[C_GLASS + I] := C_GLASSD + I;
    Shade[C_GLASSH + I] := C_GLASSD + I;
    Shade[C_GLASSD + I] := C_GLASSD + I;
  End;
  Shade[C_GRID] := C_PILLAR;
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

{ ==================================================================== }
{ Vue du cube : plateaux de verre empiles                               }
{ ==================================================================== }

Procedure SetGeometry;
Var Zz : LongInt;
Begin
  If N = 4 Then
  Begin
    DXu := 46; DXv := 18; DYv := 18; PlaneGap := 94; BallR := 9;
  End
  Else
  Begin
    DXu := 62; DXv := 24; DYv := 24; PlaneGap := 126; BallR := 12;
  End;
  X0 := (BW - N * (DXu + DXv)) Div 2 + 24;
  For Zz := 0 To N - 1 Do PlaneY[Zz] := BH - 26 - Zz * PlaneGap;
  BallSz := 2 * BallR + 4;
End;

{ point (U, V) du plateau Zz (U le long des colonnes, V vers le fond),
  en 1/4 de case pour les centres }
Function PX(U4, V4 : LongInt) : LongInt;
Begin
  PX := X0 + (U4 * DXu + V4 * DXv) Div 4;
End;

Function PY(Zz, V4 : LongInt) : LongInt;
Begin
  PY := PlaneY[Zz] - (V4 * DYv) Div 4;
End;

Function CellX(C : LongInt) : LongInt;
Begin
  CellX := PX((C Mod N) * 4 + 2, ((C Div N) Mod N) * 4 + 2);
End;

Function CellY(C : LongInt) : LongInt;
Begin
  CellY := PY(C Div (N * N), ((C Div N) Mod N) * 4 + 2);
End;

{ remplit le parallelogramme de la case (X, Y) du plateau Zz (ou tout le
  plateau si X < 0) en passant chaque point par la table T }
Procedure FillPara(Zz, X, Y, Base : LongInt);
Var Yy, Xa, Xb, U1, U2, V1, V2, Xx, A, V : LongInt;
Begin
  If X < 0 Then
  Begin
    U1 := 0; U2 := N; V1 := 0; V2 := N;
  End
  Else
  Begin
    U1 := X; U2 := X + 1; V1 := Y; V2 := Y + 1;
  End;
  For Yy := PY(Zz, V2 * 4) To PY(Zz, V1 * 4) Do
  Begin
    { V reel = (PlaneY - Yy) / DYv }
    V := PlaneY[Zz] - Yy;
    Xa := X0 + U1 * DXu + V * DXv Div DYv;
    Xb := X0 + U2 * DXu + V * DXv Div DYv - 1;
    If (Yy >= 0) And (Yy < BH) Then
      For Xx := Xa To Xb Do
        If (Xx >= 0) And (Xx < BW) Then
        Begin
          A := (BH - 1 - Yy) * BW + Xx;
          If Fb[A] < 16 Then Fb[A] := Base + Fb[A]
          Else If (Fb[A] >= C_GLASS) And (Fb[A] < C_GLASS + 48) Then Fb[A] := Base + (Fb[A] And 15);
        End;
  End;
End;

Procedure ParaEdge(Zz, X, Y, C, T : LongInt);
Begin
  TLine(PX(X * 4, Y * 4), PY(Zz, Y * 4), PX(X * 4 + 4, Y * 4), PY(Zz, Y * 4), T, C);
  TLine(PX(X * 4, Y * 4 + 4), PY(Zz, Y * 4 + 4), PX(X * 4 + 4, Y * 4 + 4), PY(Zz, Y * 4 + 4), T, C);
  TLine(PX(X * 4, Y * 4), PY(Zz, Y * 4), PX(X * 4, Y * 4 + 4), PY(Zz, Y * 4 + 4), T, C);
  TLine(PX(X * 4 + 4, Y * 4), PY(Zz, Y * 4), PX(X * 4 + 4, Y * 4 + 4), PY(Zz, Y * 4 + 4), T, C);
End;

{ fond, aretes du cube, plateaux de verre et leur grille }
Procedure RenderBack;
Var X, Y, Zz, K, B, U, V : LongInt; S : String;
Begin
  For Y := 0 To BH - 1 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := 0 To BW - 1 Do
    Begin
      K := Y * 15 Div BH;
      If ((X * 7 + Y * 3) Mod 23 = 0) And (K > 0) Then Dec(K);
      Fb[B + X] := C_BG + K;
    End;
  End;
  { aretes verticales du cube (sous le verre) }
  For K := 0 To 3 Do
  Begin
    U := (K Mod 2) * N * 4; V := (K Div 2) * N * 4;
    For Zz := 0 To N - 2 Do
      For Y := PY(Zz + 1, V) To PY(Zz, V) Do
        If (Y Mod 6) < 4 Then Pix(PX(U, V), Y, C_PILLAR);
  End;
  { plateaux de verre }
  For Zz := 0 To N - 1 Do
  Begin
    FillPara(Zz, -1, 0, C_GLASS);
    For K := 0 To N Do
    Begin
      TLine(PX(0, K * 4), PY(Zz, K * 4), PX(N * 4, K * 4), PY(Zz, K * 4), 0, C_GRID);
      TLine(PX(K * 4, 0), PY(Zz, 0), PX(K * 4, N * 4), PY(Zz, N * 4), 0, C_GRID);
    End;
    { tranche du verre (epaisseur) le long du bord avant }
    TLine(PX(0, 0), PY(Zz, 0) + 1, PX(N * 4, 0), PY(Zz, 0) + 1, 0, C_PILLAR);
    TLine(PX(N * 4, 0) + 1, PY(Zz, 0), PX(N * 4, N * 4) + 1, PY(Zz, N * 4), 0, C_PILLAR);
    S := 'Niveau ' + IStr(Zz + 1);
    FbText(PX(0, 0) - Length(S) * 8 - 10, PY(Zz, N * 2) - 8, S, C_TEXTD, 1);
  End;
  Move(Fb, Back, SizeOf(Fb));
End;

{ billes : sphere eclairee en haut a gauche, reflet, bord sombre }
Procedure MakeBalls;
Var P, X, Y, Dx, Dy, D2, R, Hd, S, Base, Cl, Cc : LongInt;
Begin
  R := BallR; Cc := BallSz Div 2;
  For P := 0 To 1 Do
  Begin
    Base := P * 32 * 32;
    If P = 0 Then Cl := C_RED Else Cl := C_BLUE;
    For Y := 0 To 31 Do
      For X := 0 To 31 Do
      Begin
        BallS[Base + Y * 32 + X] := 255;
        If (X < BallSz) And (Y < BallSz) Then
        Begin
          Dx := X - Cc; Dy := Y - Cc;
          D2 := Dx * Dx + Dy * Dy;
          If D2 <= R * R + R Then
          Begin
            Hd := Round(Sqrt((Dx * 3 + R) * (Dx * 3 + R) + (Dy * 3 + R) * (Dy * 3 + R)));
            S := 15 - Hd * 15 Div (R * 4);
            If S < 0 Then S := 0;
            If S > 13 Then S := 13;
            If Round(Sqrt(D2)) >= R Then S := MaxI(0, S - 4);
            If (Dx * 3 + R) * (Dx * 3 + R) + (Dy * 3 + R) * (Dy * 3 + R) <= R * R Div 2 Then S := 15;
            BallS[Base + Y * 32 + X] := Cl + S;
          End;
        End;
      End;
  End;
End;

{ ombre de la bille sur le verre (ellipse) }
Procedure BallShadow(Cx, Cy : LongInt);
Var X, Y, R, A : LongInt;
Begin
  R := BallR;
  For Y := -R Div 2 To R Div 2 Do
    For X := -R To R Do
      If X * X + 4 * Y * Y <= R * R Then
        If (Cx + X >= 0) And (Cx + X < BW) And (Cy + Y >= 0) And (Cy + Y < BH) Then
        Begin
          A := (BH - 1 - (Cy + Y)) * BW + Cx + X;
          Fb[A] := Shade[Fb[A]];
        End;
End;

Procedure DrawBall(Cx, Cy, P : LongInt);
Var X, Y, V, Base, X1, Y1 : LongInt;
Begin
  Base := (P - 1) * 32 * 32;
  X1 := Cx - BallSz Div 2; Y1 := Cy - BallSz Div 2;
  For Y := 0 To BallSz - 1 Do
    For X := 0 To BallSz - 1 Do
    Begin
      V := BallS[Base + Y * 32 + X];
      If V <> 255 Then Pix(X1 + X, Y1 + Y, V);
    End;
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

Procedure DrawBanner;
Var W, X, Y, H : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(Length(Banner) * 16, MaxI(Length(Banner2), Length(Banner3)) * 8) + 32;
  If W > BW - 16 Then W := BW - 16;
  H := 96; X := (BW - W) Div 2; Y := 152;
  Rect(X + 5, Y + 5, X + W + 4, Y + H + 4, C_SHADOW);
  Rect(X, Y, X + W - 1, Y + H - 1, C_BANNER);
  Rect(X, Y, X + W - 1, Y + 1, C_BANNERE); Rect(X, Y + H - 2, X + W - 1, Y + H - 1, C_BANNERE);
  Rect(X, Y, X + 1, Y + H - 1, C_BANNERE); Rect(X + W - 2, Y, X + W - 1, Y + H - 1, C_BANNERE);
  FbText((BW - Length(Banner) * 16) Div 2, Y + 12, Banner, BannerC, 2);
  FbText((BW - Length(Banner2) * 8) Div 2, Y + 50, Banner2, C_WHITE, 1);
  FbText((BW - Length(Banner3) * 8) Div 2, Y + 70, Banner3, C_GREEN, 1);
End;

Function LineHas(L, C : LongInt) : Boolean;
Var K : LongInt; R : Boolean;
Begin
  R := False;
  If L >= 0 Then
    For K := 0 To N - 1 Do
      If LineC[L * MaxN + K] = C Then R := True;
  LineHas := R;
End;

{ l'image : niveau courant eclaire, curseur, indice, billes, ligne gagnante }
Procedure Render;
Var Zz, Y, X, C, P, Cx, Cy, K, A, B, Lift : LongInt;
Begin
  Move(Back, Fb, SizeOf(Fb));
  If (Over = O_PLAY) And (AutoAll = 0) Then
  Begin
    FillPara(CurZ, -1, 0, C_GLASSH);
    ParaEdge(CurZ, 0, 0, C_EDGEH, 0);
    TLine(PX(0, 0), PY(CurZ, 0), PX(N * 4, 0), PY(CurZ, 0), 0, C_FRAME);
    TLine(PX(0, N * 4), PY(CurZ, N * 4), PX(N * 4, N * 4), PY(CurZ, N * 4), 0, C_FRAME);
    TLine(PX(0, 0), PY(CurZ, 0), PX(0, N * 4), PY(CurZ, N * 4), 0, C_FRAME);
    TLine(PX(N * 4, 0), PY(CurZ, 0), PX(N * 4, N * 4), PY(CurZ, N * 4), 0, C_FRAME);
    FbText(PX(0, 0) - 74, PY(CurZ, N * 2) - 8, 'Niveau ' + IStr(CurZ + 1), C_YELLOW, 1);
  End;
  If HintC >= 0 Then
  Begin
    FillPara(HintC Div (N * N), HintC Mod N, (HintC Div N) Mod N, C_GLASSD);
    ParaEdge(HintC Div (N * N), HintC Mod N, (HintC Div N) Mod N, C_HINT, 1);
  End;
  If (KbdUsed <> 0) And (Over = O_PLAY) And (AutoAll = 0) Then
    ParaEdge(CurZ, CurC Mod N, (CurC Div N) Mod N, C_CURSOR, 1);
  { billes, du fond vers l'avant dans chaque plateau }
  For Zz := 0 To N - 1 Do
    For Y := N - 1 Downto 0 Do
      For X := 0 To N - 1 Do
      Begin
        C := CellOf(X, Y, Zz);
        P := Bd[C];
        If P <> 0 Then
        Begin
          Cx := CellX(C); Cy := CellY(C);
          Lift := 0;
          If (AnOn <> 0) And (C = AnC) Then Lift := (AnN - AnK) * (AnN - AnK) * 3;
          BallShadow(Cx + 2, Cy + 1);
          DrawBall(Cx, Cy - BallR Div 2 - Lift, P);
          If (C = LastC) And (Over = O_PLAY) And (Lift = 0) Then
          Begin
            Pix(Cx - 1, Cy - BallR Div 2, C_WHITE); Pix(Cx, Cy - BallR Div 2, C_WHITE);
            Pix(Cx, Cy - BallR Div 2 - 1, C_WHITE); Pix(Cx - 1, Cy - BallR Div 2 - 1, C_WHITE);
          End;
          If LineHas(WinL, C) And ((Tick Div 8) Mod 2 = 0) Then
            Ring(Cx, Cy - BallR Div 2, BallR + 1, BallR + 2, C_WIN);
        End;
      End;
  { ligne gagnante : trait dore d'un bout a l'autre }
  If WinL >= 0 Then
  Begin
    A := LineC[WinL * MaxN]; B := LineC[WinL * MaxN + N - 1];
    For K := -1 To 0 Do
      TLine(CellX(A) + K, CellY(A) - BallR Div 2 + K, CellX(B) + K, CellY(B) - BallR Div 2 + K, 1, C_WIN);
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

Function PName(P : LongInt) : String;
Begin
  If P = 1 Then PName := 'Rouge' Else PName := 'Bleu';
End;

Function Who(P : LongInt) : String;
Begin
  If (AutoAll <> 0) Or (CompP = P) Then Who := 'Ordinateur'
  Else If CompP = 0 Then Who := 'Joueur ' + PName(P)
  Else Who := 'Vous';
End;

Procedure SmallBall(X, Y, C1, C2 : LongInt);
Begin
  FBar(X + 2, Y, X + 9, Y + 11, C1);
  FBar(X, Y + 2, X + 11, Y + 9, C1);
  FBar(X + 3, Y + 2, X + 5, Y + 4, C2);
End;

Procedure DrawInfo;
Var S : String; Y, P : LongInt;
Begin
  FBar(PnX, 64, PnX + PW - 1, 214, CLR_PALEGRAY);
  For P := 1 To 2 Do
  Begin
    Y := 46 + P * 22;
    If P = 1 Then SmallBall(PnX + 4, Y + 2, CLR_RED, CLR_WHITE) Else SmallBall(PnX + 4, Y + 2, CLR_BLUE, CLR_WHITE);
    S := Who(P);
    If (Over = O_PLAY) And (Cur = P) Then OutTxt(PnX + 22, Y, S + ' ' + Chr(17), CLR_DARKBLUE, CLR_PALEGRAY)
    Else OutTxt(PnX + 22, Y, S, CLR_BLACK, CLR_PALEGRAY);
    If P = 1 Then S := IStr(WinsR) Else S := IStr(WinsB);
    OutTxt(PnX + PW - 4 - Length(S) * 8, Y, S, CLR_BLACK, CLR_PALEGRAY);
  End;
  OutTxt(PnX + 22, 112, 'Nulles', CLR_DARKGRAY, CLR_PALEGRAY);
  S := IStr(Draws);
  OutTxt(PnX + PW - 4 - Length(S) * 8, 112, S, CLR_DARKGRAY, CLR_PALEGRAY);
  FBar(PnX, 134, PnX + PW - 1, 134, CLR_DARKGRAY);
  FBar(PnX, 135, PnX + PW - 1, 135, CLR_WHITE);
  OutTxt(PnX, 142, 'Billes pos' + Chr(130) + 'es : ' + IStr(NH) + ' / ' + IStr(NCell), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 160, 'Lignes ouvertes :', CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX + 8, 178, 'rouge ' + IStr(OpenLines(1)) + ', bleu ' + IStr(OpenLines(2)) + ' / ' + IStr(NLine),
         CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 196, 'Niveau courant : ' + IStr(CurZ + 1), CLR_DARKBLUE, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 11 * 16) Div 2, 4, 'Tic-Tac-Toe', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX + (PW - 18 * 8) Div 2, 40, 'en 3D : cube ' + IStr(N) + 'x' + IStr(N) + 'x' + IStr(N), CLR_DARKRED,
         CLR_PALEGRAY);
  DrawInfo;
  Button(PnX, 224, PW, 26, 'Nouvelle partie');
  Button(PnX, 256, (PW - 6) Div 2, 26, 'Annuler');
  Button(PnX + (PW + 6) Div 2, 256, (PW - 6) Div 2, 26, 'Indice');
  OutTxt(PnX, 296, 'Clic : poser une bille', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 312, 'Fl' + Chr(138) + 'ches : case', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 328, 'Pg Pr' + Chr(130) + 'c/Suiv : niveau', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 344, 'Espace : poser', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 360, 'U annuler  I indice', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 376, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Function Sig : LongInt;
Begin
  Sig := NH * 7 + Cur * 131 + Over * 1009 + CurZ * 10007 + WinsR * 77 + WinsB * 3 + Draws * 5 + CompP * 333 +
         AutoAll * 991;
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
  SndPrio := 0; MakeClack(0, 40, 55, 2);                  { bille posee }
  SndPrio := 1; MakeTone(1, 700, 1100, 120, 30);          { menace }
  SndPrio := 3; MakeTone(2, 520, 1560, 700, 50);          { partie gagnee }
  SndPrio := 3; MakeTone(3, 420, 140, 700, 45);           { partie perdue }
  SndPrio := 2; MakeTone(4, 600, 600, 300, 35);           { nulle }
  SndPrio := 1; MakeTone(5, 300, 260, 90, 30);            { coup refuse }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Deroulement de la partie                                              }
{ ==================================================================== }

Function IsComputer(P : LongInt) : Boolean;
Begin
  IsComputer := (AutoAll <> 0) Or (CompP = P);
End;

Procedure TurnMsg;
Var F : LongInt;
Begin
  If Over <> O_PLAY Then Exit;
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue les deux couleurs (Options).'
  Else If IsComputer(Cur) Then Msg := 'L''ordinateur (bleu) r' + Chr(130) + 'fl' + Chr(130) + 'chit...'
  Else If CompP = 0 Then Msg := 'Au joueur ' + PName(Cur) + ' : cliquez une case libre.'
  Else Msg := 'A vous (rouge) : alignez ' + IStr(N) + ' billes dans n''importe quelle direction.';
  If (Over = O_PLAY) And Not IsComputer(Cur) And (ThreatCells(3 - Cur, F) > 0) Then
    Msg := 'Attention : l''adversaire menace d''aligner ' + IStr(N) + ' billes !';
End;

Procedure GameOver(Res : LongInt);
Begin
  Over := Res;
  HintC := -1; Wait := 0;
  BannerC := C_YELLOW;
  If Res = O_DRAW Then
  Begin
    Banner := 'Partie nulle'; Banner2 := 'Le cube est plein, aucune ligne compl' + Chr(138) + 'te.';
    Inc(Draws);
    PlaySnd(4);
  End
  Else
  Begin
    If CompP = 0 Then Banner := PName(Res) + ' gagne !'
    Else If IsComputer(Res) Then Banner := 'L''ordinateur gagne'
    Else Banner := 'Vous gagnez !';
    Banner2 := IStr(N) + ' billes align' + Chr(130) + 'es en ' + IStr((NH + 1) Div 2) + ' coups.';
    If Res = 1 Then Inc(WinsR) Else Inc(WinsB);
    If IsComputer(Res) And (CompP <> 0) And (AutoAll = 0) Then
    Begin
      BannerC := C_TEXTD;
      PlaySnd(3);
    End
    Else PlaySnd(2);
  End;
  Banner3 := 'F2 ou clic : nouvelle partie';
  Msg := Banner + ' ' + Banner2;
  FullBlit := 1;
End;

{ pose une bille du joueur courant en C }
Procedure Place(C : LongInt; Anim : Boolean);
Var L, F : LongInt;
Begin
  If (C < 0) Or (C >= NCell) Or (Bd[C] <> 0) Or (Over <> O_PLAY) Then Exit;
  Bd[C] := Cur;
  Hist[NH] := C; Inc(NH);
  LastC := C; HintC := -1; Wait := 0;
  If Not IsComputer(Cur) Then
  Begin
    CurZ := C Div (N * N); CurC := C;
  End;
  If Anim And (TestMode = 0) And (Client <> 0) Then
  Begin
    AnOn := 1; AnC := C; AnK := 0; AnN := 6;
  End
  Else PlaySnd(0);
  L := WinLine(Cur);
  If L >= 0 Then
  Begin
    WinL := L;
    GameOver(Cur);
  End
  Else If NH >= NCell Then GameOver(O_DRAW)
  Else
  Begin
    Cur := 3 - Cur;
    TurnMsg;
    If ThreatCells(3 - Cur, F) > 0 Then PlaySnd(1);
  End;
  FullBlit := 1;
End;

Procedure NewGame;
Var C : LongInt;
Begin
  MakeLines;
  SetGeometry;
  If (TestMode = 0) And (Client <> 0) Then
  Begin
    RenderBack;
    MakeBalls;
  End;
  For C := 0 To MaxCell - 1 Do Bd[C] := 0;
  NH := 0; Over := O_PLAY; WinL := -1; HintC := -1; LastC := -1; AnOn := 0; Wait := 0;
  Cur := Starter;
  Starter := 3 - Starter;
  CurZ := 0; CurC := CellOf(N Div 2, 0, 0);
  Banner := ''; Banner2 := ''; Banner3 := '';
  TurnMsg;
  If (CompP <> 0) And (AutoAll = 0) And (Cur = CompP) Then Msg := 'L''ordinateur commence. ' + Msg;
  FullBlit := 1;
End;

Procedure ComputerMove;
Var C, L : LongInt;
Begin
  L := Level;
  If AutoAll <> 0 Then
  Begin
    If Cur = 1 Then L := 2 Else L := 3;
  End;
  C := AiMove(Cur, L);
  Place(C, True);
End;

Procedure UndoMove;
Var K : LongInt;
Begin
  If (AutoAll <> 0) Or (AnOn <> 0) Or (NH = 0) Then Exit;
  If (CompP <> 0) And (Over = O_PLAY) And (Cur = CompP) Then Exit;
  K := 1;
  If (CompP <> 0) And (NH >= 2) And (Bd[Hist[NH - 1]] = CompP) Then K := 2;
  While (K > 0) And (NH > 0) Do
  Begin
    Dec(NH);
    Cur := Bd[Hist[NH]];
    Bd[Hist[NH]] := 0;
    Dec(K);
  End;
  If Over = O_DRAW Then Dec(Draws)
  Else If Over = O_RED Then Dec(WinsR)
  Else If Over = O_BLUE Then Dec(WinsB);
  Over := O_PLAY; WinL := -1; HintC := -1; Banner := ''; Banner2 := ''; Banner3 := '';
  If NH > 0 Then LastC := Hist[NH - 1] Else LastC := -1;
  TurnMsg;
  Msg := 'Coup annul' + Chr(130) + '. ' + Msg;
  PlaySnd(5);
  FullBlit := 1;
End;

Function HumanTurn : Boolean;
Begin
  HumanTurn := (Over = O_PLAY) And (AnOn = 0) And Not IsComputer(Cur);
End;

Procedure Hint;
Begin
  If Not HumanTurn Then Exit;
  HintC := AiMove(Cur, 3);
  If HintC >= 0 Then
  Begin
    CurZ := HintC Div (N * N); CurC := HintC;
    Msg := 'Indice : la case marqu' + Chr(130) + 'e en vert, niveau ' + IStr(CurZ + 1) + ', colonne ' +
           IStr(HintC Mod N + 1) + ', rang' + Chr(130) + 'e ' + IStr((HintC Div N) Mod N + 1) + '.';
  End;
  FullBlit := 1;
End;

Procedure Activate(C : LongInt);
Begin
  If Over <> O_PLAY Then
  Begin
    NewGame;
    Exit;
  End;
  If Not HumanTurn Then Exit;
  If Bd[C] <> 0 Then
  Begin
    PlaySnd(5);
    Msg := 'Cette case est d' + Chr(130) + 'j' + Chr(133) + ' prise.';
    Exit;
  End;
  Place(C, True);
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If WinL >= 0 Then
    If Tick Mod 8 = 0 Then FullBlit := 1;
  If AnOn <> 0 Then
  Begin
    Inc(AnK);
    If AnK >= AnN Then
    Begin
      AnOn := 0;
      PlaySnd(0);
    End;
    Touch(CellX(AnC) - 20, CellY(AnC) - 20 - AnN * AnN * 3, CellX(AnC) + 20, CellY(AnC) + 12);
  End
  Else If (Over = O_PLAY) And IsComputer(Cur) Then
  Begin
    Inc(Wait);
    If Wait > 10 Then
    Begin
      Wait := 0;
      ComputerMove;
    End;
  End
  Else If (Over <> O_PLAY) And (AutoAll <> 0) Then
  Begin
    Inc(Wait);
    If Wait > 100 Then NewGame;
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
  SetMark(CM_LEVEL1, Level = 1); SetMark(CM_LEVEL2, Level = 2); SetMark(CM_LEVEL3, Level = 3);
  SetMark(CM_CUBE4, N = 4); SetMark(CM_CUBE3, N = 3); SetMark(CM_TWO, CompP = 0);
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0);
End;

Procedure ShowRules;
Begin
  LClr;
  LAdd('Le Tic-Tac-Toe en trois dimensions se joue dans un cube de 4 x 4 x 4 cases, dessin' + Chr(130) +
       ' comme quatre plateaux de verre empil' + Chr(130) + 's (le niveau 1 en bas). Le rouge et le bleu posent ' +
       'chacun leur tour une bille dans une case libre de n''importe quel niveau. Le premier qui aligne 4 billes ' +
       'gagne ; si le cube se remplit sans ligne, la partie est nulle.' + Chr(10) + Chr(10));
  LAdd('Les lignes vont dans toutes les directions : dans un m' + Chr(136) + 'me niveau (rang' + Chr(130) +
       'es, colonnes, diagonales), verticalement d''un niveau ' + Chr(133) + ' l''autre (une case au m' + Chr(136) +
       'me endroit sur chaque niveau), et en escalier ' + Chr(133) + ' travers les quatre niveaux, jusqu''aux ' +
       'quatre grandes diagonales du cube : 76 lignes en tout (49 dans le cube de 3 x 3 x 3).' + Chr(10) + Chr(10));
  LAdd('Conseil : les 8 coins et les 8 cases du centre sont sur 7 lignes chacune, les autres sur 4 seulement. ' +
       'Une fourchette (deux menaces ' + Chr(133) + ' la fois) gagne presque toujours.' + Chr(10) + Chr(10));
  LAdd('Le premier joueur change ' + Chr(133) + ' chaque partie. Souris : cliquer une case. Clavier : fl' +
       Chr(138) + 'ches, Pg Pr' + Chr(130) + 'c et Pg Suiv (niveau), Espace ou Entr' + Chr(130) + 'e (poser), U ' +
       '(annuler), I (indice), F2 (nouvelle partie).');
  Dummy := LMsgBox('Tic-Tac-Toe 3D - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_UNDO : UndoMove;
    CM_HINT : Hint;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_LEVEL1, CM_LEVEL2, CM_LEVEL3 :
      Begin
        Level := Id - CM_LEVEL1 + 1; SetMarks;
        Case Level Of
          1 : Msg := 'Niveau d' + Chr(130) + 'butant.';
          2 : Msg := 'Niveau moyen.';
        Else
          Msg := 'Niveau expert : l''ordinateur cherche les suites de menaces forc' + Chr(130) + 'es.';
        End;
      End;
    CM_CUBE4, CM_CUBE3 :
      Begin
        If Id = CM_CUBE4 Then N := 4 Else N := 3;
        SetMarks; NewGame;
        Dummy := WinInvalidateRect(Client, 0, 0);
      End;
    CM_TWO :
      Begin
        If CompP = 0 Then CompP := 2 Else CompP := 0;
        SetMarks; NewGame;
      End;
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; Wait := 0; TurnMsg; FullBlit := 1; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES : ShowRules;
    CM_ABOUT : Dummy := Ask('Tic-Tac-Toe 3D pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype TTT3D.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

Procedure MoveCur(Dx, Dy, Dz : LongInt);
Var X, Y : LongInt;
Begin
  If Over <> O_PLAY Then Exit;
  KbdUsed := 1;
  X := (CurC Mod N + Dx + N) Mod N; Y := ((CurC Div N) Mod N + Dy + N) Mod N;
  CurZ := (CurZ + Dz + N) Mod N;
  CurC := CellOf(X, Y, CurZ);
  HintC := -1;
  FullBlit := 1;
  Frame1;
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
    If Vk = VK_LEFT Then Begin MoveCur(-1, 0, 0); Exit; End;
    If Vk = VK_RIGHT Then Begin MoveCur(1, 0, 0); Exit; End;
    If Vk = VK_UP Then Begin MoveCur(0, 1, 0); Exit; End;
    If Vk = VK_DOWN Then Begin MoveCur(0, -1, 0); Exit; End;
    If Vk = VK_PAGEUP Then Begin MoveCur(0, 0, 1); Exit; End;
    If Vk = VK_PAGEDOWN Then Begin MoveCur(0, 0, -1); Exit; End;
    If Vk = VK_BACKSPACE Then Begin Command(CM_UNDO); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      KbdUsed := 1;
      Activate(CurC);
      Frame1;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'U' : Command(CM_UNDO);
      'I' : Command(CM_HINT);
      ' ' : Begin KbdUsed := 1; Activate(CurC); Frame1; End;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

{ case sous le point (X, Y) de l'image (-1 : aucune) }
Function CellAt(X, Y : LongInt) : LongInt;
Var Zz, V, U, R : LongInt;
Begin
  R := -1;
  For Zz := 0 To N - 1 Do
  Begin
    V := PlaneY[Zz] - Y;
    If (V >= 0) And (V < N * DYv) Then
    Begin
      U := X - X0 - V * DXv Div DYv;
      If (U >= 0) And (U < N * DXu) Then R := CellOf(U Div DXu, V Div DYv, Zz);
    End;
  End;
  CellAt := R;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, C : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 224) And (Y < 250) Then Command(CM_NEW)
    Else If (Y >= 256) And (Y < 282) Then
    Begin
      If X < PnX + PW Div 2 Then Command(CM_UNDO) Else Command(CM_HINT);
    End;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If Over <> O_PLAY Then
    Begin
      NewGame;
      Frame1;
      Exit;
    End;
    C := CellAt(X - OX, Y - OY);
    If C < 0 Then Exit;
    KbdUsed := 0;
    CurZ := C Div (N * N); CurC := C;
    Activate(C);
    FullBlit := 1;
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

Procedure Clear;
Var C : LongInt;
Begin
  For C := 0 To MaxCell - 1 Do Bd[C] := 0;
End;

Procedure RunTests;
Var Ok, A, B, C, D, E, F, K, G, Games, Moves, LvR, LvB : LongInt;
    Res : Array[0..3] Of LongInt;
Begin
  Ok := 0;
  { 1 : les lignes du cube (76 en 4 x 4 x 4 : 16 cases sur 7 lignes ; 49 en 3 x 3 x 3) }
  N := 3; MakeLines; B := NLine; C := CellN[13];
  N := 4; MakeLines; A := NLine;
  D := 0; E := 0;
  For K := 0 To NCell - 1 Do
  Begin
    If CellN[K] = 7 Then Inc(D);
    E := E + CellN[K];
  End;
  Log('TTT3D : TEST1 lignes 4x4x4 ' + IStr(A) + ' (cases a 7 lignes ' + IStr(D) + ', total ' + IStr(E) +
      ') 3x3x3 ' + IStr(B) + ' (centre ' + IStr(C) + ')');
  If (A = 76) And (D = 16) And (E = 304) And (B = 49) And (C = 13) Then Inc(Ok);
  { 2 : gain detecte (colonne verticale, grande diagonale), pas pour 3 billes }
  Clear;
  For K := 0 To 3 Do Bd[CellOf(1, 2, K)] := 1;
  A := Ord(WinLine(1) >= 0);
  Clear;
  For K := 0 To 3 Do Bd[CellOf(3 - K, K, K)] := 2;
  B := Ord(WinLine(2) >= 0);
  Clear;
  For K := 0 To 2 Do Bd[CellOf(K, 0, K)] := 1;
  Bd[CellOf(3, 0, 3)] := 2;
  C := Ord(WinLine(1) >= 0);
  Log('TTT3D : TEST2 verticale ' + IStr(A) + ' diagonale ' + IStr(B) + ' trois billes ' + IStr(C));
  If (A = 1) And (B = 1) And (C = 0) Then Inc(Ok);
  { 3 : l'ordinateur gagne, pare, et fait une fourchette }
  Seed := 7;
  Clear;
  For K := 0 To 2 Do Bd[CellOf(K, K, 2)] := 2;
  For K := 0 To 2 Do Bd[CellOf(0, 3, K)] := 1;
  A := AiMove(2, 3);                         { gagner en (3,3,2) plutot que parer }
  Clear;
  For K := 0 To 2 Do Bd[CellOf(2, K, 1)] := 1;
  Bd[CellOf(0, 0, 0)] := 2;
  B := AiMove(2, 2);                         { parer en (2,3,1) }
  { fourchette : la case (0,0,0) complete deux lignes de 3 billes a la fois }
  Clear;
  Bd[CellOf(1, 0, 0)] := 2; Bd[CellOf(2, 0, 0)] := 2; Bd[CellOf(0, 1, 0)] := 2; Bd[CellOf(0, 2, 0)] := 2;
  Bd[CellOf(3, 3, 3)] := 1; Bd[CellOf(3, 3, 2)] := 1; Bd[CellOf(2, 3, 3)] := 1; Bd[CellOf(1, 3, 1)] := 1;
  C := AiMove(2, 2);
  Bd[C] := 2;
  D := ThreatCells(2, F);
  Log('TTT3D : TEST3 gain ' + IStr(Ord(A = CellOf(3, 3, 2))) + ' parade ' + IStr(Ord(B = CellOf(2, 3, 1))) +
      ' fourchette ' + IStr(Ord(C = 0)) + ' (' + IStr(D) + ' menaces)');
  If (A = CellOf(3, 3, 2)) And (B = CellOf(2, 3, 1)) And (C = 0) And (D >= 2) Then Inc(Ok);
  { parties : expert (bleu) contre debutant (rouge), puis expert contre
    moyen, premier joueur en alternance, graine fixe }
  Seed := 2026; Starter := 1; CompP := 0; AutoAll := 0; Client := 0;
  Games := 0; Moves := 0;
  For K := 0 To 3 Do Res[K] := 0;
  For G := 0 To 15 Do
  Begin
    If G < 8 Then LvR := 1 Else LvR := 2;
    LvB := 3;
    NewGame;
    While Over = O_PLAY Do
    Begin
      If Cur = 1 Then C := AiMove(1, LvR) Else C := AiMove(2, LvB);
      Place(C, False);
      Inc(Moves);
    End;
    Inc(Res[Over]);
    Inc(Games);
  End;
  Log('TTT3D : PARTIE ' + IStr(Games) + ' parties expert contre debutant et moyen : expert ' + IStr(Res[O_BLUE]) +
      ' adversaire ' + IStr(Res[O_RED]) + ' nulles ' + IStr(Res[O_DRAW]) + ' billes ' + IStr(Moves));
  If (Games = 16) And (Res[O_BLUE] > Res[O_RED]) Then Inc(Ok);
  Log('TTT3D : ' + IStr(Ok) + '/4 essais reussis');
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
  Client := 0; Frame := 0; SoundOn := 1; Level := 2; CompP := 2; N := 4; Starter := 1; SndCur := 0;
  SndEnd := 0; TestMode := 0; KbdUsed := 0; WinsR := 0; WinsB := 0; Draws := 0; AnOn := 0; WinL := -1;
  CW := CWant; CH := CHWant; BannerC := C_YELLOW;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1; FullBlit := 1;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/LEVEL:') Then
    Begin
      Val(Copy(S, 8, 20), Level, E);
      If Level < 1 Then Level := 1;
      If Level > 3 Then Level := 3;
    End;
    If S = '/SIZE:3' Then N := 3;
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
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('TTT3D'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('TTT3D'), Z2('Tic-Tac-Toe 3D'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'U');
  MItem(MIS_TEXT, 0, CM_HINT, '~Indice' + Chr(9) + 'I');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_LEVEL1, 'Niveau ~d' + Chr(130) + 'butant');
  MItem(MIS_TEXT, 0, CM_LEVEL2, 'Niveau ~moyen');
  MItem(MIS_TEXT, 0, CM_LEVEL3, 'Niveau ~expert');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_CUBE4, 'Cube ~4 x 4 x 4');
  MItem(MIS_TEXT, 0, CM_CUBE3, 'Cube ~3 x 3 x 3');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_TWO, 'Partie ' + Chr(133) + ' ~deux joueurs');
  MItem(MIS_TEXT, 0, CM_AUTO, 'D' + Chr(130) + 'mons~tration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 10);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Tic-Tac-Toe 3D');
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
