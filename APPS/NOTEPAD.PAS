{ NOTEPAD.PAS - Bloc-notes d'OS/2-0 (Presentation Manager).

  Compilation : OS2PC NOTEPAD.PAS NOTEPAD.EXE

  Portage du Bloc-notes de Pasdows 95 (KERNEL/VMM32.PAS, application
  integree au noyau de Pasdows) vers l'API d'OS/2 (PMWIN, PMGPI,
  DOSCALLS) et l'apparence de Warp 3. Les fenetres internes, la barre de
  menus dessinee, les boites Ouvrir et Enregistrer sous dessinees, la
  boite Rechercher dessinee, le presse-papiers et les boites de message
  du noyau de Pasdows sont remplaces par :
   - une fenetre standard de PM a bordure de taille (titre, menu
     systeme, reduction, agrandissement, liste des fenetres) avec ses
     barres de defilement de PM verticale et horizontale ;
   - la barre de menus de PM (Fichier, Edition, Recherche, Aide ;
     mnemoniques ~, raccourcis, choix grises a l'ouverture du menu) ;
   - des boites de dialogue de PM : Ouvrir et Enregistrer sous (champ du
     nom, repertoire, liste des repertoires et des fichiers, masque),
     Rechercher (champ de saisie, case Respecter la casse, boutons
     Suivant et Annuler) ;
   - WinMessageBox (A propos, question avant de fermer un texte modifie,
     erreurs) ;
   - le presse-papiers de PM (CF_TEXT).
  Comme le Bloc-notes de Pasdows 95 : texte jusqu'a 256 Ko (CR seul en
  memoire, CR LF dans les fichiers ; LF seul et Ctrl+Z acceptes a la
  lecture), selection a la souris ou avec Maj et les fleches, Annuler
  (un second Annuler retablit), Couper, Copier, Coller, Supprimer,
  Selectionner tout, Heure/Date (F5), Rechercher (Ctrl+F) et Suivant
  (F3), question "Voulez-vous enregistrer les modifications ?" avant
  Nouveau, Ouvrir et Quitter.

  Raccourcis : Ctrl+N, Ctrl+O, Ctrl+S, Ctrl+Z, Ctrl+X, Ctrl+C, Ctrl+V,
  Ctrl+A, Ctrl+F, F3, F5, Suppr ; NOTEPAD fichier ouvre un fichier.
  L'interface suit la variable LANGUAGE de CONFIG.SYS (FR, EN, GR, IT,
  SP). }

Program Notepad;

Const
  WM_CREATE = $0001; WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023;
  WM_CLOSE = $0029; WM_QUIT = $002A; WM_CONTROL = $0030; WM_VSCROLL = $0031; WM_HSCROLL = $0032;
  WM_INITMENU = $0033; WM_SETFOCUS = $000F;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
  WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_VERTSCROLL = $40; FCF_HORZSCROLL = $80; FCF_DLGBORDER = $200; FCF_TASKLIST = $800;
  FID_VERTSCROLL = $8006; FID_HORZSCROLL = $8007;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000;
  WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006; WC_LISTBOX = $FFFF0007;
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_DEFAULT = $0400;
  SS_TEXT = 1; DT_VCENTER = $0400;
  ES_AUTOSCROLL = 4; ES_MARGIN = 8;
  EM_SETTEXTLIMIT = $0143; EM_SETSEL = $0142;
  BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_DELETEALL = $016E;
  LN_SELECT = 1; LN_ENTER = 5;
  SBM_SETSCROLLBAR = $01A0; SBM_SETTHUMBSIZE = $01A6;
  SB_LINEUP = 1; SB_LINEDOWN = 2; SB_PAGEUP = 3; SB_PAGEDOWN = 4; SB_SLIDERTRACK = 5; SB_SLIDERPOSITION = 6;
  MM_SETITEMATTR = $0192;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_DISABLED = $4000;
  MB_OK = 0; MB_YESNOCANCEL = 5; MB_ICONQUESTION = $10; MB_WARNING = $20; MB_INFORMATION = $30;
  MB_MOVEABLE = $4000;
  MBID_YES = 6; MBID_NO = 7;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = $05; VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08; VK_ESC = $0F;
  VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_DELETE = $1B; VK_ENTER = $1E;
  VK_F3 = $22; VK_F5 = $24;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_DARKBLUE = 9; CLR_PALEGRAY = 15;
  { menus }
  idFile = 100; idNew = 101; idOpen = 102; idSave = 103; idSaveAs = 104; idExit = 105;
  idEdit = 110; idUndo = 111; idCut = 112; idCopy = 113; idPaste = 114; idDel = 115; idSelAll = 116;
  idTime = 117;
  idSearch = 120; idFind = 121; idFindNext = 122;
  idHelpM = 130; idAbout = 131;
  { boites de dialogue }
  ID_OK = 1; ID_CANCEL = 2; ID_EF = 20; ID_LIST = 21; ID_CASE = 22;
  NoteMax = 262144;
  ChW = 8; ChH = 16;

