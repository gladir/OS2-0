{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2011 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BLOX - blocs qui tombent, avec des briques deja posees au
                fond du puits, pour le Presentation Manager d'OS/2-0
                (dossier Jeux du bureau).
}

Program BLOX;

{$R-,S-,I-}

{ Compilation : OS2PC BLOX.PAS   (produit BLOX.EXE)

  Portage vers OS/2-0 du prototype BLOX.PAS du depot 7iles (Turbo Pascal,
  BGI ou texte en 40 colonnes) : fenetre de Presentation Manager avec
  menus, image en memoire recopiee par GpiDrawBits (sans scintillement),
  puits encadre en relief, blocs en relief, briques maconnees, panneaux
  gris a la facon de Warp 3, piece suivante, ombre de la piece, lignes
  qui clignotent avant de disparaitre, barre d'etat.

  Comme le prototype : sept pieces de quatre blocs (Barre, Boite, V, L
  gauche, L droite, Serpent romain, Serpent arabe) tombent dans un puits
  de 10 x 20 ; une ligne complete disparait ; des morceaux de briques
  sont deja poses au fond du puits au depart, d'autant plus que le niveau
  est eleve ; la vitesse augmente avec le niveau.
  Ce qui s'ajoute : chute immediate (Espace), rotation dans les deux sens
  avec decalage contre les murs, piece suivante, ombre, pointage par
  lignes simultanees (100, 300, 500, 800 fois le niveau), prime quand
  toutes les briques de depart sont detruites, a chaque niveau une
  rangee de briques monte du fond, pause, record, niveau de depart,
  demonstration (l'ordinateur joue), sons.
  Ce qui est corrige : les pieces n'etaient pas tirees au hasard de
  facon egale (les deux serpents sortaient deux fois moins souvent) ;
  les briques de depart pouvaient former une ligne deja complete ; les
  couleurs des blocs changeaient a chaque rafraichissement ; le niveau 0
  s'affichait 1 ; « Partie Terminer ».

  Clavier : Gauche et Droite (deplacer), Haut ou X (tourner), Z (tourner
  dans l'autre sens), Bas (descendre), Espace (chute), P (pause), F2
  (nouvelle partie), F1 (regles) ; 4, 6, 8, 5 et 2 du pave numerique
  comme le prototype.
  Parametres : /SEED:n ; /LEVEL:n (niveau de depart, 1 a 9) ; /AUTO
  (demonstration) ; /NOSOUND ; /TEST (essais des rotations, des lignes,
  des briques de depart, puis une partie jouee par l'ordinateur,
  resultat sur le port serie COM1). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_QUERY = $10; MB_INFORMATION = $30; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_PAUSE = 102; CM_QUIT = 104;
  CM_GHOST = 201; CM_AUTO = 202; CM_SOUND = 203;
  CM_LEVEL = 210;                              { 211..219 : niveau de depart }
  CM_RULES = 301; CM_ABOUT = 302;
  { image }
  BW = 560; BH = 392; OX = 8; OY = 8;
  CWant = 576; CHWant = 430;
  { puits }
  NX = 10; NY = 20; Cell = 18;
  WX = 190; WY = 16;                           { coin du puits dans l'image }
  NPiece = 7;
  { couleurs de l'image }
  C_BG = 0;                                    { 0..15 : fond }
  C_PIECE = 16;                                { 16 + piece * 8 : 0 base, 1 clair, 2 tres clair, 3 sombre, 4 tres sombre }
  C_BRICK = 80;                                { 80..85 : briques et mortier }
  C_GRAYB = 88;                                { 88..92 : blocs grises (fin de partie) }
  C_WELL = 96; C_WELL2 = 97; C_GRID = 98;
  C_PANEL = 100; C_HI = 101; C_LO = 102; C_DARK = 103; C_INK = 104; C_VAL = 105; C_WHITE = 106;
  C_BLACK = 107; C_GOLD = 108; C_BANNER = 109; C_FLASH = 110; C_GHOST = 111; C_TITLE = 112; C_SHADOW = 113;
  C_RED = 114; C_BAR = 115;
  { etats }
  S_PLAY = 1; S_CLEAR = 2; S_OVER = 3; S_IDLE = 4;
  SndRate = 11025;
  PieceCol : Array[0..6] Of LongInt = ($20B8E0, $F0C020, $A050D8, $F08A20, $3070E8, $40C050, $E04040);
  { forme de depart de chaque piece (4 blocs x, y) et taille de sa boite }
  Shp : Array[0..55] Of LongInt = (0, 1, 1, 1, 2, 1, 3, 1,      { Barre }
                                   0, 0, 1, 0, 0, 1, 1, 1,      { Boite }
                                   1, 0, 0, 1, 1, 1, 2, 1,      { V }
                                   0, 0, 0, 1, 1, 1, 2, 1,      { L gauche }
                                   2, 0, 0, 1, 1, 1, 2, 1,      { L droite }
                                   1, 0, 2, 0, 0, 1, 1, 1,      { Serpent romain }
                                   0, 0, 1, 0, 1, 1, 2, 1);     { Serpent arabe }
  ShpBox : Array[0..6] Of LongInt = (4, 2, 3, 3, 3, 3, 3);
  LinePts : Array[0..4] Of LongInt = (0, 100, 300, 500, 800);

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { puits : 0 vide, 1..7 piece, 8 brique ; rangee 0 en haut }
  Board : Array[0..NX * NY - 1] Of LongInt;
  { formes : PX/PY[piece * 16 + rotation * 4 + bloc] }
  PX, PY : Array[0..NPiece * 16 - 1] Of LongInt;
  Box : Array[0..NPiece - 1] Of LongInt;
  Bag : Array[0..6] Of LongInt;
  BagN : LongInt;
  Cur, Rot, PosX, PosY, Next : LongInt;
  State, Score, Best, Level, StartLevel, Lines, Pieces, Bricks, Fall, Delay, Paused, LockWait : LongInt;
  Seed, AutoAll, SoundOn, Ghost, TestMode, Tick, Anim, OverRow, BonusShown : LongInt;
  FullRow : Array[0..NY - 1] Of LongInt;
  NFull, BanT : LongInt;
  TB : Array[0..NX * NY - 1] Of LongInt;
  AiRot, AiX, AiOn : LongInt;
  Banner, Banner2, Msg, LastMsg : String;
  BannerC, Dirty : LongInt;
  SndBuf : Array[0..59999] Of Byte;
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
{ Regles : pieces, puits, briques                                       }
{ ==================================================================== }

Procedure InitShapes;
Var P, R, I, N, X, Y, T : LongInt;
Begin
  For P := 0 To NPiece - 1 Do
  Begin
    N := ShpBox[P];
    Box[P] := N;
    For I := 0 To 3 Do
    Begin
      X := Shp[P * 8 + I * 2]; Y := Shp[P * 8 + I * 2 + 1];
      For R := 0 To 3 Do
      Begin
        PX[P * 16 + R * 4 + I] := X; PY[P * 16 + R * 4 + I] := Y;
        { quart de tour dans le sens des aiguilles d'une montre }
        T := X; X := N - 1 - Y; Y := T;
      End;
    End;
  End;
End;

Function Fits(P, R, X, Y : LongInt) : Boolean;
Var I, Cx, Cy : LongInt;
Begin
  Fits := False;
  For I := 0 To 3 Do
  Begin
    Cx := X + PX[P * 16 + R * 4 + I]; Cy := Y + PY[P * 16 + R * 4 + I];
    If (Cx < 0) Or (Cx >= NX) Or (Cy >= NY) Then Exit;
    If Cy >= 0 Then
      If Board[Cy * NX + Cx] <> 0 Then Exit;
  End;
  Fits := True;
End;

Function MinRow(P, R : LongInt) : LongInt;
Var I, M : LongInt;
Begin
  M := 9;
  For I := 0 To 3 Do M := MinI(M, PY[P * 16 + R * 4 + I]);
  MinRow := M;
End;

{ les sept pieces dans un sac, tirees dans un ordre melange }
Function FromBag : LongInt;
Var I, J, T : LongInt;
Begin
  If BagN <= 0 Then
  Begin
    For I := 0 To 6 Do Bag[I] := I;
    For I := 6 DownTo 1 Do
    Begin
      J := Rnd(I + 1);
      T := Bag[I]; Bag[I] := Bag[J]; Bag[J] := T;
    End;
    BagN := 7;
  End;
  Dec(BagN);
  FromBag := Bag[BagN];
End;

Function CountBricks : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To NX * NY - 1 Do If Board[I] = 8 Then Inc(N);
  CountBricks := N;
End;

Function DelayFor(L : LongInt) : LongInt;
Begin
  DelayFor := MaxI(3, 26 - 2 * L);
End;

Function BrickRows(L : LongInt) : LongInt;
Begin
  BrickRows := MinI(2 + L, 11);
End;

{ une rangee de briques avec au moins deux trous }
Procedure BrickRow(Y, Holes : LongInt);
Var X, K, N : LongInt;
Begin
  For X := 0 To NX - 1 Do Board[Y * NX + X] := 8;
  N := 0; K := 0;
  While (N < Holes) And (K < 100) Do
  Begin
    X := Rnd(NX);
    If Board[Y * NX + X] <> 0 Then
    Begin
      Board[Y * NX + X] := 0;
      Inc(N);
    End;
    Inc(K);
  End;
End;

{ briques de depart : plus nombreuses quand le niveau est eleve,
  plus clairsemees vers le haut du tas }
Procedure MakeBricks(L : LongInt);
Var R, Rows : LongInt;
Begin
  FillChar(Board, SizeOf(Board), 0);
  Rows := BrickRows(L);
  For R := 0 To Rows - 1 Do
    If R >= Rows - 2 Then BrickRow(NY - 1 - R, 4 + Rnd(3))
    Else BrickRow(NY - 1 - R, 2 + Rnd(3));
  Bricks := CountBricks;
End;

Function RowFull(Y : LongInt) : Boolean;
Var X : LongInt;
Begin
  RowFull := False;
  For X := 0 To NX - 1 Do If Board[Y * NX + X] = 0 Then Exit;
  RowFull := True;
End;

Function Spawn : Boolean;
Begin
  Cur := Next; Next := FromBag;
  Rot := 0;
  PosX := (NX - Box[Cur]) Div 2;
  PosY := -MinRow(Cur, 0);
  Fall := 0; AiOn := 0;
  Spawn := Fits(Cur, Rot, PosX, PosY);
End;

Function TryMove(Dx, Dy : LongInt) : Boolean;
Begin
  TryMove := False;
  If Not Fits(Cur, Rot, PosX + Dx, PosY + Dy) Then Exit;
  PosX := PosX + Dx; PosY := PosY + Dy;
  TryMove := True;
End;

{ rotation avec decalage contre les murs et les blocs }
Function TryRotate(Dir : LongInt) : Boolean;
Var R, K, D : LongInt;
Begin
  TryRotate := False;
  R := (Rot + Dir + 4) Mod 4;
  For K := 0 To 4 Do
  Begin
    Case K Of
      0 : D := 0; 1 : D := -1; 2 : D := 1; 3 : D := -2;
    Else D := 2;
    End;
    If Fits(Cur, R, PosX + D, PosY) Then
    Begin
      Rot := R; PosX := PosX + D;
      TryRotate := True;
      Exit;
    End;
  End;
  { contre le fond : remonter d'une rangee }
  If Fits(Cur, R, PosX, PosY - 1) Then
  Begin
    Rot := R; PosY := PosY - 1;
    TryRotate := True;
  End;
End;

Function DropY : LongInt;
Var Y : LongInt;
Begin
  Y := PosY;
  While Fits(Cur, Rot, PosX, Y + 1) Do Inc(Y);
  DropY := Y;
End;

{ pose la piece ; rend faux si elle depasse le haut du puits }
Function Place : Boolean;
Var I, Cx, Cy : LongInt;
Begin
  Place := True;
  For I := 0 To 3 Do
  Begin
    Cx := PosX + PX[Cur * 16 + Rot * 4 + I]; Cy := PosY + PY[Cur * 16 + Rot * 4 + I];
    If Cy < 0 Then Place := False Else Board[Cy * NX + Cx] := Cur + 1;
  End;
  Inc(Pieces);
End;

Procedure FindFull;
Var Y : LongInt;
Begin
  NFull := 0;
  For Y := 0 To NY - 1 Do
    If RowFull(Y) Then
    Begin
      FullRow[NFull] := Y;
      Inc(NFull);
    End;
End;

{ une rangee de briques monte du fond ; rend faux si le tas deborde }
Function RaiseRow : Boolean;
Var X, Y : LongInt;
Begin
  RaiseRow := True;
  For X := 0 To NX - 1 Do If Board[X] <> 0 Then RaiseRow := False;
  For Y := 0 To NY - 2 Do
    For X := 0 To NX - 1 Do Board[Y * NX + X] := Board[(Y + 1) * NX + X];
  BrickRow(NY - 1, 2 + Rnd(2));
  Bricks := CountBricks;
End;

{ efface les lignes completes ; rend 1 si le niveau monte, 2 si les
  briques sont toutes detruites, 3 les deux, 0 sinon }
Function ClearFull : LongInt;
Var K, Y, X, N, Old, NewL, Res : LongInt;
Begin
  Res := 0;
  N := NFull;
  Old := Bricks;
  For K := 0 To N - 1 Do
  Begin
    For Y := FullRow[K] DownTo 1 Do
      For X := 0 To NX - 1 Do Board[Y * NX + X] := Board[(Y - 1) * NX + X];
    For X := 0 To NX - 1 Do Board[X] := 0;
  End;
  NFull := 0;
  Score := Score + LinePts[MinI(N, 4)] * Level;
  Lines := Lines + N;
  Bricks := CountBricks;
  If (Old > 0) And (Bricks = 0) Then
  Begin
    Score := Score + 1000 * Level;
    Res := Res Or 2;
  End;
  NewL := StartLevel + Lines Div 10;
  If NewL > Level Then
  Begin
    Level := NewL;
    Delay := DelayFor(Level);
    Res := Res Or 1;
  End;
  If Score > Best Then Best := Score;
  ClearFull := Res;
End;

{ ==================================================================== }
{ Joueur automatique (demonstration et essais)                          }
{ ==================================================================== }

Function Evaluate(P, R, X : LongInt; Var Ok : Boolean) : LongInt;
Var Y, I, Cx, Cy, Ln, Agg, Holes, Bump, H, PrevH, Top : LongInt; Full : Boolean;
Begin
  Evaluate := -1000000000; Ok := False;
  Y := -MinRow(P, R);
  If Not Fits(P, R, X, Y) Then Exit;
  While Fits(P, R, X, Y + 1) Do Inc(Y);
  Move(Board, TB, SizeOf(Board));
  For I := 0 To 3 Do
  Begin
    Cx := X + PX[P * 16 + R * 4 + I]; Cy := Y + PY[P * 16 + R * 4 + I];
    If Cy < 0 Then Exit;
    TB[Cy * NX + Cx] := 9;
  End;
  Ok := True;
  { lignes completes retirees }
  Ln := 0;
  For Cy := NY - 1 DownTo 0 Do
  Begin
    Full := True;
    For Cx := 0 To NX - 1 Do If TB[Cy * NX + Cx] = 0 Then Full := False;
    If Full Then Inc(Ln)
    Else If Ln > 0 Then
      For Cx := 0 To NX - 1 Do TB[(Cy + Ln) * NX + Cx] := TB[Cy * NX + Cx];
  End;
  For Cy := 0 To Ln - 1 Do
    For Cx := 0 To NX - 1 Do TB[Cy * NX + Cx] := 0;
  Agg := 0; Holes := 0; Bump := 0; PrevH := -1;
  For Cx := 0 To NX - 1 Do
  Begin
    Top := NY;
    For Cy := NY - 1 DownTo 0 Do If TB[Cy * NX + Cx] <> 0 Then Top := Cy;
    H := NY - Top;
    Agg := Agg + H;
    For Cy := Top + 1 To NY - 1 Do If TB[Cy * NX + Cx] = 0 Then Inc(Holes);
    If PrevH >= 0 Then Bump := Bump + Abs(H - PrevH);
    PrevH := H;
  End;
  Evaluate := 761 * Ln - 510 * Agg - 357 * Holes - 184 * Bump;
End;

Procedure Plan;
Var R, X, V, BestV : LongInt; Ok : Boolean;
Begin
  BestV := -2000000000; AiRot := 0; AiX := PosX;
  For R := 0 To 3 Do
    For X := -2 To NX - 1 Do
    Begin
      V := Evaluate(Cur, R, X, Ok);
      If Ok And (V > BestV) Then
      Begin
        BestV := V; AiRot := R; AiX := X;
      End;
    End;
  AiOn := 1;
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
  For I := 0 To 15 Do SetPal(C_BG + I, Mix($0A1030, $2C4478, I, 15));
  For K := 0 To 6 Do
  Begin
    C := PieceCol[K];
    SetPal(C_PIECE + K * 8, C);
    SetPal(C_PIECE + K * 8 + 1, Mix(C, $FFFFFF, 4, 10));
    SetPal(C_PIECE + K * 8 + 2, Mix(C, $FFFFFF, 8, 10));
    SetPal(C_PIECE + K * 8 + 3, Mix(C, $000000, 4, 10));
    SetPal(C_PIECE + K * 8 + 4, Mix(C, $000000, 7, 10));
    SetPal(C_PIECE + K * 8 + 5, Mix(C, $0A0E1A, 6, 10));
  End;
  SetPal(C_BRICK, $A8482C); SetPal(C_BRICK + 1, $D07454); SetPal(C_BRICK + 2, $6A2614);
  SetPal(C_BRICK + 3, $9C9488); SetPal(C_BRICK + 4, $5E5850); SetPal(C_BRICK + 5, $8A3820);
  For I := 0 To 4 Do SetPal(C_GRAYB + I, Mix($303438, $C8CCD0, I, 4));
  SetPal(C_WELL, $080C18); SetPal(C_WELL2, $0E1424); SetPal(C_GRID, $161E34);
  SetPal(C_PANEL, $CCCCCC); SetPal(C_HI, $FFFFFF); SetPal(C_LO, $808080); SetPal(C_DARK, $404040);
  SetPal(C_INK, $000000); SetPal(C_VAL, $00207C); SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $000000);
  SetPal(C_GOLD, $F4CC40); SetPal(C_BANNER, $101A3C); SetPal(C_FLASH, $FFFFFF); SetPal(C_GHOST, $6A7CA8);
  SetPal(C_TITLE, $E8ECF8); SetPal(C_SHADOW, $04060E); SetPal(C_RED, $E03C3C); SetPal(C_BAR, $2C7CD0);
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

Procedure FbCenter(Cx, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(Cx - Length(S) * 4 * Sc + 2, Y + 2, S, C_SHADOW, Sc);
  FbText(Cx - Length(S) * 4 * Sc, Y, S, C, Sc);
End;

Procedure FbRight(X2, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbText(X2 - Length(S) * 8 * Sc, Y, S, C, Sc);
End;

{ cadre en relief : enfonce (Sunk) ou en saillie }
Procedure Bevel(X1, Y1, X2, Y2 : LongInt; Sunk : Boolean);
Var A, B : LongInt;
Begin
  If Sunk Then Begin A := C_LO; B := C_HI; End Else Begin A := C_HI; B := C_LO; End;
  Rect(X1, Y1, X2, Y1, A); Rect(X1, Y1, X1, Y2, A);
  Rect(X1, Y2, X2, Y2, B); Rect(X2, Y1, X2, Y2, B);
End;

{ panneau gris a la facon de Warp, avec son titre }
Procedure Panel(X1, Y1, X2, Y2 : LongInt; T : String);
Begin
  Rect(X1 + 3, Y1 + 3, X2 + 3, Y2 + 3, C_SHADOW);
  Rect(X1, Y1, X2, Y2, C_PANEL);
  Bevel(X1, Y1, X2, Y2, False);
  Bevel(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, False);
  If T <> '' Then FbText(X1 + 8, Y1 + 5, T, C_INK, 1);
End;

{ un bloc en relief de la piece P (0..6), une brique (7) ou un bloc grise (8) }
Procedure DrawBlock(X, Y, P : LongInt);
Var B, K : LongInt;
Begin
  If P = 7 Then
  Begin
    Rect(X, Y, X + Cell - 1, Y + Cell - 1, C_BRICK + 3);
    { rang du haut : une brique ; rang du bas : deux demi-briques }
    Rect(X, Y, X + Cell - 3, Y + 7, C_BRICK);
    Rect(X, Y, X + Cell - 3, Y, C_BRICK + 1);
    Rect(X, Y + 7, X + Cell - 3, Y + 7, C_BRICK + 2);
    Rect(X + Cell - 2, Y, X + Cell - 1, Y + 7, C_BRICK + 3);
    Rect(X, Y + 9, X + 6, Y + 16, C_BRICK + 5);
    Rect(X, Y + 9, X + 6, Y + 9, C_BRICK + 1);
    Rect(X, Y + 16, X + 6, Y + 16, C_BRICK + 2);
    Rect(X + 9, Y + 9, X + Cell - 1, Y + 16, C_BRICK);
    Rect(X + 9, Y + 9, X + Cell - 1, Y + 9, C_BRICK + 1);
    Rect(X + 9, Y + 16, X + Cell - 1, Y + 16, C_BRICK + 2);
    Rect(X, Y + 8, X + Cell - 1, Y + 8, C_BRICK + 4);
    Rect(X, Y + Cell - 1, X + Cell - 1, Y + Cell - 1, C_BRICK + 4);
    Pix(X + 3, Y + 3, C_BRICK + 2); Pix(X + 11, Y + 5, C_BRICK + 2); Pix(X + 13, Y + 12, C_BRICK + 2);
    Exit;
  End;
  If P = 8 Then
  Begin
    Rect(X, Y, X + Cell - 1, Y + Cell - 1, C_GRAYB + 2);
    Rect(X, Y, X + Cell - 1, Y + 1, C_GRAYB + 4); Rect(X, Y, X + 1, Y + Cell - 1, C_GRAYB + 3);
    Rect(X, Y + Cell - 2, X + Cell - 1, Y + Cell - 1, C_GRAYB); Rect(X + Cell - 2, Y, X + Cell - 1, Y + Cell - 1, C_GRAYB + 1);
    Exit;
  End;
  B := C_PIECE + P * 8;
  Rect(X, Y, X + Cell - 1, Y + Cell - 1, B);
  { arete claire en haut et a gauche, sombre en bas et a droite }
  For K := 0 To 2 Do
  Begin
    Rect(X + K, Y + K, X + Cell - 1 - K, Y + K, B + 1);
    Rect(X + K, Y + K, X + K, Y + Cell - 1 - K, B + 1);
    Rect(X + K, Y + Cell - 1 - K, X + Cell - 1 - K, Y + Cell - 1 - K, B + 3);
    Rect(X + Cell - 1 - K, Y + K, X + Cell - 1 - K, Y + Cell - 1 - K, B + 3);
  End;
  Rect(X, Y, X + Cell - 1, Y, B + 2); Rect(X, Y, X, Y + Cell - 1, B + 2);
  Rect(X, Y + Cell - 1, X + Cell - 1, Y + Cell - 1, B + 4); Rect(X + Cell - 1, Y, X + Cell - 1, Y + Cell - 1, B + 4);
  { reflet }
  Rect(X + 4, Y + 4, X + 6, Y + 5, B + 2); Pix(X + 4, Y + 6, B + 2);
End;

Procedure GhostBlock(X, Y, P : LongInt);
Var B : LongInt;
Begin
  B := C_PIECE + P * 8 + 5;
  Rect(X + 1, Y + 1, X + Cell - 2, Y + Cell - 2, B);
  Rect(X + 1, Y + 1, X + Cell - 2, Y + 1, C_GHOST); Rect(X + 1, Y + Cell - 2, X + Cell - 2, Y + Cell - 2, C_GHOST);
  Rect(X + 1, Y + 1, X + 1, Y + Cell - 2, C_GHOST); Rect(X + Cell - 2, Y + 1, X + Cell - 2, Y + Cell - 2, C_GHOST);
End;

{ titre en lettres faites de petits blocs }
Procedure BlockTitle(X, Y : LongInt; S : String);
Var I, R, K, B, P, Px, Py : LongInt;
Begin
  If FontH = 0 Then Exit;
  For I := 1 To Length(S) Do
  Begin
    P := C_PIECE + ((I * 3) Mod 7) * 8;
    For R := 2 To FontH - 3 Do
    Begin
      B := Font[Ord(S[I]) * FontH + R];
      For K := 0 To 7 Do
        If (B And ($80 Shr K)) <> 0 Then
        Begin
          Px := X + ((I - 1) * 8 + K) * 4; Py := Y + (R - 2) * 4;
          Rect(Px + 1, Py + 1, Px + 4, Py + 4, C_SHADOW);
          Rect(Px, Py, Px + 3, Py + 3, P);
          Rect(Px, Py, Px + 2, Py, P + 2); Rect(Px, Py, Px, Py + 2, P + 1);
          Rect(Px + 3, Py, Px + 3, Py + 3, P + 3); Rect(Px, Py + 3, Px + 3, Py + 3, P + 4);
        End;
    End;
  End;
End;

Procedure PieceAt(Cx, Cy, P, Sz : LongInt);
Var I, MinX, MaxX, MinY, MaxY, X, Y : LongInt;
Begin
  MinX := 9; MaxX := -9; MinY := 9; MaxY := -9;
  For I := 0 To 3 Do
  Begin
    MinX := MinI(MinX, PX[P * 16 + I]); MaxX := MaxI(MaxX, PX[P * 16 + I]);
    MinY := MinI(MinY, PY[P * 16 + I]); MaxY := MaxI(MaxY, PY[P * 16 + I]);
  End;
  For I := 0 To 3 Do
  Begin
    X := Cx - (MaxX - MinX + 1) * Sz Div 2 + (PX[P * 16 + I] - MinX) * Sz;
    Y := Cy - (MaxY - MinY + 1) * Sz Div 2 + (PY[P * 16 + I] - MinY) * Sz;
    DrawBlock(X, Y, P);
  End;
End;

{ decor fixe : fond, panneaux, puits }
Procedure RenderBack;
Var X, Y, S, N : LongInt;
Begin
  N := 3;
  For Y := 0 To BH - 1 Do
  Begin
    S := 15 - Y * 15 Div (BH - 1);
    For X := 0 To BW - 1 Do
    Begin
      N := (N * 1103515245 + 12345) And $7FFFFFFF;
      Back[(BH - 1 - Y) * BW + X] := C_BG + MaxI(0, MinI(15, S - ((N Shr 16) And 1)));
    End;
  End;
  Move(Back, Fb, SizeOf(Fb));
  { motif discret de briques sur le fond }
  For Y := 0 To BH Div 12 Do
    For X := 0 To BW Div 24 + 1 Do
    Begin
      Rect(X * 24 + (Y Mod 2) * 12, Y * 12, X * 24 + (Y Mod 2) * 12, Y * 12 + 11, C_BG + 2);
      Rect(X * 24, Y * 12, X * 24 + 23, Y * 12, C_BG + 2);
    End;
  { panneau de gauche }
  BlockTitle(30, 18, 'BLOX');
  Panel(14, 90, 174, 146, 'Pointage');
  Panel(14, 154, 90, 210, 'Niveau');
  Panel(98, 154, 174, 210, 'Lignes');
  Panel(14, 218, 174, 274, 'Briques');
  Panel(14, 282, 174, 326, 'Prochain niveau');
  Panel(14, 334, 174, 376, 'Record');
  { puits }
  Rect(WX - 7, WY - 7, WX + NX * Cell + 9, WY + NY * Cell + 9, C_SHADOW);
  Rect(WX - 8, WY - 8, WX + NX * Cell + 7, WY + NY * Cell + 7, C_PANEL);
  Bevel(WX - 8, WY - 8, WX + NX * Cell + 7, WY + NY * Cell + 7, False);
  Bevel(WX - 7, WY - 7, WX + NX * Cell + 6, WY + NY * Cell + 6, False);
  Bevel(WX - 2, WY - 2, WX + NX * Cell + 1, WY + NY * Cell + 1, True);
  Bevel(WX - 1, WY - 1, WX + NX * Cell, WY + NY * Cell, True);
  For X := 0 To NX - 1 Do
  Begin
    If X Mod 2 = 0 Then S := C_WELL Else S := C_WELL2;
    Rect(WX + X * Cell, WY, WX + X * Cell + Cell - 1, WY + NY * Cell - 1, S);
  End;
  For Y := 1 To NY - 1 Do
    For X := 0 To NX * Cell - 1 Do
      If X Mod 3 = 0 Then Pix(WX + X, WY + Y * Cell, C_GRID);
  { panneau de droite }
  Panel(386, 16, 546, 120, 'Suivante');
  Rect(402, 36, 530, 112, C_WELL);
  Bevel(401, 35, 531, 113, True);
  Panel(386, 128, 546, 318, 'Touches');
  FbText(398, 152, Chr(27) + ' ' + Chr(26) + '  d' + Chr(130) + 'placer', C_INK, 1);
  FbText(398, 172, Chr(24) + ' X  tourner', C_INK, 1);
  FbText(398, 192, 'Z    autre sens', C_INK, 1);
  FbText(398, 212, Chr(25) + '    descendre', C_INK, 1);
  FbText(398, 232, 'Espace  chute', C_INK, 1);
  FbText(398, 252, 'P    pause', C_INK, 1);
  FbText(398, 272, 'F2   nouvelle', C_INK, 1);
  FbText(398, 292, 'F1   r' + Chr(138) + 'gles', C_INK, 1);
  Panel(386, 326, 546, 376, 'Pi' + Chr(138) + 'ces');
  Move(Fb, Back, SizeOf(Fb));
  Dirty := 1;
End;

Procedure DrawBanner;
Var W, X1, Cx : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(Length(Banner) * 16, Length(Banner2) * 8) + 32;
  Cx := WX + NX * Cell Div 2;
  X1 := Cx - W Div 2;
  Rect(X1 + 4, 154, X1 + W + 4, 226, C_SHADOW);
  Rect(X1, 150, X1 + W, 222, C_GOLD);
  Rect(X1 + 3, 153, X1 + W - 3, 219, C_BANNER);
  FbCenter(Cx, 160, Banner, BannerC, 2);
  FbCenter(Cx, 198, Banner2, C_TITLE, 1);
End;

{ la scene entiere dans Fb }
Procedure RenderScene;
Var X, Y, V, I, Gy, P, F : LongInt; S : String;
Begin
  Move(Back, Fb, SizeOf(Fb));
  { valeurs des panneaux }
  FbRight(166, 112, IStr(Score), C_VAL, 2);
  FbRight(82, 176, IStr(Level), C_VAL, 2);
  If Lines < 1000 Then FbRight(166, 176, IStr(Lines), C_VAL, 2) Else FbRight(166, 186, IStr(Lines), C_VAL, 1);
  FbRight(166, 240, IStr(Bricks), C_VAL, 2);
  DrawBlock(24, 244, 7);
  V := 10 - (Lines Mod 10);
  Rect(22, 304, 166, 316, C_WELL);
  Bevel(21, 303, 167, 317, True);
  If Lines Mod 10 > 0 Then Rect(23, 305, 23 + (Lines Mod 10) * 143 Div 10, 315, C_BAR);
  FbText(26, 304, IStr(V) + ' ligne', C_WHITE, 1);
  If V > 1 Then FbText(26 + Length(IStr(V)) * 8 + 48, 304, 's', C_WHITE, 1);
  FbRight(166, 354, IStr(Best), C_VAL, 1);
  FbRight(538, 352, IStr(Pieces), C_VAL, 1);
  { piece suivante }
  If State <> S_IDLE Then PieceAt(466, 74, Next, Cell);
  { puits }
  For Y := 0 To NY - 1 Do
  Begin
    F := 0;
    If State = S_CLEAR Then
      For I := 0 To NFull - 1 Do If FullRow[I] = Y Then F := 1;
    For X := 0 To NX - 1 Do
    Begin
      P := Board[Y * NX + X];
      If P <> 0 Then
      Begin
        If (State = S_OVER) And (Y >= OverRow) Then DrawBlock(WX + X * Cell, WY + Y * Cell, 8)
        Else If (F <> 0) And ((Anim Div 2) Mod 2 = 0) Then
          Rect(WX + X * Cell, WY + Y * Cell, WX + X * Cell + Cell - 1, WY + Y * Cell + Cell - 1, C_FLASH)
        Else If P = 8 Then DrawBlock(WX + X * Cell, WY + Y * Cell, 7)
        Else DrawBlock(WX + X * Cell, WY + Y * Cell, P - 1);
      End;
    End;
  End;
  { piece qui tombe et son ombre }
  If State = S_PLAY Then
  Begin
    If (Ghost <> 0) And (Paused = 0) Then
    Begin
      Gy := DropY;
      If Gy > PosY Then
        For I := 0 To 3 Do
        Begin
          Y := Gy + PY[Cur * 16 + Rot * 4 + I];
          If Y >= 0 Then GhostBlock(WX + (PosX + PX[Cur * 16 + Rot * 4 + I]) * Cell, WY + Y * Cell, Cur);
        End;
    End;
    For I := 0 To 3 Do
    Begin
      Y := PosY + PY[Cur * 16 + Rot * 4 + I];
      If Y >= 0 Then DrawBlock(WX + (PosX + PX[Cur * 16 + Rot * 4 + I]) * Cell, WY + Y * Cell, Cur);
    End;
  End;
  If Paused <> 0 Then
    For Y := WY To WY + NY * Cell - 1 Do
      For X := WX To WX + NX * Cell - 1 Do
        If (X + Y) Mod 2 = 0 Then Fb[(BH - 1 - Y) * BW + X] := C_WELL;
  DrawBanner;
End;

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 0; MakeTone(0, 900, 900, 18, 14);           { deplacement }
  SndPrio := 0; MakeTone(1, 700, 1300, 40, 18);          { rotation }
  SndPrio := 1; MakeNoise(2, 70, 70, 2);                 { piece posee }
  SndPrio := 2; MakeTone(3, 520, 1560, 260, 40);         { ligne }
  SndPrio := 3; MakeTone(4, 440, 1980, 520, 45);         { quatre lignes }
  SndPrio := 3; MakeTone(5, 660, 1320, 420, 40);         { niveau }
  SndPrio := 4; MakeTone(6, 520, 110, 900, 45);          { fin de partie }
  SndPrio := 3; MakeTone(7, 880, 2640, 700, 45);         { briques detruites }
  SndPrio := 1; MakeNoise(8, 160, 90, 4);                { rangee de briques qui monte }
  SndPrio := 0;
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
  DrawStatus;
  LastMsg := Msg;
  Dirty := 0;
  Dummy := WinEndPaint(Hps);
End;

Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  RenderScene;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  If Msg <> LastMsg Then
  Begin
    LastMsg := Msg;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
  Dirty := 0;
End;

{ ==================================================================== }
{ Deroulement de la partie                                              }
{ ==================================================================== }

Procedure Show(B1, B2 : String; C, T : LongInt);
Begin
  Banner := B1; Banner2 := B2; BannerC := C; BanT := T;
End;

Procedure PlayMsg;
Begin
  If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue (Options).'
  Else If Paused <> 0 Then Msg := 'Pause : P pour reprendre.'
  Else Msg := 'Niveau ' + IStr(Level) + ' : ' + IStr(Bricks) + ' briques ' + Chr(133) + ' d' + Chr(130) +
              'truire. Fl' + Chr(138) + 'ches, Espace (chute), P (pause).';
End;

Procedure GameOver;
Begin
  State := S_OVER; OverRow := NY; Anim := 0;
  If Score > Best Then Best := Score;
  PlaySnd(6);
  Msg := 'Partie termin' + Chr(130) + 'e : ' + IStr(Score) + ' points, ' + IStr(Lines) + ' lignes. F2 : nouvelle partie.';
End;

Procedure NextPiece;
Begin
  State := S_PLAY;
  If Not Spawn Then GameOver;
End;

Procedure NewGame;
Begin
  Level := StartLevel; Score := 0; Lines := 0; Pieces := 0; Paused := 0; NFull := 0;
  Delay := DelayFor(Level);
  BagN := 0;
  MakeBricks(Level);
  Next := FromBag;
  Banner := ''; BanT := 0;
  NextPiece;
  Show('Niveau ' + IStr(Level), IStr(Bricks) + ' briques au fond du puits', C_GOLD, 60);
  PlayMsg;
  Dirty := 1;
End;

{ la piece se pose : lignes completes ou piece suivante }
Procedure Lock;
Begin
  If Not Place Then
  Begin
    GameOver;
    Exit;
  End;
  FindFull;
  If NFull > 0 Then
  Begin
    State := S_CLEAR; Anim := 0;
    If NFull >= 4 Then PlaySnd(4) Else PlaySnd(3);
  End
  Else
  Begin
    PlaySnd(2);
    NextPiece;
  End;
End;

Procedure AfterClear;
Var R, N : LongInt;
Begin
  N := NFull;
  R := ClearFull;
  If (R And 2) <> 0 Then
  Begin
    Show('Briques d' + Chr(130) + 'truites !', 'Prime : ' + IStr(1000 * Level) + ' points', C_GOLD, 70);
    PlaySnd(7);
  End
  Else If N >= 4 Then Show('Quatre lignes !', '+' + IStr(800 * Level) + ' points', C_GOLD, 40);
  If (R And 1) <> 0 Then
  Begin
    If Not RaiseRow Then
    Begin
      GameOver;
      Exit;
    End;
    If (R And 2) = 0 Then Show('Niveau ' + IStr(Level), 'Une rang' + Chr(130) + 'e de briques monte !', C_GOLD, 60);
    PlaySnd(5);
  End;
  NextPiece;
  If State = S_PLAY Then PlayMsg;
End;

Procedure HardDrop;
Var D : LongInt;
Begin
  D := DropY - PosY;
  PosY := PosY + D;
  Score := Score + 2 * D;
  If Score > Best Then Best := Score;
  Lock;
End;

Procedure SoftDrop;
Begin
  If TryMove(0, 1) Then
  Begin
    Inc(Score);
    If Score > Best Then Best := Score;
    Fall := 0;
  End
  Else Lock;
End;

Procedure AutoStep;
Begin
  If AiOn = 0 Then
  Begin
    Plan;
    Exit;
  End;
  If Rot <> AiRot Then
  Begin
    If Not TryRotate(1) Then AiRot := Rot;
  End
  Else If PosX < AiX Then
  Begin
    If Not TryMove(1, 0) Then AiX := PosX;
  End
  Else If PosX > AiX Then
  Begin
    If Not TryMove(-1, 0) Then AiX := PosX;
  End
  Else SoftDrop;
End;

Procedure Command(Id : LongInt); Forward;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If BanT > 0 Then
  Begin
    Dec(BanT);
    If BanT = 0 Then
    Begin
      Banner := '';
      Dirty := 1;
    End;
  End;
  Case State Of
    S_PLAY :
      If Paused = 0 Then
      Begin
        If (AutoAll <> 0) And (Tick Mod 2 = 0) Then
        Begin
          AutoStep;
          Dirty := 1;
        End;
        If State = S_PLAY Then
        Begin
          Inc(Fall);
          If Fall >= Delay Then
          Begin
            Fall := 0;
            If Not TryMove(0, 1) Then Lock;
            Dirty := 1;
          End;
        End;
      End;
    S_CLEAR :
      Begin
        Inc(Anim);
        Dirty := 1;
        If Anim >= 12 Then AfterClear;
      End;
    S_OVER :
      If OverRow > 0 Then
      Begin
        Dec(OverRow);
        Dirty := 1;
        If OverRow = 0 Then
        Begin
          Show('Partie termin' + Chr(130) + 'e', IStr(Score) + ' points, ' + IStr(Lines) + ' lignes', C_RED, 0);
          Anim := 0;
        End;
      End
      Else If AutoAll <> 0 Then
      Begin
        Inc(Anim);
        If Anim > 120 Then NewGame;
      End;
  End;
  If (Dirty <> 0) Or (Msg <> LastMsg) Then Frame1;
End;

{ ==================================================================== }
{ Commandes, clavier                                                    }
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
Var K : LongInt;
Begin
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0); SetMark(CM_GHOST, Ghost <> 0);
  SetMark(CM_PAUSE, Paused <> 0);
  For K := 1 To 9 Do SetMark(CM_LEVEL + K, K = StartLevel);
End;

Procedure TogglePause;
Begin
  If State <> S_PLAY Then Exit;
  Paused := 1 - Paused;
  If Paused <> 0 Then Show('Pause', 'P pour reprendre', C_GOLD, 0) Else Banner := '';
  PlayMsg;
  SetMarks;
  Dirty := 1;
End;

Procedure Command(Id : LongInt);
Var WasP : LongInt;
Begin
  Case Id Of
    CM_NEW :
      Begin
        WasP := Paused;
        If (State = S_PLAY) Or (State = S_CLEAR) Then Paused := 1;
        If (State = S_OVER) Or (State = S_IDLE) Or (AutoAll <> 0) Or (Pieces < 2) Or
           (Ask('Abandonner la partie en cours et recommencer ?', 'Blox', MB_YESNO Or MB_QUERY) = MBID_YES) Then
          NewGame
        Else Paused := WasP;
      End;
    CM_PAUSE : TogglePause;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_GHOST : Ghost := 1 - Ghost;
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll; AiOn := 0;
        If (AutoAll <> 0) And (State = S_OVER) Then NewGame;
        If Paused <> 0 Then TogglePause;
        PlayMsg;
      End;
    CM_SOUND : SoundOn := 1 - SoundOn;
    CM_LEVEL + 1..CM_LEVEL + 9 :
      Begin
        StartLevel := Id - CM_LEVEL;
        Msg := 'Niveau de d' + Chr(130) + 'part : ' + IStr(StartLevel) + ' (' + IStr(BrickRows(StartLevel)) +
               ' rang' + Chr(130) + 'es de briques). F2 : nouvelle partie.';
      End;
    CM_RULES :
      Begin
        WasP := Paused;
        If State = S_PLAY Then Paused := 1;
        LClr;
        LAdd('Des pi' + Chr(138) + 'ces de quatre blocs tombent dans le puits. Tournez-les et d' + Chr(130) +
             'placez-les pour former des lignes compl' + Chr(138) + 'tes, qui disparaissent.' + Chr(10) + Chr(10));
        LAdd('Particularit' + Chr(130) + ' de Blox : des morceaux de briques sont d' + Chr(130) + 'j' + Chr(133) +
             ' pos' + Chr(130) + 's au fond du puits, d''autant plus que le niveau de d' + Chr(130) + 'part est ' +
             Chr(130) + 'lev' + Chr(130) + '. Chaque rang' + Chr(130) + 'e de briques a des trous ' + Chr(133) +
             ' boucher. ');
        LAdd('Toutes les 10 lignes, le niveau monte, les pi' + Chr(138) + 'ces tombent plus vite et une rang' +
             Chr(130) + 'e de briques monte du fond.' + Chr(10) + Chr(10));
        LAdd('Pointage : 100, 300, 500 ou 800 points (une ' + Chr(133) + ' quatre lignes d''un coup) fois le ' +
             'niveau ; 1 point par rang' + Chr(130) + 'e descendue, 2 par la chute ; prime de 1000 fois le ' +
             'niveau quand toutes les briques sont d' + Chr(130) + 'truites.' + Chr(10) + Chr(10));
        LAdd('Clavier : Gauche et Droite (d' + Chr(130) + 'placer), Haut ou X (tourner), Z (autre sens), Bas ' +
             '(descendre), Espace (chute), P (pause), F2 (nouvelle partie).');
        Dummy := LMsgBox('Blox - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
        Paused := WasP;
      End;
    CM_ABOUT :
      Begin
        WasP := Paused;
        If State = S_PLAY Then Paused := 1;
        Dummy := Ask('Blox pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype BLOX.PAS de ' +
                     '7iles.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) +
                     ' par OS2PC.', 'A propos', MB_OK Or MB_INFORMATION);
        Paused := WasP;
      End;
  End;
  SetMarks;
  Dirty := 1;
  Frame1;
End;

{ action du joueur : G, D, T (tourner), A (autre sens), B (bas), C (chute) }
Procedure Act(A : Char);
Begin
  If (State <> S_PLAY) Or (Paused <> 0) Or (AutoAll <> 0) Then Exit;
  Case A Of
    'G' : If TryMove(-1, 0) Then PlaySnd(0);
    'D' : If TryMove(1, 0) Then PlaySnd(0);
    'T' : If TryRotate(1) Then PlaySnd(1);
    'A' : If TryRotate(-1) Then PlaySnd(1);
    'B' : SoftDrop;
    'C' : HardDrop;
  End;
  Dirty := 1;
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
    Case Vk Of
      VK_F1 : Begin Command(CM_RULES); Exit; End;
      VK_F2 : Begin Command(CM_NEW); Exit; End;
      VK_LEFT : Act('G');
      VK_RIGHT : Act('D');
      VK_UP : Act('T');
      VK_DOWN : Act('B');
      VK_SPACE : Act('C');
    Else
      If (Fl And KC_CHAR) = 0 Then
      Begin
        KeyChar := False;
        Exit;
      End;
    End;
    If (Vk >= VK_SPACE) And (Vk <= VK_DOWN) Then
    Begin
      Frame1;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      '4' : Act('G');
      '6' : Act('D');
      '8', '5', 'X' : Act('T');
      'Z', 'W' : Act('A');
      '2' : Act('B');
      ' ' : Act('C');
      'P' : TogglePause;
      'N' : Command(CM_NEW);
    Else
      KeyChar := False;
    End;
    Frame1;
    Exit;
  End;
  KeyChar := False;
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
        If State = S_OVER Then Command(CM_NEW);
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

Function CellsKey : LongInt;
Var I, K : LongInt;
Begin
  K := 0;
  For I := 0 To 3 Do K := K + (PosX + PX[Cur * 16 + Rot * 4 + I]) * 7 + (PosY + PY[Cur * 16 + Rot * 4 + I]) * 131;
  CellsKey := K;
End;

{ une partie jouee sans fenetre par le joueur automatique }
Procedure GameSync(MaxP : LongInt);
Begin
  NewGame;
  While (State = S_PLAY) And (Pieces < MaxP) Do
  Begin
    Plan;
    While Rot <> AiRot Do If Not TryRotate(1) Then AiRot := Rot;
    While (PosX < AiX) And TryMove(1, 0) Do ;
    While (PosX > AiX) And TryMove(-1, 0) Do ;
    HardDrop;
    If State = S_CLEAR Then AfterClear;
  End;
End;

Procedure RunTests;
Var Ok, K, A, B, C, N, R, Y : LongInt; S : String; Good : Boolean;
Begin
  Ok := 0;
  { TEST1 : quatre quarts de tour ramenent la piece ; murs ; decalage }
  FillChar(Board, SizeOf(Board), 0);
  Good := True;
  For K := 0 To NPiece - 1 Do
  Begin
    Cur := K; Rot := 0; PosX := 3; PosY := 5;
    A := CellsKey;
    For R := 1 To 4 Do If Not TryRotate(1) Then Good := False;
    If (CellsKey <> A) Or (Rot <> 0) Then Good := False;
  End;
  Cur := 0; Rot := 1; PosX := -2; PosY := 5;         { barre debout contre le mur de gauche }
  B := 0; While TryMove(-1, 0) Do Inc(B);
  C := 0; If TryRotate(1) Then C := PosX;
  N := 0; While TryMove(1, 0) Do Inc(N);
  S := 'TEST1 rotations ';
  If Good Then S := S + 'ok' Else S := S + 'NON';
  S := S + ' mur ' + IStr(B) + ' decalage ' + IStr(C) + ' droite ' + IStr(N);
  Log('BLOX : ' + S);
  If S = 'TEST1 rotations ok mur 0 decalage 0 droite 6' Then Inc(Ok);
  { TEST2 : une ligne (100), puis quatre lignes d'un coup (800 au niveau 1) }
  StartLevel := 1; Level := 1; Score := 0; Lines := 0; Pieces := 0;
  FillChar(Board, SizeOf(Board), 0);
  For K := 0 To NX - 1 Do If K < 6 Then Board[(NY - 1) * NX + K] := 1;
  Cur := 0; Rot := 0; PosX := 6; PosY := 0; HardDrop; A := NFull;
  If State = S_CLEAR Then AfterClear;
  B := Score;
  FillChar(Board, SizeOf(Board), 0);
  For Y := NY - 4 To NY - 1 Do For K := 0 To NX - 2 Do Board[Y * NX + K] := 8;
  Bricks := CountBricks;
  Score := 0; Cur := 0; Rot := 1; PosX := NX - 3; PosY := 0;
  C := DropY;
  HardDrop; N := NFull;
  If State = S_CLEAR Then AfterClear;
  S := 'TEST2 une ligne ' + IStr(A) + ' ' + IStr(B) + ' ; quatre lignes ' + IStr(N) + ' ' + IStr(Score) +
       ' briques ' + IStr(Bricks) + ' lignes ' + IStr(Lines);
  Log('BLOX : ' + S);
  { 1 ligne : 100 + 2 x 18 (chute) ; 4 lignes : 800 + 2 x C + prime 1000 }
  If (A = 1) And (B = 136) And (N = 4) And (Score = 1800 + 2 * C) And (Bricks = 0) And (Lines = 5) Then Inc(Ok);
  { TEST3 : briques de depart des niveaux 1 a 9 : nombre de rangees, aucune
    rangee complete, rien au-dessus ; une rangee qui monte }
  Good := True; S := '';
  For K := 1 To 9 Do
  Begin
    Seed := 100 + K;
    MakeBricks(K);
    N := 0;
    For Y := 0 To NY - 1 Do
    Begin
      A := 0;
      For R := 0 To NX - 1 Do If Board[Y * NX + R] <> 0 Then Inc(A);
      If A = NX Then Good := False;
      If A > 0 Then Inc(N);
      If (A > 0) And (Y < NY - BrickRows(K)) Then Good := False;
    End;
    S := S + IStr(N);
    If N <> BrickRows(K) Then Good := False;
  End;
  A := Bricks;
  If Not RaiseRow Then Good := False;
  If RowFull(NY - 1) Then Good := False;
  S := 'TEST3 rangees ' + S;
  If Good Then S := S + ' ok' Else S := S + ' NON';
  Log('BLOX : ' + S);
  If S = 'TEST3 rangees 34567891011 ok' Then Inc(Ok);
  { PARTIE : le joueur automatique, graine fixe, niveau 1 }
  Seed := 2026; StartLevel := 1;
  GameSync(600);
  Log('BLOX : PARTIE pieces ' + IStr(Pieces) + ' lignes ' + IStr(Lines) + ' pointage ' + IStr(Score) + ' niveau ' +
      IStr(Level) + ' briques ' + IStr(Bricks) + ' etat ' + IStr(State));
  Log('BLOX : ' + IStr(Ok) + '/3 essais reussis');
End;

Var
  Flg, H0, H1, H2, H3, H4, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; LastMsg := '-'; AutoAll := 0; Banner := ''; Banner2 := ''; Best := 0; Tick := 0; Client := 0;
  Frame := 0; SoundOn := 1; Ghost := 1; StartLevel := 1; Level := 1; SndCur := 0; SndEnd := 0; Score := 0;
  TestMode := 0; State := S_IDLE; Paused := 0; BanT := 0; NFull := 0; Lines := 0; Pieces := 0; Bricks := 0;
  CW := CWant; CH := CHWant; Dirty := 1; BannerC := C_GOLD; BagN := 0; AiOn := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/LEVEL:') Then
    Begin
      Val(Copy(S, 8, 20), StartLevel, E);
      If StartLevel < 1 Then StartLevel := 1;
      If StartLevel > 9 Then StartLevel := 9;
    End;
    If S = '/AUTO' Then AutoAll := 1;
    If S = '/NOSOUND' Then SoundOn := 0;
    If S = '/TEST' Then TestMode := 1;
  End;
  InitShapes;
  If TestMode <> 0 Then
  Begin
    RunTests;
    Halt(0);
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  InitPal;
  RenderBack;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('BLOX'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('BLOX'), Z2('Blox'), 0, 0, 0, LongInt(@Client));
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
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, CM_LEVEL, '~Niveau de d' + Chr(130) + 'part');
  H4 := MenuOpen;
  For K := 1 To 9 Do MItem(MIS_TEXT, 0, CM_LEVEL + K, '~' + IStr(K) + Chr(9) + IStr(BrickRows(K)) + ' rang' +
                           Chr(130) + 'es de briques');
  MenuClose(H4, 9);
  MItem(MIS_TEXT, 0, CM_GHOST, '~Ombre de la pi' + Chr(138) + 'ce');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MenuClose(H3, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Blox');
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
  Dummy := WinStartTimer(Hab, Client, 1, 30);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
