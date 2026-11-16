{ CALC.PAS - Calculatrice d'OS/2-0 (Presentation Manager).

  Compilation : OS2PC CALC.PAS CALC.EXE

  Portage de la Calculatrice de Pasdows 95 (APPS/CALC.PAS, Win32) vers
  l'API d'OS/2 (PMWIN, PMGPI) et l'apparence de Warp 3 : fenetre standard
  a bordure de dialogue (titre, menu systeme, reduction, liste des
  fenetres), barre de menus PM (mnemoniques ~), boutons poussoirs en
  relief comme ceux de PMWIN (blanc, noir, gris fonce), affichage en creux
  comme une zone de saisie, boite A propos WinMessageBox et presse-papiers
  de PM (CF_TEXT). OS/2 Warp 3 n'avait pas de calculatrice : celle-ci est
  dans le dossier Productivite du dossier Systeme OS/2.

  Comme la Calculatrice de Pasdows 95 en mode Standard : affichage,
  indicateur de memoire, touches Retour arriere, CE et C, memoire (MC,
  MR, MS, M+), chiffres, virgule, +/-, les quatre operations, racine
  carree, pourcentage, inverse (1/x) et egal (repete la derniere
  operation). Chiffres et fonctions en bleu, operations et memoire en
  rouge (teintes foncees : lisibles sur le gris, meme en VGA 16 couleurs).

  Clavier : chiffres, virgule ou point, + - * /, Entree ou = (egal), @
  (racine carree), % , R (1/x), F9 (+/-), Retour arriere, Suppr (CE),
  Echap (C), Ctrl+L (MC), Ctrl+R (MR), Ctrl+M (MS), Ctrl+P (M+),
  Ctrl+C (Copier), Ctrl+V (Coller : le texte est tape touche par touche).

  Le separateur decimal suit le carnet Pays (OS2.INI, PM_National,
  sDecimal ; sinon DosQueryCtryInfo) et l'interface la variable LANGUAGE
  de CONFIG.SYS (FR, EN, GR, IT, SP). Calcul en double precision,
  affichage sur 15 chiffres significatifs (notation scientifique au-dela) ;
  les exceptions du coprocesseur sont masquees (un depassement donne un
  message, jamais une TRAP 0010). }

Program Calc;

Const
  WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
  WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $200; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_NEWLINE = $08; VK_ESC = $0F; VK_DELETE = $1B; VK_ENTER = $1E;
  VK_F9 = $28;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10;
  CLR_PALEGRAY = 15;
  DT_CENTER = $100; DT_RIGHT = $200; DT_VCENTER = $400;
  { touches : fonctions (identifiants des boutons et du clavier) }
  kBack = 20; kCE = 21; kC = 22; kMC = 23; kMR = 24; kMS = 25; kMP = 26;
  kDiv = 27; kMul = 28; kSub = 29; kAdd = 30; kEq = 31; kSqrt = 32;
  kPct = 33; kInv = 34; kNeg = 35; kDot = 36;
  { menus }
  idEdit = 100; idCopy = 101; idPaste = 102;
  idView = 110; idStd = 111; idSci = 112;
  idHelpM = 120; idHelp = 121; idAbout = 122;
  NBtn = 28;
  { zone client (coordonnees de la disposition : origine en haut a gauche) }
  CliW = 300; CliH = 228;

Type
  PByte = ^Byte;
  PLong = ^LongInt;

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
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCtryInfo(Cb, Pcc, Pci, PcbActual : LongInt) : LongInt; External 'DOSCALLS';

Var
  Hab, Hmq, Frame, Client, MenuHw, Lang, Dummy : LongInt;
  DecSep : Char;
  NameZ, NameZ2, TxtBuf : Array[0..511] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  { boutons (disposition : origine en haut a gauche) }
  BX, BY, BW, BH, BK, BC : Array[0..NBtn - 1] Of LongInt;
  BT : Array[0..NBtn - 1] Of String[6];
  Pressed, Hot : LongInt;
  { etat du calcul }
  Acc, Cur, MemV, LastVal : Double;
  Op, LastOp : LongInt;
  Entering, HaveLast, IsErr : Boolean;
  Disp : String;               { nombre en cours de saisie (sans le
                                 separateur final) }
  ErrMsg : String;
  CpuCw : Word;

