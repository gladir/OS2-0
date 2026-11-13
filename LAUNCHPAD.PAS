{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: LAUNCHPD.EXE de OS/2-0 : le LaunchPad du Workplace Shell
                d'OS/2 Warp 3, lance par PMSHELL au demarrage du bureau.
}

Program LAUNCHPAD;

{$R-,S-,I-}

{ Compilation : OS2PC LAUNCHPAD.PAS LAUNCHPD.EXE   (nom 8.3 du CD-ROM)

  Le LaunchPad est la barre de lancement d'OS/2 Warp 3 : une petite
  fenetre toujours visible au-dessus du bureau qui donne acces en un
  clic aux actions et aux objets les plus utilises. PMSHELL.EXE le lance
  au demarrage (dans la session de Presentation Manager ; les deux
  programmes s'executent en meme temps).

  Actions (petits boutons de gauche) :
    Verrouiller        : verrouille l'ecran (OS2.INI, LAUNCHPAD, MOTDEPASSE :
                         mot de passe a taper pour deverrouiller ; sans
                         mot de passe, Entree deverrouille) ;
    Rechercher         : recherche de fichiers sur toutes les unites
                         (masque avec * et ?), en arriere-plan ;
                         double clic ou Entree sur un resultat : l'ouvrir ;
    Arret              : arret du systeme (demande au bureau) ;
    Liste des fenetres : liste des fenetres et des sessions (bureau).
  Objets (grands boutons) : Lecteur C:, Invite de commandes OS/2, Aide,
  Imprimante (file d'attente du spouleur PMSPL : travaux, annulation,
  impression d'un fichier). Chaque objet a un tiroir (fleche au-dessus
  du bouton) qui contient d'autres objets : les autres unites et le
  dossier Lecteurs, le dossier Systeme OS/2, les Modeles, les
  informations sur le systeme (et C:\LISEZMOI.TXT s'il existe),
  l'impression d'un fichier...

  Il n'y a pas de limite au nombre d'objets : on en ajoute en deposant un
  objet du bureau ou d'un dossier sur le LaunchPad (glisser-deposer avec
  le bouton 2 de la souris ; deposer sur un bouton qui a un tiroir le
  range dans ce tiroir) ou par le menu contextuel (bouton 2 : Ajouter un
  programme ou un dossier..., Retirer cet objet, Mot de passe de
  verrouillage..., Fermer le LaunchPad). Les objets et la position de la
  barre sont gardes dans OS2.INI (application LAUNCHPAD).

  Souris : clic sur un bouton : action ; clic sur la fleche d'un tiroir :
  ouvrir ou fermer le tiroir ; glisser le fond de la barre : la deplacer ;
  la souris immobile sur un bouton affiche son nom (bulle d'aide).
  Clavier (barre active) : fleches gauche et droite : bouton suivant ;
  Entree ou espace : action ; fleche haut : ouvrir le tiroir ; Echap :
  fermer le tiroir.

  Les dossiers, les programmes et les fichiers sont ouverts par le
  bureau : le LaunchPad ecrit la demande dans OS2.INI (PMSHELL, REQn) et
  envoie le message WM_USER + 1 a la fenetre du bureau (PMSHELL, HWND). }

Const
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0007; WM_TIMER = $0024; WM_SETFOCUS = $000F;
  WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029; WM_CONTROL = $0030;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073;
  WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075; WM_CHAR = $007A; WM_USER = $1000;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_DLGBORDER = $200;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_HIDE = $10; SWP_ACTIVATE = $80;
  WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006; WC_LISTBOX = $FFFF0007;
  BS_PUSHBUTTON = 0; BS_DEFAULT = $0400; SS_TEXT = 1; ES_AUTOSCROLL = 4; ES_MARGIN = 8;
  EM_SETTEXTLIMIT = $0143;
  LM_QUERYITEMCOUNT = $0160; LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165;
  LM_DELETEALL = $016E;
  LN_ENTER = 5;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_ERROR = $40; MB_WARNING = $20; MB_QUERY = $10;
  MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_KEYUP = $40;
  VK_BACKSPACE = 5; VK_TAB = 6; VK_NEWLINE = 8; VK_ESC = $0F; VK_SPACE = $10; VK_LEFT = $15; VK_UP = $16;
  VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  WM_REQUEST = WM_USER + 1;      { demande au bureau / objet depose (PMSHELL) }

  { genres d'objets }
  K_FOLDER = 1; K_DRIVES = 2; K_CMD = 3; K_HELP = 4; K_PRINTER = 5; K_PROG = 6; K_BATCH = 7;
  K_FILE = 8; K_SYS = 9; K_INFO = 10; K_TEMPL = 11; K_PRINTFILE = 12; K_SHUT = 13; K_WINLIST = 14;
  K_LOCK = 15; K_FIND = 16;

  { geometrie de la barre }
  BtnW = 44; BtnH = 46; ArrH = 10; Pad = 4; SmW = 22; SmH = 23; ObjX0 = 56;
  DrwRowH = 36; DrwW = 190;

  { commandes des menus et des boutons }
  CM_ADD = 200; CM_REMOVE = 201; CM_PASSWORD = 202; CM_QUIT = 203;
  ID_OK = 1; ID_CANCEL = 2; ID_EF = 10; ID_GO = 11; ID_LIST = 12; ID_STAT = 13;
  ID_PRINT = 20; ID_CANJOB = 21; ID_REFR = 22;
  IN_ADD = 1; IN_PASSWORD = 2; IN_PRINT = 3;

Type
  TObj = Record
    Use, Kind, Parent : LongInt;
    Name : String[47];
    Path : String[127];
  End;
  PObj = ^TObj;
  TPath = String[127];
  PPath = ^TPath;

Var
  Hab, Hmq, BarW, BarH, BarX, BarY, ScrW, ScrH, Dummy, I : LongInt;
  BarHw, DrwHw, DrwOf, TipHw, LockHw, Focus, Pressed, PressArr, Hover, HoverTicks, TipShown : LongInt;
  Dragging, DragX0, DragY0, DragBX, DragBY, Moved, MenuH, MenuAt : LongInt;
  ObjBuf, ObjCap : LongInt;
  { recherche }
  FindFr, FindCl, FindEf, FindLb, FindSt, FindGo, FindLbl, Searching, Found, Scanned : LongInt;
  StkBuf, StkCap, StkN, ResBuf, ResCap, ResN : LongInt;
  Mask : String;
  { imprimante }
  PrnFr, PrnCl, PrnLb, PrnStat : LongInt;
  JobIds : Array[0..255] Of LongInt;
  JobN : LongInt;
  { saisie }
  InFr, InCl, InEf, InMode, InParent : LongInt;
  InPrompt, InTitle : String;
  { verrouillage }
  LockPw, LockTyped : String;
  LockTick, LockX, LockY, LockBad : LongInt;
  { tampons }
  NameZ, NameZ2, ArgBuf : Array[0..511] Of Byte;
  MenuTpl : Array[0..1023] Of Byte;
  MenuLen, MenuCnt : LongInt;
  FindBuf : Array[0..4095] Of Byte;
  InfoBuf : Array[0..8191] Of Byte;
  Qmsg : Array[0..7] Of LongInt;

{ --- DOSCALLS.DLL --- }
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCurrentDisk(PDisk, PLogical : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';

{ --- PMWIN.DLL --- }
Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
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
Function WinSetFocus(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HDesk : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetCapture(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetSysModalWindow(HDesk, H : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindow(Hab, H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryPointerPos(HD, P : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, T : LongInt) : LongInt; External 'PMWIN';

{ --- PMGPI.DLL --- }
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';

{ --- PMMERGE.DLL (profil de l'utilisateur) --- }
Function PrfQueryProfileString(H, A, K, Df, B, M : LongInt) : LongInt; External 'PMMERGE';
Function PrfWriteProfileString(H, A, K, D : LongInt) : LongInt; External 'PMMERGE';

{ --- PMSPL.DLL (file d'attente de l'imprimante) --- }
Function SplQmListJobs(PQ, Lv, PBuf, Cb, PcRet, PcTot, PcbNeed : LongInt) : LongInt; External 'PMSPL';
Function SplQmCancelJob(PQ, Id : LongInt) : LongInt; External 'PMSPL';
Function SplQmWriteFile(PQ, PFile, PDoc, PJob : LongInt) : LongInt; External 'PMSPL';
Function SplQmListAvailQueues(PBuf, Cb, PcRet : LongInt) : LongInt; External 'PMSPL';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function RdL(A : LongInt) : LongInt;
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  RdL := Q^;
End;

Function RdB(A : LongInt) : LongInt;
Type PByte = ^Byte;
Var Q : PByte;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PByte = ^Byte;
Var Q : PByte;
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

Function GetZ(A : LongInt) : String;
Var S : String; K : LongInt;
Begin
  S := ''; K := 0;
  If A <> 0 Then
    While (K < 255) And (RdB(A + K) <> 0) Do
    Begin
      S := S + Chr(RdB(A + K));
      Inc(K);
    End;
  GetZ := S;
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

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'a') And (S[K] <= 'z') Then S[K] := Chr(Ord(S[K]) - 32);
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

Function AbsI(A : LongInt) : LongInt;
Begin
  If A < 0 Then AbsI := -A Else AbsI := A;
End;

Function FileExists(S : String) : Boolean;
Var Info : Array[0..63] Of Byte;
Begin
  FileExists := DosQueryPathInfo(Z(S), 1, LongInt(@Info), 64) = 0;
End;

Function ExtOf(S : String) : String;
Var K : LongInt;
Begin
  K := Length(S);
  While (K > 0) And (S[K] <> '.') And (S[K] <> '\') Do Dec(K);
  If (K > 0) And (S[K] = '.') Then ExtOf := UpStr(Copy(S, K + 1, 255)) Else ExtOf := '';
End;

Function BaseName(S : String) : String;
Var K : LongInt;
Begin
  If (Length(S) > 3) And (S[Length(S)] = '\') Then S := Copy(S, 1, Length(S) - 1);
  K := Length(S);
  While (K > 0) And (S[K] <> '\') Do Dec(K);
  BaseName := Copy(S, K + 1, 255);
End;

Procedure ShowMsg(Text, Cap : String; Style : LongInt);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z(Text), Z2(Cap), 0, Style Or MB_MOVEABLE);
End;

Function PrfGet(App, Key : String) : String;
Var B : Array[0..299] Of Byte;
Begin
  B[0] := 0;
  Dummy := PrfQueryProfileString(-1, Z(App), Z2(Key), 0, LongInt(@B), 290);
  PrfGet := GetZ(LongInt(@B));
End;

Procedure PrfPut(App, Key, Value : String);
Var B : Array[0..299] Of Byte;
Begin
  PutZ(LongInt(@B), Value);
  Dummy := PrfWriteProfileString(-1, Z(App), Z2(Key), LongInt(@B));
End;

Procedure PrfDel(App, Key : String);
Begin
  Dummy := PrfWriteProfileString(-1, Z(App), Z2(Key), 0);
End;

Function ValI(S : String; Df : LongInt) : LongInt;
Var V, C : LongInt;
Begin
  Val(S, V, C);
  If C <> 0 Then V := Df;
  ValI := V;
End;

{ table qui double quand elle est pleine (pas de limite fixe) }
Procedure Grow(Var Buf, Cap : LongInt; Sz : LongInt);
Var N, P, K : LongInt;
Begin
  If Cap = 0 Then N := 16 Else N := Cap * 2;
  GetMem(Pointer(P), N * Sz);
  For K := 0 To N * Sz - 1 Do WrB(P + K, 0);
  If Cap > 0 Then
  Begin
    For K := 0 To Cap * Sz - 1 Do WrB(P + K, RdB(Buf + K));
    FreeMem(Pointer(Buf), Cap * Sz);
  End;
  Buf := P; Cap := N;
End;

Function Ob(K : LongInt) : PObj;
Begin
  Ob := Pointer(ObjBuf + K * SizeOf(TObj));
End;

Function StkAt(K : LongInt) : PPath;
Begin
  StkAt := Pointer(StkBuf + K * SizeOf(TPath));
End;

Function ResAt(K : LongInt) : PPath;
Begin
  ResAt := Pointer(ResBuf + K * SizeOf(TPath));
End;

{ ==================================================================== }
{ Objets du LaunchPad                                                   }
{ ==================================================================== }

Function NewObj(Kind, Parent : LongInt; Name, Path : String) : LongInt;
Var K, R : LongInt;
Begin
  R := -1;
  For K := 0 To ObjCap - 1 Do
    If (R < 0) And (Ob(K)^.Use = 0) Then R := K;
  If R < 0 Then
  Begin
    R := ObjCap;
    Grow(ObjBuf, ObjCap, SizeOf(TObj));
  End;
  Ob(R)^.Use := 1; Ob(R)^.Kind := Kind; Ob(R)^.Parent := Parent;
  Ob(R)^.Name := Name; Ob(R)^.Path := Path;
  NewObj := R;
End;

{ objets de la barre, dans l'ordre (rang -> indice) }
Function BarCount : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To ObjCap - 1 Do
    If (Ob(K)^.Use <> 0) And (Ob(K)^.Parent < 0) Then Inc(N);
  BarCount := N;
End;

Function BarObj(R : LongInt) : LongInt;
Var K, N, Res : LongInt;
Begin
  N := 0; Res := -1;
  For K := 0 To ObjCap - 1 Do
    If (Res < 0) And (Ob(K)^.Use <> 0) And (Ob(K)^.Parent < 0) Then
    Begin
      If N = R Then Res := K;
      Inc(N);
    End;
  BarObj := Res;
End;

Function DrwCount(P : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To ObjCap - 1 Do
    If (Ob(K)^.Use <> 0) And (Ob(K)^.Parent = P) Then Inc(N);
  DrwCount := N;
End;

Function DrwObj(P, R : LongInt) : LongInt;
Var K, N, Res : LongInt;
Begin
  N := 0; Res := -1;
  For K := 0 To ObjCap - 1 Do
    If (Res < 0) And (Ob(K)^.Use <> 0) And (Ob(K)^.Parent = P) Then
    Begin
      If N = R Then Res := K;
      Inc(N);
    End;
  DrwObj := Res;
End;

Function KindName(K : LongInt) : String;
Begin
  KindName := IStr(K);
End;

{ OS2.INI : NOMBRE, puis OBJn = "genre,parent,nom,chemin" }
Procedure SaveObjs;
Var K, N, R, J : LongInt;
Begin
  N := 0;
  For K := 0 To ObjCap - 1 Do
    If Ob(K)^.Use <> 0 Then
    Begin
      { parent : rang du parent parmi les objets gardes }
      R := -1;
      If Ob(K)^.Parent >= 0 Then
      Begin
        R := 0;
        For J := 0 To Ob(K)^.Parent - 1 Do
          If Ob(J)^.Use <> 0 Then Inc(R);
      End;
      PrfPut('LAUNCHPAD', 'OBJ' + IStr(N), KindName(Ob(K)^.Kind) + ',' + IStr(R) + ',' + Ob(K)^.Name + ',' +
             Ob(K)^.Path);
      Inc(N);
    End;
  K := ValI(PrfGet('LAUNCHPAD', 'NOMBRE'), 0);
  While K > N Do
  Begin
    Dec(K);
    PrfDel('LAUNCHPAD', 'OBJ' + IStr(K));
  End;
  PrfPut('LAUNCHPAD', 'NOMBRE', IStr(N));
End;

Function Field(Var S : String) : String;
Var P : LongInt;
Begin
  P := Pos(',', S);
  If P = 0 Then
  Begin
    Field := S;
    S := '';
  End
  Else
  Begin
    Field := Copy(S, 1, P - 1);
    S := Copy(S, P + 1, 255);
  End;
End;

Procedure DefaultObjs;
Var K, D, L, Drv : LongInt;
Begin
  D := 0; L := 0;
  Dummy := DosQueryCurrentDisk(LongInt(@D), LongInt(@L));
  K := NewObj(K_FOLDER, -1, 'Lecteur C:', 'C:\');
  Dummy := NewObj(K_DRIVES, K, 'Lecteurs', '');
  For Drv := 3 To 25 Do
    If (Drv <> 2) And ((L Shr Drv) And 1 <> 0) Then
      Dummy := NewObj(K_FOLDER, K, 'Lecteur ' + Chr(65 + Drv) + ':', Chr(65 + Drv) + ':\');
  K := NewObj(K_CMD, -1, 'Invite de commandes OS/2', '');
  Dummy := NewObj(K_SYS, K, 'Systeme OS/2', '');
  Dummy := NewObj(K_TEMPL, K, 'Modeles', '');
  K := NewObj(K_HELP, -1, 'Aide', '');
  Dummy := NewObj(K_INFO, K, 'Informations sur le systeme', '');
  If FileExists('C:\LISEZMOI.TXT') Then Dummy := NewObj(K_FILE, K, 'Lisez-moi', 'C:\LISEZMOI.TXT');
  If FileExists('C:\README.TXT') Then Dummy := NewObj(K_FILE, K, 'Readme', 'C:\README.TXT');
  K := NewObj(K_PRINTER, -1, 'Imprimante', '');
  Dummy := NewObj(K_PRINTFILE, K, 'Imprimer un fichier...', '');
End;

Procedure LoadObjs;
Var N, K, Kind, Par, J : LongInt; S, Nm : String;
Begin
  N := ValI(PrfGet('LAUNCHPAD', 'NOMBRE'), -1);
  If N < 0 Then
  Begin
    DefaultObjs;
    SaveObjs;
    Exit;
  End;
  { les objets sont relus dans l'ordre : le rang du parent est l'indice }
  For K := 0 To N - 1 Do
  Begin
    S := PrfGet('LAUNCHPAD', 'OBJ' + IStr(K));
    Kind := ValI(Field(S), 0);
    Par := ValI(Field(S), -1);
    Nm := Field(S);
    J := NewObj(Kind, Par, Nm, S);
    If (Kind <= 0) Or (Kind > K_FIND) Then Ob(J)^.Use := 0;
  End;
End;

{ genre d'un objet depose (chemin, ou *n : objet du systeme n de PMSHELL) }
Function KindOfTarget(T : String) : LongInt;
Var E : String; N : LongInt;
Begin
  KindOfTarget := 0;
  If T = '' Then Exit;
  If T[1] = '*' Then
  Begin
    N := ValI(Copy(T, 2, 10), 0);
    Case N Of
      1 : KindOfTarget := K_SYS;
      2 : KindOfTarget := K_DRIVES;
      3 : KindOfTarget := K_CMD;
      4 : KindOfTarget := K_SHUT;
      5 : KindOfTarget := K_WINLIST;
      6 : KindOfTarget := K_INFO;
      7 : KindOfTarget := K_HELP;
      12 : KindOfTarget := K_TEMPL;
    End;
    Exit;
  End;
  If T[Length(T)] = '\' Then
  Begin
    KindOfTarget := K_FOLDER;
    Exit;
  End;
  E := ExtOf(T);
  If (E = 'EXE') Or (E = 'COM') Then KindOfTarget := K_PROG
  Else If (E = 'CMD') Or (E = 'BAT') Then KindOfTarget := K_BATCH
  Else KindOfTarget := K_FILE;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Procedure GBox(Hps, X1, Y1, X2, Y2, C, Fl : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiBox(Hps, Fl, LongInt(@P), 0, 0);
End;

Procedure FBox(Hps, X1, Y1, X2, Y2, Fill, Edge : LongInt);
Begin
  GBox(Hps, X1, Y1, X2, Y2, Fill, DRO_FILL);
  If Edge <> Fill Then GBox(Hps, X1, Y1, X2, Y2, Edge, DRO_OUTLINE);
End;

Procedure GLn(Hps, X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

Procedure GText(Hps, X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt; B : Array[0..63] Of Byte;
Begin
  If Length(S) > 60 Then S := Copy(S, 1, 60);
  PutZ(LongInt(@B), S);
  Rc[0] := X; Rc[1] := Y; Rc[2] := X + Length(S) * 8; Rc[3] := Y + 16;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@B), LongInt(@Rc), Fg, Bg, 0);
End;

{ relief : enfonce (Down) ou en saillie }
Procedure Bevel(Hps, X1, Y1, X2, Y2 : LongInt; Down : Boolean);
Var CHi, CLo : LongInt;
Begin
  If Down Then
  Begin
    CHi := CLR_DARKGRAY; CLo := CLR_WHITE;
  End
  Else
  Begin
    CHi := CLR_WHITE; CLo := CLR_DARKGRAY;
  End;
  GLn(Hps, X1, Y1, X1, Y2, CHi);
  GLn(Hps, X1, Y2, X2, Y2, CHi);
  GLn(Hps, X2, Y2, X2, Y1, CLo);
  GLn(Hps, X2, Y1, X1, Y1, CLo);
End;

{ grande icone (32 x 32) d'un objet }
Procedure BigIcon(Hps, Kind : LongInt; Path : String; X, Y : LongInt);
Begin
  Case Kind Of
    K_FOLDER :
      If Length(Path) = 3 Then
      Begin
        { unite }
        FBox(Hps, X + 1, Y + 9, X + 30, Y + 22, CLR_PALEGRAY, CLR_BLACK);
        GLn(Hps, X + 5, Y + 16, X + 21, Y + 16, CLR_BLACK);
        GBox(Hps, X + 24, Y + 12, X + 27, Y + 13, CLR_GREEN, DRO_FILL);
        GText(Hps, X + 4, Y - 6, Copy(Path, 1, 2), CLR_BLACK, CLR_PALEGRAY);
      End
      Else
      Begin
        FBox(Hps, X + 2, Y + 22, X + 13, Y + 26, CLR_YELLOW, CLR_BROWN);
        FBox(Hps, X + 1, Y + 4, X + 30, Y + 23, CLR_YELLOW, CLR_BROWN);
      End;
    K_DRIVES, K_SYS, K_TEMPL :
      Begin
        FBox(Hps, X + 2, Y + 22, X + 13, Y + 26, CLR_YELLOW, CLR_BROWN);
        FBox(Hps, X + 1, Y + 4, X + 30, Y + 23, CLR_YELLOW, CLR_BROWN);
        If Kind = K_DRIVES Then FBox(Hps, X + 7, Y + 8, X + 24, Y + 15, CLR_PALEGRAY, CLR_BLACK)
        Else If Kind = K_SYS Then
        Begin
          FBox(Hps, X + 9, Y + 8, X + 22, Y + 18, CLR_DARKBLUE, CLR_BLACK);
          GText(Hps, X + 12, Y + 5, '2', CLR_WHITE, CLR_DARKBLUE);
        End
        Else FBox(Hps, X + 8, Y + 6, X + 23, Y + 19, CLR_WHITE, CLR_DARKGRAY);
      End;
    K_CMD :
      Begin
        FBox(Hps, X + 1, Y + 4, X + 30, Y + 28, CLR_BLACK, CLR_PALEGRAY);
        FBox(Hps, X + 1, Y + 24, X + 30, Y + 28, CLR_DARKBLUE, CLR_PALEGRAY);
        GText(Hps, X + 2, Y + 6, 'OS/2', CLR_WHITE, CLR_BLACK);
      End;
    K_PROG :
      Begin
        FBox(Hps, X + 2, Y + 4, X + 29, Y + 28, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 3, Y + 23, X + 28, Y + 27, CLR_DARKBLUE, CLR_DARKBLUE);
        FBox(Hps, X + 4, Y + 6, X + 27, Y + 21, CLR_WHITE, CLR_DARKGRAY);
      End;
    K_BATCH, K_FILE, K_PRINTFILE :
      Begin
        FBox(Hps, X + 6, Y + 2, X + 25, Y + 29, CLR_WHITE, CLR_BLACK);
        GLn(Hps, X + 9, Y + 22, X + 22, Y + 22, CLR_DARKGRAY);
        GLn(Hps, X + 9, Y + 18, X + 22, Y + 18, CLR_DARKGRAY);
        GLn(Hps, X + 9, Y + 14, X + 22, Y + 14, CLR_DARKGRAY);
        If Kind = K_BATCH Then
        Begin
          FBox(Hps, X + 1, Y + 1, X + 17, Y + 12, CLR_BLACK, CLR_BLACK);
          GText(Hps, X + 2, Y - 2, 'C>', CLR_WHITE, CLR_BLACK);
        End
        Else If Kind = K_PRINTFILE Then
        Begin
          FBox(Hps, X + 14, Y + 1, X + 31, Y + 10, CLR_PALEGRAY, CLR_BLACK);
          GBox(Hps, X + 26, Y + 3, X + 28, Y + 4, CLR_GREEN, DRO_FILL);
        End;
      End;
    K_HELP, K_INFO :
      Begin
        FBox(Hps, X + 4, Y + 4, X + 27, Y + 27, CLR_BLUE, CLR_DARKBLUE);
        If Kind = K_HELP Then GText(Hps, X + 12, Y + 8, '?', CLR_WHITE, CLR_BLUE)
        Else GText(Hps, X + 12, Y + 8, 'i', CLR_WHITE, CLR_BLUE);
      End;
    K_PRINTER :
      Begin
        FBox(Hps, X + 9, Y + 20, X + 22, Y + 29, CLR_WHITE, CLR_BLACK);
        FBox(Hps, X + 2, Y + 8, X + 29, Y + 20, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 7, Y + 2, X + 24, Y + 9, CLR_WHITE, CLR_BLACK);
        GBox(Hps, X + 24, Y + 15, X + 26, Y + 16, CLR_GREEN, DRO_FILL);
      End;
    K_SHUT :
      Begin
        FBox(Hps, X + 6, Y + 4, X + 25, Y + 27, CLR_RED, CLR_DARKRED);
        GBox(Hps, X + 14, Y + 13, X + 17, Y + 24, CLR_WHITE, DRO_FILL);
      End;
    K_WINLIST :
      Begin
        FBox(Hps, X + 1, Y + 12, X + 20, Y + 29, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 11, Y + 2, X + 30, Y + 19, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 12, Y + 16, X + 29, Y + 18, CLR_DARKBLUE, CLR_DARKBLUE);
      End;
  End;
End;

{ petite icone (16 x 16) d'une action }
Procedure SmallIcon(Hps, Kind, X, Y : LongInt);
Begin
  Case Kind Of
    K_LOCK :
      Begin
        { cadenas }
        GBox(Hps, X + 5, Y + 9, X + 10, Y + 14, CLR_DARKGRAY, DRO_OUTLINE);
        FBox(Hps, X + 3, Y + 2, X + 12, Y + 9, CLR_YELLOW, CLR_BROWN);
        GBox(Hps, X + 7, Y + 4, X + 8, Y + 6, CLR_BLACK, DRO_FILL);
      End;
    K_FIND :
      Begin
        { loupe }
        FBox(Hps, X + 2, Y + 7, X + 10, Y + 14, CLR_CYAN, CLR_BLACK);
        GLn(Hps, X + 10, Y + 7, X + 14, Y + 2, CLR_BLACK);
        GLn(Hps, X + 11, Y + 7, X + 15, Y + 2, CLR_BLACK);
      End;
    K_SHUT :
      Begin
        FBox(Hps, X + 2, Y + 2, X + 13, Y + 13, CLR_RED, CLR_DARKRED);
        GBox(Hps, X + 7, Y + 6, X + 8, Y + 12, CLR_WHITE, DRO_FILL);
      End;
    K_WINLIST :
      Begin
        FBox(Hps, X + 1, Y + 6, X + 9, Y + 14, CLR_PALEGRAY, CLR_BLACK);
        FBox(Hps, X + 6, Y + 1, X + 14, Y + 9, CLR_WHITE, CLR_BLACK);
        GLn(Hps, X + 7, Y + 8, X + 13, Y + 8, CLR_DARKBLUE);
      End;
  End;
End;

Function SmallKind(K : LongInt) : LongInt;
Begin
  Case K Of
    0 : SmallKind := K_LOCK;
    1 : SmallKind := K_FIND;
    2 : SmallKind := K_SHUT;
  Else
    SmallKind := K_WINLIST;
  End;
End;

Function SmallName(K : LongInt) : String;
Begin
  Case K Of
    0 : SmallName := 'Verrouiller';
    1 : SmallName := 'Rechercher';
    2 : SmallName := 'Arret';
  Else
    SmallName := 'Liste des fenetres';
  End;
End;

{ boutons de la barre : 0..3 actions ; 100 + r : objet r ; 200 + r : tiroir r }
Procedure SmallRect(K : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Begin
  X1 := Pad + (K Mod 2) * (SmW + 1);
  If K < 2 Then Y1 := Pad + SmH + 1 Else Y1 := Pad;
  X2 := X1 + SmW - 1; Y2 := Y1 + SmH - 1;
End;

Procedure ObjRect(R : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Begin
  X1 := ObjX0 + R * (BtnW + 4);
  Y1 := Pad; X2 := X1 + BtnW - 1; Y2 := Y1 + BtnH - 1;
End;

Procedure ArrRect(R : LongInt; Var X1, Y1, X2, Y2 : LongInt);
Begin
  ObjRect(R, X1, Y1, X2, Y2);
  Y1 := Pad + BtnH + 1; Y2 := Y1 + ArrH - 1;
End;

Function HitBar(X, Y : LongInt) : LongInt;
Var K, X1, Y1, X2, Y2, R : LongInt;
Begin
  R := -1;
  For K := 0 To 3 Do
  Begin
    SmallRect(K, X1, Y1, X2, Y2);
    If (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2) Then R := K;
  End;
  For K := 0 To BarCount - 1 Do
  Begin
    ObjRect(K, X1, Y1, X2, Y2);
    If (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2) Then R := 100 + K;
    ArrRect(K, X1, Y1, X2, Y2);
    { la fleche s'etend jusqu'au bord de la barre }
    If (X >= X1) And (X <= X2) And (Y >= Y1) And (Y <= Y2 + Pad) Then R := 200 + K;
  End;
  HitBar := R;
End;

Procedure PaintBar(H : LongInt);
Var Hps, K, X1, Y1, X2, Y2, O, N, Cx : LongInt; Rc : Array[0..3] Of LongInt; Dn : Boolean;
Begin
  Hps := WinBeginPaint(H, 0, LongInt(@Rc));
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  Bevel(Hps, 0, 0, Rc[2] - 1, Rc[3] - 1, False);
  Bevel(Hps, 1, 1, Rc[2] - 2, Rc[3] - 2, False);
  For K := 0 To 3 Do
  Begin
    SmallRect(K, X1, Y1, X2, Y2);
    Dn := (Pressed = K) And (PressArr = 0);
    Bevel(Hps, X1, Y1, X2, Y2, Dn);
    If Focus = K Then GBox(Hps, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, CLR_DARKBLUE, DRO_OUTLINE);
    SmallIcon(Hps, SmallKind(K), X1 + 3, Y1 + 3);
  End;
  GLn(Hps, ObjX0 - 5, Pad, ObjX0 - 5, Rc[3] - Pad - 1, CLR_DARKGRAY);
  GLn(Hps, ObjX0 - 4, Pad, ObjX0 - 4, Rc[3] - Pad - 1, CLR_WHITE);
  N := BarCount;
  For K := 0 To N - 1 Do
  Begin
    O := BarObj(K);
    ObjRect(K, X1, Y1, X2, Y2);
    Bevel(Hps, X1, Y1, X2, Y2, Pressed = 100 + K);
    If Focus = 100 + K Then GBox(Hps, X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, CLR_DARKBLUE, DRO_OUTLINE);
    BigIcon(Hps, Ob(O)^.Kind, Ob(O)^.Path, X1 + 6, Y1 + 8);
    { tiroir : fleche vers le haut (vers le bas s'il est ouvert) }
    ArrRect(K, X1, Y1, X2, Y2);
    Bevel(Hps, X1, Y1, X2, Y2, (Pressed = 200 + K) Or (DrwOf = O));
    Cx := (X1 + X2) Div 2;
    If DrwCount(O) > 0 Then
    Begin
      If DrwOf = O Then
      Begin
        GLn(Hps, Cx - 4, Y1 + 6, Cx + 4, Y1 + 6, CLR_BLACK);
        GLn(Hps, Cx - 3, Y1 + 5, Cx + 3, Y1 + 5, CLR_BLACK);
        GLn(Hps, Cx - 2, Y1 + 4, Cx + 2, Y1 + 4, CLR_BLACK);
        GLn(Hps, Cx - 1, Y1 + 3, Cx + 1, Y1 + 3, CLR_BLACK);
      End
      Else
      Begin
        GLn(Hps, Cx - 4, Y1 + 3, Cx + 4, Y1 + 3, CLR_BLACK);
        GLn(Hps, Cx - 3, Y1 + 4, Cx + 3, Y1 + 4, CLR_BLACK);
        GLn(Hps, Cx - 2, Y1 + 5, Cx + 2, Y1 + 5, CLR_BLACK);
        GLn(Hps, Cx - 1, Y1 + 6, Cx + 1, Y1 + 6, CLR_BLACK);
      End;
    End;
  End;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Demandes au bureau (PMSHELL)                                          }
{ ==================================================================== }

Procedure Request(S : String);
Var Hd, N : LongInt;
Begin
  Hd := ValI(PrfGet('PMSHELL', 'HWND'), 0);
  N := ValI(PrfGet('PMSHELL', 'REQSEQ'), 0) + 1;
  If N > 9999 Then N := 1;
  PrfPut('PMSHELL', 'REQSEQ', IStr(N));
  PrfPut('PMSHELL', 'REQ' + IStr(N), S);
  If (Hd = 0) Or (WinPostMsg(Hd, WM_REQUEST, N, 0) = 0) Then
  Begin
    PrfDel('PMSHELL', 'REQ' + IStr(N));
    ShowMsg('Le bureau (PMSHELL) ne repond pas.', 'LaunchPad', MB_OK Or MB_ERROR);
  End;
End;

{ ==================================================================== }
{ Bulle d'aide                                                          }
{ ==================================================================== }

Function HoverName(Hv : LongInt) : String;
Begin
  If Hv < 0 Then HoverName := ''
  Else If Hv < 4 Then HoverName := SmallName(Hv)
  Else If (Hv >= 100) And (Hv < 200) And (BarObj(Hv - 100) >= 0) Then HoverName := Ob(BarObj(Hv - 100))^.Name
  Else If (Hv >= 200) And (BarObj(Hv - 200) >= 0) And (DrwCount(BarObj(Hv - 200)) > 0) Then
    HoverName := 'Tiroir : ' + Ob(BarObj(Hv - 200))^.Name
  Else HoverName := '';
End;

Procedure HideTip;
Begin
  If TipShown <> 0 Then Dummy := WinSetWindowPos(TipHw, 0, 0, 0, 0, 0, SWP_HIDE);
  TipShown := 0;
End;

Procedure ShowTip;
Var S : String; X1, Y1, X2, Y2, W, X, Y : LongInt;
Begin
  S := HoverName(Hover);
  If S = '' Then Exit;
  If Hover < 4 Then SmallRect(Hover, X1, Y1, X2, Y2)
  Else If Hover < 200 Then ObjRect(Hover - 100, X1, Y1, X2, Y2)
  Else ArrRect(Hover - 200, X1, Y1, X2, Y2);
  W := Length(S) * 8 + 8;
  X := MaxI(0, MinI(ScrW - W, BarX + X1));
  Y := BarY + BarH + 2;
  If Y + 20 > ScrH Then Y := BarY - 22;
  Dummy := WinSetWindowText(TipHw, Z(S));
  Dummy := WinSetWindowPos(TipHw, HWND_TOP, X, Y, W, 20, SWP_MOVE Or SWP_SIZE Or SWP_SHOW Or SWP_ZORDER);
  Dummy := WinInvalidateRect(TipHw, 0, 1);
  TipShown := 1;
End;

Function TipProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps : LongInt; Rc : Array[0..3] Of LongInt; B : Array[0..127] Of Byte;
Begin
  TipProc := 0;
  If Msg = WM_PAINT Then
  Begin
    Hps := WinBeginPaint(H, 0, LongInt(@Rc));
    Dummy := WinQueryWindowRect(H, LongInt(@Rc));
    Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_YELLOW);
    GBox(Hps, 0, 0, Rc[2] - 1, Rc[3] - 1, CLR_BLACK, DRO_OUTLINE);
    B[0] := 0;
    Dummy := WinQueryWindowText(H, 120, LongInt(@B));
    GText(Hps, 4, 2, GetZ(LongInt(@B)), CLR_BLACK, CLR_YELLOW);
    Dummy := WinEndPaint(Hps);
  End
  Else TipProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

{ ==================================================================== }
{ Tiroirs                                                               }
{ ==================================================================== }

Procedure CloseDrawer;
Begin
  If DrwHw <> 0 Then
  Begin
    Dummy := WinDestroyWindow(DrwHw);
    DrwHw := 0;
  End;
  DrwOf := -1;
  Dummy := WinInvalidateRect(BarHw, 0, 1);
End;

Procedure OpenDrawer(R : LongInt);
Var O, N, X1, Y1, X2, Y2, X, Y, Hh : LongInt;
Begin
  O := BarObj(R);
  If O < 0 Then Exit;
  If DrwOf = O Then
  Begin
    CloseDrawer;
    Exit;
  End;
  CloseDrawer;
  N := DrwCount(O);
  If N = 0 Then Exit;
  HideTip;
  ArrRect(R, X1, Y1, X2, Y2);
  Hh := N * DrwRowH + 6;
  X := MaxI(0, MinI(ScrW - DrwW, BarX + X1));
  Y := BarY + BarH;
  If Y + Hh > ScrH Then Y := MaxI(0, BarY - Hh);
  DrwOf := O;
  DrwHw := WinCreateWindow(HWND_DESKTOP, Z('LPDrawer'), Z2(Ob(O)^.Name), WS_VISIBLE, X, Y, DrwW, Hh, 0, HWND_TOP, 2, 0, 0);
  Dummy := WinInvalidateRect(BarHw, 0, 1);
End;

{ rang d'un objet du tiroir sous le point }
Function HitDrawer(Y : LongInt) : LongInt;
Var N, R : LongInt;
Begin
  N := DrwCount(DrwOf);
  R := (N * DrwRowH + 3 - Y) Div DrwRowH;
  If (Y < 3) Or (R < 0) Or (R >= N) Then R := -1;
  HitDrawer := R;
End;

Procedure RunObj(O : LongInt); Forward;

Function DrawerProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, K, N, O, Y, R : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  DrawerProc := 0;
  Case Msg Of
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, LongInt(@Rc));
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
        Bevel(Hps, 0, 0, Rc[2] - 1, Rc[3] - 1, False);
        If DrwOf >= 0 Then
        Begin
          N := DrwCount(DrwOf);
          For K := 0 To N - 1 Do
          Begin
            O := DrwObj(DrwOf, K);
            Y := Rc[3] - 3 - (K + 1) * DrwRowH;
            If Pressed = 300 + K Then Bevel(Hps, 2, Y, Rc[2] - 3, Y + DrwRowH - 1, True);
            BigIcon(Hps, Ob(O)^.Kind, Ob(O)^.Path, 4, Y + 2);
            GText(Hps, 40, Y + 10, Copy(Ob(O)^.Name, 1, 18), CLR_BLACK, CLR_PALEGRAY);
          End;
        End;
        Dummy := WinEndPaint(Hps);
      End;
    WM_BUTTON1DOWN :
      Begin
        Pressed := 300 + HitDrawer(S16(Mp1 Shr 16));
        Dummy := WinInvalidateRect(H, 0, 1);
        DrawerProc := 1;
      End;
    WM_BUTTON1UP :
      Begin
        R := HitDrawer(S16(Mp1 Shr 16));
        K := Pressed;
        Pressed := -1;
        Dummy := WinInvalidateRect(H, 0, 1);
        If (R >= 0) And (K = 300 + R) And (DrwOf >= 0) Then
        Begin
          O := DrwObj(DrwOf, R);
          CloseDrawer;
          RunObj(O);
        End;
        DrawerProc := 1;
      End;
    WM_BUTTON2DOWN : DrawerProc := 1;
    WM_BUTTON2UP :
      Begin
        { retirer un objet du tiroir }
        R := HitDrawer(S16(Mp1 Shr 16));
        If (R >= 0) And (DrwOf >= 0) Then
        Begin
          O := DrwObj(DrwOf, R);
          If WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z('Retirer "' + Ob(O)^.Name + '" du tiroir ?'),
                           Z2('LaunchPad'), 0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) = MBID_YES Then
          Begin
            Ob(O)^.Use := 0;
            SaveObjs;
            CloseDrawer;
          End;
        End;
        DrawerProc := 1;
      End;
    WM_CHAR :
      If ((Lo16(Mp1) And KC_KEYUP) = 0) And ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) And (Hi16(Mp2) = VK_ESC) Then
        CloseDrawer
      Else DrawerProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  Else
    DrawerProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Verrouillage de l'ecran                                               }
{ ==================================================================== }

Procedure Unlock;
Begin
  Dummy := WinStopTimer(Hab, LockHw, 2);
  Dummy := WinSetSysModalWindow(HWND_DESKTOP, 0);
  Dummy := WinSetCapture(HWND_DESKTOP, 0);
  Dummy := WinDestroyWindow(LockHw);
  LockHw := 0;
  Dummy := WinInvalidateRect(HWND_DESKTOP, 0, 1);
End;

Procedure Lockup;
Begin
  If LockHw <> 0 Then Exit;
  CloseDrawer;
  HideTip;
  LockPw := PrfGet('LAUNCHPAD', 'MOTDEPASSE');
  LockTyped := ''; LockTick := 0; LockBad := 0;
  LockX := (ScrW - 256) Div 2; LockY := (ScrH - 96) Div 2;
  LockHw := WinCreateWindow(HWND_DESKTOP, Z('LPLock'), Z2('Verrouillage'), WS_VISIBLE, 0, 0, ScrW, ScrH, 0, HWND_TOP,
                            3, 0, 0);
  If LockHw = 0 Then Exit;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, LockHw);
  Dummy := WinSetFocus(HWND_DESKTOP, LockHw);
  Dummy := WinSetCapture(HWND_DESKTOP, LockHw);
  Dummy := WinSetSysModalWindow(HWND_DESKTOP, LockHw);
  Dummy := WinStartTimer(Hab, LockHw, 2, 250);
End;

Function LockProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Hps, Fl, Ch, Vk, K : LongInt; Rc : Array[0..3] Of LongInt; S : String;
Begin
  LockProc := 0;
  Case Msg Of
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, LongInt(@Rc));
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_BLACK);
        FBox(Hps, LockX, LockY, LockX + 255, LockY + 95, CLR_DARKBLUE, CLR_WHITE);
        GText(Hps, LockX + 16, LockY + 70, 'OS/2 - systeme verrouille', CLR_WHITE, CLR_DARKBLUE);
        If LockPw = '' Then GText(Hps, LockX + 16, LockY + 40, 'Entree : deverrouiller', CLR_YELLOW, CLR_DARKBLUE)
        Else
        Begin
          GText(Hps, LockX + 16, LockY + 44, 'Mot de passe, puis Entree :', CLR_YELLOW, CLR_DARKBLUE);
          S := '';
          For K := 1 To MinI(Length(LockTyped), 26) Do S := S + '*';
          FBox(Hps, LockX + 16, LockY + 22, LockX + 239, LockY + 39, CLR_WHITE, CLR_BLACK);
          GText(Hps, LockX + 20, LockY + 23, S, CLR_BLACK, CLR_WHITE);
        End;
        If LockBad <> 0 Then GText(Hps, LockX + 16, LockY + 4, 'Mot de passe incorrect', CLR_RED, CLR_DARKBLUE);
        Dummy := WinEndPaint(Hps);
      End;
    WM_TIMER :
      Begin
        { le verrouillage garde le focus ; le cadre se deplace (economiseur) }
        Inc(LockTick);
        If WinQueryFocus(HWND_DESKTOP) <> H Then Dummy := WinSetFocus(HWND_DESKTOP, H);
        If LockTick Mod 40 = 0 Then
        Begin
          LockX := (LockX * 7 + 61) Mod MaxI(1, ScrW - 256);
          LockY := (LockY * 5 + 37) Mod MaxI(1, ScrH - 96);
          Dummy := WinInvalidateRect(H, 0, 1);
        End;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
        LockProc := 1;
        If (Fl And KC_KEYUP) <> 0 Then Exit;
        If ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
        Begin
          If (LockPw = '') Or (LockTyped = LockPw) Then Unlock
          Else
          Begin
            LockBad := 1; LockTyped := '';
            Dummy := WinAlarm(HWND_DESKTOP, 2);
            Dummy := WinInvalidateRect(H, 0, 1);
          End;
        End
        Else If ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_BACKSPACE) Then
        Begin
          If LockTyped <> '' Then LockTyped := Copy(LockTyped, 1, Length(LockTyped) - 1);
          Dummy := WinInvalidateRect(H, 0, 1);
        End
        Else If ((Fl And KC_CHAR) <> 0) And (Ch >= 32) And (Ch < 256) And (Length(LockTyped) < 60) Then
        Begin
          LockTyped := LockTyped + Chr(Ch);
          LockBad := 0;
          Dummy := WinInvalidateRect(H, 0, 1);
        End;
      End;
    WM_BUTTON1DOWN, WM_BUTTON1UP, WM_BUTTON2DOWN, WM_BUTTON2UP, WM_BUTTON1DBLCLK : LockProc := 1;
    WM_CLOSE : LockProc := 0;
  Else
    LockProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Recherche de fichiers                                                 }
{ ==================================================================== }

{ masque avec * et ? (majuscules) }
Function Match(P, S : String) : Boolean;
Var Ip, Si, Star, Mark : LongInt;
Begin
  Ip := 1; Si := 1; Star := 0; Mark := 0;
  While Si <= Length(S) Do
  Begin
    If (Ip <= Length(P)) And ((P[Ip] = '?') Or (P[Ip] = S[Si])) Then
    Begin
      Inc(Ip); Inc(Si);
    End
    Else If (Ip <= Length(P)) And (P[Ip] = '*') Then
    Begin
      Star := Ip; Mark := Si; Inc(Ip);
    End
    Else If Star > 0 Then
    Begin
      Ip := Star + 1; Inc(Mark); Si := Mark;
    End
    Else
    Begin
      Match := False;
      Exit;
    End;
  End;
  While (Ip <= Length(P)) And (P[Ip] = '*') Do Inc(Ip);
  Match := Ip > Length(P);
End;

Procedure SetStatus(S : String);
Begin
  If FindSt <> 0 Then Dummy := WinSetWindowText(FindSt, Z(S));
End;

Procedure PushDir(S : String);
Begin
  If StkN >= StkCap Then Grow(StkBuf, StkCap, SizeOf(TPath));
  StkAt(StkN)^ := S;
  Inc(StkN);
End;

Procedure AddResult(S : String);
Var B : Array[0..259] Of Byte;
Begin
  If ResN >= ResCap Then Grow(ResBuf, ResCap, SizeOf(TPath));
  ResAt(ResN)^ := S;
  Inc(ResN);
  PutZ(LongInt(@B), S);
  Dummy := WinSendMsg(FindLb, LM_INSERTITEM, -1, LongInt(@B));
End;

Procedure StopSearch;
Begin
  If Searching <> 0 Then Dummy := WinStopTimer(Hab, FindCl, 3);
  Searching := 0;
  SetStatus(IStr(ResN) + ' objet(s) trouve(s) (' + IStr(Scanned) + ' repertoire(s) parcouru(s)).');
End;

Procedure StartSearch;
Var B : Array[0..259] Of Byte; D, L, Drv : LongInt;
Begin
  B[0] := 0;
  Dummy := WinQueryWindowText(FindEf, 250, LongInt(@B));
  Mask := UpStr(GetZ(LongInt(@B)));
  If Mask = '' Then Mask := '*';
  If (Pos('*', Mask) = 0) And (Pos('?', Mask) = 0) Then Mask := '*' + Mask + '*';
  Dummy := WinSendMsg(FindLb, LM_DELETEALL, 0, 0);
  StkN := 0; ResN := 0; Scanned := 0;
  D := 0; L := 0;
  Dummy := DosQueryCurrentDisk(LongInt(@D), LongInt(@L));
  If L = 0 Then L := 4;
  For Drv := 25 DownTo 2 Do
    If (L Shr Drv) And 1 <> 0 Then PushDir(Chr(65 + Drv) + ':\');
  Searching := 1;
  SetStatus('Recherche de ' + Mask + '...');
  Dummy := WinStartTimer(Hab, FindCl, 3, 30);
End;

{ un repertoire de la pile }
Procedure SearchStep;
Var H, N, A, Rc, K, Off : LongInt; Dir, S : String;
Begin
  If StkN = 0 Then
  Begin
    StopSearch;
    Exit;
  End;
  Dec(StkN);
  Dir := StkAt(StkN)^;
  Inc(Scanned);
  H := -1; N := 1;
  Rc := DosFindFirst(Z(Dir + '*.*'), LongInt(@H), $37, LongInt(@FindBuf), 4096, LongInt(@N), 1);
  While (Rc = 0) And (N > 0) Do
  Begin
    Off := 0;
    While N > 0 Do
    Begin
      A := RdL(LongInt(@FindBuf) + Off + 24);
      S := '';
      For K := 0 To RdB(LongInt(@FindBuf) + Off + 28) - 1 Do S := S + Chr(RdB(LongInt(@FindBuf) + Off + 29 + K));
      If (S <> '.') And (S <> '..') Then
      Begin
        If Match(Mask, UpStr(S)) Then
        Begin
          If (A And $10) <> 0 Then AddResult(Dir + S + '\') Else AddResult(Dir + S);
        End;
        If ((A And $10) <> 0) And (Length(Dir) + Length(S) < 120) Then PushDir(Dir + S + '\');
      End;
      Dec(N);
      If RdL(LongInt(@FindBuf) + Off) = 0 Then N := 0
      Else Off := Off + RdL(LongInt(@FindBuf) + Off);
    End;
    N := 1;
    Rc := DosFindNext(H, LongInt(@FindBuf), 4096, LongInt(@N));
  End;
  If H <> -1 Then Dummy := DosFindClose(H);
  SetStatus('Recherche : ' + Dir + ' (' + IStr(ResN) + ')');
End;

Procedure OpenResult;
Var Sel, K : LongInt; S : String;
Begin
  Sel := WinSendMsg(FindLb, LM_QUERYSELECTION, -1, 0);
  If (Sel < 0) Or (Sel >= ResN) Then Exit;
  S := ResAt(Sel)^;
  K := KindOfTarget(S);
  Case K Of
    K_FOLDER : Request('OPEN ' + S);
    K_PROG : Request('RUN ' + S);
    K_BATCH : Request('BATCH ' + S);
  Else
    Request('VIEW ' + S);
  End;
End;

Procedure OpenFind;
Var Fl : LongInt;
Begin
  If FindFr <> 0 Then
  Begin
    Dummy := WinSetWindowPos(FindFr, HWND_TOP, 0, 0, 0, 0, SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
    Dummy := WinSetFocus(HWND_DESKTOP, FindEf);
    Exit;
  End;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER;
  FindCl := 0;
  FindFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('LPFind'), Z2('Rechercher des objets'), 0, 0, 0,
                               LongInt(@FindCl));
  If FindFr = 0 Then Exit;
  Dummy := WinSetWindowPos(FindFr, HWND_TOP, (ScrW - 420) Div 2, (ScrH - 300) Div 2 + 40, 420, 300,
                           SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, FindFr);
  Dummy := WinSetFocus(HWND_DESKTOP, FindEf);
End;

Procedure FindLayout(Cx, Cy : LongInt);
Begin
  If FindLbl <> 0 Then Dummy := WinSetWindowPos(FindLbl, 0, 8, Cy - 24, 52, 18, SWP_MOVE Or SWP_SIZE);
  Dummy := WinSetWindowPos(FindEf, 0, 64, Cy - 24, MaxI(40, Cx - 176), 18, SWP_MOVE Or SWP_SIZE);
  Dummy := WinSetWindowPos(FindGo, 0, Cx - 104, Cy - 26, 96, 22, SWP_MOVE Or SWP_SIZE);
  Dummy := WinSetWindowPos(FindLb, 0, 8, 26, MaxI(40, Cx - 16), MaxI(20, Cy - 58), SWP_MOVE Or SWP_SIZE);
  Dummy := WinSetWindowPos(FindSt, 0, 8, 4, MaxI(40, Cx - 16), 18, SWP_MOVE Or SWP_SIZE);
End;

Function FindProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk : LongInt;
Begin
  FindProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        FindCl := H;
        FindLbl := WinCreateWindow(H, WC_STATIC, Z('Nom :'), WS_VISIBLE Or SS_TEXT, 8, 200, 52, 18, H, HWND_TOP, 14, 0, 0);
        FindEf := WinCreateWindow(H, WC_ENTRYFIELD, Z('*.EXE'), WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
                                  64, 200, 200, 18, H, HWND_TOP, ID_EF, 0, 0);
        Dummy := WinSendMsg(FindEf, EM_SETTEXTLIMIT, 120, 0);
        FindGo := WinCreateWindow(H, WC_BUTTON, Z('Rechercher'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                                  300, 200, 96, 22, H, HWND_TOP, ID_GO, 0, 0);
        FindLb := WinCreateWindow(H, WC_LISTBOX, 0, WS_VISIBLE Or WS_TABSTOP, 8, 26, 380, 160, H, HWND_TOP, ID_LIST, 0, 0);
        FindSt := WinCreateWindow(H, WC_STATIC, Z('Masque : * et ? (exemple : *.CMD)'), WS_VISIBLE Or SS_TEXT,
                                  8, 4, 380, 18, H, HWND_TOP, ID_STAT, 0, 0);
      End;
    WM_SIZE : FindLayout(Lo16(Mp2), Hi16(Mp2));
    WM_COMMAND :
      If Lo16(Mp1) = ID_GO Then
      Begin
        If Searching <> 0 Then StopSearch Else StartSearch;
      End;
    WM_CONTROL :
      If (Lo16(Mp1) = ID_LIST) And (Hi16(Mp1) = LN_ENTER) Then OpenResult;
    WM_TIMER :
      If (Lo16(Mp1) = 3) And (Searching <> 0) Then
      Begin
        SearchStep;
        If Searching <> 0 Then SearchStep;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
          StartSearch
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then
          Dummy := WinPostMsg(H, WM_CLOSE, 0, 0)
        Else FindProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE :
      Begin
        If Searching <> 0 Then StopSearch;
        Dummy := WinDestroyWindow(FindFr);
        FindFr := 0; FindCl := 0; FindEf := 0; FindLb := 0; FindSt := 0; FindGo := 0; FindLbl := 0;
      End;
  Else
    FindProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Saisie d'un texte (ajout d'un objet, mot de passe, impression)        }
{ ==================================================================== }

Procedure AskText(Mode, Parent : LongInt; Title, Prompt, Default : String);
Var Fl : LongInt;
Begin
  If InFr <> 0 Then Dummy := WinDestroyWindow(InFr);
  InMode := Mode; InParent := Parent; InTitle := Title; InPrompt := Prompt;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  InCl := 0;
  InFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('LPInput'), Z2(Title), 0, 0, 0, LongInt(@InCl));
  If InFr = 0 Then Exit;
  Dummy := WinSetWindowText(InEf, Z(Default));
  Dummy := WinSetWindowPos(InFr, HWND_TOP, (ScrW - 400) Div 2, (ScrH - 120) Div 2, 400, 120,
                           SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, InFr);
  Dummy := WinSetFocus(HWND_DESKTOP, InEf);
End;

Procedure CloseInput;
Begin
  If InFr <> 0 Then Dummy := WinDestroyWindow(InFr);
  InFr := 0; InCl := 0; InEf := 0;
End;

Procedure RefreshJobs; Forward;

Procedure InputDone;
Var B : Array[0..259] Of Byte; S : String; K, Rc, Id : LongInt;
Begin
  B[0] := 0;
  Dummy := WinQueryWindowText(InEf, 250, LongInt(@B));
  S := GetZ(LongInt(@B));
  K := InMode;
  CloseInput;
  Case K Of
    IN_ADD :
      If S <> '' Then
      Begin
        S := UpStr(S);
        If (Length(S) >= 2) And (S[2] = ':') And (Length(S) = 2) Then S := S + '\';
        If (S[Length(S)] <> '\') And (DosQueryPathInfo(Z(S), 1, LongInt(@InfoBuf), 64) = 0) And
           ((RdL(LongInt(@InfoBuf) + 20) And $10) <> 0) Then S := S + '\';
        If Not FileExists(S) And Not ((Length(S) = 3) And (S[2] = ':')) Then
          ShowMsg('SYS0002: Le fichier ' + S + ' est introuvable.', 'LaunchPad', MB_OK Or MB_ERROR)
        Else
        Begin
          Dummy := NewObj(KindOfTarget(S), InParent, BaseName(S), S);
          If BaseName(S) = '' Then Ob(ObjCap - 1)^.Name := S;
          SaveObjs;
          CloseDrawer;
          Dummy := WinSendMsg(BarHw, WM_USER + 2, 0, 0);
        End;
      End;
    IN_PASSWORD :
      Begin
        If S = '' Then PrfDel('LAUNCHPAD', 'MOTDEPASSE') Else PrfPut('LAUNCHPAD', 'MOTDEPASSE', S);
        If S = '' Then ShowMsg('Verrouillage sans mot de passe.', 'LaunchPad', MB_OK Or MB_INFORMATION)
        Else ShowMsg('Mot de passe de verrouillage enregistre.', 'LaunchPad', MB_OK Or MB_INFORMATION);
      End;
    IN_PRINT :
      If S <> '' Then
      Begin
        Id := 0;
        PutZ(LongInt(@B), S);
        Rc := SplQmWriteFile(Z(''), LongInt(@B), 0, LongInt(@Id));
        If Rc <> 0 Then ShowMsg('Impression de ' + S + ' impossible (erreur ' + IStr(Rc) + ').', 'Imprimante',
                                MB_OK Or MB_ERROR)
        Else ShowMsg(S + ' : travail ' + IStr(Id) + ' envoye a l''imprimante.', 'Imprimante', MB_OK Or MB_INFORMATION);
        RefreshJobs;
      End;
  End;
End;

Function InputProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Fl, Vk, Hps : LongInt; Rc : Array[0..3] Of LongInt;
Begin
  InputProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        InCl := H;
        InEf := WinCreateWindow(H, WC_ENTRYFIELD, 0, WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN,
                                8, 40, 376, 18, H, HWND_TOP, ID_EF, 0, 0);
        Dummy := WinSendMsg(InEf, EM_SETTEXTLIMIT, 120, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                                 8, 6, 80, 22, H, HWND_TOP, ID_OK, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 96, 6, 80, 22, H, HWND_TOP, ID_CANCEL, 0, 0);
      End;
    WM_PAINT :
      Begin
        Hps := WinBeginPaint(H, 0, LongInt(@Rc));
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
        GText(Hps, 8, Rc[3] - 22, InPrompt, CLR_BLACK, CLR_PALEGRAY);
        Dummy := WinEndPaint(Hps);
      End;
    WM_COMMAND :
      If Lo16(Mp1) = ID_OK Then InputDone
      Else If Lo16(Mp1) = ID_CANCEL Then CloseInput;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
          InputDone
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then CloseInput
        Else InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_CLOSE : CloseInput;
  Else
    InputProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Imprimante : file d'attente du spouleur (PMSPL.DLL)                   }
{ ==================================================================== }

Procedure RefreshJobs;
Var Ret, Tot, Need, K, Rc, St, A : LongInt; B : Array[0..259] Of Byte; S, D : String;
Begin
  If PrnFr = 0 Then Exit;
  Dummy := WinSendMsg(PrnLb, LM_DELETEALL, 0, 0);
  Ret := 0; Tot := 0; Need := 0;
  Rc := SplQmListJobs(0, 2, LongInt(@InfoBuf), SizeOf(InfoBuf), LongInt(@Ret), LongInt(@Tot), LongInt(@Need));
  JobN := 0;
  If (Rc = 0) Or (Ret > 0) Then
    For K := 0 To Ret - 1 Do
      If JobN < 256 Then
      Begin
        A := LongInt(@InfoBuf) + K * 28;
        JobIds[JobN] := RdW(A);
        St := RdW(A + 10);
        D := GetZ(RdL(A + 24));
        If D = '' Then D := '(sans nom)';
        S := IStr(RdW(A)) + '  ' + D + '  ' + IStr(RdL(A + 16)) + ' octets';
        If (St And 3) = 1 Then S := S + '  (suspendu)'
        Else If (St And 3) = 2 Then S := S + '  (impression)';
        PutZ(LongInt(@B), S);
        Dummy := WinSendMsg(PrnLb, LM_INSERTITEM, -1, LongInt(@B));
        Inc(JobN);
      End;
  If JobN = 0 Then Dummy := WinSetWindowText(PrnStat, Z('Aucun travail en attente.'))
  Else Dummy := WinSetWindowText(PrnStat, Z(IStr(JobN) + ' travail(aux) dans la file d''attente.'));
End;

Procedure OpenPrinter;
Var Fl : LongInt;
Begin
  If PrnFr <> 0 Then
  Begin
    Dummy := WinSetWindowPos(PrnFr, HWND_TOP, 0, 0, 0, 0, SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
    RefreshJobs;
    Exit;
  End;
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER;
  PrnCl := 0;
  PrnFr := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('LPPrinter'), Z2('Imprimante - file d''attente'), 0, 0, 0,
                              LongInt(@PrnCl));
  If PrnFr = 0 Then Exit;
  Dummy := WinSetWindowPos(PrnFr, HWND_TOP, (ScrW - 440) Div 2, (ScrH - 260) Div 2 + 30, 440, 260,
                           SWP_SIZE Or SWP_MOVE Or SWP_SHOW Or SWP_ZORDER Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, PrnFr);
  RefreshJobs;
  Dummy := WinStartTimer(Hab, PrnCl, 4, 2000);
End;

Procedure ClosePrinter;
Begin
  If PrnFr = 0 Then Exit;
  Dummy := WinStopTimer(Hab, PrnCl, 4);
  Dummy := WinDestroyWindow(PrnFr);
  PrnFr := 0; PrnCl := 0; PrnLb := 0; PrnStat := 0;
End;

Function PrinterProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Sel, Cx, Cy, Rc : LongInt;
Begin
  PrinterProc := 0;
  Case Msg Of
    WM_CREATE :
      Begin
        PrnCl := H;
        PrnLb := WinCreateWindow(H, WC_LISTBOX, 0, WS_VISIBLE Or WS_TABSTOP, 8, 54, 400, 120, H, HWND_TOP, ID_LIST, 0, 0);
        PrnStat := WinCreateWindow(H, WC_STATIC, 0, WS_VISIBLE Or SS_TEXT, 8, 32, 400, 18, H, HWND_TOP, ID_STAT, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Imprimer...'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 8, 6, 112, 22, H, HWND_TOP, ID_PRINT, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Annuler le travail'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 128, 6, 152, 22, H, HWND_TOP, ID_CANJOB, 0, 0);
        Dummy := WinCreateWindow(H, WC_BUTTON, Z('Actualiser'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                                 288, 6, 96, 22, H, HWND_TOP, ID_REFR, 0, 0);
      End;
    WM_SIZE :
      Begin
        Cx := Lo16(Mp2); Cy := Hi16(Mp2);
        If PrnLb <> 0 Then Dummy := WinSetWindowPos(PrnLb, 0, 8, 54, MaxI(40, Cx - 16), MaxI(20, Cy - 62), SWP_MOVE Or SWP_SIZE);
        If PrnStat <> 0 Then Dummy := WinSetWindowPos(PrnStat, 0, 8, 32, MaxI(40, Cx - 16), 18, SWP_MOVE Or SWP_SIZE);
      End;
    WM_COMMAND :
      Case Lo16(Mp1) Of
        ID_PRINT : AskText(IN_PRINT, -1, 'Imprimer un fichier', 'Fichier a imprimer :', 'C:\CONFIG.SYS');
        ID_REFR : RefreshJobs;
        ID_CANJOB :
          Begin
            Sel := WinSendMsg(PrnLb, LM_QUERYSELECTION, -1, 0);
            If (Sel >= 0) And (Sel < JobN) Then
            Begin
              Rc := SplQmCancelJob(0, JobIds[Sel]);
              If Rc <> 0 Then ShowMsg('Annulation impossible (erreur ' + IStr(Rc) + ').', 'Imprimante', MB_OK Or MB_ERROR);
              RefreshJobs;
            End;
          End;
      End;
    WM_TIMER : If Lo16(Mp1) = 4 Then RefreshJobs;
    WM_CLOSE : ClosePrinter;
  Else
    PrinterProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Actions et objets                                                     }
{ ==================================================================== }

Procedure RunObj(O : LongInt);
Begin
  If (O < 0) Or (Ob(O)^.Use = 0) Then Exit;
  HideTip;
  Case Ob(O)^.Kind Of
    K_FOLDER : Request('OPEN ' + Ob(O)^.Path);
    K_DRIVES : Request('DRIVES');
    K_CMD : Request('CMD');
    K_HELP : Request('HELP');
    K_SYS : Request('SYS');
    K_INFO : Request('INFO');
    K_TEMPL : Request('TEMPL');
    K_PROG : Request('RUN ' + Ob(O)^.Path);
    K_BATCH : Request('BATCH ' + Ob(O)^.Path);
    K_FILE : Request('VIEW ' + Ob(O)^.Path);
    K_SHUT : Request('SHUTDOWN');
    K_WINLIST : Request('WINLIST');
    K_LOCK : Lockup;
    K_FIND : OpenFind;
    K_PRINTER : OpenPrinter;
    K_PRINTFILE : AskText(IN_PRINT, -1, 'Imprimer un fichier', 'Fichier a imprimer :', 'C:\CONFIG.SYS');
  End;
End;

Procedure RunSmall(K : LongInt);
Begin
  HideTip;
  CloseDrawer;
  Case K Of
    0 : Lockup;
    1 : OpenFind;
    2 : Request('SHUTDOWN');
    3 : Request('WINLIST');
  End;
End;

{ taille de la barre selon le nombre d'objets }
Procedure SizeBar;
Var N : LongInt;
Begin
  N := BarCount;
  BarW := ObjX0 + N * (BtnW + 4) + Pad;
  BarH := Pad + BtnH + 1 + ArrH + Pad;
  If BarW > ScrW Then BarW := ScrW;
  BarX := MaxI(0, MinI(ScrW - BarW, BarX));
  BarY := MaxI(0, MinI(ScrH - BarH, BarY));
  If BarHw <> 0 Then
  Begin
    Dummy := WinSetWindowPos(BarHw, HWND_TOP, BarX, BarY, BarW, BarH, SWP_MOVE Or SWP_SIZE Or SWP_ZORDER);
    Dummy := WinInvalidateRect(BarHw, 0, 1);
  End;
End;

Procedure SaveBarPos;
Begin
  PrfPut('LAUNCHPAD', 'POS', IStr(BarX) + ',' + IStr(BarY));
End;

{ menus contextuels }
Procedure MenuStart;
Begin
  MenuLen := 6; MenuCnt := 0;
End;

Procedure MenuAdd(Id : LongInt; S : String);
Begin
  If Id = 0 Then WrW(LongInt(@MenuTpl) + MenuLen, 4) Else WrW(LongInt(@MenuTpl) + MenuLen, 1);
  WrW(LongInt(@MenuTpl) + MenuLen + 2, 0);
  WrW(LongInt(@MenuTpl) + MenuLen + 4, Id);
  MenuLen := MenuLen + 6;
  If Id <> 0 Then
  Begin
    PutZ(LongInt(@MenuTpl) + MenuLen, S);
    MenuLen := MenuLen + Length(S) + 1;
  End;
  Inc(MenuCnt);
End;

Procedure BarMenu(X, Y : LongInt);
Begin
  MenuAt := HitBar(X, Y);
  MenuStart;
  If (MenuAt >= 100) And (MenuAt < 300) Then
  Begin
    MenuAdd(CM_ADD, 'Ajouter au tiroir...');
    MenuAdd(CM_REMOVE, 'Retirer cet objet');
  End
  Else MenuAdd(CM_ADD, 'Ajouter un programme ou un dossier...');
  MenuAdd(0, '');
  MenuAdd(CM_PASSWORD, 'Mot de passe de verrouillage...');
  MenuAdd(CM_QUIT, 'Fermer le LaunchPad');
  WrW(LongInt(@MenuTpl), MenuLen); WrW(LongInt(@MenuTpl) + 2, 0); WrW(LongInt(@MenuTpl) + 4, MenuCnt);
  If MenuH <> 0 Then Dummy := WinDestroyWindow(MenuH);
  MenuH := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuTpl));
  If MenuH <> 0 Then Dummy := WinPopupMenu(BarHw, BarHw, MenuH, X, Y, CM_ADD, 0);
End;

Procedure BarCommand(Cmd : LongInt);
Var O, R : LongInt;
Begin
  R := MenuAt;
  O := -1;
  If (R >= 100) And (R < 200) Then O := BarObj(R - 100)
  Else If (R >= 200) And (R < 300) Then O := BarObj(R - 200);
  Case Cmd Of
    CM_ADD :
      If O >= 0 Then AskText(IN_ADD, O, 'Ajouter au tiroir', 'Programme, fichier ou dossier (chemin complet) :', 'C:\')
      Else AskText(IN_ADD, -1, 'Ajouter au LaunchPad', 'Programme, fichier ou dossier (chemin complet) :', 'C:\');
    CM_REMOVE :
      If O >= 0 Then
        If WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z('Retirer "' + Ob(O)^.Name + '" (et son tiroir) du LaunchPad ?'),
                         Z2('LaunchPad'), 0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) = MBID_YES Then
        Begin
          CloseDrawer;
          For R := 0 To ObjCap - 1 Do
            If (Ob(R)^.Use <> 0) And (Ob(R)^.Parent = O) Then Ob(R)^.Use := 0;
          Ob(O)^.Use := 0;
          SaveObjs;
          SizeBar;
        End;
    CM_PASSWORD : AskText(IN_PASSWORD, -1, 'Verrouillage', 'Mot de passe (vide : aucun) :', '');
    CM_QUIT :
      If WinMessageBox(HWND_DESKTOP, HWND_DESKTOP, Z('Fermer le LaunchPad ? (il revient au prochain demarrage)'),
                       Z2('LaunchPad'), 0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) = MBID_YES Then
      Begin
        SaveBarPos;
        Halt(0);
      End;
  End;
End;

{ objet depose depuis le bureau (PMSHELL : LAUNCHPAD, DEPOT = cible,
  mp1/mp2 : point du depot sur l'ecran) }
Procedure Dropped(Sx, Sy : LongInt);
Var T, Nm : String; K, Hv, Par, O : LongInt;
Begin
  T := PrfGet('LAUNCHPAD', 'DEPOT');
  Nm := PrfGet('LAUNCHPAD', 'DEPOTNOM');
  PrfDel('LAUNCHPAD', 'DEPOT'); PrfDel('LAUNCHPAD', 'DEPOTNOM');
  K := KindOfTarget(T);
  If K = 0 Then
  Begin
    Dummy := WinAlarm(HWND_DESKTOP, 2);
    Exit;
  End;
  If Nm = '' Then Nm := BaseName(T);
  If Nm = '' Then Nm := T;
  Par := -1;
  Hv := HitBar(Sx - BarX, Sy - BarY);
  If (Hv >= 100) And (Hv < 300) Then
  Begin
    O := BarObj((Hv Mod 100));
    If O >= 0 Then Par := O;
  End;
  If T[1] = '*' Then T := '';
  Dummy := NewObj(K, Par, Nm, T);
  SaveObjs;
  CloseDrawer;
  SizeBar;
  If Par >= 0 Then OpenDrawer(Hv Mod 100);
End;

Procedure Activate(Hv : LongInt);
Begin
  If Hv < 0 Then Exit;
  If Hv < 4 Then RunSmall(Hv)
  Else If (Hv >= 100) And (Hv < 200) Then
  Begin
    CloseDrawer;
    RunObj(BarObj(Hv - 100));
  End
  Else If Hv >= 200 Then OpenDrawer(Hv - 200);
End;

Function NextFocus(F, D : LongInt) : LongInt;
Var Ord1, N : LongInt;
Begin
  N := BarCount;
  If F < 4 Then Ord1 := F Else Ord1 := 4 + (F Mod 100);
  Ord1 := Ord1 + D;
  If Ord1 < 0 Then Ord1 := 3 + N;
  If Ord1 > 3 + N Then Ord1 := 0;
  If Ord1 < 4 Then NextFocus := Ord1 Else NextFocus := 100 + Ord1 - 4;
End;

Function BarProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var X, Y, Hv, Fl, Vk, Ch, K : LongInt; Pt : Array[0..1] Of LongInt;
Begin
  BarProc := 0;
  Case Msg Of
    WM_PAINT : PaintBar(H);
    WM_BUTTON1DOWN :
      Begin
        Dummy := WinSetFocus(HWND_DESKTOP, H);
        HideTip;
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        Hv := HitBar(X, Y);
        Pressed := Hv; PressArr := 0;
        If Hv < 0 Then
        Begin
          { glisser le fond : deplacer la barre }
          Pt[0] := X; Pt[1] := Y;
          Dummy := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@Pt), 1);
          Dragging := 1; Moved := 0; DragX0 := Pt[0]; DragY0 := Pt[1]; DragBX := BarX; DragBY := BarY;
        End;
        Dummy := WinSetCapture(HWND_DESKTOP, H);
        Dummy := WinInvalidateRect(H, 0, 1);
        BarProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        If Dragging <> 0 Then
        Begin
          Pt[0] := X; Pt[1] := Y;
          Dummy := WinMapWindowPoints(H, HWND_DESKTOP, LongInt(@Pt), 1);
          If AbsI(Pt[0] - DragX0) + AbsI(Pt[1] - DragY0) > 2 Then Moved := 1;
          If Moved <> 0 Then
          Begin
            BarX := MaxI(0, MinI(ScrW - BarW, DragBX + Pt[0] - DragX0));
            BarY := MaxI(0, MinI(ScrH - BarH, DragBY + Pt[1] - DragY0));
            Dummy := WinSetWindowPos(H, 0, BarX, BarY, 0, 0, SWP_MOVE);
          End;
        End
        Else
        Begin
          Hv := HitBar(X, Y);
          If Hv <> Hover Then
          Begin
            Hover := Hv; HoverTicks := 0;
            HideTip;
          End;
        End;
        BarProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_BUTTON1UP :
      Begin
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        If Dragging <> 0 Then
        Begin
          Dragging := 0;
          If Moved <> 0 Then
          Begin
            SaveBarPos;
            CloseDrawer;
          End;
        End
        Else
        Begin
          Hv := HitBar(X, Y);
          K := Pressed;
          Pressed := -1;
          Dummy := WinInvalidateRect(H, 0, 1);
          If (Hv >= 0) And (Hv = K) Then Activate(Hv);
        End;
        Pressed := -1;
        BarProc := 1;
      End;
    WM_BUTTON2DOWN : BarProc := 1;
    WM_BUTTON2UP :
      Begin
        HideTip;
        BarMenu(S16(Mp1), S16(Mp1 Shr 16));
        BarProc := 1;
      End;
    WM_COMMAND : BarCommand(Lo16(Mp1));
    WM_TIMER :
      If Lo16(Mp1) = 1 Then
      Begin
        { bulle d'aide : la souris reste sur le meme bouton }
        Pt[0] := 0; Pt[1] := 0;
        Dummy := WinQueryPointerPos(HWND_DESKTOP, LongInt(@Pt));
        X := Pt[0] - BarX; Y := Pt[1] - BarY;
        If (X < 0) Or (Y < 0) Or (X >= BarW) Or (Y >= BarH) Or (Dragging <> 0) Or (Pressed >= 0) Or (LockHw <> 0) Then
        Begin
          Hover := -1;
          HideTip;
        End
        Else
        Begin
          Hv := HitBar(X, Y);
          If Hv <> Hover Then
          Begin
            Hover := Hv; HoverTicks := 0;
            HideTip;
          End
          Else
          Begin
            Inc(HoverTicks);
            If (HoverTicks = 2) And (TipShown = 0) And (DrwHw = 0) Then ShowTip;
          End;
        End;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Ch := Lo16(Mp2); Vk := Hi16(Mp2);
        BarProc := 1;
        If (Fl And KC_KEYUP) <> 0 Then Exit;
        If (Fl And KC_VIRTUALKEY) <> 0 Then
          Case Vk Of
            VK_LEFT : Focus := NextFocus(Focus, -1);
            VK_RIGHT, VK_TAB : Focus := NextFocus(Focus, 1);
            VK_UP : If Focus >= 100 Then OpenDrawer(Focus - 100);
            VK_DOWN, VK_ESC : CloseDrawer;
            VK_ENTER, VK_NEWLINE, VK_SPACE : Activate(Focus);
          Else
            BarProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
          End
        Else BarProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
        Dummy := WinInvalidateRect(H, 0, 1);
      End;
    WM_REQUEST : Dropped(Mp1, Mp2);
    WM_USER + 2 : SizeBar;
  Else
    BarProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

Var S0 : String; P0 : LongInt;

BEGIN
  ObjBuf := 0; ObjCap := 0; StkBuf := 0; StkCap := 0; ResBuf := 0; ResCap := 0;
  BarHw := 0; DrwHw := 0; DrwOf := -1; TipHw := 0; LockHw := 0; Focus := 100; Pressed := -1; Hover := -1;
  TipShown := 0; Dragging := 0; MenuH := 0; MenuAt := -1;
  FindFr := 0; PrnFr := 0; InFr := 0; Searching := 0; FindLbl := 0;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  If Hmq = 0 Then
  Begin
    WriteLn('LAUNCHPAD : Presentation Manager (PMWIN.DLL) ne peut pas demarrer.');
    Halt(1);
  End;
  ScrW := WinQuerySysValue(HWND_DESKTOP, 20); ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  If ScrW <= 0 Then ScrW := 640;
  If ScrH <= 0 Then ScrH := 480;
  Dummy := WinRegisterClass(Hab, Z('LPBar'), LongInt(@BarProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('LPDrawer'), LongInt(@DrawerProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('LPTip'), LongInt(@TipProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('LPLock'), LongInt(@LockProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('LPFind'), LongInt(@FindProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('LPPrinter'), LongInt(@PrinterProc), 0, 0);
  Dummy := WinRegisterClass(Hab, Z('LPInput'), LongInt(@InputProc), 0, 0);
  LoadObjs;
  { position : OS2.INI, sinon en bas au centre }
  BarX := -1; BarY := -1;
  S0 := PrfGet('LAUNCHPAD', 'POS');
  P0 := Pos(',', S0);
  If P0 > 1 Then
  Begin
    BarX := ValI(Copy(S0, 1, P0 - 1), -1);
    BarY := ValI(Copy(S0, P0 + 1, 20), -1);
  End;
  BarX := MaxI(0, BarX); BarY := MaxI(0, BarY);
  SizeBar;
  If PrfGet('LAUNCHPAD', 'POS') = '' Then
  Begin
    BarX := (ScrW - BarW) Div 2; BarY := 8;
  End;
  TipHw := WinCreateWindow(HWND_DESKTOP, Z('LPTip'), 0, 0, 0, 0, 10, 10, 0, HWND_TOP, 4, 0, 0);
  BarHw := WinCreateWindow(HWND_DESKTOP, Z('LPBar'), Z2('LaunchPad'), WS_VISIBLE, BarX, BarY, BarW, BarH, 0, HWND_TOP,
                           1, 0, 0);
  If BarHw = 0 Then Halt(1);
  { le bureau trouve la barre (objets deposes) }
  PrfPut('LAUNCHPAD', 'HWND', IStr(BarHw));
  Dummy := WinStartTimer(Hab, BarHw, 1, 400);
  Repeat
    If WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Then Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Until False;
END.
