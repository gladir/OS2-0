{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BLACKJAK - BlackJack pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau).
}

Program BLACKJAK;

{$R-,S-,I-}

{ Compilation : OS2PC BLACKJAK.PAS   (produit BLACKJAK.EXE)

  Portage vers OS/2-0 du prototype BLACKJAK.PAS du depot 7iles (Turbo
  Pascal, BGI en 640 x 480, touches H, S et N) : fenetre de Presentation
  Manager avec menus, tapis vert dans une image en memoire recopiee par
  GpiDrawBits (sans scintillement), rebord de bois, sabot, cartes
  dessinees (symboles, figures), jetons, cercle de mise, cartes qui
  glissent du sabot, totaux, bandeau du resultat, boutons, barre d'etat
  et apparence d'OS/2 Warp 3.

  Comme le prototype : atteindre 21 sans le depasser ; l'as vaut 1 ou
  11, les figures 10 ; le croupier tire jusqu'a 16 et reste a 17 ; un
  BlackJack (21 avec deux cartes) gagne.
  Ce qui s'ajoute : un solde (1000 $) et des mises (jetons de 5, 10, 25,
  100 et 500), BlackJack paye 3 contre 2, Doubler (une seule carte de
  plus, mise doublee), carte cachee du croupier et verification de son
  BlackJack quand sa carte visible est un as ou un 10, sabot de quatre
  jeux melange quand il reste moins de 52 cartes, record de la seance,
  demonstration (l'ordinateur joue selon la strategie de base), sons.
  Ce qui est corrige : la carte cachee du croupier etait la premiere (le
  total affiche ne comptait que la seconde) ; le paquet etait melange a
  chaque donne avec Randomize ; rien ne limitait la main a l'ecran.

  Souris : jetons du rack (mise), boutons. Clavier : 1 a 5 (jetons),
  Entree ou Espace (distribuer), T ou H (tirer), R ou S (rester), D
  (doubler), Retour arriere (effacer la mise), F2 (nouvelle partie), F1
  (regles).
  Parametres : /SEED:n ; /AUTO (demonstration) ; /NOSOUND ; /TEST
  (essais des totaux, du croupier, du doublement, puis 300 mains jouees
  par l'ordinateur, resultat sur le port serie COM1). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_QUERY = $10; MB_INFORMATION = $30; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_SPACE = $10; VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_DEAL = 102; CM_QUIT = 104;
  CM_AUTO = 201; CM_SOUND = 202; CM_FAST = 203; CM_TOTALS = 204;
  CM_RULES = 301; CM_ABOUT = 302;
  { image du tapis }
  BW = 608; BH = 360; OX = 8; OY = 8;
  CWant = 624; CHWant = 428;
  BtnY = 376; BtnW = 112; BtnH = 26;
  { cartes }
  CardW = 64; CardH = 90; Spread = 30;
  HandX = 214; DealerY = 22; PlayerY = 182;
  ShoeX = 508; ShoeY = 24;
  NDecks = 4; ShoeMax = 208;
  MaxHand = 12; MaxQ = 64;
  StartBank = 1000; MinBet = 5; MaxBet = 500;
  ChipV : Array[0..4] Of LongInt = (5, 10, 25, 100, 500);
  ChipX : Array[0..4] Of LongInt = (184, 248, 312, 376, 440);
  ChipBase : Array[0..4] Of LongInt = ($C83228, $2C58D0, $2C9C44, $2A2A2E, $8C38B4);
  ChipY = 318; ChipR = 22;
  BetCX = 72; BetCY = 228;
  { couleurs de l'image }
  C_FELT = 0;                                 { 0..15 : tapis (sombre -> clair) }
  C_WOOD = 16;                                { 16..23 : bois }
  C_WHITE = 24; C_BLACK = 25; C_RED = 26; C_EDGE = 27; C_SHADOW = 28; C_BACK = 29; C_BACK2 = 30;
  C_GOLD = 31; C_GOLD2 = 32; C_CREAM = 33; C_BADGE = 34; C_TEXT = 35; C_BANNER = 36; C_DIM = 37;
  C_BLUE = 38; C_RACK = 39; C_RACK2 = 40; C_GRAY = 41;
  C_CHIP = 48;                                { 48 + jeton * 4 : base, sombre, clair, liseret }
  { etats }
  S_BET = 1; S_DEAL = 2; S_PLAY = 3; S_DEALER = 4; S_DONE = 5; S_BROKE = 6;
  { actions de la file }
  Q_CARD = 1; Q_PEEK = 2; Q_REVEAL = 3; Q_DSTEP = 4; Q_SETTLE = 5; Q_WAIT = 6; Q_SHUFFLE = 7; Q_PCHECK = 8;
  { resultats }
  R_NONE = 0; R_WIN = 1; R_LOSE = 2; R_PUSH = 3; R_BJ = 4; R_BUST = 5; R_DBJ = 6;
  SndRate = 11025;

Var
  InDlg : LongInt;  { boite de message ouverte : animation suspendue }
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { sabot et mains (cartes 0..51 : rang C mod 13, couleur C div 13 ;
    0 coeur, 1 carreau, 2 trefle, 3 pique) }
  Shoe : Array[0..ShoeMax - 1] Of LongInt;
  ShoePos : LongInt;
  PH, DH : Array[0..MaxHand - 1] Of LongInt;
  PN, DN : LongInt;
  HoleDown, Doubled : Boolean;
  Bank, Bet, LastBet, Best, State, Result, Payout, Seed, AutoAll, SoundOn, Fast, Totals, Tick, Wait : LongInt;
  TestMode, Hands, Wins, Losses, Pushes, Blacks, Doubles, BackDirty : LongInt;
  { file des actions animees }
  QK, QW, QF : Array[0..MaxQ - 1] Of LongInt;
  QH, QT : LongInt;
  { carte en vol (du sabot vers une main) }
  AnOn, AnC, AnW, AnDown, AnK, AnSteps, AnX0, AnY0, AnX1, AnY1 : LongInt;
  Banner, Banner2, Msg, LastMsg : String;
  BannerC : LongInt;
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

{ ==================================================================== }
{ Regles : sabot, totaux, croupier, reglement                           }
{ ==================================================================== }

Function CRank(C : LongInt) : LongInt;
Begin
  CRank := C Mod 13;
End;

Function CSuit(C : LongInt) : LongInt;
Begin
  CSuit := C Div 13;
End;

Function CValue(C : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := CRank(C);
  If R = 0 Then CValue := 11
  Else If R >= 9 Then CValue := 10
  Else CValue := R + 1;
End;

{ main W (0 : joueur, 1 : croupier) }
Function HCard(W, I : LongInt) : LongInt;
Begin
  If W = 0 Then HCard := PH[I] Else HCard := DH[I];
End;

Function HCount(W : LongInt) : LongInt;
Begin
  If W = 0 Then HCount := PN Else HCount := DN;
End;

{ total d'une main (les as valent 11 tant que la main ne depasse pas 21) ;
  Soft : un as compte encore 11 }
Function HandTotal(W : LongInt; Var Soft : Boolean) : LongInt;
Var I, T, Aces : LongInt;
Begin
  T := 0; Aces := 0;
  For I := 0 To HCount(W) - 1 Do
  Begin
    T := T + CValue(HCard(W, I));
    If CRank(HCard(W, I)) = 0 Then Inc(Aces);
  End;
  While (T > 21) And (Aces > 0) Do
  Begin
    T := T - 10;
    Dec(Aces);
  End;
  Soft := Aces > 0;
  HandTotal := T;
End;

Function Total(W : LongInt) : LongInt;
Var Sf : Boolean;
Begin
  Total := HandTotal(W, Sf);
End;

Function IsBJ(W : LongInt) : Boolean;
Begin
  IsBJ := (HCount(W) = 2) And (Total(W) = 21);
End;

Procedure ShuffleShoe;
Var I, J, T : LongInt;
Begin
  For I := 0 To ShoeMax - 1 Do Shoe[I] := I Mod 52;
  For I := ShoeMax - 1 DownTo 1 Do
  Begin
    J := Rnd(I + 1);
    T := Shoe[I]; Shoe[I] := Shoe[J]; Shoe[J] := T;
  End;
  ShoePos := 0;
End;

Function ShoeLeft : LongInt;
Begin
  ShoeLeft := ShoeMax - ShoePos;
End;

Function DrawCard : LongInt;
Begin
  If ShoePos >= ShoeMax Then ShuffleShoe;
  DrawCard := Shoe[ShoePos];
  Inc(ShoePos);
End;

Procedure AddCard(W, C : LongInt);
Begin
  If W = 0 Then
  Begin
    If PN < MaxHand Then Begin PH[PN] := C; Inc(PN); End;
  End
  Else If DN < MaxHand Then
  Begin
    DH[DN] := C; Inc(DN);
  End;
End;

{ la carte visible du croupier : un as ou un 10 (il regarde sa carte cachee) }
Function DealerPeeks : Boolean;
Begin
  DealerPeeks := (DN >= 1) And ((CRank(DH[0]) = 0) Or (CValue(DH[0]) = 10));
End;

{ resultat et somme rendue (mise comprise) ; le solde a deja ete debite }
Procedure Settle;
Var P, D : LongInt;
Begin
  P := Total(0); D := Total(1);
  If IsBJ(0) And Not IsBJ(1) Then
  Begin
    Result := R_BJ; Payout := Bet + Bet * 3 Div 2;
  End
  Else If IsBJ(1) And Not IsBJ(0) Then
  Begin
    Result := R_DBJ; Payout := 0;
  End
  Else If IsBJ(0) And IsBJ(1) Then
  Begin
    Result := R_PUSH; Payout := Bet;
  End
  Else If P > 21 Then
  Begin
    Result := R_BUST; Payout := 0;
  End
  Else If (D > 21) Or (P > D) Then
  Begin
    Result := R_WIN; Payout := 2 * Bet;
  End
  Else If P = D Then
  Begin
    Result := R_PUSH; Payout := Bet;
  End
  Else
  Begin
    Result := R_LOSE; Payout := 0;
  End;
  Bank := Bank + Payout;
  If Bank > Best Then Best := Bank;
  Inc(Hands);
  Case Result Of
    R_WIN : Inc(Wins);
    R_BJ : Begin Inc(Wins); Inc(Blacks); End;
    R_PUSH : Inc(Pushes);
  Else
    Inc(Losses);
  End;
End;

{ strategie de base (sabot de plusieurs jeux, croupier reste sur 17) :
  'H' tirer, 'S' rester, 'D' doubler }
Function Advice : Char;
Var T, Up : LongInt; Soft, CanD : Boolean;
Begin
  T := HandTotal(0, Soft);
  Up := CValue(DH[0]);
  CanD := (PN = 2) And (Bank >= Bet);
  Advice := 'S';
  If Soft Then
  Begin
    If T >= 19 Then Advice := 'S'
    Else If T = 18 Then
    Begin
      If (Up >= 3) And (Up <= 6) And CanD Then Advice := 'D'
      Else If Up >= 9 Then Advice := 'H'
      Else Advice := 'S';
    End
    Else If (T >= 13) And (Up >= 5) And (Up <= 6) And CanD Then Advice := 'D'
    Else Advice := 'H';
    Exit;
  End;
  If T >= 17 Then Advice := 'S'
  Else If T >= 13 Then
  Begin
    If Up <= 6 Then Advice := 'S' Else Advice := 'H';
  End
  Else If T = 12 Then
  Begin
    If (Up >= 4) And (Up <= 6) Then Advice := 'S' Else Advice := 'H';
  End
  Else If T = 11 Then
  Begin
    If CanD Then Advice := 'D' Else Advice := 'H';
  End
  Else If T = 10 Then
  Begin
    If (Up <= 9) And CanD Then Advice := 'D' Else Advice := 'H';
  End
  Else If T = 9 Then
  Begin
    If (Up >= 3) And (Up <= 6) And CanD Then Advice := 'D' Else Advice := 'H';
  End
  Else Advice := 'H';
End;

{ ==================================================================== }
{ Dessin dans l'image (coordonnees : origine en haut a gauche)          }
{ ==================================================================== }

Procedure InitPal;
Var I, K, C : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  For I := 0 To 15 Do SetPal(C_FELT + I, Mix($083A1C, $1E8A44, I, 15));
  For I := 0 To 7 Do SetPal(C_WOOD + I, Mix($3A1C0A, $B06A30, I, 7));
  SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $101010); SetPal(C_RED, $D01E1E); SetPal(C_EDGE, $7A7A7A);
  SetPal(C_SHADOW, $04200E); SetPal(C_BACK, $1C3C9C); SetPal(C_BACK2, $4C74DC); SetPal(C_GOLD, $F0C83C);
  SetPal(C_GOLD2, $A0801C); SetPal(C_CREAM, $FFF4D0); SetPal(C_BADGE, $0C1C10); SetPal(C_TEXT, $C8F0C8);
  SetPal(C_BANNER, $102A18); SetPal(C_DIM, $5A9A6A); SetPal(C_BLUE, $1C2C8C); SetPal(C_RACK, $2A1406);
  SetPal(C_RACK2, $50300F); SetPal(C_GRAY, $C8C8C8);
  For K := 0 To 4 Do
  Begin
    C := ChipBase[K];
    SetPal(C_CHIP + K * 4, C);
    SetPal(C_CHIP + K * 4 + 1, Mix(C, $000000, 5, 10));
    SetPal(C_CHIP + K * 4 + 2, Mix(C, $FFFFFF, 3, 10));
    SetPal(C_CHIP + K * 4 + 3, $F4F4F4);
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
  FbText(X, Y, S, C, Sc);
End;

Procedure FbCenter(Cx, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbTextSh(Cx - Length(S) * 4 * Sc, Y, S, C, Sc);
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

{ trait d'ellipse (inscriptions du tapis) }
Procedure EllipseLine(Cx, Cy, A, B, C : LongInt);
Var K : LongInt; T : Real;
Begin
  For K := 0 To 719 Do
  Begin
    T := K * Pi / 360;
    Pix(Cx + Round(Cos(T) * A), Cy + Round(Sin(T) * B), C);
  End;
End;

{ disposition des symboles d'une carte (colonne G, C, D ; ligne 0 a 6) }
Function PipLayout(N : LongInt) : String;
Begin
  Case N Of
    2 : PipLayout := 'C0C6';
    3 : PipLayout := 'C0C3C6';
    4 : PipLayout := 'G0D0G6D6';
    5 : PipLayout := 'G0D0C3G6D6';
    6 : PipLayout := 'G0D0G3D3G6D6';
    7 : PipLayout := 'G0D0C1G3D3G6D6';
    8 : PipLayout := 'G0D0C1G3D3C5G6D6';
    9 : PipLayout := 'G0D0G2D2C3G4D4G6D6';
  Else
    PipLayout := 'G0D0C1G2D2G4D4C5G6D6';
  End;
End;

Function RankName(R : LongInt) : String;
Begin
  Case R Of
    0 : RankName := 'A';
    10 : RankName := 'V';
    11 : RankName := 'D';
    12 : RankName := 'R';
  Else
    RankName := IStr(R + 1);
  End;
End;

Procedure CardBack(X, Y : LongInt);
Var I, J, A : LongInt;
Begin
  RRect(X + 4, Y + 4, X + CardW - 5, Y + CardH - 5, 4, C_BACK);
  { treillis en losanges }
  For J := Y + 5 To Y + CardH - 6 Do
    For I := X + 5 To X + CardW - 6 Do
    Begin
      A := (I - X + J - Y) Mod 8;
      If (A = 0) Or ((I - X - (J - Y) + 800) Mod 8 = 0) Then Pix(I, J, C_BACK2);
    End;
  RRect(X + CardW Div 2 - 15, Y + CardH Div 2 - 11, X + CardW Div 2 + 14, Y + CardH Div 2 + 10, 6, C_GOLD);
  RRect(X + CardW Div 2 - 13, Y + CardH Div 2 - 9, X + CardW Div 2 + 12, Y + CardH Div 2 + 8, 5, C_BLUE);
  FbText(X + CardW Div 2 - 8, Y + CardH Div 2 - 8, '21', C_GOLD, 1);
End;

Procedure DrawCardAt(X, Y, C : LongInt; Down : Boolean);
Var Fg, R, K, Px, Py, Cx : LongInt; L, S, Sy : String;
Begin
  RRect(X + 3, Y + 3, X + CardW + 2, Y + CardH + 2, 6, C_SHADOW);
  RRect(X, Y, X + CardW - 1, Y + CardH - 1, 6, C_EDGE);
  RRect(X + 1, Y + 1, X + CardW - 2, Y + CardH - 2, 5, C_WHITE);
  If Down Then
  Begin
    CardBack(X, Y);
    Exit;
  End;
  If CSuit(C) < 2 Then Fg := C_RED Else Fg := C_BLACK;
  R := CRank(C);
  S := RankName(R); Sy := Chr(3 + CSuit(C));
  FbText(X + 4, Y + 3, S, Fg, 1);
  FbText(X + 4, Y + 18, Sy, Fg, 1);
  FbText(X + CardW - 5 - Length(S) * 8, Y + CardH - 34, S, Fg, 1);
  FbText(X + CardW - 13, Y + CardH - 19, Sy, Fg, 1);
  Cx := X + CardW Div 2 - 4;
  If R = 0 Then FbText(X + CardW Div 2 - 12, Y + CardH Div 2 - 24, Sy, Fg, 3)
  Else If R >= 10 Then
  Begin
    { figure : cadre creme, grande lettre, symboles aux coins }
    Rect(X + 14, Y + 16, X + CardW - 15, Y + CardH - 17, Fg);
    Rect(X + 15, Y + 17, X + CardW - 16, Y + CardH - 18, C_CREAM);
    Rect(X + 17, Y + 19, X + CardW - 18, Y + 21, C_GOLD);
    Rect(X + 17, Y + CardH - 22, X + CardW - 18, Y + CardH - 20, C_GOLD);
    FbText(X + CardW Div 2 - 8, Y + CardH Div 2 - 16, S, Fg, 2);
    FbText(X + 17, Y + 22, Sy, Fg, 1);
    FbText(X + CardW - 26, Y + CardH - 40, Sy, Fg, 1);
  End
  Else
  Begin
    L := PipLayout(R + 1);
    K := 1;
    While K < Length(L) Do
    Begin
      Case L[K] Of
        'G' : Px := Cx - 13;
        'D' : Px := Cx + 13;
      Else
        Px := Cx;
      End;
      Py := Y + 10 + ((Ord(L[K + 1]) - 48) * (CardH - 38)) Div 6;
      FbText(Px, Py, Sy, Fg, 1);
      K := K + 2;
    End;
  End;
End;

Procedure DrawChip(Cx, Cy, K : LongInt; Small : Boolean);
Var R, I, B : LongInt; T : Real; S : String;
Begin
  If Small Then R := 15 Else R := ChipR;
  B := C_CHIP + K * 4;
  Disc(Cx + 2, Cy + 2, R, C_SHADOW);
  Disc(Cx, Cy, R, B + 1);
  Disc(Cx, Cy, R - 2, B);
  { liserets du bord }
  For I := 0 To 7 Do
  Begin
    T := I * Pi / 4;
    Disc(Cx + Round(Cos(T) * (R - 4)), Cy + Round(Sin(T) * (R - 4)), R Div 7, B + 3);
  End;
  Disc(Cx, Cy, R - 7, B + 2);
  Disc(Cx, Cy, R - 9, B);
  If Not Small Then
  Begin
    S := IStr(ChipV[K]);
    FbText(Cx - Length(S) * 4, Cy - 8, S, C_WHITE, 1);
  End;
End;

Function CardX(W, I : LongInt) : LongInt;
Begin
  CardX := HandX + I * Spread;
End;

Function CardY(W : LongInt) : LongInt;
Begin
  If W = 0 Then CardY := PlayerY Else CardY := DealerY;
End;

Procedure Badge(X, Y : LongInt; S : String);
Begin
  RRect(X, Y, X + Length(S) * 8 + 11, Y + 21, 9, C_GOLD2);
  RRect(X + 1, Y + 1, X + Length(S) * 8 + 10, Y + 20, 8, C_BADGE);
  FbText(X + 6, Y + 3, S, C_WHITE, 1);
End;

Function TotalText(W : LongInt) : String;
Var T : LongInt; Sf : Boolean;
Begin
  T := HandTotal(W, Sf);
  If IsBJ(W) Then TotalText := 'BlackJack'
  Else If Sf And (T < 21) Then TotalText := IStr(T - 10) + '/' + IStr(T)
  Else TotalText := IStr(T);
End;

{ decor fixe : tapis, rebord, inscriptions, cercle de mise, rack, sabot }
Procedure RenderBack;
Var X, Y, D, S, N, K : LongInt; Dx, Dy : Real;
Begin
  N := 7;
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      Dx := (X - BW Div 2) / (BW * 0.62); Dy := (Y - 160) / (BH * 0.70);
      D := Round(Sqrt(Dx * Dx + Dy * Dy) * 16);
      N := (N * 1103515245 + 12345) And $7FFFFFFF;
      S := 15 - D + ((N Shr 16) And 1);
      If S < 0 Then S := 0;
      If S > 15 Then S := 15;
      Back[(BH - 1 - Y) * BW + X] := C_FELT + S;
    End;
  Move(Back, Fb, SizeOf(Fb));
  { rebord de bois }
  For K := 0 To 9 Do
  Begin
    Rect(K, K, BW - 1 - K, K, C_WOOD + MinI(7, 7 - K Div 2));
    Rect(K, BH - 1 - K, BW - 1 - K, BH - 1 - K, C_WOOD + MaxI(0, 2 - K Div 4));
    Rect(K, K, K, BH - 1 - K, C_WOOD + MinI(7, 6 - K Div 2));
    Rect(BW - 1 - K, K, BW - 1 - K, BH - 1 - K, C_WOOD + MaxI(0, 3 - K Div 3));
  End;
  { inscriptions du tapis }
  Rect(HandX - 4, 121, HandX + 284, 121, C_GOLD2);
  Rect(HandX - 4, 165, HandX + 284, 165, C_GOLD2);
  FbCenter(HandX + 140, 125, 'BLACKJACK PAIE 3 CONTRE 2', C_GOLD, 1);
  FbCenter(HandX + 140, 144, 'Le croupier tire jusqu''' + Chr(133) + ' 16 et reste ' + Chr(133) + ' 17', C_TEXT, 1);
  { cercle de mise }
  EllipseLine(BetCX, BetCY, 42, 32, C_GOLD);
  EllipseLine(BetCX, BetCY, 44, 34, C_GOLD2);
  FbCenter(BetCX, BetCY - 54, 'MISE', C_GOLD, 1);
  { rack des jetons }
  RRect(ChipX[0] - 36, ChipY - 30, ChipX[4] + 36, ChipY + 28, 8, C_RACK2);
  RRect(ChipX[0] - 33, ChipY - 27, ChipX[4] + 33, ChipY + 25, 6, C_RACK);
  For K := 0 To 4 Do Disc(ChipX[K], ChipY, ChipR + 3, C_SHADOW);
  { sabot }
  RRect(ShoeX - 6, ShoeY - 6, ShoeX + CardW + 12, ShoeY + CardH + 14, 6, C_WOOD + 1);
  RRect(ShoeX - 3, ShoeY - 3, ShoeX + CardW + 9, ShoeY + CardH + 11, 5, C_WOOD);
  Move(Fb, Back, SizeOf(Fb));
  BackDirty := 0;
End;

Procedure DrawBanner;
Var W, X1 : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(MaxI(Length(Banner) * 16, Length(Banner2) * 8) + 40, 340);
  X1 := HandX + 140 - W Div 2;
  RRect(X1, 114, X1 + W, 177, 10, C_GOLD);
  RRect(X1 + 3, 117, X1 + W - 3, 174, 8, C_BANNER);
  FbCenter(HandX + 140, 120, Banner, BannerC, 2);
  FbCenter(HandX + 140, 154, Banner2, C_TEXT, 1);
End;

{ la scene entiere dans Fb }
Procedure RenderScene;
Var K, I, V, Y, N : LongInt; S : String;
Begin
  If BackDirty <> 0 Then RenderBack;
  Move(Back, Fb, SizeOf(Fb));
  { sabot : cartes restantes }
  N := MinI(5, (ShoeLeft + 39) Div 40);
  For K := 0 To N - 1 Do
  Begin
    RRect(ShoeX + K * 2, ShoeY + K * 2, ShoeX + K * 2 + CardW - 1, ShoeY + K * 2 + CardH - 1, 6, C_EDGE);
    RRect(ShoeX + K * 2 + 1, ShoeY + K * 2 + 1, ShoeX + K * 2 + CardW - 2, ShoeY + K * 2 + CardH - 2, 5, C_WHITE);
    CardBack(ShoeX + K * 2, ShoeY + K * 2);
  End;
  FbCenter(ShoeX + CardW Div 2 + 3, ShoeY + CardH + 16, 'Sabot ' + IStr(ShoeLeft), C_TEXT, 1);
  { mains }
  FbTextSh(HandX - 72, DealerY + 10, 'Croupier', C_TEXT, 1);
  For I := 0 To DN - 1 Do DrawCardAt(CardX(1, I), DealerY, DH[I], (I = 1) And HoleDown);
  FbTextSh(HandX - 40, PlayerY + 10, 'Vous', C_TEXT, 1);
  For I := 0 To PN - 1 Do DrawCardAt(CardX(0, I), PlayerY, PH[I], False);
  If Totals <> 0 Then
  Begin
    If (DN > 0) And Not HoleDown Then S := TotalText(1) Else S := IStr(CValue(DH[0]));
    If DN > 0 Then Badge(HandX - 20 - Length(S) * 8, DealerY + 34, S);
    S := TotalText(0);
    If PN > 0 Then Badge(HandX - 20 - Length(S) * 8, PlayerY + 34, S);
  End;
  If Doubled And (PN > 0) Then FbTextSh(HandX - 96, PlayerY + 62, 'Mise doubl' + Chr(130) + 'e', C_GOLD, 1);
  { mise : pile de jetons }
  V := Bet; Y := BetCY + 6; N := 0;
  For K := 4 DownTo 0 Do
    While (V >= ChipV[K]) And (N < 12) Do
    Begin
      DrawChip(BetCX, Y, K, True);
      V := V - ChipV[K];
      Y := Y - 4; Inc(N);
    End;
  S := IStr(Bet) + ' $';
  If Bet > 0 Then FbCenter(BetCX, BetCY + 38, S, C_WHITE, 1);
  { solde et record }
  FbTextSh(22, 282, 'Solde', C_TEXT, 1);
  FbTextSh(22, 298, IStr(Bank) + ' $', C_WHITE, 2);
  If Best > 0 Then FbTextSh(498, 282, 'Record', C_TEXT, 1);
  If Best > 0 Then FbTextSh(498, 300, IStr(Best) + ' $', C_GOLD, 1);
  { jetons du rack (grises si on ne peut pas les miser) }
  For K := 0 To 4 Do DrawChip(ChipX[K], ChipY, K, False);
  { carte en vol }
  If AnOn <> 0 Then
    DrawCardAt(AnX0 + (AnX1 - AnX0) * AnK Div AnSteps, AnY0 + (AnY1 - AnY0) * AnK Div AnSteps, AnC, AnDown <> 0);
  DrawBanner;
End;

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 0; MakeNoise(0, 45, 60, 2);                 { carte }
  SndPrio := 0; MakeTone(1, 2600, 1900, 45, 30);         { jeton }
  SndPrio := 0; MakeNoise(2, 35, 50, 1);                 { carte retournee }
  SndPrio := 2; MakeTone(3, 520, 1040, 260, 40);         { gagne }
  SndPrio := 2; MakeTone(4, 520, 220, 380, 40);          { perdu }
  SndPrio := 3; MakeTone(5, 660, 1980, 600, 45);         { BlackJack }
  SndPrio := 1; MakeNoise(6, 420, 70, 3);                { melange }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Fenetre : boutons et barre d'etat                                     }
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

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Var Fg : LongInt;
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then Fg := CLR_BLACK Else Fg := CLR_DARKGRAY;
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, Fg, CLR_PALEGRAY);
End;

Function CanDeal : Boolean;
Begin
  CanDeal := ((State = S_BET) And (Bet >= MinBet) And (Bet <= Bank)) Or
             ((State = S_DONE) And (Bank >= MinBet));
End;

Function CanPlay : Boolean;
Begin
  CanPlay := (State = S_PLAY) And (AutoAll = 0);
End;

Function CanDouble : Boolean;
Begin
  CanDouble := CanPlay And (PN = 2) And (Bank >= Bet);
End;

Function CanClear : Boolean;
Begin
  CanClear := ((State = S_BET) And (Bet > 0)) Or (State = S_DONE);
End;

Procedure DrawButtons;
Begin
  Button(8, BtnY, BtnW, BtnH, 'Distribuer', CanDeal And (AutoAll = 0));
  Button(128, BtnY, BtnW, BtnH, 'Tirer', CanPlay);
  Button(248, BtnY, BtnW, BtnH, 'Rester', CanPlay);
  Button(368, BtnY, BtnW, BtnH, 'Doubler', CanDouble);
  Button(488, BtnY, BtnW + 16, BtnH, 'Effacer la mise', CanClear And (AutoAll = 0));
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
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawButtons;
  DrawStatus;
  LastMsg := Msg;
  Dummy := WinEndPaint(Hps);
End;

{ image, boutons et barre d'etat a jour (hors de WM_PAINT) }
Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  RenderScene;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawButtons;
  If Msg <> LastMsg Then
  Begin
    LastMsg := Msg;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Deroulement de la donne (file d'actions animees)                      }
{ ==================================================================== }

Procedure QPush(K, W, F : LongInt);
Begin
  If QT - QH >= MaxQ Then Exit;
  QK[QT Mod MaxQ] := K; QW[QT Mod MaxQ] := W; QF[QT Mod MaxQ] := F;
  Inc(QT);
End;

Procedure Show(B1, B2 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; BannerC := C;
End;

Procedure BetMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue (Options).'
  Else If Bet = 0 Then Msg := 'Misez : cliquez sur les jetons (ou 1 ' + Chr(133) + ' 5), puis Distribuer.'
  Else Msg := 'Mise : ' + IStr(Bet) + ' $. Entr' + Chr(130) + 'e ou Distribuer pour jouer.';
End;

Procedure PlayMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue (Options).'
  Else If CanDouble Then Msg := 'Tirer (T), Rester (R) ou Doubler (D) ?'
  Else Msg := 'Tirer (T) ou Rester (R) ?';
End;

Procedure StartRound;
Begin
  If State = S_DONE Then
  Begin
    Bet := LastBet;
    If Bet > Bank Then Bet := (Bank Div MinBet) * MinBet;
    If Bet < MinBet Then Bet := MinBet;
  End;
  If (Bet < MinBet) Or (Bet > Bank) Then Exit;
  Bank := Bank - Bet; LastBet := Bet;
  PN := 0; DN := 0; HoleDown := True; Doubled := False;
  Banner := ''; Result := R_NONE;
  QH := 0; QT := 0;
  If ShoeLeft < 52 Then QPush(Q_SHUFFLE, 0, 0);
  QPush(Q_CARD, 0, 0); QPush(Q_CARD, 1, 0); QPush(Q_CARD, 0, 0); QPush(Q_CARD, 1, 1);
  QPush(Q_PEEK, 0, 0);
  State := S_DEAL;
  Msg := 'Distribution...';
  Wait := 0;
End;

Procedure ClearTable;
Begin
  PN := 0; DN := 0; Banner := ''; Doubled := False;
  If State = S_DONE Then Bet := 0;
  State := S_BET;
End;

Procedure NewGame;
Begin
  Bank := StartBank; Bet := 0; LastBet := 10;
  PN := 0; DN := 0; Banner := ''; Doubled := False;
  QH := 0; QT := 0; AnOn := 0;
  ShuffleShoe;
  State := S_BET; Wait := 0;
  BetMsg;
End;

Procedure AddChip(K : LongInt);
Begin
  If AutoAll <> 0 Then Exit;
  If State = S_DONE Then ClearTable;
  If State <> S_BET Then Exit;
  If Bet + ChipV[K] > MinI(Bank, MaxBet) Then
  Begin
    If Bet + ChipV[K] > Bank Then Msg := 'Solde insuffisant pour ce jeton.'
    Else Msg := 'La mise maximale est de ' + IStr(MaxBet) + ' $.';
    PlaySnd(4);
    Exit;
  End;
  Bet := Bet + ChipV[K];
  PlaySnd(1);
  BetMsg;
End;

Procedure ClearBet;
Begin
  If State = S_DONE Then ClearTable;
  If State <> S_BET Then Exit;
  Bet := 0;
  BetMsg;
End;

Procedure Hit;
Begin
  If State <> S_PLAY Then Exit;
  QPush(Q_CARD, 0, 0); QPush(Q_PCHECK, 0, 0);
  State := S_DEAL;
End;

Procedure Stand;
Begin
  If State <> S_PLAY Then Exit;
  State := S_DEALER;
  QPush(Q_REVEAL, 0, 0); QPush(Q_DSTEP, 0, 0);
  Msg := 'Le croupier joue...';
End;

Procedure DoubleDown;
Begin
  If (State <> S_PLAY) Or (PN <> 2) Or (Bank < Bet) Then Exit;
  Bank := Bank - Bet; Bet := Bet * 2; Doubled := True; Inc(Doubles);
  PlaySnd(1);
  QPush(Q_CARD, 0, 0); QPush(Q_PCHECK, 0, 1);
  State := S_DEAL;
End;

Procedure ShowResult;
Var G : LongInt;
Begin
  G := Payout - Bet;
  Case Result Of
    R_BJ : Begin Show('BlackJack !', '+' + IStr(G) + ' $ (3 contre 2)', C_GOLD); PlaySnd(5); End;
    R_WIN :
      Begin
        If Total(1) > 21 Then Show('Le croupier saute !', '+' + IStr(G) + ' $', C_GOLD)
        Else Show('Vous gagnez !', '+' + IStr(G) + ' $', C_GOLD);
        PlaySnd(3);
      End;
    R_PUSH : Begin Show('Egalit' + Chr(130), 'Mise rendue', C_WHITE); PlaySnd(2); End;
    R_BUST : Begin Show('Vous d' + Chr(130) + 'passez 21', '-' + IStr(Bet) + ' $', C_RED); PlaySnd(4); End;
    R_DBJ : Begin Show('BlackJack du croupier', '-' + IStr(Bet) + ' $', C_RED); PlaySnd(4); End;
  Else
    Begin Show('Le croupier gagne', '-' + IStr(Bet) + ' $', C_RED); PlaySnd(4); End;
  End;
  If Bank < MinBet Then
  Begin
    State := S_BROKE;
    Show('Vous ' + Chr(136) + 'tes ruin' + Chr(130), 'F2 : nouvelle partie (1000 $)', C_RED);
    Msg := 'Plus assez d''argent pour miser. F2 : nouvelle partie.';
  End
  Else
  Begin
    State := S_DONE;
    If AutoAll <> 0 Then BetMsg
    Else Msg := 'Entr' + Chr(130) + 'e : nouvelle donne (' + IStr(LastBet) + ' $), ou jetons pour changer la mise.';
  End;
  Wait := 0;
End;

{ une action de la file }
Procedure RunQ;
Var K, W, F, T : LongInt;
Begin
  K := QK[QH Mod MaxQ]; W := QW[QH Mod MaxQ]; F := QF[QH Mod MaxQ];
  Inc(QH);
  Case K Of
    Q_CARD :
      Begin
        AnC := DrawCard; AnW := W; AnDown := F; AnK := 0;
        If Fast <> 0 Then AnSteps := 4 Else AnSteps := 8;
        AnX0 := ShoeX + 8; AnY0 := ShoeY + 8;
        AnX1 := CardX(W, HCount(W)); AnY1 := CardY(W);
        AnOn := 1;
        PlaySnd(0);
      End;
    Q_PEEK :
      If IsBJ(0) Or (DealerPeeks And IsBJ(1)) Then
      Begin
        HoleDown := False;
        PlaySnd(2);
        State := S_DEALER;
        QPush(Q_WAIT, 0, 6); QPush(Q_SETTLE, 0, 0);
      End
      Else
      Begin
        State := S_PLAY; Wait := 0;
        PlayMsg;
      End;
    Q_PCHECK :
      Begin
        T := Total(0);
        If T > 21 Then
        Begin
          HoleDown := False;
          State := S_DEALER;
          QPush(Q_WAIT, 0, 4); QPush(Q_SETTLE, 0, 0);
        End
        Else If (T = 21) Or (F <> 0) Then
        Begin
          State := S_PLAY;
          Stand;
        End
        Else
        Begin
          State := S_PLAY; Wait := 0;
          PlayMsg;
        End;
      End;
    Q_REVEAL :
      Begin
        HoleDown := False;
        PlaySnd(2);
        QPush(Q_WAIT, 0, 5);
      End;
    Q_DSTEP :
      If Total(1) < 17 Then
      Begin
        QPush(Q_CARD, 1, 0); QPush(Q_WAIT, 0, 4); QPush(Q_DSTEP, 0, 0);
      End
      Else QPush(Q_SETTLE, 0, 0);
    Q_SETTLE :
      Begin
        Settle;
        ShowResult;
      End;
    Q_WAIT : Wait := F;
    Q_SHUFFLE :
      Begin
        ShuffleShoe;
        PlaySnd(6);
        Msg := 'Le sabot est m' + Chr(130) + 'lang' + Chr(130) + ' (quatre jeux de 52 cartes).';
        Wait := 14;
      End;
  End;
End;

Procedure Command(Id : LongInt); Forward;

Procedure TimerTick;
Var Changed : Boolean; A : Char;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  Changed := False;
  If AnOn <> 0 Then
  Begin
    Inc(AnK);
    If AnK >= AnSteps Then
    Begin
      AnOn := 0;
      AddCard(AnW, AnC);
    End;
    Changed := True;
  End
  Else If Wait > 0 Then Dec(Wait)
  Else If QH < QT Then
  Begin
    RunQ;
    Changed := True;
  End
  Else If AutoAll <> 0 Then
  Begin
    Case State Of
      S_BET, S_DONE :
        If Tick Mod 40 = 0 Then
        Begin
          If State = S_DONE Then ClearTable;
          Bet := MinI(10, Bank);
          StartRound;
          Changed := True;
        End;
      S_PLAY :
        If Tick Mod 16 = 0 Then
        Begin
          A := Advice;
          If A = 'H' Then Hit Else If A = 'D' Then DoubleDown Else Stand;
          Changed := True;
        End;
      S_BROKE :
        If Tick Mod 80 = 0 Then
        Begin
          NewGame;
          Changed := True;
        End;
    End;
  End;
  If Changed Or (Msg <> LastMsg) Then Frame1;
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
  SetMark(CM_TOTALS, Totals <> 0);
End;

Procedure Deal;
Begin
  If AutoAll <> 0 Then Exit;
  If Not CanDeal Then
  Begin
    If State = S_BET Then Msg := 'Misez d''abord (au moins ' + IStr(MinBet) + ' $).';
    Exit;
  End;
  StartRound;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW :
      If (State = S_BET) Or (State = S_DONE) Or (State = S_BROKE) Or
         (Ask('Abandonner la donne en cours et recommencer avec 1000 $ ?', 'BlackJack', MB_YESNO Or MB_QUERY) =
          MBID_YES) Then NewGame;
    CM_DEAL : Deal;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll; SetMarks; Tick := 0;
        If State = S_BROKE Then NewGame;
        If State = S_PLAY Then PlayMsg Else BetMsg;
      End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_FAST : Begin Fast := 1 - Fast; SetMarks; End;
    CM_TOTALS : Begin Totals := 1 - Totals; SetMarks; End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Battez le croupier en approchant 21 sans le d' + Chr(130) + 'passer : 2 ' + Chr(133) +
             ' 10 valent leur nombre, valet, dame et roi 10, l''as 1 ou 11.' + Chr(10) + Chr(10));
        LAdd('Misez avec les jetons (5 ' + Chr(133) + ' 500 $), puis Distribuer. Tirer : une carte de plus ; ' +
             'Rester : le croupier joue ; Doubler (deux premi' + Chr(138) + 'res cartes) : mise doubl' + Chr(130) +
             'e et une seule carte.' + Chr(10) + Chr(10));
        LAdd('Le croupier tire jusqu''' + Chr(133) + ' 16 et reste ' + Chr(133) + ' 17. Avec un as ou un 10 ' +
             'visible, il v' + Chr(130) + 'rifie sa carte cach' + Chr(130) + 'e : son BlackJack gagne aussit' +
             Chr(147) + 't.' + Chr(10) + Chr(10));
        LAdd('BlackJack (21 en deux cartes) : 3 contre 2 ; main gagnante : 1 contre 1 ; ' + Chr(130) +
             'galit' + Chr(130) + ' : mise rendue. Sabot de quatre jeux ; solde de d' + Chr(130) + 'part : 1000 $.' +
             Chr(10) + Chr(10));
        LAdd('Clavier : 1 ' + Chr(133) + ' 5 jetons, Entr' + Chr(130) + 'e distribuer, T tirer, R rester, ' +
             'D doubler, Retour arri' + Chr(138) + 're effacer la mise, F2 nouvelle partie.');
        Dummy := LMsgBox('BlackJack - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('BlackJack pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype BLACKJAK.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
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
  If (Fl And (KC_KEYUP Or KC_CTRL Or KC_ALT)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_BACKSPACE Then Begin ClearBet; Frame1; Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Deal; Frame1; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      '1'..'5' : AddChip(Ch - Ord('1'));
      'T', 'H' : If AutoAll = 0 Then Hit;
      'R', 'S' : If AutoAll = 0 Then Stand;
      'D' : If AutoAll = 0 Then DoubleDown;
      'E' : ClearBet;
      'N' : Command(CM_NEW);
      ' ' : Deal;
    Else
      KeyChar := False;
    End;
    Frame1;
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
    If (X >= 8) And (X < 8 + BtnW) Then Deal
    Else If (X >= 128) And (X < 128 + BtnW) And (AutoAll = 0) Then Hit
    Else If (X >= 248) And (X < 248 + BtnW) And (AutoAll = 0) Then Stand
    Else If (X >= 368) And (X < 368 + BtnW) And (AutoAll = 0) Then DoubleDown
    Else If (X >= 488) And (X < 488 + BtnW + 16) Then ClearBet;
    Frame1;
    Exit;
  End;
  X := X - OX; Y := Y - OY;
  For K := 0 To 4 Do
    If (X - ChipX[K]) * (X - ChipX[K]) + (Y - ChipY) * (Y - ChipY) <= ChipR * ChipR Then AddChip(K);
  If (Abs(X - BetCX) < 44) And (Abs(Y - BetCY) < 34) Then ClearBet;
  Frame1;
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

Procedure SetHand(W, A, B, C : LongInt);
Begin
  If W = 0 Then PN := 0 Else DN := 0;
  If A >= 0 Then AddCard(W, A);
  If B >= 0 Then AddCard(W, B);
  If C >= 0 Then AddCard(W, C);
End;

{ prochaines cartes du sabot }
Procedure Stack(A, B, C, D : LongInt);
Begin
  ShoePos := 100;
  Shoe[100] := A; Shoe[101] := B; Shoe[102] := C; Shoe[103] := D;
End;

{ une donne sans animation (strategie de base), comme dans la fenetre }
Procedure RoundSync;
Var A : Char; Base : LongInt;
Begin
  If ShoeLeft < 52 Then ShuffleShoe;
  Base := Bet;
  Bank := Bank - Bet; PN := 0; DN := 0; Doubled := False;
  AddCard(0, DrawCard); AddCard(1, DrawCard); AddCard(0, DrawCard); AddCard(1, DrawCard);
  If Not (IsBJ(0) Or (DealerPeeks And IsBJ(1))) Then
  Begin
    Repeat
      A := Advice;
      If A = 'H' Then AddCard(0, DrawCard)
      Else If A = 'D' Then
      Begin
        Bank := Bank - Bet; Bet := Bet * 2; Doubled := True; Inc(Doubles);
        AddCard(0, DrawCard);
      End;
    Until (A <> 'H') Or (Total(0) >= 21);
    If Total(0) <= 21 Then
      While Total(1) < 17 Do AddCard(1, DrawCard);
  End;
  Settle;
  Bet := Base;
End;

Procedure RunTests;
Var Ok, N : LongInt; S : String; Sf : Boolean; T1, T2, T3, T4, T5 : LongInt;
Begin
  Ok := 0;
  { TEST1 : totaux (as 1 ou 11, figures 10, BlackJack) }
  SetHand(0, 0, 12, -1); T1 := Total(0);
  If IsBJ(0) Then S := ' BJ' Else S := '';
  SetHand(0, 0, 0, 8); T2 := Total(0);
  SetHand(0, 9, 5, 0); T3 := HandTotal(0, Sf);
  If Sf Then S := S + ' 17s?' Else S := S;
  SetHand(0, 0, 5, -1); T4 := HandTotal(0, Sf);
  SetHand(0, 12, 11, 1); T5 := Total(0);
  S := 'TEST1 totaux ' + IStr(T1) + S + ' ' + IStr(T2) + ' ' + IStr(T3) + ' ' + IStr(T4);
  If Sf Then S := S + 's';
  S := S + ' ' + IStr(T5);
  Log('BLACKJACK : ' + S);
  If S = 'TEST1 totaux 21 BJ 21 17 17s 22' Then Inc(Ok);
  { TEST2 : le croupier tire a 16 et reste a 17 (souple compris) ; 3 contre 2 }
  Bank := 0; Bet := 10;
  SetHand(0, 9, 6, -1); SetHand(1, 9, 5, -1); Stack(4, -1, -1, -1);
  While Total(1) < 17 Do AddCard(1, DrawCard);
  Settle; T1 := Result; T2 := DN; T3 := Payout;
  SetHand(0, 9, 7, -1); SetHand(1, 0, 5, -1);
  While Total(1) < 17 Do AddCard(1, DrawCard);
  Settle; T4 := Result; T5 := DN; N := Payout;
  SetHand(0, 0, 12, -1); SetHand(1, 8, 6, -1);
  Settle;
  S := 'TEST2 croupier ' + IStr(T2) + ' cartes ' + IStr(T1) + ' ' + IStr(T3) + ' ; 17 souple ' + IStr(T5) +
       ' cartes ' + IStr(T4) + ' ' + IStr(N) + ' ; BlackJack ' + IStr(Result) + ' ' + IStr(Payout);
  Log('BLACKJACK : ' + S);
  If (T1 = R_LOSE) And (T2 = 3) And (T3 = 0) And (T4 = R_WIN) And (T5 = 2) And (N = 20) And (Result = R_BJ) And
     (Payout = 25) Then Inc(Ok);
  { TEST3 : doubler sur 11 contre un 10 }
  Bank := 100; Bet := 10;
  SetHand(0, 4, 5, -1); SetHand(1, 9, 6, -1);
  T1 := Ord(Advice);
  Stack(22, -1, -1, -1);
  Bank := Bank - 2 * Bet; Bet := Bet * 2;
  AddCard(0, DrawCard);
  While Total(1) < 17 Do AddCard(1, DrawCard);
  Settle;
  S := 'TEST3 conseil ' + Chr(T1) + ' total ' + IStr(Total(0)) + ' ' + IStr(Result) + ' ' + IStr(Payout) +
       ' solde ' + IStr(Bank);
  Log('BLACKJACK : ' + S);
  If (Chr(T1) = 'D') And (Total(0) = 21) And (Result = R_WIN) And (Payout = 40) And (Bank = 120) Then Inc(Ok);
  { PARTIE : 300 mains a 10 $ avec la strategie de base, graine fixe }
  Seed := 2026; ShuffleShoe;
  Bank := StartBank; Best := 0; Hands := 0; Wins := 0; Losses := 0; Pushes := 0; Blacks := 0; Doubles := 0;
  N := 0;
  While (N < 300) And (Bank >= 10) Do
  Begin
    Bet := 10;
    RoundSync;
    Inc(N);
  End;
  Log('BLACKJACK : PARTIE mains ' + IStr(Hands) + ' gagnees ' + IStr(Wins) + ' perdues ' + IStr(Losses) +
      ' egalites ' + IStr(Pushes) + ' blackjacks ' + IStr(Blacks) + ' doubles ' + IStr(Doubles) + ' solde ' +
      IStr(Bank));
  Log('BLACKJACK : ' + IStr(Ok) + '/3 essais reussis');
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
  Msg := ''; LastMsg := '-'; AutoAll := 0; Banner := ''; Banner2 := ''; Best := 0; Tick := 0; Client := 0;
  Frame := 0; SoundOn := 1; Fast := 0; Totals := 1; SndCur := 0; SndEnd := 0; TestMode := 0; AnOn := 0;
  Hands := 0; Wins := 0; Losses := 0; Pushes := 0; Blacks := 0; Doubles := 0; BackDirty := 1;
  CW := CWant; CH := CHWant; QH := 0; QT := 0; Wait := 0; PN := 0; DN := 0; HoleDown := True;
  Doubled := False; Result := R_NONE; Payout := 0; BannerC := C_GOLD;
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
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('BLACKJAK'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('BLACKJAK'), Z2('BlackJack'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_DEAL, '~Distribuer' + Chr(9) + 'Entr' + Chr(130) + 'e');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MItem(MIS_TEXT, 0, CM_FAST, 'Distribution ~rapide');
  MItem(MIS_TEXT, 0, CM_TOTALS, 'Afficher les ~totaux');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MenuClose(H3, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de BlackJack');
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