{ ------------------------------------------------------- utilitaires }

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

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; C : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    C := RdB(A);
    While (C <> 0) And (Length(S) < 250) Do
    Begin
      S := S + Chr(C);
      Inc(A);
      C := RdB(A);
    End;
  End;
  GetZ := S;
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

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'a') And (S[K] <= 'z') Then S[K] := Chr(Ord(S[K]) - 32);
  UpStr := S;
End;

Function GetEnvS(N : String) : String;
Var P : LongInt;
Begin
  P := 0;
  If DosScanEnv(Z(N), LongInt(@P)) = 0 Then GetEnvS := GetZ(P) Else GetEnvS := '';
End;

{ langue (LANGUAGE de CONFIG.SYS) et separateur decimal (carnet Pays) }
Procedure LangInit;
Var S : String; Cc : Array[0..1] Of LongInt; Ci : Array[0..15] Of LongInt; N : LongInt;
    B : Array[0..63] Of Byte;
Begin
  S := UpStr(GetEnvS('LANGUAGE'));
  If (S <> '') And (S[1] = '"') Then Delete(S, 1, 1);
  S := Copy(S, 1, 2);
  If (S = '') Or (S = 'FR') Then Lang := 0
  Else If (S = 'GR') Or (S = 'DE') Then Lang := 2
  Else If S = 'IT' Then Lang := 3
  Else If (S = 'SP') Or (S = 'ES') Then Lang := 4
  Else Lang := 1;
  DecSep := ',';
  { carnet Pays - Parametres : OS2.INI, PM_National, sDecimal }
  B[0] := 0;
  Dummy := PrfQueryProfileString(-1, Z('PM_National'), Z2('sDecimal'), 0, LongInt(@B), 8);
  If (B[0] > 32) And (B[0] < 127) Then DecSep := Chr(B[0])
  Else
  Begin
    { pays du systeme (COUNTRY= de CONFIG.SYS) : COUNTRYINFO.szDecimal }
    Cc[0] := 0; Cc[1] := 0;
    FillChar(Ci, SizeOf(Ci), 0);
    N := 0;
    If DosQueryCtryInfo(44, LongInt(@Cc), LongInt(@Ci), LongInt(@N)) = 0 Then
      If (RdB(LongInt(@Ci) + 19) > 32) And (RdB(LongInt(@Ci) + 19) < 127) Then
        DecSep := Chr(RdB(LongInt(@Ci) + 19));
  End;
End;

{ Texte dans la langue courante (page de codes 850) }
Function L(Fr, En, De, It, Es : String) : String;
Begin
  Case Lang Of
    1 : L := En;
    2 : L := De;
    3 : L := It;
    4 : L := Es;
  Else
    L := Fr;
  End;
End;

Procedure Beep;
Begin
  Dummy := WinAlarm(HWND_DESKTOP, 2);
End;

{ ------------------------------------------------- nombres et texte }

