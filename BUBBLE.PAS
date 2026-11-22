{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2024 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BUBBLE - Bubble Shooter pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau).
}

Program BUBBLE;

{$R-,S-,I-}

{ Compilation : OS2PC BUBBLE.PAS   (produit BUBBLE.EXE)

  Portage vers OS/2-0 du prototype BS.PAS du depot 7iles (Turbo Pascal,
  BGI en 640 x 480, clavier seulement) : fenetre de Presentation Manager
  avec menus, image en memoire recopiee par GpiDrawBits (seule la zone
  qui change est recopiee), bulles en relief (degrade et reflet), fond en
  degrade, plafond de metal rivete qui descend, canon a dome, ligne de
  visee avec ses rebonds, bulle suivante, bulles qui eclatent et qui
  tombent, points qui montent, panneau du pointage, bruitages, barre
  d'etat et apparence d'OS/2 Warp 3.

  Comme le prototype : le canon, en bas, tire des bulles de couleur vers
  les bulles accrochees en haut ; trois bulles ou plus de la meme couleur
  qui se touchent eclatent (10 points chacune).
  Ce qui est corrige : les bulles sont rangees dans une vraie grille
  hexagonale (rangees decalees d'une demi-bulle) et la bulle tiree s'y
  accroche a la case libre la plus proche ; le groupe est cherche par
  remplissage (seules les bulles de la meme couleur reliees a la bulle
  tiree eclatent, toutes, et elles sont toutes effacees) ; les bulles qui
  ne tiennent plus au plafond tombent (20 points chacune) ; la bulle
  rebondit sur les murs ; la bulle chargee est toujours d'une couleur
  encore presente.
  Ce qui s'ajoute : niveaux (plus de rangees et de couleurs), plafond qui
  descend d'une rangee apres quelques tirs sans eclatement, partie perdue
  quand une bulle depasse la ligne rouge, niveau gagne quand tout est
  vide (bonus), record de la seance, demonstration (l'ordinateur joue).

  Souris : viser, clic : tirer. Clavier : fleches gauche et droite
  (viser), Espace, Entree ou fleche haut (tirer), P (pause), F2 (nouvelle
  partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (demonstration) ; /LEVEL:n ; /NOSOUND ;
  /TEST (essais de la grille et partie jouee par l'ordinateur sans
  fenetre, resultat sur le port serie COM1). }

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
  VK_NEWLINE = $08; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21; VK_PAUSE = $0D;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_PAUSE = 102; CM_QUIT = 104;
  CM_AUTO = 201; CM_SOUND = 202; CM_GUIDE = 203;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : terrain de 400 x 400 }
  BW = 400; BH = 400; OX = 8; OY = 8;
  PnX = 424; PW = 192;
  CWant = 624; CHWant = 436;
  { grille hexagonale : bulles de 32 points, rangees de 28 points }
  BR = 16; BD = 32; RH = 28; COLS = 12; MaxRow = 15; NCell = 180;
  TopStart = 6; DangerY = 340; CanX = 200; CanY = 372;
  NCol = 6;                                  { couleurs des bulles (7 : grise) }
  MaxPop = 64; MaxFall = 160; MaxFloat = 12;
  { couleurs de l'image }
  C_BG = 0;                                  { 0..15 : degrade du fond }
  C_MET = 16;                                { 16..21 : metal (sombre -> clair) }
  C_RED = 22; C_WHITE = 23; C_BLACK = 24; C_GUIDE = 25; C_BANNER = 26; C_BANNERE = 27; C_YELLOW = 28;
  C_GREEN = 29; C_SHADOW = 30; C_DOT = 31; C_DANGER2 = 32; C_RIVET = 33;
  C_BALL = 40;                               { 40 + (couleur - 1) * 8 + nuance }
  NPal = 96;
  Base : Array[1..7] Of LongInt = ($E02828, $F0C418, $2CB040, $2C5CE8, $A43CD8, $18B8C8, $8C8C8C);
  ColName : Array[1..7] Of String[8] = ('rouge', 'jaune', 'verte', 'bleue', 'violette', 'cyan', 'grise');
  S_LEVEL = 1; S_AIM = 2; S_FLY = 3; S_CLEAR = 4; S_OVER = 5; S_PAUSE = 6;
  SndRate = 11025;

Var
  InDlg : LongInt;  { boite de message ouverte : animation suspendue }
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  SprA : Array[0..7 * BD * BD - 1] Of Byte;           { bulles de 32 x 32 (255 : transparent) }
  CosT, SinT : Array[0..1800] Of LongInt;               { angles en dixiemes de degre, x 256 }
  { grille : 0 vide, 1..6 couleur ; case (R, C) = indice R * COLS + C }
  GridA : Array[0..NCell - 1] Of LongInt;
  MarkA : Array[0..NCell - 1] Of LongInt;
  SeenA : Array[0..NCell - 1] Of LongInt;
  QI : Array[0..NCell] Of LongInt;
  Top, Level, Colors, Score, Best, Shots, Miss, MissMax, Popped, Dropped, Descents, Cleared : LongInt;
  CurCol, NextCol, Ang, State, OldState, Wait, Seed, AutoAll, GuideOn, SoundOn, Tick : LongInt;
  StartLevel, TestMode, GrayOut, Shake : LongInt;
  { bulle tiree (positions et vitesse x 256) }
  PX, PY, PVX, PVY, Bounces : LongInt;
  { animations }
  PopOn, PopX, PopY, PopC, PopT : Array[0..MaxPop - 1] Of LongInt;
  FallOn, FallX, FallY, FallV, FallC : Array[0..MaxFall - 1] Of LongInt;
  FlOn, FlX, FlY, FlT : Array[0..MaxFloat - 1] Of LongInt;
  FlS : Array[0..MaxFloat - 1] Of String[12];
  { zone recopiee : rectangle precedent et rectangle courant }
  RX1, RY1, RX2, RY2, NX1, NY1, NX2, NY2, FullBlit, BackDirty : LongInt;
  Banner, Banner2, Msg, LastMsg : String;
  BannerC, LastSig : LongInt;
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
Var I, S, C : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  { fond : bleu nuit vers violet }
  For I := 0 To 15 Do SetPal(C_BG + I, Mix($0A1238, $3A1E58, I, 15));
  { metal }
  For I := 0 To 5 Do SetPal(C_MET + I, Mix($3C4250, $D8DCE4, I, 5));
  SetPal(C_RED, $E83C32); SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $000000);
  SetPal(C_GUIDE, $E6EBFF); SetPal(C_BANNER, $1C2450); SetPal(C_BANNERE, $A0B4FF);
  SetPal(C_YELLOW, $FFDC46); SetPal(C_GREEN, $64E68C); SetPal(C_SHADOW, $05081C); SetPal(C_DOT, $1E2A5C);
  SetPal(C_DANGER2, $78283C); SetPal(C_RIVET, $F0F2F8);
  { bulles : 8 nuances par couleur (0 bord sombre ... 7 reflet) }
  For C := 1 To 7 Do
    For S := 0 To 7 Do
    Begin
      If S = 0 Then I := Mix(Base[C], $000000, 6, 10)
      Else If S <= 5 Then I := Mix(Mix(Base[C], $000000, 5, 10), Base[C], S - 1, 4)
      Else If S = 6 Then I := Mix(Base[C], $FFFFFF, 4, 10)
      Else I := Mix(Base[C], $FFFFFF, 9, 10);
      SetPal(C_BALL + (C - 1) * 8 + S, I);
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

{ ==================================================================== }
{ Bulles en relief                                                      }
{ ==================================================================== }

{ nuance d'un point (Dx, Dy) d'une bulle de rayon R (x 16 pour la
  precision) ; -1 hors de la bulle }
Function Shade(Dx, Dy, R : LongInt) : LongInt;
Var D2, Rr, Hx, Hy, H2, S : LongInt; Q : Real;
Begin
  D2 := Dx * Dx + Dy * Dy;
  Rr := R * 16;
  If D2 > Rr * Rr Then
  Begin
    Shade := -1;
    Exit;
  End;
  { bord sombre }
  If D2 > (Rr - 20) * (Rr - 20) Then
  Begin
    Shade := 0;
    Exit;
  End;
  { lumiere venant du haut a gauche }
  Hx := Dx + Rr * 4 Div 10; Hy := Dy + Rr * 45 Div 100;
  H2 := Hx * Hx + Hy * Hy;
  If H2 < (Rr * 2 Div 10) * (Rr * 2 Div 10) Then
  Begin
    Shade := 7;
    Exit;
  End;
  Q := Sqrt(H2 + 0.0) / (Rr * 1.55);
  S := 6 - Round(Q * 6);
  If S < 1 Then S := 1;
  If S > 6 Then S := 6;
  { reflet de la couleur en bas a droite }
  If (Dx + Dy > Rr * 9 Div 10) And (D2 > (Rr * 7 Div 10) * (Rr * 7 Div 10)) And (S < 3) Then S := 3;
  Shade := S;
End;

Procedure MakeSprites;
Var C, X, Y, S : LongInt;
Begin
  For C := 1 To 7 Do
    For Y := 0 To BD - 1 Do
      For X := 0 To BD - 1 Do
      Begin
        S := Shade(X * 16 + 8 - BR * 16, Y * 16 + 8 - BR * 16, BR);
        If S < 0 Then SprA[((C - 1) * BD + Y) * BD + X] := 255 Else SprA[((C - 1) * BD + Y) * BD + X] := C_BALL + (C - 1) * 8 + S;
      End;
End;

{ bulle de taille normale centree en (Cx, Cy) }
Procedure DrawBubble(Cx, Cy, C : LongInt);
Var X, Y, V, Px, Py : LongInt;
Begin
  If (C < 1) Or (C > 7) Then Exit;
  For Y := 0 To BD - 1 Do
  Begin
    Py := Cy - BR + Y;
    If (Py >= 0) And (Py < BH) Then
      For X := 0 To BD - 1 Do
      Begin
        V := SprA[((C - 1) * BD + Y) * BD + X];
        Px := Cx - BR + X;
        If (V <> 255) And (Px >= 0) And (Px < BW) Then Fb[(BH - 1 - Py) * BW + Px] := V;
      End;
  End;
End;

{ bulle de rayon R quelconque (eclatement, bulle suivante) : la bulle de
  32 x 32 mise a l'echelle }
Procedure DrawBall(Cx, Cy, R, C : LongInt);
Var X, Y, V, Sx, Sy : LongInt;
Begin
  If (C < 1) Or (C > 7) Or (R < 1) Then Exit;
  For Y := 0 To 2 * R - 1 Do
  Begin
    Sy := Y * BD Div (2 * R);
    For X := 0 To 2 * R - 1 Do
    Begin
      Sx := X * BD Div (2 * R);
      V := SprA[((C - 1) * BD + Sy) * BD + Sx];
      If V <> 255 Then Pix(Cx - R + X, Cy - R + Y, V);
    End;
  End;
End;

{ ==================================================================== }
{ Grille hexagonale                                                     }
{ ==================================================================== }
{ rangee R : centres en X = 16 + 32 C (rangees paires) ou 32 + 32 C
  (rangees impaires, decalees d'une demi-bulle), Y = Top + 16 + 28 R }

Function CellX(R, C : LongInt) : LongInt;
Begin
  CellX := BR + C * BD + (R And 1) * BR;
End;

Function CellY(R : LongInt) : LongInt;
Begin
  CellY := Top + BR + R * RH;
End;

Function GAt(R, C : LongInt) : LongInt;
Begin
  GAt := GridA[R * COLS + C];
End;

Procedure SetG(R, C, V : LongInt);
Begin
  GridA[R * COLS + C] := V;
End;

Function MAt(R, C : LongInt) : LongInt;
Begin
  MAt := MarkA[R * COLS + C];
End;

Function SAt(R, C : LongInt) : LongInt;
Begin
  SAt := SeenA[R * COLS + C];
End;

{ voisine K (0..5) de la case I : son indice, ou -1 hors de la grille }
Function NbI(I, K : LongInt) : LongInt;
Var R, C, NR, NC : LongInt;
Begin
  R := I Div COLS; C := I Mod COLS;
  NR := R; NC := C;
  If K = 0 Then NC := C - 1
  Else If K = 1 Then NC := C + 1
  Else If K = 2 Then
  Begin
    NR := R - 1;
    If (R And 1) = 0 Then NC := C - 1;
  End
  Else If K = 3 Then
  Begin
    NR := R - 1;
    If (R And 1) <> 0 Then NC := C + 1;
  End
  Else If K = 4 Then
  Begin
    NR := R + 1;
    If (R And 1) = 0 Then NC := C - 1;
  End
  Else
  Begin
    NR := R + 1;
    If (R And 1) <> 0 Then NC := C + 1;
  End;
  If (NR >= 0) And (NR < MaxRow) And (NC >= 0) And (NC < COLS) Then NbI := NR * COLS + NC Else NbI := -1;
End;

Procedure ClearMark;
Var I : LongInt;
Begin
  For I := 0 To NCell - 1 Do MarkA[I] := 0;
End;

{ groupe des bulles de couleur Col reliees a (R0, C0) : MarkA = 1 ; nombre }
Function Group(R0, C0, Col : LongInt) : LongInt;
Var N, H, I, J, K, V : LongInt;
Begin
  ClearMark;
  I := R0 * COLS + C0;
  QI[0] := I; MarkA[I] := 1; N := 1; H := 0;
  While H < N Do
  Begin
    I := QI[H]; Inc(H);
    For K := 0 To 5 Do
    Begin
      J := NbI(I, K);
      If J >= 0 Then
      Begin
        V := GridA[J];
        If (V = Col) And (MarkA[J] = 0) Then
        Begin
          MarkA[J] := 1;
          QI[N] := J; Inc(N);
        End;
      End;
    End;
  End;
  Group := N;
End;

{ bulles qui ne tiennent plus au plafond si les cases marquees (MarkA = 1)
  sont videes : SeenA = 2 pour elles ; nombre }
Function Hanging : LongInt;
Var N, H, I, J, K, Cnt : LongInt;
Begin
  For I := 0 To NCell - 1 Do SeenA[I] := 0;
  N := 0; H := 0;
  For I := 0 To COLS - 1 Do
    If (GridA[I] <> 0) And (MarkA[I] = 0) Then
    Begin
      SeenA[I] := 1;
      QI[N] := I; Inc(N);
    End;
  While H < N Do
  Begin
    I := QI[H]; Inc(H);
    For K := 0 To 5 Do
    Begin
      J := NbI(I, K);
      If J >= 0 Then
        If (SeenA[J] = 0) And (GridA[J] <> 0) And (MarkA[J] = 0) Then
        Begin
          SeenA[J] := 1;
          QI[N] := J; Inc(N);
        End;
    End;
  End;
  Cnt := 0;
  For I := 0 To NCell - 1 Do
    If (GridA[I] <> 0) And (MarkA[I] = 0) And (SeenA[I] = 0) Then
    Begin
      SeenA[I] := 2;
      Inc(Cnt);
    End;
  Hanging := Cnt;
End;

Function CountBubbles : LongInt;
Var R, C, N : LongInt;
Begin
  N := 0;
  For R := 0 To MaxRow - 1 Do
    For C := 0 To COLS - 1 Do
      If GAt(R, C) <> 0 Then Inc(N);
  CountBubbles := N;
End;

Function ColorPresent(Col : LongInt) : Boolean;
Var R, C : LongInt; F : Boolean;
Begin
  F := False;
  For R := 0 To MaxRow - 1 Do
    For C := 0 To COLS - 1 Do
      If GAt(R, C) = Col Then F := True;
  ColorPresent := F;
End;

{ couleur au hasard parmi celles qui restent dans la grille }
Function PickColor : LongInt;
Var Have : Array[1..7] Of LongInt; N, K, R, C, Pick : LongInt;
Begin
  For K := 1 To 7 Do Have[K] := 0;
  For R := 0 To MaxRow - 1 Do
    For C := 0 To COLS - 1 Do
      If (GAt(R, C) >= 1) And (GAt(R, C) <= NCol) Then Have[GAt(R, C)] := 1;
  N := 0;
  For K := 1 To NCol Do N := N + Have[K];
  If N = 0 Then
  Begin
    PickColor := 1 + Rnd(Colors);
    Exit;
  End;
  Pick := Rnd(N);
  For K := 1 To NCol Do
    If Have[K] <> 0 Then
    Begin
      If Pick = 0 Then
      Begin
        PickColor := K;
        Exit;
      End;
      Dec(Pick);
    End;
  PickColor := 1;
End;

{ plus basse bulle : bas de la bulle (Y), ou 0 }
Function LowestY : LongInt;
Var R, C, Y : LongInt;
Begin
  Y := 0;
  For R := 0 To MaxRow - 1 Do
    For C := 0 To COLS - 1 Do
      If GAt(R, C) <> 0 Then Y := MaxI(Y, CellY(R) + BR);
  LowestY := Y;
End;

{ ==================================================================== }
{ Trajectoire (positions x 256, pas de 2 points)                        }
{ ==================================================================== }

{ la bulle en (X, Y) (x 256) touche-t-elle le plafond ou une bulle ? }
Function Touches(X, Y : LongInt) : Boolean;
Var R, C, R1, R2, Dx, Dy, Lim : LongInt;
Begin
  Touches := True;
  If Y Div 256 - BR <= Top Then Exit;
  R1 := MaxI(0, ((Y Div 256) - Top - BR) Div RH - 2);
  R2 := MinI(MaxRow - 1, R1 + 4);
  Lim := (BD - 6) * 256;
  For R := R1 To R2 Do
    For C := 0 To COLS - 1 Do
      If GAt(R, C) <> 0 Then
      Begin
        Dx := X - CellX(R, C) * 256; Dy := Y - CellY(R) * 256;
        If (Abs(Dx) < Lim) And (Abs(Dy) < Lim) Then
          If (Dx Div 16) * (Dx Div 16) + (Dy Div 16) * (Dy Div 16) < (Lim Div 16) * (Lim Div 16) Then Exit;
      End;
  Touches := False;
End;

{ un pas de 2 points ; rebonds sur les murs ; vrai si la bulle touche }
Function ProjStep(Var X, Y, VX, VY, Bn : LongInt) : Boolean;
Begin
  X := X + VX * 2; Y := Y + VY * 2;
  If X < BR * 256 Then
  Begin
    X := 2 * BR * 256 - X; VX := -VX; Inc(Bn);
  End;
  If X > (BW - BR) * 256 Then
  Begin
    X := 2 * (BW - BR) * 256 - X; VX := -VX; Inc(Bn);
  End;
  ProjStep := Touches(X, Y);
End;

{ case libre ou s'accroche une bulle arretee en (X, Y) (x 256) : la plus
  proche parmi celles du plafond ou voisines d'une bulle }
Function AttachCell(X, Y : LongInt; Var BR0, BC0 : LongInt) : Boolean;
Var R, C, K, J, D, Best, Dx, Dy : LongInt; Ok : Boolean;
Begin
  Best := MaxLongInt; BR0 := -1; BC0 := -1;
  For R := 0 To MaxRow - 1 Do
    If Abs(CellY(R) * 256 - Y) <= RH * 2 * 256 Then
      For C := 0 To COLS - 1 Do
        If GridA[R * COLS + C] = 0 Then
        Begin
          Ok := R = 0;
          K := 0;
          While (Not Ok) And (K < 6) Do
          Begin
            J := NbI(R * COLS + C, K);
            If J >= 0 Then
              If GridA[J] <> 0 Then Ok := True;
            Inc(K);
          End;
          If Ok Then
          Begin
            Dx := (X - CellX(R, C) * 256) Div 16; Dy := (Y - CellY(R) * 256) Div 16;
            D := Dx * Dx + Dy * Dy;
            If D < Best Then
            Begin
              Best := D; BR0 := R; BC0 := C;
            End;
          End;
        End;
  AttachCell := BR0 >= 0;
End;

{ vitesse de depart (x 256 par point) pour l'angle A (dixiemes de degre) }
Procedure StartShot(A : LongInt; Var X, Y, VX, VY : LongInt);
Begin
  X := CanX * 256; Y := CanY * 256;
  VX := CosT[A]; VY := -SinT[A];
End;

{ trajectoire complete (pour la ligne de visee et l'ordinateur) : case
  d'arrivee ; faux si aucune }
Function Simulate(A : LongInt; Var R0, C0 : LongInt) : Boolean;
Var X, Y, VX, VY, Bn, N : LongInt; Hit : Boolean;
Begin
  StartShot(A, X, Y, VX, VY);
  Bn := 0; N := 0; Hit := False;
  While (Not Hit) And (N < 2000) Do
  Begin
    Hit := ProjStep(X, Y, VX, VY, Bn);
    Inc(N);
  End;
  Simulate := Hit And AttachCell(X, Y, R0, C0);
End;

{ ==================================================================== }
{ Bruitages (8 bits, 11025 Hz, joues par MDM)                           }
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
  SndPrio := 1; MakeTone(0, 700, 260, 90, 35);           { tir }
  SndPrio := 0; MakeTone(1, 1500, 1300, 25, 25);         { rebond }
  SndPrio := 1; MakeNoise(2, 70, 70, 6);                 { accrochage }
  SndPrio := 2; MakeTone(3, 600, 1700, 180, 45);         { eclatement }
  SndPrio := 2; MakeTone(4, 900, 180, 420, 40);          { chute }
  SndPrio := 3; MakeNoise(5, 450, 110, 10);              { descente du plafond }
  SndPrio := 4; MakeTone(6, 520, 1560, 700, 50);         { niveau gagne }
  SndPrio := 5; MakeTone(7, 420, 70, 1300, 60);          { partie perdue }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Decor fixe (Back) : fond, plafond, grille, tableau de bord, canon     }
{ ==================================================================== }

Procedure DrawCeiling;
Var X, Y, S : LongInt;
Begin
  { plaque de metal rivetee qui descend avec le plafond }
  For Y := 0 To Top - 1 Do
  Begin
    S := 1 + (Y * 3) Div MaxI(Top, 1);
    If Y >= Top - 2 Then S := 0;
    If Y = 0 Then S := 5;
    Rect(0, Y, BW - 1, Y, C_MET + S);
  End;
  If Top > 12 Then
  Begin
    Y := 6;
    While Y < Top - 6 Do
    Begin
      Rect(0, Y, BW - 1, Y, C_MET + 1);
      Y := Y + RH;
    End;
  End;
  X := 12;
  While X < BW Do
  Begin
    Y := Top - 4;
    If Y > 1 Then
    Begin
      Pix(X, Y, C_RIVET); Pix(X + 1, Y, C_MET + 3); Pix(X, Y + 1, C_MET + 1); Pix(X + 1, Y + 1, C_MET);
    End;
    X := X + 32;
  End;
End;

Procedure DrawDashboard;
Var X, Y, S, D2 : LongInt;
Begin
  { ligne rouge (danger) en tirets }
  X := 0;
  While X < BW Do
  Begin
    Rect(X, DangerY, X + 9, DangerY + 1, C_RED);
    Rect(X + 10, DangerY, X + 15, DangerY + 1, C_DANGER2);
    X := X + 16;
  End;
  { tableau de bord en metal }
  For Y := DangerY + 4 To BH - 1 Do
  Begin
    S := 1 + ((Y - DangerY - 4) * 2) Div (BH - DangerY);
    Rect(0, Y, BW - 1, Y, C_MET + S);
  End;
  Rect(0, DangerY + 4, BW - 1, DangerY + 4, C_MET + 4);
  { dome du canon }
  For Y := -34 To 0 Do
    For X := -34 To 34 Do
    Begin
      D2 := X * X + Y * Y;
      If D2 <= 34 * 34 Then
      Begin
        If D2 > 32 * 32 Then S := 0
        Else
        Begin
          S := 5 - ((X + 20) * (X + 20) + (Y + 20) * (Y + 20)) Div 500;
          If S < 1 Then S := 1;
        End;
        Pix(CanX + X, CanY + 10 + Y, C_MET + S);
      End;
    End;
  { emplacement de la bulle suivante }
  FbTextSh(12, 352, 'Suivante', C_YELLOW, 1);
  Disc(44, 384, 13, C_SHADOW);
End;

Procedure RenderBack;
Var X, Y, B, R, C, Idx : LongInt;
Begin
  { fond en degrade (tramage 2 x 2) et petits points }
  For Y := 0 To BH - 1 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := 0 To BW - 1 Do
    Begin
      Idx := (Y * 30 + ((X + Y) And 1) * 13) Div BH Div 2;
      If Idx > 15 Then Idx := 15;
      Fb[B + X] := C_BG + Idx;
    End;
  End;
  Y := 20;
  While Y < DangerY Do
  Begin
    X := 8 + ((Y Div 28) And 1) * 16;
    While X < BW Do
    Begin
      Pix(X, Y, C_DOT);
      X := X + 32;
    End;
    Y := Y + 28;
  End;
  DrawCeiling;
  DrawDashboard;
  For R := 0 To MaxRow - 1 Do
    For C := 0 To COLS - 1 Do
      If GAt(R, C) <> 0 Then
      Begin
        If GrayOut <> 0 Then DrawBubble(CellX(R, C), CellY(R), 7)
        Else DrawBubble(CellX(R, C), CellY(R), GAt(R, C));
      End;
  Move(Fb, Back, SizeOf(Fb));
  BackDirty := 0;
  FullBlit := 1;
End;

{ ==================================================================== }
{ Objets mobiles (dessines sur Fb, rectangle englobant recopie)          }
{ ==================================================================== }

Procedure Touch(X1, Y1, X2, Y2 : LongInt);
Begin
  If X1 < NX1 Then NX1 := X1;
  If Y1 < NY1 Then NY1 := Y1;
  If X2 > NX2 Then NX2 := X2;
  If Y2 > NY2 Then NY2 := Y2;
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

{ ligne de visee : points jusqu'a la premiere bulle (avec les rebonds) }
Procedure DrawGuide;
Var X, Y, VX, VY, Bn, N, Px, Py : LongInt; Hit : Boolean;
Begin
  StartShot(Ang, X, Y, VX, VY);
  Bn := 0; N := 0; Hit := False;
  While (Not Hit) And (N < 400) And (Bn < 3) Do
  Begin
    Hit := ProjStep(X, Y, VX, VY, Bn);
    Inc(N);
    If (N > 22) And (N Mod 7 = 0) And (Not Hit) Then
    Begin
      Px := X Div 256; Py := Y Div 256;
      If Py < DangerY - 2 Then
      Begin
        Rect(Px - 1, Py - 1, Px + 1, Py + 1, C_GUIDE);
        Touch(Px - 1, Py - 1, Px + 1, Py + 1);
      End;
    End;
  End;
End;

Procedure DrawCannon;
Var X2, Y2 : LongInt;
Begin
  X2 := CanX + CosT[Ang] * 46 Div 256; Y2 := CanY - SinT[Ang] * 46 Div 256;
  TLine(CanX, CanY, X2, Y2, 5, C_MET);
  TLine(CanX, CanY, X2, Y2, 3, C_MET + 3);
  TLine(CanX + 1, CanY - 1, X2 + 1, Y2 - 1, 0, C_MET + 5);
  Touch(MinI(CanX, X2) - 6, MinI(CanY, Y2) - 6, MaxI(CanX, X2) + 6, MaxI(CanY, Y2) + 6);
  If State <> S_FLY Then
  Begin
    If GrayOut <> 0 Then DrawBubble(CanX, CanY, 7) Else DrawBubble(CanX, CanY, CurCol);
  End
  Else Disc(CanX, CanY, 8, C_SHADOW);
  Touch(CanX - BR, CanY - BR, CanX + BR, CanY + BR);
  { bulle suivante }
  DrawBall(44, 384, 12, NextCol);
  Touch(30, 370, 58, 398);
End;

Procedure DrawPops;
Var K, T, A, X, Y, R, C : LongInt;
Begin
  For K := 0 To MaxPop - 1 Do
    If PopOn[K] <> 0 Then
    Begin
      T := PopT[K];
      If T < 0 Then DrawBubble(PopX[K], PopY[K], PopC[K])
      Else If T < 4 Then DrawBall(PopX[K], PopY[K], BR - T * 3, PopC[K])
      Else
      Begin
        R := BR + (T - 4) * 3;
        For A := 0 To 7 Do
        Begin
          X := PopX[K] + CosT[A * 225] * R Div 256; Y := PopY[K] - SinT[A * 225] * R Div 256;
          If T < 8 Then C := C_BALL + (PopC[K] - 1) * 8 + 7 Else C := C_BALL + (PopC[K] - 1) * 8 + 5;
          Rect(X - 1, Y - 1, X + 1, Y + 1, C);
        End;
      End;
      Touch(PopX[K] - BR - 16, PopY[K] - BR - 16, PopX[K] + BR + 16, PopY[K] + BR + 16);
    End;
End;

Procedure DrawFalls;
Var K, Y : LongInt;
Begin
  For K := 0 To MaxFall - 1 Do
    If FallOn[K] <> 0 Then
    Begin
      Y := FallY[K] Div 256;
      DrawBubble(FallX[K], Y, FallC[K]);
      Touch(FallX[K] - BR, Y - BR - 12, FallX[K] + BR, Y + BR);
    End;
End;

Procedure DrawFloats;
Var K : LongInt;
Begin
  For K := 0 To MaxFloat - 1 Do
    If FlOn[K] <> 0 Then
    Begin
      FbTextSh(FlX[K], FlY[K], FlS[K], C_YELLOW, 1);
      Touch(FlX[K] - 1, FlY[K] - 1, FlX[K] + Length(FlS[K]) * 8 + 2, FlY[K] + 18);
    End;
End;

Procedure DrawBanner;
Var W, X, Y, H : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(Length(Banner) * 16, Length(Banner2) * 8) + 40;
  If W > BW - 20 Then W := BW - 20;
  H := 70; If Banner2 = '' Then H := 52;
  X := (BW - W) Div 2; Y := 150;
  Rect(X + 4, Y + 4, X + W + 3, Y + H + 3, C_SHADOW);
  Rect(X, Y, X + W - 1, Y + H - 1, C_BANNER);
  Rect(X, Y, X + W - 1, Y + 1, C_BANNERE); Rect(X, Y + H - 2, X + W - 1, Y + H - 1, C_BANNERE);
  Rect(X, Y, X + 1, Y + H - 1, C_BANNERE); Rect(X + W - 2, Y, X + W - 1, Y + H - 1, C_BANNERE);
  FbTextSh(X + (W - Length(Banner) * 16) Div 2, Y + 10, Banner, BannerC, 2);
  If Banner2 <> '' Then FbTextSh(X + (W - Length(Banner2) * 8) Div 2, Y + 46, Banner2, C_WHITE, 1);
  Touch(X, Y, X + W + 4, Y + H + 4);
End;

Procedure DrawSprites;
Begin
  RestoreRect(RX1, RY1, RX2, RY2);
  NX1 := BW; NY1 := BH; NX2 := -1; NY2 := -1;
  If (GuideOn <> 0) And (State = S_AIM) And (AutoAll = 0) Then DrawGuide;
  DrawCannon;
  If State = S_FLY Then
  Begin
    DrawBubble(PX Div 256, PY Div 256, CurCol);
    Touch(PX Div 256 - BR, PY Div 256 - BR, PX Div 256 + BR, PY Div 256 + BR);
  End;
  DrawPops;
  DrawFalls;
  DrawFloats;
  DrawBanner;
End;

{ ==================================================================== }
{ Fenetre                                                               }
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
  FBar(PnX + 2, 86, PnX + PW - 3, 120, CLR_WHITE);
  S := IStr(Score);
  BigText(PnX + PW - 8 - Length(S) * 16, 87, S, CLR_DARKBLUE, CLR_WHITE);
  FBar(PnX, 128, PnX + PW - 1, 226, CLR_PALEGRAY);
  OutTxt(PnX, 128, 'Niveau : ' + IStr(Level), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 146, 'Bulles : ' + IStr(CountBubbles), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 164, 'Tirs : ' + IStr(Shots), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 182, 'Plafond :', CLR_BLACK, CLR_PALEGRAY);
  { tirs avant la descente du plafond : cases pleines }
  For K := 0 To MissMax - 1 Do
  Begin
    X := PnX + 80 + K * 14;
    Edge(X, 184, X + 10, 194, CLR_DARKGRAY, CLR_WHITE);
    If K < MissMax - Miss Then FBar(X + 1, 185, X + 9, 193, CLR_DARKGREEN)
    Else FBar(X + 1, 185, X + 9, 193, CLR_DARKRED);
  End;
  If Best > 0 Then OutTxt(PnX, 204, 'Record : ' + IStr(Best), CLR_DARKRED, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 6 * 16) Div 2, 0, 'Bubble', CLR_DARKBLUE, CLR_PALEGRAY);
  BigText(PnX + (PW - 7 * 16) Div 2, 30, 'Shooter', CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX, 64, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 82, PnX + PW - 1, 124, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 83, PnX + PW - 2, 123, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 84, PnX + PW - 3, 122, CLR_WHITE);
  DrawCounters;
  Button(PnX, 236, PW, 28, 'Nouvelle partie');
  Button(PnX, 270, PW, 28, 'Pause');
  OutTxt(PnX, 312, 'Souris : viser', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 328, 'Clic : tirer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 344, 'ou fl' + Chr(138) + 'ches et Espace', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 360, 'P : pause', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 376, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Function Sig : LongInt;
Begin
  Sig := Score * 7 + Level * 131 + Shots * 1009 + Miss * 10007 + Best * 3 + MissMax * 77 + CountBubbles * 5;
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(OX - 1, OY - 1, OX + BW, OY + BH, CLR_BLACK, CLR_PALEGRAY);
  If BackDirty <> 0 Then RenderBack;
  Move(Back, Fb, SizeOf(Fb));
  RX1 := 0; RY1 := 0; RX2 := -1; RY2 := -1;
  DrawSprites;
  RX1 := NX1; RY1 := NY1; RX2 := NX2; RY2 := NY2;
  FullBlit := 0;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  DrawPanel;
  DrawStatus;
  LastMsg := Msg; LastSig := Sig;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ une image : objets mobiles, zone changee (ancienne et nouvelle) recopiee }
Procedure Frame1;
Var X1, Y1, X2, Y2 : LongInt;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  If BackDirty <> 0 Then RenderBack;
  If FullBlit <> 0 Then
  Begin
    Move(Back, Fb, SizeOf(Fb));
    RX1 := 0; RY1 := 0; RX2 := -1; RY2 := -1;
  End;
  X1 := RX1; Y1 := RY1; X2 := RX2; Y2 := RY2;
  DrawSprites;
  RX1 := NX1; RY1 := NY1; RX2 := NX2; RY2 := NY2;
  If X2 < X1 Then
  Begin
    X1 := NX1; Y1 := NY1; X2 := NX2; Y2 := NY2;
  End
  Else If NX2 >= NX1 Then
  Begin
    X1 := MinI(X1, NX1); Y1 := MinI(Y1, NY1); X2 := MaxI(X2, NX2); Y2 := MaxI(Y2, NY2);
  End;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If FullBlit <> 0 Then
  Begin
    BlitRect(Hps, 0, 0, BW - 1, BH - 1);
    FullBlit := 0;
  End
  Else If X2 >= X1 Then BlitRect(Hps, X1 - 1, Y1 - 1, X2 + 1, Y2 + 1);
  If Sig <> LastSig Then
  Begin
    LastSig := Sig;
    DrawCounters;
  End;
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

Procedure Show(B1, B2 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; BannerC := C;
End;

Procedure AimMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue (Options).'
  Else Msg := 'Visez avec la souris et cliquez. Bulle ' + ColName[CurCol] + ', suivante : ' + ColName[NextCol] + '.';
End;

Procedure AddFloat(X, Y : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 0 To MaxFloat - 1 Do
    If FlOn[K] = 0 Then
    Begin
      FlOn[K] := 1; FlX[K] := MaxI(2, MinI(BW - Length(S) * 8 - 2, X - Length(S) * 4)); FlY[K] := Y;
      FlT[K] := 0; FlS[K] := S;
      Exit;
    End;
End;

Procedure AddScore(N : LongInt);
Begin
  Score := Score + N;
  If Score > Best Then Best := Score;
End;

Procedure ClearAnims;
Var K : LongInt;
Begin
  For K := 0 To MaxPop - 1 Do PopOn[K] := 0;
  For K := 0 To MaxFall - 1 Do FallOn[K] := 0;
  For K := 0 To MaxFloat - 1 Do FlOn[K] := 0;
End;

{ niveau L : rangees et couleurs, bulles voisines souvent de meme couleur }
Procedure FillLevel;
Var R, C, Rows, Col : LongInt;
Begin
  For R := 0 To MaxRow - 1 Do
    For C := 0 To COLS - 1 Do SetG(R, C, 0);
  Rows := MinI(4 + Level, 9);
  Colors := MinI(3 + Level, NCol);
  For R := 0 To Rows - 1 Do
    For C := 0 To COLS - 1 Do
    Begin
      Col := 1 + Rnd(Colors);
      If (C > 0) And (Rnd(100) < 40) Then Col := GAt(R, C - 1);
      If (R > 0) And (Rnd(100) < 25) Then Col := GAt(R - 1, C);
      SetG(R, C, Col);
    End;
  Top := TopStart;
  MissMax := MaxI(3, 8 - Level);
  Miss := 0;
End;

Procedure NewLevel;
Begin
  ClearAnims;
  FillLevel;
  GrayOut := 0;
  CurCol := PickColor; NextCol := PickColor;
  State := S_LEVEL; Wait := 0;
  Show('Niveau ' + IStr(Level), 'Clic ou Espace : commencer', C_YELLOW);
  Msg := 'Niveau ' + IStr(Level) + ' : ' + IStr(Colors) + ' couleurs. Le plafond descend apr' + Chr(138) + 's ' +
         IStr(MissMax) + ' tirs sans ' + Chr(130) + 'clatement.';
  BackDirty := 1;
  PlaySnd(6);
End;

Procedure NewGame;
Begin
  Level := StartLevel; Score := 0; Shots := 0; Popped := 0; Dropped := 0; Descents := 0; Cleared := 0;
  Ang := 900;
  NewLevel;
  Redraw;
End;

Procedure GameOver;
Begin
  State := S_OVER; Wait := 0;
  GrayOut := 1;
  BackDirty := 1;
  Show('Partie termin' + Chr(130) + 'e', 'Pointage : ' + IStr(Score) + ' - F2 : nouvelle partie', C_RED);
  Msg := 'Les bulles ont d' + Chr(130) + 'pass' + Chr(130) + ' la ligne rouge. Pointage : ' + IStr(Score) + '.';
  PlaySnd(7);
End;

Procedure CheckLost;
Begin
  If (State <> S_OVER) And (LowestY > DangerY) Then GameOver;
End;

{ la bulle tiree s'arrete en (X, Y) : accrochage, eclatement, chute,
  descente du plafond, fin du niveau ou de la partie }
Procedure Land(X, Y : LongInt);
Var R0, C0, N, R, C, K, D, Gain : LongInt;
Begin
  If Not AttachCell(X, Y, R0, C0) Then
  Begin
    GameOver;
    Exit;
  End;
  SetG(R0, C0, CurCol);
  Inc(Shots);
  N := Group(R0, C0, CurCol);
  If N >= 3 Then
  Begin
    D := Hanging;
    Gain := N * 10 + D * 20;
    AddScore(Gain);
    Popped := Popped + N; Dropped := Dropped + D;
    For R := 0 To MaxRow - 1 Do
      For C := 0 To COLS - 1 Do
      Begin
        If MAt(R, C) <> 0 Then
        Begin
          For K := 0 To MaxPop - 1 Do
            If PopOn[K] = 0 Then
            Begin
              PopOn[K] := 1; PopX[K] := CellX(R, C); PopY[K] := CellY(R); PopC[K] := GAt(R, C);
              PopT[K] := 0 - (Abs(R - R0) + Abs(C - C0));
              Break;
            End;
          SetG(R, C, 0);
        End
        Else If SAt(R, C) = 2 Then
        Begin
          For K := 0 To MaxFall - 1 Do
            If FallOn[K] = 0 Then
            Begin
              FallOn[K] := 1; FallX[K] := CellX(R, C); FallY[K] := CellY(R) * 256; FallV[K] := -Rnd(300);
              FallC[K] := GAt(R, C);
              Break;
            End;
          SetG(R, C, 0);
        End;
      End;
    AddFloat(CellX(R0, C0), CellY(R0) - 8, '+' + IStr(Gain));
    PlaySnd(3);
    If D > 0 Then PlaySnd(4);
    Miss := 0;
  End
  Else
  Begin
    PlaySnd(2);
    Inc(Miss);
    If Miss >= MissMax Then
    Begin
      Miss := 0;
      Top := Top + RH;
      Inc(Descents);
      Shake := 6;
      PlaySnd(5);
    End;
  End;
  BackDirty := 1;
  If CountBubbles = 0 Then
  Begin
    Gain := 500 + Level * 100;
    AddScore(Gain);
    Inc(Cleared);
    State := S_CLEAR; Wait := 0;
    Show('Bravo !', 'Niveau ' + IStr(Level) + ' termin' + Chr(130) + ' : bonus de ' + IStr(Gain) + ' points', C_GREEN);
    Msg := 'Tout est vide ! Clic ou Espace : niveau suivant.';
    PlaySnd(6);
    Exit;
  End;
  CheckLost;
  If State = S_OVER Then Exit;
  { prochaine bulle : une couleur encore presente }
  CurCol := NextCol;
  If Not ColorPresent(CurCol) Then CurCol := PickColor;
  NextCol := PickColor;
  State := S_AIM;
  AimMsg;
End;

Procedure Fire;
Begin
  If State <> S_AIM Then Exit;
  StartShot(Ang, PX, PY, PVX, PVY);
  Bounces := 0;
  State := S_FLY;
  PlaySnd(0);
End;

{ la bulle tiree avance de 16 points (8 pas de 2) }
Procedure MoveShot;
Var K, B0 : LongInt; Hit : Boolean;
Begin
  If State <> S_FLY Then Exit;
  B0 := Bounces;
  Hit := False; K := 0;
  While (Not Hit) And (K < 8) Do
  Begin
    Hit := ProjStep(PX, PY, PVX, PVY, Bounces);
    Inc(K);
  End;
  If Bounces <> B0 Then PlaySnd(1);
  If Hit Then Land(PX, PY);
End;

Procedure MoveAnims;
Var K : LongInt;
Begin
  For K := 0 To MaxPop - 1 Do
    If PopOn[K] <> 0 Then
    Begin
      Inc(PopT[K]);
      If PopT[K] > 10 Then PopOn[K] := 0;
    End;
  For K := 0 To MaxFall - 1 Do
    If FallOn[K] <> 0 Then
    Begin
      FallV[K] := FallV[K] + 90;
      FallY[K] := FallY[K] + FallV[K];
      If FallY[K] Div 256 > BH + BR Then FallOn[K] := 0;
    End;
  For K := 0 To MaxFloat - 1 Do
    If FlOn[K] <> 0 Then
    Begin
      Inc(FlT[K]);
      If FlT[K] Mod 2 = 0 Then Dec(FlY[K]);
      If FlT[K] > 40 Then FlOn[K] := 0;
    End;
End;

{ demonstration : l'angle qui fait eclater le plus de bulles }
Function BestAngle : LongInt;
Var A, R0, C0, N, D, V, BestV, BestA : LongInt;
Begin
  BestV := -1000000; BestA := 900;
  A := 100;
  While A <= 1700 Do
  Begin
    If Simulate(A, R0, C0) Then
    Begin
      SetG(R0, C0, CurCol);
      N := Group(R0, C0, CurCol);
      If N >= 3 Then
      Begin
        D := Hanging;
        V := 1000 + N * 10 + D * 25;
      End
      Else V := N * 40 - R0 * 6;
      SetG(R0, C0, 0);
      { leger hasard pour varier les parties egales }
      V := V * 8 + Rnd(8);
      If V > BestV Then
      Begin
        BestV := V; BestA := A;
      End;
    End;
    A := A + 10;
  End;
  BestAngle := BestA;
End;

Procedure TimerTick;
Begin
  If (State = S_PAUSE) Or (InDlg > 0) Then Exit;
  Inc(Tick);
  MoveShot;
  MoveAnims;
  If Shake > 0 Then Dec(Shake);
  Case State Of
    S_LEVEL :
      Begin
        Inc(Wait);
        If (Wait > 60) Or ((AutoAll <> 0) And (Wait > 25)) Then
        Begin
          State := S_AIM; Banner := '';
          AimMsg;
        End;
      End;
    S_AIM :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait = 4 Then Ang := BestAngle;
        If Wait > 14 Then
        Begin
          Wait := 0;
          Fire;
        End;
      End;
    S_CLEAR :
      Begin
        Inc(Wait);
        If (AutoAll <> 0) And (Wait > 60) Then
        Begin
          Inc(Level);
          NewLevel;
        End;
      End;
    S_OVER :
      If AutoAll <> 0 Then
      Begin
        Inc(Wait);
        If Wait > 110 Then NewGame;
      End;
  End;
  Frame1;
End;

Procedure TogglePause;
Begin
  If (State = S_AIM) Or (State = S_FLY) Or (State = S_LEVEL) Then
  Begin
    OldState := State;
    State := S_PAUSE;
    Show('Pause', 'P ou Espace : reprendre', C_GREEN);
    Msg := 'Pause.';
    Frame1;
  End
  Else If State = S_PAUSE Then
  Begin
    State := OldState; Banner := '';
    AimMsg;
    Frame1;
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

Procedure SetMarks;
Begin
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0); SetMark(CM_GUIDE, GuideOn <> 0);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_PAUSE : TogglePause;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO : Begin AutoAll := 1 - AutoAll; SetMarks; Wait := 0; If State = S_AIM Then AimMsg; End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_GUIDE : Begin GuideOn := 1 - GuideOn; SetMarks; End;
    CM_RULES :
      Begin
        If (State = S_AIM) Or (State = S_FLY) Then TogglePause;
        LClr;
        LAdd('Le canon, en bas, tire des bulles de couleur vers les bulles accroch' + Chr(130) + 'es au plafond. ');
        LAdd('Visez avec la souris (ou les fl' + Chr(138) + 'ches gauche et droite) et cliquez (ou Espace) : la ' +
             'bulle part en ligne droite, rebondit sur les murs et s''accroche ' + Chr(133) + ' la premi' + Chr(138) +
             're bulle qu''elle touche. ');
        LAdd('Trois bulles ou plus de la m' + Chr(136) + 'me couleur qui se touchent ' + Chr(130) + 'clatent (10 ' +
             'points chacune) ; les bulles qui ne tiennent plus au plafond tombent (20 points chacune).' + Chr(10) +
             Chr(10));
        LAdd('Apr' + Chr(138) + 's quelques tirs sans ' + Chr(130) + 'clatement (cases du panneau), le plafond ' +
             'descend d''une rang' + Chr(130) + 'e. Une bulle sous la ligne rouge : la partie est perdue. ');
        LAdd('Tout est vide : le niveau est gagn' + Chr(130) + ' (bonus) ; chaque niveau a plus de rang' + Chr(130) +
             'es et de couleurs. ');
        LAdd('La bulle suivante est affich' + Chr(130) + 'e en bas ' + Chr(133) + ' gauche ; la bulle charg' +
             Chr(130) + 'e est toujours d''une couleur encore pr' + Chr(130) + 'sente.' + Chr(10) + Chr(10));
        LAdd('Clavier : fl' + Chr(138) + 'ches (viser), Espace, Entr' + Chr(130) + 'e ou fl' + Chr(138) +
             'che haut (tirer), P (pause), F2 (nouvelle partie).');
        Dummy := LMsgBox('Bubble Shooter - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Bubble Shooter pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype BS.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
End;

Procedure Action;
Begin
  Case State Of
    S_AIM : If AutoAll = 0 Then Fire;
    S_LEVEL :
      Begin
        State := S_AIM; Banner := '';
        AimMsg;
      End;
    S_CLEAR :
      Begin
        Inc(Level);
        NewLevel;
        Redraw;
      End;
    S_PAUSE : TogglePause;
    S_OVER : NewGame;
  End;
End;

Procedure Turn(D : LongInt);
Begin
  Ang := MaxI(100, MinI(1700, Ang + D));
End;

{ angle vers le point (X, Y) de l'image }
Procedure AimAt(X, Y : LongInt);
Var Dx, Dy : LongInt; A : Real;
Begin
  Dx := X - CanX; Dy := CanY - Y;
  If Dy < 4 Then Dy := 4;
  A := ArcTan(Dy / (Abs(Dx) + 0.0001)) * 1800 / Pi;
  If Dx < 0 Then A := 1800 - A;
  Ang := MaxI(100, MinI(1700, Round(A)));
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
    If Vk = VK_LEFT Then Begin Turn(25); Exit; End;
    If Vk = VK_RIGHT Then Begin Turn(-25); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_UP) Then Begin Action; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'P' : TogglePause;
      'N' : NewGame;
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
    If (Y >= 236) And (Y < 264) Then NewGame
    Else If (Y >= 270) And (Y < 298) Then TogglePause;
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If (State = S_AIM) And (AutoAll = 0) Then AimAt(X - OX, Y - OY);
    Action;
  End;
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
        If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) And (AutoAll = 0) And
           (State <> S_PAUSE) And (State <> S_OVER) Then AimAt(X - OX, Y - OY);
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
{ Essais (/TEST) : grille, eclatement, chute, partie de l'ordinateur    }
{ ==================================================================== }

Procedure ClearGrid;
Var R, C : LongInt;
Begin
  For R := 0 To MaxRow - 1 Do
    For C := 0 To COLS - 1 Do SetG(R, C, 0);
  Top := TopStart;
End;

Procedure RunTests;
Var R0, C0, N, D, K, Ok, A : LongInt; S : String;
Begin
  Ok := 0;
  { 1 : deux rouges au plafond + tir rouge droit dessous -> 3 eclatees }
  ClearGrid;
  SetG(0, 5, 1); SetG(0, 6, 1); SetG(0, 7, 2);
  CurCol := 1;
  StartShot(900, PX, PY, PVX, PVY);
  K := 0; Bounces := 0;
  While (K < 2000) And Not ProjStep(PX, PY, PVX, PVY, Bounces) Do Inc(K);
  If AttachCell(PX, PY, R0, C0) Then
  Begin
    SetG(R0, C0, 1);
    N := Group(R0, C0, 1);
    D := Hanging;
  End
  Else
  Begin
    N := -1; D := -1;
  End;
  S := 'TEST1 accroche ' + IStr(R0) + ',' + IStr(C0) + ' groupe ' + IStr(N) + ' chute ' + IStr(D);
  Log('BUBBLE : ' + S);
  If (R0 = 1) And (N = 3) And (D = 0) Then Inc(Ok);
  { 2 : groupe rouge qui porte deux bulles bleues -> 3 eclatees, 2 tombent }
  ClearGrid;
  SetG(0, 3, 1); SetG(1, 3, 1); SetG(2, 3, 4); SetG(3, 3, 4); SetG(0, 0, 2);
  SetG(1, 2, 1);
  N := Group(1, 3, 1);
  D := Hanging;
  Log('BUBBLE : TEST2 groupe ' + IStr(N) + ' chute ' + IStr(D));
  If (N = 3) And (D = 2) Then Inc(Ok);
  { 3 : rebond sur le mur gauche puis accrochage au plafond }
  ClearGrid;
  CurCol := 3;
  StartShot(1500, PX, PY, PVX, PVY);
  K := 0; Bounces := 0;
  While (K < 2000) And Not ProjStep(PX, PY, PVX, PVY, Bounces) Do Inc(K);
  A := 0;
  If AttachCell(PX, PY, R0, C0) Then A := 1;
  Log('BUBBLE : TEST3 rebonds ' + IStr(Bounces) + ' rangee ' + IStr(R0) + ' accroche ' + IStr(A));
  If (Bounces >= 1) And (R0 = 0) And (A = 1) Then Inc(Ok);
  { 4 : partie jouee par l'ordinateur (graine fixe, 120 tirs au plus) }
  Seed := 1234; Level := 1; Score := 0; Shots := 0; Popped := 0; Dropped := 0; Descents := 0; Cleared := 0;
  FillLevel;
  CurCol := PickColor; NextCol := PickColor;
  State := S_AIM;
  K := 0;
  While (K < 120) And (State <> S_OVER) Do
  Begin
    If State = S_CLEAR Then
    Begin
      Inc(Level);
      FillLevel;
      CurCol := PickColor; NextCol := PickColor;
      State := S_AIM;
    End;
    Ang := BestAngle;
    Fire;
    N := 0;
    While (State = S_FLY) And (N < 1000) Do
    Begin
      MoveShot;
      Inc(N);
    End;
    Inc(K);
  End;
  Log('BUBBLE : PARTIE tirs ' + IStr(Shots) + ' eclatees ' + IStr(Popped) + ' tombees ' + IStr(Dropped) +
      ' niveaux ' + IStr(Cleared) + ' descentes ' + IStr(Descents) + ' pointage ' + IStr(Score));
  Log('BUBBLE : ' + IStr(Ok) + '/3 essais reussis');
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
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Best := 0; Tick := 0; Client := 0;
  Frame := 0; SoundOn := 1; GuideOn := 1; StartLevel := 1; Level := 1; SndCur := 0; SndEnd := 0; Score := 0;
  TestMode := 0; GrayOut := 0; Shake := 0; State := S_LEVEL; Ang := 900; CW := CWant; CH := CHWant;
  RX1 := 0; RY1 := 0; RX2 := -1; RY2 := -1; FullBlit := 1; BackDirty := 1;
  For K := 0 To 1800 Do
  Begin
    CosT[K] := Round(Cos(K * Pi / 1800) * 256);
    SinT[K] := Round(Sin(K * Pi / 1800) * 256);
  End;
  ClearAnims;
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
  MakeSprites;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('BUBBLE'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('BUBBLE'), Z2('Bubble Shooter'), 0, 0, 0,
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
  MItem(MIS_TEXT, 0, CM_GUIDE, '~Ligne de vis' + Chr(130) + 'e');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 3);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Bubble Shooter');
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
