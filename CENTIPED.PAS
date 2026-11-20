{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: CENTIPED - Mille-pattes (jeu d'adresse) pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program CENTIPED;

{$R-,S-,I-}

{ Compilation : OS2PC CENTIPED.PAS   (produit CENTIPED.EXE)

  Portage vers OS/2-0 du prototype CENTIPED.PAS du depot 7iles (Turbo
  Pascal, mode texte de 40 x 23 caracteres) : fenetre de Presentation
  Manager avec menus, image en memoire (GpiDrawBits, seuls les carreaux
  changes sont recopies), dessins en couleur (jardin de nuit, bordure de
  pierres, champignons, mille-pattes, araignee, canon), panneau du
  pointage, pause, bruitages (tir, champignon et anneau touches, canon
  perdu ; menu Options, Son), barre d'etat et apparence d'OS/2. Le terrain, les
  regles et les deplacements du prototype sont repris tels quels.

  But (comme le prototype) : empechez le mille-pattes de descendre sur
  terre. Tirez-lui dessus ; touche au milieu, il se coupe en deux
  mille-pattes (et accelere) ; chaque anneau touche devient un
  champignon. Un champignon tient deux tirs. Mefiez-vous de l'araignee :
  elle ne peut pas etre tuee, seme des champignons et detruit le canon
  au contact. Un mille-pattes detruit, le suivant arrive, plus long.
  Pointage (comme le prototype) : 50 au depart, -2 par tir, +10 par
  champignon detruit, +100 par anneau.
  Difference avec le prototype : un mille-pattes qui atteint la terre
  coute une vie (le prototype terminait la partie) ; 3 vies.

  Clavier : fleches gauche et droite (ou 1 et 3, 4 et 6, 7 et 9 pour
  aller plus vite, comme le prototype), Espace (tirer ; maintenue : tir
  continu), P (pause), F2 (nouvelle partie), F1 (regles).
  Souris : le canon suit la souris, clic : tirer.
  Parametres : /SEED:n (parties reproductibles) ; /AUTO (le canon joue
  seul : demonstration) ; /NOSOUND (sans bruitages). }

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
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_PAUSE = $0D; VK_ESC = $0F; VK_SPACE = $10; VK_LEFT = $15;
  VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21; VK_F3 = $22;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKPINK = 11; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_PAUSE = 102; CM_AUTO = 103; CM_QUIT = 104;
  CM_SLOW = 111; CM_NORMAL = 112; CM_FAST = 113;
  CM_SOUND = 114;
  CM_RULES = 301; CM_ABOUT = 302;
  SndRate = 11025;
  { terrain du prototype : 23 rangees, 40 colonnes (bordure, terre en bas) }
  ScreenRow = 23; ScreenCol = 40;
  CW_ = 12; CH_ = 16;                    { taille d'un carreau }
  BW = 480; BH = 368;                    { image : 40 x 12, 23 x 16 }
  OX = 8; OY = 8;
  PnX = 496; PW = 120;
  CWant = 624; CHWant = 406;
  InitMoveWhen = 9; InitNumMushs = 30; InitLenCent = 12;
  { objets du terrain (ceux du prototype) }
  O_BLANK = 0; O_WEAKMUSH = 1; O_STRONGMUSH = 2; O_WEAKSEG = 3; O_STRONGSEG = 4; O_CANNON = 5; O_WALL = 6;
  O_EARTH = 7; O_CENT = 8; O_SHOT = 9;
  MaxSeg = 80; MaxCh = 80; MaxDirty = 120;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  Scr : Array[1..ScreenRow, 1..ScreenCol] Of Byte;
  SegAt : Array[1..ScreenRow, 1..ScreenCol] Of LongInt;
  { anneaux (Suivant vers la queue) et mille-pattes (dans l'ordre de la liste du prototype) }
  SR, SC, SNx, SPv, SUsed : Array[0..MaxSeg - 1] Of LongInt;
  KHead, KTail, KDir : Array[0..MaxCh - 1] Of LongInt;
  NCh : LongInt;
  YouX, NumMoves, Score, Lives, NumMush, NumCent, MoveWhen, Speed, Wave : LongInt;
  SpiderY, SpiderX, SpiderDX, SpiderDY, ShotY, ShotX, Target : LongInt;
  ShotGoing : Boolean;
  State, Seed, Best, Auto, LostFlag : LongInt;   { State : 0 en jeu, 1 message, 2 fin }
  Banner1, Banner2 : String;
  DX1, DY1, DX2, DY2 : Array[0..MaxDirty - 1] Of LongInt;
  NDirty : LongInt;
  Msg : String;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  { bruitages }
  SndBuf : Array[0..29999] Of Byte;
  SndOfs, SndLen, SndPri : Array[0..15] Of LongInt;
  NSndBuf, SndPrio, SndCur, SndEnd, SoundOn : LongInt;


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
  SndPrio := 0; MakeTone(0, 1500, 500, 70, 45);          { tir }
  SndPrio := 1; MakeNoise(1, 45, 70, 2);                  { champignon touche }
  SndPrio := 2; MakeNoise(2, 160, 100, 3);                { anneau detruit }
  SndPrio := 5; MakeTone(3, 620, 70, 750, 70);            { canon perdu }
  SndPrio := 4; MakeTone(4, 300, 900, 350, 50);           { nouvelle vague }
  SndPrio := 0;
End;

Procedure WrL(A, V : LongInt);
Begin
  WrW(A, V And $FFFF);
  WrW(A + 2, (V Shr 16) And $FFFF);
End;

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
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

{ ==================================================================== }
{ Image en memoire                                                      }
{ ==================================================================== }

Procedure SetPal(I, C : LongInt);
Var A : LongInt;
Begin
  A := LongInt(@Bmi) + 16 + I * 4;
  WrB(A, C And 255); WrB(A + 1, (C Shr 8) And 255); WrB(A + 2, (C Shr 16) And 255);
End;

Const
  { 0 noir ; 1-3 terre ; 4-6 pierres ; 7-9 terre et herbe ; 10-16 champignons ;
    17-24 mille-pattes ; 25-27 araignee ; 28-31 canon ; 32-33 tir }
  Pal : Array[0..34] Of LongInt = (
    $000000, $221C14, $3A3020, $1C2C14, $6E6E76, $A0A0AA, $3C3C42, $5A3C1E,
    $288C28, $5ABE3C, $DC5A1E, $963214, $FAF0D2, $EBDCB4, $BEAA82, $963CBE,
    $5A1E78, $3CC83C, $147820, $A0F078, $E6D228, $FFFFFF, $1E1E1E, $DC1E1E,
    $50321E, $9A5028, $D08850, $FF2828, $2858DC, $8CB4FF, $14287A, $BEBEC8,
    $FFF050, $FFFFDC, $B4A082);

Procedure InitBmi;
Var I : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 34 Do SetPal(I, Pal[I]);
End;

Procedure Pix(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Fb[(BH - 1 - Y) * BW + X] := C;
End;

Procedure Rect(X1, Y1, X2, Y2, C : LongInt);
Var X, Y : LongInt;
Begin
  For Y := Y1 To Y2 Do
    For X := X1 To X2 Do Pix(X, Y, C);
End;

{ ellipse pleine de centre (Cx, Cy) ; Top : seulement la moitie du haut }
Procedure Ell(Cx, Cy, Rx, Ry, C : LongInt; Top : Boolean);
Var Dy, W, Y2 : LongInt;
Begin
  If Top Then Y2 := 0 Else Y2 := Ry;
  For Dy := -Ry To Y2 Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) * Ry * Ry + Dy * Dy * Rx * Rx <= Rx * Rx * Ry * Ry + Rx * Ry Do Inc(W);
    Rect(Cx - W, Cy + Dy, Cx + W, Cy + Dy, C);
  End;
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

{ ==================================================================== }
{ Dessins des carreaux (originaux)                                      }
{ ==================================================================== }

Function CellX(C : LongInt) : LongInt;
Begin
  CellX := (C - 1) * CW_;
End;

Function CellY(R : LongInt) : LongInt;
Begin
  CellY := (R - 1) * CH_;
End;

{ fond : terre de jardin, quelques grains (toujours les memes) }
Procedure DrawSoil(R, C : LongInt);
Var X, Y, H : LongInt;
Begin
  X := CellX(C); Y := CellY(R);
  Rect(X, Y, X + CW_ - 1, Y + CH_ - 1, 1);
  H := (R * 31 + C * 17) Mod 23;
  Pix(X + H Mod 11, Y + H Mod 15, 2);
  Pix(X + (H * 7) Mod 11, Y + (H * 5) Mod 15, 3);
  If H Mod 3 = 0 Then Pix(X + (H * 3) Mod 11, Y + (H * 11) Mod 15, 2);
End;

Procedure DrawStone(R, C : LongInt);
Var X, Y : LongInt;
Begin
  X := CellX(C); Y := CellY(R);
  Rect(X, Y, X + CW_ - 1, Y + CH_ - 1, 0);
  Rect(X + 1, Y + 1, X + CW_ - 2, Y + CH_ - 2, 4);
  Rect(X + 1, Y + 1, X + CW_ - 2, Y + 2, 5);
  Rect(X + 1, Y + 1, X + 2, Y + CH_ - 2, 5);
  Rect(X + 2, Y + CH_ - 3, X + CW_ - 2, Y + CH_ - 2, 6);
  Rect(X + CW_ - 3, Y + 3, X + CW_ - 2, Y + CH_ - 2, 6);
  If (R + C) Mod 2 = 0 Then Pix(X + 6, Y + 8, 5) Else Pix(X + 5, Y + 6, 6);
End;

Procedure DrawEarth(C : LongInt);
Var X, Y, K : LongInt;
Begin
  X := CellX(C); Y := CellY(ScreenRow);
  Rect(X, Y, X + CW_ - 1, Y + CH_ - 1, 7);
  Rect(X, Y, X + CW_ - 1, Y + 2, 8);
  For K := 0 To 3 Do DLine(X + K * 3 + 1, Y + 3, X + K * 3 + (C + K) Mod 2, Y, 9);
  Pix(X + (C * 5) Mod 11, Y + 9, 1); Pix(X + (C * 7) Mod 11, Y + 13, 2);
End;

{ champignon : Strong (deux tirs) ou entame ; Seg : ne d'un anneau (violet) }
Procedure DrawMush(R, C : LongInt; Strong, Seg : Boolean);
Var X, Y, Cap, Dk : LongInt;
Begin
  X := CellX(C); Y := CellY(R);
  If Seg Then
  Begin
    Cap := 15; Dk := 16;
  End
  Else
  Begin
    Cap := 10; Dk := 11;
  End;
  Rect(X + 4, Y + 9, X + 7, Y + 14, 13);
  Rect(X + 7, Y + 9, X + 7, Y + 14, 14);
  Rect(X + 3, Y + 14, X + 8, Y + 14, 14);
  If Strong Then
  Begin
    Ell(X + 6, Y + 9, 6, 7, Dk, True);
    Ell(X + 5, Y + 8, 5, 6, Cap, True);
    Rect(X + 3, Y + 4, X + 4, Y + 5, 12);
    Rect(X + 7, Y + 3, X + 8, Y + 4, 12);
    Pix(X + 9, Y + 7, 12); Pix(X + 2, Y + 7, 12);
  End
  Else
  Begin
    { chapeau entame par un tir }
    Ell(X + 6, Y + 9, 6, 3, Dk, True);
    Ell(X + 5, Y + 9, 5, 2, Cap, True);
    Pix(X + 4, Y + 8, 12);
    Pix(X + 2, Y + 6, Dk); Pix(X + 9, Y + 5, Dk);
  End;
End;

{ chaine dont l'anneau S est la tete (-1 : aucune) }
Function ChainOfHead(S : LongInt) : LongInt;
Var K : LongInt;
Begin
  ChainOfHead := -1;
  For K := 0 To NCh - 1 Do If KHead[K] = S Then ChainOfHead := K;
End;

Procedure DrawSeg(R, C : LongInt);
Var X, Y, S, K, D, Ph : LongInt;
Begin
  X := CellX(C); Y := CellY(R);
  S := SegAt[R, C];
  Ph := (R + C + NumMoves Div 4) Mod 2;
  { pattes }
  DLine(X + 1, Y + 11 + Ph, X + 3, Y + 9, 24); DLine(X + 10, Y + 12 - Ph, X + 8, Y + 9, 24);
  DLine(X + 2, Y + 14 - Ph, X + 4, Y + 11, 24); DLine(X + 9, Y + 13 + Ph, X + 7, Y + 11, 24);
  If (S >= 0) And (SPv[S] < 0) Then
  Begin
    { tete : jaune, yeux du cote ou elle va, antennes }
    K := ChainOfHead(S);
    If K >= 0 Then D := KDir[K] Else D := -1;
    Ell(X + 6, Y + 9, 5, 5, 18, False);
    Ell(X + 6, Y + 8, 4, 4, 20, False);
    DLine(X + 4, Y + 4, X + 2, Y, 24); DLine(X + 8, Y + 4, X + 10, Y, 24);
    Pix(X + 2, Y, 23); Pix(X + 10, Y, 23);
    If D < 0 Then
    Begin
      Rect(X + 3, Y + 7, X + 4, Y + 8, 21); Pix(X + 3, Y + 8, 22);
      Rect(X + 6, Y + 7, X + 7, Y + 8, 21); Pix(X + 6, Y + 8, 22);
    End
    Else
    Begin
      Rect(X + 5, Y + 7, X + 6, Y + 8, 21); Pix(X + 6, Y + 8, 22);
      Rect(X + 8, Y + 7, X + 9, Y + 8, 21); Pix(X + 9, Y + 8, 22);
    End;
    Rect(X + 5, Y + 11, X + 7, Y + 11, 23);
  End
  Else
  Begin
    Ell(X + 6, Y + 9, 5, 5, 18, False);
    Ell(X + 6, Y + 8, 4, 4, 17, False);
    Rect(X + 4, Y + 6, X + 5, Y + 7, 19);
    Rect(X + 2, Y + 9, X + 10, Y + 9, 18);
  End;
End;

Procedure DrawSpider(R, C : LongInt);
Var X, Y, K : LongInt;
Begin
  X := CellX(C); Y := CellY(R);
  For K := 0 To 3 Do
  Begin
    DLine(X + 4, Y + 8 + K, X + K Mod 2, Y + 3 + K * 3, 34);
    DLine(X + 7, Y + 8 + K, X + 11 - K Mod 2, Y + 3 + K * 3, 34);
  End;
  Ell(X + 6, Y + 10, 4, 4, 25, False);
  Ell(X + 6, Y + 9, 3, 3, 26, False);
  Ell(X + 6, Y + 5, 2, 2, 25, False);
  Pix(X + 5, Y + 5, 27); Pix(X + 7, Y + 5, 27);
  Pix(X + 6, Y + 10, 23); Pix(X + 6, Y + 11, 23);
End;

Procedure DrawCannon;
Var X, Y : LongInt;
Begin
  { fut (rangee 22) }
  X := CellX(YouX); Y := CellY(ScreenRow - 1);
  Rect(X + 4, Y + 3, X + 7, Y + CH_ - 1, 30);
  Rect(X + 5, Y + 2, X + 6, Y + CH_ - 1, 31);
  Rect(X + 5, Y + 2, X + 5, Y + CH_ - 1, 21);
  Rect(X + 4, Y + 1, X + 7, Y + 2, 29);
  { tourelle sur la terre (rangee 23) }
  Y := CellY(ScreenRow);
  Ell(X + 6, Y + 11, 6, 9, 30, True);
  Ell(X + 5, Y + 10, 5, 8, 28, True);
  Rect(X + 3, Y + 5, X + 4, Y + 6, 29);
  Rect(X, Y + 12, X + CW_ - 1, Y + CH_ - 1, 22);
  Pix(X + 2, Y + 14, 31); Pix(X + 6, Y + 14, 31); Pix(X + 9, Y + 14, 31);
End;

Procedure DrawShot(R, C : LongInt);
Var X, Y : LongInt;
Begin
  X := CellX(C); Y := CellY(R);
  Rect(X + 5, Y + 3, X + 6, Y + 12, 32);
  Rect(X + 5, Y + 4, X + 5, Y + 10, 33);
End;

{ --- rectangles a recopier --- }
Procedure AddDirty(X1, Y1, X2, Y2 : LongInt);
Begin
  If NDirty >= MaxDirty Then
  Begin
    NDirty := 1;
    DX1[0] := 0; DY1[0] := 0; DX2[0] := BW - 1; DY2[0] := BH - 1;
    Exit;
  End;
  DX1[NDirty] := X1; DY1[NDirty] := Y1; DX2[NDirty] := X2; DY2[NDirty] := Y2;
  Inc(NDirty);
End;

{ redessine le carreau (R, C) dans l'image : fond, objet, araignee }
Procedure DrawCell(R, C : LongInt);
Begin
  If (R < 1) Or (R > ScreenRow) Or (C < 1) Or (C > ScreenCol) Then Exit;
  Case Scr[R, C] Of
    O_WALL : DrawStone(R, C);
    O_EARTH : DrawEarth(C);
  Else
    DrawSoil(R, C);
  End;
  Case Scr[R, C] Of
    O_WEAKMUSH : DrawMush(R, C, False, False);
    O_STRONGMUSH : DrawMush(R, C, True, False);
    O_WEAKSEG : DrawMush(R, C, False, True);
    O_STRONGSEG : DrawMush(R, C, True, True);
    O_CENT : DrawSeg(R, C);
    O_SHOT : DrawShot(R, C);
  End;
  If (R >= ScreenRow - 1) And (C = YouX) Then
  Begin
    If R = ScreenRow Then DrawEarth(C);
    DrawCannon;
  End;
  If (R = SpiderY) And (C = SpiderX) And (State <> 2) Then DrawSpider(R, C);
  AddDirty(CellX(C), CellY(R), CellX(C) + CW_ - 1, CellY(R) + CH_ - 1);
End;

Procedure DrawAll;
Var R, C : LongInt;
Begin
  For R := 1 To ScreenRow Do
    For C := 1 To ScreenCol Do DrawCell(R, C);
  NDirty := 0;
  AddDirty(0, 0, BW - 1, BH - 1);
End;

Procedure BlitRect(H, X1, Y1, X2, Y2 : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  P[0] := OX + X1; P[1] := CH - OY - 1 - Y2; P[2] := OX + X2 + 1; P[3] := CH - OY - Y1;
  P[4] := X1; P[5] := BH - 1 - Y2; P[6] := X2 + 1; P[7] := BH - Y1;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
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
Var S : String; K, X : LongInt;
Begin
  FBar(PnX + 2, 90, PnX + PW - 3, 124, CLR_WHITE);
  S := IStr(Score);
  If Length(S) > 7 Then S := Copy(S, Length(S) - 6, 7);
  BigText(PnX + PW - 8 - Length(S) * 16, 91, S, CLR_DARKGREEN, CLR_WHITE);
  FBar(PnX, 132, PnX + PW - 1, 200, CLR_PALEGRAY);
  OutTxt(PnX, 132, 'Vague : ' + IStr(Wave), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 150, 'Vies :', CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To Lives - 1 Do
  Begin
    X := PnX + 56 + K * 16;
    FBar(X + 4, 151, X + 6, 158, CLR_DARKGRAY);
    FBar(X + 1, 159, X + 9, 165, CLR_BLUE);
    FBar(X + 3, 157, X + 7, 158, CLR_BLUE);
  End;
  OutTxt(PnX, 170, 'Champignons ' + IStr(NumMush), CLR_BLACK, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 186, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 5 * 16) Div 2, 4, 'MILLE', CLR_DARKGREEN, CLR_PALEGRAY);
  BigText(PnX + (PW - 6 * 16) Div 2, 36, 'PATTES', CLR_DARKGREEN, CLR_PALEGRAY);
  OutTxt(PnX, 68, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 86, PnX + PW - 1, 128, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 87, PnX + PW - 2, 127, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 88, PnX + PW - 3, 126, CLR_WHITE);
  DrawCounters;
  Button(PnX, 214, PW, 28, 'Nouvelle partie');
  Button(PnX, 248, PW, 28, 'Pause');
  OutTxt(PnX, 290, Chr(27) + ' ' + Chr(26) + ' : canon', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 306, 'Espace : tirer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 322, 'Souris : viser', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 338, 'P : pause', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure DrawBanner;
Var W, X, Y : LongInt;
Begin
  If State = 0 Then Exit;
  W := Length(Banner1) * 16;
  If Length(Banner2) * 8 > W Then W := Length(Banner2) * 8;
  W := W + 40;
  X := OX + (BW - W) Div 2; Y := OY + 130;
  FBar(X, Y, X + W - 1, Y + 75, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + 75, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + 74, CLR_PALEGRAY, CLR_DARKGRAY);
  FBar(X + 2, Y + 2, X + W - 3, Y + 20, CLR_DARKBLUE);
  OutTxt(X + (W - 12 * 8) Div 2, Y + 3, 'Mille-pattes', CLR_WHITE, CLR_DARKBLUE);
  If State = 2 Then BigText(X + (W - Length(Banner1) * 16) Div 2, Y + 24, Banner1, CLR_DARKRED, CLR_PALEGRAY)
  Else BigText(X + (W - Length(Banner1) * 16) Div 2, Y + 24, Banner1, CLR_DARKGREEN, CLR_PALEGRAY);
  OutTxt(X + (W - Length(Banner2) * 8) Div 2, Y + 56, Banner2, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(OX - 1, OY - 1, OX + BW, OY + BH, CLR_BLACK, CLR_PALEGRAY);
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawBanner;
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
  NDirty := 0;
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

Procedure FlushScr(Counters : Boolean);
Var K : LongInt;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  For K := 0 To NDirty - 1 Do BlitRect(Hps, DX1[K], DY1[K], DX2[K], DY2[K]);
  NDirty := 0;
  DrawBanner;
  If Counters Then
  Begin
    DrawCounters;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Partie (logique du prototype)                                         }
{ ==================================================================== }

Function RndR(Lb, Ub : LongInt) : LongInt;
Begin
  RndR := Lb + Rnd(Ub - Lb + 1);
End;

Procedure SetCell(R, C, O : LongInt);
Begin
  Scr[R, C] := O;
  DrawCell(R, C);
End;

Function NewSeg(R, C : LongInt) : LongInt;
Var K : LongInt;
Begin
  NewSeg := -1;
  For K := 0 To MaxSeg - 1 Do
    If SUsed[K] = 0 Then
    Begin
      SUsed[K] := 1; SR[K] := R; SC[K] := C; SNx[K] := -1; SPv[K] := -1;
      NewSeg := K;
      Exit;
    End;
End;

Procedure FreeSeg(S : LongInt);
Begin
  If S < 0 Then Exit;
  SUsed[S] := 0;
  If SegAt[SR[S], SC[S]] = S Then SegAt[SR[S], SC[S]] := -1;
End;

Procedure RemoveChain(K : LongInt);
Var I : LongInt;
Begin
  For I := K To NCh - 2 Do
  Begin
    KHead[I] := KHead[I + 1]; KTail[I] := KTail[I + 1]; KDir[I] := KDir[I + 1];
  End;
  Dec(NCh);
End;

{ insere un mille-pattes juste apres K dans la liste }
Function InsertChain(K : LongInt) : LongInt;
Var I : LongInt;
Begin
  If NCh >= MaxCh Then
  Begin
    InsertChain := -1;
    Exit;
  End;
  For I := NCh - 1 DownTo K + 1 Do
  Begin
    KHead[I + 1] := KHead[I]; KTail[I + 1] := KTail[I]; KDir[I + 1] := KDir[I];
  End;
  Inc(NCh);
  InsertChain := K + 1;
End;

Function ChainOf(S : LongInt) : LongInt;
Var K, T : LongInt;
Begin
  ChainOf := -1;
  For K := 0 To NCh - 1 Do
  Begin
    T := KHead[K];
    While T >= 0 Do
    Begin
      If T = S Then
      Begin
        ChainOf := K;
        Exit;
      End;
      T := SNx[T];
    End;
  End;
End;

{ efface tous les mille-pattes (vie perdue) }
Procedure ClearCents;
Var R, C, K : LongInt;
Begin
  For R := 1 To ScreenRow Do
    For C := 1 To ScreenCol Do
    Begin
      SegAt[R, C] := -1;
      If Scr[R, C] = O_CENT Then SetCell(R, C, O_BLANK);
    End;
  For K := 0 To MaxSeg - 1 Do SUsed[K] := 0;
  NCh := 0;
End;

Procedure AddScore(N : LongInt);
Begin
  Score := Score + N;
End;

Procedure ShowBanner(St : LongInt; S1, S2 : String);
Begin
  State := St; Banner1 := S1; Banner2 := S2;
  Redraw;
End;

Procedure ResetSpider;
Var R, C : LongInt;
Begin
  R := SpiderY; C := SpiderX;
  SpiderY := 2; SpiderX := 10; SpiderDY := 1; SpiderDX := 1;
  DrawCell(R, C);
  DrawCell(SpiderY, SpiderX);
End;

{ vie perdue : araignee sur le canon, ou mille-pattes sur la terre }
Procedure LoseLife(Why : String);
Begin
  If SoundOn <> 0 Then PlaySnd(3) Else Dummy := WinAlarm(HWND_DESKTOP, 1);
  Dec(Lives);
  LostFlag := 1;
  If ShotGoing Then
  Begin
    ShotGoing := False;
    If Scr[ShotY, ShotX] = O_SHOT Then SetCell(ShotY, ShotX, O_BLANK);
  End;
  If Lives <= 0 Then
  Begin
    Lives := 0;
    If Score > Best Then Best := Score;
    Msg := Why + ' Partie termin' + Chr(130) + 'e : ' + IStr(Score) + ' points (vague ' + IStr(Wave) + ').';
    ShowBanner(2, 'Partie termin' + Chr(130) + 'e', 'Espace ou F2 : nouvelle partie');
    Exit;
  End;
  ResetSpider;
  Msg := Why + ' Il reste ' + IStr(Lives) + ' vie(s).';
  ShowBanner(1, 'Canon perdu !', 'Espace ou clic : continuer');
End;

{ un pas du mille-pattes K : nouvelle tete en (R, C), la queue s'en va }
Procedure AddHead(K, R, C : LongInt);
Var S, T, OldH : LongInt;
Begin
  S := NewSeg(R, C);
  If S < 0 Then Exit;
  OldH := KHead[K];
  SNx[S] := OldH; SPv[OldH] := S; KHead[K] := S;
  T := KTail[K];
  SetCell(SR[T], SC[T], O_BLANK);
  SegAt[SR[T], SC[T]] := -1;
  KTail[K] := SPv[T];
  SNx[KTail[K]] := -1;
  SUsed[T] := 0;
  SegAt[R, C] := S;
  SetCell(R, C, O_CENT);
  If (OldH <> T) And (SUsed[OldH] <> 0) Then DrawCell(SR[OldH], SC[OldH]);
End;

Function IsMush(O : LongInt) : Boolean;
Begin
  IsMush := (O = O_WEAKMUSH) Or (O = O_STRONGMUSH) Or (O = O_WEAKSEG) Or (O = O_STRONGSEG);
End;

{ MoveThisCent du prototype ; resultat False si une vie a ete perdue }
Function MoveThisCent(K : LongInt) : Boolean;
Var Hr, Hc, D, Dir, O : LongInt;
Begin
  MoveThisCent := True;
  Hr := SR[KHead[K]]; Hc := SC[KHead[K]]; D := KDir[K];
  O := Scr[Hr, Hc + D];
  If O = O_BLANK Then AddHead(K, Hr, Hc + D)
  Else If (O = O_WALL) Or (O = O_CENT) Or IsMush(O) Then
  Begin
    O := Scr[Hr + 1, Hc];
    If IsMush(O) Then
    Begin
      If Scr[Hr + 1, Hc + D] = O_BLANK Then AddHead(K, Hr + 1, Hc + D)
      Else
      Begin
        KDir[K] := -D; D := -D;
        If Scr[Hr + 1, Hc + D] = O_BLANK Then AddHead(K, Hr + 1, Hc + D)
        Else
        Begin
          Case RndR(1, 3) Of
            1 : Dir := 1;
            2 : Dir := -1;
          Else
            Dir := 0;
          End;
          If IsMush(Scr[Hr + 1, Hc + Dir]) Then
          Begin
            If (Scr[Hr + 1, Hc + Dir] = O_STRONGMUSH) Or (Scr[Hr + 1, Hc + Dir] = O_WEAKMUSH) Then Dec(NumMush);
            AddHead(K, Hr + 1, Hc + Dir);
          End;
        End;
      End;
    End
    Else If O = O_BLANK Then
    Begin
      KDir[K] := -D;
      AddHead(K, Hr + 1, Hc);
    End
    Else If (O = O_CANNON) Or (O = O_EARTH) Then
    Begin
      MoveThisCent := False;
      ClearCents;
      Dec(NumCent);
      LoseLife('Le mille-pattes est descendu sur terre !');
    End;
  End
  Else If O = O_CANNON Then
  Begin
    MoveThisCent := False;
    ClearCents;
    Dec(NumCent);
    LoseLife('Le mille-pattes a atteint le canon !');
  End;
End;

Procedure NewCentipede;
Var Len, Cnt, S, Prev, Col : LongInt;
Begin
  Inc(NumCent);
  Wave := NumCent;
  MoveWhen := InitMoveWhen - NumCent + Speed;
  If MoveWhen <= 1 Then MoveWhen := 2;
  Len := InitLenCent + NumCent;
  If Len >= 37 Then Len := 37;
  NCh := 1; KHead[0] := -1; KTail[0] := -1; KDir[0] := -1;
  Prev := -1;
  For Cnt := 1 To Len Do
  Begin
    Col := 39 - Len + Cnt - 1 + 1;
    If Col < 2 Then Col := 2;
    S := NewSeg(2, Col);
    If S < 0 Then Break;
    If KHead[0] < 0 Then KHead[0] := S;
    SPv[S] := Prev;
    If Prev >= 0 Then SNx[Prev] := S;
    Scr[2, Col] := O_CENT; SegAt[2, Col] := S;
    Prev := S;
  End;
  KTail[0] := Prev;
  For Col := 2 To 39 Do DrawCell(2, Col);
  Msg := 'Vague ' + IStr(Wave) + ' : un mille-pattes de ' + IStr(Len) + ' anneaux arrive !';
  If Wave > 1 Then PlaySnd(4);
End;

Procedure MoveCentipede;
Var I, Cnt : LongInt;
Begin
  If NCh = 0 Then
  Begin
    NewCentipede;
    Exit;
  End;
  I := 0;
  While I < NCh Do
  Begin
    Cnt := 0;
    While (Cnt < NumMoves Mod MoveWhen) And (I < NCh) Do
    Begin
      Inc(I); Inc(Cnt);
    End;
    If I < NCh Then
    Begin
      If Not MoveThisCent(I) Then Exit;
      While (Cnt < MoveWhen) And (I < NCh) Do
      Begin
        Inc(I); Inc(Cnt);
      End;
    End;
  End;
End;

{ DeleteSegment du prototype : l'anneau touche devient un champignon }
Procedure DeleteSegment(R, C : LongInt);
Var S, K, N, H : LongInt;
Begin
  S := SegAt[R, C];
  If S < 0 Then Exit;
  K := ChainOf(S);
  SegAt[R, C] := -1;
  Scr[R, C] := O_STRONGSEG;
  If K < 0 Then
  Begin
    SUsed[S] := 0;
    DrawCell(R, C);
    Exit;
  End;
  If KHead[K] = S Then
  Begin
    If SNx[S] < 0 Then RemoveChain(K)
    Else
    Begin
      KHead[K] := SNx[S]; SPv[KHead[K]] := -1;
      DrawCell(SR[KHead[K]], SC[KHead[K]]);
    End;
  End
  Else If KTail[K] = S Then
  Begin
    KTail[K] := SPv[S]; SNx[KTail[K]] := -1;
  End
  Else
  Begin
    { au milieu : deux mille-pattes, et ils accelerent }
    Dec(MoveWhen);
    If MoveWhen <= 1 Then MoveWhen := 2;
    N := InsertChain(K);
    If N >= 0 Then
    Begin
      H := SNx[S];
      KHead[N] := H; SPv[H] := -1;
      KTail[N] := KTail[K];
      If Scr[SR[H], SC[H] + 1] = O_STRONGMUSH Then KDir[N] := 1 Else KDir[N] := -1;
      KTail[K] := SPv[S]; SNx[KTail[K]] := -1;
      DrawCell(SR[H], SC[H]);
    End;
  End;
  SUsed[S] := 0;
  DrawCell(R, C);
End;

Procedure MoveShot;
Var Cnt : LongInt;
Begin
  For Cnt := 1 To 2 Do
    If ShotGoing Then
    Begin
      If Scr[ShotY, ShotX] = O_SHOT Then SetCell(ShotY, ShotX, O_BLANK);
      Dec(ShotY);
      Case Scr[ShotY, ShotX] Of
        O_BLANK : SetCell(ShotY, ShotX, O_SHOT);
        O_WEAKSEG :
          Begin
            SetCell(ShotY, ShotX, O_BLANK);
            ShotGoing := False; AddScore(10);
            PlaySnd(1);
          End;
        O_WEAKMUSH :
          Begin
            Dec(NumMush);
            SetCell(ShotY, ShotX, O_BLANK);
            ShotGoing := False; AddScore(10);
            PlaySnd(1);
          End;
        O_STRONGMUSH :
          Begin
            SetCell(ShotY, ShotX, O_WEAKMUSH);
            ShotGoing := False;
            PlaySnd(1);
          End;
        O_STRONGSEG :
          Begin
            SetCell(ShotY, ShotX, O_WEAKSEG);
            ShotGoing := False;
            PlaySnd(1);
          End;
        O_CENT :
          Begin
            AddScore(100);
            PlaySnd(2);
            DeleteSegment(ShotY, ShotX);
            ShotGoing := False;
          End;
      Else
        ShotGoing := False;
      End;
    End;
End;

Procedure Fire;
Begin
  If (State <> 0) Or ShotGoing Then Exit;
  ShotGoing := True;
  ShotY := ScreenRow - 1; ShotX := YouX;
  PlaySnd(0);
  AddScore(-2);
End;

{ deplace le canon de M colonnes (bloque par les champignons) }
Procedure MoveCannon(M : LongInt);
Var Nx, St, Old : LongInt;
Begin
  If (State <> 0) Or (M = 0) Then Exit;
  If M > 0 Then St := 1 Else St := -1;
  While M <> 0 Do
  Begin
    Nx := YouX + St;
    If (Nx <= 1) Or (Nx >= ScreenCol) Then Exit;
    If Scr[ScreenRow - 1, Nx] = O_CENT Then
    Begin
      ClearCents; Dec(NumCent);
      LoseLife('Le canon a heurt' + Chr(130) + ' le mille-pattes !');
      Exit;
    End;
    If (Scr[ScreenRow - 1, Nx] <> O_BLANK) And (Scr[ScreenRow - 1, Nx] <> O_SHOT) Then Exit;
    Old := YouX;
    Scr[ScreenRow - 1, Old] := O_BLANK; Scr[ScreenRow, Old] := O_EARTH;
    YouX := Nx;
    Scr[ScreenRow - 1, YouX] := O_CANNON; Scr[ScreenRow, YouX] := O_CANNON;
    DrawCell(ScreenRow - 1, Old); DrawCell(ScreenRow, Old);
    DrawCell(ScreenRow - 1, YouX); DrawCell(ScreenRow, YouX);
    If (SpiderY >= ScreenRow - 1) And (SpiderX = YouX) Then
    Begin
      LoseLife('L''araign' + Chr(130) + 'e a d' + Chr(130) + 'truit le canon !');
      Exit;
    End;
    M := M - St;
  End;
End;

Procedure MoveSpider;
Var O, R, C : LongInt;
Begin
  R := SpiderY; C := SpiderX;
  O := Scr[R, C];
  If O = O_CANNON Then
  Begin
    LoseLife('L''araign' + Chr(130) + 'e a d' + Chr(130) + 'truit le canon !');
    Exit;
  End;
  { elle seme des champignons dans le bas du terrain }
  If (O = O_BLANK) And (R < ScreenRow - 1) And (R > ScreenRow Div 3) And (NumMush < InitNumMushs) Then
    If RndR(1, ScreenRow - R) = 1 Then
    Begin
      Scr[R, C] := O_STRONGMUSH;
      Inc(NumMush);
    End;
  O := Scr[R + SpiderDY, C + SpiderDX];
  If (O = O_WALL) Or (O = O_EARTH) Then
  Begin
    If (R + SpiderDY = ScreenRow) Or (R + SpiderDY = 1) Then SpiderDY := -SpiderDY;
    If (C + SpiderDX = ScreenCol) Or (C + SpiderDX = 1) Then SpiderDX := -SpiderDX;
    DrawCell(R, C);
    Exit;
  End;
  If O = O_CANNON Then
  Begin
    LoseLife('L''araign' + Chr(130) + 'e a d' + Chr(130) + 'truit le canon !');
    Exit;
  End;
  SpiderY := R + SpiderDY; SpiderX := C + SpiderDX;
  DrawCell(R, C);
  DrawCell(SpiderY, SpiderX);
End;

Procedure SetUp;
Var R, C, Cnt : LongInt;
Begin
  Score := 50; Lives := 3; NumMoves := 1; NumCent := 0; Wave := 1; NCh := 0; LostFlag := 0;
  ShotGoing := False; Target := 0;
  For C := 0 To MaxSeg - 1 Do SUsed[C] := 0;
  For R := 1 To ScreenRow Do
    For C := 1 To ScreenCol Do
    Begin
      SegAt[R, C] := -1;
      If (R = 1) Or (C = 1) Or (C = ScreenCol) Then Scr[R, C] := O_WALL
      Else If R = ScreenRow Then Scr[R, C] := O_EARTH
      Else Scr[R, C] := O_BLANK;
    End;
  Cnt := 0;
  While Cnt < InitNumMushs Do
  Begin
    R := RndR(3, ScreenRow - 2); C := RndR(2, ScreenCol - 1);
    If Scr[R, C] = O_BLANK Then
    Begin
      Scr[R, C] := O_STRONGMUSH;
      Inc(Cnt);
    End;
  End;
  NumMush := InitNumMushs;
  YouX := 20;
  Scr[ScreenRow - 1, YouX] := O_CANNON; Scr[ScreenRow, YouX] := O_CANNON;
  SpiderY := 2; SpiderX := 10; SpiderDY := 1; SpiderDX := 1;
  DrawAll;
End;

Procedure NewGame;
Begin
  State := 1;
  SetUp;
  Msg := 'Emp' + Chr(136) + 'chez le mille-pattes de descendre sur terre. M' + Chr(130) + 'fiez-vous de ' +
         'l''araign' + Chr(130) + 'e !';
  ShowBanner(1, 'Mille-pattes', 'Espace ou clic : commencer');
End;

Procedure Resume;
Begin
  If State = 2 Then
  Begin
    NewGame;
    Exit;
  End;
  If State = 0 Then Exit;
  State := 0;
  DrawAll;
  Redraw;
End;

Procedure TogglePause;
Begin
  If State = 0 Then
  Begin
    Msg := 'Pause.';
    ShowBanner(1, 'Pause', 'Espace, P ou clic : reprendre');
  End
  Else If State = 1 Then Resume;
End;

{ canon automatique : sous l'anneau le plus bas, et tirer }
Procedure AutoPlay;
Var K, S, BestR, BestC : LongInt;
Begin
  BestR := 0; BestC := YouX;
  For K := 0 To NCh - 1 Do
  Begin
    S := KHead[K];
    While S >= 0 Do
    Begin
      If SR[S] > BestR Then
      Begin
        BestR := SR[S]; BestC := SC[S];
      End;
      S := SNx[S];
    End;
  End;
  If BestC < YouX Then MoveCannon(-1) Else If BestC > YouX Then MoveCannon(1);
  If State = 0 Then Fire;
End;

Procedure TimerTick;
Var S0, L0 : LongInt;
Begin
  If State <> 0 Then Exit;
  S0 := Score; L0 := Lives;
  Inc(NumMoves);
  MoveCentipede;
  If State <> 0 Then Exit;
  If NumMoves Mod 3 = 0 Then
  Begin
    MoveSpider;
    If State <> 0 Then Exit;
  End;
  If Auto <> 0 Then AutoPlay
  Else If (Target > 0) And (Target <> YouX) Then
  Begin
    If Target < YouX Then MoveCannon(-1) Else MoveCannon(1);
  End;
  If State <> 0 Then Exit;
  If ShotGoing Then MoveShot;
  FlushScr((Score <> S0) Or (Lives <> L0) Or (NumMoves Mod 25 = 0));
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
  SetMark(CM_SLOW, Speed = 3); SetMark(CM_NORMAL, Speed = 0); SetMark(CM_FAST, Speed = -3);
  SetMark(CM_AUTO, Auto <> 0);
  SetMark(CM_SOUND, SoundOn <> 0);
End;

Procedure SetSpeed(V : LongInt);
Begin
  MoveWhen := MoveWhen - Speed + V;
  If MoveWhen <= 1 Then MoveWhen := 2;
  Speed := V;
  SetMarks;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PAUSE : TogglePause;
    CM_AUTO :
      Begin
        Auto := 1 - Auto;
        SetMarks;
      End;
    CM_SOUND :
      Begin
        SoundOn := 1 - SoundOn;
        SetMarks;
      End;
    CM_SLOW : SetSpeed(3);
    CM_NORMAL : SetSpeed(0);
    CM_FAST : SetSpeed(-3);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        If State = 0 Then TogglePause;
        LClr;
        LAdd('Emp' + Chr(136) + 'chez le mille-pattes de descendre sur terre. Tirez-lui dessus ; touch' +
             Chr(130) + ' au milieu, il se coupe en deux mille-pattes, qui vont plus vite. Chaque anneau ' +
             'touch' + Chr(130) + ' devient un champignon (violet). Un champignon tient deux tirs. ');
        LAdd('M' + Chr(130) + 'fiez-vous de l''araign' + Chr(130) + 'e : elle ne peut pas ' + Chr(136) +
             'tre tu' + Chr(130) + 'e, s' + Chr(138) + 'me des champignons et d' + Chr(130) +
             'truit le canon au contact. Un mille-pattes qui atteint la terre co' + Chr(150) +
             'te aussi une vie ; vous en avez trois.' + Chr(10) + Chr(10));
        LAdd('Pointage : 50 au d' + Chr(130) + 'part, -2 par tir, +10 par champignon d' + Chr(130) + 'truit, ' +
             '+100 par anneau.' + Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches (ou 1 3, 4 6, 7 9 pour aller plus vite), Espace (tirer), P ' +
             '(pause), F2 (nouvelle partie). Souris : le canon suit la souris, clic pour tirer.');
        Dummy := LMsgBox('Mille-pattes - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT :
      Begin
        If State = 0 Then TogglePause;
        Dummy := Ask('Mille-pattes pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                     'CENTIPED.PAS de 7iles (2024, mode texte) et dessin' + Chr(130) + ' en couleur.' + Chr(10) +
                     'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                     'A propos de Mille-pattes', MB_OK Or MB_INFORMATION);
      End;
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Function MouseCol(Mx : LongInt) : LongInt;
Var C : LongInt;
Begin
  C := (Mx - OX) Div CW_ + 1;
  If C < 2 Then C := 2;
  If C > ScreenCol - 1 Then C := ScreenCol - 1;
  MouseCol := C;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If State <> 0 Then
    Begin
      Resume;
      Exit;
    End;
    Target := MouseCol(X);
    Fire;
    Exit;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 214) And (Y < 242) Then Command(CM_NEW)
    Else If (Y >= 248) And (Y < 276) Then Command(CM_PAUSE);
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
    If Vk = VK_LEFT Then Begin Target := 0; MoveCannon(-1); FlushScr(False); Exit; End;
    If Vk = VK_RIGHT Then Begin Target := 0; MoveCannon(1); FlushScr(False); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_UP) Then
    Begin
      If State = 0 Then Fire Else Resume;
      Exit;
    End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Resume; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Target := 0;
    Case UpCase(Chr(Ch)) Of
      '1', '<', ',' : MoveCannon(-1);
      '3', '>', '.' : MoveCannon(1);
      '4' : MoveCannon(-2);
      '6' : MoveCannon(2);
      '7' : MoveCannon(-3);
      '9' : MoveCannon(3);
      '2', '5', '8', ' ' : If State = 0 Then Fire Else Resume;
      'P' : TogglePause;
      'N' : NewGame;
    Else
      KeyChar := False;
    End;
    If State = 0 Then FlushScr(False);
    Exit;
  End;
  KeyChar := False;
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
        If (State = 0) And (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then Target := MouseCol(X);
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

Var
  Fl, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Auto := 0; Best := 0; Speed := 0; NDirty := 0; State := 1; Frame := 0; Lives := 3; Wave := 1;
  SoundOn := 1; SndCur := 0; SndEnd := 0;
  Client := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
    If (S = '/AUTO') Or (S = '/auto') Then Auto := 1;
    If (S = '/NOSOUND') Or (S = '/nosound') Then SoundOn := 0;
  End;
  MakeSounds;
  InitBmi;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('CENTIPED'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('CENTIPED'), Z2('Mille-pattes'), 0, 0, 0,
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
  MItem(MIS_TEXT, 0, CM_SLOW, 'Vitesse ~lente');
  MItem(MIS_TEXT, MIA_CHECKED, CM_NORMAL, 'Vitesse ~normale');
  MItem(MIS_TEXT, 0, CM_FAST, 'Vitesse ~rapide');
  MItem(MIS_SEPARATOR, 0, 0, '');
  If Auto <> 0 Then MItem(MIS_TEXT, MIA_CHECKED, CM_AUTO, 'Canon ~automatique')
  Else MItem(MIS_TEXT, 0, CM_AUTO, 'Canon ~automatique');
  If SoundOn <> 0 Then MItem(MIS_TEXT, MIA_CHECKED, CM_SOUND, '~Son')
  Else MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Mille-pattes');
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
  If Auto <> 0 Then
  Begin
    State := 0;
    Msg := 'Canon automatique (d' + Chr(130) + 'monstration).';
  End;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
