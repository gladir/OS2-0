{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2025 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: 421 - jeu de des traditionnel francais pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program Game421;

{$R-,S-,I-}

{ Compilation : OS2PC 421.PAS   (produit 421.EXE)

  Portage vers OS/2-0 du prototype 421.PAS du depot 7iles (Turbo Pascal
  et BGI) : fenetre de Presentation Manager avec menus, piste de 421 en
  bois et feutre vert, des en relief qui roulent, jetons, panneau des
  joueurs, barre d'etat et apparence d'OS/2.

  Regles (comme le prototype) : chaque joueur a 21 jetons et trois des ;
  a chaque manche, il lance les trois des jusqu'a trois fois, en gardant
  ceux qu'il veut entre les lancers. Combinaisons : 421 (10 points, la
  meilleure), brelans 111 a 666 (8 points), suites 654, 543, 432, 321
  (6 points) ; sinon chaque as compte 1 point. La meilleure main gagne la
  manche : sur un 421, chaque autre joueur lui donne 2 jetons ; sur un
  brelan ou une suite, 1 jeton. Apres 11 manches (ou quand un joueur n'a
  plus de jetons), celui qui a le plus de jetons gagne la partie.

  Differences avec le prototype : le gagnant d'une manche recoit les
  jetons payes ; les suites font payer un jeton (comme l'annoncait le
  prototype) ; une egalite ne fait payer personne ; l'ordinateur s'arrete
  sur une combinaison ; une partie se joue contre 1, 2 ou 3 adversaires.

  Clavier : Espace (lancer les des non gardes), 1 2 3 (garder ou
  relancer un de), Entree (garder la main et passer), F2 ou N (nouvelle
  partie), F1 (regles). Souris : cliquer un de pour le garder, les
  boutons du panneau.
  Parametres : /SEED:n (parties reproductibles) ; /AUTO (l'ordinateur
  joue aussi votre main : demonstration) ; /OPP:n (1 a 3 adversaires). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10; VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKPINK = 11; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_ROLL = 102; CM_KEEP = 103; CM_QUIT = 104; CM_AUTO = 105;
  CM_OPP1 = 111;                    { CM_OPP1 .. CM_OPP1 + 2 : 1 a 3 adversaires }
  CM_RULES = 301; CM_ABOUT = 302;
  MaxPl = 4; MaxRounds = 11; StartTokens = 21;
  S421 = 10; SBrelan = 8; SSuite = 6;
  { disposition (zone client, Y vers le bas) }
  TX = 8; TY = 8; TW = 440; THt = 382;   { piste }
  Ds = 48; DGap = 8;                      { des }
  PnX = 460; PW = 140;
  CWant = 608; CHWant = 420;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  NPl, Cur, RoundNo, Phase, Winner, Seed, Anim, CpuWait, AutoMe, NOpp, Paid : LongInt;
  { Phase : 0 on joue, 1 fin de manche (resultat), 2 fin de partie }
  PName : Array[0..MaxPl - 1] Of String[16];
  Tokens, RollsLeft, PScore, Played : Array[0..MaxPl - 1] Of LongInt;
  Dice, Hold : Array[0..MaxPl - 1, 1..3] Of LongInt;
  Msg, ResMsg : String;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;


{ --- PMWIN.DLL, PMGPI.DLL, VIOCALLS.DLL, DOSCALLS.DLL --- }
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
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function VioGetFont(PInfo, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioGetFont';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';

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

Function Rnd(N : LongInt) : LongInt;
Begin
  Seed := (Seed * 1103515245 + 12345) And $7FFFFFFF;
  Rnd := (Seed Shr 8) Mod N;
End;

Function WinGetPS(H : LongInt) : LongInt; External 'PMWIN';
Function WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN';

Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

{ ==================================================================== }
{ Combinaisons (celles du prototype)                                    }
{ ==================================================================== }

Procedure Sort3(P : LongInt; Var D1, D2, D3 : LongInt);
Var T : LongInt;
Begin
  D1 := Dice[P, 1]; D2 := Dice[P, 2]; D3 := Dice[P, 3];
  If D1 > D2 Then Begin T := D1; D1 := D2; D2 := T; End;
  If D2 > D3 Then Begin T := D2; D2 := D3; D3 := T; End;
  If D1 > D2 Then Begin T := D1; D1 := D2; D2 := T; End;
End;

Function CalcScore(P : LongInt) : LongInt;
Var D1, D2, D3, S : LongInt;
Begin
  Sort3(P, D1, D2, D3);
  If (D1 = 1) And (D2 = 2) And (D3 = 4) Then S := S421
  Else If (D1 = D2) And (D2 = D3) Then S := SBrelan
  Else If (D2 = D1 + 1) And (D3 = D2 + 1) Then S := SSuite
  Else
  Begin
    S := 0;
    If D1 = 1 Then Inc(S);
    If D2 = 1 Then Inc(S);
    If D3 = 1 Then Inc(S);
  End;
  CalcScore := S;
End;

{ force pour departager : combinaison puis valeur (111 avant 666, etc.) }
Function Strength(P : LongInt) : LongInt;
Var D1, D2, D3, S : LongInt;
Begin
  Sort3(P, D1, D2, D3);
  S := CalcScore(P) * 1000;
  If (S Div 1000 = SBrelan) And (D1 = 1) Then S := S + 700
  Else If S Div 1000 = SBrelan Then S := S + D1 * 100
  Else If S Div 1000 = SSuite Then S := S + D3 * 100
  Else If S Div 1000 < SSuite Then S := S + D3 * 100 + D2 * 10 + D1;
  Strength := S;
End;

Function ScoreDesc(P : LongInt) : String;
Var D1, D2, D3, S : LongInt;
Begin
  Sort3(P, D1, D2, D3);
  S := CalcScore(P);
  If S = S421 Then ScoreDesc := '421 !'
  Else If S = SBrelan Then
  Begin
    If D1 = 1 Then ScoreDesc := 'Brelan d''as' Else ScoreDesc := 'Brelan de ' + IStr(D1);
  End
  Else If S = SSuite Then ScoreDesc := 'Suite ' + IStr(D3) + IStr(D2) + IStr(D1)
  Else If S = 1 Then ScoreDesc := 'Un as'
  Else If S = 2 Then ScoreDesc := 'Deux as'
  Else ScoreDesc := 'Rien';
End;


{ messages de plus de 255 caracteres (limite des chaines) : texte cumule
  dans LBuf par LAdd, puis affiche par LMsgBox }
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
  LMsgBox := WinMessageBox(HWND_DESKTOP, Frame, LongInt(@LBuf), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;
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

{ disque plein de rayon R centre en (X, Y) }
Procedure Disc(X, Y, R, C : LongInt);
Var Dy, W, Rr : LongInt;
Begin
  Rr := R * R + R;
  For Dy := -R To R Do
  Begin
    W := 0;
    While (W + 1) * (W + 1) + Dy * Dy <= Rr Do Inc(W);
    FBar(X - W, Y + Dy, X + W, Y + Dy, C);
  End;
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

{ police 8 x 16 du VGA (VIOCALLS) pour les textes agrandis }
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

{ ==================================================================== }
{ Dessin (Y vers le bas)                                                }
{ ==================================================================== }

{ position des des du joueur P : 0 en bas (vous), 1 en haut, 2 a droite, 3 a gauche }
Procedure Seat(P : LongInt; Var X, Y : LongInt);
Begin
  Case P Of
    0 : Begin X := TX + (TW - 3 * Ds - 2 * DGap) Div 2; Y := TY + 276; End;
    1 : Begin X := TX + (TW - 3 * Ds - 2 * DGap) Div 2; Y := TY + 46; End;
    2 : Begin X := TX + TW - 3 * Ds - 2 * DGap - 18; Y := TY + 162; End;
  Else
    Begin X := TX + 18; Y := TY + 162; End;
  End;
End;

Procedure Pip(X, Y : LongInt);
Begin
  Disc(X, Y, 5, CLR_BLACK);
  FBar(X - 2, Y - 3, X - 1, Y - 2, CLR_DARKGRAY);
End;

{ de en relief ; Kept : garde (fond jaune, cadre rouge) }
Procedure DrawDie(X, Y, V : LongInt; Kept : Boolean);
Var Bg, L, M, R, T, B : LongInt;
Begin
  If Kept Then Bg := CLR_YELLOW Else Bg := CLR_WHITE;
  FBar(X + 3, Y + 3, X + Ds + 2, Y + Ds + 2, CLR_BLACK);            { ombre }
  FBar(X + 2, Y, X + Ds - 3, Y + Ds - 1, Bg);
  FBar(X, Y + 2, X + Ds - 1, Y + Ds - 3, Bg);
  FBar(X + 1, Y + 1, X + Ds - 2, Y + Ds - 2, Bg);
  FBar(X + 2, Y + Ds - 2, X + Ds - 3, Y + Ds - 2, CLR_PALEGRAY);
  FBar(X + Ds - 2, Y + 2, X + Ds - 2, Y + Ds - 3, CLR_PALEGRAY);
  If Kept Then
  Begin
    Edge(X, Y, X + Ds - 1, Y + Ds - 1, CLR_RED, CLR_RED);
    Edge(X + 1, Y + 1, X + Ds - 2, Y + Ds - 2, CLR_RED, CLR_RED);
  End;
  L := X + 12; M := X + Ds Div 2; R := X + Ds - 13;
  T := Y + 12; B := Y + Ds - 13;
  If V In [1, 3, 5] Then
  Begin
    If V = 1 Then
    Begin
      Disc(M, Y + Ds Div 2, 7, CLR_RED);
      FBar(M - 3, Y + Ds Div 2 - 4, M - 2, Y + Ds Div 2 - 3, CLR_PINK);
    End
    Else Pip(M, Y + Ds Div 2);
  End;
  If V >= 2 Then
  Begin
    Pip(R, T); Pip(L, B);
  End;
  If V >= 4 Then
  Begin
    Pip(L, T); Pip(R, B);
  End;
  If V = 6 Then
  Begin
    Pip(L, Y + Ds Div 2); Pip(R, Y + Ds Div 2);
  End;
End;

Procedure Token(X, Y : LongInt);
Begin
  Disc(X, Y, 6, CLR_BLACK);
  Disc(X, Y, 5, CLR_RED);
  Disc(X, Y, 2, CLR_PINK);
End;

Procedure DrawPlayer(P : LongInt);
Var X, Y, K, Fg, Ty, Dy : LongInt; S : String;
Begin
  Seat(P, X, Y);
  If (Phase = 0) And (P = Cur) Then Fg := CLR_YELLOW Else Fg := CLR_WHITE;
  If (Phase >= 1) And (P = Winner) Then Fg := CLR_YELLOW;
  S := PName[P] + ' - ' + IStr(Tokens[P]) + ' jetons';
  Ty := Y - 22;
  If (Phase = 0) And (P = Cur) Then
  Begin
    FBar(X - 14, Ty + 4, X - 6, Ty + 11, CLR_YELLOW);
    FBar(X - 6, Ty + 2, X - 5, Ty + 13, CLR_YELLOW);
  End;
  OutTxt(X, Ty, S, Fg, CLR_DARKGREEN);
  For K := 1 To 3 Do DrawDie(X + (K - 1) * (Ds + DGap), Y, Dice[P, K], (Hold[P, K] <> 0) And (Phase = 0));
  Dy := Y + Ds + 6;
  If Played[P] <> 0 Then
  Begin
    S := ScoreDesc(P);
    If (Phase = 0) And (P = Cur) Then S := S + ' (' + IStr(RollsLeft[P]) + ' lancer(s))';
    OutTxt(X, Dy, S, CLR_PALEGRAY, CLR_DARKGREEN);
  End;
End;

Procedure DrawTable;
Var P, X, W : LongInt; S : String;
Begin
  { piste : rebord de bois et feutre vert }
  FBar(TX, TY, TX + TW - 1, TY + THt - 1, CLR_BROWN);
  Edge(TX, TY, TX + TW - 1, TY + THt - 1, CLR_YELLOW, CLR_DARKRED);
  Edge(TX + 1, TY + 1, TX + TW - 2, TY + THt - 2, CLR_YELLOW, CLR_DARKRED);
  FBar(TX + 10, TY + 10, TX + TW - 11, TY + THt - 11, CLR_DARKGREEN);
  Edge(TX + 9, TY + 9, TX + TW - 10, TY + THt - 10, CLR_DARKRED, CLR_YELLOW);
  For P := 0 To NPl - 1 Do DrawPlayer(P);
  If (NPl = 2) And (Phase = 0) Then
  Begin
    S := 'Manche ' + IStr(RoundNo) + ' / ' + IStr(MaxRounds);
    OutTxt(TX + (TW - Length(S) * 8) Div 2, TY + 154, S, CLR_PALEGRAY, CLR_DARKGREEN);
  End;
  If Phase >= 1 Then
  Begin
    { resultat de la manche : boite au milieu de la piste }
    W := 300; X := TX + (TW - W) Div 2;
    FBar(X, TY + 172, X + W - 1, TY + 244, CLR_PALEGRAY);
    Edge(X, TY + 172, X + W - 1, TY + 244, CLR_WHITE, CLR_BLACK);
    FBar(X + 2, TY + 174, X + W - 3, TY + 191, CLR_DARKBLUE);
    If Phase = 2 Then S := 'Fin de la partie' Else S := 'Fin de la manche ' + IStr(RoundNo);
    OutTxt(X + (W - Length(S) * 8) Div 2, TY + 175, S, CLR_WHITE, CLR_DARKBLUE);
    If Winner >= 0 Then S := PName[Winner] + ' gagne' Else S := Chr(144) + 'galit' + Chr(130);
    If Length(S) * 16 <= W - 8 Then BigText(X + (W - Length(S) * 16) Div 2, TY + 194, S, CLR_DARKRED, CLR_PALEGRAY)
    Else OutTxt(X + (W - Length(S) * 8) Div 2, TY + 202, S, CLR_DARKRED, CLR_PALEGRAY);
    OutTxt(X + (W - Length(ResMsg) * 8) Div 2, TY + 226, ResMsg, CLR_BLACK, CLR_PALEGRAY);
  End;
End;

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

Function HumanTurn : Boolean;
Begin
  HumanTurn := (Phase = 0) And (Cur = 0) And (AutoMe = 0) And (Anim = 0);
End;

Procedure DrawPanel;
Var P, Y : LongInt; S : String;
Begin
  BigText(PnX + (PW - 3 * 16) Div 2, TY + 2, '421', CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX, TY + 40, 'Manche ' + IStr(RoundNo) + ' / ' + IStr(MaxRounds), CLR_DARKBLUE, CLR_PALEGRAY);
  FBar(PnX, TY + 62, PnX + PW - 1, TY + 64 + NPl * 22, CLR_WHITE);
  Edge(PnX, TY + 62, PnX + PW - 1, TY + 64 + NPl * 22, CLR_DARKGRAY, CLR_WHITE);
  For P := 0 To NPl - 1 Do
  Begin
    Y := TY + 66 + P * 22;
    Token(PnX + 12, Y + 8);
    S := PName[P];
    If P = Cur Then OutTxt(PnX + 24, Y, S, CLR_DARKRED, CLR_WHITE) Else OutTxt(PnX + 24, Y, S, CLR_BLACK, CLR_WHITE);
    S := IStr(Tokens[P]);
    OutTxt(PnX + PW - 8 - Length(S) * 8, Y, S, CLR_BLACK, CLR_WHITE);
  End;
  Y := TY + 160;
  If RollsLeft[0] > 0 Then S := 'Lancer (' + IStr(RollsLeft[0]) + ')' Else S := 'Lancer';
  Button(PnX, Y, PW, 30, S, HumanTurn And (RollsLeft[0] > 0));
  Button(PnX, Y + 36, PW, 30, 'Garder la main', HumanTurn);
  If Phase = 0 Then Button(PnX, Y + 72, PW, 30, 'Manche suivante', False)
  Else If Phase = 1 Then Button(PnX, Y + 72, PW, 30, 'Manche suivante', True)
  Else Button(PnX, Y + 72, PW, 30, 'Nouvelle partie', True);
  OutTxt(PnX, Y + 116, 'Espace : lancer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, Y + 132, '1 2 3 : garder', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, Y + 148, 'Entr' + Chr(130) + 'e : passer', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, Y + 164, 'F1 : r' + Chr(138) + 'gles', CLR_DARKGRAY, CLR_PALEGRAY);
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
  DrawTable;
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ ne redessine que les des du joueur P (pendant le roulement) }
Procedure DrawDiceNow(P : LongInt);
Var X, Y, K : LongInt;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  Seat(P, X, Y);
  FBar(X, Y, X + 3 * Ds + 2 * DGap + 3, Y + Ds + 3, CLR_DARKGREEN);
  For K := 1 To 3 Do DrawDie(X + (K - 1) * (Ds + DGap), Y, Dice[P, K], Hold[P, K] <> 0);
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Partie                                                                }
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
  For K := 1 To 3 Do SetMark(CM_OPP1 + K - 1, K = NOpp);
  SetMark(CM_AUTO, AutoMe <> 0);
End;

Procedure StartRoll(P : LongInt);
Begin
  If RollsLeft[P] <= 0 Then Exit;
  If Hold[P, 1] + Hold[P, 2] + Hold[P, 3] = 3 Then Exit;
  Anim := 6;
End;

{ fin du roulement : valeurs definitives }
Procedure FinishRoll(P : LongInt);
Var K : LongInt;
Begin
  For K := 1 To 3 Do If Hold[P, K] = 0 Then Dice[P, K] := Rnd(6) + 1;
  Dec(RollsLeft[P]);
  Played[P] := 1;
  PScore[P] := CalcScore(P);
End;

Procedure NewRound;
Var P, K : LongInt;
Begin
  Phase := 0; Cur := 0; Winner := -1; Anim := 0; CpuWait := 0;
  For P := 0 To NPl - 1 Do
  Begin
    RollsLeft[P] := 3; Played[P] := 0; PScore[P] := 0;
    For K := 1 To 3 Do
    Begin
      Dice[P, K] := Rnd(6) + 1; Hold[P, K] := 0;
    End;
  End;
  { premier lancer de chacun, comme le prototype }
  For P := 0 To NPl - 1 Do FinishRoll(P);
  Msg := 'Manche ' + IStr(RoundNo) + ' : ' + ScoreDesc(0) + '. Cliquez les d' + Chr(130) + 's ' + Chr(133) +
         ' garder, puis Lancer (Espace) ou Garder la main (Entr' + Chr(130) + 'e).';
  Redraw;
End;

Procedure NewGame;
Var P : LongInt;
Begin
  NPl := NOpp + 1;
  PName[0] := 'Vous';
  If NOpp = 1 Then PName[1] := 'Ordinateur'
  Else For P := 1 To NOpp Do PName[P] := 'Ordi ' + IStr(P);
  For P := 0 To NPl - 1 Do Tokens[P] := StartTokens;
  RoundNo := 1;
  NewRound;
End;

Procedure EndRound;
Var P, Best, BestS, N, Pay, Gain : LongInt;
Begin
  Best := -1; BestS := -1; N := 0;
  For P := 0 To NPl - 1 Do
    If Strength(P) > BestS Then
    Begin
      BestS := Strength(P); Best := P; N := 1;
    End
    Else If Strength(P) = BestS Then Inc(N);
  If N > 1 Then Best := -1;
  Winner := Best; Gain := 0;
  If Best >= 0 Then
  Begin
    If PScore[Best] = S421 Then Pay := 2 Else If PScore[Best] >= SSuite Then Pay := 1 Else Pay := 0;
    For P := 0 To NPl - 1 Do
      If (P <> Best) And (Pay > 0) Then
      Begin
        If Tokens[P] < Pay Then
        Begin
          Gain := Gain + Tokens[P]; Tokens[P] := 0;
        End
        Else
        Begin
          Tokens[P] := Tokens[P] - Pay; Gain := Gain + Pay;
        End;
      End;
    Tokens[Best] := Tokens[Best] + Gain;
    If Gain > 0 Then ResMsg := ScoreDesc(Best) + ' : ' + IStr(Gain) + ' jeton(s) gagn' + Chr(130) + '(s)'
    Else ResMsg := ScoreDesc(Best) + ' : aucun jeton';
    Msg := PName[Best] + ' gagne la manche ' + IStr(RoundNo) + ' (' + ScoreDesc(Best) + ').';
  End
  Else
  Begin
    ResMsg := 'Mains de m' + Chr(136) + 'me force : aucun jeton';
    Msg := Chr(144) + 'galit' + Chr(130) + ' ' + Chr(133) + ' la manche ' + IStr(RoundNo) + '.';
  End;
  Paid := Gain;
  Phase := 1;
  N := 0;
  For P := 0 To NPl - 1 Do If Tokens[P] = 0 Then Inc(N);
  If (RoundNo >= MaxRounds) Or (N > 0) Then
  Begin
    Phase := 2;
    Best := 0;
    For P := 1 To NPl - 1 Do If Tokens[P] > Tokens[Best] Then Best := P;
    N := 0;
    For P := 0 To NPl - 1 Do If Tokens[P] = Tokens[Best] Then Inc(N);
    If N > 1 Then Winner := -1 Else Winner := Best;
    If Winner = 0 Then ResMsg := 'Vous gagnez avec ' + IStr(Tokens[0]) + ' jetons !'
    Else If Winner > 0 Then ResMsg := PName[Winner] + ' : ' + IStr(Tokens[Winner]) + ' jetons'
    Else ResMsg := 'Plusieurs joueurs ' + Chr(133) + ' ' + IStr(Tokens[Best]) + ' jetons';
    Msg := 'Partie termin' + Chr(130) + 'e : ' + ResMsg + ' Espace ou F2 : nouvelle partie.';
  End
  Else Msg := Msg + ' Espace ou Entr' + Chr(130) + 'e : manche suivante.';
  Redraw;
End;

Procedure NextPlayer;
Begin
  Inc(Cur);
  CpuWait := 0;
  If Cur >= NPl Then
  Begin
    Cur := 0;
    EndRound;
    Exit;
  End;
  Msg := PName[Cur] + ' joue...';
  Redraw;
End;

{ ordinateur : s'arreter sur une combinaison, sinon garder les 1, 2 et 4 }
Procedure CpuDecide(P : LongInt);
Var K, V, Ones : LongInt; Seen2, Seen4 : Boolean;
Begin
  If (RollsLeft[P] <= 0) Or (PScore[P] >= SSuite) Then
  Begin
    NextPlayer;
    Exit;
  End;
  Ones := 0;
  For K := 1 To 3 Do If Dice[P, K] = 1 Then Inc(Ones);
  Seen2 := False; Seen4 := False;
  For K := 1 To 3 Do
  Begin
    V := Dice[P, K];
    Hold[P, K] := 0;
    If V = 1 Then
    Begin
      If (Ones >= 2) Or Not ((Seen2) And (Seen4)) Then Hold[P, K] := 1;
    End
    Else If (V = 2) And Not Seen2 And (Ones <= 1) Then
    Begin
      Hold[P, K] := 1; Seen2 := True;
    End
    Else If (V = 4) And Not Seen4 And (Ones <= 1) Then
    Begin
      Hold[P, K] := 1; Seen4 := True;
    End;
  End;
  If Hold[P, 1] + Hold[P, 2] + Hold[P, 3] = 3 Then
  Begin
    NextPlayer;
    Exit;
  End;
  StartRoll(P);
  DrawDiceNow(P);
End;

Procedure HumanRoll;
Begin
  If Not HumanTurn Then
  Begin
    If Phase <> 0 Then Exit;
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  If RollsLeft[0] <= 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Plus de lancer : Entr' + Chr(130) + 'e pour passer.';
    Redraw;
    Exit;
  End;
  If Hold[0, 1] + Hold[0, 2] + Hold[0, 3] = 3 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Les trois d' + Chr(130) + 's sont gard' + Chr(130) + 's : Entr' + Chr(130) + 'e pour passer.';
    Redraw;
    Exit;
  End;
  StartRoll(0);
End;

Procedure HumanKeep;
Begin
  If Not HumanTurn Then Exit;
  NextPlayer;
End;

Procedure ToggleKeep(K : LongInt);
Begin
  If Not HumanTurn Then Exit;
  Hold[0, K] := 1 - Hold[0, K];
  DrawDiceNow(0);
End;

Procedure Continue_;
Begin
  If Phase = 1 Then
  Begin
    Inc(RoundNo);
    NewRound;
  End
  Else If Phase = 2 Then NewGame;
End;

Procedure TimerTick;
Var K : LongInt;
Begin
  If Phase <> 0 Then Exit;
  If Anim > 0 Then
  Begin
    Dec(Anim);
    If Anim > 0 Then
    Begin
      For K := 1 To 3 Do If Hold[Cur, K] = 0 Then Dice[Cur, K] := Rnd(6) + 1;
      DrawDiceNow(Cur);
    End
    Else
    Begin
      FinishRoll(Cur);
      If Cur = 0 Then
      Begin
        Msg := ScoreDesc(0) + '.';
        If RollsLeft[0] > 0 Then Msg := Msg + ' Encore ' + IStr(RollsLeft[0]) + ' lancer(s), ou Entr' + Chr(130) +
                                        'e pour garder.'
        Else Msg := Msg + ' Plus de lancer.';
      End
      Else Msg := PName[Cur] + ' : ' + ScoreDesc(Cur) + '.';
      Redraw;
      If (Cur = 0) And (RollsLeft[0] = 0) And (AutoMe = 0) Then NextPlayer;
    End;
    Exit;
  End;
  If (Cur <> 0) Or (AutoMe <> 0) Then
  Begin
    Inc(CpuWait);
    If CpuWait >= 7 Then
    Begin
      CpuWait := 0;
      CpuDecide(Cur);
    End;
  End;
End;

Procedure Command(Id : LongInt);
Begin
  If (Id >= CM_OPP1) And (Id <= CM_OPP1 + 2) Then
  Begin
    NOpp := Id - CM_OPP1 + 1;
    SetMarks;
    NewGame;
    Exit;
  End;
  Case Id Of
    CM_NEW : NewGame;
    CM_ROLL : If Phase = 0 Then HumanRoll Else Continue_;
    CM_KEEP : If Phase = 0 Then HumanKeep Else Continue_;
    CM_AUTO :
      Begin
        AutoMe := 1 - AutoMe;
        SetMarks;
        Redraw;
      End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd('Chaque joueur a 21 jetons et trois d' + Chr(130) + 's. ' + Chr(128) + ' chaque manche, il lance ' +
             'les d' + Chr(130) + 's jusqu''' + Chr(133) + ' trois fois et peut garder des d' + Chr(130) +
             's entre les lancers.' + Chr(10) + Chr(10));
        LAdd('Combinaisons, de la meilleure ' + Chr(133) + ' la moins bonne : 421 (10 points) ; brelans 111, 666 ' +
             Chr(133) + ' 222 (8 points) ; suites 654, 543, 432, 321 (6 points) ; sinon chaque as vaut 1 point.' +
             Chr(10) + Chr(10));
        LAdd('Le meilleur de la manche re' + Chr(135) + 'oit 2 jetons de chaque autre joueur sur un 421, 1 jeton ' +
             'sur un brelan ou une suite. Apr' + Chr(138) + 's 11 manches, ou quand un joueur n''a plus de ' +
             'jetons, le plus riche gagne.' + Chr(10) + Chr(10));
        LAdd('Clavier : Espace (lancer), 1 2 3 (garder un d' + Chr(130) + '), Entr' + Chr(130) + 'e (garder la ' +
             'main), F2 (nouvelle partie). Souris : cliquez un d' + Chr(130) + ' pour le garder (fond jaune).');
        Dummy := LMsgBox('421 - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('421 pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype 421.PAS de ' +
                            '7iles (Turbo Pascal et BGI).' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos de 421', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure Click(Mx, My : LongInt);
Var X, Y, K, DX, DY : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= TX) And (X < TX + TW) And (Y >= TY) And (Y < TY + THt) Then
  Begin
    If Phase <> 0 Then
    Begin
      Continue_;
      Exit;
    End;
    Seat(0, DX, DY);
    For K := 1 To 3 Do
      If (X >= DX + (K - 1) * (Ds + DGap)) And (X < DX + (K - 1) * (Ds + DGap) + Ds) And (Y >= DY) And
         (Y < DY + Ds) Then ToggleKeep(K);
    Exit;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= TY + 160) And (Y < TY + 190) Then HumanRoll
    Else If (Y >= TY + 196) And (Y < TY + 226) Then HumanKeep
    Else If (Y >= TY + 232) And (Y < TY + 262) Then Continue_;
  End;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
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
    If Vk = VK_SPACE Then Begin Command(CM_ROLL); Exit; End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Command(CM_KEEP); Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case Chr(Ch) Of
      '1' : ToggleKeep(1);
      '2' : ToggleKeep(2);
      '3' : ToggleKeep(3);
      ' ' : Command(CM_ROLL);
      'n', 'N' : NewGame;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  MainProc := 0;
  Case Msg Of
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
      If Not KeyChar(Mp1, Mp2) Then MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2) Else MainProc := 1;
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  NOpp := 1; AutoMe := 0; Frame := 0;
  Client := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
    If (S = '/AUTO') Or (S = '/auto') Then AutoMe := 1;
    If (Length(S) = 6) And ((Copy(S, 1, 5) = '/OPP:') Or (Copy(S, 1, 5) = '/opp:')) And (S[6] >= '1') And
       (S[6] <= '3') Then NOpp := Ord(S[6]) - 48;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('GAME421'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('GAME421'), Z2('421'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_ROLL, '~Lancer les d' + Chr(130) + 's' + Chr(9) + 'Espace');
  MItem(MIS_TEXT, 0, CM_KEEP, '~Garder la main' + Chr(9) + 'Entr' + Chr(130) + 'e');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Options');
  H3 := MenuOpen;
  For K := 1 To 3 Do
  Begin
    If K = 1 Then S := '~1 adversaire' Else S := '~' + IStr(K) + ' adversaires';
    If K = NOpp Then MItem(MIS_TEXT, MIA_CHECKED, CM_OPP1 + K - 1, S) Else MItem(MIS_TEXT, 0, CM_OPP1 + K - 1, S);
  End;
  MItem(MIS_SEPARATOR, 0, 0, '');
  If AutoMe <> 0 Then MItem(MIS_TEXT, MIA_CHECKED, CM_AUTO, 'L''ordinateur joue ~pour moi')
  Else MItem(MIS_TEXT, 0, CM_AUTO, 'L''ordinateur joue ~pour moi');
  MenuClose(H3, 5);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de 421');
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
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 100);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
