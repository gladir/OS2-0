{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: CRAPS - Craps, jeu de des de casino pour le Presentation
                Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program CRAPS;

{$R-,S-,I-}

{ Compilation : OS2PC CRAPS.PAS   (produit CRAPS.EXE)

  Portage vers OS/2-0 du prototype CRAPS.PAS du depot 7iles (Turbo
  Pascal, BGI en 640 x 480, clavier seulement) : fenetre de Presentation
  Manager avec menus, tapis vert dans une image en memoire recopiee par
  GpiDrawBits (seules les zones qui changent sont recopiees), rebord de
  bois, cases des points 4, 5, SIX, 8, NEUF et 10 avec le palet ON/OFF,
  champ, lignes Passe et Ne passe pas, cote, rack de jetons, des rouges
  dessines en relief qui roulent, rebondissent et tournent sur le tapis,
  bandeau du resultat, boutons, barre d'etat et apparence d'OS/2 Warp 3.

  Comme le prototype : au premier lancer, 7 ou 11 gagnent (naturel), 2, 3
  ou 12 perdent (craps), les autres totaux deviennent le point ; on
  relance jusqu'a refaire le point (gagne) ou sortir un 7 (perdu). Les
  jetons valent 5, 10, 25, 50 et 100 (touches 1 a 5, comme le prototype).
  Ce qui est corrige : un 11 pendant la phase du point faisait perdre (il
  etait traite comme un 7) ; la mise pouvait changer entre le premier
  lancer et le point ; apres un coup gagne ou perdu il fallait appuyer
  sur N pour rejouer ; rien n'arretait la partie sans argent ; le
  prototype retirait la mise du solde seulement en cas de perte.
  Ce qui s'ajoute : mises de casino posees en jetons sur le tapis (la
  ligne de passe, la ligne Ne passe pas ou le 12 est nul, le champ paye
  sur un seul lancer avec le 2 et le 12 payes double, la cote derriere
  la ligne de passe payee au juste prix : 2 pour 1 sur 4 et 10, 3 pour 2
  sur 5 et 9, 6 pour 5 sur 6 et 8, jusqu'au double de la mise de passe),
  solde de depart de 1000 $, mise precedente rejouee d'une touche,
  statistiques (lancers, points), record de la seance, demonstration
  (l'ordinateur mise et lance), bruitages.

  Souris : cliquer un jeton du rack (valeur), puis une zone du tapis pour
  y poser ce jeton ; boutons sous le tapis. Clavier : 1 a 5, + et -
  (jeton), P (passe), D (ne passe pas), C (champ), O (cote), Espace ou
  Entree (lancer les des), R (rejouer la mise precedente), Retour arriere
  (effacer les mises), F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (demonstration) ; /NOSOUND ; /TEST (essais
  du reglement, puis 600 lancers joues par l'ordinateur, resultat sur le
  port serie COM1). }

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
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_SPACE = $10; VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_ROLL = 102; CM_REBET = 103; CM_CLEAR = 104; CM_QUIT = 105;
  CM_AUTO = 201; CM_SOUND = 202; CM_FAST = 203;
  CM_RULES = 301; CM_ABOUT = 302;
  { image du tapis }
  BW = 608; BH = 368; OX = 8; OY = 8;
  CWant = 624; CHWant = 436;
  BtnY = 382; BtnW = 148; BtnH = 26;
  { zones de mise }
  Z_PASS = 0; Z_DONT = 1; Z_FIELD = 2; Z_ODDS = 3;
  { disposition (coordonnees de l'image, Y vers le bas) }
  PbX = 154; PbY = 18; PbW = 72; PbH = 48;         { cases des points }
  DaX1 = 152; DaY1 = 72; DaX2 = 587; DaY2 = 188;     { zone de lancer }
  FdX1 = 152; FdY1 = 194; FdX2 = 587; FdY2 = 244;    { champ }
  DpY1 = 250; DpY2 = 276;                            { ne passe pas }
  PsY1 = 282; PsY2 = 318;                            { ligne de passe }
  CoX1 = 430;                                        { cote (a droite de la passe) }
  RkY = 338;                                         { rack des jetons }
  ChipV : Array[0..4] Of LongInt = (5, 10, 25, 50, 100);
  ChipBase : Array[0..4] Of LongInt = ($C8302C, $2C58D0, $2C9C44, $E08C1C, $2A2A2E);
  ChipR = 15;
  StartBank = 1000; MaxZone = 500;
  DieS = 40;
  { couleurs de l'image }
  C_FELT = 0;                                 { 0..15 : tapis (sombre -> clair) }
  C_WOOD = 16;                                { 16..23 : bois }
  C_WHITE = 24; C_BLACK = 25; C_SHADOW = 26; C_GOLD = 27; C_GOLD2 = 28; C_TEXT = 29; C_DIM = 30; C_RED = 31;
  C_PLAQUE = 32; C_BANNER = 33; C_GRAY = 34; C_LINE = 35; C_YEL = 36; C_GREEN = 37; C_PUCK = 38; C_PUCK2 = 39;
  C_DIE = 40;                                 { 40..47 : des rouges (sombre -> clair) }
  C_PIP = 48; C_PIP2 = 49; C_DIEEDGE = 50;
  C_CHIP = 64;                                { 64 + jeton * 4 + (0 fond, 1 sombre, 2 clair, 3 liseret) }
  C_TRANS = 255;
  { etats }
  P_BET = 0; P_ROLL = 1; P_OVER = 2;
  SndRate = 11025;

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back, Prv : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  DieSpr : Array[0..6 * DieS * DieS - 1] Of Byte;
  { partie }
  Bets, LastBets : Array[0..3] Of LongInt;
  Bank, Best, ChipSel, PointN, Phase, Seed, Rolls, Coups, Wins, Losses, PointsSet, PointsMade, SevenOuts : LongInt;
  Naturals, Crapss, FieldWins, LastGain, LastT : LongInt;
  { des en mouvement (positions en 1/16 de point) }
  DX, DY, DVX, DVY, DFace, DFinal, DRest : Array[0..1] Of LongInt;
  DAng, DSpin, DTgt : Array[0..1] Of Real;
  DTgtOn : Array[0..1] Of LongInt;
  AnimF, RestF, Fast, AutoAll, SoundOn, TestMode, Tick, AutoWait, Dirty, BackDirty, LastBtn : LongInt;
  Banner, Banner2, Msg, LastMsg : String;
  BannerC : LongInt;
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
  PLong = ^LongInt;

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

Function Dollars(V : LongInt) : String;
Begin
  Dollars := IStr(V) + ' $';
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
{ Regles : reglement d'un lancer                                        }
{ ==================================================================== }

Function IsPointNum(T : LongInt) : Boolean;
Begin
  IsPointNum := (T = 4) Or (T = 5) Or (T = 6) Or (T = 8) Or (T = 9) Or (T = 10);
End;

{ gain de la cote (au juste prix) pour une mise S sur le point P }
Function OddsPay(P, S : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If (P = 4) Or (P = 10) Then R := 2 * S
  Else If (P = 5) Or (P = 9) Then R := 3 * S Div 2
  Else If (P = 6) Or (P = 8) Then R := 6 * S Div 5;
  OddsPay := R;
End;

Function TotalBets : LongInt;
Begin
  TotalBets := Bets[0] + Bets[1] + Bets[2] + Bets[3];
End;

{ reglement des mises apres un lancer de total T. Les jetons poses ont
  deja quitte le solde : une mise gagnee revient avec son gain, une mise
  nulle revient seule, une mise perdue reste au casino. LastGain : gain
  net du lancer ; le texte du resultat va dans Banner, Banner2 et Msg. }
Procedure Settle(T : LongInt);
Var Ret, Lost, R, Before : LongInt; S : String;
Begin
  Ret := 0; Lost := 0; Before := TotalBets;
  LastT := T;
  Inc(Rolls);
  S := '';
  { champ : un seul lancer }
  If Bets[Z_FIELD] > 0 Then
  Begin
    If (T = 2) Or (T = 12) Then R := 3 * Bets[Z_FIELD]
    Else If (T = 3) Or (T = 4) Or (T = 9) Or (T = 10) Or (T = 11) Then R := 2 * Bets[Z_FIELD]
    Else R := 0;
    If R > 0 Then Inc(FieldWins) Else Lost := Lost + Bets[Z_FIELD];
    Ret := Ret + R;
    Bets[Z_FIELD] := 0;
  End;
  If PointN = 0 Then
  Begin
    { premier lancer }
    If (T = 7) Or (T = 11) Then
    Begin
      Inc(Naturals);
      Banner := IStr(T) + ' : naturel !';
      S := 'Naturel : la ligne de passe gagne, Ne passe pas perd.';
      If Bets[Z_PASS] > 0 Then Begin Ret := Ret + 2 * Bets[Z_PASS]; Inc(Wins); Inc(Coups); End;
      If Bets[Z_DONT] > 0 Then Begin Lost := Lost + Bets[Z_DONT]; Inc(Losses); Inc(Coups); End;
      Bets[Z_PASS] := 0; Bets[Z_DONT] := 0;
    End
    Else If (T = 2) Or (T = 3) Or (T = 12) Then
    Begin
      Inc(Crapss);
      Banner := IStr(T) + ' : craps !';
      If T = 12 Then S := 'Craps : la ligne de passe perd, le 12 est nul pour Ne passe pas.'
      Else S := 'Craps : la ligne de passe perd, Ne passe pas gagne.';
      If Bets[Z_PASS] > 0 Then Begin Lost := Lost + Bets[Z_PASS]; Inc(Losses); Inc(Coups); End;
      If Bets[Z_DONT] > 0 Then
      Begin
        If T = 12 Then Ret := Ret + Bets[Z_DONT]
        Else Begin Ret := Ret + 2 * Bets[Z_DONT]; Inc(Wins); End;
        Inc(Coups);
      End;
      Bets[Z_PASS] := 0; Bets[Z_DONT] := 0;
    End
    Else
    Begin
      PointN := T;
      Inc(PointsSet);
      Banner := 'Point : ' + IStr(T);
      S := 'Le point est ' + IStr(T) + ' : refaites-le avant le 7.';
    End;
  End
  Else If T = PointN Then
  Begin
    Inc(PointsMade);
    Banner := 'Point r' + Chr(130) + 'ussi !';
    S := 'Point r' + Chr(130) + 'ussi : la ligne de passe et la cote gagnent.';
    If Bets[Z_PASS] > 0 Then Begin Ret := Ret + 2 * Bets[Z_PASS]; Inc(Wins); Inc(Coups); End;
    If Bets[Z_ODDS] > 0 Then Ret := Ret + Bets[Z_ODDS] + OddsPay(PointN, Bets[Z_ODDS]);
    If Bets[Z_DONT] > 0 Then Begin Lost := Lost + Bets[Z_DONT]; Inc(Losses); Inc(Coups); End;
    Bets[Z_PASS] := 0; Bets[Z_DONT] := 0; Bets[Z_ODDS] := 0;
    PointN := 0;
  End
  Else If T = 7 Then
  Begin
    Inc(SevenOuts);
    Banner := '7 : sept perdant';
    S := 'Sept avant le point : la ligne de passe perd, Ne passe pas gagne.';
    If Bets[Z_PASS] > 0 Then Begin Lost := Lost + Bets[Z_PASS]; Inc(Losses); Inc(Coups); End;
    Lost := Lost + Bets[Z_ODDS];
    If Bets[Z_DONT] > 0 Then Begin Ret := Ret + 2 * Bets[Z_DONT]; Inc(Wins); Inc(Coups); End;
    Bets[Z_PASS] := 0; Bets[Z_DONT] := 0; Bets[Z_ODDS] := 0;
    PointN := 0;
  End
  Else
  Begin
    Banner := IStr(T);
    S := 'Ni le point (' + IStr(PointN) + ') ni le 7 : on relance.';
  End;
  Bank := Bank + Ret;
  LastGain := Ret - (Before - TotalBets);
  If Bank + TotalBets > Best Then Best := Bank + TotalBets;
  If LastGain > 0 Then
  Begin
    Banner2 := 'Gain : +' + Dollars(LastGain);
    BannerC := C_YEL;
  End
  Else If LastGain < 0 Then
  Begin
    Banner2 := 'Perte : ' + Dollars(LastGain);
    BannerC := C_WHITE;
  End
  Else
  Begin
    If PointN <> 0 Then Banner2 := 'Point : ' + IStr(PointN) Else Banner2 := '';
    BannerC := C_WHITE;
  End;
  Msg := S;
End;

{ ==================================================================== }
{ Dessin dans la fenetre (boutons, barre d'etat)                        }
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

Procedure InitPal;
Var I, K, C : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 15 Do SetPal(C_FELT + I, Mix($06361A, $1C8A42, I, 15));
  For I := 0 To 7 Do SetPal(C_WOOD + I, Mix($361A08, $B26C32, I, 7));
  SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $101010); SetPal(C_SHADOW, $031C0C); SetPal(C_GOLD, $F0C83C);
  SetPal(C_GOLD2, $A0801C); SetPal(C_TEXT, $D2F2D2); SetPal(C_DIM, $0C4A22); SetPal(C_RED, $E0302A);
  SetPal(C_PLAQUE, $0A2E16); SetPal(C_BANNER, $0E2A16); SetPal(C_GRAY, $9AA49C); SetPal(C_LINE, $E8F4E8);
  SetPal(C_YEL, $FFE04A); SetPal(C_GREEN, $7CF09C); SetPal(C_PUCK, $F4F4F0); SetPal(C_PUCK2, $B4B4B0);
  For I := 0 To 7 Do SetPal(C_DIE + I, Mix($5A0606, $F0443C, I, 7));
  SetPal(C_PIP, $FFFFFF); SetPal(C_PIP2, $D8C8C8); SetPal(C_DIEEDGE, $3C0404);
  For K := 0 To 4 Do
  Begin
    C := ChipBase[K];
    SetPal(C_CHIP + K * 4, C);
    SetPal(C_CHIP + K * 4 + 1, Mix(C, $000000, 5, 10));
    SetPal(C_CHIP + K * 4 + 2, Mix(C, $FFFFFF, 3, 10));
    SetPal(C_CHIP + K * 4 + 3, $F4F4F4);
  End;
End;

Procedure Pix(X, Y, C : LongInt);
Begin
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then Fb[(BH - 1 - Y) * BW + X] := C;
End;

Function GetPix(X, Y : LongInt) : LongInt;
Begin
  GetPix := 0;
  If (X >= 0) And (X < BW) And (Y >= 0) And (Y < BH) Then GetPix := Fb[(BH - 1 - Y) * BW + X];
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

Procedure Frame2(X1, Y1, X2, Y2, C : LongInt);
Begin
  Rect(X1, Y1, X2, Y1, C); Rect(X1, Y2, X2, Y2, C);
  Rect(X1, Y1, X1, Y2, C); Rect(X2, Y1, X2, Y2, C);
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

{ rectangle aux coins arrondis (rayon R) }
Procedure RRect(X1, Y1, X2, Y2, R, C : LongInt);
Var Y, D, W : LongInt;
Begin
  For Y := Y1 To Y2 Do
  Begin
    D := 0;
    If Y < Y1 + R Then D := Y1 + R - Y;
    If Y > Y2 - R Then D := Y - (Y2 - R);
    If D > 0 Then W := R - Round(Sqrt(R * R - D * D + 0.0)) Else W := 0;
    Rect(X1 + W, Y, X2 - W, Y, C);
  End;
End;

{ contour d'un rectangle arrondi (epaisseur 1) }
Procedure RFrame(X1, Y1, X2, Y2, R, C : LongInt);
Var K : LongInt; T : Real;
Begin
  Rect(X1 + R, Y1, X2 - R, Y1, C); Rect(X1 + R, Y2, X2 - R, Y2, C);
  Rect(X1, Y1 + R, X1, Y2 - R, C); Rect(X2, Y1 + R, X2, Y2 - R, C);
  For K := 0 To 90 Do
  Begin
    T := K * Pi / 180;
    Pix(X1 + R - Round(Cos(T) * R), Y1 + R - Round(Sin(T) * R), C);
    Pix(X2 - R + Round(Cos(T) * R), Y1 + R - Round(Sin(T) * R), C);
    Pix(X1 + R - Round(Cos(T) * R), Y2 - R + Round(Sin(T) * R), C);
    Pix(X2 - R + Round(Cos(T) * R), Y2 - R + Round(Sin(T) * R), C);
  End;
End;

{ trait d'ellipse }
Procedure EllipseLine(Cx, Cy, A, B, C : LongInt);
Var K : LongInt; T : Real;
Begin
  For K := 0 To 359 Do
  Begin
    T := K * Pi / 180;
    Pix(Cx + Round(Cos(T) * A), Cy + Round(Sin(T) * B), C);
  End;
End;

{ texte avec la police du VGA, agrandi Sc fois }
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
          Else Rect(X + ((I - 1) * 8 + K) * Sc, Y + R * Sc, X + ((I - 1) * 8 + K) * Sc + Sc - 1, Y + R * Sc + Sc - 1, C);
        End;
    End;
End;

Procedure FbTextSh(X, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(X + 1, Y + 1, S, C_SHADOW, Sc);
  If Sc > 1 Then FbText(X + 2, Y + 2, S, C_SHADOW, Sc);
  FbText(X, Y, S, C, Sc);
End;

Procedure FbCenter(Cx, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbTextSh(Cx - Length(S) * 4 * Sc, Y, S, C, Sc);
End;

{ ==================================================================== }
{ Des et jetons                                                         }
{ ==================================================================== }

{ position des points d'une face (colonne 0..2, rangee 0..2) }
Function PipOn(F, Col, Row : LongInt) : Boolean;
Var R : Boolean;
Begin
  R := False;
  Case F Of
    1 : R := (Col = 1) And (Row = 1);
    2 : R := ((Col = 0) And (Row = 0)) Or ((Col = 2) And (Row = 2));
    3 : R := (Col = Row);
    4 : R := (Col <> 1) And (Row <> 1);
    5 : R := ((Col <> 1) And (Row <> 1)) Or ((Col = 1) And (Row = 1));
    6 : R := (Col <> 1);
  End;
  PipOn := R;
End;

{ faces des des (40 x 40) : coins arrondis, degrade du rouge (clair en
  haut a gauche), liseret sombre, points blancs legerement creuses }
Procedure MakeDice;
Var F, X, Y, D, W, S, Col, Row, Px, Py, Dx, Dy, Base : LongInt;
Begin
  For F := 1 To 6 Do
  Begin
    Base := (F - 1) * DieS * DieS;
    For Y := 0 To DieS - 1 Do
      For X := 0 To DieS - 1 Do
      Begin
        { coins arrondis (rayon 7) }
        Dx := 0; Dy := 0;
        If X < 7 Then Dx := 7 - X;
        If X > DieS - 8 Then Dx := X - (DieS - 8);
        If Y < 7 Then Dy := 7 - Y;
        If Y > DieS - 8 Then Dy := Y - (DieS - 8);
        D := Dx * Dx + Dy * Dy;
        If D > 50 Then S := C_TRANS
        Else
        Begin
          W := 7 - (X + Y) * 6 Div (2 * DieS);
          If W < 0 Then W := 0;
          S := C_DIE + W;
          If (D > 30) Or (X = 0) Or (Y = 0) Or (X = DieS - 1) Or (Y = DieS - 1) Then S := C_DIE;
          If ((X = 1) Or (Y = 1)) And (D <= 30) Then S := C_DIE + 7;
        End;
        DieSpr[Base + Y * DieS + X] := S;
      End;
    For Row := 0 To 2 Do
      For Col := 0 To 2 Do
        If PipOn(F, Col, Row) Then
        Begin
          Px := 9 + Col * 11; Py := 9 + Row * 11;
          If F = 1 Then Begin Px := 20; Py := 20; End;
          For Dy := -5 To 5 Do
            For Dx := -5 To 5 Do
            Begin
              D := Dx * Dx + Dy * Dy;
              If D <= 20 Then
              Begin
                If (Dx + Dy >= 3) Then S := C_PIP2 Else S := C_PIP;
                If D > 14 Then S := C_DIE + 1;
                If (D > 14) And (Dx + Dy < 0) Then S := C_DIE;
                If F = 1 Then
                Begin
                  If D <= 14 Then S := C_PIP;
                End;
                DieSpr[Base + (Py + Dy) * DieS + Px + Dx] := S;
              End;
            End;
          { l'as : un point plus gros }
          If F = 1 Then
            For Dy := -7 To 7 Do
              For Dx := -7 To 7 Do
              Begin
                D := Dx * Dx + Dy * Dy;
                If D <= 42 Then
                Begin
                  If D > 30 Then S := C_DIE Else If Dx + Dy >= 5 Then S := C_PIP2 Else S := C_PIP;
                  DieSpr[Base + (Py + Dy) * DieS + Px + Dx] := S;
                End;
              End;
        End;
  End;
End;

{ un de tourne de l'angle A (radians) centre en (Cx, Cy) ; Mode 0 :
  ombre, 1 : epaisseur, 2 : face }
Procedure DieLayer(Cx, Cy, F : LongInt; A : Real; Mode : LongInt);
Var Ci, Si, Dx, Dy, Sx, Sy, V, Base, X, Y : LongInt;
Begin
  Ci := Round(Cos(A) * 65536); Si := Round(Sin(A) * 65536);
  Base := (F - 1) * DieS * DieS;
  For Dy := -29 To 29 Do
  Begin
    Y := Cy + Dy;
    If (Y >= 0) And (Y < BH) Then
      For Dx := -29 To 29 Do
      Begin
        Sx := Dx * Ci + Dy * Si + 20 * 65536;
        Sy := Dy * Ci - Dx * Si + 20 * 65536;
        If (Sx >= 0) And (Sy >= 0) Then
        Begin
          Sx := Sx Div 65536; Sy := Sy Div 65536;
          If (Sx < DieS) And (Sy < DieS) Then
          Begin
            V := DieSpr[Base + Sy * DieS + Sx];
            If V <> C_TRANS Then
            Begin
              X := Cx + Dx;
              If Mode = 0 Then V := C_SHADOW Else If Mode = 1 Then V := C_DIEEDGE;
              If (X >= 0) And (X < BW) Then Fb[(BH - 1 - Y) * BW + X] := V;
            End;
          End;
        End;
      End;
  End;
End;

Procedure DrawDie(Cx, Cy, F : LongInt; A : Real);
Begin
  If (F < 1) Or (F > 6) Then F := 1;
  DieLayer(Cx + 6, Cy + 7, F, A, 0);
  DieLayer(Cx + 2, Cy + 3, F, A, 1);
  DieLayer(Cx + 1, Cy + 2, F, A, 1);
  DieLayer(Cx, Cy, F, A, 2);
End;

{ jeton vu de dessus (K : 0..4) ; R : rayon }
Procedure DrawChip(Cx, Cy, K, R : LongInt; Lbl : Boolean);
Var I, B : LongInt; T : Real; S : String;
Begin
  B := C_CHIP + K * 4;
  Disc(Cx, Cy, R, B + 1);
  Disc(Cx, Cy, R - 1, B);
  { liserets du bord }
  For I := 0 To 7 Do
  Begin
    T := I * Pi / 4 + Pi / 8;
    Disc(Cx + Round(Cos(T) * (R - 3)), Cy + Round(Sin(T) * (R - 3)), MaxI(1, R Div 7), B + 3);
  End;
  Disc(Cx, Cy, R - 6, B + 3);
  Disc(Cx, Cy, R - 7, B + 2);
  Disc(Cx, Cy, R - 8, B);
  If Lbl Then
  Begin
    S := IStr(ChipV[K]);
    FbText(Cx - Length(S) * 4 + 1, Cy - 7, S, B + 1, 1);
    FbText(Cx - Length(S) * 4, Cy - 8, S, C_WHITE, 1);
  End;
End;

{ pile de jetons de la somme V posee en (Cx, Cy) ; l'etiquette du
  montant est ecrite a droite (Side 1) ou a gauche (Side -1) }
Procedure DrawStack(Cx, Cy, V, Side : LongInt);
Var K, N, Y, W, M : LongInt; S : String;
Begin
  If V <= 0 Then Exit;
  W := V; Y := Cy; N := 0;
  For K := 4 DownTo 0 Do
    While (W >= ChipV[K]) And (N < 9) Do
    Begin
      Disc(Cx + 2, Y + 3, ChipR, C_SHADOW);
      DrawChip(Cx, Y, K, ChipR, False);
      W := W - ChipV[K];
      Y := Y - 3; Inc(N);
    End;
  { le jeton du dessus porte sa valeur }
  M := 0;
  For K := 0 To 4 Do
    If ChipV[K] <= V Then M := K;
  S := Dollars(V);
  If Side = 0 Then
  Begin
    { etiquette au-dessus de la pile }
    W := Length(S) * 8 + 10;
    Y := Y + 3 - ChipR - 2;
    RRect(Cx - W Div 2, Y - 18, Cx + W Div 2, Y, 7, C_GOLD2);
    RRect(Cx - W Div 2 + 1, Y - 17, Cx + W Div 2 - 1, Y - 1, 6, C_PLAQUE);
    FbText(Cx - Length(S) * 4, Y - 17, S, C_WHITE, 1);
  End
  Else If Side > 0 Then
  Begin
    RRect(Cx + 18, Cy - 9, Cx + 18 + Length(S) * 8 + 9, Cy + 9, 7, C_GOLD2);
    RRect(Cx + 19, Cy - 8, Cx + 17 + Length(S) * 8 + 9, Cy + 8, 6, C_PLAQUE);
    FbText(Cx + 23, Cy - 7, S, C_WHITE, 1);
  End
  Else
  Begin
    RRect(Cx - 27 - Length(S) * 8, Cy - 9, Cx - 18, Cy + 9, 7, C_GOLD2);
    RRect(Cx - 26 - Length(S) * 8, Cy - 8, Cx - 19, Cy + 8, 6, C_PLAQUE);
    FbText(Cx - 22 - Length(S) * 8, Cy - 7, S, C_WHITE, 1);
  End;
End;

{ ==================================================================== }
{ Tapis                                                                 }
{ ==================================================================== }

Function ChipX(K : LongInt) : LongInt;
Begin
  ChipX := 330 + K * 52;
End;

Function PbLabel(I : LongInt) : String;
Var S : String;
Begin
  Case I Of
    0 : S := '4'; 1 : S := '5'; 2 : S := 'SIX'; 3 : S := '8'; 4 : S := 'NEUF'; 5 : S := '10';
  Else S := '';
  End;
  PbLabel := S;
End;

Function PbNum(I : LongInt) : LongInt;
Var R : LongInt;
Begin
  Case I Of
    0 : R := 4; 1 : R := 5; 2 : R := 6; 3 : R := 8; 4 : R := 9; 5 : R := 10;
  Else R := 0;
  End;
  PbNum := R;
End;

{ decor fixe : tapis, rebord de bois, inscriptions }
Procedure RenderBack;
Var X, Y, D, S, N, K, X1 : LongInt; Dx, Dy : Real;
Begin
  N := 7;
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      Dx := (X - BW Div 2) / (BW * 0.60); Dy := (Y - BH Div 2) / (BH * 0.75);
      D := Round(Sqrt(Dx * Dx + Dy * Dy) * 15);
      N := (N * 1103515245 + 12345) And $7FFFFFFF;
      S := 14 - D + ((N Shr 16) And 1);
      If S < 1 Then S := 1;
      If S > 15 Then S := 15;
      Fb[(BH - 1 - Y) * BW + X] := C_FELT + S;
    End;
  { rebord de bois arrondi }
  For K := 0 To 10 Do
  Begin
    If K < 3 Then S := C_WOOD + 2 + K * 2 Else S := C_WOOD + MaxI(1, 7 - (K - 3) Div 2);
    RFrame(K, K, BW - 1 - K, BH - 1 - K, 16 - K Div 2, S);
    RFrame(K, K + 1, BW - 1 - K, BH - 1 - K, 16 - K Div 2, S);
  End;
  RFrame(11, 11, BW - 12, BH - 12, 10, C_SHADOW);
  RFrame(12, 12, BW - 13, BH - 13, 10, C_DIM);
  { plaque du solde }
  RRect(20, 20, 145, 246, 8, C_GOLD2);
  RRect(22, 22, 143, 244, 7, C_PLAQUE);
  { cases des points }
  For K := 0 To 5 Do
  Begin
    X1 := PbX + K * PbW;
    Frame2(X1, PbY, X1 + PbW, PbY + PbH, C_LINE);
    Frame2(X1 + 1, PbY + 1, X1 + PbW - 1, PbY + PbH - 1, C_DIM);
    Rect(X1 + 2, PbY + 2, X1 + PbW - 2, PbY + PbH - 2, C_FELT + 7);
    FbCenter(X1 + PbW Div 2 + 1, PbY + 8, PbLabel(K), C_WHITE, 2);
  End;
  { zone de lancer : logo grave dans le tapis }
  RFrame(DaX1, DaY1, DaX2, DaY2, 10, C_DIM);
  FbText(DaX1 + (DaX2 - DaX1 - 5 * 32) Div 2 + 2, DaY1 + 34, 'CRAPS', C_DIM, 4);
  FbText(DaX1 + (DaX2 - DaX1 - 5 * 32) Div 2, DaY1 + 32, 'CRAPS', C_FELT + 4, 4);
  { champ }
  RRect(FdX1, FdY1, FdX2, FdY2, 10, C_LINE);
  RRect(FdX1 + 2, FdY1 + 2, FdX2 - 2, FdY2 - 2, 9, C_FELT + 9);
  FbTextSh(FdX1 + 12, FdY1 + 4, 'CHAMP', C_YEL, 2);
  FbText(FdX1 + 14, FdY1 + 32, 'un lancer', C_TEXT, 1);
  X1 := FdX1 + 118;
  FbCenter(X1, FdY1 + 3, '2', C_WHITE, 2);
  EllipseLine(X1, FdY1 + 18, 15, 15, C_YEL);
  FbCenter(X1 + 40, FdY1 + 3, '3', C_WHITE, 2);
  FbCenter(X1 + 76, FdY1 + 3, '4', C_WHITE, 2);
  FbCenter(X1 + 112, FdY1 + 3, '9', C_WHITE, 2);
  FbCenter(X1 + 152, FdY1 + 3, '10', C_WHITE, 2);
  FbCenter(X1 + 196, FdY1 + 3, '11', C_WHITE, 2);
  FbCenter(X1 + 240, FdY1 + 3, '12', C_WHITE, 2);
  EllipseLine(X1 + 240, FdY1 + 18, 21, 15, C_YEL);
  FbCenter(X1, FdY1 + 34, 'x2', C_YEL, 1);
  FbCenter(X1 + 240, FdY1 + 34, 'x2', C_YEL, 1);
  { ne passe pas }
  RRect(20, DpY1, BW - 21, DpY2, 6, C_LINE);
  RRect(22, DpY1 + 2, BW - 23, DpY2 - 2, 5, C_FELT + 8);
  FbTextSh(34, DpY1 + 5, 'NE PASSE PAS', C_WHITE, 1);
  FbTextSh(150, DpY1 + 5, '- le 12 est nul -', C_TEXT, 1);
  { ligne de passe et cote }
  RRect(20, PsY1, CoX1 - 4, PsY2, 8, C_LINE);
  RRect(22, PsY1 + 2, CoX1 - 6, PsY2 - 2, 7, C_FELT + 10);
  FbTextSh(34, PsY1 + 3, 'LIGNE DE PASSE', C_WHITE, 2);
  RRect(CoX1 + 2, PsY1, BW - 21, PsY2, 8, C_GOLD);
  RRect(CoX1 + 4, PsY1 + 2, BW - 23, PsY2 - 2, 7, C_FELT + 10);
  FbTextSh(CoX1 + 12, PsY1 + 3, 'COTE', C_GOLD, 1);
  FbText(CoX1 + 12, PsY1 + 18, 'x2 max', C_TEXT, 1);
  { rack des jetons }
  RRect(ChipX(0) - 30, RkY - 18, ChipX(4) + 30, RkY + 17, 8, C_WOOD + 3);
  RRect(ChipX(0) - 27, RkY - 15, ChipX(4) + 27, RkY + 14, 6, C_WOOD);
  For K := 0 To 4 Do Disc(ChipX(K), RkY, ChipR + 2, C_SHADOW);
  FbTextSh(34, RkY - 8, 'Jeton :', C_TEXT, 1);
  Move(Fb, Back, SizeOf(Fb));
  BackDirty := 0;
End;

{ palet : blanc ON sur la case du point, noir OFF sans point }
Procedure DrawPuck(Cx, Cy : LongInt; On : Boolean);
Begin
  Disc(Cx + 2, Cy + 3, 17, C_SHADOW);
  If On Then
  Begin
    Disc(Cx, Cy, 17, C_PUCK2);
    Disc(Cx, Cy, 16, C_PUCK);
    EllipseLine(Cx, Cy, 13, 13, C_PUCK2);
    FbText(Cx - 8, Cy - 8, 'ON', C_BLACK, 1);
  End
  Else
  Begin
    Disc(Cx, Cy, 17, C_GRAY);
    Disc(Cx, Cy, 16, C_BLACK);
    EllipseLine(Cx, Cy, 13, 13, C_GRAY);
    FbText(Cx - 12, Cy - 8, 'OFF', C_WHITE, 1);
  End;
End;

{ bandeau du resultat, en haut de la zone de lancer (les des roulent
  en dessous) : le texte en grand, le gain ou la perte a droite }
Procedure DrawBanner;
Var W, X1, Y1 : LongInt;
Begin
  If Banner = '' Then Exit;
  W := Length(Banner) * 16 + 28;
  If Banner2 <> '' Then W := W + Length(Banner2) * 8 + 16;
  X1 := (DaX1 + DaX2 - W) Div 2;
  Y1 := DaY1 + 4;
  RRect(X1, Y1, X1 + W, Y1 + 38, 10, C_GOLD);
  RRect(X1 + 3, Y1 + 3, X1 + W - 3, Y1 + 35, 8, C_BANNER);
  FbTextSh(X1 + 14, Y1 + 3, Banner, BannerC, 2);
  If Banner2 <> '' Then FbTextSh(X1 + 30 + Length(Banner) * 16, Y1 + 12, Banner2, C_TEXT, 1);
End;

{ la scene entiere dans Fb }
Procedure RenderScene;
Var K, I, X1, Y : LongInt; S : String;
Begin
  If BackDirty <> 0 Then RenderBack;
  Move(Back, Fb, SizeOf(Fb));
  { case du point }
  For K := 0 To 5 Do
    If PbNum(K) = PointN Then
    Begin
      X1 := PbX + K * PbW;
      { le palet ON couvre le chiffre, comme sur une vraie table }
      Rect(X1 + 2, PbY + 2, X1 + PbW - 2, PbY + PbH - 2, C_FELT + 11);
      Frame2(X1 + 2, PbY + 2, X1 + PbW - 2, PbY + PbH - 2, C_YEL);
      Frame2(X1 + 3, PbY + 3, X1 + PbW - 3, PbY + PbH - 3, C_GOLD2);
      DrawPuck(X1 + PbW Div 2, PbY + PbH Div 2, True);
    End;
  { plaque : solde, record, point, statistiques }
  FbTextSh(32, 30, 'Solde', C_GOLD, 1);
  S := IStr(Bank);
  FbTextSh(32, 48, S, C_WHITE, 2);
  FbText(36 + Length(S) * 16, 64, '$', C_WHITE, 1);
  FbTextSh(32, 86, 'Sur le tapis', C_GOLD, 1);
  FbTextSh(32, 102, Dollars(TotalBets), C_WHITE, 1);
  FbTextSh(32, 124, 'Point', C_GOLD, 1);
  If PointN = 0 Then
  Begin
    DrawPuck(110, 132, False);
    FbTextSh(32, 140, 'aucun', C_TEXT, 1);
  End
  Else FbTextSh(32, 140, IStr(PointN), C_YEL, 1);
  FbTextSh(32, 166, 'Lancers : ' + IStr(Rolls), C_TEXT, 1);
  FbTextSh(32, 184, 'Points : ' + IStr(PointsMade) + '/' + IStr(PointsSet), C_TEXT, 1);
  If Best > 0 Then
  Begin
    FbTextSh(32, 206, 'Record', C_GOLD, 1);
    FbTextSh(32, 222, Dollars(Best), C_WHITE, 1);
  End;
  { jetons du rack : celui choisi est souleve et cercle d'or }
  For K := 0 To 4 Do
    If K = ChipSel Then
    Begin
      Disc(ChipX(K), RkY - 3, ChipR + 3, C_GOLD);
      DrawChip(ChipX(K), RkY - 3, K, ChipR + 1, True);
    End
    Else DrawChip(ChipX(K), RkY, K, ChipR, True);
  FbTextSh(96, RkY - 8, Dollars(ChipV[ChipSel]), C_YEL, 1);
  { mises posees }
  DrawStack(FdX2 - 26, FdY1 + 33, Bets[Z_FIELD], 0);
  DrawStack(CoX1 - 100, DpY1 + 13, Bets[Z_DONT], 1);
  DrawStack(CoX1 - 100, PsY1 + 20, Bets[Z_PASS], 1);
  DrawStack(BW - 46, PsY1 + 20, Bets[Z_ODDS], -1);
  If PointN = 0 Then
  Begin
    { la cote n'est ouverte qu'avec un point }
    For Y := PsY1 + 3 To PsY2 - 3 Do
      If Odd(Y) Then
        For I := CoX1 + 5 To BW - 24 Do
          If Odd(I + Y Div 2) Then Pix(I, Y, C_FELT + 6);
  End;
  { des }
  DrawDie(DX[0] Div 16, DY[0] Div 16, DFace[0], DAng[0]);
  DrawDie(DX[1] Div 16, DY[1] Div 16, DFace[1], DAng[1]);
  If (Phase <> P_ROLL) Then DrawBanner;
End;

{ ==================================================================== }
{ Recopie : seule la zone qui a change depuis la derniere recopie       }
{ ==================================================================== }

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

{ compare Fb a Prv (par mots de 4 octets) et recopie le rectangle qui
  englobe les changements }
Procedure BlitChanged(H : LongInt);
Var R, K, A, B, NW, X1, X2, R1, R2, F, L : LongInt; P, Q : PLong;
Begin
  NW := BW Div 4;
  X1 := NW; X2 := -1; R1 := -1; R2 := -1;
  A := LongInt(@Fb); B := LongInt(@Prv);
  For R := 0 To BH - 1 Do
  Begin
    F := -1; L := -1;
    For K := 0 To NW - 1 Do
    Begin
      P := Pointer(A + K * 4); Q := Pointer(B + K * 4);
      If P^ <> Q^ Then
      Begin
        If F < 0 Then F := K;
        L := K;
        Q^ := P^;
      End;
    End;
    If F >= 0 Then
    Begin
      If R1 < 0 Then R1 := R;
      R2 := R;
      If F < X1 Then X1 := F;
      If L > X2 Then X2 := L;
    End;
    A := A + BW; B := B + BW;
  End;
  If R1 < 0 Then Exit;
  { rangees de Fb : de bas en haut }
  BlitRect(H, X1 * 4, BH - 1 - R2, X2 * 4 + 3, BH - 1 - R1);
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

{ bruit (des qui roulent, jetons) : Hold echantillons par valeur }
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
    { cliquetis : le bruit est module par paquets }
    If ((K Div 300) Mod 3) = 2 Then Env := Env Div 3;
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
  SndPrio := 0; MakeTone(0, 2600, 1900, 40, 30);         { jeton }
  SndPrio := 1; MakeNoise(1, 420, 70, 2);                { des qui roulent }
  SndPrio := 0; MakeNoise(2, 40, 60, 1);                 { rebond }
  SndPrio := 2; MakeTone(3, 520, 1040, 300, 40);         { gagne }
  SndPrio := 2; MakeTone(4, 440, 200, 380, 40);          { perdu }
  SndPrio := 0; MakeTone(5, 300, 260, 90, 30);           { refus }
  SndPrio := 1; MakeTone(6, 880, 880, 120, 30);          { point }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Fenetre : boutons et barre d'etat                                     }
{ ==================================================================== }

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Var Fg : LongInt;
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then Fg := CLR_BLACK Else Fg := CLR_DARKGRAY;
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, Fg, CLR_PALEGRAY);
End;

Function CanRoll : Boolean;
Begin
  CanRoll := (Phase = P_BET) And (AutoAll = 0) And ((PointN <> 0) Or (TotalBets > 0) Or (Bank >= ChipV[0]));
End;

Function CanClear : Boolean;
Begin
  CanClear := (Phase = P_BET) And (AutoAll = 0) And
              ((Bets[Z_FIELD] > 0) Or (Bets[Z_ODDS] > 0) Or ((PointN = 0) And (TotalBets > 0)));
End;

Function CanRebet : Boolean;
Begin
  CanRebet := (Phase = P_BET) And (AutoAll = 0) And (LastBets[0] + LastBets[1] + LastBets[2] > 0);
End;

Function BtnSig : LongInt;
Begin
  BtnSig := Ord(CanRoll) + 2 * Ord(CanClear) + 4 * Ord(CanRebet);
End;

Function BtnX(I : LongInt) : LongInt;
Begin
  BtnX := 8 + I * 152;
End;

Procedure DrawButtons;
Begin
  Button(BtnX(0), BtnY, BtnW, BtnH, 'Lancer les d' + Chr(130) + 's', CanRoll);
  Button(BtnX(1), BtnY, BtnW, BtnH, 'Rejouer la mise', CanRebet);
  Button(BtnX(2), BtnY, BtnW, BtnH, 'Effacer les mises', CanClear);
  Button(BtnX(3), BtnY, BtnW, BtnH, 'Nouvelle partie', True);
  LastBtn := BtnSig;
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
  RenderScene;
  Move(Fb, Prv, SizeOf(Fb));
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawButtons;
  DrawStatus;
  LastMsg := Msg; Dirty := 0;
  Dummy := WinEndPaint(Hps);
End;

{ image, boutons et barre d'etat a jour (hors de WM_PAINT) }
Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  If (Dirty = 0) And (Msg = LastMsg) And (BtnSig = LastBtn) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If Dirty <> 0 Then
  Begin
    RenderScene;
    BlitChanged(Hps);
    Dirty := 0;
  End;
  If BtnSig <> LastBtn Then DrawButtons;
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

Procedure BetMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur mise et lance les d' + Chr(130) + 's.'
  Else If PointN = 0 Then
    Msg := 'Premier lancer : posez un jeton (Passe, Ne passe pas, Champ) puis lancez.'
  Else Msg := 'Point ' + IStr(PointN) + ' : misez la cote ou le champ, puis relancez.';
End;

Procedure PlaceDice;
Begin
  DX[0] := 470 * 16; DY[0] := 154 * 16; DX[1] := 522 * 16; DY[1] := 164 * 16;
  DAng[0] := 0.12; DAng[1] := -0.2;
  DFace[0] := 5; DFace[1] := 2;
End;

Procedure NewGame;
Var K : LongInt;
Begin
  For K := 0 To 3 Do Begin Bets[K] := 0; LastBets[K] := 0; End;
  Bank := StartBank; PointN := 0; Phase := P_BET; ChipSel := 1;
  Rolls := 0; Coups := 0; Wins := 0; Losses := 0; PointsSet := 0; PointsMade := 0; SevenOuts := 0;
  Naturals := 0; Crapss := 0; FieldWins := 0; LastGain := 0;
  If Best < Bank Then Best := Bank;
  Banner := 'Faites vos jeux'; Banner2 := 'Premier lancer'; BannerC := C_YEL;
  AutoWait := 0;
  PlaceDice;
  BetMsg;
  Dirty := 1;
End;

Procedure Refuse(S : String);
Begin
  Msg := S;
  PlaySnd(5);
End;

{ pose le jeton choisi sur la zone Zn ; renvoie Vrai si c'est fait }
Function AddBet(Zn : LongInt) : Boolean;
Var V : LongInt; Ok : Boolean;
Begin
  Ok := False;
  V := ChipV[ChipSel];
  If Phase = P_OVER Then Refuse('Plus d''argent : F2 pour une nouvelle partie.')
  Else If Phase <> P_BET Then Refuse('Les d' + Chr(130) + 's roulent : attendez le r' + Chr(130) + 'sultat.')
  Else If V > Bank Then Refuse('Solde insuffisant pour un jeton de ' + Dollars(V) + '.')
  Else If ((Zn = Z_PASS) Or (Zn = Z_DONT)) And (PointN <> 0) Then
    Refuse('Passe et Ne passe pas se misent avant le premier lancer ; misez la cote.')
  Else If (Zn = Z_ODDS) And (PointN = 0) Then Refuse('La cote se mise quand un point est ' + Chr(130) + 'tabli.')
  Else If (Zn = Z_ODDS) And (Bets[Z_PASS] = 0) Then Refuse('La cote se mise derri' + Chr(138) + 're une mise de passe.')
  Else If (Zn = Z_ODDS) And (Bets[Z_ODDS] + V > 2 * Bets[Z_PASS]) Then
    Refuse('La cote est limit' + Chr(130) + 'e au double de la mise de passe (' + Dollars(2 * Bets[Z_PASS]) + ').')
  Else If Bets[Zn] + V > MaxZone Then Refuse('Mise maximale : ' + Dollars(MaxZone) + ' par case.')
  Else
  Begin
    Bets[Zn] := Bets[Zn] + V;
    Bank := Bank - V;
    Ok := True;
    PlaySnd(0);
    If Banner <> '' Then Begin Banner := ''; Banner2 := ''; End;
    BetMsg;
    Dirty := 1;
  End;
  AddBet := Ok;
End;

Procedure ClearBets;
Var K : LongInt;
Begin
  If Phase <> P_BET Then Exit;
  For K := 0 To 3 Do
    If (K = Z_FIELD) Or (K = Z_ODDS) Or (PointN = 0) Then
    Begin
      Bank := Bank + Bets[K];
      Bets[K] := 0;
    End;
  Msg := 'Mises retir' + Chr(130) + 'es.';
  Dirty := 1;
End;

{ rejoue les mises du coup precedent (passe, ne passe pas, champ) }
Procedure Rebet;
Var K, N : LongInt;
Begin
  If Phase <> P_BET Then Exit;
  N := 0;
  For K := 0 To 2 Do
    If (LastBets[K] > 0) And (Bets[K] = 0) And ((K = Z_FIELD) Or (PointN = 0)) And (LastBets[K] <= Bank) Then
    Begin
      Bets[K] := LastBets[K];
      Bank := Bank - LastBets[K];
      Inc(N);
    End;
  If N > 0 Then
  Begin
    PlaySnd(0);
    Banner := ''; Banner2 := '';
    Msg := 'Mise pr' + Chr(130) + 'c' + Chr(130) + 'dente rejou' + Chr(130) + 'e : ' + Dollars(TotalBets) + ' sur le tapis.';
  End;
  Dirty := 1;
End;

Procedure SelChip(K : LongInt);
Begin
  If (K < 0) Or (K > 4) Then Exit;
  ChipSel := K;
  PlaySnd(0);
  Dirty := 1;
End;

Procedure CheckBroke;
Begin
  If (Bank < ChipV[0]) And (TotalBets = 0) Then
  Begin
    Phase := P_OVER;
    Banner := 'Ruin' + Chr(130) + ' !';
    Banner2 := 'F2 : nouvelle partie';
    BannerC := C_RED;
    Msg := 'Plus d''argent ! Partie termin' + Chr(130) + 'e apr' + Chr(138) + 's ' + IStr(Rolls) + ' lancers.';
  End;
End;

{ fin du lancer : reglement }
Procedure RollDone;
Var T, Before : LongInt;
Begin
  T := DFinal[0] + DFinal[1];
  Before := PointN;
  Settle(T);
  Phase := P_BET;
  If LastGain > 0 Then PlaySnd(3)
  Else If LastGain < 0 Then PlaySnd(4)
  Else If (Before = 0) And (PointN <> 0) Then PlaySnd(6);
  If LastGain <> 0 Then Msg := Msg + '  (' + Banner2 + ')';
  CheckBroke;
  AutoWait := 0;
  Dirty := 1;
End;

{ lance les des (animation, ou tout de suite avec le lancer rapide) }
Procedure Roll;
Var K : LongInt;
Begin
  If Phase = P_OVER Then Begin Refuse('Plus d''argent : F2 pour une nouvelle partie.'); Exit; End;
  If Phase <> P_BET Then Exit;
  If (PointN = 0) And (TotalBets = 0) Then
  Begin
    { comme le prototype : sans mise, le lancer reprend la mise
      precedente ou pose le jeton choisi sur la ligne de passe }
    If LastBets[0] + LastBets[1] + LastBets[2] > 0 Then Rebet;
    If TotalBets = 0 Then
      If Not AddBet(Z_PASS) Then Exit;
  End;
  For K := 0 To 2 Do
    If ((K = Z_FIELD) Or (PointN = 0)) And (Bets[K] > 0) Then LastBets[K] := Bets[K]
    Else If (PointN = 0) Then LastBets[K] := 0;
  If (PointN <> 0) And (Bets[Z_FIELD] = 0) Then LastBets[Z_FIELD] := 0;
  DFinal[0] := 1 + Rnd(6); DFinal[1] := 1 + Rnd(6);
  Banner := ''; Banner2 := '';
  Msg := 'Les d' + Chr(130) + 's roulent...';
  If Fast <> 0 Then
  Begin
    DFace[0] := DFinal[0]; DFace[1] := DFinal[1];
    DX[0] := (200 + Rnd(280)) * 16; DY[0] := (146 + Rnd(22)) * 16;
    DX[1] := DX[0] + (50 + Rnd(30)) * 16; DY[1] := (146 + Rnd(22)) * 16;
    If DX[1] > 556 * 16 Then DX[1] := DX[0] - 60 * 16;
    DAng[0] := (Rnd(40) - 20) / 100; DAng[1] := (Rnd(40) - 20) / 100;
    PlaySnd(2);
    RollDone;
    Exit;
  End;
  Phase := P_ROLL;
  AnimF := 0; RestF := 0;
  For K := 0 To 1 Do
  Begin
    DX[K] := (178 + K * 8) * 16;
    DY[K] := (146 + K * 22) * 16;
    DVX[K] := (210 + Rnd(70)) ;
    DVY[K] := Rnd(50) - 25;
    DSpin[K] := (Rnd(30) + 20) / 100;
    If Odd(K) Then DSpin[K] := -DSpin[K];
    DFace[K] := 1 + Rnd(6);
    DRest[K] := 0; DTgtOn[K] := 0;
  End;
  PlaySnd(1);
  Dirty := 1;
End;

{ une image de l'animation des des }
Procedure StepDice;
Var K, Sp, T : LongInt; Q : Real;
Begin
  Inc(AnimF);
  For K := 0 To 1 Do
    If DRest[K] = 0 Then
    Begin
      DX[K] := DX[K] + DVX[K]; DY[K] := DY[K] + DVY[K];
      If DX[K] > (DaX2 - 30) * 16 Then Begin DX[K] := (DaX2 - 30) * 16; DVX[K] := -DVX[K] * 6 Div 10; PlaySnd(2); End;
      If DX[K] < (DaX1 + 30) * 16 Then Begin DX[K] := (DaX1 + 30) * 16; DVX[K] := -DVX[K] * 6 Div 10; End;
      If DY[K] > 170 * 16 Then Begin DY[K] := 170 * 16; DVY[K] := -DVY[K] * 7 Div 10; End;
      If DY[K] < 144 * 16 Then Begin DY[K] := 144 * 16; DVY[K] := -DVY[K] * 7 Div 10; End;
      DVX[K] := DVX[K] * 93 Div 100; DVY[K] := DVY[K] * 93 Div 100;
      Sp := Abs(DVX[K]) + Abs(DVY[K]);
      DAng[K] := DAng[K] + DSpin[K] * Sp / 200;
      If Sp > 48 Then
      Begin
        If AnimF Mod 3 = 0 Then
        Begin
          T := 1 + Rnd(6);
          If T = DFace[K] Then T := 7 - T;
          DFace[K] := T;
        End;
      End
      Else
      Begin
        DFace[K] := DFinal[K];
        If DTgtOn[K] = 0 Then
        Begin
          { le de se couche presque droit }
          Q := Round(DAng[K] / (Pi / 2)) * (Pi / 2);
          DTgt[K] := Q + (Rnd(30) - 15) / 100;
          DTgtOn[K] := 1;
        End;
        DAng[K] := DAng[K] + (DTgt[K] - DAng[K]) * 0.25;
        If Sp < 6 Then DRest[K] := 1;
      End;
    End;
  { les deux des ne se chevauchent pas }
  If (Abs(DX[0] - DX[1]) < 46 * 16) And (Abs(DY[0] - DY[1]) < 46 * 16) Then
  Begin
    If DX[0] < DX[1] Then T := 1 Else T := -1;
    DX[0] := DX[0] - T * 24; DX[1] := DX[1] + T * 24;
    Sp := DVX[0]; DVX[0] := DVX[1]; DVX[1] := Sp;
    If (DRest[0] <> 0) And (DRest[1] <> 0) Then
    Begin
      DRest[0] := 0; DRest[1] := 0;
      DVX[0] := -T * 30; DVX[1] := T * 30;
    End;
  End;
  If (DRest[0] <> 0) And (DRest[1] <> 0) Then
  Begin
    Inc(RestF);
    If RestF > 6 Then RollDone;
  End;
  If AnimF > 200 Then
  Begin
    DFace[0] := DFinal[0]; DFace[1] := DFinal[1];
    RollDone;
  End;
  Dirty := 1;
End;

{ demonstration : passe 10 $, cote double, champ un lancer sur trois }
Procedure AutoStep;
Begin
  If Phase = P_OVER Then
  Begin
    Inc(AutoWait);
    If AutoWait > 90 Then NewGame;
    Exit;
  End;
  If Phase <> P_BET Then Exit;
  Inc(AutoWait);
  If AutoWait < 45 Then Exit;
  AutoWait := 0;
  If (PointN = 0) And (Bets[Z_PASS] = 0) Then
  Begin
    ChipSel := 1;
    Dummy := Ord(AddBet(Z_PASS));
    Exit;
  End;
  If (PointN <> 0) And (Bets[Z_PASS] > 0) And (Bets[Z_ODDS] < 2 * Bets[Z_PASS]) And (Bank >= 10) Then
  Begin
    ChipSel := 1;
    Dummy := Ord(AddBet(Z_ODDS));
    Exit;
  End;
  If (Rolls Mod 3 = 1) And (Bets[Z_FIELD] = 0) And (Bank >= 5) Then
  Begin
    ChipSel := 0;
    Dummy := Ord(AddBet(Z_FIELD));
    ChipSel := 1;
    Exit;
  End;
  AutoAll := 0;
  Roll;
  AutoAll := 1;
  Msg := 'D' + Chr(130) + 'monstration : les d' + Chr(130) + 's roulent...';
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If Phase = P_ROLL Then StepDice
  Else If AutoAll <> 0 Then AutoStep;
  Frame1;
End;

{ ==================================================================== }
{ Commandes, clavier, souris                                            }
{ ==================================================================== }

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
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0); SetMark(CM_FAST, Fast <> 0);
End;

Procedure Rules;
Begin
  LClr;
  LAdd('Au premier lancer (sans point), 7 ou 11 font gagner la ligne de passe (naturel) ; 2, 3 ou 12 la font ' +
       'perdre (craps). Tout autre total (4, 5, 6, 8, 9, 10) devient le point, marqu' + Chr(130) + ' par le ' +
       'palet ON : on relance jusqu''' + Chr(133) + ' refaire le point (la passe gagne) ou sortir un 7 (elle ' +
       'perd). Pendant le point, les autres totaux ne d' + Chr(130) + 'cident rien.' + Chr(10) + Chr(10));
  LAdd('Mises (pos' + Chr(130) + 'es en jetons, elles quittent le solde) : Ligne de passe, 1 pour 1 ; Ne ' +
       'passe pas, le contraire, 1 pour 1, le 12 au premier lancer est nul ; Champ, un seul lancer : 3, 4, 9, ' +
       '10 et 11 paient 1 pour 1, 2 et 12 paient double, 5, 6, 7 et 8 perdent ; Cote, derri' + Chr(138) +
       're la passe une fois le point ' + Chr(130) + 'tabli (jusqu''au double de la passe), pay' + Chr(130) +
       'e au juste prix : 2 pour 1 sur 4 et 10, 3 pour 2 sur 5 et 9, 6 pour 5 sur 6 et 8.' + Chr(10) + Chr(10));
  LAdd('Choisissez un jeton (5, 10, 25, 50 ou 100 $) dans le rack, puis cliquez une zone. Lancer sans mise ' +
       'reprend la mise pr' + Chr(130) + 'c' + Chr(130) + 'dente ou pose le jeton sur la passe.' + Chr(10) +
       Chr(10));
  LAdd('Clavier : 1 ' + Chr(133) + ' 5, + et - (jeton), P (passe), D (ne passe pas), C (champ), O (cote), ' +
       'Espace ou Entr' + Chr(130) + 'e (lancer), R (rejouer la mise), Retour arri' + Chr(138) + 're ' +
       '(effacer), F2 (nouvelle partie).');
  Dummy := LMsgBox('Craps - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_ROLL : If AutoAll = 0 Then Roll;
    CM_REBET : If AutoAll = 0 Then Rebet;
    CM_CLEAR : If AutoAll = 0 Then ClearBets;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; AutoWait := 0; If Phase = P_BET Then BetMsg; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_FAST : Begin Fast := 1 - Fast; SetMarks; End;
    CM_RULES : Rules;
    CM_ABOUT : Dummy := Ask('Craps pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype CRAPS.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

Procedure Bet1(Zn : LongInt);
Begin
  If AutoAll <> 0 Then Exit;
  Dummy := Ord(AddBet(Zn));
  Frame1;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
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
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_BACKSPACE Then Begin Command(CM_CLEAR); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Command(CM_ROLL); Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      '1'..'5' : Begin SelChip(Ch - Ord('1')); Frame1; End;
      '+' : Begin SelChip(MinI(4, ChipSel + 1)); Frame1; End;
      '-' : Begin SelChip(MaxI(0, ChipSel - 1)); Frame1; End;
      'P' : Bet1(Z_PASS);
      'D' : Bet1(Z_DONT);
      'C' : Bet1(Z_FIELD);
      'O' : Bet1(Z_ODDS);
      'R' : Command(CM_REBET);
      'E' : Command(CM_CLEAR);
      'N' : Command(CM_NEW);
      ' ' : Command(CM_ROLL);
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, K : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (Y >= BtnY) And (Y < BtnY + BtnH) Then
  Begin
    If (X >= BtnX(0)) And (X < BtnX(0) + BtnW) Then Command(CM_ROLL)
    Else If (X >= BtnX(1)) And (X < BtnX(1) + BtnW) Then Command(CM_REBET)
    Else If (X >= BtnX(2)) And (X < BtnX(2) + BtnW) Then Command(CM_CLEAR)
    Else If (X >= BtnX(3)) And (X < BtnX(3) + BtnW) Then Command(CM_NEW);
    Exit;
  End;
  X := X - OX; Y := Y - OY;
  For K := 0 To 4 Do
    If (X - ChipX(K)) * (X - ChipX(K)) + (Y - RkY) * (Y - RkY) <= (ChipR + 3) * (ChipR + 3) Then
    Begin
      SelChip(K);
      Frame1;
      Exit;
    End;
  If (Y >= FdY1) And (Y <= FdY2) And (X >= FdX1) And (X <= FdX2) Then Bet1(Z_FIELD)
  Else If (Y >= DpY1) And (Y <= DpY2) And (X >= 20) And (X < BW - 20) Then Bet1(Z_DONT)
  Else If (Y >= PsY1) And (Y <= PsY2) And (X >= 20) And (X < CoX1) Then Bet1(Z_PASS)
  Else If (Y >= PsY1) And (Y <= PsY2) And (X >= CoX1) And (X < BW - 20) Then Bet1(Z_ODDS)
  Else If (Y >= DaY1) And (Y <= DaY2) And (X >= DaX1) And (X <= DaX2) Then Command(CM_ROLL);
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

{ mises d'un essai : le tapis est vide, puis les mises sont posees }
Procedure SetBets(P, D, F, O : LongInt);
Begin
  Bets[Z_PASS] := P; Bets[Z_DONT] := D; Bets[Z_FIELD] := F; Bets[Z_ODDS] := O;
  Bank := Bank - P - D - F - O;
End;

{ ajoute une mise sur la zone Zn (partie jouee par l'ordinateur) }
Procedure PutBet(Zn, V : LongInt);
Begin
  Bets[Zn] := Bets[Zn] + V;
  Bank := Bank - V;
End;

Procedure RunTests;
Var Ok, A, B, C, D, E, N, K : LongInt; S : String;
Begin
  Ok := 0;
  { TEST1 : premier lancer (7 et 11 naturels, 2 3 12 craps, 12 nul pour
    Ne passe pas, 6 devient le point) }
  Bank := 100; PointN := 0; SetBets(10, 0, 0, 0); Settle(7); A := Bank;
  Bank := 100; PointN := 0; SetBets(10, 0, 0, 0); Settle(11); B := Bank;
  Bank := 100; PointN := 0; SetBets(10, 10, 0, 0); Settle(3); C := Bank;
  Bank := 100; PointN := 0; SetBets(10, 10, 0, 0); Settle(12); D := Bank;
  Bank := 100; PointN := 0; SetBets(10, 0, 0, 0); Settle(6); E := PointN;
  S := 'TEST1 premier lancer ' + IStr(A) + ' ' + IStr(B) + ' ' + IStr(C) + ' ' + IStr(D) + ' point ' + IStr(E) +
       ' sur le tapis ' + IStr(TotalBets);
  Log('CRAPS : ' + S);
  If (A = 110) And (B = 110) And (C = 100) And (D = 90) And (E = 6) And (TotalBets = 10) Then Inc(Ok);
  { TEST2 : phase du point (11 ne decide plus rien : defaut corrige du
    prototype ; point refait ; sept perdant) }
  Bank := 100; PointN := 6; SetBets(10, 0, 0, 0); Settle(11); A := Bank + TotalBets; B := PointN;
  Settle(6); C := Bank;
  Bank := 100; PointN := 9; SetBets(10, 10, 0, 0); Settle(7); D := Bank; E := PointN;
  S := 'TEST2 point 11 neutre ' + IStr(A) + ' point ' + IStr(B) + ' refait ' + IStr(C) + ' sept ' + IStr(D) +
       ' point ' + IStr(E);
  Log('CRAPS : ' + S);
  If (A = 100) And (B = 6) And (C = 110) And (D = 100) And (E = 0) Then Inc(Ok);
  { TEST3 : champ (2 et 12 doubles, 5 perdant) et cote au juste prix }
  Bank := 100; PointN := 0; SetBets(0, 0, 10, 0); Settle(2); A := Bank;
  Bank := 100; PointN := 6; SetBets(0, 0, 10, 0); Settle(5); B := Bank;
  Bank := 100; PointN := 4; SetBets(10, 0, 0, 20); Settle(4); C := Bank;
  Bank := 100; PointN := 5; SetBets(10, 0, 0, 20); Settle(5); D := Bank;
  Bank := 100; PointN := 8; SetBets(10, 0, 0, 25); Settle(8); E := Bank;
  S := 'TEST3 champ ' + IStr(A) + ' ' + IStr(B) + ' cote 4 ' + IStr(C) + ' cote 5 ' + IStr(D) + ' cote 8 ' + IStr(E);
  Log('CRAPS : ' + S);
  If (A = 120) And (B = 90) And (C = 150) And (D = 140) And (E = 140) And (OddsPay(6, 25) = 30) Then Inc(Ok);
  { PARTIE : 600 lancers, passe 10 $ et cote double, champ 5 $ un lancer
    sur trois, graine fixe }
  Seed := 2026;
  Bank := StartBank; Best := 0; PointN := 0;
  For K := 0 To 3 Do Bets[K] := 0;
  Rolls := 0; Coups := 0; Wins := 0; Losses := 0; PointsSet := 0; PointsMade := 0; SevenOuts := 0;
  Naturals := 0; Crapss := 0; FieldWins := 0;
  N := 0;
  While (N < 600) And (Bank + TotalBets >= 10) Do
  Begin
    If (PointN = 0) And (Bets[Z_PASS] = 0) And (Bank >= 10) Then PutBet(Z_PASS, 10);
    If (PointN <> 0) And (Bets[Z_PASS] > 0) And (Bets[Z_ODDS] = 0) And (Bank >= 20) Then PutBet(Z_ODDS, 20);
    If (N Mod 3 = 0) And (Bank >= 5) Then PutBet(Z_FIELD, 5);
    A := 1 + Rnd(6); B := 1 + Rnd(6);
    Settle(A + B);
    Inc(N);
  End;
  Log('CRAPS : PARTIE lancers ' + IStr(Rolls) + ' coups ' + IStr(Coups) + ' gagnes ' + IStr(Wins) + ' perdus ' +
      IStr(Losses) + ' naturels ' + IStr(Naturals) + ' craps ' + IStr(Crapss) + ' points ' + IStr(PointsMade) +
      '/' + IStr(PointsSet) + ' champ ' + IStr(FieldWins) + ' solde ' + IStr(Bank + TotalBets) + ' record ' +
      IStr(Best));
  Log('CRAPS : ' + IStr(Ok) + '/3 essais reussis');
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
  Msg := ''; LastMsg := '-'; AutoAll := 0; Banner := ''; Banner2 := ''; Best := 0; Tick := 0; Client := 0;
  Frame := 0; SoundOn := 1; Fast := 0; SndCur := 0; SndEnd := 0; TestMode := 0; BackDirty := 1; Dirty := 1;
  CW := CWant; CH := CHWant; Phase := P_BET; PointN := 0; LastBtn := -1; BannerC := C_YEL;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
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
  InitPal;
  MakeDice;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('CRAPS'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('CRAPS'), Z2('Craps'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_ROLL, '~Lancer les d' + Chr(130) + 's' + Chr(9) + 'Espace');
  MItem(MIS_TEXT, 0, CM_REBET, '~Rejouer la mise' + Chr(9) + 'R');
  MItem(MIS_TEXT, 0, CM_CLEAR, '~Effacer les mises' + Chr(9) + 'Retour arr.');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_FAST, 'Lancer ~rapide');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MenuClose(H3, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Craps');
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
