{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: INVADERS - Invasion de l'espace pour le Presentation
                Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program INVADERS;

{$R-,S-,I-}

{ Compilation : OS2PC INVADERS.PAS   (produit INVADERS.EXE)

  Portage vers OS/2-0 du prototype INVADERS.PAS du depot 7iles (Turbo
  Pascal et BGI en noir et blanc, dessins de 24 x 17 points, titre en
  caracteres, fleches et Espace) : fenetre de Presentation Manager avec
  menus, image en memoire (GpiDrawBits, seules les parties qui bougent
  sont recopiees), ciel etoile, envahisseurs en couleur (les dessins du
  prototype, avec relief et ombre), abris qui s'effritent au point pres,
  canon, vaisseau mere, explosions, ecran titre avec la table des
  pointages, panneau du pointage, bruitages (tirs, explosions, marche des
  envahisseurs qui s'accelere), barre d'etat et apparence d'OS/2.

  Regles du prototype : 5 rangees de 12 envahisseurs qui se deplacent
  ensemble et descendent a chaque bord ; ils tirent ; 40, 30, 20 et 10
  points selon la sorte, 100 points pour le vaisseau mere ; 3 canons ;
  un tableau termine rapporte un canon ; quatre abris ; les envahisseurs
  qui arrivent en bas terminent la partie.
  Ce qui est ajoute : la marche s'accelere quand il reste peu
  d'envahisseurs, chaque tableau commence plus bas, les abris s'abiment
  au point pres, un tir peut detruire une bombe, la souris, le record de
  la seance, une demonstration.

  Clavier : fleches gauche et droite (ou 4 et 6), Espace ou fleche haut
  (tirer), P (pause), F2 (nouvelle partie), F1 (regles).
  Souris : le canon suit le pointeur, clic : tirer.
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
  MaxDirty = 160; MaxSpr = 120;
  NRow = 5; NCol = 12; ColW = 32; RowH = 26; SprW = 24; SprH = 16;
  GunY = 352; GroundY = 374; UfoY = 30;
  NBunk = 4; BkW = 44; BkH = 26; BunkY = 296;
  MaxShot = 3; MaxBomb = 8; MaxExp = 16;
  { dessins du prototype (24 x 16 points, un bit par point, ligne par ligne) :
    0-7 envahisseurs (4 sortes, 2 poses), 8 vaisseau mere, 9 canon,
    10-11 explosion }
  NSprD = 192;
  SprD : Array[0..NSprD - 1] Of LongInt = (
    $080010, $140028, $020040, $013C80, $63FFC6, $6718E6, $6F9CF6, $6F18F6,
    $7FE7FE, $3FC3FC, $07C3E0, $03E7C0, $033CC0, $060060, $3C003C, $000000,
    $018180, $020040, $020040, $013C80, $03FFC0, $07FFE0, $0718F0, $0F39F0,
    $3F18FC, $7FE7FE, $67E7E6, $63FFC6, $63FFC6, $6300C6, $018180, $000000,
    $002400, $187E18, $3CFF3C, $66FF66, $66FF66, $3FFFFC, $1CFF38, $00C300,
    $004200, $004200, $01DB80, $07FFE0, $1CC338, $31818C, $6300C6, $000000,
    $002400, $006600, $00FF00, $18FF18, $3CFF3C, $7EFF7E, $66FF66, $3FFFFC,
    $1CFF38, $006600, $01E780, $03FFC0, $062460, $0C6630, $084210, $000000,
    $041820, $061860, $0718E0, $0599A0, $07FFE0, $3F99FC, $7FDBFE, $C7FFE3,
    $86FF61, $CCC333, $0C5A30, $0C3C30, $0C1830, $181818, $3C003C, $000000,
    $C43C23, $861861, $C718E3, $7D99BE, $3FFFFC, $033CC0, $0399C0, $07FFE0,
    $06C360, $0CFF30, $0CFF30, $0C3C30, $0C1830, $060060, $0F00F0, $000000,
    $000000, $00C300, $01E780, $03FFC0, $0318C0, $075AE0, $1FFFF8, $7781EE,
    $6399C6, $63FFC6, $673CE6, $661866, $0700E0, $03E7C0, $01E780, $000000,
    $000000, $60C306, $61E786, $63FFC6, $635AC6, $7718EE, $1FFFF8, $07C3E0,
    $03FFC0, $03FFC0, $073CE0, $060060, $0E0070, $7C003E, $78001E, $000000,
    $003C00, $004200, $008100, $010080, $020040, $3EA57C, $FFFFFF, $0C4610,
    $0DDAD0, $0DDA10, $0DDAF0, $0446E0, $03FFC0, $000000, $000000, $000000,
    $001800, $001800, $001800, $001800, $003C00, $007E00, $00DB00, $01DB80,
    $075AE0, $0D5AB0, $3D5ABC, $BEFF7D, $BFFFFD, $FF81FF, $8300C1, $0300C0,
    $000008, $008A00, $000400, $037100, $01E7C0, $01F9C0, $073B80, $11CE80,
    $00E700, $0B39D4, $0018A0, $0510A0, $2C0080, $A00000, $200000, $724210,
    $000008, $092000, $244852, $828010, $010295, $104852, $420008, $00C03B,
    $1010DC, $034211, $40004A, $122089, $00800A, $094448, $422002, $041090);
  { couleurs de l'image }
  C_SPACE = 0; C_SPACE2 = 1; C_STAR1 = 2; C_STAR2 = 3; C_STAR3 = 4; C_GROUND = 5; C_GROUNDD = 6;
  C_BUNK = 7; C_BUNKD = 8; C_A1 = 9; C_A1L = 10; C_A2 = 11; C_A2L = 12; C_A3 = 13; C_A3L = 14; C_A4 = 15;
  C_A4L = 16; C_SHADOW = 17; C_GUN = 18; C_GUNL = 19; C_GUND = 20; C_GUNC = 21; C_SHOT = 22; C_SHOTG = 23;
  C_BOMB = 24; C_BOMBL = 25; C_UFO = 26; C_UFOL = 27; C_EXP1 = 28; C_EXP2 = 29; C_EXP3 = 30;
  C_BANNER = 31; C_BANNERE = 32; C_WHITE = 33; C_BLACK = 34; C_YELLOW = 35; C_RED = 36; C_GREEN = 37;
  C_PLANET = 38; C_NEB = 39; C_PLANETL = 40;
  NPal = 41;
  Pal : Array[0..NPal - 1] Of LongInt = (
    $04061A, $080C28, $4B5568, $A0AAC0, $FFFFFF, $32B446, $145A1E, $E68C28,
    $8C4B14, $E650DC, $FFAAFF, $3CC8F0, $B4F0FF, $64E650, $C8FFB4, $F0D23C,
    $FFF5AA, $000000, $C8CDD7, $FFFFFF, $6E7387, $50C8FF, $FFFFC8, $78B4FF,
    $FF5A3C, $FFC864, $E62828, $FF9696, $FFFADC, $FFC83C, $FF6E1E, $14143C,
    $FFD23C, $FFFFFF, $000000, $FFE650, $FF5050, $50DC78, $1E2D64, $120C2E, $3C5AA0);
  S_TITLE = 0; S_PLAY = 1; S_HIT = 2; S_CLEAR = 3; S_OVER = 4; S_PAUSE = 5;
  SndRate = 11025;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back, Bg : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  DX1, DY1, DX2, DY2 : Array[0..MaxDirty - 1] Of LongInt;
  SX1, SY1, SX2, SY2 : Array[0..MaxSpr - 1] Of LongInt;
  NDirty, NSpr : LongInt;
  { envahisseurs : la formation (FX, FY : coin de la premiere colonne) }
  Alive : Array[0..NRow - 1, 0..NCol - 1] Of Byte;
  FX, FY, FDir, FPose, StepWait, NAlive, MarchNo : LongInt;
  OldX1, OldY1, OldX2, OldY2 : LongInt;
  { abris : un octet par point }
  Bunk : Array[0..NBunk - 1, 0..BkH - 1, 0..BkW - 1] Of Byte;
  BkX : Array[0..NBunk - 1] Of LongInt;
  { canon, tirs, bombes, vaisseau mere, explosions }
  GunX, GunT, MouseOn, FireCool : LongInt;
  ShX, ShY, ShOn : Array[0..MaxShot - 1] Of LongInt;
  BmX, BmY, BmOn : Array[0..MaxBomb - 1] Of LongInt;
  UfoOn, UfoX, UfoDir, UfoWait : LongInt;
  ExX, ExY, ExT, ExC, ExK : Array[0..MaxExp - 1] Of LongInt;
  Score, Best, Lives, Level, StartLevel : LongInt;
  State, Wait, Seed, AutoAll, Tick, OldState : LongInt;
  Banner, Banner2, Msg : String;
  BannerC : LongInt;
  LastSig : LongInt;
  LastMsg : String;
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
  SndPrio := 1; MakeTone(0, 1250, 380, 95, 40);         { tir du canon }
  SndPrio := 2; MakeNoise(1, 190, 100, 3);               { envahisseur touche }
  SndPrio := 5; MakeNoise(2, 950, 120, 9);               { canon detruit }
  SndPrio := 0; MakeTone(3, 820, 1020, 110, 30);         { vaisseau mere }
  SndPrio := 3; MakeTone(4, 1600, 240, 520, 50);         { vaisseau mere touche }
  SndPrio := 0; MakeTone(5, 98, 98, 70, 70);             { marche des envahisseurs }
  SndPrio := 0; MakeTone(6, 87, 87, 70, 70);
  SndPrio := 0; MakeTone(7, 78, 78, 70, 70);
  SndPrio := 0; MakeTone(8, 73, 73, 70, 70);
  SndPrio := 4; MakeTone(9, 400, 1600, 700, 50);         { tableau termine }
  SndPrio := 1; MakeNoise(10, 60, 70, 2);                { bombe sur un abri }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Dessins                                                               }
{ ==================================================================== }

Procedure PutB(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Back[(BH - 1 - Y) * BW + X] := C;
End;

Function SprBit(N, R, B : LongInt) : Boolean;
Begin
  If (R < 0) Or (R >= SprH) Or (B < 0) Or (B >= SprW) Then SprBit := False
  Else SprBit := ((SprD[N * 16 + R] Shr (23 - B)) And 1) <> 0;
End;

{ dessin N du prototype en (X, Y) : ombre, couleur C, bord superieur L ;
  dans l'image affichee (ToBack faux) ou dans le fond fixe }
Procedure DrawSpr(N, X, Y, C, L : LongInt; ToBack : Boolean);
Var R, B : LongInt;
Begin
  For R := 0 To SprH - 1 Do
    For B := 0 To SprW - 1 Do
      If SprBit(N, R, B) Then
      Begin
        If Not SprBit(N, R + 1, B + 1) Then
          If ToBack Then PutB(X + B + 1, Y + R + 1, C_SHADOW) Else Pix(X + B + 1, Y + R + 1, C_SHADOW);
      End;
  For R := 0 To SprH - 1 Do
    For B := 0 To SprW - 1 Do
      If SprBit(N, R, B) Then
      Begin
        If SprBit(N, R - 1, B) Then
        Begin
          If ToBack Then PutB(X + B, Y + R, C) Else Pix(X + B, Y + R, C);
        End
        Else If ToBack Then PutB(X + B, Y + R, L) Else Pix(X + B, Y + R, L);
      End;
End;

{ texte agrandi Sc fois dans l'image }
Procedure BigFb(X, Y : LongInt; S : String; C, Sh, Sc : LongInt);
Var I, R, K, B, P : LongInt;
Begin
  If FontH = 0 Then Exit;
  For P := 1 DownTo 0 Do
    For I := 1 To Length(S) Do
      For R := 0 To FontH - 1 Do
      Begin
        B := Font[Ord(S[I]) * FontH + R];
        For K := 0 To 7 Do
          If (B And ($80 Shr K)) <> 0 Then
          Begin
            If P = 1 Then Rect(X + (I - 1) * 8 * Sc + K * Sc + 2, Y + R * Sc + 2, X + (I - 1) * 8 * Sc + K * Sc + Sc + 1,
                               Y + R * Sc + Sc + 1, Sh)
            Else Rect(X + (I - 1) * 8 * Sc + K * Sc, Y + R * Sc, X + (I - 1) * 8 * Sc + K * Sc + Sc - 1,
                      Y + R * Sc + Sc - 1, C);
          End;
      End;
End;

Procedure AlienCols(Row : LongInt; Var C, L, N : LongInt);
Begin
  Case Row Of
    0 : Begin C := C_A1; L := C_A1L; N := 0; End;
    1 : Begin C := C_A2; L := C_A2L; N := 2; End;
    2 : Begin C := C_A3; L := C_A3L; N := 4; End;
  Else
    Begin C := C_A4; L := C_A4L; N := 6; End;
  End;
End;

{ points d'un envahisseur (prototype : 40, 30, 20, 10) }
Function AlienPts(Row : LongInt) : LongInt;
Begin
  Case Row Of
    0 : AlienPts := 40;
    1 : AlienPts := 30;
    2 : AlienPts := 20;
  Else
    AlienPts := 10;
  End;
End;

{ ciel etoile, nebuleuse, planete et sol }
Procedure RenderBg;
Var X, Y, C, K, D : LongInt;
Begin
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      If Y < 200 Then C := C_SPACE
      Else If Y < 240 Then Begin If (X + Y) Mod 2 = 0 Then C := C_SPACE Else C := C_SPACE2; End
      Else C := C_SPACE2;
      D := Sqr(X - 360) + Sqr((Y - 120) * 2);
      If D < 5200 Then If (X * 3 + Y) Mod 4 <> 0 Then C := C_NEB;
      Fb[(BH - 1 - Y) * BW + X] := C;
    End;
  { planete au loin }
  For Y := 66 To 118 Do
    For X := 44 To 96 Do
      If Sqr(X - 70) + Sqr(Y - 92) <= 26 * 26 Then
      Begin
        If Sqr(X - 60) + Sqr(Y - 82) <= 22 * 22 Then C := C_PLANETL Else C := C_PLANET;
        If (Y Mod 6 = 0) And (C = C_PLANETL) Then C := C_PLANET;
        Pix(X, Y, C);
      End;
  For K := -34 To 34 Do
    If (Abs(K) > 20) Or (K > 0) Then Pix(70 + K, 96 - K Div 4, C_STAR2);
  { etoiles }
  For K := 1 To 150 Do
  Begin
    X := Rnd(BW); Y := Rnd(GroundY - 4);
    Case Rnd(6) Of
      0 : C := C_STAR3;
      1, 2 : C := C_STAR2;
    Else
      C := C_STAR1;
    End;
    Pix(X, Y, C);
    If C = C_STAR3 Then Begin Pix(X - 1, Y, C_STAR1); Pix(X + 1, Y, C_STAR1); End;
  End;
  { sol }
  Rect(0, GroundY, BW - 1, GroundY + 1, C_GROUND);
  Rect(0, GroundY + 2, BW - 1, BH - 1, C_GROUNDD);
  For X := 0 To BW - 1 Do If X Mod 7 = 0 Then Pix(X, GroundY + 3 + (X Div 7) Mod 5, C_GROUND);
  Move(Fb, Bg, SizeOf(Fb));
End;

{ ==================================================================== }
{ Abris                                                                 }
{ ==================================================================== }

Procedure BunkPix(K, R, C : LongInt);
Var X, Y, Cc : LongInt;
Begin
  X := BkX[K] + C; Y := BunkY + R;
  If Bunk[K, R, C] = 0 Then Cc := Bg[(BH - 1 - Y) * BW + X]
  Else If (R = 0) Or (Bunk[K, MaxX(R - 1, 0), C] = 0) Then Cc := C_YELLOW
  Else If (X + Y * 3) Mod 5 = 0 Then Cc := C_BUNKD
  Else Cc := C_BUNK;
  Back[(BH - 1 - Y) * BW + X] := Cc;
End;

Procedure BuildBunkers;
Var K, R, C, Dx, Dy : LongInt;
Begin
  For K := 0 To NBunk - 1 Do
  Begin
    BkX[K] := (BW * (K + 1)) Div (NBunk + 1) - BkW Div 2;
    For R := 0 To BkH - 1 Do
      For C := 0 To BkW - 1 Do
      Begin
        Bunk[K, R, C] := 1;
        { coins du haut arrondis }
        If R < 8 Then
        Begin
          Dx := MinX(C, BkW - 1 - C);
          If Dx < 8 Then If Sqr(8 - Dx) + Sqr(8 - R) > 64 Then Bunk[K, R, C] := 0;
        End;
        { porte en arche en bas }
        Dx := Abs(2 * C - (BkW - 1));
        Dy := BkH - R;
        If (Dx < 22) And (Sqr(Dx) + Sqr(Dy * 2) * 2 < 22 * 22 * 2) And (R > 12) Then Bunk[K, R, C] := 0;
      End;
  End;
End;

Procedure DrawBunkers;
Var K, R, C : LongInt;
Begin
  For K := 0 To NBunk - 1 Do
    For R := 0 To BkH - 1 Do
      For C := 0 To BkW - 1 Do BunkPix(K, R, C);
End;

{ point (X, Y) dans un abri ? (K : l'abri) }
Function BunkAt(X, Y : LongInt; Var K : LongInt) : Boolean;
Var I : LongInt;
Begin
  BunkAt := False;
  If (Y < BunkY) Or (Y >= BunkY + BkH) Then Exit;
  For I := 0 To NBunk - 1 Do
    If (X >= BkX[I]) And (X < BkX[I] + BkW) Then
      If Bunk[I, Y - BunkY, X - BkX[I]] <> 0 Then
      Begin
        K := I;
        BunkAt := True;
        Exit;
      End;
End;

{ un tir ou une bombe abime l'abri autour de (X, Y) }
Procedure Erode(K, X, Y, Rad : LongInt);
Var R, C, Cx, Cy : LongInt;
Begin
  Cx := X - BkX[K]; Cy := Y - BunkY;
  For R := MaxX(Cy - Rad - 1, 0) To MinX(Cy + Rad + 1, BkH - 1) Do
    For C := MaxX(Cx - Rad, 0) To MinX(Cx + Rad, BkW - 1) Do
      If Bunk[K, R, C] <> 0 Then
        If Sqr(C - Cx) + Sqr(R - Cy) <= Rad * Rad + Rnd(Rad * 2 + 1) - Rad Then Bunk[K, R, C] := 0;
  For R := MaxX(Cy - Rad - 2, 0) To MinX(Cy + Rad + 2, BkH - 1) Do
    For C := MaxX(Cx - Rad - 1, 0) To MinX(Cx + Rad + 1, BkW - 1) Do BunkPix(K, R, C);
  X := BkX[K]; Y := BunkY;
  RestoreRect(X + Cx - Rad - 1, Y + Cy - Rad - 2, X + Cx + Rad + 1, Y + Cy + Rad + 2);
  AddDirty(X + Cx - Rad - 1, Y + Cy - Rad - 2, X + Cx + Rad + 1, Y + Cy + Rad + 2);
End;

{ ==================================================================== }
{ Formation des envahisseurs (dessinee dans le fond fixe)               }
{ ==================================================================== }

Function AX(C : LongInt) : LongInt;
Begin
  AX := FX + C * ColW;
End;

Function AY(R : LongInt) : LongInt;
Begin
  AY := FY + R * RowH;
End;

{ rectangle occupe par les envahisseurs vivants }
Procedure FormBox(Var X1, Y1, X2, Y2 : LongInt);
Var R, C : LongInt;
Begin
  X1 := BW; Y1 := BH; X2 := -1; Y2 := -1;
  For R := 0 To NRow - 1 Do
    For C := 0 To NCol - 1 Do
      If Alive[R, C] <> 0 Then
      Begin
        X1 := MinX(X1, AX(C)); Y1 := MinX(Y1, AY(R));
        X2 := MaxX(X2, AX(C) + SprW); Y2 := MaxX(Y2, AY(R) + SprH);
      End;
End;

{ refait le fond fixe dans le rectangle, puis la formation par-dessus }
Procedure PaintForm(X1, Y1, X2, Y2 : LongInt);
Var R, C, Y, B, K, Cc, L, N : LongInt;
Begin
  X1 := MaxX(X1, 0); Y1 := MaxX(Y1, 0); X2 := MinX(X2, BW - 1); Y2 := MinX(Y2, BH - 1);
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW + X1;
    Move(Bg[B], Back[B], X2 - X1 + 1);
  End;
  { abris dans le rectangle (un envahisseur qui les touche les efface) }
  For K := 0 To NBunk - 1 Do
    If (Y2 >= BunkY) And (Y1 < BunkY + BkH) And (X2 >= BkX[K]) And (X1 < BkX[K] + BkW) Then
      For R := MaxX(Y1 - BunkY, 0) To MinX(Y2 - BunkY, BkH - 1) Do
        For C := MaxX(X1 - BkX[K], 0) To MinX(X2 - BkX[K], BkW - 1) Do BunkPix(K, R, C);
  For R := 0 To NRow - 1 Do
    For C := 0 To NCol - 1 Do
      If Alive[R, C] <> 0 Then
      Begin
        AlienCols(R, Cc, L, N);
        DrawSpr(N + FPose, AX(C), AY(R), Cc, L, True);
      End;
  RestoreRect(X1, Y1, X2, Y2);
  AddDirty(X1, Y1, X2, Y2);
End;

{ les envahisseurs qui touchent un abri le rongent }
Procedure FormEatsBunkers;
Var R, C, K, Y, X, Rr, Cc : LongInt;
Begin
  For R := 0 To NRow - 1 Do
    For C := 0 To NCol - 1 Do
      If (Alive[R, C] <> 0) And (AY(R) + SprH >= BunkY) Then
        For K := 0 To NBunk - 1 Do
          If (AX(C) + SprW > BkX[K]) And (AX(C) < BkX[K] + BkW) Then
            For Y := AY(R) To AY(R) + SprH - 1 Do
              For X := AX(C) To AX(C) + SprW - 1 Do
              Begin
                Rr := Y - BunkY; Cc := X - BkX[K];
                If (Rr >= 0) And (Rr < BkH) And (Cc >= 0) And (Cc < BkW) Then Bunk[K, Rr, Cc] := 0;
              End;
End;

Procedure RepaintForm;
Var X1, Y1, X2, Y2 : LongInt;
Begin
  FormBox(X1, Y1, X2, Y2);
  PaintForm(MinX(X1, OldX1), MinX(Y1, OldY1), MaxX(X2, OldX2), MaxX(Y2, OldY2));
  OldX1 := X1; OldY1 := Y1; OldX2 := X2; OldY2 := Y2;
End;

{ ==================================================================== }
{ Objets mobiles                                                        }
{ ==================================================================== }

Procedure DrawGun;
Begin
  If (State = S_HIT) Or (State = S_OVER) Or (State = S_TITLE) Then Exit;
  DrawSpr(9, GunX - SprW Div 2, GunY, C_GUN, C_GUNL, False);
  Rect(GunX - 1, GunY + 7, GunX, GunY + 9, C_GUNC);
  Rect(GunX - 11, GunY + 13, GunX - 7, GunY + 13, C_GUND);
  Rect(GunX + 6, GunY + 13, GunX + 10, GunY + 13, C_GUND);
  SprRect(GunX - SprW Div 2, GunY, GunX + SprW Div 2 + 1, GunY + SprH + 1);
End;

Procedure DrawShots;
Var K, X, Y : LongInt;
Begin
  For K := 0 To MaxShot - 1 Do
    If ShOn[K] <> 0 Then
    Begin
      X := ShX[K]; Y := ShY[K];
      Rect(X - 1, Y + 1, X + 1, Y + 9, C_SHOTG);
      Rect(X, Y, X, Y + 8, C_SHOT);
      SprRect(X - 1, Y, X + 1, Y + 9);
    End;
  For K := 0 To MaxBomb - 1 Do
    If BmOn[K] <> 0 Then
    Begin
      X := BmX[K]; Y := BmY[K];
      { bombe en zigzag (deux poses) }
      If (Y Div 4) Mod 2 = 0 Then
      Begin
        Pix(X - 1, Y, C_BOMBL); Pix(X, Y + 1, C_BOMB); Pix(X + 1, Y + 2, C_BOMB); Pix(X, Y + 3, C_BOMB);
        Pix(X - 1, Y + 4, C_BOMB); Pix(X, Y + 5, C_BOMB); Pix(X + 1, Y + 6, C_BOMB); Rect(X - 1, Y + 7, X + 1, Y + 8, C_BOMBL);
      End
      Else
      Begin
        Pix(X + 1, Y, C_BOMBL); Pix(X, Y + 1, C_BOMB); Pix(X - 1, Y + 2, C_BOMB); Pix(X, Y + 3, C_BOMB);
        Pix(X + 1, Y + 4, C_BOMB); Pix(X, Y + 5, C_BOMB); Pix(X - 1, Y + 6, C_BOMB); Rect(X - 1, Y + 7, X + 1, Y + 8, C_BOMBL);
      End;
      SprRect(X - 1, Y, X + 1, Y + 8);
    End;
End;

Procedure DrawUfo;
Begin
  If UfoOn = 0 Then Exit;
  DrawSpr(8, UfoX, UfoY, C_UFO, C_UFOL, False);
  If (Tick Div 4) Mod 2 = 0 Then
  Begin
    Pix(UfoX + 6, UfoY + 7, C_YELLOW); Pix(UfoX + 12, UfoY + 7, C_YELLOW); Pix(UfoX + 18, UfoY + 7, C_YELLOW);
  End;
  SprRect(UfoX, UfoY, UfoX + SprW + 1, UfoY + SprH + 1);
End;

Procedure DrawExps;
Var K, N : LongInt;
Begin
  For K := 0 To MaxExp - 1 Do
    If ExT[K] > 0 Then
    Begin
      If ExK[K] = 1 Then
      Begin
        { points du vaisseau mere }
        FbTextSh(ExX[K], ExY[K], '100', C_YELLOW, C_BLACK, 1);
        SprRect(ExX[K], ExY[K], ExX[K] + 25, ExY[K] + FontH + 1);
      End
      Else
      Begin
        If ExT[K] > 7 Then N := 10 Else N := 11;
        DrawSpr(N, ExX[K], ExY[K], ExC[K], C_EXP1, False);
        SprRect(ExX[K], ExY[K], ExX[K] + SprW + 1, ExY[K] + SprH + 1);
      End;
    End;
End;

{ le canon detruit : eclats qui alternent }
Procedure DrawGunExp;
Begin
  If State <> S_HIT Then Exit;
  If Wait > 50 Then Exit;
  If (Wait Div 4) Mod 2 = 0 Then DrawSpr(10, GunX - SprW Div 2, GunY, C_EXP2, C_EXP1, False)
  Else DrawSpr(11, GunX - SprW Div 2, GunY, C_EXP3, C_EXP2, False);
  SprRect(GunX - SprW Div 2, GunY, GunX + SprW Div 2 + 1, GunY + SprH + 1);
End;

Procedure BannerDraw;
Var W, X, Y : LongInt;
Begin
  If Banner = '' Then Exit;
  W := Length(Banner) * 16;
  If Length(Banner2) * 8 > W Then W := Length(Banner2) * 8;
  W := W + 28;
  X := (BW - W) Div 2; Y := 190;
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
  DrawUfo;
  DrawExps;
  DrawShots;
  DrawGun;
  DrawGunExp;
  BannerDraw;
End;

{ ecran titre (dans l'image, sur le ciel) }
Procedure DrawTitle;
Var K, Y, Cc, L, N : LongInt; S : String;
Begin
  Move(Bg, Back, SizeOf(Back));
  Move(Bg, Fb, SizeOf(Fb));
  BigFb((BW - 8 * 24) Div 2, 34, 'INVASION', C_GREEN, C_BLACK, 3);
  BigFb((BW - 11 * 16) Div 2, 92, 'DE L''ESPACE', C_RED, C_BLACK, 2);
  S := 'Table des pointages';
  FbTextSh((BW - Length(S) * 8) Div 2, 146, S, C_WHITE, C_BLACK, 1);
  Y := 176;
  For K := 0 To 3 Do
  Begin
    AlienCols(K, Cc, L, N);
    DrawSpr(N, 150, Y, Cc, L, False);
    FbTextSh(190, Y, '= ' + IStr(AlienPts(K)) + ' points', C_WHITE, C_BLACK, 1);
    Y := Y + 28;
  End;
  DrawSpr(8, 150, Y, C_UFO, C_UFOL, False);
  FbTextSh(190, Y, '= 100 points', C_WHITE, C_BLACK, 1);
  S := 'Espace ou clic : jouer';
  FbTextSh((BW - Length(S) * 8) Div 2, 336, S, C_YELLOW, C_BLACK, 1);
  NDirty := 0; NSpr := 0;
  AddDirty(0, 0, BW - 1, BH - 1);
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

{ petit canon du panneau (vies) }
Procedure LifeIcon(X, Y : LongInt);
Begin
  FBar(X + 5, Y, X + 6, Y + 3, CLR_DARKGREEN);
  FBar(X + 2, Y + 3, X + 9, Y + 6, CLR_DARKGREEN);
  FBar(X, Y + 6, X + 11, Y + 9, CLR_DARKGREEN);
End;

Procedure DrawCounters;
Var S : String; K : LongInt;
Begin
  FBar(PnX + 2, 86, PnX + PW - 3, 120, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 87, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 128, PnX + PW - 1, 218, CLR_PALEGRAY);
  OutTxt(PnX, 128, 'Tableau : ' + IStr(Level), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 148, 'Canons :', CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To MinX(Lives, 6) - 1 Do LifeIcon(PnX + 74 + K * 14, 151);
  OutTxt(PnX, 168, 'Envahisseurs : ' + IStr(NAlive), CLR_BLACK, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 188, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 8 * 16) Div 2, 0, 'INVASION', CLR_DARKGREEN, CLR_PALEGRAY);
  OutTxt(PnX + (PW - 11 * 8) Div 2, 34, 'de l''espace', CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX, 64, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 82, PnX + PW - 1, 124, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 83, PnX + PW - 2, 123, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 84, PnX + PW - 3, 122, CLR_WHITE);
  DrawCounters;
  Button(PnX, 226, PW, 28, 'Nouvelle partie');
  Button(PnX, 260, PW, 28, 'Pause');
  OutTxt(PnX, 302, Chr(27) + ' ' + Chr(26) + ' : canon', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 318, 'ou la souris', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 334, 'Espace : tirer', CLR_DARKGRAY, CLR_PALEGRAY);
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
  If State <> S_TITLE Then DrawSprites;
  NDirty := 0;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawPanel;
  DrawStatus;
  LastMsg := Msg;
  LastSig := Score * 7 + Level * 131 + Lives * 1009 + NAlive * 10007 + Best * 3;
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
  { panneau et barre d'etat : seulement s'ils ont change (pas de scintillement) }
  If Counters And (Score * 7 + Level * 131 + Lives * 1009 + NAlive * 10007 + Best * 3 <> LastSig) Then
  Begin
    LastSig := Score * 7 + Level * 131 + Lives * 1009 + NAlive * 10007 + Best * 3;
    DrawCounters;
  End;
  If Counters And (Msg <> LastMsg) Then
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
  Msg := Chr(27) + ' ' + Chr(26) + ' ou la souris : canon ; Espace ou clic : tirer.';
End;

Procedure AddExp(X, Y, C, K, T : LongInt);
Var I : LongInt;
Begin
  For I := 0 To MaxExp - 1 Do
    If ExT[I] <= 0 Then
    Begin
      ExX[I] := X; ExY[I] := Y; ExC[I] := C; ExK[I] := K; ExT[I] := T;
      Exit;
    End;
End;

Procedure ClearMobiles;
Var K : LongInt;
Begin
  For K := 0 To MaxShot - 1 Do ShOn[K] := 0;
  For K := 0 To MaxBomb - 1 Do BmOn[K] := 0;
  For K := 0 To MaxExp - 1 Do ExT[K] := 0;
  UfoOn := 0; UfoWait := 500 + Rnd(500);
End;

Function StepEvery : LongInt;
Var N : LongInt;
Begin
  N := 1 + NAlive * 13 Div (NRow * NCol) - (Level - 1) Div 2;
  If N < 1 Then N := 1;
  StepEvery := N;
End;

{ nouveau tableau : la formation part de plus en plus bas }
Procedure NewBoard;
Var R, C : LongInt;
Begin
  For R := 0 To NRow - 1 Do For C := 0 To NCol - 1 Do Alive[R, C] := 1;
  NAlive := NRow * NCol;
  FX := (BW - ((NCol - 1) * ColW + SprW)) Div 2;
  FY := 56 + MinX(Level - 1, 6) * 10;
  FDir := 1; FPose := 0; MarchNo := 0;
  StepWait := StepEvery;
  ClearMobiles;
  Move(Bg, Back, SizeOf(Back));
  BuildBunkers;
  DrawBunkers;
  OldX1 := BW; OldY1 := BH; OldX2 := -1; OldY2 := -1;
  RepaintForm;
  Move(Back, Fb, SizeOf(Fb));
  NDirty := 0; NSpr := 0;
  AddDirty(0, 0, BW - 1, BH - 1);
  State := S_PLAY;
  Show('Tableau ' + IStr(Level), 'Les envahisseurs arrivent !', C_YELLOW);
  Wait := 0;
  PlayMsg;
  Redraw;
End;

Procedure NewGame;
Begin
  Score := 0; Level := StartLevel; Lives := 3;
  GunX := BW Div 2; GunT := GunX;
  NewBoard;
End;

Procedure GameOver(Why : String);
Begin
  State := S_OVER;
  If Score > Best Then Best := Score;
  Show('Partie termin' + Chr(130) + 'e', Why, C_RED);
  Msg := Why + ' Pointage : ' + IStr(Score) + '. F2 ou Espace : nouvelle partie.';
  Wait := 0;
  Redraw;
End;

Procedure GunHit;
Var K : LongInt;
Begin
  PlaySnd(2);
  For K := 0 To MaxBomb - 1 Do BmOn[K] := 0;
  For K := 0 To MaxShot - 1 Do ShOn[K] := 0;
  Dec(Lives);
  State := S_HIT; Wait := 0;
  If Lives <= 0 Then Msg := 'Votre dernier canon est d' + Chr(130) + 'truit !'
  Else Msg := 'Canon d' + Chr(130) + 'truit ! Il reste ' + IStr(Lives) + ' canon(s).';
End;

Procedure Fire;
Var K : LongInt;
Begin
  If (State <> S_PLAY) Or (FireCool > 0) Then Exit;
  For K := 0 To MaxShot - 1 Do
    If ShOn[K] = 0 Then
    Begin
      ShOn[K] := 1; ShX[K] := GunX; ShY[K] := GunY - 8;
      FireCool := 11;
      PlaySnd(0);
      Banner := '';
      Exit;
    End;
End;

{ envahisseur touche par le tir en (X, Y) ? }
Function HitAlien(X, Y : LongInt) : Boolean;
Var R, C, Cc, L, N : LongInt;
Begin
  HitAlien := False;
  If (Y < FY) Or (Y > AY(NRow - 1) + SprH) Then Exit;
  For R := NRow - 1 DownTo 0 Do
    For C := 0 To NCol - 1 Do
      If (Alive[R, C] <> 0) And (X >= AX(C)) And (X < AX(C) + SprW) And (Y >= AY(R)) And (Y < AY(R) + SprH - 1) Then
      Begin
        Alive[R, C] := 0;
        Dec(NAlive);
        Score := Score + AlienPts(R);
        AlienCols(R, Cc, L, N);
        AddExp(AX(C), AY(R), Cc, 0, 14);
        PaintForm(AX(C), AY(R), AX(C) + SprW + 1, AY(R) + SprH + 1);
        PlaySnd(1);
        HitAlien := True;
        Exit;
      End;
End;

Procedure MoveShots;
Var K, I, J, Y, B : LongInt;
Begin
  For K := 0 To MaxShot - 1 Do
    If ShOn[K] <> 0 Then
    Begin
      For I := 1 To 9 Do
        If ShOn[K] <> 0 Then
        Begin
          Dec(ShY[K]);
          Y := ShY[K];
          If Y < 16 Then ShOn[K] := 0
          Else If BunkAt(ShX[K], Y, B) Then
          Begin
            Erode(B, ShX[K], Y, 3);
            ShOn[K] := 0;
          End
          Else If HitAlien(ShX[K], Y) Then ShOn[K] := 0
          Else If (UfoOn <> 0) And (ShX[K] >= UfoX) And (ShX[K] < UfoX + SprW) And (Y >= UfoY) And
                  (Y < UfoY + 13) Then
          Begin
            ShOn[K] := 0; UfoOn := 0;
            Score := Score + 100;
            AddExp(UfoX + 2, UfoY + 2, 0, 1, 40);
            PlaySnd(4);
          End
          Else
            For J := 0 To MaxBomb - 1 Do
              If (BmOn[J] <> 0) And (ShOn[K] <> 0) And (Abs(BmX[J] - ShX[K]) <= 2) And (Y >= BmY[J]) And
                 (Y <= BmY[J] + 8) Then
              Begin
                BmOn[J] := 0; ShOn[K] := 0;
                AddExp(ShX[K] - 12, Y - 8, C_SHOT, 0, 6);
              End;
        End;
    End;
End;

Procedure MoveBombs;
Var K, I, B, Spd : LongInt;
Begin
  Spd := 3 + MinX(Level - 1, 6) Div 3;
  For K := 0 To MaxBomb - 1 Do
    If BmOn[K] <> 0 Then
      For I := 1 To Spd Do
        If BmOn[K] <> 0 Then
        Begin
          Inc(BmY[K]);
          If BmY[K] + 8 >= GroundY Then
          Begin
            BmOn[K] := 0;
            AddExp(BmX[K] - 12, GroundY - 14, C_BOMB, 0, 5);
          End
          Else If BunkAt(BmX[K], BmY[K] + 8, B) Then
          Begin
            Erode(B, BmX[K], BmY[K] + 8, 4);
            BmOn[K] := 0;
            PlaySnd(10);
          End
          Else If (State = S_PLAY) And (BmY[K] + 8 >= GunY + 4) And (Abs(BmX[K] - GunX) <= 11) Then
          Begin
            BmOn[K] := 0;
            GunHit;
          End;
        End;
End;

{ un envahisseur du bas d'une colonne lache une bombe }
Procedure AlienFire;
Var K, C, R, N, Best0, D : LongInt;
Begin
  If NAlive = 0 Then Exit;
  N := 0;
  For K := 0 To MaxBomb - 1 Do If BmOn[K] <> 0 Then Inc(N);
  If N >= MinX(3 + Level Div 2, MaxBomb) Then Exit;
  If Rnd(1000) >= 30 + MinX(Level, 8) * 6 Then Exit;
  { une fois sur trois, la colonne au-dessus du canon }
  Best0 := -1;
  If Rnd(3) = 0 Then
  Begin
    D := 9999;
    For C := 0 To NCol - 1 Do
      For R := 0 To NRow - 1 Do
        If (Alive[R, C] <> 0) And (Abs(AX(C) + SprW Div 2 - GunX) < D) Then
        Begin
          D := Abs(AX(C) + SprW Div 2 - GunX); Best0 := C;
        End;
  End;
  If Best0 < 0 Then
  Begin
    C := Rnd(NCol); K := 0;
    While K < NCol Do
    Begin
      For R := 0 To NRow - 1 Do If Alive[R, (C + K) Mod NCol] <> 0 Then Best0 := (C + K) Mod NCol;
      If Best0 >= 0 Then K := NCol Else Inc(K);
    End;
  End;
  If Best0 < 0 Then Exit;
  For R := NRow - 1 DownTo 0 Do
    If Alive[R, Best0] <> 0 Then
    Begin
      For K := 0 To MaxBomb - 1 Do
        If BmOn[K] = 0 Then
        Begin
          BmOn[K] := 1; BmX[K] := AX(Best0) + SprW Div 2; BmY[K] := AY(R) + SprH;
          Exit;
        End;
      Exit;
    End;
End;

{ un pas de la formation ; aux bords : elle descend et repart }
Procedure StepForm;
Var X1, Y1, X2, Y2, Dx : LongInt;
Begin
  FormBox(X1, Y1, X2, Y2);
  If NAlive <= 1 Then Dx := 8 Else If NAlive <= 6 Then Dx := 6 Else Dx := 4;
  If ((FDir > 0) And (X2 + Dx > BW - 6)) Or ((FDir < 0) And (X1 - Dx < 6)) Then
  Begin
    FY := FY + 12;
    FDir := -FDir;
  End
  Else FX := FX + FDir * Dx;
  FPose := 1 - FPose;
  FormEatsBunkers;
  RepaintForm;
  PlaySnd(5 + MarchNo);
  MarchNo := (MarchNo + 1) Mod 4;
  FormBox(X1, Y1, X2, Y2);
  If Y2 >= GunY + 2 Then
  Begin
    PlaySnd(2);
    Lives := 0;
    GameOver('Les envahisseurs ont atteint le sol !');
  End;
End;

Procedure MoveUfo;
Begin
  If UfoOn = 0 Then
  Begin
    If NAlive < 8 Then Exit;
    Dec(UfoWait);
    If UfoWait <= 0 Then
    Begin
      UfoOn := 1;
      If Rnd(2) = 0 Then Begin UfoDir := -2; UfoX := BW; End Else Begin UfoDir := 2; UfoX := -SprW; End;
    End;
    Exit;
  End;
  UfoX := UfoX + UfoDir;
  If Tick Mod 14 = 0 Then PlaySnd(3);
  If (UfoX < -SprW - 2) Or (UfoX > BW + 2) Then
  Begin
    UfoOn := 0;
    UfoWait := 600 + Rnd(600);
  End;
End;

Procedure MoveGun;
Var D, Lo, Hi : LongInt;
Begin
  Lo := SprW Div 2 + 4; Hi := BW - SprW Div 2 - 5;
  If GunT < Lo Then GunT := Lo;
  If GunT > Hi Then GunT := Hi;
  D := GunT - GunX;
  If D > 4 Then D := 4;
  If D < -4 Then D := -4;
  GunX := GunX + D;
End;

{ demonstration : viser la colonne la plus basse, eviter les bombes }
Procedure AutoPlay;
Var R, C, K, T, D, Dmin : LongInt;
Begin
  If State <> S_PLAY Then Exit;
  T := GunX; Dmin := 9999;
  For C := 0 To NCol - 1 Do
    For R := 0 To NRow - 1 Do
      If Alive[R, C] <> 0 Then
      Begin
        D := Abs(AX(C) + SprW Div 2 - GunX) - R * 6;
        If D < Dmin Then Begin Dmin := D; T := AX(C) + SprW Div 2 + FDir * 6; End;
      End;
  If UfoOn <> 0 Then
    If Abs(UfoX + SprW Div 2 + UfoDir * 30 - GunX) < 60 Then T := UfoX + SprW Div 2 + UfoDir * 30;
  For K := 0 To MaxBomb - 1 Do
    If (BmOn[K] <> 0) And (BmY[K] > GunY - 90) And (Abs(BmX[K] - T) < 16) Then
      If BmX[K] < GunX Then T := BmX[K] + 26 Else T := BmX[K] - 26;
  GunT := T;
  If Abs(T - GunX) < 6 Then Fire;
End;

Procedure Step;
Var K : LongInt;
Begin
  Inc(Tick);
  For K := 0 To MaxExp - 1 Do If ExT[K] > 0 Then Dec(ExT[K]);
  If FireCool > 0 Then Dec(FireCool);
  If State = S_PLAY Then
  Begin
    If AutoAll <> 0 Then AutoPlay;
    MoveGun;
  End;
  MoveShots;
  If (State = S_PLAY) Or (State = S_HIT) Then MoveBombs;
  If State = S_PLAY Then
  Begin
    MoveUfo;
    AlienFire;
    Dec(StepWait);
    If StepWait <= 0 Then
    Begin
      StepForm;
      StepWait := StepEvery;
    End;
    If (State = S_PLAY) And (NAlive = 0) Then
    Begin
      PlaySnd(9);
      State := S_CLEAR; Wait := 0;
      If Lives < 6 Then Inc(Lives);
      Show('Tableau termin' + Chr(130) + ' !', 'Un canon de plus. Tableau suivant...', C_GREEN);
      Msg := 'Tableau termin' + Chr(130) + ' : un canon de plus !';
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
      If Banner <> '' Then
      Begin
        Inc(Wait);
        If Wait > 50 Then Banner := '';
      End;
    S_HIT :
      Begin
        Inc(Wait);
        If Wait > 70 Then
        Begin
          If Lives <= 0 Then GameOver('Tous vos canons sont d' + Chr(130) + 'truits.')
          Else
          Begin
            State := S_PLAY; Wait := 0;
            GunX := BW Div 2; GunT := GunX;
            PlayMsg;
          End;
          C := True;
        End;
      End;
    S_CLEAR :
      Begin
        Inc(Wait);
        If Wait > 70 Then
        Begin
          Inc(Level);
          NewBoard;
          Exit;
        End;
      End;
    S_OVER :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait > 90 Then NewGame;
      End;
  End;
  If Tick Mod 5 = 0 Then C := True;
  Frame1(C);
End;

Procedure TogglePause;
Begin
  If (State = S_PLAY) Or (State = S_HIT) Then
  Begin
    OldState := State;
    State := S_PAUSE;
    Show('Pause', 'P ou Espace : reprendre', C_GREEN);
    Msg := 'Pause.';
    Frame1(True);
  End
  Else If State = S_PAUSE Then
  Begin
    State := OldState; Banner := '';
    PlayMsg;
    Frame1(True);
  End;
End;

Procedure StartFromTitle;
Begin
  If State = S_TITLE Then NewGame;
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
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll;
        SetMarks;
        If (AutoAll <> 0) And ((State = S_TITLE) Or (State = S_OVER)) Then NewGame;
      End;
    CM_SOUND :
      Begin
        SoundOn := 1 - SoundOn;
        SetMarks;
      End;
    CM_RULES :
      Begin
        If State = S_PLAY Then TogglePause;
        LClr;
        LAdd('Cinq rang' + Chr(130) + 'es de douze envahisseurs avancent ensemble ; ' + Chr(133) +
             ' chaque bord, ils descendent d''un cran. Abattez-les avec votre canon avant qu''ils n''arrivent ' +
             'en bas. Ils l' + Chr(131) + 'chent des bombes : quatre abris vous prot' + Chr(138) + 'gent, ');
        LAdd('mais tirs et bombes les ' + Chr(130) + 'miettent. Plus il reste peu d''envahisseurs, plus ils ' +
             'vont vite.' + Chr(10) + Chr(10));
        LAdd('Points : 40, 30, 20 ou 10 selon la rang' + Chr(130) + 'e ; le vaisseau m' + Chr(138) + 're qui ' +
             'passe en haut vaut 100 points. Trois canons ; un tableau termin' + Chr(130) + ' rapporte un ' +
             'canon et le suivant commence plus bas.' + Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches (ou 4 et 6), Espace ou fl' + Chr(138) + 'che haut (tirer), P ' +
             '(pause), F2 (nouvelle partie). Souris : le canon suit le pointeur, clic : tirer.');
        Dummy := LMsgBox('Invasion de l''espace - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Invasion de l''espace pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype INVADERS.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos d''Invasion de ' +
                            'l''espace', MB_OK Or MB_INFORMATION);
  End;
End;

Procedure Action;
Begin
  Case State Of
    S_TITLE : StartFromTitle;
    S_PLAY : Fire;
    S_PAUSE : TogglePause;
    S_OVER : NewGame;
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
    If Vk = VK_LEFT Then Begin MouseOn := 0; GunT := MinX(GunT, GunX) - 18; Exit; End;
    If Vk = VK_RIGHT Then Begin MouseOn := 0; GunT := MaxX(GunT, GunX) + 18; Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_UP) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      Action;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'P' : TogglePause;
      'N' : NewGame;
      '4' : GunT := MinX(GunT, GunX) - 18;
      '6' : GunT := MaxX(GunT, GunX) + 18;
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
    If (Y >= 226) And (Y < 254) Then NewGame
    Else If (Y >= 260) And (Y < 288) Then TogglePause;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then Action;
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
          GunT := X - OX;
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
  Client := 0; Frame := 0; SoundOn := 1; MouseOn := 0; State := S_TITLE; StartLevel := 1; Level := 1;
  Lives := 3; Score := 0; NAlive := NRow * NCol; SndCur := 0; SndEnd := 0; FireCool := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/LEVEL:') Then
    Begin
      Val(Copy(S, 8, 20), StartLevel, E);
      If StartLevel < 1 Then StartLevel := 1;
      If StartLevel > 20 Then StartLevel := 20;
      Level := StartLevel;
    End;
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  MakeSounds;
  ClearMobiles;
  RenderBg;
  Dummy := WinRegisterClass(Hab, Z('INVADERS'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('INVADERS'), Z2('Invasion de l''espace'), 0, 0,
                              0, LongInt(@Client));
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
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos d''Invasion de l''espace');
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
  If AutoAll <> 0 Then NewGame
  Else
  Begin
    DrawTitle;
    Msg := 'Espace ou clic : jouer. F1 : r' + Chr(138) + 'gles.';
  End;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 30);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
