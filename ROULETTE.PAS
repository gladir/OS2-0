{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: ROULETTE - Roulette europeenne (un seul zero) pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program ROULETTE;

{$R-,S-,I-}

{ Compilation : OS2PC ROULETTE.PAS   (produit ROULETTE.EXE)

  Portage vers OS/2-0 du prototype ROULETTE.PAS du depot 7iles (Turbo
  Pascal, BGI en 640 x 480, clavier et souris) : fenetre de Presentation
  Manager avec menus, tapis vert dans une image en memoire recopiee par
  GpiDrawBits (seules les zones qui changent sont recopiees), cylindre
  de roulette dessine avec soin (jante de bois, piste de la bille,
  losanges, numeros, cases et cloisons, cone et croisillon) qui tourne
  vraiment pendant que la bille tourne en sens inverse, ralentit,
  rebondit et tombe dans sa case ; tableau des mises complet, jetons,
  plaque du solde, derniers numeros sortis, boutons, barre d'etat et
  apparence d'OS/2 Warp 3.

  Comme le prototype : roulette europeenne a un zero, 1000 $ au depart ;
  plein (un numero) paye 35 pour 1, rouge, noir, pair, impair, manque
  (1 a 18) et passe (19 a 36) payent 1 pour 1, les douzaines 2 pour 1 ;
  sur le zero, les chances simples perdent.
  Ce qui est corrige : les numeros de la roue etaient dans l'ordre 0 a
  36 (ils sont maintenant dans l'ordre du cylindre europeen, rouges et
  noirs alternes) ; la roue ne tournait pas (une bille jaune tremblait
  au centre) ; manque, passe et les douzaines ne pouvaient pas etre
  misees a la souris ; les touches + et - pouvaient donner une mise
  negative ; Randomize etait appele a chaque lancer ; une case misee
  devenait jaune et cachait sa couleur ; dix mises au plus.
  Ce qui s'ajoute : les colonnes (2 pour 1), des jetons de 1, 5, 10, 25
  et 100 $ poses en piles sur le tapis, curseur au clavier sur tout le
  tapis, mises du coup precedent rejouees d'une touche, numero gagnant
  marque sur le tapis, douze derniers numeros, record de la seance,
  lancer rapide, demonstration (l'ordinateur mise et lance), bruitages.

  Souris : cliquer un jeton de la plaque (valeur), puis une case du tapis
  pour y poser ce jeton ; boutons sous le tapis. Clavier : fleches
  (curseur sur le tapis), Entree (poser le jeton), 1 a 5, + et - (jeton),
  Espace (lancer la bille), R (rejouer la mise precedente), Retour
  arriere (effacer les mises), F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (demonstration) ; /NOSOUND ; /TEST (essais
  du cylindre, des gains, du tapis et de la chute de la bille, puis 500
  lancers joues par l'ordinateur, resultat sur le port serie COM1). }

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
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17;
  VK_DOWN = $18; VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_SPIN = 102; CM_REBET = 103; CM_CLEAR = 104; CM_QUIT = 105;
  CM_AUTO = 201; CM_SOUND = 202; CM_FAST = 203;
  CM_RULES = 301; CM_ABOUT = 302;
  { image du tapis }
  BW = 608; BH = 368; OX = 8; OY = 8;
  CWant = 624; CHWant = 436;
  BtnY = 382; BtnW = 148; BtnH = 26;
  { cylindre : centre, rayons }
  WCx = 122; WCy = 118; WR = 112; RotR = 84;       { RotR : la partie qui tourne }
  WBox = 2 * RotR + 1;
  NSlot = 37; SlotU = 32; Circ = 1184;           { unites d'angle : 37 cases de 32 }
  { tapis des mises }
  TX0 = 20; TZW = 36; TCW = 40; TY0 = 236; TRH = 26; TColW = 48;
  NSpot = 49;
  { plaque }
  PqX1 = 254; PqY1 = 8; PqX2 = 599; PqY2 = 228;
  RkX = 288; RkY = 94; ChipR = 16;
  { animation (images de 30 ms) }
  T_DROP = 92; T_LOCK = 120; T_END = 150;
  StartBank = 1000; MaxSpot = 500;
  ChipV : Array[0..4] Of LongInt = (1, 5, 10, 25, 100);
  ChipBase : Array[0..4] Of LongInt = ($D8D8D0, $C8302C, $2C58D0, $2C9C44, $2A2A2E);
  WheelOrder : Array[0..36] Of LongInt = (0, 32, 15, 19, 4, 21, 2, 25, 17, 34, 6, 27, 13, 36, 11, 30, 8, 23, 10,
                                          5, 24, 16, 33, 1, 20, 14, 31, 9, 22, 18, 29, 7, 28, 12, 35, 3, 26);
  { couleurs de l'image }
  C_FELT = 0;                                 { 0..15 : tapis }
  C_WOOD = 16;                                { 16..23 : bois (sombre -> clair) }
  C_RED = 24; C_BLK = 25; C_ZERO = 26; C_WHITE = 27; C_BLACK = 28; C_SHADOW = 29; C_GOLD = 30; C_GOLD2 = 31;
  C_TEXT = 32; C_PLAQUE = 33; C_LINE = 34; C_POCKR = 35; C_POCKB = 36; C_POCKG = 37; C_CURSOR = 38; C_YEL = 39;
  C_GRAY = 40; C_DIM = 41; C_GREEN = 42;
  C_SILVER = 44;                              { 44..47 : argent }
  C_TRACK = 48;                               { 48..55 : piste de la bille }
  C_BALL = 56;                                { 56..59 : bille }
  C_CHIP = 64;                                { 64 + jeton * 4 + (0 fond, 1 sombre, 2 clair, 3 liseret) }
  { etats }
  S_BET = 0; S_SPIN = 1; S_RESULT = 2; S_OVER = 3;
  SndRate = 11025;

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back, Prv : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { cylindre : texture polaire (rayon x angle) et, pour chaque point du
    carre de la partie tournante, son rayon, son angle et son eclairage }
  Tex : Array[0..(RotR + 1) * Circ - 1] Of Byte;
  WPr, WPa : Array[0..WBox * WBox - 1] Of LongInt;
  WPl : Array[0..WBox * WBox - 1] Of Byte;
  SlotOf : Array[0..36] Of LongInt;              { position du numero sur le cylindre }
  { partie }
  Bets, LastBets : Array[0..NSpot - 1] Of LongInt;
  Hist : Array[0..11] Of LongInt;
  NHist, Bank, Best, ChipSel, State, Seed, Spins, Winning, LastGain, LastStake, CurX, CurY : LongInt;
  NumWins, Reds, Blacks, Zeros : LongInt;
  { animation }
  SpinT, RotI, Fast, AutoAll, SoundOn, TestMode, Tick, AutoWait, Dirty, LastBtn, Target : LongInt;
  Rot, Rot0, BallA, BallR : Real;
  Msg, LastMsg, Line1, Line2 : String;
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
{ Regles : couleurs, cases du tapis, gains                              }
{ ==================================================================== }

Function IsRed(N : LongInt) : Boolean;
Begin
  IsRed := (N = 1) Or (N = 3) Or (N = 5) Or (N = 7) Or (N = 9) Or (N = 12) Or (N = 14) Or (N = 16) Or
           (N = 18) Or (N = 19) Or (N = 21) Or (N = 23) Or (N = 25) Or (N = 27) Or (N = 30) Or (N = 32) Or
           (N = 34) Or (N = 36);
End;

{ cases du tapis : 0..36 les pleins, 37..39 les colonnes (du haut vers
  le bas : 3e, 2e, 1re), 40..42 les douzaines, 43..48 manque, pair,
  rouge, noir, impair, passe }
Function SpotWins(S, N : LongInt) : Boolean;
Var R : Boolean;
Begin
  R := False;
  If S <= 36 Then R := (S = N)
  Else If N >= 1 Then
    Case S Of
      37 : R := (N Mod 3 = 0);
      38 : R := (N Mod 3 = 2);
      39 : R := (N Mod 3 = 1);
      40 : R := (N <= 12);
      41 : R := (N >= 13) And (N <= 24);
      42 : R := (N >= 25);
      43 : R := (N <= 18);
      44 : R := Not Odd(N);
      45 : R := IsRed(N);
      46 : R := Not IsRed(N);
      47 : R := Odd(N);
      48 : R := (N >= 19);
    End;
  SpotWins := R;
End;

{ gain pour 1 (plein 35, colonne et douzaine 2, chances simples 1) }
Function SpotPays(S : LongInt) : LongInt;
Begin
  If S <= 36 Then SpotPays := 35 Else If S <= 42 Then SpotPays := 2 Else SpotPays := 1;
End;

Function SpotName(S : LongInt) : String;
Var R : String;
Begin
  If S <= 36 Then R := 'le ' + IStr(S)
  Else
    Case S Of
      37 : R := 'la 3e colonne';
      38 : R := 'la 2e colonne';
      39 : R := 'la 1re colonne';
      40 : R := 'la 1re douzaine';
      41 : R := 'la 2e douzaine';
      42 : R := 'la 3e douzaine';
      43 : R := 'manque (1-18)';
      44 : R := 'pair';
      45 : R := 'rouge';
      46 : R := 'noir';
      47 : R := 'impair';
      48 : R := 'passe (19-36)';
    Else R := '';
    End;
  SpotName := R;
End;

Function TotalBets : LongInt;
Var K, T : LongInt;
Begin
  T := 0;
  For K := 0 To NSpot - 1 Do T := T + Bets[K];
  TotalBets := T;
End;

{ description du numero sorti : couleur, parite, manque ou passe }
Function Describe(N : LongInt) : String;
Var S : String;
Begin
  If N = 0 Then S := 'Z' + Chr(130) + 'ro'
  Else
  Begin
    If IsRed(N) Then S := 'Rouge' Else S := 'Noir';
    If Odd(N) Then S := S + ', impair' Else S := S + ', pair';
    If N <= 18 Then S := S + ', manque' Else S := S + ', passe';
  End;
  Describe := S;
End;

{ reglement du numero N : les mises gagnantes reviennent avec leur
  gain (elles ont quitte le solde a la pose). LastGain : gain net. }
Procedure Settle(N : LongInt);
Var K, Ret : LongInt;
Begin
  Ret := 0;
  LastStake := TotalBets;
  For K := 0 To NSpot - 1 Do
    If (Bets[K] > 0) And SpotWins(K, N) Then Ret := Ret + Bets[K] * (SpotPays(K) + 1);
  Bank := Bank + Ret;
  LastGain := Ret - LastStake;
  If Bets[N] > 0 Then Inc(NumWins);
  Inc(Spins);
  If N = 0 Then Inc(Zeros) Else If IsRed(N) Then Inc(Reds) Else Inc(Blacks);
  For K := 10 DownTo 1 Do Hist[K] := Hist[K - 1];
  Hist[0] := N;
  If NHist < 12 Then Inc(NHist);
  If Bank > Best Then Best := Bank;
  Winning := N;
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
  For I := 0 To 7 Do SetPal(C_WOOD + I, Mix($2A1206, $B8742E, I, 7));
  SetPal(C_RED, $C81E24); SetPal(C_BLK, $18181C); SetPal(C_ZERO, $10903C); SetPal(C_WHITE, $FFFFFF);
  SetPal(C_BLACK, $101010); SetPal(C_SHADOW, $031C0C); SetPal(C_GOLD, $F0C83C); SetPal(C_GOLD2, $A0801C);
  SetPal(C_TEXT, $D2F2D2); SetPal(C_PLAQUE, $0A2E16); SetPal(C_LINE, $F0F0E0); SetPal(C_POCKR, $8A1014);
  SetPal(C_POCKB, $0A0A0C); SetPal(C_POCKG, $0A6026); SetPal(C_CURSOR, $40E0FF); SetPal(C_YEL, $FFE04A);
  SetPal(C_GRAY, $9AA49C); SetPal(C_DIM, $0C4A22); SetPal(C_GREEN, $7CF09C);
  For I := 0 To 3 Do SetPal(C_SILVER + I, Mix($5A5E66, $F4F6FA, I, 3));
  For I := 0 To 7 Do SetPal(C_TRACK + I, Mix($6A3A14, $E8C68C, I, 7));
  SetPal(C_BALL, $8C8C90); SetPal(C_BALL + 1, $C8C8CC); SetPal(C_BALL + 2, $ECECF0); SetPal(C_BALL + 3, $FFFFFF);
  For K := 0 To 4 Do
  Begin
    C := ChipBase[K];
    SetPal(C_CHIP + K * 4, C);
    SetPal(C_CHIP + K * 4 + 1, Mix(C, $000000, 5, 10));
    SetPal(C_CHIP + K * 4 + 2, Mix(C, $FFFFFF, 3, 10));
    If K = 0 Then SetPal(C_CHIP + 3, $3C64C8) Else SetPal(C_CHIP + K * 4 + 3, $F4F4F4);
  End;
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

Procedure FbMid(Cx, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(Cx - Length(S) * 4 * Sc, Y, S, C, Sc);
End;

{ chiffres etroits (colonnes 1 a 6 de la police, 7 points par chiffre) }
Procedure FbNarrow(Cx, Y : LongInt; S : String; C : LongInt);
Var I, R, K, B, X : LongInt;
Begin
  If FontH = 0 Then Exit;
  X := Cx - (Length(S) * 7 - 1) Div 2;
  For I := 1 To Length(S) Do
    For R := 0 To FontH - 1 Do
    Begin
      B := Font[Ord(S[I]) * FontH + R];
      For K := 1 To 6 Do
        If (B And ($80 Shr K)) <> 0 Then Pix(X + (I - 1) * 7 + K - 1, Y + R, C);
    End;
End;

{ ==================================================================== }
{ Cylindre                                                              }
{ ==================================================================== }

{ angle (0 .. 2 Pi) du point (X, Y), Y vers le bas }
Function Ang(X, Y : Real) : Real;
Var A : Real;
Begin
  If Abs(X) < 0.000001 Then
  Begin
    If Y >= 0 Then A := Pi / 2 Else A := 3 * Pi / 2;
  End
  Else
  Begin
    A := ArcTan(Y / X);
    If X < 0 Then A := A + Pi
    Else If Y < 0 Then A := A + 2 * Pi;
  End;
  Ang := A;
End;

Function SlotColor(N : LongInt) : LongInt;
Begin
  If N = 0 Then SlotColor := C_ZERO Else If IsRed(N) Then SlotColor := C_RED Else SlotColor := C_BLK;
End;

Function PocketColor(N : LongInt) : LongInt;
Begin
  If N = 0 Then PocketColor := C_POCKG Else If IsRed(N) Then PocketColor := C_POCKR Else PocketColor := C_POCKB;
End;

{ texture polaire de la partie tournante : rangee R (rayon en points),
  colonne T (angle, 37 cases de 32 unites). Les valeurs 200..204 sont
  du bois que l'eclairage fixe eclaircit (cone). }
Procedure MakeTexture;
Var R, T, K, Off, N, V, U, D, Gy, Gc, B, Arm, W : LongInt; S : String; Sc : Real;
Begin
  For R := 0 To RotR Do
  Begin
    Sc := Circ / (2 * Pi * MaxI(R, 1));         { unites d'angle par point a ce rayon }
    For T := 0 To Circ - 1 Do
    Begin
      K := T Div SlotU; Off := T Mod SlotU;
      N := WheelOrder[K];
      If R >= 69 Then
      Begin
        { anneau des numeros }
        V := SlotColor(N);
        If (Off = 0) Or (Off = SlotU - 1) Then V := C_GOLD2;
        { chiffres : le haut vers l'exterieur, lus dans le sens des aiguilles }
        S := IStr(N);
        U := Round((Off - SlotU Div 2 + 0.5) / (Circ / (2 * Pi * 77))) + (Length(S) * 6) Div 2;
        Gy := 84 - R + 2;
        If (U >= 0) And (U < Length(S) * 6) And (Gy >= 2) And (Gy <= 14) And (FontH > 0) Then
        Begin
          D := U Div 6; Gc := U Mod 6 + 1;
          B := Font[Ord(S[D + 1]) * FontH + Gy];
          If (B And ($80 Shr Gc)) <> 0 Then V := C_WHITE;
        End;
      End
      Else If R >= 67 Then V := C_GOLD
      Else If R >= 53 Then
      Begin
        { cases ou tombe la bille, cloisons d'argent }
        V := PocketColor(N);
        W := Round(1.6 * Sc);
        If (Off < W) Or (Off >= SlotU - W) Then V := C_SILVER + 3
        Else If (Off < 2 * W) Or (Off >= SlotU - 2 * W) Then V := C_SILVER + 1;
        If (R <= 55) And (V = PocketColor(N)) Then V := C_SILVER;
      End
      Else If R >= 50 Then V := C_SILVER + 2 - Ord(R = 50)
      Else If R >= 13 Then
      Begin
        { cone de bois, croisillon a quatre bras }
        V := 200 + (R - 13) * 4 Div 37;
        Arm := T Mod (Circ Div 4);
        If Arm > Circ Div 8 Then Arm := Circ Div 4 - Arm;
        If (R <= 46) And (Arm <= Round(3.2 * Sc)) Then V := C_GOLD;
        If (R <= 46) And (Arm <= Round(1.2 * Sc)) Then V := C_YEL;
        If (R >= 44) And (R <= 46) And (Arm <= Round(5 * Sc)) Then V := C_GOLD2;
      End
      Else V := C_SILVER + 1;
      Tex[R * Circ + T] := V;
    End;
  End;
End;

{ rayon, angle et eclairage de chaque point de la partie tournante }
Procedure MakeWheelMaps;
Var X, Y, I, R, L : LongInt; D, A : Real;
Begin
  For Y := -RotR To RotR Do
    For X := -RotR To RotR Do
    Begin
      I := (Y + RotR) * WBox + X + RotR;
      D := Sqrt(X * X + Y * Y + 0.0);
      R := Round(D);
      If R > RotR Then WPr[I] := -1
      Else
      Begin
        WPr[I] := R;
        A := Ang(X, Y);
        WPa[I] := Round(A * Circ / (2 * Pi)) Mod Circ;
        { eclairage du cone : clair en haut a gauche }
        If R > 0 Then L := Round(1.6 - 1.8 * (X + Y) / (D * 1.414)) Else L := 2;
        If L < 0 Then L := 0;
        If L > 3 Then L := 3;
        WPl[I] := L;
      End;
    End;
  For I := 0 To 36 Do SlotOf[WheelOrder[I]] := I;
End;

{ partie fixe du cylindre (jante, piste, losanges), dessinee une fois
  dans le decor }
Procedure DrawWheelStatic;
Var X, Y, R, V, K, L : LongInt; D, A : Real;
Begin
  Disc(WCx + 7, WCy + 9, WR, C_SHADOW);
  For Y := -WR To WR Do
    For X := -WR To WR Do
    Begin
      D := Sqrt(X * X + Y * Y + 0.0);
      R := Round(D);
      If (R <= WR) And (R > RotR) Then
      Begin
        L := Round(3.5 - 3.5 * (X + Y) / (MaxI(R, 1) * 1.414));
        If R >= 103 Then
        Begin
          { jante de bois, bord arrondi }
          V := C_WOOD + MinI(7, MaxI(0, 7 - L - Abs(R - 107) Div 2));
          If R = WR Then V := C_WOOD;
        End
        Else If R >= 101 Then V := C_GOLD2 + Ord(R = 102) * (C_GOLD - C_GOLD2)
        Else If R >= 88 Then
        Begin
          { piste de la bille : creusee (plus sombre au milieu) }
          V := C_TRACK + MinI(7, MaxI(0, 7 - L Div 2 - Abs(R - 94) Div 3));
        End
        Else V := C_SILVER + MinI(3, MaxI(0, 3 - L Div 2));
        Pix(WCx + X, WCy + Y, V);
      End;
    End;
  { losanges de la piste (huit deflecteurs) }
  For K := 0 To 7 Do
  Begin
    A := K * Pi / 4 + Pi / 8;
    X := WCx + Round(Cos(A) * 92); Y := WCy + Round(Sin(A) * 92);
    For R := -4 To 4 Do
    Begin
      V := 4 - Abs(R);
      Rect(X - V, Y + R, X + V, Y + R, C_GOLD);
    End;
    Pix(X - 1, Y - 2, C_YEL); Pix(X, Y - 3, C_YEL);
  End;
End;

{ partie tournante du cylindre (decalage RotI) et moyeu }
Procedure DrawWheel;
Var I, X, Y, R, T, V, Row, Base : LongInt;
Begin
  For Y := 0 To WBox - 1 Do
  Begin
    Row := (BH - 1 - (WCy - RotR + Y)) * BW + WCx - RotR;
    Base := Y * WBox;
    For X := 0 To WBox - 1 Do
    Begin
      I := Base + X;
      R := WPr[I];
      If R >= 0 Then
      Begin
        T := WPa[I] + RotI;
        If T >= Circ Then T := T - Circ;
        V := Tex[R * Circ + T];
        If V >= 200 Then V := C_WOOD + MinI(7, V - 200 + WPl[I]);
        Fb[Row + X] := V;
      End;
    End;
  End;
  { moyeu d'argent, reflet fixe }
  Disc(WCx, WCy, 12, C_SILVER);
  Disc(WCx - 1, WCy - 1, 10, C_SILVER + 1);
  Disc(WCx - 2, WCy - 2, 7, C_SILVER + 2);
  Disc(WCx - 4, WCy - 4, 3, C_SILVER + 3);
  Disc(WCx, WCy, 3, C_GOLD);
End;

Procedure DrawBallAt(Bx, By : LongInt);
Begin
  Disc(Bx + 2, By + 2, 5, C_SHADOW);
  Disc(Bx, By, 5, C_BALL);
  Disc(Bx - 1, By - 1, 4, C_BALL + 1);
  Disc(Bx - 1, By - 1, 2, C_BALL + 2);
  Pix(Bx - 2, By - 2, C_BALL + 3); Pix(Bx - 1, By - 2, C_BALL + 3);
End;

{ ==================================================================== }
{ Tapis des mises                                                       }
{ ==================================================================== }

Procedure SpotRect(S : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Var C, R : LongInt;
Begin
  X1 := 0; Y1 := 0; X2 := 0; Y2 := 0;
  If S = 0 Then
  Begin
    X1 := TX0; Y1 := TY0; X2 := TX0 + TZW; Y2 := TY0 + 3 * TRH;
  End
  Else If S <= 36 Then
  Begin
    C := (S - 1) Div 3; R := 2 - (S - 1) Mod 3;
    X1 := TX0 + TZW + C * TCW; Y1 := TY0 + R * TRH; X2 := X1 + TCW; Y2 := Y1 + TRH;
  End
  Else If S <= 39 Then
  Begin
    X1 := TX0 + TZW + 12 * TCW; Y1 := TY0 + (S - 37) * TRH; X2 := X1 + TColW; Y2 := Y1 + TRH;
  End
  Else If S <= 42 Then
  Begin
    X1 := TX0 + TZW + (S - 40) * 4 * TCW; Y1 := TY0 + 3 * TRH; X2 := X1 + 4 * TCW; Y2 := Y1 + 24;
  End
  Else
  Begin
    X1 := TX0 + TZW + (S - 43) * 2 * TCW; Y1 := TY0 + 3 * TRH + 24; X2 := X1 + 2 * TCW; Y2 := Y1 + 24;
  End;
End;

{ case du tapis sous le point (X, Y) de l'image ; -1 : aucune }
Function SpotAt(X, Y : LongInt) : LongInt;
Var S, R, X1, Y1, X2, Y2 : LongInt;
Begin
  R := -1;
  For S := 0 To NSpot - 1 Do
  Begin
    SpotRect(S, X1, Y1, X2, Y2);
    If (X >= X1) And (X < X2) And (Y >= Y1) And (Y < Y2) Then R := S;
  End;
  SpotAt := R;
End;

{ case sous le curseur du clavier (CurX 0..13, CurY 0..4) }
Function CurSpot : LongInt;
Var R : LongInt;
Begin
  If CurY <= 2 Then
  Begin
    If CurX = 0 Then R := 0
    Else If CurX = 13 Then R := 37 + CurY
    Else R := 3 * (CurX - 1) + 3 - CurY;
  End
  Else If CurY = 3 Then R := 40 + (MaxI(1, MinI(12, CurX)) - 1) Div 4
  Else R := 43 + (MaxI(1, MinI(12, CurX)) - 1) Div 2;
  CurSpot := R;
End;

{ jeton vu de dessus }
Procedure DrawChip(Cx, Cy, K, R : LongInt);
Var I, B : LongInt; T : Real;
Begin
  B := C_CHIP + K * 4;
  Disc(Cx, Cy, R, B + 1);
  Disc(Cx, Cy, R - 1, B);
  For I := 0 To 7 Do
  Begin
    T := I * Pi / 4 + Pi / 8;
    Disc(Cx + Round(Cos(T) * (R - 3)), Cy + Round(Sin(T) * (R - 3)), MaxI(1, R Div 7), B + 3);
  End;
  Disc(Cx, Cy, R - 5, B + 3);
  Disc(Cx, Cy, R - 6, B + 2);
  Disc(Cx, Cy, R - 7, B);
End;

{ pile de jetons de la somme V : le jeton du dessus porte le montant }
Procedure DrawStack(Cx, Cy, V : LongInt; Hilite : Boolean);
Var K, N, Y, W, Top : LongInt; S : String;
Begin
  If V <= 0 Then Exit;
  W := V; Y := Cy; N := 0; Top := 0;
  For K := 4 DownTo 0 Do
    While (W >= ChipV[K]) And (N < 5) Do
    Begin
      Disc(Cx + 1, Y + 2, 11, C_SHADOW);
      If Hilite Then Disc(Cx, Y, 13, C_GOLD);
      DrawChip(Cx, Y, K, 11);
      W := W - ChipV[K];
      Top := K;
      Y := Y - 2; Inc(N);
    End;
  S := IStr(V);
  FbNarrow(Cx + 1, Y - 5, S, C_BLACK);
  If Top = 0 Then FbNarrow(Cx, Y - 6, S, C_BLACK) Else FbNarrow(Cx, Y - 6, S, C_WHITE);
End;

{ tapis : cases, inscriptions }
Procedure DrawTableBack;
Var S, X1, Y1, X2, Y2, C, Cx, Cy, K : LongInt; T : String;
Begin
  { ombre et fond du tapis }
  Rect(TX0 + 4, TY0 + 4, TX0 + TZW + 12 * TCW + TColW + 4, TY0 + 3 * TRH + 52, C_SHADOW);
  For S := 0 To NSpot - 1 Do
  Begin
    SpotRect(S, X1, Y1, X2, Y2);
    If (S >= 1) And (S <= 36) Then C := SlotColor(S)
    Else If S = 0 Then C := C_ZERO
    Else C := C_FELT + 9;
    Rect(X1, Y1, X2 - 1, Y2 - 1, C);
    Frame2(X1, Y1, X2, Y2, C_LINE);
    Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
    If S <= 36 Then
    Begin
      T := IStr(S);
      FbText(Cx - Length(T) * 4 + 1, Cy - 7, T, C_BLACK, 1);
      FbText(Cx - Length(T) * 4, Cy - 8, T, C_WHITE, 1);
    End
    Else If S <= 39 Then FbMid(Cx, Cy - 8, '2:1', C_WHITE, 1)
    Else If S <= 42 Then
    Begin
      Case S Of
        40 : T := '1re douzaine';
        41 : T := '2e douzaine';
      Else T := '3e douzaine';
      End;
      FbMid(Cx, Cy - 8, T, C_WHITE, 1);
    End
    Else
    Begin
      Case S Of
        43 : T := '1 - 18';
        44 : T := 'PAIR';
        47 : T := 'IMPAIR';
        48 : T := '19 - 36';
      Else T := '';
      End;
      If T <> '' Then FbMid(Cx, Cy - 8, T, C_WHITE, 1)
      Else
      Begin
        { losange rouge ou noir }
        If S = 45 Then C := C_RED Else C := C_BLK;
        For K := -9 To 9 Do
        Begin
          X1 := (9 - Abs(K)) * 2;
          Rect(Cx - X1 - 1, Cy + K, Cx + X1 + 1, Cy + K, C_LINE);
          If X1 > 1 Then Rect(Cx - X1 + 1, Cy + K, Cx + X1 - 1, Cy + K, C);
        End;
      End;
    End;
  End;
End;

{ ==================================================================== }
{ Decor et scene                                                        }
{ ==================================================================== }

Function ChipX(K : LongInt) : LongInt;
Begin
  ChipX := RkX + K * 44;
End;

Procedure RenderBack;
Var X, Y, D, S, N : LongInt; Dx, Dy : Real;
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
  DrawWheelStatic;
  DrawTableBack;
  { plaque }
  RRect(PqX1, PqY1, PqX2, PqY2, 10, C_GOLD2);
  RRect(PqX1 + 2, PqY1 + 2, PqX2 - 2, PqY2 - 2, 9, C_PLAQUE);
  Rect(PqX1 + 12, 68, PqX2 - 12, 68, C_GOLD2);
  Rect(PqX1 + 12, 158, PqX2 - 12, 158, C_GOLD2);
  For X := 0 To 4 Do Disc(ChipX(X), RkY, ChipR + 2, C_SHADOW);
  Move(Fb, Back, SizeOf(Fb));
End;

{ le numero dans un disque de sa couleur }
Procedure NumDisc(Cx, Cy, R, N, Sc : LongInt);
Var S : String;
Begin
  Disc(Cx, Cy, R, C_LINE);
  Disc(Cx, Cy, R - 1, SlotColor(N));
  S := IStr(N);
  If Sc = 1 Then
  Begin
    If Length(S) = 1 Then FbMid(Cx + 1, Cy - 7, S, C_WHITE, 1) Else FbNarrow(Cx, Cy - 7, S, C_WHITE);
  End
  Else
  Begin
    FbText(Cx - Length(S) * 4 * Sc + 2, Cy - 8 * Sc + 2, S, C_BLACK, Sc);
    FbText(Cx - Length(S) * 4 * Sc, Cy - 8 * Sc, S, C_WHITE, Sc);
  End;
End;

Procedure RenderScene;
Var K, X1, Y1, X2, Y2, Cx, Cy, S0 : LongInt; S : String; W : Boolean;
Begin
  Move(Back, Fb, SizeOf(Fb));
  DrawWheel;
  If (State = S_SPIN) Or (State = S_RESULT) Or (NHist > 0) Then
    DrawBallAt(WCx + Round(Cos(BallA * 2 * Pi / Circ) * BallR), WCy + Round(Sin(BallA * 2 * Pi / Circ) * BallR));
  { mises posees ; numero gagnant marque }
  For K := 0 To NSpot - 1 Do
  Begin
    SpotRect(K, X1, Y1, X2, Y2);
    Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
    W := (State = S_RESULT) And SpotWins(K, Winning);
    If W Then
    Begin
      Frame2(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, C_GOLD);
      Frame2(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2, C_YEL);
    End;
    DrawStack(Cx, Cy + 1, Bets[K], W);
  End;
  If (State = S_RESULT) And (Bets[Winning] = 0) Then
  Begin
    { le marqueur du numero gagnant }
    SpotRect(Winning, X1, Y1, X2, Y2);
    Cx := (X1 + X2) Div 2; Cy := (Y1 + Y2) Div 2;
    Disc(Cx + 1, Cy + 2, 8, C_SHADOW);
    Disc(Cx, Cy, 8, C_GOLD2);
    Disc(Cx, Cy, 6, C_GOLD);
    Disc(Cx - 1, Cy - 2, 2, C_YEL);
  End;
  { curseur du clavier }
  If ((State = S_BET) Or (State = S_RESULT)) And (AutoAll = 0) Then
  Begin
    SpotRect(CurSpot, X1, Y1, X2, Y2);
    Frame2(X1 - 1, Y1 - 1, X2 + 1, Y2 + 1, C_CURSOR);
    Frame2(X1, Y1, X2, Y2, C_CURSOR);
  End;
  { plaque : solde, mises, jetons, derniers numeros, resultat }
  FbTextSh(PqX1 + 14, 14, 'Solde', C_GOLD, 1);
  S := IStr(Bank);
  FbTextSh(PqX1 + 14, 32, S, C_WHITE, 2);
  FbText(PqX1 + 18 + Length(S) * 16, 48, '$', C_WHITE, 1);
  FbTextSh(PqX1 + 190, 14, 'Sur le tapis', C_GOLD, 1);
  FbTextSh(PqX1 + 190, 32, Dollars(TotalBets), C_WHITE, 1);
  If Best > 0 Then FbTextSh(PqX1 + 190, 48, 'Record ' + Dollars(Best), C_GRAY, 1);
  For K := 0 To 4 Do
  Begin
    If K = ChipSel Then
    Begin
      Disc(ChipX(K), RkY - 3, ChipR + 3, C_GOLD);
      DrawChip(ChipX(K), RkY - 3, K, ChipR + 1);
      Cy := RkY - 3;
    End
    Else
    Begin
      DrawChip(ChipX(K), RkY, K, ChipR);
      Cy := RkY;
    End;
    S := IStr(ChipV[K]);
    If K = 0 Then FbMid(ChipX(K) + 1, Cy - 8, S, C_BLACK, 1)
    Else
    Begin
      FbMid(ChipX(K) + 2, Cy - 7, S, C_BLACK, 1);
      FbMid(ChipX(K) + 1, Cy - 8, S, C_WHITE, 1);
    End;
  End;
  FbTextSh(ChipX(4) + 30, 78, 'Jeton', C_GOLD, 1);
  FbTextSh(ChipX(4) + 30, 96, Dollars(ChipV[ChipSel]), C_YEL, 1);
  FbTextSh(PqX1 + 14, 116, 'Derniers num' + Chr(130) + 'ros', C_GOLD, 1);
  For K := 0 To NHist - 1 Do NumDisc(PqX1 + 26 + K * 26, 142, 11, Hist[K], 1);
  { resultat ou consigne }
  If (State = S_RESULT) Or ((State = S_OVER) And (NHist > 0)) Then NumDisc(PqX1 + 40, 194, 26, Winning, 2)
  Else
  Begin
    Disc(PqX1 + 40, 194, 26, C_GOLD2);
    Disc(PqX1 + 40, 194, 24, C_DIM);
    If State = S_SPIN Then FbMid(PqX1 + 41, 186, '...', C_TEXT, 1) Else FbMid(PqX1 + 41, 186, '?', C_TEXT, 1);
  End;
  S0 := PqX1 + 80;
  FbTextSh(S0, 174, Line1, C_YEL, 1);
  If (State = S_RESULT) And (LastGain > 0) Then FbTextSh(S0, 196, Line2, C_GREEN, 1)
  Else FbTextSh(S0, 196, Line2, C_TEXT, 1);
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
  SndPrio := 0; MakeTone(0, 2600, 1900, 40, 30);         { jeton }
  SndPrio := 1; MakeNoise(1, 2200, 28, 6);               { bille qui roule }
  SndPrio := 2; MakeNoise(2, 25, 70, 1);                 { cloison }
  SndPrio := 3; MakeTone(3, 520, 1040, 300, 40);         { gagne }
  SndPrio := 3; MakeTone(4, 440, 200, 380, 40);          { perdu }
  SndPrio := 0; MakeTone(5, 300, 260, 90, 30);           { refus }
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

Function HasLast : Boolean;
Var K : LongInt; R : Boolean;
Begin
  R := False;
  For K := 0 To NSpot - 1 Do
    If LastBets[K] > 0 Then R := True;
  HasLast := R;
End;

Function CanSpin : Boolean;
Begin
  CanSpin := ((State = S_BET) Or (State = S_RESULT)) And (AutoAll = 0) And ((TotalBets > 0) Or HasLast);
End;

Function CanClear : Boolean;
Begin
  CanClear := (State = S_BET) And (AutoAll = 0) And (TotalBets > 0);
End;

Function CanRebet : Boolean;
Begin
  CanRebet := ((State = S_BET) Or (State = S_RESULT)) And (AutoAll = 0) And HasLast;
End;

Function BtnSig : LongInt;
Begin
  BtnSig := Ord(CanSpin) + 2 * Ord(CanClear) + 4 * Ord(CanRebet);
End;

Function BtnX(I : LongInt) : LongInt;
Begin
  BtnX := 8 + I * 152;
End;

Procedure DrawButtons;
Begin
  Button(BtnX(0), BtnY, BtnW, BtnH, 'Lancer la bille', CanSpin);
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
{ Partie : mises, lancer, animation                                     }
{ ==================================================================== }

Procedure BetMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur mise et lance la bille.'
  Else Msg := 'Faites vos jeux : choisissez un jeton puis cliquez une case du tapis ; Espace : lancer.';
  Line1 := 'Faites vos jeux';
  Line2 := 'Mise sur le tapis : ' + Dollars(TotalBets);
End;

Procedure NewGame;
Var K : LongInt;
Begin
  For K := 0 To NSpot - 1 Do Begin Bets[K] := 0; LastBets[K] := 0; End;
  Bank := StartBank; State := S_BET; ChipSel := 2; NHist := 0; Spins := 0; NumWins := 0;
  Reds := 0; Blacks := 0; Zeros := 0; LastGain := 0; Winning := 0; AutoWait := 0;
  If Best < Bank Then Best := Bank;
  CurX := 6; CurY := 1;
  BallR := 60; BallA := 0;
  BetMsg;
  Dirty := 1;
End;

Procedure Refuse(S : String);
Begin
  Msg := S;
  PlaySnd(5);
End;

{ apres un resultat, le tapis est debarrasse (les gains sont payes) }
Procedure ClearTable;
Var K : LongInt;
Begin
  If State <> S_RESULT Then Exit;
  For K := 0 To NSpot - 1 Do Bets[K] := 0;
  State := S_BET;
  BetMsg;
End;

Function AddBet(S : LongInt) : Boolean;
Var V : LongInt; Ok : Boolean;
Begin
  Ok := False;
  ClearTable;
  V := ChipV[ChipSel];
  If State = S_OVER Then Refuse('Plus d''argent : F2 pour une nouvelle partie.')
  Else If State <> S_BET Then Refuse('Rien ne va plus : la bille tourne.')
  Else If (S < 0) Or (S >= NSpot) Then
  Else If V > Bank Then Refuse('Solde insuffisant pour un jeton de ' + Dollars(V) + '.')
  Else If Bets[S] + V > MaxSpot Then Refuse('Mise maximale : ' + Dollars(MaxSpot) + ' par case.')
  Else
  Begin
    Bets[S] := Bets[S] + V;
    Bank := Bank - V;
    Ok := True;
    PlaySnd(0);
    BetMsg;
    Msg := Dollars(V) + ' sur ' + SpotName(S) + ' (' + Dollars(Bets[S]) + ' sur cette case).';
    Dirty := 1;
  End;
  AddBet := Ok;
End;

Procedure ClearBets;
Var K : LongInt;
Begin
  If State <> S_BET Then Exit;
  For K := 0 To NSpot - 1 Do
  Begin
    Bank := Bank + Bets[K];
    Bets[K] := 0;
  End;
  BetMsg;
  Msg := 'Mises retir' + Chr(130) + 'es.';
  Dirty := 1;
End;

{ rejoue les mises du coup precedent }
Procedure Rebet;
Var K, T : LongInt;
Begin
  ClearTable;
  If State <> S_BET Then Exit;
  T := 0;
  For K := 0 To NSpot - 1 Do T := T + LastBets[K];
  If T = 0 Then Exit;
  If T > Bank + TotalBets Then
  Begin
    Refuse('Solde insuffisant pour rejouer ' + Dollars(T) + '.');
    Exit;
  End;
  For K := 0 To NSpot - 1 Do
  Begin
    Bank := Bank + Bets[K] - LastBets[K];
    Bets[K] := LastBets[K];
  End;
  PlaySnd(0);
  BetMsg;
  Msg := 'Mise pr' + Chr(130) + 'c' + Chr(130) + 'dente rejou' + Chr(130) + 'e : ' + Dollars(T) + '.';
  Dirty := 1;
End;

Procedure SelChip(K : LongInt);
Begin
  If (K < 0) Or (K > 4) Then Exit;
  ChipSel := K;
  PlaySnd(0);
  Dirty := 1;
End;

{ position de la bille et du cylindre a l'image T de l'animation.
  Le cylindre tourne dans le sens des aiguilles d'une montre et ralentit
  jusqu'a T_END ; la bille tourne en sens inverse sur la piste, ralentit,
  quitte la piste a T_DROP, rebondit et se loge a T_LOCK dans la case du
  numero gagnant (Target, en unites du cylindre), puis suit le cylindre. }
Procedure SpinPos(T : LongInt);
Var Phi, S, Tt : Real;
Begin
  If T > T_END Then Tt := T_END Else Tt := T;
  Rot := Rot0 - 1.5 * Circ * (2 * Tt / T_END - Tt * Tt / (T_END * T_END));
  If T < T_LOCK Then Phi := Target + 4.0 * Circ * (T_LOCK - T) * (T_LOCK - T) / (T_LOCK * T_LOCK)
  Else Phi := Target;
  BallA := Phi - Rot;
  If T < T_DROP Then BallR := 94
  Else If T < T_LOCK Then
  Begin
    S := (T - T_DROP) / (T_LOCK - T_DROP);
    BallR := 94 - 34 * S + 10 * Abs(Sin(2.5 * Pi * S)) * (1 - S);
  End
  Else BallR := 60;
  RotI := Round(Rot) Mod Circ;
  If RotI < 0 Then RotI := RotI + Circ;
  While BallA < 0 Do BallA := BallA + Circ;
  While BallA >= Circ Do BallA := BallA - Circ;
End;

{ case du cylindre sous la bille (essais) }
Function SlotUnderBall : LongInt;
Var T : LongInt;
Begin
  T := Round(BallA + Rot) Mod Circ;
  If T < 0 Then T := T + Circ;
  SlotUnderBall := WheelOrder[T Div SlotU];
End;

Procedure CheckBroke;
Begin
  If (Bank < ChipV[0]) Then
  Begin
    State := S_OVER;
    Line1 := 'Ruin' + Chr(130) + ' !';
    Line2 := 'F2 : nouvelle partie';
    Msg := 'Plus d''argent ! Partie termin' + Chr(130) + 'e apr' + Chr(138) + 's ' + IStr(Spins) + ' lancers.';
  End;
End;

Procedure SpinDone;
Begin
  Settle(Winning);
  State := S_RESULT;
  Line1 := Describe(Winning);
  If LastGain > 0 Then Line2 := 'Gain : +' + Dollars(LastGain)
  Else If LastGain < 0 Then Line2 := 'Perte : ' + Dollars(LastGain)
  Else Line2 := 'Mises rendues';
  Msg := 'Le ' + IStr(Winning) + ' : ' + Describe(Winning) + '. ' + Line2 + '. Espace : relancer la m' + Chr(136) +
         'me mise.';
  If LastGain > 0 Then PlaySnd(3) Else PlaySnd(4);
  CheckBroke;
  AutoWait := 0;
  Dirty := 1;
End;

{ lance la bille (en S_RESULT : rejoue d'abord la mise precedente) }
Procedure Spin;
Var K : LongInt;
Begin
  If State = S_OVER Then Begin Refuse('Plus d''argent : F2 pour une nouvelle partie.'); Exit; End;
  If State = S_RESULT Then Rebet;
  If State <> S_BET Then Exit;
  If (TotalBets = 0) And HasLast Then Rebet;
  If TotalBets = 0 Then
  Begin
    Refuse('Posez au moins un jeton sur le tapis avant de lancer.');
    Exit;
  End;
  For K := 0 To NSpot - 1 Do LastBets[K] := Bets[K];
  Winning := Rnd(37);
  Target := SlotOf[Winning] * SlotU + SlotU Div 2;
  Rot0 := RotI;
  State := S_SPIN;
  SpinT := 0;
  Line1 := 'Rien ne va plus';
  Line2 := 'La bille tourne...';
  Msg := 'Rien ne va plus ! La bille tourne...';
  If Fast <> 0 Then
  Begin
    SpinPos(T_END);
    SpinDone;
    Exit;
  End;
  SpinPos(0);
  PlaySnd(1);
  Dirty := 1;
End;

Procedure StepSpin;
Begin
  Inc(SpinT);
  SpinPos(SpinT);
  If (SpinT > T_DROP) And (SpinT < T_LOCK) And (SpinT Mod 4 = 0) Then PlaySnd(2);
  If SpinT = T_LOCK Then PlaySnd(2);
  If SpinT >= T_END + 8 Then SpinDone;
  Dirty := 1;
End;

{ demonstration : rouge 10 $, la 2e douzaine 10 $, un plein de 5 $ }
Procedure AutoStep;
Begin
  Inc(AutoWait);
  If State = S_OVER Then
  Begin
    If AutoWait > 90 Then NewGame;
    Exit;
  End;
  If (State <> S_BET) And (State <> S_RESULT) Then Exit;
  If AutoWait < 50 Then Exit;
  AutoWait := 30;
  ClearTable;
  If (Bets[45] = 0) And (Bank >= 10) Then Begin ChipSel := 2; Dummy := Ord(AddBet(45)); Exit; End;
  If (Bets[41] = 0) And (Bank >= 10) Then Begin ChipSel := 2; Dummy := Ord(AddBet(41)); Exit; End;
  If (TotalBets < 25) And (Bank >= 5) Then Begin ChipSel := 1; Dummy := Ord(AddBet(1 + Rnd(36))); Exit; End;
  AutoWait := 0;
  AutoAll := 0;
  Spin;
  AutoAll := 1;
  Msg := 'D' + Chr(130) + 'monstration : rien ne va plus !';
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If State = S_SPIN Then StepSpin
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
  LAdd('Roulette europ' + Chr(130) + 'enne : 37 cases, de 0 ' + Chr(133) + ' 36. Posez vos jetons sur le tapis, ' +
       'puis lancez la bille : le cylindre tourne, la bille tourne en sens inverse, ralentit et tombe dans une ' +
       'case.' + Chr(10) + Chr(10));
  LAdd('Gains (la mise gagnante est rendue en plus) : plein (un num' + Chr(130) + 'ro, z' + Chr(130) +
       'ro compris), 35 pour 1 ; colonne (2:1 au bout de chaque rang' + Chr(130) + 'e) et douzaine, 2 pour 1 ; ' +
       'rouge, noir, pair, impair, manque (1 ' + Chr(133) + ' 18) et passe (19 ' + Chr(133) + ' 36), 1 pour ' +
       '1. Sur le z' + Chr(130) + 'ro, colonnes, douzaines et chances simples perdent.' + Chr(10) + Chr(10));
  LAdd('Choisissez un jeton (1, 5, 10, 25 ou 100 $) dans la plaque, puis cliquez les cases. Apr' + Chr(138) +
       's un lancer, Espace relance avec la m' + Chr(136) + 'me mise. Vous commencez avec 1000 $.' + Chr(10) +
       Chr(10));
  LAdd('Clavier : fl' + Chr(138) + 'ches (curseur sur le tapis), Entr' + Chr(130) + 'e (poser le jeton), 1 ' +
       Chr(133) + ' 5, + et - (jeton), Espace (lancer), R (rejouer la mise), Retour arri' + Chr(138) + 're ' +
       '(effacer), F2 (nouvelle partie).');
  Dummy := LMsgBox('Roulette - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_SPIN : If AutoAll = 0 Then Spin;
    CM_REBET : If AutoAll = 0 Then Rebet;
    CM_CLEAR : If AutoAll = 0 Then ClearBets;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; AutoWait := 0; If State = S_BET Then BetMsg; Dirty := 1; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_FAST : Begin Fast := 1 - Fast; SetMarks; End;
    CM_RULES : Rules;
    CM_ABOUT : Dummy := Ask('Roulette pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype ROULETTE.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Frame1;
End;

Procedure Bet1(S : LongInt);
Begin
  If AutoAll <> 0 Then Exit;
  Dummy := Ord(AddBet(S));
  Frame1;
End;

Procedure MoveCur(Dx, Dy : LongInt);
Begin
  If AutoAll <> 0 Then Exit;
  If Dy <> 0 Then CurY := MaxI(0, MinI(4, CurY + Dy));
  If Dx <> 0 Then
  Begin
    If CurY = 3 Then CurX := ((MaxI(1, MinI(12, CurX)) - 1) Div 4) * 4 + 1 + Dx * 4
    Else If CurY = 4 Then CurX := ((MaxI(1, MinI(12, CurX)) - 1) Div 2) * 2 + 1 + Dx * 2
    Else CurX := CurX + Dx;
  End;
  If CurY >= 3 Then CurX := MaxI(1, MinI(12, CurX)) Else CurX := MaxI(0, MinI(13, CurX));
  Msg := 'Case : ' + SpotName(CurSpot) + ' (Entr' + Chr(130) + 'e : poser ' + Dollars(ChipV[ChipSel]) + ').';
  Dirty := 1;
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
    If Vk = VK_LEFT Then Begin MoveCur(-1, 0); Exit; End;
    If Vk = VK_RIGHT Then Begin MoveCur(1, 0); Exit; End;
    If Vk = VK_UP Then Begin MoveCur(0, -1); Exit; End;
    If Vk = VK_DOWN Then Begin MoveCur(0, 1); Exit; End;
    If Vk = VK_SPACE Then Begin Command(CM_SPIN); Exit; End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Bet1(CurSpot); Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      '1'..'5' : Begin SelChip(Ch - Ord('1')); Frame1; End;
      '+' : Begin SelChip(MinI(4, ChipSel + 1)); Frame1; End;
      '-' : Begin SelChip(MaxI(0, ChipSel - 1)); Frame1; End;
      'R' : Command(CM_REBET);
      'E' : Command(CM_CLEAR);
      'N' : Command(CM_NEW);
      'S', ' ' : Command(CM_SPIN);
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, K, S : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (Y >= BtnY) And (Y < BtnY + BtnH) Then
  Begin
    If (X >= BtnX(0)) And (X < BtnX(0) + BtnW) Then Command(CM_SPIN)
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
  S := SpotAt(X, Y);
  If S >= 0 Then
  Begin
    { le curseur du clavier suit la souris }
    If S = 0 Then Begin CurX := 0; CurY := 1; End
    Else If S <= 36 Then Begin CurX := (S - 1) Div 3 + 1; CurY := 2 - (S - 1) Mod 3; End
    Else If S <= 39 Then Begin CurX := 13; CurY := S - 37; End
    Else If S <= 42 Then Begin CurX := (S - 40) * 4 + 1; CurY := 3; End
    Else Begin CurX := (S - 43) * 2 + 1; CurY := 4; End;
    Bet1(S);
  End
  Else If (X - WCx) * (X - WCx) + (Y - WCy) * (Y - WCy) <= WR * WR Then Command(CM_SPIN);
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

Procedure RunTests;
Var Ok, K, N, A, B, C, D, Alt, X1, Y1, X2, Y2 : LongInt; S : String;
Begin
  Ok := 0;
  For K := 0 To 36 Do SlotOf[WheelOrder[K]] := K;
  { TEST1 : cylindre (37 numeros distincts, 18 rouges, couleurs
    alternees le long du cylindre) }
  A := 0; B := 0; Alt := 0;
  For K := 0 To 36 Do
  Begin
    If WheelOrder[SlotOf[K]] = K Then Inc(A);
    If IsRed(K) Then Inc(B);
    If (K >= 2) And (IsRed(WheelOrder[K]) <> IsRed(WheelOrder[K - 1])) Then Inc(Alt);
  End;
  If IsRed(WheelOrder[1]) <> IsRed(WheelOrder[36]) Then Inc(Alt);
  Log('ROULETTE : TEST1 cylindre ' + IStr(A) + ' numeros ' + IStr(B) + ' rouges alternance ' + IStr(Alt) + '/36');
  If (A = 37) And (B = 18) And (Alt = 36) Then Inc(Ok);
  { TEST2 : gains (17 : plein, rouge... non : 17 est noir ; impair,
    manque, 2e douzaine, 2e colonne) et le zero }
  For K := 0 To NSpot - 1 Do Bets[K] := 0;
  Bank := 0; Bets[17] := 10; Bets[46] := 10; Bets[45] := 10; Bets[41] := 10; Bets[38] := 10; Bets[47] := 10;
  Settle(17); A := Bank;
  For K := 0 To NSpot - 1 Do Bets[K] := 0;
  Bank := 0; Bets[0] := 10; Bets[45] := 10; Bets[46] := 10; Bets[40] := 10;
  Settle(0); B := Bank;
  S := 'TEST2 le 17 rend ' + IStr(A) + ' le zero rend ' + IStr(B);
  Log('ROULETTE : ' + S);
  If (A = 360 + 20 + 30 + 30 + 20) And (B = 360) Then Inc(Ok);
  { TEST3 : tapis (chaque case trouvee a son centre, curseur) et chute
    de la bille dans la case du numero gagnant pour les 37 numeros }
  A := 0;
  For K := 0 To NSpot - 1 Do
  Begin
    SpotRect(K, X1, Y1, X2, Y2);
    If SpotAt((X1 + X2) Div 2, (Y1 + Y2) Div 2) = K Then Inc(A);
  End;
  CurX := 1; CurY := 2; C := CurSpot;
  CurX := 12; CurY := 0; C := C * 100 + CurSpot;
  CurX := 7; CurY := 3; D := CurSpot;
  CurX := 13; CurY := 1; D := D * 100 + CurSpot;
  B := 0; Rot0 := 300;
  For N := 0 To 36 Do
  Begin
    Target := SlotOf[N] * SlotU + SlotU Div 2;
    SpinPos(T_LOCK);
    If SlotUnderBall = N Then
    Begin
      SpinPos(T_END + 8);
      If SlotUnderBall = N Then Inc(B);
    End;
    Rot0 := RotI;
  End;
  S := 'TEST3 cases ' + IStr(A) + '/49 curseur ' + IStr(C) + ' ' + IStr(D) + ' bille ' + IStr(B) + '/37';
  Log('ROULETTE : ' + S);
  If (A = NSpot) And (C = 136) And (D = 4138) And (B = 37) Then Inc(Ok);
  { PARTIE : 500 lancers, rouge 10 $, 2e douzaine 10 $, plein 5 $ sur un
    numero au hasard, graine fixe }
  Seed := 2026;
  For K := 0 To NSpot - 1 Do Bets[K] := 0;
  Bank := StartBank; Best := 0; Spins := 0; NumWins := 0; Reds := 0; Blacks := 0; Zeros := 0; NHist := 0;
  N := 0;
  While (N < 500) And (Bank >= 25) Do
  Begin
    For K := 0 To NSpot - 1 Do Bets[K] := 0;
    Bets[45] := 10; Bets[41] := 10; Bets[1 + Rnd(36)] := 5;
    Bank := Bank - 25;
    Settle(Rnd(37));
    Inc(N);
  End;
  Log('ROULETTE : PARTIE lancers ' + IStr(Spins) + ' rouges ' + IStr(Reds) + ' noirs ' + IStr(Blacks) + ' zeros ' +
      IStr(Zeros) + ' pleins ' + IStr(NumWins) + ' solde ' + IStr(Bank) + ' record ' + IStr(Best));
  Log('ROULETTE : ' + IStr(Ok) + '/3 essais reussis');
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
  Msg := ''; LastMsg := '-'; Line1 := ''; Line2 := ''; AutoAll := 0; Best := 0; Tick := 0; Client := 0;
  Frame := 0; SoundOn := 1; Fast := 0; SndCur := 0; SndEnd := 0; TestMode := 0; Dirty := 1; LastBtn := -1;
  CW := CWant; CH := CHWant; State := S_BET; RotI := 0; Rot := 0; NHist := 0;
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
  MakeWheelMaps;
  MakeTexture;
  RenderBack;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('ROULETTE'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('ROULETTE'), Z2('Roulette'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_SPIN, '~Lancer la bille' + Chr(9) + 'Espace');
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
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Roulette');
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
