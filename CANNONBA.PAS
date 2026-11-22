{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: CANNONBA - Cannonball, l'homme-canon du cirque pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program CANNONBA;

{$R-,S-,I-}

{ Compilation : OS2PC CANNONBA.PAS   (produit CANNONBA.EXE)

  Portage vers OS/2-0 du prototype CANNONBA.PAS du depot 7iles (Turbo
  Pascal, BGI en 640 x 480 : fond bleu, canon en disque brun, trajectoire
  en points blancs, filet en barre, clavier seulement) : fenetre de
  Presentation Manager avec menus, image en memoire recopiee par
  GpiDrawBits (seules les zones qui bougent sont recopiees), interieur
  d'un chapiteau (toile rayee, lambrequin festonne, guirlande de fanions,
  public dans les gradins, piste en sciure bordee de sa banquette,
  projecteurs), canon de cirque peint sur son affut a roue, artiste en
  combinaison et casque oriente selon sa trajectoire, trainee de points,
  fumee au depart, filet sur chariot qui s'enfonce et fait rebondir
  l'artiste, confettis, etoiles autour de la tete en cas de chute, panneau
  du pointage, barre d'etat et apparence d'OS/2 Warp 3.

  Comme le prototype : le canon part d'un angle tire au hasard entre 40
  et 59 degres ; on l'ajuste de 10 a 80 degres avec les fleches gauche et
  droite, puis Espace tire l'artiste (vitesse de depart 50, gravite 9,81) ;
  pendant le vol, les fleches deplacent le filet pour le rattraper ; les
  artistes sauves et tombes sont comptes.
  Ce qui est corrige : la trajectoire etait effacee point par point avec
  le fond (trous dans le decor) ; le filet se deplacait par a-coups selon
  la repetition du clavier ; le prototype ne s'arretait jamais (pas de fin
  de partie ni de pointage) ; l'artiste pouvait sortir de l'ecran ; le
  message << MPH >> affichait une valeur sans rapport avec le tir.
  Ce qui s'ajoute : la puissance du canon (fleches haut et bas, 40 a 60),
  un spectacle de 10 artistes avec pointage (100 par artiste sauve, plus
  la precision au centre du filet, la distance, le vent et les series),
  courants d'air sous le chapiteau a partir du 3e artiste, trois
  difficultes (largeur du filet), point de chute prevu (option), record
  de la seance, demonstration, souris, bruitages (canon, filet, chute,
  applaudissements).

  Clavier : avant le tir, fleches gauche et droite (angle), haut et bas
  (puissance), Espace (feu) ; en vol, fleches gauche et droite (filet) ;
  Entree (artiste suivant), F2 (nouveau spectacle), F1 (regles).
  Souris : avant le tir, le pointeur regle l'angle et la puissance, clic :
  feu ; en vol, le filet suit le pointeur.
  Parametres : /SEED:n ; /AUTO (demonstration) ; /NOSOUND ; /TEST
  (essais du jeu sans fenetre, resultat sur le port serie COM1). }

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
  VK_NEWLINE = $08; VK_SPACE = $10;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_FIRE = 102; CM_NEXT = 103; CM_QUIT = 104;
  CM_AUTO = 201; CM_SOUND = 202; CM_WIND = 203; CM_HINT = 204; CM_EASY = 205; CM_NORMAL = 206; CM_HARD = 207;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : chapiteau de 432 x 400 }
  BW = 432; BH = 400; OX = 8; OY = 8;
  PnX = 452; PW = 164;
  CWant = 624; CHWant = 436;
  { canon (pivot sur l'axe de la roue), filet, piste }
  CanX = 58; CanY = 334; BarL = 62; WheelR = 19;
  NetY = 334; NetMin = 150; NetMax = 396; FloorY = 372; Wall = 426;
  Shows = 10;
  { physique (unites du prototype : points, secondes) : positions en
    millipoints, temps en millisecondes ; une image = 56 ms de vol }
  Grav = 9810; DtMs = 56;
  MaxPt = 160;
  { couleurs de l'image }
  C_RED = 0;                                 { 0..7 : toile rouge }
  C_CREAM = 8;                               { 8..15 : toile creme }
  C_STAND = 16;                              { 16..23 : gradins }
  C_FLOOR = 24;                              { 24..31 : sciure }
  C_CURB = 32;                               { 32..35 : banquette rouge }
  C_CURBW = 36;                              { 36..39 : bord blanc de la banquette }
  C_GOLD = 40;                               { 40..43 : dorures }
  C_BLUE = 44;                               { 44..51 : canon }
  C_WOOD = 52;                               { 52..55 : bois de la roue }
  C_SKIN = 56; C_SKIN2 = 57; C_SUIT = 58; C_SUIT2 = 59; C_HELM = 60; C_HELM2 = 61; C_VISOR = 62;
  C_NET = 63; C_NET2 = 64;
  C_POLE = 65;                               { 65..67 : chrome }
  C_WHITE = 68; C_BLACK = 69; C_SHADOW = 70; C_YELLOW = 71; C_BANNER = 72; C_BANNERE = 73;
  C_GREENT = 74; C_REDT = 75; C_TRAIL = 76; C_TRAIL2 = 77;
  C_SMOKE = 78;                              { 78..81 : fumee }
  C_FLAG = 82;                               { 82..85 : fanions }
  C_HEAD = 86;                               { 86..89 : tetes du public }
  C_VAL = 90;                                { 90..93 : lambrequin }
  { etats }
  S_AIM = 1; S_FLY = 2; S_CAUGHT = 3; S_MISS = 4; S_OVER = 5;
  { particules }
  P_SMOKE = 1; P_CONF = 2; P_DUST = 3;
  SndRate = 11025;

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { tir }
  Angle, Power, Wind, NetX, NetW, FlyT, X0m, Y0m, VX0, VY0, HXm, HYm, HVX, HVY, PredX : LongInt;
  LieX, LieY, LieMode, Bounce, Sag, TrailN : LongInt;
  HoldL, HoldR, PulL, PulR, MouseOn, MouseX, AutoDelay : LongInt;
  { particules }
  PtX, PtY, PtVX, PtVY, PtL, PtK : Array[0..MaxPt - 1] Of LongInt;
  NPt : LongInt;
  { partie }
  State, Artist, Saved, Fell, Streak, Score, Best, Seed, AutoAll, SoundOn, TestMode, WindOn, HintOn : LongInt;
  Diff, Wait, Tick, LastPts : LongInt;
  { zones a recopier }
  FullBlit, BackOk : LongInt;
  Banner, Banner2, Banner3, Msg, LastMsg : String;
  BannerC : LongInt;
  PanS : Array[0..7] Of String[40];
  LastSig : LongInt;
  { bruitages }
  SndBuf : Array[0..49999] Of Byte;
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

Function Clamp(V, A, B : LongInt) : LongInt;
Begin
  If V < A Then V := A;
  If V > B Then V := B;
  Clamp := V;
End;

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

{ nombre avec une decimale (dixiemes) et la virgule francaise }
Function Dec1(T : LongInt) : String;
Var S : String; Neg : Boolean;
Begin
  Neg := T < 0;
  T := AbsI(T);
  S := IStr(T Div 10) + ',' + IStr(T Mod 10);
  If Neg Then S := '-' + S;
  Dec1 := S;
End;

Function PadL(S : String; N : LongInt) : String;
Begin
  While Length(S) < N Do S := ' ' + S;
  PadL := S;
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
Var I : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 7 Do SetPal(C_RED + I, Mix($3A0608, $F04838, I, 7));
  For I := 0 To 7 Do SetPal(C_CREAM + I, Mix($4A3A28, $FFF2D2, I, 7));
  For I := 0 To 7 Do SetPal(C_STAND + I, Mix($0C0A1A, $6A5C88, I, 7));
  For I := 0 To 7 Do SetPal(C_FLOOR + I, Mix($5A3816, $F2CC88, I, 7));
  For I := 0 To 3 Do SetPal(C_CURB + I, Mix($6A0A10, $E8303A, I, 3));
  For I := 0 To 3 Do SetPal(C_CURBW + I, Mix($9A9490, $FFFFFF, I, 3));
  For I := 0 To 3 Do SetPal(C_GOLD + I, Mix($7A5208, $FFE680, I, 3));
  For I := 0 To 7 Do SetPal(C_BLUE + I, Mix($0A1448, $70A8FF, I, 7));
  For I := 0 To 3 Do SetPal(C_WOOD + I, Mix($3A1E0A, $C88840, I, 3));
  SetPal(C_SKIN, $F0B890); SetPal(C_SKIN2, $1830A0); SetPal(C_SUIT, $2C5CF0); SetPal(C_SUIT2, $FFD830);
  SetPal(C_HELM, $F0B020); SetPal(C_HELM2, $FFFFFF); SetPal(C_VISOR, $102040);
  SetPal(C_NET, $E8E8E8); SetPal(C_NET2, $9A9AA0);
  For I := 0 To 2 Do SetPal(C_POLE + I, Mix($5A5E66, $E8ECF2, I, 2));
  SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $000000); SetPal(C_SHADOW, $000000); SetPal(C_YELLOW, $FFDC40);
  SetPal(C_BANNER, $2A0A10); SetPal(C_BANNERE, $FFC850); SetPal(C_GREENT, $80F0A0); SetPal(C_REDT, $FF7060);
  SetPal(C_TRAIL, $FFF4B0); SetPal(C_TRAIL2, $C8A048);
  For I := 0 To 3 Do SetPal(C_SMOKE + I, Mix($F0F0F0, $787480, I, 3));
  SetPal(C_FLAG, $E82828); SetPal(C_FLAG + 1, $FFD030); SetPal(C_FLAG + 2, $2C64E0); SetPal(C_FLAG + 3, $30B048);
  SetPal(C_HEAD, $2A1E16); SetPal(C_HEAD + 1, $5A3A24); SetPal(C_HEAD + 2, $1A1A28); SetPal(C_HEAD + 3, $8A6A40);
  For I := 0 To 3 Do SetPal(C_VAL + I, Mix($3A0410, $A01830, I, 3));
End;

Procedure Pix(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Fb[(BH - 1 - Y) * BW + X] := C;
End;

Function GetPix(X, Y : LongInt) : LongInt;
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then GetPix := Fb[(BH - 1 - Y) * BW + X] Else GetPix := 0;
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

Procedure Line(X1, Y1, X2, Y2, C : LongInt);
Var Dx, Dy, Sx, Sy, E, E2 : LongInt;
Begin
  Dx := AbsI(X2 - X1); Dy := -AbsI(Y2 - Y1);
  If X1 < X2 Then Sx := 1 Else Sx := -1;
  If Y1 < Y2 Then Sy := 1 Else Sy := -1;
  E := Dx + Dy;
  While True Do
  Begin
    Pix(X1, Y1, C);
    If (X1 = X2) And (Y1 = Y2) Then Exit;
    E2 := 2 * E;
    If E2 >= Dy Then
    Begin
      E := E + Dy;
      X1 := X1 + Sx;
    End;
    If E2 <= Dx Then
    Begin
      E := E + Dx;
      Y1 := Y1 + Sy;
    End;
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
  FbText(X + 1, Y + 1, S, C_SHADOW, Sc);
  FbText(X, Y, S, C, Sc);
End;

{ recopie du decor (Back) dans l'image sur un rectangle }
Procedure Restore(X1, Y1, X2, Y2 : LongInt);
Var X, Y, B : LongInt;
Begin
  X1 := MaxI(0, X1); Y1 := MaxI(0, Y1); X2 := MinI(BW - 1, X2); Y2 := MinI(BH - 1, Y2);
  For Y := Y1 To Y2 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := X1 To X2 Do Fb[B + X] := Back[B + X];
  End;
End;

Function CosD(A : LongInt) : LongInt;
Begin
  CosD := Round(Cos(A * Pi / 180) * 1024);
End;

Function SinD(A : LongInt) : LongInt;
Begin
  SinD := Round(Sin(A * Pi / 180) * 1024);
End;

{ ==================================================================== }
{ Decor : le chapiteau                                                  }
{ ==================================================================== }

{ eclairage des deux projecteurs (0, 1 ou 2 crans de plus) }
Function SpotLit(X, Y : LongInt) : LongInt;
Var Px, Py, Al, Pe, L : LongInt;
Begin
  L := 0;
  Px := X - 70; Py := Y + 10;
  Al := (Px * 311 + Py * 976) Div 1024; Pe := AbsI(Px * 976 - Py * 311) Div 1024;
  If (Al > 0) And (Pe * 100 < Al * 11) Then L := L + 2 Else If (Al > 0) And (Pe * 100 < Al * 14) Then L := L + 1;
  Px := X - 362; Py := Y + 10;
  Al := (Px * (-242) + Py * 995) Div 1024; Pe := AbsI(Px * 995 + Py * 242) Div 1024;
  If (Al > 0) And (Pe * 100 < Al * 11) Then L := L + 2 Else If (Al > 0) And (Pe * 100 < Al * 14) Then L := L + 1;
  SpotLit := MinI(L, 3);
End;

Function BackPix(X, Y : LongInt) : LongInt;
Var L, K, Sh, Base, R, Yy, Hx, Dy, D, Ed, E, Q, C : LongInt;
Begin
  L := SpotLit(X, Y);
  If Y < 248 Then
  Begin
    { toile rayee en perspective vers le mat central }
    K := (X - 216) * 100 Div (Y + 80) + 7000;
    If (K Div 14) Mod 2 = 0 Then Base := C_RED Else Base := C_CREAM;
    Sh := 21 - (248 - Y) * 12 Div 248 - AbsI(X - 216) * 8 Div 216 + L * 3;
    If K Mod 14 = 0 Then Sh := Sh - 4;
    Sh := (Sh + ((X And 1) * 2 + (Y And 1) * 3) Mod 4) Div 4;
    C := Base + Clamp(Sh, 0, 7);
    { lambrequin festonne en haut }
    D := (X Mod 28) - 14;
    Ed := 24 + (196 - D * D) Div 28;
    If Y <= Ed Then
    Begin
      C := C_VAL + Clamp(1 + Y * 2 Div Ed + L Div 2, 0, 3);
      If Y >= Ed - 1 Then C := C_GOLD + 2;
      If (Y = 4) Or (Y = 5) Then C := C_GOLD + 1;
      If (Y >= 9) And (Y <= 10) And ((X Mod 14) < 7) Then C := C_GOLD;
    End
    Else If ((D = 0) Or (D = -1)) And (Y <= Ed + 5) Then C := C_GOLD + 3 - (Y - Ed) Div 2;
  End
  Else If Y < 346 Then
  Begin
    { gradins : rangees de spectateurs dans la penombre }
    R := (Y - 248) Div 16; Yy := (Y - 248) Mod 16;
    Hx := ((X + R * 5) Mod 12) - 6; Dy := Yy - 6;
    If Hx * Hx + Dy * Dy <= 15 Then C := C_HEAD + ((X Div 12) * 7 + R * 3) Mod 4
    Else If (Dy >= 3) And (AbsI(Hx) <= 5) And (Yy < 13) Then C := C_STAND + Clamp(L, 0, 7)
    Else If Yy >= 13 Then C := C_STAND + Clamp(3 + L, 0, 7)
    Else C := C_STAND + Clamp(1 + L + R Div 2, 0, 7);
  End
  Else If Y < 352 Then
  Begin
    { balustrade doree }
    If Y <= 347 Then C := C_GOLD + 2
    Else If (X Mod 24) < 2 Then C := C_GOLD + 1
    Else C := C_STAND;
  End
  Else
  Begin
    { piste : sciure, banquette en ellipse }
    E := (X - 240) * (X - 240) * 10 Div 900 + (Y - 470) * (Y - 470) * 1000 Div 12100;
    Q := ((X * 7919 + Y * 104729) Shr 3) Mod 3;
    Sh := (8 + (Y - 352) * 8 Div 48 + ((X And 1) * 2 + (Y And 1) * 3) Mod 4) Div 4 + Q;
    If E > 1000 Then Sh := Sh - 2;
    If (E >= 880) And (E <= 1000) Then
    Begin
      If E < 912 Then C := C_CURBW + Clamp(1 + L, 0, 3)
      Else C := C_CURB + Clamp(1 + L - (E - 912) Div 40, 0, 3);
    End
    Else C := C_FLOOR + Clamp(Sh + L, 0, 7);
  End;
  BackPix := C;
End;

Procedure RenderBack;
Var X, Y, I, U, Yb, Fx, J, Hw, L, C : LongInt;
Begin
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do Fb[(BH - 1 - Y) * BW + X] := BackPix(X, Y);
  { guirlande de fanions }
  For X := 0 To BW - 1 Do
  Begin
    U := 2 * X - BW;
    Yb := 92 - 34 * U * U Div (BW * BW);
    Pix(X, Yb, C_GOLD + 1);
  End;
  I := 0; Fx := 7;
  While Fx < BW - 4 Do
  Begin
    U := 2 * Fx - BW;
    Yb := 92 - 34 * U * U Div (BW * BW) + 1;
    For J := 0 To 9 Do
    Begin
      Hw := (10 - J) Div 2;
      Rect(Fx - Hw, Yb + J, Fx + Hw, Yb + J, C_FLAG + I Mod 4);
    End;
    Pix(Fx - 4, Yb, C_WHITE);
    Inc(I); Fx := Fx + 18;
  End;
  { mat du fanion de vent (courant d'air) }
  Rect(Wall - 9, 96, Wall - 8, 150, C_POLE + 2);
  Rect(Wall - 7, 96, Wall - 7, 150, C_POLE);
  Disc(Wall - 8, 95, 2, C_GOLD + 3);
  If Wind = 0 Then
  Begin
    For J := 0 To 11 Do Rect(Wall - 6, 98 + J, Wall - 6 + (12 - J) Div 3, 98 + J, C_FLAG + (J Div 6));
  End
  Else
  Begin
    L := 8 + AbsI(Wind) Div 250;
    For J := 0 To L Do
    Begin
      Hw := 5 - J * 5 Div L;
      If Wind > 0 Then X := Wall - 6 + J Else X := Wall - 10 - J;
      Rect(X, 100 - Hw, X, 100 + Hw, C_FLAG + (J * 2 Div L));
    End;
  End;
  { affut du canon : caisse peinte, dorures, etoile }
  Rect(CanX - 34, 370, CanX + 30, 373, C_FLOOR);
  For Y := 342 To 370 Do
  Begin
    X := CanX - 28 + (370 - Y) Div 4;
    I := CanX + 22 - (370 - Y) Div 3;
    Rect(X, Y, I, Y, C_RED + 2 + (370 - Y) Div 10);
    Pix(X, Y, C_GOLD + 2); Pix(I, Y, C_GOLD);
  End;
  Rect(CanX - 21, 342, CanX + 12, 343, C_GOLD + 2);
  Rect(CanX - 28, 369, CanX + 22, 370, C_GOLD + 1);
  For J := -3 To 3 Do
  Begin
    Pix(CanX + J - 4, 358, C_GOLD + 3); Pix(CanX - 4, 358 + J, C_GOLD + 3);
    If AbsI(J) <= 1 Then Begin Pix(CanX - 4 + J, 358 + J, C_GOLD + 3); Pix(CanX - 4 + J, 358 - J, C_GOLD + 3); End;
  End;
  Move(Fb, Back, SizeOf(Fb));
  BackOk := 1;
End;

{ ==================================================================== }
{ Objets mobiles                                                        }
{ ==================================================================== }

{ canon (tube peint, bagues dorees, etoile) et sa roue }
Procedure DrawCannon;
Var X, Y, Px, Py, Ca, Sa, T, W, R, C, Sh, Tt, Wq, K : LongInt; In0 : Boolean;
Begin
  Ca := CosD(Angle); Sa := SinD(Angle);
  For Y := CanY - 76 To CanY + 12 Do
    For X := CanX - 14 To CanX + 76 Do
    Begin
      Px := X - CanX; Py := Y - CanY;
      T := (Px * Ca - Py * Sa) Div 64; W := (-Px * Sa - Py * Ca) Div 64;
      In0 := False; R := 9;
      If (T >= 0) And (T <= 54 * 16) And (AbsI(W) <= 9 * 16) Then In0 := True
      Else If (T > 54 * 16) And (T <= 62 * 16) And (AbsI(W) <= 11 * 16) Then
      Begin
        In0 := True; R := 11;
      End
      Else If (T < 0) And (T * T + W * W <= 20736) Then In0 := True;
      If In0 Then
      Begin
        Sh := Clamp(4 + W * 3 Div (R * 16), 0, 7);
        C := C_BLUE + Sh;
        If ((T >= 12 * 16) And (T <= 16 * 16)) Or ((T >= 38 * 16) And (T <= 41 * 16)) Or (T > 54 * 16) Then
          C := C_GOLD + Clamp(1 + W * 2 Div (R * 16), 0, 3);
        Tt := T Div 16 - 27; Wq := W Div 16;
        If (AbsI(Tt) + AbsI(Wq) <= 2) Or ((AbsI(Tt) <= 4) And (Wq = 0)) Or ((AbsI(Wq) <= 4) And (Tt = 0)) Then C := C_WHITE;
        If (T >= 61 * 16) And (AbsI(W) <= 6 * 16) Then C := C_BLACK;
        Fb[(BH - 1 - Y) * BW + X] := C;
      End;
    End;
  { roue a rayons }
  For Y := -WheelR To WheelR Do
    For X := -WheelR To WheelR Do
    Begin
      R := X * X + Y * Y;
      If (R <= WheelR * WheelR) And (R >= (WheelR - 3) * (WheelR - 3)) Then
      Begin
        If Y < -4 Then C := C_WOOD + 3 Else If Y < 6 Then C := C_WOOD + 2 Else C := C_WOOD + 1;
        If R >= (WheelR - 1) * (WheelR - 1) Then C := C_BLACK;
        Pix(CanX + X, CanY + Y, C);
      End;
    End;
  For K := 0 To 7 Do
    Line(CanX, CanY, CanX + CosD(K * 45 + 22) * (WheelR - 3) Div 1024, CanY + SinD(K * 45 + 22) * (WheelR - 3) Div 1024,
         C_WOOD + 2);
  Disc(CanX, CanY, 4, C_GOLD + 2);
  Pix(CanX - 1, CanY - 1, C_GOLD + 3); Pix(CanX, CanY, C_GOLD);
End;

{ l'artiste : combinaison bleue a bande jaune, casque dore, bras en
  avant, cerne de noir pour se detacher de la toile ; (Ux, Uy) :
  direction de la tete (sur 1024) }
Var
  ManM : Array[0..37 * 37 - 1] Of LongInt;

Procedure DrawMan(Cx, Cy, Ux, Uy : LongInt);
Var X, Y, Px, Py, T, W, C, Aw, K : LongInt;
Begin
  For Y := 0 To 36 Do
    For X := 0 To 36 Do
    Begin
      Px := X - 18; Py := Y - 18;
      T := (Px * Ux + Py * Uy) Div 64; W := (-Px * Uy + Py * Ux) Div 64;
      Aw := AbsI(W);
      C := -1;
      If (T - 96) * (T - 96) + W * W <= 3364 Then
      Begin
        If W > 14 Then C := C_SKIN
        Else If Aw <= 6 Then C := C_HELM2
        Else C := C_HELM;
        If (T >= 136) And (W > 4) Then C := C_VISOR;
      End
      Else If (T >= 24) And (T <= 212) And (Aw >= 38) And (Aw <= 62) Then
      Begin
        If T > 180 Then C := C_SKIN Else If T > 160 Then C := C_SUIT2 Else C := C_SUIT;
      End
      Else If (T >= -112) And (T <= 40) And (Aw <= 54) Then
      Begin
        C := C_SUIT;
        If Aw <= 12 Then C := C_SUIT2;
        If (T >= -48) And (T <= -32) Then C := C_HELM;
        If W >= 40 Then C := C_SKIN2;
      End
      Else If (T >= -240) And (T < -112) And (Aw >= 9) And (Aw <= 44) Then
      Begin
        C := C_SUIT;
        If T < -204 Then C := C_HELM;
      End;
      ManM[Y * 37 + X] := C;
    End;
  For Y := 0 To 36 Do
    For X := 0 To 36 Do
    Begin
      C := ManM[Y * 37 + X];
      If C < 0 Then
      Begin
        K := 0;
        If (X > 0) And (ManM[Y * 37 + X - 1] >= 0) Then K := 1;
        If (X < 36) And (ManM[Y * 37 + X + 1] >= 0) Then K := 1;
        If (Y > 0) And (ManM[(Y - 1) * 37 + X] >= 0) Then K := 1;
        If (Y < 36) And (ManM[(Y + 1) * 37 + X] >= 0) Then K := 1;
        If K <> 0 Then Pix(Cx + X - 18, Cy + Y - 18, C_BLACK);
      End
      Else Pix(Cx + X - 18, Cy + Y - 18, C);
    End;
End;

{ etoiles qui tournent autour de la tete (artiste tombe) }
Procedure DrawStars(Hx, Hy : LongInt);
Var K, A, X, Y : LongInt;
Begin
  For K := 0 To 2 Do
  Begin
    A := Tick * 18 + K * 120;
    X := Hx + CosD(A) * 10 Div 1024; Y := Hy - 7 + SinD(A) * 4 Div 1024;
    Pix(X, Y, C_YELLOW); Pix(X - 1, Y, C_YELLOW); Pix(X + 1, Y, C_YELLOW); Pix(X, Y - 1, C_YELLOW);
    Pix(X, Y + 1, C_YELLOW);
  End;
End;

{ filet sur son chariot (Sag : enfoncement au centre) }
Procedure DrawNet;
Var X1, X2, X, Y, U, S, Top : LongInt;
Begin
  X1 := NetX - NetW Div 2; X2 := NetX + NetW Div 2;
  Rect(X1 - 6, 371, X2 + 6, 372, C_FLOOR + 1);
  Rect(X1 - 3, NetY - 6, X1 - 2, 366, C_POLE + 2); Rect(X1 - 1, NetY - 6, X1 - 1, 366, C_POLE);
  Rect(X2 + 1, NetY - 6, X2 + 2, 366, C_POLE + 2); Rect(X2 + 3, NetY - 6, X2 + 3, 366, C_POLE);
  Rect(X1 - 4, NetY - 8, X1 - 1, NetY - 7, C_GOLD + 2); Rect(X2 + 1, NetY - 8, X2 + 4, NetY - 7, C_GOLD + 2);
  Rect(X1 - 9, 363, X2 + 9, 366, C_RED + 3); Rect(X1 - 9, 363, X2 + 9, 363, C_GOLD + 2);
  Rect(X1 - 9, 366, X2 + 9, 366, C_RED + 1);
  Disc(X1 - 4, 369, 3, C_BLACK); Disc(X2 + 4, 369, 3, C_BLACK);
  Pix(X1 - 4, 369, C_POLE + 2); Pix(X2 + 4, 369, C_POLE + 2);
  For X := X1 To X2 Do
  Begin
    U := 2 * (X - NetX) * 100 Div MaxI(1, NetW);
    S := Sag * (10000 - U * U) Div 10000;
    Top := NetY + S;
    Pix(X, Top, C_WHITE);
    For Y := Top + 1 To Top + 6 Do
      If ((X + Y) Mod 4 = 0) Or ((X - Y + 800) Mod 4 = 0) Then Pix(X, Y, C_NET);
    Pix(X, Top + 7, C_NET2);
  End;
End;

Procedure AddPt(X, Y, VX, VY, L, K : LongInt);
Begin
  If NPt >= MaxPt Then Exit;
  PtX[NPt] := X; PtY[NPt] := Y; PtVX[NPt] := VX; PtVY[NPt] := VY; PtL[NPt] := L; PtK[NPt] := K;
  Inc(NPt);
End;

Procedure MovePts;
Var I : LongInt;
Begin
  I := 0;
  While I < NPt Do
  Begin
    Case PtK[I] Of
      P_SMOKE : Begin PtVX[I] := PtVX[I] * 9 Div 10; PtVY[I] := PtVY[I] * 9 Div 10 - 300; End;
      P_CONF : PtVY[I] := MinI(PtVY[I] + 400, 3000);
      P_DUST : PtVY[I] := PtVY[I] + 600;
    End;
    PtX[I] := PtX[I] + PtVX[I] Div 25; PtY[I] := PtY[I] + PtVY[I] Div 25;
    Dec(PtL[I]);
    If (PtL[I] <= 0) Or (PtX[I] < 0) Or (PtX[I] >= BW * 1000) Or (PtY[I] >= FloorY * 1000 + 4000) Then
    Begin
      Dec(NPt);
      PtX[I] := PtX[NPt]; PtY[I] := PtY[NPt]; PtVX[I] := PtVX[NPt]; PtVY[I] := PtVY[NPt];
      PtL[I] := PtL[NPt]; PtK[I] := PtK[NPt];
    End
    Else Inc(I);
  End;
End;

Procedure DrawPts;
Var I, X, Y, R : LongInt;
Begin
  For I := 0 To NPt - 1 Do
  Begin
    X := PtX[I] Div 1000; Y := PtY[I] Div 1000;
    Case PtK[I] Of
      P_SMOKE :
        Begin
          R := MinI(7, 2 + (30 - PtL[I]) Div 4);
          Disc(X, Y, R, C_SMOKE + MinI(3, (30 - PtL[I]) Div 8));
        End;
      P_CONF : Rect(X, Y, X + (I And 1), Y + 1 - (I And 1), C_FLAG + I Mod 4);
      P_DUST : Pix(X, Y, C_FLOOR + 6 - (I Mod 3));
    End;
  End;
End;

Procedure PtBox(Var X1, Y1, X2, Y2 : LongInt);
Var I, X, Y : LongInt;
Begin
  X1 := 1; Y1 := 1; X2 := 0; Y2 := 0;
  For I := 0 To NPt - 1 Do
  Begin
    X := PtX[I] Div 1000; Y := PtY[I] Div 1000;
    If X2 < X1 Then
    Begin
      X1 := X - 8; Y1 := Y - 8; X2 := X + 8; Y2 := Y + 8;
    End
    Else
    Begin
      X1 := MinI(X1, X - 8); Y1 := MinI(Y1, Y - 8); X2 := MaxI(X2, X + 8); Y2 := MaxI(Y2, Y + 8);
    End;
  End;
End;

{ ==================================================================== }
{ Mise a jour de l'image : chaque objet a sa boite ; on remet le decor
  sous l'ancienne et la nouvelle boite des objets qui changent, puis on
  redessine les objets touches, du fond vers l'avant                    }
{ ==================================================================== }

Const
  NObj = 5;                                  { canon, filet, artiste, particules, repere }

Var
  OBX1, OBY1, OBX2, OBY2, NBX1, NBY1, NBX2, NBY2, ODirty : Array[0..NObj - 1] Of LongInt;
  RgX1, RgY1, RgX2, RgY2 : Array[0..NObj - 1] Of LongInt;
  NRg : LongInt;
  TLx1, TLy1, TLx2, TLy2 : Array[0..15] Of LongInt;
  NTL : LongInt;

Procedure Touch(X1, Y1, X2, Y2 : LongInt);
Begin
  X1 := MaxI(0, X1); Y1 := MaxI(0, Y1); X2 := MinI(BW - 1, X2); Y2 := MinI(BH - 1, Y2);
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  If NTL >= 16 Then
  Begin
    TLx1[15] := MinI(TLx1[15], X1); TLy1[15] := MinI(TLy1[15], Y1);
    TLx2[15] := MaxI(TLx2[15], X2); TLy2[15] := MaxI(TLy2[15], Y2);
    Exit;
  End;
  TLx1[NTL] := X1; TLy1[NTL] := Y1; TLx2[NTL] := X2; TLy2[NTL] := Y2;
  Inc(NTL);
End;

Function ManVisible : Boolean;
Begin
  ManVisible := (State = S_FLY) Or (State = S_CAUGHT) Or (State = S_MISS) Or ((State = S_OVER) And (LieMode <> 0));
End;

Procedure ObjBoxes;
Var X, Y : LongInt;
Begin
  NBX1[0] := CanX - 22; NBY1[0] := CanY - 78; NBX2[0] := CanX + 78; NBY2[0] := CanY + 22;
  NBX1[1] := NetX - NetW Div 2 - 10; NBY1[1] := NetY - 9; NBX2[1] := NetX + NetW Div 2 + 10; NBY2[1] := 373;
  If ManVisible Then
  Begin
    If State = S_FLY Then Begin X := HXm Div 1000; Y := HYm Div 1000; End Else Begin X := LieX; Y := LieY; End;
    NBX1[2] := X - 19; NBY1[2] := Y - 19; NBX2[2] := X + 19; NBY2[2] := Y + 19;
  End
  Else
  Begin
    NBX1[2] := 1; NBX2[2] := 0;
  End;
  PtBox(NBX1[3], NBY1[3], NBX2[3], NBY2[3]);
  If (HintOn <> 0) And (State = S_FLY) And (PredX > 0) And (PredX < BW) Then
  Begin
    NBX1[4] := PredX - 5; NBY1[4] := 374; NBX2[4] := PredX + 5; NBY2[4] := 381;
  End
  Else
  Begin
    NBX1[4] := 1; NBX2[4] := 0;
  End;
End;

Function Hit(A1, B1, A2, B2, X1, Y1, X2, Y2 : LongInt) : Boolean;
Begin
  Hit := (A2 >= A1) And (X2 >= X1) And (A1 <= X2) And (X1 <= A2) And (B1 <= Y2) And (Y1 <= B2);
End;

Function RgHit(X1, Y1, X2, Y2 : LongInt) : Boolean;
Var K : LongInt; R : Boolean;
Begin
  R := False;
  For K := 0 To NRg - 1 Do
    If Hit(RgX1[K], RgY1[K], RgX2[K], RgY2[K], X1, Y1, X2, Y2) Then R := True;
  RgHit := R;
End;

Procedure DrawBanner;
Var W, X1, Y1, X2, Y2 : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(MaxI(Length(Banner) * 16, Length(Banner2) * 8), Length(Banner3) * 8) + 40;
  W := MaxI(W, 280);
  X1 := (BW - W) Div 2; X2 := X1 + W - 1; Y1 := 112; Y2 := 212;
  Rect(X1 + 5, Y1 + 5, X2 + 5, Y2 + 5, C_SHADOW);
  Rect(X1, Y1, X2, Y2, C_BANNER);
  Rect(X1, Y1, X2, Y1 + 1, C_BANNERE); Rect(X1, Y2 - 1, X2, Y2, C_BANNERE);
  Rect(X1, Y1, X1 + 1, Y2, C_BANNERE); Rect(X2 - 1, Y1, X2, Y2, C_BANNERE);
  Rect(X1 + 4, Y1 + 4, X2 - 4, Y1 + 4, C_GOLD); Rect(X1 + 4, Y2 - 4, X2 - 4, Y2 - 4, C_GOLD);
  FbText((BW - Length(Banner) * 16) Div 2, Y1 + 14, Banner, BannerC, 2);
  FbText((BW - Length(Banner2) * 8) Div 2, Y1 + 54, Banner2, C_WHITE, 1);
  FbText((BW - Length(Banner3) * 8) Div 2, Y1 + 76, Banner3, C_GREENT, 1);
  Touch(X1, Y1, X2 + 5, Y2 + 5);
End;

Procedure DrawObj(K : LongInt);
Var X, Y : LongInt;
Begin
  Case K Of
    0 : DrawCannon;
    1 : DrawNet;
    2 :
      If State = S_FLY Then
      Begin
        X := HVX Div 100; Y := HVY Div 100;
        Y := MaxI(1, Round(Sqrt(X * X + Y * Y + 0.0)));
        DrawMan(HXm Div 1000, HYm Div 1000, HVX Div 100 * 1024 Div Y, HVY Div 100 * 1024 Div Y);
      End
      Else
      Begin
        If LieMode = 2 Then DrawMan(LieX, LieY, -1024, 0) Else DrawMan(LieX, LieY, 1024, 0);
        If State = S_MISS Then
        Begin
          If LieMode = 2 Then DrawStars(LieX - 6, LieY) Else DrawStars(LieX + 6, LieY);
        End;
      End;
    3 : DrawPts;
    4 :
      For Y := 0 To 6 Do Rect(PredX - (6 - Y) * 2 Div 3, 374 + Y, PredX + (6 - Y) * 2 Div 3, 374 + Y, C_YELLOW);
  End;
End;

Procedure RenderDyn;
Var K, X1, Y1, X2, Y2 : LongInt;
Begin
  ObjBoxes;
  NRg := 0;
  For K := 0 To NObj - 1 Do
  Begin
    If (NBX1[K] <> OBX1[K]) Or (NBY1[K] <> OBY1[K]) Or (NBX2[K] <> OBX2[K]) Or (NBY2[K] <> OBY2[K]) Or
       (ODirty[K] <> 0) Then
    Begin
      X1 := NBX1[K]; Y1 := NBY1[K]; X2 := NBX2[K]; Y2 := NBY2[K];
      If OBX2[K] >= OBX1[K] Then
      Begin
        If X2 < X1 Then
        Begin
          X1 := OBX1[K]; Y1 := OBY1[K]; X2 := OBX2[K]; Y2 := OBY2[K];
        End
        Else
        Begin
          X1 := MinI(X1, OBX1[K]); Y1 := MinI(Y1, OBY1[K]); X2 := MaxI(X2, OBX2[K]); Y2 := MaxI(Y2, OBY2[K]);
        End;
      End;
      If X2 >= X1 Then
      Begin
        RgX1[NRg] := MaxI(0, X1); RgY1[NRg] := MaxI(0, Y1); RgX2[NRg] := MinI(BW - 1, X2);
        RgY2[NRg] := MinI(BH - 1, Y2);
        Restore(RgX1[NRg], RgY1[NRg], RgX2[NRg], RgY2[NRg]);
        Touch(RgX1[NRg], RgY1[NRg], RgX2[NRg], RgY2[NRg]);
        Inc(NRg);
      End;
    End;
    OBX1[K] := NBX1[K]; OBY1[K] := NBY1[K]; OBX2[K] := NBX2[K]; OBY2[K] := NBY2[K]; ODirty[K] := 0;
  End;
  If NRg = 0 Then Exit;
  For K := 0 To NObj - 1 Do
    If (NBX2[K] >= NBX1[K]) And RgHit(NBX1[K], NBY1[K], NBX2[K], NBY2[K]) Then DrawObj(K);
  If (Banner <> '') And RgHit(0, 112, BW - 1, 217) Then DrawBanner;
End;

Procedure RenderAll;
Var K : LongInt;
Begin
  If BackOk = 0 Then RenderBack;
  Move(Back, Fb, SizeOf(Fb));
  ObjBoxes;
  For K := 0 To NObj - 1 Do
  Begin
    If NBX2[K] >= NBX1[K] Then DrawObj(K);
    OBX1[K] := NBX1[K]; OBY1[K] := NBY1[K]; OBX2[K] := NBX2[K]; OBY2[K] := NBY2[K]; ODirty[K] := 0;
  End;
  DrawBanner;
  NTL := 0;
  Touch(0, 0, BW - 1, BH - 1);
End;

{ point de trainee : dans le decor jusqu'au tir suivant }
Procedure TrailDot(X, Y : LongInt);
Begin
  If (X < 1) Or (X >= BW - 1) Or (Y < 1) Or (Y >= BH - 1) Or (TestMode <> 0) Then Exit;
  Back[(BH - 1 - Y) * BW + X] := C_TRAIL;
  Back[(BH - 1 - Y) * BW + X + 1] := C_TRAIL2;
  Back[(BH - Y) * BW + X] := C_TRAIL2;
  Restore(X, Y - 1, X + 1, Y);
  Touch(X, Y - 1, X + 1, Y);
  ODirty[2] := 1;
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

{ ==================================================================== }
{ Panneau                                                               }
{ ==================================================================== }

Function Sig : LongInt;
Begin
  Sig := Score * 7 + Best * 3;
End;

Procedure DrawCounters;
Var S : String;
Begin
  FBar(PnX + 2, 66, PnX + PW - 3, 100, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 67, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 242, PnX + PW - 1, 258, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 242, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

{ ligne du panneau (redessinee seulement si elle change) }
Procedure PanLine(I, Y : LongInt; L, V : String; C : LongInt);
Var S : String;
Begin
  S := L + PadL(V, 20 - Length(L));
  If S = PanS[I] Then Exit;
  PanS[I] := S;
  OutTxt(PnX, Y, S, C, CLR_PALEGRAY);
End;

Function WindTxt : String;
Var S : String;
Begin
  If Wind = 0 Then S := 'nul'
  Else If Wind > 0 Then S := 'droite ' + IStr(Wind Div 700)
  Else S := 'gauche ' + IStr(-Wind Div 700);
  WindTxt := S;
End;

Procedure DrawInfo(Force : Boolean);
Var K : LongInt;
Begin
  If Force Then
    For K := 0 To 7 Do PanS[K] := '';
  PanLine(0, 108, 'Artiste', IStr(MinI(Artist, Shows)) + ' / ' + IStr(Shows), CLR_DARKBLUE);
  PanLine(1, 126, 'Sauv' + Chr(130) + 's', IStr(Saved), CLR_DARKGREEN);
  PanLine(2, 144, 'Tomb' + Chr(130) + 's', IStr(Fell), CLR_DARKRED);
  PanLine(3, 166, 'Angle', IStr(Angle) + Chr(248), CLR_BLACK);
  PanLine(4, 184, 'Puissance', IStr(Power), CLR_BLACK);
  PanLine(5, 202, 'Vent', WindTxt, CLR_BLACK);
  PanLine(6, 220, 'S' + Chr(130) + 'rie', IStr(Streak), CLR_BLACK);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 10 * 16) Div 2, 6, 'Cannonball', CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX, 44, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 62, PnX + PW - 1, 104, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 63, PnX + PW - 2, 103, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 64, PnX + PW - 3, 102, CLR_WHITE);
  DrawCounters;
  DrawInfo(True);
  Button(PnX, 262, PW, 26, 'Feu !');
  Button(PnX, 292, PW, 26, 'Nouveau spectacle');
  OutTxt(PnX, 326, 'Gauche, droite :', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 342, '  angle, puis filet', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 358, 'Haut/bas : puissance', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 374, 'Espace : feu', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 390, 'F1 : r' + Chr(138) + 'gles du jeu', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure BlitAll(H : LongInt);
Var K : LongInt;
Begin
  For K := 0 To NTL - 1 Do BlitRect(H, TLx1[K], TLy1[K], TLx2[K], TLy2[K]);
  NTL := 0;
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
  BlitAll(Hps);
  FullBlit := 0;
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
    FullBlit := 0;
  End
  Else RenderDyn;
  BlitAll(Hps);
  If Sig <> LastSig Then
  Begin
    LastSig := Sig;
    DrawCounters;
  End;
  DrawInfo(False);
  If Msg <> LastMsg Then
  Begin
    LastMsg := Msg;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

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

{ son continu (moteur) : rejoue seulement quand le precedent est fini }
Procedure PlayLoop(N : LongInt);
Var T : LongInt;
Begin
  If (SoundOn = 0) Or (TestMode <> 0) Then Exit;
  T := SndNow;
  If (T < SndEnd - 20) And (T >= SndEnd - 60000) Then Exit;
  PlaySnd(N);
End;

Var
  QSnd, QSndT : LongInt;                     { bruitage differe }

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 3; MakeNoise(0, 380, 115, 9);               { coup de canon }
  SndPrio := 0; MakeTone(1, 1500, 1500, 14, 14);         { cran de reglage }
  SndPrio := 2; MakeTone(2, 260, 720, 260, 40);          { rebond dans le filet }
  SndPrio := 2; MakeNoise(3, 240, 95, 6);                { chute dans la sciure }
  SndPrio := 1; MakeNoise(4, 1300, 40, 1);               { applaudissements }
  SndPrio := 1; MakeTone(5, 430, 250, 480, 30);          { oh ! du public }
  SndPrio := 3; MakeTone(6, 523, 1568, 800, 40);         { fanfare }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure SetDiff;
Begin
  Case Diff Of
    0 : NetW := 76;
    2 : NetW := 46;
  Else
    NetW := 60;
  End;
End;

Procedure Show(B1, B2, B3 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; Banner3 := B3; BannerC := C;
  FullBlit := 1;
End;

{ position au temps T (ms) : X = X0 + Vx T + Vent T2 / 2 ; Y = Y0 + Vy T + g T2 / 2 }
Procedure PosAt(T : LongInt; Var X, Y : LongInt);
Begin
  X := X0m + VX0 * T Div 1000 + ((Wind * T) Div 1000) * T Div 2000;
  Y := Y0m + VY0 * T Div 1000 + ((Grav * T) Div 1000) * T Div 2000;
End;

Procedure Aim0(A, P : LongInt);
Var Ca, Sa : LongInt;
Begin
  Ca := CosD(A); Sa := SinD(A);
  X0m := (CanX * 1024 + BarL * Ca) * 1000 Div 1024;
  Y0m := (CanY * 1024 - BarL * Sa) * 1000 Div 1024;
  VX0 := P * Ca * 1000 Div 1024;
  VY0 := -P * Sa * 1000 Div 1024;
End;

{ abscisse ou l'artiste traverse le niveau du filet en descendant
  (9999 : il touche d'abord les gradins) }
Function Predict : LongInt;
Var T, X, Y, R, Ta : LongInt;
Begin
  R := 9999; T := 0;
  Ta := -VY0 * 1000 Div Grav;
  While T < 40000 Do
  Begin
    PosAt(T, X, Y);
    If X >= Wall * 1000 Then T := 99999
    Else If (T > Ta) And (Y >= NetY * 1000) Then
    Begin
      R := X Div 1000;
      T := 99999;
    End;
    T := T + 10;
  End;
  Predict := R;
End;

Procedure AimMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration (Options) : l''ordinateur vise et d' + Chr(130) +
                              'place le filet.'
  Else Msg := 'Artiste ' + IStr(Artist) + ' : visez (fl' + Chr(138) + 'ches ou souris) puis Espace pour le tir.';
End;

Procedure NewShot;
Var Tries : LongInt;
Begin
  Angle := 40 + Rnd(20);
  NetX := 300; Sag := 0; NPt := 0; LieMode := 0; PredX := 0;
  HoldL := 0; HoldR := 0; PulL := 0; PulR := 0; MouseOn := 0; AutoDelay := 0; QSnd := -1;
  Wind := 0;
  If (WindOn <> 0) And (Artist >= 3) Then Wind := (Rnd(9) - 4) * 700;
  If AutoAll <> 0 Then
  Begin
    { l'ordinateur choisit un tir qui retombe dans la portee du filet }
    Tries := 0;
    Repeat
      Angle := 25 + Rnd(51); Power := 42 + Rnd(17);
      Aim0(Angle, Power);
      PredX := Predict;
      Inc(Tries);
    Until ((PredX >= NetMin + 10) And (PredX <= NetMax - 10)) Or (Tries > 40);
    PredX := 0;
  End;
  State := S_AIM; Wait := 0;
  BackOk := 0; Banner := ''; FullBlit := 1;
  AimMsg;
End;

Procedure NewGame;
Begin
  Score := 0; Saved := 0; Fell := 0; Streak := 0; Artist := 1; Power := 50;
  NewShot;
End;

Procedure Fire;
Var K, Ca, Sa : LongInt;
Begin
  If State <> S_AIM Then Exit;
  Aim0(Angle, Power);
  FlyT := 0; HXm := X0m; HYm := Y0m; HVX := VX0; HVY := VY0;
  PredX := Predict;
  State := S_FLY; Wait := 0; TrailN := 0; AutoDelay := 0;
  Ca := CosD(Angle); Sa := SinD(Angle);
  If TestMode = 0 Then
    For K := 0 To 17 Do
      AddPt(X0m + Rnd(6000) - 3000, Y0m + Rnd(6000) - 3000, (Ca * (10 + Rnd(30)) + (Rnd(21) - 10) * 400) * 1000 Div 1024 Div 10,
            (-Sa * (10 + Rnd(30)) + (Rnd(21) - 10) * 400) * 1000 Div 1024 Div 10, 18 + Rnd(12), P_SMOKE);
  ODirty[0] := 1;
  PlaySnd(0);
  If AutoAll <> 0 Then Msg := 'Feu ! Le filet se place sous l''artiste.'
  Else Msg := 'Feu ! Gauche et droite (ou la souris) : placez le filet sous l''artiste !';
End;

Procedure Caught(Dx : LongInt);
Var Pts, C, D, Wb, K : LongInt;
Begin
  Inc(Saved); Inc(Streak);
  C := MaxI(0, 50 - AbsI(Dx) * 50 Div MaxI(1, NetW Div 2));
  D := MaxI(0, (HXm Div 1000 - 150) Div 3);
  Wb := AbsI(Wind) Div 100;
  Pts := 100 + C + D + Wb + 25 * (Streak - 1);
  LastPts := Pts;
  Score := Score + Pts;
  If (Score > Best) And (AutoAll = 0) Then Best := Score;
  LieX := Clamp(HXm Div 1000, NetX - NetW Div 2 + 8, NetX + NetW Div 2 - 8); LieY := NetY - 4;
  If HVX >= 0 Then LieMode := 1 Else LieMode := 2;
  Bounce := 0; Sag := 10;
  State := S_CAUGHT; Wait := 0;
  If TestMode = 0 Then
    For K := 0 To 49 Do AddPt((LieX + Rnd(80) - 40) * 1000, (40 + Rnd(60)) * 1000, Rnd(2001) - 1000, Rnd(2000), 60 + Rnd(40),
                              P_CONF);
  If C >= 40 Then Show('En plein centre !', 'Artiste rattrap' + Chr(130) + ' : +' + IStr(Pts) + ' points',
                        'Entr' + Chr(130) + 'e ou clic : artiste suivant', C_YELLOW)
  Else Show('Bravo !', 'Artiste rattrap' + Chr(130) + ' : +' + IStr(Pts) + ' points',
            'Entr' + Chr(130) + 'e ou clic : artiste suivant', C_YELLOW);
  If Artist >= Shows Then Banner3 := 'Entr' + Chr(130) + 'e ou clic : fin du spectacle';
  Msg := 'L''artiste ' + IStr(Artist) + ' est rattrap' + Chr(130) + ' par le filet (' + IStr(LastPts) + ' points).';
  PlaySnd(2);
  QSnd := 4; QSndT := 6;
End;

Procedure Missed(Why : String);
Var K : LongInt;
Begin
  Inc(Fell); Streak := 0; LastPts := 0;
  LieX := Clamp(HXm Div 1000, 24, Wall - 16); LieY := FloorY - 4;
  If HVX >= 0 Then LieMode := 1 Else LieMode := 2;
  State := S_MISS; Wait := 0;
  If TestMode = 0 Then
    For K := 0 To 23 Do AddPt((LieX + Rnd(24) - 12) * 1000, (FloorY - 1) * 1000, Rnd(16001) - 8000, -6000 - Rnd(12000),
                              12 + Rnd(10), P_DUST);
  Show('Rat' + Chr(130) + ' !', Why, 'Entr' + Chr(130) + 'e ou clic : artiste suivant', C_REDT);
  If Artist >= Shows Then Banner3 := 'Entr' + Chr(130) + 'e ou clic : fin du spectacle';
  Msg := 'D' + Chr(130) + 'sol' + Chr(130) + ', l''artiste ' + IStr(Artist) + ' est tomb' + Chr(130) +
         ' dans la sciure (il n''a rien de cass' + Chr(130) + ').';
  PlaySnd(3);
  QSnd := 5; QSndT := 5;
End;

Procedure GameOver;
Var S : String;
Begin
  State := S_OVER; Wait := 0;
  If Saved = Shows Then S := 'Ovation ! Les ' + IStr(Shows) + ' artistes sont sauv' + Chr(130) + 's.'
  Else If Saved >= 8 Then S := 'Le public applaudit : ' + IStr(Saved) + ' artistes sauv' + Chr(130) + 's.'
  Else If Saved >= 5 Then S := 'Pas mal : ' + IStr(Saved) + ' artistes sauv' + Chr(130) + 's.'
  Else S := 'Le public siffle : ' + IStr(Saved) + ' artistes sauv' + Chr(130) + 's.';
  Show('Fin du spectacle', S + '  ' + IStr(Score) + ' points', 'Entr' + Chr(130) + 'e ou F2 : nouveau spectacle',
       C_YELLOW);
  Msg := 'Spectacle termin' + Chr(130) + ' : ' + IStr(Saved) + ' sauv' + Chr(130) + 's, ' + IStr(Fell) + ' tomb' +
         Chr(130) + 's, ' + IStr(Score) + ' points.';
  If Saved >= 8 Then PlaySnd(6) Else PlaySnd(5);
End;

Procedure Continue0;
Begin
  Case State Of
    S_AIM : Fire;
    S_CAUGHT, S_MISS :
      If Artist >= Shows Then GameOver
      Else
      Begin
        Inc(Artist);
        NewShot;
      End;
    S_OVER : NewGame;
  End;
End;

Procedure SetAim(A, P : LongInt);
Begin
  A := Clamp(A, 10, 80); P := Clamp(P, 40, 60);
  If (A <> Angle) Or (P <> Power) Then
  Begin
    Angle := A; Power := P;
    ODirty[0] := 1;
  End;
End;

{ une image (40 ms) }
Procedure Step;
Var Px, Py, D, Dx, Mx : LongInt;
Begin
  If QSnd >= 0 Then
  Begin
    Dec(QSndT);
    If QSndT <= 0 Then
    Begin
      PlaySnd(QSnd);
      QSnd := -1;
    End;
  End;
  Case State Of
    S_FLY :
      Begin
        Px := HXm; Py := HYm;
        FlyT := FlyT + DtMs;
        PosAt(FlyT, HXm, HYm);
        HVX := VX0 + Wind * FlyT Div 1000; HVY := VY0 + Grav * FlyT Div 1000;
        { le filet }
        D := 0;
        If AutoAll <> 0 Then
        Begin
          Inc(AutoDelay);
          If (AutoDelay > 8) And (PredX < 9999) Then D := Clamp(PredX - NetX, -6, 6);
        End
        Else
        Begin
          If (HoldL > 0) Or (PulL > 0) Then D := D - 6;
          If (HoldR > 0) Or (PulR > 0) Then D := D + 6;
          If (D = 0) And (MouseOn <> 0) Then D := Clamp(MouseX - NetX, -8, 8);
        End;
        If HoldL > 0 Then Dec(HoldL);
        If HoldR > 0 Then Dec(HoldR);
        If PulL > 0 Then Dec(PulL);
        If PulR > 0 Then Dec(PulR);
        NetX := Clamp(NetX + D, NetMin, NetMax);
        { trainee }
        Inc(TrailN);
        If TrailN Mod 2 = 0 Then TrailDot(Px Div 1000, Py Div 1000);
        { gradins, filet, sciure }
        If HXm >= Wall * 1000 Then
        Begin
          HXm := (Wall - 2) * 1000;
          Missed('Il a manqu' + Chr(130) + ' la piste et rebondi sur la balustrade');
        End
        Else If (Py < NetY * 1000) And (HYm >= NetY * 1000) And (HVY > 0) Then
        Begin
          Dx := HXm Div 1000 - NetX;
          If AbsI(Dx) <= NetW Div 2 Then Caught(Dx)
          Else
          Begin
            Mx := AbsI(Dx) - NetW Div 2;
            Msg := 'A c' + Chr(147) + 't' + Chr(130) + ' du filet, de ' + IStr(Mx) + ' pixels...';
          End;
        End
        Else If HYm >= (FloorY - 4) * 1000 Then
        Begin
          Dx := AbsI(HXm Div 1000 - NetX) - NetW Div 2;
          Missed('Le filet ' + Chr(130) + 'tait trop loin (' + IStr(MaxI(1, Dx)) + ' pixels)');
        End;
      End;
    S_CAUGHT :
      Begin
        If Bounce < 48 Then
        Begin
          Inc(Bounce);
          D := MaxI(0, 14 - Bounce * 14 Div 40) * AbsI(SinD(Bounce * 24)) Div 1024;
          Sag := 2 + MaxI(0, 10 - Bounce Div 4) * (1024 - AbsI(SinD(Bounce * 24))) Div 1024;
          LieY := NetY - 4 + Sag - D;
          ODirty[1] := 1; ODirty[2] := 1;
        End;
        Inc(Wait);
      End;
    S_MISS :
      Begin
        ODirty[2] := 1;
        Inc(Wait);
      End;
    S_OVER : Inc(Wait);
  End;
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  Step;
  MovePts;
  If State = S_AIM Then Inc(Wait);
  If AutoAll <> 0 Then
  Begin
    If (State = S_AIM) And (Wait > 30) Then Fire
    Else If ((State = S_CAUGHT) Or (State = S_MISS)) And (Wait > 70) Then Continue0
    Else If (State = S_OVER) And (Wait > 150) Then NewGame;
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
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0); SetMark(CM_WIND, WindOn <> 0);
  SetMark(CM_HINT, HintOn <> 0);
  SetMark(CM_EASY, Diff = 0); SetMark(CM_NORMAL, Diff = 1); SetMark(CM_HARD, Diff = 2);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_FIRE : If State = S_AIM Then Fire;
    CM_NEXT : If State <> S_AIM Then If State <> S_FLY Then Continue0;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; AutoDelay := 0; If State = S_AIM Then NewShot; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_WIND : Begin WindOn := 1 - WindOn; SetMarks; If (WindOn = 0) And (State = S_AIM) Then Begin Wind := 0; BackOk := 0; FullBlit := 1; End; End;
    CM_HINT : Begin HintOn := 1 - HintOn; SetMarks; End;
    CM_EASY, CM_NORMAL, CM_HARD :
      Begin
        Diff := Id - CM_EASY; SetDiff; SetMarks;
        NewGame;
      End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Le canon du cirque projette un artiste vers le filet. Avant le tir, r' + Chr(130) + 'glez l''angle ' +
             '(10 ' + Chr(133) + ' 80 degr' + Chr(130) + 's) et la puissance (40 ' + Chr(133) + ' 60), puis feu ! ' +
             'Pendant le vol, d' + Chr(130) + 'placez le filet sur son chariot pour rattraper l''artiste. S''il ' +
             'manque le filet, il tombe dans la sciure (sans mal, mais le public n''aime pas).' + Chr(10) + Chr(10));
        LAdd('Un spectacle compte ' + IStr(Shows) + ' artistes. Un artiste sauv' + Chr(130) + ' rapporte 100 ' +
             'points, plus 50 au plus pour la pr' + Chr(130) + 'cision (au centre du filet), plus la distance ' +
             '(plus il va loin, plus il rapporte), plus le vent, plus 25 par artiste de la s' + Chr(130) + 'rie. ' +
             'A partir du 3e artiste, des courants d''air (fanion en haut ' + Chr(133) + ' droite) d' + Chr(130) +
             'vient le vol.' + Chr(10) + Chr(10));
        LAdd('Clavier : avant le tir, fl' + Chr(138) + 'ches gauche et droite (lever ou baisser le canon), haut ' +
             'et bas (puissance), Espace (feu) ; en vol, gauche et droite (filet) ; Entr' + Chr(130) + 'e ' +
             '(artiste suivant), F2 (nouveau spectacle). Souris : le pointeur r' + Chr(138) + 'gle l''angle et la ' +
             'puissance, clic : feu ; en vol, le filet suit le pointeur. Options : vent, point de chute pr' +
             Chr(130) + 'vu, largeur du filet (difficult' + Chr(130) + ').');
        Dummy := LMsgBox('Cannonball - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Cannonball pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype CANNONBA.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    If (Fl And KC_VIRTUALKEY) <> 0 Then
    Begin
      If Vk = VK_LEFT Then HoldL := 0;
      If Vk = VK_RIGHT Then HoldR := 0;
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
    If (Vk = VK_LEFT) Or (Vk = VK_RIGHT) Or (Vk = VK_UP) Or (Vk = VK_DOWN) Then
    Begin
      If AutoAll <> 0 Then Exit;
      If State = S_AIM Then
      Begin
        Case Vk Of
          VK_LEFT : SetAim(Angle + 1, Power);
          VK_RIGHT : SetAim(Angle - 1, Power);
          VK_UP : SetAim(Angle, Power + 1);
          VK_DOWN : SetAim(Angle, Power - 1);
        End;
        PlaySnd(1);
      End
      Else If State = S_FLY Then
      Begin
        MouseOn := 0;
        If Vk = VK_LEFT Then Begin HoldL := 14; PulL := 2; End;
        If Vk = VK_RIGHT Then Begin HoldR := 14; PulR := 2; End;
      End;
      Frame1;
      Exit;
    End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      If State <> S_FLY Then Continue0;
      Frame1;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      ' ' : Begin If State <> S_FLY Then Continue0; Frame1; End;
      'N' : Begin NewGame; Frame1; End;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

{ pointeur : angle et puissance avant le tir, filet en vol }
Procedure MouseAt(Mx, My : LongInt);
Var X, Y, Dx, Dy, A, D : LongInt;
Begin
  X := Mx - OX; Y := CH - 1 - My - OY;
  If (X < 0) Or (X >= BW) Or (Y < 0) Or (Y >= BH) Or (AutoAll <> 0) Then Exit;
  If State = S_AIM Then
  Begin
    Dx := X - CanX; Dy := CanY - Y;
    If Dx < 4 Then Exit;
    A := Round(ArcTan(Dy / Dx) * 180 / Pi);
    D := Round(Sqrt(Dx * Dx + Dy * Dy + 0.0));
    SetAim(A, 40 + (D - 80) * 20 Div 250);
  End
  Else If State = S_FLY Then
  Begin
    MouseOn := 1; MouseX := X;
  End;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 262) And (Y < 288) Then Command(CM_FIRE)
    Else If (Y >= 292) And (Y < 318) Then Command(CM_NEW);
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If AutoAll <> 0 Then Exit;
    If State = S_AIM Then
    Begin
      MouseAt(Mx, My);
      Fire;
    End
    Else If State = S_FLY Then MouseAt(Mx, My)
    Else Continue0;
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
    WM_MOUSEMOVE :
      Begin
        MouseAt(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
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

{ vol jusqu'a l'arrivee ; le filet est d'abord place en Nx }
Procedure FlyTo(Nx : LongInt);
Var N : LongInt;
Begin
  Fire;
  NetX := Nx;
  N := 0;
  While (State = S_FLY) And (N < 2000) Do
  Begin
    Step;
    Inc(N);
  End;
End;

Procedure RunTests;
Var Ok, X, Y, A, B, C, K, S1, S2, N : LongInt;
Begin
  Ok := 0;
  SoundOn := 0; Diff := 1; SetDiff; AutoAll := 0; WindOn := 1; Artist := 1;
  NewGame;
  { 1 : tir a 45 degres, puissance 50, sans vent : portee de 2500 / 9,81 }
  Wind := 0;
  Aim0(45, 50);
  PosAt(7208, X, Y);
  A := X - X0m; B := Y - Y0m;
  Log('CANNONBALL : TEST1 portee ' + IStr(A Div 1000) + ' points, ecart vertical ' + IStr(B) + ' millipoints');
  If (A Div 1000 >= 254) And (A Div 1000 <= 255) And (AbsI(B) < 1500) Then Inc(Ok);
  { 2 : reglages bornes (angle 10 a 80, puissance 40 a 60) }
  Angle := 50; Power := 50;
  For K := 1 To 40 Do SetAim(Angle + 1, Power + 1);
  A := Angle; B := Power;
  For K := 1 To 100 Do SetAim(Angle - 1, Power - 1);
  Log('CANNONBALL : TEST2 angle ' + IStr(A) + ' puis ' + IStr(Angle) + ', puissance ' + IStr(B) + ' puis ' + IStr(Power));
  If (A = 80) And (Angle = 10) And (B = 60) And (Power = 40) Then Inc(Ok);
  { 3 : filet sous le point de chute (sauve), puis trop loin (tombe) }
  Angle := 45; Power := 50; Wind := 0;
  Aim0(Angle, Power);
  X := Predict;
  FlyTo(X);
  S1 := State;
  Inc(Artist); NewShot;
  Angle := 45; Power := 50; Wind := 0;
  FlyTo(Clamp(X - NetW, NetMin, NetMax));
  S2 := State;
  Log('CANNONBALL : TEST3 chute prevue ' + IStr(X) + ' etats ' + IStr(S1) + ' ' + IStr(S2) + ' sauves ' + IStr(Saved) +
      ' tombes ' + IStr(Fell) + ' pointage ' + IStr(Score));
  If (S1 = S_CAUGHT) And (S2 = S_MISS) And (Saved = 1) And (Fell = 1) And (Score > 100) Then Inc(Ok);
  { 4 : le vent deplace le point de chute }
  Aim0(45, 50);
  Wind := -1400; A := Predict;
  Wind := 0; B := Predict;
  Wind := 1400; C := Predict;
  Log('CANNONBALL : TEST4 chute avec vent ' + IStr(A) + ' ' + IStr(B) + ' ' + IStr(C));
  If (A < B) And (B < C) Then Inc(Ok);
  { partie : un spectacle joue par l'ordinateur (graine fixe) }
  Seed := 1234; AutoAll := 1; WindOn := 1;
  NewGame;
  N := 0;
  While (State <> S_OVER) And (N < 50) Do
  Begin
    Inc(N);
    FlyTo(NetX);
    While (State = S_FLY) Do Step;
    Continue0;
  End;
  Log('CANNONBALL : PARTIE artistes ' + IStr(Saved + Fell) + ' sauves ' + IStr(Saved) + ' tombes ' + IStr(Fell) +
      ' pointage ' + IStr(Score));
  If (Saved + Fell = Shows) And (Saved >= 8) Then Inc(Ok);
  Log('CANNONBALL : ' + IStr(Ok) + '/5 essais reussis');
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
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Banner3 := ''; Best := 0; Tick := 0;
  Client := 0; Frame := 0; SoundOn := 1; SndCur := 0; SndEnd := 0; WindOn := 1; HintOn := 0; QSnd := -1;
  Score := 0; TestMode := 0; State := S_AIM; CW := CWant; CH := CHWant; Diff := 1; Artist := 1; Power := 50;
  FullBlit := 1; BackOk := 0; NPt := 0; NTL := 0; LieMode := 0;
  For K := 0 To NObj - 1 Do Begin OBX1[K] := 1; OBX2[K] := 0; ODirty[K] := 0; End;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
    If S = '/TEST' Then TestMode := 1;
  End;
  SetDiff;
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
  Dummy := WinRegisterClass(Hab, Z('CANNONBA'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('CANNONBA'), Z2('Cannonball'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouveau spectacle' + Chr(9) + 'F2');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_FIRE, '~Feu !' + Chr(9) + 'Espace');
  MItem(MIS_TEXT, 0, CM_NEXT, '~Artiste suivant' + Chr(9) + 'Entr' + Chr(130) + 'e');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MItem(MIS_TEXT, 0, CM_WIND, '~Courants d''air');
  MItem(MIS_TEXT, 0, CM_HINT, '~Point de chute pr' + Chr(130) + 'vu');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_EASY, '~Facile (grand filet)');
  MItem(MIS_TEXT, 0, CM_NORMAL, '~Normal');
  MItem(MIS_TEXT, 0, CM_HARD, 'D~ifficile (petit filet)');
  MenuClose(H3, 8);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Cannonball');
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
