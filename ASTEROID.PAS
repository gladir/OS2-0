{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: ASTEROID - Asteroide (jeu d'adresse) pour le Presentation
                Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program ASTEROID;

{$R-,S-,I-}

{ Compilation : OS2PC ASTEROID.PAS   (produit ASTEROID.EXE)

  Portage vers OS/2-0 du prototype ASTEROID.PAS du depot 7iles (Turbo
  Pascal et BGI : vaisseau en triangle, asteroides en cercles, tirs en
  points, fleches et Espace) : fenetre de Presentation Manager avec menus,
  image en memoire (GpiDrawBits, seules les parties qui bougent sont
  recopiees), espace etoile avec une planete, asteroides en roches
  crateres, vaisseau en relief, tirs lumineux, explosions, panneau du
  pointage, pause, barre d'etat et apparence d'OS/2.

  Regles du prototype : le vaisseau reste au centre et tourne ; les
  asteroides arrivent des bords en ligne droite ; un tir detruit un
  asteroide (10 points) ; un asteroide qui touche le vaisseau coute une
  vie et vide le ciel ; trois vies.
  Ce qui est ajoute : des vagues (tous les 15 asteroides detruits, ils
  sont plus nombreux et plus rapides), le record de la seance, la souris.

  Clavier : fleches gauche et droite (tourner), Espace (tirer ; maintenue :
  tir continu), P (pause), F2 (nouvelle partie), F1 (regles).
  Souris : le vaisseau vise le pointeur, clic : tirer.
  Parametres : /SEED:n ; /AUTO (le vaisseau joue seul : demonstration). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_SPACE = $10; VK_LEFT = $15; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  VK_UP = $16; VK_PAUSE = $0D;
  CM_NEW = 101; CM_PAUSE = 102; CM_QUIT = 104;
  CM_RULES = 301; CM_ABOUT = 302;
  BW = 456; BH = 400; OX = 8; OY = 8;
  PnX = 472; PW = 146;
  CWant = 624; CHWant = 436;
  MaxDirty = 160; MaxSpr = 130;
  SCX = 228; SCY = 200;                   { le vaisseau (prototype : au centre) }
  MaxRock = 20; MaxShot = 20; MaxPart = 64;
  { couleurs de l'image }
  C_SPACE = 0; C_WHITE = 1; C_STAR1 = 2; C_STAR2 = 3; C_STAR3 = 4; C_PLANET = 5; C_PLSHADE = 6; C_PLLIGHT = 7;
  C_RING = 8; C_NEB1 = 9; C_ROCKD = 10; C_ROCKM = 11; C_ROCKL = 12; C_CRATER = 13; C_HULL = 14; C_HULLD = 15;
  C_ACCENT = 16; C_COCKPIT = 17; C_FLAME1 = 18; C_FLAME2 = 19; C_SHOT = 20; C_GLOW = 21; C_EXP1 = 22;
  C_EXP2 = 23; C_EXP3 = 24; C_EXP4 = 25; C_BANNER = 26; C_YELLOW = 27; C_RED = 28; C_GREEN = 29; C_NEB2 = 30;
  C_SHIELD = 31;
  NPal = 32;
  Pal : Array[0..NPal - 1] Of LongInt = (
    $050814, $FFFFFF, $5A6478, $A0AAC0, $F0F4FF, $3C5AA0, $1E2D64, $78A0DC,
    $B4A078, $1C1430, $46403A, $6E6258, $9A8A7C, $37302C, $C8CDD7, $787D8C,
    $D23228, $50C8FF, $FFDC50, $FF821E, $FFFFC8, $FF783C, $FFFADC, $FFE650,
    $FF9628, $C83214, $14143C, $FFE650, $FF5050, $50DC78, $140C24, $50A0FF);
  S_TITLE = 0; S_PLAY = 1; S_HIT = 2; S_PAUSE = 3; S_OVER = 4;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  DX1, DY1, DX2, DY2 : Array[0..MaxDirty - 1] Of LongInt;
  SX1, SY1, SX2, SY2 : Array[0..MaxSpr - 1] Of LongInt;
  NDirty, NSpr : LongInt;
  { asteroides : position et vitesse en 1/16 de pixel }
  RX, RY, RVX, RVY, RR, RAlive : Array[0..MaxRock - 1] Of LongInt;
  RowL, RowR : Array[0..MaxRock - 1, 0..48] Of LongInt;
  CrX, CrY, CrR : Array[0..MaxRock - 1, 0..2] Of LongInt;
  { tirs }
  TX, TY, TVX, TVY, TLife : Array[0..MaxShot - 1] Of LongInt;
  { eclats }
  PX, PY, PVX, PVY, PLife, PCol : Array[0..MaxPart - 1] Of LongInt;
  ShipA, RotDir, RotTime, FireHeld, FireCool, Invul, Lives, Score, Best, Wave, Killed, SpawnWait : LongInt;
  State, Wait, Seed, AutoAll, Tick, MouseAim, AimA : LongInt;
  Banner, Banner2, Msg : String;
  BannerC : LongInt;
  CosT, SinT : Array[0..359] Of LongInt;   { x 1024 }
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


Function GpiDrawBits(Hps, PBits, Pbmi, N, P, Rop, Fl : LongInt) : LongInt; External 'PMGPI';

Procedure WrL(A, V : LongInt);
Begin
  WrW(A, V And $FFFF);
  WrW(A + 2, (V Shr 16) And $FFFF);
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
{ Image en memoire (8 bits, palette en vraies couleurs) : fond fixe     }
{ (Back), image affichee (Fb), rectangles a recopier (GpiDrawBits)      }
{ ==================================================================== }

Procedure SetPal(I, C : LongInt);
Var A : LongInt;
Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, C And 255); WrB(A + 1, (C Shr 8) And 255); WrB(A + 2, (C Shr 16) And 255);
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
  For I := 0 To NPal - 1 Do SetPal(I, Pal[I]);
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

{ ellipse pleine de centre (Cx, Cy) }
Procedure Ell(Cx, Cy, Rx, Ry, C : LongInt);
Var Dy, W : LongInt;
Begin
  For Dy := -Ry To Ry Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) * Ry * Ry + Dy * Dy * Rx * Rx <= Rx * Rx * Ry * Ry + Rx * Ry Do Inc(W);
    Rect(Cx - W, Cy + Dy, Cx + W, Cy + Dy, C);
  End;
End;

Procedure FDisc(Cx, Cy, R, C : LongInt);
Begin
  If R <= 0 Then Pix(Cx, Cy, C) Else Ell(Cx, Cy, R, R, C);
End;

Procedure DLine(X1, Y1, X2, Y2, C : LongInt);
Var N, K, Dx, Dy : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  N := Abs(Dx);
  If Abs(Dy) > N Then N := Abs(Dy);
  If N = 0 Then
  Begin
    Pix(X1, Y1, C);
    Exit;
  End;
  For K := 0 To N Do Pix(X1 + (Dx * K) Div N, Y1 + (Dy * K) Div N, C);
End;

{ trait epais (carre de cote 2T + 1 le long du trait) }
Procedure TLine(X1, Y1, X2, Y2, T, C : LongInt);
Var N, K, Dx, Dy, X, Y : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  N := Abs(Dx);
  If Abs(Dy) > N Then N := Abs(Dy);
  If N = 0 Then N := 1;
  For K := 0 To N Do
  Begin
    X := X1 + (Dx * K) Div N; Y := Y1 + (Dy * K) Div N;
    Rect(X - T, Y - T, X + T, Y + T, C);
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

{ texte avec une ombre d'un pixel }
Procedure FbTextSh(X, Y : LongInt; S : String; C, Sh, Sc : LongInt);
Begin
  FbText(X + 1, Y + 1, S, Sh, Sc);
  FbText(X, Y, S, C, Sc);
End;

{ --- fond fixe --- }
Procedure SaveBack;
Begin
  Move(Fb, Back, SizeOf(Fb));
End;

Procedure RestoreRect(X1, Y1, X2, Y2 : LongInt);
Var Y, B : LongInt;
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW + X1;
    Move(Back[B], Fb[B], X2 - X1 + 1);
  End;
End;

{ --- rectangles a recopier --- }
Procedure AddDirty(X1, Y1, X2, Y2 : LongInt);
Begin
  If X1 < 0 Then X1 := 0;
  If Y1 < 0 Then Y1 := 0;
  If X2 > BW - 1 Then X2 := BW - 1;
  If Y2 > BH - 1 Then Y2 := BH - 1;
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  If NDirty >= MaxDirty Then
  Begin
    NDirty := 1;
    DX1[0] := 0; DY1[0] := 0; DX2[0] := BW - 1; DY2[0] := BH - 1;
    Exit;
  End;
  DX1[NDirty] := X1; DY1[NDirty] := Y1; DX2[NDirty] := X2; DY2[NDirty] := Y2;
  Inc(NDirty);
End;

Procedure BlitRect(H, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  P[0] := OX + X1; P[1] := CH - OY - 1 - Y2; P[2] := OX + X2 + 1; P[3] := CH - OY - Y1;
  P[4] := X1; P[5] := BH - 1 - Y2; P[6] := X2 + 1; P[7] := BH - Y1;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

{ --- objets mobiles : effaces (fond fixe) puis redessines --- }
Procedure SprBegin;
Var K : LongInt;
Begin
  For K := 0 To NSpr - 1 Do
  Begin
    RestoreRect(SX1[K], SY1[K], SX2[K], SY2[K]);
    AddDirty(SX1[K], SY1[K], SX2[K], SY2[K]);
  End;
  NSpr := 0;
End;

Procedure SprRect(X1, Y1, X2, Y2 : LongInt);
Begin
  If NSpr >= MaxSpr Then Exit;
  SX1[NSpr] := X1; SY1[NSpr] := Y1; SX2[NSpr] := X2; SY2[NSpr] := Y2;
  Inc(NSpr);
  AddDirty(X1, Y1, X2, Y2);
End;


Function MinX(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinX := A Else MinX := B;
End;

Function MaxX(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxX := A Else MaxX := B;
End;

Procedure InitTrig;
Var A : LongInt;
Begin
  For A := 0 To 359 Do
  Begin
    CosT[A] := Round(Cos(A * Pi / 180) * 1024);
    SinT[A] := Round(Sin(A * Pi / 180) * 1024);
  End;
End;

Function Norm(A : LongInt) : LongInt;
Begin
  A := A Mod 360;
  If A < 0 Then A := A + 360;
  Norm := A;
End;

{ angle (0 vers le haut, sens horaire) du point (Dx, Dy) vu du vaisseau }
Function AngleTo(Dx, Dy : LongInt) : LongInt;
Var A : Real;
Begin
  If (Dx = 0) And (Dy = 0) Then
  Begin
    AngleTo := ShipA;
    Exit;
  End;
  A := ArcTan(Abs(Dx) / (Abs(Dy) + 0.0001)) * 180 / Pi;
  If Dy > 0 Then A := 180 - A;
  If Dx < 0 Then A := 360 - A;
  AngleTo := Norm(Round(A));
End;

{ ==================================================================== }
{ Ciel (dessine une fois)                                               }
{ ==================================================================== }

Procedure RenderSky;
Var X, Y, K, Dx, Dy, D2, L, C, S : LongInt;
Begin
  { fond et nebuleuse }
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      C := C_SPACE;
      Dx := X - 340; Dy := Y - 90;
      D2 := Dx * Dx Div 2 + Dy * Dy * 2;
      If D2 < 9000 Then
      Begin
        If ((X + Y) Mod 2 = 0) Or (D2 < 4000) Then C := C_NEB1;
        If (D2 < 2500) And ((X * 3 + Y) Mod 4 = 0) Then C := C_NEB2;
      End;
      Fb[(BH - 1 - Y) * BW + X] := C;
    End;
  { etoiles }
  S := 12345;
  For K := 1 To 320 Do
  Begin
    S := (S * 1103515245 + 12345) And $7FFFFFFF;
    X := (S Shr 8) Mod BW;
    S := (S * 1103515245 + 12345) And $7FFFFFFF;
    Y := (S Shr 8) Mod BH;
    S := (S * 1103515245 + 12345) And $7FFFFFFF;
    L := (S Shr 8) Mod 10;
    If L < 6 Then Pix(X, Y, C_STAR1)
    Else If L < 9 Then Pix(X, Y, C_STAR2)
    Else
    Begin
      Pix(X, Y, C_STAR3);
      Pix(X - 1, Y, C_STAR1); Pix(X + 1, Y, C_STAR1); Pix(X, Y - 1, C_STAR1); Pix(X, Y + 1, C_STAR1);
    End;
  End;
  { planete avec anneau (eclairee d'en haut a droite) }
  For Y := -50 To 50 Do
    For X := -50 To 50 Do
    Begin
      D2 := X * X + Y * Y;
      If D2 <= 46 * 46 Then
      Begin
        L := X - Y;
        If L > 30 Then C := C_PLLIGHT Else If L < -26 Then C := C_PLSHADE Else C := C_PLANET;
        If ((Y + 50) Div 9) Mod 2 = 0 Then
          If C = C_PLANET Then C := C_PLLIGHT Else If C = C_PLSHADE Then C := C_PLANET;
        Pix(66 + X, 336 + Y, C);
      End;
    End;
  For X := -78 To 78 Do
  Begin
    Y := Round(Sqrt(Abs(1 - (X * X) / (78.0 * 78))) * 12);
    If (X * X + Y * Y > 46 * 46) Or (X < -30) Then Pix(66 + X, 336 + Y - X Div 6, C_RING);
    If X * X + Y * Y > 46 * 46 Then Pix(66 + X, 336 - Y - X Div 6, C_RING);
  End;
  SaveBack;
End;

{ ==================================================================== }
{ Dessin des objets                                                     }
{ ==================================================================== }

{ triangle plein }
Procedure FillTri(X1, Y1, X2, Y2, X3, Y3, C : LongInt);
Var T, Y, Xa, Xb : LongInt;
Begin
  If Y2 < Y1 Then Begin T := X1; X1 := X2; X2 := T; T := Y1; Y1 := Y2; Y2 := T; End;
  If Y3 < Y1 Then Begin T := X1; X1 := X3; X3 := T; T := Y1; Y1 := Y3; Y3 := T; End;
  If Y3 < Y2 Then Begin T := X2; X2 := X3; X3 := T; T := Y2; Y2 := Y3; Y3 := T; End;
  If Y3 = Y1 Then Exit;
  For Y := Y1 To Y3 Do
  Begin
    Xa := X1 + (X3 - X1) * (Y - Y1) Div (Y3 - Y1);
    If Y < Y2 Then Xb := X1 + (X2 - X1) * (Y - Y1) Div (Y2 - Y1)
    Else If Y3 = Y2 Then Xb := X2
    Else Xb := X2 + (X3 - X2) * (Y - Y2) Div (Y3 - Y2);
    If Xa > Xb Then Begin T := Xa; Xa := Xb; Xb := T; End;
    Rect(Xa, Y, Xb, Y, C);
  End;
End;

{ point du vaisseau (repere du vaisseau : X a droite, Y vers l'avant) }
Procedure ShipPt(Lx, Ly : LongInt; Var X, Y : LongInt);
Begin
  X := SCX + (Lx * CosT[ShipA] + Ly * SinT[ShipA]) Div 1024;
  Y := SCY + (Lx * SinT[ShipA] - Ly * CosT[ShipA]) Div 1024;
End;

Procedure DrawShip;
Var Nx, Ny, Lx, Ly, Rx, Ry, Bx, By, Fx, Fy, Ax, Ay, Cx, Cy, K : LongInt;
Begin
  If (State = S_HIT) Or (State = S_OVER) Then Exit;
  ShipPt(0, 22, Nx, Ny); ShipPt(-14, -12, Lx, Ly); ShipPt(14, -12, Rx, Ry); ShipPt(0, -5, Bx, By);
  { flamme du reacteur }
  ShipPt(-5, -7, Ax, Ay); ShipPt(5, -7, Cx, Cy);
  ShipPt(0, -14 - (Tick Mod 3) * 3, Fx, Fy);
  FillTri(Ax, Ay, Cx, Cy, Fx, Fy, C_FLAME2);
  ShipPt(0, -10 - (Tick Mod 2) * 2, Fx, Fy);
  FillTri(Ax, Ay, Cx, Cy, Fx, Fy, C_FLAME1);
  { coque : moitie gauche claire, moitie droite ombree }
  FillTri(Nx, Ny, Lx, Ly, Bx, By, C_HULL);
  FillTri(Nx, Ny, Rx, Ry, Bx, By, C_HULLD);
  DLine(Nx, Ny, Bx, By, C_ACCENT);
  ShipPt(-12, -10, Ax, Ay); ShipPt(-6, -3, Cx, Cy); DLine(Ax, Ay, Cx, Cy, C_ACCENT);
  ShipPt(12, -10, Ax, Ay); ShipPt(6, -3, Cx, Cy); DLine(Ax, Ay, Cx, Cy, C_ACCENT);
  ShipPt(0, 9, Cx, Cy);
  FDisc(Cx, Cy, 2, C_COCKPIT);
  { bouclier (invulnerable apres un choc) }
  If (Invul > 0) And (Tick Mod 4 < 2) Then
    For K := 0 To 23 Do Pix(SCX + 26 * CosT[K * 15] Div 1024, SCY + 26 * SinT[K * 15] Div 1024, C_SHIELD);
  SprRect(SCX - 28, SCY - 28, SCX + 28, SCY + 28);
End;

Procedure DrawRock(K : LongInt);
Var X, Y, R, Dy, L, Wr, Dx, C, J : LongInt;
Begin
  X := RX[K] Div 16; Y := RY[K] Div 16; R := RR[K];
  For Dy := -R To R Do
  Begin
    L := RowL[K, Dy + R]; Wr := RowR[K, Dy + R];
    For Dx := -L To Wr Do
    Begin
      { eclairage d'en haut a gauche }
      J := Dx + Dy;
      If J < -R Div 2 Then C := C_ROCKL Else If J > R Div 2 Then C := C_ROCKD Else C := C_ROCKM;
      Pix(X + Dx, Y + Dy, C);
    End;
  End;
  For J := 0 To 2 Do
    If CrR[K, J] > 0 Then
    Begin
      FDisc(X + CrX[K, J], Y + CrY[K, J], CrR[K, J], C_CRATER);
      Pix(X + CrX[K, J] + CrR[K, J], Y + CrY[K, J] + CrR[K, J] Div 2, C_ROCKL);
    End;
  SprRect(X - R - 2, Y - R - 1, X + R + 2, Y + R + 1);
End;

Procedure DrawShot(K : LongInt);
Var X, Y, Bx, By : LongInt;
Begin
  X := TX[K] Div 16; Y := TY[K] Div 16;
  Bx := (TX[K] - TVX[K] * 2) Div 16; By := (TY[K] - TVY[K] * 2) Div 16;
  DLine(Bx, By, X, Y, C_GLOW);
  Rect(X - 1, Y - 1, X + 1, Y + 1, C_SHOT);
  SprRect(MinX(X, Bx) - 2, MinX(Y, By) - 2, MaxX(X, Bx) + 2, MaxX(Y, By) + 2);
End;

Procedure BannerDraw;
Var W, X, Y : LongInt;
Begin
  If Banner = '' Then Exit;
  W := Length(Banner) * 16;
  If Length(Banner2) * 8 > W Then W := Length(Banner2) * 8;
  W := W + 28;
  X := (BW - W) Div 2; Y := 120;
  Rect(X, Y, X + W - 1, Y + 58, C_BANNER);
  Rect(X, Y, X + W - 1, Y, C_SHIELD); Rect(X, Y + 58, X + W - 1, Y + 58, C_SHIELD);
  Rect(X, Y, X, Y + 58, C_SHIELD); Rect(X + W - 1, Y, X + W - 1, Y + 58, C_SHIELD);
  FbTextSh(X + (W - Length(Banner) * 16) Div 2, Y + 6, Banner, BannerC, C_SPACE, 2);
  FbText(X + (W - Length(Banner2) * 8) Div 2, Y + 38, Banner2, C_WHITE, 1);
  SprRect(X, Y, X + W - 1, Y + 58);
End;

Procedure DrawSprites;
Var K : LongInt;
Begin
  SprBegin;
  For K := 0 To MaxRock - 1 Do If RAlive[K] <> 0 Then DrawRock(K);
  For K := 0 To MaxPart - 1 Do
    If PLife[K] > 0 Then
    Begin
      Rect(PX[K] Div 16, PY[K] Div 16, PX[K] Div 16 + 1, PY[K] Div 16 + 1, PCol[K]);
      SprRect(PX[K] Div 16, PY[K] Div 16, PX[K] Div 16 + 1, PY[K] Div 16 + 1);
    End;
  For K := 0 To MaxShot - 1 Do If TLife[K] > 0 Then DrawShot(K);
  DrawShip;
  BannerDraw;
End;

Procedure BlitAll(H : LongInt);
Var K : LongInt;
Begin
  For K := 0 To NDirty - 1 Do BlitRect(H, DX1[K], DY1[K], DX2[K], DY2[K]);
  NDirty := 0;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ petit vaisseau (vies) }
Procedure LifeIcon(X, Y : LongInt);
Var K : LongInt;
Begin
  For K := 0 To 9 Do FBar(X + 6 - K Div 2, Y + K, X + 6 + K Div 2, Y + K, CLR_DARKBLUE);
  FBar(X + 5, Y + 3, X + 7, Y + 5, CLR_CYAN);
End;

Procedure DrawCounters;
Var S : String; K : LongInt;
Begin
  FBar(PnX + 2, 72, PnX + PW - 3, 106, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 73, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 114, PnX + PW - 1, 196, CLR_PALEGRAY);
  OutTxt(PnX, 114, 'Vague : ' + IStr(Wave), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 134, 'Vies :', CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To Lives - 1 Do LifeIcon(PnX + 52 + K * 16, 137);
  OutTxt(PnX, 154, 'D' + Chr(130) + 'truits : ' + IStr(Killed), CLR_BLACK, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 174, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 9 * 16) Div 2, 8, 'AST' + Chr(144) + 'RO' + Chr(139) + 'DE', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 48, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 68, PnX + PW - 1, 110, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 69, PnX + PW - 2, 109, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 70, PnX + PW - 3, 108, CLR_WHITE);
  DrawCounters;
  Button(PnX, 206, PW, 28, 'Nouvelle partie');
  Button(PnX, 240, PW, 28, 'Pause');
  OutTxt(PnX, 284, Chr(27) + ' ' + Chr(26) + ' : tourner', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 300, 'Espace : tirer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 316, 'Souris : viser', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 332, 'Clic : tirer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 348, 'P : pause', CLR_DARKGRAY, CLR_PALEGRAY);
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
  DrawSprites;
  NDirty := 0;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

Procedure Frame1(Counters : Boolean);
Begin
  If Client = 0 Then Exit;
  DrawSprites;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  BlitAll(Hps);
  If Counters Then
  Begin
    DrawCounters;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure Show(B1, B2 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; BannerC := C;
End;

Procedure ClearSky;
Var K : LongInt;
Begin
  For K := 0 To MaxRock - 1 Do RAlive[K] := 0;
  For K := 0 To MaxShot - 1 Do TLife[K] := 0;
End;

Procedure NewGame;
Var K : LongInt;
Begin
  ClearSky;
  For K := 0 To MaxPart - 1 Do PLife[K] := 0;
  Score := 0; Lives := 3; Wave := 1; Killed := 0; SpawnWait := 20; ShipA := 0; Invul := 0;
  RotDir := 0; RotTime := 0; FireHeld := 0; FireCool := 0;
  State := S_PLAY; Banner := '';
  Show('Vague 1', 'D' + Chr(130) + 'truisez les ast' + Chr(130) + 'ro' + Chr(139) + 'des !', C_YELLOW);
  Wait := 40;
  Msg := 'Fl' + Chr(138) + 'ches : tourner, Espace : tirer (ou la souris).';
  Redraw;
End;

Procedure NewRock;
Var K, E, X, Y, Tx, Ty, Sp, D, R, J, Dy, W : LongInt; Dd : Real;
Begin
  K := 0;
  While (K < MaxRock) And (RAlive[K] <> 0) Do Inc(K);
  If K >= MaxRock Then Exit;
  { taille du prototype : 10, 15 ou 20 }
  R := 10 + Rnd(3) * 5 + Rnd(3);
  E := Rnd(4);
  Case E Of
    0 : Begin X := Rnd(BW); Y := -R; End;
    1 : Begin X := Rnd(BW); Y := BH + R; End;
    2 : Begin X := -R; Y := Rnd(BH); End;
  Else
    Begin X := BW + R; Y := Rnd(BH); End;
  End;
  { vers le centre, a peu pres }
  Tx := SCX - 140 + Rnd(281); Ty := SCY - 110 + Rnd(221);
  Sp := 10 + Wave * 2 + Rnd(8);
  Dd := Sqrt(Sqr(Tx - X * 1.0) + Sqr(Ty - Y * 1.0));
  If Dd < 1 Then Dd := 1;
  RX[K] := X * 16; RY[K] := Y * 16;
  RVX[K] := Round((Tx - X) * Sp / Dd); RVY[K] := Round((Ty - Y) * Sp / Dd);
  RR[K] := R;
  { contour irregulier : largeur de chaque rangee, a gauche et a droite }
  For Dy := -R To R Do
  Begin
    W := Round(Sqrt(R * R - Dy * Dy + 0.0));
    D := Rnd(3);
    J := W - D;
    If J < 0 Then J := 0;
    RowL[K, Dy + R] := J;
    D := Rnd(3);
    J := W - D;
    If J < 0 Then J := 0;
    RowR[K, Dy + R] := J;
  End;
  { lissage du contour (pas de dents) }
  For Dy := 1 To 2 * R - 1 Do
  Begin
    RowL[K, Dy] := (RowL[K, Dy - 1] + 2 * RowL[K, Dy] + RowL[K, Dy + 1]) Div 4;
    RowR[K, Dy] := (RowR[K, Dy - 1] + 2 * RowR[K, Dy] + RowR[K, Dy + 1]) Div 4;
  End;
  For J := 0 To 2 Do
  Begin
    CrR[K, J] := 1 + Rnd(R Div 5 + 1);
    CrX[K, J] := Rnd(R) - R Div 2; CrY[K, J] := Rnd(R) - R Div 2;
  End;
  RAlive[K] := 1;
End;

Procedure Burst(X, Y, N : LongInt);
Var K, A, Sp, M : LongInt;
Begin
  M := 0;
  For K := 0 To MaxPart - 1 Do
    If (PLife[K] <= 0) And (M < N) Then
    Begin
      A := Rnd(360); Sp := 8 + Rnd(28);
      PX[K] := X * 16; PY[K] := Y * 16;
      PVX[K] := Sp * CosT[A] Div 1024; PVY[K] := Sp * SinT[A] Div 1024;
      PLife[K] := 10 + Rnd(14);
      Case Rnd(4) Of
        0 : PCol[K] := C_EXP1;
        1 : PCol[K] := C_EXP2;
        2 : PCol[K] := C_EXP3;
      Else
        PCol[K] := C_EXP4;
      End;
      Inc(M);
    End;
End;

Procedure Fire;
Var K, Nx, Ny : LongInt;
Begin
  If (State <> S_PLAY) Or (FireCool > 0) Then Exit;
  K := 0;
  While (K < MaxShot) And (TLife[K] > 0) Do Inc(K);
  If K >= MaxShot Then Exit;
  ShipPt(0, 24, Nx, Ny);
  TX[K] := Nx * 16; TY[K] := Ny * 16;
  TVX[K] := 9 * SinT[ShipA] * 16 Div 1024; TVY[K] := -9 * CosT[ShipA] * 16 Div 1024;
  TLife[K] := 60;
  FireCool := 5;
End;

Procedure GameOver;
Begin
  State := S_OVER;
  If Score > Best Then Best := Score;
  Show('Partie termin' + Chr(130) + 'e', 'Pointage : ' + IStr(Score) + '   F2 : nouvelle partie', C_RED);
  Msg := 'Vous avez perdu ! Pointage : ' + IStr(Score) + '. F2 : nouvelle partie.';
  Wait := 0;
  Redraw;
End;

Procedure ShipHit;
Begin
  Burst(SCX, SCY, 40);
  Dec(Lives);
  ClearSky;
  If Lives <= 0 Then
  Begin
    Lives := 0;
    GameOver;
    Exit;
  End;
  State := S_HIT; Wait := 0;
  Show('Touch' + Chr(130) + ' !', 'Vous avez ' + Chr(130) + 't' + Chr(130) + ' touch' + Chr(130) + ' ; il reste ' +
       IStr(Lives) + ' vie(s)', C_RED);
  Msg := 'Vous avez ' + Chr(130) + 't' + Chr(130) + ' touch' + Chr(130) + ' !';
End;

{ demonstration : viser l'asteroide le plus proche }
Procedure AutoAim;
Var K, D, Bd, Bk, A, Df : LongInt;
Begin
  Bd := MaxLongInt; Bk := -1;
  For K := 0 To MaxRock - 1 Do
    If RAlive[K] <> 0 Then
    Begin
      D := Sqr(RX[K] Div 16 - SCX) + Sqr(RY[K] Div 16 - SCY);
      If D < Bd Then Begin Bd := D; Bk := K; End;
    End;
  If Bk < 0 Then Exit;
  A := AngleTo(RX[Bk] Div 16 + RVX[Bk] Div 2 - SCX, RY[Bk] Div 16 + RVY[Bk] Div 2 - SCY);
  Df := Norm(A - ShipA + 180) - 180;
  If Df > 6 Then ShipA := Norm(ShipA + 6) Else If Df < -6 Then ShipA := Norm(ShipA - 6) Else ShipA := A;
  If Abs(Df) < 12 Then Fire;
End;

Procedure Step;
Var K, J, X, Y, Df, Maxc, N : LongInt;
Begin
  Inc(Tick);
  If FireCool > 0 Then Dec(FireCool);
  If Invul > 0 Then Dec(Invul);
  { rotation : touches tenues ou souris }
  If RotTime > 0 Then
  Begin
    Dec(RotTime);
    ShipA := Norm(ShipA + RotDir * 6);
  End;
  If (MouseAim <> 0) And (RotTime = 0) Then
  Begin
    Df := Norm(AimA - ShipA + 180) - 180;
    If Df > 8 Then ShipA := Norm(ShipA + 8) Else If Df < -8 Then ShipA := Norm(ShipA - 8) Else ShipA := AimA;
  End;
  If AutoAll <> 0 Then AutoAim;
  If FireHeld > 0 Then
  Begin
    Dec(FireHeld);
    Fire;
  End;
  { eclats }
  For K := 0 To MaxPart - 1 Do
    If PLife[K] > 0 Then
    Begin
      Dec(PLife[K]);
      PX[K] := PX[K] + PVX[K]; PY[K] := PY[K] + PVY[K];
    End;
  If State <> S_PLAY Then Exit;
  { nouveaux asteroides (plus nombreux a chaque vague) }
  Dec(SpawnWait);
  N := 0;
  For K := 0 To MaxRock - 1 Do N := N + RAlive[K];
  Maxc := 3 + Wave;
  If Maxc > MaxRock Then Maxc := MaxRock;
  If (SpawnWait <= 0) And (N < Maxc) Then
  Begin
    NewRock;
    SpawnWait := 26 - Wave * 2;
    If SpawnWait < 6 Then SpawnWait := 6;
  End;
  { asteroides : avancent ; sortis du ciel, ils disparaissent (prototype) }
  For K := 0 To MaxRock - 1 Do
    If RAlive[K] <> 0 Then
    Begin
      RX[K] := RX[K] + RVX[K]; RY[K] := RY[K] + RVY[K];
      X := RX[K] Div 16; Y := RY[K] Div 16;
      If (X < -40) Or (Y < -40) Or (X > BW + 40) Or (Y > BH + 40) Then RAlive[K] := 0;
      If (RAlive[K] <> 0) And (Invul = 0) And (Sqr(X - SCX) + Sqr(Y - SCY) <= Sqr(RR[K] + 12)) Then
      Begin
        ShipHit;
        Exit;
      End;
    End;
  { tirs : touchent un asteroide (10 points, comme le prototype) }
  For J := 0 To MaxShot - 1 Do
    If TLife[J] > 0 Then
    Begin
      Dec(TLife[J]);
      TX[J] := TX[J] + TVX[J]; TY[J] := TY[J] + TVY[J];
      X := TX[J] Div 16; Y := TY[J] Div 16;
      If (X < 0) Or (Y < 0) Or (X >= BW) Or (Y >= BH) Then TLife[J] := 0;
      For K := 0 To MaxRock - 1 Do
        If (TLife[J] > 0) And (RAlive[K] <> 0) Then
          If Sqr(X - RX[K] Div 16) + Sqr(Y - RY[K] Div 16) <= Sqr(RR[K] + 2) Then
          Begin
            RAlive[K] := 0; TLife[J] := 0;
            Burst(RX[K] Div 16, RY[K] Div 16, 8 + RR[K] Div 2);
            Score := Score + 10;
            Inc(Killed);
            If Killed Mod 15 = 0 Then
            Begin
              Inc(Wave);
              Show('Vague ' + IStr(Wave), 'Les ast' + Chr(130) + 'ro' + Chr(139) + 'des acc' + Chr(130) +
                   'l' + Chr(138) + 'rent !', C_YELLOW);
              Wait := 50;
            End;
          End;
    End;
End;

Procedure TimerTick;
Var C : Boolean;
Begin
  If (State = S_PAUSE) Or (State = S_TITLE) Then Exit;
  C := False;
  Step;
  Case State Of
    S_PLAY :
      If Wait > 0 Then
      Begin
        Dec(Wait);
        If Wait = 0 Then Banner := '';
      End;
    S_HIT :
      Begin
        Inc(Wait);
        If Wait > 45 Then
        Begin
          State := S_PLAY; Banner := ''; Wait := 0; Invul := 60; SpawnWait := 30;
          Msg := 'Fl' + Chr(138) + 'ches : tourner, Espace : tirer (ou la souris).';
          C := True;
        End;
      End;
    S_OVER :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait > 60 Then NewGame;
      End;
  End;
  If Tick Mod 5 = 0 Then C := True;
  Frame1(C);
End;

Procedure TogglePause;
Begin
  If State = S_PLAY Then
  Begin
    State := S_PAUSE;
    Show('Pause', 'P ou Espace : reprendre', C_GREEN);
    Msg := 'Pause.';
    Frame1(True);
  End
  Else If State = S_PAUSE Then
  Begin
    State := S_PLAY; Banner := '';
    Msg := 'Fl' + Chr(138) + 'ches : tourner, Espace : tirer (ou la souris).';
    Frame1(True);
  End;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PAUSE : TogglePause;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        If State = S_PLAY Then TogglePause;
        LClr;
        LAdd('Votre vaisseau est au centre du ciel ; il tourne sur lui-m' + Chr(136) + 'me. Les ast' + Chr(130) +
             'ro' + Chr(139) + 'des arrivent des bords en ligne droite : d' + Chr(130) + 'truisez-les avant ' +
             'qu''ils ne vous touchent. Chaque ast' + Chr(130) + 'ro' + Chr(139) + 'de d' + Chr(130) +
             'truit vaut 10 points.' + Chr(10) + Chr(10));
        LAdd('Un ast' + Chr(130) + 'ro' + Chr(139) + 'de qui touche le vaisseau co' + Chr(150) + 'te une vie et ' +
             'vide le ciel ; trois vies. Tous les 15 ast' + Chr(130) + 'ro' + Chr(139) + 'des d' + Chr(130) +
             'truits, une nouvelle vague : ils sont plus nombreux et plus rapides.' + Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches gauche et droite (tourner), Espace (tirer ; maintenue : tir ' +
             'continu), P (pause), F2 (nouvelle partie). Souris : le vaisseau vise le pointeur, clic : tirer.');
        Dummy := LMsgBox('Ast' + Chr(130) + 'ro' + Chr(139) + 'de - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Ast' + Chr(130) + 'ro' + Chr(139) + 'de pour OS/2-0 (Presentation Manager), port' +
                            Chr(130) + ' du prototype ASTEROID.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos d''Ast' + Chr(130) + 'ro' + Chr(139) + 'de', MB_OK Or MB_INFORMATION);
  End;
End;

Procedure StartRot(D : LongInt);
Begin
  If State <> S_PLAY Then Exit;
  MouseAim := 0;
  If (RotTime = 0) Or (RotDir <> D) Then ShipA := Norm(ShipA + D * 12);
  RotDir := D; RotTime := 14;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    { touche relachee : fin de la rotation ou du tir continu }
    If (Fl And KC_VIRTUALKEY) <> 0 Then
    Begin
      If (Vk = VK_LEFT) Or (Vk = VK_RIGHT) Then RotTime := 0;
      If Vk = VK_SPACE Then FireHeld := 0;
    End;
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
    If Vk = VK_PAUSE Then Begin TogglePause; Exit; End;
    If Vk = VK_LEFT Then Begin StartRot(-1); Exit; End;
    If Vk = VK_RIGHT Then Begin StartRot(1); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_UP) Then
    Begin
      If State = S_PLAY Then
      Begin
        Fire;
        FireHeld := 14;
      End
      Else If State = S_PAUSE Then TogglePause
      Else If State = S_OVER Then NewGame;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'P' : TogglePause;
      'N' : NewGame;
      ' ' : If State = S_PLAY Then Begin Fire; FireHeld := 14; End Else If State = S_PAUSE Then TogglePause;
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
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 206) And (Y < 234) Then NewGame
    Else If (Y >= 240) And (Y < 268) Then TogglePause;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If State = S_PLAY Then
    Begin
      MouseAim := 1;
      AimA := AngleTo(X - OX - SCX, Y - OY - SCY);
      ShipA := AimA;
      Fire;
    End
    Else If State = S_PAUSE Then TogglePause
    Else If State = S_OVER Then NewGame;
  End;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y : LongInt;
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
    WM_MOUSEMOVE :
      Begin
        X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
        If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) And (State = S_PLAY) Then
        Begin
          MouseAim := 1;
          AimA := AngleTo(X - OX - SCX, Y - OY - SCY);
        End;
        MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
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
  Msg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; NSpr := 0; NDirty := 0; Best := 0; Tick := 0;
  MouseAim := 0; Client := 0; Lives := 3; Wave := 1; State := S_TITLE;
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
  InitBmi;
  InitTrig;
  ClearSky;
  For K := 0 To MaxPart - 1 Do PLife[K] := 0;
  RenderSky;
  Dummy := WinRegisterClass(Hab, Z('ASTEROID'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('ASTEROID'), Z2('Ast' + Chr(130) + 'ro' + Chr(139) + 'de'),
                              0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_PAUSE, '~Pause' + Chr(9) + 'P');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos d''Ast' + Chr(130) + 'ro' + Chr(139) + 'de');
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
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
