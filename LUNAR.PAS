{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: LUNAR - Alunissage, pilotage d'un module lunaire pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program LUNAR;

{$R-,S-,I-}

{ Compilation : OS2PC LUNAR.PAS   (produit LUNAR.EXE)

  Portage vers OS/2-0 du prototype LUNAR.PAS du depot 7iles (Turbo
  Pascal, BGI en 320 x 200 dans une fenetre de 320 points, clavier
  seulement, menu en mode texte) : fenetre de Presentation Manager avec
  menus, image en memoire recopiee par GpiDrawBits (seules les zones qui
  bougent sont recopiees), ciel etoile avec la Terre, montagnes lointaines,
  sol lunaire en relief eclaire de cote avec ses crateres, pistes
  d'alunissage balisees, module lunaire dessine (etage de descente dore,
  etage de remontee, pieds, antenne), flamme du moteur et jets des
  propulseurs lateraux, poussiere soulevee pres du sol, explosion en
  debris qui retombent, panneau des instruments (altitude, vitesses,
  carburant), barre d'etat et apparence d'OS/2 Warp 3.

  Comme le prototype : le module tombe sous l'effet de la gravite ; les
  fleches le poussent vers le haut, le bas, la gauche et la droite et
  consomment du carburant ; il rebondit sur les bords de l'ecran et sous
  le plafond ; il faut se poser sur la piste a faible vitesse, sinon c'est
  l'explosion (BOUM, ou KA-BOUM si on arrive tres vite) ; plus on se pose
  vite, plus le pointage est eleve.
  Ce qui est corrige : la poussee dependait du nombre de touches dans le
  tampon du clavier (une touche = une impulsion, puis plus rien) ; le
  carburant baissait d'une unite par touche quelle que soit la poussee ;
  l'explosion etait dessinee par-dessus le decor sans jamais etre effacee ;
  le contact avec le sol ne regardait que la couleur de deux points sous
  les pieds (le module pouvait s'enfoncer dans une pente) ; la vitesse
  horizontale n'etait pas verifiee ; le jeu dependait de la vitesse de
  l'ordinateur (attente de 100 ms apres chaque image).
  Ce qui s'ajoute : un terrain different a chaque niveau, plusieurs pistes
  avec un multiplicateur (x1 a x5 : plus la piste est etroite, plus elle
  rapporte), trois modules (un de plus tous les 5000 points), niveaux de
  plus en plus durs (moins de carburant, derive au depart, pistes plus
  etroites), trois difficultes, pause, pilote automatique (demonstration),
  record de la seance, bruitages (moteur, propulseurs, alarme du
  carburant, contact, explosion).

  Clavier : fleche haut ou Espace (moteur principal), fleches gauche et
  droite (propulseurs lateraux), fleche bas (propulseurs vers le bas),
  P (pause), Entree (continuer), F2 (nouvelle partie), F1 (regles).
  Souris : bouton 1 maintenu sur le ciel : moteur principal, le module se
  deporte vers le pointeur ; boutons du panneau.
  Parametres : /SEED:n ; /LEVEL:n ; /AUTO (pilote automatique) ;
  /NOSOUND ; /TEST (essais du jeu sans fenetre, resultat sur le port
  serie COM1). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_PAUSE = $0D; VK_SPACE = $10;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_PAUSE = 102; CM_QUIT = 103;
  CM_AUTO = 201; CM_SOUND = 202; CM_EASY = 203; CM_NORMAL = 204; CM_HARD = 205;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : ciel et sol de 432 x 400 }
  BW = 432; BH = 400; OX = 8; OY = 8;
  PnX = 452; PW = 164;
  CWant = 624; CHWant = 436;
  { physique : positions en millipoints, vitesses en millipoints par seconde,
    un point vaut 25 cm ; une image toutes les 40 ms }
  Grav = 6480;                               { 1,62 m/s2 }
  ThrMain = 17000; ThrSide = 5000;           { moteur principal et propulseurs }
  Foot = 11;                                 { demi-ecart des pieds (points) }
  MaxPad = 4; MaxPt = 160;
  { couleurs de l'image }
  C_SKY = 0;                                 { 0..15 : ciel (haut -> horizon) }
  C_ROCK = 16;                               { 16..39 : roche (sombre -> claire) }
  C_STAR = 40;                               { 40..43 : etoiles }
  C_EARTH = 44;                              { 44..51 : oceans (nuit -> jour) }
  C_CLOUD = 52; C_LAND = 53; C_LANDD = 54; C_ATMO = 55;
  C_PAD = 56;                                { 56..59 : metal des pistes }
  C_RED = 60; C_GREEN = 61; C_REDD = 62; C_GREEND = 63;
  C_FOIL = 64;                               { 64..67 : feuille doree }
  C_HULL = 68;                               { 68..71 : coque grise }
  C_WIN = 72; C_WIN2 = 73; C_NOZ = 74; C_LEG = 75;
  C_FL = 76;                                 { 76..80 : flamme (blanc -> rouge) }
  C_WHITE = 81; C_BLACK = 82; C_YELLOW = 83; C_SHADOW = 84; C_BANNER = 85; C_BANNERE = 86;
  C_GREENT = 87; C_REDT = 88; C_CYAN = 89;
  C_DUST = 90;                               { 90..93 : poussiere }
  C_FAR = 94;                                { 94..97 : montagnes lointaines }
  { etats }
  S_READY = 1; S_FLY = 2; S_LANDED = 3; S_CRASH = 4; S_OVER = 5;
  { particules }
  P_DUST = 1; P_DEBRIS = 2; P_FIRE = 3;
  SndRate = 11025;

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { terrain : hauteur du sol (ordonnee du dessus) pour chaque colonne }
  TH, FarH : Array[0..BW - 1] Of LongInt;
  Hm : Array[0..512] Of LongInt;               { relief en construction }
  NPad : LongInt;
  PadX1, PadX2, PadY, PadM : Array[0..MaxPad - 1] Of LongInt;
  { module : position du milieu des pieds }
  LXm, LYm, VXm, VYm, Fuel, FuelCap, Visible, FlyTicks : LongInt;
  ThrU, ThrL, ThrR, ThrD : LongInt;          { poussees de l'image en cours }
  HoldU, HoldL, HoldR, HoldD, PulU, PulL, PulR, PulD : LongInt;
  MouseHeld, MouseX : LongInt;
  { pilote automatique }
  ATgt, ADesc : LongInt;
  { particules }
  PtX, PtY, PtVX, PtVY, PtL, PtK : Array[0..MaxPt - 1] Of LongInt;
  NPt : LongInt;
  { partie }
  State, PrevState, Paused, Level, Lives, Score, Best, NextBonus, Seed, LevelSeed, AutoAll, SoundOn, TestMode : LongInt;
  Diff, Wait, Tick, Blink, LastPts, Landings, Crashes, LastVY, LastVX, LastOK : LongInt;
  SafeVY, SafeVX : LongInt;
  { zones a recopier }
  DX1, DY1, DX2, DY2, OBx1, OBy1, OBx2, OBy2, FullBlit, BackOk : LongInt;
  Banner, Banner2, Banner3, Msg, LastMsg : String;
  BannerC : LongInt;
  PanS : Array[0..7] Of String[40];
  PanG, LastSig : LongInt;
  { bruitages }
  SndBuf : Array[0..29999] Of Byte;
  SndOfs, SndLen, SndPri : Array[0..15] Of LongInt;
  NSndBuf, SndPrio, SndCur, SndEnd, AlarmT : LongInt;
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
  For I := 0 To 15 Do SetPal(C_SKY + I, Mix($02030A, $0E1630, I, 15));
  For I := 0 To 23 Do SetPal(C_ROCK + I, Mix($15161A, $D8D6CE, I, 23));
  SetPal(C_STAR, $50586C); SetPal(C_STAR + 1, $8890A8); SetPal(C_STAR + 2, $C8D0E4); SetPal(C_STAR + 3, $FFFFFF);
  For I := 0 To 7 Do SetPal(C_EARTH + I, Mix($061030, $2E78D8, I, 7));
  SetPal(C_CLOUD, $F0F4FA); SetPal(C_LAND, $5C9A48); SetPal(C_LANDD, $1C3418); SetPal(C_ATMO, $8CC4FF);
  For I := 0 To 3 Do SetPal(C_PAD + I, Mix($3A3E46, $C4CAD4, I, 3));
  SetPal(C_RED, $FF3020); SetPal(C_GREEN, $40FF60); SetPal(C_REDD, $501010); SetPal(C_GREEND, $104018);
  SetPal(C_FOIL, $6A4808); SetPal(C_FOIL + 1, $A8780E); SetPal(C_FOIL + 2, $DCA82C); SetPal(C_FOIL + 3, $FFE070);
  SetPal(C_HULL, $50545C); SetPal(C_HULL + 1, $8A8E96); SetPal(C_HULL + 2, $BCC0C6); SetPal(C_HULL + 3, $E8EAEE);
  SetPal(C_WIN, $102030); SetPal(C_WIN2, $70C8FF); SetPal(C_NOZ, $3A3A40); SetPal(C_LEG, $9A9488);
  SetPal(C_FL, $FFFFF4); SetPal(C_FL + 1, $FFF0A0); SetPal(C_FL + 2, $FFC838); SetPal(C_FL + 3, $FF7A18);
  SetPal(C_FL + 4, $C02C08);
  SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $000000); SetPal(C_YELLOW, $FFD840); SetPal(C_SHADOW, $000000);
  SetPal(C_BANNER, $101830); SetPal(C_BANNERE, $8CA4E8); SetPal(C_GREENT, $70F090); SetPal(C_REDT, $FF6A50);
  SetPal(C_CYAN, $70D8FF);
  For I := 0 To 3 Do SetPal(C_DUST + I, Mix($5A5852, $D0CCC0, I, 3));
  For I := 0 To 3 Do SetPal(C_FAR + I, Mix($1C1F2A, $4A4E5C, I, 3));
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

Procedure Touch(X1, Y1, X2, Y2 : LongInt);
Begin
  If X2 < X1 Then Exit;
  If DX2 < DX1 Then
  Begin
    DX1 := X1; DY1 := Y1; DX2 := X2; DY2 := Y2;
  End
  Else
  Begin
    DX1 := MinI(DX1, X1); DY1 := MinI(DY1, Y1); DX2 := MaxI(DX2, X2); DY2 := MaxI(DY2, Y2);
  End;
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

{ ==================================================================== }
{ Terrain                                                               }
{ ==================================================================== }

{ relief par deplacement du point milieu (513 points, on garde les 432
  premiers) : Amp est l'amplitude du premier niveau }
Procedure Midpoint(H0, H1, Amp : LongInt);
Var St, I, A : LongInt;
Begin
  Hm[0] := H0; Hm[512] := H1;
  St := 512; A := Amp;
  While St > 1 Do
  Begin
    I := St Div 2;
    While I < 512 Do
    Begin
      Hm[I] := (Hm[I - St Div 2] + Hm[I + St Div 2]) Div 2 + Rnd(2 * A + 1) - A;
      I := I + St;
    End;
    St := St Div 2;
    A := A * 11 Div 20;
  End;
End;

{ pistes du niveau : multiplicateurs et largeurs }
Procedure PadSpec(L, K : LongInt; Var M, W : LongInt);
Begin
  If L <= 1 Then
  Begin
    Case K Of
      0 : Begin M := 1; W := 70; End;
      1 : Begin M := 2; W := 48; End;
    Else
      Begin M := 5; W := 34; End;
    End;
  End
  Else
  Begin
    Case K Of
      0 : Begin M := 1; W := MaxI(50, 70 - 3 * (L - 1)); End;
      1 : Begin M := 2; W := MaxI(40, 52 - 2 * (L - 1)); End;
      2 : Begin M := 3; W := MaxI(34, 42 - (L - 1)); End;
    Else
      Begin M := 5; W := MaxI(30, 34 - (L - 1) Div 2); End;
    End;
  End;
End;

Procedure GenTerrain(L : LongInt);
Var Ord0 : Array[0..MaxPad - 1] Of LongInt;
    I, K, N, H, X, A, B, M, W, Slot, Cx, T, R, D : LongInt;
Begin
  Seed := LevelSeed + L * 7919;
  { sol : relief accidente }
  Midpoint(300, 300, 90);
  A := Hm[0]; B := Hm[0];
  For X := 0 To BW - 1 Do
  Begin
    A := MinI(A, Hm[X]); B := MaxI(B, Hm[X]);
  End;
  { mise a l'echelle : du sommet (entre 222 et 270) au fond (372) }
  H := 222 + Rnd(49);
  For X := 0 To BW - 1 Do TH[X] := H + (Hm[X] - A) * (372 - H) Div MaxI(1, B - A);
  { crateres en creux dans le profil (rebord releve) }
  For K := 1 To 3 + Rnd(3) Do
  Begin
    Cx := 10 + Rnd(BW - 20); R := 8 + Rnd(16); D := R Div 3 + Rnd(4);
    For X := MaxI(0, Cx - R - 3) To MinI(BW - 1, Cx + R + 3) Do
    Begin
      T := (X - Cx) * (X - Cx);
      If T <= R * R Then TH[X] := TH[X] + D * (R * R - T) Div (R * R) - 1
      Else TH[X] := TH[X] - 2;
    End;
  End;
  { pistes : une par tranche de l'ecran, dans un ordre au hasard }
  If L <= 1 Then NPad := 3 Else NPad := 4;
  For I := 0 To NPad - 1 Do Ord0[I] := I;
  For I := NPad - 1 DownTo 1 Do
  Begin
    K := Rnd(I + 1);
    T := Ord0[I]; Ord0[I] := Ord0[K]; Ord0[K] := T;
  End;
  For Slot := 0 To NPad - 1 Do
  Begin
    PadSpec(L, Ord0[Slot], M, W);
    A := 18 + Slot * (BW - 36) Div NPad; B := 18 + (Slot + 1) * (BW - 36) Div NPad;
    Cx := A + W Div 2 + 4 + Rnd(MaxI(1, B - A - W - 8));
    PadX1[Slot] := Cx - W Div 2; PadX2[Slot] := PadX1[Slot] + W - 1;
    H := 0;
    For X := PadX1[Slot] To PadX2[Slot] Do H := H + TH[X];
    PadY[Slot] := Clamp(H Div W, 262, 366);
    PadM[Slot] := M;
  End;
  { epaulements : le sol rejoint la piste en pente douce }
  For Slot := 0 To NPad - 1 Do
  Begin
    For X := MaxI(0, PadX1[Slot] - 12) To PadX1[Slot] - 1 Do
    Begin
      D := PadX1[Slot] - X;
      TH[X] := PadY[Slot] + (TH[X] - PadY[Slot]) * D Div 12;
    End;
    For X := PadX2[Slot] + 1 To MinI(BW - 1, PadX2[Slot] + 12) Do
    Begin
      D := X - PadX2[Slot];
      TH[X] := PadY[Slot] + (TH[X] - PadY[Slot]) * D Div 12;
    End;
  End;
  For Slot := 0 To NPad - 1 Do
    For X := PadX1[Slot] To PadX2[Slot] Do TH[X] := PadY[Slot];
  For X := 0 To BW - 1 Do TH[X] := Clamp(TH[X], 200, BH - 14);
  { montagnes lointaines }
  Midpoint(200, 200, 60);
  A := Hm[0]; B := Hm[0];
  For X := 0 To BW - 1 Do
  Begin
    A := MinI(A, Hm[X]); B := MaxI(B, Hm[X]);
  End;
  H := 150 + Rnd(30);
  For X := 0 To BW - 1 Do FarH[X] := H + (Hm[X] - A) * (236 - H) Div MaxI(1, B - A);
  N := 0;
End;

Function PadAt(X : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To NPad - 1 Do
    If (X >= PadX1[I]) And (X <= PadX2[I]) Then R := I;
  PadAt := R;
End;

{ ==================================================================== }
{ Decor                                                                 }
{ ==================================================================== }

Procedure RectB(X1, Y1, X2, Y2, C : LongInt);
Var X, Y : LongInt;
Begin
  For Y := MaxI(0, Y1) To MinI(BH - 1, Y2) Do
    For X := MaxI(0, X1) To MinI(BW - 1, X2) Do Back[(BH - 1 - Y) * BW + X] := C;
End;

{ balises des pistes (rouge a gauche, verte a droite, en alternance) :
  dessinees dans le decor puis recopiees dans l'image }
Procedure Beacons(On : Boolean);
Var I, X, C1, C2 : LongInt;
Begin
  For I := 0 To NPad - 1 Do
  Begin
    If On Then Begin C1 := C_RED; C2 := C_GREEND; End Else Begin C1 := C_REDD; C2 := C_GREEN; End;
    X := PadX1[I] + 1;
    RectB(X - 1, PadY[I] - 8, X, PadY[I] - 7, C1);
    X := PadX2[I] - 1;
    RectB(X, PadY[I] - 8, X + 1, PadY[I] - 7, C2);
    Restore(PadX1[I], PadY[I] - 8, PadX1[I] + 1, PadY[I] - 7);
    Restore(PadX2[I] - 1, PadY[I] - 8, PadX2[I], PadY[I] - 7);
    Touch(PadX1[I], PadY[I] - 8, PadX2[I], PadY[I] - 7);
  End;
End;

Procedure RenderBack;
Var X, Y, D, S, Lv, Sl, N, K, Cx, Cy, A, B, R, Dx, Dy, Q, M : LongInt; L : String;
Begin
  { ciel : degrade vers l'horizon }
  For Y := 0 To BH - 1 Do Rect(0, Y, BW - 1, Y, C_SKY + MinI(15, Y * 15 Div 300));
  { etoiles (toujours les memes) }
  N := 977;
  For K := 1 To 150 Do
  Begin
    N := (N * 1103515245 + 12345) And $7FFFFFFF;
    X := (N Shr 8) Mod BW;
    N := (N * 1103515245 + 12345) And $7FFFFFFF;
    Y := (N Shr 8) Mod 250;
    N := (N * 1103515245 + 12345) And $7FFFFFFF;
    S := (N Shr 8) Mod 10;
    If S < 5 Then Pix(X, Y, C_STAR) Else If S < 8 Then Pix(X, Y, C_STAR + 1)
    Else If S < 9 Then Pix(X, Y, C_STAR + 2)
    Else
    Begin
      Pix(X, Y, C_STAR + 3); Pix(X - 1, Y, C_STAR); Pix(X + 1, Y, C_STAR); Pix(X, Y - 1, C_STAR); Pix(X, Y + 1, C_STAR);
    End;
  End;
  { la Terre : eclairee par la gauche, continents et nuages }
  Cx := BW - 62; Cy := 52; R := 21;
  For Dy := -R - 2 To R + 2 Do
    For Dx := -R - 2 To R + 2 Do
    Begin
      D := Dx * Dx + Dy * Dy;
      If D <= R * R Then
      Begin
        Lv := 7 - (Dx + R) * 9 Div (2 * R) + Dy Div 12;
        Lv := Clamp(Lv, 0, 7);
        Q := ((Dx * 7 + Dy * 13 + 400) Div 5 + (Dx * Dy + 900) Div 23) Mod 9;
        M := C_EARTH + Lv;
        If (Q < 2) And (Lv >= 2) Then M := C_LAND;
        If (Q < 2) And (Lv < 2) Then M := C_LANDD;
        If ((Dy * 3 + Dx Div 2 + 300) Mod 11 = 0) And (Lv >= 3) Then M := C_CLOUD;
        If (D >= (R - 2) * (R - 2)) And (Dx < 0) And (Lv >= 4) Then M := C_ATMO;
        Pix(Cx + Dx, Cy + Dy, M);
      End
      Else If (D <= (R + 2) * (R + 2)) And (Dx < -R Div 3) Then Pix(Cx + Dx, Cy + Dy, C_SKY + 6);
    End;
  { montagnes lointaines }
  For X := 0 To BW - 1 Do
  Begin
    Sl := FarH[MinI(BW - 1, X + 2)] - FarH[MaxI(0, X - 2)];
    For Y := FarH[X] To BH - 1 Do
    Begin
      If Y - FarH[X] < 2 Then S := Clamp(2 - Sl Div 2, 1, 3)
      Else If (Y - FarH[X] < 34) Or ((Y - FarH[X] < 52) And ((X + Y) Mod 2 = 0)) Then S := 1
      Else S := 0;
      Pix(X, Y, C_FAR + S);
    End;
  End;
  { sol : rebord eclaire selon la pente, assombri en profondeur, grain en
    taches et strates }
  For X := 0 To BW - 1 Do
  Begin
    Sl := TH[MinI(BW - 1, X + 2)] - TH[MaxI(0, X - 2)];
    Lv := Clamp(12 - Sl * 2, 3, 20);
    For Y := TH[X] To BH - 1 Do
    Begin
      D := Y - TH[X];
      N := (X Div 3) * 7919 + (Y Div 2) * 104729 + (X + Y) Div 5 * 31;
      N := (N * 1103515245 + 12345) And $7FFFFFFF;
      Q := (N Shr 16) Mod 3;
      M := 10 - D Div 14 + Q - 1;
      If D < 2 Then S := MinI(23, Lv + 3)
      Else If D < 16 Then S := (Lv * (16 - D) + M * D) Div 16
      Else S := M;
      If (D > 5) And (((Y * 3 + X Div 12) Mod 17) = 0) Then S := S - 2;
      If (D > 5) And (((Y * 3 + X Div 12) Mod 17) = 1) Then S := S + 1;
      Pix(X, Y, C_ROCK + Clamp(S, 1, 23));
    End;
  End;
  { crateres dans le sol }
  N := LevelSeed * 3 + Level * 101 + 5;
  For K := 1 To 14 Do
  Begin
    N := (N * 1103515245 + 12345) And $7FFFFFFF;
    Cx := (N Shr 8) Mod BW;
    N := (N * 1103515245 + 12345) And $7FFFFFFF;
    A := 5 + (N Shr 8) Mod 14; B := MaxI(2, A Div 3);
    N := (N * 1103515245 + 12345) And $7FFFFFFF;
    Cy := TH[Cx] + B + 6 + (N Shr 8) Mod 60;
    If (Cy + B < BH) And (PadAt(Cx) < 0) Then
      For Dy := -B To B Do
        For Dx := -A To A Do
          If Dx * Dx * B * B + Dy * Dy * A * A <= A * A * B * B Then
          Begin
            X := Cx + Dx; Y := Cy + Dy;
            If (X >= 0) And (X < BW) And (Y > TH[X] + 2) Then
            Begin
              S := GetPix(X, Y) - C_ROCK;
              If Dy < 0 Then S := S - 4 Else S := S + 2;
              If Dx * Dx * B * B + Dy * Dy * A * A >= (A - 1) * (A - 1) * B * B Then
              Begin
                If Dy < 0 Then S := S + 6 Else S := S - 3;
              End;
              Pix(X, Y, C_ROCK + Clamp(S, 1, 23));
            End;
          End;
  End;
  { pistes : plaque de metal, poteaux, balises, multiplicateur }
  For K := 0 To NPad - 1 Do
  Begin
    Y := PadY[K];
    Rect(PadX1[K], Y, PadX2[K], Y, C_PAD + 3);
    Rect(PadX1[K], Y + 1, PadX2[K], Y + 2, C_PAD + 2);
    Rect(PadX1[K], Y + 3, PadX2[K], Y + 3, C_PAD);
    For X := PadX1[K] + 3 To PadX2[K] - 3 Do
      If (X - PadX1[K]) Mod 8 < 4 Then Pix(X, Y + 1, C_YELLOW);
    Rect(PadX1[K], Y - 6, PadX1[K], Y - 1, C_PAD + 1);
    Rect(PadX2[K], Y - 6, PadX2[K], Y - 1, C_PAD + 1);
    L := 'x' + IStr(PadM[K]);
    FbTextSh((PadX1[K] + PadX2[K]) Div 2 - Length(L) * 4, Y + 7, L, C_YELLOW, 1);
  End;
  Move(Fb, Back, SizeOf(Fb));
  Beacons(Blink <> 0);
  BackOk := 1;
End;

{ ==================================================================== }
{ Module lunaire et particules                                          }
{ ==================================================================== }

Procedure DrawLander(Cx, By, Up, Lf, Rt, Dn, Fl : LongInt);
Var X, Y, I, N, W, C : LongInt;
Begin
  { flamme du moteur principal }
  If Up <> 0 Then
  Begin
    N := 8 + Fl Mod 5;
    For I := 0 To N Do
    Begin
      W := 3 - I * 3 Div N;
      For X := -W To W Do
      Begin
        If I < 2 Then C := C_FL
        Else If I < N Div 2 Then C := C_FL + 1 + AbsI(X)
        Else C := C_FL + 2 + MinI(2, AbsI(X) + (I * 2) Div N);
        Pix(Cx + X, By - 3 + I, C);
      End;
    End;
  End;
  { pieds : jambes, contrefiches, semelles }
  Line(Cx - 7, By - 9, Cx - Foot, By - 1, C_LEG);
  Line(Cx - 6, By - 7, Cx - Foot + 1, By - 4, C_HULL);
  Line(Cx + 7, By - 9, Cx + Foot, By - 1, C_LEG);
  Line(Cx + 6, By - 7, Cx + Foot - 1, By - 4, C_HULL);
  Rect(Cx - Foot - 2, By, Cx - Foot + 2, By, C_HULL + 2);
  Rect(Cx + Foot - 2, By, Cx + Foot + 2, By, C_HULL + 2);
  { tuyere }
  Rect(Cx - 3, By - 6, Cx + 3, By - 5, C_NOZ);
  Rect(Cx - 2, By - 4, Cx + 2, By - 4, C_NOZ);
  { etage de descente : feuille doree froissee }
  For Y := By - 14 To By - 7 Do
    For X := Cx - 9 To Cx + 9 Do
    Begin
      If X < Cx - 3 Then C := C_FOIL + 3 Else If X < Cx + 4 Then C := C_FOIL + 2 Else C := C_FOIL + 1;
      If Y = By - 7 Then C := C_FOIL;
      If ((X * 7 + Y * 3) Mod 5 = 0) And (C > C_FOIL) Then C := C - 1;
      Pix(X, Y, C);
    End;
  Rect(Cx - 9, By - 15, Cx + 9, By - 15, C_HULL + 1);
  { etage de remontee }
  Rect(Cx - 7, By - 22, Cx + 7, By - 16, C_HULL + 2);
  Rect(Cx - 7, By - 22, Cx + 6, By - 22, C_HULL + 3);
  Rect(Cx - 7, By - 22, Cx - 7, By - 16, C_HULL + 3);
  Rect(Cx + 7, By - 21, Cx + 7, By - 16, C_HULL);
  Rect(Cx - 6, By - 16, Cx + 7, By - 16, C_HULL + 1);
  Rect(Cx - 5, By - 21, Cx - 2, By - 19, C_WIN);
  Pix(Cx - 5, By - 21, C_WIN2); Pix(Cx - 4, By - 21, C_WIN2);
  Rect(Cx + 1, By - 20, Cx + 4, By - 18, C_HULL + 1);
  Rect(Cx - 2, By - 24, Cx + 2, By - 23, C_HULL + 1);
  Line(Cx + 5, By - 23, Cx + 8, By - 28, C_HULL + 2);
  Rect(Cx + 7, By - 29, Cx + 9, By - 29, C_HULL + 3);
  { blocs des propulseurs }
  Rect(Cx - 9, By - 20, Cx - 8, By - 18, C_NOZ);
  Rect(Cx + 8, By - 20, Cx + 9, By - 18, C_NOZ);
  { jets lateraux (fleche gauche : le jet sort a droite) }
  If Lf <> 0 Then
    For I := 0 To 3 + Fl Mod 3 Do Pix(Cx + 10 + I, By - 19, C_FL + MinI(3, I));
  If Rt <> 0 Then
    For I := 0 To 3 + Fl Mod 3 Do Pix(Cx - 10 - I, By - 19, C_FL + MinI(3, I));
  If Dn <> 0 Then
    For I := 0 To 2 + Fl Mod 3 Do
    Begin
      Pix(Cx - 9, By - 21 - I, C_FL + MinI(3, I));
      Pix(Cx + 8, By - 21 - I, C_FL + MinI(3, I));
    End;
End;

{ petit fanion plante a cote du module pose }
Procedure DrawFlag(X, Y : LongInt);
Var I : LongInt;
Begin
  Rect(X, Y - 15, X, Y, C_HULL + 3);
  For I := 0 To 5 Do Rect(X + 1, Y - 15 + I, X + 9 - I * 3 Div 2, Y - 15 + I, C_YELLOW);
  Pix(X + 2, Y - 13, C_FOIL);
End;

Procedure AddPt(X, Y, VX, VY, L, K : LongInt);
Begin
  If NPt >= MaxPt Then Exit;
  PtX[NPt] := X; PtY[NPt] := Y; PtVX[NPt] := VX; PtVY[NPt] := VY; PtL[NPt] := L; PtK[NPt] := K;
  Inc(NPt);
End;

Procedure DelPt(I : LongInt);
Begin
  Dec(NPt);
  PtX[I] := PtX[NPt]; PtY[I] := PtY[NPt]; PtVX[I] := PtVX[NPt]; PtVY[I] := PtVY[NPt];
  PtL[I] := PtL[NPt]; PtK[I] := PtK[NPt];
End;

{ deplacement des particules ; un debris qui touche le sol y reste (dans
  le decor) }
Procedure MovePts;
Var I, X, Y : LongInt;
Begin
  I := 0;
  While I < NPt Do
  Begin
    If PtK[I] = P_DUST Then PtVY[I] := PtVY[I] + Grav Div 100 Else PtVY[I] := PtVY[I] + Grav Div 25;
    PtX[I] := PtX[I] + PtVX[I] Div 25; PtY[I] := PtY[I] + PtVY[I] Div 25;
    Dec(PtL[I]);
    X := PtX[I] Div 1000; Y := PtY[I] Div 1000;
    If (X < 0) Or (X >= BW) Or (Y >= BH) Or (PtL[I] <= 0) Then DelPt(I)
    Else If (PtK[I] = P_DEBRIS) And (Y >= TH[X]) Then
    Begin
      If (BackOk <> 0) And (TestMode = 0) Then
      Begin
        Back[(BH - 1 - TH[X]) * BW + X] := C_NOZ;
        If X + 1 < BW Then Back[(BH - 1 - TH[X]) * BW + X + 1] := C_FOIL + (I And 1);
        Touch(X, TH[X], X + 1, TH[X]);
        Restore(X, TH[X], X + 1, TH[X]);
      End;
      DelPt(I);
    End
    Else Inc(I);
  End;
End;

Procedure DrawPts;
Var I, X, Y, A : LongInt;
Begin
  For I := 0 To NPt - 1 Do
  Begin
    X := PtX[I] Div 1000; Y := PtY[I] Div 1000;
    Case PtK[I] Of
      P_DUST : If PtL[I] > 8 Then Pix(X, Y, C_DUST + 2 + (I And 1)) Else Pix(X, Y, C_DUST + (I And 1));
      P_DEBRIS : Begin Rect(X, Y, X + 1, Y, C_FOIL + (I Mod 4)); Rect(X, Y + 1, X + 1, Y + 1, C_HULL + (I Mod 3)); End;
      P_FIRE :
        Begin
          A := MinI(4, (24 - PtL[I]) Div 5);
          If A < 0 Then A := 0;
          Rect(X - 1, Y - 1, X + 1, Y + 1, C_FL + A);
        End;
    End;
  End;
End;

Procedure Explode;
Var K, A, Sp : LongInt;
Begin
  For K := 0 To 59 Do
  Begin
    A := Rnd(628);
    Sp := 12000 + Rnd(40000);
    AddPt(LXm + Rnd(16000) - 8000, LYm - 10000 + Rnd(10000), Round(Cos(A / 100) * Sp), -AbsI(Round(Sin(A / 100) * Sp)) - 6000,
          150 + Rnd(100), P_DEBRIS);
  End;
  For K := 0 To 69 Do
  Begin
    A := Rnd(628);
    Sp := 6000 + Rnd(30000);
    AddPt(LXm, LYm - 9000, Round(Cos(A / 100) * Sp), Round(Sin(A / 100) * Sp) - 9000, 14 + Rnd(12), P_FIRE);
  End;
End;

{ ==================================================================== }
{ Mise a jour de l'image                                                }
{ ==================================================================== }

Procedure DrawBanner;
Var W, X1, Y1, X2, Y2 : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(MaxI(Length(Banner) * 16, Length(Banner2) * 8), Length(Banner3) * 8) + 40;
  W := MaxI(W, 280);
  X1 := (BW - W) Div 2; X2 := X1 + W - 1; Y1 := 96; Y2 := 196;
  Rect(X1 + 5, Y1 + 5, X2 + 5, Y2 + 5, C_SHADOW);
  Rect(X1, Y1, X2, Y2, C_BANNER);
  Rect(X1, Y1, X2, Y1 + 1, C_BANNERE); Rect(X1, Y2 - 1, X2, Y2, C_BANNERE);
  Rect(X1, Y1, X1 + 1, Y2, C_BANNERE); Rect(X2 - 1, Y1, X2, Y2, C_BANNERE);
  FbText((BW - Length(Banner) * 16) Div 2, Y1 + 14, Banner, BannerC, 2);
  FbText((BW - Length(Banner2) * 8) Div 2, Y1 + 54, Banner2, C_WHITE, 1);
  FbText((BW - Length(Banner3) * 8) Div 2, Y1 + 76, Banner3, C_GREENT, 1);
  Touch(X1, Y1, X2 + 5, Y2 + 5);
End;

Function BannerHit(X1, Y1, X2, Y2 : LongInt) : Boolean;
Begin
  BannerHit := (Banner <> '') And (X2 >= 0) And (X1 <= BW - 1) And (Y2 >= 96) And (Y1 <= 201);
End;

{ objets mobiles : on remet le decor sous l'ancienne et la nouvelle
  position, puis on redessine }
Procedure RenderDyn;
Var Bx1, By1, Bx2, By2, I, X, Y, Cx, By : LongInt;
Begin
  Bx1 := 1; By1 := 1; Bx2 := 0; By2 := 0;
  Cx := LXm Div 1000; By := LYm Div 1000;
  If Visible <> 0 Then
  Begin
    Bx1 := Cx - 18; By1 := By - 31; Bx2 := Cx + 18; By2 := By + 14;
    If State = S_LANDED Then Bx2 := Cx + 30;
  End;
  For I := 0 To NPt - 1 Do
  Begin
    X := PtX[I] Div 1000; Y := PtY[I] Div 1000;
    If Bx2 < Bx1 Then
    Begin
      Bx1 := X - 2; By1 := Y - 2; Bx2 := X + 2; By2 := Y + 2;
    End
    Else
    Begin
      Bx1 := MinI(Bx1, X - 2); By1 := MinI(By1, Y - 2); Bx2 := MaxI(Bx2, X + 2); By2 := MaxI(By2, Y + 2);
    End;
  End;
  { region : ancienne et nouvelle boites }
  X := Bx1; Y := By1; I := Bx2; Cx := By2;
  If OBx2 >= OBx1 Then
  Begin
    If Bx2 < Bx1 Then
    Begin
      X := OBx1; Y := OBy1; I := OBx2; Cx := OBy2;
    End
    Else
    Begin
      X := MinI(X, OBx1); Y := MinI(Y, OBy1); I := MaxI(I, OBx2); Cx := MaxI(Cx, OBy2);
    End;
  End;
  OBx1 := Bx1; OBy1 := By1; OBx2 := Bx2; OBy2 := By2;
  If I < X Then Exit;
  X := MaxI(0, X); Y := MaxI(0, Y); I := MinI(BW - 1, I); Cx := MinI(BH - 1, Cx);
  Restore(X, Y, I, Cx);
  DrawPts;
  By := LYm Div 1000;
  If Visible <> 0 Then
  Begin
    DrawLander(LXm Div 1000, By, ThrU, ThrL, ThrR, ThrD, Tick);
    If State = S_LANDED Then DrawFlag(LXm Div 1000 + 18, By);
  End;
  Touch(X, Y, I, Cx);
  If BannerHit(X, Y, I, Cx) Then DrawBanner;
End;

Procedure RenderAll;
Begin
  If BackOk = 0 Then RenderBack;
  Move(Back, Fb, SizeOf(Fb));
  OBx1 := 1; OBx2 := 0;
  RenderDyn;
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

{ ==================================================================== }
{ Panneau des instruments                                               }
{ ==================================================================== }

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ petit module (vies restantes) }
Procedure MiniLander(X, Y : LongInt);
Begin
  FBar(X + 4, Y, X + 9, Y + 4, CLR_DARKGRAY);
  FBar(X + 5, Y + 1, X + 6, Y + 2, CLR_DARKBLUE);
  FBar(X + 2, Y + 5, X + 11, Y + 8, CLR_YELLOW);
  FBar(X + 2, Y + 8, X + 11, Y + 8, CLR_BROWN);
  FBar(X + 2, Y + 9, X + 2, Y + 11, CLR_BLACK); FBar(X + 11, Y + 9, X + 11, Y + 11, CLR_BLACK);
  FBar(X, Y + 12, X + 3, Y + 12, CLR_BLACK); FBar(X + 10, Y + 12, X + 13, Y + 12, CLR_BLACK);
End;

Function Sig : LongInt;
Begin
  Sig := Score * 7 + Level * 131 + Lives * 1009 + Best * 3;
End;

Procedure DrawCounters;
Var S : String; K : LongInt;
Begin
  FBar(PnX + 2, 66, PnX + PW - 3, 100, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 67, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 108, PnX + PW - 1, 144, CLR_PALEGRAY);
  OutTxt(PnX, 108, 'Niveau : ' + IStr(Level), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 127, 'Modules', CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To MinI(5, Lives) - 1 Do MiniLander(PnX + 66 + K * 18, 128);
  FBar(PnX, 262, PnX + PW - 1, 278, CLR_PALEGRAY);
  If Best > 0 Then OutTxt(PnX, 262, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

{ ligne d'instrument (redessinee seulement si elle change) }
Procedure PanLine(I, Y : LongInt; L, V : String; C : LongInt);
Var S : String;
Begin
  S := L + PadL(V, 20 - Length(L));
  If S = PanS[I] Then Exit;
  PanS[I] := S;
  OutTxt(PnX, Y, S, C, CLR_PALEGRAY);
End;

Function AltPx : LongInt;
Var X, A, K : LongInt;
Begin
  X := Clamp(LXm Div 1000, 0, BW - 1);
  A := TH[X];
  For K := MaxI(0, X - Foot) To MinI(BW - 1, X + Foot) Do A := MinI(A, TH[K]);
  AltPx := A * 1000 - LYm;
End;

Procedure DrawInstr(Force : Boolean);
Var G, C, Vy, Vx : LongInt;
Begin
  If Force Then
  Begin
    For G := 0 To 7 Do PanS[G] := '';
    PanG := -1;
  End;
  If FuelCap > 0 Then G := Fuel * (PW - 6) Div FuelCap Else G := 0;
  G := Clamp(G, 0, PW - 6);
  PanLine(0, 150, 'Carburant', IStr((Fuel * 100 + FuelCap - 1) Div MaxI(1, FuelCap)) + ' %', CLR_BLACK);
  If G <> PanG Then
  Begin
    PanG := G;
    If Fuel * 100 < FuelCap * 15 Then C := CLR_DARKRED Else If Fuel * 100 < FuelCap * 35 Then C := CLR_YELLOW
    Else C := CLR_DARKGREEN;
    FBar(PnX + 3, 171, PnX + 2 + G, 181, C);
    FBar(PnX + 3 + G, 171, PnX + PW - 4, 181, CLR_WHITE);
  End;
  Vy := VYm Div 400; Vx := VXm Div 400;
  PanLine(1, 188, 'Altitude', Dec1(MaxI(0, AltPx) Div 400) + ' m', CLR_BLACK);
  If AbsI(VYm) <= SafeVY Then C := CLR_DARKGREEN Else C := CLR_DARKRED;
  If Vy >= 0 Then PanLine(2, 206, 'Descente', Dec1(Vy) + ' m/s', C)
  Else PanLine(2, 206, 'Mont' + Chr(130) + 'e', Dec1(-Vy) + ' m/s', C);
  If AbsI(VXm) <= SafeVX Then C := CLR_DARKGREEN Else C := CLR_DARKRED;
  PanLine(3, 224, 'D' + Chr(130) + 'rive', Dec1(Vx) + ' m/s', C);
  PanLine(4, 242, 'Temps', IStr(FlyTicks Div 25) + ' s', CLR_BLACK);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 10 * 16) Div 2, 6, 'Alunissage', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 44, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 62, PnX + PW - 1, 104, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 63, PnX + PW - 2, 103, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 64, PnX + PW - 3, 102, CLR_WHITE);
  Edge(PnX, 168, PnX + PW - 1, 184, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 169, PnX + PW - 2, 183, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 170, PnX + PW - 3, 182, CLR_WHITE);
  DrawCounters;
  DrawInstr(True);
  Button(PnX, 284, PW, 26, 'Nouvelle partie');
  Button(PnX, 314, PW, 26, 'Pause');
  OutTxt(PnX, 346, 'Haut : moteur', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 362, 'Gauche, droite, bas', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 378, '  propulseurs', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 394, 'P : pause  F1 : aide', CLR_DARKGRAY, CLR_PALEGRAY);
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
  Else
  Begin
    RenderDyn;
    If DX2 >= DX1 Then BlitRect(Hps, DX1, DY1, DX2, DY2);
  End;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1;
  If Sig <> LastSig Then
  Begin
    LastSig := Sig;
    DrawCounters;
  End;
  DrawInstr(False);
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

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 0; MakeNoise(0, 160, 34, 4);                { moteur }
  SndPrio := 0; MakeNoise(1, 60, 18, 1);                 { propulseur }
  SndPrio := 3; MakeTone(2, 520, 1560, 600, 40);         { alunissage reussi }
  SndPrio := 3; MakeNoise(3, 900, 100, 7);               { explosion }
  SndPrio := 1; MakeTone(4, 1100, 1400, 140, 30);        { alarme du carburant }
  SndPrio := 2; MakeNoise(5, 90, 60, 5);                 { contact }
  SndPrio := 3; MakeTone(6, 880, 1760, 320, 35);         { module de plus }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure SetDiff;
Begin
  Case Diff Of
    0 : Begin SafeVY := 14000; SafeVX := 8000; End;
    2 : Begin SafeVY := 8000; SafeVX := 5000; End;
  Else
    Begin SafeVY := 10000; SafeVX := 6000; End;
  End;
End;

Procedure Show(B1, B2, B3 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; Banner3 := B3; BannerC := C;
  FullBlit := 1;
End;

Procedure FlyMsg;
Begin
  If AutoAll <> 0 Then Msg := 'Pilote automatique (Options) : le module se pose tout seul.'
  Else Msg := 'Posez-vous sur une piste, ' + Chr(133) + ' moins de ' + Dec1(SafeVY Div 400) + ' m/s. Fl' +
              Chr(138) + 'ches : moteurs.';
End;

{ choix de la piste du pilote automatique : le meilleur multiplicateur }
Procedure PickTarget;
Var I : LongInt;
Begin
  ATgt := 0;
  For I := 1 To NPad - 1 Do
    If PadM[I] > PadM[ATgt] Then ATgt := I;
  ADesc := 0;
End;

{ module au depart (nouveau niveau ou nouvel essai) }
Procedure ResetLander;
Var F : LongInt;
Begin
  Seed := LevelSeed + Level * 104729 + Lives * 31;
  LXm := (40 + Rnd(BW - 80)) * 1000; LYm := 36000;
  VXm := (Rnd(2) * 2 - 1) * (3000 + MinI(20000, (Level - 1) * 2500) + Rnd(2000)); VYm := 2000;
  F := MaxI(1600, 3000 - (Level - 1) * 120);
  Case Diff Of
    0 : F := F * 3 Div 2;
    2 : F := F * 3 Div 4;
  End;
  FuelCap := F; Fuel := F;
  Visible := 1; FlyTicks := 0; NPt := 0;
  ThrU := 0; ThrL := 0; ThrR := 0; ThrD := 0;
  HoldU := 0; HoldL := 0; HoldR := 0; HoldD := 0; PulU := 0; PulL := 0; PulR := 0; PulD := 0; MouseHeld := 0;
  PickTarget;
  State := S_READY; Wait := 0; Paused := 0;
  Show('Niveau ' + IStr(Level), IStr(NPad) + ' pistes, carburant ' + IStr(FuelCap Div 100) + ' s de moteur',
       'Une fl' + Chr(138) + 'che ou Entr' + Chr(130) + 'e : d' + Chr(130) + 'part', C_YELLOW);
  Msg := 'Niveau ' + IStr(Level) + ' : choisissez votre piste (x5 : la plus difficile, la mieux pay' + Chr(130) + 'e).';
End;

Procedure StartLevel(L : LongInt);
Begin
  Level := L;
  GenTerrain(L);
  BackOk := 0;
  ResetLander;
End;

Procedure NewGame;
Begin
  Score := 0; Lives := 3; NextBonus := 5000; Landings := 0; Crashes := 0;
  LevelSeed := (Rnd(30000) + Tick * 17) Mod 30000 + 1;
  StartLevel(1);
End;

Procedure GoFly;
Begin
  If State <> S_READY Then Exit;
  State := S_FLY; Banner := ''; FullBlit := 1;
  FlyMsg;
End;

{ fin de vol : alunissage reussi ou ecrasement }
Procedure Touchdown;
Var P, Pts, Secs, X, K : LongInt; Why : String;
Begin
  X := LXm Div 1000;
  P := PadAt(X - Foot);
  LastVY := VYm; LastVX := VXm;
  Why := '';
  If VYm > SafeVY Then Why := 'Trop vite : ' + Dec1(VYm Div 400) + ' m/s'
  Else If AbsI(VXm) > SafeVX Then Why := 'D' + Chr(130) + 'rive trop forte : ' + Dec1(AbsI(VXm) Div 400) + ' m/s';
  If (P < 0) Or (PadAt(X + Foot) <> P) Then
  Begin
    If Why = '' Then Why := 'Hors de la piste' Else Why := 'Hors de la piste, ' + Why;
  End;
  ThrU := 0; ThrL := 0; ThrR := 0; ThrD := 0;
  If Why = '' Then
  Begin
    LastOK := 1;
    LYm := PadY[P] * 1000; VXm := 0; VYm := 0;
    Secs := FlyTicks Div 25;
    Pts := 100 + 100 * Fuel Div MaxI(1, FuelCap) + MaxI(0, 60 - Secs) * 2;
    If LastVY <= SafeVY Div 2 Then Pts := Pts + 50;
    Pts := Pts * PadM[P];
    LastPts := Pts;
    Score := Score + Pts;
    If (Score > Best) And (AutoAll = 0) Then Best := Score;
    Inc(Landings);
    State := S_LANDED; Wait := 0;
    K := 0;
    While (AutoAll = 0) And (Score >= NextBonus) Do
    Begin
      NextBonus := NextBonus + 5000;
      If Lives < 5 Then Begin Inc(Lives); K := 1; End;
    End;
    If LastVY <= SafeVY Div 2 Then Why := 'en douceur, ' Else Why := '';
    Show('Alunissage r' + Chr(130) + 'ussi', 'Piste x' + IStr(PadM[P]) + ', ' + Why + IStr(Secs) + ' s  +' + IStr(Pts) +
         ' points', 'Entr' + Chr(130) + 'e ou clic : niveau suivant', C_GREENT);
    If K <> 0 Then Banner2 := Banner2 + ', module de plus';
    Msg := 'Le module est pos' + Chr(130) + ' sur la piste x' + IStr(PadM[P]) + ' (' + Dec1(LastVY Div 400) + ' m/s).';
    PlaySnd(5);
    If K <> 0 Then PlaySnd(6) Else PlaySnd(2);
  End
  Else
  Begin
    LastOK := 0;
    LYm := MinI(LYm, BH * 1000 - 1000);
    Explode;
    Visible := 0;
    Dec(Lives); Inc(Crashes);
    State := S_CRASH; Wait := 0;
    If VYm > 2 * SafeVY Then K := 1 Else K := 0;
    If Lives <= 0 Then
    Begin
      State := S_OVER;
      Show('Fin de la mission', Why + '.  Pointage : ' + IStr(Score), 'Entr' + Chr(130) + 'e ou F2 : nouvelle partie',
           C_REDT);
      Msg := 'Plus de module. Pointage final : ' + IStr(Score) + '.';
    End
    Else
    Begin
      If K <> 0 Then Show('KA-BOUM !', Why, 'Entr' + Chr(130) + 'e ou clic : nouvel essai', C_REDT)
      Else Show('BOUM !', Why, 'Entr' + Chr(130) + 'e ou clic : nouvel essai', C_REDT);
      Msg := 'Le module s''est ' + Chr(130) + 'cras' + Chr(130) + ' : ' + Why + '. Il reste ' + IStr(Lives) + ' module(s).';
    End;
    PlaySnd(3);
  End;
End;

{ pilote automatique : poussees de l'image en cours }
Procedure AutoPilot(Var U, L, R : LongInt);
Var Tx, Dx, Vd, X, X1, X2, Hm, Ty, Vyd, Lim : LongInt;
Begin
  U := 0; L := 0; R := 0;
  Tx := (PadX1[ATgt] + PadX2[ATgt] + 1) * 500;
  Dx := Tx - LXm;
  If ADesc <> 0 Then Lim := 6000 Else Lim := 2500;
  If (AbsI(Dx) <= Lim) And (AbsI(VXm) <= 2500) Then ADesc := 1 Else ADesc := 0;
  { horizontal : vitesse voulue proportionnelle a la distance }
  Vd := Clamp(Dx * 7 Div 10, -32000, 32000);
  If VXm < Vd - 700 Then R := 1 Else If VXm > Vd + 700 Then L := 1;
  { vertical : au-dessus des obstacles tant qu'on n'est pas aligne }
  If ADesc = 0 Then
  Begin
    X1 := MinI(LXm Div 1000, Tx Div 1000) - 24; X2 := MaxI(LXm Div 1000, Tx Div 1000) + 24;
    Hm := BH;
    For X := MaxI(0, X1) To MinI(BW - 1, X2) Do Hm := MinI(Hm, TH[X]);
    Ty := (Hm - 46) * 1000;
    Vyd := Clamp((Ty - LYm) * 8 Div 10, -14000, 16000);
  End
  Else Vyd := MinI(18000, 2600 + (PadY[ATgt] * 1000 - LYm) * 14 Div 100);
  If VYm > Vyd Then U := 1;
End;

{ un pas de simulation (40 ms) }
Procedure Step;
Var U, L, R, D, X, K, Hit : LongInt;
Begin
  If State <> S_FLY Then
  Begin
    ThrU := 0; ThrL := 0; ThrR := 0; ThrD := 0;
    Exit;
  End;
  Inc(FlyTicks);
  If AutoAll <> 0 Then
  Begin
    AutoPilot(U, L, R);
    D := 0;
  End
  Else
  Begin
    U := Ord((HoldU > 0) Or (PulU > 0)); L := Ord((HoldL > 0) Or (PulL > 0));
    R := Ord((HoldR > 0) Or (PulR > 0)); D := Ord((HoldD > 0) Or (PulD > 0));
    If MouseHeld <> 0 Then
    Begin
      U := 1;
      If MouseX < LXm Div 1000 - 8 Then L := 1;
      If MouseX > LXm Div 1000 + 8 Then R := 1;
    End;
    If L + R = 2 Then Begin L := 0; R := 0; End;
  End;
  If HoldU > 0 Then Dec(HoldU);
  If HoldL > 0 Then Dec(HoldL);
  If HoldR > 0 Then Dec(HoldR);
  If HoldD > 0 Then Dec(HoldD);
  If PulU > 0 Then Dec(PulU);
  If PulL > 0 Then Dec(PulL);
  If PulR > 0 Then Dec(PulR);
  If PulD > 0 Then Dec(PulD);
  { carburant : 4 par image pour le moteur, 1 par propulseur }
  If Fuel < 4 Then U := 0;
  If Fuel < 1 Then Begin L := 0; R := 0; D := 0; End;
  Fuel := MaxI(0, Fuel - U * 4 - L - R - D);
  ThrU := U; ThrL := L; ThrR := R; ThrD := D;
  { integration }
  VYm := VYm + (Grav - U * ThrMain + D * ThrSide) Div 25;
  VXm := VXm + (R - L) * ThrSide Div 25;
  VXm := VXm - VXm * 15 Div 2500;                 { amortissement du prototype }
  LXm := LXm + VXm Div 25; LYm := LYm + VYm Div 25;
  { bords et plafond : rebond (comme le prototype) }
  If LXm < 14000 Then Begin LXm := 14000; VXm := AbsI(VXm) Div 2; End;
  If LXm > (BW - 15) * 1000 Then Begin LXm := (BW - 15) * 1000; VXm := -AbsI(VXm) Div 2; End;
  If LYm < 31000 Then Begin LYm := 31000; VYm := AbsI(VYm) Div 2; End;
  { poussiere sous la tuyere pres du sol }
  If (U <> 0) And (TestMode = 0) And (AltPx < 40000) Then
  Begin
    X := LXm Div 1000;
    For K := 0 To 1 Do
    Begin
      If K = 0 Then AddPt((X - 2) * 1000, (TH[Clamp(X, 0, BW - 1)] - 1) * 1000, -14000 - Rnd(14000), -3000 - Rnd(4000),
                          10 + Rnd(10), P_DUST)
      Else AddPt((X + 2) * 1000, (TH[Clamp(X, 0, BW - 1)] - 1) * 1000, 14000 + Rnd(14000), -3000 - Rnd(4000),
                 10 + Rnd(10), P_DUST);
    End;
  End;
  { bruitages du vol }
  If U <> 0 Then PlayLoop(0) Else If L + R + D > 0 Then PlayLoop(1);
  If (Fuel * 100 < FuelCap * 15) And (Fuel > 0) And (Tick - AlarmT >= 25) Then
  Begin
    AlarmT := Tick;
    PlaySnd(4);
    Msg := 'Alarme : carburant presque ' + Chr(130) + 'puis' + Chr(130) + ' !';
  End;
  { contact avec le sol (toute la largeur entre les pieds) }
  X := LXm Div 1000; Hit := 0;
  For K := MaxI(0, X - Foot) To MinI(BW - 1, X + Foot) Do
    If LYm Div 1000 >= TH[K] Then Hit := 1;
  If Hit <> 0 Then Touchdown;
End;

Procedure Continue0;
Begin
  Case State Of
    S_READY : GoFly;
    S_LANDED : StartLevel(Level + 1);
    S_CRASH : ResetLander;
    S_OVER : NewGame;
  End;
  FullBlit := 1;
End;

Procedure TogglePause;
Begin
  If (State <> S_FLY) And (State <> S_READY) Then Exit;
  If Paused = 0 Then
  Begin
    Paused := 1;
    PrevState := State;
    Show('Pause', 'P ou Entr' + Chr(130) + 'e : reprendre', '', C_YELLOW);
    Msg := 'Pause.';
  End
  Else
  Begin
    Paused := 0;
    Banner := '';
    If State = S_READY Then ResetLander Else FlyMsg;
    FullBlit := 1;
  End;
  Frame1;
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If Paused <> 0 Then Exit;
  If Tick Mod 12 = 0 Then
  Begin
    Blink := 1 - Blink;
    If BackOk <> 0 Then Beacons(Blink <> 0);
  End;
  Step;
  MovePts;
  Inc(Wait);
  If State = S_READY Then
  Begin
    If (AutoAll <> 0) And (Wait > 40) Then GoFly;
  End
  Else If (AutoAll <> 0) And (((State = S_LANDED) Or (State = S_CRASH)) And (Wait > 75)) Then Continue0
  Else If (AutoAll <> 0) And (State = S_OVER) And (Wait > 125) Then NewGame;
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
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0);
  SetMark(CM_EASY, Diff = 0); SetMark(CM_NORMAL, Diff = 1); SetMark(CM_HARD, Diff = 2);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PAUSE : TogglePause;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll; SetMarks; PickTarget;
        If State = S_FLY Then FlyMsg;
      End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_EASY, CM_NORMAL, CM_HARD :
      Begin
        Diff := Id - CM_EASY; SetDiff; SetMarks;
        NewGame;
      End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Le module lunaire tombe vers la Lune. Posez-le sur une des pistes balis' + Chr(130) + 'es, les deux ' +
             'pieds sur la plaque, ' + Chr(133) + ' faible vitesse : moins de ' + Dec1(SafeVY Div 400) +
             ' m/s en descente et ' + Dec1(SafeVX Div 400) + ' m/s de d' + Chr(130) + 'rive. Sinon le module ' +
             'explose et vous en perdez un (trois au d' + Chr(130) + 'part, un de plus tous les 5000 points).' +
             Chr(10) + Chr(10));
        LAdd('Les pistes ont un multiplicateur : x1 (large) ' + Chr(133) + ' x5 (' + Chr(130) + 'troite). Points : ' +
             '100, plus le carburant qui reste (jusqu''' + Chr(133) + ' 100), plus la rapidit' + Chr(130) +
             ' (2 par seconde sous 60 s), plus 50 en douceur, le tout multipli' + Chr(130) + ' par la piste. ' +
             'Chaque niveau donne un nouveau terrain, moins de carburant et plus de d' + Chr(130) + 'rive.' +
             Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'che haut ou Espace (moteur principal), gauche et droite (propulseurs ' +
             'lat' + Chr(130) + 'raux), bas (propulseurs vers le bas), P (pause), Entr' + Chr(130) +
             'e (continuer), F2 (nouvelle partie). Souris : bouton maintenu sur le ciel = moteur, le module ' +
             'se d' + Chr(130) + 'porte vers le pointeur. Options : pilote automatique, son, difficult' + Chr(130) +
             '.');
        Dummy := LMsgBox('Alunissage - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Alunissage pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype LUNAR.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

{ touche enfoncee : poussee maintenue (14 images, renouvelee par la
  repetition du clavier) et impulsion minimale de 3 images }
Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    If (Fl And KC_VIRTUALKEY) <> 0 Then
    Begin
      If (Vk = VK_UP) Or (Vk = VK_SPACE) Then HoldU := 0;
      If Vk = VK_LEFT Then HoldL := 0;
      If Vk = VK_RIGHT Then HoldR := 0;
      If Vk = VK_DOWN Then HoldD := 0;
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
    If (Vk = VK_UP) Or (Vk = VK_SPACE) Or (Vk = VK_LEFT) Or (Vk = VK_RIGHT) Or (Vk = VK_DOWN) Then
    Begin
      If Paused <> 0 Then Exit;
      If State = S_READY Then GoFly;
      If (Vk = VK_SPACE) And (State <> S_FLY) Then
      Begin
        Continue0;
        Frame1;
        Exit;
      End;
      Case Vk Of
        VK_UP, VK_SPACE : Begin HoldU := 14; PulU := 3; End;
        VK_LEFT : Begin HoldL := 14; PulL := 3; End;
        VK_RIGHT : Begin HoldR := 14; PulR := 3; End;
        VK_DOWN : Begin HoldD := 14; PulD := 3; End;
      End;
      Frame1;
      Exit;
    End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      If Paused <> 0 Then TogglePause Else Continue0;
      Frame1;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'P' : TogglePause;
      'N' : Begin NewGame; Frame1; End;
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
    If (Y >= 284) And (Y < 310) Then Command(CM_NEW)
    Else If (Y >= 314) And (Y < 340) Then Command(CM_PAUSE);
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If Paused <> 0 Then Begin TogglePause; Exit; End;
    If (State = S_LANDED) Or (State = S_CRASH) Or (State = S_OVER) Then
    Begin
      Continue0;
      Frame1;
      Exit;
    End;
    If State = S_READY Then GoFly;
    If (State = S_FLY) And (AutoAll = 0) Then
    Begin
      MouseHeld := 1; MouseX := X - OX;
    End;
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
    WM_BUTTON1UP :
      Begin
        MouseHeld := 0;
        MainProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        MouseX := S16(Mp1) - OX;
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

{ vol jusqu'a la fin (pilote automatique) ; resultat : 1 pose, 0 ecrase }
Function FlyAuto : LongInt;
Var N, R : LongInt;
Begin
  GoFly;
  N := 0;
  While (State = S_FLY) And (N < 6000) Do
  Begin
    Step;
    MovePts;
    Inc(N);
  End;
  If State = S_LANDED Then R := 1 Else R := 0;
  FlyAuto := R;
End;

Procedure RunTests;
Var Ok, K, L, S, Good, Bad, A, B, N, T, V, Lv, Fu : LongInt;
Begin
  Ok := 0;
  SoundOn := 0; Diff := 1; SetDiff; AutoAll := 0; LevelSeed := 77; Lives := 3; Score := 0; Level := 1;
  NextBonus := 5000;
  { 1 : chute libre d'une seconde (25 images) : 1,62 m/s et 0,8 m }
  GenTerrain(1);
  ResetLander;
  GoFly;
  LXm := 200000; LYm := 40000; VXm := 0; VYm := 0;
  For K := 1 To 25 Do Step;
  V := VYm; A := LYm - 40000;
  Log('LUNAR : TEST1 vitesse ' + Dec1(V Div 400) + ' m/s chute ' + IStr(A Div 1000) + ' points etat ' + IStr(State));
  If (V = 25 * (Grav Div 25)) And (A Div 1000 >= 3) And (A Div 1000 <= 4) And (State = S_FLY) Then Inc(Ok);
  { 2 : terrains de 8 niveaux pour 20 graines : pistes plates, separees,
    dans l'ecran, sol dans les limites }
  Good := 0; T := 0;
  For S := 1 To 20 Do
    For L := 1 To 8 Do
    Begin
      Inc(T);
      LevelSeed := S * 13;
      GenTerrain(L);
      Bad := 0;
      If (L = 1) And (NPad <> 3) Then Bad := 1;
      If (L > 1) And (NPad <> 4) Then Bad := 1;
      For A := 0 To NPad - 1 Do
      Begin
        If (PadX1[A] < 0) Or (PadX2[A] >= BW) Or (PadX2[A] - PadX1[A] + 1 < 2 * Foot + 8) Then Bad := 1;
        For K := PadX1[A] To PadX2[A] Do
          If TH[K] <> PadY[A] Then Bad := 1;
        For B := 0 To NPad - 1 Do
          If (B <> A) And (PadX1[B] <= PadX2[A] + 4) And (PadX2[B] >= PadX1[A] - 4) Then Bad := 1;
      End;
      For K := 0 To BW - 1 Do
        If (TH[K] < 200) Or (TH[K] > BH - 14) Then Bad := 1;
      If Bad = 0 Then Inc(Good);
    End;
  Log('LUNAR : TEST2 terrains ' + IStr(Good) + '/' + IStr(T) + ' corrects');
  If Good = T Then Inc(Ok);
  { 3 : jugement du contact : piste a 2 m/s (pose), a 4 m/s (ecrase), hors
    de la piste, derive trop forte }
  LevelSeed := 77; Level := 1; GenTerrain(1);
  N := 0;
  For K := 0 To 3 Do
  Begin
    ResetLander; GoFly;
    LXm := (PadX1[0] + PadX2[0] + 1) * 500; LYm := PadY[0] * 1000 - 200; VXm := 0; VYm := 8000;
    If K = 1 Then VYm := 16000;
    If K = 2 Then LXm := (PadX1[0] - 3) * 1000;
    If K = 3 Then VXm := 9000;
    Step;
    If (K = 0) And (State = S_LANDED) Then Inc(N);
    If (K > 0) And ((State = S_CRASH) Or (State = S_OVER)) Then Inc(N);
  End;
  Log('LUNAR : TEST3 contacts ' + IStr(N) + '/4 bien juges, pointage ' + IStr(Score) + ' modules ' + IStr(Lives));
  If (N = 4) And (Lives = 0) Then Inc(Ok);
  { 4 : carburant : le moteur consomme 4 par image et s'arrete a sec }
  Lives := 3; ResetLander; GoFly;
  LXm := 200000; LYm := 40000; VXm := 0; VYm := 0; Fuel := 10;
  HoldU := 50;
  Step; Fu := Fuel; Lv := VYm;
  Step; Step; Step;
  Log('LUNAR : TEST4 carburant ' + IStr(Fu) + ' puis ' + IStr(Fuel) + ' vitesse ' + IStr(Lv) + ' puis ' + IStr(VYm));
  If (Fu = 6) And (Fuel = 2) And (Lv = (Grav - ThrMain) Div 25) And (VYm > Lv) Then Inc(Ok);
  { 5 : partie avec le pilote automatique (graine fixe) : 12 vols ; le
    pointage est compte comme pour un joueur }
  Seed := 2026; AutoAll := 1; HoldU := 0;
  NewGame;
  A := 0; B := 0; N := 0;
  For K := 1 To 12 Do
  Begin
    If FlyAuto = 1 Then
    Begin
      Inc(A);
      N := N + PadM[PadAt(LXm Div 1000)];
      StartLevel(Level + 1);
    End
    Else
    Begin
      Inc(B);
      Lives := 3;
      ResetLander;
    End;
  End;
  Log('LUNAR : PARTIE vols 12 poses ' + IStr(A) + ' ecrases ' + IStr(B) + ' niveau ' + IStr(Level) + ' multiplicateurs ' +
      IStr(N) + ' pointage ' + IStr(Score));
  If A >= 10 Then Inc(Ok);
  Log('LUNAR : ' + IStr(Ok) + '/5 essais reussis');
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
  Flg, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y, StartL : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  InDlg := 0;
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Banner3 := ''; Best := 0; Tick := 0;
  Client := 0; Frame := 0; SoundOn := 1; StartL := 1; Level := 1; SndCur := 0; SndEnd := 0; AlarmT := 0;
  Score := 0; TestMode := 0; State := S_READY; CW := CWant; CH := CHWant; Diff := 1; Paused := 0; Blink := 0;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1; FullBlit := 1; BackOk := 0; NPt := 0; OBx1 := 1; OBx2 := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/LEVEL:') Then
    Begin
      Val(Copy(S, 8, 20), StartL, E);
      If StartL < 1 Then StartL := 1;
      If StartL > 99 Then StartL := 99;
    End;
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
  Dummy := WinRegisterClass(Hab, Z('LUNAR'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('LUNAR'), Z2('Alunissage'), 0, 0, 0, LongInt(@Client));
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
  MItem(MIS_TEXT, 0, CM_AUTO, '~Pilote automatique');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_EASY, '~Facile');
  MItem(MIS_TEXT, 0, CM_NORMAL, '~Normal');
  MItem(MIS_TEXT, 0, CM_HARD, '~Difficile');
  MenuClose(H3, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos d''Alunissage');
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
  Score := 0; Lives := 3; NextBonus := 5000;
  LevelSeed := Rnd(30000) + 1;
  StartLevel(StartL);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