{ Les N derniers chiffres de l'entier V (V >= 0, exact en double) }
Function Digits(V : Double; N : LongInt) : String;
Var S : String; Q, D : Double; I : LongInt;
Begin
  S := '';
  For I := 1 To N Do
  Begin
    Q := Int(V / 10);
    D := V - Q * 10;
    If D < 0 Then D := 0;
    If D > 9 Then D := 9;
    S := Chr(48 + Trunc(D + 0.5)) + S;
    V := Q;
  End;
  Digits := S;
End;

Function Pow10(N : LongInt) : Double;
Var R : Double; I : LongInt;
Begin
  R := 1;
  If N > 400 Then N := 400;
  If N < -400 Then N := -400;
  If N >= 0 Then
    For I := 1 To N Do R := R * 10
  Else
    For I := 1 To -N Do R := R / 10;
  Pow10 := R;
End;

Function StripZeros(S : String) : String;
Begin
  While (Length(S) > 0) And (S[Length(S)] = '0') Do Delete(S, Length(S), 1);
  StripZeros := S;
End;

{ valeur hors des limites (depassement, infini, NaN) }
Function BadNum(X : Double) : Boolean;
Begin
  BadNum := Not ((X <= 1E300) And (X >= -1E300));
End;

{ Nombre affiche comme la Calculatrice de Pasdows 95 : 15 chiffres
  significatifs, separateur decimal toujours present ("12,"), notation
  scientifique "1,5e+020" }
Function FmtNum(X : Double) : String;
Var Neg : Boolean; E, Dc, N : LongInt; M, V : Double; S, IP, FP, R : String;
Begin
  If X = 0 Then
  Begin
    FmtNum := '0' + DecSep;
    Exit;
  End;
  If BadNum(X) Then
  Begin
    FmtNum := '0' + DecSep;
    Exit;
  End;
  Neg := X < 0;
  X := Abs(X);
  { exposant decimal : 1 <= X / 10^E < 10 }
  M := X; E := 0;
  While M >= 10 Do
  Begin
    M := M / 10; Inc(E);
  End;
  While (M < 1) And (E > -400) Do
  Begin
    M := M * 10; Dec(E);
  End;
  If (E >= 15) Or (E < -15) Then
  Begin
    V := Int(M * 1E14 + 0.5);
    If V >= 1E15 Then
    Begin
      V := Int(V / 10 + 0.5); Inc(E);
    End;
    S := Digits(V, 15);
    R := S[1] + DecSep + StripZeros(Copy(S, 2, 14)) + 'e';
    If E < 0 Then R := R + '-' Else R := R + '+';
    S := Digits(Abs(E), 3);
    R := R + S;
  End
  Else
  Begin
    Dc := 14 - E;
    V := Int(X * Pow10(Dc) + 0.5);
    If V >= 1E15 Then
    Begin
      Dec(Dc);
      V := Int(X * Pow10(Dc) + 0.5);
    End;
    If Dc < 0 Then Dc := 0;
    N := Dc + 1;
    If N < 15 Then N := 15;
    S := Digits(V, N);
    IP := Copy(S, 1, N - Dc);
    FP := StripZeros(Copy(S, N - Dc + 1, Dc));
    While (Length(IP) > 1) And (IP[1] = '0') Do Delete(IP, 1, 1);
    R := IP + DecSep + FP;
  End;
  If Neg Then R := '-' + R;
  FmtNum := R;
End;

{ Valeur d'un texte de nombre (separateur '.' ou ',', exposant 'e') }
Function ParseNum(S : String) : Double;
Var I, E, ES : LongInt; V, F : Double; Neg, InFrac, Done : Boolean; C : Char;
Begin
  V := 0; F := 1; Neg := False; InFrac := False; E := 0; ES := 1; Done := False;
  I := 1;
  If (Length(S) > 0) And (S[1] = '-') Then
  Begin
    Neg := True; I := 2;
  End;
  While (I <= Length(S)) And Not Done Do
  Begin
    C := S[I];
    If (C >= '0') And (C <= '9') Then
    Begin
      If InFrac Then
      Begin
        F := F / 10;
        V := V + (Ord(C) - 48) * F;
      End
      Else V := V * 10 + (Ord(C) - 48);
    End
    Else If (C = '.') Or (C = ',') Then InFrac := True
    Else If (C = 'e') Or (C = 'E') Then
    Begin
      Inc(I);
      If (I <= Length(S)) And (S[I] = '-') Then ES := -1;
      If (I <= Length(S)) And ((S[I] = '-') Or (S[I] = '+')) Then Inc(I);
      While (I <= Length(S)) And (S[I] >= '0') And (S[I] <= '9') Do
      Begin
        If E < 1000 Then E := E * 10 + Ord(S[I]) - 48;
        Inc(I);
      End;
      V := V * Pow10(E * ES);
      Done := True;
    End;
    Inc(I);
  End;
  If Neg Then V := -V;
  ParseNum := V;
End;

{ Texte de l'affichage }
Function DispText : String;
Begin
  If IsErr Then DispText := ErrMsg
  Else If Entering Then
  Begin
    If Pos(DecSep, Disp) > 0 Then DispText := Disp
    Else DispText := Disp + DecSep;
  End
  Else DispText := FmtNum(Cur);
End;

Function CurVal : Double;
Begin
  If Entering Then CurVal := ParseNum(Disp) Else CurVal := Cur;
End;

{ ------------------------------------------------------------- calcul }

Procedure SetErr(M : String);
Begin
  IsErr := True; ErrMsg := M;
  Entering := False; Op := 0; HaveLast := False;
End;

Function DivZero : String;
Begin
  DivZero := L('Impossible de diviser par z'#130'ro.', 'Cannot divide by zero.',
               'Division durch Null nicht m'#148'glich.', 'Impossibile dividere per zero.',
               'No se puede dividir por cero.');
End;

Function OverMsg : String;
Begin
  OverMsg := L('D'#130'passement de capacit'#130'.', 'Overflow.', #154'berlauf.', 'Overflow.',
               'Desbordamiento.');
End;

Function Calc2(A : Double; O : LongInt; B : Double) : Double;
Var R : Double;
Begin
  R := 0;
  Case O Of
    kAdd : R := A + B;
    kSub : R := A - B;
    kMul : R := A * B;
    kDiv :
      If B = 0 Then SetErr(DivZero)
      Else R := A / B;
  End;
  If Not IsErr And BadNum(R) Then
  Begin
    SetErr(OverMsg);
    R := 0;
  End;
  Calc2 := R;
End;

Procedure Key(K : LongInt);
Var V : Double;
Begin
  If IsErr And (K <> kC) And (K <> kCE) Then
  Begin
    Beep;
    Exit;
  End;
  Case K Of
    0..9 :
    Begin
      If Not Entering Then
      Begin
        Disp := ''; Entering := True;
      End;
      If (Disp = '0') Or (Disp = '-0') Then Delete(Disp, Length(Disp), 1);
      If Length(Disp) < 32 Then Disp := Disp + Chr(48 + K)
      Else Beep;
      If Disp = '' Then Disp := '0';
    End;
    kDot :
    Begin
      If Not Entering Then
      Begin
        Disp := '0'; Entering := True;
      End;
      If Pos(DecSep, Disp) = 0 Then Disp := Disp + DecSep;
    End;
    kBack :
      If Entering Then
      Begin
        Delete(Disp, Length(Disp), 1);
        If (Disp = '') Or (Disp = '-') Then Disp := '0';
      End;
    kCE :
    Begin
      IsErr := False; Entering := False; Cur := 0;
    End;
    kC :
    Begin
      IsErr := False; Entering := False; Cur := 0; Acc := 0; Op := 0;
      HaveLast := False;
    End;
    kNeg :
      If Entering Then
      Begin
        If (Length(Disp) > 0) And (Disp[1] = '-') Then Delete(Disp, 1, 1)
        Else Disp := '-' + Disp;
      End
      Else Cur := -Cur;
    kAdd, kSub, kMul, kDiv :
    Begin
      V := CurVal;
      If (Op <> 0) And Entering Then Acc := Calc2(Acc, Op, V)
      Else If Op = 0 Then Acc := V;
      If Not IsErr Then
      Begin
        Cur := Acc; Op := K; Entering := False; HaveLast := False;
      End;
    End;
    kEq :
    Begin
      If Op <> 0 Then
      Begin
        V := CurVal;
        Cur := Calc2(Acc, Op, V);
        LastOp := Op; LastVal := V; HaveLast := True; Op := 0;
        Acc := Cur;
      End
      Else If HaveLast Then
      Begin
        Cur := Calc2(CurVal, LastOp, LastVal);
        Acc := Cur;
      End
      Else Cur := CurVal;
      Entering := False;
    End;
    kSqrt :
    Begin
      V := CurVal;
      If V < 0 Then SetErr(L('Entr'#130'e non valide pour la fonction.',
                             'Invalid input for function.',
                             'Ung'#129'ltige Eingabe f'#129'r die Funktion.',
                             'Input non valido per la funzione.',
                             'Entrada no v'#160'lida para la funci'#162'n.'))
      Else
      Begin
        Cur := Sqrt(V); Entering := False;
      End;
    End;
    kPct :
    Begin
      Cur := Acc * CurVal / 100; Entering := False;
    End;
    kInv :
    Begin
      V := CurVal;
      If V = 0 Then SetErr(DivZero)
      Else
      Begin
        Cur := 1 / V; Entering := False;
      End;
    End;
    kMC : MemV := 0;
    kMR :
    Begin
      Cur := MemV; Entering := False;
    End;
    kMS : MemV := CurVal;
    kMP : MemV := MemV + CurVal;
  End;
  { depassement (1/x d'un tres petit nombre, %, M+, valeur collee...) }
  If Not IsErr And (BadNum(Cur) Or BadNum(Acc) Or BadNum(CurVal)) Then
  Begin
    SetErr(OverMsg);
    Cur := 0; Acc := 0;
  End;
  If BadNum(MemV) Then MemV := 0;
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ Caractere tape (clavier ou Coller) -> touche ; -1 si aucune }
Function CharKey(C : LongInt) : LongInt;
Begin
  Case C Of
    48..57 : CharKey := C - 48;
    46, 44 : CharKey := kDot;          { . , }
    43 : CharKey := kAdd;              { + }
    45 : CharKey := kSub;              { - }
    42 : CharKey := kMul;              { * }
    47 : CharKey := kDiv;              { / }
    61, 13 : CharKey := kEq;           { = Entree }
    64 : CharKey := kSqrt;             { @ }
    37 : CharKey := kPct;              { % }
    82, 114 : CharKey := kInv;         { R r }
    8 : CharKey := kBack;
    27 : CharKey := kC;
    12 : CharKey := kMC;               { Ctrl+L }
    18 : CharKey := kMR;               { Ctrl+R }
    16 : CharKey := kMP;               { Ctrl+P }
  Else
    CharKey := -1;
  End;
End;

{ ------------------------------------------------------ presse-papiers }

Procedure CopyText;
Var S : String;
Begin
  S := DispText;
  If Not IsErr And (Length(S) > 0) And (S[Length(S)] = DecSep) Then
    Delete(S, Length(S), 1);
  PutZ(LongInt(@TxtBuf), S);
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    { CF_TEXT, CFI_POINTER : PM copie le texte }
    Dummy := WinSetClipbrdData(Hab, LongInt(@TxtBuf), 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
End;

Procedure PasteText;
Var S : String; A, I, K : LongInt;
Begin
  S := '';
  If WinOpenClipbrd(Hab) = 0 Then Exit;
  A := WinQueryClipbrdData(Hab, 1);
  If A <> 0 Then S := GetZ(A);
  Dummy := WinCloseClipbrd(Hab);
  For I := 1 To Length(S) Do
  Begin
    K := CharKey(Ord(S[I]));
    If (K >= 0) And (K <> kC) Then Key(K);
  End;
End;

{ ------------------------------------------------------------ dessin }

Procedure AddBtn(I, X, Y, W, K, C : LongInt; T : String);
Begin
  BX[I] := X; BY[I] := Y; BW[I] := W; BH[I] := 30; BK[I] := K;
  BC[I] := C; BT[I] := T;
End;

{ Disposition de la Calculatrice de Pasdows 95 (mode Standard), un peu
  plus large pour la police du systeme de PM (8 x 16) }
Procedure Layout;
Const
  Pad : Array[0..19] Of LongInt = (
    7, 8, 9, kDiv, kSqrt, 4, 5, 6, kMul, kPct,
    1, 2, 3, kSub, kInv, 0, kNeg, kDot, kAdd, kEq);
Var R, C, I, K, Col : LongInt; T : String;
Begin
  AddBtn(0, 62, 44, 71, kBack, CLR_DARKRED, L('Retour', 'Back', 'R'#129'ck', 'Canc', 'Retr'));
  AddBtn(1, 139, 44, 71, kCE, CLR_DARKRED, 'CE');
  AddBtn(2, 216, 44, 72, kC, CLR_DARKRED, 'C');
  AddBtn(3, 12, 82, 40, kMC, CLR_DARKRED, 'MC');
  AddBtn(4, 12, 118, 40, kMR, CLR_DARKRED, 'MR');
  AddBtn(5, 12, 154, 40, kMS, CLR_DARKRED, 'MS');
  AddBtn(6, 12, 190, 40, kMP, CLR_DARKRED, 'M+');
  I := 7;
  For R := 0 To 3 Do
    For C := 0 To 4 Do
    Begin
      K := Pad[R * 5 + C];
      Col := CLR_DARKBLUE;
      T := '';
      Case K Of
        0..9 : T := Chr(48 + K);
        kDiv : T := '/';
        kMul : T := '*';
        kSub : T := '-';
        kAdd : T := '+';
        kEq : T := '=';
        kSqrt : T := 'sqrt';
        kPct : T := '%';
        kInv : T := '1/x';
        kNeg : T := '+/-';
        kDot : T := DecSep;
      End;
      If (K = kDiv) Or (K = kMul) Or (K = kSub) Or (K = kAdd) Or (K = kEq) Then Col := CLR_DARKRED;
      AddBtn(I, 62 + C * 46, 82 + R * 36, 42, K, Col, T);
      Inc(I);
    End;
End;

{ ligne (coordonnees de la disposition : Y vers le bas) }
Procedure GLine(Hps, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := CliH - 1 - Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := CliH - 1 - Y2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

{ rectangle plein : X1..X2-1, Y1..Y2-1 (Y vers le bas) }
Procedure Fill(Hps, X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := X1; Rc[1] := CliH - Y2; Rc[2] := X2; Rc[3] := CliH - Y1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

{ cadre d'un pixel : haut et gauche Lt, bas et droite Dk (bornes incluses) }
Procedure Bevel(Hps, X1, Y1, X2, Y2, Lt, Dk : LongInt);
Begin
  GLine(Hps, X1, Y2, X1, Y1, Lt); GLine(Hps, X1, Y1, X2, Y1, Lt);
  GLine(Hps, X1 + 1, Y2, X2, Y2, Dk); GLine(Hps, X2, Y2, X2, Y1 + 1, Dk);
End;

{ champ en creux de PM (zone de saisie) }
Procedure Sunken(Hps, X1, Y1, X2, Y2 : LongInt);
Begin
  Bevel(Hps, X1, Y1, X2, Y2, CLR_DARKGRAY, CLR_WHITE);
  Bevel(Hps, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure DrawText(Hps, X1, Y1, X2, Y2 : LongInt; S : String; Fg, Bg, Fl : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X1; Rc[1] := CliH - Y2; Rc[2] := X2; Rc[3] := CliH - Y1;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, Fl);
End;

{ bouton poussoir de PM (comme ceux de PMWIN : blanc et noir a
  l'exterieur, gris fonce a l'interieur ; enfonce : inverse) }
Procedure DrawBtn(Hps, I : LongInt);
Var Dn : Boolean; D, X1, Y1, X2, Y2 : LongInt;
Begin
  Dn := (Pressed = I) And (Hot = I);
  X1 := BX[I]; Y1 := BY[I]; X2 := BX[I] + BW[I] - 1; Y2 := BY[I] + BH[I] - 1;
  Fill(Hps, X1, Y1, X2 + 1, Y2 + 1, CLR_PALEGRAY);
  If Dn Then
  Begin
    Bevel(Hps, X1, Y1, X2, Y2, CLR_BLACK, CLR_WHITE);
    Bevel(Hps, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, CLR_DARKGRAY, CLR_PALEGRAY);
  End
  Else
  Begin
    Bevel(Hps, X1, Y1, X2, Y2, CLR_WHITE, CLR_BLACK);
    Bevel(Hps, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, CLR_PALEGRAY, CLR_DARKGRAY);
  End;
  D := Ord(Dn);
  DrawText(Hps, X1 + 2 + D, Y1 + 2 + D, X2 - 1 + D, Y2 - 1 + D, BT[I], BC[I], CLR_PALEGRAY,
           DT_CENTER Or DT_VCENTER);
End;

Procedure Paint(H : LongInt);
Var Hps, I : LongInt; S : String;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  Fill(Hps, 0, 0, CliW, CliH, CLR_PALEGRAY);
  { affichage : zone de saisie en creux, texte aligne a droite }
  Fill(Hps, 12, 10, 288, 34, CLR_WHITE);
  Sunken(Hps, 10, 8, 289, 35);
  S := DispText;
  If Length(S) > 33 Then S := Copy(S, 1, 33);
  DrawText(Hps, 14, 10, 284, 34, S, CLR_BLACK, CLR_WHITE, DT_RIGHT Or DT_VCENTER);
  { indicateur de memoire }
  Fill(Hps, 14, 46, 50, 72, CLR_PALEGRAY);
  Sunken(Hps, 12, 44, 51, 73);
  If MemV <> 0 Then DrawText(Hps, 14, 46, 50, 72, 'M', CLR_BLACK, CLR_PALEGRAY, DT_CENTER Or DT_VCENTER);
  For I := 0 To NBtn - 1 Do DrawBtn(Hps, I);
  Dummy := WinEndPaint(Hps);
End;

Function HitBtn(X, Y : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To NBtn - 1 Do
    If (X >= BX[I]) And (X < BX[I] + BW[I]) And (Y >= BY[I]) And (Y < BY[I] + BH[I]) Then R := I;
  HitBtn := R;
End;

{ ------------------------------------------------------------- menus }

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

{ barre de menus de PM : Edition, Affichage, Aide }
Procedure BuildMenu;
Var H0, H1 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, idEdit, L('~Edition', '~Edit', '~Bearbeiten', '~Modifica', '~Edici'#162'n'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, idCopy, L('~Copier', '~Copy', '~Kopieren', '~Copia', '~Copiar') + Chr(9) + 'Ctrl+C');
  MItem(MIS_TEXT, 0, idPaste, L('C~oller', '~Paste', '~Einf'#129'gen', '~Incolla', '~Pegar') + Chr(9) + 'Ctrl+V');
  MenuClose(H1, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, idView, L('~Affichage', '~View', '~Ansicht', '~Visualizza', '~Ver'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, MIA_CHECKED, idStd, L('S~tandard', 'S~tandard', 'S~tandard', 'S~tandard', '~Est'#160'ndar'));
  MItem(MIS_TEXT, MIA_DISABLED, idSci, L('~Scientifique', '~Scientific', '~Wissenschaftlich', '~Scientifica',
        '~Cient'#161'fica'));
  MenuClose(H1, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, idHelpM, L('A~ide', '~Help', '~Hilfe', '~Guida', '~Ayuda'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, MIA_DISABLED, idHelp, L('~Index de l''aide', 'Help ~index', 'Hilfe~index', '~Indice della guida',
        #161'~ndice de ayuda'));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, idAbout, L('~A propos de la Calculatrice...', '~About Calculator...',
        #154'ber ~Rechner...', '~Informazioni su Calcolatrice...', '~Acerca de Calculadora...'));
  MenuClose(H1, 3);
  MenuClose(H0, 3);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Function AppName : String;
Begin
  AppName := L('Calculatrice', 'Calculator', 'Rechner', 'Calcolatrice', 'Calculadora');
End;

Procedure About;
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame,
                         Z(AppName + Chr(10) + 'OS/2-0 (Presentation Manager)' + Chr(10) +
                           L('Port'#130'e de Pasdows 95', 'Ported from Pasdows 95', 'Portiert von Pasdows 95',
                             'Portata da Pasdows 95', 'Portada de Pasdows 95') + Chr(10) +
                           'Copyright Gladir.com 2026'),
                         Z2(L('A propos de la Calculatrice', 'About Calculator', #154'ber Rechner',
                              'Informazioni su Calcolatrice', 'Acerca de Calculadora')),
                         0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

{ ------------------------------------------------- fenetre principale }

{ clavier : WM_CHAR de PM (mp1 : indicateurs KC_* ; mp2 : caractere et
  touche virtuelle) }
Function DoChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Vk, Ch, K : LongInt;
Begin
  DoChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then
  Begin
    DoChar := False;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
    Case Vk Of
      VK_DELETE : Begin Key(kCE); Exit; End;
      VK_F9 : Begin Key(kNeg); Exit; End;
      VK_BACKSPACE : Begin Key(kBack); Exit; End;
      VK_ESC : Begin Key(kC); Exit; End;
      VK_ENTER, VK_NEWLINE : Begin Key(kEq); Exit; End;
    End;
  If (Fl And KC_ALT) <> 0 Then
  Begin
    DoChar := False;
    Exit;
  End;
  If (Fl And KC_CTRL) <> 0 Then
  Begin
    { Ctrl+lettre : la lettre (PM) ou son code de controle }
    If (Ch >= 97) And (Ch <= 122) Then Ch := Ch - 96
    Else If (Ch >= 65) And (Ch <= 90) Then Ch := Ch - 64;
    Case Ch Of
      3 : CopyText;
      22 : PasteText;
      12 : Key(kMC);
      18 : Key(kMR);
      13 : Key(kMS);
      16 : Key(kMP);
    Else
      DoChar := False;
    End;
    Exit;
  End;
  If (Fl And KC_CHAR) = 0 Then
  Begin
    DoChar := False;
    Exit;
  End;
  K := CharKey(Ch);
  If K >= 0 Then Key(K) Else DoChar := False;
End;

Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, X, Y : LongInt;
Begin
  ClientProc := 0;
  Case Msg Of
    WM_PAINT : Paint(H);
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
    Begin
      Dummy := WinSetFocus(HWND_DESKTOP, H);
      X := S16(Mp1); Y := CliH - 1 - S16(Mp1 Shr 16);
      I := HitBtn(X, Y);
      If I >= 0 Then
      Begin
        Pressed := I; Hot := I;
        Dummy := WinSetCapture(HWND_DESKTOP, H);
        Dummy := WinInvalidateRect(H, 0, 0);
      End;
      ClientProc := 1;
    End;
    WM_MOUSEMOVE :
    Begin
      If Pressed >= 0 Then
      Begin
        X := S16(Mp1); Y := CliH - 1 - S16(Mp1 Shr 16);
        I := HitBtn(X, Y);
        If I <> Hot Then
        Begin
          Hot := I;
          Dummy := WinInvalidateRect(H, 0, 0);
        End;
      End;
      ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
    WM_BUTTON1UP :
    Begin
      If Pressed >= 0 Then
      Begin
        X := S16(Mp1); Y := CliH - 1 - S16(Mp1 Shr 16);
        I := Pressed;
        Pressed := -1; Hot := -1;
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        If HitBtn(X, Y) = I Then Key(BK[I])
        Else Dummy := WinInvalidateRect(H, 0, 0);
      End;
      ClientProc := 1;
    End;
    WM_CHAR :
      If DoChar(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_COMMAND :
      Case Lo16(Mp1) Of
        idCopy : CopyText;
        idPaste : PasteText;
        idAbout : About;
      End;
    WM_CLOSE : Dummy := WinPostMsg(H, $002A, 0, 0);
  Else
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, Sw, Sh, Fw, Fh, X, Y : LongInt;
  Rc, Rf : Array[0..3] Of LongInt;
  Qmsg : Array[0..7] Of LongInt;

BEGIN
  { exceptions du coprocesseur masquees : un depassement donne l'infini
    (verifie par BadNum), jamais une TRAP 0010 (VirtualBox : CR0.NE) }
  CpuCw := $037F;
  asm
    fldcw CpuCw
  end;
  LangInit;
  Pressed := -1; Hot := -1;
  Acc := 0; Cur := 0; MemV := 0; Op := 0; LastOp := 0; LastVal := 0;
  IsErr := False; Entering := False; HaveLast := False;
  Disp := '0'; ErrMsg := '';
  Layout;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('OS2CALC'), LongInt(@ClientProc), 0, 0);
  { fenetre de taille fixe : titre, menu systeme, reduction, liste des
    fenetres, bordure de dialogue }
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('OS2CALC'), Z2(AppName), 0, 0, 0,
                              LongInt(@Client));
  BuildMenu;
  { taille du cadre : zone client CliW x CliH + bordures, titre et menus }
  Dummy := WinSetWindowPos(Frame, 0, 0, 0, CliW + 40, CliH + 80, SWP_SIZE);
  Dummy := WinQueryWindowRect(Frame, LongInt(@Rf));
  Dummy := WinQueryWindowRect(Client, LongInt(@Rc));
  Fw := CliW + (Rf[2] - Rf[0]) - (Rc[2] - Rc[0]);
  Fh := CliH + (Rf[3] - Rf[1]) - (Rc[3] - Rc[1]);
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - Fw) Div 2; If X < 0 Then X := 0;
  Y := (Sh - Fh) Div 2; If Y < 0 Then Y := 0;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
