{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: GRENOUILLE - faire traverser la route puis la riviere a
                une grenouille, pour le Presentation Manager d'OS/2-0
                (dossier Jeux du bureau).
}

Program GRENOUILLE;

{ Grenouille

  Portage vers OS/2-0 du prototype FROGGER.PAS du depot 7iles (Turbo
  Pascal, BGI 320 x 200) : fenetre de Presentation Manager avec menus,
  decor et personnages entierement redessines (dessins originaux) dans
  une image en memoire affichee par GpiDrawBits (sans scintillement),
  animation reguliere sur minuterie (25 images par seconde), bruitages
  et apparence d'OS/2 Warp 3.

  Le jeu : la grenouille part du trottoir, traverse quatre voies de
  circulation (voitures, tracteurs, bolides, camions), se repose sur la
  berge puis franchit la riviere en sautant sur les troncs et sur les
  tortues (certaines plongent !) pour atteindre un des cinq nenuphars de
  l'autre rive. Les cinq nenuphars occupes, on passe au niveau suivant,
  plus rapide. Une mouche apparait parfois sur un nenuphar libre (bonus).
  Une grenouille est perdue si elle est ecrasee, tombe a l'eau, est
  emportee hors de l'ecran, saute dans la haie ou sur un nenuphar deja
  occupe, ou si le temps est ecoule.

  Ce qui est corrige par rapport au prototype : couleurs des voitures
  lues hors du tableau (indices inverses), grenouille deplacee par tous
  les troncs a la fois (meme hors d'un tronc), test de collision sur des
  octets non signes, minuterie liee a la vitesse de l'ordinateur, partie
  qui se terminait sans message (ou apres quatre traversees), message de
  noyade errone (« tue du billot »).

  Pointage : 10 par rangee gagnee, 50 par nenuphar plus 1 par seconde
  restante, 200 pour une mouche, 1000 par niveau termine ; une vie de
  plus tous les 5000 points.

  Clavier : fleches (sauter), P (pause), F2 (nouvelle partie), F1
  (regles). Souris : cliquer au-dessus, au-dessous, a gauche ou a droite
  de la grenouille.
  Parametres : /SEED:n ; /AUTO (demonstration) ; /LEVEL:n ; /NOSOUND ;
  /TEST (essais des collisions, de la noyade, des troncs, des nenuphars,
  du temps et du changement de niveau, puis partie jouee par
  l'ordinateur ; resultat sur le port serie COM1). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_PAUSE = $0D; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18;
  VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_PAUSE = 102; CM_QUIT = 104;
  CM_EASY = 201; CM_NORMAL = 202; CM_HARD = 203; CM_AUTO = 204; CM_SOUND = 205;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : 13 colonnes x 12 rangees de 32 points + bande du temps }
  BW = 416; BH = 400; OX = 8; OY = 8;
  PnX = 440; PW = 168;
  CWant = 616; CHWant = 436;
  Cell = 32; NRow = 12; StartX = 192; HopN = 6;
  { genres de voies }
  K_NONE = 0; K_CAR = 1; K_LOG = 2; K_TURT = 3;
  { styles de vehicules }
  V_CAR = 1; V_TRACT = 2; V_RACER = 3; V_TRUCK = 4;
  { couleurs de l'image }
  C_SHADOW = 1; C_WATER = 2;                   { 2..5 : eau (sombre -> claire) }
  C_WAVE = 6; C_HEDGE = 7;                     { 7..9 : haie }
  C_PAD = 10; C_PADD = 11; C_GRASS = 12;       { 12..14 : herbe }
  C_FLOWER = 15; C_ROAD = 16;                  { 16..18 : asphalte }
  C_LINE = 19; C_YLINE = 20; C_WALK0 = 21; C_WALK1 = 22; C_WALKL = 23; C_BAND = 24; C_BAR = 25;
  C_BARW = 26; C_BARR = 27; C_TEXT = 28; C_LOG0 = 29; C_LOG1 = 30; C_LOG2 = 31; C_LOGE = 32; C_TURT0 = 33;
  C_TURT1 = 34; C_TURTS = 35; C_TURTU = 36; C_FROG0 = 37; C_FROG1 = 38; C_FROG2 = 39; C_EYE = 40;
  C_BLACK = 41; C_RED = 42; C_CAR1 = 43; C_CAR2 = 44; C_CAR3 = 45; C_CAR4 = 46; C_GLASS = 47; C_TIRE = 48;
  C_WHITE = 49; C_GRAY = 50; C_ORANGE = 51; C_FLY = 52; C_BANNER = 53; C_BANNERE = 54; C_YELLOW = 55;
  C_SPLASH = 56; C_SPLAT = 57; C_TRAIL = 58; C_CAR5 = 59; C_DARK = 60; C_LIGHT = 61; C_WATERL = 62;
  C_TRAILD = 63; C_BELLY = 64; C_STONE = 65; C_STONED = 66;
  NPal = 72;
  { etats }
  S_START = 1; S_PLAY = 2; S_DYING = 3; S_HOMEP = 4; S_LEVEL = 5; S_OVER = 6;
  { causes de perte }
  D_CAR = 1; D_WATER = 2; D_OUT = 3; D_TIME = 4; D_HEDGE = 5; D_TAKEN = 6;
  SndRate = 11025;

Var
  InDlg : LongInt;  { boite de message ouverte : animation suspendue }
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { voies (rangee 0..11) ; objets : rangee * 4 + k }
  LKind, LStyle, LN, LaneLen, LBase, LSpd, LPer : Array[0..NRow - 1] Of LongInt;
  ObX, ObDive, ObPh : Array[0..NRow * 4 - 1] Of LongInt;
  { grenouille : FrX = bord gauche en 1/16 de point }
  FrX, FrRow, FrDir, HopT, Row0, Row1, X0, X1, MaxRow, NextMove : LongInt;
  BayFull : Array[0..4] Of LongInt;
  FlyBay, FlyT, Homes, HomesAll, Deaths, DieT, DieCause, DieX, DieY, StT, LastHome : LongInt;
  Score, HiScore, Level, Lives, NextLife, TimeLeft, TimeMax, Diff, NextDiff : LongInt;
  State, Paused, GTick, Seed, AutoAll, SoundOn, Tick, TestMode, Dirty, LastSig : LongInt;
  Banner, Banner2, Msg, LastMsg : String;
  GCx, GCy, GDir : LongInt;
  SavB, SavB2 : String;
  SavBC, FirstLevel : LongInt;     { orientation du dessin de la grenouille }
  BannerC : LongInt;
  { bruitages }
  SndBuf : Array[0..29999] Of Byte;
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
  SetPal(0, $000000); SetPal(C_SHADOW, $101818);
  For I := 0 To 3 Do SetPal(C_WATER + I, Mix($0C2C6C, $2A62B4, I, 3));
  SetPal(C_WAVE, $78A8E8); SetPal(C_WATERL, $4C86D0);
  For I := 0 To 2 Do SetPal(C_HEDGE + I, Mix($0C3A12, $2E7A2A, I, 2));
  SetPal(C_PAD, $3CAA3C); SetPal(C_PADD, $1E6E28);
  For I := 0 To 2 Do SetPal(C_GRASS + I, Mix($2E7C2A, $5EB04A, I, 2));
  SetPal(C_FLOWER, $F4E46A);
  For I := 0 To 2 Do SetPal(C_ROAD + I, Mix($2A2A30, $4A4A52, I, 2));
  SetPal(C_LINE, $E8E8E8); SetPal(C_YLINE, $E8C030);
  SetPal(C_WALK0, $A8A49C); SetPal(C_WALK1, $BCB8AE); SetPal(C_WALKL, $7C786E);
  SetPal(C_BAND, $14202C); SetPal(C_BAR, $3CD050); SetPal(C_BARW, $F0D040); SetPal(C_BARR, $F04030);
  SetPal(C_TEXT, $E8F0F4);
  SetPal(C_LOG0, $B07A44); SetPal(C_LOG1, $8A5A2C); SetPal(C_LOG2, $5E3A18); SetPal(C_LOGE, $E0BC84);
  SetPal(C_TURT0, $1E7A4A); SetPal(C_TURT1, $56B070); SetPal(C_TURTS, $A8C858); SetPal(C_TURTU, $1C4E70);
  SetPal(C_FROG0, $1A6A1A); SetPal(C_FROG1, $42B830); SetPal(C_FROG2, $9CE060); SetPal(C_EYE, $FFFFF0);
  SetPal(C_BELLY, $D8F098);
  SetPal(C_BLACK, $101010); SetPal(C_RED, $E02828);
  SetPal(C_CAR1, $F0C028); SetPal(C_CAR2, $A050D0); SetPal(C_CAR3, $3070D8); SetPal(C_CAR4, $3C9A30);
  SetPal(C_CAR5, $E04020); SetPal(C_GLASS, $9CD8F0); SetPal(C_TIRE, $181818); SetPal(C_WHITE, $FFFFFF);
  SetPal(C_GRAY, $9098A0); SetPal(C_ORANGE, $F08C20); SetPal(C_FLY, $202028);
  SetPal(C_BANNER, $102A40); SetPal(C_BANNERE, $A0C8F0); SetPal(C_YELLOW, $FFDC46);
  SetPal(C_SPLASH, $D8ECFF); SetPal(C_SPLAT, $C02020); SetPal(C_TRAIL, $E4E4DC); SetPal(C_TRAILD, $A8A8A0);
  SetPal(C_DARK, $202020); SetPal(C_LIGHT, $FFF8C0);
  SetPal(C_STONE, $8C8C7C); SetPal(C_STONED, $5C5C50);
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

{ trait epais (carre de cote 2T + 1) }
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

Procedure FbTextSh(X, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(X + Sc, Y + Sc, S, C_SHADOW, Sc);
  FbText(X, Y, S, C, Sc);
End;


{ rectangle aux coins arrondis (rayon 3) }
Procedure RRect(X1, Y1, X2, Y2, C : LongInt);
Begin
  Rect(X1 + 3, Y1, X2 - 3, Y1, C); Rect(X1 + 1, Y1 + 1, X2 - 1, Y1 + 2, C);
  Rect(X1, Y1 + 3, X2, Y2 - 3, C);
  Rect(X1 + 1, Y2 - 2, X2 - 1, Y2 - 1, C); Rect(X1 + 3, Y2, X2 - 3, Y2, C);
End;

{ ==================================================================== }
{ Grenouille : dessinee tournee vers le haut, puis orientee            }
{ ==================================================================== }

Procedure LMap(U, V : LongInt; Var X, Y : LongInt);
Begin
  Case GDir Of
    0 : Begin X := GCx + U; Y := GCy + V; End;
    1 : Begin X := GCx - V; Y := GCy + U; End;
    2 : Begin X := GCx - U; Y := GCy - V; End;
  Else
    Begin X := GCx + V; Y := GCy - U; End;
  End;
End;

Procedure LRect(U1, V1, U2, V2, C : LongInt);
Var Xa, Ya, Xb, Yb : LongInt;
Begin
  LMap(U1, V1, Xa, Ya); LMap(U2, V2, Xb, Yb);
  Rect(MinI(Xa, Xb), MinI(Ya, Yb), MaxI(Xa, Xb), MaxI(Ya, Yb), C);
End;

Procedure LDisc(U, V, R, C : LongInt);
Var X, Y : LongInt;
Begin
  LMap(U, V, X, Y);
  Disc(X, Y, R, C);
End;

{ grenouille centree en (Cx, Cy) ; Jump : 0 assise, 1 pattes etirees }
Procedure DrawFrog(Cx, Cy, Dir, Jump : LongInt);
Var S : LongInt;
Begin
  GCx := Cx; GCy := Cy; GDir := Dir;
  { ombre }
  If Jump <> 0 Then S := 4 Else S := 2;
  Disc(Cx + S, Cy + S, 10, C_SHADOW);
  { pattes arriere }
  If Jump <> 0 Then
  Begin
    LRect(-11, 6, -8, 15, C_FROG0); LRect(8, 6, 11, 15, C_FROG0);
    LRect(-13, 13, -8, 15, C_FROG1); LRect(8, 13, 13, 15, C_FROG1);
  End
  Else
  Begin
    LRect(-13, 2, -9, 10, C_FROG0); LRect(9, 2, 13, 10, C_FROG0);
    LRect(-14, 9, -9, 12, C_FROG1); LRect(9, 9, 14, 12, C_FROG1);
    LRect(-12, -1, -9, 4, C_FROG0); LRect(9, -1, 12, 4, C_FROG0);
  End;
  { pattes avant }
  If Jump <> 0 Then
  Begin
    LRect(-10, -14, -7, -5, C_FROG0); LRect(7, -14, 10, -5, C_FROG0);
  End
  Else
  Begin
    LRect(-11, -10, -7, -6, C_FROG0); LRect(7, -10, 11, -6, C_FROG0);
    LRect(-12, -12, -10, -9, C_FROG1); LRect(10, -12, 12, -9, C_FROG1);
  End;
  { corps }
  LDisc(0, 3, 8, C_FROG0);
  LDisc(0, -3, 7, C_FROG0);
  LDisc(0, 3, 7, C_FROG1);
  LDisc(0, -3, 6, C_FROG1);
  LRect(-1, -6, 1, 7, C_FROG2);
  LDisc(-4, 4, 1, C_FROG0); LDisc(4, 2, 1, C_FROG0); LDisc(-3, -1, 1, C_FROG0);
  { yeux }
  LDisc(-5, -8, 3, C_FROG0); LDisc(5, -8, 3, C_FROG0);
  LDisc(-5, -8, 2, C_EYE); LDisc(5, -8, 2, C_EYE);
  LRect(-5, -10, -5, -9, C_BLACK); LRect(5, -10, 5, -9, C_BLACK);
End;

{ grenouille ecrasee }
Procedure DrawSplat(Cx, Cy, T : LongInt);
Var K, Dx, Dy : LongInt;
Begin
  For K := 0 To 7 Do
  Begin
    Dx := ((K * 37 + 11) Mod 23) - 11; Dy := ((K * 53 + 5) Mod 21) - 10;
    Disc(Cx + Dx, Cy + Dy, 2 + (K Mod 3), C_FROG0);
  End;
  Disc(Cx, Cy, 9, C_FROG1);
  Disc(Cx - 2, Cy + 1, 4, C_FROG2);
  { yeux en croix }
  TLine(Cx - 7, Cy - 6, Cx - 3, Cy - 2, 0, C_BLACK); TLine(Cx - 7, Cy - 2, Cx - 3, Cy - 6, 0, C_BLACK);
  TLine(Cx + 3, Cy - 6, Cx + 7, Cy - 2, 0, C_BLACK); TLine(Cx + 3, Cy - 2, Cx + 7, Cy - 6, 0, C_BLACK);
  If (T Div 4) Mod 2 = 0 Then Disc(Cx, Cy + 12, 2, C_SPLAT);
End;

Procedure Ring(Cx, Cy, R, C : LongInt);
Var A, X : LongInt;
Begin
  { cercle par symetrie d'octant }
  For A := 0 To R Do
  Begin
    X := 0;
    While (X + 1) * (X + 1) + A * A <= R * R + R Do Inc(X);
    Pix(Cx + X, Cy + A, C); Pix(Cx - X, Cy + A, C); Pix(Cx + X, Cy - A, C); Pix(Cx - X, Cy - A, C);
    Pix(Cx + A, Cy + X, C); Pix(Cx - A, Cy + X, C); Pix(Cx + A, Cy - X, C); Pix(Cx - A, Cy - X, C);
  End;
End;

{ grenouille tombee a l'eau : ronds dans l'eau }
Procedure DrawSplash(Cx, Cy, T : LongInt);
Begin
  If T < 10 Then
  Begin
    Disc(Cx, Cy, 6 - T Div 2, C_SPLASH);
    Disc(Cx - 8, Cy - 6 - T, 2, C_SPLASH); Disc(Cx + 8, Cy - 6 - T, 2, C_SPLASH);
    Disc(Cx, Cy - 9 - T, 2, C_SPLASH);
  End;
  Ring(Cx, Cy, 4 + T Div 2, C_SPLASH);
  If T > 6 Then Ring(Cx, Cy, T Div 2 - 1, C_WAVE);
End;

{ mouche (bonus) }
Procedure DrawFly(Cx, Cy, T : LongInt);
Begin
  If (T Div 3) Mod 2 = 0 Then
  Begin
    Disc(Cx - 5, Cy - 3, 4, C_EYE); Disc(Cx + 5, Cy - 3, 4, C_EYE);
  End
  Else
  Begin
    Disc(Cx - 6, Cy, 4, C_EYE); Disc(Cx + 6, Cy, 4, C_EYE);
  End;
  Disc(Cx, Cy, 3, C_FLY); Disc(Cx, Cy + 4, 2, C_FLY);
  Pix(Cx - 1, Cy - 2, C_RED); Pix(Cx + 1, Cy - 2, C_RED);
End;

{ ==================================================================== }
{ Vehicules, troncs, tortues                                            }
{ ==================================================================== }

{ vehicule vu de dessus ; D : +1 vers la droite, -1 vers la gauche }
Procedure DrawVehicle(X, Y, Len, Style, D, T : LongInt);
Var F, B, C, K : LongInt;
Begin
  { F : abscisse de l'avant ; B : de l'arriere }
  If D > 0 Then Begin F := X + Len - 1; B := X; End Else Begin F := X; B := X + Len - 1; End;
  Case Style Of
    V_TRUCK :
      Begin
        RRect(X + 3, Y + 7, X + Len + 2, Y + 28, C_SHADOW);
        { remorque }
        If D > 0 Then K := X Else K := X + 20;
        Rect(K, Y + 5, K + Len - 21, Y + 26, C_TRAIL);
        Rect(K, Y + 5, K + Len - 21, Y + 6, C_WHITE);
        Rect(K, Y + 25, K + Len - 21, Y + 26, C_TRAILD);
        For C := 1 To 4 Do Rect(K + C * (Len - 20) Div 5, Y + 7, K + C * (Len - 20) Div 5, Y + 24, C_TRAILD);
        { cabine }
        If D > 0 Then K := X + Len - 18 Else K := X;
        Rect(K - 2 * D, Y + 6, K - 2 * D + 1, Y + 25, C_DARK);
        RRect(K, Y + 6, K + 17, Y + 25, C_CAR3);
        If D > 0 Then Rect(K + 10, Y + 9, K + 13, Y + 22, C_GLASS) Else Rect(K + 4, Y + 9, K + 7, Y + 22, C_GLASS);
        Rect(F - D, Y + 7, F, Y + 9, C_LIGHT); Rect(F - D, Y + 22, F, Y + 24, C_LIGHT);
        Rect(K + 2, Y + 4, K + 7, Y + 5, C_TIRE); Rect(K + 2, Y + 26, K + 7, Y + 27, C_TIRE);
        If D > 0 Then K := X Else K := X + Len - 16;
        Rect(K + 3, Y + 3, K + 13, Y + 4, C_TIRE); Rect(K + 3, Y + 27, K + 13, Y + 28, C_TIRE);
      End;
    V_TRACT :
      Begin
        RRect(X + 3, Y + 7, X + Len + 2, Y + 28, C_SHADOW);
        { grandes roues arriere, petites roues avant }
        Rect(B - 2 * D, Y + 3, B + 9 * D, Y + 3, C_TIRE);
        Rect(MinI(B, B + 9 * D), Y + 2, MaxI(B, B + 9 * D), Y + 7, C_TIRE);
        Rect(MinI(B, B + 9 * D), Y + 24, MaxI(B, B + 9 * D), Y + 29, C_TIRE);
        Rect(MinI(F - 3 * D, F - 8 * D), Y + 6, MaxI(F - 3 * D, F - 8 * D), Y + 8, C_TIRE);
        Rect(MinI(F - 3 * D, F - 8 * D), Y + 23, MaxI(F - 3 * D, F - 8 * D), Y + 25, C_TIRE);
        { capot et cabine }
        Rect(MinI(B + 2 * D, F), Y + 10, MaxI(B + 2 * D, F), Y + 21, C_CAR4);
        Rect(MinI(B + 2 * D, B + 13 * D), Y + 8, MaxI(B + 2 * D, B + 13 * D), Y + 23, C_CAR4);
        Rect(MinI(B + 4 * D, B + 11 * D), Y + 11, MaxI(B + 4 * D, B + 11 * D), Y + 20, C_FROG0);
        Disc(B + 7 * D, Y + 15, 3, C_ORANGE);
        { pot d'echappement }
        Disc(F - 9 * D, Y + 12, 1, C_DARK);
        Rect(F - D, Y + 12, F, Y + 19, C_YELLOW);
      End;
    V_RACER :
      Begin
        RRect(X + 3, Y + 9, X + Len + 2, Y + 26, C_SHADOW);
        Rect(X + 4, Y + 6, X + 9, Y + 8, C_TIRE); Rect(X + Len - 10, Y + 6, X + Len - 5, Y + 8, C_TIRE);
        Rect(X + 4, Y + 23, X + 9, Y + 25, C_TIRE); Rect(X + Len - 10, Y + 23, X + Len - 5, Y + 25, C_TIRE);
        RRect(X, Y + 9, X + Len - 1, Y + 22, C_CAR5);
        { nez effile, aileron }
        Rect(MinI(F, F - 6 * D), Y + 9, MaxI(F, F - 6 * D), Y + 11, C_ROAD + 1);
        Rect(MinI(F, F - 6 * D), Y + 20, MaxI(F, F - 6 * D), Y + 22, C_ROAD + 1);
        Rect(MinI(B, B + 3 * D), Y + 7, MaxI(B, B + 3 * D), Y + 24, C_DARK);
        Rect(X + 3, Y + 15, X + Len - 4, Y + 16, C_WHITE);
        Disc(X + Len Div 2 - 2 * D, Y + 15, 3, C_GLASS);
        Disc(X + Len Div 2 - 2 * D, Y + 15, 1, C_CAR3);
      End;
  Else
    Begin
      RRect(X + 3, Y + 8, X + Len + 2, Y + 27, C_SHADOW);
      Rect(X + 4, Y + 5, X + 9, Y + 7, C_TIRE); Rect(X + Len - 10, Y + 5, X + Len - 5, Y + 7, C_TIRE);
      Rect(X + 4, Y + 24, X + 9, Y + 26, C_TIRE); Rect(X + Len - 10, Y + 24, X + Len - 5, Y + 26, C_TIRE);
      C := C_CAR1;
      If T = 1 Then C := C_CAR2;
      RRect(X, Y + 7, X + Len - 1, Y + 24, C);
      { pare-brise vers l'avant, lunette vers l'arriere, toit }
      Rect(MinI(F - 7 * D, F - 10 * D), Y + 9, MaxI(F - 7 * D, F - 10 * D), Y + 22, C_GLASS);
      Rect(MinI(B + 4 * D, B + 6 * D), Y + 10, MaxI(B + 4 * D, B + 6 * D), Y + 21, C_GLASS);
      Rect(MinI(F - 11 * D, B + 7 * D), Y + 10, MaxI(F - 11 * D, B + 7 * D), Y + 21, C_DARK);
      Rect(MinI(F - 11 * D, B + 7 * D) + 1, Y + 11, MaxI(F - 11 * D, B + 7 * D) - 1, Y + 20, C);
      Rect(F, Y + 8, F, Y + 10, C_LIGHT); Rect(F, Y + 21, F, Y + 23, C_LIGHT);
      Rect(B, Y + 8, B, Y + 10, C_RED); Rect(B, Y + 21, B, Y + 23, C_RED);
    End;
  End;
End;

{ tronc flottant }
Procedure DrawLog(X, Y, Len, Id : LongInt);
Var K, Gx : LongInt;
Begin
  Rect(X + 4, Y + 25, X + Len - 3, Y + 28, C_WATER);
  Disc(X + 11, Y + 16, 11, C_LOG2); Disc(X + Len - 12, Y + 16, 11, C_LOG2);
  Rect(X + 11, Y + 5, X + Len - 12, Y + 27, C_LOG2);
  Rect(X + 11, Y + 6, X + Len - 12, Y + 25, C_LOG1);
  Disc(X + 11, Y + 16, 10, C_LOG1);
  Rect(X + 9, Y + 7, X + Len - 12, Y + 10, C_LOG0);
  { veines du bois }
  For K := 0 To Len Div 20 Do
  Begin
    Gx := X + 14 + ((K * 37 + Id * 11) Mod (Len - 30 + 1));
    Rect(Gx, Y + 13 + (K Mod 3) * 3, Gx + 10 + (K Mod 4) * 2, Y + 13 + (K Mod 3) * 3, C_LOG2);
  End;
  { bout coupe (anneaux) }
  Disc(X + Len - 12, Y + 16, 10, C_LOGE);
  Disc(X + Len - 12, Y + 16, 7, C_LOG0);
  Disc(X + Len - 12, Y + 16, 5, C_LOGE);
  Disc(X + Len - 12, Y + 16, 2, C_LOG0);
  { branche cassee }
  Rect(X + Len Div 2, Y + 3, X + Len Div 2 + 3, Y + 6, C_LOG1);
End;

{ tortue ; Su : 0 en surface, 1 a demi plongee, 2 sous l'eau ; D : sens de la nage }
Procedure DrawTurtle(Cx, Cy, Su, D, T : LongInt);
Var Fl : LongInt;
Begin
  If Su = 2 Then
  Begin
    Ring(Cx, Cy, 6 + (T Div 4) Mod 3, C_WATERL);
    Exit;
  End;
  If Su = 1 Then
  Begin
    Disc(Cx, Cy, 10, C_TURTU);
    Disc(Cx, Cy, 6, C_TURT0);
    Ring(Cx, Cy, 11, C_WAVE);
    Exit;
  End;
  Fl := (T Div 5) Mod 2;
  { nageoires }
  Rect(Cx - 9 + Fl * 2, Cy - 12, Cx - 5 + Fl * 2, Cy - 9, C_TURTS);
  Rect(Cx + 5 - Fl * 2, Cy - 12, Cx + 9 - Fl * 2, Cy - 9, C_TURTS);
  Rect(Cx - 9 - Fl * 2, Cy + 9, Cx - 5 - Fl * 2, Cy + 12, C_TURTS);
  Rect(Cx + 5 + Fl * 2, Cy + 9, Cx + 9 + Fl * 2, Cy + 12, C_TURTS);
  { tete }
  Disc(Cx + 12 * D, Cy, 3, C_TURTS);
  Pix(Cx + 13 * D, Cy - 1, C_BLACK); Pix(Cx + 13 * D, Cy + 1, C_BLACK);
  { carapace }
  Disc(Cx + 1, Cy + 2, 10, C_SHADOW);
  Disc(Cx, Cy, 10, C_TURT0);
  Disc(Cx, Cy, 7, C_TURT1);
  Disc(Cx, Cy, 3, C_TURT0);
  Rect(Cx - 7, Cy, Cx - 4, Cy, C_TURT0); Rect(Cx + 4, Cy, Cx + 7, Cy, C_TURT0);
  Rect(Cx, Cy - 7, Cx, Cy - 4, C_TURT0); Rect(Cx, Cy + 4, Cx, Cy + 7, C_TURT0);
  Pix(Cx - 3, Cy - 6, C_FROG2);
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
  FillChar(SndLen, SizeOf(SndLen), 0);
  SndPrio := 1; MakeTone(0, 480, 760, 35, 60);        { saut }
  SndPrio := 3; MakeNoise(1, 230, 120, 5);            { ecrasee }
  SndPrio := 3; MakeNoise(2, 320, 90, 1);             { plouf }
  SndPrio := 4; MakeTone(3, 600, 1300, 220, 80);      { nenuphar }
  SndPrio := 5; MakeTone(4, 400, 1700, 420, 90);      { niveau termine }
  SndPrio := 5; MakeTone(5, 520, 140, 650, 90);       { partie terminee }
  SndPrio := 4; MakeTone(6, 900, 1500, 160, 80);      { vie de plus }
  SndPrio := 2; MakeTone(7, 1100, 1100, 30, 40);      { temps presque ecoule }
End;

{ ==================================================================== }
{ Voies et objets                                                       }
{ ==================================================================== }

Function BayC(I : LongInt) : LongInt;
Begin
  BayC := 32 + I * 88;
End;

{ multiplicateur de vitesse (en seiziemes) selon le niveau et la difficulte }
Function SpeedMul : LongInt;
Var M : LongInt;
Begin
  M := 12 + Diff * 4 + (Level - 1) * 3;
  If M > 44 Then M := 44;
  SpeedMul := M;
End;

Procedure SetLane(R, Kind, Style, N, Len, Spd, M, Off : LongInt);
Var K : LongInt;
Begin
  LKind[R] := Kind; LStyle[R] := Style; LN[R] := N; LaneLen[R] := Len; LBase[R] := Spd;
  LPer[R] := BW + M;
  LSpd[R] := Spd * SpeedMul Div 16;
  If LSpd[R] = 0 Then LSpd[R] := Spd;
  For K := 0 To 3 Do
  Begin
    ObX[R * 4 + K] := (((K * LPer[R]) Div N + Off) Mod LPer[R]) * 16;
    ObDive[R * 4 + K] := 0; ObPh[R * 4 + K] := K * 53 + R * 17;
  End;
End;

Procedure SetupLanes;
Var R, N1 : LongInt;
Begin
  For R := 0 To NRow - 1 Do
  Begin
    LKind[R] := K_NONE; LN[R] := 0; LSpd[R] := 0; LaneLen[R] := 0; LPer[R] := BW;
  End;
  If Level >= 3 Then N1 := 4 Else N1 := 3;
  { route : rangees 7 a 10 (vitesses en seiziemes de point par image) }
  SetLane(10, K_CAR, V_CAR, N1, 30, -14, 96, 40);
  SetLane(9, K_CAR, V_TRACT, 3, 30, 10, 96, 150);
  SetLane(8, K_CAR, V_RACER, 2, 30, -34, 96, 10);
  SetLane(7, K_CAR, V_TRUCK, 2, 62, 16, 128, 220);
  { riviere : rangees 1 a 5 }
  SetLane(5, K_TURT, 3, 3, 90, -14, 128, 60);
  SetLane(4, K_LOG, 0, 3, 84, 10, 128, 30);
  SetLane(3, K_LOG, 0, 2, 150, 22, 192, 100);
  SetLane(2, K_TURT, 2, 4, 60, -16, 128, 0);
  SetLane(1, K_LOG, 0, 3, 116, 14, 128, 200);
  { tortues qui plongent : un groupe (deux a partir du niveau 3) }
  ObDive[5 * 4 + 1] := 1; ObDive[2 * 4 + 2] := 1;
  If Level >= 3 Then Begin ObDive[5 * 4 + 2] := 1; ObDive[2 * 4 + 0] := 1; End;
End;

{ position (abscisse a l'ecran) de l'objet I de la rangee R dans T images }
Function ObSX(R, I, T : LongInt) : LongInt;
Var P, X : LongInt;
Begin
  P := LPer[R] * 16;
  X := (ObX[I] + LSpd[R] * T) Mod P;
  If X < 0 Then X := X + P;
  ObSX := X Div 16 - (LPer[R] - BW);
End;

{ etat de plongee d'un groupe de tortues dans T images : 0 surface, 1 a demi, 2 sous l'eau }
Function DiveSt(I, T : LongInt) : LongInt;
Var P, R : LongInt;
Begin
  R := 0;
  If ObDive[I] <> 0 Then
  Begin
    P := (GTick + T + ObPh[I]) Mod 180;
    If P >= 160 Then R := 1
    Else If P >= 130 Then R := 2
    Else If P >= 110 Then R := 1;
  End;
  DiveSt := R;
End;

Procedure MoveObjects;
Var R, K, I, P : LongInt;
Begin
  For R := 1 To 10 Do
    For K := 0 To LN[R] - 1 Do
    Begin
      I := R * 4 + K;
      P := LPer[R] * 16;
      ObX[I] := ObX[I] + LSpd[R];
      If ObX[I] < 0 Then ObX[I] := ObX[I] + P;
      If ObX[I] >= P Then ObX[I] := ObX[I] - P;
    End;
End;

{ un vehicule de la rangee R touche-t-il [A, B] dans T images ? }
Function CarHit(R, A, B, T : LongInt) : Boolean;
Var K, X, Hit : LongInt;
Begin
  Hit := 0;
  If LKind[R] = K_CAR Then
    For K := 0 To LN[R] - 1 Do
    Begin
      X := ObSX(R, R * 4 + K, T);
      If (X + 2 <= B) And (X + LaneLen[R] - 3 >= A) Then Hit := 1;
    End;
  CarHit := Hit <> 0;
End;

{ un tronc ou une tortue porte-t-il le point Cx de la rangee R dans T images (Mg : marge aux bouts) ?
  Strict : tortues a demi plongees refusees }
Function Floats(R, Cx, T, Mg : LongInt; Strict : Boolean) : Boolean;
Var K, X, I, F, Dv : LongInt;
Begin
  F := 0;
  For K := 0 To LN[R] - 1 Do
  Begin
    I := R * 4 + K;
    X := ObSX(R, I, T);
    If (Cx >= X + Mg) And (Cx < X + LaneLen[R] - Mg) Then
    Begin
      Dv := DiveSt(I, T);
      If (Dv = 0) Or ((Dv = 1) And Not Strict) Then F := 1;
    End;
  End;
  Floats := F <> 0;
End;

Function FrogCx : LongInt;
Begin
  FrogCx := FrX Div 16 + 16;
End;

{ ==================================================================== }
{ Deroulement                                                           }
{ ==================================================================== }

Procedure SetMsg;
Begin
  If Paused <> 0 Then Begin Msg := 'Pause : P pour reprendre.'; Exit; End;
  Case State Of
    S_START, S_PLAY :
      If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur guide la grenouille (Options).'
      Else Msg := 'Fl' + Chr(138) + 'ches : sauter. Atteignez les cinq n' + Chr(130) + 'nuphars de l''autre rive.';
    S_OVER : Msg := 'Partie termin' + Chr(130) + 'e : ' + IStr(Score) + ' points. F2 : nouvelle partie.';
  End;
End;

Procedure Show(S1, S2 : String; C : LongInt);
Begin
  Banner := S1; Banner2 := S2; BannerC := C;
End;

Procedure AddScore(P : LongInt);
Begin
  Score := Score + P;
  If Score > HiScore Then HiScore := Score;
  While Score >= NextLife Do
  Begin
    NextLife := NextLife + 5000;
    If Lives < 6 Then
    Begin
      Inc(Lives);
      PlaySnd(6);
    End;
  End;
End;

Procedure Respawn;
Begin
  FrRow := 11; FrX := StartX * 16; FrDir := 0; HopT := 0; MaxRow := 11; NextMove := -1;
  TimeLeft := TimeMax;
End;

Procedure StartLevel;
Var I : LongInt;
Begin
  For I := 0 To 4 Do BayFull[I] := 0;
  Homes := 0; FlyBay := -1; FlyT := 200;
  TimeMax := (65 - (Level - 1) * 3 - Diff * 5) * 25;
  If TimeMax < 900 Then TimeMax := 900;
  SetupLanes;
  Respawn;
End;

Procedure NewGame;
Begin
  Diff := NextDiff;
  Score := 0; Lives := 5 - Diff;
  NextLife := 5000; Deaths := 0; HomesAll := 0; Paused := 0;
  Level := FirstLevel;
  StartLevel;
  State := S_START; StT := 50;
  Show('Niveau ' + IStr(Level), 'Pr' + Chr(136) + 'te ? Fl' + Chr(138) + 'ches pour sauter', C_YELLOW);
  SetMsg;
  Dirty := 1;
End;

Procedure Die(C : LongInt);
Begin
  State := S_DYING; DieT := 0; DieCause := C;
  DieX := FrogCx; DieY := FrRow * Cell + 16;
  If HopT > 0 Then DieY := (Row0 * Cell + (Row1 - Row0) * Cell * HopT Div HopN) + 16;
  HopT := 0; NextMove := -1;
  Dec(Lives); Inc(Deaths);
  If C = D_WATER Then PlaySnd(2) Else PlaySnd(1);
  Case C Of
    D_CAR : Msg := 'A' + Chr(239) + 'e ! Ecras' + Chr(130) + 'e par un v' + Chr(130) + 'hicule.';
    D_WATER : Msg := 'Plouf ! Cette grenouille ne sait pas nager dans le courant.';
    D_OUT : Msg := 'Emport' + Chr(130) + 'e hors de l''' + Chr(130) + 'cran par le courant.';
    D_TIME : Msg := 'Temps ' + Chr(130) + 'coul' + Chr(130) + ' !';
    D_HEDGE : Msg := 'Bloqu' + Chr(130) + 'e par la haie : visez un n' + Chr(130) + 'nuphar.';
    D_TAKEN : Msg := 'Ce n' + Chr(130) + 'nuphar est d' + Chr(130) + 'j' + Chr(133) + ' occup' + Chr(130) + '.';
  End;
  If Lives > 0 Then Msg := Msg + ' Il reste ' + IStr(Lives) + ' grenouille(s).';
  Dirty := 1;
End;

{ arrivee sur la rive : nenuphar libre, occupe ou haie }
Procedure Arrive;
Var I, B, Cx, P : LongInt;
Begin
  Cx := FrogCx; B := -1;
  For I := 0 To 4 Do
    If Abs(Cx - BayC(I)) <= 16 Then B := I;
  If B < 0 Then Begin Die(D_HEDGE); Exit; End;
  If BayFull[B] <> 0 Then Begin Die(D_TAKEN); Exit; End;
  BayFull[B] := 1; Inc(Homes); Inc(HomesAll); LastHome := B;
  P := 50 + TimeLeft Div 25;
  Msg := 'N' + Chr(130) + 'nuphar atteint : ' + IStr(P) + ' points';
  If FlyBay = B Then
  Begin
    P := P + 200; FlyBay := -1; FlyT := 250;
    Msg := Msg + ' (+ 200 pour la mouche !)';
  End;
  AddScore(P);
  Msg := Msg + '.';
  If Homes >= 5 Then
  Begin
    AddScore(1000);
    PlaySnd(4);
    Inc(Level);
    StartLevel;
    State := S_LEVEL; StT := 75;
    Show('Niveau ' + IStr(Level), 'Les cinq n' + Chr(130) + 'nuphars sont occup' + Chr(130) + 's : + 1000', C_YELLOW);
    Msg := 'Bravo ! Niveau ' + IStr(Level) + ' : plus vite et moins de temps.';
  End
  Else
  Begin
    PlaySnd(3);
    Respawn;
    State := S_HOMEP; StT := 12;
  End;
  Dirty := 1;
End;

Procedure StartHop(D : LongInt);
Var R, X : LongInt;
Begin
  R := FrRow; X := FrX;
  Case D Of
    0 : R := R - 1;
    2 : R := R + 1;
    1 : X := X + Cell * 16;
    3 : X := X - Cell * 16;
  End;
  FrDir := D;
  If (R < 0) Or (R > 11) Then Exit;
  If X < 0 Then X := 0;
  If X > (BW - Cell) * 16 Then X := (BW - Cell) * 16;
  Row0 := FrRow; Row1 := R; X0 := FrX; X1 := X;
  HopT := 1;
  PlaySnd(0);
End;

{ verifie la grenouille a sa place actuelle }
Procedure Check;
Var R, Cx : LongInt;
Begin
  Cx := FrogCx;
  If HopT > 0 Then
  Begin
    If HopT * 2 >= HopN Then R := Row1 Else R := Row0;
  End
  Else R := FrRow;
  If (R >= 7) And (R <= 10) Then
    If CarHit(R, Cx - 10, Cx + 10, 0) Then Begin Die(D_CAR); Exit; End;
  If (HopT = 0) And (R >= 1) And (R <= 5) Then
  Begin
    If (Cx < 4) Or (Cx > BW - 4) Then Begin Die(D_OUT); Exit; End;
    If Not Floats(R, Cx, 0, 3, False) Then Begin Die(D_WATER); Exit; End;
  End;
End;

Procedure AiThink; Forward;

{ une image du jeu (1/25 s) }
Procedure Step;
Var I, Tries : LongInt;
Begin
  If (Paused <> 0) Or (State = S_OVER) Then Exit;
  Inc(GTick);
  MoveObjects;
  Case State Of
    S_START, S_LEVEL, S_HOMEP :
      Begin
        Dec(StT);
        If StT <= 0 Then
        Begin
          State := S_PLAY; Banner := '';
          SetMsg;
          Dirty := 1;
        End;
      End;
    S_DYING :
      Begin
        Inc(DieT);
        If DieT >= 32 Then
        Begin
          If Lives <= 0 Then
          Begin
            State := S_OVER;
            PlaySnd(5);
            Show('Partie termin' + Chr(130) + 'e', IStr(Score) + ' points - F2 : nouvelle partie', C_WHITE);
            SetMsg;
          End
          Else
          Begin
            Respawn;
            State := S_PLAY;
            SetMsg;
          End;
        End;
      End;
    S_PLAY :
      Begin
        { mouche sur un nenuphar libre }
        Dec(FlyT);
        If FlyT <= 0 Then
        Begin
          If FlyBay >= 0 Then
          Begin
            FlyBay := -1; FlyT := 150 + Rnd(200);
          End
          Else
          Begin
            Tries := 0; I := Rnd(5);
            While (BayFull[I] <> 0) And (Tries < 5) Do Begin I := (I + 1) Mod 5; Inc(Tries); End;
            If BayFull[I] = 0 Then FlyBay := I;
            FlyT := 150;
          End;
        End;
        Dec(TimeLeft);
        If (TimeLeft = 250) Or (TimeLeft = 125) Then PlaySnd(7);
        If TimeLeft <= 0 Then Begin Die(D_TIME); Exit; End;
        If HopT > 0 Then
        Begin
          Inc(HopT);
          If HopT >= HopN Then
          Begin
            HopT := 0; FrRow := Row1; FrX := X1;
            If FrRow < MaxRow Then
            Begin
              AddScore(10 * (MaxRow - FrRow));
              MaxRow := FrRow;
            End;
            If FrRow = 0 Then Begin Arrive; Exit; End;
          End;
        End
        Else If (FrRow >= 1) And (FrRow <= 5) Then FrX := FrX + LSpd[FrRow];
        Check;
        If State <> S_PLAY Then Exit;
        If HopT = 0 Then
        Begin
          If AutoAll <> 0 Then AiThink;
          If NextMove >= 0 Then
          Begin
            I := NextMove; NextMove := -1;
            StartHop(I);
          End;
        End;
      End;
  End;
End;

{ ==================================================================== }
{ Pilote automatique (demonstration et essais)                          }
{ ==================================================================== }

{ la grenouille posee en (R, Cx) a l'image T0 est-elle sauve a l'image T ? }
Function FrogOk(R, Cx, T0, T : LongInt) : Boolean;
Var Ok : Boolean; X : LongInt;
Begin
  Ok := True;
  If (R >= 7) And (R <= 10) Then Ok := Not CarHit(R, Cx - 15, Cx + 15, T)
  Else If (R >= 1) And (R <= 5) Then
  Begin
    X := Cx + LSpd[R] * (T - T0) Div 16;
    Ok := (X >= 14) And (X <= BW - 14) And Floats(R, X, T, 8, True);
  End;
  FrogOk := Ok;
End;

{ le saut D (ou -1 : rester) est-il sur ? }
Function MoveSafe(D : LongInt) : Boolean;
Var R, Cx, Nx, T, I : LongInt; Ok : Boolean;
Begin
  R := FrRow; Cx := FrogCx; Ok := True;
  If D < 0 Then
  Begin
    T := 0;
    While Ok And (T <= 16) Do
    Begin
      If Not FrogOk(R, Cx, 0, T) Then Ok := False;
      T := T + 2;
    End;
    MoveSafe := Ok;
    Exit;
  End;
  Nx := Cx;
  Case D Of
    0 : R := R - 1;
    2 : R := R + 1;
    1 : Nx := Cx + Cell;
    3 : Nx := Cx - Cell;
  End;
  If (R < 0) Or (R > 11) Or (Nx < 16) Or (Nx > BW - 16) Then Begin MoveSafe := False; Exit; End;
  If R = 0 Then
  Begin
    Ok := False;
    For I := 0 To 4 Do
      If (BayFull[I] = 0) And (Abs(Cx - BayC(I)) <= 10) Then Ok := True;
    MoveSafe := Ok;
    Exit;
  End;
  { le saut est decide pendant l'image 0 et la grenouille se pose a l'image HopN - 1 }
  If (FrRow >= 7) And (FrRow <= 10) Then
    For T := 0 To 2 Do
      If Not FrogOk(FrRow, Cx, 0, T) Then Ok := False;
  T := 2;
  While Ok And (T <= HopN + 20) Do
  Begin
    If (R >= 1) And (R <= 5) Then
    Begin
      If T >= HopN - 1 Then
        If Not FrogOk(R, Nx, HopN - 1, T) Then Ok := False;
    End
    Else If Not FrogOk(R, Nx, HopN - 1, T) Then Ok := False;
    Inc(T);
  End;
  MoveSafe := Ok;
End;

Procedure AiThink;
Var D, Best, Bs, V, Cx, Tg, I : LongInt;
Begin
  If (HopT > 0) Or (NextMove >= 0) Then Exit;
  If GTick Mod 3 <> 0 Then Exit;
  Cx := FrogCx;
  { nenuphar libre le plus proche (la mouche d'abord) }
  Tg := -1;
  For I := 0 To 4 Do
    If BayFull[I] = 0 Then
      If (Tg < 0) Or (Abs(BayC(I) - Cx) < Abs(Tg - Cx)) Then Tg := BayC(I);
  If (FlyBay >= 0) And (FrRow <= 5) Then Tg := BayC(FlyBay);
  If Tg < 0 Then Tg := Cx;
  Best := -99; Bs := -2;
  For D := -1 To 3 Do
  Begin
    V := -99;
    If MoveSafe(D) Then
      Case D Of
        -1 : V := 2;
        0 : V := 10;
        2 : V := 0;
        1 : If Cx < Tg - 10 Then V := 4 Else V := 1;
        3 : If Cx > Tg + 10 Then V := 4 Else V := 1;
      End;
    If V > Best Then Begin Best := V; Bs := D; End;
  End;
  If Best < -50 Then Exit;   { rien de sur : rester en esperant }
  If Bs >= 0 Then NextMove := Bs;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Function Tex(X, Y, N : LongInt) : LongInt;
Begin
  Tex := ((X * 7 + Y * 13 + (X * Y) Mod 11 + (X Div 5) * (Y Div 3)) Mod N);
End;

{ decor fixe : haie et nenuphars, riviere, berge, route, trottoir, bande du temps }
Procedure RenderBack;
Var X, Y, I, C, B : LongInt;
Begin
  For Y := 0 To BH - 1 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := 0 To BW - 1 Do
    Begin
      If Y < 32 Then C := C_HEDGE + Tex(X, Y, 3)
      Else If Y < 192 Then
      Begin
        C := C_WATER + 1 + Tex(X Div 6, Y Div 2, 5) Div 4;
        If ((Y - 32) Mod 32 < 2) Then C := C_WATER;
      End
      Else If Y < 224 Then C := C_GRASS + Tex(X, Y, 3)
      Else If Y < 352 Then C := C_ROAD + Tex(X, Y, 5) Div 2
      Else If Y < 384 Then
      Begin
        If ((X + ((Y - 352) Div 16) * 16) Mod 32 < 31) And ((Y - 352) Mod 16 < 15) Then
        Begin
          If ((X Div 32) + ((Y - 352) Div 16)) Mod 2 = 0 Then C := C_WALK0 Else C := C_WALK1;
        End
        Else C := C_WALKL;
      End
      Else C := C_BAND;
      Fb[B + X] := C;
    End;
  End;
  { haie : feuilles plus claires, bord ombre sur l'eau }
  For I := 0 To 90 Do Disc((I * 89) Mod BW, 3 + (I * 7) Mod 26, 1 + I Mod 2, C_HEDGE + 2);
  Rect(0, 30, BW - 1, 33, C_SHADOW);
  { baies et nenuphars }
  For I := 0 To 4 Do
  Begin
    X := BayC(I);
    Rect(X - 21, 4, X + 20, 31, C_HEDGE);
    Rect(X - 19, 6, X + 18, 33, C_WATER + 1);
    Rect(X - 19, 6, X + 18, 7, C_WATER);
    Disc(X, 20, 12, C_PADD);
    Disc(X, 19, 11, C_PAD);
    Rect(X + 1, 17, X + 12, 20, C_WATER + 1);
    TLine(X - 7, 19, X - 1, 19, 0, C_PADD); TLine(X, 12, X, 18, 0, C_PADD);
  End;
  { reflets fixes sur l'eau }
  For I := 0 To 60 Do
  Begin
    X := (I * 131) Mod BW; Y := 38 + (I * 47) Mod 150;
    Rect(X, Y, X + 4 + I Mod 5, Y, C_WATERL);
  End;
  { berge : pierres en bordure, fleurs }
  For X := 0 To BW Div 12 Do
  Begin
    Disc(X * 12 + 5, 193, 4, C_STONED); Disc(X * 12 + 5, 192, 3, C_STONE);
    Disc(X * 12 + 11, 223, 3, C_STONED); Disc(X * 12 + 11, 222, 2, C_STONE);
  End;
  For I := 0 To 18 Do
  Begin
    X := 10 + (I * 97) Mod (BW - 20); Y := 201 + (I * 13) Mod 14;
    Pix(X, Y, C_FLOWER); Pix(X - 1, Y, C_EYE); Pix(X + 1, Y, C_EYE); Pix(X, Y - 1, C_EYE); Pix(X, Y + 1, C_EYE);
  End;
  { route : bordures, lignes pointillees, ligne jaune au centre }
  Rect(0, 224, BW - 1, 226, C_STONE);
  Rect(0, 228, BW - 1, 229, C_LINE);
  Rect(0, 347, BW - 1, 348, C_LINE);
  Rect(0, 350, BW - 1, 355, C_STONE); Rect(0, 355, BW - 1, 355, C_STONED);
  For X := 0 To BW Div 32 Do
  Begin
    Rect(X * 32 + 4, 255, X * 32 + 20, 256, C_LINE);
    Rect(X * 32 + 4, 319, X * 32 + 20, 320, C_LINE);
  End;
  Rect(0, 286, BW - 1, 287, C_YLINE); Rect(0, 289, BW - 1, 290, C_YLINE);
  { bande du temps }
  Rect(0, 384, BW - 1, 384, C_SHADOW);
  FbText(8, 384, 'TEMPS', C_TEXT, 1);
  Move(Fb, Back, SizeOf(Fb));
End;

Procedure DrawBanner;
Var W, X, Y, H : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(Length(Banner) * 16, Length(Banner2) * 8) + 40;
  If W > BW - 12 Then W := BW - 12;
  H := 70; If Banner2 = '' Then H := 52;
  X := (BW - W) Div 2; Y := 196 - H Div 2;
  Rect(X + 4, Y + 4, X + W + 3, Y + H + 3, C_SHADOW);
  Rect(X, Y, X + W - 1, Y + H - 1, C_BANNER);
  Rect(X, Y, X + W - 1, Y + 1, C_BANNERE); Rect(X, Y + H - 2, X + W - 1, Y + H - 1, C_BANNERE);
  Rect(X, Y, X + 1, Y + H - 1, C_BANNERE); Rect(X + W - 2, Y, X + W - 1, Y + H - 1, C_BANNERE);
  FbTextSh(X + (W - Length(Banner) * 16) Div 2, Y + 10, Banner, BannerC, 2);
  If Banner2 <> '' Then FbTextSh(X + (W - Length(Banner2) * 8) Div 2, Y + 46, Banner2, C_WHITE, 1);
End;

Procedure Render;
Var R, K, I, X, Y, J, N, D, Cx, Cy, W, C : LongInt;
Begin
  Move(Back, Fb, SizeOf(Fb));
  { vaguelettes qui suivent le courant }
  For R := 1 To 5 Do
    For K := 0 To 4 Do
    Begin
      X := (K * 89 + R * 41 + (GTick * LSpd[R]) Div 40) Mod BW;
      If X < 0 Then X := X + BW;
      Y := R * 32 + 6 + (K Mod 3) * 9;
      Rect(X, Y, X + 5, Y, C_WAVE); Rect(X + 2, Y - 1, X + 3, Y - 1, C_WAVE);
    End;
  { nenuphars occupes, mouche }
  For I := 0 To 4 Do
    If BayFull[I] <> 0 Then DrawFrog(BayC(I), 19, 2, 0);
  If (FlyBay >= 0) And (State <> S_OVER) Then DrawFly(BayC(FlyBay), 19, GTick);
  { troncs, tortues, vehicules }
  For R := 1 To 10 Do
    For K := 0 To LN[R] - 1 Do
    Begin
      I := R * 4 + K;
      X := ObSX(R, I, 0); Y := R * 32;
      If LSpd[R] > 0 Then D := 1 Else D := -1;
      Case LKind[R] Of
        K_LOG : DrawLog(X, Y, LaneLen[R], I);
        K_TURT :
          Begin
            N := LaneLen[R] Div 30;
            For J := 0 To N - 1 Do DrawTurtle(X + J * 30 + 15, Y + 16, DiveSt(I, 0), D, GTick + J * 3);
          End;
        K_CAR : DrawVehicle(X, Y, LaneLen[R], LStyle[R], D, K Mod 2);
      End;
    End;
  { grenouille }
  If (State = S_PLAY) Or (State = S_START) Or (State = S_HOMEP) Or (State = S_LEVEL) Then
  Begin
    If HopT > 0 Then
    Begin
      Cx := (X0 + (X1 - X0) * HopT Div HopN) Div 16 + 16;
      Cy := Row0 * Cell + (Row1 - Row0) * Cell * HopT Div HopN + 16;
      DrawFrog(Cx, Cy, FrDir, 1);
    End
    Else DrawFrog(FrogCx, FrRow * Cell + 16, FrDir, 0);
  End
  Else If State = S_DYING Then
  Begin
    If (DieCause = D_WATER) Or (DieCause = D_OUT) Then DrawSplash(DieX, DieY, DieT)
    Else DrawSplat(DieX, DieY, DieT);
  End;
  { temps restant }
  W := BW - 64;
  Rect(55, 387, 56 + W, 396, C_SHADOW);
  Rect(56, 388, 55 + W, 395, C_DARK);
  If TimeMax > 0 Then
  Begin
    K := W * TimeLeft Div TimeMax;
    If K < 0 Then K := 0;
    C := C_BAR;
    If TimeLeft * 2 < TimeMax Then C := C_BARW;
    If TimeLeft * 5 < TimeMax Then C := C_BARR;
    If (TimeLeft < 250) And ((GTick Div 6) Mod 2 = 0) And (State = S_PLAY) Then C := C_YELLOW;
    If K > 0 Then
    Begin
      Rect(56, 388, 55 + K, 395, C);
      Rect(56, 388, 55 + K, 389, C_WHITE);
    End;
  End;
  DrawBanner;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Procedure BlitAll(H : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  P[0] := OX; P[1] := CH - OY - BH; P[2] := OX + BW; P[3] := CH - OY;
  P[4] := 0; P[5] := 0; P[6] := BW; P[7] := BH;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure InfoLine(Y : LongInt; L, V : String; C : LongInt);
Begin
  FBar(PnX + 6, Y, PnX + PW - 7, Y + 15, CLR_PALEGRAY);
  OutTxt(PnX + 8, Y, L, CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX + PW - 10 - Length(V) * 8, Y, V, C, CLR_PALEGRAY);
End;

Procedure DrawInfo;
Var S : String;
Begin
  InfoLine(74, 'Pointage', IStr(Score), CLR_DARKBLUE);
  InfoLine(94, 'Record', IStr(HiScore), CLR_DARKBLUE);
  InfoLine(114, 'Niveau', IStr(Level), CLR_DARKBLUE);
  InfoLine(134, 'N' + Chr(130) + 'nuphars', IStr(Homes) + ' / 5', CLR_DARKGREEN);
  InfoLine(154, 'Grenouilles', IStr(MaxI(Lives, 0)), CLR_DARKRED);
  Case Diff Of
    0 : S := 'facile';
    2 : S := 'difficile';
  Else
    S := 'normal';
  End;
  InfoLine(186, 'Jeu', S, CLR_DARKGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 10 * 16) Div 2, 4, 'Grenouille', CLR_DARKGREEN, CLR_PALEGRAY);
  OutTxt(PnX + (PW - 16 * 8) Div 2, 40, 'route et rivi' + Chr(138) + 're', CLR_DARKGRAY, CLR_PALEGRAY);
  Edge(PnX, 68, PnX + PW - 1, 176, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX, 182, PnX + PW - 1, 205, CLR_DARKGRAY, CLR_WHITE);
  DrawInfo;
  Button(PnX, 300, PW, 28, 'Nouvelle partie');
  Button(PnX, 334, PW, 28, 'Pause');
  Button(PnX, 368, PW, 28, 'R' + Chr(138) + 'gles');
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Function Sig : LongInt;
Begin
  Sig := Score * 3 + HiScore * 7 + Level * 1009 + Lives * 10007 + Homes * 100003 + Diff * 13;
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(OX - 1, OY - 1, OX + BW, OY + BH, CLR_BLACK, CLR_PALEGRAY);
  Render;
  BlitAll(Hps);
  Dirty := 0;
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
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If (Paused = 0) Or (Dirty <> 0) Then
  Begin
    Render;
    BlitAll(Hps);
    Dirty := 0;
  End;
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
{ Commandes                                                             }
{ ==================================================================== }

Procedure TogglePause;
Begin
  If State = S_OVER Then Exit;
  Paused := 1 - Paused;
  If Paused <> 0 Then
  Begin
    SavB := Banner; SavB2 := Banner2; SavBC := BannerC;
    Show('Pause', 'P ou le bouton Pause pour reprendre', C_YELLOW);
  End
  Else
  Begin
    Banner := SavB; Banner2 := SavB2; BannerC := SavBC;
  End;
  SetMsg;
  Dirty := 1;
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  Step;
  If (State = S_OVER) And (AutoAll <> 0) Then
  Begin
    Inc(StT);
    If StT > 100 Then NewGame;
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
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0); SetMark(CM_PAUSE, Paused <> 0);
  SetMark(CM_EASY, NextDiff = 0); SetMark(CM_NORMAL, NextDiff = 1); SetMark(CM_HARD, NextDiff = 2);
End;

{ demande de saut (clavier ou souris) }
Procedure Want(D : LongInt);
Begin
  If (Paused <> 0) Or (AutoAll <> 0) Then Exit;
  If State = S_START Then
  Begin
    State := S_PLAY; Banner := ''; SetMsg; Dirty := 1;
  End;
  If State = S_PLAY Then NextMove := D;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : Begin NewGame; SetMarks; End;
    CM_PAUSE : Begin TogglePause; SetMarks; End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_EASY, CM_NORMAL, CM_HARD :
      Begin
        NextDiff := Id - CM_EASY;
        SetMarks;
        If (Score = 0) And (Level = FirstLevel) And (Homes = 0) Then NewGame
        Else Msg := 'La nouvelle difficult' + Chr(130) + ' s''appliquera ' + Chr(133) + ' la prochaine partie (F2).';
        Dirty := 1;
      End;
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll; NextMove := -1; SetMarks;
        If AutoAll <> 0 Then
        Begin
          If State = S_OVER Then NewGame;
          If Paused <> 0 Then TogglePause;
        End;
        SetMsg;
      End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Faites traverser la route puis la rivi' + Chr(138) + 're ' + Chr(133) + ' la grenouille pour ' +
             'l''amener sur un des cinq n' + Chr(130) + 'nuphars de l''autre rive.' + Chr(10) + Chr(10));
        LAdd('Sur la route, ' + Chr(130) + 'vitez les voitures, les tracteurs, les bolides et les camions. ' +
             'Dans la rivi' + Chr(138) + 're, sautez sur les troncs et sur le dos des tortues : l''eau est ' +
             'mortelle, et certaines tortues plongent ! Ne vous laissez pas emporter hors de l''' + Chr(130) +
             'cran.' + Chr(10) + Chr(10));
        LAdd('Une grenouille est aussi perdue si elle saute dans la haie, sur un n' + Chr(130) + 'nuphar d' +
             Chr(130) + 'j' + Chr(133) + ' occup' + Chr(130) + ' ou si le temps (barre du bas) est ' + Chr(130) +
             'coul' + Chr(130) + '. Les cinq n' + Chr(130) + 'nuphars occup' + Chr(130) + 's, le niveau suivant ' +
             'est plus rapide.' + Chr(10) + Chr(10));
        LAdd('Points : 10 par rang' + Chr(130) + 'e gagn' + Chr(130) + 'e, 50 par n' + Chr(130) + 'nuphar plus 1 ' +
             'par seconde restante, 200 pour une mouche, 1000 par niveau ; une grenouille de plus tous les ' +
             '5000 points.' + Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches (sauter), P (pause), F2 (nouvelle partie). Souris : cliquez ' +
             'au-dessus, au-dessous ou ' + Chr(133) + ' c' + Chr(147) + 't' + Chr(130) + ' de la grenouille.');
        Dummy := LMsgBox('Grenouille - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Grenouille pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du ' +
                            'prototype FROGGER.PAS de 7iles, d' + Chr(130) + 'cor et personnages ' +
                            'originaux.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et compil' +
                            Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or MB_INFORMATION);
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
    If Vk = VK_PAUSE Then Begin Command(CM_PAUSE); Exit; End;
    If Vk = VK_UP Then Begin Want(0); Exit; End;
    If Vk = VK_RIGHT Then Begin Want(1); Exit; End;
    If Vk = VK_DOWN Then Begin Want(2); Exit; End;
    If Vk = VK_LEFT Then Begin Want(3); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      If State = S_OVER Then Command(CM_NEW)
      Else If State = S_START Then Want(-1);
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'P' : Command(CM_PAUSE);
      'N' : Command(CM_NEW);
      '8' : Want(0);
      '6' : Want(1);
      '2' : Want(2);
      '4' : Want(3);
      ' ' : If State = S_OVER Then Command(CM_NEW);
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, Dx, Dy : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 300) And (Y < 328) Then Command(CM_NEW)
    Else If (Y >= 334) And (Y < 362) Then Command(CM_PAUSE)
    Else If (Y >= 368) And (Y < 396) Then Command(CM_RULES);
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If State = S_OVER Then Begin Command(CM_NEW); Exit; End;
    If Paused <> 0 Then Begin Command(CM_PAUSE); Exit; End;
    Dx := X - OX - FrogCx; Dy := Y - OY - (FrRow * Cell + 16);
    If (Abs(Dx) < 8) And (Abs(Dy) < 8) Then Exit;
    If Abs(Dy) >= Abs(Dx) Then
    Begin
      If Dy < 0 Then Want(0) Else Want(2);
    End
    Else If Dx > 0 Then Want(1) Else Want(3);
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

{ place l'objet K de la rangee R a l'abscisse X de l'ecran }
Procedure PutOb(R, K, X : LongInt);
Begin
  ObX[R * 4 + K] := (X + LPer[R] - BW) * 16;
End;

Procedure TestStart;
Begin
  NewGame;
  State := S_PLAY; Banner := ''; NextMove := -1;
End;

Procedure Steps(N : LongInt);
Var K : LongInt;
Begin
  K := 0;
  While (K < N) And (State = S_PLAY) Do
  Begin
    Step;
    Inc(K);
  End;
End;

Procedure RunTests;
Var Ok, N, S0, Cx : LongInt;
Begin
  Ok := 0; Seed := 1; GTick := 0; FirstLevel := 1; NextDiff := 1; AutoAll := 0;
  { 1 : une voiture ecrase la grenouille }
  TestStart;
  FrRow := 10; PutOb(10, 0, 150); FrX := (150 + 15 - 16) * 16;
  Steps(1);
  Log('GRENOUILLE : TEST1 cause ' + IStr(DieCause) + ' vies ' + IStr(Lives));
  If (State = S_DYING) And (DieCause = D_CAR) And (Lives = 3) Then Inc(Ok);
  { 2 : la grenouille tombe a l'eau entre deux troncs }
  TestStart;
  FrRow := 3; PutOb(3, 0, -190); PutOb(3, 1, 300);
  Steps(1);
  Log('GRENOUILLE : TEST2 cause ' + IStr(DieCause));
  If (State = S_DYING) And (DieCause = D_WATER) Then Inc(Ok);
  { 3 : un tronc emporte la grenouille (vitesse 10/16 de point par image) }
  TestStart;
  FrRow := 4; PutOb(4, 0, 150); PutOb(4, 1, 330); PutOb(4, 2, -100); FrX := (180 - 16) * 16;
  Steps(32);
  Log('GRENOUILLE : TEST3 derive ' + IStr(FrogCx - 180) + ' etat ' + IStr(State));
  If (State = S_PLAY) And (FrogCx = 200) Then Inc(Ok);
  { 4 : saut sur un nenuphar libre }
  TestStart;
  FrRow := 1; MaxRow := 1; PutOb(1, 0, 160); FrX := (BayC(2) - 16) * 16;
  S0 := Score; NextMove := 0;
  Steps(10);
  Log('GRENOUILLE : TEST4 nenuphars ' + IStr(Homes) + ' points ' + IStr(Score - S0) + ' etat ' + IStr(State));
  If (Homes = 1) And (BayFull[2] = 1) And (Score - S0 = 119) And (State = S_HOMEP) Then Inc(Ok);
  { 5 : temps ecoule }
  TestStart;
  TimeLeft := 1;
  Steps(1);
  Log('GRENOUILLE : TEST5 cause ' + IStr(DieCause));
  If (State = S_DYING) And (DieCause = D_TIME) Then Inc(Ok);
  { 6 : dernier nenuphar : niveau suivant }
  TestStart;
  BayFull[0] := 1; BayFull[1] := 1; BayFull[3] := 1; BayFull[4] := 1; Homes := 4;
  FrRow := 1; MaxRow := 1; PutOb(1, 0, 160); FrX := (BayC(2) - 16) * 16;
  S0 := Score; NextMove := 0;
  Steps(10);
  N := LSpd[10];
  Log('GRENOUILLE : TEST6 niveau ' + IStr(Level) + ' points ' + IStr(Score - S0) + ' nenuphars ' + IStr(Homes) +
      ' vitesse ' + IStr(N));
  If (State = S_LEVEL) And (Level = 2) And (Homes = 0) And (Score - S0 = 1119) And (N = -16) Then Inc(Ok);
  { 7 : la haie entre deux nenuphars }
  FirstLevel := 1;
  TestStart;
  FrRow := 1; MaxRow := 1; PutOb(1, 0, 40); Cx := BayC(0) + 44; FrX := (Cx - 16) * 16;
  NextMove := 0;
  Steps(10);
  Log('GRENOUILLE : TEST7 cause ' + IStr(DieCause));
  If (State = S_DYING) And (DieCause = D_HEDGE) Then Inc(Ok);
  { partie jouee par l'ordinateur (graine fixe) }
  Seed := 2026; GTick := 0; AutoAll := 1;
  NewGame;
  N := 0;
  While (State <> S_OVER) And (N < 60000) Do
  Begin
    Step;
    Inc(N);
  End;
  Log('GRENOUILLE : PARTIE images ' + IStr(N) + ' niveau ' + IStr(Level) + ' nenuphars ' + IStr(HomesAll) +
      ' pertes ' + IStr(Deaths) + ' points ' + IStr(Score));
  Log('GRENOUILLE : ' + IStr(Ok) + '/7 essais reussis');
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

{ police 8 x 16 du VGA (VIOCALLS) }
Procedure LoadFont;
Var P, K : LongInt; Inf : Array[0..15] Of Byte;
Begin
  InDlg := 0;
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
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Tick := 0; Client := 0; Frame := 0;
  SoundOn := 1; SndCur := 0; SndEnd := 0; TestMode := 0; InDlg := 0; Paused := 0; HiScore := 0;
  CW := CWant; CH := CHWant; Dirty := 1; State := S_START; GTick := 0; FirstLevel := 1; NextDiff := 1; Diff := 1;
  Level := 1; LastSig := -1;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/LEVEL:') Then
    Begin
      Val(Copy(S, 8, 20), FirstLevel, E);
      If FirstLevel < 1 Then FirstLevel := 1;
      If FirstLevel > 9 Then FirstLevel := 9;
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
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  RenderBack;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('GRENOUIL'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('GRENOUIL'), Z2('Grenouille'), 0, 0, 0,
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
  MItem(MIS_TEXT, 0, CM_EASY, '~Facile');
  MItem(MIS_TEXT, 0, CM_NORMAL, '~Normal');
  MItem(MIS_TEXT, 0, CM_HARD, 'D~ifficile');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Grenouille');
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
  NewGame;
  SetMarks;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
