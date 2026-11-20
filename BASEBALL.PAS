{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BASEBALL - Baseball pour le Presentation Manager d'OS/2-0
                (dossier Jeux du bureau).
}

Program BASEBALL;

{$R-,S-,I-}

{ Compilation : OS2PC BASEBALL.PAS   (produit BASEBALL.EXE)

  Portage vers OS/2-0 du prototype BASEBALL.PAS du depot 7iles (Turbo
  Pascal et BGI : terrain vert, losange, joueurs en points jaunes, Espace
  pour lancer et frapper, + et - pour la puissance) : fenetre de
  Presentation Manager avec menus, terrain dessine (pelouse tondue, terre
  du losange, monticule, lignes de craie, cloture, gradins), joueurs en
  uniformes, balle lancee et frappee, coureurs qui courent d'un but a
  l'autre, tableau de pointage par manche, balles, prises et retraits,
  bruitages (lancer, frappe, gant, retrait, point, foule ; menu Options,
  Son), barre d'etat et apparence d'OS/2.

  Regles du prototype : deux equipes de neuf joueurs (memes noms et memes
  moyennes au baton), neuf manches, trois retraits par demi-manche, quatre
  balles (but sur balles), trois prises (retrait) ; la frappe donne un
  simple, un double, un triple ou un coup de circuit (selon la moyenne du
  frappeur et la qualite du lancer), une prise, une fausse balle ou une
  balle au sol (retrait sept fois sur dix) ; les coureurs avancent d'autant
  de buts que le coup.
  Ce qui est ajoute : vous dirigez une equipe (les Visiteurs, ou l'equipe
  locale : menu Partie) contre l'ordinateur. Au baton, la balle arrive et
  le moment de l'elan compte ; sans elan, le lancer est une prise ou une
  balle (comme le prototype). Au monticule, + et - reglent la puissance
  (comme le prototype) et Espace lance. L'equipe locale ne frappe pas en
  fin de neuvieme si elle mene.

  Clavier : Espace (lancer, ou frapper), + et - (puissance), F2 (nouvelle
  partie), F1 (regles). Souris : clic sur le terrain (lancer ou frapper).
  Parametres : /SEED:n ; /AUTO (l'ordinateur joue les deux equipes) ;
  /NOSOUND (sans bruitages). }

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
  CM_NEW = 101; CM_ACT = 102; CM_QUIT = 104; CM_VIS = 111; CM_DOM = 112;
  CM_SOUND = 201;
  CM_RULES = 301; CM_ABOUT = 302;
  SndRate = 11025;
  { image du terrain }
  BW = 440; BH = 400; OX = 8; OY = 8;
  PnX = 456; PW = 156;
  CWant = 618; CHWant = 436;
  MaxDirty = 60; MaxSpr = 24;
  HX = 220; HY = 372; FenceR = 332;
  { couleurs de l'image }
  C_BLACK = 0; C_WHITE = 1; C_GRASS1 = 2; C_GRASS2 = 3; C_DIRT = 4; C_DIRT2 = 5; C_CHALK = 6; C_STAND = 7;
  C_CROWD = 8; C_WALL = 12; C_WALLTOP = 13; C_RED = 14; C_REDD = 15; C_BLUE = 16; C_BLUED = 17; C_SKIN = 18;
  C_BALL = 19; C_SHADOW = 20; C_BAT = 21; C_GRAY = 22; C_YELLOW = 23; C_BANNER = 24; C_PANTS = 25;
  C_GRASS3 = 26; C_SEAM = 27;
  NPal = 28;
  Pal : Array[0..NPal - 1] Of LongInt = (
    $000000, $FFFFFF, $2E7D32, $3A9440, $B07A48, $8E5E36, $F0F0E6, $3C4048,
    $D23C3C, $E6C83C, $3C78D2, $E6E6E6, $1E5030, $E6C828, $C82828, $781414,
    $2848C8, $142878, $E6B48C, $FAFAFA, $1E4A22, $966432, $808080, $FFE650,
    $14143C, $D2D2D2, $34883A, $DC3232);
  { equipes : 0 Visiteurs (au baton en haut de manche), 1 Locaux }
  S_IDLE = 0; S_PITCH = 1; S_FLY = 2; S_RUN = 3; S_SHOW = 4; S_OVER = 5;
  MaxInnings = 9;
  { resultats }
  R_NONE = 0; R_SINGLE = 1; R_DOUBLE = 2; R_TRIPLE = 3; R_HR = 4; R_STRIKE = 5; R_FOUL = 6; R_GROUND = 7;
  R_BALL = 8; R_LOOK = 9;
  { position des joueurs (prototype : P, C, 1B, 2B, 3B, SS, LF, CF, RF) }
  FX : Array[0..8] Of LongInt = (220, 220, 296, 260, 144, 180, 104, 220, 336);
  FY : Array[0..8] Of LongInt = (300, 396, 290, 222, 290, 222, 146, 104, 146);
  NamesV : Array[0..8] Of String[12] = ('Lopez', 'Brown', 'Taylor', 'Moore', 'Jackson', 'White', 'Harris',
                                        'Clark', 'Lewis');
  AvgV : Array[0..8] Of LongInt = (198, 254, 276, 298, 312, 289, 301, 287, 269);
  NamesD : Array[0..8] Of String[12] = ('Rodriguez', 'Johnson', 'Williams', 'Davis', 'Martinez', 'Garcia',
                                        'Thompson', 'Anderson', 'Wilson');
  AvgD : Array[0..8] Of LongInt = (245, 278, 312, 289, 301, 267, 298, 315, 283);
  { ordre au baton : le lanceur frappe en dernier }
  Order : Array[0..8] Of LongInt = (6, 3, 7, 4, 2, 5, 8, 1, 0);
  { bout du baton (elan : 0 arme ... 7 fini), par rapport aux mains }
  BatX : Array[0..7] Of LongInt = (-8, -14, -16, -12, -2, 10, 16, 14);
  BatY : Array[0..7] Of LongInt = (-16, -10, -2, 6, 10, 8, 0, -8);

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back, Field : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  DX1, DY1, DX2, DY2 : Array[0..MaxDirty - 1] Of LongInt;
  SX1, SY1, SX2, SY2 : Array[0..MaxSpr - 1] Of LongInt;
  NDirty, NSpr : LongInt;
  { partie (prototype) }
  Inning, TopHalf, Outs, Balls, Strikes, You, AutoAll, Seed, Power, CpuPower : LongInt;
  Runs : Array[0..1] Of LongInt;
  Line : Array[0..1, 1..12] Of LongInt;
  Bases : Array[1..3] Of LongInt;
  Batter : Array[0..1] Of LongInt;
  Hits : Array[0..1] Of LongInt;
  { animation }
  State, Frm, NFrm, Swung, SwingF, Result, Wait, Quality : LongInt;
  BallX0, BallY0, BallX1, BallY1, BallH, BallOn : LongInt;
  NRun : LongInt;
  RunFrom, RunTo : Array[0..3] Of LongInt;
  Banner, Banner2, Msg : String;
  BannerC : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  { bruitages }
  SndBuf : Array[0..39999] Of Byte;
  SndOfs, SndLen, SndPri : Array[0..15] Of LongInt;
  NSndBuf, SndPrio, SndCur, SndEnd, SoundOn : LongInt;

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

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 1; MakeNoise(0, 140, 45, 1);                 { lancer : la balle siffle }
  SndPrio := 3; MakeNoise(1, 70, 125, 1);                 { frappe du baton }
  SndPrio := 1; MakeTone(2, 260, 120, 120, 35);           { elan }
  SndPrio := 2; MakeNoise(3, 45, 90, 3);                  { balle dans le gant }
  SndPrio := 3; MakeTone(4, 420, 180, 320, 50);           { retrait }
  SndPrio := 4; MakeTone(5, 523, 1046, 420, 50);          { point marque }
  SndPrio := 4; MakeNoise(6, 1100, 45, 1);                { la foule : coup de circuit }
  SndPrio := 5; MakeTone(7, 392, 784, 800, 55);           { fin de partie }
  SndPrio := 0;
End;

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
{ Terrain (dessine une fois)                                            }
{ ==================================================================== }

Function BaseX(B : LongInt) : LongInt;
Begin
  Case B Of
    1 : BaseX := HX + 68;
    2 : BaseX := HX;
    3 : BaseX := HX - 68;
  Else
    BaseX := HX;
  End;
End;

Function BaseY(B : LongInt) : LongInt;
Begin
  Case B Of
    1, 3 : BaseY := HY - 68;
    2 : BaseY := HY - 136;
  Else
    BaseY := HY;
  End;
End;

Procedure RenderField;
Var X, Y, Dx, Dy, D2, C, Dd, Md, H, R2, R3 : LongInt;
Begin
  R2 := (FenceR - 14) * (FenceR - 14);
  R3 := (FenceR + 7) * (FenceR + 7);
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      Dx := X - HX; Dy := HY - Y;
      D2 := Dx * Dx + Dy * Dy;
      If (Dy >= Abs(Dx) - 60) And (D2 <= FenceR * FenceR) Then
      Begin
        { pelouse tondue en bandes }
        If ((X - Y + 2000) Div 22) Mod 2 = 0 Then C := C_GRASS1 Else C := C_GRASS2;
        If D2 > R2 Then C := C_DIRT2;                         { piste d'avertissement }
        Md := (X - HX) * (X - HX) + (Y - 304) * (Y - 304);
        If (Md <= 116 * 116) And (Dy >= 0) And (Dy <= 200) Then C := C_DIRT;   { terre du losange }
        Dd := Abs(X - HX) + Abs(Y - 304);
        If Dd < 58 Then C := C_GRASS3;                        { pelouse du losange }
        If (Dd >= 58) And (Dd <= 78) And (Md > 116 * 116) Then C := C_DIRT;    { allees }
        If (X - HX) * (X - HX) + (Y - 306) * (Y - 306) <= 15 * 15 Then C := C_DIRT;   { monticule }
        If D2 <= 28 * 28 Then C := C_DIRT;                     { marbre }
        If (Abs(Abs(Dx) - Dy) <= 1) And (Dy >= 0) And (D2 <= R2) And (D2 > 18 * 18) Then C := C_CHALK;
      End
      Else If (Dy >= Abs(Dx) - 60) And (D2 <= R3) Then
      Begin
        { cloture : mur vert, bordure jaune }
        If D2 > (FenceR + 5) * (FenceR + 5) Then C := C_WALLTOP Else C := C_WALL;
      End
      Else
      Begin
        { gradins (rangees de sieges) et spectateurs }
        C := C_STAND;
        If Y Mod 7 = 6 Then C := C_BLACK;
        If (X Mod 6 < 3) And (Y Mod 7 >= 1) And (Y Mod 7 <= 3) Then
        Begin
          H := ((X Div 6) * 7919 + (Y Div 7) * 104729) Mod 11;
          If H < 4 Then C := C_CROWD + H
          Else If H < 6 Then C := C_SKIN;
        End;
      End;
      Fb[(BH - 1 - Y) * BW + X] := C;
    End;
  { cases des frappeurs, marbre, plaque du lanceur, buts }
  For X := 0 To 1 Do
  Begin
    DLine(HX - 24 + X * 34, HY - 12, HX - 10 + X * 34, HY - 12, C_CHALK);
    DLine(HX - 24 + X * 34, HY + 12, HX - 10 + X * 34, HY + 12, C_CHALK);
    DLine(HX - 24 + X * 34, HY - 12, HX - 24 + X * 34, HY + 12, C_CHALK);
    DLine(HX - 10 + X * 34, HY - 12, HX - 10 + X * 34, HY + 12, C_CHALK);
  End;
  Rect(HX - 4, HY - 3, HX + 4, HY + 1, C_WHITE);
  For Y := 0 To 3 Do Rect(HX - 3 + Y, HY + 2 + Y, HX + 3 - Y, HY + 2 + Y, C_WHITE);
  Rect(HX - 4, 305, HX + 4, 306, C_WHITE);
  For C := 1 To 3 Do
    For Y := -5 To 5 Do Rect(BaseX(C) - (5 - Abs(Y)), BaseY(C) + Y, BaseX(C) + (5 - Abs(Y)), BaseY(C) + Y, C_WHITE);
  Move(Fb, Field, SizeOf(Fb));
End;

{ joueur debout, pieds en (X, Y) ; T : 0 Visiteurs (rouge), 1 Locaux (bleu) }
Procedure Figure(X, Y, T : LongInt; Crouch : Boolean);
Var Jc, Dc, Up : LongInt;
Begin
  If T = 0 Then Begin Jc := C_RED; Dc := C_REDD; End Else Begin Jc := C_BLUE; Dc := C_BLUED; End;
  Ell(X, Y, 5, 2, C_SHADOW);
  If Crouch Then Up := 5 Else Up := 0;
  Rect(X - 3, Y - 6 + Up, X - 1, Y, C_PANTS);
  Rect(X + 1, Y - 6 + Up, X + 3, Y, C_PANTS);
  Rect(X - 4, Y - 14 + Up, X + 4, Y - 7 + Up, Jc);
  Pix(X - 5, Y - 12 + Up, C_SKIN); Pix(X + 5, Y - 12 + Up, C_SKIN);
  FDisc(X, Y - 17 + Up, 3, C_SKIN);
  Rect(X - 3, Y - 21 + Up, X + 3, Y - 19 + Up, Dc);
  Rect(X - 1, Y - 19 + Up, X + 4, Y - 19 + Up, Dc);
End;

{ ==================================================================== }
{ Partie (regles du prototype)                                          }
{ ==================================================================== }

Function BatTeam : LongInt;
Begin
  If TopHalf <> 0 Then BatTeam := 0 Else BatTeam := 1;
End;

Function FieldTeam : LongInt;
Begin
  FieldTeam := 1 - BatTeam;
End;

Function HumanBats : Boolean;
Begin
  HumanBats := (AutoAll = 0) And (BatTeam = You);
End;

Function HumanPitches : Boolean;
Begin
  HumanPitches := (AutoAll = 0) And (FieldTeam = You);
End;

Function TeamName(T : LongInt) : String;
Begin
  If T = 0 Then TeamName := 'Visiteurs' Else TeamName := 'Locaux';
End;

Function BatterIdx : LongInt;
Begin
  BatterIdx := Order[Batter[BatTeam] Mod 9];
End;

Function BatterName : String;
Begin
  If BatTeam = 0 Then BatterName := NamesV[BatterIdx] Else BatterName := NamesD[BatterIdx];
End;

Function BatterAvg : LongInt;
Begin
  If BatTeam = 0 Then BatterAvg := AvgV[BatterIdx] Else BatterAvg := AvgD[BatterIdx];
End;

Function PitcherName : String;
Begin
  If FieldTeam = 0 Then PitcherName := NamesV[0] Else PitcherName := NamesD[0];
End;

Procedure Score(N : LongInt);
Begin
  Runs[BatTeam] := Runs[BatTeam] + N;
  Line[BatTeam, Inning] := Line[BatTeam, Inning] + N;
  If N > 0 Then PlaySnd(5);
End;

{ GetBattingResult du prototype : moyenne du frappeur, qualite du lancer }
Function BattingResult(Avg, PitchQ, Bonus : LongInt) : LongInt;
Var Chance : LongInt;
Begin
  Chance := Rnd(100);
  If PitchQ > 75 Then Chance := Chance + 20 Else If PitchQ < 25 Then Chance := Chance - 20;
  Chance := Chance + Bonus;
  If Chance < Avg Div 10 Then
  Begin
    Case Rnd(10) Of
      0..5 : BattingResult := R_SINGLE;
      6..7 : BattingResult := R_DOUBLE;
      8 : BattingResult := R_TRIPLE;
    Else
      BattingResult := R_HR;
    End;
  End
  Else
  Begin
    Case Rnd(3) Of
      0 : BattingResult := R_STRIKE;
      1 : BattingResult := R_FOUL;
    Else
      BattingResult := R_GROUND;
    End;
  End;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

{ fond fixe : terrain, defenseurs, coureurs sur les buts }
Procedure BuildBack;
Var K, Ft : LongInt;
Begin
  Move(Field, Fb, SizeOf(Fb));
  Ft := FieldTeam;
  For K := 0 To 8 Do Figure(FX[K], FY[K], Ft, K = 1);
  If State <> S_RUN Then
    For K := 1 To 3 Do
      If Bases[K] <> 0 Then Figure(BaseX(K) + 6, BaseY(K) - 2, BatTeam, False);
  SaveBack;
  NSpr := 0;
  NDirty := 0;
  AddDirty(0, 0, BW - 1, BH - 1);
End;

Procedure BannerDraw;
Var W, X, Y : LongInt;
Begin
  If Banner = '' Then Exit;
  W := Length(Banner) * 16;
  If Length(Banner2) * 8 > W Then W := Length(Banner2) * 8;
  W := W + 24;
  X := (BW - W) Div 2; Y := 18;
  Rect(X, Y, X + W - 1, Y + 54, C_BANNER);
  Rect(X, Y, X + W - 1, Y, C_YELLOW); Rect(X, Y + 54, X + W - 1, Y + 54, C_YELLOW);
  Rect(X, Y, X, Y + 54, C_YELLOW); Rect(X + W - 1, Y, X + W - 1, Y + 54, C_YELLOW);
  FbTextSh(X + (W - Length(Banner) * 16) Div 2, Y + 4, Banner, BannerC, C_BLACK, 2);
  FbText(X + (W - Length(Banner2) * 8) Div 2, Y + 36, Banner2, C_WHITE, 1);
  SprRect(X, Y, X + W - 1, Y + 54);
End;

{ position d'un coureur : du but A vers le but B, a F / N du chemin }
Procedure RunnerPos(A, B, F, N : LongInt; Var X, Y : LongInt);
Var Tot, Cur, Seg, Fr : LongInt;
Begin
  Tot := (B - A) * 100;
  If N <= 0 Then N := 1;
  Cur := Tot * F Div N;
  Seg := A + Cur Div 100; Fr := Cur Mod 100;
  If Seg >= B Then
  Begin
    X := BaseX(B); Y := BaseY(B);
    Exit;
  End;
  X := BaseX(Seg) + (BaseX(Seg + 1) - BaseX(Seg)) * Fr Div 100;
  Y := BaseY(Seg) + (BaseY(Seg + 1) - BaseY(Seg)) * Fr Div 100;
End;

{ objets mobiles : frappeur et baton, balle, coureurs, bandeau }
Procedure DrawSprites;
Var X, Y, Hx, Hy, Sf, K, Bx, By : LongInt;
Begin
  SprBegin;
  { frappeur dans la case de gauche }
  If (State <> S_RUN) And (State <> S_OVER) Then
  Begin
    X := HX - 16; Y := HY + 4;
    Figure(X, Y, BatTeam, False);
    Sf := SwingF;
    If Sf > 7 Then Sf := 7;
    Hx := X + 4; Hy := Y - 12;
    TLine(Hx, Hy, Hx + BatX[Sf], Hy + BatY[Sf], 1, C_BAT);
    SprRect(X - 18, Y - 30, X + 22, Y + 3);
  End;
  { coureurs en course }
  If State = S_RUN Then
    For K := 0 To NRun - 1 Do
    Begin
      RunnerPos(RunFrom[K], RunTo[K], Frm, NFrm, X, Y);
      Figure(X + 6, Y - 2, BatTeam, False);
      SprRect(X - 1, Y - 24, X + 13, Y + 2);
    End;
  { balle (ombre au sol, balle en l'air) }
  If BallOn <> 0 Then
  Begin
    If NFrm <= 0 Then NFrm := 1;
    Bx := BallX0 + (BallX1 - BallX0) * Frm Div NFrm;
    By := BallY0 + (BallY1 - BallY0) * Frm Div NFrm;
    Y := BallH * 4 * Frm * (NFrm - Frm) Div (NFrm * NFrm);
    Ell(Bx, By, 2, 1, C_SHADOW);
    FDisc(Bx, By - Y - 2, 2, C_BALL);
    Pix(Bx - 1, By - Y - 2, C_SEAM);
    SprRect(Bx - 4, By - Y - 6, Bx + 4, By + 3);
  End;
  BannerDraw;
End;

Procedure BlitAll(H : LongInt);
Var K : LongInt;
Begin
  For K := 0 To NDirty - 1 Do BlitRect(H, DX1[K], DY1[K], DX2[K], DY2[K]);
  NDirty := 0;
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ voyants : N allumes sur Tot }
Procedure Lights(X, Y, N, Tot, C : LongInt);
Var K : LongInt;
Begin
  For K := 0 To Tot - 1 Do
  Begin
    Disc(X + K * 16, Y, 5, CLR_DARKGRAY);
    If K < N Then Disc(X + K * 16, Y, 4, C) Else Disc(X + K * 16, Y, 4, CLR_BLACK);
  End;
End;

Procedure DrawPanel;
Var T, I, X, Last : LongInt; S : String;
Begin
  BigText(PnX + (PW - 8 * 16) Div 2, 6, 'BASEBALL', CLR_DARKGREEN, CLR_PALEGRAY);
  { tableau de pointage }
  FBar(PnX, 42, PnX + PW - 1, 102, CLR_DARKGREEN);
  Edge(PnX, 42, PnX + PW - 1, 102, CLR_DARKGRAY, CLR_WHITE);
  Last := Inning;
  If Last < MaxInnings Then Last := MaxInnings;
  For I := 1 To 9 Do
    OutTxt(PnX + 32 + (I - 1) * 12, 44, IStr(I), CLR_PALEGRAY, CLR_DARKGREEN);
  OutTxt(PnX + 142, 44, 'P', CLR_YELLOW, CLR_DARKGREEN);
  For T := 0 To 1 Do
  Begin
    If T = 0 Then S := 'VIS' Else S := 'LOC';
    If T = You Then OutTxt(PnX + 3, 62 + T * 18, S, CLR_YELLOW, CLR_DARKGREEN)
    Else OutTxt(PnX + 3, 62 + T * 18, S, CLR_WHITE, CLR_DARKGREEN);
    For I := 1 To 9 Do
    Begin
      X := PnX + 32 + (I - 1) * 12;
      If (I < Inning) Or ((I = Inning) And ((T = 0) Or (TopHalf = 0))) Then
      Begin
        If Line[T, I] > 9 Then OutTxt(X, 62 + T * 18, '+', CLR_WHITE, CLR_DARKGREEN)
        Else OutTxt(X, 62 + T * 18, IStr(Line[T, I]), CLR_WHITE, CLR_DARKGREEN);
      End;
    End;
    OutTxt(PnX + 152 - Length(IStr(Runs[T])) * 8, 62 + T * 18, IStr(Runs[T]), CLR_YELLOW, CLR_DARKGREEN);
  End;
  { manche, compte }
  If State = S_OVER Then S := 'Partie termin' + Chr(130) + 'e'
  Else If TopHalf <> 0 Then S := 'Manche ' + IStr(Inning) + ' (haut)'
  Else S := 'Manche ' + IStr(Inning) + ' (bas)';
  OutTxt(PnX, 108, S, CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 128, 'Balles', CLR_BLACK, CLR_PALEGRAY);
  Lights(PnX + 76, 136, Balls, 4, CLR_GREEN);
  OutTxt(PnX, 146, 'Prises', CLR_BLACK, CLR_PALEGRAY);
  Lights(PnX + 76, 154, Strikes, 3, CLR_YELLOW);
  OutTxt(PnX, 164, 'Retraits', CLR_BLACK, CLR_PALEGRAY);
  Lights(PnX + 76, 172, Outs, 3, CLR_RED);
  { frappeur et lanceur }
  FBar(PnX, 186, PnX + PW - 1, 244, CLR_WHITE);
  Edge(PnX, 186, PnX + PW - 1, 244, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(PnX + 4, 188, 'Au b' + Chr(131) + 'ton :', CLR_DARKGRAY, CLR_WHITE);
  S := IStr(BatterAvg);
  While Length(S) < 3 Do S := '0' + S;
  OutTxt(PnX + 4, 205, BatterName + ' .' + S, CLR_BLACK, CLR_WHITE);
  OutTxt(PnX + 4, 224, 'Lanceur : ' + PitcherName, CLR_DARKGRAY, CLR_WHITE);
  { puissance du lancer (prototype : + et -) }
  OutTxt(PnX, 252, 'Puissance : ' + IStr(Power), CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX, 272, PnX + PW - 1, 281, CLR_WHITE);
  Edge(PnX, 272, PnX + PW - 1, 281, CLR_DARKGRAY, CLR_WHITE);
  FBar(PnX + 1, 273, PnX + 1 + (PW - 3) * Power Div 100, 280, CLR_RED);
  If State = S_OVER Then Button(PnX, 296, PW, 30, 'Nouvelle partie')
  Else If HumanPitches Then Button(PnX, 296, PW, 30, 'Lancer (Espace)')
  Else If HumanBats Then Button(PnX, 296, PW, 30, 'Frapper (Espace)')
  Else Button(PnX, 296, PW, 30, 'D' + Chr(130) + 'monstration');
  If You = 0 Then S := 'Vous : Visiteurs' Else S := 'Vous : Locaux';
  If AutoAll <> 0 Then S := 'D' + Chr(130) + 'monstration';
  OutTxt(PnX, 336, S, CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 354, 'Coups s' + Chr(150) + 'rs : ' + IStr(Hits[0]) + ' / ' + IStr(Hits[1]), CLR_BLACK,
         CLR_PALEGRAY);
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

{ une image de l'animation : objets mobiles seulement }
Procedure Frame1;
Begin
  If Client = 0 Then Exit;
  DrawSprites;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  BlitAll(Hps);
  Dummy := WinReleasePS(Hps);
End;

Procedure PanelOnly;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  FBar(PnX, 0, CW - 1, CH - 23, CLR_PALEGRAY);
  DrawPanel;
  DrawStatus;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Deroulement                                                           }
{ ==================================================================== }

Procedure Show(B1, B2 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; BannerC := C;
End;

Procedure PromptMsg;
Begin
  If State = S_OVER Then Exit;
  If HumanPitches Then
    Msg := 'Au monticule : + et - (puissance), Espace pour lancer ' + Chr(133) + ' ' + BatterName + '.'
  Else If HumanBats Then
    Msg := 'Au b' + Chr(131) + 'ton : ' + BatterName + '. Espace au bon moment pour frapper.'
  Else Msg := TeamName(BatTeam) + ' au b' + Chr(131) + 'ton : ' + BatterName + '.';
End;

Procedure GameOver;
Var S : String;
Begin
  State := S_OVER;
  PlaySnd(7);
  If Runs[0] = Runs[1] Then S := 'Match nul'
  Else If (AutoAll = 0) And ((Runs[You] > Runs[1 - You])) Then S := 'Victoire !'
  Else If AutoAll = 0 Then S := 'D' + Chr(130) + 'faite'
  Else If Runs[0] > Runs[1] Then S := 'Les Visiteurs gagnent'
  Else S := 'Les Locaux gagnent';
  Show(S, 'Pointage final : Visiteurs ' + IStr(Runs[0]) + ', Locaux ' + IStr(Runs[1]), CLR_YELLOW);
  BannerC := C_YELLOW;
  Msg := 'Partie termin' + Chr(130) + 'e. F2 : nouvelle partie.';
  Wait := 0;
  BuildBack;
  Redraw;
End;

{ fin de la demi-manche (prototype : changement de manche) }
Procedure ChangeSides;
Begin
  Outs := 0; Balls := 0; Strikes := 0;
  Bases[1] := 0; Bases[2] := 0; Bases[3] := 0;
  If TopHalf <> 0 Then
  Begin
    { les Locaux ne frappent pas en fin de neuvieme s'ils menent }
    If (Inning >= MaxInnings) And (Runs[1] > Runs[0]) Then
    Begin
      GameOver;
      Exit;
    End;
    TopHalf := 0;
  End
  Else
  Begin
    TopHalf := 1;
    Inc(Inning);
    If Inning > MaxInnings Then
    Begin
      Inning := MaxInnings;
      GameOver;
      Exit;
    End;
  End;
  Show('Changement', TeamName(BatTeam) + ' au b' + Chr(131) + 'ton', C_WHITE);
End;

Procedure NextBatter;
Begin
  Batter[BatTeam] := (Batter[BatTeam] + 1) Mod 9;
  Balls := 0; Strikes := 0;
End;

{ ProcessOut du prototype }
Procedure DoOut;
Begin
  PlaySnd(4);
  Inc(Outs);
  NextBatter;
  If Outs >= 3 Then ChangeSides;
End;

{ fin de neuvieme : les Locaux passent devant }
Procedure WalkOff;
Begin
  If (TopHalf = 0) And (Inning >= MaxInnings) And (Runs[1] > Runs[0]) Then GameOver;
End;

{ le coup (Simple ... Coup de circuit) : chaque coureur avance de K buts
  (ProcessHit du prototype) ; la course est animee }
Procedure StartRun(K : LongInt);
Var B, N, NewB : Array[0..3] Of LongInt; I, S, T : LongInt;
Begin
  NRun := 0; S := 0;
  For I := 1 To 3 Do NewB[I] := 0;
  For I := 3 DownTo 1 Do
    If Bases[I] <> 0 Then
    Begin
      T := I + K;
      If T > 4 Then T := 4;
      RunFrom[NRun] := I; RunTo[NRun] := T; Inc(NRun);
      If T >= 4 Then Inc(S) Else NewB[T] := 1;
    End;
  T := K;
  If T > 4 Then T := 4;
  RunFrom[NRun] := 0; RunTo[NRun] := T; Inc(NRun);
  If T >= 4 Then Inc(S) Else NewB[T] := 1;
  For I := 1 To 3 Do Bases[I] := NewB[I];
  Score(S);
  Inc(Hits[BatTeam]);
  NextBatter;
  State := S_RUN; Frm := 0; NFrm := 14 + K * 10;
  BuildBack;
End;

{ but sur balles (prototype : coureurs forces) }
Procedure Walk;
Begin
  If (Bases[1] <> 0) And (Bases[2] <> 0) And (Bases[3] <> 0) Then Score(1);
  If (Bases[1] <> 0) And (Bases[2] <> 0) Then Bases[3] := 1;
  If Bases[1] <> 0 Then Bases[2] := 1;
  Bases[1] := 1;
  NextBatter;
  WalkOff;
End;

Procedure ShowCount;
Begin
  PanelOnly;
End;

{ le lancer arrive : resultat (frappe, prise, balle...) }
Procedure Resolve;
Var A, D, Bonus, Ang, Dist : LongInt; Th : Real;
Begin
  BallOn := 0;
  If Swung <> 0 Then
  Begin
    { elan : le moment compte (au baton, le joueur) }
    Bonus := 0;
    If HumanBats Then
    Begin
      D := Abs(Swung - NFrm + 1);
      If D <= 1 Then Bonus := -25 Else If D <= 3 Then Bonus := 0 Else If D <= 6 Then Bonus := 25 Else Bonus := 100;
    End;
    If Bonus >= 100 Then Result := R_STRIKE
    Else Result := BattingResult(BatterAvg, Quality, Bonus);
  End
  Else
  Begin
    { pas d'elan : prise ou balle (prototype : 60 % de prises) }
    If Rnd(100) < 60 Then Result := R_LOOK Else Result := R_BALL;
  End;
  Case Result Of
    R_SINGLE, R_DOUBLE, R_TRIPLE, R_HR, R_FOUL, R_GROUND :
      Begin
        { la balle part dans le champ }
        If Result = R_FOUL Then
        Begin
          If Rnd(2) = 0 Then Ang := -60 - Rnd(25) Else Ang := 60 + Rnd(25);
          Dist := 120 + Rnd(100); BallH := 70;
        End
        Else
        Begin
          Ang := Rnd(76) - 38;
          Case Result Of
            R_SINGLE : Begin Dist := 150 + Rnd(40); BallH := 40; End;
            R_DOUBLE : Begin Dist := 220 + Rnd(40); BallH := 70; End;
            R_TRIPLE : Begin Dist := 280 + Rnd(30); BallH := 80; End;
            R_HR : Begin Dist := 400 + Rnd(40); BallH := 140; End;
          Else
            Begin Dist := 70 + Rnd(30); BallH := 4; End;
          End;
        End;
        PlaySnd(1);
        Th := Ang * Pi / 180;
        BallX0 := HX; BallY0 := HY - 6;
        BallX1 := HX + Round(Sin(Th) * Dist); BallY1 := HY - Round(Cos(Th) * Dist);
        BallOn := 1; Frm := 0;
        If Result = R_HR Then NFrm := 40 Else If Result = R_GROUND Then NFrm := 14 Else NFrm := 18 + Dist Div 12;
        State := S_FLY;
      End;
  Else
    Begin
      State := S_SHOW; Wait := 0;
      PlaySnd(3);
      Case Result Of
        R_STRIKE :
          Begin
            Inc(Strikes);
            If Strikes >= 3 Then
            Begin
              Show('Retrait !', 'Trois prises : ' + BatterName + ' est retir' + Chr(130), C_RED);
              DoOut;
            End
            Else Show('Prise !', 'Elan dans le vide (' + IStr(Strikes) + ' prise(s))', C_YELLOW);
          End;
        R_LOOK :
          Begin
            Inc(Strikes);
            If Strikes >= 3 Then
            Begin
              Show('Retrait !', 'Trois prises : ' + BatterName + ' est retir' + Chr(130), C_RED);
              DoOut;
            End
            Else Show('Prise !', IStr(Strikes) + ' prise(s)', C_YELLOW);
          End;
      Else
        Begin
          Inc(Balls);
          If Balls >= 4 Then
          Begin
            Show('But sur balles', BatterName + ' va au premier but', C_WHITE);
            Walk;
          End
          Else Show('Balle !', IStr(Balls) + ' balle(s)', C_WHITE);
        End;
      End;
      If State <> S_OVER Then BuildBack;
      PanelOnly;
    End;
  End;
End;

{ la balle frappee est arrivee : le coup est joue }
Procedure Landed;
Var K : LongInt;
Begin
  BallOn := 0;
  Case Result Of
    R_FOUL :
      Begin
        If Strikes < 2 Then Inc(Strikes);
        Show('Fausse balle', IStr(Strikes) + ' prise(s)', C_YELLOW);
        State := S_SHOW; Wait := 0;
      End;
    R_GROUND :
      Begin
        If Rnd(100) < 70 Then
        Begin
          Show('Retrait !', 'Balle au sol : ' + BatterName + ' est retir' + Chr(130), C_RED);
          DoOut;
          If State <> S_OVER Then State := S_SHOW;
          Wait := 0;
        End
        Else
        Begin
          Show('Sauf !', 'Balle au sol : le coureur arrive au but', C_WHITE);
          StartRun(1);
        End;
      End;
  Else
    Begin
      K := Result;
      Case K Of
        R_SINGLE : Show('Simple !', 'Coup s' + Chr(150) + 'r de ' + BatterName, C_WHITE);
        R_DOUBLE : Show('Double !', 'Excellent coup de ' + BatterName, C_WHITE);
        R_TRIPLE : Show('Triple !', 'Incroyable : ' + BatterName + ' au troisi' + Chr(138) + 'me', C_YELLOW);
      Else
        Show('Circuit !', 'Coup de circuit de ' + BatterName + ' !', C_YELLOW);
      End;
      StartRun(K);
      If K = R_HR Then PlaySnd(6);
    End;
  End;
  If (State = S_SHOW) Then BuildBack;
  PanelOnly;
End;

Procedure Pitch;
Begin
  If State <> S_IDLE Then Exit;
  Banner := '';
  If HumanPitches Then Quality := Power + Rnd(50)
  Else
  Begin
    CpuPower := 30 + Rnd(61);
    Quality := CpuPower + Rnd(50);
  End;
  BallX0 := HX; BallY0 := 300; BallX1 := HX + 1; BallY1 := HY + 18; BallH := 8;
  If HumanPitches Then NFrm := 30 - Power Div 5 Else NFrm := 30 - CpuPower Div 5;
  Frm := 0; BallOn := 1; Swung := 0; SwingF := 0;
  State := S_PITCH;
  PlaySnd(0);
  Msg := PitcherName + ' lance...';
  BuildBack;
  PanelOnly;
End;

Procedure Swing;
Begin
  If (State <> S_PITCH) Or (Swung <> 0) Then Exit;
  Swung := Frm + 1;
  SwingF := 1;
  PlaySnd(2);
End;

{ l'ordinateur au baton : elan une fois sur deux environ }
Procedure CpuBatter;
Begin
  If (State = S_PITCH) And (Swung = 0) And Not HumanBats And (Frm = NFrm - 3) Then
    If Rnd(100) < 55 Then Swing;
End;

Procedure NewGame;
Var T, I : LongInt;
Begin
  For T := 0 To 1 Do
  Begin
    Runs[T] := 0; Batter[T] := 0; Hits[T] := 0;
    For I := 1 To 12 Do Line[T, I] := 0;
  End;
  Inning := 1; TopHalf := 1; Outs := 0; Balls := 0; Strikes := 0;
  Bases[1] := 0; Bases[2] := 0; Bases[3] := 0;
  Power := 50; Swung := 0; SwingF := 0; BallOn := 0; Wait := 0;
  State := S_SHOW;
  Show('Au jeu !', 'Les Visiteurs frappent en premier', C_YELLOW);
  BuildBack;
  PromptMsg;
  Redraw;
End;

Procedure Action;
Begin
  Case State Of
    S_OVER : NewGame;
    S_IDLE : If HumanPitches Then Pitch;
    S_PITCH : If HumanBats Then Swing;
    S_SHOW : If Wait > 8 Then Wait := 1000;
  End;
End;

Procedure TimerTick;
Begin
  Case State Of
    S_SHOW :
      Begin
        Inc(Wait);
        If Wait = 1 Then Frame1;
        If Wait > 30 Then
        Begin
          State := S_IDLE; Banner := ''; Wait := 0;
          PromptMsg;
          Frame1;
          PanelOnly;
        End;
      End;
    S_IDLE :
      Begin
        If Not HumanPitches Then
        Begin
          Inc(Wait);
          If Wait > 12 Then
          Begin
            Wait := 0;
            Pitch;
          End;
        End;
      End;
    S_PITCH :
      Begin
        Inc(Frm);
        CpuBatter;
        If SwingF > 0 Then Inc(SwingF);
        If Frm >= NFrm Then
        Begin
          Frm := NFrm;
          Frame1;
          Resolve;
        End;
        Frame1;
      End;
    S_FLY :
      Begin
        If SwingF > 0 Then Inc(SwingF);
        Inc(Frm);
        If Frm >= NFrm Then
        Begin
          Frm := NFrm;
          Landed;
        End;
        Frame1;
      End;
    S_RUN :
      Begin
        Inc(Frm);
        If Frm >= NFrm Then
        Begin
          State := S_SHOW; Wait := 0;
          WalkOff;
          BuildBack;
          PanelOnly;
        End;
        Frame1;
      End;
    S_OVER :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait > 80 Then NewGame;
      End;
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

Procedure SetPower(V : LongInt);
Begin
  If V < 0 Then V := 0;
  If V > 100 Then V := 100;
  Power := V;
  PanelOnly;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_ACT : Action;
    CM_VIS, CM_DOM :
      Begin
        If Id = CM_VIS Then You := 0 Else You := 1;
        SetMark(CM_VIS, You = 0); SetMark(CM_DOM, You = 1);
        NewGame;
      End;
    CM_SOUND :
      Begin
        SoundOn := 1 - SoundOn;
        SetMark(CM_SOUND, SoundOn <> 0);
      End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd('Deux ' + Chr(130) + 'quipes de neuf joueurs, neuf manches. Les Visiteurs frappent en haut de ' +
             'manche, les Locaux en bas ; trois retraits terminent la demi-manche. Quatre balles : but sur ' +
             'balles. Trois prises : retrait.' + Chr(10) + Chr(10));
        LAdd('Au b' + Chr(131) + 'ton : appuyez sur Espace (ou cliquez le terrain) quand la balle arrive au ' +
             'marbre ; le bon moment aide la frappe. Sans ' + Chr(130) + 'lan, le lancer est une prise ou ' +
             'une balle. Frappe : simple, double, triple ou circuit (selon la moyenne du frappeur), fausse ' +
             'balle, ou balle au sol (retrait sept fois sur dix). Les coureurs avancent d''autant de buts que ' +
             'le coup.' + Chr(10) + Chr(10));
        LAdd('Au monticule : + et - r' + Chr(130) + 'glent la puissance (plus elle est grande, plus la balle ' +
             'va vite et plus elle est difficile ' + Chr(133) + ' frapper), Espace lance.' + Chr(10) + Chr(10));
        LAdd('Menu Partie : vous jouez les Visiteurs ou les Locaux. F2 : nouvelle partie.');
        Dummy := LMsgBox('Baseball - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Baseball pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'BASEBALL.PAS de 7iles : neuf manches contre l''ordinateur.' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos de Baseball', MB_OK Or MB_INFORMATION);
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
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Action; Exit; End;
  End;
  If ((Fl And KC_CHAR) <> 0) And ((Fl And (KC_ALT Or KC_CTRL)) = 0) Then
  Begin
    Case Chr(Ch) Of
      ' ' : Action;
      '+', '=' : SetPower(Power + 10);
      '-', '_' : SetPower(Power - 10);
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
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    Action;
    Exit;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 296) And (Y < 326) Then Action
    Else If (Y >= 270) And (Y < 284) Then SetPower((X - PnX) * 100 Div (PW - 1));
  End;
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
    WM_TIMER : If Lo16(Mp1) = 1 Then TimerTick;
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
  Fl, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; AutoAll := 0; You := 0; Banner := ''; Banner2 := ''; NSpr := 0; NDirty := 0;
  Client := 0; State := S_IDLE; Inning := 1; TopHalf := 1;
  SoundOn := 1; SndCur := 0; SndEnd := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
    If (S = '/AUTO') Or (S = '/auto') Then AutoAll := 1;
    If (S = '/NOSOUND') Or (S = '/nosound') Then SoundOn := 0;
  End;
  MakeSounds;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  RenderField;
  Dummy := WinRegisterClass(Hab, Z('BASEBALL'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('BASEBALL'), Z2('Baseball'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_ACT, '~Lancer ou frapper' + Chr(9) + 'Espace');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, MIA_CHECKED, CM_VIS, 'Vous jouez les ~Visiteurs');
  MItem(MIS_TEXT, 0, CM_DOM, 'Vous jouez les L~ocaux');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 7);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  If SoundOn <> 0 Then MItem(MIS_TEXT, MIA_CHECKED, CM_SOUND, '~Son')
  Else MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 1);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Baseball');
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
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
