{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: LIGHTS - Lights, casse-tete des lumieres pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program LIGHTS;

{$R-,S-,I-}

{ Compilation : OS2PC LIGHTS.PAS   (produit LIGHTS.EXE)

  Portage vers OS/2-0 du prototype LIGHTS.PAS du depot 7iles (Turbo
  Pascal, BGI en 640 x 480, clavier seulement) : fenetre de Presentation
  Manager avec menus, image en memoire recopiee par GpiDrawBits (seules
  les lampes qui changent sont recopiees), lampes en verre dans des
  douilles de metal en relief, halo de lumiere dans la douille, lampes
  qui s'allument et s'eteignent en fondu, panneau du pointage, barre
  d'etat et apparence d'OS/2 Warp 3.

  Comme le prototype : 25 niveaux sur une grille de 5 x 5 ; un clic sur
  une lampe l'inverse ainsi que ses voisines du haut, du bas, de gauche
  et de droite ; il faut eteindre toutes les lampes.
  Ce qui est corrige : le niveau 14 du prototype n'avait pas de solution
  (une configuration de 5 x 5 n'est soluble que si elle est orthogonale
  aux deux vecteurs du noyau de la matrice des coups) : une lampe y est
  ajoutee ; le compteur de coups n'etait affiche que sur deux chiffres ;
  la souris n'etait pas prise en charge.
  Ce qui s'ajoute : nombre minimal de coups de chaque niveau (resolution
  exacte par elimination de Gauss sur GF(2), les quatre solutions du
  noyau essayees), indice (une lampe de la solution la plus courte),
  affichage de la solution, annulation (sans limite), pointage (100 points
  au minimum de coups, 10 de moins par coup en trop), niveaux au hasard
  apres le 25e (toujours solubles), record de la seance, demonstration
  (l'ordinateur joue la solution), bruitages.

  Souris : clic sur une lampe. Clavier : fleches (deplacer le curseur),
  Espace ou Entree (basculer), U ou Retour arriere (annuler), I (indice),
  R (recommencer le niveau), Pg Suiv et Pg Prec (niveau suivant et
  precedent), F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /LEVEL:n (1 a 25) ; /AUTO (demonstration) ;
  /NOSOUND ; /TEST (essais du jeu sans fenetre, resultat sur le port
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
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_SPACE = $10; VK_PAGEUP = $11; VK_PAGEDOWN = $12;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_RESTART = 102; CM_UNDO = 103; CM_HINT = 104; CM_PREV = 105; CM_NEXT = 106; CM_QUIT = 107;
  CM_SOLUTION = 201; CM_AUTO = 202; CM_SOUND = 203;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : plateau de 400 x 400 }
  BW = 400; BH = 400; OX = 8; OY = 8;
  PnX = 424; PW = 192;
  CWant = 624; CHWant = 436;
  { grille de 5 x 5 : cases de 76 points, douilles de 70 points }
  NG = 5; NCell = 25; G0 = 10; CellP = 76; SockP = 70; LampR = 26;
  NLevel = 25; MaxHist = 999;
  { couleurs de l'image }
  C_BG = 0;                                  { 0..15 : degrade du fond }
  C_MET = 16;                                { 16..21 : metal (sombre -> clair) }
  C_CURSOR = 22; C_WHITE = 23; C_BLACK = 24; C_HINT = 25; C_BANNER = 26; C_BANNERE = 27; C_YELLOW = 28;
  C_SHADOW = 29; C_GREEN = 30; C_SCREW = 31;
  C_LAMP = 32;                               { 32 + niveau * 16 + nuance (niveau 0..4, nuance 0..15) }
  C_GLOW = 112;                              { 112 + niveau * 8 + nuance (0..7) }
  S_PLAY = 1; S_WON = 2;
  SndRate = 11025;
  { niveaux du prototype (ligne par ligne, 1 : allumee) ; le 14e est
    corrige (une lampe ajoutee en ligne 4, colonne 1 : il etait insoluble) }
  Levels : Array[1..NLevel] Of String[25] = (
    '0000000000101010000000000', '1010110101000001010110101', '0101011011110111101101010',
    '0000011011000001000111011', '1111011101111010001111011', '0000000000101011010101110',
    '1111010001100011000111110', '0000000100010101010101010', '0101011111011100101111100',
    '0111001110011100000000000', '1010110101101011010101110', '1111101010110110111001010',
    '0001000101010101010001000', '0000000000000001100001110', '0000001000000000100000000',
    '1000010000100001000011111', '0000000000001000111011111', '0010001010101010101000100',
    '1010100000101010000010101', '0000000000100010000000000', '0111101000011100100001000',
    '0111010001100011000101110', '0000000000001110011000100', '0000000000100011111101001',
    '1000011000111001111001111');

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  Spr : Array[0..5 * SockP * SockP - 1] Of Byte;      { douilles : 5 niveaux de lumiere }
  { plateau : masque de 25 bits (bit R * 5 + C : allumee) }
  Board, Start, SolMask, HintCell : LongInt;
  PressM : Array[0..NCell - 1] Of LongInt;
  CurL, TgtL : Array[0..NCell - 1] Of LongInt;         { lumiere affichee et visee (0..4) }
  Hist : Array[0..MaxHist] Of LongInt;
  HN, Moves, MinMoves, Level, Score, Best, Seed, State, CurX, CurY, Hints, ShowSol, AutoAll, AutoWait : LongInt;
  SoundOn, TestMode, Tick, WonWait, LastSig, Rows0 : LongInt;
  { zone a recopier }
  DX1, DY1, DX2, DY2, FullBlit : LongInt;
  Banner, Banner2, Banner3, Msg, LastMsg : String;
  { bruitages }
  SndBuf : Array[0..29999] Of Byte;
  SndOfs, SndLen, SndPri : Array[0..15] Of LongInt;
  NSndBuf, SndPrio, SndCur, SndEnd : LongInt;
  { resolution sur GF(2) }
  ERow : Array[0..NCell - 1] Of LongInt;
  PivC : Array[0..NCell - 1] Of LongInt;
  FreeC : Array[0..NCell - 1] Of LongInt;
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
{ Grille et resolution                                                  }
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

Procedure InitPress;
Var I, R, C, M : LongInt;
Begin
  For I := 0 To NCell - 1 Do
  Begin
    R := I Div NG; C := I Mod NG;
    M := 1 Shl I;
    If R > 0 Then M := M Or (1 Shl (I - NG));
    If R < NG - 1 Then M := M Or (1 Shl (I + NG));
    If C > 0 Then M := M Or (1 Shl (I - 1));
    If C < NG - 1 Then M := M Or (1 Shl (I + 1));
    PressM[I] := M;
  End;
End;

{ solution la plus courte (masque des lampes a presser) ; -1 : aucune.
  La matrice des coups est symetrique : l'equation de la lampe I a pour
  coefficients PressM[I]. Elimination complete, puis les variables
  libres (2 pour 5 x 5) sont essayees toutes. }
Function Solve(B : LongInt) : LongInt;
Var I, K, R, NP, NF, Col, P, T, Fv, X, V, Best0, BestN, FreeSel : LongInt;
Begin
  For I := 0 To NCell - 1 Do ERow[I] := PressM[I] Or (Bit(B, I) Shl 25);
  R := 0; NP := 0; NF := 0;
  For Col := 0 To NCell - 1 Do
  Begin
    P := -1;
    K := R;
    While (P < 0) And (K < NCell) Do
    Begin
      If Bit(ERow[K], Col) <> 0 Then P := K;
      Inc(K);
    End;
    If P < 0 Then
    Begin
      FreeC[NF] := Col;
      Inc(NF);
    End
    Else
    Begin
      T := ERow[R]; ERow[R] := ERow[P]; ERow[P] := T;
      For K := 0 To NCell - 1 Do
        If (K <> R) And (Bit(ERow[K], Col) <> 0) Then ERow[K] := ERow[K] Xor ERow[R];
      PivC[NP] := Col;
      Inc(NP);
      Inc(R);
    End;
  End;
  Solve := -1;
  For K := R To NCell - 1 Do
    If Bit(ERow[K], 25) <> 0 Then Exit;
  Best0 := -1; BestN := 99;
  For Fv := 0 To (1 Shl NF) - 1 Do
  Begin
    FreeSel := 0;
    For T := 0 To NF - 1 Do
      If Bit(Fv, T) <> 0 Then FreeSel := FreeSel Or (1 Shl FreeC[T]);
    X := FreeSel;
    For K := 0 To NP - 1 Do
    Begin
      V := Bit(ERow[K], 25) Xor (PopCount(ERow[K] And FreeSel) And 1);
      If V <> 0 Then X := X Or (1 Shl PivC[K]);
    End;
    If PopCount(X) < BestN Then
    Begin
      BestN := PopCount(X);
      Best0 := X;
    End;
  End;
  Solve := Best0;
End;

Function LevelMask(L : LongInt) : LongInt;
Var I, M : LongInt; S : String;
Begin
  M := 0;
  S := Levels[L];
  For I := 1 To NCell Do
    If S[I] = '1' Then M := M Or (1 Shl (I - 1));
  LevelMask := M;
End;

{ niveau au hasard (apres le 25e) : des coups au hasard depuis le plateau
  eteint, donc toujours soluble }
Function RandomMask(L : LongInt) : LongInt;
Var M, K, N : LongInt;
Begin
  Repeat
    M := 0;
    N := MinI(15, 9 + (L - NLevel) Div 3);
    For K := 1 To N Do M := M Xor PressM[Rnd(NCell)];
  Until PopCount(Solve(M)) >= MinI(10, 6 + (L - NLevel) Div 5);
  RandomMask := M;
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

{ verre eteint et lampe allumee (nuance 0 : bord ... 15 : reflet) }
Function OffC(S : LongInt) : LongInt;
Begin
  If S <= 12 Then OffC := Mix($101828, $56647E, S, 12) Else OffC := Mix($56647E, $C8D4E8, S - 12, 3);
End;

Function OnC(S : LongInt) : LongInt;
Begin
  If S <= 10 Then OnC := Mix($A84C00, $FFC830, S, 10) Else OnC := Mix($FFC830, $FFFFF0, S - 10, 5);
End;

Procedure InitBmi;
Var I, B, S : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 15 Do SetPal(C_BG + I, Mix($1A2236, $2E3A54, I, 15));
  For I := 0 To 5 Do SetPal(C_MET + I, Mix($2C3038, $D4D8E0, I, 5));
  SetPal(C_CURSOR, $38D8FF); SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $000000); SetPal(C_HINT, $40F080);
  SetPal(C_BANNER, $182040); SetPal(C_BANNERE, $A0B4FF); SetPal(C_YELLOW, $FFDC46); SetPal(C_SHADOW, $06080E);
  SetPal(C_GREEN, $64E68C); SetPal(C_SCREW, $8C9098);
  For B := 0 To 4 Do
  Begin
    For S := 0 To 15 Do SetPal(C_LAMP + B * 16 + S, Mix(OffC(S), OnC(S), B, 4));
    For S := 0 To 7 Do
      SetPal(C_GLOW + B * 8 + S, Mix(Mix($0A0E16, $1C2434, S, 7), Mix($3A2808, $D8A030, S, 7), B, 4));
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

Procedure FbTextC(Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText((BW - Length(S) * 8 * Sc) Div 2 + 1, Y + 1, S, C_SHADOW, Sc);
  FbText((BW - Length(S) * 8 * Sc) Div 2, Y, S, C, Sc);
End;

{ douilles de 70 x 70 pour les 5 niveaux de lumiere : cadre de metal en
  relief (vis aux coins), creux eclaire par la lampe, lampe en verre
  (reflet en haut a gauche, bord assombri) }
Procedure MakeSprites;
Var B, X, Y, Dx, Dy, D2, D, Hd, S, G, C, Base : LongInt;
Begin
  For B := 0 To 4 Do
  Begin
    Base := B * SockP * SockP;
    For Y := 0 To SockP - 1 Do
      For X := 0 To SockP - 1 Do
      Begin
        Dx := X - SockP Div 2; Dy := Y - SockP Div 2;
        D2 := Dx * Dx + Dy * Dy;
        If (X = 0) Or (Y = 0) Or (X = SockP - 1) Or (Y = SockP - 1) Then C := C_SHADOW
        Else If (X < 5) Or (Y < 5) Or (X > SockP - 6) Or (Y > SockP - 6) Then
        Begin
          { cadre : clair en haut et a gauche, sombre en bas et a droite }
          If (X + Y < SockP) And ((X < 5) Or (Y < 5)) Then C := C_MET + 4 Else C := C_MET + 1;
          If ((X < 5) And (Y > SockP - 6)) Or ((Y < 5) And (X > SockP - 6)) Then C := C_MET + 2;
          If (X >= 1) And (X <= 2) And (Y >= 1) Then C := C_MET + 5;
          If (Y >= 1) And (Y <= 2) And (X >= 1) And (X < SockP - 2) Then C := C_MET + 5;
        End
        Else If D2 <= LampR * LampR Then
        Begin
          { lampe : nuance selon la distance au reflet (-9, -9) }
          Hd := Round(Sqrt((Dx + 9) * (Dx + 9) + (Dy + 9) * (Dy + 9)));
          S := 15 - Hd * 15 Div 34;
          If S < 0 Then S := 0;
          If S > 15 Then S := 15;
          D := Round(Sqrt(D2));
          If D >= LampR - 2 Then S := MaxI(0, S - 5);
          If (Dx + 11) * (Dx + 11) + (Dy + 11) * (Dy + 11) <= 20 Then S := 15;
          C := C_LAMP + B * 16 + S;
        End
        Else
        Begin
          { creux : plus clair pres de la lampe, ombre du cadre en haut a gauche }
          D := Round(Sqrt(D2));
          G := 7 - (D - LampR) * 7 Div 20;
          If G < 0 Then G := 0;
          If G > 7 Then G := 7;
          If (X < 8) Or (Y < 8) Then G := MaxI(0, G - 3);
          If D <= LampR + 1 Then G := 0;
          C := C_GLOW + B * 8 + G;
        End;
        { vis aux quatre coins du cadre }
        If ((X - 2) * (X - 2) + (Y - 2) * (Y - 2) <= 2) Or ((X - SockP + 3) * (X - SockP + 3) + (Y - 2) * (Y - 2) <= 2) Or
           ((X - 2) * (X - 2) + (Y - SockP + 3) * (Y - SockP + 3) <= 2) Or
           ((X - SockP + 3) * (X - SockP + 3) + (Y - SockP + 3) * (Y - SockP + 3) <= 2) Then C := C_SCREW;
        Spr[Base + Y * SockP + X] := C;
      End;
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

Function SockX(I : LongInt) : LongInt;
Begin
  SockX := G0 + (I Mod NG) * CellP + 3;
End;

Function SockY(I : LongInt) : LongInt;
Begin
  SockY := G0 + (I Div NG) * CellP + 3;
End;

{ une case : douille, curseur, indice }
Procedure DrawCell(I : LongInt);
Var X0, Y0, X, Y, B, C, Src : LongInt;
Begin
  X0 := SockX(I); Y0 := SockY(I);
  B := CurL[I];
  If B < 0 Then B := 0;
  If B > 4 Then B := 4;
  Src := B * SockP * SockP;
  For Y := 0 To SockP - 1 Do
    For X := 0 To SockP - 1 Do Fb[(BH - 1 - (Y0 + Y)) * BW + X0 + X] := Spr[Src + Y * SockP + X];
  { curseur : cadre cyan autour de la douille }
  C := C_BG + 6;
  If (I = CurY * NG + CurX) And (State = S_PLAY) And (AutoAll = 0) Then C := C_CURSOR;
  Rect(X0 - 3, Y0 - 3, X0 + SockP + 2, Y0 - 2, C); Rect(X0 - 3, Y0 + SockP + 1, X0 + SockP + 2, Y0 + SockP + 2, C);
  Rect(X0 - 3, Y0 - 3, X0 - 2, Y0 + SockP + 2, C); Rect(X0 + SockP + 1, Y0 - 3, X0 + SockP + 2, Y0 + SockP + 2, C);
  { indice ou solution : anneau vert au centre de la lampe }
  If (State = S_PLAY) And ((I = HintCell) Or ((ShowSol <> 0) And (SolMask <> -1) And (Bit(SolMask, I) <> 0))) Then
  Begin
    For Y := -8 To 8 Do
      For X := -8 To 8 Do
        If (X * X + Y * Y <= 64) And (X * X + Y * Y >= 30) Then Pix(X0 + 35 + X, Y0 + 35 + Y, C_HINT);
    Disc(X0 + 35, Y0 + 35, 2, C_HINT);
  End;
  Touch(X0 - 3, Y0 - 3, X0 + SockP + 2, Y0 + SockP + 2);
End;

Procedure DrawBanner;
Var Y : LongInt;
Begin
  If Banner = '' Then Exit;
  Rect(42, 136, 369, 263, C_SHADOW);
  Rect(36, 130, 363, 257, C_BANNER);
  Rect(36, 130, 363, 131, C_BANNERE); Rect(36, 256, 363, 257, C_BANNERE);
  Rect(36, 130, 37, 257, C_BANNERE); Rect(362, 130, 363, 257, C_BANNERE);
  Y := 146;
  FbText((BW - Length(Banner) * 16) Div 2, Y, Banner, C_YELLOW, 2);
  FbText((BW - Length(Banner2) * 8) Div 2, Y + 44, Banner2, C_WHITE, 1);
  FbText((BW - Length(Banner3) * 8) Div 2, Y + 68, Banner3, C_GREEN, 1);
  Touch(36, 130, 369, 263);
End;

{ tout le plateau }
Procedure RenderAll;
Var Y, I, R : LongInt;
Begin
  For Y := 0 To BH - 1 Do
  Begin
    R := C_BG + Y * 16 Div BH;
    Rect(0, Y, BW - 1, Y, R);
  End;
  For I := 0 To NCell - 1 Do DrawCell(I);
  DrawBanner;
  DX1 := 0; DY1 := 0; DX2 := BW - 1; DY2 := BH - 1;
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

Function LitCount : LongInt;
Begin
  LitCount := PopCount(Board);
End;

Procedure DrawCounters;
Var S : String;
Begin
  FBar(PnX + 2, 86, PnX + PW - 3, 120, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 87, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 128, PnX + PW - 1, 226, CLR_PALEGRAY);
  If Level <= NLevel Then S := 'Niveau : ' + IStr(Level) + ' / ' + IStr(NLevel)
  Else S := 'Niveau : ' + IStr(Level) + ' (hasard)';
  OutTxt(PnX, 128, S, CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 146, 'Coups : ' + IStr(Moves), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 164, 'Minimum : ' + IStr(MinMoves), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 182, 'Allum' + Chr(130) + 'es : ' + IStr(LitCount), CLR_BLACK, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 204, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 6 * 16) Div 2, 8, 'Lights', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 64, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 82, PnX + PW - 1, 124, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 83, PnX + PW - 2, 123, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 84, PnX + PW - 3, 122, CLR_WHITE);
  DrawCounters;
  Button(PnX, 232, PW, 26, 'Recommencer');
  Button(PnX, 264, PW, 26, 'Annuler');
  Button(PnX, 296, PW, 26, 'Indice');
  OutTxt(PnX, 334, 'Clic : basculer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 350, 'Fl' + Chr(138) + 'ches et Espace', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 366, 'U : annuler  I : indice', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 382, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Function Sig : LongInt;
Begin
  Sig := Score * 7 + Level * 131 + Moves * 1009 + MinMoves * 10007 + Best * 3 + LitCount * 77;
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
  RenderAll;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1; FullBlit := 0;
  DrawPanel;
  DrawStatus;
  LastMsg := Msg; LastSig := Sig;
  Dummy := WinEndPaint(Hps);
End;

{ recopie des zones changees (hors de WM_PAINT) }
Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If FullBlit <> 0 Then
  Begin
    RenderAll;
    BlitRect(Hps, 0, 0, BW - 1, BH - 1);
    FullBlit := 0;
  End
  Else If DX2 >= DX1 Then BlitRect(Hps, DX1, DY1, DX2, DY2);
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1;
  If Sig <> LastSig Then
  Begin
    LastSig := Sig;
    DrawCounters;
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
  SndPrio := 0; MakeTone(0, 1800, 1200, 35, 30);         { interrupteur }
  SndPrio := 0; MakeTone(1, 500, 380, 60, 30);           { annulation }
  SndPrio := 2; MakeTone(2, 660, 1980, 650, 45);         { niveau reussi }
  SndPrio := 1; MakeTone(3, 1200, 1500, 120, 30);        { indice }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure SetTargets(Instant : Boolean);
Var I : LongInt;
Begin
  For I := 0 To NCell - 1 Do
  Begin
    TgtL[I] := Bit(Board, I) * 4;
    If Instant Then CurL[I] := TgtL[I];
  End;
End;

Procedure PlayMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue la solution (Options).'
  Else Msg := 'Eteignez toutes les lampes. Clic : la lampe et ses voisines changent.';
End;

Procedure LoadLevel(L : LongInt);
Begin
  If L < 1 Then L := 1;
  Level := L;
  If L <= NLevel Then Board := LevelMask(L) Else Board := RandomMask(L);
  Start := Board;
  SolMask := Solve(Board);
  MinMoves := PopCount(SolMask);
  Moves := 0; HN := 0; HintCell := -1; Hints := 0;
  State := S_PLAY; Banner := ''; Banner2 := ''; Banner3 := '';
  AutoWait := 0;
  SetTargets(False);
  PlayMsg;
  FullBlit := 1;
End;

Procedure NewGame;
Begin
  Score := 0;
  LoadLevel(1);
  Frame1;
End;

Procedure Won;
Var Pts : LongInt;
Begin
  State := S_WON;
  Pts := 100 - 10 * (Moves - MinMoves) - 20 * Hints;
  If Pts < 10 Then Pts := 10;
  If AutoAll <> 0 Then Pts := 0;
  Score := Score + Pts;
  If Score > Best Then Best := Score;
  WonWait := 0;
  If Level = NLevel Then
  Begin
    Banner := 'Bravo !';
    Banner2 := 'Les ' + IStr(NLevel) + ' niveaux sont r' + Chr(130) + 'ussis.';
  End
  Else
  Begin
    Banner := 'Niveau r' + Chr(130) + 'ussi';
    Banner2 := IStr(Moves) + ' coups (minimum ' + IStr(MinMoves) + ')  +' + IStr(Pts) + ' points';
  End;
  Banner3 := 'Clic ou Entr' + Chr(130) + 'e : niveau suivant';
  Msg := 'Niveau ' + IStr(Level) + ' r' + Chr(130) + 'ussi en ' + IStr(Moves) + ' coups.';
  PlaySnd(2);
End;

{ presser la lampe I (Undo : retour en arriere) }
Procedure Press(I : LongInt; Undo : Boolean);
Var K : LongInt;
Begin
  If (I < 0) Or (I >= NCell) Or (State <> S_PLAY) Then Exit;
  Board := Board Xor PressM[I];
  If Undo Then
  Begin
    Dec(Moves);
    PlaySnd(1);
  End
  Else
  Begin
    Inc(Moves);
    If HN <= MaxHist Then
    Begin
      Hist[HN] := I;
      Inc(HN);
    End;
    PlaySnd(0);
  End;
  CurX := I Mod NG; CurY := I Div NG;
  SolMask := Solve(Board);
  HintCell := -1;
  For K := 0 To NCell - 1 Do TgtL[K] := Bit(Board, K) * 4;
  If Board = 0 Then Won;
  FullBlit := 1;
End;

Procedure UndoMove;
Begin
  If (State <> S_PLAY) Or (HN = 0) Then Exit;
  Dec(HN);
  Press(Hist[HN], True);
End;

Procedure Hint;
Var I : LongInt;
Begin
  If (State <> S_PLAY) Or (SolMask = -1) Or (SolMask = 0) Then Exit;
  I := 0;
  While (I < NCell) And (Bit(SolMask, I) = 0) Do Inc(I);
  HintCell := I;
  Inc(Hints);
  Msg := 'Indice : appuyez sur la lampe marqu' + Chr(130) + 'e d''un anneau vert (ligne ' + IStr(I Div NG + 1) +
         ', colonne ' + IStr(I Mod NG + 1) + ').';
  PlaySnd(3);
  FullBlit := 1;
End;

Procedure NextLevel;
Begin
  LoadLevel(Level + 1);
End;

Procedure TimerTick;
Var I, Changed, Pend : LongInt;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  Changed := 0; Pend := 0;
  For I := 0 To NCell - 1 Do
    If CurL[I] <> TgtL[I] Then
    Begin
      If CurL[I] < TgtL[I] Then Inc(CurL[I]) Else Dec(CurL[I]);
      DrawCell(I);
      Changed := 1;
      If CurL[I] <> TgtL[I] Then Pend := 1;
    End;
  If (Changed <> 0) And (Banner <> '') Then DrawBanner;
  If (State = S_WON) And (Pend = 0) Then
  Begin
    Inc(WonWait);
    If (AutoAll <> 0) And (WonWait > 45) Then NextLevel;
  End;
  If (AutoAll <> 0) And (State = S_PLAY) And (Pend = 0) Then
  Begin
    Inc(AutoWait);
    If AutoWait > 14 Then
    Begin
      AutoWait := 0;
      If (SolMask <> -1) And (SolMask <> 0) Then
      Begin
        I := 0;
        While (I < NCell) And (Bit(SolMask, I) = 0) Do Inc(I);
        Press(I, False);
      End;
    End;
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
  SetMark(CM_SOLUTION, ShowSol <> 0); SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_RESTART : Begin LoadLevel(Level); Msg := 'Niveau ' + IStr(Level) + ' recommenc' + Chr(130) + '.'; End;
    CM_UNDO : UndoMove;
    CM_HINT : Hint;
    CM_PREV : If Level > 1 Then LoadLevel(Level - 1);
    CM_NEXT : NextLevel;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_SOLUTION : Begin ShowSol := 1 - ShowSol; SetMarks; FullBlit := 1; End;
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; AutoWait := 0; If State = S_PLAY Then PlayMsg; FullBlit := 1; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Le plateau compte 25 lampes. Un clic sur une lampe la fait changer d''' + Chr(130) + 'tat (allum' +
             Chr(130) + 'e ou ' + Chr(130) + 'teinte), ainsi que ses voisines du haut, du bas, de gauche et de ' +
             'droite. Le but : ' + Chr(130) + 'teindre toutes les lampes, avec le moins de coups possible.' + Chr(10) +
             Chr(10));
        LAdd('Le panneau indique le nombre minimal de coups du niveau (calcul' + Chr(130) + ' exactement). R' +
             Chr(130) + 'ussir au minimum rapporte 100 points, 10 de moins par coup en trop et 20 de moins par ' +
             'indice (au moins 10). Apr' + Chr(138) + 's les 25 niveaux, les niveaux suivants sont tir' + Chr(130) +
             's au hasard (toujours solubles).' + Chr(10) + Chr(10));
        LAdd('Annuler (U) d' + Chr(130) + 'fait le dernier coup ; Indice (I) marque une lampe de la solution la ' +
             'plus courte ; Options - Afficher la solution les marque toutes. Presser deux fois la m' + Chr(136) +
             'me lampe ne change rien : l''ordre des coups n''a pas d''importance.' + Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches (curseur), Espace ou Entr' + Chr(130) + 'e (basculer), U ou ' +
             'Retour arri' + Chr(138) + 're (annuler), I (indice), R (recommencer), Pg Suiv et Pg Pr' + Chr(130) +
             'c (niveau suivant et pr' + Chr(130) + 'c' + Chr(130) + 'dent), F2 (nouvelle partie).');
        Dummy := LMsgBox('Lights - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Lights pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype LIGHTS.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

Procedure Action;
Begin
  If State = S_WON Then
  Begin
    NextLevel;
    Frame1;
    Exit;
  End;
  If AutoAll <> 0 Then Exit;
  Press(CurY * NG + CurX, False);
  Frame1;
End;

Procedure MoveCur(Dx, Dy : LongInt);
Var Old : LongInt;
Begin
  If State <> S_PLAY Then Exit;
  Old := CurY * NG + CurX;
  CurX := (CurX + Dx + NG) Mod NG; CurY := (CurY + Dy + NG) Mod NG;
  DrawCell(Old);
  DrawCell(CurY * NG + CurX);
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
    If Vk = VK_LEFT Then Begin MoveCur(-1, 0); Exit; End;
    If Vk = VK_RIGHT Then Begin MoveCur(1, 0); Exit; End;
    If Vk = VK_UP Then Begin MoveCur(0, -1); Exit; End;
    If Vk = VK_DOWN Then Begin MoveCur(0, 1); Exit; End;
    If Vk = VK_PAGEUP Then Begin Command(CM_PREV); Exit; End;
    If Vk = VK_PAGEDOWN Then Begin Command(CM_NEXT); Exit; End;
    If Vk = VK_BACKSPACE Then Begin Command(CM_UNDO); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Action; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'U' : Command(CM_UNDO);
      'I' : Command(CM_HINT);
      'R' : Command(CM_RESTART);
      'N' : Command(CM_NEXT);
      ' ' : Action;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, C, R : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 232) And (Y < 258) Then Command(CM_RESTART)
    Else If (Y >= 264) And (Y < 290) Then Command(CM_UNDO)
    Else If (Y >= 296) And (Y < 322) Then Command(CM_HINT);
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If State = S_WON Then
    Begin
      Action;
      Exit;
    End;
    If AutoAll <> 0 Then Exit;
    X := X - OX - G0; Y := Y - OY - G0;
    If (X < 0) Or (Y < 0) Then Exit;
    C := X Div CellP; R := Y Div CellP;
    If (C >= NG) Or (R >= NG) Then Exit;
    If (X Mod CellP < 3) Or (Y Mod CellP < 3) Or (X Mod CellP > SockP + 2) Or (Y Mod CellP > SockP + 2) Then Exit;
    Press(R * NG + C, False);
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

Procedure RunTests;
Var Ok, L, M, X, I, Tot, Good, B0, K, N, Bad, Sv : LongInt;
Begin
  Ok := 0;
  InitPress;
  { 1 : un coup inverse la lampe et ses voisines (3 au coin, 4 au bord, 5 au centre) }
  B0 := PressM[0]; M := PressM[2]; X := PressM[12];
  Log('LIGHTS : TEST1 coin ' + IStr(PopCount(B0)) + ' bord ' + IStr(PopCount(M)) + ' centre ' + IStr(PopCount(X)));
  If (PopCount(B0) = 3) And (PopCount(M) = 4) And (PopCount(X) = 5) And (B0 = 1 + 2 + 32) Then Inc(Ok);
  { 2 : les 25 niveaux sont solubles ; la solution la plus courte les eteint }
  Tot := 0; Good := 0;
  For L := 1 To NLevel Do
  Begin
    B0 := LevelMask(L);
    X := Solve(B0);
    If X <> -1 Then
    Begin
      M := B0;
      For I := 0 To NCell - 1 Do
        If Bit(X, I) <> 0 Then M := M Xor PressM[I];
      If M = 0 Then Inc(Good);
      Tot := Tot + PopCount(X);
    End
    Else Log('LIGHTS : niveau ' + IStr(L) + ' insoluble');
  End;
  Log('LIGHTS : TEST2 niveaux ' + IStr(Good) + '/25 resolus, minimum total ' + IStr(Tot) + ', niveau 14 : ' +
      IStr(PopCount(Solve(LevelMask(14)))) + ' coups');
  If (Good = NLevel) And (Tot = 201) Then Inc(Ok);
  { 3 : partie jouee : coups, annulation, niveau reussi, pointage }
  Seed := 4242; Score := 0; Best := 0; AutoAll := 0; ShowSol := 0;
  LoadLevel(3);
  Sv := Board;
  Press(0, False); Press(7, False); Press(24, False);
  N := Moves;
  UndoMove; UndoMove; UndoMove;
  K := Ord((Board = Sv) And (Moves = 0));
  X := SolMask;
  For I := 0 To NCell - 1 Do
    If Bit(X, I) <> 0 Then Press(I, False);
  Log('LIGHTS : TEST3 coups ' + IStr(N) + ' annules ' + IStr(K) + ' niveau 3 en ' + IStr(Moves) + ' coups etat ' +
      IStr(State) + ' pointage ' + IStr(Score));
  If (N = 3) And (K = 1) And (State = S_WON) And (Moves = 6) And (Score = 100) Then Inc(Ok);
  { partie complete : les 25 niveaux, puis 10 niveaux au hasard (graine fixe) }
  Seed := 1; Score := 0; Bad := 0; Tot := 0;
  LoadLevel(1);
  While Level <= NLevel + 10 Do
  Begin
    X := SolMask;
    If X = -1 Then Inc(Bad)
    Else
      For I := 0 To NCell - 1 Do
        If Bit(X, I) <> 0 Then Press(I, False);
    If State <> S_WON Then Inc(Bad);
    Tot := Tot + Moves;
    NextLevel;
  End;
  Log('LIGHTS : PARTIE niveaux 35 coups ' + IStr(Tot) + ' echecs ' + IStr(Bad) + ' pointage ' + IStr(Score));
  Log('LIGHTS : ' + IStr(Ok) + '/3 essais reussis');
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
  Flg, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y, StartLevel : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  InDlg := 0;
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Banner3 := ''; Best := 0; Tick := 0;
  Client := 0; Frame := 0; SoundOn := 1; ShowSol := 0; StartLevel := 1; Level := 1; SndCur := 0; SndEnd := 0;
  Score := 0; TestMode := 0; State := S_PLAY; CurX := 2; CurY := 2; CW := CWant; CH := CHWant;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1; FullBlit := 1; HintCell := -1; Rows0 := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/LEVEL:') Then
    Begin
      Val(Copy(S, 8, 20), StartLevel, E);
      If StartLevel < 1 Then StartLevel := 1;
      If StartLevel > NLevel Then StartLevel := NLevel;
    End;
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
    If S = '/TEST' Then TestMode := 1;
  End;
  If TestMode <> 0 Then
  Begin
    RunTests;
    Halt(0);
  End;
  InitPress;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  MakeSprites;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('LIGHTS'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('LIGHTS'), Z2('Lights'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_RESTART, '~Recommencer le niveau' + Chr(9) + 'R');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'U');
  MItem(MIS_TEXT, 0, CM_HINT, '~Indice' + Chr(9) + 'I');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_PREV, 'Niveau ~pr' + Chr(130) + 'c' + Chr(130) + 'dent' + Chr(9) + 'Pg Pr' + Chr(130) + 'c');
  MItem(MIS_TEXT, 0, CM_NEXT, 'Niveau ~suivant' + Chr(9) + 'Pg Suiv');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 10);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_SOLUTION, '~Afficher la solution');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 3);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Lights');
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
  LoadLevel(StartLevel);
  SetTargets(True);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
