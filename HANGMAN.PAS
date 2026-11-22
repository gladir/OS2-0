{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: HANGMAN - Bonhomme pendu pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau).
}

Program HANGMAN;

{$R-,S-,I-}

{ Compilation : OS2PC HANGMAN.PAS   (produit HANGMAN.EXE)

  Portage vers OS/2-0 du prototype HANGMAN.PAS du depot 7iles (Turbo
  Pascal, BGI, clavier seulement) : fenetre de Presentation Manager avec
  menus, image en memoire recopiee par GpiDrawBits (pas de scintillement),
  apparence d'OS/2 Warp 3.

  La scene est entierement redessinee : ciel, soleil, nuages, collines,
  potence en bois (planches, veinures, vis, jambe de force), corde
  torsadee avec noeud coulant, et un bonhomme dessine comme un dessin
  anime, a gros contours : grosse tete ronde (cheveux, oreilles, joues),
  yeux et bouche qui changent selon les erreurs (sourire, inquietude,
  peur avec goutte de sueur, yeux en croix et langue tiree a la fin, grand
  sourire et bras leves s'il est sauve, clignement des yeux), chemise a
  boutons et ceinture, manches, mains, pantalon, chaussures. Une partie
  s'ajoute a chaque erreur : tete, corps, bras gauche, bras droit, jambe
  gauche, jambe droite, chaussures (7 erreurs : perdu).

  Les trois listes de mots du prototype (Debutant, Chevalier, Roi) sont
  reprises. Ce qui est corrige : une bonne lettre tapee deux fois etait
  comptee deux fois (victoire avant d'avoir trouve le mot) ; le dernier
  mot de chaque liste n'etait jamais tire (Random(High)) ; le bonhomme
  etait dessine en commencant par les jambes. Ce qui s'ajoute : clavier
  de lettres a cliquer (vert : trouvee, rouge : absente), clavier
  physique (lettres accentuees acceptees), lettres fausses deja
  essayees, coeurs des erreurs restantes, mots tires sans repetition
  (sac melange), pointage (lettres du mot et erreurs restantes, multiplies
  par le niveau, prime de serie), parties gagnees et perdues, record de
  la seance, demonstration (l'ordinateur essaie les lettres les plus
  frequentes du francais), bruitages.

  Clavier : A a Z (essayer une lettre), Entree ou Espace (nouveau mot
  apres la fin), F2 (nouveau mot), F1 (regles).
  Parametres : /SEED:n ; /LEVEL:BEGINNER|KNIGHT|KING (ou DEBUTANT,
  CHEVALIER, ROI) ; /AUTO (demonstration) ; /NOSOUND ; /TEST (essais
  sans fenetre, resultat sur le port serie COM1). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_SPACE = $10; VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_PALEGRAY = 15;
  CM_NEWWORD = 101; CM_NEWGAME = 102; CM_QUIT = 103;
  CM_LEVEL0 = 201; CM_LEVEL1 = 202; CM_LEVEL2 = 203; CM_AUTO = 204; CM_SOUND = 205;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : scene a gauche (0..SW-1), lettres et clavier a droite }
  BW = 608; BH = 400; OX = 8; OY = 8; SW = 286; RX = 298;
  CWant = 624; CHWant = 436;
  MaxErr = 7; NWord = 32;
  { mot : cases de 26 x 42 ; clavier : touches de 40 x 38 }
  TileY = 156; TileW = 26; TileH = 42; TileS = 29;
  KeyY = 238; KeyW = 40; KeyH = 38; KeySX = 43; KeySY = 40;
  { couleurs de l'image }
  C_SKY = 0;                                 { 0..15 : ciel (haut -> horizon) }
  C_GRASS = 16;                              { 16..19 : herbe (sombre -> clair) }
  C_WOOD = 20;                               { 20..23 : bois (sombre -> reflet) }
  C_INK = 24; C_WHITE = 25; C_SKIN = 26; C_SKIND = 27; C_CHEEK = 28;
  C_SHIRT = 29; C_SHIRTD = 30; C_SHIRTL = 31; C_PANTS = 32; C_PANTSD = 33; C_SHOE = 34; C_SHOEL = 35;
  C_HAIR = 36; C_HAIRD = 37; C_ROPE = 38; C_ROPED = 39; C_MOUTH = 40; C_TONGUE = 41; C_SWEAT = 42;
  C_CLOUD = 43; C_CLOUDD = 44; C_SUN = 45; C_SUNG = 46; C_HILL1 = 47; C_HILL2 = 48;
  C_GRAY = 49; C_DGRAY = 50; C_BLACK = 51; C_DBLUE = 52; C_KEYG = 53; C_KEYGD = 54; C_KEYR = 55; C_KEYRD = 56;
  C_TILE = 57; C_TILED = 58; C_DRED = 59; C_DGREEN = 60; C_GOLD = 61; C_BELT = 62; C_BUCKLE = 63;
  C_HEART = 64; C_SHADOWG = 65; C_LGRAY = 66; C_SKINL = 67; C_PALE = 68;
  S_PLAY = 1; S_WON = 2; S_LOST = 3;
  SndRate = 11025;
  { lettres les plus frequentes du francais (demonstration) }
  Freq = 'EASIRNTOULDCMPGBVHFQYXJKWZ';
  { mots du prototype : 0..31 Debutant, 32..63 Chevalier, 64..95 Roi }
  Words : Array[0..3 * NWord - 1] Of String[12] = (
    'ARBRE', 'ARGENT', 'ABRI', 'BIEN', 'MAL', 'BEAU', 'MOCHE', 'SALE', 'OEIL', 'DENT', 'BRAS', 'MAIN', 'PIED',
    'CUISSE', 'JAMBE', 'COU', 'FLEUR', 'BEBE', 'COLLE', 'SAUT', 'PAIN', 'CHANT', 'MATIN', 'SOIR', 'DOS', 'DEVANT',
    'FACE', 'LOIN', 'YEUX', 'TROIS', 'DEUX', 'QUATRE',
    'ARGENTINE', 'MALAISIE', 'MONACO', 'PAKISTAN', 'PARISIEN', 'SOUMISSION', 'OMAN', 'GAMBIE', 'LAOS', 'ALBATROS',
    'ALBATOR', 'AMOURETTE', 'CABESTAN', 'BARBARE', 'BICEPS', 'MUSCLE', 'BORDURE', 'PROCESSEUR', 'MONITEUR',
    'DISQUE', 'DISQUETTE', 'CLAVIER', 'CARTE', 'CIRCUIT', 'ROLLER', 'MATRICE', 'PIXEL', 'INTRODUIT', 'DICTON',
    'REPAS', 'CANADA', 'CANARI',
    'AORTITE', 'APEX', 'APLITE', 'BAUX', 'BLUFF', 'BOURG', 'CAITYA', 'CAPRON', 'CENS', 'CHIITE', 'CIMIER',
    'COOLIE', 'COTIR', 'DIDYME', 'DIZAIN', 'DIZYGOTE', 'DOUAR', 'EUTEXIE', 'FASEYER', 'FJELD', 'FUSCINE',
    'GALATE', 'GLOME', 'GOY', 'GUELFE', 'HERCHER', 'HOSANNA', 'JUSANT', 'LAD', 'LINTER', 'LIMAN', 'LODS');

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { partie }
  Secret, Wrong : String;
  WLen, Errors, State, LevelI, Score, Best, Wins, Losses, Streak, LastPts, Tried, Seed : LongInt;
  Guessed : Array[0..25] Of LongInt;          { 0 : pas essayee, 1 : dans le mot, 2 : absente }
  BagOrd : Array[0..3 * NWord - 1] Of LongInt;
  BagPos : Array[0..2] Of LongInt;
  AutoAll, AutoWait, SoundOn, TestMode, Tick, Blink, EndWait : LongInt;
  { zone a recopier }
  DX1, DY1, DX2, DY2 : LongInt;
  Msg, LastMsg : String;
  { bruitages }
  SndBuf : Array[0..39999] Of Byte;
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

Function LevelName(L : LongInt) : String;
Begin
  If L = 0 Then LevelName := 'D' + Chr(130) + 'butant'
  Else If L = 1 Then LevelName := 'Chevalier'
  Else LevelName := 'Roi';
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
  For I := 0 To 15 Do SetPal(C_SKY + I, Mix($3C8CDC, $D2ECFA, I, 15));
  SetPal(C_GRASS, $2E7A22); SetPal(C_GRASS + 1, $3E9830); SetPal(C_GRASS + 2, $52B23E); SetPal(C_GRASS + 3, $6CC84E);
  SetPal(C_WOOD, $5A3214); SetPal(C_WOOD + 1, $8C5428); SetPal(C_WOOD + 2, $B07440); SetPal(C_WOOD + 3, $D09A62);
  SetPal(C_INK, $1E140E); SetPal(C_WHITE, $FFFFFF); SetPal(C_SKIN, $FFD2A8); SetPal(C_SKIND, $E0A478);
  SetPal(C_CHEEK, $FF9C9C); SetPal(C_SHIRT, $E0402C); SetPal(C_SHIRTD, $A82818); SetPal(C_SHIRTL, $FF7A5C);
  SetPal(C_PANTS, $3460C8); SetPal(C_PANTSD, $203C88); SetPal(C_SHOE, $6A3A1A); SetPal(C_SHOEL, $A8683A);
  SetPal(C_HAIR, $E07818); SetPal(C_HAIRD, $A04C08); SetPal(C_ROPE, $D8B878); SetPal(C_ROPED, $9C7C40);
  SetPal(C_MOUTH, $7A1418); SetPal(C_TONGUE, $FF6E84); SetPal(C_SWEAT, $7CC8FF);
  SetPal(C_CLOUD, $FFFFFF); SetPal(C_CLOUDD, $C4D8EC); SetPal(C_SUN, $FFE040); SetPal(C_SUNG, $FFF0A0);
  SetPal(C_HILL1, $7CC060); SetPal(C_HILL2, $5CA84A);
  SetPal(C_GRAY, $CCCCCC); SetPal(C_DGRAY, $808080); SetPal(C_BLACK, $000000); SetPal(C_DBLUE, $000080);
  SetPal(C_KEYG, $3CA046); SetPal(C_KEYGD, $1E6426); SetPal(C_KEYR, $D04038); SetPal(C_KEYRD, $801C18);
  SetPal(C_TILE, $FFF8E4); SetPal(C_TILED, $C8BC9C); SetPal(C_DRED, $B01010); SetPal(C_DGREEN, $007A10);
  SetPal(C_GOLD, $FFC020); SetPal(C_BELT, $3C2410); SetPal(C_BUCKLE, $F0C838); SetPal(C_HEART, $E8243C);
  SetPal(C_SHADOWG, $2A6A1E); SetPal(C_LGRAY, $E4E4E4); SetPal(C_SKINL, $FFE6CC); SetPal(C_PALE, $D8E4C8);
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

{ demi-largeur d'une ellipse a la hauteur Dy }
Function EllW(Rx, Ry, Dy : LongInt) : LongInt;
Var W : LongInt;
Begin
  W := 0;
  If (Ry <= 0) Or (Dy > Ry) Or (Dy < -Ry) Then
  Begin
    EllW := -1;
    Exit;
  End;
  While (W + 1) * (W + 1) * Ry * Ry + Dy * Dy * Rx * Rx <= Rx * Rx * Ry * Ry + Rx * Ry Do Inc(W);
  EllW := W;
End;

Procedure Ell(Cx, Cy, Rx, Ry, C : LongInt);
Var Dy, W : LongInt;
Begin
  For Dy := -Ry To Ry Do
  Begin
    W := EllW(Rx, Ry, Dy);
    If W >= 0 Then Rect(Cx - W, Cy + Dy, Cx + W, Cy + Dy, C);
  End;
End;

Procedure Disc(Cx, Cy, R, C : LongInt);
Begin
  Ell(Cx, Cy, R, R, C);
End;

{ anneau elliptique d'epaisseur T }
Procedure Ring(Cx, Cy, Rx, Ry, T, C : LongInt);
Var Dy, W, Wi : LongInt;
Begin
  For Dy := -Ry To Ry Do
  Begin
    W := EllW(Rx, Ry, Dy);
    Wi := EllW(Rx - T, Ry - T, Dy);
    If W >= 0 Then
    Begin
      If Wi < 0 Then Rect(Cx - W, Cy + Dy, Cx + W, Cy + Dy, C)
      Else
      Begin
        Rect(Cx - W, Cy + Dy, Cx - Wi - 1, Cy + Dy, C);
        Rect(Cx + Wi + 1, Cy + Dy, Cx + W, Cy + Dy, C);
      End;
    End;
  End;
End;

{ trait epais (rayon R) aux bouts arrondis }
Procedure TLine(X1, Y1, X2, Y2, R, C : LongInt);
Var X, Y, Dx, Dy, L2, T, Qx, Qy, Xa, Xb, Ya, Yb, Lim : LongInt;
Begin
  Dx := X2 - X1; Dy := Y2 - Y1;
  L2 := Dx * Dx + Dy * Dy;
  Xa := MinI(X1, X2) - R; Xb := MaxI(X1, X2) + R;
  Ya := MinI(Y1, Y2) - R; Yb := MaxI(Y1, Y2) + R;
  Lim := R * R + R;
  If R = 0 Then Lim := 0;
  For Y := Ya To Yb Do
    For X := Xa To Xb Do
    Begin
      If L2 = 0 Then
      Begin
        Qx := X1; Qy := Y1;
      End
      Else
      Begin
        T := (X - X1) * Dx + (Y - Y1) * Dy;
        If T < 0 Then T := 0;
        If T > L2 Then T := L2;
        Qx := X1 + (Dx * T + L2 Div 2) Div L2;
        Qy := Y1 + (Dy * T + L2 Div 2) Div L2;
      End;
      If (X - Qx) * (X - Qx) + (Y - Qy) * (Y - Qy) <= Lim Then Pix(X, Y, C);
    End;
End;

{ arc de cercle (angles en degres, 0 : droite, 90 : bas) }
Procedure Arc(Cx, Cy, R, A1, A2, T, C : LongInt);
Var A, X, Y, Px, Py : LongInt;
Begin
  Px := -9999; Py := -9999;
  A := A1;
  While A <= A2 Do
  Begin
    X := Cx + Round(R * Cos(A * 0.0174533));
    Y := Cy + Round(R * Sin(A * 0.0174533));
    If Px <> -9999 Then TLine(Px, Py, X, Y, T, C);
    Px := X; Py := Y;
    A := A + 10;
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

{ texte centre dans la partie droite }
Procedure RText(Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(RX + (BW - RX - Length(S) * 8 * Sc) Div 2, Y, S, C, Sc);
End;

Procedure Touch(X1, Y1, X2, Y2 : LongInt);
Begin
  If DX2 < DX1 Then
  Begin
    DX1 := X1; DY1 := Y1; DX2 := X2; DY2 := Y2;
  End
  Else
  Begin
    DX1 := MinI(DX1, X1); DY1 := MinI(DY1, Y1); DX2 := MaxI(DX2, X2); DY2 := MaxI(DY2, Y2);
  End;
End;

{ ==================================================================== }
{ Scene : ciel, potence, bonhomme                                       }
{ ==================================================================== }

Procedure Cloud(X, Y, S : LongInt);
Begin
  Disc(X - 16 * S Div 4, Y + 4, 11 * S Div 4, C_CLOUDD); Disc(X, Y + 3, 15 * S Div 4, C_CLOUDD);
  Disc(X + 18 * S Div 4, Y + 5, 10 * S Div 4, C_CLOUDD);
  Disc(X - 16 * S Div 4, Y, 11 * S Div 4, C_CLOUD); Disc(X, Y - 3, 15 * S Div 4, C_CLOUD);
  Disc(X + 18 * S Div 4, Y + 1, 10 * S Div 4, C_CLOUD);
  Rect(X - 16 * S Div 4, Y + 1, X + 18 * S Div 4, Y + 8 * S Div 4, C_CLOUD);
End;

{ poutre de bois : contour, face, reflet en haut et a gauche, ombre }
Procedure Beam(X1, Y1, X2, Y2 : LongInt; Vert : Boolean);
Var K : LongInt;
Begin
  Rect(X1 - 2, Y1 - 2, X2 + 2, Y2 + 2, C_INK);
  Rect(X1, Y1, X2, Y2, C_WOOD + 1);
  If Vert Then
  Begin
    Rect(X1, Y1, X1 + 3, Y2, C_WOOD + 2); Rect(X1 + 1, Y1, X1 + 1, Y2, C_WOOD + 3);
    Rect(X2 - 3, Y1, X2, Y2, C_WOOD);
    K := Y1 + 30;
    While K < Y2 - 30 Do
    Begin
      Rect(X1 + 7, K, X1 + 7, K + 22, C_WOOD); Rect(X1 + 11, K + 12, X1 + 11, K + 40, C_WOOD);
      K := K + 64;
    End;
  End
  Else
  Begin
    Rect(X1, Y1, X2, Y1 + 3, C_WOOD + 2); Rect(X1, Y1 + 1, X2, Y1 + 1, C_WOOD + 3);
    Rect(X1, Y2 - 3, X2, Y2, C_WOOD);
    K := X1 + 24;
    While K < X2 - 30 Do
    Begin
      Rect(K, Y1 + 8, K + 26, Y1 + 8, C_WOOD); Rect(K + 14, Y1 + 12, K + 44, Y1 + 12, C_WOOD);
      K := K + 70;
    End;
  End;
End;

Procedure Screw(X, Y : LongInt);
Begin
  Disc(X, Y, 3, C_INK);
  Disc(X, Y, 2, C_LGRAY);
  Rect(X - 1, Y, X + 1, Y, C_DGRAY);
End;

{ corde torsadee verticale }
Procedure Rope(X, Y1, Y2 : LongInt);
Var Y : LongInt;
Begin
  TLine(X, Y1, X, Y2, 4, C_INK);
  TLine(X, Y1, X, Y2, 2, C_ROPE);
  Y := Y1 + 2;
  While Y < Y2 - 2 Do
  Begin
    Pix(X - 2, Y, C_ROPED); Pix(X - 1, Y + 1, C_ROPED); Pix(X, Y + 2, C_ROPED); Pix(X + 1, Y + 3, C_ROPED);
    Y := Y + 6;
  End;
End;

{ membre : contour epais puis couleur (Cd : ombre, C : couleur) }
Procedure Limb(X1, Y1, X2, Y2, R, C, Cd : LongInt);
Begin
  TLine(X1, Y1, X2, Y2, R + 3, C_INK);
  TLine(X1, Y1, X2, Y2, R, Cd);
  TLine(X1 - 2, Y1, X2 - 2, Y2, R - 3, C);
End;

Procedure Hand(X, Y : LongInt);
Begin
  Disc(X, Y, 10, C_INK);
  Disc(X, Y, 7, C_SKIND);
  Disc(X - 1, Y - 1, 5, C_SKIN);
End;

Procedure Shoe(X, Y, Dir : LongInt);
Begin
  Ell(X + Dir * 4, Y, 16, 9, C_INK);
  Ell(X + Dir * 4, Y, 13, 6, C_SHOE);
  Ell(X + Dir * 4 - 2, Y - 2, 8, 3, C_SHOEL);
  Rect(X + Dir * 4 - 12, Y + 3, X + Dir * 4 + 12, Y + 4, C_INK);
End;

{ bras : Side -1 (gauche) ou 1 (droite) ; Up : bras leves (sauve) }
Procedure Arm(Side : LongInt; Up : Boolean);
Var Sx, Ex, Ey, Hx, Hy : LongInt;
Begin
  Sx := 190 + Side * 17;
  If Up Then
  Begin
    Ex := 190 + Side * 34; Ey := 156; Hx := 190 + Side * 44; Hy := 124;
  End
  Else
  Begin
    Ex := 190 + Side * 27; Ey := 192; Hx := 190 + Side * 40; Hy := 226;
  End;
  TLine(Ex, Ey, Hx, Hy, 9, C_INK);
  TLine(Ex, Ey, Hx, Hy, 6, C_SKIND);
  TLine(Ex - 1, Ey, Hx - 1, Hy, 3, C_SKIN);
  Hand(Hx, Hy);
  { manche courte }
  TLine(Sx, 172, Ex, Ey, 12, C_INK);
  TLine(Sx, 172, Ex, Ey, 9, C_SHIRTD);
  TLine(Sx - 2, 171, Ex - 2, Ey - 1, 6, C_SHIRT);
End;

Procedure Leg(Side : LongInt);
Var Hx, Fx : LongInt;
Begin
  Hx := 190 + Side * 10; Fx := 190 + Side * 16;
  Limb(Hx, 226, Fx, 290, 10, C_PANTS, C_PANTSD);
End;

{ corps : chemise a boutons, ceinture }
Procedure Body;
Var Dy, W : LongInt;
Begin
  Ell(190, 196, 26, 42, C_INK);
  Ell(190, 196, 23, 39, C_SHIRTD);
  Ell(187, 193, 19, 35, C_SHIRT);
  Ell(181, 180, 5, 14, C_SHIRTL);
  { col en V }
  TLine(181, 160, 190, 174, 2, C_INK); TLine(199, 160, 190, 174, 2, C_INK);
  Disc(190, 186, 2, C_INK); Disc(190, 200, 2, C_INK); Disc(190, 214, 2, C_INK);
  { ceinture : tranche de l'ellipse }
  For Dy := 26 To 32 Do
  Begin
    W := EllW(23, 39, Dy);
    If W >= 0 Then Rect(190 - W, 196 + Dy, 190 + W, 196 + Dy, C_BELT);
  End;
  Rect(185, 222, 195, 228, C_INK); Rect(187, 223, 193, 227, C_BUCKLE); Rect(189, 224, 191, 226, C_BELT);
End;

Procedure Neck;
Begin
  Rect(181, 144, 199, 166, C_INK);
  Rect(184, 144, 196, 166, C_SKIND);
  Rect(184, 144, 192, 166, C_SKIN);
End;

{ noeud coulant serre autour du cou }
Procedure Noose;
Begin
  Ring(190, 160, 15, 7, 5, C_INK);
  Ring(190, 160, 13, 5, 3, C_ROPE);
  Disc(205, 154, 7, C_INK);
  Disc(205, 154, 5, C_ROPE);
  Rect(201, 152, 209, 152, C_ROPED); Rect(201, 156, 209, 156, C_ROPED);
End;

{ tete, cheveux, visage selon l'etat : Mood 0 calme, 1 inquiet, 2 peur,
  3 pendu (perdu), 4 sauve }
Procedure Head(Mood : LongInt);
Var X, Y, K : LongInt;
Begin
  X := 190; Y := 124;
  { oreilles }
  Disc(X - 25, Y + 3, 8, C_INK); Disc(X + 25, Y + 3, 8, C_INK);
  Disc(X - 25, Y + 3, 5, C_SKIND); Disc(X + 25, Y + 3, 5, C_SKIND);
  { tete : contour, ombre en bas a droite, reflet }
  Disc(X, Y, 28, C_INK);
  If Mood = 3 Then Disc(X, Y, 25, C_SKIND) Else Disc(X, Y, 25, C_SKIND);
  If Mood = 3 Then Disc(X - 3, Y - 3, 21, C_PALE) Else Disc(X - 3, Y - 3, 21, C_SKIN);
  Ell(X - 11, Y - 13, 6, 4, C_SKINL);
  { cheveux : touffe en meches }
  Disc(X - 12, Y - 22, 10, C_INK); Disc(X, Y - 26, 11, C_INK); Disc(X + 12, Y - 22, 10, C_INK);
  Disc(X - 12, Y - 22, 7, C_HAIRD); Disc(X, Y - 26, 8, C_HAIRD); Disc(X + 12, Y - 22, 7, C_HAIRD);
  Disc(X - 13, Y - 23, 5, C_HAIR); Disc(X - 1, Y - 27, 6, C_HAIR); Disc(X + 11, Y - 23, 5, C_HAIR);
  TLine(X + 2, Y - 34, X + 8, Y - 40, 2, C_INK); TLine(X + 8, Y - 40, X + 14, Y - 38, 2, C_INK);
  { sourcils }
  Case Mood Of
    0, 4 :
      Begin
        Arc(X - 10, Y - 10, 6, 200, 340, 1, C_INK); Arc(X + 10, Y - 10, 6, 200, 340, 1, C_INK);
      End;
    1 :
      Begin
        TLine(X - 16, Y - 13, X - 5, Y - 16, 1, C_INK); TLine(X + 5, Y - 16, X + 16, Y - 13, 1, C_INK);
      End;
    2 :
      Begin
        TLine(X - 16, Y - 14, X - 5, Y - 20, 1, C_INK); TLine(X + 5, Y - 20, X + 16, Y - 14, 1, C_INK);
      End;
  End;
  { yeux }
  If Mood = 3 Then
  Begin
    For K := 0 To 1 Do
    Begin
      TLine(X + K * 20 - 15, Y - 7, X + K * 20 - 5, Y + 1, 2, C_INK);
      TLine(X + K * 20 - 15, Y + 1, X + K * 20 - 5, Y - 7, 2, C_INK);
    End;
  End
  Else If Mood = 4 Then
  Begin
    Arc(X - 10, Y - 1, 6, 190, 350, 2, C_INK); Arc(X + 10, Y - 1, 6, 190, 350, 2, C_INK);
  End
  Else If Blink <> 0 Then
  Begin
    TLine(X - 15, Y - 3, X - 5, Y - 3, 1, C_INK); TLine(X + 5, Y - 3, X + 15, Y - 3, 1, C_INK);
  End
  Else
  Begin
    K := 0;
    If Mood = 2 Then K := 1;
    Ell(X - 10, Y - 4, 7 + K, 9 + K, C_INK); Ell(X + 10, Y - 4, 7 + K, 9 + K, C_INK);
    Ell(X - 10, Y - 4, 5 + K, 7 + K, C_WHITE); Ell(X + 10, Y - 4, 5 + K, 7 + K, C_WHITE);
    If Mood = 2 Then
    Begin
      Disc(X - 10, Y - 4, 2, C_INK); Disc(X + 10, Y - 4, 2, C_INK);
    End
    Else
    Begin
      Disc(X - 8, Y - 2, 3, C_INK); Disc(X + 12, Y - 2, 3, C_INK);
      Pix(X - 9, Y - 3, C_WHITE); Pix(X + 11, Y - 3, C_WHITE);
    End;
  End;
  { nez et joues }
  Disc(X + 1, Y + 6, 4, C_INK); Disc(X + 1, Y + 6, 3, C_SKIND); Pix(X, Y + 5, C_SKINL);
  If (Mood = 0) Or (Mood = 4) Then
  Begin
    Ell(X - 15, Y + 9, 5, 3, C_CHEEK); Ell(X + 16, Y + 9, 5, 3, C_CHEEK);
  End;
  { bouche }
  Case Mood Of
    0 : Arc(X, Y + 6, 10, 30, 150, 2, C_INK);
    1 :
      Begin
        TLine(X - 8, Y + 16, X - 3, Y + 14, 1, C_INK); TLine(X - 3, Y + 14, X + 3, Y + 16, 1, C_INK);
        TLine(X + 3, Y + 16, X + 8, Y + 14, 1, C_INK);
      End;
    2 :
      Begin
        Ell(X, Y + 16, 7, 7, C_INK); Ell(X, Y + 16, 5, 5, C_MOUTH); Ell(X, Y + 19, 3, 2, C_TONGUE);
        { goutte de sueur }
        Disc(X + 22, Y - 4, 5, C_INK); TLine(X + 22, Y - 4, X + 22, Y - 14, 3, C_INK);
        Disc(X + 22, Y - 4, 3, C_SWEAT); TLine(X + 22, Y - 4, X + 22, Y - 12, 1, C_SWEAT);
        Pix(X + 21, Y - 5, C_WHITE);
      End;
    3 :
      Begin
        Ell(X, Y + 14, 9, 5, C_INK); Ell(X, Y + 14, 7, 3, C_MOUTH);
        Disc(X + 4, Y + 20, 6, C_INK); Disc(X + 4, Y + 20, 4, C_TONGUE); Rect(X + 4, Y + 18, X + 4, Y + 22, C_DRED);
      End;
    4 :
      Begin
        For K := 0 To 12 Do
        Begin
          Rect(X - EllW(14, 13, K) - 0, Y + 8 + K, X + EllW(14, 13, K), Y + 8 + K, C_INK);
          If K <= 10 Then Rect(X - EllW(11, 10, K), Y + 9 + K, X + EllW(11, 10, K), Y + 9 + K, C_MOUTH);
        End;
        Rect(X - 10, Y + 9, X + 10, Y + 12, C_WHITE);
        Ell(X + 1, Y + 17, 5, 2, C_TONGUE);
      End;
  End;
End;

Procedure RenderScene;
Var Y, K, X, Mood : LongInt;
Begin
  { cadre en creux }
  Rect(0, 0, SW - 1, 0, C_DGRAY); Rect(0, 0, 0, BH - 1, C_DGRAY);
  Rect(0, BH - 1, SW - 1, BH - 1, C_WHITE); Rect(SW - 1, 0, SW - 1, BH - 1, C_WHITE);
  Rect(1, 1, SW - 2, 1, C_BLACK); Rect(1, 1, 1, BH - 2, C_BLACK);
  Rect(1, BH - 2, SW - 2, BH - 2, C_GRAY); Rect(SW - 2, 1, SW - 2, BH - 2, C_GRAY);
  { ciel, soleil, nuages, collines, herbe }
  For Y := 2 To 309 Do Rect(2, Y, SW - 3, Y, C_SKY + (Y - 2) * 16 Div 308);
  Disc(240, 52, 30, C_SUNG);
  Disc(240, 52, 22, C_SUN);
  Cloud(78, 62, 4); Cloud(150, 30, 3); Cloud(254, 116, 3);
  Ell(70, 326, 150, 46, C_HILL1);
  Ell(262, 334, 120, 40, C_HILL2);
  For Y := 310 To BH - 3 Do Rect(2, Y, SW - 3, Y, C_GRASS + 3 - (Y - 310) * 3 Div 88);
  For K := 0 To 13 Do
  Begin
    X := 10 + K * 20 + (K * 7) Mod 11;
    Y := 368 + (K * 13) Mod 22;
    TLine(X, Y, X - 3, Y - 7, 0, C_GRASS); TLine(X, Y, X, Y - 9, 0, C_GRASS); TLine(X, Y, X + 4, Y - 6, 0, C_GRASS);
  End;
  { potence : ombre, estrade, jambe de force, montant, traverse }
  Ell(132, 360, 120, 9, C_SHADOWG);
  Beam(24, 330, 238, 352, False);
  K := 54;
  While K < 238 Do
  Begin
    Rect(K, 332, K, 350, C_WOOD);
    K := K + 31;
  End;
  Screw(32, 341); Screw(230, 341);
  TLine(66, 112, 120, 54, 9, C_INK);
  TLine(66, 112, 120, 54, 6, C_WOOD + 1);
  TLine(64, 110, 118, 52, 2, C_WOOD + 2);
  Beam(46, 34, 64, 329, True);
  Beam(36, 34, 216, 52, False);
  Screw(55, 43); Screw(55, 320); Screw(84, 95); Screw(112, 61);
  { corde enroulee sur la traverse }
  Rect(182, 30, 198, 56, C_INK);
  Rect(184, 32, 196, 54, C_ROPE);
  For K := 0 To 3 Do Rect(184, 35 + K * 6, 196, 35 + K * 6, C_ROPED);
  If Errors = 0 Then
  Begin
    { noeud coulant vide }
    Rope(190, 56, 132);
    Ring(190, 150, 13, 19, 6, C_INK);
    Ring(190, 150, 11, 17, 3, C_ROPE);
    Disc(190, 131, 6, C_INK); Disc(190, 131, 4, C_ROPE);
  End
  Else
  Begin
    Rope(190, 56, 150);
    If State = S_LOST Then Mood := 3
    Else If State = S_WON Then Mood := 4
    Else If Errors >= 5 Then Mood := 2
    Else If Errors >= 3 Then Mood := 1
    Else Mood := 0;
    If Errors >= 5 Then Leg(-1);
    If Errors >= 6 Then Leg(1);
    If Errors >= 7 Then
    Begin
      Shoe(174, 296, -1); Shoe(206, 296, 1);
    End;
    If Errors >= 2 Then Body;
    If Errors >= 3 Then Arm(-1, State = S_WON);
    If Errors >= 4 Then Arm(1, State = S_WON);
    Neck;
    Noose;
    Head(Mood);
  End;
  Touch(0, 0, SW - 1, BH - 1);
End;

{ ==================================================================== }
{ Partie droite : mot, lettres, clavier                                 }
{ ==================================================================== }

Function LetterAt(I : LongInt) : LongInt;
Begin
  LetterAt := Ord(Secret[I]) - 65;
End;

Function IsShown(I : LongInt) : Boolean;
Begin
  IsShown := Guessed[LetterAt(I)] = 1;
End;

Procedure Heart(X, Y : LongInt; Full : Boolean);
Var K, C, Dx, Dy : LongInt;
Begin
  For Dy := -1 To 1 Do
    For Dx := -1 To 1 Do
    Begin
      Disc(X + 5 + Dx, Y + 5 + Dy, 5, C_INK); Disc(X + 13 + Dx, Y + 5 + Dy, 5, C_INK);
      For K := 0 To 9 Do Rect(X + 9 - (9 - K) + Dx, Y + 7 + K + Dy, X + 9 + (9 - K) + Dx, Y + 7 + K + Dy, C_INK);
    End;
  If Full Then C := C_HEART Else C := C_LGRAY;
  Disc(X + 5, Y + 5, 5, C); Disc(X + 13, Y + 5, 5, C);
  For K := 0 To 9 Do Rect(X + 9 - (9 - K), Y + 7 + K, X + 9 + (9 - K), Y + 7 + K, C);
  If Full Then Rect(X + 4, Y + 3, X + 5, Y + 4, C_WHITE);
End;

{ bouton de Warp 3 : en relief, ou en creux (lettre deja essayee) }
Procedure KeyBox(X, Y, W, H, Face : LongInt; Sunken : Boolean);
Var Lt, Dk, Lt2, Dk2 : LongInt;
Begin
  If Sunken Then
  Begin
    Lt := C_DGRAY; Dk := C_WHITE; Lt2 := C_BLACK; Dk2 := C_GRAY;
  End
  Else
  Begin
    Lt := C_WHITE; Dk := C_BLACK; Lt2 := C_GRAY; Dk2 := C_DGRAY;
  End;
  Rect(X, Y, X + W - 1, Y + H - 1, Face);
  Rect(X, Y, X + W - 1, Y, Lt); Rect(X, Y, X, Y + H - 1, Lt);
  Rect(X, Y + H - 1, X + W - 1, Y + H - 1, Dk); Rect(X + W - 1, Y, X + W - 1, Y + H - 1, Dk);
  Rect(X + 1, Y + 1, X + W - 2, Y + 1, Lt2); Rect(X + 1, Y + 1, X + 1, Y + H - 2, Lt2);
  Rect(X + 1, Y + H - 2, X + W - 2, Y + H - 2, Dk2); Rect(X + W - 2, Y + 1, X + W - 2, Y + H - 2, Dk2);
End;

Procedure KeyPos(I : LongInt; Var X, Y : LongInt);
Var R, C, N : LongInt;
Begin
  R := I Div 7; C := I Mod 7;
  If R = 3 Then N := 5 Else N := 7;
  X := RX + (BW - RX - (N * KeySX - 3)) Div 2 + C * KeySX;
  Y := KeyY + R * KeySY;
End;

Procedure DrawKey(I : LongInt);
Var X, Y, G, F, T : LongInt;
Begin
  KeyPos(I, X, Y);
  G := Guessed[I];
  If G = 1 Then
  Begin
    F := C_KEYG; T := C_WHITE;
  End
  Else If G = 2 Then
  Begin
    F := C_KEYR; T := C_WHITE;
  End
  Else
  Begin
    F := C_GRAY; T := C_BLACK;
  End;
  KeyBox(X, Y, KeyW, KeyH, F, G <> 0);
  If G <> 0 Then FbText(X + 13, Y + 4, Chr(65 + I), T, 2) Else FbText(X + 12, Y + 3, Chr(65 + I), T, 2);
End;

Procedure RenderRight;
Var I, X, Y, C, Tx : LongInt; S : String;
Begin
  Rect(SW, 0, BW - 1, BH - 1, C_GRAY);
  RText(2, 'Bonhomme pendu', C_DBLUE, 2);
  Rect(RX, 38, BW - 4, 38, C_DGRAY); Rect(RX, 39, BW - 4, 39, C_WHITE);
  FbText(RX + 4, 46, 'Niveau : ' + LevelName(LevelI), C_DBLUE, 1);
  S := 'Pointage : ' + IStr(Score);
  FbText(BW - 6 - Length(S) * 8, 46, S, C_BLACK, 1);
  FbText(RX + 4, 64, 'Gagn' + Chr(130) + 'es : ' + IStr(Wins) + '   Perdues : ' + IStr(Losses), C_BLACK, 1);
  S := 'Record : ' + IStr(Best);
  FbText(BW - 6 - Length(S) * 8, 64, S, C_DRED, 1);
  FbText(RX + 4, 82, 'S' + Chr(130) + 'rie : ' + IStr(Streak), C_BLACK, 1);
  { erreurs restantes : coeurs }
  FbText(RX + 4, 108, 'Erreurs restantes : ' + IStr(MaxErr - Errors), C_BLACK, 1);
  For I := 0 To MaxErr - 1 Do Heart(RX + 4 + I * 22, 128, I < MaxErr - Errors);
  { mot : cases }
  Tx := RX + (BW - RX - (WLen * TileS - 3)) Div 2;
  For I := 1 To WLen Do
  Begin
    X := Tx + (I - 1) * TileS; Y := TileY;
    Rect(X + 2, Y + 2, X + TileW + 1, Y + TileH + 1, C_DGRAY);
    Rect(X, Y, X + TileW - 1, Y + TileH - 1, C_INK);
    Rect(X + 1, Y + 1, X + TileW - 2, Y + TileH - 2, C_TILE);
    Rect(X + 1, Y + TileH - 5, X + TileW - 2, Y + TileH - 2, C_TILED);
    If IsShown(I) Then FbText(X + 5, Y + 3, Secret[I], C_DBLUE, 2)
    Else If State = S_LOST Then FbText(X + 5, Y + 3, Secret[I], C_DRED, 2)
    Else Rect(X + 5, Y + TileH - 10, X + TileW - 6, Y + TileH - 8, C_INK);
  End;
  { lettres absentes deja essayees }
  If Wrong = '' Then S := 'Lettres absentes : aucune' Else
  Begin
    S := 'Lettres absentes :';
    For I := 1 To Length(Wrong) Do S := S + ' ' + Wrong[I];
  End;
  FbText(RX + 4, 210, S, C_DRED, 1);
  If State = S_PLAY Then
  Begin
    For I := 0 To 25 Do DrawKey(I);
  End
  Else
  Begin
    { fin du mot }
    KeyBox(RX + 4, KeyY, BW - RX - 10, 156, C_LGRAY, True);
    If State = S_WON Then
    Begin
      RText(KeyY + 14, 'Gagn' + Chr(130) + ' !', C_DGREEN, 2);
      RText(KeyY + 58, 'Le bonhomme est sauv' + Chr(130) + '.', C_BLACK, 1);
      If AutoAll <> 0 Then S := 'D' + Chr(130) + 'monstration : pas de points'
      Else S := '+' + IStr(LastPts) + ' points';
      RText(KeyY + 80, S, C_DBLUE, 1);
    End
    Else
    Begin
      RText(KeyY + 14, 'Perdu !', C_DRED, 2);
      RText(KeyY + 58, 'Le mot ' + Chr(130) + 'tait :', C_BLACK, 1);
      RText(KeyY + 78, Secret, C_DRED, 1);
    End;
    C := C_DGRAY;
    RText(KeyY + 120, 'Clic ou Entr' + Chr(130) + 'e : nouveau mot', C, 1);
  End;
  Touch(SW, 0, BW - 1, BH - 1);
End;

Procedure RenderAll;
Begin
  RenderScene;
  RenderRight;
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
{ Fenetre : barre d'etat, peinture                                      }
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

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, OX - 1, CH - 23, CLR_PALEGRAY);
  FBar(OX + BW, 0, CW - 1, CH - 23, CLR_PALEGRAY);
  FBar(0, 0, CW - 1, OY - 1, CLR_PALEGRAY);
  FBar(0, OY + BH, CW - 1, CH - 23, CLR_PALEGRAY);
  RenderAll;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1;
  DrawStatus;
  LastMsg := Msg;
  Dummy := WinEndPaint(Hps);
End;

{ recopie des zones changees (hors de WM_PAINT) }
Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If DX2 >= DX1 Then BlitRect(Hps, DX1, DY1, DX2, DY2);
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1;
  If Msg <> LastMsg Then
  Begin
    LastMsg := Msg;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

Procedure Refresh;
Begin
  If TestMode <> 0 Then Exit;
  RenderAll;
  Frame1;
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

{ suite de notes (frequences en Hz, separees par des virgules) }
Procedure MakeTune(N : LongInt; Notes : String; Ms, Vol : LongInt);
Var K, F, St, Len0, E : LongInt; S : String;
Begin
  St := NSndBuf; Len0 := 0;
  S := Notes + ',';
  While Pos(',', S) > 0 Do
  Begin
    K := Pos(',', S);
    Val(Copy(S, 1, K - 1), F, E);
    Delete(S, 1, K);
    MakeTone(15, F, F, Ms, Vol);
    Len0 := Len0 + SndLen[15];
  End;
  SndOfs[N] := St; SndLen[N] := Len0; SndPri[N] := SndPrio;
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
  SndPrio := 0; MakeTone(0, 880, 1320, 110, 32);              { bonne lettre }
  SndPrio := 0; MakeTone(1, 220, 150, 220, 36);               { mauvaise lettre }
  SndPrio := 0; MakeTone(2, 600, 600, 30, 20);                { deja essayee }
  SndPrio := 2; MakeTune(3, '523,659,784,1047', 130, 36);     { gagne }
  SndPrio := 2; MakeTune(4, '392,349,311,262', 220, 36);      { perdu }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Partie                                                                }
{ ==================================================================== }

Procedure Shuffle(L : LongInt);
Var K, J, T : LongInt;
Begin
  For K := 0 To NWord - 1 Do BagOrd[L * NWord + K] := K;
  For K := NWord - 1 DownTo 1 Do
  Begin
    J := Rnd(K + 1);
    T := BagOrd[L * NWord + K]; BagOrd[L * NWord + K] := BagOrd[L * NWord + J]; BagOrd[L * NWord + J] := T;
  End;
  BagPos[L] := 0;
End;

Procedure PlayMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur essaie les lettres (Options).'
  Else Msg := 'Trouvez le mot : cliquez sur une lettre ou tapez-la au clavier.';
End;

Procedure SetWord(S : String);
Var K : LongInt;
Begin
  Secret := S;
  WLen := Length(S);
  For K := 0 To 25 Do Guessed[K] := 0;
  Errors := 0; Tried := 0; Wrong := ''; State := S_PLAY; AutoWait := 0; EndWait := 0; Blink := 0;
  PlayMsg;
End;

Procedure NewWord;
Var L : LongInt;
Begin
  L := LevelI;
  If BagPos[L] >= NWord Then Shuffle(L);
  SetWord(Words[L * NWord + BagOrd[L * NWord + BagPos[L]]]);
  Inc(BagPos[L]);
End;

{ nouveau mot demande pendant un mot commence : partie abandonnee }
Procedure Abandon;
Begin
  If (State = S_PLAY) And (Tried > 0) Then
  Begin
    Inc(Losses);
    Streak := 0;
  End;
End;

Procedure Guess(L : LongInt);
Var I, All : LongInt;
Begin
  If (State <> S_PLAY) Or (L < 0) Or (L > 25) Then Exit;
  If Guessed[L] <> 0 Then
  Begin
    Msg := 'La lettre ' + Chr(65 + L) + ' a d' + Chr(130) + 'j' + Chr(133) + ' ' + Chr(130) + 't' + Chr(130) +
           ' essay' + Chr(130) + 'e.';
    PlaySnd(2);
    Exit;
  End;
  Inc(Tried);
  If Pos(Chr(65 + L), Secret) > 0 Then
  Begin
    Guessed[L] := 1;
    All := 1;
    For I := 1 To WLen Do
      If Not IsShown(I) Then All := 0;
    If All <> 0 Then
    Begin
      State := S_WON;
      LastPts := (WLen * 5 + (MaxErr - Errors) * 10) * (LevelI + 1) + Streak * 10;
      If AutoAll <> 0 Then LastPts := 0;
      Score := Score + LastPts;
      If Score > Best Then Best := Score;
      Inc(Wins);
      Inc(Streak);
      Msg := 'Gagn' + Chr(130) + ' ! Le mot est ' + Secret + '.';
      PlaySnd(3);
    End
    Else
    Begin
      Msg := 'Oui, la lettre ' + Chr(65 + L) + ' est dans le mot.';
      PlaySnd(0);
    End;
  End
  Else
  Begin
    Guessed[L] := 2;
    Wrong := Wrong + Chr(65 + L);
    Inc(Errors);
    If Errors >= MaxErr Then
    Begin
      State := S_LOST;
      Inc(Losses);
      Streak := 0;
      Msg := 'Perdu ! Le mot ' + Chr(130) + 'tait ' + Secret + '.';
      PlaySnd(4);
    End
    Else
    Begin
      Msg := 'Non, pas de ' + Chr(65 + L) + ' dans le mot. Erreurs restantes : ' + IStr(MaxErr - Errors) + '.';
      PlaySnd(1);
    End;
  End;
End;

{ demonstration : prochaine lettre frequente pas encore essayee }
Function AutoLetter : LongInt;
Var K, L : LongInt;
Begin
  AutoLetter := -1;
  For K := 1 To Length(Freq) Do
  Begin
    L := Ord(Freq[K]) - 65;
    If Guessed[L] = 0 Then
    Begin
      AutoLetter := L;
      Exit;
    End;
  End;
End;

Procedure NewGame;
Begin
  Abandon;
  Score := 0; Wins := 0; Losses := 0; Streak := 0;
  NewWord;
End;

Procedure TimerTick;
Var B : LongInt;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  { clignement des yeux }
  B := 0;
  If (State = S_PLAY) And (Errors > 0) And (Tick Mod 90 < 4) Then B := 1;
  If B <> Blink Then
  Begin
    Blink := B;
    RenderScene;
  End;
  If AutoAll <> 0 Then
  Begin
    If State = S_PLAY Then
    Begin
      Inc(AutoWait);
      If AutoWait > 18 Then
      Begin
        AutoWait := 0;
        Guess(AutoLetter);
        RenderAll;
      End;
    End
    Else
    Begin
      Inc(EndWait);
      If EndWait > 80 Then
      Begin
        NewWord;
        RenderAll;
      End;
    End;
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
  SetMark(CM_LEVEL0, LevelI = 0); SetMark(CM_LEVEL1, LevelI = 1); SetMark(CM_LEVEL2, LevelI = 2);
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0);
End;

Procedure SetLevel(L : LongInt);
Begin
  Abandon;
  LevelI := L;
  SetMarks;
  NewWord;
  Msg := 'Niveau ' + LevelName(L) + ' : nouveau mot de ' + IStr(WLen) + ' lettres.';
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEWWORD : Begin Abandon; NewWord; End;
    CM_NEWGAME : NewGame;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_LEVEL0 : SetLevel(0);
    CM_LEVEL1 : SetLevel(1);
    CM_LEVEL2 : SetLevel(2);
    CM_AUTO : Begin AutoAll := 1 - AutoAll; AutoWait := 0; EndWait := 0; SetMarks; If State = S_PLAY Then PlayMsg; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Il faut trouver le mot cach' + Chr(130) + ' avant que le bonhomme soit pendu. Chaque case ' +
             'repr' + Chr(130) + 'sente une lettre du mot.' + Chr(10) + Chr(10));
        LAdd('Cliquez sur une lettre du clavier de droite ou tapez-la au clavier. Si elle est dans le mot, ' +
             'elle appara' + Chr(140) + 't dans toutes ses cases et sa touche devient verte. Sinon, sa touche ' +
             'devient rouge et une partie du bonhomme est dessin' + Chr(130) + 'e : t' + Chr(136) + 'te, corps, ' +
             'bras, jambes puis chaussures. A la 7e erreur, c''est perdu. Une lettre d' + Chr(130) + 'j' +
             Chr(133) + ' essay' + Chr(130) + 'e ne compte pas deux fois.' + Chr(10) + Chr(10));
        LAdd('Pointage d''un mot trouv' + Chr(130) + ' : 5 points par lettre et 10 par erreur restante, ' +
             'multipli' + Chr(130) + 's par 1 (D' + Chr(130) + 'butant), 2 (Chevalier) ou 3 (Roi), plus 10 ' +
             'points par mot d' + Chr(130) + 'j' + Chr(133) + ' trouv' + Chr(130) + ' dans la s' + Chr(130) +
             'rie. Demander un nouveau mot apr' + Chr(138) + 's avoir essay' + Chr(130) + ' une lettre compte ' +
             'comme une partie perdue.' + Chr(10) + Chr(10));
        LAdd('Clavier : A ' + Chr(133) + ' Z (lettre), Entr' + Chr(130) + 'e ou Espace (nouveau mot apr' +
             Chr(138) + 's la fin), F2 (nouveau mot), F1 (r' + Chr(138) + 'gles).');
        Dummy := LMsgBox('Bonhomme pendu - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Bonhomme pendu pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype HANGMAN.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Refresh;
End;

Procedure Action;
Begin
  If State <> S_PLAY Then
  Begin
    NewWord;
    Refresh;
  End;
End;

Procedure TypeLetter(L : LongInt);
Begin
  If AutoAll <> 0 Then
  Begin
    Msg := 'D' + Chr(130) + 'monstration en cours : d' + Chr(130) + 'sactivez-la dans le menu Options.';
    Frame1;
    Exit;
  End;
  If State <> S_PLAY Then Exit;
  Guess(L);
  Refresh;
End;

{ lettre tapee (page de codes 850 : lettres accentuees ramenees a la lettre) }
Function BaseLetter(Ch : LongInt) : LongInt;
Begin
  BaseLetter := -1;
  If (Ch >= 65) And (Ch <= 90) Then BaseLetter := Ch - 65
  Else If (Ch >= 97) And (Ch <= 122) Then BaseLetter := Ch - 97
  Else
    Case Ch Of
      130, 136, 137, 138, 144 : BaseLetter := 4;
      131, 132, 133, 134, 160 : BaseLetter := 0;
      135, 128 : BaseLetter := 2;
      139, 140, 141, 161 : BaseLetter := 8;
      147, 148, 149, 162 : BaseLetter := 14;
      129, 150, 151, 163 : BaseLetter := 20;
    End;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk, L : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And (KC_KEYUP Or KC_ALT Or KC_CTRL)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEWWORD); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Action; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    L := BaseLetter(Ch);
    If L >= 0 Then TypeLetter(L)
    Else If Ch = 32 Then Action
    Else KeyChar := False;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, I, Kx, Ky : LongInt;
Begin
  X := Mx - OX; Y := CH - 1 - My - OY;
  If (X < 0) Or (Y < 0) Or (X >= BW) Or (Y >= BH) Then Exit;
  If State <> S_PLAY Then
  Begin
    If AutoAll = 0 Then Action;
    Exit;
  End;
  For I := 0 To 25 Do
  Begin
    KeyPos(I, Kx, Ky);
    If (X >= Kx) And (X < Kx + KeyW) And (Y >= Ky) And (Y < Ky + KeyH) Then
    Begin
      TypeLetter(I);
      Exit;
    End;
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

Procedure GuessStr(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do Guess(Ord(S[K]) - 65);
End;

Procedure RunTests;
Var Ok, K, L, N, Bad, Seen, S1, E1, T1, Dup, I, W, Lo, Le : LongInt; S : String;
Begin
  Ok := 0;
  Score := 0; Best := 0; Wins := 0; Losses := 0; Streak := 0; AutoAll := 0; LevelI := 0;
  { 1 : une bonne lettre tapee deux fois ne compte qu'une fois }
  SetWord('BEBE');
  Guess(1); S1 := State; Guess(1); E1 := State; T1 := Tried;
  Guess(4);
  Log('HANGMAN : TEST1 BEBE apres B ' + IStr(S1) + ' apres B B ' + IStr(E1) + ' essais ' + IStr(T1) + ' apres E ' +
      IStr(State) + ' erreurs ' + IStr(Errors));
  If (S1 = S_PLAY) And (E1 = S_PLAY) And (T1 = 1) And (State = S_WON) And (Errors = 0) Then Inc(Ok);
  { 2 : le sac tire les 32 mots de chaque niveau, le dernier compris }
  Seed := 777; Bad := 0;
  For L := 0 To 2 Do
  Begin
    LevelI := L;
    Shuffle(L);
    Seen := 0;
    For K := 1 To NWord Do
    Begin
      NewWord;
      For I := 0 To NWord - 1 Do
        If Secret = Words[L * NWord + I] Then Seen := Seen Or (1 Shl I);
    End;
    If Seen <> -1 Then Inc(Bad);
  End;
  Log('HANGMAN : TEST2 sac 3 x 32 mots, niveaux incomplets ' + IStr(Bad));
  If Bad = 0 Then Inc(Ok);
  { 3 : 7 erreurs : perdu ; les lettres suivantes sont ignorees }
  SetWord('APEX');
  GuessStr('BCDFGHI');
  K := State;
  GuessStr('APEX');
  Log('HANGMAN : TEST3 APEX erreurs ' + IStr(Errors) + ' etat ' + IStr(K) + ' absentes ' + Wrong + ' perdues ' +
      IStr(Losses));
  If (Errors = MaxErr) And (K = S_LOST) And (State = S_LOST) And (Wrong = 'BCDFGHI') And (Losses = 1) Then Inc(Ok);
  { 4 : pointage (Chevalier, CANADA, une erreur : (6 x 5 + 6 x 10) x 2 = 180) }
  Score := 0; Streak := 0; LevelI := 1;
  SetWord('CANADA');
  GuessStr('ZCANAD');
  Log('HANGMAN : TEST4 CANADA etat ' + IStr(State) + ' erreurs ' + IStr(Errors) + ' points ' + IStr(Score));
  If (State = S_WON) And (Errors = 1) And (Score = 180) Then Inc(Ok);
  { 5 : mots : A a Z seulement, pas de doublon dans un niveau }
  Bad := 0; Dup := 0;
  For W := 0 To 3 * NWord - 1 Do
  Begin
    S := Words[W];
    If (Length(S) < 2) Or (Length(S) > 12) Then Inc(Bad);
    For K := 1 To Length(S) Do
      If (S[K] < 'A') Or (S[K] > 'Z') Then Inc(Bad);
    For K := (W Div NWord) * NWord To W - 1 Do
      If Words[K] = S Then Inc(Dup);
  End;
  Log('HANGMAN : TEST5 mots ' + IStr(3 * NWord) + ' invalides ' + IStr(Bad) + ' doublons ' + IStr(Dup));
  If (Bad = 0) And (Dup = 0) Then Inc(Ok);
  { partie : les 96 mots joues par les lettres frequentes }
  Seed := 1; Score := 0; Best := 0; Wins := 0; Losses := 0; Streak := 0; N := 0; Le := 0;
  For L := 0 To 2 Do
  Begin
    LevelI := L;
    Shuffle(L);
    For K := 1 To NWord Do
    Begin
      NewWord;
      Lo := 0;
      While (State = S_PLAY) And (Lo < 40) Do
      Begin
        Guess(AutoLetter);
        Inc(Lo);
      End;
      Le := Le + Errors;
      Inc(N);
    End;
  End;
  Log('HANGMAN : PARTIE mots ' + IStr(N) + ' gagnes ' + IStr(Wins) + ' perdus ' + IStr(Losses) + ' erreurs ' +
      IStr(Le) + ' pointage ' + IStr(Score));
  Log('HANGMAN : ' + IStr(Ok) + '/5 essais reussis');
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
  Flg, H0, H1, H2, H3, ScrW, ScrH, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  InDlg := 0;
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LastMsg := ''; AutoAll := 0; Best := 0; Tick := 0; Blink := 0;
  Client := 0; Frame := 0; SoundOn := 1; LevelI := 0; SndCur := 0; SndEnd := 0;
  Score := 0; Wins := 0; Losses := 0; Streak := 0; LastPts := 0; TestMode := 0; State := S_PLAY;
  CW := CWant; CH := CHWant;
  DX1 := 0; DY1 := 0; DX2 := -1; DY2 := -1;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (S = '/LEVEL:BEGINNER') Or (S = '/LEVEL:DEBUTANT') Or (S = '/LEVEL:1') Then LevelI := 0;
    If (S = '/LEVEL:KNIGHT') Or (S = '/LEVEL:CHEVALIER') Or (S = '/LEVEL:2') Then LevelI := 1;
    If (S = '/LEVEL:KING') Or (S = '/LEVEL:ROI') Or (S = '/LEVEL:3') Then LevelI := 2;
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
    If S = '/TEST' Then TestMode := 1;
  End;
  If TestMode <> 0 Then
  Begin
    RunTests;
    Halt(0);
  End;
  Shuffle(0); Shuffle(1); Shuffle(2);
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitBmi;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('HANGMAN'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('HANGMAN'), Z2('Bonhomme pendu'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEWWORD, '~Nouveau mot' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_NEWGAME, 'Nouvelle ~partie (pointage ' + Chr(133) + ' z' + Chr(130) + 'ro)');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_LEVEL0, '~D' + Chr(130) + 'butant');
  MItem(MIS_TEXT, 0, CM_LEVEL1, '~Chevalier');
  MItem(MIS_TEXT, 0, CM_LEVEL2, '~Roi');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_AUTO, 'D' + Chr(130) + '~monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos du Bonhomme pendu');
  MenuClose(H2, 2);
  MenuClose(H0, 3);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CWant; Rc[3] := CHWant;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (ScrW - Fw) Div 2; Y := (ScrH - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := ScrH - Fh;
  SetMarks;
  NewWord;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 40);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
