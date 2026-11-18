{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2011 (prototype), 2026 (OS/2-0)
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: HANOIS - Tours de Hanoi pour le Presentation Manager
                d'OS/2-0 (dossier Jeux du bureau).
}

Program HANOIS;

{$R-,S-,I-}

{ Compilation : OS2PC HANOIS.PAS   (produit HANOIS.EXE)

  Portage vers OS/2-0 du prototype HANOIS.PAS du depot 7iles (Turbo
  Pascal, mode texte) : fenetre de Presentation Manager avec menus,
  socle et tiges de bois, disques de couleur en relief, souris, clavier,
  annulation, solution animee, barre d'etat et apparence d'OS/2.

  But (comme le prototype) : les disques sont empiles sur la tige 2 ;
  deplacez toute la pile sur la tige 1 ou la tige 3, un disque a la fois,
  sans jamais poser un disque sur un plus petit. Il faut au moins 2^n - 1
  coups (127 pour 7 disques, le nombre du prototype ; 3 a 8 disques).

  Clavier : 1, 2, 3 (prendre le disque du dessus de cette tige, puis le
  poser sur une autre, comme le "De :" et "a :" du prototype), fleches
  gauche et droite et Espace ou Entree (meme chose avec le curseur),
  Ctrl+Z ou Retour arriere (annuler), F2 (recommencer), F3 (solution
  animee a partir de la position courante), F1 (regles).
  Souris : cliquer une tige pour prendre son disque, puis une autre pour
  le poser.
  Parametres : /DISKS:n (3 a 8 disques) ; /SOLVE (lance la solution). }

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
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_ESC = $0F; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21; VK_F3 = $22;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKPINK = 11; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  CM_RESTART = 101; CM_UNDO = 102; CM_SOLVE = 103; CM_QUIT = 104;
  CM_D3 = 113;                     { CM_D3 .. CM_D3 + 5 : 3 a 8 disques }
  CM_RULES = 301; CM_ABOUT = 302;
  MaxD = 8; MaxHist = 2000;
  { disposition (zone client, Y vers le bas) }
  BX0 = 10; BY0 = 10; AW = 440; AH = 362;
  PegSp = 146; PegX0 = 83;         { centre de la tige 1 : BX0 + PegX0 }
  BaseY = 300; PegTop = 110; DiskH = 20;
  PnX = 462; PW = 140;
  CWant = 612; CHWant = 406;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  DPeg : Array[1..MaxD] Of LongInt;       { tige (1 a 3) de chaque disque ; 1 = le plus petit }
  NDisk, Held, Cur, Moves, Solving, Done, Best, Seed : LongInt;
  HistF, HistT : Array[0..MaxHist - 1] Of Byte;
  NHist : LongInt;
  BestD : Array[3..MaxD] Of LongInt;
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
Function Ask(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

{ ==================================================================== }
{ Tours                                                                 }
{ ==================================================================== }

{ disque du dessus d'une tige (0 : tige vide) }
Function TopDisk(P : LongInt) : LongInt;
Var K : LongInt;
Begin
  TopDisk := 0;
  For K := NDisk DownTo 1 Do If DPeg[K] = P Then TopDisk := K;
End;

Function Count(P : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 1 To NDisk Do If DPeg[K] = P Then Inc(N);
  Count := N;
End;

Function MinMoves : LongInt;
Begin
  MinMoves := (1 Shl NDisk) - 1;
End;

Function Solved : Boolean;
Begin
  Solved := (Count(1) = NDisk) Or (Count(3) = NDisk);
End;

Function CanMove(F, T : LongInt) : Boolean;
Begin
  CanMove := False;
  If (F < 1) Or (F > 3) Or (T < 1) Or (T > 3) Or (F = T) Then Exit;
  If TopDisk(F) = 0 Then Exit;
  If (TopDisk(T) <> 0) And (TopDisk(T) < TopDisk(F)) Then Exit;
  CanMove := True;
End;

Procedure DoMove(F, T : LongInt);
Begin
  DPeg[TopDisk(F)] := T;
  Inc(Moves);
  If NHist < MaxHist Then
  Begin
    HistF[NHist] := F; HistT[NHist] := T;
    Inc(NHist);
  End;
End;

{ prochain coup optimal pour amener les disques 1 a K sur la tige T,
  depuis n'importe quelle position : De * 10 + Vers, 0 s'ils y sont }
Function NextMv(K, T : LongInt) : LongInt;
Var M : LongInt;
Begin
  If K = 0 Then
  Begin
    NextMv := 0;
    Exit;
  End;
  If DPeg[K] = T Then
  Begin
    NextMv := NextMv(K - 1, T);
    Exit;
  End;
  M := NextMv(K - 1, 6 - DPeg[K] - T);
  If M <> 0 Then NextMv := M Else NextMv := DPeg[K] * 10 + T;
End;

{ tige d'arrivee de la solution : 3, sauf si le grand disque est deja sur la 1 }
Function Goal : LongInt;
Begin
  If DPeg[NDisk] = 1 Then Goal := 1 Else Goal := 3;
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

Function PegCx(P : LongInt) : LongInt;
Begin
  PegCx := BX0 + PegX0 + (P - 1) * PegSp;
End;

Function DiskW(K : LongInt) : LongInt;
Begin
  DiskW := 26 + K * 14;
End;

Procedure DiskColors(K : LongInt; Var C, Lt, Dk : LongInt);
Begin
  Case K Of
    1 : Begin C := CLR_RED; Lt := CLR_PINK; Dk := CLR_DARKRED; End;
    2 : Begin C := CLR_BROWN; Lt := CLR_YELLOW; Dk := CLR_DARKRED; End;
    3 : Begin C := CLR_YELLOW; Lt := CLR_WHITE; Dk := CLR_BROWN; End;
    4 : Begin C := CLR_GREEN; Lt := CLR_WHITE; Dk := CLR_DARKGREEN; End;
    5 : Begin C := CLR_CYAN; Lt := CLR_WHITE; Dk := CLR_DARKCYAN; End;
    6 : Begin C := CLR_BLUE; Lt := CLR_CYAN; Dk := CLR_DARKBLUE; End;
    7 : Begin C := CLR_DARKPINK; Lt := CLR_PINK; Dk := CLR_DARKBLUE; End;
  Else
    Begin C := CLR_PALEGRAY; Lt := CLR_WHITE; Dk := CLR_DARKGRAY; End;
  End;
End;

{ disque K centre en Cx, haut en Y : bords arrondis et relief }
Procedure DrawDisk(K, Cx, Y : LongInt);
Var W, C, Lt, Dk, X1, X2 : LongInt;
Begin
  W := DiskW(K);
  DiskColors(K, C, Lt, Dk);
  X1 := Cx - W Div 2; X2 := X1 + W - 1;
  FBar(X1 + 3, Y, X2 - 3, Y, CLR_BLACK);
  FBar(X1 + 1, Y + 1, X2 - 1, Y + 1, CLR_BLACK);
  FBar(X1, Y + 2, X2, Y + DiskH - 3, CLR_BLACK);
  FBar(X1 + 1, Y + DiskH - 2, X2 - 1, Y + DiskH - 2, CLR_BLACK);
  FBar(X1 + 3, Y + DiskH - 1, X2 - 3, Y + DiskH - 1, CLR_BLACK);
  FBar(X1 + 3, Y + 1, X2 - 3, Y + DiskH - 2, C);
  FBar(X1 + 1, Y + 3, X2 - 1, Y + DiskH - 4, C);
  FBar(X1 + 4, Y + 2, X2 - 4, Y + 3, Lt);
  FBar(X1 + 2, Y + 4, X1 + 3, Y + DiskH - 6, Lt);
  FBar(X1 + 3, Y + DiskH - 4, X2 - 3, Y + DiskH - 3, Dk);
  FBar(X2 - 3, Y + 5, X2 - 2, Y + DiskH - 5, Dk);
  { trou de la tige }
  FBar(Cx - 3, Y + 6, Cx + 2, Y + DiskH - 7, Dk);
  OutTxt(X1 + 6, Y + 2, IStr(K), CLR_BLACK, C);
End;

Procedure DrawPeg(P : LongInt);
Var Cx, K, N, Y : LongInt;
Begin
  Cx := PegCx(P);
  { tige de bois }
  FBar(Cx - 4, BY0 + PegTop, Cx + 3, BY0 + BaseY - 1, CLR_BROWN);
  FBar(Cx - 4, BY0 + PegTop, Cx - 3, BY0 + BaseY - 1, CLR_YELLOW);
  FBar(Cx + 2, BY0 + PegTop, Cx + 3, BY0 + BaseY - 1, CLR_DARKRED);
  FBar(Cx - 3, BY0 + PegTop - 3, Cx + 2, BY0 + PegTop - 1, CLR_BROWN);
  { disques, du plus grand au plus petit }
  N := 0;
  For K := NDisk DownTo 1 Do
    If (DPeg[K] = P) And Not ((Held = P) And (K = TopDisk(P))) Then
    Begin
      Y := BY0 + BaseY - (N + 1) * DiskH;
      DrawDisk(K, Cx, Y);
      Inc(N);
    End;
  { disque souleve au-dessus de sa tige }
  If (Held = P) And (TopDisk(P) <> 0) Then DrawDisk(TopDisk(P), Cx, BY0 + 40);
  { numero et curseur du clavier }
  If Cur = P Then
  Begin
    FBar(Cx - 14, BY0 + BaseY + 24, Cx + 13, BY0 + BaseY + 43, CLR_YELLOW);
    OutTxt(Cx - 4, BY0 + BaseY + 26, IStr(P), CLR_BLACK, CLR_YELLOW);
  End
  Else OutTxt(Cx - 4, BY0 + BaseY + 26, IStr(P), CLR_WHITE, CLR_DARKCYAN);
End;

Procedure DrawBoard;
Var P : LongInt;
Begin
  FBar(BX0, BY0, BX0 + AW - 1, BY0 + AH - 1, CLR_DARKCYAN);
  { socle }
  FBar(BX0 + 8, BY0 + BaseY, BX0 + AW - 9, BY0 + BaseY + 17, CLR_BROWN);
  FBar(BX0 + 8, BY0 + BaseY, BX0 + AW - 9, BY0 + BaseY + 1, CLR_YELLOW);
  FBar(BX0 + 8, BY0 + BaseY + 16, BX0 + AW - 9, BY0 + BaseY + 17, CLR_DARKRED);
  FBar(BX0 + 8, BY0 + BaseY, BX0 + 9, BY0 + BaseY + 17, CLR_YELLOW);
  FBar(BX0 + AW - 10, BY0 + BaseY, BX0 + AW - 9, BY0 + BaseY + 17, CLR_DARKRED);
  For P := 1 To 3 Do DrawPeg(P);
End;

Procedure Button(X, Y, W, H : LongInt; S : String);
Begin
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
  Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  OutTxt(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure DrawPanel;
Begin
  BigText(PnX + (PW - 5 * 16) Div 2, 10, 'HANOI', CLR_DARKRED, CLR_PALEGRAY);
  OutTxt(PnX + (PW - 13 * 8) Div 2, 44, 'Tours d''Hanoi', CLR_DARKGRAY, CLR_PALEGRAY);
  FBar(PnX, 66, PnX + PW - 1, 150, CLR_PALEGRAY);
  OutTxt(PnX, 68, 'Disques : ' + IStr(NDisk), CLR_BLACK, CLR_PALEGRAY);
  OutTxt(PnX, 86, 'Coups : ' + IStr(Moves), CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(PnX, 104, 'Minimum : ' + IStr(MinMoves), CLR_BLACK, CLR_PALEGRAY);
  If BestD[NDisk] > 0 Then OutTxt(PnX, 122, 'Record : ' + IStr(BestD[NDisk]), CLR_DARKGREEN, CLR_PALEGRAY);
  Button(PnX, 160, PW, 28, 'Recommencer');
  Button(PnX, 194, PW, 28, 'Annuler');
  Button(PnX, 228, PW, 28, 'Solution');
  Button(PnX, 262, 68, 28, 'Disque -');
  Button(PnX + 72, 262, 68, 28, 'Disque +');
  OutTxt(PnX, 300, '1 2 3 : prendre', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 316, '  puis poser', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 332, 'Ctrl+Z : annuler', CLR_DARKGRAY, CLR_PALEGRAY);
  OutTxt(PnX, 348, 'F3 : solution', CLR_DARKGRAY, CLR_PALEGRAY);
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
  Edge(BX0 - 2, BY0 - 2, BX0 + AW + 1, BY0 + AH + 1, CLR_DARKGRAY, CLR_WHITE);
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
Var K : LongInt;
Begin
  For K := 3 To MaxD Do SetMark(CM_D3 + K - 3, K = NDisk);
End;

Procedure Restart(N : LongInt);
Var K : LongInt;
Begin
  If N < 3 Then N := 3;
  If N > MaxD Then N := MaxD;
  NDisk := N;
  For K := 1 To NDisk Do DPeg[K] := 2;
  Held := 0; Cur := 2; Moves := 0; NHist := 0; Solving := 0; Done := 0;
  Msg := 'D' + Chr(130) + 'placez les ' + IStr(N) + ' disques de la tige 2 vers la tige 1 ou 3 (au moins ' +
         IStr(MinMoves) + ' coups).';
  If Frame <> 0 Then SetMarks;
  Redraw;
End;

Procedure CheckWin;
Var S : String;
Begin
  If Not Solved Then Exit;
  Done := 1; Held := 0;
  If Solving = 0 Then
    If (BestD[NDisk] = 0) Or (Moves < BestD[NDisk]) Then BestD[NDisk] := Moves;
  Solving := 0;
  Msg := 'F' + Chr(130) + 'licitations - il t''a fallu ' + IStr(Moves) + ' coups (minimum : ' + IStr(MinMoves) + ').';
  Redraw;
  If Moves = MinMoves Then S := Msg + Chr(10) + 'Parfait : le nombre minimum de coups !' Else S := Msg;
  If Ask(S + Chr(10) + Chr(10) + 'Nouvelle partie ?', 'Tours de Hanoi', MB_YESNO Or MB_QUERY) = MBID_YES Then
    Restart(NDisk);
End;

{ prendre ou poser sur la tige P (souris, 1 2 3, curseur) }
Procedure PickPeg(P : LongInt);
Begin
  If (P < 1) Or (P > 3) Then Exit;
  Cur := P;
  If Solving <> 0 Then
  Begin
    Solving := 0;
    Msg := 'Solution interrompue.';
  End;
  If Done <> 0 Then
  Begin
    Redraw;
    Exit;
  End;
  If Held = 0 Then
  Begin
    If TopDisk(P) = 0 Then
    Begin
      Dummy := WinAlarm(HWND_DESKTOP, 0);
      Msg := 'La tige ' + IStr(P) + ' est vide.';
    End
    Else
    Begin
      Held := P;
      Msg := 'Disque ' + IStr(TopDisk(P)) + ' pris sur la tige ' + IStr(P) + ' : o' + Chr(151) +
             ' le poser (1, 2 ou 3) ?';
    End;
  End
  Else If Held = P Then
  Begin
    Held := 0;
    Msg := 'Disque repos' + Chr(130) + '.';
  End
  Else If CanMove(Held, P) Then
  Begin
    DoMove(Held, P);
    Held := 0;
    Msg := 'Coup ' + IStr(Moves) + '.';
    Redraw;
    CheckWin;
    Exit;
  End
  Else
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Msg := 'Coup ill' + Chr(130) + 'gal : un disque ne se pose pas sur un plus petit. Recommencez.';
  End;
  Redraw;
End;

Procedure Undo;
Begin
  Solving := 0; Held := 0;
  If (NHist = 0) Or (Done <> 0) Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 0);
    Exit;
  End;
  Dec(NHist);
  DPeg[TopDisk(HistT[NHist])] := HistF[NHist];
  Dec(Moves);
  Msg := 'Coup annul' + Chr(130) + ' (' + IStr(Moves) + ' coups).';
  Redraw;
End;

Procedure StartSolve;
Begin
  If Done <> 0 Then Restart(NDisk);
  Held := 0; Solving := 1;
  Msg := 'Solution vers la tige ' + IStr(Goal) + ' (une touche l''arr' + Chr(136) + 'te).';
  Redraw;
End;

Procedure TimerTick;
Var M : LongInt;
Begin
  If Solving = 0 Then Exit;
  M := NextMv(NDisk, Goal);
  If M = 0 Then
  Begin
    Solving := 0;
    Exit;
  End;
  DoMove(M Div 10, M Mod 10);
  Cur := M Mod 10;
  Msg := 'Solution : coup ' + IStr(Moves) + ', disque ' + IStr(TopDisk(M Mod 10)) + ' de la tige ' + IStr(M Div 10) +
         ' vers la tige ' + IStr(M Mod 10) + '.';
  Redraw;
  If Solved Then
  Begin
    Done := 1; Solving := 0;
    Msg := 'Solution termin' + Chr(130) + 'e en ' + IStr(Moves) + ' coups (minimum : ' + IStr(MinMoves) + ').';
    Redraw;
  End;
End;

Procedure Command(Id : LongInt);
Begin
  If (Id >= CM_D3) And (Id <= CM_D3 + MaxD - 3) Then
  Begin
    Restart(Id - CM_D3 + 3);
    Exit;
  End;
  Case Id Of
    CM_RESTART : Restart(NDisk);
    CM_UNDO : Undo;
    CM_SOLVE : StartSolve;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_RULES :
      Begin
        LClr;
        LAdd('Les disques sont empil' + Chr(130) + 's sur la tige 2. D' + Chr(130) + 'placez toute la pile ' +
             'sur la tige 1 ou sur la tige 3, un disque ' + Chr(133) + ' la fois (celui du dessus), sans ' +
             'jamais poser un disque sur un plus petit. ');
        LAdd('Il faut au moins 2^n - 1 coups : 127 pour 7 disques.' + Chr(10) + Chr(10));
        LAdd('Souris : cliquez une tige pour prendre son disque du dessus, puis une autre tige pour l''y ' +
             'poser (la m' + Chr(136) + 'me tige : le reposer).' + Chr(10));
        LAdd('Clavier : 1, 2, 3 (prendre puis poser, comme le De : et ' + Chr(133) + ' : du prototype), ' +
             'fl' + Chr(138) + 'ches et Espace (m' + Chr(136) + 'me chose avec le curseur), Ctrl+Z (annuler), ');
        LAdd('F2 (recommencer), F3 (solution anim' + Chr(130) + 'e depuis la position courante). Le menu Disques ' +
             'choisit 3 ' + Chr(133) + ' 8 disques.');
        Dummy := LMsgBox('Tours de Hanoi - R' + Chr(138) + 'gles', MB_OK Or MB_INFORMATION);
      End;
    CM_ABOUT : Dummy := Ask('Tours de Hanoi pour OS/2-0 (Presentation Manager), port' + Chr(130) + ' du prototype ' +
                            'HANOIS.PAS de 7iles (2011, mode texte).' + Chr(10) +
                            'Programme ' + Chr(130) + 'crit en Pascal et compil' + Chr(130) + ' par OS2PC.',
                            'A propos de Tours de Hanoi', MB_OK Or MB_INFORMATION);
  End;
End;

{ ==================================================================== }
{ Souris et clavier                                                     }
{ ==================================================================== }

Procedure Click(Mx, My : LongInt);
Var X, Y, P : LongInt;
Begin
  X := Mx; Y := CH - 1 - My;
  If (X >= BX0) And (X < BX0 + AW) And (Y >= BY0) And (Y < BY0 + AH) Then
  Begin
    P := (X - BX0 - PegX0 + PegSp Div 2) Div PegSp + 1;
    If X - BX0 - PegX0 + PegSp Div 2 < 0 Then P := 1;
    If P > 3 Then P := 3;
    PickPeg(P);
    Exit;
  End;
  If (X >= PnX) And (X < PnX + PW) Then
  Begin
    If (Y >= 160) And (Y < 188) Then Command(CM_RESTART)
    Else If (Y >= 194) And (Y < 222) Then Command(CM_UNDO)
    Else If (Y >= 228) And (Y < 256) Then Command(CM_SOLVE)
    Else If (Y >= 262) And (Y < 290) Then
    Begin
      If X < PnX + 70 Then
      Begin
        If NDisk > 3 Then Restart(NDisk - 1) Else Dummy := WinAlarm(HWND_DESKTOP, 0);
      End
      Else If NDisk < MaxD Then Restart(NDisk + 1) Else Dummy := WinAlarm(HWND_DESKTOP, 0);
    End;
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
    If Vk = VK_F2 Then Begin Command(CM_RESTART); Exit; End;
    If Vk = VK_F3 Then Begin Command(CM_SOLVE); Exit; End;
    If Vk = VK_BACKSPACE Then Begin Undo; Exit; End;
    If Vk = VK_LEFT Then
    Begin
      If Cur > 1 Then Dec(Cur) Else Cur := 3;
      Redraw;
      Exit;
    End;
    If Vk = VK_RIGHT Then
    Begin
      If Cur < 3 Then Inc(Cur) Else Cur := 1;
      Redraw;
      Exit;
    End;
    If (Vk = VK_SPACE) Or (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Or (Vk = VK_UP) Or (Vk = VK_DOWN) Then
    Begin
      PickPeg(Cur);
      Exit;
    End;
    If Vk = VK_ESC Then
    Begin
      Solving := 0;
      If Held <> 0 Then
      Begin
        Held := 0;
        Msg := 'Disque repos' + Chr(130) + '.';
        Redraw;
      End;
      Exit;
    End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    If (Ch >= Ord('1')) And (Ch <= Ord('3')) Then
    Begin
      PickPeg(Ch - Ord('0'));
      Exit;
    End;
    If Ch = 32 Then
    Begin
      PickPeg(Cur);
      Exit;
    End;
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
  Fl, H0, H1, H2, H3, Sw, Sh, Fw, Fh, M, K, E, X, Y, Nd, Sv : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Msg := ''; Nd := 7; Sv := 0; Frame := 0;
  For K := 3 To MaxD Do BestD[K] := 0;
  Client := 0;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (Length(S) > 7) And ((Copy(S, 1, 7) = '/DISKS:') Or (Copy(S, 1, 7) = '/disks:')) Then
      Val(Copy(S, 8, 20), Nd, E);
    If (S = '/SOLVE') Or (S = '/solve') Then Sv := 1;
  End;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('HANOIS'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('HANOIS'), Z2('Tours de Hanoi'), 0, 0, 0,
                              LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Partie');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RESTART, '~Recommencer' + Chr(9) + 'F2');
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler le coup' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_SOLVE, '~Solution' + Chr(9) + 'F3');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Disques');
  H3 := MenuOpen;
  For K := 3 To MaxD Do MItem(MIS_TEXT, 0, CM_D3 + K - 3, '~' + IStr(K) + ' disques');
  MenuClose(H3, MaxD - 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, 'A~ide');
  H2 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_RULES, '~R' + Chr(138) + 'gles du jeu' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, '~A propos de Tours de Hanoi');
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
  Restart(Nd);
  If Sv <> 0 Then StartSolve;
  Dummy := WinStartTimer(Hab, Client, 1, 250);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
