{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: BOSTON - Boston, jeu de levees a quatre avec encheres pour
                le Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program BOSTON;

{$R-,S-,I-}

{ Compilation : OS2PC BOSTON.PAS   (produit BOSTON.EXE)

  Portage vers OS/2-0 du prototype BOSTON.PAS du depot 7iles (Turbo
  Pascal et BGI : cartes en rectangles de 30 x 45, symboles en ellipses,
  touches 1 a 9 pour jouer, contrat impose) : fenetre de Presentation
  Manager avec menus, image en memoire recopiee par GpiDrawBits, tapis
  vert dans un cadre de bois, cartes dessinees (index, grand symbole,
  figures encadrees), dos de cartes a croisillons, mains des adversaires
  en eventail, levee au centre, cartes qui glissent vers le tapis, boite
  d'encheres en relief a la maniere d'OS/2, bulles des annonces, panneau
  du contrat et des pointages, barre d'etat et apparence d'OS/2 Warp 3.

  Comme le prototype : vous (Sud) contre Ouest, Nord et Est (l'ordinateur),
  13 cartes chacun, jeu dans le sens des aiguilles d'une montre ; il faut
  fournir a la couleur demandee ; l'atout l'emporte, sinon la plus haute
  carte de la couleur demandee (l'as est la plus forte) ; le contrat
  demande de 5 a 13 levees dans une couleur ou sans atout ; la partie se
  joue par levees.
  Ce qui est corrige : le prototype imposait toujours au joueur humain un
  contrat de 7 levees dans une couleur tiree au hasard (pas d'encheres) ;
  les touches 1 a 9 ne permettaient pas de jouer les cartes 10 a 13 ;
  l'ordinateur jouait la premiere carte de la couleur demandee ou une
  carte << moyenne >> ; la carte choisie n'etait jamais mise en evidence
  (le jaune etait aussitot ecrase par le dessin de la carte) ; le nom du
  gagnant de la levee disparaissait aussitot ; la partie s'arretait apres
  une seule donne sans aucun pointage ; des attentes de 1,5 et 2 secondes
  bloquaient le programme.
  Ce qui s'ajoute : les encheres (chaque joueur annonce plus haut ou
  passe ; un joueur qui passe ne revient plus ; si tous passent, on
  redonne), le demandeur qui joue seul contre les trois autres, le
  pointage du Boston (valeur du contrat, surlevees et levees de chute,
  paye par chaque adversaire), une partie de 4 ou 8 donnes avec donneur
  tournant, un ordinateur qui evalue sa main pour encherir, compte les
  cartes passees, tire les atouts et se defausse avec soin, la derniere
  levee, la souris, la demonstration et les bruitages.

  Souris : clic sur une carte de votre main (les cartes jouables sont
  claires, les autres grisees), clic dans la boite d'encheres. Clavier :
  fleches gauche et droite et Entree (jouer), 1 a 9 (comme le prototype),
  pendant les encheres fleches haut et bas (nombre de levees), gauche et
  droite (couleur), Entree (annoncer), P (passer) ; L (derniere levee),
  N ou Entree (donne suivante), F2 (nouvelle partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (l'ordinateur joue aussi pour vous) ;
  /NOSOUND ; /TEST (essais du jeu sans fenetre, resultat sur le port
  serie COM1). }

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
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_SPACE = $10;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_DARKGREEN = 12; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_NEXT = 102; CM_LAST = 103; CM_QUIT = 104;
  CM_AUTO = 201; CM_SOUND = 202; CM_FAST = 203; CM_SHORT = 204; CM_LONG = 205;
  CM_RULES = 301; CM_ABOUT = 302;
  { image : tapis de 432 x 400 }
  BW = 432; BH = 400; OX = 8; OY = 8;
  PnX = 452; PW = 164;
  CWant = 624; CHWant = 436;
  { cartes }
  CardW = 50; CardH = 70; Spread = 26; HandY = 318;
  SBw = 34; SBh = 48; SOv = 12;              { petits dos (adversaires) }
  { boite d'encheres }
  BX1 = 66; BY1 = 100; BX2 = 366; BY2 = 276;
  { phases }
  PH_BID = 1; PH_PLAY = 2; PH_TRICK = 3; PH_END = 4; PH_OVER = 5; PH_REDEAL = 6;
  { couleurs de l'image }
  C_FELT = 0;                                { 0..15 : tapis (sombre -> clair) }
  C_WOOD = 16;                               { 16..23 : bois }
  C_WHITE = 24; C_BLACK = 25; C_RED = 26; C_EDGE = 27; C_SHADOW = 28; C_BACK = 29; C_BACK2 = 30;
  C_GOLD = 31; C_GOLD2 = 32; C_CREAM = 33; C_TEXT = 34; C_DIMF = 35; C_SEL = 36; C_BANNER = 37; C_BANNERE = 38;
  C_BTN = 39; C_BTNL = 40; C_BTND = 41; C_BTNS = 42; C_GRAYT = 43; C_GREENT = 44; C_REDT = 45; C_YELLOW = 46;
  C_TITLE = 47; C_DIMR = 48; C_DIMK = 49; C_BUBBLE = 50;
  SndRate = 11025;

Var
  InDlg : LongInt;
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Fb, Back : Array[0..BW * BH - 1] Of Byte;
  Bmi : Array[0..16 + 256 * 4 - 1] Of Byte;
  { cartes 0..51 : couleur C div 13 (0 trefle, 1 carreau, 2 coeur, 3 pique),
    rang C mod 13 (0 : le 2 ... 12 : l'as) ; joueurs 0 Sud (vous), 1 Ouest,
    2 Nord, 3 Est }
  Deck : Array[0..51] Of LongInt;
  Hand : Array[0..51] Of LongInt;            { joueur * 13 + i }
  NHand, Tricks, Total, DealPts, BidOf, Passed, TrickC, LastC : Array[0..3] Of LongInt;
  Played : Array[0..51] Of LongInt;
  VoidS : Array[0..15] Of LongInt;           { joueur * 4 + couleur : coupe connue }
  CurBid, BidBy, Declarer, CLevel, Trump, Dealer, DealNo, NDeals, Leader, LeadSuit, NTrick, TrickNo : LongInt;
  LastWin, LastShow, Phase, CurP, Sel, Wait, Seed, AutoAll, SoundOn, TestMode, Fast, Tick : LongInt;
  BLvl, BSuit, Redeals, Made, Failed, HumanMade, SumLvl : LongInt;
  { carte qui glisse vers le tapis }
  AnOn, AnC, AnK, AnX0, AnY0, AnX1, AnY1 : LongInt;
  FullBlit, Dirty, BackOk : LongInt;
  Banner, Banner2, Banner3, Msg, LastMsg : String;
  BannerC : LongInt;
  PanS : Array[0..15] Of String[40];
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
  For I := 0 To 15 Do SetPal(C_FELT + I, Mix($07301A, $1C7A42, I, 15));
  For I := 0 To 7 Do SetPal(C_WOOD + I, Mix($34180A, $A8662E, I, 7));
  SetPal(C_WHITE, $FFFFFF); SetPal(C_BLACK, $141414); SetPal(C_RED, $D0181E); SetPal(C_EDGE, $6E6E6E);
  SetPal(C_SHADOW, $041A0C); SetPal(C_BACK, $7A1420); SetPal(C_BACK2, $C04050); SetPal(C_GOLD, $F0C83C);
  SetPal(C_GOLD2, $A07E1C); SetPal(C_CREAM, $FFF2D0); SetPal(C_TEXT, $D8F4DC); SetPal(C_DIMF, $B4B8B4);
  SetPal(C_SEL, $FFE040); SetPal(C_BANNER, $0C2414); SetPal(C_BANNERE, $E8D070);
  SetPal(C_BTN, $CCCCCC); SetPal(C_BTNL, $FFFFFF); SetPal(C_BTND, $808080); SetPal(C_BTNS, $203C9C);
  SetPal(C_GRAYT, $8C8C8C); SetPal(C_GREENT, $90F0A8); SetPal(C_REDT, $FF7868); SetPal(C_YELLOW, $FFDC40);
  SetPal(C_TITLE, $1C2C8C); SetPal(C_DIMR, $9A5458); SetPal(C_DIMK, $5A5E5A); SetPal(C_BUBBLE, $FAFAF0);
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

{ ==================================================================== }
{ Cartes et dessin                                                      }
{ ==================================================================== }

Function CSuit(C : LongInt) : LongInt;
Begin
  CSuit := C Div 13;
End;

Function CRank(C : LongInt) : LongInt;
Begin
  CRank := C Mod 13;
End;

Function RankName(R : LongInt) : String;
Var S : String;
Begin
  Case R Of
    9 : S := 'V';
    10 : S := 'D';
    11 : S := 'R';
    12 : S := 'A';
  Else
    S := IStr(R + 2);
  End;
  RankName := S;
End;

Function RankLong(R : LongInt) : String;
Var S : String;
Begin
  Case R Of
    9 : S := 'valet';
    10 : S := 'dame';
    11 : S := 'roi';
    12 : S := 'as';
  Else
    S := IStr(R + 2);
  End;
  RankLong := S;
End;

Function SuitName(S : LongInt) : String;
Var R : String;
Begin
  Case S Of
    0 : R := 'tr' + Chr(138) + 'fle';
    1 : R := 'carreau';
    2 : R := 'coeur';
    3 : R := 'pique';
  Else
    R := 'sans atout';
  End;
  SuitName := R;
End;

{ symbole de la couleur dans la police du VGA }
Function SuitCh(S : LongInt) : String;
Var R : String;
Begin
  Case S Of
    0 : R := Chr(5);
    1 : R := Chr(4);
    2 : R := Chr(3);
    3 : R := Chr(6);
  Else
    R := 'SA';
  End;
  SuitCh := R;
End;

Function CardName(C : LongInt) : String;
Var S : String;
Begin
  S := RankLong(CRank(C)) + ' de ' + SuitName(CSuit(C));
  If CRank(C) = 12 Then S := 'as de ' + SuitName(CSuit(C));
  CardName := S;
End;

Function PName(P : LongInt) : String;
Var S : String;
Begin
  Case P Of
    0 : S := 'Vous';
    1 : S := 'Ouest';
    2 : S := 'Nord';
  Else
    S := 'Est';
  End;
  PName := S;
End;

{ rectangle aux coins arrondis }
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

Procedure FbCenter(Cx, Y : LongInt; S : String; C, Sc : LongInt);
Begin
  FbTextSh(Cx - Length(S) * 4 * Sc, Y, S, C, Sc);
End;

{ dos de carte : bordure blanche, croisillons bordeaux, filet dore }
Procedure DrawBack(X, Y, W, H : LongInt);
Var I, J : LongInt;
Begin
  RRect(X + 2, Y + 2, X + W + 1, Y + H + 1, 4, C_SHADOW);
  RRect(X, Y, X + W - 1, Y + H - 1, 4, C_EDGE);
  RRect(X + 1, Y + 1, X + W - 2, Y + H - 2, 3, C_WHITE);
  Rect(X + 3, Y + 3, X + W - 4, Y + H - 4, C_BACK);
  For J := Y + 4 To Y + H - 5 Do
    For I := X + 4 To X + W - 5 Do
      If ((I - X + J - Y) Mod 6 = 0) Or ((I - X - (J - Y) + 600) Mod 6 = 0) Then Pix(I, J, C_BACK2);
  Rect(X + 5, Y + 5, X + W - 6, Y + 5, C_GOLD2); Rect(X + 5, Y + H - 6, X + W - 6, Y + H - 6, C_GOLD2);
  Rect(X + 5, Y + 5, X + 5, Y + H - 6, C_GOLD2); Rect(X + W - 6, Y + 5, X + W - 6, Y + H - 6, C_GOLD2);
  Disc(X + W Div 2, Y + H Div 2, 3, C_GOLD);
End;

{ carte face visible ; Dim : carte qu'on ne peut pas jouer (grisee) }
Procedure DrawCard(X, Y, C : LongInt; Dim, Hi : Boolean);
Var Fg, Face, R, Cx, Cy : LongInt; S, Sy : String;
Begin
  RRect(X + 2, Y + 2, X + CardW + 1, Y + CardH + 1, 5, C_SHADOW);
  If Hi Then RRect(X - 2, Y - 2, X + CardW + 1, Y + CardH + 1, 6, C_SEL);
  RRect(X, Y, X + CardW - 1, Y + CardH - 1, 5, C_EDGE);
  If Dim Then Face := C_DIMF Else Face := C_WHITE;
  RRect(X + 1, Y + 1, X + CardW - 2, Y + CardH - 2, 4, Face);
  If (CSuit(C) = 1) Or (CSuit(C) = 2) Then
  Begin
    If Dim Then Fg := C_DIMR Else Fg := C_RED;
  End
  Else If Dim Then Fg := C_DIMK Else Fg := C_BLACK;
  R := CRank(C);
  S := RankName(R); Sy := SuitCh(CSuit(C));
  FbText(X + 3, Y + 2, S, Fg, 1);
  FbText(X + 3, Y + 17, Sy, Fg, 1);
  FbText(X + CardW - 4 - Length(S) * 8, Y + CardH - 18, S, Fg, 1);
  Cx := X + CardW Div 2; Cy := Y + CardH Div 2;
  If R >= 9 Then
  Begin
    If R = 12 Then FbText(Cx - 12, Cy - 24, Sy, Fg, 3)
    Else
    Begin
      { figure : cadre creme et dore, grande lettre }
      Rect(Cx - 12, Cy - 22, Cx + 15, Cy + 21, Fg);
      If Dim Then Rect(Cx - 11, Cy - 21, Cx + 14, Cy + 20, C_DIMF)
      Else Rect(Cx - 11, Cy - 21, Cx + 14, Cy + 20, C_CREAM);
      Rect(Cx - 9, Cy - 19, Cx + 12, Cy - 18, C_GOLD); Rect(Cx - 9, Cy + 17, Cx + 12, Cy + 18, C_GOLD);
      FbText(Cx - 6, Cy - 16, S, Fg, 2);
      FbText(Cx + 5, Cy + 1, Sy, Fg, 1);
    End;
  End
  Else FbText(Cx - 7, Cy - 15, Sy, Fg, 2);
End;

{ bulle d'annonce }
Procedure Bubble(X, Y : LongInt; S : String; C : LongInt);
Var W : LongInt;
Begin
  W := Length(S) * 8 + 12;
  RRect(X + 2, Y + 2, X + W + 1, Y + 21, 7, C_SHADOW);
  RRect(X, Y, X + W - 1, Y + 19, 7, C_GOLD2);
  RRect(X + 1, Y + 1, X + W - 2, Y + 18, 6, C_BUBBLE);
  FbText(X + 6, Y + 2, S, C, 1);
End;

Function BidText(B : LongInt) : String;
Var S : String;
Begin
  If B = -1 Then S := 'Passe'
  Else If B Mod 5 = 4 Then S := IStr(5 + B Div 5) + ' SA'
  Else S := IStr(5 + B Div 5) + ' ' + SuitCh(B Mod 5);
  BidText := S;
End;

Function BidLong(B : LongInt) : String;
Var S : String;
Begin
  If B < 0 Then S := 'passe'
  Else S := IStr(5 + B Div 5) + ' ' + SuitName(B Mod 5);
  BidLong := S;
End;

Function BidColor(B : LongInt) : LongInt;
Begin
  If (B >= 0) And ((B Mod 5 = 1) Or (B Mod 5 = 2)) Then BidColor := C_RED
  Else If B = -1 Then BidColor := C_GRAYT
  Else BidColor := C_BLACK;
End;

{ ==================================================================== }
{ Positions                                                             }
{ ==================================================================== }

Function HandX0 : LongInt;
Begin
  HandX0 := (BW - ((NHand[0] - 1) * Spread + CardW)) Div 2;
End;

{ emplacement de la carte de chaque joueur dans la levee }
Procedure SlotXY(P : LongInt; Var X, Y : LongInt);
Begin
  Case P Of
    0 : Begin X := 191; Y := 206; End;
    1 : Begin X := 124; Y := 158; End;
    2 : Begin X := 191; Y := 110; End;
  Else
    Begin X := 258; Y := 158; End;
  End;
End;

{ d'ou part la carte jouee par un adversaire }
Procedure FromXY(P : LongInt; Var X, Y : LongInt);
Begin
  Case P Of
    1 : Begin X := 8; Y := 150; End;
    2 : Begin X := 191; Y := 8; End;
  Else
    Begin X := BW - 58; Y := 150; End;
  End;
End;

{ ==================================================================== }
{ Regles : donne, cartes jouables, levee, encheres                      }
{ ==================================================================== }

Function HCard(P, I : LongInt) : LongInt;
Begin
  HCard := Hand[P * 13 + I];
End;

{ ordre d'affichage : atout d'abord, puis pique, coeur, trefle, carreau
  (rouges et noires alternees), rang decroissant }
Function SortKey(C : LongInt) : LongInt;
Var S, K : LongInt;
Begin
  S := CSuit(C);
  Case S Of
    3 : K := 0;
    2 : K := 1;
    0 : K := 2;
  Else
    K := 3;
  End;
  If (Trump < 4) And (S = Trump) And (Declarer >= 0) Then K := -1;
  SortKey := K * 13 + (12 - CRank(C));
End;

Procedure SortHand(P : LongInt);
Var I, J, T : LongInt;
Begin
  For I := 0 To NHand[P] - 2 Do
    For J := I + 1 To NHand[P] - 1 Do
      If SortKey(Hand[P * 13 + J]) < SortKey(Hand[P * 13 + I]) Then
      Begin
        T := Hand[P * 13 + I]; Hand[P * 13 + I] := Hand[P * 13 + J]; Hand[P * 13 + J] := T;
      End;
End;

Procedure DealCards;
Var I, J, T, P : LongInt;
Begin
  For I := 0 To 51 Do Deck[I] := I;
  For I := 51 DownTo 1 Do
  Begin
    J := Rnd(I + 1);
    T := Deck[I]; Deck[I] := Deck[J]; Deck[J] := T;
  End;
  { distribution une par une, en commencant a gauche du donneur }
  For I := 0 To 51 Do
  Begin
    P := (Dealer + 1 + I) Mod 4;
    Hand[P * 13 + I Div 4] := Deck[I];
  End;
  For P := 0 To 3 Do
  Begin
    NHand[P] := 13; Tricks[P] := 0; BidOf[P] := -2; Passed[P] := 0; TrickC[P] := -1; LastC[P] := -1;
  End;
  For I := 0 To 51 Do Played[I] := 0;
  For I := 0 To 15 Do VoidS[I] := 0;
  CurBid := -1; BidBy := -1; Declarer := -1; Trump := 4; CLevel := 0;
  NTrick := 0; TrickNo := 0; LastWin := -1; LastShow := 0; LeadSuit := -1;
  For P := 0 To 3 Do SortHand(P);
End;

Function HasSuit(P, S : LongInt) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  For I := 0 To NHand[P] - 1 Do
    If CSuit(Hand[P * 13 + I]) = S Then R := True;
  HasSuit := R;
End;

Function CountSuit(P, S : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To NHand[P] - 1 Do
    If CSuit(Hand[P * 13 + I]) = S Then Inc(N);
  CountSuit := N;
End;

Function InHand(P, C : LongInt) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  For I := 0 To NHand[P] - 1 Do
    If Hand[P * 13 + I] = C Then R := True;
  InHand := R;
End;

Function Legal(P, I : LongInt) : Boolean;
Begin
  If NTrick = 0 Then Legal := True
  Else If CSuit(HCard(P, I)) = LeadSuit Then Legal := True
  Else Legal := Not HasSuit(P, LeadSuit);
End;

{ A bat-elle B ? (B est la carte qui gagne pour l'instant) }
Function Beats(A, B : LongInt) : Boolean;
Begin
  If CSuit(A) = CSuit(B) Then Beats := CRank(A) > CRank(B)
  Else Beats := (Trump < 4) And (CSuit(A) = Trump);
End;

Function TrickWinner : LongInt;
Var K, P, W : LongInt;
Begin
  W := Leader;
  For K := 1 To NTrick - 1 Do
  Begin
    P := (Leader + K) Mod 4;
    If Beats(TrickC[P], TrickC[W]) Then W := P;
  End;
  TrickWinner := W;
End;

{ jouer la carte I du joueur P (regles seulement) }
Procedure PlayCardIdx(P, I : LongInt);
Var C, K : LongInt;
Begin
  C := HCard(P, I);
  For K := I To NHand[P] - 2 Do Hand[P * 13 + K] := Hand[P * 13 + K + 1];
  Dec(NHand[P]);
  If NTrick = 0 Then
  Begin
    Leader := P; LeadSuit := CSuit(C);
  End
  Else If CSuit(C) <> LeadSuit Then VoidS[P * 4 + LeadSuit] := 1;
  TrickC[P] := C;
  Played[C] := 1;
  Inc(NTrick);
  CurP := (P + 1) Mod 4;
End;

{ cartes de la couleur S qui ne sont ni jouees ni dans la main de P }
Function OutCount(P, S : LongInt) : LongInt;
Var R, N, C : LongInt;
Begin
  N := 0;
  For R := 0 To 12 Do
  Begin
    C := S * 13 + R;
    If (Played[C] = 0) And Not InHand(P, C) Then Inc(N);
  End;
  OutCount := N;
End;

{ carte maitresse : aucune carte plus forte de sa couleur dehors }
Function IsMaster(P, C : LongInt) : Boolean;
Var R, X : LongInt; M : Boolean;
Begin
  M := True;
  For R := CRank(C) + 1 To 12 Do
  Begin
    X := CSuit(C) * 13 + R;
    If (Played[X] = 0) And Not InHand(P, X) Then M := False;
  End;
  IsMaster := M;
End;

Function BidVal(L, S : LongInt) : LongInt;
Begin
  BidVal := (L - 5) * 5 + S;
End;

{ estimation (en dixiemes de levee) de ce que la main de P rapporte en
  jouant seul avec l'atout T (4 : sans atout) }
Function Estimate(P, T : LongInt) : LongInt;
Var S, N, E, NT, R : LongInt; A, K, Q, J : Boolean;
Begin
  E := 0;
  If T < 4 Then NT := CountSuit(P, T) Else NT := 0;
  For S := 0 To 3 Do
  Begin
    N := CountSuit(P, S);
    A := InHand(P, S * 13 + 12); K := InHand(P, S * 13 + 11); Q := InHand(P, S * 13 + 10); J := InHand(P, S * 13 + 9);
    R := 0;
    If A Then R := R + 10;
    If K Then Begin If N >= 2 Then R := R + 8 Else R := R + 3; End;
    If Q Then Begin If N >= 3 Then R := R + 4 Else If A Or K Then R := R + 2; End;
    If J And (N >= 4) And (A Or K Or Q) Then R := R + 2;
    If S = T Then
    Begin
      If K And (N >= 2) Then R := R + 2;
      If Q And (N >= 3) Then R := R + 3;
      R := R + 10 * MaxI(0, N - 3);
    End
    Else If T = 4 Then R := R + 6 * MaxI(0, N - 4)
    Else If NT >= 4 Then
    Begin
      If N = 0 Then R := R + 12 Else If N = 1 Then R := R + 6;
    End;
    E := E + R;
  End;
  Estimate := E;
End;

{ enchere de l'ordinateur : la moins chere qui depasse l'enchere en cours
  et que la main peut tenir ; -1 : passe }
Function AIBid(P : LongInt) : LongInt;
Var S, E, Lm, L, B, Best, BestE : LongInt;
Begin
  Best := -1; BestE := -1;
  For S := 0 To 4 Do
  Begin
    E := Estimate(P, S);
    Lm := (E + 4) Div 10;
    L := 5;
    While (L <= 13) And (BidVal(L, S) <= CurBid) Do Inc(L);
    { on saute directement pres de ce que vaut la main }
    If L <= Lm Then L := MaxI(L, Lm);
    If (L <= Lm) And (E > BestE) Then
    Begin
      Best := BidVal(L, S); BestE := E;
    End;
  End;
  AIBid := Best;
End;

{ ==================================================================== }
{ Jeu de la carte par l'ordinateur                                      }
{ ==================================================================== }

Var
  LIdx : Array[0..12] Of LongInt;
  NL : LongInt;

Procedure LegalList(P : LongInt);
Var I : LongInt;
Begin
  NL := 0;
  For I := 0 To NHand[P] - 1 Do
    If Legal(P, I) Then
    Begin
      LIdx[NL] := I;
      Inc(NL);
    End;
End;

{ la plus petite carte jouable (defausse : hors atout d'abord) }
Function LowestIdx(P : LongInt) : LongInt;
Var K, I, C, Best, BestV, V : LongInt;
Begin
  Best := LIdx[0]; BestV := 9999;
  For K := 0 To NL - 1 Do
  Begin
    I := LIdx[K]; C := HCard(P, I);
    V := CRank(C);
    If (Trump < 4) And (CSuit(C) = Trump) And (LeadSuit <> Trump) Then V := V + 40;
    If (NTrick > 0) And (CSuit(C) <> LeadSuit) And ((Trump = 4) Or (CSuit(C) <> Trump)) Then
      V := V + CountSuit(P, CSuit(C));
    If V < BestV Then
    Begin
      BestV := V; Best := I;
    End;
  End;
  LowestIdx := Best;
End;

Function LeadIdx(P : LongInt) : LongInt;
Var S, I, C, H, Hi, N, BestN, R, OppT, MyT, Lo : LongInt; IsD, Ok : Boolean;
Begin
  IsD := P = Declarer;
  R := -1;
  If Trump < 4 Then
  Begin
    OppT := OutCount(P, Trump); MyT := CountSuit(P, Trump);
  End
  Else
  Begin
    OppT := 0; MyT := 0;
  End;
  { atout maitre du demandeur : on tire les atouts }
  If IsD And (OppT > 0) And (MyT > 0) Then
  Begin
    Hi := -1;
    For I := 0 To NHand[P] - 1 Do
      If CSuit(HCard(P, I)) = Trump Then
        If (Hi < 0) Or (CRank(HCard(P, I)) > CRank(HCard(P, Hi))) Then Hi := I;
    If IsMaster(P, HCard(P, Hi)) Then R := Hi
    Else If MyT >= 4 Then
    Begin
      Lo := Hi;
      For I := 0 To NHand[P] - 1 Do
        If (CSuit(HCard(P, I)) = Trump) And (CRank(HCard(P, I)) < CRank(HCard(P, Lo))) Then Lo := I;
      R := Lo;
    End;
  End;
  { carte maitresse dans une couleur ou personne ne coupe }
  If R < 0 Then
    For S := 0 To 3 Do
      If (R < 0) And ((Trump = 4) Or (S <> Trump)) And (CountSuit(P, S) > 0) And (OutCount(P, S) > 0) Then
      Begin
        Hi := -1;
        For I := 0 To NHand[P] - 1 Do
          If CSuit(HCard(P, I)) = S Then
            If (Hi < 0) Or (CRank(HCard(P, I)) > CRank(HCard(P, Hi))) Then Hi := I;
        Ok := IsMaster(P, HCard(P, Hi));
        If Ok And (Trump < 4) Then
        Begin
          If IsD And (OppT > 0) Then
          Begin
            For C := 0 To 3 Do
              If (C <> P) And (VoidS[C * 4 + S] <> 0) Then Ok := False;
          End
          Else If (Not IsD) And (VoidS[Declarer * 4 + S] <> 0) And (OutCount(P, Trump) > 0) Then Ok := False;
        End;
        If Ok Then R := Hi;
      End;
  { sinon : la plus petite carte de la plus longue couleur hors atout
    (la defense evite les couleurs ou le demandeur coupe) }
  If R < 0 Then
  Begin
    BestN := -99;
    For S := 0 To 3 Do
      If ((Trump = 4) Or (S <> Trump)) And (CountSuit(P, S) > 0) Then
      Begin
        N := CountSuit(P, S) * 2;
        If (Not IsD) And (Trump < 4) And (VoidS[Declarer * 4 + S] <> 0) Then N := N - 20;
        If N > BestN Then
        Begin
          BestN := N; H := S;
        End;
      End;
    If BestN = -99 Then H := Trump;
    For I := 0 To NHand[P] - 1 Do
      If CSuit(HCard(P, I)) = H Then
        If (R < 0) Or (CRank(HCard(P, I)) < CRank(HCard(P, R))) Then R := I;
  End;
  LeadIdx := R;
End;

Function FollowIdx(P : LongInt) : LongInt;
Var K, I, C, W, WC, R, Cost, BestCost, Hi : LongInt; IsD, Last, DeclPlayed, Partner, Ok0 : Boolean;
Begin
  W := TrickWinner; WC := TrickC[W];
  IsD := P = Declarer;
  Last := NTrick = 3;
  DeclPlayed := TrickC[Declarer] >= 0;
  Partner := (Not IsD) And (W <> Declarer);
  R := -1;
  If Partner Then
  Begin
    If Not (DeclPlayed Or Last) Then
    Begin
      Ok0 := IsMaster(P, WC) And Not ((Trump < 4) And (VoidS[Declarer * 4 + LeadSuit] <> 0));
      If Not Ok0 Then
      Begin
        { surcouvrir avec une carte maitresse }
        BestCost := 9999;
        For K := 0 To NL - 1 Do
        Begin
          C := HCard(P, LIdx[K]);
          If Beats(C, WC) And IsMaster(P, C) Then
          Begin
            Cost := CRank(C);
            If CSuit(C) <> LeadSuit Then Cost := Cost + 20;
            If Cost < BestCost Then Begin BestCost := Cost; R := LIdx[K]; End;
          End;
        End;
      End;
    End;
  End
  Else
  Begin
    BestCost := 9999; Hi := -1;
    For K := 0 To NL - 1 Do
    Begin
      C := HCard(P, LIdx[K]);
      If Beats(C, WC) Then
      Begin
        Cost := CRank(C);
        If CSuit(C) <> LeadSuit Then Cost := Cost + 20;
        If Last Or IsMaster(P, C) Or (CSuit(C) <> LeadSuit) Then
        Begin
          If Cost < BestCost Then Begin BestCost := Cost; R := LIdx[K]; End;
        End;
        If (Hi < 0) Or (CRank(C) > CRank(HCard(P, Hi))) Then Hi := LIdx[K];
      End;
    End;
    { pas de carte sure : la plus forte si c'est une grosse carte }
    If (R < 0) And (Hi >= 0) Then
      If CRank(HCard(P, Hi)) >= 10 Then R := Hi;
  End;
  If R < 0 Then R := LowestIdx(P);
  FollowIdx := R;
End;

Function ChooseCard(P : LongInt) : LongInt;
Var R : LongInt;
Begin
  LegalList(P);
  If NL = 1 Then R := LIdx[0]
  Else If NTrick = 0 Then R := LeadIdx(P)
  Else R := FollowIdx(P);
  ChooseCard := R;
End;

{ ==================================================================== }
{ Encheres et pointage                                                  }
{ ==================================================================== }

{ annonce B (-1 : passe) du joueur P ; resultat : 0 les encheres
  continuent, 1 contrat conclu, 2 tout le monde a passe }
Function DoBid(P, B : LongInt) : LongInt;
Var K, N, R : LongInt;
Begin
  BidOf[P] := B;
  If (B >= 0) And (B > CurBid) Then
  Begin
    CurBid := B; BidBy := P;
  End
  Else Passed[P] := 1;
  N := 0;
  For K := 0 To 3 Do
    If Passed[K] = 0 Then Inc(N);
  R := 0;
  If N = 0 Then R := 2
  Else If (N = 1) And (CurBid >= 0) And (Passed[BidBy] = 0) Then R := 1
  Else
  Begin
    K := (P + 1) Mod 4;
    While Passed[K] <> 0 Do K := (K + 1) Mod 4;
    CurP := K;
  End;
  DoBid := R;
End;

Procedure StartPlay;
Var P : LongInt;
Begin
  Declarer := BidBy; CLevel := 5 + CurBid Div 5; Trump := CurBid Mod 5;
  For P := 0 To 3 Do SortHand(P);
  Leader := (Dealer + 1) Mod 4; CurP := Leader; NTrick := 0; TrickNo := 0;
  For P := 0 To 3 Do TrickC[P] := -1;
  Phase := PH_PLAY; Wait := 0;
End;

{ fin de la levee : resultat le gagnant }
Function CollectTrick : LongInt;
Var W, P : LongInt;
Begin
  W := TrickWinner;
  Inc(Tricks[W]);
  For P := 0 To 3 Do
  Begin
    LastC[P] := TrickC[P]; TrickC[P] := -1;
  End;
  LastWin := W;
  NTrick := 0; Inc(TrickNo);
  Leader := W; CurP := W;
  CollectTrick := W;
End;

{ pointage de la donne (somme nulle) : valeur 10 + 5 par levee au-dela
  de 5 (5 de plus sans atout) ; reussi : chaque adversaire paie la valeur
  + 2 par surlevee ; chute : le demandeur paie a chacun la valeur + 5 par
  levee manquante }
Function ScoreDeal : LongInt;
Var V, T, Pay, P, R : LongInt;
Begin
  T := Tricks[Declarer];
  V := 10 + 5 * (CLevel - 5);
  If Trump = 4 Then V := V + 5;
  If T >= CLevel Then
  Begin
    Pay := V + 2 * (T - CLevel); R := 1;
  End
  Else
  Begin
    Pay := -(V + 5 * (CLevel - T)); R := 0;
  End;
  For P := 0 To 3 Do
  Begin
    If P = Declarer Then DealPts[P] := 3 * Pay Else DealPts[P] := -Pay;
    Total[P] := Total[P] + DealPts[P];
  End;
  ScoreDeal := R;
End;

{ ==================================================================== }
{ Scene                                                                 }
{ ==================================================================== }

{ tapis (degrade), cadre de bois, marque doree au centre }
Procedure RenderBack;
Var X, Y, D, S, N, K, E : LongInt; Dx, Dy : Real;
Begin
  N := 7;
  For Y := 0 To BH - 1 Do
    For X := 0 To BW - 1 Do
    Begin
      Dx := (X - BW Div 2) / (BW * 0.66); Dy := (Y - 190) / (BH * 0.74);
      D := Round(Sqrt(Dx * Dx + Dy * Dy) * 16);
      N := (N * 1103515245 + 12345) And $7FFFFFFF;
      S := 14 - D + ((N Shr 16) And 1);
      Fb[(BH - 1 - Y) * BW + X] := C_FELT + Clamp(S, 0, 15);
    End;
  { anneau dore autour de la levee }
  For Y := 80 To 300 Do
    For X := 70 To 362 Do
    Begin
      E := (X - 216) * (X - 216) * 1000 Div (138 * 138) + (Y - 190) * (Y - 190) * 1000 Div (104 * 104);
      If (E >= 975) And (E <= 1025) Then Pix(X, Y, C_GOLD2);
    End;
  { cadre de bois }
  For K := 0 To 7 Do
  Begin
    Rect(K, K, BW - 1 - K, K, C_WOOD + MinI(7, 7 - K Div 2));
    Rect(K, BH - 1 - K, BW - 1 - K, BH - 1 - K, C_WOOD + MaxI(0, 2 - K Div 4));
    Rect(K, K, K, BH - 1 - K, C_WOOD + MinI(7, 6 - K Div 2));
    Rect(BW - 1 - K, K, BW - 1 - K, BH - 1 - K, C_WOOD + MaxI(0, 3 - K Div 3));
  End;
  Move(Fb, Back, SizeOf(Fb));
  BackOk := 1;
End;

{ case de la boite d'encheres (Etat : 0 grisee, 1 normale, 2 choisie) }
Procedure Cell(X1, Y1, X2, Y2 : LongInt; S : String; Fg, Etat : LongInt);
Var Lt, Dk, F : LongInt;
Begin
  If Etat = 2 Then Begin Lt := C_BTND; Dk := C_BTNL; F := C_BTNS; End
  Else Begin Lt := C_BTNL; Dk := C_BTND; F := C_BTN; End;
  Rect(X1, Y1, X2, Y2, F);
  Rect(X1, Y1, X2, Y1, Lt); Rect(X1, Y1, X1, Y2, Lt);
  Rect(X1, Y2, X2, Y2, Dk); Rect(X2, Y1, X2, Y2, Dk);
  Rect(X1 - 1, Y1 - 1, X2 + 1, Y1 - 1, C_BLACK); Rect(X1 - 1, Y2 + 1, X2 + 1, Y2 + 1, C_BLACK);
  Rect(X1 - 1, Y1 - 1, X1 - 1, Y2 + 1, C_BLACK); Rect(X2 + 1, Y1 - 1, X2 + 1, Y2 + 1, C_BLACK);
  If Etat = 0 Then Fg := C_GRAYT;
  If Etat = 2 Then Fg := C_WHITE;
  FbText((X1 + X2 + 1) Div 2 - Length(S) * 4, (Y1 + Y2 + 1) Div 2 - 8, S, Fg, 1);
End;

Function LvlX(K : LongInt) : LongInt;
Begin
  LvlX := BX1 + 13 + K * 31;
End;

Function SuitX(K : LongInt) : LongInt;
Begin
  SuitX := BX1 + 13 + K * 56;
End;

Function LvlOk(L : LongInt) : Boolean;
Begin
  LvlOk := BidVal(L, 4) > CurBid;
End;

{ meilleure estimation de votre main (conseil de la boite) }
Function BestEst(Var S : LongInt) : LongInt;
Var T, E, B : LongInt;
Begin
  B := -1; S := 0;
  For T := 0 To 4 Do
  Begin
    E := Estimate(0, T);
    If E > B Then Begin B := E; S := T; End;
  End;
  BestEst := B;
End;

Procedure DrawBidBox;
Var K, E, Fg, S0 : LongInt; S : String;
Begin
  Rect(BX1 + 5, BY1 + 5, BX2 + 5, BY2 + 5, C_SHADOW);
  Rect(BX1, BY1, BX2, BY2, C_BTN);
  Rect(BX1, BY1, BX2, BY1, C_BTNL); Rect(BX1, BY1, BX1, BY2, C_BTNL);
  Rect(BX1, BY2, BX2, BY2, C_BLACK); Rect(BX2, BY1, BX2, BY2, C_BLACK);
  Rect(BX1 + 1, BY2 - 1, BX2 - 1, BY2 - 1, C_BTND); Rect(BX2 - 1, BY1 + 1, BX2 - 1, BY2 - 1, C_BTND);
  Rect(BX1 + 3, BY1 + 3, BX2 - 3, BY1 + 21, C_TITLE);
  S := 'Votre ench' + Chr(138) + 're';
  FbText((BX1 + BX2) Div 2 - Length(S) * 4, BY1 + 4, S, C_WHITE, 1);
  If CurBid < 0 Then S := 'Aucune ench' + Chr(138) + 're pour l''instant'
  Else S := 'A battre : ' + BidText(CurBid) + ' (' + PName(BidBy) + ')';
  FbText(BX1 + 12, BY1 + 28, S, C_BLACK, 1);
  { nombre de levees }
  For K := 0 To 8 Do
  Begin
    If Not LvlOk(K + 5) Then E := 0 Else If BLvl = K + 5 Then E := 2 Else E := 1;
    Cell(LvlX(K), BY1 + 52, LvlX(K) + 27, BY1 + 75, IStr(K + 5), C_BLACK, E);
  End;
  { couleur de l'atout }
  For K := 0 To 4 Do
  Begin
    If BidVal(BLvl, K) <= CurBid Then E := 0 Else If BSuit = K Then E := 2 Else E := 1;
    If (K = 1) Or (K = 2) Then Fg := C_RED Else Fg := C_BLACK;
    Cell(SuitX(K), BY1 + 84, SuitX(K) + 51, BY1 + 108, SuitCh(K), Fg, E);
  End;
  If BidVal(BLvl, BSuit) > CurBid Then E := 1 Else E := 0;
  Cell(BX1 + 36, BY1 + 122, BX1 + 136, BY1 + 147, 'Annoncer', C_BLACK, E);
  Cell(BX1 + 164, BY1 + 122, BX1 + 264, BY1 + 147, 'Passer', C_BLACK, 1);
  E := BestEst(S0);
  S := 'Conseil : environ ' + IStr(E Div 10) + ' lev' + Chr(130) + 'es ' + Chr(133) + ' ' + SuitName(S0);
  FbText((BX1 + BX2) Div 2 - Length(S) * 4, BY1 + 154, S, C_BTNS, 1);
End;

Procedure DrawBanner;
Var W, X1, Y1, X2, Y2 : LongInt;
Begin
  If Banner = '' Then Exit;
  W := MaxI(MaxI(Length(Banner) * 16, Length(Banner2) * 8), Length(Banner3) * 8) + 36;
  W := MaxI(W, 280);
  X1 := (BW - W) Div 2; X2 := X1 + W - 1; Y1 := 120; Y2 := 226;
  RRect(X1 + 4, Y1 + 4, X2 + 4, Y2 + 4, 10, C_SHADOW);
  RRect(X1, Y1, X2, Y2, 10, C_BANNERE);
  RRect(X1 + 3, Y1 + 3, X2 - 3, Y2 - 3, 8, C_BANNER);
  FbCenter(BW Div 2, Y1 + 12, Banner, BannerC, 2);
  FbCenter(BW Div 2, Y1 + 52, Banner2, C_WHITE, 1);
  FbCenter(BW Div 2, Y1 + 74, Banner3, C_GREENT, 1);
End;

Procedure Label0(X, Y, P : LongInt; RightAl : Boolean);
Var S : String; C, W : LongInt;
Begin
  S := PName(P);
  If (Declarer >= 0) And (Phase <> PH_BID) Then S := S + ' : ' + IStr(Tricks[P]);
  If P = Declarer Then C := C_GOLD Else C := C_TEXT;
  W := Length(S) * 8;
  If RightAl Then X := X - W;
  FbTextSh(X, Y, S, C, 1);
  { jeton du donneur }
  If P = Dealer Then
  Begin
    If RightAl Then X := X - 14 Else X := X + W + 12;
    Disc(X, Y + 8, 7, C_GOLD2);
    Disc(X, Y + 8, 6, C_CREAM);
    FbText(X - 3, Y + 1, 'D', C_BLACK, 1);
  End;
End;

Procedure BubbleAt(P : LongInt; B : LongInt);
Var S : String;
Begin
  S := BidText(B);
  Case P Of
    0 : Bubble(96, 290, S, BidColor(B));
    1 : Bubble(12, 54, S, BidColor(B));
    2 : Bubble(BW Div 2 + 46, 58, S, BidColor(B));
  Else
    Bubble(BW - 24 - Length(S) * 8, 54, S, BidColor(B));
  End;
End;

Procedure RenderScene;
Var P, I, N, X, Y, X0, W, C : LongInt; Hum, Dm : Boolean;
Begin
  If BackOk = 0 Then RenderBack;
  Move(Back, Fb, SizeOf(Fb));
  { mains des adversaires (dos) }
  N := NHand[2];
  If N > 0 Then
  Begin
    X0 := (BW - ((N - 1) * SOv + SBw)) Div 2;
    For I := 0 To N - 1 Do DrawBack(X0 + I * SOv, 12, SBw, SBh);
  End;
  N := NHand[1];
  For I := 0 To N - 1 Do DrawBack(14, 104 + (12 - N) * SOv Div 2 + I * SOv, SBh, SBw);
  N := NHand[3];
  For I := 0 To N - 1 Do DrawBack(BW - 14 - SBh, 104 + (12 - N) * SOv Div 2 + I * SOv, SBh, SBw);
  { noms, levees, donneur }
  Label0(BW Div 2 - 24, 62, 2, False);
  Label0(14, 80, 1, False);
  Label0(BW - 14, 80, 3, True);
  Label0(14, 292, 0, False);
  { annonces }
  If (Phase = PH_BID) Or (Phase = PH_REDEAL) Then
  Begin
    For P := 0 To 3 Do
      If BidOf[P] >= -1 Then BubbleAt(P, BidOf[P]);
  End
  Else If Declarer >= 0 Then BubbleAt(Declarer, CurBid);
  { levee en cours (ou la derniere) }
  For P := 0 To 3 Do
  Begin
    If LastShow > 0 Then C := LastC[P] Else C := TrickC[P];
    If (C >= 0) And Not ((AnOn <> 0) And (C = AnC)) Then
    Begin
      SlotXY(P, X, Y);
      DrawCard(X, Y, C, False, ((Phase = PH_TRICK) And (P = TrickWinner) And (LastShow = 0)) Or
                               ((LastShow > 0) And (P = LastWin)));
    End;
  End;
  If LastShow > 0 Then FbCenter(BW Div 2, 88, 'Derni' + Chr(138) + 're lev' + Chr(130) + 'e', C_YELLOW, 1);
  { votre main }
  Hum := (Phase = PH_PLAY) And (CurP = 0) And (AutoAll = 0) And (AnOn = 0) And (LastShow = 0);
  X0 := HandX0;
  For I := 0 To NHand[0] - 1 Do
  Begin
    Y := HandY;
    Dm := Hum And Not Legal(0, I);
    If Hum And (I = Sel) Then Y := Y - 12;
    DrawCard(X0 + I * Spread, Y, HCard(0, I), Dm, Hum And (I = Sel));
  End;
  { carte qui glisse }
  If AnOn <> 0 Then
  Begin
    X := AnX0 + (AnX1 - AnX0) * AnK Div 6; Y := AnY0 + (AnY1 - AnY0) * AnK Div 6;
    DrawCard(X, Y, AnC, False, False);
  End;
  If (Phase = PH_BID) And (CurP = 0) And (AutoAll = 0) Then DrawBidBox;
  DrawBanner;
  W := 0;
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

Procedure PanLine(I, Y : LongInt; L, V : String; C, Bg : LongInt);
Var S : String;
Begin
  S := L + PadL(V, 20 - Length(L));
  If S = PanS[I] Then Exit;
  PanS[I] := S;
  OutTxt(PnX + 1, Y, S, C, Bg);
End;

Function SignStr(V : LongInt) : String;
Begin
  If V > 0 Then SignStr := '+' + IStr(V) Else SignStr := IStr(V);
End;

Procedure DrawInfo(Force : Boolean);
Var K, C : LongInt; S : String;
Begin
  If Force Then
    For K := 0 To 15 Do PanS[K] := '';
  PanLine(0, 44, 'Donne', IStr(MinI(DealNo, NDeals)) + ' / ' + IStr(NDeals), CLR_DARKBLUE, CLR_PALEGRAY);
  PanLine(1, 62, 'Donneur', PName(Dealer), CLR_BLACK, CLR_PALEGRAY);
  If Declarer >= 0 Then
  Begin
    PanLine(2, 84, 'Contrat', BidLong(CurBid), CLR_DARKRED, CLR_PALEGRAY);
    PanLine(3, 102, 'Demandeur', PName(Declarer), CLR_BLACK, CLR_PALEGRAY);
    PanLine(4, 120, 'Lev' + Chr(130) + 'es', IStr(Tricks[Declarer]) + ' / ' + IStr(CLevel), CLR_BLACK, CLR_PALEGRAY);
    PanLine(5, 138, 'D' + Chr(130) + 'fense', IStr(TrickNo - Tricks[Declarer]) + ' / ' + IStr(14 - CLevel), CLR_BLACK,
            CLR_PALEGRAY);
  End
  Else
  Begin
    If CurBid >= 0 Then S := BidLong(CurBid) Else S := '-';
    PanLine(2, 84, 'Ench' + Chr(138) + 're', S, CLR_DARKRED, CLR_PALEGRAY);
    If BidBy >= 0 Then S := PName(BidBy) Else S := '';
    PanLine(3, 102, 'Par', S, CLR_BLACK, CLR_PALEGRAY);
    PanLine(4, 120, '', '', CLR_BLACK, CLR_PALEGRAY);
    PanLine(5, 138, '', '', CLR_BLACK, CLR_PALEGRAY);
  End;
  For K := 0 To 3 Do
  Begin
    If Total[K] < 0 Then C := CLR_DARKRED Else C := CLR_BLACK;
    S := PName(K);
    PanLine(6 + K, 185 + K * 18, ' ' + S, SignStr(Total[K]) + ' ', C, CLR_WHITE);
  End;
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 6 * 16) Div 2, 6, 'Boston', CLR_DARKGREEN, CLR_PALEGRAY);
  OutTxt(PnX, 162, 'Pointage', CLR_BLACK, CLR_PALEGRAY);
  Edge(PnX, 180, PnX + PW - 1, 262, CLR_DARKGRAY, CLR_WHITE);
  Edge(PnX + 1, 181, PnX + PW - 2, 261, CLR_BLACK, CLR_PALEGRAY);
  FBar(PnX + 2, 182, PnX + PW - 3, 260, CLR_WHITE);
  DrawInfo(True);
  Button(PnX, 272, PW, 26, 'Nouvelle partie');
  Button(PnX, 304, PW, 26, 'Derni' + Chr(138) + 're lev' + Chr(130) + 'e');
  OutTxt(PnX, 340, 'Clic : jouer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 356, 'Fl' + Chr(138) + 'ches et Entr' + Chr(130) + 'e', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 372, 'P : passer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 388, 'F1 : r' + Chr(138) + 'gles du jeu', CLR_DARKGRAY, CLR_PALEGRAY);
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
  RenderScene;
  BlitRect(Hps, 0, 0, BW - 1, BH - 1);
  Dirty := 0;
  DrawPanel;
  DrawStatus;
  LastMsg := Msg;
  Dummy := WinEndPaint(Hps);
End;

{ image (si elle a change), panneau et barre d'etat a jour }
Procedure Frame1;
Begin
  If (Client = 0) Or (TestMode <> 0) Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  If Dirty <> 0 Then
  Begin
    RenderScene;
    BlitRect(Hps, 0, 0, BW - 1, BH - 1);
    Dirty := 0;
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

Procedure MakeSounds;
Begin
  NSndBuf := 0;
  SndPrio := 0; MakeNoise(0, 50, 55, 2);                 { carte posee }
  SndPrio := 1; MakeNoise(1, 520, 50, 1);                { melange }
  SndPrio := 0; MakeTone(2, 1200, 1200, 25, 18);         { annonce }
  SndPrio := 1; MakeTone(3, 700, 940, 140, 28);          { levee pour vous }
  SndPrio := 2; MakeTone(4, 523, 1568, 650, 40);         { contrat reussi }
  SndPrio := 2; MakeTone(5, 520, 210, 520, 36);          { contrat chute }
  SndPrio := 0; MakeTone(6, 380, 380, 60, 22);           { refus }
  SndPrio := 0;
End;

{ ==================================================================== }
{ Deroulement                                                           }
{ ==================================================================== }

Procedure Show(B1, B2, B3 : String; C : LongInt);
Begin
  Banner := B1; Banner2 := B2; Banner3 := B3; BannerC := C;
  Dirty := 1;
End;

Function Delay0 : LongInt;
Begin
  If Fast <> 0 Then Delay0 := 6 Else Delay0 := 18;
End;

{ choix par defaut de la boite : la plus petite enchere possible }
Procedure BoxDefault;
Var B : LongInt;
Begin
  B := MinI(44, CurBid + 1);
  BLvl := 5 + B Div 5; BSuit := B Mod 5;
End;

Procedure BidMsg;
Begin
  If (CurP = 0) And (AutoAll = 0) Then
    Msg := 'A vous d''annoncer : nombre de lev' + Chr(130) + 'es et atout, puis Annoncer (ou Passer).'
  Else Msg := PName(CurP) + ' r' + Chr(130) + 'fl' + Chr(130) + 'chit ' + Chr(133) + ' son ench' + Chr(138) + 're...';
End;

Procedure FirstLegal;
Var I : LongInt;
Begin
  Sel := 0;
  For I := NHand[0] - 1 DownTo 0 Do
    If Legal(0, I) Then Sel := I;
End;

Procedure PlayMsg;
Begin
  If (CurP = 0) And (AutoAll = 0) Then
  Begin
    FirstLegal;
    If NTrick = 0 Then Msg := 'A vous d''entamer : cliquez une carte (ou fl' + Chr(138) + 'ches et Entr' + Chr(130) + 'e).'
    Else Msg := 'A vous : fournissez ' + Chr(133) + ' ' + SuitName(LeadSuit) + ' si vous pouvez.';
  End;
End;

Procedure StartDeal;
Begin
  DealCards;
  Phase := PH_BID; CurP := (Dealer + 1) Mod 4; Wait := 0;
  Banner := ''; AnOn := 0;
  BoxDefault;
  BidMsg;
  Dirty := 1; FullBlit := 1;
  PlaySnd(1);
End;

Procedure NewGame;
Var P : LongInt;
Begin
  For P := 0 To 3 Do Total[P] := 0;
  DealNo := 1; Made := 0; Failed := 0; Redeals := 0; HumanMade := 0; SumLvl := 0;
  Dealer := Rnd(4);
  StartDeal;
End;

Procedure GameOver;
Var P, W : LongInt;
Begin
  Phase := PH_OVER; Wait := 0;
  W := 0;
  For P := 1 To 3 Do
    If Total[P] > Total[W] Then W := P;
  If W = 0 Then Show('Vous gagnez !', 'Partie termin' + Chr(130) + 'e : ' + SignStr(Total[0]) + ' points',
                     'Entr' + Chr(130) + 'e ou F2 : nouvelle partie', C_YELLOW)
  Else Show(PName(W) + ' gagne', 'Partie termin' + Chr(130) + 'e. Vous : ' + SignStr(Total[0]) + ' points',
            'Entr' + Chr(130) + 'e ou F2 : nouvelle partie', C_REDT);
  Msg := 'Fin de la partie apr' + Chr(138) + 's ' + IStr(NDeals) + ' donnes.';
  If W = 0 Then PlaySnd(4) Else PlaySnd(5);
End;

Procedure NextDeal;
Begin
  If DealNo >= NDeals Then
  Begin
    GameOver;
    Exit;
  End;
  Inc(DealNo);
  Dealer := (Dealer + 1) Mod 4;
  StartDeal;
End;

{ fin de la donne }
Procedure EndDeal;
Var R : LongInt; S : String;
Begin
  R := ScoreDeal;
  SumLvl := SumLvl + CLevel;
  If R <> 0 Then Inc(Made) Else Inc(Failed);
  If (R <> 0) And (Declarer = 0) Then Inc(HumanMade);
  Phase := PH_END; Wait := 0;
  S := PName(Declarer) + ' : ' + IStr(Tricks[Declarer]) + ' lev' + Chr(130) + 'es pour ' + IStr(CLevel) +
       ' demand' + Chr(130) + 'es';
  If Declarer = 0 Then S := 'Vous : ' + IStr(Tricks[0]) + ' lev' + Chr(130) + 'es pour ' + IStr(CLevel) +
                            ' demand' + Chr(130) + 'es';
  If R <> 0 Then Show('Contrat r' + Chr(130) + 'ussi', S, 'Vous : ' + SignStr(DealPts[0]) + ' points.  Entr' + Chr(130) +
                      'e : suite', C_YELLOW)
  Else Show('Contrat chut' + Chr(130), S, 'Vous : ' + SignStr(DealPts[0]) + ' points.  Entr' + Chr(130) + 'e : suite',
            C_REDT);
  Msg := 'Donne ' + IStr(DealNo) + ' : ' + BidLong(CurBid) + ' par ' + PName(Declarer) + ', ' + IStr(Tricks[Declarer]) +
         ' lev' + Chr(130) + 'es.';
  If ((R <> 0) And (Declarer = 0)) Or ((R = 0) And (Declarer <> 0)) Then PlaySnd(4) Else PlaySnd(5);
End;

{ une annonce (B : -1 passe) }
Procedure Bid(P, B : LongInt);
Var R : LongInt;
Begin
  R := DoBid(P, B);
  PlaySnd(2);
  Wait := 0; Dirty := 1;
  If R = 1 Then
  Begin
    StartPlay;
    Msg := PName(Declarer) + ' joue ' + BidLong(CurBid) + ' seul contre les trois autres.';
    If Declarer = 0 Then Msg := 'Vous jouez ' + BidLong(CurBid) + ' seul contre les trois autres.';
    PlayMsg;
  End
  Else If R = 2 Then
  Begin
    Phase := PH_REDEAL; Inc(Redeals);
    Show('Tout le monde passe', 'Les cartes sont redistribu' + Chr(130) + 'es', '', C_YELLOW);
    Msg := 'Personne n''a annonc' + Chr(130) + ' : nouvelle distribution.';
  End
  Else
  Begin
    BoxDefault;
    BidMsg;
  End;
End;

{ jouer la carte I du joueur P (avec la carte qui glisse) }
Procedure PlayIdx(P, I : LongInt);
Var C, X, Y : LongInt;
Begin
  C := HCard(P, I);
  If (TestMode = 0) And (Client <> 0) Then
  Begin
    If P = 0 Then
    Begin
      AnX0 := HandX0 + I * Spread; AnY0 := HandY - 12;
    End
    Else FromXY(P, AnX0, AnY0);
    SlotXY(P, X, Y);
    AnX1 := X; AnY1 := Y; AnC := C; AnK := 0; AnOn := 1;
  End;
  PlayCardIdx(P, I);
  If P <> 0 Then Msg := PName(P) + ' joue ' + CardName(C) + '.';
  PlaySnd(0);
  Wait := 0; Dirty := 1;
  If NTrick = 4 Then Phase := PH_TRICK
  Else PlayMsg;
End;

Procedure EndTrick;
Var W : LongInt;
Begin
  W := CollectTrick;
  If W = 0 Then Msg := 'Vous remportez la lev' + Chr(130) + 'e.'
  Else Msg := PName(W) + ' remporte la lev' + Chr(130) + 'e.';
  If (W = Declarer) = (Declarer = 0) Then PlaySnd(3);
  Wait := 0; Dirty := 1;
  If TrickNo >= 13 Then EndDeal
  Else
  Begin
    Phase := PH_PLAY;
    PlayMsg;
  End;
End;

{ une action de l'ordinateur ou de la partie (sans attendre) }
Procedure AutoAct;
Begin
  Case Phase Of
    PH_BID : Bid(CurP, AIBid(CurP));
    PH_PLAY : PlayIdx(CurP, ChooseCard(CurP));
    PH_TRICK : EndTrick;
    PH_REDEAL :
      Begin
        Dealer := (Dealer + 1) Mod 4;
        StartDeal;
      End;
    PH_END : NextDeal;
    PH_OVER : NewGame;
  End;
End;

{ actions du joueur }
Procedure HumanPlay(I : LongInt);
Begin
  If (Phase <> PH_PLAY) Or (CurP <> 0) Or (AutoAll <> 0) Or (AnOn <> 0) Then Exit;
  If (I < 0) Or (I >= NHand[0]) Then Exit;
  LastShow := 0;
  If Not Legal(0, I) Then
  Begin
    Msg := 'Cette carte ne se joue pas : il faut fournir ' + Chr(133) + ' ' + SuitName(LeadSuit) + '.';
    PlaySnd(6);
    Sel := I; Dirty := 1;
    Exit;
  End;
  PlayIdx(0, I);
End;

Procedure HumanBid(Pass : Boolean);
Begin
  If (Phase <> PH_BID) Or (CurP <> 0) Or (AutoAll <> 0) Then Exit;
  If Pass Then Bid(0, -1)
  Else If BidVal(BLvl, BSuit) > CurBid Then Bid(0, BidVal(BLvl, BSuit))
  Else PlaySnd(6);
End;

Procedure Continue0;
Begin
  Case Phase Of
    PH_TRICK : EndTrick;
    PH_END : NextDeal;
    PH_OVER : NewGame;
    PH_REDEAL : AutoAct;
  End;
End;

Procedure TimerTick;
Begin
  If InDlg > 0 Then Exit;
  Inc(Tick);
  If AnOn <> 0 Then
  Begin
    Inc(AnK);
    If AnK >= 6 Then AnOn := 0;
    Dirty := 1;
  End;
  If LastShow > 0 Then
  Begin
    Dec(LastShow);
    If LastShow = 0 Then Dirty := 1;
  End;
  If (AnOn = 0) And (LastShow = 0) Then
  Begin
    Inc(Wait);
    Case Phase Of
      PH_BID, PH_PLAY : If ((CurP <> 0) Or (AutoAll <> 0)) And (Wait > Delay0) Then AutoAct;
      PH_TRICK : If Wait > 2 * Delay0 + 4 Then AutoAct;
      PH_REDEAL : If Wait > 50 Then AutoAct;
      PH_END : If (AutoAll <> 0) And (Wait > 90) Then AutoAct;
      PH_OVER : If (AutoAll <> 0) And (Wait > 160) Then AutoAct;
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
  SetMark(CM_AUTO, AutoAll <> 0); SetMark(CM_SOUND, SoundOn <> 0); SetMark(CM_FAST, Fast <> 0);
  SetMark(CM_SHORT, NDeals = 4); SetMark(CM_LONG, NDeals = 8);
End;

Procedure ShowLast;
Begin
  If (LastWin >= 0) And ((Phase = PH_PLAY) Or (Phase = PH_TRICK)) And (AnOn = 0) Then
  Begin
    LastShow := 60; Dirty := 1;
    Msg := 'Derni' + Chr(138) + 're lev' + Chr(130) + 'e : remport' + Chr(130) + 'e par ' + PName(LastWin) + '.';
  End;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_NEXT : Continue0;
    CM_LAST : ShowLast;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_AUTO :
      Begin
        AutoAll := 1 - AutoAll; SetMarks; Wait := 0; Dirty := 1;
        If AutoAll <> 0 Then Msg := 'D' + Chr(130) + 'monstration : l''ordinateur joue aussi pour vous.'
        Else If Phase = PH_PLAY Then PlayMsg Else If Phase = PH_BID Then BidMsg;
      End;
    CM_SOUND : Begin SoundOn := 1 - SoundOn; SetMarks; End;
    CM_FAST : Begin Fast := 1 - Fast; SetMarks; End;
    CM_SHORT : Begin NDeals := 4; SetMarks; NewGame; End;
    CM_LONG : Begin NDeals := 8; SetMarks; NewGame; End;
    CM_RULES :
      Begin
        LClr;
        LAdd('Quatre joueurs, 13 cartes chacun : vous (Sud), Ouest, Nord et Est. Ench' + Chr(138) + 'res : ' +
             'chacun ' + Chr(133) + ' son tour annonce un nombre de lev' + Chr(130) + 'es (5 ' + Chr(133) + ' 13) ' +
             'et un atout (tr' + Chr(138) + 'fle, carreau, coeur, pique, puis sans atout, du plus faible au plus ' +
             'fort), plus haut que l''ench' + Chr(138) + 're en cours, ou passe (et ne revient plus). Le dernier ' +
             'qui a annonc' + Chr(130) + ' devient le demandeur et joue seul contre les trois autres. Si tout le ' +
             'monde passe, on redistribue.' + Chr(10) + Chr(10));
        LAdd('Jeu : le joueur ' + Chr(133) + ' gauche du donneur entame ; il faut fournir ' + Chr(133) + ' la ' +
             'couleur demand' + Chr(130) + 'e si on peut ; sinon on peut couper (atout) ou se d' + Chr(130) +
             'fausser. La lev' + Chr(130) + 'e va ' + Chr(133) + ' l''atout le plus fort, sinon ' + Chr(133) +
             ' la plus haute carte de la couleur demand' + Chr(130) + 'e (l''as est la plus forte) ; son gagnant ' +
             'entame la suivante.' + Chr(10) + Chr(10));
        LAdd('Pointage : le contrat vaut 10 points, plus 5 par lev' + Chr(130) + 'e au-del' + Chr(133) + ' de 5 (et ' +
             '5 de plus sans atout). R' + Chr(130) + 'ussi : chaque adversaire paie au demandeur cette valeur, ' +
             'plus 2 par lev' + Chr(130) + 'e en trop. Chut' + Chr(130) + ' : le demandeur paie ' + Chr(133) +
             ' chacun la valeur plus 5 par lev' + Chr(130) + 'e manquante. Partie en 4 ou 8 donnes.' + Chr(10) +
             Chr(10));
        LAdd('Souris : clic sur une carte (les cartes grises ne peuvent pas ' + Chr(136) + 'tre jou' + Chr(130) +
             'es), clic dans la bo' + Chr(140) + 'te d''ench' + Chr(138) + 'res. Clavier : fl' + Chr(138) + 'ches et ' +
             'Entr' + Chr(130) + 'e, 1 ' + Chr(133) + ' 9 ; ench' + Chr(138) + 'res : haut et bas (lev' + Chr(130) +
             'es), gauche et droite (atout), Entr' + Chr(130) + 'e (annoncer), P (passer) ; L (derni' + Chr(138) +
             're lev' + Chr(130) + 'e), F2 (nouvelle partie).');
        Dummy := LMsgBox('Boston - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Boston pour OS/2-0 (Presentation Manager), port' + Chr(130) +
                            ' du prototype BOSTON.PAS de 7iles.' + Chr(10) + 'Programme ' + Chr(130) +
                            'crit en Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos', MB_OK Or
                            MB_INFORMATION);
  End;
  Dirty := 1;
  Frame1;
End;

{ boite d'encheres : changer le nombre de levees ou l'atout }
Procedure BoxLevel(D : LongInt);
Var L : LongInt;
Begin
  L := BLvl + D;
  While (L >= 5) And (L <= 13) And Not LvlOk(L) Do L := L + D;
  If (L < 5) Or (L > 13) Then Exit;
  BLvl := L;
  If BidVal(BLvl, BSuit) <= CurBid Then
  Begin
    BSuit := 0;
    While (BSuit < 4) And (BidVal(BLvl, BSuit) <= CurBid) Do Inc(BSuit);
  End;
  Dirty := 1;
End;

Procedure BoxSuit(D : LongInt);
Var S : LongInt;
Begin
  S := BSuit + D;
  If (S < 0) Or (S > 4) Then Exit;
  If BidVal(BLvl, S) <= CurBid Then Exit;
  BSuit := S;
  Dirty := 1;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt; Bx, Hp : Boolean;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And (KC_KEYUP Or KC_CTRL Or KC_ALT)) <> 0 Then
  Begin
    KeyChar := False;
    Exit;
  End;
  Bx := (Phase = PH_BID) And (CurP = 0) And (AutoAll = 0);
  Hp := (Phase = PH_PLAY) And (CurP = 0) And (AutoAll = 0) And (AnOn = 0);
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Bx Then
    Begin
      If Vk = VK_UP Then Begin BoxLevel(1); Frame1; Exit; End;
      If Vk = VK_DOWN Then Begin BoxLevel(-1); Frame1; Exit; End;
      If Vk = VK_LEFT Then Begin BoxSuit(-1); Frame1; Exit; End;
      If Vk = VK_RIGHT Then Begin BoxSuit(1); Frame1; Exit; End;
      If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin HumanBid(False); Frame1; Exit; End;
      If Vk = VK_BACKSPACE Then Begin HumanBid(True); Frame1; Exit; End;
    End;
    If Hp Then
    Begin
      If (Vk = VK_LEFT) And (Sel > 0) Then Begin Dec(Sel); LastShow := 0; Dirty := 1; Frame1; Exit; End;
      If (Vk = VK_RIGHT) And (Sel < NHand[0] - 1) Then Begin Inc(Sel); LastShow := 0; Dirty := 1; Frame1; Exit; End;
      If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then Begin HumanPlay(Sel); Frame1; Exit; End;
    End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then Begin Continue0; Frame1; Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'P' : If Bx Then Begin HumanBid(True); Frame1; End;
      'L' : Begin ShowLast; Frame1; End;
      'N' : Begin Continue0; Frame1; End;
      '1'..'9' : If Hp Then Begin HumanPlay(Ch - Ord('1')); Frame1; End;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, K, X0, Yc : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 272) And (Y < 298) Then Command(CM_NEW)
    Else If (Y >= 304) And (Y < 330) Then Command(CM_LAST);
    Exit;
  End;
  If (X < OX) Or (X >= OX + BW) Or (Y < OY) Or (Y >= OY + BH) Then Exit;
  X := X - OX; Y := Y - OY;
  If (Phase = PH_BID) And (CurP = 0) And (AutoAll = 0) Then
  Begin
    For K := 0 To 8 Do
      If (X >= LvlX(K)) And (X <= LvlX(K) + 27) And (Y >= BY1 + 52) And (Y <= BY1 + 75) And LvlOk(K + 5) Then
      Begin
        BLvl := K + 5; Dirty := 1;
        If BidVal(BLvl, BSuit) <= CurBid Then
        Begin
          BSuit := 0;
          While (BSuit < 4) And (BidVal(BLvl, BSuit) <= CurBid) Do Inc(BSuit);
        End;
      End;
    For K := 0 To 4 Do
      If (X >= SuitX(K)) And (X <= SuitX(K) + 51) And (Y >= BY1 + 84) And (Y <= BY1 + 108) And
         (BidVal(BLvl, K) > CurBid) Then
      Begin
        BSuit := K; Dirty := 1;
      End;
    If (Y >= BY1 + 122) And (Y <= BY1 + 147) Then
    Begin
      If (X >= BX1 + 36) And (X <= BX1 + 136) Then HumanBid(False);
      If (X >= BX1 + 164) And (X <= BX1 + 264) Then HumanBid(True);
    End;
    Frame1;
    Exit;
  End;
  If (Phase = PH_PLAY) And (CurP = 0) And (AutoAll = 0) Then
  Begin
    X0 := HandX0;
    For K := NHand[0] - 1 DownTo 0 Do
    Begin
      If K = Sel Then Yc := HandY - 12 Else Yc := HandY;
      If (X >= X0 + K * Spread) And (X < X0 + K * Spread + CardW) And (Y >= Yc) And (Y < Yc + CardH) Then
      Begin
        HumanPlay(K);
        Frame1;
        Exit;
      End;
    End;
    Exit;
  End;
  Continue0;
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

Procedure RunTests;
Var Ok, P, I, N, A, B, R, K : LongInt; Seen : Array[0..51] Of LongInt; S : String;
Begin
  Ok := 0;
  SoundOn := 0; AutoAll := 0; Seed := 5; Dealer := 3; NDeals := 8;
  For P := 0 To 3 Do Total[P] := 0;
  { 1 : distribution : 4 mains de 13, 52 cartes differentes, mains triees }
  DealCards;
  For I := 0 To 51 Do Seen[I] := 0;
  N := 0; A := 0;
  For P := 0 To 3 Do
  Begin
    N := N + NHand[P];
    For I := 0 To NHand[P] - 1 Do Inc(Seen[HCard(P, I)]);
    For I := 0 To NHand[P] - 2 Do
      If SortKey(HCard(P, I)) > SortKey(HCard(P, I + 1)) Then Inc(A);
  End;
  B := 0;
  For I := 0 To 51 Do
    If Seen[I] = 1 Then Inc(B);
  Log('BOSTON : TEST1 cartes ' + IStr(N) + ' differentes ' + IStr(B) + ' desordres ' + IStr(A));
  If (N = 52) And (B = 52) And (A = 0) Then Inc(Ok);
  { 2 : gagnant de la levee : sans atout, avec atout coupe, defausse }
  N := 0;
  Trump := 4; Leader := 0; NTrick := 4;
  TrickC[0] := 2 * 13 + 3; TrickC[1] := 2 * 13 + 11; TrickC[2] := 3 * 13 + 12; TrickC[3] := 2 * 13 + 0;
  If TrickWinner = 1 Then Inc(N);
  Trump := 3;
  If TrickWinner = 2 Then Inc(N);
  Trump := 3; Leader := 1;
  TrickC[1] := 3 * 13 + 0; TrickC[2] := 3 * 13 + 5; TrickC[3] := 0 * 13 + 12; TrickC[0] := 2 * 13 + 12;
  If TrickWinner = 2 Then Inc(N);
  Trump := 1; Leader := 3;
  TrickC[3] := 0 * 13 + 4; TrickC[0] := 2 * 13 + 12; TrickC[1] := 0 * 13 + 2; TrickC[2] := 1 * 13 + 0;
  If TrickWinner = 2 Then Inc(N);
  Log('BOSTON : TEST2 levees ' + IStr(N) + '/4 bien attribuees');
  If N = 4 Then Inc(Ok);
  { 3 : il faut fournir ; sinon tout se joue }
  NHand[0] := 3; Hand[0] := 2 * 13 + 3; Hand[1] := 3 * 13 + 12; Hand[2] := 0;
  NTrick := 1; LeadSuit := 2;
  LegalList(0); A := NL;
  LeadSuit := 1;
  LegalList(0); B := NL;
  NTrick := 0; LeadSuit := 2;
  LegalList(0); R := NL;
  Log('BOSTON : TEST3 jouables ' + IStr(A) + ' ' + IStr(B) + ' ' + IStr(R));
  If (A = 1) And (B = 3) And (R = 3) Then Inc(Ok);
  { 4 : encheres : ordre des annonces, joueur qui passe ecarte, contrat }
  DealCards;
  Dealer := 3; CurP := 0;
  N := 0;
  If (BidVal(7, 3) > BidVal(7, 2)) And (BidVal(8, 0) > BidVal(7, 4)) Then Inc(N);
  R := DoBid(0, BidVal(6, 2)); If (R = 0) And (CurP = 1) Then Inc(N);
  R := DoBid(1, -1); If (R = 0) And (CurP = 2) Then Inc(N);
  R := DoBid(2, BidVal(7, 0)); If (R = 0) And (CurP = 3) Then Inc(N);
  R := DoBid(3, -1); If (R = 0) And (CurP = 0) Then Inc(N);
  R := DoBid(0, -1); If (R = 1) And (BidBy = 2) And (CurBid = BidVal(7, 0)) Then Inc(N);
  StartPlay;
  If (Declarer = 2) And (CLevel = 7) And (Trump = 0) And (CurP = 0) Then Inc(N);
  Log('BOSTON : TEST4 encheres ' + IStr(N) + '/7 correctes');
  If N = 7 Then Inc(Ok);
  { 5 : pointage a somme nulle (7 a coeur : reussi avec 8, chute avec 5) }
  For P := 0 To 3 Do Begin Total[P] := 0; Tricks[P] := 0; End;
  Declarer := 2; CLevel := 7; Trump := 2; Tricks[2] := 8;
  A := ScoreDeal;
  Tricks[2] := 5;
  B := ScoreDeal;
  Log('BOSTON : TEST5 resultats ' + IStr(A) + ' ' + IStr(B) + ' pointages ' + IStr(Total[0]) + ' ' + IStr(Total[1]) + ' ' +
      IStr(Total[2]) + ' ' + IStr(Total[3]));
  If (A = 1) And (B = 0) And (Total[2] = 66 - 90) And (Total[0] = -22 + 30) And
     (Total[0] + Total[1] + Total[2] + Total[3] = 0) Then Inc(Ok);
  { partie : 8 donnes jouees par l'ordinateur (graine fixe) }
  Seed := 99; AutoAll := 1; NDeals := 8;
  NewGame;
  K := 0;
  While (Phase <> PH_OVER) And (K < 20000) Do
  Begin
    AutoAct;
    Inc(K);
  End;
  S := '';
  For P := 0 To 3 Do S := S + ' ' + IStr(Total[P]);
  Log('BOSTON : PARTIE donnes ' + IStr(Made + Failed) + ' reussies ' + IStr(Made) + ' chutees ' + IStr(Failed) +
      ' redistributions ' + IStr(Redeals) + ' levees demandees ' + IStr(SumLvl) + ' pointages' + S);
  If (Made + Failed = 8) And (Total[0] + Total[1] + Total[2] + Total[3] = 0) And (Phase = PH_OVER) Then Inc(Ok);
  Log('BOSTON : ' + IStr(Ok) + '/6 essais reussis');
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
  Msg := ''; LastMsg := ''; AutoAll := 0; Banner := ''; Banner2 := ''; Banner3 := ''; Tick := 0;
  Client := 0; Frame := 0; SoundOn := 1; SndCur := 0; SndEnd := 0; Fast := 0; NDeals := 8;
  TestMode := 0; CW := CWant; CH := CHWant; Dirty := 1; FullBlit := 1; BackOk := 0; AnOn := 0;
  Declarer := -1; CurBid := -1; BidBy := -1; Trump := 4; Phase := PH_BID; Dealer := 0; DealNo := 1;
  For K := 0 To 3 Do Begin Total[K] := 0; Tricks[K] := 0; TrickC[K] := -1; LastC[K] := -1; End;
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
  InitBmi;
  MakeSounds;
  Dummy := WinRegisterClass(Hab, Z('BOSTON'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('BOSTON'), Z2('Boston'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_NEXT, '~Donne suivante' + Chr(9) + 'N');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_LAST, 'Derni' + Chr(138) + 're ~lev' + Chr(130) + 'e' + Chr(9) + 'L');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_AUTO, '~D' + Chr(130) + 'monstration');
  MItem(MIS_TEXT, 0, CM_SOUND, '~Son');
  MItem(MIS_TEXT, 0, CM_FAST, '~Jeu rapide');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_SHORT, 'Partie ~courte (4 donnes)');
  MItem(MIS_TEXT, 0, CM_LONG, 'Partie ~longue (8 donnes)');
  MenuClose(H3, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Boston');
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