Type
  PByte = ^Byte;
  TBytes = Array[0..NoteMax + 15] Of Byte;
  PBytes = ^TBytes;

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinBeginPaint(H, Hps, P : LongInt) : LongInt; External 'PMWIN';
Function WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN';
Function WinFillRect(Hps, P, C : LongInt) : LongInt; External 'PMWIN';
Function WinDrawText(Hps, Cch, P, PR, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinInvalidateRect(H, P, Inc : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowPos(H, HB, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDir(Disk, PBuf, PLen : LongInt) : LongInt; External 'DOSCALLS';

Var
  Hab, Hmq, Frame, Client, MenuHw, Lang, Dummy : LongInt;
  NameZ, NameZ2, TxtBuf : Array[0..511] Of Byte;
  MenuT : Array[0..2047] Of Byte;
  MenuLen : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  { texte : Buf[0..Len-1], CR seul ; Cur curseur ; Sel ancre (-1 : aucune) ;
    Top debut de la premiere ligne montree, TopLn son numero ; Left
    premiere colonne montree ; NLines nombre de lignes }
  Buf, UndoB : PBytes;
  Len, Cur, Sel, Top, TopLn, Left, NLines, MaxCol : LongInt;
  UndoLen, UndoPos : LongInt;
  UndoOk, Group, Dirty, MouseDown : Boolean;
  NotePath : String;
  FindStr : String;
  FindCase : Boolean;
  CliW, CliH : LongInt;
  { boites de dialogue }
  DlgEnd : LongInt;
  DlgFr, DlgCl, DlgEf, DlgLb, DlgDl, DlgCk : LongInt;
  FdDir, FdMask, FdRes : String;
  FdSave : Boolean;
  FdN : LongInt;
  FdItem : Array[0..399] Of String[64];
  FindBuf : Array[0..4095] Of Byte;
  RdBuf : Array[0..8191] Of Byte;

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

Function MinL(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinL := A Else MinL := B;
End;

Function MaxL(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxL := A Else MaxL := B;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'a') And (S[K] <= 'z') Then S[K] := Chr(Ord(S[K]) - 32);
  UpStr := S;
End;

Function IStr(N : LongInt) : String;
Var S : String;
Begin
  Str(N, S);
  IStr := S;
End;

Function Pad2(N : LongInt) : String;
Begin
  If N < 10 Then Pad2 := '0' + IStr(N) Else Pad2 := IStr(N);
End;

Function GetEnvS(N : String) : String;
Var P : LongInt;
Begin
  P := 0;
  If DosScanEnv(Z(N), LongInt(@P)) = 0 Then GetEnvS := GetZ(P) Else GetEnvS := '';
End;

Procedure LangInit;
Var S : String;
Begin
  S := UpStr(GetEnvS('LANGUAGE'));
  If (S <> '') And (S[1] = '"') Then Delete(S, 1, 1);
  S := Copy(S, 1, 2);
  If (S = '') Or (S = 'FR') Then Lang := 0
  Else If (S = 'GR') Or (S = 'DE') Then Lang := 2
  Else If S = 'IT' Then Lang := 3
  Else If (S = 'SP') Or (S = 'ES') Then Lang := 4
  Else Lang := 1;
End;

{ texte dans la langue courante (page de codes 850) }
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

Function AppName : String;
Begin
  AppName := L('Bloc-notes', 'Notepad', 'Editor', 'Blocco note', 'Bloc de notas');
End;

Function BaseName(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '\') And (S[K] <> ':') Do Dec(K);
  BaseName := Copy(S, K + 1, 255);
End;

Function DirOf(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '\') Do Dec(K);
  DirOf := Copy(S, 1, K);
End;

Function MsgBox(T : String; Fl : LongInt) : LongInt;
Var I : LongInt;
Begin
  For I := 1 To Length(T) Do If T[I] = '|' Then T[I] := Chr(10);
  MsgBox := WinMessageBox(HWND_DESKTOP, Frame, Z(T), Z2(AppName), 0, Fl Or MB_MOVEABLE);
End;

{ repertoire courant (X:\...\) }
Function CurDir : String;
Var D, Lg, N : LongInt; B : Array[0..259] Of Byte; S : String;
Begin
  D := 0; Lg := 0;
  Dummy := DosQueryCurrentDisk(LongInt(@D), LongInt(@Lg));
  If (D < 1) Or (D > 26) Then D := 3;
  N := 250; B[0] := 0;
  Dummy := DosQueryCurrentDir(0, LongInt(@B), LongInt(@N));
  S := Chr(Ord('A') + D - 1) + ':\' + GetZ(LongInt(@B));
  If S[Length(S)] <> '\' Then S := S + '\';
  CurDir := S;
End;

{ ---------------------------------------------------- texte (CR seul) }

Function LineStart(P : LongInt) : LongInt;
Begin
  While (P > 0) And (Buf^[P - 1] <> 13) Do Dec(P);
  LineStart := P;
End;

Function LineEnd(P : LongInt) : LongInt;
Begin
  While (P < Len) And (Buf^[P] <> 13) Do Inc(P);
  LineEnd := P;
End;

Function LineOf(P : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To P - 1 Do If Buf^[I] = 13 Then Inc(N);
  LineOf := N;
End;

{ nombre de lignes et ligne la plus longue (barres de defilement) }
Procedure Measure;
Var I, C : LongInt;
Begin
  NLines := 1; MaxCol := 0; C := 0;
  For I := 0 To Len - 1 Do
    If Buf^[I] = 13 Then
    Begin
      Inc(NLines);
      If C > MaxCol Then MaxCol := C;
      C := 0;
    End
    Else Inc(C);
  If C > MaxCol Then MaxCol := C;
End;

Function Rows : LongInt;
Begin
  Rows := MaxL(1, CliH Div ChH);
End;

Function Cols : LongInt;
Begin
  Cols := MaxL(1, (CliW - 4) Div ChW);
End;

Procedure SetTitle;
Var S : String;
Begin
  If NotePath = '' Then S := L('Sans titre', 'Untitled', 'Unbenannt', 'Senza nome', 'Sin t'#161'tulo')
  Else S := BaseName(NotePath);
  Dummy := WinSetWindowText(Frame, Z(S + ' - ' + AppName));
End;

Procedure UpdateBars;
Var H : LongInt;
Begin
  H := WinWindowFromID(Frame, FID_VERTSCROLL);
  If H <> 0 Then
  Begin
    Dummy := WinSendMsg(H, SBM_SETTHUMBSIZE, Rows Or (MaxL(NLines, 1) Shl 16), 0);
    Dummy := WinSendMsg(H, SBM_SETSCROLLBAR, TopLn, MaxL(0, NLines - 1) Shl 16);
    Dummy := WinEnableWindow(H, Ord(NLines > Rows));
  End;
  H := WinWindowFromID(Frame, FID_HORZSCROLL);
  If H <> 0 Then
  Begin
    Dummy := WinSendMsg(H, SBM_SETTHUMBSIZE, Cols Or (MaxL(MaxCol + 1, 1) Shl 16), 0);
    Dummy := WinSendMsg(H, SBM_SETSCROLLBAR, Left, MaxL(0, MaxCol) Shl 16);
    Dummy := WinEnableWindow(H, Ord(MaxCol >= Cols));
  End;
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ la premiere ligne montree devient la ligne N }
Procedure SetTopLine(N : LongInt);
Begin
  If N > NLines - 1 Then N := NLines - 1;
  If N < 0 Then N := 0;
  While TopLn < N Do
  Begin
    Top := LineEnd(Top) + 1;
    Inc(TopLn);
  End;
  While TopLn > N Do
  Begin
    Top := LineStart(Top - 1);
    Dec(TopLn);
  End;
End;

{ le curseur reste visible (lignes et colonnes) }
Procedure ShowCaret;
Var Ln, Col : LongInt;
Begin
  Ln := LineOf(Cur);
  If Ln < TopLn Then SetTopLine(Ln)
  Else If Ln >= TopLn + Rows Then SetTopLine(Ln - Rows + 1);
  Col := Cur - LineStart(Cur);
  If Col < Left Then Left := MaxL(0, Col - 8);
  If Col >= Left + Cols Then Left := Col - Cols + 8;
End;

Procedure Changed;
Begin
  Measure;
  If Top > Len Then Begin Top := 0; TopLn := 0; End;
  Top := LineStart(MinL(Top, Len));
  TopLn := LineOf(Top);
  ShowCaret;
  UpdateBars;
  Redraw;
End;

Procedure SelRange(Var A, B : LongInt);
Begin
  A := MinL(Sel, Cur); B := MaxL(Sel, Cur);
End;

{ copie pour Annuler (debut d'un groupe de modifications) }
Procedure Snap;
Begin
  If Group Then Exit;
  Move(Buf^, UndoB^, Len);
  UndoLen := Len; UndoPos := Cur;
  UndoOk := True;
End;

Procedure Undo;
Var I, T, N : LongInt;
Begin
  If Not UndoOk Then Exit;
  { echange : un second Annuler retablit }
  N := MaxL(UndoLen, Len);
  For I := 0 To N - 1 Do
  Begin
    T := Buf^[I]; Buf^[I] := UndoB^[I]; UndoB^[I] := T;
  End;
  T := Len; Len := UndoLen; UndoLen := T;
  T := Cur; Cur := MinL(UndoPos, Len); UndoPos := T;
  Sel := -1; Dirty := True; Group := False;
End;

{ supprimer la selection ; True s'il y en avait une }
Function DelSel : Boolean;
Var A, B : LongInt;
Begin
  DelSel := False;
  If Sel < 0 Then Exit;
  SelRange(A, B);
  Sel := -1;
  If A = B Then Exit;
  Move(Buf^[B], Buf^[A], Len - B);
  Len := Len - (B - A); Cur := A;
  Dirty := True;
  DelSel := True;
End;

{ inserer N octets de Src (texte CR LF : les LF sont retires) }
Procedure InsertText(Src, N : LongInt);
Var I, C : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    C := RdB(Src + I);
    If (C = 10) Or (C = 0) Then Continue;
    If Len >= NoteMax Then
    Begin
      Dummy := WinAlarm(HWND_DESKTOP, 2);
      Break;
    End;
    If Cur < Len Then Move(Buf^[Cur], Buf^[Cur + 1], Len - Cur);
    Buf^[Cur] := C;
    Inc(Len); Inc(Cur);
  End;
  Dirty := True;
End;

Procedure InsertStr(S : String);
Begin
  If S <> '' Then InsertText(LongInt(@S[1]), Length(S));
End;

{ ----------------------------------------------------- presse-papiers }

Procedure CopySel;
Var A, B, I, K, P : LongInt; T : PBytes;
Begin
  If Sel < 0 Then Exit;
  SelRange(A, B);
  If A = B Then Exit;
  GetMem(T, (B - A) * 2 + 16);
  K := 0;
  For I := A To B - 1 Do
  Begin
    T^[K] := Buf^[I]; Inc(K);
    If Buf^[I] = 13 Then Begin T^[K] := 10; Inc(K); End;
  End;
  T^[K] := 0;
  P := LongInt(T);
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(Hab);
    { CF_TEXT, CFI_POINTER : PM copie le texte }
    Dummy := WinSetClipbrdData(Hab, P, 1, $400);
    Dummy := WinCloseClipbrd(Hab);
  End;
  FreeMem(T, (B - A) * 2 + 16);
End;

Procedure Paste;
Var A, N : LongInt;
Begin
  If WinOpenClipbrd(Hab) = 0 Then Exit;
  A := WinQueryClipbrdData(Hab, 1);
  If A <> 0 Then
  Begin
    N := 0;
    While (N < NoteMax) And (RdB(A + N) <> 0) Do Inc(N);
    Group := False; Snap; Dummy := DelSel;
    InsertText(A, N);
  End;
  Dummy := WinCloseClipbrd(Hab);
End;

{ ---------------------------------------------------------- fichiers }

{ charger Path (vide : nouveau document) }
Procedure LoadFile(Path : String);
Var H, A, N, I, C : LongInt; CR : Boolean;
Begin
  Len := 0; Cur := 0; Sel := -1; Top := 0; TopLn := 0; Left := 0;
  Dirty := False; UndoOk := False; Group := False;
  NotePath := '';
  If Path <> '' Then
  Begin
    H := 0; A := 0;
    If DosOpen(Z(Path), LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) = 0 Then
    Begin
      CR := False;
      Repeat
        N := 0;
        If DosRead(H, LongInt(@RdBuf), SizeOf(RdBuf), LongInt(@N)) <> 0 Then N := 0;
        For I := 0 To N - 1 Do
        Begin
          If Len >= NoteMax Then Break;
          C := RdBuf[I];
          If C = 13 Then
          Begin
            Buf^[Len] := 13; Inc(Len); CR := True;
          End
          Else If C = 10 Then
          Begin
            If Not CR Then Begin Buf^[Len] := 13; Inc(Len); End;
            CR := False;
          End
          Else
          Begin
            If (C <> 26) And (C <> 0) Then Begin Buf^[Len] := C; Inc(Len); End;
            CR := False;
          End;
        End;
      Until N <= 0;
      Dummy := DosClose(H);
      NotePath := Path;
    End
    Else
      Dummy := MsgBox(L('Impossible d''ouvrir ', 'Cannot open ', 'Kann nicht '#148'ffnen: ',
                        'Impossibile aprire ', 'No se puede abrir ') + Path, MB_OK Or MB_WARNING);
  End;
  SetTitle;
  Changed;
End;

{ ecrire le texte dans Path (CR LF) ; False si impossible }
Function WriteFile(Path : String) : Boolean;
Var H, A, W, I, K : LongInt; Ok : Boolean;
Begin
  Ok := False;
  H := 0; A := 0;
  If DosOpen(Z(Path), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) = 0 Then
  Begin
    Ok := True; K := 0;
    For I := 0 To Len - 1 Do
    Begin
      RdBuf[K] := Buf^[I]; Inc(K);
      If Buf^[I] = 13 Then Begin RdBuf[K] := 10; Inc(K); End;
      If (K >= SizeOf(RdBuf) - 2) Or (I = Len - 1) Then
      Begin
        W := 0;
        If (DosWrite(H, LongInt(@RdBuf), K, LongInt(@W)) <> 0) Or (W <> K) Then Ok := False;
        K := 0;
      End;
    End;
    Dummy := DosClose(H);
  End;
  WriteFile := Ok;
  If Ok Then
  Begin
    NotePath := Path;
    Dirty := False;
    SetTitle;
  End
  Else
    Dummy := MsgBox(L('Impossible d''enregistrer ', 'Cannot save ', 'Kann nicht speichern: ',
                      'Impossibile salvare ', 'No se puede guardar ') + Path +
                    L(' (le CD-ROM est en lecture seule).', ' (the CD-ROM is read-only).',
                      ' (CD-ROM schreibgesch'#129'tzt).', ' (CD-ROM di sola lettura).',
                      ' (el CD-ROM es de s'#162'lo lectura).'), MB_OK Or MB_WARNING);
End;

{ ------------------------------------------- boites de dialogue de PM }

{ boite modale : la fenetre principale est desactivee jusqu'a DlgEnd }
Function DlgOpen(Cls, Title : String; W, H : LongInt) : Boolean;
Var Fl, X, Y : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DlgCl := 0;
  DlgFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z(Cls), Z2(Title), 0, 0, 0, LongInt(@DlgCl));
  DlgOpen := DlgFr <> 0;
  If DlgFr = 0 Then Exit;
  Rc[0] := 0; Rc[1] := 0; Rc[2] := W; Rc[3] := H;
  Dummy := WinCalcFrameRect(DlgFr, LongInt(@Rc), 0);
  W := Rc[2] - Rc[0]; H := Rc[3] - Rc[1];
  X := MaxL(0, (WinQuerySysValue(HWND_DESKTOP, 20) - W) Div 2);
  Y := MaxL(0, (WinQuerySysValue(HWND_DESKTOP, 21) - H) Div 2);
  Dummy := WinSetWindowPos(DlgFr, HWND_TOP, X, Y, W, H, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
End;

Function DlgRun(Focus : LongInt) : LongInt;
Begin
  Dummy := WinEnableWindow(Frame, 0);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, DlgFr);
  If Focus <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Focus);
  DlgEnd := 0;
  While DlgEnd = 0 Do
    If WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) = 0 Then DlgEnd := ID_CANCEL
    Else Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  DlgRun := DlgEnd;
End;

Procedure DlgClose;
Begin
  Dummy := WinEnableWindow(Frame, 1);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  Dummy := WinDestroyWindow(DlgFr);
  DlgFr := 0;
End;

Function Ctl(Cls, Txt : LongInt; Style, X, Y, W, H, Id : LongInt) : LongInt;
Var C : LongInt;
Begin
  C := WinCreateWindow(DlgCl, Cls, Txt, Style Or WS_VISIBLE, X, Y, W, H, DlgCl, HWND_TOP, Id, 0, 0);
  Ctl := C;
End;

Procedure Gray(H : LongInt);
Var C : LongInt;
Begin
  C := CLR_PALEGRAY;
  Dummy := WinSetPresParam(H, 4, 4, LongInt(@C));
End;

Function CtlText(H : LongInt) : String;
Var N : LongInt; B : Array[0..259] Of Byte; S : String;
Begin
  N := WinQueryWindowText(H, 250, LongInt(@B));
  S := '';
  While (Length(S) < N) And (B[Length(S)] <> 0) Do S := S + Chr(B[Length(S)]);
  CtlText := S;
End;

{ touches communes : Entree = OK, Echap = Annuler }
Function DlgKey(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk : LongInt;
Begin
  Fl := Lo16(Mp1); Vk := Hi16(Mp2);
  DlgKey := 1;
  If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
    Dummy := WinPostMsg(H, WM_COMMAND, ID_OK, 0)
  Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then DlgEnd := ID_CANCEL
  Else DlgKey := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

Procedure DlgPaint(H : LongInt);
Var Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  Dummy := WinEndPaint(Hps);
End;

{ --- Ouvrir et Enregistrer sous --- }

Function FdMatch(N, M : String) : Boolean;
Var I, J, SI, SJ : LongInt;
Begin
  N := UpStr(N); M := UpStr(M);
  I := 1; J := 1; SI := 0; SJ := 0;
  While I <= Length(N) Do
  Begin
    If (J <= Length(M)) And ((M[J] = '?') Or (M[J] = N[I])) Then Begin Inc(I); Inc(J); End
    Else If (J <= Length(M)) And (M[J] = '*') Then Begin SJ := J; SI := I; Inc(J); End
    Else If SJ > 0 Then Begin J := SJ + 1; Inc(SI); I := SI; End
    Else Begin FdMatch := False; Exit; End;
  End;
  While (J <= Length(M)) And (M[J] = '*') Do Inc(J);
  FdMatch := J > Length(M);
End;

Procedure FdAdd(S : String);
Begin
  If FdN > 399 Then Exit;
  FdItem[FdN] := S; Inc(FdN);
  Dummy := WinSendMsg(DlgLb, LM_INSERTITEM, -1, Z(S));
End;

{ repertoires puis fichiers du masque }
Procedure FdFill;
Var H, N, Rc, Off, A, K, Pass : LongInt; S : String;
Begin
  Dummy := WinSendMsg(DlgLb, LM_DELETEALL, 0, 0);
  FdN := 0;
  If Length(FdDir) > 3 Then FdAdd('[..]');
  For Pass := 1 To 2 Do
  Begin
    H := -1; N := 1;
    Rc := DosFindFirst(Z(FdDir + '*.*'), LongInt(@H), $37, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N), 1);
    While (Rc = 0) And (N > 0) Do
    Begin
      Off := 0;
      While N > 0 Do
      Begin
        A := RdB(LongInt(@FindBuf) + Off + 24);
        S := '';
        For K := 0 To RdB(LongInt(@FindBuf) + Off + 28) - 1 Do S := S + Chr(RdB(LongInt(@FindBuf) + Off + 29 + K));
        If (S <> '.') And (S <> '..') Then
        Begin
          If Pass = 1 Then
          Begin
            If (A And $10) <> 0 Then FdAdd('[' + S + ']');
          End
          Else If ((A And $10) = 0) And ((FdMask = '*.*') Or FdMatch(S, FdMask)) Then FdAdd(S);
        End;
        Dec(N);
        K := RdB(LongInt(@FindBuf) + Off) Or (RdB(LongInt(@FindBuf) + Off + 1) Shl 8);
        If K = 0 Then N := 0 Else Off := Off + K;
      End;
      N := 1;
      Rc := DosFindNext(H, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N));
    End;
    If H <> -1 Then Dummy := DosFindClose(H);
  End;
  Dummy := WinSetWindowText(DlgDl, Z(FdDir + FdMask));
End;

Procedure FdEnter(D : String);
Var K : LongInt;
Begin
  If D = '..' Then
  Begin
    K := Length(FdDir) - 1;
    While (K > 0) And (FdDir[K] <> '\') Do Dec(K);
    If K > 0 Then FdDir := Copy(FdDir, 1, K);
  End
  Else FdDir := FdDir + D + '\';
  FdFill;
End;

{ choix du nom S (champ ou liste) : True si la boite est finie }
Function FdChoose(S : String) : Boolean;
Var H, N, A : LongInt;
Begin
  FdChoose := False;
  While (S <> '') And (S[1] = ' ') Do Delete(S, 1, 1);
  While (S <> '') And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
  If S = '' Then Exit;
  If (S[1] = '[') And (S[Length(S)] = ']') Then
  Begin
    FdEnter(Copy(S, 2, Length(S) - 2));
    Exit;
  End;
  If (Pos('*', S) > 0) Or (Pos('?', S) > 0) Then
  Begin
    FdMask := S; FdFill;
    Exit;
  End;
  If (Length(S) = 2) And (S[2] = ':') Then S := S + '\';
  If (Pos(':', S) = 0) And (S[1] <> '\') Then S := FdDir + S
  Else If S[1] = '\' Then S := Copy(FdDir, 1, 2) + S;
  If S[Length(S)] = '\' Then
  Begin
    FdDir := S; FdFill;
    Exit;
  End;
  { repertoire existant : on y entre }
  H := -1; N := 1;
  If DosFindFirst(Z(S), LongInt(@H), $37, LongInt(@FindBuf), SizeOf(FindBuf), LongInt(@N), 1) = 0 Then
  Begin
    A := RdB(LongInt(@FindBuf) + 24);
    Dummy := DosFindClose(H);
    If (A And $10) <> 0 Then
    Begin
      FdDir := S + '\'; FdFill;
      Exit;
    End;
  End;
  FdRes := S;
  FdChoose := True;
End;

Function FileProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I : LongInt;
Begin
  FileProc := 0;
  Case Msg Of
    WM_PAINT : DlgPaint(H);
    WM_CONTROL :
      If Lo16(Mp1) = ID_LIST Then
      Begin
        I := WinSendMsg(DlgLb, LM_QUERYSELECTION, -1, 0);
        If (I >= 0) And (I < FdN) Then
        Begin
          If Hi16(Mp1) = LN_ENTER Then
          Begin
            If FdChoose(FdItem[I]) Then DlgEnd := ID_OK;
          End
          Else If Hi16(Mp1) = LN_SELECT Then
            If FdItem[I][1] <> '[' Then Dummy := WinSetWindowText(DlgEf, Z(FdItem[I]));
        End;
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_OK Then
      Begin
        If FdChoose(CtlText(DlgEf)) Then DlgEnd := ID_OK;
      End
      Else If Lo16(Mp1) = ID_CANCEL Then DlgEnd := ID_CANCEL;
    WM_CHAR : FileProc := DlgKey(H, Msg, Mp1, Mp2);
    WM_CLOSE : DlgEnd := ID_CANCEL;
  Else
    FileProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ boite Ouvrir (Save False) ou Enregistrer sous ; Name : nom propose,
  recoit le nom complet choisi }
Function FileDialog(Save : Boolean; Var Name : String) : Boolean;
Var W, H, C : LongInt; S, Title : String;
Begin
  FileDialog := False;
  W := 440; H := 330;
  If Save Then Title := L('Enregistrer sous', 'Save As', 'Speichern unter', 'Salva con nome', 'Guardar como')
  Else Title := L('Ouvrir', 'Open', #148'ffnen', 'Apri', 'Abrir');
  If Not DlgOpen('NPFILE', Title, W, H) Then Exit;
  C := Ctl(WC_STATIC, Z(L('Nom du fichier :', 'File name:', 'Dateiname:', 'Nome file:', 'Nombre:')),
           SS_TEXT Or DT_VCENTER, 10, H - 28, W - 20, 20, 10);
  Gray(C);
  DlgEf := Ctl(WC_ENTRYFIELD, 0, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 10, H - 52, W - 20, 20, ID_EF);
  Dummy := WinSendMsg(DlgEf, EM_SETTEXTLIMIT, 250, 0);
  C := Ctl(WC_STATIC, Z(L('R'#130'pertoire :', 'Folder:', 'Ordner:', 'Cartella:', 'Carpeta:')),
           SS_TEXT Or DT_VCENTER, 10, H - 78, 100, 20, 11);
  Gray(C);
  DlgDl := Ctl(WC_STATIC, 0, SS_TEXT Or DT_VCENTER, 110, H - 78, W - 120, 20, 12);
  Gray(DlgDl);
  DlgLb := Ctl(WC_LISTBOX, 0, WS_TABSTOP, 10, 44, W - 20, H - 44 - 86, ID_LIST);
  If Save Then S := L('Enregistrer', 'Save', 'Speichern', 'Salva', 'Guardar') Else S := L('Ouvrir', 'Open', #148'ffnen', 'Apri', 'Abrir');
  Dummy := Ctl(WC_BUTTON, Z(S), WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT, W - 208, 8, 96, 26, ID_OK);
  Dummy := Ctl(WC_BUTTON, Z(L('Annuler', 'Cancel', 'Abbrechen', 'Annulla', 'Cancelar')),
               WS_TABSTOP Or BS_PUSHBUTTON, W - 104, 8, 96, 26, ID_CANCEL);
  FdSave := Save;
  FdMask := '*.TXT';
  FdDir := DirOf(Name);
  If FdDir = '' Then FdDir := CurDir;
  S := BaseName(Name);
  FdFill;
  Dummy := WinSetWindowText(DlgEf, Z(S));
  Dummy := WinSendMsg(DlgEf, EM_SETSEL, Length(S) Shl 16, 0);
  FdRes := '';
  If DlgRun(DlgEf) = ID_OK Then
  Begin
    Name := FdRes;
    FileDialog := True;
  End;
  DlgClose;
End;

{ --- Rechercher --- }

Procedure FindNext(Quiet : Boolean);
Var I, K, N : LongInt; Ok : Boolean; C1, C2 : Char;
Begin
  If FindStr = '' Then Exit;
  N := Length(FindStr);
  For I := Cur To Len - N Do
  Begin
    Ok := True;
    For K := 1 To N Do
    Begin
      C1 := Chr(Buf^[I + K - 1]); C2 := FindStr[K];
      If Not FindCase Then Begin C1 := UpCase(C1); C2 := UpCase(C2); End;
      If C1 <> C2 Then Begin Ok := False; Break; End;
    End;
    If Ok Then
    Begin
      Sel := I; Cur := I + N; Group := False;
      ShowCaret; UpdateBars; Redraw;
      Exit;
    End;
  End;
  If Not Quiet Then
    Dummy := MsgBox(L('Impossible de trouver '#174' ', 'Cannot find "', '"', 'Impossibile trovare "',
                      'No se encuentra "') + FindStr +
                    L(' '#175'.', '".', '" nicht gefunden.', '".', '".'), MB_OK Or MB_INFORMATION);
End;

Function FindProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  FindProc := 0;
  Case Msg Of
    WM_PAINT : DlgPaint(H);
    WM_COMMAND :
      If Lo16(Mp1) = ID_OK Then
      Begin
        FindStr := CtlText(DlgEf);
        FindCase := WinSendMsg(DlgCk, BM_QUERYCHECK, 0, 0) <> 0;
        FindNext(False);
        Dummy := WinSetFocus(HWND_DESKTOP, DlgEf);
      End
      Else If Lo16(Mp1) = ID_CANCEL Then DlgEnd := ID_CANCEL;
    WM_CHAR : FindProc := DlgKey(H, Msg, Mp1, Mp2);
    WM_CLOSE : DlgEnd := ID_CANCEL;
  Else
    FindProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Procedure FindDialog;
Var C, W, H : LongInt;
Begin
  W := 400; H := 90;
  If Not DlgOpen('NPFIND', L('Rechercher', 'Find', 'Suchen', 'Trova', 'Buscar'), W, H) Then Exit;
  C := Ctl(WC_STATIC, Z(L('Rechercher :', 'Find what:', 'Suchen nach:', 'Trova:', 'Buscar:')),
           SS_TEXT Or DT_VCENTER, 10, H - 32, 100, 20, 10);
  Gray(C);
  DlgEf := Ctl(WC_ENTRYFIELD, 0, WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN, 110, H - 32, W - 230, 20, ID_EF);
  Dummy := WinSendMsg(DlgEf, EM_SETTEXTLIMIT, 63, 0);
  Dummy := WinSetWindowText(DlgEf, Z(FindStr));
  Dummy := WinSendMsg(DlgEf, EM_SETSEL, Length(FindStr) Shl 16, 0);
  DlgCk := Ctl(WC_BUTTON, Z(L('Respecter la casse', 'Match case', 'Gro'#225'-/Kleinschreibung',
                                'Maiuscole/minuscole', 'Coincidir may'#163'sculas')),
               WS_TABSTOP Or BS_AUTOCHECKBOX, 10, 12, 220, 20, ID_CASE);
  Gray(DlgCk);
  Dummy := WinSendMsg(DlgCk, BM_SETCHECK, Ord(FindCase), 0);
  Dummy := Ctl(WC_BUTTON, Z(L('Suivant', 'Find Next', 'Weitersuchen', 'Successivo', 'Siguiente')),
               WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT, W - 110, H - 36, 100, 26, ID_OK);
  Dummy := Ctl(WC_BUTTON, Z(L('Annuler', 'Cancel', 'Abbrechen', 'Annulla', 'Cancelar')),
               WS_TABSTOP Or BS_PUSHBUTTON, W - 110, 8, 100, 26, ID_CANCEL);
  Dummy := DlgRun(DlgEf);
  DlgClose;
End;

{ ------------------------------------------------------- commandes }

{ question "enregistrer les modifications ?" ; True si on peut continuer }
Function AskSave : Boolean;
Var R : LongInt; S : String;
Begin
  AskSave := True;
  If Not Dirty Then Exit;
  If NotePath = '' Then S := L('Sans titre', 'Untitled', 'Unbenannt', 'Senza nome', 'Sin t'#161'tulo')
  Else S := BaseName(NotePath);
  R := MsgBox(L('Le texte du fichier ', 'The text in the ', 'Der Text in der Datei ', 'Il testo del file ',
                'El texto del archivo ') + S +
              L(' a '#130't'#130' modifi'#130'.|Voulez-vous enregistrer les modifications ?',
                ' file has changed.|Do you want to save the changes?',
                ' wurde ge'#132'ndert.|'#142'nderungen speichern?',
                ' '#138' stato modificato.|Salvare le modifiche?',
                ' ha cambiado.|'#168'Desea guardar los cambios?'), MB_YESNOCANCEL Or MB_ICONQUESTION);
  If R = MBID_YES Then
  Begin
    If NotePath = '' Then
    Begin
      S := CurDir + '*.TXT';
      If Not FileDialog(True, S) Then Begin AskSave := False; Exit; End;
      If (Pos('.', BaseName(S)) = 0) Then S := S + '.TXT';
      AskSave := WriteFile(S);
    End
    Else AskSave := WriteFile(NotePath);
  End
  Else If R <> MBID_NO Then AskSave := False;
End;

Procedure SaveAs;
Var S : String;
Begin
  If NotePath = '' Then S := CurDir + '*.TXT' Else S := NotePath;
  If FileDialog(True, S) Then
  Begin
    If Pos('.', BaseName(S)) = 0 Then S := S + '.TXT';
    Dummy := WriteFile(S);
  End;
End;

Procedure About;
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame,
    Z(AppName + Chr(10) + 'OS/2-0 (Presentation Manager)' + Chr(10) +
      L('Port'#130' de Pasdows 95', 'Ported from Pasdows 95', 'Portiert von Pasdows 95',
        'Portato da Pasdows 95', 'Portado de Pasdows 95') + Chr(10) + 'Copyright (C) 2026 Gladir.com'),
    Z2(L('A propos du Bloc-notes', 'About Notepad', #154'ber Editor', 'Informazioni su Blocco note',
         'Acerca del Bloc de notas')), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure TimeDate;
Var B : Array[0..15] Of Byte; T : String;
Begin
  FillChar(B, SizeOf(B), 0);
  Dummy := DosGetDateTime(LongInt(@B));
  T := Pad2(B[0]) + ':' + Pad2(B[1]) + ' ' + Pad2(B[4]) + '/' + Pad2(B[5]) + '/' + IStr(B[6] Or (B[7] Shl 8));
  Group := False; Snap; Dummy := DelSel;
  InsertStr(T);
End;

Procedure Command(Id : LongInt);
Var S : String;
Begin
  Case Id Of
    idNew : If AskSave Then LoadFile('');
    idOpen :
      If AskSave Then
      Begin
        If NotePath = '' Then S := CurDir + '*.TXT' Else S := DirOf(NotePath) + '*.TXT';
        If FileDialog(False, S) Then LoadFile(S);
      End;
    idSave : If NotePath = '' Then SaveAs Else Dummy := WriteFile(NotePath);
    idSaveAs : SaveAs;
    idExit : If AskSave Then Dummy := WinPostMsg(Client, WM_QUIT, 0, 0);
    idUndo : Undo;
    idCut : If Sel >= 0 Then Begin CopySel; Group := False; Snap; Dummy := DelSel; End;
    idCopy : CopySel;
    idPaste : Paste;
    idDel : Begin Group := False; Snap; If Not DelSel And (Cur < Len) Then
              Begin Move(Buf^[Cur + 1], Buf^[Cur], Len - Cur - 1); Dec(Len); Dirty := True; End; End;
    idSelAll : Begin Sel := 0; Cur := Len; End;
    idTime : TimeDate;
    idFind : FindDialog;
    idFindNext : If FindStr = '' Then FindDialog Else FindNext(False);
    idAbout : About;
  End;
  Changed;
End;

{ ---------------------------------------------------------- clavier }

Procedure DoKey(Fl, Ch, Vk : LongInt);
Var LS, LE, Col, Old, N : LongInt; Sh, Ctrl : Boolean;
Begin
  Sh := (Fl And KC_SHIFT) <> 0;
  Ctrl := (Fl And KC_CTRL) <> 0;
  If Ctrl And ((Fl And KC_CHAR) <> 0) Or Ctrl And (Ch > 0) And ((Fl And KC_VIRTUALKEY) = 0) Then
  Begin
    If (Ch >= 1) And (Ch <= 26) Then Ch := Ch + 64;
    Case UpCase(Chr(Ch)) Of
      'A' : Command(idSelAll);
      'C' : Command(idCopy);
      'X' : Command(idCut);
      'V' : Command(idPaste);
      'Z' : Command(idUndo);
      'N' : Command(idNew);
      'O' : Command(idOpen);
      'S' : Command(idSave);
      'F' : Command(idFind);
    End;
    Exit;
  End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_F3 Then Begin Command(idFindNext); Exit; End;
    If Vk = VK_F5 Then Begin Command(idTime); Exit; End;
    Old := Cur;
    Case Vk Of
      VK_LEFT, VK_RIGHT, VK_HOME, VK_END, VK_UP, VK_DOWN, VK_PAGEUP, VK_PAGEDOWN :
      Begin
        Case Vk Of
          VK_LEFT : If Cur > 0 Then Dec(Cur);
          VK_RIGHT : If Cur < Len Then Inc(Cur);
          VK_HOME : If Ctrl Then Cur := 0 Else Cur := LineStart(Cur);
          VK_END : If Ctrl Then Cur := Len Else Cur := LineEnd(Cur);
          VK_UP, VK_PAGEUP :
            For N := 1 To MaxL(1, (Ord(Vk = VK_PAGEUP) * (Rows - 1))) Do
            Begin
              LS := LineStart(Cur); Col := Cur - LS;
              If LS > 0 Then
              Begin
                LS := LineStart(LS - 1); LE := LineEnd(LS);
                Cur := MinL(LS + Col, LE);
              End;
            End;
        Else
          For N := 1 To MaxL(1, (Ord(Vk = VK_PAGEDOWN) * (Rows - 1))) Do
          Begin
            LS := LineStart(Cur); Col := Cur - LS;
            LE := LineEnd(Cur);
            If LE < Len Then
            Begin
              LS := LE + 1; LE := LineEnd(LS);
              Cur := MinL(LS + Col, LE);
            End;
          End;
        End;
        If Sh Then
        Begin
          If Sel < 0 Then Sel := Old;
        End
        Else Sel := -1;
        Group := False;
        ShowCaret; UpdateBars; Redraw;
        Exit;
      End;
      VK_DELETE :
      Begin
        Command(idDel);
        Exit;
      End;
      VK_BACKSPACE :
      Begin
        Snap; Group := True;
        If Not DelSel And (Cur > 0) Then
        Begin
          Move(Buf^[Cur], Buf^[Cur - 1], Len - Cur);
          Dec(Len); Dec(Cur);
          Dirty := True;
        End;
        Changed;
        Exit;
      End;
      VK_ENTER, VK_NEWLINE : Ch := 13;
      VK_TAB : Ch := 9;
    End;
  End;
  If (Ch = 13) Or (Ch = 9) Or ((Ch >= 32) And (Ch < 256)) Then
  Begin
    Snap;
    Dummy := DelSel;
    Group := True;
    InsertStr(Chr(Ch));
    Changed;
  End;
End;

{ ---------------------------------------------------------- dessin }

Procedure TextAt(Hps, X, Row : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CliH - (Row + 1) * ChH; Rc[2] := X + Length(S) * ChW; Rc[3] := CliH - Row * ChH;
  Dummy := WinFillRect(Hps, LongInt(@Rc), Bg);
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

Procedure Paint(H : LongInt);
Var Hps, R, P, E, Q, C, SA, SB, X, Cs, Ch : LongInt; Rc : Array[0..3] Of LongInt; S : String; InSel, NowSel : Boolean;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  CliW := Rc[2]; CliH := Rc[3];
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_WHITE);
  SA := -1; SB := -1;
  If Sel >= 0 Then SelRange(SA, SB);
  Cs := Cols;
  P := Top;
  For R := 0 To Rows Do
  Begin
    If P > Len Then Break;
    E := LineEnd(P);
    { morceaux de meme etat (selectionne ou non) }
    Q := P + Left; C := 0; S := ''; X := 2; InSel := (Q >= SA) And (Q < SB);
    While (Q < E) And (C < Cs + 1) Do
    Begin
      NowSel := (Q >= SA) And (Q < SB);
      If (NowSel <> InSel) Or (Length(S) >= 200) Then
      Begin
        If InSel Then TextAt(Hps, X, R, S, CLR_WHITE, CLR_DARKBLUE) Else TextAt(Hps, X, R, S, CLR_BLACK, CLR_WHITE);
        X := X + Length(S) * ChW; S := ''; InSel := NowSel;
      End;
      Ch := Buf^[Q];
      If Ch = 9 Then Ch := 32;
      If Ch < 32 Then Ch := 32;
      S := S + Chr(Ch);
      Inc(Q); Inc(C);
    End;
    If InSel Then TextAt(Hps, X, R, S, CLR_WHITE, CLR_DARKBLUE) Else TextAt(Hps, X, R, S, CLR_BLACK, CLR_WHITE);
    { fin de ligne selectionnee }
    If (E >= SA) And (E < SB) And (E - P - Left >= 0) And (E - P - Left <= Cs) Then
    Begin
      Rc[0] := 2 + (E - P - Left) * ChW; Rc[1] := CliH - (R + 1) * ChH; Rc[2] := Rc[0] + 4; Rc[3] := CliH - R * ChH;
      Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_DARKBLUE);
    End;
    { curseur }
    If (Cur >= P) And (Cur <= E) Then
    Begin
      C := Cur - P - Left;
      If (C >= 0) And (C <= Cs) Then
      Begin
        Rc[0] := 2 + C * ChW - 1; Rc[1] := CliH - (R + 1) * ChH + 1; Rc[2] := Rc[0] + 2; Rc[3] := CliH - R * ChH - 1;
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_BLACK);
      End;
    End;
    P := E + 1;
  End;
  Dummy := WinEndPaint(Hps);
End;

{ position du texte sous le point X, Y de la zone client }
Function Hit(X, Y : LongInt) : LongInt;
Var R, P, Col : LongInt;
Begin
  R := (CliH - 1 - Y) Div ChH;
  If R < 0 Then R := 0;
  P := Top;
  While (R > 0) And (LineEnd(P) < Len) Do
  Begin
    P := LineEnd(P) + 1;
    Dec(R);
  End;
  Col := (X - 2 + 4) Div ChW + Left;
  If Col < 0 Then Col := 0;
  Hit := MinL(P + Col, LineEnd(P));
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

Procedure BuildMenu;
Var H0, H1 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, idFile, L('~Fichier', '~File', '~Datei', '~File', '~Archivo'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, idNew, L('~Nouveau', '~New', '~Neu', '~Nuovo', '~Nuevo') + Chr(9) + 'Ctrl+N');
  MItem(MIS_TEXT, 0, idOpen, L('~Ouvrir...', '~Open...', #148'~ffnen...', '~Apri...', '~Abrir...') + Chr(9) + 'Ctrl+O');
  MItem(MIS_TEXT, 0, idSave, L('~Enregistrer', '~Save', '~Speichern', '~Salva', '~Guardar') + Chr(9) + 'Ctrl+S');
  MItem(MIS_TEXT, 0, idSaveAs, L('Enregistrer ~sous...', 'Save ~As...', 'Speichern ~unter...', 'Salva ~con nome...',
        'Guardar ~como...'));
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, idExit, L('~Quitter', 'E~xit', '~Beenden', '~Esci', '~Salir'));
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, idEdit, L('~Edition', '~Edit', '~Bearbeiten', '~Modifica', '~Edici'#162'n'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, idUndo, L('~Annuler', '~Undo', '~R'#129'ckg'#132'ngig', '~Annulla', '~Deshacer') + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, idCut, L('Co~uper', 'Cu~t', '~Ausschneiden', '~Taglia', 'Cor~tar') + Chr(9) + 'Ctrl+X');
  MItem(MIS_TEXT, 0, idCopy, L('~Copier', '~Copy', '~Kopieren', '~Copia', '~Copiar') + Chr(9) + 'Ctrl+C');
  MItem(MIS_TEXT, 0, idPaste, L('C~oller', '~Paste', '~Einf'#129'gen', '~Incolla', '~Pegar') + Chr(9) + 'Ctrl+V');
  MItem(MIS_TEXT, 0, idDel, L('~Supprimer', 'De~lete', '~L'#148'schen', '~Elimina', '~Eliminar') + Chr(9) + 'Suppr');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, idSelAll, L('S'#130'lectionner ~tout', 'Select ~All', 'Alles ~markieren', 'Seleziona ~tutto',
        'Seleccionar ~todo') + Chr(9) + 'Ctrl+A');
  MItem(MIS_TEXT, 0, idTime, L('~Heure/Date', 'Time/~Date', '~Uhrzeit/Datum', 'Ora/~Data', '~Hora y fecha') + Chr(9) + 'F5');
  MenuClose(H1, 9);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, idSearch, L('~Recherche', '~Search', '~Suchen', '~Cerca', '~Buscar'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, idFind, L('~Rechercher...', '~Find...', '~Suchen...', '~Trova...', '~Buscar...') + Chr(9) + 'Ctrl+F');
  MItem(MIS_TEXT, 0, idFindNext, L('~Suivant', 'Find ~Next', '~Weitersuchen', 'Tr~ova successivo', 'Buscar ~siguiente') +
        Chr(9) + 'F3');
  MenuClose(H1, 2);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, idHelpM, L('A~ide', '~Help', '~Hilfe', '~Guida', '~Ayuda'));
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, idAbout, L('~A propos du Bloc-notes...', '~About Notepad...', #154'ber ~Editor...',
        '~Informazioni su Blocco note...', '~Acerca del Bloc de notas...'));
  MenuClose(H1, 1);
  MenuClose(H0, 4);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

Procedure MenuGray(Id : LongInt; Off : Boolean);
Var V : LongInt;
Begin
  If Off Then V := MIA_DISABLED Else V := 0;
  Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or $10000, MIA_DISABLED Or (V Shl 16));
End;

{ ------------------------------------------------------ zone client }

Function ClientProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var X, Y, N : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  ClientProc := 0;
  Case Msg Of
    WM_PAINT : Paint(H);
    WM_SIZE :
    Begin
      Dummy := WinQueryWindowRect(H, LongInt(@Rc));
      CliW := Rc[2]; CliH := Rc[3];
      ShowCaret; UpdateBars; Redraw;
    End;
    WM_BUTTON1DOWN, WM_BUTTON1DBLCLK :
    Begin
      Dummy := WinSetFocus(HWND_DESKTOP, H);
      X := S16(Mp1); Y := S16(Mp1 Shr 16);
      Cur := Hit(X, Y); Sel := Cur; Group := False;
      MouseDown := True;
      Dummy := WinSetCapture(HWND_DESKTOP, H);
      Redraw;
      ClientProc := 1;
    End;
    WM_MOUSEMOVE :
    Begin
      If MouseDown Then
      Begin
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        N := Hit(X, Y);
        If Y < 0 Then N := MinL(Len, LineEnd(N) + 1);
        If N <> Cur Then
        Begin
          Cur := N;
          ShowCaret; UpdateBars; Redraw;
        End;
      End;
      ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    End;
    WM_BUTTON1UP :
    Begin
      If MouseDown Then
      Begin
        MouseDown := False;
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        If Sel = Cur Then Sel := -1;
        Redraw;
      End;
      ClientProc := 1;
    End;
    WM_VSCROLL :
    Begin
      Case Hi16(Mp2) Of
        SB_LINEUP : SetTopLine(TopLn - 1);
        SB_LINEDOWN : SetTopLine(TopLn + 1);
        SB_PAGEUP : SetTopLine(TopLn - Rows + 1);
        SB_PAGEDOWN : SetTopLine(TopLn + Rows - 1);
        SB_SLIDERTRACK, SB_SLIDERPOSITION : SetTopLine(S16(Mp2));
      End;
      UpdateBars; Redraw;
    End;
    WM_HSCROLL :
    Begin
      Case Hi16(Mp2) Of
        SB_LINEUP : Dec(Left);
        SB_LINEDOWN : Inc(Left);
        SB_PAGEUP : Left := Left - Cols + 4;
        SB_PAGEDOWN : Left := Left + Cols - 4;
        SB_SLIDERTRACK, SB_SLIDERPOSITION : Left := S16(Mp2);
      End;
      If Left > MaxCol Then Left := MaxCol;
      If Left < 0 Then Left := 0;
      UpdateBars; Redraw;
    End;
    WM_CHAR :
    Begin
      If (Lo16(Mp1) And KC_KEYUP) = 0 Then
      Begin
        If ((Lo16(Mp1) And KC_ALT) <> 0) Then
        Begin
          ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
          Exit;
        End;
        DoKey(Lo16(Mp1), Lo16(Mp2) And 255, Hi16(Mp2));
      End;
      ClientProc := 1;
    End;
    WM_INITMENU :
      Case Lo16(Mp1) Of
        idEdit :
        Begin
          MenuGray(idUndo, Not UndoOk);
          MenuGray(idCut, Sel < 0);
          MenuGray(idCopy, Sel < 0);
        End;
        idSearch : MenuGray(idFindNext, FindStr = '');
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CLOSE : If AskSave Then Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    ClientProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, Sw, Sh, W, H, I : LongInt;
  Arg : String;

BEGIN
  LangInit;
  GetMem(Buf, SizeOf(TBytes));
  GetMem(UndoB, SizeOf(TBytes));
  Len := 0; Cur := 0; Sel := -1; Top := 0; TopLn := 0; Left := 0; NLines := 1; MaxCol := 0;
  FindStr := ''; FindCase := False; MouseDown := False; DlgFr := 0;
  CliW := 480; CliH := 320;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('OS2NOTEPAD'), LongInt(@ClientProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('NPFILE'), LongInt(@FileProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('NPFIND'), LongInt(@FindProc), 0, 0);
  { fenetre a bordure de taille, barres de defilement de PM }
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST Or
        FCF_VERTSCROLL Or FCF_HORZSCROLL;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('OS2NOTEPAD'), Z2(AppName), 0, 0, 0,
                              LongInt(@Client));
  BuildMenu;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  W := MinL(560, Sw); H := MinL(380, Sh);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, (Sw - W) Div 2, MaxL(0, (Sh - H) Div 2 + 20), W, H,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Arg := '';
  For I := 1 To ParamCount Do
  Begin
    If Arg <> '' Then Arg := Arg + ' ';
    Arg := Arg + ParamStr(I);
  End;
  If (Arg <> '') And (Arg[1] = '"') Then Arg := Copy(Arg, 2, Length(Arg) - 2);
  If (Arg <> '') And (Pos(':', Arg) = 0) And (Arg[1] <> '\') Then Arg := CurDir + Arg;
  LoadFile(Arg);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
