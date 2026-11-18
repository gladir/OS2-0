{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BILLARD - billard americain a 8 boules pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program BILLARD;

{$R-,S-,I-}

{ Compilation : OS2PC BILLARD.PAS   (produit BILLARD.EXE)

  Portage vers OS/2-0 du prototype BILLARD.PAS du depot 7iles (Turbo
  Pascal et BGI, visee aux fleches, ecran de titre) : fenetre de
  Presentation Manager avec menus, visee a la souris, table dessinee dans
  une image en memoire (GpiDrawBits : pas de scintillement), panneau des
  joueurs, barre d'etat et apparence d'OS/2.

  Jeu de la boule 8 : apres la casse, le premier joueur qui empoche une
  boule prend les pleines (1 a 7) ou les rayees (9 a 15) ; l'autre a les
  autres. On rejoue tant qu'on empoche une de ses boules sans faute. Il
  faut empocher toutes ses boules puis la 8 ; empocher la 8 trop tot (ou
  avec une faute) fait perdre. Fautes : boule blanche empochee, aucune
  boule touchee, premiere boule touchee qui n'est pas des siennes ; le tour
  passe a l'adversaire et la blanche revient sur son point si elle a ete
  empochee.

  Souris : la queue suit le pointeur ; maintenir le bouton 1 pour doser
  la puissance (la jauge monte puis redescend), le relacher pour tirer.
  Une ligne de visee montre la premiere boule touchee. Clavier : fleches
  (gauche et droite : 1 degre, haut et bas : 5 degres), Espace (puissance,
  comme le prototype), Entree (tirer), F2 (nouvelle partie), F1 (regles).
  Modes : contre l'ordinateur (il vise la boule la mieux placee vers une
  poche, Facile ou Normal) ou deux joueurs (comme le prototype).
  Parametres : /SEED:n (hasard reproductible) ; /AUTO (l'ordinateur joue
  les deux joueurs : demonstration et essais). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18;
  VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_QUIT = 104; CM_VSCPU = 111; CM_TWO = 112; CM_EASY = 121; CM_NORMAL = 122; CM_GUIDE = 131;
  CM_RULES = 301; CM_ABOUT = 302;
  { image de la table (pixels, Y vers le bas) : multiple de 4 en largeur }
  BW = 584; BH = 320;
  OX = 8; OY = 8;                   { position de l'image dans la zone client }
  CL = 22; CT = 22; CR = 561; CB = 297;  { tapis (bandes comprises) }
  Rb = 8;                           { rayon d'une boule }
  Sh = 64;                          { unites de position : 1/64 de pixel }
  NB = 16;
  MaxPow = 30;
  CWant = 600; CHWant = 424;
  { couleurs de l'image }
  P_BLACK = 0; P_WHITE = 1; P_CLOTH = 2; P_CLOTHD = 3; P_WOOD = 4; P_WOODD = 5; P_WOODL = 6;
  P_YEL = 7; P_BLU = 8; P_RED = 9; P_PUR = 10; P_ORA = 11; P_GRN = 12; P_MAR = 13; P_GRAY = 14;
  P_IVORY = 15; P_TAN = 16; P_TIP = 17; P_GUIDE = 18; P_CUSH = 19;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Bg : Array[0..BW * BH - 1] Of Byte;   { image (lignes de bas en haut) ; fond fixe }
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  BX, BY, VX, VY, BAct : Array[0..NB - 1] Of LongInt;
  PkX, PkY, PkR : Array[0..5] Of LongInt;
  AimX, AimY, Power, PowDir, Charging, Moving, Turn, Mode, Level, Over, Seed, AutoAll, Guide : LongInt;
  Group : Array[1..2] Of LongInt;   { 0 a determiner, 1 pleines, 2 rayees }
  Potted : Array[0..NB - 1] Of LongInt;
  NPot, FirstHit, Scratch, Break1, Wait, CpuAim, Winner : LongInt;
  OwnBefore, FullNext : LongInt;
  LX, LY : Array[0..NB - 1] Of LongInt;   { positions affichees (pixels ; LX = -100 : absente) }
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
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

Procedure WrL(A, V : LongInt);
Begin
  WrW(A, V And $FFFF);
  WrW(A + 2, (V Shr 16) And $FFFF);
End;

Function ISqrt(N : LongInt) : LongInt;
Var X, Y : LongInt;
Begin
  If N <= 0 Then
  Begin
    ISqrt := 0;
    Exit;
  End;
  X := N;
  Y := (X + 1) Div 2;
  While Y < X Do
  Begin
    X := Y;
    Y := (X + N Div X) Div 2;
  End;
  ISqrt := X;
End;

{ ==================================================================== }
{ Image de la table                                                     }
{ ==================================================================== }

Procedure InitBmi;
Const
  Pal : Array[0..19] Of LongInt = (
    $000000, $FFFFFF, $00804A, $006A3C, $7A3E14, $4A2208, $A8642C, $F2C810,
    $1840C8, $E02424, $7424A8, $F07818, $28A048, $801C1C, $606060, $F0E8C8,
    $D8B070, $3050A0, $C8F0D0, $00703F);
Var I, A : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 19 Do
  Begin
    A := LongInt(@Bmi) + 16 + I * 4;
    WrB(A, Pal[I] And 255);
    WrB(A + 1, (Pal[I] Shr 8) And 255);
    WrB(A + 2, (Pal[I] Shr 16) And 255);
  End;
End;

Procedure Pix(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Fb[(BH - 1 - Y) * BW + X] := C;
End;

Procedure Span(X1, X2, Y, C : LongInt);
Var A, X : LongInt;
Begin
  If (Y < 0) Or (Y >= BH) Then Exit;
  If X1 < 0 Then X1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If X2 < X1 Then Exit;
  A := (BH - 1 - Y) * BW;
  For X := X1 To X2 Do Fb[A + X] := C;
End;

Procedure Rect(X1, Y1, X2, Y2, C : LongInt);
Var Y : LongInt;
Begin
  For Y := Y1 To Y2 Do Span(X1, X2, Y, C);
End;

Procedure DiscB(X, Y, R, C : LongInt);
Var Dy, W : LongInt;
Begin
  For Dy := -R To R Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) + Dy * Dy <= R * R + R Do Inc(W);
    Span(X - W, X + W, Y + Dy, C);
  End;
End;

Procedure CircleB(X, Y, R, C : LongInt);
Var Dy, W, Pw : LongInt;
Begin
  Pw := 0;
  For Dy := -R To R Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) + Dy * Dy <= R * R + R Do Inc(W);
    Pix(X - W, Y + Dy, C); Pix(X + W, Y + Dy, C);
    If (Dy = -R) Or (Dy = R) Then Span(X - W, X + W, Y + Dy, C);
  End;
End;

Procedure LineB(X1, Y1, X2, Y2, C : LongInt);
Var Dx, Dy, Sx, Sy, E, E2 : LongInt;
Begin
  Dx := Abs(X2 - X1); Dy := -Abs(Y2 - Y1);
  If X1 < X2 Then Sx := 1 Else Sx := -1;
  If Y1 < Y2 Then Sy := 1 Else Sy := -1;
  E := Dx + Dy;
  While True Do
  Begin
    Pix(X1, Y1, C);
    If (X1 = X2) And (Y1 = Y2) Then Exit;
    E2 := 2 * E;
    If E2 >= Dy Then Begin E := E + Dy; X1 := X1 + Sx; End;
    If E2 <= Dx Then Begin E := E + Dx; Y1 := Y1 + Sy; End;
  End;
End;

{ chiffres de 3 x 5 pour les numeros des boules }
Const
  Dig : Array[0..9] Of LongInt = ($7B6F, $2C97, $73E7, $73CF, $5BC9, $79CF, $79EF, $7249, $7BEF, $7BCF);

Procedure Digit(X, Y, D, C : LongInt);
Var R, K : LongInt;
Begin
  For R := 0 To 4 Do
    For K := 0 To 2 Do
      If (Dig[D] And (1 Shl (14 - R * 3 - K))) <> 0 Then Pix(X + K, Y + R, C);
End;

Function BallColor(N : LongInt) : LongInt;
Begin
  Case N Mod 8 Of
    1 : BallColor := P_YEL;
    2 : BallColor := P_BLU;
    3 : BallColor := P_RED;
    4 : BallColor := P_PUR;
    5 : BallColor := P_ORA;
    6 : BallColor := P_GRN;
    7 : BallColor := P_MAR;
  Else
    BallColor := P_BLACK;
  End;
End;

{ boule N centree en (X, Y) (pixels) }
Procedure DrawBall(X, Y, N : LongInt);
Var Dy, W, C : LongInt;
Begin
  DiscB(X + 1, Y + 2, Rb, P_CLOTHD);       { ombre }
  DiscB(X, Y, Rb, P_BLACK);
  C := BallColor(N);
  If N = 0 Then DiscB(X, Y, Rb - 1, P_WHITE)
  Else If N <= 8 Then DiscB(X, Y, Rb - 1, C)
  Else
  Begin
    { rayee : blanche avec une bande de couleur }
    DiscB(X, Y, Rb - 1, P_WHITE);
    For Dy := -4 To 4 Do
    Begin
      W := 0;
      While (W + 1) * (W + 1) + Dy * Dy <= (Rb - 1) * (Rb - 1) + Rb - 1 Do Inc(W);
      Span(X - W, X + W, Y + Dy, C);
    End;
  End;
  If N > 0 Then
  Begin
    DiscB(X, Y, 3, P_WHITE);
    If N >= 10 Then
    Begin
      Digit(X - 3, Y - 2, 1, P_BLACK); Digit(X + 1, Y - 2, N - 10, P_BLACK);
    End
    Else Digit(X - 1, Y - 2, N, P_BLACK);
  End;
  Pix(X - 3, Y - 4, P_WHITE); Pix(X - 4, Y - 3, P_WHITE); Pix(X - 3, Y - 3, P_WHITE);
End;

{ fond fixe : bois, bandes, tapis, mouches, poches }
Procedure BuildBg;
Var K, X, Y : LongInt;
Begin
  Rect(0, 0, BW - 1, BH - 1, P_WOOD);
  Rect(0, 0, BW - 1, 1, P_WOODD); Rect(0, BH - 2, BW - 1, BH - 1, P_WOODD);
  Rect(0, 0, 1, BH - 1, P_WOODD); Rect(BW - 2, 0, BW - 1, BH - 1, P_WOODD);
  Rect(3, 3, BW - 4, 4, P_WOODL); Rect(3, 3, 4, BH - 4, P_WOODL);
  { bandes (un peu plus foncees que le tapis) }
  Rect(CL - 6, CT - 6, CR + 6, CB + 6, P_CUSH);
  Rect(CL, CT, CR, CB, P_CLOTH);
  { ligne de casse et points }
  X := CL + (CR - CL) Div 4;
  For Y := CT + 2 To CB - 2 Do If Y Mod 3 <> 0 Then Pix(X, Y, P_CLOTHD);
  DiscB(X, (CT + CB) Div 2, 1, P_CLOTHD);
  DiscB(CL + 3 * (CR - CL) Div 4, (CT + CB) Div 2, 1, P_CLOTHD);
  { mouches sur le bois }
  For K := 1 To 7 Do
    If K <> 4 Then
    Begin
      X := CL + K * (CR - CL) Div 8;
      DiscB(X, 9, 1, P_IVORY); DiscB(X, BH - 10, 1, P_IVORY);
    End;
  For K := 1 To 3 Do
  Begin
    Y := CT + K * (CB - CT) Div 4;
    DiscB(9, Y, 1, P_IVORY); DiscB(BW - 10, Y, 1, P_IVORY);
  End;
  { poches }
  For K := 0 To 5 Do
  Begin
    DiscB(PkX[K], PkY[K], 13, P_WOODD);
    DiscB(PkX[K], PkY[K], 11, P_BLACK);
  End;
  Move(Fb, Bg, SizeOf(Fb));
End;

{ ==================================================================== }
{ Physique (positions et vitesses en 1/64 de pixel, 4 sous-pas par top) }
{ ==================================================================== }

Procedure InitPockets;
Begin
  PkX[0] := CL - 2; PkY[0] := CT - 2;
  PkX[1] := (CL + CR) Div 2; PkY[1] := CT - 5;
  PkX[2] := CR + 2; PkY[2] := CT - 2;
  PkX[3] := CL - 2; PkY[3] := CB + 2;
  PkX[4] := (CL + CR) Div 2; PkY[4] := CB + 5;
  PkX[5] := CR + 2; PkY[5] := CB + 2;
  PkR[0] := 20; PkR[2] := 20; PkR[3] := 20; PkR[5] := 20;
  PkR[1] := 17; PkR[4] := 17;
End;

Function IsOwn(P, N : LongInt) : Boolean;
Begin
  If Group[P] = 1 Then IsOwn := (N >= 1) And (N <= 7)
  Else If Group[P] = 2 Then IsOwn := (N >= 9) And (N <= 15)
  Else IsOwn := (N >= 1) And (N <= 15) And (N <> 8);
End;

Function OwnLeft(P : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  If Group[P] = 0 Then
  Begin
    OwnLeft := 7;
    Exit;
  End;
  For K := 1 To 15 Do If (BAct[K] <> 0) And (K <> 8) And IsOwn(P, K) Then Inc(N);
  OwnLeft := N;
End;

{ remet la blanche sur son point (decalee si la place est prise) }
Procedure SpotCue;
Var X, Y, K : LongInt; Free : Boolean;
Begin
  X := CL + (CR - CL) Div 4; Y := (CT + CB) Div 2;
  Repeat
    Free := True;
    For K := 1 To NB - 1 Do
      If BAct[K] <> 0 Then
        If (Abs(BX[K] Div Sh - X) < 2 * Rb + 1) And (Abs(BY[K] Div Sh - Y) < 2 * Rb + 1) Then Free := False;
    If Not Free Then X := X - 3;
  Until Free Or (X < CL + Rb);
  BX[0] := X * Sh; BY[0] := Y * Sh; VX[0] := 0; VY[0] := 0; BAct[0] := 1;
End;

Procedure Rack;
Var Slot, Pool : Array[0..14] Of LongInt; R, C, K, N, I, J, T, Fx, Fy, Ss : LongInt;
Begin
  { triangle : la 8 au milieu, une pleine et une rayee aux coins arriere }
  N := 0;
  For K := 1 To 15 Do
    If (K <> 8) And (K <> 1) And (K <> 9) Then
    Begin
      Pool[N] := K; Inc(N);
    End;
  For I := N - 1 DownTo 1 Do
  Begin
    J := Rnd(I + 1);
    T := Pool[I]; Pool[I] := Pool[J]; Pool[J] := T;
  End;
  K := 0;
  For I := 0 To 14 Do
  Begin
    If I = 4 Then Slot[I] := 8
    Else If I = 10 Then Slot[I] := 1
    Else If I = 14 Then Slot[I] := 9
    Else
    Begin
      Slot[I] := Pool[K]; Inc(K);
    End;
  End;
  Fx := (CL + 3 * (CR - CL) Div 4) * Sh; Fy := ((CT + CB) Div 2) * Sh;
  Ss := (2 * Rb + 1) * Sh;
  I := 0;
  For R := 0 To 4 Do
    For C := 0 To R Do
    Begin
      K := Slot[I];
      BX[K] := Fx + R * Ss * 866 Div 1000;
      BY[K] := Fy + (2 * C - R) * Ss Div 2;
      VX[K] := 0; VY[K] := 0; BAct[K] := 1;
      Inc(I);
    End;
  SpotCue;
End;

Procedure Collide(I, J : LongInt);
Var Dx, Dy, D2, D, Nx, Ny, Rel, Ov, Mn : LongInt;
Begin
  Mn := 2 * Rb * Sh;
  Dx := BX[J] - BX[I]; Dy := BY[J] - BY[I];
  If (Abs(Dx) >= Mn) Or (Abs(Dy) >= Mn) Then Exit;
  D2 := Dx * Dx + Dy * Dy;
  If D2 >= Mn * Mn Then Exit;
  D := ISqrt(D2);
  If D < 1 Then
  Begin
    D := 1; Dx := 1;
  End;
  Nx := Dx * 1024 Div D; Ny := Dy * 1024 Div D;
  { separer les boules }
  Ov := (Mn - D) Div 2 + 1;
  BX[I] := BX[I] - Ov * Nx Div 1024; BY[I] := BY[I] - Ov * Ny Div 1024;
  BX[J] := BX[J] + Ov * Nx Div 1024; BY[J] := BY[J] + Ov * Ny Div 1024;
  Rel := ((VX[I] - VX[J]) * Nx + (VY[I] - VY[J]) * Ny) Div 1024;
  If Rel <= 0 Then Exit;
  Rel := Rel * 96 Div 100;
  VX[I] := VX[I] - Rel * Nx Div 1024; VY[I] := VY[I] - Rel * Ny Div 1024;
  VX[J] := VX[J] + Rel * Nx Div 1024; VY[J] := VY[J] + Rel * Ny Div 1024;
  If (FirstHit < 0) And ((I = 0) Or (J = 0)) Then
  Begin
    If I = 0 Then FirstHit := J Else FirstHit := I;
  End;
End;

{ un sous-pas ; resultat : nombre de boules en mouvement }
Function Step : LongInt;
Var K, J, S, Ns, N, Lo, Hi, Dx, Dy, P : LongInt;
Begin
  N := 0;
  For K := 0 To NB - 1 Do
    If BAct[K] <> 0 Then
    Begin
      If (VX[K] <> 0) Or (VY[K] <> 0) Then
      Begin
        BX[K] := BX[K] + VX[K]; BY[K] := BY[K] + VY[K];
        { frottement du tapis }
        S := ISqrt(VX[K] * VX[K] + VY[K] * VY[K]);
        Ns := S - S Div 100 - 3;
        If Ns <= 0 Then
        Begin
          VX[K] := 0; VY[K] := 0;
        End
        Else
        Begin
          VX[K] := VX[K] * Ns Div S; VY[K] := VY[K] * Ns Div S;
          Inc(N);
        End;
        { bandes }
        Lo := (CL + Rb) * Sh; Hi := (CR - Rb) * Sh;
        If BX[K] < Lo Then Begin BX[K] := 2 * Lo - BX[K]; VX[K] := -VX[K] * 80 Div 100; End;
        If BX[K] > Hi Then Begin BX[K] := 2 * Hi - BX[K]; VX[K] := -VX[K] * 80 Div 100; End;
        Lo := (CT + Rb) * Sh; Hi := (CB - Rb) * Sh;
        If BY[K] < Lo Then Begin BY[K] := 2 * Lo - BY[K]; VY[K] := -VY[K] * 80 Div 100; End;
        If BY[K] > Hi Then Begin BY[K] := 2 * Hi - BY[K]; VY[K] := -VY[K] * 80 Div 100; End;
        { poches }
        For P := 0 To 5 Do
        Begin
          Dx := BX[K] Div Sh - PkX[P]; Dy := BY[K] Div Sh - PkY[P];
          If Dx * Dx + Dy * Dy < PkR[P] * PkR[P] Then
          Begin
            BAct[K] := 0; VX[K] := 0; VY[K] := 0;
            If K = 0 Then Scratch := 1
            Else
            Begin
              Potted[NPot] := K; Inc(NPot);
            End;
          End;
        End;
      End;
    End;
  For K := 0 To NB - 2 Do
    If BAct[K] <> 0 Then
      For J := K + 1 To NB - 1 Do
        If BAct[J] <> 0 Then Collide(K, J);
  Step := N;
End;

{ ==================================================================== }
{ Visee                                                                 }
{ ==================================================================== }

Procedure Normalize(Var X, Y : LongInt);
Var L : LongInt;
Begin
  L := ISqrt(X * X + Y * Y);
  If L = 0 Then
  Begin
    X := 1024; Y := 0;
    Exit;
  End;
  X := X * 1024 Div L; Y := Y * 1024 Div L;
End;

{ tourne la visee (C, S : cosinus et sinus * 1024) }
Procedure Rotate(C, S : LongInt);
Var X, Y : LongInt;
Begin
  X := (AimX * C - AimY * S) Div 1024;
  Y := (AimX * S + AimY * C) Div 1024;
  AimX := X; AimY := Y;
  Normalize(AimX, AimY);
End;

{ distance (pixels) que la blanche parcourt avant de toucher une boule
  (Hit = son numero) ou une bande (Hit = -1) }
Function RayHit(Var Hit : LongInt) : LongInt;
Var K, Wx, Wy, Pr, Pp, T, Best, Cx, Cy, Mn : LongInt;
Begin
  Cx := BX[0] Div Sh; Cy := BY[0] Div Sh;
  Best := 2000; Hit := -1;
  If AimX > 0 Then Best := ((CR - Rb) - Cx) * 1024 Div AimX
  Else If AimX < 0 Then Best := ((CL + Rb) - Cx) * 1024 Div AimX;
  If AimY > 0 Then T := ((CB - Rb) - Cy) * 1024 Div AimY
  Else If AimY < 0 Then T := ((CT + Rb) - Cy) * 1024 Div AimY
  Else T := 2000;
  If T < Best Then Best := T;
  Mn := 2 * Rb;
  For K := 1 To NB - 1 Do
    If BAct[K] <> 0 Then
    Begin
      Wx := BX[K] Div Sh - Cx; Wy := BY[K] Div Sh - Cy;
      Pr := (Wx * AimX + Wy * AimY) Div 1024;
      If Pr > 0 Then
      Begin
        Pp := Wx * Wx + Wy * Wy - Pr * Pr;
        If Pp < Mn * Mn Then
        Begin
          T := Pr - ISqrt(Mn * Mn - Pp);
          If T < Best Then
          Begin
            Best := T; Hit := K;
          End;
        End;
      End;
    End;
  If Best < 0 Then Best := 0;
  RayHit := Best;
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

Function AnyMoving : Boolean;
Var K : LongInt;
Begin
  AnyMoving := False;
  For K := 0 To NB - 1 Do
    If (BAct[K] <> 0) And ((VX[K] <> 0) Or (VY[K] <> 0)) Then AnyMoving := True;
End;

Function Aiming : Boolean;
Begin
  Aiming := (Over = 0) And (Moving = 0) And (BAct[0] <> 0);
End;

Function IsCpu(P : LongInt) : Boolean;
Begin
  IsCpu := (AutoAll <> 0) Or ((Mode = 0) And (P = 2));
End;

{ queue, ligne de visee et boule fantome }
Procedure DrawCue;
Var Cx, Cy, D, K, X1, Y1, X2, Y2, Px, Py, Hit, Gx, Gy, Back : LongInt;
Begin
  Cx := BX[0] Div Sh; Cy := BY[0] Div Sh;
  If (Guide <> 0) And Not (IsCpu(Turn) And (CpuAim = 0)) Then
  Begin
    D := RayHit(Hit);
    K := Rb + 4;
    While K < D Do
    Begin
      Pix(Cx + AimX * K Div 1024, Cy + AimY * K Div 1024, P_GUIDE);
      K := K + 5;
    End;
    Gx := Cx + AimX * D Div 1024; Gy := Cy + AimY * D Div 1024;
    If Hit >= 0 Then CircleB(Gx, Gy, Rb, P_GUIDE);
  End;
  { queue : derriere la blanche, reculee selon la puissance }
  Back := Rb + 3 + Power * 2;
  Px := -AimY; Py := AimX;   { perpendiculaire }
  X1 := Cx - AimX * Back Div 1024; Y1 := Cy - AimY * Back Div 1024;
  X2 := Cx - AimX * (Back + 170) Div 1024; Y2 := Cy - AimY * (Back + 170) Div 1024;
  For K := -1 To 1 Do
    LineB(X1 + Px * K Div 1024, Y1 + Py * K Div 1024, X2 + Px * K Div 1024, Y2 + Py * K Div 1024, P_TAN);
  LineB(X1 + Px * 2 Div 1024 - AimX * 60 Div 1024, Y1 + Py * 2 Div 1024 - AimY * 60 Div 1024,
        X2 + Px * 2 Div 1024, Y2 + Py * 2 Div 1024, P_WOODD);
  LineB(X1 - Px * 2 Div 1024 - AimX * 60 Div 1024, Y1 - Py * 2 Div 1024 - AimY * 60 Div 1024,
        X2 - Px * 2 Div 1024, Y2 - Py * 2 Div 1024, P_WOODD);
  For K := -1 To 1 Do
    LineB(X1 + Px * K Div 1024, Y1 + Py * K Div 1024, X1 + Px * K Div 1024 - AimX * 4 Div 1024,
          Y1 + Py * K Div 1024 - AimY * 4 Div 1024, P_TIP);
End;

Procedure Render;
Var K : LongInt;
Begin
  Move(Bg, Fb, SizeOf(Fb));
  For K := NB - 1 DownTo 0 Do
    If BAct[K] <> 0 Then DrawBall(BX[K] Div Sh, BY[K] Div Sh, K);
  If Aiming Then DrawCue;
End;

{ ne redessine que le rectangle ou des boules ont bouge (pendant le
  roulement) ; resultat : False s'il faut tout redessiner }
Procedure BlitRect(H, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  P[0] := OX + X1; P[1] := CH - OY - 1 - Y2; P[2] := OX + X2 + 1; P[3] := CH - OY - Y1;
  P[4] := X1; P[5] := BH - 1 - Y2; P[6] := X2 + 1; P[7] := BH - Y1;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Procedure RememberBalls;
Var K : LongInt;
Begin
  For K := 0 To NB - 1 Do
    If BAct[K] <> 0 Then
    Begin
      LX[K] := BX[K] Div Sh; LY[K] := BY[K] Div Sh;
    End
    Else LX[K] := -100;
End;

Procedure ShowMoving(H : LongInt);
Var K, X, Y, X1, Y1, X2, Y2, A : LongInt;
Begin
  X1 := BW; Y1 := BH; X2 := -1; Y2 := -1;
  For K := 0 To NB - 1 Do
  Begin
    If BAct[K] <> 0 Then
    Begin
      X := BX[K] Div Sh; Y := BY[K] Div Sh;
    End
    Else
    Begin
      X := -100; Y := -100;
    End;
    If (X <> LX[K]) Or (Y <> LY[K]) Then
    Begin
      If X >= 0 Then
      Begin
        If X - Rb - 1 < X1 Then X1 := X - Rb - 1;
        If X + Rb + 3 > X2 Then X2 := X + Rb + 3;
        If Y - Rb - 1 < Y1 Then Y1 := Y - Rb - 1;
        If Y + Rb + 3 > Y2 Then Y2 := Y + Rb + 3;
      End;
      If LX[K] >= 0 Then
      Begin
        If LX[K] - Rb - 1 < X1 Then X1 := LX[K] - Rb - 1;
        If LX[K] + Rb + 3 > X2 Then X2 := LX[K] + Rb + 3;
        If LY[K] - Rb - 1 < Y1 Then Y1 := LY[K] - Rb - 1;
        If LY[K] + Rb + 3 > Y2 Then Y2 := LY[K] + Rb + 3;
      End;
    End;
  End;
  If X2 < 0 Then Exit;
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  { fond du rectangle, puis les boules qui le touchent }
  For Y := Y1 To Y2 Do
  Begin
    A := (BH - 1 - Y) * BW + X1;
    Move(Bg[A], Fb[A], X2 - X1 + 1);
  End;
  For K := NB - 1 DownTo 0 Do
    If BAct[K] <> 0 Then
    Begin
      X := BX[K] Div Sh; Y := BY[K] Div Sh;
      If (X + Rb + 3 >= X1) And (X - Rb - 1 <= X2) And (Y + Rb + 3 >= Y1) And (Y - Rb - 1 <= Y2) Then
        DrawBall(X, Y, K);
    End;
  RememberBalls;
  BlitRect(H, X1, Y1, X2, Y2);
End;

Procedure Blit(H : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  P[0] := OX; P[1] := CH - OY - BH; P[2] := OX + BW; P[3] := CH - OY;
  P[4] := 0; P[5] := 0; P[6] := BW; P[7] := BH;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Function GroupName(P : LongInt) : String;
Begin
  Case Group[P] Of
    1 : GroupName := 'pleines (1-7)';
    2 : GroupName := 'ray' + Chr(130) + 'es (9-15)';
  Else
    GroupName := Chr(133) + ' d' + Chr(130) + 'terminer';
  End;
End;

Function PlayerName(P : LongInt) : String;
Begin
  If AutoAll <> 0 Then PlayerName := 'Ordinateur ' + IStr(P)
  Else If (Mode = 0) And (P = 2) Then PlayerName := 'Ordinateur'
  Else If Mode = 0 Then PlayerName := 'Vous'
  Else PlayerName := 'Joueur ' + IStr(P);
End;

Procedure PlayerBox(X, P : LongInt);
Var K, N, Bx0 : LongInt;
Begin
  FBar(X, 336, X + 199, 393, CLR_WHITE);
  Edge(X, 336, X + 199, 393, CLR_DARKGRAY, CLR_WHITE);
  If (Turn = P) And (Over = 0) Then
  Begin
    Edge(X + 1, 337, X + 198, 392, CLR_BLUE, CLR_BLUE);
    Edge(X + 2, 338, X + 197, 391, CLR_BLUE, CLR_BLUE);
  End;
  OutTxt(X + 8, 340, PlayerName(P), CLR_BLACK, CLR_WHITE);
  OutTxt(X + 8, 356, GroupName(P), CLR_DARKBLUE, CLR_WHITE);
  { boules qui restent a empocher }
  N := 0; Bx0 := X + 12;
  If Group[P] <> 0 Then
    For K := 1 To 15 Do
      If (K <> 8) And IsOwn(P, K) And (BAct[K] <> 0) Then
      Begin
        Disc(Bx0 + N * 14, 382, 5, CLR_BLACK);
        If K < 8 Then Disc(Bx0 + N * 14, 382, 4, CLR_YELLOW) Else Disc(Bx0 + N * 14, 382, 4, CLR_WHITE);
        If K > 8 Then FBar(Bx0 + N * 14 - 3, 381, Bx0 + N * 14 + 3, 383, CLR_RED);
        Inc(N);
      End;
  If (Group[P] <> 0) And (N = 0) Then OutTxt(X + 8, 374, 'puis la 8 !', CLR_RED, CLR_WHITE);
End;

Procedure PowerBar;
Var W : LongInt;
Begin
  OutTxt(216, 340, 'Puissance', CLR_BLACK, CLR_PALEGRAY);
  Edge(216, 360, 383, 377, CLR_DARKGRAY, CLR_WHITE);
  FBar(217, 361, 382, 376, CLR_WHITE);
  W := 165 * Power Div MaxPow;
  If W > 0 Then
  Begin
    If Power > 22 Then FBar(217, 361, 216 + W, 376, CLR_RED)
    Else If Power > 12 Then FBar(217, 361, 216 + W, 376, CLR_YELLOW)
    Else FBar(217, 361, 216 + W, 376, CLR_GREEN);
  End;
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
  LMsg := Msg;
End;

Procedure DrawInfo;
Begin
  PlayerBox(8, 1);
  PlayerBox(392, 2);
  FBar(208, 336, 391, 393, CLR_PALEGRAY);
  PowerBar;
  DrawStatus;
End;

{ montre la table (et le panneau si All) sans effacer la fenetre }
Procedure Show(All : Boolean);
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If (Moving <> 0) And (FullNext = 0) And Not All Then ShowMoving(Hps)
  Else
  Begin
    Render;
    RememberBalls;
    Blit(Hps);
    FullNext := 0;
  End;
  If All Then DrawInfo
  Else
  Begin
    FBar(208, 336, 391, 393, CLR_PALEGRAY);
    PowerBar;
    If Msg <> LMsg Then DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Render;
  RememberBalls;
  Blit(Hps);
  DrawInfo;
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
  SetMark(CM_VSCPU, Mode = 0); SetMark(CM_TWO, Mode = 1);
  SetMark(CM_EASY, Level = 0); SetMark(CM_NORMAL, Level = 1);
  SetMark(CM_GUIDE, Guide <> 0);
End;

Procedure TurnMsg;
Begin
  If IsCpu(Turn) Then Msg := PlayerName(Turn) + ' vise...'
  Else If Mode = 0 Then Msg := 'A vous : visez avec la souris, maintenez le bouton pour la puissance, rel' + Chr(131) +
    'chez.'
  Else Msg := 'Au tour de ' + PlayerName(Turn) + ' (' + GroupName(Turn) + ').';
End;

Procedure NewGame;
Var K : LongInt;
Begin
  For K := 0 To NB - 1 Do BAct[K] := 0;
  Rack;
  Group[1] := 0; Group[2] := 0;
  Turn := 1; Over := 0; Moving := 0; Charging := 0; Power := 0; Break1 := 1; Winner := 0;
  AimX := 1024; AimY := 0; CpuAim := 0;
  Wait := 0;
  If IsCpu(Turn) Then Wait := 10;
  TurnMsg;
  If Not IsCpu(Turn) Then Msg := 'Casse : ' + Msg;
  Redraw;
End;

Procedure Shoot;
Begin
  If Not Aiming Then Exit;
  If Power < 1 Then Power := 1;
  VX[0] := AimX * Power * 22 Div 1024;
  VY[0] := AimY * Power * 22 Div 1024;
  NPot := 0; FirstHit := -1; Scratch := 0;
  OwnBefore := OwnLeft(Turn);
  Moving := 1; Charging := 0; CpuAim := 0; FullNext := 1;
  Msg := '';
End;

Procedure GameOver(W : LongInt; Why : String);
Begin
  Over := 1; Winner := W;
  Msg := Why + ' ' + PlayerName(W) + ' gagne la partie.  F2 : nouvelle partie.';
  Show(True);
  If AutoAll = 0 Then
    If Ask(Why + Chr(10) + PlayerName(W) + ' gagne la partie.' + Chr(10) + Chr(10) + 'Une nouvelle partie ?',
           'Billard', MB_YESNO Or MB_QUERY) = MBID_YES Then NewGame;
End;

{ fin d'un coup : fautes, attribution des groupes, joueur suivant }
Procedure EndShot;
Var K, B, Opp, Own : LongInt; Foul, Keep, Eight : Boolean; Why : String;
Begin
  Moving := 0;
  Opp := 3 - Turn;
  Foul := False; Why := '';
  Eight := False;
  For K := 0 To NPot - 1 Do If Potted[K] = 8 Then Eight := True;
  If Scratch <> 0 Then
  Begin
    Foul := True; Why := 'Faute : la blanche est empoch' + Chr(130) + 'e.';
  End
  Else If FirstHit < 0 Then
  Begin
    Foul := True; Why := 'Faute : aucune boule touch' + Chr(130) + 'e.';
  End
  Else If (Break1 = 0) And (Group[Turn] <> 0) And Not IsOwn(Turn, FirstHit) And
          Not ((FirstHit = 8) And (OwnBefore = 0)) Then
  Begin
    Foul := True; Why := 'Faute : la premi' + Chr(138) + 're boule touch' + Chr(130) + 'e n''est pas des v' +
      Chr(147) + 'tres.';
  End;
  If Eight Then
  Begin
    If (Group[Turn] <> 0) And (OwnBefore = 0) And Not Foul Then
      GameOver(Turn, 'La 8 est empoch' + Chr(130) + 'e !')
    Else
      GameOver(Opp, 'La 8 est empoch' + Chr(130) + 'e trop t' + Chr(147) + 't ou avec une faute.');
    Exit;
  End;
  { table ouverte : la premiere boule empochee donne le groupe }
  If (Group[Turn] = 0) And (Break1 = 0) And Not Foul Then
    For K := NPot - 1 DownTo 0 Do
    Begin
      B := Potted[K];
      If B < 8 Then Begin Group[Turn] := 1; Group[Opp] := 2; End
      Else If B > 8 Then Begin Group[Turn] := 2; Group[Opp] := 1; End;
    End;
  Own := 0;
  For K := 0 To NPot - 1 Do If IsOwn(Turn, Potted[K]) Then Inc(Own);
  If Break1 <> 0 Then Own := NPot;
  Break1 := 0;
  Keep := (Not Foul) And (Own > 0);
  If Scratch <> 0 Then SpotCue;
  If NPot > 0 Then
  Begin
    If NPot = 1 Then Msg := 'Boule ' + IStr(Potted[0]) + ' empoch' + Chr(130) + 'e. '
    Else Msg := IStr(NPot) + ' boules empoch' + Chr(130) + 'es. ';
  End
  Else Msg := '';
  If Foul Then Msg := Why + ' '
  Else If Group[Turn] <> 0 Then
    If (NPot > 0) And (Own = 0) Then Msg := Msg + '(pas des v' + Chr(147) + 'tres) ';
  If Not Keep Then Turn := Opp;
  If Keep Then Msg := Msg + PlayerName(Turn) + ' rejoue.'
  Else Msg := Msg + 'Au tour de ' + PlayerName(Turn) + '.';
  Power := 0;
  If IsCpu(Turn) Then Wait := 12 Else Wait := 0;
  Show(True);
End;

{ ==================================================================== }
{ Ordinateur                                                            }
{ ==================================================================== }

{ un segment (A -> B, pixels) est-il libre de boules (sauf E1, E2) ? }
Function PathFree(Ax, Ay, Bx0, By0, E1, E2 : LongInt) : Boolean;
Var K, Dx, Dy, L, Wx, Wy, Pr, Pp, Mn : LongInt;
Begin
  PathFree := True;
  Dx := Bx0 - Ax; Dy := By0 - Ay;
  L := ISqrt(Dx * Dx + Dy * Dy);
  If L = 0 Then Exit;
  Mn := 2 * Rb + 1;
  For K := 0 To NB - 1 Do
    If (BAct[K] <> 0) And (K <> E1) And (K <> E2) Then
    Begin
      Wx := BX[K] Div Sh - Ax; Wy := BY[K] Div Sh - Ay;
      Pr := (Wx * Dx + Wy * Dy) Div L;
      If (Pr > 0) And (Pr < L) Then
      Begin
        Pp := Wx * Wx + Wy * Wy - Pr * Pr;
        If Pp < Mn * Mn Then PathFree := False;
      End;
    End;
End;

{ choisit la visee et la puissance de l'ordinateur }
Procedure CpuPlan;
Var K, P, Tx, Ty, Ux, Uy, Gx, Gy, Cx, Cy, Dx, Dy, Lc, Lt, Cs, Sc, Best, BAx, BAy, BPw, E, Tgt : LongInt;
Begin
  Cx := BX[0] Div Sh; Cy := BY[0] Div Sh;
  Best := -1000000; BAx := 1024; BAy := 0; BPw := 12;
  If Break1 <> 0 Then
  Begin
    { casse : plein dans la boule de tete, fort }
    Dx := BX[1] Div Sh; Dy := 0;
    For K := 1 To 15 Do If (BAct[K] <> 0) And (BX[K] Div Sh < Dx + 100) Then
      If BX[K] < BX[1] Then Dx := BX[K] Div Sh;
    BAx := (CL + 3 * (CR - CL) Div 4) - Cx; BAy := ((CT + CB) Div 2) - Cy;
    Normalize(BAx, BAy);
    BPw := MaxPow;
  End
  Else
  Begin
    For K := 1 To 15 Do
      If BAct[K] <> 0 Then
      Begin
        If K = 8 Then Tgt := Ord(OwnLeft(Turn) = 0) Else If Group[Turn] = 0 Then Tgt := 1
        Else Tgt := Ord(IsOwn(Turn, K));
        If Tgt <> 0 Then
          For P := 0 To 5 Do
          Begin
            Tx := BX[K] Div Sh; Ty := BY[K] Div Sh;
            Ux := PkX[P] - Tx; Uy := PkY[P] - Ty;
            Lt := ISqrt(Ux * Ux + Uy * Uy);
            Normalize(Ux, Uy);
            Gx := Tx - Ux * 2 * Rb Div 1024; Gy := Ty - Uy * 2 * Rb Div 1024;
            Dx := Gx - Cx; Dy := Gy - Cy;
            Lc := ISqrt(Dx * Dx + Dy * Dy);
            If Lc > 4 Then
            Begin
              Cs := (Dx * Ux + Dy * Uy) Div Lc;      { cosinus de la coupe * 1024 }
              If (Cs > 300) And PathFree(Cx, Cy, Gx, Gy, 0, K) And PathFree(Tx, Ty, PkX[P], PkY[P], K, 0) Then
              Begin
                Sc := Cs - (Lc + Lt) Div 2;
                If Sc > Best Then
                Begin
                  Best := Sc; BAx := Dx; BAy := Dy;
                  BPw := 6 + (Lc + Lt * 2) * 1024 Div Cs Div 40;
                End;
              End;
            End;
          End;
      End;
    If Best = -1000000 Then
    Begin
      { aucun coup franc : toucher une de ses boules (coup de securite) }
      For K := 1 To 15 Do
        If (BAct[K] <> 0) And (IsOwn(Turn, K) Or ((K = 8) And (OwnLeft(Turn) = 0))) Then
        Begin
          Dx := BX[K] Div Sh - Cx; Dy := BY[K] Div Sh - Cy;
          Lc := ISqrt(Dx * Dx + Dy * Dy);
          If -Lc > Best Then
          Begin
            Best := -Lc; BAx := Dx; BAy := Dy; BPw := 10 + Lc Div 40;
          End;
        End;
    End;
    Normalize(BAx, BAy);
  End;
  { imprecision selon le niveau }
  If Level = 0 Then E := 40 Else E := 10;
  E := Rnd(2 * E + 1) - E;
  AimX := BAx - BAy * E Div 1024; AimY := BAy + BAx * E Div 1024;
  Normalize(AimX, AimY);
  If BPw > MaxPow Then BPw := MaxPow;
  If BPw < 6 Then BPw := 6;
  Power := BPw;
End;

Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';

Procedure TimerTick;
Var K : LongInt;
Begin
  If Over <> 0 Then
  Begin
    If AutoAll <> 0 Then
    Begin
      Inc(Wait);
      If Wait > 60 Then NewGame;
    End;
    Exit;
  End;
  If Moving <> 0 Then
  Begin
    For K := 1 To 4 Do Dummy := Step;
    If Not AnyMoving Then EndShot Else Show(False);
    Exit;
  End;
  If Charging <> 0 Then
  Begin
    Power := Power + PowDir;
    If Power >= MaxPow Then Begin Power := MaxPow; PowDir := -1; End;
    If Power <= 1 Then Begin Power := 1; PowDir := 1; End;
    Show(False);
    Exit;
  End;
  If IsCpu(Turn) Then
  Begin
    If Wait > 0 Then Dec(Wait);
    If Wait = 8 Then
    Begin
      CpuPlan;
      CpuAim := 1;
      Msg := PlayerName(Turn) + ' vise...';
      Show(False);
    End
    Else If Wait = 0 Then Shoot;
  End;
End;

Procedure SetMode(M : LongInt);
Begin
  Mode := M;
  SetMarks;
  NewGame;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_VSCPU : SetMode(0);
    CM_TWO : SetMode(1);
    CM_EASY : Begin Level := 0; SetMarks; End;
    CM_NORMAL : Begin Level := 1; SetMarks; End;
    CM_GUIDE : Begin Guide := 1 - Guide; SetMarks; Show(False); End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Dummy := Ask('Jeu de la boule 8. Apr' + Chr(138) + 's la casse, le premier qui empoche une boule ' +
                            'prend les pleines (1 ' + Chr(133) + ' 7) ou les ray' + Chr(130) + 'es (9 ' + Chr(133) +
                            ' 15). On rejoue tant qu''on empoche une de ses boules sans faute. Empochez toutes ' +
                            'vos boules, puis la 8 ; empocher la 8 trop t' + Chr(147) + 't ou avec une faute fait ' +
                            'perdre. Fautes : blanche empoch' + Chr(130) + 'e (elle revient sur son point), ' +
                            'aucune boule touch' + Chr(130) + 'e, premi' + Chr(138) + 're boule touch' + Chr(130) +
                            'e qui n''est pas des v' + Chr(147) + 'tres : le tour passe.' + Chr(10) + Chr(10) +
                            'Souris : la queue suit le pointeur ; maintenez le bouton pour doser la puissance, ' +
                            'rel' + Chr(131) + 'chez pour tirer. Clavier : fl' + Chr(138) + 'ches (viser), ' +
                            'Espace (puissance), Entr' + Chr(130) + 'e (tirer), F2 (nouvelle partie).',
                            'Billard - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    CM_ABOUT : Dummy := Ask('Billard pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'BILLARD.PAS de 7iles : billard am' + Chr(130) + 'ricain ' + Chr(133) + ' 8 boules, ' +
                            'contre l''ordinateur ou ' + Chr(133) + ' deux.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos du Billard',
                            MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Function Human : Boolean;
Begin
  Human := Aiming And Not IsCpu(Turn);
End;

Procedure AimAt(Mx, My : LongInt);
Var X, Y, Dx, Dy : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  Dx := X - OX - BX[0] Div Sh; Dy := Y - OY - BY[0] Div Sh;
  If Abs(Dx) + Abs(Dy) < 3 Then Exit;
  AimX := Dx; AimY := Dy;
  Normalize(AimX, AimY);
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
    If Human Then
    Begin
      If Vk = VK_LEFT Then Begin Rotate(1024, -18); Show(False); Exit; End;
      If Vk = VK_RIGHT Then Begin Rotate(1024, 18); Show(False); Exit; End;
      If Vk = VK_UP Then Begin Rotate(1020, -89); Show(False); Exit; End;
      If Vk = VK_DOWN Then Begin Rotate(1020, 89); Show(False); Exit; End;
      If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Shoot; Exit; End;
      If Vk = VK_SPACE Then
      Begin
        Inc(Power);
        If Power > MaxPow Then Power := 1;
        Show(False);
        Exit;
      End;
    End;
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
    WM_TIMER :
      If Lo16(Mp1) = 1 Then
        If (WinQueryFocus(HWND_DESKTOP) = Client) Or (AutoAll <> 0) Then TimerTick;
    WM_MOUSEMOVE :
      Begin
        If Human Then
        Begin
          AimAt(S16(Mp1), S16(Mp1 Shr 16));
          If Charging = 0 Then Show(False);
        End;
        MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        If Human Then
        Begin
          AimAt(S16(Mp1), S16(Mp1 Shr 16));
          Charging := 1; Power := 0; PowDir := 1;
          Dummy := WinSetCapture(HWND_DESKTOP, H);
          Show(False);
        End;
        MainProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        If Charging <> 0 Then
        Begin
          Dummy := WinSetCapture(HWND_DESKTOP, 0);
          Shoot;
        End;
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
  Fl, H0, H1, H2, ScrW, ScrH, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LMsg := ''; AutoAll := 0; Mode := 0; Level := 1; Guide := 1; Over := 1; Moving := 0;
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
  Dummy := WinRegisterClass(Hab, Z('BILLARD'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  InitBmi;
  InitPockets;
  BuildBg;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('BILLARD'), Z2('Billard'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, MIA_CHECKED, CM_VSCPU, '~Contre l''ordinateur');
  MItem(MIS_TEXT, 0, CM_TWO, '~Deux joueurs');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_EASY, '~Facile');
  MItem(MIS_TEXT, MIA_CHECKED, CM_NORMAL, 'N~ormal');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, MIA_CHECKED, CM_GUIDE, '~Ligne de vis' + Chr(130) + 'e');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 11);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos du Billard');
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
  Dummy := WinStartTimer(Hab, Client, 1, 30);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
