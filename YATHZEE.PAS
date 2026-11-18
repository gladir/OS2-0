{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: YATHZEE - jeu de des Yahtzee pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau).
}

Program YATHZEE;

{$R-,S-,I-}

{ Compilation : OS2PC YATHZEE.PAS   (produit YATHZEE.EXE)

  Portage vers OS/2-0 du prototype YATHZEE.PAS du depot 7iles (Turbo
  Pascal, mode texte, feuille de pointage en caracteres semi-graphiques,
  des choisis en tapant leur numero) : fenetre de Presentation Manager
  avec menus, des dessines, feuille de pointage cliquable (les points
  possibles sont affiches en gris), barre d'etat et apparence d'OS/2.

  Treize tours : a chaque tour, jusqu'a trois lancers des cinq des ; entre
  les lancers, on garde les des voulus (clic). Puis on inscrit le resultat
  dans une case libre de la feuille (clic sur la ligne). Section
  superieure : as a six (somme des des de cette valeur), prime de 35 si
  elle totalise 63 ou plus. Section inferieure : brelan et carre (somme
  des des), full (25), petite suite de 4 (30), grande suite de 5 (40),
  Yahtzee : cinq des pareils (50), chance (somme) ; prime de 100 pour
  chaque Yahtzee de plus apres un premier Yahtzee de 50.

  Modes : seul (comme le prototype), contre l'ordinateur ou deux joueurs.
  Clavier : Espace ou Entree (lancer), 1 a 5 (garder un de), F2 (nouvelle
  partie), F1 (regles).
  Parametres : /SEED:n ; /AUTO (l'ordinateur joue seul : demonstration). }

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
  VK_NEWLINE = $08; VK_SPACE = $10; VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_ROLL = 102; CM_QUIT = 104;
  CM_SOLO = 111; CM_VSCPU = 112; CM_TWO = 113;
  CM_RULES = 301; CM_ABOUT = 302;
  NCat = 13;
  { feuille (zone client, Y vers le bas) }
  SX = 10; SY = 10; LabW = 168; ColW = 68; RowH = 20;
  DX0 = 352; DY0 = 120; DSz = 44; DStep = 52;   { des }
  PnX = 344; PW = 254;
  CWant = 606; CHWant = 412;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Sc : Array[0..2 * NCat - 1] Of LongInt;         { joueur * 13 + case ; -1 : case libre }
  YBonus : Array[0..1] Of LongInt;               { primes Yahtzee (100 chacune) }
  Dice, Held : Array[0..4] Of LongInt;
  Turn, NPlay, Mode, Rolls, RoundNo, Anim, Over, Seed, AutoAll, CpuStep, Wait, Best : LongInt;
  Msg : String;
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

Function CatName(C : LongInt) : String;
Begin
  Case C Of
    0 : CatName := 'As';
    1 : CatName := 'Deux';
    2 : CatName := 'Trois';
    3 : CatName := 'Quatre';
    4 : CatName := 'Cinq';
    5 : CatName := 'Six';
    6 : CatName := 'Brelan';
    7 : CatName := 'Carr' + Chr(130);
    8 : CatName := 'Full (25)';
    9 : CatName := 'Petite suite (30)';
    10 : CatName := 'Grande suite (40)';
    11 : CatName := 'Yahtzee (50)';
  Else
    CatName := 'Chance';
  End;
End;

Function IsCpu(P : LongInt) : Boolean;
Begin
  IsCpu := (AutoAll <> 0) Or ((Mode = 1) And (P = 1));
End;

Function PName(P : LongInt) : String;
Begin
  If AutoAll <> 0 Then PName := 'Ordi'
  Else If Mode = 0 Then PName := 'Vous'
  Else If Mode = 1 Then
  Begin
    If P = 0 Then PName := 'Vous' Else PName := 'Ordi';
  End
  Else PName := 'Joueur ' + IStr(P + 1);
End;

{ ==================================================================== }
{ Points                                                                }
{ ==================================================================== }

Function MaxSame : LongInt;
Var N : Array[0..6] Of LongInt; K, M : LongInt;
Begin
  For K := 0 To 6 Do N[K] := 0;
  For K := 0 To 4 Do Inc(N[Dice[K]]);
  M := 0;
  For K := 1 To 6 Do If N[K] > M Then M := N[K];
  MaxSame := M;
End;

{ plus longue suite de valeurs differentes }
Function RunLen : LongInt;
Var N : Array[0..6] Of LongInt; K, R, M : LongInt;
Begin
  For K := 0 To 6 Do N[K] := 0;
  For K := 0 To 4 Do Inc(N[Dice[K]]);
  R := 0; M := 0;
  For K := 1 To 6 Do
    If N[K] > 0 Then
    Begin
      Inc(R);
      If R > M Then M := R;
    End
    Else R := 0;
  RunLen := M;
End;

Function SumDice : LongInt;
Var K, S : LongInt;
Begin
  S := 0;
  For K := 0 To 4 Do S := S + Dice[K];
  SumDice := S;
End;

{ points que vaudraient les des dans la case C }
Function Score(C : LongInt) : LongInt;
Var K, S, M : LongInt; N : Array[0..6] Of LongInt; Two, Three : Boolean;
Begin
  For K := 0 To 6 Do N[K] := 0;
  For K := 0 To 4 Do Inc(N[Dice[K]]);
  M := MaxSame;
  S := 0;
  Case C Of
    0..5 : S := N[C + 1] * (C + 1);
    6 : If M >= 3 Then S := SumDice;
    7 : If M >= 4 Then S := SumDice;
    8 :
      Begin
        Two := False; Three := False;
        For K := 1 To 6 Do
        Begin
          If N[K] = 2 Then Two := True;
          If N[K] = 3 Then Three := True;
        End;
        If Two And Three Then S := 25;
      End;
    9 : If RunLen >= 4 Then S := 30;
    10 : If RunLen >= 5 Then S := 40;
    11 : If M = 5 Then S := 50;
  Else
    S := SumDice;
  End;
  Score := S;
End;

Function Upper(P : LongInt) : LongInt;
Var C, S : LongInt;
Begin
  S := 0;
  For C := 0 To 5 Do If Sc[P * NCat + C] > 0 Then S := S + Sc[P * NCat + C];
  Upper := S;
End;

Function Bonus(P : LongInt) : LongInt;
Begin
  If Upper(P) >= 63 Then Bonus := 35 Else Bonus := 0;
End;

Function Total(P : LongInt) : LongInt;
Var C, S : LongInt;
Begin
  S := 0;
  For C := 0 To NCat - 1 Do If Sc[P * NCat + C] > 0 Then S := S + Sc[P * NCat + C];
  Total := S + Bonus(P) + YBonus[P];
End;

Function Free(P, C : LongInt) : Boolean;
Begin
  Free := Sc[P * NCat + C] < 0;
End;

{ ==================================================================== }
{ Ordinateur                                                            }
{ ==================================================================== }

{ valeur d'une inscription pour l'ordinateur (points ajustes) }
Function Worth(P, C : LongInt) : LongInt;
Var S, W : LongInt;
Begin
  S := Score(C);
  Case C Of
    0..5 :
      Begin
        W := (S - 3 * (C + 1)) * 2 + S;
        If S = 0 Then W := -4 * (C + 1);
      End;
    6, 7 : If S > 0 Then W := S - 12 Else W := -18 + C;
    8 : If S > 0 Then W := 30 Else W := -16;
    9 : If S > 0 Then W := 32 Else W := -18;
    10 : If S > 0 Then W := 45 Else W := -22;
    11 : If S > 0 Then W := 80 Else W := -30 + RoundNo * 2;
  Else
    W := S - 24;
  End;
  Worth := W;
End;

Function CpuCategory(P : LongInt) : LongInt;
Var C, B, W, Bw : LongInt;
Begin
  B := -1; Bw := -100000;
  For C := 0 To NCat - 1 Do
    If Free(P, C) Then
    Begin
      W := Worth(P, C);
      If W > Bw Then
      Begin
        Bw := W; B := C;
      End;
    End;
  CpuCategory := B;
End;

{ choisit les des a garder ; resultat : True s'il vaut mieux s'arreter }
Function CpuHold(P : LongInt) : Boolean;
Var N : Array[0..6] Of LongInt; K, V, M, Mv, R, Lo, Hi, I : LongInt; Got : Array[0..6] Of LongInt;
Begin
  CpuHold := False;
  For K := 0 To 4 Do Held[K] := 0;
  For K := 0 To 6 Do N[K] := 0;
  For K := 0 To 4 Do Inc(N[Dice[K]]);
  M := MaxSame;
  If (M = 5) And (Free(P, 11) Or (Sc[P * NCat + 11] = 50)) Then
  Begin
    CpuHold := True;
    Exit;
  End;
  If (RunLen >= 5) And Free(P, 10) Then
  Begin
    CpuHold := True;
    Exit;
  End;
  If (Score(8) > 0) And Free(P, 8) And (M = 3) Then
  Begin
    CpuHold := True;
    Exit;
  End;
  { suite de quatre : la garder si une suite est libre }
  If (RunLen >= 4) And (Free(P, 9) Or Free(P, 10)) And (M < 3) Then
  Begin
    If Not Free(P, 10) Then
    Begin
      CpuHold := True;
      Exit;
    End;
    { trouver la suite de 4 et garder un de de chaque valeur }
    Lo := 0;
    For K := 1 To 3 Do
      If (N[K] > 0) And (N[K + 1] > 0) And (N[K + 2] > 0) And (N[K + 3] > 0) Then Lo := K;
    For K := 0 To 6 Do Got[K] := 0;
    For I := 0 To 4 Do
    Begin
      V := Dice[I];
      If (V >= Lo) And (V <= Lo + 3) And (Got[V] = 0) Then
      Begin
        Held[I] := 1; Got[V] := 1;
      End;
    End;
    Exit;
  End;
  { sinon : garder la valeur la plus frequente (la plus forte a egalite) }
  Mv := 0;
  For V := 6 DownTo 1 Do If (N[V] = M) And (Mv = 0) Then Mv := V;
  If (M = 1) Then
  Begin
    { rien d'interessant : garder un six ou un cinq pour la chance }
    For I := 0 To 4 Do If (Dice[I] >= 5) And (Mv <> 0) Then
    Begin
      Held[I] := 1; Mv := 0;
    End;
    Exit;
  End;
  For I := 0 To 4 Do If Dice[I] = Mv Then Held[I] := 1;
  Hi := 0; R := 0;
  If R + Hi < 0 Then CpuHold := True;
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
{ Dessin (Y vers le bas)                                                }
{ ==================================================================== }

Var
  Face : Array[0..4] Of LongInt;    { faces affichees (hasard pendant le roulement) }

Procedure Button(X, Y, W, H : LongInt; S : String; On : Boolean);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  If On Then OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_DARKGRAY, CLR_PALEGRAY);
End;

Procedure DrawDie(K : LongInt);
Var X, Y, V, Bg, Fg, C, D : LongInt;
Begin
  X := DX0 + K * DStep; Y := DY0;
  FBar(X - 4, Y - 4, X + DSz + 6, Y + DSz + 26, CLR_PALEGRAY);
  If Rolls = 0 Then
  Begin
    Bg := CLR_PALEGRAY; Fg := CLR_DARKGRAY;
  End
  Else
  Begin
    Bg := CLR_WHITE; Fg := CLR_BLACK;
  End;
  If Held[K] <> 0 Then Y := Y - 3;
  FBar(X + 3, Y + 3, X + DSz + 2, Y + DSz + 2, CLR_DARKGRAY);
  FBar(X + 2, Y, X + DSz - 3, Y + DSz - 1, Bg);
  FBar(X, Y + 2, X + DSz - 1, Y + DSz - 3, Bg);
  Edge(X, Y + 2, X + DSz - 1, Y + DSz - 3, Bg, CLR_DARKGRAY);
  If Held[K] <> 0 Then
  Begin
    Edge(X - 2, Y - 2, X + DSz + 1, Y + DSz + 1, CLR_RED, CLR_RED);
    Edge(X - 3, Y - 3, X + DSz + 2, Y + DSz + 2, CLR_RED, CLR_RED);
    OutTxt(X + (DSz - 40) Div 2, DY0 + DSz + 8, 'gard' + Chr(130), CLR_DARKRED, CLR_PALEGRAY);
  End
  Else If (Rolls > 0) And (Rolls < 3) And Not IsCpu(Turn) And (Over = 0) Then
    OutTxt(X + DSz Div 2 - 4, DY0 + DSz + 8, IStr(K + 1), CLR_DARKGRAY, CLR_PALEGRAY);
  If Rolls = 0 Then
  Begin
    OutTxt(X + DSz Div 2 - 4, Y + DSz Div 2 - 8, '?', Fg, Bg);
    Exit;
  End;
  V := Face[K]; C := DSz Div 2; D := 11;
  If (V = 1) Or (V = 3) Or (V = 5) Then Disc(X + C, Y + C, 4, Fg);
  If V >= 2 Then
  Begin
    Disc(X + C - D, Y + C - D, 4, Fg); Disc(X + C + D, Y + C + D, 4, Fg);
  End;
  If V >= 4 Then
  Begin
    Disc(X + C + D, Y + C - D, 4, Fg); Disc(X + C - D, Y + C + D, 4, Fg);
  End;
  If V = 6 Then
  Begin
    Disc(X + C - D, Y + C, 4, Fg); Disc(X + C + D, Y + C, 4, Fg);
  End;
End;

Function RowY(R : LongInt) : LongInt;
Begin
  RowY := SY + R * RowH;
End;

Function CatRow(C : LongInt) : LongInt;
Begin
  If C < 6 Then CatRow := 1 + C Else CatRow := 3 + C;
End;

Procedure Cell(R, P : LongInt; S : String; Fg, Bg : LongInt);
Var X, Y : LongInt;
Begin
  X := SX + LabW + P * ColW; Y := RowY(R);
  FBar(X, Y, X + ColW - 1, Y + RowH - 1, Bg);
  FBar(X, Y, X, Y + RowH - 1, CLR_DARKGRAY);
  FBar(X, Y + RowH - 1, X + ColW - 1, Y + RowH - 1, CLR_DARKGRAY);
  OutTxt(X + ColW - 8 - Length(S) * 8, Y + 2, S, Fg, Bg);
End;

Procedure Lab(R : LongInt; S : String; Fg, Bg : LongInt);
Var Y : LongInt;
Begin
  Y := RowY(R);
  FBar(SX, Y, SX + LabW - 1, Y + RowH - 1, Bg);
  FBar(SX, Y + RowH - 1, SX + LabW - 1, Y + RowH - 1, CLR_DARKGRAY);
  OutTxt(SX + 6, Y + 2, S, Fg, Bg);
End;

Procedure DrawSheet;
Var P, C, R, V, W : LongInt; Bg : LongInt;
Begin
  W := LabW + NPlay * ColW;
  Edge(SX - 2, SY - 2, SX + W + 1, RowY(18) + 1, CLR_DARKGRAY, CLR_WHITE);
  Lab(0, 'Feuille de pointage', CLR_WHITE, CLR_DARKBLUE);
  For P := 0 To NPlay - 1 Do
    If (P = Turn) And (Over = 0) Then Cell(0, P, PName(P), CLR_YELLOW, CLR_DARKBLUE)
    Else Cell(0, P, PName(P), CLR_WHITE, CLR_DARKBLUE);
  For C := 0 To NCat - 1 Do
  Begin
    R := CatRow(C);
    If C < 6 Then Bg := CLR_WHITE Else Bg := CLR_WHITE;
    Lab(R, CatName(C), CLR_BLACK, Bg);
    For P := 0 To NPlay - 1 Do
    Begin
      V := Sc[P * NCat + C];
      If V >= 0 Then Cell(R, P, IStr(V), CLR_BLACK, Bg)
      Else If (P = Turn) And (Rolls > 0) And (Over = 0) And (Anim = 0) Then
        Cell(R, P, IStr(Score(C)), CLR_DARKGRAY, CLR_YELLOW)
      Else Cell(R, P, '', CLR_BLACK, Bg);
    End;
  End;
  Lab(7, 'Total sup' + Chr(130) + 'rieur', CLR_DARKBLUE, CLR_PALEGRAY);
  Lab(8, 'Prime 35 (63 et +)', CLR_DARKBLUE, CLR_PALEGRAY);
  Lab(16, 'Prime Yahtzee', CLR_DARKBLUE, CLR_PALEGRAY);
  Lab(17, 'TOTAL', CLR_WHITE, CLR_DARKBLUE);
  For P := 0 To NPlay - 1 Do
  Begin
    Cell(7, P, IStr(Upper(P)) + '/63', CLR_DARKBLUE, CLR_PALEGRAY);
    Cell(8, P, IStr(Bonus(P)), CLR_DARKBLUE, CLR_PALEGRAY);
    Cell(16, P, IStr(YBonus[P]), CLR_DARKBLUE, CLR_PALEGRAY);
    Cell(17, P, IStr(Total(P)), CLR_YELLOW, CLR_DARKBLUE);
  End;
End;

Function RollLabel : String;
Begin
  If Rolls = 0 Then RollLabel := 'Lancer les d' + Chr(130) + 's'
  Else If Rolls < 3 Then RollLabel := 'Relancer (' + IStr(3 - Rolls) + ')'
  Else RollLabel := 'Choisissez une case';
End;

Procedure DrawPanel;
Var K : LongInt;
Begin
  BigText(PnX + (PW - 7 * 16) Div 2, SY + 2, 'YAHTZEE', CLR_DARKRED, CLR_PALEGRAY);
  FBar(PnX, SY + 44, PnX + PW - 1, SY + 100, CLR_PALEGRAY);
  If Over = 0 Then
  Begin
    OutTxt(PnX, SY + 48, 'Tour ' + IStr(RoundNo) + ' sur 13', CLR_BLACK, CLR_PALEGRAY);
    OutTxt(PnX, SY + 66, 'A jouer : ' + PName(Turn), CLR_DARKBLUE, CLR_PALEGRAY);
    OutTxt(PnX, SY + 84, 'Lancers : ' + IStr(Rolls) + ' sur 3', CLR_BLACK, CLR_PALEGRAY);
  End
  Else OutTxt(PnX, SY + 48, 'Partie termin' + Chr(130) + 'e', CLR_BLACK, CLR_PALEGRAY);
  For K := 0 To 4 Do DrawDie(K);
  Button(PnX + 8, SY + 194, PW - 16, 32, RollLabel, (Over = 0) And (Rolls < 3) And Not IsCpu(Turn) And (Anim = 0));
  FBar(PnX, SY + 240, PnX + PW - 1, SY + 300, CLR_PALEGRAY);
  OutTxt(PnX, SY + 244, 'Meilleur pointage : ' + IStr(Best), CLR_BLACK, CLR_PALEGRAY);
  If Mode = 0 Then OutTxt(PnX, SY + 262, 'Mode : seul', CLR_BLACK, CLR_PALEGRAY)
  Else If Mode = 1 Then OutTxt(PnX, SY + 262, 'Mode : contre l''ordinateur', CLR_BLACK, CLR_PALEGRAY)
  Else OutTxt(PnX, SY + 262, 'Mode : deux joueurs', CLR_BLACK, CLR_PALEGRAY);
  Button(PnX + 8, SY + 330, PW - 16, 30, 'Nouvelle partie', True);
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
  DrawSheet;
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ des seulement (pendant le roulement : pas de scintillement) }
Procedure ShowDice;
Var K : LongInt;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  For K := 0 To 4 Do DrawDie(K);
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
Begin
  SetMark(CM_SOLO, Mode = 0); SetMark(CM_VSCPU, Mode = 1); SetMark(CM_TWO, Mode = 2);
End;

Procedure StartTurn;
Var K : LongInt;
Begin
  Rolls := 0;
  For K := 0 To 4 Do Held[K] := 0;
  If IsCpu(Turn) Then
  Begin
    CpuStep := 1; Wait := 5;
    Msg := Msg + ' L''ordinateur joue.';
  End
  Else
  Begin
    CpuStep := 0;
    If Msg = '' Then Msg := 'Lancez les d' + Chr(130) + 's (Espace).'
    Else Msg := Msg + ' A ' + PName(Turn) + ' de lancer.';
  End;
  Redraw;
End;

Procedure NewGame;
Var K : LongInt;
Begin
  For K := 0 To 2 * NCat - 1 Do Sc[K] := -1;
  YBonus[0] := 0; YBonus[1] := 0;
  If Mode = 0 Then NPlay := 1 Else NPlay := 2;
  If AutoAll <> 0 Then NPlay := 1;
  Turn := 0; RoundNo := 1; Over := 0; Anim := 0;
  For K := 0 To 4 Do
  Begin
    Dice[K] := K + 1; Face[K] := K + 1;
  End;
  Msg := '';
  StartTurn;
End;

Procedure Roll;
Var K : LongInt;
Begin
  If (Over <> 0) Or (Rolls >= 3) Or (Anim > 0) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  If Rolls = 0 Then For K := 0 To 4 Do Held[K] := 0;
  For K := 0 To 4 Do If Held[K] = 0 Then Dice[K] := 1 + Rnd(6);
  Inc(Rolls);
  Anim := 6;
  Msg := 'Lancer ' + IStr(Rolls) + ' sur 3.';
  If Not IsCpu(Turn) Then
  Begin
    If Rolls < 3 Then Msg := Msg + ' Cliquez les d' + Chr(130) + 's ' + Chr(133) + ' garder, relancez ou ' +
      'choisissez une case.'
    Else Msg := Msg + ' Choisissez une case de la feuille.';
  End;
  Redraw;
End;

Procedure GameOver;
Var S : String; T0, T1 : LongInt;
Begin
  Over := 1;
  T0 := Total(0); T1 := Total(1);
  If T0 > Best Then Best := T0;
  If (NPlay = 2) And (T1 > Best) Then Best := T1;
  If NPlay = 1 Then S := 'Partie termin' + Chr(130) + 'e : ' + IStr(T0) + ' points.'
  Else If T0 > T1 Then S := PName(0) + ' gagne ' + IStr(T0) + ' ' + Chr(133) + ' ' + IStr(T1) + ' !'
  Else If T1 > T0 Then S := PName(1) + ' gagne ' + IStr(T1) + ' ' + Chr(133) + ' ' + IStr(T0) + ' !'
  Else S := Chr(144) + 'galit' + Chr(130) + ' : ' + IStr(T0) + ' points chacun.';
  Msg := S + '  F2 : nouvelle partie.';
  Redraw;
  If AutoAll = 0 Then
    If Ask(S + Chr(10) + Chr(10) + 'Une nouvelle partie ?', 'Yahtzee', MB_YESNO Or MB_QUERY) = MBID_YES Then
      NewGame;
End;

{ inscrit les des dans la case C du joueur }
Procedure Take(C : LongInt);
Var V : LongInt;
Begin
  If (Over <> 0) Or (Rolls = 0) Or (Anim > 0) Or (C < 0) Or Not Free(Turn, C) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  V := Score(C);
  If (MaxSame = 5) And (Sc[Turn * NCat + 11] = 50) Then
  Begin
    YBonus[Turn] := YBonus[Turn] + 100;
    Msg := 'Prime Yahtzee (+100) ! ';
  End
  Else Msg := '';
  Sc[Turn * NCat + C] := V;
  Msg := Msg + PName(Turn) + ' : ' + IStr(V) + ' en ' + CatName(C) + '.';
  Inc(Turn);
  If Turn >= NPlay Then
  Begin
    Turn := 0;
    Inc(RoundNo);
  End;
  If RoundNo > 13 Then
  Begin
    Rolls := 0;
    GameOver;
    Exit;
  End;
  StartTurn;
End;

Procedure ToggleHold(K : LongInt);
Begin
  If (Over <> 0) Or (Rolls = 0) Or (Rolls >= 3) Or IsCpu(Turn) Or (Anim > 0) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  Held[K] := 1 - Held[K];
  ShowDice;
End;

{ un top : roulement des des, coups de l'ordinateur }
Procedure TimerTick;
Var K : LongInt;
Begin
  If Anim > 0 Then
  Begin
    Dec(Anim);
    For K := 0 To 4 Do
      If (Held[K] = 0) And (Anim > 0) Then Face[K] := 1 + Rnd(6) Else Face[K] := Dice[K];
    If Anim = 0 Then Redraw Else ShowDice;
    Exit;
  End;
  If (Over <> 0) Then
  Begin
    If AutoAll <> 0 Then
    Begin
      Inc(Wait);
      If Wait > 40 Then NewGame;
    End;
    Exit;
  End;
  If (CpuStep = 0) Or Not IsCpu(Turn) Then Exit;
  If Wait > 0 Then
  Begin
    Dec(Wait);
    Exit;
  End;
  If Rolls = 0 Then
  Begin
    Roll;
    Wait := 4;
    Exit;
  End;
  If CpuStep = 1 Then
  Begin
    { choisir les des a garder (montres un instant) }
    If (Rolls < 3) And Not CpuHold(Turn) Then
    Begin
      CpuStep := 2; Wait := 5;
      ShowDice;
      Exit;
    End;
    Take(CpuCategory(Turn));
    Exit;
  End;
  CpuStep := 1;
  Roll;
  Wait := 4;
End;

Procedure SetMode(M : LongInt);
Begin
  Mode := M;
  SetMarks;
  NewGame;
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_NEW : NewGame;
    CM_ROLL : If Not IsCpu(Turn) Then Roll;
    CM_SOLO : SetMode(0);
    CM_VSCPU : SetMode(1);
    CM_TWO : SetMode(2);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Begin
      LClr;
      LAdd('' + 'Treize tours. A chaque tour : jusqu''' + Chr(133) + ' trois lancers ' + 'des cinq d' + Chr(130) +
           's ; entre les lancers, cliquez les d' + Chr(130) + 's ' + Chr(133) +
           ' garder. Puis cliquez une case libre de votre colonne (les points ');
      LAdd('' + 'possibles sont en gris sur fond jaune).' + Chr(10) + 'Section sup' + Chr(130) + 'rieure : as ' +
           Chr(133) + ' six = somme des d' + Chr(130) +
           's de cette valeur ; prime de 35 si elle totalise 63 ou plus.' + Chr(10) + 'Brelan, carr' + Chr(130) +
           ' : somme des d' + Chr(130) + 's (3 ou 4 pareils). Full : ');
      LAdd('' + '25 (3 + 2). Petite suite (4 qui se suivent) : 30. Grande suite (5) : 40. ' +
           'Yahtzee (5 pareils) : 50, puis 100 de prime par Yahtzee de plus. Chance : somme ' + 'des d' +
           Chr(130) + 's.' + Chr(10) + Chr(10) + 'Clavier : Espace (lancer), 1 ' + Chr(133));
      LAdd('' + ' 5 (garder un d' + Chr(130) + '), F2 (nouvelle partie).');
      Dummy := LMsgBox('Yahtzee - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    End;
    CM_ABOUT : Dummy := Ask('Yahtzee pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'YATHZEE.PAS de 7iles (mode texte) : seul, contre l''ordinateur ou ' + Chr(133) +
                            ' deux.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) +
                            ' par OS2PC.', 'A propos de Yahtzee', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure Click(Mx, My : LongInt);
Var X, Y, K, R, C : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  { des }
  If (Y >= DY0 - 4) And (Y < DY0 + DSz + 4) Then
    For K := 0 To 4 Do
      If (X >= DX0 + K * DStep) And (X < DX0 + K * DStep + DSz) Then
      Begin
        ToggleHold(K);
        Exit;
      End;
  { feuille : colonne du joueur qui joue }
  If (X >= SX + LabW + Turn * ColW) And (X < SX + LabW + (Turn + 1) * ColW) And (Y >= SY) And Not IsCpu(Turn) Then
  Begin
    R := (Y - SY) Div RowH;
    For C := 0 To NCat - 1 Do
      If CatRow(C) = R Then
      Begin
        Take(C);
        Exit;
      End;
  End;
  If (X >= PnX + 8) And (X < PnX + PW - 8) Then
  Begin
    If (Y >= SY + 194) And (Y < SY + 226) And Not IsCpu(Turn) Then Roll
    Else If (Y >= SY + 330) And (Y < SY + 360) Then NewGame;
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
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then
    Begin
      If Not IsCpu(Turn) Then Roll;
      Exit;
    End;
  End;
  If ((Fl And KC_CHAR) = 0) Or ((Fl And (KC_ALT Or KC_CTRL)) <> 0) Then
  Begin
    KeyChar := False;
    Exit;
  End;
  If (Ch >= 49) And (Ch <= 53) Then ToggleHold(Ch - 49)
  Else If Ch = 32 Then
  Begin
    If Not IsCpu(Turn) Then Roll;
  End
  Else KeyChar := False;
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

Var
  Fl, H0, H1, H2, Sw, Sh, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; AutoAll := 0; Mode := 1; Best := 0; Over := 1; Anim := 0; Rolls := 0; NPlay := 2;
  Client := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 6) And ((Copy(S, 1, 6) = '/SEED:') Or (Copy(S, 1, 6) = '/seed:')) Then
      Val(Copy(S, 7, 20), Seed, E);
    If (S = '/AUTO') Or (S = '/auto') Then AutoAll := 1;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('YATHZEE'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('YATHZEE'), Z2('Yahtzee'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_ROLL, '~Lancer les d' + Chr(130) + 's' + Chr(9) + 'Espace');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_SOLO, '~Seul');
  MItem(MIS_TEXT, MIA_CHECKED, CM_VSCPU, '~Contre l''ordinateur');
  MItem(MIS_TEXT, 0, CM_TWO, '~Deux joueurs');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 8);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Yahtzee');
  MenuClose(H2, 2);
  MenuClose(H0, 2);
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
  SetMarks;
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 90);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
