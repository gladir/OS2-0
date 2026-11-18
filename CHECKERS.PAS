{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: CHECKERS - jeu de dames anglaises (checkers) pour le
                Presentation Manager d'OS/2-0 (dossier Jeux du bureau).
}

Program CHECKERS;

{$R-,S-,I-}

{ Compilation : OS2PC CHECKERS.PAS   (produit CHECKERS.EXE)

  Portage vers OS/2-0 du prototype CHECKERS.PAS du depot 7iles (Turbo
  Pascal et BGI, deux curseurs au clavier, historique des coups) : fenetre
  de Presentation Manager avec menus, souris, panneau des pions et des
  coups, barre d'etat et apparence d'OS/2.

  Regles des dames anglaises (checkers), sur les cases foncees d'un damier
  de 8 x 8 : un pion avance d'une case en diagonale ; il prend en sautant
  par-dessus un pion adverse voisin (vers l'avant seulement), et continue
  tant qu'il peut prendre (rafle). La prise est obligatoire. Un pion qui
  atteint la derniere rangee devient une dame (couronne), qui avance et
  prend dans les quatre directions, d'une case a la fois. On perd quand on
  n'a plus de pion ou plus de coup ; 40 coups de chaque cote sans prise ni
  pion avance : partie nulle. Le prototype ne connaissait ni la prise
  obligatoire ni les rafles, et les dames ne prenaient pas.

  Vous jouez les blancs (en bas) contre l'ordinateur (rouges), qui
  cherche ses coups par alpha-beta (Facile, Moyen, Difficile), ou a deux
  joueurs. Comme dans le prototype, on choisit qui commence (menu Partie).
  Souris : cliquer un de ses pions puis une case marquee d'un point ; une
  rafle se joue d'un clic sur sa case d'arrivee. Clavier : fleches, Entree
  ou Espace (choisir puis jouer), Echap, Ctrl+Z (annuler), F2 (nouvelle
  partie), F1 (regles). Coups notes comme le prototype (colonne A a H,
  rangee 1 a 8 depuis le haut ; x pour une prise).
  Parametres : /SEED:n ; /AUTO (l'ordinateur joue les deux couleurs). }

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
  VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18;
  VK_ENTER = $1E; VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_NEW = 101; CM_UNDO = 102; CM_CPUFIRST = 103; CM_QUIT = 104;
  CM_VSCPU = 111; CM_TWO = 112;
  CM_EASY = 121; CM_MEDIUM = 122; CM_HARD = 123;
  CM_RULES = 301; CM_ABOUT = 302;
  { pieces : pions et dames blancs (vous), rouges (l'ordinateur) }
  SW = 1; SR = 2;
  WMan = 1; WKing = 2; RMan = 3; RKing = 4; Gone = 9;
  { disposition (zone client, Y vers le bas) }
  Cell = 46; GX = 14; GY = 12; Rad = 17;
  PnX = 404; PW = 196;
  CWant = 612; CHWant = 412;
  { recherche }
  MaxPly = 12; MaxM = 40; MaxP = 10;
  MaxHist = 200;
  Inf = 1000000;

Type
  TBd = Array[0..63] Of LongInt;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  Bd : TBd;
  Turn, Mode, Level, CpuFirst, Sel, SelC, LastF, LastT, Over, Thinking, Seed, AutoAll, NoProg, NMoves : LongInt;
  { coups generes, par profondeur }
  GN : Array[0..MaxPly] Of LongInt;
  GLen : Array[0..(MaxPly + 1) * MaxM - 1] Of LongInt;
  GPath, GCap : Array[0..(MaxPly + 1) * MaxM * MaxP - 1] Of LongInt;
  TPath, TCap : Array[0..MaxP] Of LongInt;
  { historique (annuler) et liste des coups }
  Hist : Array[0..MaxHist - 1] Of TBd;
  HTurn, HNoProg, HLastF, HLastT : Array[0..MaxHist - 1] Of LongInt;
  NHist : LongInt;
  MoveTxt : Array[0..MaxHist - 1] Of String[24];
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

Function Opp(S : LongInt) : LongInt;
Begin
  Opp := 3 - S;
End;

Function SideOf(P : LongInt) : LongInt;
Begin
  If (P = WMan) Or (P = WKing) Then SideOf := SW
  Else If (P = RMan) Or (P = RKing) Then SideOf := SR
  Else SideOf := 0;
End;

Function IsKing(P : LongInt) : Boolean;
Begin
  IsKing := (P = WKing) Or (P = RKing);
End;

Function SideName(S : LongInt) : String;
Begin
  If S = SW Then SideName := 'Blancs' Else SideName := 'Rouges';
End;

Function IsCpu(S : LongInt) : Boolean;
Begin
  IsCpu := (AutoAll <> 0) Or ((Mode = 0) And (S = SR));
End;

Function SqName(Q : LongInt) : String;
Begin
  SqName := Chr(65 + Q Mod 8) + Chr(49 + Q Div 8);
End;

{ ==================================================================== }
{ Coups (case = rangee * 8 + colonne ; rangee 0 en haut)                }
{ ==================================================================== }

Procedure AddMove(Ply, Len : LongInt);
Var M, K : LongInt;
Begin
  M := GN[Ply];
  If M >= MaxM Then Exit;
  GLen[Ply * MaxM + M] := Len;
  For K := 0 To Len - 1 Do GPath[(Ply * MaxM + M) * MaxP + K] := TPath[K];
  For K := 0 To Len - 2 Do GCap[(Ply * MaxM + M) * MaxP + K] := TCap[K];
  GN[Ply] := M + 1;
End;

{ rafles depuis la case Sq (pion Pc ; Len cases deja dans le chemin) ;
  resultat : au moins une prise trouvee }
Function Jumps(Var B : TBd; Ply, S, Pc, Sq, Len : LongInt) : Boolean;
Var D, Dr, Dc, R, C, Mid, Land, Old : LongInt; Any : Boolean;
Begin
  Any := False;
  R := Sq Div 8; C := Sq Mod 8;
  For D := 0 To 3 Do
  Begin
    If D < 2 Then Dr := -1 Else Dr := 1;
    If D Mod 2 = 0 Then Dc := -1 Else Dc := 1;
    If IsKing(Pc) Or ((S = SW) And (Dr = -1)) Or ((S = SR) And (Dr = 1)) Then
      If (R + 2 * Dr >= 0) And (R + 2 * Dr <= 7) And (C + 2 * Dc >= 0) And (C + 2 * Dc <= 7) Then
      Begin
        Mid := Sq + Dr * 8 + Dc; Land := Sq + 2 * (Dr * 8 + Dc);
        If (SideOf(B[Mid]) = Opp(S)) And (B[Land] = 0) And (Len < MaxP) Then
        Begin
          Any := True;
          TPath[Len] := Land; TCap[Len - 1] := Mid;
          Old := B[Mid];
          B[Sq] := 0; B[Mid] := Gone; B[Land] := Pc;
          { un pion qui arrive sur la derniere rangee devient dame : fin du coup }
          If (Not IsKing(Pc)) And (((S = SW) And (Land Div 8 = 0)) Or ((S = SR) And (Land Div 8 = 7))) Then
            AddMove(Ply, Len + 1)
          Else If Not Jumps(B, Ply, S, Pc, Land, Len + 1) Then AddMove(Ply, Len + 1);
          B[Land] := 0; B[Mid] := Old; B[Sq] := Pc;
        End;
      End;
  End;
  Jumps := Any;
End;

{ tous les coups permis de S (prise obligatoire) dans GN[Ply] }
Procedure Gen(Var B : TBd; Ply, S : LongInt);
Var Q, D, Dr, Dc, R, C, T : LongInt;
Begin
  GN[Ply] := 0;
  For Q := 0 To 63 Do
    If SideOf(B[Q]) = S Then
    Begin
      TPath[0] := Q;
      Dummy := Ord(Jumps(B, Ply, S, B[Q], Q, 1));
    End;
  If GN[Ply] > 0 Then Exit;
  For Q := 0 To 63 Do
    If SideOf(B[Q]) = S Then
    Begin
      R := Q Div 8; C := Q Mod 8;
      For D := 0 To 3 Do
      Begin
        If D < 2 Then Dr := -1 Else Dr := 1;
        If D Mod 2 = 0 Then Dc := -1 Else Dc := 1;
        If IsKing(B[Q]) Or ((S = SW) And (Dr = -1)) Or ((S = SR) And (Dr = 1)) Then
          If (R + Dr >= 0) And (R + Dr <= 7) And (C + Dc >= 0) And (C + Dc <= 7) Then
          Begin
            T := Q + Dr * 8 + Dc;
            If B[T] = 0 Then
            Begin
              TPath[0] := Q; TPath[1] := T;
              AddMove(Ply, 2);
            End;
          End;
      End;
    End;
End;

Function MFrom(Ply, M : LongInt) : LongInt;
Begin
  MFrom := GPath[(Ply * MaxM + M) * MaxP];
End;

Function MTo(Ply, M : LongInt) : LongInt;
Begin
  MTo := GPath[(Ply * MaxM + M) * MaxP + GLen[Ply * MaxM + M] - 1];
End;

Function IsJump(Ply, M : LongInt) : Boolean;
Var A, B0 : LongInt;
Begin
  A := MFrom(Ply, M); B0 := GPath[(Ply * MaxM + M) * MaxP + 1];
  IsJump := Abs(A Div 8 - B0 Div 8) = 2;
End;

{ joue le coup M ; resultat : une prise ou un pion a avance }
Function DoMove(Var B : TBd; Ply, M : LongInt) : Boolean;
Var F, T, Pc, K, L : LongInt;
Begin
  F := MFrom(Ply, M); T := MTo(Ply, M);
  Pc := B[F];
  L := GLen[Ply * MaxM + M];
  B[F] := 0;
  If IsJump(Ply, M) Then
    For K := 0 To L - 2 Do B[GCap[(Ply * MaxM + M) * MaxP + K]] := 0;
  If (Pc = WMan) And (T Div 8 = 0) Then Pc := WKing;
  If (Pc = RMan) And (T Div 8 = 7) Then Pc := RKing;
  B[T] := Pc;
  DoMove := IsJump(Ply, M) Or (Pc = WMan) Or (Pc = RMan);
End;

Function MoveName(Ply, M : LongInt) : String;
Var S : String; K, L : LongInt;
Begin
  L := GLen[Ply * MaxM + M];
  S := SqName(GPath[(Ply * MaxM + M) * MaxP]);
  For K := 1 To L - 1 Do
    If IsJump(Ply, M) Then S := S + 'x' + SqName(GPath[(Ply * MaxM + M) * MaxP + K])
    Else S := S + '-' + SqName(GPath[(Ply * MaxM + M) * MaxP + K]);
  MoveName := S;
End;

Function Count(Var B : TBd; S : LongInt; Kings : Boolean) : LongInt;
Var Q, N : LongInt;
Begin
  N := 0;
  For Q := 0 To 63 Do
    If SideOf(B[Q]) = S Then
      If (Not Kings) Or IsKing(B[Q]) Then Inc(N);
  Count := N;
End;

{ ==================================================================== }
{ Ordinateur : alpha-beta                                               }
{ ==================================================================== }

Function Eval(Var B : TBd; S : LongInt) : LongInt;
Var Q, V, P, R, C, W : LongInt;
Begin
  V := 0;
  For Q := 0 To 63 Do
  Begin
    P := B[Q];
    If P <> 0 Then
    Begin
      R := Q Div 8; C := Q Mod 8;
      Case P Of
        WMan : W := 100 + (7 - R) * 4;
        RMan : W := 100 + R * 4;
      Else
        W := 165;
      End;
      If (C >= 2) And (C <= 5) And (R >= 2) And (R <= 5) Then W := W + 5;
      If ((P = WMan) And (R = 7)) Or ((P = RMan) And (R = 0)) Then W := W + 8;
      If SideOf(P) = S Then V := V + W Else V := V - W;
    End;
  End;
  Eval := V;
End;

Function Search(Var B : TBd; S, Ply, Depth, Alpha, Beta : LongInt) : LongInt;
Var M, V, Best : LongInt; T : TBd; Prog : Boolean;
Begin
  Gen(B, Ply, S);
  If GN[Ply] = 0 Then
  Begin
    Search := -Inf + Ply;
    Exit;
  End;
  { les prises se poursuivent au-dela de l'horizon }
  If ((Depth <= 0) And Not IsJump(Ply, 0)) Or (Ply >= MaxPly - 1) Then
  Begin
    Search := Eval(B, S);
    Exit;
  End;
  Best := -Inf - 1;
  For M := 0 To GN[Ply] - 1 Do
  Begin
    T := B;
    Prog := DoMove(T, Ply, M);
    V := -Search(T, Opp(S), Ply + 1, Depth - 1, -Beta, -Alpha);
    If V > Best Then Best := V;
    If V > Alpha Then Alpha := V;
    If Alpha >= Beta Then
    Begin
      Search := Best;
      Exit;
    End;
  End;
  Search := Best;
End;

{ meilleur coup de S (indice dans GN[0]) ; au hasard entre coups egaux }
Function BestMove(S : LongInt) : LongInt;
Var M, V, Best, Raw, BestM, Depth, Sc : LongInt; T : TBd; Prog : Boolean;
Begin
  Case Level Of
    0 : Depth := 2;
    2 : Depth := 7;
  Else
    Depth := 4;
  End;
  Gen(Bd, 0, S);
  BestM := 0; Best := -Inf - 100; Raw := -Inf - 2;
  For M := 0 To GN[0] - 1 Do
  Begin
    T := Bd;
    Prog := DoMove(T, 0, M);
    If Level = 0 Then
    Begin
      V := -Search(T, Opp(S), 1, Depth - 1, -Inf - 2, Inf + 2);
      Sc := V + Rnd(60);
    End
    Else
    Begin
      V := -Search(T, Opp(S), 1, Depth - 1, -Inf - 2, -(Raw - 1));
      Sc := V * 4 + Rnd(3);
    End;
    If V > Raw Then Raw := V;
    If Sc > Best Then
    Begin
      Best := Sc; BestM := M;
    End;
  End;
  BestMove := BestM;
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

{ pion ou dame P centre en (X, Y) }
Procedure Piece(X, Y, P : LongInt);
Var C, Ci : LongInt;
Begin
  If SideOf(P) = SW Then
  Begin
    C := CLR_WHITE; Ci := CLR_PALEGRAY;
  End
  Else
  Begin
    C := CLR_RED; Ci := CLR_DARKRED;
  End;
  Disc(X + 2, Y + 3, Rad, CLR_BLACK);
  Disc(X, Y, Rad, CLR_BLACK);
  Disc(X, Y, Rad - 1, Ci);
  Disc(X - 1, Y - 2, Rad - 3, C);
  Disc(X - 1, Y - 2, Rad - 8, Ci);
  Disc(X - 1, Y - 2, Rad - 9, C);
  If IsKing(P) Then
  Begin
    { couronne }
    FBar(X - 8, Y + 1, X + 6, Y + 4, CLR_YELLOW);
    FBar(X - 8, Y - 6, X - 6, Y + 1, CLR_YELLOW);
    FBar(X - 2, Y - 8, X, Y + 1, CLR_YELLOW);
    FBar(X + 4, Y - 6, X + 6, Y + 1, CLR_YELLOW);
    FBar(X - 8, Y + 4, X + 6, Y + 4, CLR_BROWN);
  End;
End;

Function HumanToMove : Boolean;
Begin
  HumanToMove := (Over = 0) And Not IsCpu(Turn) And (Thinking = 0);
End;

{ la case T est-elle l'arrivee d'un coup du pion choisi ? }
Function IsDest(T : LongInt) : Boolean;
Var M : LongInt;
Begin
  IsDest := False;
  If (Sel < 0) Or Not HumanToMove Then Exit;
  For M := 0 To GN[0] - 1 Do
    If (MFrom(0, M) = Sel) And (MTo(0, M) = T) Then IsDest := True;
End;

Procedure DrawCell(Q : LongInt);
Var X, Y : LongInt;
Begin
  X := GX + 2 + (Q Mod 8) * Cell; Y := GY + 2 + (Q Div 8) * Cell;
  If ((Q Div 8) + (Q Mod 8)) Mod 2 = 0 Then FBar(X, Y, X + Cell - 1, Y + Cell - 1, CLR_PALEGRAY)
  Else FBar(X, Y, X + Cell - 1, Y + Cell - 1, CLR_DARKGRAY);
  If (Q = LastF) Or (Q = LastT) Then Edge(X + 1, Y + 1, X + Cell - 2, Y + Cell - 2, CLR_CYAN, CLR_CYAN);
  If Bd[Q] <> 0 Then Piece(X + Cell Div 2, Y + Cell Div 2, Bd[Q]);
  If Q = Sel Then
  Begin
    Edge(X + 1, Y + 1, X + Cell - 2, Y + Cell - 2, CLR_YELLOW, CLR_YELLOW);
    Edge(X + 2, Y + 2, X + Cell - 3, Y + Cell - 3, CLR_YELLOW, CLR_YELLOW);
  End;
  If IsDest(Q) Then
  Begin
    Disc(X + Cell Div 2, Y + Cell Div 2, 6, CLR_BLACK);
    Disc(X + Cell Div 2, Y + Cell Div 2, 5, CLR_YELLOW);
  End;
  If (Q = SelC) And (Over = 0) And Not IsCpu(Turn) Then
    Edge(X + 3, Y + 3, X + Cell - 4, Y + Cell - 4, CLR_BLUE, CLR_BLUE);
End;

Procedure DrawBoard;
Var K, W : LongInt;
Begin
  W := 8 * Cell + 4;
  Edge(GX - 2, GY - 2, GX + W + 1, GY + W + 1, CLR_DARKGRAY, CLR_WHITE);
  FBar(GX - 1, GY - 1, GX + W, GY + W, CLR_BLACK);
  For K := 0 To 63 Do DrawCell(K);
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure SideBox(Y, S : LongInt);
Var P : LongInt;
Begin
  FBar(PnX, Y, PnX + PW - 1, Y + 53, CLR_WHITE);
  Edge(PnX, Y, PnX + PW - 1, Y + 53, CLR_DARKGRAY, CLR_WHITE);
  If (Turn = S) And (Over = 0) Then
  Begin
    Edge(PnX + 1, Y + 1, PnX + PW - 2, Y + 52, CLR_BLUE, CLR_BLUE);
    Edge(PnX + 2, Y + 2, PnX + PW - 3, Y + 51, CLR_BLUE, CLR_BLUE);
  End;
  If S = SW Then P := WMan Else P := RMan;
  Piece(PnX + 26, Y + 26, P);
  OutTxt(PnX + 52, Y + 4, SideName(S), CLR_BLACK, CLR_WHITE);
  If IsCpu(S) Then OutTxt(PnX + 108, Y + 4, 'ordinateur', CLR_DARKGRAY, CLR_WHITE)
  Else If Mode = 0 Then OutTxt(PnX + 108, Y + 4, 'vous', CLR_DARKGRAY, CLR_WHITE);
  OutTxt(PnX + 52, Y + 20, 'Pions : ' + IStr(Count(Bd, S, False) - Count(Bd, S, True)), CLR_DARKBLUE, CLR_WHITE);
  OutTxt(PnX + 52, Y + 36, 'Dames : ' + IStr(Count(Bd, S, True)), CLR_DARKBLUE, CLR_WHITE);
End;

Procedure DrawPanel;
Var K, First, Y : LongInt; S : String;
Begin
  BigText(PnX + (PW - 8 * 16) Div 2, GY + 2, 'CHECKERS', CLR_DARKRED, CLR_PALEGRAY);
  SideBox(GY + 44, SR);
  SideBox(GY + 104, SW);
  If Mode = 0 Then
  Begin
    Case Level Of
      0 : S := 'Facile';
      2 : S := 'Difficile';
    Else
      S := 'Moyen';
    End;
    OutTxt(PnX, GY + 164, 'Niveau : ' + S, CLR_BLACK, CLR_PALEGRAY);
  End
  Else OutTxt(PnX, GY + 164, 'Deux joueurs', CLR_BLACK, CLR_PALEGRAY);
  { derniers coups }
  FBar(PnX, GY + 184, PnX + PW - 1, GY + 292, CLR_WHITE);
  Edge(PnX, GY + 184, PnX + PW - 1, GY + 292, CLR_DARKGRAY, CLR_WHITE);
  First := NHist - 6;
  If First < 0 Then First := 0;
  Y := GY + 188;
  For K := First To NHist - 1 Do
  Begin
    S := IStr(K + 1) + '. ' + MoveTxt[K];
    If HTurn[K] = SW Then OutTxt(PnX + 6, Y, S, CLR_BLACK, CLR_WHITE)
    Else OutTxt(PnX + 6, Y, S, CLR_DARKRED, CLR_WHITE);
    Y := Y + 17;
  End;
  Button(PnX, GY + 304, PW, 30, 'Nouvelle partie');
  Button(PnX, GY + 340, PW, 30, 'Annuler le coup');
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
  DrawBoard;
  DrawPanel;
  DrawStatus;
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
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
  SetMark(CM_VSCPU, Mode = 0); SetMark(CM_TWO, Mode = 1);
  SetMark(CM_EASY, Level = 0); SetMark(CM_MEDIUM, Level = 1); SetMark(CM_HARD, Level = 2);
  SetMark(CM_CPUFIRST, CpuFirst <> 0);
End;

Procedure TurnMsg;
Var M : LongInt; Jump : Boolean;
Begin
  Jump := (GN[0] > 0) And IsJump(0, 0);
  If IsCpu(Turn) Then Msg := 'L''ordinateur r' + Chr(130) + 'fl' + Chr(130) + 'chit...'
  Else
  Begin
    If Mode = 0 Then Msg := 'A vous (blancs) : ' Else Msg := 'Au tour des ' + SideName(Turn) + ' : ';
    If Jump Then Msg := Msg + 'prise obligatoire !' Else Msg := Msg + 'cliquez un pion, puis sa case d''arriv' +
      Chr(130) + 'e.';
  End;
  M := 0;
End;

Procedure GameOver(W : LongInt; Why : String);
Var S : String;
Begin
  Over := 1; Sel := -1;
  If W = 0 Then S := 'Partie nulle : ' + Why
  Else S := 'Les ' + SideName(W) + ' gagnent : ' + Why;
  Msg := S + '  F2 : nouvelle partie.';
  Redraw;
  If AutoAll <> 0 Then Exit;
  If (Mode = 0) And (W = SW) Then S := S + Chr(10) + 'Bravo, vous avez battu l''ordinateur !'
  Else If (Mode = 0) And (W = SR) Then S := S + Chr(10) + 'L''ordinateur gagne cette fois.';
  If Ask(S + Chr(10) + Chr(10) + 'Une nouvelle partie ?', 'Checkers', MB_YESNO Or MB_QUERY) = MBID_YES Then
  Begin
    Over := 0;
    Dummy := WinPostMsg(Client, WM_COMMAND, CM_NEW, 0);
  End;
End;

{ joueur suivant : fin de partie s'il ne peut plus jouer }
Procedure NextTurn;
Begin
  Sel := -1;
  Gen(Bd, 0, Turn);
  If GN[0] = 0 Then
  Begin
    If Count(Bd, Turn, False) = 0 Then GameOver(Opp(Turn), 'les ' + SideName(Turn) + ' n''ont plus de pion.')
    Else GameOver(Opp(Turn), 'les ' + SideName(Turn) + ' ne peuvent plus jouer.');
    Exit;
  End;
  If NoProg >= 80 Then
  Begin
    GameOver(0, '40 coups sans prise ni pion avanc' + Chr(130) + '.');
    Exit;
  End;
  TurnMsg;
  If IsCpu(Turn) Then Thinking := 2;
  Redraw;
End;

Procedure NewGame;
Var Q : LongInt;
Begin
  For Q := 0 To 63 Do
  Begin
    Bd[Q] := 0;
    If ((Q Div 8) + (Q Mod 8)) Mod 2 = 1 Then
    Begin
      If Q Div 8 <= 2 Then Bd[Q] := RMan;
      If Q Div 8 >= 5 Then Bd[Q] := WMan;
    End;
  End;
  If CpuFirst <> 0 Then Turn := SR Else Turn := SW;
  Over := 0; Sel := -1; SelC := 42; LastF := -1; LastT := -1; NHist := 0; NoProg := 0; Thinking := 0;
  NextTurn;
End;

Procedure Play(M : LongInt);
Begin
  If NHist < MaxHist Then
  Begin
    Hist[NHist] := Bd;
    HTurn[NHist] := Turn; HNoProg[NHist] := NoProg; HLastF[NHist] := LastF; HLastT[NHist] := LastT;
    MoveTxt[NHist] := MoveName(0, M);
    Inc(NHist);
  End;
  LastF := MFrom(0, M); LastT := MTo(0, M);
  If DoMove(Bd, 0, M) Then NoProg := 0 Else Inc(NoProg);
  Turn := Opp(Turn);
  NextTurn;
End;

Procedure CpuMove;
Begin
  If (Over <> 0) Or Not IsCpu(Turn) Then
  Begin
    Thinking := 0;
    Exit;
  End;
  Play(BestMove(Turn));
  If Not IsCpu(Turn) Then Thinking := 0;
End;

{ annuler : jusqu'au dernier coup du joueur (contre l'ordinateur) }
Procedure Undo;
Begin
  If (NHist = 0) Or (Thinking <> 0) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  Repeat
    Dec(NHist);
    Bd := Hist[NHist];
    Turn := HTurn[NHist]; NoProg := HNoProg[NHist]; LastF := HLastF[NHist]; LastT := HLastT[NHist];
  Until (NHist = 0) Or Not IsCpu(Turn);
  Over := 0;
  NextTurn;
End;

{ clic (ou Entree) sur la case Q }
Procedure Choose(Q : LongInt);
Var M, Any, Jump : LongInt;
Begin
  If Not HumanToMove Then Exit;
  Gen(Bd, 0, Turn);
  If Sel >= 0 Then
    For M := 0 To GN[0] - 1 Do
      If (MFrom(0, M) = Sel) And (MTo(0, M) = Q) Then
      Begin
        Play(M);
        Exit;
      End;
  If SideOf(Bd[Q]) = Turn Then
  Begin
    Any := 0;
    For M := 0 To GN[0] - 1 Do If MFrom(0, M) = Q Then Any := 1;
    If Any <> 0 Then
    Begin
      Sel := Q;
      TurnMsg;
    End
    Else
    Begin
      Dummy := WinAlarm(HWND_DESKTOP, 0);
      Jump := 0;
      If (GN[0] > 0) And IsJump(0, 0) Then Jump := 1;
      If Jump <> 0 Then Msg := 'Prise obligatoire : un autre pion doit prendre.'
      Else Msg := 'Ce pion ne peut pas avancer.';
      Sel := -1;
    End;
    Redraw;
    Exit;
  End;
  If Sel >= 0 Then Dummy := WinAlarm(HWND_DESKTOP, 0);
  Sel := -1;
  Redraw;
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
    CM_UNDO : Undo;
    CM_CPUFIRST : Begin CpuFirst := 1 - CpuFirst; SetMarks; NewGame; End;
    CM_VSCPU : SetMode(0);
    CM_TWO : SetMode(1);
    CM_EASY : Begin Level := 0; SetMarks; Redraw; End;
    CM_MEDIUM : Begin Level := 1; SetMarks; Redraw; End;
    CM_HARD : Begin Level := 2; SetMarks; Redraw; End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES : Begin
      LClr;
      LAdd('' + 'Dames anglaises (checkers) sur les cases fonc' + Chr(130) + 'es. Un pion avance ' +
           'd''une case en diagonale ; il prend en sautant par-dessus un pion adverse voisin ');
      LAdd('' + '(vers l''avant) et continue tant qu''il peut prendre (rafle). La prise est ' +
           'obligatoire. Un pion qui atteint la derni' + Chr(138) + 're rang' + Chr(130) + 'e ');
      LAdd('' + 'devient une dame (couronne), qui avance et prend dans les quatre directions. On ' +
           'perd quand on n''a plus de pion ou plus de coup ; 40 coups de chaque c' + Chr(147) + 't' + Chr(130) +
           ' sans prise ni pion avanc' + Chr(130) + ' : partie nulle.' + Chr(10) + Chr(10));
      LAdd('' + 'Souris : un pion puis une case marqu' + Chr(130) + 'e d''un point (une rafle ' +
           'se joue sur sa case d''arriv' + Chr(130) + 'e). Clavier : fl' + Chr(138) + 'ches, ' + 'Entr' +
           Chr(130) + 'e, ' + Chr(144) + 'chap, Ctrl+Z (annuler), F2 (nouvelle partie).');
      Dummy := LMsgBox('Checkers - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
    End;
    CM_ABOUT : Dummy := Ask('Checkers pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'CHECKERS.PAS de 7iles : dames anglaises contre l''ordinateur (alpha-b' + Chr(130) +
                            'ta) ou ' + Chr(133) + ' deux joueurs.' + Chr(10) + 'Programme ' + Chr(130) + 'crit en ' +
                            'Pascal et compil' + Chr(130) + ' par OS2PC.', 'A propos de Checkers',
                            MB_OK Or MB_INFORMATION);
  End;
End;

Procedure Click(Mx, My : LongInt);
Var X, Y, C, R : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= GX + 2) And (Y >= GY + 2) Then
  Begin
    C := (X - GX - 2) Div Cell; R := (Y - GY - 2) Div Cell;
    If (C < 8) And (R < 8) Then
    Begin
      SelC := R * 8 + C;
      Choose(SelC);
      Exit;
    End;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= GY + 304) And (Y < GY + 334) Then NewGame
    Else If (Y >= GY + 340) And (Y < GY + 370) Then Undo;
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
  If (Fl And KC_CTRL) <> 0 Then
  Begin
    If (Ch = 26) Or (Ch = Ord('z')) Or (Ch = Ord('Z')) Then Undo Else KeyChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F1 Then Begin Command(CM_RULES); Exit; End;
    If Vk = VK_F2 Then Begin Command(CM_NEW); Exit; End;
    If Vk = VK_LEFT Then Begin If SelC Mod 8 > 0 Then Dec(SelC); Redraw; Exit; End;
    If Vk = VK_RIGHT Then Begin If SelC Mod 8 < 7 Then Inc(SelC); Redraw; Exit; End;
    If Vk = VK_UP Then Begin If SelC >= 8 Then SelC := SelC - 8; Redraw; Exit; End;
    If Vk = VK_DOWN Then Begin If SelC < 56 Then SelC := SelC + 8; Redraw; Exit; End;
    If Vk = VK_ESC Then Begin Sel := -1; Redraw; Exit; End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_SPACE) Then Begin Choose(SelC); Exit; End;
  End;
  If ((Fl And KC_CHAR) <> 0) And (Ch = 32) Then
  Begin
    Choose(SelC);
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
    WM_TIMER :
      If Lo16(Mp1) = 1 Then
        If Thinking > 0 Then
        Begin
          Dec(Thinking);
          If Thinking = 0 Then
          Begin
            Thinking := 1;
            CpuMove;
          End;
        End;
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
  Fl, H0, H1, H2, ScrW, ScrH, Fw, Fh, M, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; AutoAll := 0; Mode := 0; Level := 1; CpuFirst := 0; Over := 1; Thinking := 0; Sel := -1;
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
  Dummy := WinRegisterClass(Hab, Z('CHECKERS'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('CHECKERS'), Z2('Checkers'), 0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouvelle partie' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_TEXT, 0, CM_CPUFIRST, 'Les rouges ~commencent');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, MIA_CHECKED, CM_VSCPU, '~Contre l''ordinateur');
  MItem(MIS_TEXT, 0, CM_TWO, '~Deux joueurs');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_EASY, '~Facile');
  MItem(MIS_TEXT, MIA_CHECKED, CM_MEDIUM, '~Moyen');
  MItem(MIS_TEXT, 0, CM_HARD, 'Di~fficile');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 12);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Checkers');
  MenuClose(H2, 2);
  MenuClose(H0, 2);
  M := WinCreateMenu(Frame, LongInt(@MenuT));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CWant; Rc[3] := CHWant;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (ScrW - Fw) Div 2; Y := (ScrH - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := ScrH - Fh;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  SetMarks;
  NewGame;
  Dummy := WinStartTimer(Hab, Client, 1, 300);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
