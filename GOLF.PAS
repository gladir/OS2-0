{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: GOLF - le jeu de cartes Golf (six cartes) pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program GOLF;

{$R-,S-,I-}

{ Compilation : OS2PC GOLF.PAS   (produit GOLF.EXE)

  Portage vers OS/2-0 du prototype GOLF.PAS du depot 7iles (Turbo Pascal,
  BGI en 640 x 480, clavier et souris) : fenetre de Presentation Manager
  avec menus, tapis vert en degrade dessine dans une image en memoire
  (GpiDrawBits, sans scintillement), cartes dessinees (coins arrondis,
  ombre, enseignes, figures encadrees, dos a motif avec un drapeau de
  golf), cartes qui glissent de la pioche a la main et de la main a la
  defausse, carnet de pointage, bruitages et apparence d'OS/2 Warp 3.

  Le jeu (comme le prototype) : chaque joueur, vous contre l'ordinateur,
  a six cartes face cachee en deux rangees de trois. A son tour, il
  pioche (pioche ou defausse) puis echange la carte prise avec une de ses
  cartes (qui va, retournee, sur la defausse) ou, si elle vient de la
  pioche, la defausse. Le plus bas pointage gagne : As 1, 2 a 10 leur
  valeur, Valet et Dame 10, Roi 0.
  Ce qui est corrige : le compte des cartes retournees (la donne ne
  finissait jamais), le pointage affiche sur un seul chiffre, la pioche
  vide (la defausse est rebattue), la carte prise de la defausse qui
  pouvait y etre remise, les cartes face cachee oubliees a la fin.
  Ce qui s'ajoute (regles habituelles du Golf a six cartes) : deux cartes
  retournees au choix au debut de chaque trou ; apres une defausse, une
  carte face cachee est retournee ; deux cartes de meme rang dans une
  colonne valent 0 ; quand un joueur a retourne ses six cartes, l'autre
  joue un dernier tour ; parcours de 9 trous (ou 3), carnet de pointage,
  total le plus bas gagnant ; ordinateur qui calcule ses echanges ;
  demonstration (l'ordinateur joue pour vous).

  Souris : cliquer la pioche, la defausse ou une de vos cartes. Clavier :
  D (piocher), P (prendre la defausse), 1 a 6 (vos cartes), F (defausser
  la carte en main), Espace (continuer), F2 (nouvelle partie), F1
  (regles).
  Parametres : /SEED:n ; /AUTO (demonstration) ; /HOLES:n (1 a 9) ;
  /NOSOUND ; /TEST (essais du pointage, de la pioche et du dernier tour,
  puis parcours joue par l'ordinateur, resultat sur le port serie COM1). }

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
  VK_NEWLINE = $08; VK_SPACE = $10; VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_NEXT = 102; CM_QUIT = 104;
  CM_H9 = 201; CM_H3 = 202; CM_AUTO = 203; CM_SOUND = 204;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : tapis de 456 x 400 }
  BW = 456; BH = 400; OX = 8; OY = 8;
  PnX = 480; PW = 136;
  CWant = 624; CHWant = 436;
  { cartes }
  KW = 58; KH = 80;
  DeckX = 238; DeckY = 156; DiscX = 308; HoldX = 384;
  { couleurs de l'image }
  C_FELT = 0;                                  { 0..15 : tapis (sombre -> clair) }
  C_CARD = 16; C_CARDE = 17; C_BORDER = 18; C_RED = 19; C_BLACK = 20; C_BACK1 = 21; C_BACK2 = 22;
  C_GOLD = 23; C_HILITE = 24; C_SHADOW = 25; C_PAIR = 26; C_WHITE = 27; C_FLAG = 28; C_GREEN = 29;
  C_FACE = 30; C_BANNER = 31; C_BANNERE = 32; C_YELLOW = 33; C_SLOT = 34; C_GRAY = 35; C_TEXT = 36;
  NPal = 40;
  { etats }
  G_FLIP = 1; G_DRAW = 2; G_HOLD = 3; G_TURNUP = 4; G_HOLEEND = 5; G_OVER = 6;
  { emplacements : 0..5 vos cartes, 6..11 l'ordinateur, 12 pioche, 13 defausse, 14 main }
  SL_DECK = 12; SL_DISC = 13; SL_HOLD = 14;
  MaxFly = 4;
  SndRate = 11025;
  SuitName : Array[0..3] Of String[8] = ('coeur', 'carreau', 'tr'#138'fle', 'pique');

Var
  InDlg : LongInt;  { boite de message ouverte : animation suspendue }
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { cartes : 0..51 (couleur = c Div 13 : 0 coeur, 1 carreau, 2 trefle, 3 pique ; rang = c Mod 13 + 1) }
  HandC, HandUp : Array[0..11] Of LongInt;         { joueur p, carte i : indice p * 6 + i }
  DeckA, DiscA : Array[0..51] Of LongInt;
  DeckN, DiscN, HoldC, HoldFromDeck, Cur, Starter, Finisher, Flips : LongInt;
  Hole, Holes, NextHoles, State, Wait, Seed, AutoAll, SoundOn, Tick, TestMode, Reshuffles : LongInt;
  Tot : Array[0..1] Of LongInt;
  HS : Array[0..19] Of LongInt;                     { pointage du trou h, joueur p : h * 2 + p }
  HoverSl, LastHover, Dirty, Games, Wins : LongInt;
  { cartes qui glissent ; GhostC/GhostUp : ce que montre un emplacement tant qu'elle n'est pas arrivee }
  FlyOn, FlyC, FlyUp, FlyX0, FlyY0, FlyX1, FlyY1, FlyT, FlyN, FlySl : Array[0..MaxFly - 1] Of LongInt;
  GhostOn, GhostC, GhostUp : Array[0..14] Of LongInt;
  Banner, Banner2, Msg, LastMsg : String;
  BannerC, LastSig : LongInt;
  { bruitages }
  SndBuf : Array[0..29999] Of Byte;
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
Var I : LongInt;
Begin
  FillChar(Bmi, SizeOf(Bmi), 0);
  WrL(LongInt(@Bmi), 16);
  WrL(LongInt(@Bmi) + 4, BW);
  WrL(LongInt(@Bmi) + 8, BH);
  WrW(LongInt(@Bmi) + 12, 1);
  WrW(LongInt(@Bmi) + 14, 8);
  { tapis : vert sombre (bords) vers vert clair (centre) }
  For I := 0 To 15 Do SetPal(C_FELT + I, Mix($0B3A1A, $2E8A48, I, 15));
  SetPal(C_CARD, $FFFFFF); SetPal(C_CARDE, $E8E8E0); SetPal(C_BORDER, $303030); SetPal(C_RED, $D01E1E);
  SetPal(C_BLACK, $101010); SetPal(C_BACK1, $1C3C9C); SetPal(C_BACK2, $3C64CC); SetPal(C_GOLD, $E0B030);
  SetPal(C_HILITE, $FFE040); SetPal(C_SHADOW, $072410); SetPal(C_PAIR, $40E070); SetPal(C_WHITE, $FFFFFF);
  SetPal(C_FLAG, $E83030); SetPal(C_GREEN, $1E8C3C); SetPal(C_FACE, $FFF4D0); SetPal(C_BANNER, $0E3A1C);
  SetPal(C_BANNERE, $A8E8B0); SetPal(C_YELLOW, $FFDC46); SetPal(C_SLOT, $1A5C30); SetPal(C_GRAY, $909090);
  SetPal(C_TEXT, $E8F4E0);
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
{ Cartes                                                                }
{ ==================================================================== }

Function Rank(C : LongInt) : LongInt;
Begin
  Rank := C Mod 13 + 1;
End;

Function SuitOf(C : LongInt) : LongInt;
Begin
  SuitOf := C Div 13;
End;

Function IsRed(C : LongInt) : Boolean;
Begin
  IsRed := (C Div 13) <= 1;
End;

Function RankName(R : LongInt) : String;
Begin
  Case R Of
    1 : RankName := 'A';
    11 : RankName := 'V';
    12 : RankName := 'D';
    13 : RankName := 'R';
  Else
    RankName := IStr(R);
  End;
End;

Function CardPts(C : LongInt) : LongInt;
Var R, V : LongInt;
Begin
  R := C Mod 13 + 1;
  If R = 13 Then V := 0
  Else If R >= 11 Then V := 10
  Else V := R;
  CardPts := V;
End;

Function CardName(C : LongInt) : String;
Var R : LongInt; S : String;
Begin
  R := C Mod 13 + 1;
  Case R Of
    1 : S := 'As';
    11 : S := 'Valet';
    12 : S := 'Dame';
    13 : S := 'Roi';
  Else
    S := IStr(R);
  End;
  CardName := S + ' de ' + SuitName[C Div 13];
End;

{ rectangle aux coins arrondis (rayon 4) }
Procedure RRect(X1, Y1, X2, Y2, C : LongInt);
Begin
  Rect(X1 + 4, Y1, X2 - 4, Y2, C);
  Rect(X1 + 2, Y1 + 1, X2 - 2, Y2 - 1, C);
  Rect(X1 + 1, Y1 + 2, X2 - 1, Y2 - 2, C);
  Rect(X1, Y1 + 4, X2, Y2 - 4, C);
End;

{ triangle plein (sommet en haut ou en bas), pour les enseignes }
Procedure Tri(Cx, Y1, Y2, W, C : LongInt; Down : Boolean);
Var Y, H, Hw : LongInt;
Begin
  H := Y2 - Y1;
  If H <= 0 Then Exit;
  For Y := Y1 To Y2 Do
  Begin
    If Down Then Hw := W * (Y2 - Y) Div H Else Hw := W * (Y - Y1) Div H;
    Rect(Cx - Hw, Y, Cx + Hw, Y, C);
  End;
End;

{ enseigne au centre (Cx, Cy), taille S (demi-hauteur) }
Procedure Suit(Cx, Cy, S, Su, C : LongInt);
Var R, Y, Hw : LongInt;
Begin
  R := S Div 2;
  Case Su Of
    0 :
      Begin
        { coeur : deux disques et une pointe }
        Disc(Cx - R + R Div 4, Cy - R Div 2, R, C);
        Disc(Cx + R - R Div 4, Cy - R Div 2, R, C);
        Tri(Cx, Cy - R Div 3, Cy + S, S - R Div 4, C, True);
      End;
    1 :
      Begin
        { carreau : losange }
        For Y := -S To S Do
        Begin
          Hw := (S - Abs(Y)) * 3 Div 4;
          Rect(Cx - Hw, Cy + Y, Cx + Hw, Cy + Y, C);
        End;
      End;
    2 :
      Begin
        { trefle : trois disques et une tige }
        Disc(Cx, Cy - R, R, C);
        Disc(Cx - R - 1, Cy + R Div 3, R, C);
        Disc(Cx + R + 1, Cy + R Div 3, R, C);
        Tri(Cx, Cy, Cy + S, R, C, False);
      End;
    3 :
      Begin
        { pique : coeur renverse et une tige }
        Tri(Cx, Cy - S, Cy + R Div 3, S - R Div 4, C, False);
        Disc(Cx - R + R Div 4, Cy + R Div 3, R, C);
        Disc(Cx + R - R Div 4, Cy + R Div 3, R, C);
        Tri(Cx, Cy + R Div 2, Cy + S, R, C, False);
      End;
  End;
End;

{ dos : bleu a croisillons, cadre blanc, petit drapeau de golf }
Procedure DrawBack(X, Y : LongInt);
Var I, J : LongInt;
Begin
  RRect(X, Y, X + KW - 1, Y + KH - 1, C_CARD);
  Rect(X + 4, Y + 4, X + KW - 5, Y + KH - 5, C_BACK1);
  For J := Y + 4 To Y + KH - 5 Do
    For I := X + 4 To X + KW - 5 Do
      If ((I - X + J - Y) Mod 8 = 0) Or ((I - X - (J - Y) + 64) Mod 8 = 0) Then Pix(I, J, C_BACK2);
  { drapeau sur le green }
  Disc(X + KW Div 2, Y + KH Div 2 + 14, 9, C_GREEN);
  Rect(X + KW Div 2 - 9, Y + KH Div 2 + 15, X + KW Div 2 + 9, Y + KH Div 2 + 23, C_BACK1);
  Rect(X + KW Div 2, Y + KH Div 2 - 14, X + KW Div 2 + 1, Y + KH Div 2 + 14, C_WHITE);
  Tri(X + KW Div 2 + 2, Y + KH Div 2 - 14, Y + KH Div 2 - 4, 0, C_FLAG, False);
  For I := 0 To 9 Do Rect(X + KW Div 2 + 2, Y + KH Div 2 - 14 + I Div 2, X + KW Div 2 + 2 + (10 - I), Y + KH Div 2 - 13 + I Div 2, C_FLAG);
  Disc(X + KW Div 2 + 5, Y + KH Div 2 + 12, 2, C_WHITE);
End;

{ face : rang et enseigne aux coins, grande enseigne ou figure au centre }
Procedure DrawFace(X, Y, C : LongInt);
Var R, Su, Fg : LongInt; S : String;
Begin
  RRect(X, Y, X + KW - 1, Y + KH - 1, C_CARD);
  Rect(X + 3, Y + KH - 3, X + KW - 4, Y + KH - 2, C_CARDE);
  R := Rank(C); Su := SuitOf(C);
  If IsRed(C) Then Fg := C_RED Else Fg := C_BLACK;
  S := RankName(R);
  FbText(X + 4, Y + 2, S, Fg, 1);
  Suit(X + 8 + (Length(S) - 1) * 4, Y + 24, 4, Su, Fg);
  FbText(X + KW - 4 - Length(S) * 8, Y + KH - 2 - FontH, S, Fg, 1);
  Suit(X + KW - 8 - (Length(S) - 1) * 4, Y + KH - 24, 4, Su, Fg);
  If R >= 11 Then
  Begin
    { figure : cadre dore, lettre agrandie et enseigne }
    Rect(X + 15, Y + 18, X + KW - 16, Y + KH - 19, C_GOLD);
    Rect(X + 17, Y + 20, X + KW - 18, Y + KH - 21, C_FACE);
    FbText(X + KW Div 2 - 8, Y + 24, S, Fg, 2);
    Suit(X + KW Div 2, Y + KH - 30, 5, Su, Fg);
  End
  Else If R = 1 Then Suit(X + KW Div 2, Y + KH Div 2, 15, Su, Fg)
  Else Suit(X + KW Div 2, Y + KH Div 2, 11, Su, Fg);
End;

{ contour d'une carte (coins arrondis) ; Th : 1 trait fin, 2 trait epais }
Procedure Outline(X, Y, C, Th : LongInt);
Begin
  Rect(X + 3, Y, X + KW - 4, Y, C); Rect(X + 3, Y + KH - 1, X + KW - 4, Y + KH - 1, C);
  Rect(X, Y + 3, X, Y + KH - 4, C); Rect(X + KW - 1, Y + 3, X + KW - 1, Y + KH - 4, C);
  Pix(X + 1, Y + 2, C); Pix(X + 2, Y + 1, C); Pix(X + KW - 2, Y + 2, C); Pix(X + KW - 3, Y + 1, C);
  Pix(X + 1, Y + KH - 3, C); Pix(X + 2, Y + KH - 2, C); Pix(X + KW - 2, Y + KH - 3, C); Pix(X + KW - 3, Y + KH - 2, C);
  If Th > 1 Then
  Begin
    Rect(X + 3, Y - 2, X + KW - 4, Y - 1, C); Rect(X + 3, Y + KH, X + KW - 4, Y + KH + 1, C);
    Rect(X - 2, Y + 3, X - 1, Y + KH - 4, C); Rect(X + KW, Y + 3, X + KW + 1, Y + KH - 4, C);
    Rect(X - 1, Y, X + 2, Y + 2, C); Rect(X + KW - 3, Y - 1, X + KW, Y + 2, C);
    Rect(X - 1, Y + KH - 3, X + 2, Y + KH, C); Rect(X + KW - 3, Y + KH - 3, X + KW, Y + KH, C);
  End;
End;

{ une carte (C < 0 : emplacement vide), ombre, bordure (Hl : couleur du contour, -1 aucun) }
Procedure DrawCard(X, Y, C, Up, Hl : LongInt);
Begin
  If C < 0 Then
  Begin
    RRect(X, Y, X + KW - 1, Y + KH - 1, C_SLOT);
    If Hl >= 0 Then Outline(X, Y, Hl, 2);
    Exit;
  End;
  RRect(X + 3, Y + 3, X + KW + 2, Y + KH + 2, C_SHADOW);
  If Up <> 0 Then DrawFace(X, Y, C) Else DrawBack(X, Y);
  Outline(X, Y, C_BORDER, 1);
  If Hl >= 0 Then Outline(X, Y, Hl, 2);
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
  SndPrio := 0; MakeNoise(0, 60, 40, 3);                  { carte qui glisse }
  SndPrio := 1; MakeTone(1, 900, 1400, 50, 30);           { carte retournee }
  SndPrio := 2; MakeTone(2, 500, 1000, 260, 40);          { fin du trou }
  SndPrio := 3; MakeTone(3, 520, 1560, 700, 50);          { partie gagnee }
  SndPrio := 3; MakeTone(4, 420, 140, 700, 45);           { partie perdue }
  SndPrio := 1; MakeTone(5, 300, 260, 90, 30);            { coup refuse }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Positions                                                             }
{ ==================================================================== }

Function SlotX(S : LongInt) : LongInt;
Var X : LongInt;
Begin
  If S < 12 Then X := 14 + (S Mod 3) * 66
  Else If S = SL_DECK Then X := DeckX
  Else If S = SL_DISC Then X := DiscX
  Else X := HoldX;
  SlotX := X;
End;

Function SlotY(S : LongInt) : LongInt;
Var Y : LongInt;
Begin
  If S < 6 Then Y := 222 + (S Div 3) * 86
  Else If S < 12 Then Y := 24 + ((S - 6) Div 3) * 86
  Else Y := DeckY;
  SlotY := Y;
End;

{ ==================================================================== }
{ Pointage                                                              }
{ ==================================================================== }

{ pointage d'un joueur ; Known : seulement les cartes retournees ;
  deux cartes de meme rang dans une colonne valent 0 }
Function HandScore(P : LongInt; Known : Boolean) : LongInt;
Var Col, A, B, T : LongInt; UA, UB : Boolean;
Begin
  T := 0;
  For Col := 0 To 2 Do
  Begin
    A := HandC[P * 6 + Col]; B := HandC[P * 6 + Col + 3];
    UA := (HandUp[P * 6 + Col] <> 0) Or Not Known;
    UB := (HandUp[P * 6 + Col + 3] <> 0) Or Not Known;
    If Not (UA And UB And (Rank(A) = Rank(B))) Then
    Begin
      If UA Then T := T + CardPts(A);
      If UB Then T := T + CardPts(B);
    End;
  End;
  HandScore := T;
End;

Function IsPairSlot(S : LongInt) : Boolean;
Var P, I, J : LongInt;
Begin
  P := S Div 6; I := S Mod 6;
  If I < 3 Then J := I + 3 Else J := I - 3;
  IsPairSlot := (HandUp[P * 6 + I] <> 0) And (HandUp[P * 6 + J] <> 0) And (Rank(HandC[P * 6 + I]) = Rank(HandC[P * 6 + J]));
End;

Function UpCount(P : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To 5 Do If HandUp[P * 6 + I] <> 0 Then Inc(N);
  UpCount := N;
End;

{ estimation par l'ordinateur : carte V a l'emplacement I (I < 0 : sans
  changement) ; carte inconnue : 6 points }
Function Est(P, I, V : LongInt) : LongInt;
Var Col, A, B, T, KA, KB : LongInt; UA, UB : Boolean;
Begin
  T := 0;
  For Col := 0 To 2 Do
  Begin
    A := HandC[P * 6 + Col]; B := HandC[P * 6 + Col + 3];
    UA := HandUp[P * 6 + Col] <> 0; UB := HandUp[P * 6 + Col + 3] <> 0;
    If I = Col Then Begin A := V; UA := True; End;
    If I = Col + 3 Then Begin B := V; UB := True; End;
    If UA Then KA := CardPts(A) Else KA := 6;
    If UB Then KB := CardPts(B) Else KB := 6;
    If Not (UA And UB And (Rank(A) = Rank(B))) Then T := T + KA + KB;
  End;
  Est := T;
End;

{ meilleur emplacement pour la carte V ; Gain : points gagnes }
Function BestSlot(P, V : LongInt; Var Gain : LongInt) : LongInt;
Var I, G, B, Base : LongInt;
Begin
  Base := Est(P, -1, 0);
  B := 0; Gain := -999;
  For I := 0 To 5 Do
  Begin
    G := Base - Est(P, I, V);
    { a gain egal, remplacer une carte cachee plutot qu'une carte connue (on en apprend une) }
    If (G > Gain) Or ((G = Gain) And (HandUp[P * 6 + I] = 0) And (HandUp[P * 6 + B] <> 0)) Then
    Begin
      Gain := G; B := I;
    End;
  End;
  BestSlot := B;
End;

{ ==================================================================== }
{ Cartes qui glissent                                                   }
{ ==================================================================== }

Function Flying : Boolean;
Var K : LongInt; F : Boolean;
Begin
  F := False;
  For K := 0 To MaxFly - 1 Do If FlyOn[K] <> 0 Then F := True;
  Flying := F;
End;

{ carte C qui va de l'emplacement A a l'emplacement B ; B montre GC/GU jusqu'a l'arrivee }
Procedure Fly(C, Up, A, B, GC, GU : LongInt);
Var K : LongInt;
Begin
  If (TestMode <> 0) Or (Client = 0) Then Exit;
  For K := 0 To MaxFly - 1 Do
    If FlyOn[K] = 0 Then
    Begin
      FlyOn[K] := 1; FlyC[K] := C; FlyUp[K] := Up;
      FlyX0[K] := SlotX(A); FlyY0[K] := SlotY(A); FlyX1[K] := SlotX(B); FlyY1[K] := SlotY(B);
      FlyT[K] := 0; FlyN[K] := 9; FlySl[K] := B;
      GhostOn[B] := 1; GhostC[B] := GC; GhostUp[B] := GU;
      PlaySnd(0);
      Exit;
    End;
End;

Procedure MoveFlights;
Var K : LongInt;
Begin
  For K := 0 To MaxFly - 1 Do
    If FlyOn[K] <> 0 Then
    Begin
      Inc(FlyT[K]);
      If FlyT[K] >= FlyN[K] Then
      Begin
        FlyOn[K] := 0;
        GhostOn[FlySl[K]] := 0;
      End;
      Dirty := 1;
    End;
End;

{ ==================================================================== }
{ Coups                                                                 }
{ ==================================================================== }

Procedure Shuffle;
Var I, J, T : LongInt;
Begin
  For I := DeckN - 1 DownTo 1 Do
  Begin
    J := Rnd(I + 1);
    T := DeckA[I]; DeckA[I] := DeckA[J]; DeckA[J] := T;
  End;
End;

{ pioche vide : la defausse, sauf sa derniere carte, est rebattue }
Procedure Reshuffle;
Var I, Top : LongInt;
Begin
  If DiscN <= 1 Then Exit;
  Top := DiscA[DiscN - 1];
  DeckN := 0;
  For I := 0 To DiscN - 2 Do
  Begin
    DeckA[DeckN] := DiscA[I];
    Inc(DeckN);
  End;
  DiscA[0] := Top; DiscN := 1;
  Shuffle;
  Inc(Reshuffles);
End;

Function DiscTop : LongInt;
Begin
  If DiscN > 0 Then DiscTop := DiscA[DiscN - 1] Else DiscTop := -1;
End;

Procedure PushDisc(C : LongInt);
Begin
  DiscA[DiscN] := C;
  Inc(DiscN);
End;

Procedure SetMsg; Forward;
Procedure HoleEnd; Forward;

Procedure DrawDeck(P : LongInt);
Begin
  If DeckN = 0 Then Reshuffle;
  If DeckN = 0 Then Exit;
  Dec(DeckN);
  HoldC := DeckA[DeckN]; HoldFromDeck := 1;
  Fly(HoldC, 1, SL_DECK, SL_HOLD, -1, 0);
  State := G_HOLD; Wait := 0; Dirty := 1;
  SetMsg;
End;

Procedure TakeDisc(P : LongInt);
Begin
  If DiscN = 0 Then Exit;
  Dec(DiscN);
  HoldC := DiscA[DiscN]; HoldFromDeck := 0;
  Fly(HoldC, 1, SL_DISC, SL_HOLD, -1, 0);
  State := G_HOLD; Wait := 0; Dirty := 1;
  SetMsg;
End;

{ fin du tour du joueur P : dernier tour de l'autre quand P a tout retourne }
Procedure EndTurn(P : LongInt);
Begin
  If (Finisher >= 0) And (1 - P = Finisher) Then
  Begin
    HoleEnd;
    Exit;
  End;
  If (Finisher < 0) And (UpCount(P) = 6) Then Finisher := P;
  Cur := 1 - P;
  State := G_DRAW; Wait := 0; Dirty := 1;
  SetMsg;
End;

Procedure Exchange(P, I : LongInt);
Var Old, OldUp, S, PrevTop : LongInt;
Begin
  S := P * 6 + I;
  Old := HandC[S]; OldUp := HandUp[S];
  PrevTop := DiscTop;
  HandC[S] := HoldC; HandUp[S] := 1;
  PushDisc(Old);
  Fly(HoldC, 1, SL_HOLD, S, Old, OldUp);
  Fly(Old, 1, S, SL_DISC, PrevTop, 1);
  HoldC := -1;
  EndTurn(P);
End;

Procedure TurnUp(P, I : LongInt);
Begin
  HandUp[P * 6 + I] := 1;
  PlaySnd(1);
  EndTurn(P);
End;

Procedure Discard(P : LongInt);
Var PrevTop : LongInt;
Begin
  If (HoldC < 0) Or (HoldFromDeck = 0) Then Exit;
  PrevTop := DiscTop;
  PushDisc(HoldC);
  Fly(HoldC, 1, SL_HOLD, SL_DISC, PrevTop, 1);
  HoldC := -1;
  If UpCount(P) < 6 Then
  Begin
    State := G_TURNUP; Wait := 0; Dirty := 1;
    SetMsg;
  End
  Else EndTurn(P);
End;

{ ==================================================================== }
{ Ordinateur                                                            }
{ ==================================================================== }

{ carte cachee a retourner : de preference dans une colonne sans carte connue }
Function PickHidden(P : LongInt) : LongInt;
Var I, B, J : LongInt;
Begin
  B := -1;
  For I := 0 To 5 Do
    If HandUp[P * 6 + I] = 0 Then
    Begin
      If I < 3 Then J := I + 3 Else J := I - 3;
      If (B < 0) Or ((HandUp[P * 6 + J] = 0) And (Rnd(2) = 0)) Then B := I;
    End;
  PickHidden := B;
End;

Procedure AiStep(P : LongInt);
Var I, G, T : LongInt;
Begin
  Case State Of
    G_DRAW :
      Begin
        T := DiscTop;
        G := -999;
        If T >= 0 Then I := BestSlot(P, T, G);
        If (T >= 0) And (G >= 3) Then TakeDisc(P) Else DrawDeck(P);
      End;
    G_HOLD :
      Begin
        I := BestSlot(P, HoldC, G);
        { dernier tour de l'autre joueur, ou carte prise de la defausse : on echange }
        If (HoldFromDeck = 0) Or (G >= 1) Then Exchange(P, I) Else Discard(P);
      End;
    G_TURNUP :
      Begin
        I := PickHidden(P);
        If I >= 0 Then TurnUp(P, I) Else EndTurn(P);
      End;
  End;
End;

{ deux cartes retournees au debut du trou (colonnes differentes) }
Procedure AutoFlips(P : LongInt);
Var A, B : LongInt;
Begin
  A := Rnd(6);
  Repeat
    B := Rnd(6);
  Until (B Mod 3) <> (A Mod 3);
  HandUp[P * 6 + A] := 1; HandUp[P * 6 + B] := 1;
End;

{ ==================================================================== }
{ Donnes et partie                                                      }
{ ==================================================================== }

Procedure Show(B1, B2 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; BannerC := C;
End;

Procedure ClearFly;
Var K : LongInt;
Begin
  For K := 0 To MaxFly - 1 Do FlyOn[K] := 0;
  For K := 0 To 14 Do GhostOn[K] := 0;
End;

Procedure StartHole;
Var I : LongInt;
Begin
  ClearFly;
  For I := 0 To 51 Do DeckA[I] := I;
  DeckN := 52;
  Shuffle;
  For I := 0 To 11 Do
  Begin
    Dec(DeckN);
    HandC[I] := DeckA[DeckN]; HandUp[I] := 0;
  End;
  DiscN := 0;
  Dec(DeckN);
  PushDisc(DeckA[DeckN]);
  HoldC := -1; Finisher := -1; Flips := 0; Banner := ''; Banner2 := '';
  AutoFlips(1);
  If (AutoAll <> 0) Or (TestMode <> 0) Then
  Begin
    AutoFlips(0);
    Cur := Starter; State := G_DRAW;
  End
  Else
  Begin
    Cur := 0; State := G_FLIP;
  End;
  Wait := 0; Dirty := 1;
  SetMsg;
End;

Procedure NewGame;
Var I : LongInt;
Begin
  Holes := NextHoles;
  Hole := 1; Tot[0] := 0; Tot[1] := 0; Starter := 0;
  For I := 0 To 19 Do HS[I] := 0;
  StartHole;
End;

Procedure HoleEnd;
Var I, A, B : LongInt;
Begin
  For I := 0 To 11 Do HandUp[I] := 1;
  A := HandScore(0, False); B := HandScore(1, False);
  HS[(Hole - 1) * 2] := A; HS[(Hole - 1) * 2 + 1] := B;
  Tot[0] := Tot[0] + A; Tot[1] := Tot[1] + B;
  If Hole >= Holes Then
  Begin
    State := G_OVER;
    { la demonstration ne compte pas dans le bilan du joueur }
    If AutoAll = 0 Then Inc(Games);
    If Tot[0] < Tot[1] Then
    Begin
      If AutoAll = 0 Then Inc(Wins);
      Show('Vous gagnez !', 'Vous ' + IStr(Tot[0]) + ', ordinateur ' + IStr(Tot[1]) + ' - F2 : nouvelle partie', C_YELLOW);
      PlaySnd(3);
    End
    Else If Tot[0] > Tot[1] Then
    Begin
      Show('L''ordinateur gagne', 'Vous ' + IStr(Tot[0]) + ', ordinateur ' + IStr(Tot[1]) + ' - F2 : nouvelle partie', C_WHITE);
      PlaySnd(4);
    End
    Else
    Begin
      Show(Chr(144) + 'galit' + Chr(130), 'Vous ' + IStr(Tot[0]) + ', ordinateur ' + IStr(Tot[1]) + ' - F2 : nouvelle partie', C_YELLOW);
      PlaySnd(3);
    End;
  End
  Else
  Begin
    State := G_HOLEEND;
    Show('Trou ' + IStr(Hole) + ' termin' + Chr(130), 'Vous ' + IStr(A) + ', ordinateur ' + IStr(B) + ' - clic : trou suivant', C_YELLOW);
    PlaySnd(2);
  End;
  Wait := 0; Dirty := 1;
  SetMsg;
End;

Procedure NextHole;
Begin
  If State <> G_HOLEEND Then Exit;
  Inc(Hole);
  Starter := 1 - Starter;
  StartHole;
End;

Procedure SetMsg;
Begin
  Case State Of
    G_FLIP : Msg := 'Retournez deux de vos cartes (cliquez-les) pour commencer le trou ' + IStr(Hole) + '.';
    G_DRAW :
      If Cur = 1 Then Msg := 'L''ordinateur joue...'
      Else If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue pour vous (Options).'
      Else If Finisher = 1 Then Msg := 'Dernier tour ! Piochez (pioche ou d' + Chr(130) + 'fausse).'
      Else Msg := 'A vous : cliquez la pioche ou la d' + Chr(130) + 'fausse.';
    G_HOLD :
      If (Cur = 1) Or (AutoAll <> 0) Then Msg := 'L''ordinateur joue...'
      Else If HoldFromDeck <> 0 Then Msg := Chr(144) + 'changez avec une de vos cartes, ou cliquez la d' + Chr(130) + 'fausse.'
      Else Msg := Chr(144) + 'changez la carte prise avec une de vos cartes.';
    G_TURNUP :
      If (Cur = 1) Or (AutoAll <> 0) Then Msg := 'L''ordinateur joue...'
      Else Msg := 'Retournez une de vos cartes cach' + Chr(130) + 'es.';
    G_HOLEEND : Msg := 'Trou ' + IStr(Hole) + ' : vous ' + IStr(HS[(Hole - 1) * 2]) + ', ordinateur ' +
                       IStr(HS[(Hole - 1) * 2 + 1]) + '. Clic ou Espace : trou suivant.';
    G_OVER : Msg := 'Partie termin' + Chr(130) + 'e : vous ' + IStr(Tot[0]) + ', ordinateur ' + IStr(Tot[1]) + '.';
  End;
End;

{ ==================================================================== }
{ Dessin du tapis                                                       }
{ ==================================================================== }

{ tapis : degrade radial, cadres des deux mains, etiquettes des piles }
Procedure RenderBack;
Var X, Y, D, Cx, Cy, B : LongInt;
Begin
  Cx := BW Div 2; Cy := BH Div 2;
  For Y := 0 To BH - 1 Do
  Begin
    B := (BH - 1 - Y) * BW;
    For X := 0 To BW - 1 Do
    Begin
      D := ((X - Cx) * (X - Cx) + (Y - Cy) * (Y - Cy) * 2) Div 1900;
      If D > 15 Then D := 15;
      { petit grain du feutre }
      If ((X * 7 + Y * 13) Mod 17 = 0) And (D < 15) Then Inc(D);
      Back[B + X] := C_FELT + 15 - D;
    End;
  End;
  Move(Back, Fb, SizeOf(Fb));
  { emplacements des piles }
  FbText(DeckX + (KW - 48) Div 2, DeckY - 20, 'Pioche', C_TEXT, 1);
  FbText(DiscX + (KW - 64) Div 2, DeckY - 20, 'D' + Chr(130) + 'fausse', C_TEXT, 1);
  FbText(HoldX + (KW - 56) Div 2, DeckY - 20, 'En main', C_TEXT, 1);
  Move(Fb, Back, SizeOf(Fb));
End;

Procedure DrawBanner;
Var W, X, Y, H : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(Length(Banner) * 16, Length(Banner2) * 8) + 40;
  If W > BW - 12 Then W := BW - 12;
  H := 70; If Banner2 = '' Then H := 52;
  X := (BW - W) Div 2; Y := 160;
  Rect(X + 4, Y + 4, X + W + 3, Y + H + 3, C_SHADOW);
  Rect(X, Y, X + W - 1, Y + H - 1, C_BANNER);
  Rect(X, Y, X + W - 1, Y + 1, C_BANNERE); Rect(X, Y + H - 2, X + W - 1, Y + H - 1, C_BANNERE);
  Rect(X, Y, X + 1, Y + H - 1, C_BANNERE); Rect(X + W - 2, Y, X + W - 1, Y + H - 1, C_BANNERE);
  FbTextSh(X + (W - Length(Banner) * 16) Div 2, Y + 10, Banner, BannerC, 2);
  If Banner2 <> '' Then FbTextSh(X + (W - Length(Banner2) * 8) Div 2, Y + 46, Banner2, C_WHITE, 1);
End;

{ emplacement cliquable dans l'etat courant ? }
Function Clickable(S : LongInt) : Boolean;
Var R : Boolean;
Begin
  R := False;
  If (Cur = 0) And (AutoAll = 0) And Not Flying Then
    Case State Of
      G_FLIP : R := (S < 6) And (HandUp[S] = 0);
      G_DRAW : R := (S = SL_DECK) Or ((S = SL_DISC) And (DiscN > 0));
      G_HOLD : R := (S < 6) Or ((S = SL_DISC) And (HoldFromDeck <> 0));
      G_TURNUP : R := (S < 6) And (HandUp[S] = 0);
    End;
  Clickable := R;
End;

Procedure DrawSlot(S : LongInt);
Var C, Up, Hl, X, Y : LongInt;
Begin
  X := SlotX(S); Y := SlotY(S);
  If S < 12 Then
  Begin
    C := HandC[S]; Up := HandUp[S];
  End
  Else If S = SL_DECK Then
  Begin
    If DeckN > 0 Then C := 0 Else C := -1;
    Up := 0;
  End
  Else If S = SL_DISC Then
  Begin
    C := DiscTop; Up := 1;
  End
  Else
  Begin
    C := HoldC; Up := 1;
  End;
  If GhostOn[S] <> 0 Then
  Begin
    C := GhostC[S]; Up := GhostUp[S];
  End;
  Hl := -1;
  If (S < 12) And (C >= 0) And (GhostOn[S] = 0) And IsPairSlot(S) Then Hl := C_PAIR;
  If (S = HoverSl) And Clickable(S) Then Hl := C_HILITE;
  { epaisseur de la pioche : quelques cartes decalees }
  If (S = SL_DECK) And (DeckN > 1) Then
  Begin
    RRect(X + 4, Y + 4, X + KW + 3, Y + KH + 3, C_SHADOW);
    DrawBack(X + 2, Y + 2);
    Outline(X + 2, Y + 2, C_BORDER, 1);
  End;
  DrawCard(X, Y, C, Up, Hl);
End;

Procedure DrawLabels;
Var S : String; C, Y, P : LongInt;
Begin
  For P := 0 To 1 Do
  Begin
    If P = 0 Then Y := 202 Else Y := 4;
    If P = 0 Then S := 'Vous' Else S := 'Ordinateur';
    If (Cur = P) And (State >= G_DRAW) And (State <= G_TURNUP) Then C := C_YELLOW Else C := C_TEXT;
    If (Cur = P) And (State >= G_DRAW) And (State <= G_TURNUP) Then Tri(8, Y + 3, Y + 11, 0, C_YELLOW, False);
    If (Cur = P) And (State >= G_DRAW) And (State <= G_TURNUP) Then
      For C := 0 To 4 Do Rect(4, Y + 4 + C, 4 + (4 - Abs(C - 2)) * 2, Y + 4 + C, C_YELLOW);
    If (Cur = P) And (State >= G_DRAW) And (State <= G_TURNUP) Then C := C_YELLOW Else C := C_TEXT;
    FbTextSh(16, Y, S + ' : ' + IStr(HandScore(P, True)) + ' pt', C, 1);
    If Finisher = P Then FbTextSh(16 + (Length(S) + 10) * 8, Y, '- termin' + Chr(130), C_PAIR, 1);
  End;
  If Finisher >= 0 Then
    If (State >= G_DRAW) And (State <= G_TURNUP) Then FbTextSh(DeckX, 262, 'Dernier tour !', C_YELLOW, 1);
  FbTextSh(DeckX, 290, 'Trou ' + IStr(Hole) + ' / ' + IStr(Holes), C_TEXT, 1);
  FbTextSh(DeckX, 308, 'Pioche : ' + IStr(DeckN) + ' cartes', C_TEXT, 1);
End;

Procedure DrawFlights;
Var K, X, Y : LongInt;
Begin
  For K := 0 To MaxFly - 1 Do
    If FlyOn[K] <> 0 Then
    Begin
      X := FlyX0[K] + (FlyX1[K] - FlyX0[K]) * FlyT[K] Div FlyN[K];
      Y := FlyY0[K] + (FlyY1[K] - FlyY0[K]) * FlyT[K] Div FlyN[K];
      { une carte en vol est un peu soulevee : ombre plus loin }
      RRect(X + 6, Y + 7, X + KW + 5, Y + KH + 6, C_SHADOW);
      If FlyUp[K] <> 0 Then DrawFace(X, Y, FlyC[K]) Else DrawBack(X, Y);
      Outline(X, Y, C_BORDER, 1);
    End;
End;

Procedure Render;
Var S : LongInt;
Begin
  Move(Back, Fb, SizeOf(Fb));
  For S := 0 To 14 Do DrawSlot(S);
  DrawLabels;
  DrawFlights;
  DrawBanner;
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Procedure BlitAll(H : LongInt);
Var P : Array[0..7] Of LongInt;
Begin
  P[0] := OX; P[1] := CH - OY - BH; P[2] := OX + BW; P[3] := CH - OY;
  P[4] := 0; P[5] := 0; P[6] := BW; P[7] := BH;
  Dummy := GpiDrawBits(H, LongInt(@Fb), LongInt(@Bmi), 4, LongInt(@P), $CC, 0);
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

{ carnet : trous, vos points, ceux de l'ordinateur, total }
Procedure DrawCard2;
Var H, Y, C : LongInt;
Begin
  FBar(PnX, 70, PnX + PW - 1, 262, CLR_PALEGRAY);
  OutTxt(PnX, 70, 'Trou Vous Ordi', CLR_DARKBLUE, CLR_PALEGRAY);
  FBar(PnX, 87, PnX + PW - 1, 87, CLR_DARKGRAY);
  For H := 1 To Holes Do
  Begin
    Y := 72 + H * 18;
    If (H = Hole) And (State <> G_OVER) Then C := CLR_DARKRED Else C := CLR_BLACK;
    OutTxt(PnX + 8, Y, IStr(H), C, CLR_PALEGRAY);
    If (H < Hole) Or ((H = Hole) And ((State = G_HOLEEND) Or (State = G_OVER))) Then
    Begin
      OutTxt(PnX + 40 + 32 - Length(IStr(HS[(H - 1) * 2])) * 8, Y, IStr(HS[(H - 1) * 2]), CLR_BLACK, CLR_PALEGRAY);
      OutTxt(PnX + 88 + 32 - Length(IStr(HS[(H - 1) * 2 + 1])) * 8, Y, IStr(HS[(H - 1) * 2 + 1]), CLR_BLACK,
             CLR_PALEGRAY);
    End
    Else OutTxt(PnX + 56, Y, '-      -', CLR_DARKGRAY, CLR_PALEGRAY);
  End;
  Y := 76 + (Holes + 1) * 18;
  FBar(PnX, Y - 3, PnX + PW - 1, Y - 3, CLR_DARKGRAY);
  OutTxt(PnX, Y, 'Total', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX + 40 + 32 - Length(IStr(Tot[0])) * 8, Y, IStr(Tot[0]), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX + 88 + 32 - Length(IStr(Tot[1])) * 8, Y, IStr(Tot[1]), CLR_DARKBLUE, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 4 * 16) Div 2, 4, 'Golf', CLR_DARKGREEN, CLR_PALEGRAY);
  OutTxt(PnX + (PW - 13 * 8) Div 2, 40, 'jeu de cartes', CLR_DARKGRAY, CLR_PALEGRAY);
  DrawCard2;
  Button(PnX, 300, PW, 28, 'Nouvelle partie');
  Button(PnX, 334, PW, 28, 'R' + Chr(138) + 'gles');
  If Games > 0 Then OutTxt(PnX, 372, 'Parties : ' + IStr(Wins) + '/' + IStr(Games), CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawStatus;
Begin
  FBar(0, CH - 22, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(2, CH - 21, CW - 3, CH - 2, CLR_DARKGRAY, CLR_WHITE);
  OutTxt(8, CH - 19, Msg, CLR_BLACK, CLR_PALEGRAY);
End;

Function Sig : LongInt;
Begin
  Sig := Tot[0] * 7 + Tot[1] * 131 + Hole * 1009 + State * 10007 + Holes * 77 + Games * 3 + Wins * 5;
End;

Procedure PaintAll(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 0, CW - 1, CH - 1, CLR_PALEGRAY);
  Edge(OX - 2, OY - 2, OX + BW + 1, OY + BH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(OX - 1, OY - 1, OX + BW, OY + BH, CLR_BLACK, CLR_PALEGRAY);
  Render;
  BlitAll(Hps);
  Dirty := 0;
  DrawPanel;
  DrawStatus;
  LastMsg := Msg; LastSig := Sig;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
End;

Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  If (Dirty = 0) And (Sig = LastSig) And (Msg = LastMsg) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If Dirty <> 0 Then
  Begin
    Render;
    BlitAll(Hps);
    Dirty := 0;
  End;
  If Sig <> LastSig Then
  Begin
    LastSig := Sig;
    DrawCard2;
    If Games > 0 Then OutTxt(PnX, 372, 'Parties : ' + IStr(Wins) + '/' + IStr(Games), CLR_DARKGRAY, CLR_PALEGRAY);
  End;
  If Msg <> LastMsg Then
  Begin
    LastMsg := Msg;
    DrawStatus;
  End;
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Joueur                                                                }
{ ==================================================================== }

Procedure Refuse(S : String);
Begin
  PlaySnd(5);
  Msg := S;
End;

{ clic (ou touche) sur l'emplacement S }
Procedure Pick(S : LongInt);
Begin
  If (State = G_HOLEEND) Then Begin NextHole; Redraw; Exit; End;
  If State = G_OVER Then Exit;
  If (Cur <> 0) Or (AutoAll <> 0) Or Flying Then Exit;
  Case State Of
    G_FLIP :
      If (S < 6) And (HandUp[S] = 0) Then
      Begin
        HandUp[S] := 1; PlaySnd(1); Inc(Flips); Dirty := 1;
        If Flips >= 2 Then
        Begin
          Cur := Starter; State := G_DRAW; Wait := 0;
          SetMsg;
        End;
      End;
    G_DRAW :
      If S = SL_DECK Then DrawDeck(0)
      Else If (S = SL_DISC) And (DiscN > 0) Then TakeDisc(0);
    G_HOLD :
      If S < 6 Then Exchange(0, S)
      Else If S = SL_DISC Then
      Begin
        If HoldFromDeck <> 0 Then Discard(0)
        Else Refuse('Une carte prise de la d' + Chr(130) + 'fausse doit ' + Chr(136) + 'tre ' + Chr(130) +
                    'chang' + Chr(130) + 'e avec une de vos cartes.');
      End;
    G_TURNUP :
      If (S < 6) And (HandUp[S] = 0) Then TurnUp(0, S)
      Else If S < 6 Then Refuse('Cette carte est d' + Chr(130) + 'j' + Chr(133) + ' retourn' + Chr(130) + 'e.');
  End;
End;

Function SlotAt(X, Y : LongInt) : LongInt;
Var S, R : LongInt;
Begin
  R := -1;
  For S := 0 To 14 Do
    If (S < 6) Or (S >= 12) Then
      If (X >= SlotX(S)) And (X < SlotX(S) + KW) And (Y >= SlotY(S)) And (Y < SlotY(S) + KH) Then R := S;
  SlotAt := R;
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  MoveFlights;
  If Not Flying Then
    If (State >= G_DRAW) And (State <= G_TURNUP) And ((Cur = 1) Or (AutoAll <> 0)) Then
    Begin
      Inc(Wait);
      If Wait > 14 Then
      Begin
        Wait := 0;
        AiStep(Cur);
      End;
    End
    Else If (State = G_HOLEEND) And (AutoAll <> 0) Then
    Begin
      Inc(Wait);
      If Wait > 60 Then Begin NextHole; Redraw; End;
    End
    Else If (State = G_OVER) And (AutoAll <> 0) Then
    Begin
      Inc(Wait);
      If Wait > 120 Then Begin NewGame; Redraw; End;
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
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0);
  SetMark(CM_H9, NextHoles = 9); SetMark(CM_H3, NextHoles = 3);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : Begin NewGame; Redraw; End;
    CM_NEXT : If State = G_HOLEEND Then Begin NextHole; Redraw; End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_H9, CM_H3 :
      Begin
        If Id = CM_H9 Then NextHoles := 9 Else NextHoles := 3;
        SetMarks;
        If (Hole = 1) And (State <> G_HOLEEND) And (State <> G_OVER) Then
        Begin
          Holes := NextHoles;
          Redraw;
        End
        Else Msg := 'Le nouveau parcours commencera ' + Chr(133) + ' la prochaine partie (F2).';
      End;
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll; SetMarks; Wait := 0;
        If (AutoAll <> 0) And (State = G_FLIP) Then
        Begin
          AutoFlips(0); Flips := 2;
          Cur := Starter; State := G_DRAW;
        End;
        SetMsg; Dirty := 1;
      End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Golf se joue ' + Chr(133) + ' deux, vous contre l''ordinateur, en ' + IStr(NextHoles) + ' trous ; ' +
             'le plus petit total gagne. ');
        LAdd('Chaque joueur a six cartes face cach' + Chr(130) + 'e en deux rang' + Chr(130) + 'es de trois ; au ' +
             'd' + Chr(130) + 'but du trou, retournez-en deux.' + Chr(10) + Chr(10));
        LAdd('A votre tour, prenez la carte de la pioche ou celle de la d' + Chr(130) + 'fausse, puis ' + Chr(130) +
             'changez-la avec une de vos six cartes (celle-ci va sur la d' + Chr(130) + 'fausse). Une carte de la ' +
             'pioche peut aussi ' + Chr(136) + 'tre d' + Chr(130) + 'fauss' + Chr(130) + 'e : retournez alors une de ' +
             'vos cartes cach' + Chr(130) + 'es. ');
        LAdd('Quand un joueur a retourn' + Chr(130) + ' ses six cartes, l''autre joue un dernier tour.' + Chr(10) +
             Chr(10));
        LAdd('Valeurs : As 1, 2 ' + Chr(133) + ' 10 leur valeur, Valet et Dame 10, Roi 0. Deux cartes du m' + Chr(136) +
             'me rang dans une colonne valent 0 (contour vert).' + Chr(10) + Chr(10));
        LAdd('Clavier : D (piocher), P (prendre la d' + Chr(130) + 'fausse), 1 ' + Chr(133) + ' 6 (vos cartes, ' +
             'rang' + Chr(130) + 'e du haut puis du bas), F (d' + Chr(130) + 'fausser la carte en main), Espace ' +
             '(trou suivant), F2 (nouvelle partie).');
        Dummy := LMsgBox('Golf - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Golf pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype GOLF.PAS ' +
                            'de 7iles.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) +
                            ' par OS2PC.', 'A propos', MB_OK Or MB_INFORMATION);
  End;
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
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      If State = G_HOLEEND Then Begin NextHole; Redraw; End;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'D' : Pick(SL_DECK);
      'P' : If State = G_DRAW Then Pick(SL_DISC);
      'F' : If State = G_HOLD Then Pick(SL_DISC);
      '1'..'6' : Pick(Ch - Ord('1'));
      'N' : Command(CM_NEW);
      ' ' : If State = G_HOLEEND Then Begin NextHole; Redraw; End;
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
    If (Y >= 300) And (Y < 328) Then Command(CM_NEW)
    Else If (Y >= 334) And (Y < 362) Then Command(CM_RULES);
    Exit;
  End;
  If (X >= OX) And (X < OX + BW) And (Y >= OY) And (Y < OY + BH) Then
  Begin
    If State = G_HOLEEND Then Begin NextHole; Redraw; Exit; End;
    Pick(SlotAt(X - OX, Y - OY));
  End;
End;

Function MainProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y, S : LongInt;
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
        X := S16(Mp1) - OX; Y := CH - 1 - S16(Mp1 Shr 16) - OY;
        S := SlotAt(X, Y);
        If S <> HoverSl Then
        Begin
          HoverSl := S; Dirty := 1;
        End;
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
{ Essais (/TEST)                                                        }
{ ==================================================================== }

Function Card(R, Su : LongInt) : LongInt;
Begin
  Card := Su * 13 + R - 1;
End;

Procedure SetHand(P, A, B, C, D, E, F : LongInt);
Begin
  HandC[P * 6] := A; HandC[P * 6 + 1] := B; HandC[P * 6 + 2] := C;
  HandC[P * 6 + 3] := D; HandC[P * 6 + 4] := E; HandC[P * 6 + 5] := F;
End;

Procedure RunTests;
Var Ok, I, N, K, D1, D2, E1, E2 : LongInt;
Begin
  Ok := 0;
  { 1 : paires de Rois et de 7 dans leurs colonnes -> 5 + 9 = 14 }
  SetHand(0, Card(13, 3), Card(5, 0), Card(7, 2), Card(13, 0), Card(9, 1), Card(7, 3));
  For I := 0 To 5 Do HandUp[I] := 1;
  N := HandScore(0, True);
  Log('GOLF : TEST1 pointage ' + IStr(N));
  If N = 14 Then Inc(Ok);
  { 2 : As 1, Valet et Dame 10 (pas une paire), 10 ; cartes cachees non comptees }
  SetHand(0, Card(1, 0), Card(11, 2), Card(10, 1), Card(2, 3), Card(12, 0), Card(3, 2));
  N := HandScore(0, True);
  HandUp[5] := 0;
  K := HandScore(0, True);
  Log('GOLF : TEST2 pointage ' + IStr(N) + ' visible ' + IStr(K));
  If (N = 36) And (K = 33) Then Inc(Ok);
  { 3 : pioche vide, la defausse est rebattue (sa derniere carte reste) }
  DeckN := 0; DiscN := 0;
  For I := 0 To 4 Do PushDisc(Card(I + 1, 1));
  State := G_DRAW; Cur := 0;
  DrawDeck(0);
  Log('GOLF : TEST3 pioche ' + IStr(DeckN) + ' defausse ' + IStr(DiscN) + ' main ' + IStr(Ord(HoldC >= 0)) +
      ' dessus ' + IStr(Rank(DiscTop)));
  If (DeckN = 3) And (DiscN = 1) And (HoldC >= 0) And (Rank(DiscTop) = 5) Then Inc(Ok);
  { 4 : dernier tour : le joueur 0 retourne sa derniere carte, l'ordinateur joue encore une fois }
  For I := 0 To 51 Do DeckA[I] := I;
  DeckN := 40; DiscN := 0; PushDisc(Card(13, 1));
  For I := 0 To 11 Do HandUp[I] := 1;
  HandUp[5] := 0; HandUp[9] := 0; HandUp[10] := 0;
  Finisher := -1; Hole := 1; Holes := 9; Tot[0] := 0; Tot[1] := 0;
  Cur := 0; State := G_TURNUP;
  TurnUp(0, 5);
  D1 := Finisher; D2 := Cur; E1 := State;
  Cur := 1; State := G_TURNUP;
  TurnUp(1, 3);
  E2 := State;
  Log('GOLF : TEST4 fini ' + IStr(D1) + ' tour ' + IStr(D2) + ' etat ' + IStr(E1) + ' puis ' + IStr(E2));
  If (D1 = 0) And (D2 = 1) And (E1 = G_DRAW) And (E2 = G_HOLEEND) Then Inc(Ok);
  { 5 : parcours de 9 trous joue par l'ordinateur des deux cotes (graine fixe) }
  Seed := 4321; NextHoles := 9; AutoAll := 1;
  NewGame;
  N := 0;
  While (State <> G_OVER) And (N < 20000) Do
  Begin
    If State = G_HOLEEND Then NextHole
    Else AiStep(Cur);
    Inc(N);
  End;
  Log('GOLF : PARTIE trous ' + IStr(Hole) + ' coups ' + IStr(N) + ' vous ' + IStr(Tot[0]) + ' ordinateur ' +
      IStr(Tot[1]) + ' rebattues ' + IStr(Reshuffles));
  Log('GOLF : ' + IStr(Ok) + '/4 essais reussis');
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
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Tick := 0; Client := 0; Frame := 0;
  SoundOn := 1; NextHoles := 9; Holes := 9; Hole := 1; SndCur := 0; SndEnd := 0; TestMode := 0; HoverSl := -1;
  Games := 0; Wins := 0; Reshuffles := 0; CW := CWant; CH := CHWant; Dirty := 1; State := G_FLIP; Cur := 0;
  Finisher := -1; HoldC := -1; InDlg := 0;
  ClearFly;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    For E := 1 To Length(S) Do S[E] := UpCase(S[E]);
    If (Length(S) > 6) And (Copy(S, 1, 6) = '/SEED:') Then Val(Copy(S, 7, 20), Seed, E);
    If (Length(S) > 7) And (Copy(S, 1, 7) = '/HOLES:') Then
    Begin
      Val(Copy(S, 8, 20), NextHoles, E);
      If NextHoles < 1 Then NextHoles := 1;
      If NextHoles > 9 Then NextHoles := 9;
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
  RenderBack;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('GOLF'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('GOLF'), Z2('Golf'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_NEXT, '~Trou suivant' + Chr(9) + 'Espace');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_H9, 'Parcours de ~9 trous');
  MItem(MIS_TEXT, 0, CM_H3, 'Parcours de ~3 trous');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MenuClose(H3, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Golf');
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
