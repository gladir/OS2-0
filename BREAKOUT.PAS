{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2022 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BREAKOUT - Casse-Brique pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau).
}

Program BREAKOUT;

{$R-,S-,I-}

{ Compilation : OS2PC BREAKOUT.PAS   (produit BREAKOUT.EXE)

  Portage vers OS/2-0 du prototype BREAKOUT.PAS du depot 7iles (mode
  texte de 40 colonnes : briques en caracteres, balle "o", raquette en
  espaces rouges, fleches ou 4 et 6) : fenetre de Presentation Manager
  avec menus, image en memoire (GpiDrawBits, seules les parties qui
  bougent sont recopiees), mur metallique, briques en relief, raquette
  chromee, balle lumineuse, eclats des briques, panneau du pointage,
  bruitages, barre d'etat et apparence d'OS/2.

  Regles du prototype : un mur de 6 rangees de 19 briques (deux rouges,
  une orange, deux vertes, une bleue) ; une brique des deux rangees du
  haut vaut 7 points, des trois suivantes 4 points, de la derniere 1
  point ; 5 balles ; un mur abattu rapporte une balle et un nouveau mur ;
  /FULLBALLS (balles illimitees) et /SHOWBRICKS (briques restantes).
  Ce qui est ajoute : la balle rebondit selon l'endroit ou elle touche la
  raquette, elle accelere au fil des coups, chaque nouveau mur commence
  un peu plus bas ; la souris ; le record de la seance.

  Clavier : fleches gauche et droite (ou 4 et 6, comme le prototype),
  Espace (lancer la balle), P (pause), F2 (nouvelle partie), F1 (regles).
  Souris : la raquette suit le pointeur, clic : lancer la balle.
  Parametres : /SEED:n ; /AUTO (demonstration) ; /FULLBALLS ;
  /SHOWBRICKS ; /NOSOUND. }

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
  CM_FULL = 201; CM_SHOW = 202; CM_SOUND = 203;
  CM_RULES = 301; CM_ABOUT = 302;
  BW = 456; BH = 400; OX = 8; OY = 8;
  PnX = 472; PW = 146;
  CWant = 624; CHWant = 436;
  MaxDirty = 160; MaxSpr = 120;
  WallL = 10; WallR = 446; WallT = 10;          { interieur : WallL..WallR-1 }
  NCol = 19; NRow = 6; BrW = 22; BrH = 14; BrX0 = 19; BrY0 = 52;
  PadW = 58; PadH = 10; PadY = 370; BallR = 4;
  MaxPart = 96;
  { couleurs de l'image }
  C_BG1 = 0; C_BG2 = 1; C_GRID = 2; C_MET = 3; C_METL = 4; C_METD = 5; C_WHITE = 6; C_BLACK = 7;
  C_RED = 8; C_REDL = 9; C_REDD = 10; C_ORA = 11; C_ORAL = 12; C_ORAD = 13; C_GRN = 14; C_GRNL = 15;
  C_GRND = 16; C_BLU = 17; C_BLUL = 18; C_BLUD = 19; C_PAD = 20; C_PADL = 21; C_PADD = 22; C_CAP = 23;
  C_BALL = 24; C_GLOW = 25; C_TRAIL = 26; C_BANNER = 27; C_BANNERE = 28; C_YELLOW = 29; C_GREEN = 30;
  C_SHADOW = 31;
  NPal = 32;
  Pal : Array[0..NPal - 1] Of LongInt = (
    $0A0F2C, $101A46, $1A2660, $8C96AA, $D2DCF0, $4B5568, $FFFFFF, $000000,
    $E02828, $FF7878, $901414, $F08C1E, $FFC878, $A0500A, $28B43C, $8CE696,
    $146E1E, $2850DC, $8CA0FF, $142878, $AAB4C8, $F0F5FF, $5A6478, $D22828,
    $FFFFFF, $A0DCFF, $3C6EB4, $14143C, $FFD23C, $FFE650, $50DC78, $05081A);
  S_SERVE = 1; S_PLAY = 2; S_LOST = 3; S_CLEAR = 4; S_OVER = 5; S_PAUSE = 6;
  SndRate = 11025;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back, Bg : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  DX1, DY1, DX2, DY2 : Array[0..MaxDirty - 1] Of LongInt;
  SX1, SY1, SX2, SY2 : Array[0..MaxSpr - 1] Of LongInt;
  NDirty, NSpr : LongInt;
  Brick : Array[0..NRow - 1, 0..NCol - 1] Of Byte;
  { balle (1/16 de pixel), raquette }
  BallX, BallY, VX, VY, Spd, BaseSpd, Hits, SpedOra, SpedRed : LongInt;
  PadX, PadTarget, MouseOn : LongInt;
  QX, QY, QVX, QVY, QLife, QCol : Array[0..MaxPart - 1] Of LongInt;
  TrX, TrY : Array[0..5] Of LongInt;
  Score, Best, Balls, Level, Bricks, WallOfs, Full, ShowBr, SoundOn : LongInt;
  State, Wait, Seed, AutoAll, Tick : LongInt;
  Banner, Banner2, Msg : String;
  BannerC : LongInt;
  { bruitages fabriques au demarrage (8 bits, 11025 Hz) }
  SndBuf : Array[0..39999] Of Byte;
  SndOfs, SndLen : Array[0..15] Of LongInt;
  NSndBuf : LongInt;
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
Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMPLAY';

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

{ ==================================================================== }
{ Bruitages                                                             }
{ ==================================================================== }

{ son N : frequence F1 vers F2 (Hz), duree Ms, onde carree adoucie }
Procedure MakeTone(N, F1, F2, Ms, Vol : LongInt);
Var K, Len, F, Ph, V, Env : LongInt;
Begin
  Len := SndRate * Ms Div 1000;
  If NSndBuf + Len > SizeOf(SndBuf) Then Exit;
  SndOfs[N] := NSndBuf; SndLen[N] := Len;
  Ph := 0;
  For K := 0 To Len - 1 Do
  Begin
    F := F1 + (F2 - F1) * K Div Len;
    Ph := (Ph + F * 65536 Div SndRate) And $FFFF;
    { enveloppe : attaque breve, puis decroissance }
    If K < 40 Then Env := K * 255 Div 40 Else Env := 255 * (Len - K) Div (Len - 40 + 1);
    If Ph < 32768 Then V := Vol Else V := -Vol;
    If (Ph < 2048) Or ((Ph >= 32768) And (Ph < 34816)) Then V := V Div 2;
    SndBuf[NSndBuf + K] := 128 + V * Env Div 255;
  End;
  NSndBuf := NSndBuf + Len;
End;

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  MakeTone(0, 220, 200, 45, 60);        { raquette }
  MakeTone(1, 160, 150, 30, 40);        { mur }
  MakeTone(2, 990, 990, 55, 50);        { brique rouge }
  MakeTone(3, 780, 780, 55, 50);        { brique orange }
  MakeTone(4, 620, 620, 55, 50);        { brique verte }
  MakeTone(5, 520, 520, 55, 50);        { brique bleue }
  MakeTone(6, 520, 90, 600, 70);        { balle perdue }
  MakeTone(7, 520, 1560, 700, 55);      { mur abattu }
End;

Procedure PlaySnd(N : LongInt);
Begin
  If SoundOn = 0 Then Exit;
  Dummy := MdmPlay(LongInt(@SndBuf[SndOfs[N]]), SndLen[N], SndRate, 8, 1);
End;

{ ==================================================================== }
{ Decor : fond, murs, briques                                           }
{ ==================================================================== }

Procedure RenderBg;
Var X, Y, C : LongInt;
Begin
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      { fond bleu nuit, degrade trame, quadrillage discret }
      If Y < 140 Then C := C_BG1
      Else If Y < 170 Then Begin If (X + Y) Mod 2 = 0 Then C := C_BG1 Else C := C_BG2; End
      Else C := C_BG2;
      If ((X - WallL) Mod 24 = 0) Or ((Y - WallT) Mod 24 = 0) Then
        If (X + Y) Mod 2 = 0 Then C := C_GRID;
      Fb[(BH - 1 - Y) * BW + X] := C;
    End;
  { murs metalliques avec rivets }
  Rect(0, 0, WallL - 1, BH - 1, C_MET);
  Rect(WallR, 0, BW - 1, BH - 1, C_MET);
  Rect(0, 0, BW - 1, WallT - 1, C_MET);
  Rect(0, 0, BW - 1, 1, C_METL); Rect(0, 0, 1, BH - 1, C_METL); Rect(WallR, WallT, WallR + 1, BH - 1, C_METL);
  Rect(WallL - 2, WallT, WallL - 1, BH - 1, C_METD); Rect(BW - 2, 0, BW - 1, BH - 1, C_METD);
  Rect(WallL, WallT - 2, WallR - 1, WallT - 1, C_METD);
  Y := 30;
  While Y < BH Do
  Begin
    FDisc(5, Y, 1, C_METD); Pix(4, Y - 1, C_METL);
    FDisc(BW - 6, Y, 1, C_METD); Pix(BW - 7, Y - 1, C_METL);
    Y := Y + 48;
  End;
  X := 30;
  While X < BW Do
  Begin
    FDisc(X, 5, 1, C_METD); Pix(X - 1, 4, C_METL);
    X := X + 48;
  End;
  Move(Fb, Bg, SizeOf(Fb));
End;

Procedure BrickCols(R : LongInt; Var C, L, D : LongInt);
Begin
  Case R Of
    0, 1 : Begin C := C_RED; L := C_REDL; D := C_REDD; End;
    2 : Begin C := C_ORA; L := C_ORAL; D := C_ORAD; End;
    3, 4 : Begin C := C_GRN; L := C_GRNL; D := C_GRND; End;
  Else
    Begin C := C_BLU; L := C_BLUL; D := C_BLUD; End;
  End;
End;

Function BrX(C : LongInt) : LongInt;
Begin
  BrX := BrX0 + C * BrW;
End;

Function BrY(R : LongInt) : LongInt;
Begin
  BrY := BrY0 + WallOfs + R * BrH;
End;

{ brique en relief (dans l'image) }
Procedure DrawBrick(R, C : LongInt);
Var X, Y, Cc, L, D : LongInt;
Begin
  BrickCols(R, Cc, L, D);
  X := BrX(C); Y := BrY(R);
  Rect(X + 1, Y + 1, X + BrW - 2, Y + BrH - 2, Cc);
  Rect(X + 1, Y + 1, X + BrW - 2, Y + 2, L);
  Rect(X + 1, Y + 1, X + 2, Y + BrH - 2, L);
  Rect(X + 1, Y + BrH - 3, X + BrW - 2, Y + BrH - 2, D);
  Rect(X + BrW - 3, Y + 1, X + BrW - 2, Y + BrH - 2, D);
  Rect(X + 5, Y + 4, X + 9, Y + 4, L);
  Rect(X, Y + BrH - 1, X + BrW - 1, Y + BrH - 1, C_SHADOW);
  Rect(X + BrW - 1, Y, X + BrW - 1, Y + BrH - 1, C_SHADOW);
End;

Procedure BuildWall;
Var R, C : LongInt;
Begin
  Move(Bg, Fb, SizeOf(Fb));
  For R := 0 To NRow - 1 Do
    For C := 0 To NCol - 1 Do
    Begin
      Brick[R, C] := 1;
      DrawBrick(R, C);
    End;
  Bricks := NRow * NCol;
  SaveBack;
  NDirty := 0;
  AddDirty(0, 0, BW - 1, BH - 1);
End;

{ brique cassee : le fond revient dans l'image fixe }
Procedure EraseBrick(R, C : LongInt);
Var X, Y, B, Yy : LongInt;
Begin
  X := BrX(C); Y := BrY(R);
  For Yy := Y To Y + BrH - 1 Do
  Begin
    B := (BH - 1 - Yy) * BW + X;
    Move(Bg[B], Back[B], BrW);
  End;
  RestoreRect(X, Y, X + BrW - 1, Y + BrH - 1);
  AddDirty(X, Y, X + BrW - 1, Y + BrH - 1);
End;

{ ==================================================================== }
{ Objets mobiles                                                        }
{ ==================================================================== }

Procedure DrawPaddle;
Var X1, X2 : LongInt;
Begin
  X1 := PadX - PadW Div 2; X2 := X1 + PadW - 1;
  Rect(X1 + 3, PadY + PadH, X2 + 3, PadY + PadH + 2, C_SHADOW);
  Rect(X1 + 6, PadY, X2 - 6, PadY + PadH - 1, C_PAD);
  Rect(X1 + 6, PadY + 1, X2 - 6, PadY + 2, C_PADL);
  Rect(X1 + 6, PadY + PadH - 2, X2 - 6, PadY + PadH - 1, C_PADD);
  { embouts rouges arrondis }
  Ell(X1 + 5, PadY + PadH Div 2, 5, PadH Div 2, C_CAP);
  Ell(X2 - 5, PadY + PadH Div 2, 5, PadH Div 2, C_CAP);
  Pix(X1 + 3, PadY + 2, C_REDL); Pix(X2 - 7, PadY + 2, C_REDL);
  SprRect(X1, PadY, X2 + 3, PadY + PadH + 2);
End;

Procedure DrawBall;
Var X, Y, K : LongInt;
Begin
  If (State = S_LOST) Or (State = S_OVER) Then Exit;
  For K := 5 DownTo 0 Do
    If (TrX[K] <> 0) And (State = S_PLAY) And (K Mod 2 = 1) Then
    Begin
      Pix(TrX[K], TrY[K], C_TRAIL);
      SprRect(TrX[K], TrY[K], TrX[K], TrY[K]);
    End;
  X := BallX Div 16; Y := BallY Div 16;
  FDisc(X, Y, BallR + 1, C_GLOW);
  FDisc(X, Y, BallR, C_BALL);
  Pix(X - 1, Y - 2, C_GLOW); Pix(X + 1, Y + 1, C_GLOW);
  SprRect(X - BallR - 2, Y - BallR - 2, X + BallR + 2, Y + BallR + 2);
End;

Procedure BannerDraw;
Var W, X, Y : LongInt;
Begin
  If Banner = '' Then Exit;
  W := Length(Banner) * 16;
  If Length(Banner2) * 8 > W Then W := Length(Banner2) * 8;
  W := W + 28;
  X := (BW - W) Div 2; Y := 200;
  Rect(X, Y, X + W - 1, Y + 58, C_BANNER);
  Rect(X, Y, X + W - 1, Y, C_BANNERE); Rect(X, Y + 58, X + W - 1, Y + 58, C_BANNERE);
  Rect(X, Y, X, Y + 58, C_BANNERE); Rect(X + W - 1, Y, X + W - 1, Y + 58, C_BANNERE);
  FbTextSh(X + (W - Length(Banner) * 16) Div 2, Y + 6, Banner, BannerC, C_BLACK, 2);
  FbText(X + (W - Length(Banner2) * 8) Div 2, Y + 38, Banner2, C_WHITE, 1);
  SprRect(X, Y, X + W - 1, Y + 58);
End;

Procedure DrawSprites;
Var K, X, Y : LongInt;
Begin
  SprBegin;
  For K := 0 To MaxPart - 1 Do
    If QLife[K] > 0 Then
    Begin
      X := QX[K] Div 16; Y := QY[K] Div 16;
      Rect(X, Y, X + 1, Y + 1, QCol[K]);
      SprRect(X, Y, X + 1, Y + 1);
    End;
  DrawPaddle;
  DrawBall;
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

Procedure DrawCounters;
Var S : String; K : LongInt;
Begin
  FBar(PnX + 2, 86, PnX + PW - 3, 120, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 87, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 128, PnX + PW - 1, 218, CLR_PALEGRAY);
  OutTxt(PnX, 128, 'Niveau : ' + IStr(Level), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 148, 'Balles :', CLR_BLACK, CLR_PALEGRAY);
  If Full <> 0 Then OutTxt(PnX + 72, 148, 'illimit' + Chr(130) + 'es', CLR_DARKRED, CLR_PALEGRAY)
  Else
    For K := 0 To MinX(Balls, 7) - 1 Do
    Begin
      Disc(PnX + 76 + K * 10, 157, 4, CLR_DARKBLUE);
      Disc(PnX + 75 + K * 10, 156, 1, CLR_WHITE);
    End;
  If ShowBr <> 0 Then OutTxt(PnX, 168, 'Briques : ' + IStr(Bricks), CLR_BLACK, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 188, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 5 * 16) Div 2, 0, 'CASSE', CLR_DARKRED, CLR_PALEGRAY);
  BigText(PnX + (PW - 6 * 16) Div 2, 28, 'BRIQUE', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 64, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 82, PnX + PW - 1, 124, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 83, PnX + PW - 2, 123, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 84, PnX + PW - 3, 122, CLR_WHITE);
  DrawCounters;
  Button(PnX, 226, PW, 28, 'Nouvelle partie');
  Button(PnX, 260, PW, 28, 'Pause');
  OutTxt(PnX, 302, Chr(27) + ' ' + Chr(26) + ' : raquette', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 318, 'ou la souris', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 334, 'Espace : lancer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 350, 'P : pause', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 366, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
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
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
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

Procedure PlayMsg;
Begin
  Msg := Chr(27) + ' ' + Chr(26) + ' ou la souris : raquette ; Espace ou clic : lancer la balle.';
End;

Procedure Burst(X, Y, N, C1, C2 : LongInt);
Var K, M : LongInt;
Begin
  M := 0;
  For K := 0 To MaxPart - 1 Do
    If (QLife[K] <= 0) And (M < N) Then
    Begin
      QX[K] := X * 16; QY[K] := Y * 16;
      QVX[K] := Rnd(49) - 24; QVY[K] := Rnd(41) - 28;
      QLife[K] := 10 + Rnd(14);
      If Rnd(2) = 0 Then QCol[K] := C1 Else QCol[K] := C2;
      Inc(M);
    End;
End;

{ balle posee sur la raquette }
Procedure Serve;
Var K : LongInt;
Begin
  State := S_SERVE;
  Spd := BaseSpd; Hits := 0; SpedOra := 0; SpedRed := 0;
  BallX := PadX * 16; BallY := (PadY - BallR - 1) * 16;
  For K := 0 To 5 Do TrX[K] := 0;
  PlayMsg;
End;

Procedure Launch;
Var A : Real;
Begin
  If State <> S_SERVE Then Exit;
  A := (Rnd(41) - 20) * Pi / 180;
  VX := Round(Spd * Sin(A)); VY := -Round(Spd * Cos(A));
  State := S_PLAY; Banner := '';
  Msg := 'Abattez le mur !';
End;

Procedure NewLevel;
Begin
  WallOfs := MinX((Level - 1) * 8, 56);
  BaseSpd := MinX(72 + (Level - 1) * 6, 112);
  BuildWall;
  Serve;
  Show('Niveau ' + IStr(Level), 'Espace ou clic : lancer la balle', C_YELLOW);
  Redraw;
End;

Procedure NewGame;
Var K : LongInt;
Begin
  For K := 0 To MaxPart - 1 Do QLife[K] := 0;
  Score := 0; Level := 1;
  If Full <> 0 Then Balls := 30000 Else Balls := 5;
  PadX := (WallL + WallR) Div 2; PadTarget := PadX;
  NewLevel;
End;

Procedure GameOver;
Begin
  State := S_OVER;
  If Score > Best Then Best := Score;
  Show('Partie termin' + Chr(130) + 'e', 'Pointage : ' + IStr(Score) + '   F2 : nouvelle partie', C_RED);
  Msg := 'Partie termin' + Chr(130) + 'e. Pointage : ' + IStr(Score) + '. F2 : nouvelle partie.';
  Wait := 0;
  Redraw;
End;

Procedure LoseBall;
Begin
  PlaySnd(6);
  State := S_LOST; Wait := 0;
  If Full = 0 Then Dec(Balls);
  If Balls <= 0 Then
  Begin
    Balls := 0;
    GameOver;
    Exit;
  End;
  Show('Balle perdue !', 'Il reste ' + IStr(Balls) + ' balle(s)', C_RED);
  Msg := 'Balle perdue !';
End;

{ direction de la balle selon l'endroit ou elle touche la raquette }
Procedure PaddleBounce;
Var Rel : LongInt; A : Real;
Begin
  Rel := (BallX Div 16 - PadX) * 100 Div (PadW Div 2 + BallR);
  If Rel > 100 Then Rel := 100;
  If Rel < -100 Then Rel := -100;
  A := Rel * 60 / 100 * Pi / 180;
  Inc(Hits);
  If (Hits = 4) Or (Hits = 12) Then Spd := Spd + 8;
  VX := Round(Spd * Sin(A)); VY := -Round(Spd * Cos(A));
  If VY > -12 Then VY := -12;
  BallY := (PadY - BallR - 1) * 16;
  PlaySnd(0);
End;

{ brique touchee par la balle (centre X, Y en pixels) ; rebond }
Function HitBricks(X, Y, Px, Py : LongInt) : Boolean;
Var R, C, R1, R2, C1, C2, Bx, By, Pts, Cc, L, D : LongInt;
Begin
  HitBricks := False;
  R1 := (Y - BallR - BrY0 - WallOfs) Div BrH; R2 := (Y + BallR - BrY0 - WallOfs) Div BrH;
  C1 := (X - BallR - BrX0) Div BrW; C2 := (X + BallR - BrX0) Div BrW;
  If (Y + BallR < BrY0 + WallOfs) Or (Y - BallR >= BrY0 + WallOfs + NRow * BrH) Then Exit;
  For R := MaxX(R1, 0) To MinX(R2, NRow - 1) Do
    For C := MaxX(C1, 0) To MinX(C2, NCol - 1) Do
      If (Brick[R, C] <> 0) And Not HitBricks Then
      Begin
        Brick[R, C] := 0;
        Dec(Bricks);
        EraseBrick(R, C);
        Case R Of
          0, 1 : Pts := 7;
          2, 3, 4 : Pts := 4;
        Else
          Pts := 1;
        End;
        Score := Score + Pts;
        BrickCols(R, Cc, L, D);
        Bx := BrX(C); By := BrY(R);
        Burst(Bx + BrW Div 2, By + BrH Div 2, 10, Cc, L);
        If R <= 1 Then PlaySnd(2) Else If R = 2 Then PlaySnd(3) Else If R <= 4 Then PlaySnd(4) Else PlaySnd(5);
        { la balle accelere en atteignant les rangees orange et rouges }
        If (R = 2) And (SpedOra = 0) Then Begin SpedOra := 1; Spd := Spd + 8; End;
        If (R <= 1) And (SpedRed = 0) Then Begin SpedRed := 1; Spd := Spd + 8; End;
        { rebond : sur le cote ou sur le dessus/dessous }
        If (Px + BallR <= Bx) Or (Px - BallR >= Bx + BrW) Then VX := -VX Else VY := -VY;
        HitBricks := True;
      End;
End;

Procedure ScaleSpeed;
Var L : Real;
Begin
  L := Sqrt(VX * 1.0 * VX + VY * 1.0 * VY);
  If L < 1 Then Exit;
  VX := Round(VX * Spd / L); VY := Round(VY * Spd / L);
  If Abs(VY) < 10 Then If VY < 0 Then VY := -10 Else VY := 10;
End;

Procedure MoveBall;
Var N, K, X, Y, Px, Py : LongInt;
Begin
  N := (Spd + 23) Div 24;
  If N < 1 Then N := 1;
  For K := 1 To N Do
  Begin
    Px := BallX Div 16; Py := BallY Div 16;
    BallX := BallX + VX Div N; BallY := BallY + VY Div N;
    X := BallX Div 16; Y := BallY Div 16;
    { murs }
    If X - BallR < WallL Then Begin BallX := (WallL + BallR) * 16; VX := Abs(VX); PlaySnd(1); End;
    If X + BallR >= WallR Then Begin BallX := (WallR - BallR - 1) * 16; VX := -Abs(VX); PlaySnd(1); End;
    If Y - BallR < WallT Then Begin BallY := (WallT + BallR) * 16; VY := Abs(VY); PlaySnd(1); End;
    X := BallX Div 16; Y := BallY Div 16;
    { raquette }
    If (VY > 0) And (Y + BallR >= PadY) And (Py + BallR < PadY + 4) And
       (X >= PadX - PadW Div 2 - BallR) And (X <= PadX + PadW Div 2 + BallR) Then PaddleBounce
    Else If HitBricks(X, Y, Px, Py) Then
    Begin
      ScaleSpeed;
      If Bricks = 0 Then
      Begin
        PlaySnd(7);
        State := S_CLEAR; Wait := 0;
        Inc(Balls);
        Show('Mur abattu !', 'Une balle de plus. Niveau suivant...', C_GREEN);
        Msg := 'Mur abattu : une balle de plus !';
        Exit;
      End;
    End;
    If Y - BallR > BH Then
    Begin
      LoseBall;
      Exit;
    End;
  End;
  For K := 5 DownTo 1 Do Begin TrX[K] := TrX[K - 1]; TrY[K] := TrY[K - 1]; End;
  TrX[0] := BallX Div 16; TrY[0] := BallY Div 16;
End;

Procedure MovePaddle;
Var D, Lo, Hi : LongInt;
Begin
  Lo := WallL + PadW Div 2; Hi := WallR - 1 - PadW Div 2;
  If PadTarget < Lo Then PadTarget := Lo;
  If PadTarget > Hi Then PadTarget := Hi;
  D := PadTarget - PadX;
  If D > 14 Then D := 14;
  If D < -14 Then D := -14;
  PadX := PadX + D;
  If State = S_SERVE Then BallX := PadX * 16;
End;

{ demonstration : la raquette suit la balle }
Procedure AutoPlay;
Begin
  If State = S_SERVE Then
  Begin
    Inc(Wait);
    If Wait > 25 Then Begin Wait := 0; Launch; End;
  End
  Else PadTarget := BallX Div 16 + ((BallX Div 16 * 7) Mod 23) - 11;
End;

Procedure Step;
Var K : LongInt;
Begin
  Inc(Tick);
  For K := 0 To MaxPart - 1 Do
    If QLife[K] > 0 Then
    Begin
      Dec(QLife[K]);
      QX[K] := QX[K] + QVX[K]; QY[K] := QY[K] + QVY[K];
      QVY[K] := QVY[K] + 3;
    End;
  If AutoAll <> 0 Then AutoPlay;
  If (State = S_SERVE) Or (State = S_PLAY) Then MovePaddle;
  If State = S_PLAY Then MoveBall;
End;

Procedure TimerTick;
Var C : Boolean;
Begin
  If State = S_PAUSE Then Exit;
  C := False;
  Step;
  Case State Of
    S_LOST :
      Begin
        Inc(Wait);
        If Wait > 45 Then
        Begin
          Banner := '';
          Serve;
          C := True;
        End;
      End;
    S_CLEAR :
      Begin
        Inc(Wait);
        If Wait > 60 Then
        Begin
          Inc(Level);
          NewLevel;
          Exit;
        End;
      End;
    S_OVER :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait > 80 Then NewGame;
      End;
  End;
  If Tick Mod 5 = 0 Then C := True;
  Frame1(C);
End;

Procedure TogglePause;
Begin
  If (State = S_PLAY) Or (State = S_SERVE) Then
  Begin
    Wait := State;
    State := S_PAUSE;
    Show('Pause', 'P ou Espace : reprendre', C_GREEN);
    Msg := 'Pause.';
    Frame1(True);
  End
  Else If State = S_PAUSE Then
  Begin
    State := Wait; Wait := 0; Banner := '';
    PlayMsg;
    Frame1(True);
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
  SetMark(CM_FULL, Full <> 0); SetMark(CM_SHOW, ShowBr <> 0); SetMark(CM_SOUND, SoundOn <> 0);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PAUSE : TogglePause;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_FULL :
      Begin
        If Full <> 0 Then Full := 0 Else Full := 1;
        SetMarks;
        NewGame;
      End;
    CM_SHOW :
      Begin
        If ShowBr <> 0 Then ShowBr := 0 Else ShowBr := 1;
        SetMarks;
        Redraw;
      End;
    CM_SOUND :
      Begin
        If SoundOn <> 0 Then SoundOn := 0 Else SoundOn := 1;
        SetMarks;
      End;
    CM_RULES :
      Begin
        If State = S_PLAY Then TogglePause;
        LClr;
        LAdd('Renvoyez la balle avec la raquette pour abattre le mur de briques. Une brique des deux ' +
             'rang' + Chr(130) + 'es rouges vaut 7 points, de la rang' + Chr(130) + 'e orange et des deux ' +
             'vertes 4 points, de la bleue 1 point.' + Chr(10) + Chr(10));
        LAdd('La balle part selon l''endroit o' + Chr(151) + ' elle touche la raquette (au bord : en biais) ' +
             'et acc' + Chr(130) + 'l' + Chr(138) + 're au fil des coups. ');
        LAdd('Cinq balles ; un mur abattu rapporte une balle de plus et un nouveau mur, un peu plus bas.' +
             Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches (ou 4 et 6), Espace (lancer), P (pause), F2 (nouvelle partie). ' +
             'Souris : la raquette suit le pointeur, clic : lancer. Menu Options : balles illimit' + Chr(130) +
             'es, briques restantes, son.');
        Dummy := LMsgBox('Casse-Brique - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Casse-Brique pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du ' +
                            'prototype BREAKOUT.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en ' +
                            'Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos de Casse-Brique',
                            MB_OK Or MB_INFORMATION);
  End;
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
    If Vk = VK_LEFT Then Begin MouseOn := 0; PadTarget := PadX - 28; Exit; End;
    If Vk = VK_RIGHT Then Begin MouseOn := 0; PadTarget := PadX + 28; Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_UP) Then
    Begin
      If State = S_SERVE Then Launch
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
      '4' : PadTarget := PadX - 28;
      '6' : PadTarget := PadX + 28;
      ' ' : If State = S_SERVE Then Launch Else If State = S_PAUSE Then TogglePause;
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
    If (Y >= 226) And (Y < 254) Then NewGame
    Else If (Y >= 260) And (Y < 288) Then TogglePause;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If State = S_SERVE Then Launch
    Else If State = S_PAUSE Then TogglePause
    Else If State = S_OVER Then NewGame;
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
        If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
        Begin
          MouseOn := 1;
          PadTarget := X - OX;
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
  Msg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; NSpr := 0; NDirty := 0; Best := 0; Tick := 0;
  Client := 0; Frame := 0; Full := 0; ShowBr := 0; SoundOn := 1; MouseOn := 0; State := S_SERVE;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/FULLBALLS' Then Full := 1;
    If S = '/SHOWBRICKS' Then ShowBr := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  MakeSounds;
  For K := 0 To MaxPart - 1 Do QLife[K] := 0;
  RenderBg;
  Dummy := WinRegisterClass(Hab, Z('BREAKOUT'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('BREAKOUT'), Z2('Casse-Brique'), 0, 0, 0,
                              LongInt(@Client));
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
  MItem(MIS_TEXT, 0, CM_FULL, '~Balles illimit' + Chr(130) + 'es');
  MItem(MIS_TEXT, 0, CM_SHOW, '~Afficher les briques restantes');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 3);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Casse-Brique');
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
