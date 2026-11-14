{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: DIGAUDIO - Audio numerique (Digital Audio) : lecteur et
                editeur de sons du Presentation Manager d'OS/2-0.
}

Program DIGAUDIO;

{$R-,S-,I-}

{ Compilation : OS2PC DIGAUDIO.PAS   (produit DIGAUDIO.EXE)

  L'application "Digital Audio" du multimedia d'OS/2 Warp (MMPM/2) :
  jouer, enregistrer et modifier des sons numeriques (fichiers WAV PCM).
  Elle passe par MDM.DLL (couche multimedia) et le pilote de la carte son
  (SBAUDIO.DLL, ICHAUDIO.DLL ou ESAUDIO.DLL).

  Fenetre (comme celle de Warp) :
    Informations d'edition : partie affichee (debut, fin) et selection
      (debut, fin : champs a fleches, pas de 0,1 s) ;
    boutons : debut, arret, pause, lecture, fin, enregistrement ;
    Position du media : position (champ a fleches), longueur, temps
      d'enregistrement disponible ; bouton du volume (- et +) ;
    Son : forme d'onde (cliquer : position ; glisser ou Maj+clic :
      selection), barre de defilement, curseur de lecture.
  Menus : Fichier (Nouveau, Ouvrir..., Enregistrer, Enregistrer sous...,
  Quitter), Edition (Annuler, Couper, Copier, Coller, Supprimer, Tout
  selectionner, Aucune selection), Affichage (zoom), Options (effets sur
  la selection ou tout le son : inverser, amplifier, attenuer, fondus,
  echo, silence), Controle (lecture, pause, arret, enregistrement, debut,
  fin), Type (11 025, 22 050, 44 100 Hz ; 8 ou 16 bits ; mono ou stereo :
  le son est converti), Aide.
  Clavier : Espace lecture/arret, Debut, Fin, fleches (Maj : selection),
  Suppr, Ctrl+X, C, V, Z, F1.
  Lecture : la selection, sinon de la position a la fin. Enregistrement :
  le son enregistre remplace la selection (ou s'insere a la position).
  Parametre : un fichier WAV a ouvrir. Capacite : 3 Mo de son (grands
  blocs de memoire de DosAllocMem). }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_CONTROL = $0030;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073; WM_CHAR = $007A;
  WM_FILEDONE = $1001;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $200; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3; HWND_BOTTOM = 4;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNOCANCEL = 3; MB_QUERY = $10; MB_WARNING = $20; MB_INFORMATION = $30; MB_ERROR = $40;
  MB_MOVEABLE = $4000; MBID_YES = 6; MBID_NO = 7;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_KEYUP = $40;
  VK_ESC = $0F; VK_SPACE = $10; VK_END = $13; VK_HOME = $14; VK_LEFT = $15; VK_RIGHT = $17; VK_DELETE = $1B;
  VK_NEWLINE = 8; VK_ENTER = $1E; VK_F1 = $20;
  WC_BUTTON = $FFFF0003; WC_ENTRYFIELD = $FFFF0006; WC_LISTBOX = $FFFF0007;
  BS_DEFAULT = $0400; ES_AUTOSCROLL = 4; ES_MARGIN = 8;
  LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_DELETEALL = $016E;
  LN_SELECT = 1; LN_ENTER = 5; EM_SETSEL = $0142;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12; CLR_DARKCYAN = 13;
  CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  { commandes }
  CM_NEW = 101; CM_OPEN = 102; CM_SAVE = 103; CM_SAVEAS = 104; CM_QUIT = 105;
  CM_UNDO = 201; CM_CUT = 202; CM_COPY = 203; CM_PASTE = 204; CM_DELETE = 205; CM_SELALL = 206; CM_SELNONE = 207;
  CM_ZOOMIN = 301; CM_ZOOMOUT = 302; CM_ZOOMALL = 303; CM_ZOOMSEL = 304;
  CM_REVERSE = 401; CM_LOUDER = 402; CM_SOFTER = 403; CM_FADEIN = 404; CM_FADEOUT = 405; CM_ECHO = 406;
  CM_SILENCE = 407;
  CM_PLAY = 501; CM_PAUSE = 502; CM_STOP = 503; CM_RECORD = 504; CM_HOME = 505; CM_END = 506;
  CM_R11 = 601; CM_R22 = 602; CM_R44 = 603; CM_B8 = 604; CM_B16 = 605; CM_MONO = 606; CM_STEREO = 607;
  CM_HELP = 701; CM_ABOUT = 702;
  ID_DLGENTRY = 801; ID_DLGLIST = 802; ID_DLGOK = 803; ID_DLGCANCEL = 804;
  CAP = 3145728;                    { capacite d'un son (octets) }
  NCOL = 640;
  { indicateur du bouton du volume (0, 10 ... 100) }
  KnobDX : Array[0..10] Of LongInt = (-12, -16, -17, -14, -8, 0, 8, 14, 17, 16, 12);
  KnobDY : Array[0..10] Of LongInt = (-12, -5, 3, 10, 15, 17, 15, 10, 3, -5, -12);
  { boutons de transport : gauche, droite (haut 14, bas 42) }
  BtnL : Array[0..5] Of LongInt = (196, 230, 264, 298, 344, 378);
  BtnR : Array[0..5] Of LongInt = (226, 260, 294, 340, 374, 408);

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH : LongInt;
  { son : tampon, longueur (octets), format }
  Snd, SndLen, Rate, Bits, Chans, FB : LongInt;
  UndoB, UndoLen, URate, UBits, UChans, HaveUndo : LongInt;
  ClipB, ClipLen, CRate, CBits, CChans : LongInt;
  RecB : LongInt;
  FileName : String;
  Modified : Boolean;
  { positions (trames) }
  CurPos, SelA, SelB, ViewA, ViewB : LongInt;
  { lecture, enregistrement }
  Playing, Recording, PausedF, PlayA, RecIns, RecDel, CardCaps : LongInt;
  CardName : String;
  Volume : LongInt;
  { souris }
  DragWave, DownBtn : LongInt;
  { zone a redessiner (colonnes), dernier curseur de lecture }
  UpdX1, UpdX2, LastCurX, TickN : LongInt;
  { a redessiner : 1 tout, 2 colonnes PendX1..PendX2 du curseur, 4 champ
    de la position }
  PendMask, PendX1, PendX2 : LongInt;
  { forme d'onde (cache par colonne) }
  ColMin, ColMax : Array[0..NCOL - 1] Of LongInt;
  CacheOk : Boolean;
  { boite Ouvrir / Enregistrer sous }
  DlgFrame, DlgClient, DlgEntry, DlgList, DlgSave, DlgN : LongInt;
  DlgDir, DlgResult : String;
  DlgItem : Array[0..199] Of String[40];
  NameZ, NameZ2, TxtBuf : Array[0..511] Of Byte;
  MenuT : Array[0..2047] Of Byte;
  MenuLen : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  Hdr : Array[0..63] Of Byte;

{ --- PMWIN.DLL, PMGPI.DLL, DOSCALLS.DLL, MDM.DLL --- }
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
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PMap : LongInt) : LongInt; External 'DOSCALLS';
Function MdmAudioInfo(PBuf, Len : LongInt) : LongInt; External 'MDM' Name 'MDMAUDIOINFO';
Function MdmPlay(PData, Bytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMPLAY';
Function MdmRecord(PData, MaxBytes, Rate, Bits, Ch : LongInt) : LongInt; External 'MDM' Name 'MDMRECORD';
Function MdmStop : LongInt; External 'MDM' Name 'MDMSTOP';
Function MdmPause(On : LongInt) : LongInt; External 'MDM' Name 'MDMPAUSE';
Function MdmPosition : LongInt; External 'MDM' Name 'MDMPOSITION';
Function MdmState : LongInt; External 'MDM' Name 'MDMSTATE';
Function MdmVolume(V : LongInt) : LongInt; External 'MDM' Name 'MDMVOLUME';
Function MciGetErrorString(Err, PBuf, Len : LongInt) : LongInt; External 'MDM' Name 'mciGetErrorString';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function RdB(A : LongInt) : LongInt;
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

Function RdL(A : LongInt) : LongInt;
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Procedure WrL(A, V : LongInt);
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Function RdW(A : LongInt) : LongInt;
Begin
  RdW := RdB(A) Or (RdB(A + 1) Shl 8);
End;

{ copie de N octets (zones qui peuvent se recouvrir) }
Procedure MoveMem(S, D, N : LongInt);
Begin
  If (N <= 0) Or (S = D) Then Exit;
  If (D < S) Or (D >= S + N) Then
  Begin
    asm
      push esi
      push edi
      mov esi,S
      mov edi,D
      mov ecx,N
      cld
      rep movsb
      pop edi
      pop esi
    end;
  End
  Else
  Begin
    asm
      push esi
      push edi
      mov esi,S
      add esi,N
      dec esi
      mov edi,D
      add edi,N
      dec edi
      mov ecx,N
      std
      rep movsb
      cld
      pop edi
      pop esi
    end;
  End;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := '';
  K := 0;
  While (K < 255) And (RdB(A + K) <> 0) Do
  Begin
    S := S + Chr(RdB(A + K));
    Inc(K);
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

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
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

Function Clamp(V, A, B : LongInt) : LongInt;
Begin
  If V < A Then V := A;
  If V > B Then V := B;
  Clamp := V;
End;

Function MulDiv(A, B, C : LongInt) : LongInt;
Begin
  If C <= 0 Then
  Begin
    MulDiv := 0;
    Exit;
  End;
  MulDiv := (A Div C) * B + ((A Mod C) * B) Div C;
End;

Function Frames : LongInt;
Begin
  Frames := SndLen Div FB;
End;

{ trames -> "m:ss.cc" }
Function TimeStr(Fr : LongInt) : String;
Var Cs, M, S : LongInt; T : String;
Begin
  Cs := MulDiv(MaxI(Fr, 0), 100, Rate);
  M := Cs Div 6000; S := (Cs Div 100) Mod 60; Cs := Cs Mod 100;
  T := IStr(M) + ':';
  If S < 10 Then T := T + '0';
  T := T + IStr(S) + '.';
  If Cs < 10 Then T := T + '0';
  TimeStr := T + IStr(Cs);
End;

Function ShowMsg(Text, Cap : String; Fl : LongInt) : LongInt;
Begin
  ShowMsg := WinMessageBox(HWND_DESKTOP, Frame, Z(Text), Z2(Cap), 0, Fl Or MB_MOVEABLE);
End;

Function BaseName(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '\') And (S[K] <> ':') Do Dec(K);
  BaseName := Copy(S, K + 1, 255);
End;

Procedure SetTitle;
Var T : String;
Begin
  If FileName = '' Then T := 'Sans titre' Else T := UpStr(BaseName(FileName));
  If Modified Then T := T + ' *';
  Dummy := WinSetWindowText(Frame, Z('Audio num'#130'rique - ' + T));
End;

{ ==================================================================== }
{ Dessin : primitives                                                   }
{ ==================================================================== }

Var
  Hps : LongInt;

{ coordonnees depuis le haut de la zone client }
Function YB(Yt : LongInt) : LongInt;
Begin
  YB := CH - 1 - Yt;
End;

Procedure GBoxT(X1, Yt1, X2, Yt2, C, Fl : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := YB(Yt2);
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := YB(Yt1);
  Dummy := GpiBox(Hps, Fl, LongInt(@P), 0, 0);
End;

Procedure LnT(X1, Yt1, X2, Yt2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := YB(Yt1);
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := YB(Yt2);
  Dummy := GpiLine(Hps, LongInt(@P));
End;

Procedure DiscT(X, Yt, R, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X - R; P[1] := YB(Yt + R);
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X + R; P[1] := YB(Yt - R);
  Dummy := GpiBox(Hps, DRO_FILL, LongInt(@P), 2 * R, 2 * R);
End;

Procedure CircleT(X, Yt, R, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X - R; P[1] := YB(Yt + R);
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X + R; P[1] := YB(Yt - R);
  Dummy := GpiBox(Hps, DRO_OUTLINE, LongInt(@P), 2 * R, 2 * R);
End;

Procedure TextT(X, Yt : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := YB(Yt + 15); Rc[2] := X + Length(S) * 8; Rc[3] := YB(Yt) + 1;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ relief : saillant (Up) ou enfonce }
Procedure Bevel(X1, Yt1, X2, Yt2 : LongInt; Up : Boolean);
Var A, B : LongInt;
Begin
  If Up Then
  Begin
    A := CLR_WHITE; B := CLR_DARKGRAY;
  End
  Else
  Begin
    A := CLR_DARKGRAY; B := CLR_WHITE;
  End;
  LnT(X1, Yt1, X2, Yt1, A); LnT(X1, Yt1, X1, Yt2, A);
  LnT(X1, Yt2, X2, Yt2, B); LnT(X2, Yt1, X2, Yt2, B);
End;

{ cadre grave avec un titre }
Procedure Group(X1, Yt1, X2, Yt2 : LongInt; T : String);
Begin
  GBoxT(X1 + 1, Yt1 + 8, X2 + 1, Yt2 + 1, CLR_WHITE, DRO_OUTLINE);
  GBoxT(X1, Yt1 + 7, X2, Yt2, CLR_DARKGRAY, DRO_OUTLINE);
  TextT(X1 + 8, Yt1, ' ' + T + ' ', CLR_DARKBLUE, CLR_PALEGRAY);
End;

{ triangle plein vers la droite (Dir 1) ou la gauche (-1), centre en Yt }
Procedure Tri(X, Yt, W, H, Dir, C : LongInt);
Var K, Hh : LongInt;
Begin
  For K := 0 To W - 1 Do
  Begin
    Hh := (H * (W - K)) Div W;
    If Dir > 0 Then LnT(X + K, Yt - Hh Div 2, X + K, Yt + Hh Div 2, C)
    Else LnT(X + W - 1 - K, Yt - Hh Div 2, X + W - 1 - K, Yt + Hh Div 2, C);
  End;
End;

{ champ de temps (fond jaune) a fleches }
Procedure TimeField(X, Yt, W : LongInt; S : String; Spin : Boolean);
Begin
  GBoxT(X, Yt, X + W, Yt + 18, CLR_YELLOW, DRO_FILL);
  Bevel(X, Yt, X + W, Yt + 18, False);
  TextT(X + 4, Yt + 2, S, CLR_BLACK, CLR_YELLOW);
  If Spin Then
  Begin
    GBoxT(X + W + 2, Yt, X + W + 13, Yt + 18, CLR_PALEGRAY, DRO_FILL);
    Bevel(X + W + 2, Yt, X + W + 13, Yt + 8, True);
    Bevel(X + W + 2, Yt + 10, X + W + 13, Yt + 18, True);
    { fleche haut et fleche bas }
    LnT(X + W + 7, Yt + 2, X + W + 7, Yt + 2, CLR_BLACK);
    LnT(X + W + 6, Yt + 3, X + W + 8, Yt + 3, CLR_BLACK);
    LnT(X + W + 5, Yt + 4, X + W + 9, Yt + 4, CLR_BLACK);
    LnT(X + W + 4, Yt + 5, X + W + 10, Yt + 5, CLR_BLACK);
    LnT(X + W + 4, Yt + 12, X + W + 10, Yt + 12, CLR_BLACK);
    LnT(X + W + 5, Yt + 13, X + W + 9, Yt + 13, CLR_BLACK);
    LnT(X + W + 6, Yt + 14, X + W + 8, Yt + 14, CLR_BLACK);
    LnT(X + W + 7, Yt + 15, X + W + 7, Yt + 15, CLR_BLACK);
  End;
End;

{ ==================================================================== }
{ Echantillons                                                          }
{ ==================================================================== }

{ echantillon (16 bits signes) du canal C de la trame I }
Function GetS(Buf, I, C : LongInt) : LongInt;
Var A, V : LongInt;
Begin
  If C >= Chans Then C := Chans - 1;
  A := Buf + I * FB;
  If Bits = 8 Then GetS := (RdB(A + C) - 128) * 256
  Else
  Begin
    V := RdW(A + C * 2);
    If V >= 32768 Then V := V - 65536;
    GetS := V;
  End;
End;

Procedure PutS(Buf, I, C, V : LongInt);
Var A : LongInt;
Begin
  V := Clamp(V, -32768, 32767);
  A := Buf + I * FB;
  If Bits = 8 Then WrB(A + C, (V + 32768) Shr 8) Else WrW(A + C * 2, V);
End;

Function MonoS(I : LongInt) : LongInt;
Begin
  If Chans = 2 Then MonoS := (GetS(Snd, I, 0) + GetS(Snd, I, 1)) Div 2 Else MonoS := GetS(Snd, I, 0);
End;

{ ==================================================================== }
{ Forme d'onde                                                          }
{ ==================================================================== }

Const
  WX1 = 14; WX2 = 466; WYT = 142;

Function WYB : LongInt;
Begin
  WYB := CH - 28;
End;

Function NCols : LongInt;
Begin
  NCols := WX2 - WX1;
End;

Function ColFrame(C : LongInt) : LongInt;
Begin
  ColFrame := ViewA + MulDiv(C, ViewB - ViewA, NCols);
End;

Function FrameCol(F : LongInt) : LongInt;
Begin
  If ViewB <= ViewA Then FrameCol := 0
  Else FrameCol := MulDiv(F - ViewA, NCols, ViewB - ViewA);
End;

Procedure BuildCache;
Var C, F0, F1, I, St, V, Mn, Mx : LongInt;
Begin
  For C := 0 To NCols - 1 Do
  Begin
    F0 := ColFrame(C); F1 := ColFrame(C + 1);
    If F1 <= F0 Then F1 := F0 + 1;
    Mn := 0; Mx := 0;
    If F0 < Frames Then
    Begin
      F1 := MinI(F1, Frames);
      St := (F1 - F0) Div 200 + 1;
      I := F0;
      Mn := 32767; Mx := -32768;
      While I < F1 Do
      Begin
        V := MonoS(I);
        If V < Mn Then Mn := V;
        If V > Mx Then Mx := V;
        I := I + St;
      End;
    End;
    ColMin[C] := Mn; ColMax[C] := Mx;
  End;
  CacheOk := True;
End;

Procedure Dirty;
Begin
  CacheOk := False;
  PendMask := PendMask Or 1;
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

Procedure Redraw;
Begin
  PendMask := PendMask Or 1;
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ partie affichee valable }
Procedure FixView;
Var N, W : LongInt;
Begin
  N := MaxI(Frames, 1);
  If (ViewB <= ViewA) Or (ViewB - ViewA > N) Then
  Begin
    ViewA := 0; ViewB := N;
  End;
  W := ViewB - ViewA;
  If W < 64 Then W := MinI(64, N);
  If ViewA < 0 Then ViewA := 0;
  If ViewA + W > N Then ViewA := MaxI(0, N - W);
  ViewB := ViewA + W;
End;

Function PlayFrame : LongInt;
Var P : LongInt;
Begin
  P := MdmPosition;
  If P < 0 Then P := 0;
  If Recording <> 0 Then PlayFrame := RecIns + P Div FB
  Else PlayFrame := PlayA + P Div FB;
End;

Procedure PaintWave;
Var C, Mid, Hh, Y1, Y2, S0, S1, X, Bg, Fg, P : LongInt;
Begin
  If Not CacheOk Then BuildCache;
  Mid := (WYT + WYB) Div 2; Hh := (WYB - WYT) Div 2 - 2;
  S0 := MinI(SelA, SelB); S1 := MaxI(SelA, SelB);
  For C := MaxI(0, UpdX1 - WX1 - 1) To MinI(NCols - 1, UpdX2 - WX1 + 1) Do
  Begin
    X := WX1 + C;
    If (S1 > S0) And (ColFrame(C + 1) > S0) And (ColFrame(C) < S1) Then
    Begin
      Bg := CLR_WHITE; Fg := CLR_BLUE;
    End
    Else
    Begin
      Bg := CLR_BLUE; Fg := CLR_WHITE;
    End;
    LnT(X, WYT, X, WYB, Bg);
    If ColFrame(C) < Frames Then
    Begin
      Y1 := Mid - (ColMax[C] * Hh) Div 32768;
      Y2 := Mid - (ColMin[C] * Hh) Div 32768;
      LnT(X, Y1, X, Y2, Fg);
    End;
  End;
  LnT(WX1, Mid, WX2 - 1, Mid, CLR_DARKBLUE);
  { position (jaune) et curseur de lecture (rouge) }
  If (CurPos >= ViewA) And (CurPos <= ViewB) Then
  Begin
    X := WX1 + FrameCol(CurPos);
    If X < WX2 Then LnT(X, WYT, X, WYB, CLR_YELLOW);
  End;
  { curseur de lecture : la colonne relevee par la minuterie }
  If ((Playing <> 0) Or (Recording <> 0)) And (LastCurX >= WX1) And (LastCurX < WX2) Then
    LnT(LastCurX, WYT, LastCurX, WYB, CLR_RED);
  Bevel(WX1 - 1, WYT - 1, WX2, WYB + 1, False);
  { barre de defilement }
  Y1 := WYB + 4; Y2 := WYB + 16;
  GBoxT(WX1, Y1, WX2 - 1, Y2, CLR_PALEGRAY, DRO_FILL);
  Bevel(WX1, Y1, WX2 - 1, Y2, False);
  GBoxT(WX1, Y1, WX1 + 13, Y2, CLR_PALEGRAY, DRO_FILL);
  Bevel(WX1, Y1, WX1 + 13, Y2, True);
  Tri(WX1 + 4, (Y1 + Y2) Div 2, 5, 8, -1, CLR_BLACK);
  GBoxT(WX2 - 14, Y1, WX2 - 1, Y2, CLR_PALEGRAY, DRO_FILL);
  Bevel(WX2 - 14, Y1, WX2 - 1, Y2, True);
  Tri(WX2 - 9, (Y1 + Y2) Div 2, 5, 8, 1, CLR_BLACK);
  If Frames > 0 Then
  Begin
    C := WX1 + 14 + MulDiv(ViewA, NCols - 28, Frames);
    X := WX1 + 14 + MulDiv(ViewB, NCols - 28, Frames);
    If X - C < 8 Then X := C + 8;
    If X > WX2 - 15 Then X := WX2 - 15;
    GBoxT(C, Y1 + 1, X, Y2 - 1, CLR_PALEGRAY, DRO_FILL);
    Bevel(C, Y1 + 1, X, Y2 - 1, True);
  End;
End;

{ ==================================================================== }
{ Dessin de la fenetre                                                  }
{ ==================================================================== }

Function ShownPos : LongInt;
Begin
  If (Playing <> 0) Or (Recording <> 0) Then ShownPos := PlayFrame Else ShownPos := CurPos;
End;

Function SoundLenShown : LongInt;
Var P : LongInt;
Begin
  If Recording <> 0 Then
  Begin
    P := MdmPosition;
    If P < 0 Then P := 0;
    SoundLenShown := Frames - RecDel + P Div FB;
  End
  Else SoundLenShown := Frames;
End;

Procedure PaintButtons;
Var K, Cy : LongInt; Down : Boolean;
Begin
  For K := 0 To 5 Do
  Begin
    Down := (DownBtn = K) Or ((K = 3) And (Playing <> 0) And (PausedF = 0)) Or ((K = 5) And (Recording <> 0)) Or
            ((K = 2) And (PausedF <> 0));
    GBoxT(BtnL[K], 14, BtnR[K], 42, CLR_PALEGRAY, DRO_FILL);
    GBoxT(BtnL[K] - 1, 13, BtnR[K] + 1, 43, CLR_BLACK, DRO_OUTLINE);
    Bevel(BtnL[K], 14, BtnR[K], 42, Not Down);
    Bevel(BtnL[K] + 1, 15, BtnR[K] - 1, 41, Not Down);
    Cy := 28;
    Case K Of
      0 :
        Begin
          GBoxT(BtnL[K] + 7, Cy - 5, BtnL[K] + 8, Cy + 5, CLR_BLACK, DRO_FILL);
          Tri(BtnL[K] + 9, Cy, 7, 11, -1, CLR_BLACK);
          Tri(BtnL[K] + 16, Cy, 7, 11, -1, CLR_BLACK);
        End;
      1 : GBoxT(BtnL[K] + 11, Cy - 4, BtnL[K] + 19, Cy + 4, CLR_BLACK, DRO_FILL);
      2 :
        Begin
          GBoxT(BtnL[K] + 10, Cy - 5, BtnL[K] + 12, Cy + 5, CLR_BLACK, DRO_FILL);
          GBoxT(BtnL[K] + 17, Cy - 5, BtnL[K] + 19, Cy + 5, CLR_BLACK, DRO_FILL);
        End;
      3 : Tri(BtnL[K] + 16, Cy, 11, 15, 1, CLR_BLACK);
      4 :
        Begin
          Tri(BtnL[K] + 6, Cy, 7, 11, 1, CLR_BLACK);
          Tri(BtnL[K] + 13, Cy, 7, 11, 1, CLR_BLACK);
          GBoxT(BtnL[K] + 21, Cy - 5, BtnL[K] + 22, Cy + 5, CLR_BLACK, DRO_FILL);
        End;
      5 :
        Begin
          DiscT(BtnL[K] + 15, Cy, 5, CLR_RED);
          CircleT(BtnL[K] + 15, Cy, 5, CLR_DARKRED);
        End;
    End;
  End;
End;

Procedure PaintKnob;
Var Cx, Cy, K : LongInt;
Begin
  Cx := 446; Cy := 38;
  DiscT(Cx, Cy, 24, CLR_DARKGRAY);
  DiscT(Cx - 1, Cy - 1, 22, CLR_WHITE);
  DiscT(Cx, Cy, 21, CLR_PALEGRAY);
  CircleT(Cx, Cy, 24, CLR_BLACK);
  For K := 0 To 10 Do
    LnT(Cx + (KnobDX[K] * 26) Div 17, Cy - (KnobDY[K] * 26) Div 17, Cx + (KnobDX[K] * 29) Div 17,
        Cy - (KnobDY[K] * 29) Div 17, CLR_BLACK);
  K := Clamp((Volume + 5) Div 10, 0, 10);
  LnT(Cx, Cy, Cx + KnobDX[K], Cy - KnobDY[K], CLR_BLACK);
  LnT(Cx + 1, Cy, Cx + KnobDX[K] + 1, Cy - KnobDY[K], CLR_BLACK);
  DiscT(Cx + KnobDX[K], Cy - KnobDY[K], 2, CLR_DARKRED);
  { - et + }
  GBoxT(414, 66, 428, 80, CLR_PALEGRAY, DRO_FILL);
  Bevel(414, 66, 428, 80, True);
  LnT(417, 73, 425, 73, CLR_BLACK);
  GBoxT(464, 66, 478, 80, CLR_PALEGRAY, DRO_FILL);
  Bevel(464, 66, 478, 80, True);
  LnT(467, 73, 475, 73, CLR_BLACK);
  LnT(471, 69, 471, 77, CLR_BLACK);
  TextT(Cx - Length(IStr(Volume)) * 4, 84, IStr(Volume), CLR_DARKBLUE, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Var Rc : Array[0..3] Of LongInt; S0, S1, X, M : LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  M := PendMask;
  PendMask := 0;
  If (M <> 0) And ((M And 1) = 0) Then
  Begin
    { seulement le curseur de lecture et la position (PendMask 0 : la
      fenetre a ete decouverte, tout est redessine) }
    If (M And 2) <> 0 Then
    Begin
      UpdX1 := PendX1; UpdX2 := PendX2;
      PaintWave;
    End;
    If (M And 4) <> 0 Then
    Begin
      TimeField(202, 84, 60, TimeStr(ShownPos), False);
      GBoxT(284, 86, 344, 101, CLR_PALEGRAY, DRO_FILL);
      TextT(286, 86, TimeStr(SoundLenShown), CLR_DARKBLUE, CLR_PALEGRAY);
    End;
    Dummy := WinEndPaint(Hps);
    Exit;
  End;
  UpdX1 := 0; UpdX2 := CW;
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  { Informations d'edition }
  Group(6, 4, 186, 116, 'Infos d'''#130'dition');
  TextT(14, 22, 'Affichage', CLR_DARKBLUE, CLR_PALEGRAY);
  TextT(14, 40, TimeStr(ViewA), CLR_DARKBLUE, CLR_PALEGRAY);
  TextT(84, 40, '- ' + TimeStr(ViewB), CLR_DARKBLUE, CLR_PALEGRAY);
  TextT(14, 62, 'S'#130'lection', CLR_DARKBLUE, CLR_PALEGRAY);
  S0 := MinI(SelA, SelB); S1 := MaxI(SelA, SelB);
  TimeField(14, 82, 60, TimeStr(S0), True);
  TimeField(98, 82, 60, TimeStr(S1), True);
  { boutons de transport }
  PaintButtons;
  { Position du media }
  Group(196, 46, 408, 116, 'Position du m'#130'dia');
  X := 230;
  LnT(X - 8, 64, X + 8, 64, CLR_BLACK); LnT(X, 64, X, 76, CLR_BLACK);
  LnT(X - 4, 70, X + 4, 70, CLR_BLACK);
  X := 312;
  LnT(X - 12, 62, X - 12, 76, CLR_BLACK); LnT(X + 12, 62, X + 12, 76, CLR_BLACK);
  LnT(X - 11, 69, X + 11, 69, CLR_BLACK);
  Tri(X - 11, 69, 4, 7, -1, CLR_BLACK); Tri(X + 8, 69, 4, 7, 1, CLR_BLACK);
  X := 376;
  LnT(X - 12, 62, X - 12, 76, CLR_BLACK); LnT(X + 12, 62, X + 12, 76, CLR_BLACK);
  LnT(X - 11, 69, X + 11, 69, CLR_DARKRED);
  DiscT(X, 69, 3, CLR_RED);
  TimeField(202, 84, 60, TimeStr(ShownPos), True);
  TextT(286, 86, TimeStr(SoundLenShown), CLR_DARKBLUE, CLR_PALEGRAY);
  If (CardCaps And 2) <> 0 Then
    TextT(346, 86, TimeStr((CAP - SndLen) Div FB), CLR_DARKBLUE, CLR_PALEGRAY)
  Else TextT(346, 86, '-:--.--', CLR_DARKGRAY, CLR_PALEGRAY);
  { volume }
  PaintKnob;
  { Son }
  Group(6, 120, 474, CH - 6, 'Son');
  PaintWave;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Memoire et annulation                                                 }
{ ==================================================================== }

Function AllocBuf : LongInt;
Var P : LongInt;
Begin
  P := 0;
  If DosAllocMem(LongInt(@P), CAP, $13) <> 0 Then P := 0;
  AllocBuf := P;
End;

Procedure SaveUndo;
Begin
  If UndoB = 0 Then UndoB := AllocBuf;
  If UndoB = 0 Then Exit;
  MoveMem(Snd, UndoB, SndLen);
  UndoLen := SndLen; URate := Rate; UBits := Bits; UChans := Chans;
  HaveUndo := 1;
End;

Procedure SetFmt(R, B, C : LongInt);
Begin
  Rate := R; Bits := B; Chans := C;
  FB := (Bits Div 8) * Chans;
End;

Procedure Changed;
Begin
  Modified := True;
  SetTitle;
  CurPos := Clamp(CurPos, 0, Frames);
  SelA := Clamp(SelA, 0, Frames); SelB := Clamp(SelB, 0, Frames);
  FixView;
  Dirty;
End;

Procedure DoUndo;
Var T, L, R, B, C : LongInt;
Begin
  If HaveUndo = 0 Then Exit;
  { echange du son et de la copie : Annuler une seconde fois retablit }
  T := Snd; Snd := UndoB; UndoB := T;
  L := SndLen; R := Rate; B := Bits; C := Chans;
  SndLen := UndoLen; SetFmt(URate, UBits, UChans);
  UndoLen := L; URate := R; UBits := B; UChans := C;
  ViewA := 0; ViewB := 0;
  Changed;
End;

{ ==================================================================== }
{ Fichiers WAV                                                          }
{ ==================================================================== }

Function LoadWav(F : String) : String;
Var H, A, N, Id, Sz, P0, Fmt, Got, R, B, C : LongInt; HaveFmt : Boolean;
Begin
  LoadWav := 'Fichier introuvable : ' + F;
  H := 0; A := 0;
  If DosOpen(Z(F), LongInt(@H), LongInt(@A), 0, 0, $01, $40, 0) <> 0 Then Exit;
  LoadWav := 'Ce n''est pas un fichier WAV (PCM 8 ou 16 bits).';
  N := 0;
  If (DosRead(H, LongInt(@Hdr), 12, LongInt(@N)) <> 0) Or (N <> 12) Or (RdL(LongInt(@Hdr)) <> $46464952) Or
     (RdL(LongInt(@Hdr) + 8) <> $45564157) Then
  Begin
    Dummy := DosClose(H);
    Exit;
  End;
  P0 := 12; HaveFmt := False; R := 0; B := 0; C := 0;
  Repeat
    N := 0;
    If (DosRead(H, LongInt(@Hdr), 8, LongInt(@N)) <> 0) Or (N <> 8) Then
    Begin
      Dummy := DosClose(H);
      Exit;
    End;
    Id := RdL(LongInt(@Hdr)); Sz := RdL(LongInt(@Hdr) + 4);
    P0 := P0 + 8;
    If Id = $20746D66 Then
    Begin
      Dummy := DosRead(H, LongInt(@Hdr) + 8, 16, LongInt(@N));
      Fmt := RdW(LongInt(@Hdr) + 8); C := RdW(LongInt(@Hdr) + 10);
      R := RdL(LongInt(@Hdr) + 12); B := RdW(LongInt(@Hdr) + 22);
      If (Fmt <> 1) Or ((B <> 8) And (B <> 16)) Or (C < 1) Or (C > 2) Or (R < 1000) Then
      Begin
        Dummy := DosClose(H);
        Exit;
      End;
      HaveFmt := True;
    End;
    If Id <> $61746164 Then
    Begin
      P0 := P0 + ((Sz + 1) And Not 1);
      Dummy := DosSetFilePtr(H, P0, 0, LongInt(@N));
    End;
  Until Id = $61746164;
  If Not HaveFmt Then
  Begin
    Dummy := DosClose(H);
    Exit;
  End;
  If Sz > CAP Then Sz := CAP;
  SaveUndo;
  Got := 0;
  Dummy := DosRead(H, Snd, Sz, LongInt(@Got));
  Dummy := DosClose(H);
  SetFmt(R, B, C);
  SndLen := Got - Got Mod FB;
  FileName := F;
  Modified := False;
  CurPos := 0; SelA := 0; SelB := 0; ViewA := 0; ViewB := 0;
  HaveUndo := 0;
  FixView;
  SetTitle;
  Dirty;
  LoadWav := '';
End;

Function SaveWav(F : String) : Boolean;
Var H, A, N : LongInt;
Begin
  SaveWav := False;
  H := 0; A := 0;
  If DosOpen(Z(F), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) <> 0 Then Exit;
  WrL(LongInt(@Hdr), $46464952); WrL(LongInt(@Hdr) + 4, 36 + SndLen);
  WrL(LongInt(@Hdr) + 8, $45564157); WrL(LongInt(@Hdr) + 12, $20746D66);
  WrL(LongInt(@Hdr) + 16, 16); WrW(LongInt(@Hdr) + 20, 1); WrW(LongInt(@Hdr) + 22, Chans);
  WrL(LongInt(@Hdr) + 24, Rate); WrL(LongInt(@Hdr) + 28, Rate * FB);
  WrW(LongInt(@Hdr) + 32, FB); WrW(LongInt(@Hdr) + 34, Bits);
  WrL(LongInt(@Hdr) + 36, $61746164); WrL(LongInt(@Hdr) + 40, SndLen);
  N := 0;
  Dummy := DosWrite(H, LongInt(@Hdr), 44, LongInt(@N));
  If SndLen > 0 Then Dummy := DosWrite(H, Snd, SndLen, LongInt(@N));
  Dummy := DosClose(H);
  FileName := F;
  Modified := False;
  SetTitle;
  SaveWav := True;
End;

{ ==================================================================== }
{ Lecture et enregistrement                                             }
{ ==================================================================== }

Procedure MdmError(R : LongInt);
Begin
  Dummy := MciGetErrorString(R, LongInt(@TxtBuf), 200);
  Dummy := ShowMsg(GetZ(LongInt(@TxtBuf)), 'Audio num'#130'rique', MB_OK Or MB_WARNING);
End;

Procedure StopRecording;
Var N, Nf : LongInt;
Begin
  N := MdmPosition;
  Dummy := MdmStop;
  Recording := 0; PausedF := 0;
  If N < 0 Then N := 0;
  N := N - N Mod FB;
  Nf := N Div FB;
  SaveUndo;
  { la selection est remplacee par le son enregistre }
  If RecDel > 0 Then
  Begin
    MoveMem(Snd + (RecIns + RecDel) * FB, Snd + RecIns * FB, SndLen - (RecIns + RecDel) * FB);
    SndLen := SndLen - RecDel * FB;
  End;
  If SndLen + N > CAP Then N := CAP - SndLen - (CAP - SndLen) Mod FB;
  MoveMem(Snd + RecIns * FB, Snd + RecIns * FB + N, SndLen - RecIns * FB);
  MoveMem(RecB, Snd + RecIns * FB, N);
  SndLen := SndLen + N;
  SelA := RecIns; SelB := RecIns + N Div FB; CurPos := SelB;
  ViewA := 0; ViewB := 0;
  Changed;
End;

Procedure StopAll;
Begin
  If Recording <> 0 Then StopRecording
  Else If Playing <> 0 Then
  Begin
    CurPos := Clamp(PlayFrame, 0, Frames);
    Dummy := MdmStop;
    Playing := 0; PausedF := 0;
    Dirty;
  End;
End;

Procedure StartPlay;
Var A, B, R : LongInt;
Begin
  If (Playing <> 0) Or (Recording <> 0) Then
  Begin
    StopAll;
    Exit;
  End;
  If Frames = 0 Then Exit;
  A := MinI(SelA, SelB); B := MaxI(SelA, SelB);
  If B <= A Then
  Begin
    A := CurPos; B := Frames;
    If A >= B Then A := 0;
  End;
  R := MdmPlay(Snd + A * FB, (B - A) * FB, Rate, Bits, Chans);
  If R <> 0 Then
  Begin
    MdmError(R);
    Exit;
  End;
  PlayA := A; Playing := 1; PausedF := 0; LastCurX := -1;
  Dirty;
End;

Procedure StartRecord;
Var R, Cap0 : LongInt;
Begin
  If (Playing <> 0) Or (Recording <> 0) Then StopAll;
  If CardCaps = 0 Then
  Begin
    MdmError(5053);
    Exit;
  End;
  If (CardCaps And 2) = 0 Then
  Begin
    Dummy := ShowMsg('Cette carte son ne peut pas enregistrer.', 'Audio num'#130'rique', MB_OK Or MB_WARNING);
    Exit;
  End;
  If RecB = 0 Then RecB := AllocBuf;
  If RecB = 0 Then
  Begin
    MdmError(5009);
    Exit;
  End;
  RecIns := MinI(SelA, SelB); RecDel := MaxI(SelA, SelB) - RecIns;
  If RecDel = 0 Then RecIns := CurPos;
  Cap0 := CAP - SndLen + RecDel * FB;
  Cap0 := Cap0 - Cap0 Mod FB;
  If Cap0 < FB * 100 Then
  Begin
    Dummy := ShowMsg('Le son est plein (3 Mo) : supprimez une partie avant d''enregistrer.', 'Audio num'#130'rique',
                     MB_OK Or MB_WARNING);
    Exit;
  End;
  R := MdmRecord(RecB, Cap0, Rate, Bits, Chans);
  If R <> 0 Then
  Begin
    MdmError(R);
    Exit;
  End;
  Recording := 1; PausedF := 0; LastCurX := -1;
  Dirty;
End;

Procedure TogglePause;
Begin
  If (Playing = 0) And (Recording = 0) Then Exit;
  If PausedF = 0 Then
  Begin
    Dummy := MdmPause(1);
    PausedF := 1;
  End
  Else
  Begin
    Dummy := MdmPause(0);
    PausedF := 0;
  End;
  Dirty;
End;

{ fin naturelle de la lecture (minuterie) }
Procedure Tick;
Var P, W : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  If (Playing = 0) And (Recording = 0) Then Exit;
  If MdmState = 0 Then
  Begin
    If Recording <> 0 Then StopRecording
    Else
    Begin
      Playing := 0; PausedF := 0;
      Dirty;
    End;
    Exit;
  End;
  { la partie affichee suit le curseur de lecture }
  If Playing <> 0 Then
  Begin
    P := PlayFrame;
    W := ViewB - ViewA;
    If (P > ViewB) And (W < Frames) Then
    Begin
      ViewA := P; ViewB := P + W;
      FixView;
      CacheOk := False;
    End;
  End;
  Inc(TickN);
  If Odd(TickN) Then
  Begin
    { Position du media (temps), un tic sur deux }
    PendMask := PendMask Or 4;
    Rc[0] := 200; Rc[1] := YB(104); Rc[2] := 346; Rc[3] := YB(84);
    Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
  End
  Else If Not CacheOk Then
  Begin
    { la partie affichee a change : toute la forme d'onde }
    Redraw;
  End
  Else
  Begin
    { l'ancien et le nouveau curseur de lecture }
    P := PlayFrame;
    If (P >= ViewA) And (P <= ViewB) Then W := WX1 + FrameCol(P) Else W := -1;
    If W <> LastCurX Then
    Begin
      If (PendMask And 2) = 0 Then
      Begin
        PendX1 := 100000; PendX2 := -1;
      End;
      If LastCurX >= 0 Then
      Begin
        PendX1 := MinI(PendX1, LastCurX); PendX2 := MaxI(PendX2, LastCurX);
      End;
      If W >= 0 Then
      Begin
        PendX1 := MinI(PendX1, W); PendX2 := MaxI(PendX2, W);
      End;
      LastCurX := W;
      If PendX2 >= PendX1 Then
      Begin
        PendMask := PendMask Or 2;
        Rc[0] := PendX1; Rc[1] := YB(WYB); Rc[2] := PendX2 + 1; Rc[3] := YB(WYT) + 1;
        Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
      End;
    End;
  End;
End;

{ ==================================================================== }
{ Edition et effets                                                     }
{ ==================================================================== }

Function HasSel : Boolean;
Begin
  HasSel := SelA <> SelB;
End;

Procedure SelRange(Var A, B : LongInt);
Begin
  A := MinI(SelA, SelB); B := MaxI(SelA, SelB);
  If B <= A Then
  Begin
    A := 0; B := Frames;
  End;
End;

Procedure CopySel;
Var A, B : LongInt;
Begin
  If Not HasSel Then Exit;
  If ClipB = 0 Then ClipB := AllocBuf;
  If ClipB = 0 Then Exit;
  A := MinI(SelA, SelB); B := MaxI(SelA, SelB);
  MoveMem(Snd + A * FB, ClipB, (B - A) * FB);
  ClipLen := (B - A) * FB; CRate := Rate; CBits := Bits; CChans := Chans;
End;

Procedure DeleteSel(Undo : Boolean);
Var A, B : LongInt;
Begin
  If Not HasSel Then Exit;
  If Undo Then SaveUndo;
  A := MinI(SelA, SelB); B := MaxI(SelA, SelB);
  MoveMem(Snd + B * FB, Snd + A * FB, SndLen - B * FB);
  SndLen := SndLen - (B - A) * FB;
  SelA := A; SelB := A; CurPos := A;
  Changed;
End;

Procedure Paste;
Var At, N : LongInt;
Begin
  If (ClipB = 0) Or (ClipLen = 0) Then Exit;
  If (CRate <> Rate) Or (CBits <> Bits) Or (CChans <> Chans) Then
  Begin
    Dummy := ShowMsg('Le son copi'#130' n''a pas le m'#136'me type (fr'#130'quence, bits, canaux) : changez le type ' +
                     '(menu Type) avant de coller.', 'Audio num'#130'rique', MB_OK Or MB_WARNING);
    Exit;
  End;
  SaveUndo;
  If HasSel Then DeleteSel(False);
  N := ClipLen;
  If SndLen + N > CAP Then N := (CAP - SndLen) - (CAP - SndLen) Mod FB;
  At := CurPos * FB;
  MoveMem(Snd + At, Snd + At + N, SndLen - At);
  MoveMem(ClipB, Snd + At, N);
  SndLen := SndLen + N;
  SelA := CurPos; SelB := CurPos + N Div FB; CurPos := SelB;
  Changed;
End;

Procedure Effect(Cm : LongInt);
Var A, B, I, J, C, V, N, D, T : LongInt;
Begin
  If Frames = 0 Then Exit;
  SelRange(A, B);
  If B <= A Then Exit;
  SaveUndo;
  N := B - A;
  Case Cm Of
    CM_REVERSE :
      Begin
        I := A; J := B - 1;
        While I < J Do
        Begin
          For C := 0 To Chans - 1 Do
          Begin
            T := GetS(Snd, I, C);
            PutS(Snd, I, C, GetS(Snd, J, C));
            PutS(Snd, J, C, T);
          End;
          Inc(I); Dec(J);
        End;
      End;
    CM_LOUDER, CM_SOFTER, CM_FADEIN, CM_FADEOUT, CM_SILENCE :
      For I := A To B - 1 Do
        For C := 0 To Chans - 1 Do
        Begin
          V := GetS(Snd, I, C);
          Case Cm Of
            CM_LOUDER : V := (V * 5) Div 4;
            CM_SOFTER : V := (V * 4) Div 5;
            CM_FADEIN : V := MulDiv(I - A, 1000, N) * V Div 1000;
            CM_FADEOUT : V := MulDiv(B - I, 1000, N) * V Div 1000;
          Else
            V := 0;
          End;
          PutS(Snd, I, C, V);
        End;
    CM_ECHO :
      Begin
        D := MulDiv(Rate, 180, 1000);
        For I := B - 1 DownTo A + D Do
          For C := 0 To Chans - 1 Do
            PutS(Snd, I, C, GetS(Snd, I, C) + (GetS(Snd, I - D, C) * 2) Div 5);
      End;
  End;
  Changed;
End;

{ conversion du son au type (frequence, bits, canaux) donne }
Procedure Convert(NR, NB, NC : LongInt);
Var OldR, OldB, OldC, OldFB, OldN, NewN, I, Sf, L, R : LongInt;
Begin
  If (NR = Rate) And (NB = Bits) And (NC = Chans) Then Exit;
  If Frames = 0 Then
  Begin
    SetFmt(NR, NB, NC);
    CurPos := 0; SelA := 0; SelB := 0;
    Changed;
    Exit;
  End;
  OldN := Frames;
  NewN := MulDiv(OldN, NR, Rate);
  If NewN * (NB Div 8) * NC > CAP Then
  Begin
    Dummy := ShowMsg('Le son converti d'#130'passerait 3 Mo.', 'Audio num'#130'rique', MB_OK Or MB_WARNING);
    Exit;
  End;
  SaveUndo;
  If HaveUndo = 0 Then Exit;
  OldR := Rate; OldB := Bits; OldC := Chans; OldFB := FB;
  For I := 0 To NewN - 1 Do
  Begin
    Sf := MulDiv(I, OldR, NR);
    If Sf >= OldN Then Sf := OldN - 1;
    SetFmt(OldR, OldB, OldC);
    L := GetS(UndoB, Sf, 0); R := GetS(UndoB, Sf, 1);
    SetFmt(NR, NB, NC);
    If NC = 1 Then PutS(Snd, I, 0, (L + R) Div 2)
    Else
    Begin
      PutS(Snd, I, 0, L); PutS(Snd, I, 1, R);
    End;
  End;
  SetFmt(NR, NB, NC);
  SndLen := NewN * FB;
  CurPos := MulDiv(CurPos, NR, OldR); SelA := MulDiv(SelA, NR, OldR); SelB := MulDiv(SelB, NR, OldR);
  ViewA := 0; ViewB := 0;
  Changed;
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
  MenuT[H] := (MenuLen - H) And 255; MenuT[H + 1] := ((MenuLen - H) Shr 8) And 255;
  MenuT[H + 4] := Count And 255; MenuT[H + 5] := (Count Shr 8) And 255;
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

Procedure CheckItem(Id : LongInt; On : Boolean);
Var M : LongInt;
Begin
  M := WinWindowFromID(Frame, $8005);
  If On Then Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(M, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED);
End;

Procedure CheckType;
Begin
  CheckItem(CM_R11, Rate = 11025); CheckItem(CM_R22, Rate = 22050); CheckItem(CM_R44, Rate = 44100);
  CheckItem(CM_B8, Bits = 8); CheckItem(CM_B16, Bits = 16);
  CheckItem(CM_MONO, Chans = 1); CheckItem(CM_STEREO, Chans = 2);
End;

Procedure BuildMenu;
Var H0, H1 : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 100, '~Fichier');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_NEW, '~Nouveau');
  MItem(MIS_TEXT, 0, CM_OPEN, '~Ouvrir...');
  MItem(MIS_TEXT, 0, CM_SAVE, '~Enregistrer');
  MItem(MIS_TEXT, 0, CM_SAVEAS, 'Enregistrer ~sous...');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_QUIT, '~Quitter');
  MenuClose(H1, 6);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 200, '~Edition');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_UNDO, '~Annuler' + Chr(9) + 'Ctrl+Z');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_CUT, '~Couper' + Chr(9) + 'Ctrl+X');
  MItem(MIS_TEXT, 0, CM_COPY, 'Co~pier' + Chr(9) + 'Ctrl+C');
  MItem(MIS_TEXT, 0, CM_PASTE, 'C~oller' + Chr(9) + 'Ctrl+V');
  MItem(MIS_TEXT, 0, CM_DELETE, '~Supprimer' + Chr(9) + 'Suppr');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_SELALL, '~Tout s'#130'lectionner');
  MItem(MIS_TEXT, 0, CM_SELNONE, 'Aucune s'#130'~lection');
  MenuClose(H1, 9);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 300, '~Affichage');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_ZOOMIN, 'Zoom ~avant');
  MItem(MIS_TEXT, 0, CM_ZOOMOUT, 'Zoom a~rri'#138're');
  MItem(MIS_TEXT, 0, CM_ZOOMSEL, '~S'#130'lection');
  MItem(MIS_TEXT, 0, CM_ZOOMALL, '~Tout le son');
  MenuClose(H1, 4);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 400, '~Options');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_REVERSE, '~Inverser');
  MItem(MIS_TEXT, 0, CM_LOUDER, '~Amplifier');
  MItem(MIS_TEXT, 0, CM_SOFTER, 'A~tt'#130'nuer');
  MItem(MIS_TEXT, 0, CM_FADEIN, 'Fondu ~entrant');
  MItem(MIS_TEXT, 0, CM_FADEOUT, 'Fondu ~sortant');
  MItem(MIS_TEXT, 0, CM_ECHO, ''#144'~cho');
  MItem(MIS_TEXT, 0, CM_SILENCE, 'S~ilence');
  MenuClose(H1, 7);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 500, '~Contr'#147'le');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_PLAY, '~Lecture / arr'#136't' + Chr(9) + 'Espace');
  MItem(MIS_TEXT, 0, CM_PAUSE, '~Pause');
  MItem(MIS_TEXT, 0, CM_STOP, '~Arr'#136't');
  MItem(MIS_TEXT, 0, CM_RECORD, '~Enregistrement' + Chr(9) + 'Ctrl+R');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_HOME, '~D'#130'but' + Chr(9) + 'D'#130'but');
  MItem(MIS_TEXT, 0, CM_END, '~Fin' + Chr(9) + 'Fin');
  MenuClose(H1, 7);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 600, '~Type');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_R11, '11 025 Hz');
  MItem(MIS_TEXT, 0, CM_R22, '22 050 Hz');
  MItem(MIS_TEXT, 0, CM_R44, '44 100 Hz');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_B8, '~8 bits');
  MItem(MIS_TEXT, 0, CM_B16, '~16 bits');
  MItem(MIS_SEPARATOR, 0, 0, '');
  MItem(MIS_TEXT, 0, CM_MONO, '~Mono');
  MItem(MIS_TEXT, 0, CM_STEREO, '~St'#130'r'#130'o');
  MenuClose(H1, 9);
  MItem(MIS_TEXT Or MIS_SUBMENU, 0, 700, 'Ai~de');
  H1 := MenuOpen;
  MItem(MIS_TEXT, 0, CM_HELP, '~Comment utiliser' + Chr(9) + 'F1');
  MItem(MIS_TEXT, 0, CM_ABOUT, ''#133' ~propos d''Audio num'#130'rique');
  MenuClose(H1, 2);
  MenuClose(H0, 7);
  Dummy := WinCreateMenu(Frame, LongInt(@MenuT));
End;

{ ==================================================================== }
{ Boite Ouvrir / Enregistrer sous                                       }
{ ==================================================================== }

Procedure DlgFill;
Var H, N, Rc, A, K, D, L : LongInt; S : String; Fb : Array[0..299] Of Byte;
Begin
  Dummy := WinSendMsg(DlgList, LM_DELETEALL, 0, 0);
  DlgN := 0;
  { unites }
  D := 0; L := 0;
  Dummy := DosQueryCurrentDisk(LongInt(@D), LongInt(@L));
  For K := 2 To 25 Do
    If ((L And (1 Shl K)) <> 0) And (DlgN < 200) Then
    Begin
      DlgItem[DlgN] := '<' + Chr(65 + K) + ':>';
      Inc(DlgN);
    End;
  { repertoires puis fichiers WAV }
  For Rc := 0 To 1 Do
  Begin
    H := -1; N := 1;
    If DosFindFirst(Z(DlgDir + '*.*'), LongInt(@H), $37, LongInt(@Fb), 300, LongInt(@N), 1) = 0 Then
    Begin
      Repeat
        A := RdL(LongInt(@Fb) + 24);
        S := '';
        For K := 0 To Fb[28] - 1 Do S := S + Chr(Fb[29 + K]);
        If (S <> '.') And (DlgN < 200) Then
        Begin
          If (Rc = 0) And ((A And $10) <> 0) Then
          Begin
            DlgItem[DlgN] := '[' + S + ']';
            Inc(DlgN);
          End
          Else If (Rc = 1) And ((A And $10) = 0) And (Pos('.WAV', UpStr(S)) > 0) Then
          Begin
            DlgItem[DlgN] := S;
            Inc(DlgN);
          End;
        End;
        N := 1;
      Until DosFindNext(H, LongInt(@Fb), 300, LongInt(@N)) <> 0;
      Dummy := DosFindClose(H);
    End;
  End;
  For K := 0 To DlgN - 1 Do Dummy := WinSendMsg(DlgList, LM_INSERTITEM, -1, Z(DlgItem[K]));
  Dummy := WinInvalidateRect(DlgClient, 0, 0);
End;

Procedure DlgClose;
Begin
  If DlgFrame = 0 Then Exit;
  { le focus quitte la zone de saisie (son curseur disparait) avant la
    destruction de la boite }
  Dummy := WinEnableWindow(Frame, 1);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  Dummy := WinDestroyWindow(DlgFrame);
  DlgFrame := 0;
  Redraw;
End;

Procedure DlgAccept;
Var S : String;
Begin
  Dummy := WinQueryWindowText(DlgEntry, 200, LongInt(@TxtBuf));
  S := GetZ(LongInt(@TxtBuf));
  While (S <> '') And (S[1] = ' ') Do Delete(S, 1, 1);
  If S = '' Then Exit;
  If (Pos(':', S) = 0) And (Copy(S, 1, 1) <> '\') Then S := DlgDir + S;
  If (DlgSave <> 0) And (Pos('.', BaseName(S)) = 0) Then S := S + '.WAV';
  DlgResult := S;
  Dummy := WinPostMsg(Client, WM_FILEDONE, DlgSave, 0);
  DlgClose;
End;

{ choix d'un element de la liste (Enter : ouvrir) }
Procedure DlgPick(Enter : Boolean);
Var I : LongInt; S : String;
Begin
  I := WinSendMsg(DlgList, LM_QUERYSELECTION, -1, 0);
  If (I < 0) Or (I >= DlgN) Then Exit;
  S := DlgItem[I];
  If S[1] = '<' Then
  Begin
    If Enter Then
    Begin
      DlgDir := Copy(S, 2, 2) + '\';
      DlgFill;
    End;
  End
  Else If S[1] = '[' Then
  Begin
    If Enter Then
    Begin
      S := Copy(S, 2, Length(S) - 2);
      If S = '..' Then
      Begin
        Delete(DlgDir, Length(DlgDir), 1);
        While (Length(DlgDir) > 0) And (DlgDir[Length(DlgDir)] <> '\') Do Delete(DlgDir, Length(DlgDir), 1);
      End
      Else DlgDir := DlgDir + S + '\';
      DlgFill;
    End;
  End
  Else
  Begin
    Dummy := WinSetWindowText(DlgEntry, Z(S));
    If Enter Then DlgAccept;
  End;
End;

Function DlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Hp, K : LongInt; S : String;
Begin
  DlgProc := 0;
  Case Msg Of
    WM_PAINT :
      Begin
        Hp := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hp, LongInt(@Rc), CLR_PALEGRAY);
        S := 'Nom du fichier :';
        PutZ(LongInt(@TxtBuf), S);
        Rc[0] := 12; Rc[1] := Rc[3] - 22; Rc[2] := 12 + Length(S) * 8; Rc[3] := Rc[3] - 6;
        Dummy := WinDrawText(Hp, Length(S), LongInt(@TxtBuf), LongInt(@Rc), CLR_BLACK, CLR_PALEGRAY, 0);
        S := 'R'#130'pertoire : ' + DlgDir;
        If Length(S) > 40 Then S := Copy(S, 1, 40);
        PutZ(LongInt(@TxtBuf), S);
        Rc[1] := Rc[1] - 50; Rc[3] := Rc[1] + 16; Rc[2] := 12 + Length(S) * 8;
        Dummy := WinDrawText(Hp, Length(S), LongInt(@TxtBuf), LongInt(@Rc), CLR_DARKBLUE, CLR_PALEGRAY, 0);
        Dummy := WinEndPaint(Hp);
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_DLGOK Then DlgAccept Else DlgClose;
    WM_CONTROL :
      If Lo16(Mp1) = ID_DLGLIST Then
      Begin
        If Hi16(Mp1) = LN_ENTER Then DlgPick(True)
        Else If Hi16(Mp1) = LN_SELECT Then DlgPick(False);
      End;
    WM_CHAR :
      If ((Lo16(Mp1) And KC_KEYUP) = 0) And ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) Then
      Begin
        K := Hi16(Mp2);
        If (K = VK_NEWLINE) Or (K = VK_ENTER) Then DlgAccept
        Else If K = VK_ESC Then DlgClose
        Else DlgProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End
      Else DlgProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_CLOSE : DlgClose;
  Else
    DlgProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Procedure FileDialog(Save : Boolean);
Var Fl, W, Hh, Sw, Sh, Hw, K : LongInt; T : String;
Begin
  If DlgFrame <> 0 Then Exit;
  If Save Then DlgSave := 1 Else DlgSave := 0;
  If FileName <> '' Then
  Begin
    K := Length(FileName);
    While (K > 0) And (FileName[K] <> '\') Do Dec(K);
    DlgDir := Copy(FileName, 1, K);
  End;
  If DlgDir = '' Then DlgDir := 'C:\';
  If Save Then T := 'Enregistrer sous' Else T := 'Ouvrir un fichier son';
  Fl := FCF_TITLEBAR Or FCF_DLGBORDER;
  DlgClient := 0;
  DlgFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('DIGAUDIODLG'), Z2(T), 0, 0, 0,
                                 LongInt(@DlgClient));
  If (DlgFrame = 0) Or (DlgClient = 0) Then Exit;
  W := 360; Hh := 300;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(DlgFrame, HWND_TOP, (Sw - W) Div 2, (Sh - Hh) Div 2, W, Hh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinQueryWindowRect(DlgClient, LongInt(@NameZ2));
  Hh := RdL(LongInt(@NameZ2) + 12);
  DlgEntry := WinCreateWindow(DlgClient, WC_ENTRYFIELD, Z(''), WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
                              12, Hh - 48, W - 34, 22, DlgClient, HWND_BOTTOM, ID_DLGENTRY, 0, 0);
  If Save And (FileName <> '') Then
  Begin
    { nom actuel, tout selectionne (la frappe le remplace) }
    Dummy := WinSetWindowText(DlgEntry, Z(BaseName(FileName)));
    Dummy := WinSendMsg(DlgEntry, EM_SETSEL, Length(BaseName(FileName)) Shl 16, 0);
  End;
  DlgList := WinCreateWindow(DlgClient, WC_LISTBOX, Z(''), WS_VISIBLE Or WS_TABSTOP, 12, 44, W - 34, Hh - 120,
                             DlgClient, HWND_BOTTOM, ID_DLGLIST, 0, 0);
  Hw := WinCreateWindow(DlgClient, WC_BUTTON, Z('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_DEFAULT, 12, 8, 90, 26,
                        DlgClient, HWND_BOTTOM, ID_DLGOK, 0, 0);
  Hw := WinCreateWindow(DlgClient, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP, 112, 8, 100, 26, DlgClient,
                        HWND_BOTTOM, ID_DLGCANCEL, 0, 0);
  DlgFill;
  Dummy := WinEnableWindow(Frame, 0);
  Dummy := WinSetFocus(HWND_DESKTOP, DlgEntry);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

{ le son modifie doit-il etre enregistre ? (faux : abandon) }
Function CheckSave : Boolean;
Var R : LongInt;
Begin
  CheckSave := True;
  If (Not Modified) Or (SndLen = 0) Then Exit;
  R := ShowMsg('Le son a '#130't'#130' modifi'#130'. L''enregistrer ?', 'Audio num'#130'rique', MB_YESNOCANCEL Or
               MB_QUERY);
  If R = MBID_YES Then
  Begin
    If FileName = '' Then
    Begin
      FileDialog(True);
      CheckSave := False;
    End
    Else CheckSave := SaveWav(FileName);
  End
  Else If R <> MBID_NO Then CheckSave := False;
End;

Procedure NewSound;
Begin
  StopAll;
  SndLen := 0; FileName := ''; Modified := False; HaveUndo := 0;
  CurPos := 0; SelA := 0; SelB := 0; ViewA := 0; ViewB := 0;
  FixView;
  SetTitle;
  Dirty;
End;

Procedure Zoom(Cm : LongInt);
Var C, W, A, B : LongInt;
Begin
  W := ViewB - ViewA;
  C := (ViewA + ViewB) Div 2;
  If (CurPos >= ViewA) And (CurPos <= ViewB) Then C := CurPos;
  Case Cm Of
    CM_ZOOMIN :
      Begin
        W := MaxI(W Div 2, 64);
        ViewA := C - W Div 2; ViewB := ViewA + W;
      End;
    CM_ZOOMOUT :
      Begin
        W := W * 2;
        ViewA := C - W Div 2; ViewB := ViewA + W;
      End;
    CM_ZOOMSEL :
      Begin
        A := MinI(SelA, SelB); B := MaxI(SelA, SelB);
        If B > A Then
        Begin
          ViewA := A; ViewB := B;
        End;
      End;
  Else
    Begin
      ViewA := 0; ViewB := 0;
    End;
  End;
  FixView;
  Dirty;
End;

Procedure Command(Id : LongInt);
Var S : String;
Begin
  If DlgFrame <> 0 Then Exit;
  If ((Playing <> 0) Or (Recording <> 0)) And Not ((Id = CM_PLAY) Or (Id = CM_PAUSE) Or (Id = CM_STOP) Or
     (Id = CM_RECORD) Or (Id = CM_HELP) Or (Id = CM_ABOUT) Or (Id = CM_QUIT)) Then StopAll;
  Case Id Of
    CM_NEW : If CheckSave Then NewSound;
    CM_OPEN : If CheckSave Then FileDialog(False);
    CM_SAVE :
      If FileName = '' Then FileDialog(True)
      Else If Not SaveWav(FileName) Then
        Dummy := ShowMsg('Impossible d''enregistrer ' + FileName + '.', 'Audio num'#130'rique', MB_OK Or MB_ERROR);
    CM_SAVEAS : FileDialog(True);
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_UNDO : DoUndo;
    CM_CUT :
      Begin
        CopySel;
        DeleteSel(True);
      End;
    CM_COPY : CopySel;
    CM_PASTE : Paste;
    CM_DELETE : DeleteSel(True);
    CM_SELALL :
      Begin
        SelA := 0; SelB := Frames;
        Dirty;
      End;
    CM_SELNONE :
      Begin
        SelA := CurPos; SelB := CurPos;
        Dirty;
      End;
    CM_ZOOMIN, CM_ZOOMOUT, CM_ZOOMALL, CM_ZOOMSEL : Zoom(Id);
    CM_REVERSE, CM_LOUDER, CM_SOFTER, CM_FADEIN, CM_FADEOUT, CM_ECHO, CM_SILENCE : Effect(Id);
    CM_PLAY : StartPlay;
    CM_PAUSE : TogglePause;
    CM_STOP : StopAll;
    CM_RECORD : If Recording <> 0 Then StopAll Else StartRecord;
    CM_HOME :
      Begin
        StopAll;
        CurPos := 0; SelA := 0; SelB := 0;
        ViewB := ViewB - ViewA; ViewA := 0;
        FixView;
        Dirty;
      End;
    CM_END :
      Begin
        StopAll;
        CurPos := Frames; SelA := CurPos; SelB := CurPos;
        ViewA := Frames - (ViewB - ViewA); ViewB := Frames;
        FixView;
        Dirty;
      End;
    CM_R11 : Convert(11025, Bits, Chans);
    CM_R22 : Convert(22050, Bits, Chans);
    CM_R44 : Convert(44100, Bits, Chans);
    CM_B8 : Convert(Rate, 8, Chans);
    CM_B16 : Convert(Rate, 16, Chans);
    CM_MONO : Convert(Rate, Bits, 1);
    CM_STEREO : Convert(Rate, Bits, 2);
    CM_HELP :
      Dummy := ShowMsg('Lecture : la s'#130'lection, sinon de la position '#133' la fin (Espace). Cliquez la forme ' +
                       'd''onde pour placer la position ; glissez (ou Maj+clic) pour s'#130'lectionner. ' +
                       'L''enregistrement remplace la s'#130'lection ou s''ins'#138're '#133' la position. Les effets ' +
                       '(menu Options) et le type (menu Type) s''appliquent '#133' la s'#130'lection ou au son entier.',
                       'Audio num'#130'rique - Aide', MB_OK Or MB_INFORMATION);
    CM_ABOUT :
      Begin
        S := 'Audio num'#130'rique pour OS/2-0 (multim'#130'dia, MDM.DLL). Carte son : ' + CardName + '. ' +
             'Programme '#130'crit en Pascal et compil'#130' par OS2PC.';
        Dummy := ShowMsg(S, ''#133' propos d''Audio num'#130'rique', MB_OK Or MB_INFORMATION);
      End;
  End;
  CheckType;
End;

{ ==================================================================== }
{ Souris                                                                }
{ ==================================================================== }

Function InRect(X, Yt, X1, Yt1, X2, Yt2 : LongInt) : Boolean;
Begin
  InRect := (X >= X1) And (X <= X2) And (Yt >= Yt1) And (Yt <= Yt2);
End;

Function WaveFrame(X : LongInt) : LongInt;
Begin
  WaveFrame := Clamp(ColFrame(Clamp(X - WX1, 0, NCols)), 0, Frames);
End;

{ fleches des champs : Up haut (+) ou bas (-) ; pas de 0,1 s }
Procedure Spin(Which, Dir : LongInt);
Var D, A, B : LongInt;
Begin
  If (Playing <> 0) Or (Recording <> 0) Then Exit;
  D := Dir * (Rate Div 10);
  A := MinI(SelA, SelB); B := MaxI(SelA, SelB);
  Case Which Of
    0 : A := Clamp(A + D, 0, B);
    1 : B := Clamp(B + D, A, Frames);
  Else
    Begin
      CurPos := Clamp(CurPos + D, 0, Frames);
      A := CurPos; B := CurPos;
    End;
  End;
  SelA := A; SelB := B;
  If Which < 2 Then CurPos := A;
  Dirty;
End;

Procedure ButtonDown(X, Y : LongInt; Shift : Boolean);
Var Yt, K, F, W : LongInt;
Begin
  Yt := CH - 1 - Y;
  { forme d'onde }
  If InRect(X, Yt, WX1, WYT, WX2 - 1, WYB) Then
  Begin
    If (Playing <> 0) Or (Recording <> 0) Then StopAll;
    F := WaveFrame(X);
    If Shift Then SelB := F
    Else
    Begin
      SelA := F; SelB := F; CurPos := F;
    End;
    DragWave := 1;
    Dummy := WinSetCapture(HWND_DESKTOP, Client);
    Dirty;
    Exit;
  End;
  { barre de defilement }
  If InRect(X, Yt, WX1, WYB + 4, WX2 - 1, WYB + 16) And (Frames > 0) Then
  Begin
    W := ViewB - ViewA;
    If X < WX1 + 14 Then ViewA := ViewA - MaxI(W Div 10, 1)
    Else If X > WX2 - 15 Then ViewA := ViewA + MaxI(W Div 10, 1)
    Else ViewA := MulDiv(X - WX1 - 14, Frames, NCols - 28) - W Div 2;
    ViewB := ViewA + W;
    FixView;
    Dirty;
    Exit;
  End;
  { boutons de transport }
  For K := 0 To 5 Do
    If InRect(X, Yt, BtnL[K], 14, BtnR[K], 42) Then
    Begin
      DownBtn := K;
      Dummy := WinSetCapture(HWND_DESKTOP, Client);
      Redraw;
      Exit;
    End;
  { fleches des champs }
  If InRect(X, Yt, 76, 82, 87, 100) Then
  Begin
    If Yt < 91 Then Spin(0, 1) Else Spin(0, -1);
  End
  Else If InRect(X, Yt, 160, 82, 171, 100) Then
  Begin
    If Yt < 91 Then Spin(1, 1) Else Spin(1, -1);
  End
  Else If InRect(X, Yt, 264, 84, 275, 102) Then
  Begin
    If Yt < 93 Then Spin(2, 1) Else Spin(2, -1);
  End
  { volume }
  Else If InRect(X, Yt, 414, 66, 428, 80) Or (InRect(X, Yt, 422, 14, 445, 62)) Then
  Begin
    Volume := MdmVolume(Clamp(Volume - 10, 0, 100));
    Redraw;
  End
  Else If InRect(X, Yt, 464, 66, 478, 80) Or (InRect(X, Yt, 447, 14, 470, 62)) Then
  Begin
    Volume := MdmVolume(Clamp(Volume + 10, 0, 100));
    Redraw;
  End;
End;

Procedure ButtonUp(X, Y : LongInt);
Var Yt, K : LongInt;
Begin
  Dummy := WinSetCapture(HWND_DESKTOP, 0);
  Yt := CH - 1 - Y;
  If DragWave <> 0 Then
  Begin
    DragWave := 0;
    If SelA <> SelB Then CurPos := MinI(SelA, SelB);
    Dirty;
    Exit;
  End;
  If DownBtn >= 0 Then
  Begin
    K := DownBtn;
    DownBtn := -1;
    Redraw;
    If InRect(X, Yt, BtnL[K], 14, BtnR[K], 42) Then
      Case K Of
        0 : Command(CM_HOME);
        1 : Command(CM_STOP);
        2 : Command(CM_PAUSE);
        3 :
          Begin
            If (Playing <> 0) And (PausedF <> 0) Then TogglePause
            Else If Playing = 0 Then StartPlay;
          End;
        4 : Command(CM_END);
        5 : Command(CM_RECORD);
      End;
  End;
End;

Procedure MouseMove(X, Y : LongInt);
Begin
  If DragWave = 0 Then Exit;
  SelB := WaveFrame(X);
  If X < WX1 Then
  Begin
    ViewA := ViewA - (ViewB - ViewA) Div 20;
    ViewB := ViewB - (ViewB - ViewA) Div 20;
    FixView;
    CacheOk := False;
  End;
  Redraw;
End;

{ fleches : position (Maj : selection) }
Procedure KeyMove(Dir : LongInt; Shift : Boolean);
Var D : LongInt;
Begin
  D := MaxI((ViewB - ViewA) Div 50, 1) * Dir;
  If Shift Then
  Begin
    If SelA = SelB Then SelA := CurPos;
    SelB := Clamp(SelB + D, 0, Frames);
  End
  Else
  Begin
    CurPos := Clamp(CurPos + D, 0, Frames);
    SelA := CurPos; SelB := CurPos;
  End;
  Dirty;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Fl, K, C : LongInt; Err : String;
Begin
  MainProc := 0;
  Case Msg Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
        CacheOk := False;
      End;
    WM_PAINT : PaintAll(H);
    WM_TIMER : Tick;
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        ButtonDown(S16(Mp1), S16(Mp1 Shr 16), (Hi16(Mp2) And KC_SHIFT) <> 0);
        MainProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        ButtonUp(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        MouseMove(S16(Mp1), S16(Mp1 Shr 16));
        MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_FILEDONE :
      If Mp1 <> 0 Then
      Begin
        If Not SaveWav(DlgResult) Then
          Dummy := ShowMsg('Impossible d''enregistrer ' + DlgResult + '.', 'Audio num'#130'rique', MB_OK Or MB_ERROR);
      End
      Else
      Begin
        StopAll;
        DlgDir := '';
        Err := LoadWav(DlgResult);
        If Err <> '' Then Dummy := ShowMsg(Err, 'Audio num'#130'rique', MB_OK Or MB_WARNING);
        CheckType;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1);
        If (Fl And KC_KEYUP) = 0 Then
        Begin
          K := Hi16(Mp2); C := Lo16(Mp2);
          If (Fl And KC_CTRL) <> 0 Then
          Begin
            If (C = 26) Or (C = Ord('z')) Or (C = Ord('Z')) Then Command(CM_UNDO)
            Else If (C = 24) Or (C = Ord('x')) Or (C = Ord('X')) Then Command(CM_CUT)
            Else If (C = 3) Or (C = Ord('c')) Or (C = Ord('C')) Then Command(CM_COPY)
            Else If (C = 22) Or (C = Ord('v')) Or (C = Ord('V')) Then Command(CM_PASTE)
            Else If (C = 18) Or (C = Ord('r')) Or (C = Ord('R')) Then Command(CM_RECORD)
            Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
          End
          Else If (Fl And KC_VIRTUALKEY) <> 0 Then
          Begin
            Case K Of
              VK_SPACE : Command(CM_PLAY);
              VK_HOME : Command(CM_HOME);
              VK_END : Command(CM_END);
              VK_LEFT : KeyMove(-1, (Fl And KC_SHIFT) <> 0);
              VK_RIGHT : KeyMove(1, (Fl And KC_SHIFT) <> 0);
              VK_DELETE : Command(CM_DELETE);
              VK_F1 : Command(CM_HELP);
              VK_ESC : Command(CM_STOP);
            Else
              MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
            End;
          End
          Else If C = 32 Then Command(CM_PLAY)
          Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
        End;
      End;
    WM_CLOSE :
      If CheckSave Then
      Begin
        StopAll;
        Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
      End;
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Var
  Fl, Sw, Sh, K : LongInt;
  S : String;

BEGIN
  Snd := 0; UndoB := 0; ClipB := 0; RecB := 0; HaveUndo := 0; ClipLen := 0;
  SndLen := 0; SetFmt(22050, 16, 1);
  CurPos := 0; SelA := 0; SelB := 0; ViewA := 0; ViewB := 0;
  Playing := 0; Recording := 0; PausedF := 0; DragWave := 0; DownBtn := -1; LastCurX := -1;
  FileName := ''; Modified := False; DlgFrame := 0; DlgDir := ''; CacheOk := False;
  CardCaps := MdmAudioInfo(LongInt(@TxtBuf), 100);
  CardName := GetZ(LongInt(@TxtBuf));
  Volume := MdmVolume(-1);
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('DIGAUDIO'), LongInt(@MainProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('DIGAUDIODLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('DIGAUDIO'), Z2('Audio num'#130'rique'), 0, 0, 0,
                              LongInt(@Client));
  BuildMenu;
  Snd := AllocBuf;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - 490) Div 2), MaxI(0, (Sh - 384) Div 2 + 20), 490, 384,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  If Snd = 0 Then
    Dummy := ShowMsg('M'#130'moire insuffisante pour le son (3 Mo).', 'Audio num'#130'rique', MB_OK Or MB_ERROR);
  SetTitle;
  FixView;
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (S <> '') And (S[1] <> '/') And (Snd <> 0) Then
    Begin
      S := LoadWav(S);
      If S <> '' Then Dummy := ShowMsg(S, 'Audio num'#130'rique', MB_OK Or MB_WARNING);
    End;
  End;
  CheckType;
  Dummy := WinStartTimer(Hab, Client, 1, 100);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := MdmStop;
  Dummy := WinDestroyWindow(Frame);
END.
