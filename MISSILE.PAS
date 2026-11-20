{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: MISSILE - Commandement des missiles pour le Presentation
                Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program MISSILE;

{$R-,S-,I-}

{ Compilation : OS2PC MISSILE.PAS   (produit MISSILE.EXE)

  Portage vers OS/2-0 du prototype MISSILE.PAS du depot 7iles (Turbo
  Pascal, mode 13h de 320 x 200 en 16 couleurs, souris obligatoire) :
  fenetre de Presentation Manager avec menus, image en memoire
  (GpiDrawBits, seules les parties qui bougent sont recopiees), ciel de
  nuit etoile, collines, six villes eclairees, batterie au centre dont le
  canon suit le viseur, trainees des missiles, explosions en boules de
  feu, panneau du pointage, bruitages, barre d'etat et apparence d'OS/2.

  Comme le prototype : des missiles tombent du ciel sur six villes ; une
  ville touchee est detruite pour de bon ; toutes detruites : la partie
  est perdue ; chaque niveau envoie plus de missiles, plus souvent et
  plus vite ; 100 points par missile detruit ; en fin de niveau, 75
  points par ville restante.
  Ce qui change : au lieu de cliquer sur la tete d'un missile, le clic
  envoie un antimissile de la batterie, qui explose au point vise ; sa
  boule de feu detruit les missiles qui la traversent, et chaque missile
  detruit explose a son tour (reactions en chaine). 30 antimissiles par
  niveau (5 points par antimissile restant), une batterie touchee se tait
  jusqu'au niveau suivant, des missiles se divisent a partir du niveau
  3, une ville de plus tous les 10 000 points, le record de la seance.

  Souris : le viseur suit le pointeur, clic : tirer. Clavier : fleches
  (viser), Espace ou Entree (tirer), P (pause), F2 (nouvelle partie), F1
  (regles).
  Parametres : /SEED:n ; /AUTO (demonstration) ; /LEVEL:n ; /NOSOUND. }

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
  CM_AUTO = 201; CM_SOUND = 202;
  CM_RULES = 301; CM_ABOUT = 302;
  BW = 456; BH = 400; OX = 8; OY = 8;
  PnX = 472; PW = 146;
  CWant = 624; CHWant = 436;
  MaxDirty = 200; MaxSpr = 120;
  MaxM = 40; MaxE = 40; NCity = 6;
  GroundY = 372; BatX = 228; BatY = 334; MaxAimY = 316;
  { couleurs de l'image }
  C_SKY0 = 0; C_SKY1 = 1; C_SKY2 = 2; C_SKY3 = 3; C_STAR1 = 4; C_STAR2 = 5; C_STAR3 = 6; C_GND = 7;
  C_GNDL = 8; C_GNDD = 9; C_BLD1 = 10; C_BLD2 = 11; C_BLD3 = 12; C_WIN = 13; C_WIND = 14; C_RUBBLE = 15;
  C_TRAIL = 16; C_HEAD = 17; C_ITRAIL = 18; C_IHEAD = 19; C_EX1 = 20; C_EX2 = 21; C_EX3 = 22; C_EX4 = 23;
  C_BAT = 24; C_BATL = 25; C_BATD = 26; C_AIM = 27; C_WHITE = 28; C_BLACK = 29; C_BANNER = 30;
  C_BANNERE = 31; C_YELLOW = 32; C_RED = 33; C_GREEN = 34; C_MOON = 35; C_MOOND = 36; C_EXE = 37;
  NPal = 38;
  Pal : Array[0..NPal - 1] Of LongInt = (
    $03050F, $080A20, $120E30, $24143C, $4B5568, $A0AAC0, $FFFFFF, $8C6E32,
    $B4965A, $5A4620, $5A6E8C, $46506E, $78829B, $FFE68C, $8C7846, $3C322D,
    $C83C28, $FFFFFF, $3C8CFF, $C8F0FF, $FFFFF0, $FFE650, $FF961E, $D2321E,
    $9BA5B4, $DCE6F0, $55606E, $50FF50, $FFFFFF, $000000, $14143C, $FFD23C,
    $FFE650, $FF5050, $50DC78, $E6E6D2, $A0A08C, $FF64C8);
  S_READY = 1; S_PLAY = 2; S_BONUS = 3; S_OVER = 4; S_PAUSE = 5;
  SndRate = 11025;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back, Bg, Base : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  DX1, DY1, DX2, DY2 : Array[0..MaxDirty - 1] Of LongInt;
  SX1, SY1, SX2, SY2 : Array[0..MaxSpr - 1] Of LongInt;
  NDirty, NSpr : LongInt;
  { missiles (Kind 0 : ennemi, 1 : antimissile) ; positions en 1/16 de point }
  MOn, MKind, MSX, MSY, MX, MY, MVX, MVY, MTX, MTY, MLX, MLY, MSplit, TN, TK : Array[0..MaxM - 1] Of LongInt;
  { explosions (Own 1 : du joueur, detruit les missiles) }
  EOn, EX, EY, ER, EMax, ET, EOwn : Array[0..MaxE - 1] Of LongInt;
  CityX, CityOk : Array[0..NCity - 1] Of LongInt;
  AimX, AimY, MouseOn, Ammo, BatOk, ToSend, MaxAtOnce, SendWait, Level, StartLevel : LongInt;
  Score, Best, NextBonus, Killed, BonusStep, BonusCity, BonusAmmo : LongInt;
  State, Wait, Seed, AutoAll, Tick, OldState, AutoCool : LongInt;
  Banner, Banner2, Msg, LastMsg : String;
  BannerC, LastSig : LongInt;
  { bruitages }
  SndBuf : Array[0..39999] Of Byte;
  SndOfs, SndLen, SndPri : Array[0..15] Of LongInt;
  NSndBuf, SndPrio, SndCur, SndEnd, SoundOn : LongInt;
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

{ ==================================================================== }
{ Bruitages (fabriques au demarrage, 8 bits, 11025 Hz, joues par MDM)   }
{ ==================================================================== }

Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMPLAY';

{ son N : onde carree de F1 vers F2 (Hz), duree Ms, volume Vol (0..100) }
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

{ son N : bruit (explosion, choc) ; Hold : echantillons tenus (grave si grand) }
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

{ heure en millisecondes (le son en cours se termine a SndEnd) }
Function SndNow : LongInt;
Var T : Array[0..15] Of Byte;
Begin
  Dummy := DosGetDateTime(LongInt(@T));
  SndNow := ((T[0] * 60 + T[1]) * 60 + T[2]) * 1000 + T[3] * 10;
End;

{ un nouveau son coupe celui qui joue : un son moins important (Pri)
  n'interrompt pas un son plus important qui n'est pas termine }
Procedure PlaySnd(N : LongInt);
Var T : LongInt;
Begin
  If (SoundOn = 0) Or (SndLen[N] = 0) Then Exit;
  T := SndNow;
  If (SndPri[N] < SndCur) And (T < SndEnd) And (T >= SndEnd - 60000) Then Exit;
  SndCur := SndPri[N];
  SndEnd := T + SndLen[N] * 1000 Div SndRate;
  Dummy := MdmPlay(LongInt(@SndBuf[SndOfs[N]]), SndLen[N], SndRate, 8, 1);
End;


Function MinX(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinX := A Else MinX := B;
End;

Function MaxX(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxX := A Else MaxX := B;
End;

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 1; MakeTone(0, 320, 980, 130, 40);          { depart d'un antimissile }
  SndPrio := 2; MakeNoise(1, 330, 110, 3);               { explosion }
  SndPrio := 4; MakeNoise(2, 900, 125, 8);               { ville detruite }
  SndPrio := 3; MakeTone(3, 560, 920, 520, 45);          { debut de niveau }
  SndPrio := 3; MakeTone(4, 1320, 1320, 35, 35);         { compte des points }
  SndPrio := 5; MakeTone(5, 420, 70, 1300, 60);          { partie terminee }
  SndPrio := 0; MakeTone(6, 150, 120, 70, 40);           { plus d'antimissile }
  SndPrio := 4; MakeTone(7, 520, 1560, 600, 50);         { ville de plus }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Decor                                                                 }
{ ==================================================================== }

Procedure PutB(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Back[(BH - 1 - Y) * BW + X] := C;
End;

Function GetBase(X, Y : LongInt) : LongInt;
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then GetBase := Base[(BH - 1 - Y) * BW + X]
  Else GetBase := 0;
End;

{ hauteur du sol (collines, monticule de la batterie au milieu) }
Function GroundAt(X : LongInt) : LongInt;
Var Y, D : LongInt;
Begin
  Y := GroundY - 4 + ((X * 7) Mod 23) Div 8 - ((X * 3) Mod 17) Div 9;
  D := Abs(X - BatX);
  If D < 46 Then Y := MinX(Y, BatY + 8 + D * D Div 90);
  GroundAt := Y;
End;

Procedure RenderBg;
Var X, Y, C, K : LongInt;
Begin
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      If Y < 120 Then C := C_SKY0
      Else If Y < 140 Then Begin If (X + Y) Mod 2 = 0 Then C := C_SKY0 Else C := C_SKY1; End
      Else If Y < 230 Then C := C_SKY1
      Else If Y < 250 Then Begin If (X + Y) Mod 2 = 0 Then C := C_SKY1 Else C := C_SKY2; End
      Else If Y < 320 Then C := C_SKY2
      Else If Y < 336 Then Begin If (X + Y) Mod 2 = 0 Then C := C_SKY2 Else C := C_SKY3; End
      Else C := C_SKY3;
      Fb[(BH - 1 - Y) * BW + X] := C;
    End;
  { lune }
  Ell(380, 58, 20, 20, C_MOON);
  Ell(388, 52, 17, 17, C_SKY0);
  Pix(370, 62, C_MOOND); Pix(372, 70, C_MOOND); Pix(366, 52, C_MOOND);
  For K := 1 To 110 Do
  Begin
    X := Rnd(BW); Y := Rnd(300);
    Case Rnd(6) Of
      0 : C := C_STAR3;
      1, 2 : C := C_STAR2;
    Else
      C := C_STAR1;
    End;
    If (Sqr(X - 380) + Sqr(Y - 58) > 500) Then Pix(X, Y, C);
  End;
  { collines }
  For X := 0 To BW - 1 Do
  Begin
    Y := GroundAt(X);
    Rect(X, Y, X, BH - 1, C_GND);
    Pix(X, Y, C_GNDL); Pix(X, Y + 1, C_GNDL);
    For K := Y + 6 To BH - 1 Do If (X * 5 + K * 3) Mod 11 = 0 Then Pix(X, K, C_GNDD);
  End;
  Move(Fb, Bg, SizeOf(Fb));
End;

{ ville I : immeubles a fenetres eclairees (ou ruines) dans l'image fixe }
Procedure DrawCity(I : LongInt);
Var X0, Y0, B, H, W, X, Y, C, K : LongInt;
Begin
  X0 := CityX[I] - 18; Y0 := GroundY - 2;
  { efface (fond du ciel et sol) }
  For Y := Y0 - 30 To Y0 + 4 Do
    For X := X0 - 2 To X0 + 38 Do
      If (X >= 0) And (X < BW) Then Base[(BH - 1 - Y) * BW + X] := Bg[(BH - 1 - Y) * BW + X];
  If CityOk[I] = 0 Then
  Begin
    { ruines fumantes }
    For X := X0 To X0 + 36 Do
    Begin
      H := 2 + ((X * 13 + I * 7) Mod 7);
      For Y := Y0 - H To Y0 Do Base[(BH - 1 - Y) * BW + X] := C_RUBBLE;
    End;
    Exit;
  End;
  X := X0; B := 0;
  While X < X0 + 36 Do
  Begin
    W := 7 + ((B * 5 + I * 3) Mod 4);
    If X + W > X0 + 36 Then W := X0 + 36 - X;
    H := 10 + ((B * 7 + I * 11) Mod 17);
    Case (B + I) Mod 3 Of
      0 : C := C_BLD1;
      1 : C := C_BLD2;
    Else
      C := C_BLD3;
    End;
    For Y := Y0 - H To Y0 Do
      For K := X To X + W - 2 Do
      Begin
        If ((Y - (Y0 - H)) Mod 4 = 2) And ((K - X) Mod 3 = 1) And (Y < Y0 - 2) Then
        Begin
          If (K * 7 + Y * 3 + I) Mod 5 = 0 Then Base[(BH - 1 - Y) * BW + K] := C_WIND
          Else Base[(BH - 1 - Y) * BW + K] := C_WIN;
        End
        Else Base[(BH - 1 - Y) * BW + K] := C;
      End;
    X := X + W;
    Inc(B);
  End;
End;

{ l'image fixe Base (decor et villes) passe dans Back et l'image }
Procedure BaseToScreen(X1, Y1, X2, Y2 : LongInt);
Var Y, B : LongInt;
Begin
  X1 := MaxX(X1, 0); Y1 := MaxX(Y1, 0); X2 := MinX(X2, BW - 1); Y2 := MinX(Y2, BH - 1);
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW + X1;
    Move(Base[B], Back[B], X2 - X1 + 1);
    Move(Base[B], Fb[B], X2 - X1 + 1);
  End;
  AddDirty(X1, Y1, X2, Y2);
End;

{ ==================================================================== }
{ Trainees (dans Back) et objets mobiles                                }
{ ==================================================================== }

Procedure PixT(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < GroundY + 6) Then
  Begin
    Back[(BH - 1 - Y) * BW + X] := C;
    Fb[(BH - 1 - Y) * BW + X] := C;
  End;
End;

{ trait de (X1, Y1) a (X2, Y2) dans la trainee ; C < 0 : efface (Base) }
Procedure TrailLine(X1, Y1, X2, Y2, C : LongInt);
Var N, K, X, Y, Dx, Dy : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  N := MaxX(Abs(Dx), Abs(Dy));
  If N = 0 Then N := 1;
  For K := 0 To N Do
  Begin
    X := X1 + Dx * K Div N; Y := Y1 + Dy * K Div N;
    If C < 0 Then PixT(X, Y, GetBase(X, Y)) Else PixT(X, Y, C);
  End;
  AddDirty(MinX(X1, X2), MinX(Y1, Y2), MaxX(X1, X2), MaxX(Y1, Y2));
End;

Function TrailCol(K : LongInt) : LongInt;
Begin
  If MKind[K] = 0 Then TrailCol := C_TRAIL Else TrailCol := C_ITRAIL;
End;

{ points K1 a K2 de la trainee du missile M (la droite du depart a la
  cible, en TN[M] pas) : traces et effaces sont toujours les memes points }
Procedure TrailPts(M, K1, K2, C : LongInt);
Var K, X, Y, X1, Y1, X2, Y2 : LongInt;
Begin
  If K2 < K1 Then Exit;
  X1 := BW; Y1 := BH; X2 := -1; Y2 := -1;
  For K := K1 To K2 Do
  Begin
    X := MSX[M] + (MTX[M] - MSX[M]) * K Div TN[M]; Y := MSY[M] + (MTY[M] - MSY[M]) * K Div TN[M];
    If C < 0 Then PixT(X, Y, GetBase(X, Y)) Else PixT(X, Y, C);
    X1 := MinX(X1, X); Y1 := MinX(Y1, Y); X2 := MaxX(X2, X); Y2 := MaxX(Y2, Y);
  End;
  AddDirty(X1, Y1, X2, Y2);
End;

{ fin d'un missile : sa trainee s'efface, les autres sont retracees }
Procedure KillMissile(K : LongInt);
Var J : LongInt;
Begin
  MOn[K] := 0;
  TrailPts(K, 0, TK[K], -1);
  For J := 0 To MaxM - 1 Do
    If MOn[J] <> 0 Then TrailPts(J, 0, TK[J], TrailCol(J));
End;

Procedure ClearAll;
Var K : LongInt;
Begin
  For K := 0 To MaxM - 1 Do MOn[K] := 0;
  For K := 0 To MaxE - 1 Do EOn[K] := 0;
End;

{ boule de feu : grandit jusqu'a Max puis retrecit }
Procedure AddExp(X, Y, Max, Own : LongInt);
Var K : LongInt;
Begin
  For K := 0 To MaxE - 1 Do
    If EOn[K] = 0 Then
    Begin
      EOn[K] := 1; EX[K] := X; EY[K] := Y; ER[K] := 1; EMax[K] := Max; ET[K] := 0; EOwn[K] := Own;
      Exit;
    End;
End;

Procedure DrawExps;
Var K, R, C1, C2 : LongInt;
Begin
  For K := 0 To MaxE - 1 Do
    If EOn[K] <> 0 Then
    Begin
      R := ER[K];
      Case (Tick + K) Mod 4 Of
        0 : Begin C1 := C_EX1; C2 := C_EX2; End;
        1 : Begin C1 := C_EX2; C2 := C_EX3; End;
        2 : Begin C1 := C_EX3; C2 := C_EX4; End;
      Else
        Begin C1 := C_EXE; C2 := C_EX1; End;
      End;
      If EOwn[K] = 0 Then Begin C1 := C_EX3; C2 := C_EX4; If Tick Mod 2 = 0 Then C2 := C_EX2; End;
      FDisc(EX[K], EY[K], R, C1);
      If R > 4 Then FDisc(EX[K], EY[K], R - 4, C2);
      If R > 9 Then FDisc(EX[K], EY[K], R - 9, C_EX1);
      SprRect(EX[K] - R - 1, EY[K] - R - 1, EX[K] + R + 1, EY[K] + R + 1);
    End;
End;

Procedure DrawHeads;
Var K, X, Y : LongInt;
Begin
  For K := 0 To MaxM - 1 Do
    If MOn[K] <> 0 Then
    Begin
      X := MX[K] Div 16; Y := MY[K] Div 16;
      If MKind[K] = 0 Then
      Begin
        If Tick Mod 4 < 2 Then Rect(X - 1, Y - 1, X + 1, Y + 1, C_HEAD) Else Rect(X - 1, Y - 1, X + 1, Y + 1, C_EX2);
      End
      Else
      Begin
        Rect(X - 1, Y - 1, X + 1, Y + 1, C_IHEAD);
        { croix de la cible }
        Pix(MTX[K] - 3, MTY[K] - 3, C_IHEAD); Pix(MTX[K] + 3, MTY[K] + 3, C_IHEAD);
        Pix(MTX[K] - 3, MTY[K] + 3, C_IHEAD); Pix(MTX[K] + 3, MTY[K] - 3, C_IHEAD);
        Pix(MTX[K] - 2, MTY[K] - 2, C_ITRAIL); Pix(MTX[K] + 2, MTY[K] + 2, C_ITRAIL);
        Pix(MTX[K] - 2, MTY[K] + 2, C_ITRAIL); Pix(MTX[K] + 2, MTY[K] - 2, C_ITRAIL);
        SprRect(MTX[K] - 3, MTY[K] - 3, MTX[K] + 3, MTY[K] + 3);
      End;
      SprRect(X - 1, Y - 1, X + 1, Y + 1);
    End;
End;

{ batterie : coupole et canon tourne vers le viseur }
Procedure DrawBattery;
Var Dx, Dy, L, Ex, Ey, K : LongInt;
Begin
  Ell(BatX, BatY + 4, 14, 9, C_BATD);
  Ell(BatX, BatY + 3, 13, 8, C_BAT);
  Rect(BatX - 6, BatY - 1, BatX + 2, BatY, C_BATL);
  If BatOk <> 0 Then
  Begin
    Dx := AimX - BatX; Dy := AimY - BatY;
    L := Round(Sqrt(Dx * 1.0 * Dx + Dy * 1.0 * Dy));
    If L < 1 Then L := 1;
    Ex := BatX + Dx * 16 Div L; Ey := BatY + Dy * 16 Div L;
    TLine(BatX, BatY, Ex, Ey, 1, C_BATL);
    DLine(BatX, BatY, Ex, Ey, C_WHITE);
    { reserve d'antimissiles : petits obus de part et d'autre }
    For K := 0 To MinX(Ammo, 30) - 1 Do
      If K Mod 2 = 0 Then Rect(BatX - 20 - (K Div 2) * 3, BatY + 14, BatX - 19 - (K Div 2) * 3, BatY + 18, C_ITRAIL)
      Else Rect(BatX + 19 + (K Div 2) * 3, BatY + 14, BatX + 20 + (K Div 2) * 3, BatY + 18, C_ITRAIL);
  End
  Else
  Begin
    { batterie touchee : fumee }
    For K := 0 To 5 Do FDisc(BatX - 8 + K * 3 + (Tick Div 3 + K) Mod 3, BatY - 4 - K * 2, 2, C_RUBBLE);
  End;
  SprRect(BatX - 66, BatY - 18, BatX + 66, BatY + 18);
End;

Procedure DrawAim;
Var C : LongInt;
Begin
  If (State <> S_PLAY) And (State <> S_READY) Then Exit;
  C := C_AIM;
  Rect(AimX - 9, AimY, AimX - 3, AimY, C); Rect(AimX + 3, AimY, AimX + 9, AimY, C);
  Rect(AimX, AimY - 9, AimX, AimY - 3, C); Rect(AimX, AimY + 3, AimX, AimY + 9, C);
  Pix(AimX, AimY, C_WHITE);
  SprRect(AimX - 9, AimY - 9, AimX + 9, AimY + 9);
End;

Procedure BannerDraw;
Var W, X, Y : LongInt;
Begin
  If Banner = '' Then Exit;
  W := Length(Banner) * 16;
  If Length(Banner2) * 8 > W Then W := Length(Banner2) * 8;
  W := W + 28;
  X := (BW - W) Div 2; Y := 150;
  Rect(X, Y, X + W - 1, Y + 58, C_BANNER);
  Rect(X, Y, X + W - 1, Y, C_BANNERE); Rect(X, Y + 58, X + W - 1, Y + 58, C_BANNERE);
  Rect(X, Y, X, Y + 58, C_BANNERE); Rect(X + W - 1, Y, X + W - 1, Y + 58, C_BANNERE);
  FbTextSh(X + (W - Length(Banner) * 16) Div 2, Y + 6, Banner, BannerC, C_BLACK, 2);
  FbText(X + (W - Length(Banner2) * 8) Div 2, Y + 38, Banner2, C_WHITE, 1);
  SprRect(X, Y, X + W - 1, Y + 58);
End;

Procedure DrawSprites;
Begin
  SprBegin;
  DrawBattery;
  DrawHeads;
  DrawExps;
  DrawAim;
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

Function Cities : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NCity - 1 Do If CityOk[K] <> 0 Then Inc(N);
  Cities := N;
End;

Procedure CityIcon(X, Y : LongInt; Ok : Boolean);
Begin
  If Ok Then
  Begin
    FBar(X, Y + 3, X + 3, Y + 10, CLR_DARKBLUE);
    FBar(X + 4, Y, X + 7, Y + 10, CLR_DARKBLUE);
    FBar(X + 8, Y + 5, X + 11, Y + 10, CLR_DARKBLUE);
    FBar(X + 5, Y + 2, X + 5, Y + 2, CLR_YELLOW);
  End
  Else FBar(X, Y + 8, X + 11, Y + 10, CLR_DARKGRAY);
End;

Procedure DrawCounters;
Var S : String; K : LongInt;
Begin
  FBar(PnX + 2, 86, PnX + PW - 3, 120, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 87, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 128, PnX + PW - 1, 218, CLR_PALEGRAY);
  OutTxt(PnX, 128, 'Niveau : ' + IStr(Level), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 148, 'Villes :', CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To NCity - 1 Do CityIcon(PnX + 70 + K * 13, 151, CityOk[K] <> 0);
  OutTxt(PnX, 168, 'Antimissiles : ' + IStr(Ammo), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 188, 'D' + Chr(130) + 'truits : ' + IStr(Killed), CLR_BLACK, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 206, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  OutTxt(PnX + (PW - 16 * 8) Div 2, 0, 'Commandement des', CLR_DARKRED, CLR_PALEGRAY);
  BigText(PnX + (PW - 8 * 16) Div 2, 18, 'MISSILES', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 64, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 82, PnX + PW - 1, 124, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 83, PnX + PW - 2, 123, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 84, PnX + PW - 3, 122, CLR_WHITE);
  DrawCounters;
  Button(PnX, 236, PW, 28, 'Nouvelle partie');
  Button(PnX, 270, PW, 28, 'Pause');
  OutTxt(PnX, 310, 'Souris : viser', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 326, 'Clic : tirer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 342, 'ou fl' + Chr(138) + 'ches, Espace', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 358, 'P : pause', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 374, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Function Sig : LongInt;
Var K, S : LongInt;
Begin
  S := Score * 7 + Level * 131 + Ammo * 1009 + Killed * 10007 + Best * 3;
  For K := 0 To NCity - 1 Do S := S * 3 + CityOk[K];
  Sig := S;
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
  LastMsg := Msg; LastSig := Sig;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
End;

Procedure Frame1;
Begin
  If Client = 0 Then Exit;
  DrawSprites;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  BlitAll(Hps);
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
{ Partie                                                                }
{ ==================================================================== }

Procedure Show(B1, B2 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; BannerC := C;
End;

Procedure PlayMsg;
Begin
  Msg := 'Visez avec la souris et cliquez : l''antimissile explose au point vis' + Chr(130) + '.';
End;

{ cible d'un missile ennemi : une ville, la batterie ou le sol }
Procedure PickTarget(K : LongInt);
Var I, N, R : LongInt;
Begin
  R := Rnd(10);
  If (R < 7) And (Cities > 0) Then
  Begin
    N := Rnd(Cities);
    For I := 0 To NCity - 1 Do
      If CityOk[I] <> 0 Then
      Begin
        If N = 0 Then
        Begin
          MTX[K] := CityX[I] - 12 + Rnd(25); MTY[K] := GroundY - 6;
          Exit;
        End;
        Dec(N);
      End;
  End;
  If (R = 7) And (BatOk <> 0) Then
  Begin
    MTX[K] := BatX - 6 + Rnd(13); MTY[K] := BatY;
    Exit;
  End;
  MTX[K] := 10 + Rnd(BW - 20); MTY[K] := GroundAt(MTX[K]);
End;

Function Speed : LongInt;
Begin
  Speed := 8 + MinX(Level - 1, 12) * 2 + Rnd(4 + MinX(Level, 8));
End;

Procedure Aim(K, X, Y, Spd : LongInt);
Var Dx, Dy, L : LongInt;
Begin
  MX[K] := X * 16; MY[K] := Y * 16; MSX[K] := X; MSY[K] := Y; MLX[K] := X; MLY[K] := Y;
  Dx := MTX[K] - X; Dy := MTY[K] - Y;
  L := Round(Sqrt(Dx * 1.0 * Dx + Dy * 1.0 * Dy));
  If L < 1 Then L := 1;
  MVX[K] := Dx * Spd Div L; MVY[K] := Dy * Spd Div L;
  TN[K] := MaxX(MaxX(Abs(Dx), Abs(Dy)), 1); TK[K] := 0;
  If (MVY[K] <= 0) And (MKind[K] = 0) Then MVY[K] := 1;
End;

Function FreeSlot : LongInt;
Var K : LongInt;
Begin
  FreeSlot := -1;
  For K := 0 To MaxM - 1 Do
    If MOn[K] = 0 Then
    Begin
      FreeSlot := K;
      Exit;
    End;
End;

Procedure LaunchEnemy;
Var K : LongInt;
Begin
  K := FreeSlot;
  If K < 0 Then Exit;
  MOn[K] := 1; MKind[K] := 0;
  PickTarget(K);
  Aim(K, 6 + Rnd(BW - 12), 0, Speed);
  { a partir du niveau 3, certains se diviseront en route }
  MSplit[K] := 0;
  If (Level >= 3) And (Rnd(100) < 12 + Level * 2) Then MSplit[K] := 100 + Rnd(110);
  Dec(ToSend);
End;

Procedure Fire;
Var K : LongInt;
Begin
  If State <> S_PLAY Then Exit;
  If (BatOk = 0) Or (Ammo <= 0) Then
  Begin
    PlaySnd(6);
    Exit;
  End;
  K := FreeSlot;
  If K < 0 Then Exit;
  MOn[K] := 1; MKind[K] := 1;
  MTX[K] := AimX; MTY[K] := MinX(AimY, MaxAimY);
  Aim(K, BatX, BatY - 2, 112);
  Dec(Ammo);
  PlaySnd(0);
End;

Procedure NewLevel;
Var K : LongInt;
Begin
  ClearAll;
  Move(Base, Back, SizeOf(Back));
  Move(Base, Fb, SizeOf(Fb));
  NDirty := 0; NSpr := 0;
  AddDirty(0, 0, BW - 1, BH - 1);
  { prototype : 2, 4, 5, 6, 10, 16 missiles a la fois ; ici moins, mais plus longtemps }
  Case MinX(Level, 6) Of
    1 : MaxAtOnce := 2;
    2 : MaxAtOnce := 4;
    3 : MaxAtOnce := 5;
    4 : MaxAtOnce := 6;
    5 : MaxAtOnce := 8;
  Else
    MaxAtOnce := 10;
  End;
  ToSend := MinX(10 + (Level - 1) * 5, 60);
  Ammo := 30; BatOk := 1; SendWait := 40;
  State := S_READY; Wait := 0;
  Show('Niveau ' + IStr(Level), 'D' + Chr(130) + 'fendez les villes !', C_YELLOW);
  PlaySnd(3);
  PlayMsg;
  For K := 0 To NCity - 1 Do ;
  Redraw;
End;

Procedure NewGame;
Var K : LongInt;
Begin
  Score := 0; Level := StartLevel; Killed := 0; NextBonus := 10000;
  For K := 0 To NCity - 1 Do CityOk[K] := 1;
  Move(Bg, Base, SizeOf(Base));
  For K := 0 To NCity - 1 Do DrawCity(K);
  AimX := BatX; AimY := 200;
  NewLevel;
End;

Procedure GameOver;
Begin
  State := S_OVER; Wait := 0;
  If Score > Best Then Best := Score;
  PlaySnd(5);
  Show('Partie termin' + Chr(130) + 'e', 'Toutes les villes sont d' + Chr(130) + 'truites. Pointage : ' +
       IStr(Score), C_RED);
  Msg := 'Toutes les villes sont d' + Chr(130) + 'truites ! F2 ou Espace : nouvelle partie.';
End;

Procedure AddScore(N : LongInt);
Var K : LongInt;
Begin
  Score := Score + N;
  { une ville de plus tous les 10 000 points }
  If Score >= NextBonus Then
  Begin
    NextBonus := NextBonus + 10000;
    For K := 0 To NCity - 1 Do
      If CityOk[K] = 0 Then
      Begin
        CityOk[K] := 1;
        DrawCity(K);
        BaseToScreen(CityX[K] - 20, GroundY - 32, CityX[K] + 20, GroundY + 4);
        PlaySnd(7);
        Msg := 'Une ville de plus !';
        Exit;
      End;
  End;
End;

{ un missile ennemi arrive au sol }
Procedure Impact(K : LongInt);
Var X, I : LongInt;
Begin
  X := MX[K] Div 16;
  KillMissile(K);
  AddExp(X, MTY[K], 16, 0);
  PlaySnd(1);
  For I := 0 To NCity - 1 Do
    If (CityOk[I] <> 0) And (Abs(X - CityX[I]) <= 22) Then
    Begin
      CityOk[I] := 0;
      DrawCity(I);
      BaseToScreen(CityX[I] - 20, GroundY - 32, CityX[I] + 20, GroundY + 4);
      PlaySnd(2);
      Msg := 'Une ville est d' + Chr(130) + 'truite !';
    End;
  If (BatOk <> 0) And (Abs(X - BatX) <= 16) Then
  Begin
    BatOk := 0; Ammo := 0;
    PlaySnd(2);
    Msg := 'La batterie est touch' + Chr(130) + 'e : plus de tir jusqu''au niveau suivant !';
  End;
  If Cities = 0 Then GameOver;
End;

Procedure MoveMissiles;
Var K, J, X, Y, N, S : LongInt;
Begin
  For K := 0 To MaxM - 1 Do
    If MOn[K] <> 0 Then
    Begin
      MX[K] := MX[K] + MVX[K]; MY[K] := MY[K] + MVY[K];
      X := MX[K] Div 16; Y := MY[K] Div 16;
      If MKind[K] = 1 Then
      Begin
        { antimissile : explose au point vise }
        If ((MVY[K] <= 0) And (Y <= MTY[K])) Or ((MVY[K] > 0) And (Y >= MTY[K])) Then
        Begin
          KillMissile(K);
          AddExp(MTX[K], MTY[K], 22, 1);
          PlaySnd(1);
          Continue;
        End;
      End
      Else If Y >= MTY[K] Then
      Begin
        Impact(K);
        If State = S_OVER Then Exit;
        Continue;
      End;
      { avance de la trainee le long de son grand axe }
      If Abs(MTX[K] - MSX[K]) >= Abs(MTY[K] - MSY[K]) Then N := Abs(X - MSX[K]) Else N := Abs(Y - MSY[K]);
      If N > TN[K] Then N := TN[K];
      If N > TK[K] Then
      Begin
        TrailPts(K, TK[K] + 1, N, TrailCol(K));
        TK[K] := N;
      End;
      MLX[K] := X; MLY[K] := Y;
      { division en plusieurs missiles }
      If (MKind[K] = 0) And (MSplit[K] > 0) And (Y >= MSplit[K]) Then
      Begin
        MSplit[K] := 0;
        N := 1 + Rnd(2);
        For J := 1 To N Do
        Begin
          S := FreeSlot;
          If S >= 0 Then
          Begin
            MOn[S] := 1; MKind[S] := 0; MSplit[S] := 0;
            PickTarget(S);
            Aim(S, X, Y, Speed);
          End;
        End;
      End;
    End;
End;

{ les boules de feu du joueur detruisent les missiles (et ceux-ci explosent) }
Procedure MoveExps;
Var K, J, X, Y : LongInt;
Begin
  For K := 0 To MaxE - 1 Do
    If EOn[K] <> 0 Then
    Begin
      Inc(ET[K]);
      If ET[K] <= EMax[K] Then ER[K] := ET[K]
      Else ER[K] := 2 * EMax[K] - ET[K];
      If ER[K] <= 0 Then Begin EOn[K] := 0; Continue; End;
      If EOwn[K] <> 0 Then
        For J := 0 To MaxM - 1 Do
          If (MOn[J] <> 0) And (MKind[J] = 0) Then
          Begin
            X := MX[J] Div 16; Y := MY[J] Div 16;
            If Sqr(X - EX[K]) + Sqr(Y - EY[K]) <= Sqr(ER[K]) Then
            Begin
              KillMissile(J);
              Inc(Killed);
              AddScore(100);
              AddExp(X, Y, 14, 1);
              PlaySnd(1);
            End;
          End;
    End;
End;

Function Enemies : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To MaxM - 1 Do If (MOn[K] <> 0) And (MKind[K] = 0) Then Inc(N);
  Enemies := N;
End;

Function Busy : Boolean;
Var K : LongInt;
Begin
  Busy := False;
  For K := 0 To MaxM - 1 Do If MOn[K] <> 0 Then Busy := True;
  For K := 0 To MaxE - 1 Do If EOn[K] <> 0 Then Busy := True;
End;

{ demonstration : vise le missile le plus menacant, la ou il sera }
Procedure AutoPlay;
Var K, J, Best0, Bt, T, X, Y, D, Taken : LongInt;
Begin
  If AutoCool > 0 Then Begin Dec(AutoCool); Exit; End;
  Best0 := -1; Bt := 99999;
  For K := 0 To MaxM - 1 Do
    If (MOn[K] <> 0) And (MKind[K] = 0) And (MY[K] Div 16 > 40) Then
    Begin
      Taken := 0;
      For J := 0 To MaxM - 1 Do
        If (MOn[J] <> 0) And (MKind[J] = 1) And (Abs(MTX[J] - MX[K] Div 16) < 30) Then Taken := 1;
      For J := 0 To MaxE - 1 Do
        If (EOn[J] <> 0) And (EOwn[J] <> 0) And (Abs(EX[J] - MX[K] Div 16) < 26) And
           (Abs(EY[J] - MY[K] Div 16) < 40) Then Taken := 1;
      T := (MTY[K] * 16 - MY[K]) Div MaxX(MVY[K], 1);
      If (Taken = 0) And (T < Bt) Then Begin Bt := T; Best0 := K; End;
    End;
  If Best0 < 0 Then Exit;
  X := MX[Best0] Div 16; Y := MY[Best0] Div 16;
  D := Round(Sqrt(Sqr(X - BatX) * 1.0 + Sqr(Y - BatY) * 1.0));
  T := D * 16 Div 112 + 8;
  AimX := (MX[Best0] + MVX[Best0] * T) Div 16; AimY := (MY[Best0] + MVY[Best0] * T) Div 16;
  If AimY > MaxAimY Then AimY := MaxAimY;
  If AimX < 4 Then AimX := 4;
  If AimX > BW - 5 Then AimX := BW - 5;
  Fire;
  AutoCool := 6;
End;

Procedure Step;
Begin
  Inc(Tick);
  MoveExps;
  If State = S_PLAY Then
  Begin
    If AutoAll <> 0 Then AutoPlay;
    Dec(SendWait);
    If (SendWait <= 0) And (ToSend > 0) And (Enemies < MaxAtOnce) Then
    Begin
      LaunchEnemy;
      SendWait := MaxX(6, 40 - Level * 3) + Rnd(20);
    End;
    MoveMissiles;
    If (State = S_PLAY) And (ToSend <= 0) And Not Busy Then
    Begin
      { fin du niveau : on compte les villes et les antimissiles }
      State := S_BONUS; Wait := 0; BonusStep := 0; BonusCity := 0; BonusAmmo := 0;
      Show('Niveau ' + IStr(Level) + ' termin' + Chr(130), 'Villes : 75 points, antimissiles : 5 points', C_GREEN);
      Msg := 'Fin du niveau : points des villes et des antimissiles restants.';
    End;
  End
  Else If State = S_OVER Then MoveMissiles;
End;

Procedure BonusTick;
Var K, N : LongInt;
Begin
  Inc(Wait);
  If Wait Mod 6 <> 0 Then Exit;
  { une ville, puis cinq antimissiles a chaque pas }
  N := 0;
  For K := 0 To NCity - 1 Do
    If CityOk[K] <> 0 Then
    Begin
      If N = BonusCity Then
      Begin
        Inc(BonusCity);
        AddScore(75);
        PlaySnd(4);
        Exit;
      End;
      Inc(N);
    End;
  If Ammo > 0 Then
  Begin
    N := MinX(Ammo, 5);
    Ammo := Ammo - N;
    AddScore(N * 5);
    PlaySnd(4);
    Exit;
  End;
  Inc(BonusStep);
  If BonusStep > 8 Then
  Begin
    Inc(Level);
    Banner := '';
    NewLevel;
  End;
End;

Procedure TimerTick;
Begin
  If State = S_PAUSE Then Exit;
  Step;
  Case State Of
    S_READY :
      Begin
        Inc(Wait);
        If Wait > 55 Then
        Begin
          State := S_PLAY; Banner := '';
        End;
      End;
    S_BONUS : BonusTick;
    S_OVER :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait > 110 Then NewGame;
      End;
  End;
  Frame1;
End;

Procedure TogglePause;
Begin
  If (State = S_PLAY) Or (State = S_READY) Then
  Begin
    OldState := State;
    State := S_PAUSE;
    Show('Pause', 'P ou Espace : reprendre', C_GREEN);
    Msg := 'Pause.';
    Frame1;
  End
  Else If State = S_PAUSE Then
  Begin
    State := OldState; Banner := '';
    PlayMsg;
    Frame1;
  End;
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
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PAUSE : TogglePause;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES :
      Begin
        If State = S_PLAY Then TogglePause;
        LClr;
        LAdd('Des missiles tombent du ciel sur vos six villes. La batterie, au centre, tire des ' +
             'antimissiles : visez avec la souris et cliquez ; l''antimissile explose au point vis' + Chr(130) +
             ' et sa boule de feu d' + Chr(130) + 'truit les missiles qui la traversent. ');
        LAdd('Chaque missile d' + Chr(130) + 'truit explose ' + Chr(133) + ' son tour (100 points).' + Chr(10) +
             Chr(10));
        LAdd('Une ville touch' + Chr(130) + 'e est d' + Chr(130) + 'truite ; quand il n''en reste plus, la ' +
             'partie est perdue. La batterie a 30 antimissiles par niveau ; touch' + Chr(130) + 'e, elle se ' +
             'tait jusqu''au niveau suivant. ');
        LAdd('En fin de niveau : 75 points par ville et 5 par antimissile restant. Une ville de plus tous les ' +
             '10 000 points. Des missiles se divisent ' + Chr(133) + ' partir du niveau 3.' + Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches (viser), Espace ou Entr' + Chr(130) + 'e (tirer), P (pause), F2 ' +
             '(nouvelle partie).');
        Dummy := LMsgBox('Commandement des missiles - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Commandement des missiles pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype MISSILE.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
End;

Procedure Action;
Begin
  Case State Of
    S_PLAY : Fire;
    S_PAUSE : TogglePause;
    S_OVER : NewGame;
  End;
End;

Procedure MoveAim(Dx, Dy : LongInt);
Begin
  MouseOn := 0;
  AimX := MaxX(4, MinX(BW - 5, AimX + Dx));
  AimY := MaxX(4, MinX(MaxAimY, AimY + Dy));
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And (KC_KEYUP Or KC_CTRL Or KC_ALT)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_PAUSE Then Begin TogglePause; Exit; End;
    If Vk = VK_LEFT Then Begin MoveAim(-12, 0); Exit; End;
    If Vk = VK_RIGHT Then Begin MoveAim(12, 0); Exit; End;
    If Vk = VK_UP Then Begin MoveAim(0, -12); Exit; End;
    If Vk = VK_DOWN Then Begin MoveAim(0, 12); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Action; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'P' : TogglePause;
      'N' : NewGame;
      ' ' : Action;
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
    If (Y >= 236) And (Y < 264) Then NewGame
    Else If (Y >= 270) And (Y < 298) Then TogglePause;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    AimX := X - OX; AimY := MinX(Y - OY, MaxAimY);
    Action;
  End;
End;

Function MainProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y : LongInt;
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
    WM_MOUSEMOVE :
      Begin
        X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
        If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) And (AutoAll = 0) Then
        Begin
          MouseOn := 1;
          AimX := X - OX; AimY := MinX(Y - OY, MaxAimY);
        End;
        MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
      End;
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
  Flg, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; NSpr := 0; NDirty := 0; Best := 0;
  Tick := 0; Client := 0; Frame := 0; SoundOn := 1; MouseOn := 0; StartLevel := 1; Level := 1; AutoCool := 0;
  SndCur := 0; SndEnd := 0; Score := 0; Ammo := 30; BatOk := 1; Killed := 0;
  For K := 0 To NCity - 1 Do
  Begin
    If K < 3 Then CityX[K] := 42 + K * 55 Else CityX[K] := BW - 42 - (5 - K) * 55;
    CityOk[K] := 1;
  End;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/LEVEL:') Then
    Begin
      Val(Copy(S, 8, 20), StartLevel, E);
      If StartLevel < 1 Then StartLevel := 1;
      If StartLevel > 30 Then StartLevel := 30;
    End;
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  MakeSounds;
  RenderBg;
  Dummy := WinRegisterClass(Hab, Z('MISSILE'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('MISSILE'), Z2('Commandement des missiles'), 0,
                              0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_PAUSE, '~Pause' + Chr(9) + 'P');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Commandement des missiles');
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
