{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: GETSRC - Telecharger le code source d'OS2-Zero (dossier
                Developer Kit du bureau).
}

Program GETSRC;

{$R-,S-,I-}

{ Compilation : OS2PC GETSRC.PAS   (produit GETSRC.EXE)

  Copie le code source actuel d'OS/2-0 depuis GitHub (depot
  gladir/OS2-0, branche par defaut) dans le dossier C:\SOURCE\OS2-0\ :
  seulement les fichiers du projet, sans l'historique ni les donnees de
  Git. La liste des fichiers vient de l'API de GitHub (arbre de la
  branche, api.github.com), puis chaque fichier est telecharge de
  raw.githubusercontent.com, en https:// par TLS32.DLL, sur une seule
  connexion gardee ouverte d'un fichier a l'autre (HTTP/1.1). Le
  travail se fait dans un fil d'execution a part : la fenetre reste
  active (barre de progression, pourcentage, fichier en cours, vitesse,
  temps restant) et Annuler l'interrompt.

  Telecharger : copie tous les fichiers. Mettre a jour : seulement les
  fichiers nouveaux ou modifies (la liste C:\SOURCE\OS2-0.LST garde
  l'empreinte SHA-1 de Git de chaque fichier copie) ; les fichiers
  retires du depot sont effaces. Les images du CD-ROM (IMAGE\*.ISO,
  plusieurs dizaines de Mo) ne sont copiees que si la case est cochee.
  A la fin, l'Explorateur OS2-0 s'ouvre sur le dossier.

  Proxy : SET HTTP_PROXY=hote:port (tunnel CONNECT).
  Parametres (essais) : /DEST:dossier ; /API:https://hote[:port] ;
  /RAW:https://hote[:port] ; /AUTO (telecharger tout de suite) ; /UPDATE
  (mettre a jour tout de suite) ; /ISO (avec les images) ; /NOEXPLORER. }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10; MIA_CHECKED = $2000; MIA_DISABLED = $4000;
  MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_QUERY = $10; MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_NEWLINE = $08; VK_SPACE = $10; VK_LEFT = $15; VK_RIGHT = $17; VK_DOWN = $18; VK_ENTER = $1E;
  VK_F1 = $20; VK_F2 = $21;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_PINK = 3; CLR_GREEN = 4; CLR_CYAN = 5;
  CLR_YELLOW = 6; CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12;
  CLR_DARKCYAN = 13; CLR_BROWN = 14; CLR_PALEGRAY = 15;
  VK_ESC = $0F; MB_ERROR = $40;
  WM_BUTTON1UP = $0072;
  CWant = 524; CHWant = 360;
  MaxEnt = 6000; MaxMan = 6000;
  JsonCap = 4194304; PoolCap = 1048576;
  ST_IDLE = 0; ST_LIST = 1; ST_GET = 2; ST_DONE = 3; ST_ERROR = 4; ST_CANCEL = 5;
  { boutons }
  B_GET = 0; B_UPD = 1; B_CANCEL = 2;
  BtnY = 320; BtnH = 28; BtnW = 118;
  BarX1 = 22; BarX2 = 501; BarY = 214; BarH = 22;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps, Seed : LongInt;
  { travail (fil a part) : etat partage avec la fenetre }
  State, Mode, Abort, WorkTid, NFiles, NDone, NSkipped, NDeleted, TotBytes, DoneBytes, CurSize, CurDone : LongInt;
  CurName, ErrMsg, Branch, ApiBase, RawBase, Dest, ListFile, ProxyHost, Token : String;
  ProxyPort, WithIso, NoExplorer, AutoStart, Explored, Pressed, Hover, NeedFull : LongInt;
  LocalCount, FreeKb, ListBytes : LongInt;
  { arbre du depot }
  EOfs, ELen, ESize, EOk : Array[0..MaxEnt - 1] Of LongInt;
  EType : Array[0..MaxEnt - 1] Of Byte;
  NEnt, JsonBuf, JsonLen, Pool, PoolLen : LongInt;
  { liste des fichiers deja copies (C:\SOURCE\OS2-0.LST) }
  MOfs, MLen, MSize, MNext, MUsed : Array[0..MaxMan - 1] Of LongInt;
  MHead : Array[0..4095] Of LongInt;
  NMan, MPool, MPoolLen : LongInt;
  { connexion HTTP gardee ouverte }
  CSock, CConn, CTls, CPort : LongInt;
  CHost, CScheme : String;
  RBuf : Array[0..32767] Of Byte;
  RPos, RLen : LongInt;
  SBuf : Array[0..2047] Of Byte;
  { vitesse : octets mesures a chaque seconde }
  SpT, SpB : Array[0..7] Of LongInt;
  SpN, LastTick, LastState : LongInt;
  Msg : String;
  NameZ, NameZ2, TxtBuf : Array[0..1023] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Font : Array[0..4095] Of Byte;
  FontH : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  ArgBuf, FailBuf : Array[0..511] Of Byte;

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


Function SockInit : LongInt; External 'TCPIP32' Name 'sock_init';
Function Socket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function Connect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function Send(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function Recv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function SoClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function SockErrno : LongInt; External 'TCPIP32' Name 'sock_errno';
Function GetHostByName(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function TlsOpen(S, PHost : LongInt) : LongInt; External 'TLS32' Name 'TLSOPEN';
Function TlsSend(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSSEND';
Function TlsRecv(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSRECV';
Function TlsClose(H : LongInt) : LongInt; External 'TLS32' Name 'TLSCLOSE';
Function TlsError(B, Cb : LongInt) : LongInt; External 'TLS32' Name 'TLSERROR';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryFSInfo(Disk, Level, PBuf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateThread(PTid, PFn, Param, Flags, CbStack : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

Function MinI(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinI := A Else MinI := B;
End;

Function MaxI(A, B : LongInt) : LongInt;
Begin
  If A > B Then MaxI := A Else MaxI := B;
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



Function UpS(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpS := S;
End;

Function LowS(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do If S[K] In ['A'..'Z'] Then S[K] := Chr(Ord(S[K]) + 32);
  LowS := S;
End;

Function TrimS(S : String) : String;
Begin
  While (Length(S) > 0) And (S[1] = ' ') Do Delete(S, 1, 1);
  While (Length(S) > 0) And (S[Length(S)] = ' ') Do Delete(S, Length(S), 1);
  TrimS := S;
End;

Function SVal(S : String; Def : LongInt) : LongInt;
Var V, E : LongInt;
Begin
  Val(TrimS(S), V, E);
  If E <> 0 Then SVal := Def Else SVal := V;
End;

Function HexDigit(C : Char) : LongInt;
Begin
  If C In ['0'..'9'] Then HexDigit := Ord(C) - 48
  Else If C In ['a'..'f'] Then HexDigit := Ord(C) - 87
  Else If C In ['A'..'F'] Then HexDigit := Ord(C) - 55
  Else HexDigit := -1;
End;

{ nombre avec separateur des milliers (1 234 567) }
Function NStr(V : LongInt) : String;
Var S, R : String; K : LongInt;
Begin
  S := IStr(V); R := '';
  For K := 1 To Length(S) Do
  Begin
    R := R + S[K];
    If ((Length(S) - K) Mod 3 = 0) And (K < Length(S)) Then R := R + ' ';
  End;
  NStr := R;
End;

{ taille lisible : 12,3 Mo, 456 Ko, 78 octets }
Function SizeStr(V : LongInt) : String;
Begin
  If V >= 1048576 Then SizeStr := IStr(V Div 1048576) + ',' + IStr((V Mod 1048576) * 10 Div 1048576) + ' Mo'
  Else If V >= 1024 Then SizeStr := IStr(V Div 1024) + ' Ko'
  Else SizeStr := IStr(V) + ' octets';
End;

Function GetEnvS(N : String) : String;
Var P, K : LongInt; S : String;
Begin
  GetEnvS := '';
  P := 0;
  If DosScanEnv(Z(N), LongInt(@P)) <> 0 Then Exit;
  If P = 0 Then Exit;
  S := ''; K := 0;
  While (K < 250) And (RdB(P + K) <> 0) Do
  Begin
    S := S + Chr(RdB(P + K));
    Inc(K);
  End;
  GetEnvS := S;
End;

{ heure en centiemes de seconde depuis minuit }
Function NowCs : LongInt;
Var T : Array[0..15] Of Byte;
Begin
  Dummy := DosGetDateTime(LongInt(@T));
  NowCs := ((T[0] * 60 + T[1]) * 60 + T[2]) * 100 + T[3];
End;

Function FileSize0(P : String) : LongInt;
Var Info : Array[0..31] Of Byte;
Begin
  FileSize0 := -1;
  If DosQueryPathInfo(Z(P), 1, LongInt(@Info), 24) = 0 Then FileSize0 := RdL(LongInt(@Info) + 12);
End;

{ cree un dossier et ses parents (C:\A\B\C) }
Var LastDir : String;

Procedure MakeDirs(D : String);
Var K : LongInt;
Begin
  If D = LastDir Then Exit;
  For K := 4 To Length(D) Do
    If D[K] = '\' Then Dummy := DosCreateDir(Z(Copy(D, 1, K - 1)), 0);
  Dummy := DosCreateDir(Z(D), 0);
  LastDir := D;
End;

{ ==================================================================== }
{ Chemins du depot (reserve Pool : chemin puis empreinte de 40 car.)    }
{ ==================================================================== }

Function PathOf(I : LongInt) : String;
Var K : LongInt; S : String;
Begin
  S := '';
  For K := 0 To MinI(ELen[I], 250) - 1 Do S := S + Chr(RdB(Pool + EOfs[I] + K));
  PathOf := S;
End;

Function ShaOf(I : LongInt) : String;
Var K : LongInt; S : String;
Begin
  S := '';
  For K := 0 To 39 Do S := S + Chr(RdB(Pool + EOfs[I] + ELen[I] + K));
  ShaOf := S;
End;

{ nom local : / devient \ ; lettres accentuees (UTF-8) en page 437 }
Function LocalName(P : String) : String;
Var K, C, C2 : LongInt; R : String;
Begin
  R := Dest + '\';
  K := 1;
  While K <= Length(P) Do
  Begin
    C := Ord(P[K]);
    If C = Ord('/') Then R := R + '\'
    Else If (C >= $C0) And (K < Length(P)) Then
    Begin
      C2 := ((C And $1F) Shl 6) Or (Ord(P[K + 1]) And $3F);
      Inc(K);
      Case C2 Of
        $E9 : R := R + Chr(130);
        $E8 : R := R + Chr(138);
        $EA : R := R + Chr(136);
        $E0 : R := R + Chr(133);
        $E7 : R := R + Chr(135);
        $F4 : R := R + Chr(147);
        $EE : R := R + Chr(140);
        $FB : R := R + Chr(150);
        $F9 : R := R + Chr(151);
      Else
        R := R + '_';
      End;
    End
    Else If C >= $80 Then R := R + '_'
    Else R := R + Chr(C);
    Inc(K);
  End;
  LocalName := R;
End;

{ %XX pour l'adresse (octets UTF-8 conserves) }
Function UrlPath(P : String) : String;
Var K : LongInt; R : String;
Const Hx : String[16] = '0123456789ABCDEF';
Begin
  R := '';
  For K := 1 To Length(P) Do
    If P[K] In ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~', '/'] Then R := R + P[K]
    Else R := R + '%' + Hx[Ord(P[K]) Shr 4 + 1] + Hx[Ord(P[K]) And 15 + 1];
  UrlPath := R;
End;

Function IsIso(I : LongInt) : Boolean;
Var S : String;
Begin
  S := UpS(PathOf(I));
  IsIso := (Length(S) > 4) And (Copy(S, Length(S) - 3, 4) = '.ISO');
End;

{ ==================================================================== }
{ Liste des fichiers deja copies                                        }
{ ==================================================================== }

Function HashS(S : String) : LongInt;
Var K, H : LongInt;
Begin
  H := 0;
  For K := 1 To Length(S) Do H := (H * 31 + Ord(S[K])) And $7FFFFFF;
  HashS := H And 4095;
End;

Function ManPath(M : LongInt) : String;
Var K : LongInt; S : String;
Begin
  S := '';
  For K := 0 To MinI(MLen[M], 250) - 1 Do S := S + Chr(RdB(MPool + MOfs[M] + 40 + K));
  ManPath := S;
End;

Function ManSha(M : LongInt) : String;
Var K : LongInt; S : String;
Begin
  S := '';
  For K := 0 To 39 Do S := S + Chr(RdB(MPool + MOfs[M] + K));
  ManSha := S;
End;

Function ManFind(P : String) : LongInt;
Var M : LongInt;
Begin
  ManFind := -1;
  M := MHead[HashS(P)];
  While M >= 0 Do
  Begin
    If ManPath(M) = P Then
    Begin
      ManFind := M;
      Exit;
    End;
    M := MNext[M];
  End;
End;

Procedure ManAdd(Sha, P : String; Sz : LongInt);
Var K, H : LongInt;
Begin
  If (NMan >= MaxMan) Or (MPoolLen + 40 + Length(P) > PoolCap) Then Exit;
  MOfs[NMan] := MPoolLen; MLen[NMan] := Length(P); MSize[NMan] := Sz; MUsed[NMan] := 0;
  For K := 1 To 40 Do WrB(MPool + MPoolLen + K - 1, Ord(Sha[K]));
  For K := 1 To Length(P) Do WrB(MPool + MPoolLen + 39 + K, Ord(P[K]));
  MPoolLen := MPoolLen + 40 + Length(P);
  H := HashS(P);
  MNext[NMan] := MHead[H]; MHead[H] := NMan;
  Inc(NMan);
End;

{ lignes : empreinte, taille, chemin }
Procedure LoadList;
Var H, Act, N, K, Sz, I : LongInt; Line, Sha, P : String; B : Array[0..4095] Of Byte;
Begin
  NMan := 0; MPoolLen := 0;
  For K := 0 To 4095 Do MHead[K] := -1;
  H := 0; Act := 0;
  If DosOpen(Z(ListFile), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> 0 Then Exit;
  Line := '';
  Repeat
    N := 0;
    If DosRead(H, LongInt(@B), SizeOf(B), LongInt(@N)) <> 0 Then N := 0;
    For I := 0 To N - 1 Do
      If B[I] = 10 Then
      Begin
        If (Length(Line) > 42) And (Line[1] <> '#') Then
        Begin
          Sha := Copy(Line, 1, 40);
          Delete(Line, 1, 41);
          K := Pos(' ', Line);
          If K > 0 Then
          Begin
            Sz := SVal(Copy(Line, 1, K - 1), -1);
            P := Copy(Line, K + 1, 250);
            ManAdd(Sha, P, Sz);
          End;
        End;
        Line := '';
      End
      Else If (B[I] <> 13) And (Length(Line) < 255) Then Line := Line + Chr(B[I]);
  Until N <= 0;
  Dummy := DosClose(H);
End;

Procedure WLine(H : LongInt; S : String);
Var W : LongInt;
Begin
  S := S + #13#10;
  Dummy := DosWrite(H, LongInt(@S) + 1, Length(S), LongInt(@W));
End;

{ liste a jour : fichiers copies ou identiques, plus les anciens qui
  n'ont pas ete touches (travail interrompu) }
Procedure SaveList(Finished : Boolean);
Var H, Act, I, M : LongInt; P : String;
Begin
  H := 0; Act := 0;
  If DosOpen(Z(ListFile), LongInt(@H), LongInt(@Act), 0, 0, $12, $41, 0) <> 0 Then Exit;
  WLine(H, '# OS/2-0 : fichiers copies de GitHub par GETSRC (empreinte SHA-1 de Git, taille, chemin)');
  WLine(H, '# branche ' + Branch);
  For I := 0 To NEnt - 1 Do
    If EType[I] = 0 Then
    Begin
      P := PathOf(I);
      If EOk[I] = 1 Then WLine(H, ShaOf(I) + ' ' + IStr(ESize[I]) + ' ' + P)
      Else
      Begin
        M := ManFind(P);
        If M >= 0 Then WLine(H, ManSha(M) + ' ' + IStr(MSize[M]) + ' ' + P);
      End;
    End;
  If Not Finished Then
    For M := 0 To NMan - 1 Do
      If MUsed[M] = 0 Then WLine(H, ManSha(M) + ' ' + IStr(MSize[M]) + ' ' + ManPath(M));
  Dummy := DosClose(H);
End;

{ ==================================================================== }
{ HTTP/1.1 (https:// par TLS32.DLL), connexion gardee ouverte           }
{ ==================================================================== }

Var
  UScheme, UHost, UPath, NetErr : String;
  UPort, NetReady, HStatus, HClen, HChunked, HClose : LongInt;
  HLocation : String;

Function SplitUrl(Url : String) : Boolean;
Var K : LongInt; Rest : String;
Begin
  SplitUrl := False;
  K := Pos('://', Url);
  If K = 0 Then Exit;
  UScheme := LowS(Copy(Url, 1, K - 1));
  Rest := Copy(Url, K + 3, 255);
  K := Pos('/', Rest);
  If K = 0 Then Begin UHost := Rest; UPath := '/'; End
  Else Begin UHost := Copy(Rest, 1, K - 1); UPath := Copy(Rest, K, 255); End;
  If UScheme = 'https' Then UPort := 443 Else UPort := 80;
  K := Pos(':', UHost);
  If K > 0 Then
  Begin
    UPort := SVal(Copy(UHost, K + 1, 6), UPort);
    UHost := Copy(UHost, 1, K - 1);
  End;
  SplitUrl := (UHost <> '') And ((UScheme = 'http') Or (UScheme = 'https'));
End;

Function HostIp(H : String; Var A0, A1, A2, A3 : LongInt) : Boolean;
Var K, N, V, R, P : LongInt; Num : Boolean; Ip : Array[0..3] Of LongInt; B : Array[0..255] Of Byte;
Begin
  HostIp := False;
  Num := H <> '';
  For K := 1 To Length(H) Do If Not (H[K] In ['0'..'9', '.']) Then Num := False;
  If Num Then
  Begin
    N := 0; V := 0;
    For K := 1 To Length(H) Do
      If H[K] = '.' Then
      Begin
        If N < 4 Then Ip[N] := V And 255;
        Inc(N); V := 0;
      End
      Else V := V * 10 + Ord(H[K]) - 48;
    If N <> 3 Then Exit;
    Ip[3] := V And 255;
  End
  Else
  Begin
    For K := 1 To Length(H) Do B[K - 1] := Ord(H[K]);
    B[Length(H)] := 0;
    R := GetHostByName(LongInt(@B));
    If R = 0 Then Exit;
    P := RdL(RdL(R + 16));
    If P = 0 Then Exit;
    For K := 0 To 3 Do Ip[K] := RdB(P + K);
  End;
  A0 := Ip[0]; A1 := Ip[1]; A2 := Ip[2]; A3 := Ip[3];
  HostIp := True;
End;

Procedure NetClose;
Begin
  If CConn <> 0 Then
  Begin
    If CTls <> 0 Then Dummy := TlsClose(1);
    Dummy := SoClose(CSock);
  End;
  CConn := 0; CTls := 0; RPos := 0; RLen := 0;
End;

Function NSend(P, N : LongInt) : Boolean;
Begin
  If CTls <> 0 Then NSend := TlsSend(1, P, N) = N Else NSend := Send(CSock, P, N, 0) = N;
End;

{ bloc suivant de la connexion ; faux a la fermeture }
Function Fill : Boolean;
Begin
  RPos := 0;
  If CTls <> 0 Then RLen := TlsRecv(1, LongInt(@RBuf), SizeOf(RBuf))
  Else RLen := Recv(CSock, LongInt(@RBuf), SizeOf(RBuf), 0);
  If RLen < 0 Then RLen := 0;
  Fill := RLen > 0;
End;

Function GetB(Var C : LongInt) : Boolean;
Begin
  GetB := False;
  If RPos >= RLen Then If Not Fill Then Exit;
  C := RBuf[RPos];
  Inc(RPos);
  GetB := True;
End;

{ ligne terminee par LF (sans CR) ; faux a la fermeture }
Function GetLine(Var S : String) : Boolean;
Var C : LongInt;
Begin
  GetLine := False;
  S := '';
  Repeat
    If Not GetB(C) Then Exit;
    If C = 10 Then
    Begin
      GetLine := True;
      Exit;
    End;
    If (C <> 13) And (Length(S) < 255) Then S := S + Chr(C);
  Until False;
End;

Function SendStr(S : String) : Boolean;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do SBuf[K - 1] := Ord(S[K]);
  SendStr := NSend(LongInt(@SBuf), Length(S));
End;

{ connexion (et tunnel CONNECT du proxy, poignee de main TLS) }
Function NetOpen : Boolean;
Var Ad : Array[0..15] Of Byte; A0, A1, A2, A3, K, St, Port : LongInt; Host, Line : String; B : Array[0..259] Of Byte;
Begin
  NetOpen := False;
  NetClose;
  If NetReady = 0 Then
  Begin
    If SockInit = 0 Then NetReady := 1
    Else
    Begin
      NetErr := 'Le r' + Chr(130) + 'seau n''est pas disponible (carte r' + Chr(130) + 'seau, DHCP : voir IFCONFIG).';
      Exit;
    End;
  End;
  Host := UHost; Port := UPort;
  If ProxyHost <> '' Then Begin Host := ProxyHost; Port := ProxyPort; End;
  If Not HostIp(Host, A0, A1, A2, A3) Then
  Begin
    NetErr := 'H' + Chr(147) + 'te inconnu : ' + Host + ' (serveur de noms injoignable ?).';
    Exit;
  End;
  For K := 0 To 15 Do Ad[K] := 0;
  Ad[0] := 16; Ad[1] := 2; Ad[2] := Port Shr 8; Ad[3] := Port And 255;
  Ad[4] := A0; Ad[5] := A1; Ad[6] := A2; Ad[7] := A3;
  CSock := Socket(2, 1, 0);
  If CSock < 0 Then
  Begin
    NetErr := 'Impossible de cr' + Chr(130) + 'er une connexion (socket).';
    Exit;
  End;
  If Connect(CSock, LongInt(@Ad), 16) <> 0 Then
  Begin
    NetErr := 'Connexion impossible ' + Chr(133) + ' ' + Host + ':' + IStr(Port) + ' (erreur ' + IStr(SockErrno) + ').';
    Dummy := SoClose(CSock);
    Exit;
  End;
  CConn := 1; CTls := 0; RPos := 0; RLen := 0;
  CHost := UHost; CPort := UPort; CScheme := UScheme;
  If UScheme = 'https' Then
  Begin
    If ProxyHost <> '' Then
    Begin
      If Not SendStr('CONNECT ' + UHost + ':' + IStr(UPort) + ' HTTP/1.1' + #13#10 + 'Host: ' + UHost + ':' +
                     IStr(UPort) + #13#10#13#10) Then
      Begin
        NetErr := 'Le proxy ne r' + Chr(130) + 'pond pas.';
        NetClose;
        Exit;
      End;
      St := 0;
      Repeat
        If Not GetLine(Line) Then
        Begin
          NetErr := 'Le proxy a ferm' + Chr(130) + ' la connexion.';
          NetClose;
          Exit;
        End;
        If (St = 0) And (Line <> '') Then
        Begin
          K := Pos(' ', Line);
          If K > 0 Then St := SVal(Copy(Line, K + 1, 3), 0);
        End;
      Until Line = '';
      If (St < 200) Or (St > 299) Then
      Begin
        NetErr := 'Le proxy refuse le tunnel vers ' + UHost + ' (code ' + IStr(St) + ').';
        NetClose;
        Exit;
      End;
    End;
    For K := 1 To Length(UHost) Do B[K - 1] := Ord(UHost[K]);
    B[Length(UHost)] := 0;
    If TlsOpen(CSock, LongInt(@B)) <> 1 Then
    Begin
      Dummy := TlsError(LongInt(@B), 250);
      Line := ''; K := 0;
      While (K < 200) And (B[K] <> 0) Do Begin Line := Line + Chr(B[K]); Inc(K); End;
      NetErr := 'Connexion s' + Chr(130) + 'curis' + Chr(130) + 'e impossible avec ' + UHost + ' : ' + Line;
      Dummy := SoClose(CSock);
      CConn := 0;
      Exit;
    End;
    CTls := 1;
  End;
  NetOpen := True;
End;

{ ecrit le corps de la reponse : dans JsonBuf (Fh = 0) ou un fichier }
Procedure Sink(Fh, P, N : LongInt);
Var W : LongInt;
Begin
  If N <= 0 Then Exit;
  If Fh = 0 Then
  Begin
    If JsonLen + N > JsonCap - 1 Then N := JsonCap - 1 - JsonLen;
    For W := 0 To N - 1 Do WrB(JsonBuf + JsonLen + W, RdB(P + W));
    JsonLen := JsonLen + N;
  End
  Else If Fh > 0 Then Dummy := DosWrite(Fh, P, N, LongInt(@W));
End;

{ une requete GET ; corps vers JsonBuf (FName = '') ou le fichier FName
  (cree seulement si la reponse est 200) ; resultat : code HTTP, -1
  (erreur reseau, NetErr) ou -2 (interrompu) }
Function HttpGet(Url, FName : String; Api : Boolean) : LongInt;
Var Try0, K, N, Fh, Act, Chunk : LongInt; Reused, Ok : Boolean; Line, HN, HV, PathQ, Req : String;
Begin
  HttpGet := -1;
  If Not SplitUrl(Url) Then
  Begin
    NetErr := 'Adresse non valable : ' + Url;
    Exit;
  End;
  For Try0 := 1 To 2 Do
  Begin
    If Abort <> 0 Then Begin HttpGet := -2; Exit; End;
    Reused := (CConn <> 0) And (CHost = UHost) And (CPort = UPort) And (CScheme = UScheme);
    If Not Reused Then If Not NetOpen Then Exit;
    PathQ := UPath;
    If (ProxyHost <> '') And (UScheme = 'http') Then PathQ := Url;
    Req := 'GET ' + PathQ + ' HTTP/1.1' + #13#10 + 'Host: ' + UHost;
    If ((UScheme = 'https') And (UPort <> 443)) Or ((UScheme = 'http') And (UPort <> 80)) Then
      Req := Req + ':' + IStr(UPort);
    Req := Req + #13#10 + 'User-Agent: OS2-0-GETSRC/1.0 (OS/2-0)' + #13#10;
    If Api Then
    Begin
      Req := Req + 'Accept: application/vnd.github+json' + #13#10;
      { jeton facultatif (SET GITHUB_TOKEN=...) : 5 000 demandes par heure au lieu de 60 }
      If Token <> '' Then Req := Req + 'Authorization: Bearer ' + Token + #13#10;
    End
    Else Req := Req + 'Accept: */*' + #13#10;
    Req := Req + 'Accept-Encoding: identity' + #13#10 + 'Connection: keep-alive' + #13#10#13#10;
    Ok := SendStr(Req);
    If Ok Then Ok := GetLine(Line);
    If Not Ok Then
    Begin
      NetClose;
      { connexion gardee mais fermee par le serveur : une seconde fois }
      If Reused And (Try0 = 1) Then Continue;
      NetErr := 'Le serveur ' + UHost + ' a ferm' + Chr(130) + ' la connexion.';
      Exit;
    End;
    HStatus := 0;
    K := Pos(' ', Line);
    If K > 0 Then HStatus := SVal(Copy(Line, K + 1, 3), 0);
    HClen := -1; HChunked := 0; HClose := 0; HLocation := '';
    Repeat
      If Not GetLine(Line) Then
      Begin
        NetClose;
        NetErr := 'R' + Chr(130) + 'ponse incompl' + Chr(138) + 'te de ' + UHost + '.';
        Exit;
      End;
      K := Pos(':', Line);
      If K > 0 Then
      Begin
        HN := LowS(TrimS(Copy(Line, 1, K - 1))); HV := TrimS(Copy(Line, K + 1, 255));
        If HN = 'content-length' Then HClen := SVal(HV, -1)
        Else If (HN = 'transfer-encoding') And (Pos('chunked', LowS(HV)) > 0) Then HChunked := 1
        Else If (HN = 'connection') And (Pos('close', LowS(HV)) > 0) Then HClose := 1
        Else If HN = 'location' Then HLocation := HV;
      End;
    Until Line = '';
    { fichier de destination (reponse 200 seulement) ; l'API garde aussi
      le corps d'une erreur (message de GitHub) }
    Fh := -1;
    If Api Then Fh := 0;
    If (HStatus = 200) And (FName <> '') Then
    Begin
      Fh := 0; Act := 0;
      If DosOpen(Z(FName), LongInt(@Fh), LongInt(@Act), 0, 0, $12, $41, 0) <> 0 Then
      Begin
        NetErr := 'Impossible d''' + Chr(130) + 'crire ' + FName + ' (disque plein ou prot' + Chr(130) + 'g' + Chr(130) +
                  ' ?).';
        NetClose;
        Exit;
      End;
    End
    Else If HStatus = 200 Then Fh := 0;
    { corps }
    If HChunked <> 0 Then
    Begin
      Repeat
        If Not GetLine(Line) Then Begin HClose := 1; Break; End;
        Chunk := 0;
        For K := 1 To Length(Line) Do
          If HexDigit(Line[K]) >= 0 Then Chunk := Chunk * 16 + HexDigit(Line[K]) Else Break;
        If Chunk = 0 Then
        Begin
          Repeat Until (Not GetLine(Line)) Or (Line = '');
          Break;
        End;
        While Chunk > 0 Do
        Begin
          If Abort <> 0 Then Break;
          If RPos >= RLen Then If Not Fill Then Begin HClose := 1; Break; End;
          N := MinI(Chunk, RLen - RPos);
          Sink(Fh, LongInt(@RBuf) + RPos, N);
          RPos := RPos + N; Chunk := Chunk - N;
          CurDone := CurDone + N; DoneBytes := DoneBytes + N;
        End;
        If (Abort <> 0) Or (HClose <> 0) And (Chunk > 0) Then Break;
        Dummy := Ord(GetLine(Line));
      Until False;
    End
    Else
    Begin
      K := 0;
      While (HClen < 0) Or (K < HClen) Do
      Begin
        If Abort <> 0 Then Break;
        If RPos >= RLen Then If Not Fill Then Begin HClose := 1; Break; End;
        N := RLen - RPos;
        If HClen >= 0 Then N := MinI(N, HClen - K);
        Sink(Fh, LongInt(@RBuf) + RPos, N);
        RPos := RPos + N; K := K + N;
        CurDone := CurDone + N; DoneBytes := DoneBytes + N;
      End;
      If (HClen >= 0) And (K < HClen) And (Abort = 0) Then
      Begin
        If Fh > 0 Then Dummy := DosClose(Fh);
        NetClose;
        NetErr := 'Transfert incomplet de ' + UHost + ' (' + IStr(K) + ' octets sur ' + IStr(HClen) + ').';
        Exit;
      End;
    End;
    If Fh > 0 Then Dummy := DosClose(Fh);
    If (HClose <> 0) Or (Abort <> 0) Then NetClose;
    If Abort <> 0 Then
    Begin
      If FName <> '' Then Dummy := DosDelete(Z(FName));
      HttpGet := -2;
      Exit;
    End;
    HttpGet := HStatus;
    Exit;
  End;
End;

{ ==================================================================== }
{ Lecture de l'arbre (JSON de l'API de GitHub)                          }
{ ==================================================================== }

Function JB(P : LongInt) : LongInt;
Begin
  If (P < 0) Or (P >= JsonLen) Then JB := 0 Else JB := RdB(JsonBuf + P);
End;

{ cherche Key (avec ses guillemets) a partir de P ; -1 si absent }
Function JFind(Key : String; P, Lim : LongInt) : LongInt;
Var K, L : LongInt; Ok : Boolean;
Begin
  JFind := -1;
  L := Length(Key);
  While P + L <= Lim Do
  Begin
    Ok := True;
    For K := 1 To L Do If JB(P + K - 1) <> Ord(Key[K]) Then Begin Ok := False; Break; End;
    If Ok Then
    Begin
      JFind := P;
      Exit;
    End;
    Inc(P);
  End;
End;

{ chaine JSON qui commence au guillemet P ; P avance apres la fin }
Function JStr(Var P : LongInt) : String;
Var S : String; C : LongInt;
Begin
  S := '';
  Inc(P);
  While P < JsonLen Do
  Begin
    C := JB(P);
    If C = Ord('"') Then Begin Inc(P); Break; End;
    If C = Ord('\') Then
    Begin
      Inc(P);
      C := JB(P);
      If C = Ord('u') Then
      Begin
        C := HexDigit(Chr(JB(P + 1))) * 4096 + HexDigit(Chr(JB(P + 2))) * 256 + HexDigit(Chr(JB(P + 3))) * 16 +
             HexDigit(Chr(JB(P + 4)));
        P := P + 4;
        If C < 128 Then S := S + Chr(C)
        Else If C < 2048 Then S := S + Chr($C0 Or (C Shr 6)) + Chr($80 Or (C And 63))
        Else S := S + '_';
      End
      Else If C = Ord('n') Then S := S + #10
      Else If C = Ord('t') Then S := S + #9
      Else S := S + Chr(C);
    End
    Else If Length(S) < 255 Then S := S + Chr(C);
    Inc(P);
  End;
  JStr := S;
End;

{ valeur de la cle Key dans l'objet [P, Lim) : chaine ou nombre }
Function JVal(Key : String; P, Lim : LongInt) : String;
Var Q : LongInt; S : String;
Begin
  JVal := '';
  Q := JFind('"' + Key + '"', P, Lim);
  If Q < 0 Then Exit;
  Q := Q + Length(Key) + 2;
  While (Q < Lim) And (JB(Q) In [32, 9, 10, 13, Ord(':')]) Do Inc(Q);
  If JB(Q) = Ord('"') Then JVal := JStr(Q)
  Else
  Begin
    S := '';
    While (Q < Lim) And (Chr(JB(Q)) In ['0'..'9', '-', 'a'..'z']) Do Begin S := S + Chr(JB(Q)); Inc(Q); End;
    JVal := S;
  End;
End;

Function ParseTree : Boolean;
Var P, Q, E, K : LongInt; Path, Typ, Sha : String;
Begin
  ParseTree := False;
  NEnt := 0; PoolLen := 0;
  P := JFind('"tree"', 0, JsonLen);
  If P < 0 Then Exit;
  P := JFind('[', P, JsonLen);
  If P < 0 Then Exit;
  Repeat
    Q := JFind('{', P, JsonLen);
    If Q < 0 Then Break;
    E := JFind('}', Q, JsonLen);
    If E < 0 Then Break;
    Path := JVal('path', Q, E); Typ := JVal('type', Q, E); Sha := JVal('sha', Q, E);
    If (Path <> '') And (Length(Sha) = 40) And (NEnt < MaxEnt) And (PoolLen + Length(Path) + 40 < PoolCap) Then
    Begin
      EOfs[NEnt] := PoolLen; ELen[NEnt] := Length(Path);
      For K := 1 To Length(Path) Do WrB(Pool + PoolLen + K - 1, Ord(Path[K]));
      For K := 1 To 40 Do WrB(Pool + PoolLen + Length(Path) + K - 1, Ord(Sha[K]));
      PoolLen := PoolLen + Length(Path) + 40;
      If Typ = 'blob' Then EType[NEnt] := 0 Else If Typ = 'tree' Then EType[NEnt] := 1 Else EType[NEnt] := 2;
      ESize[NEnt] := SVal(JVal('size', Q, E), 0);
      EOk[NEnt] := 0;
      Inc(NEnt);
    End;
    P := E + 1;
    { fin du tableau ? }
    Q := P;
    While (Q < JsonLen) And (JB(Q) In [32, 9, 10, 13, Ord(',')]) Do Inc(Q);
    If JB(Q) = Ord(']') Then Break;
  Until False;
  ParseTree := NEnt > 0;
End;

{ ==================================================================== }
{ Le travail (fil d'execution a part)                                   }
{ ==================================================================== }

{ "message" d'une reponse d'erreur de l'API }
Function ApiMsg : String;
Var S : String;
Begin
  S := JVal('message', 0, JsonLen);
  If Length(S) > 120 Then S := Copy(S, 1, 117) + '...';
  ApiMsg := S;
End;

Function Fail(S : String) : LongInt;
Begin
  ErrMsg := S;
  CurName := '';
  State := ST_ERROR;
  NetClose;
  Fail := 0;
End;

Function LimitMsg : String;
Var S : String;
Begin
  S := ApiMsg;
  If Pos('rate limit', S) > 0 Then
    LimitMsg := 'GitHub limite les demandes (60 par heure sans jeton) : r' + Chr(130) + 'essayez plus tard.'
  Else If S <> '' Then LimitMsg := 'GitHub refuse la demande : ' + S
  Else LimitMsg := 'GitHub refuse la demande (erreur 403).';
End;

Function Worker(Arg : LongInt) : LongInt;
Var R, I, M, Sz : LongInt; S, P, L : String; Buf : Array[0..23] Of Byte;
Begin
  Worker := 0;
  State := ST_LIST;
  NFiles := 0; NDone := 0; NSkipped := 0; NDeleted := 0; TotBytes := 0; DoneBytes := 0; CurDone := 0; CurSize := 0;
  ErrMsg := ''; CurName := '';
  { 1. branche par defaut }
  CurName := 'Lecture des renseignements du d' + Chr(130) + 'p' + Chr(147) + 't...';
  JsonLen := 0;
  R := HttpGet(ApiBase + '/repos/gladir/OS2-0', '', True);
  If R = -2 Then Begin State := ST_CANCEL; NetClose; Exit; End;
  If R < 0 Then Begin Dummy := Fail(NetErr); Exit; End;
  Branch := 'main';
  If R = 200 Then
  Begin
    S := JVal('default_branch', 0, JsonLen);
    If S <> '' Then Branch := S;
  End
  Else If (R = 403) Or (R = 429) Then
  Begin
    Dummy := Fail(LimitMsg);
    Exit;
  End;
  { 2. arbre complet de la branche }
  CurName := 'Lecture de la liste des fichiers (branche ' + Branch + ')...';
  JsonLen := 0;
  R := HttpGet(ApiBase + '/repos/gladir/OS2-0/git/trees/' + Branch + '?recursive=1', '', True);
  If R = -2 Then Begin State := ST_CANCEL; NetClose; Exit; End;
  If R < 0 Then Begin Dummy := Fail(NetErr); Exit; End;
  If R <> 200 Then
  Begin
    If (R = 403) Or (R = 429) Then Dummy := Fail(LimitMsg)
    Else Dummy := Fail('GitHub a r' + Chr(130) + 'pondu : erreur ' + IStr(R) + ' (liste des fichiers) ' + ApiMsg);
    Exit;
  End;
  If Not ParseTree Then Begin Dummy := Fail('Liste des fichiers de GitHub illisible.'); Exit; End;
  ListBytes := JsonLen;
  { 3. ce qu'il faut copier }
  DoneBytes := 0;
  LoadList;
  For I := 0 To NEnt - 1 Do
    If EType[I] = 0 Then
    Begin
      P := PathOf(I);
      M := ManFind(P);
      If M >= 0 Then MUsed[M] := 1;
      { images du CD-ROM non demandees : ni copiees, ni effacees }
      If IsIso(I) And (WithIso = 0) Then Begin EOk[I] := 2; Continue; End;
      If Mode = 1 Then
        If (M >= 0) And (ManSha(M) = ShaOf(I)) And (FileSize0(LocalName(P)) = ESize[I]) Then
        Begin
          EOk[I] := 1;
          Inc(NSkipped);
          Continue;
        End;
      Inc(NFiles);
      TotBytes := TotBytes + ESize[I];
    End;
  { place libre }
  If DosQueryFSInfo(Ord(UpCase(Dest[1])) - 64, 1, LongInt(@Buf), 18) = 0 Then
  Begin
    FreeKb := RdL(LongInt(@Buf) + 12) * (RdL(LongInt(@Buf) + 4) * (RdB(LongInt(@Buf) + 16) Or (RdB(LongInt(@Buf) + 17) Shl 8)) Div 512) Div 2;
    If (FreeKb > 0) And (TotBytes Div 1024 + 64 > FreeKb) Then
    Begin
      Dummy := Fail('Pas assez de place sur ' + Copy(Dest, 1, 2) + ' : ' + SizeStr(TotBytes) + ' n' + Chr(130) +
                    'cessaires, ' + IStr(FreeKb Div 1024) + ' Mo libres.');
      Exit;
    End;
  End;
  { 4. telechargement }
  DoneBytes := 0; CurDone := 0;
  State := ST_GET;
  LastDir := '';
  MakeDirs(Dest);
  For I := 0 To NEnt - 1 Do
  Begin
    If Abort <> 0 Then Break;
    If EType[I] = 1 Then Begin MakeDirs(LocalName(PathOf(I))); Continue; End;
    If (EType[I] <> 0) Or (EOk[I] <> 0) Then Continue;
    P := PathOf(I);
    L := LocalName(P);
    For R := Length(L) DownTo 1 Do If L[R] = '\' Then Begin MakeDirs(Copy(L, 1, R - 1)); Break; End;
    CurName := P; CurSize := ESize[I]; CurDone := 0;
    R := HttpGet(RawBase + '/gladir/OS2-0/' + Branch + '/' + UrlPath(P), L, False);
    If (R = 301) Or (R = 302) Or (R = 307) Or (R = 308) Then
      If HLocation <> '' Then R := HttpGet(HLocation, L, False);
    If R = -2 Then Break;
    If R < 0 Then
    Begin
      SaveList(False);
      Dummy := Fail(NetErr);
      Exit;
    End;
    If R <> 200 Then
    Begin
      SaveList(False);
      Dummy := Fail('GitHub a r' + Chr(130) + 'pondu : erreur ' + IStr(R) + ' pour ' + P + '.');
      Exit;
    End;
    EOk[I] := 1;
    Inc(NDone);
    { liste enregistree de temps en temps : une coupure n'oblige pas a tout reprendre }
    If NDone Mod 40 = 0 Then SaveList(False);
    { taille annoncee et taille recue : on corrige le total }
    If CurDone <> ESize[I] Then DoneBytes := DoneBytes - CurDone + ESize[I];
  End;
  NetClose;
  If Abort <> 0 Then
  Begin
    SaveList(False);
    State := ST_CANCEL;
    Exit;
  End;
  { 5. fichiers retires du depot (copies d'une fois precedente) }
  For M := 0 To NMan - 1 Do
    If MUsed[M] = 0 Then
    Begin
      If DosDelete(Z(LocalName(ManPath(M)))) = 0 Then Inc(NDeleted);
    End;
  SaveList(True);
  CurName := '';
  State := ST_DONE;
End;

{ ==================================================================== }
{ Dessin de la boite                                                    }
{ ==================================================================== }

Function Busy : Boolean;
Begin
  Busy := (State = ST_LIST) Or (State = ST_GET);
End;

Function BtnX(B : LongInt) : LongInt;
Begin
  BtnX := CW - 14 - (3 - B) * (BtnW + 8) + 8;
End;

Function BtnLabel(B : LongInt) : String;
Begin
  Case B Of
    B_GET : BtnLabel := 'T' + Chr(130) + 'l' + Chr(130) + 'charger';
    B_UPD : BtnLabel := 'Mettre ' + Chr(133) + ' jour';
  Else
    If (State = ST_DONE) Then BtnLabel := 'Fermer' Else BtnLabel := 'Annuler';
  End;
End;

Function BtnOn(B : LongInt) : Boolean;
Begin
  If B = B_CANCEL Then BtnOn := Abort = 0 Else BtnOn := Not Busy;
End;

Function DefBtn : LongInt;
Begin
  If State = ST_DONE Then DefBtn := B_CANCEL
  Else If LocalCount > 0 Then DefBtn := B_UPD
  Else DefBtn := B_GET;
End;

Procedure DrawButton(B : LongInt);
Var X, Y, W, H, Fg : LongInt; S : String;
Begin
  X := BtnX(B); Y := BtnY; W := BtnW; H := BtnH;
  FBar(X, Y, X + W - 1, Y + H - 1, CLR_PALEGRAY);
  If B = DefBtn Then
  Begin
    Edge(X - 1, Y - 1, X + W, Y + H, CLR_BLACK, CLR_BLACK);
  End;
  If (Pressed = B) And (Hover = B) Then
  Begin
    Edge(X, Y, X + W - 1, Y + H - 1, CLR_DARKGRAY, CLR_WHITE);
    Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_DARKGRAY, CLR_PALEGRAY);
  End
  Else
  Begin
    Edge(X, Y, X + W - 1, Y + H - 1, CLR_WHITE, CLR_BLACK);
    Edge(X + 1, Y + 1, X + W - 2, Y + H - 2, CLR_PALEGRAY, CLR_DARKGRAY);
  End;
  S := BtnLabel(B);
  If BtnOn(B) Then Fg := CLR_BLACK Else Fg := CLR_DARKGRAY;
  OutTxt(X + (W - Length(S) * 8) Div 2 + Ord(Pressed = B), Y + (H - 16) Div 2 + Ord(Pressed = B), S, Fg, CLR_PALEGRAY);
  { lettre soulignee (raccourci) }
  If B <> B_CANCEL Then
    FBar(X + (W - Length(S) * 8) Div 2, Y + (H - 16) Div 2 + 15, X + (W - Length(S) * 8) Div 2 + 6,
         Y + (H - 16) Div 2 + 15, Fg);
End;

{ icone : dossier jaune et fleche verte }
Procedure DrawIcon(X, Y : LongInt);
Var K : LongInt;
Begin
  FBar(X + 2, Y + 12, X + 18, Y + 16, CLR_BROWN);
  FBar(X, Y + 16, X + 44, Y + 44, CLR_BROWN);
  FBar(X + 2, Y + 18, X + 42, Y + 42, CLR_YELLOW);
  FBar(X + 2, Y + 18, X + 42, Y + 19, CLR_WHITE);
  FBar(X + 18, Y, X + 26, Y + 22, CLR_DARKGREEN);
  For K := 0 To 8 Do FBar(X + 10 + K, Y + 22 + K, X + 34 - K, Y + 22 + K, CLR_DARKGREEN);
  FBar(X + 19, Y + 1, X + 20, Y + 21, CLR_GREEN);
End;

Procedure DrawHeader;
Begin
  FBar(0, 0, CW - 1, 63, CLR_WHITE);
  BigText(16, 8, 'Code source d''OS/2-0', CLR_DARKBLUE, CLR_WHITE);
  OutTxt(16, 42, 'github.com/gladir/OS2-0', CLR_DARKGRAY, CLR_WHITE);
  If Branch <> '' Then OutTxt(16 + 25 * 8, 42, '(branche ' + Branch + ')', CLR_DARKGRAY, CLR_WHITE);
  DrawIcon(CW - 64, 10);
  FBar(0, 64, CW - 1, 64, CLR_DARKGRAY);
  FBar(0, 65, CW - 1, 65, CLR_WHITE);
End;

Procedure DrawInfo;
Var S : String; Y : LongInt;
Begin
  Y := 74;
  FBar(14, Y, CW - 14, Y + 64, CLR_PALEGRAY);
  OutTxt(16, Y, 'Destination :', CLR_BLACK, CLR_PALEGRAY);
  OutTxt(140, Y, Dest + '\', CLR_DARKBLUE, CLR_PALEGRAY);
  OutTxt(141, Y, Dest + '\', CLR_DARKBLUE, CLR_PALEGRAY);
  If FreeKb > 0 Then S := IStr(FreeKb Div 1024) + ' Mo libres sur ' + Copy(Dest, 1, 2) Else S := '';
  OutTxt(16, Y + 20, 'Espace libre :', CLR_BLACK, CLR_PALEGRAY);
  If S = '' Then S := 'inconnu';
  OutTxt(140, Y + 20, S, CLR_BLACK, CLR_PALEGRAY);
  OutTxt(16, Y + 40, 'Copie locale :', CLR_BLACK, CLR_PALEGRAY);
  If LocalCount > 0 Then S := NStr(LocalCount) + ' fichiers d' + Chr(130) + 'j' + Chr(133) + ' copi' + Chr(130) +
                              's'
  Else S := 'aucune';
  OutTxt(140, Y + 40, S, CLR_BLACK, CLR_PALEGRAY);
End;

Procedure DrawCheck;
Var X, Y : LongInt;
Begin
  X := 16; Y := 146;
  FBar(X, Y + 2, X + 12, Y + 14, CLR_WHITE);
  Edge(X, Y + 2, X + 12, Y + 14, CLR_DARKGRAY, CLR_WHITE);
  If WithIso <> 0 Then
  Begin
    FBar(X + 3, Y + 7, X + 4, Y + 10, CLR_BLACK);
    FBar(X + 5, Y + 9, X + 5, Y + 11, CLR_BLACK);
    FBar(X + 6, Y + 7, X + 6, Y + 10, CLR_BLACK);
    FBar(X + 7, Y + 5, X + 7, Y + 8, CLR_BLACK);
    FBar(X + 8, Y + 4, X + 9, Y + 6, CLR_BLACK);
  End;
  If Busy Then
    OutTxt(X + 20, Y, 'Inclure les images du CD-ROM (IMAGE\*.ISO, environ 60 Mo)', CLR_DARKGRAY, CLR_PALEGRAY)
  Else
    OutTxt(X + 20, Y, 'Inclure les images du CD-ROM (IMAGE\*.ISO, environ 60 Mo)', CLR_BLACK, CLR_PALEGRAY);
End;

{ chemin raccourci par le debut : ...\KERNEL\OS2KRNL.PAS }
Function Shorten(S : String; Max : LongInt) : String;
Begin
  If Length(S) > Max Then S := '...' + Copy(S, Length(S) - Max + 4, Max);
  Shorten := S;
End;

Function Pct : LongInt;
Begin
  If State = ST_DONE Then Pct := 100
  Else If TotBytes <= 0 Then Pct := 0
  Else If TotBytes > 20000000 Then Pct := MinI(100, (DoneBytes Div 100) * 100 Div (TotBytes Div 100))
  Else Pct := MinI(100, DoneBytes * 100 Div TotBytes);
End;

{ vitesse (octets par seconde) sur les dernieres secondes }
Function Speed : LongInt;
Var Dt : LongInt;
Begin
  Speed := 0;
  If SpN < 2 Then Exit;
  Dt := SpT[(SpN - 1) Mod 8] - SpT[MaxI(0, SpN - 8) Mod 8];
  If Dt <= 0 Then Exit;
  Speed := (SpB[(SpN - 1) Mod 8] - SpB[MaxI(0, SpN - 8) Mod 8]) * 100 Div Dt;
End;

Procedure DrawProgress;
Var X, W, Fill0, K, Cx, P, Sp, Rest : LongInt; S : String; Ch : Char;
Begin
  { cadre de groupe }
  FBar(14, 172, CW - 15, 300, CLR_PALEGRAY);
  Edge(14, 180, CW - 15, 300, CLR_DARKGRAY, CLR_WHITE);
  Edge(15, 181, CW - 16, 299, CLR_WHITE, CLR_DARKGRAY);
  OutTxt(24, 172, ' Progression ', CLR_DARKBLUE, CLR_PALEGRAY);
  { fichier en cours }
  If State = ST_GET Then S := 'Fichier : ' + Shorten(CurName, 50)
  Else S := Shorten(CurName, 58);
  OutTxt(24, 192, S, CLR_BLACK, CLR_PALEGRAY);
  { barre }
  Edge(BarX1 - 2, BarY - 2, BarX2 + 2, BarY + BarH + 1, CLR_DARKGRAY, CLR_WHITE);
  Edge(BarX1 - 1, BarY - 1, BarX2 + 1, BarY + BarH, CLR_BLACK, CLR_PALEGRAY);
  P := Pct;
  W := BarX2 - BarX1 + 1;
  Fill0 := W * P Div 100;
  If Fill0 > 0 Then FBar(BarX1, BarY, BarX1 + Fill0 - 1, BarY + BarH - 1, CLR_DARKBLUE);
  If Fill0 < W Then FBar(BarX1 + Fill0, BarY, BarX2, BarY + BarH - 1, CLR_WHITE);
  S := IStr(P) + ' %';
  X := BarX1 + (W - Length(S) * 8) Div 2;
  For K := 1 To Length(S) Do
  Begin
    Cx := X + (K - 1) * 8; Ch := S[K];
    If Cx + 4 < BarX1 + Fill0 Then OutTxt(Cx, BarY + 3, Ch, CLR_WHITE, CLR_DARKBLUE)
    Else OutTxt(Cx, BarY + 3, Ch, CLR_BLACK, CLR_WHITE);
  End;
  { compteurs }
  If (State = ST_GET) Or (State = ST_DONE) Or (State = ST_CANCEL) Or ((State = ST_ERROR) And (NFiles > 0)) Then
  Begin
    If (State = ST_DONE) And (NFiles = 0) Then S := 'Aucun fichier ' + Chr(133) + ' copier : tout est d' + Chr(130) +
                                                   'j' + Chr(133) + ' ' + Chr(133) + ' jour.'
    Else S := NStr(NDone) + ' sur ' + NStr(NFiles) + ' fichiers    ' + SizeStr(DoneBytes) + ' sur ' + SizeStr(TotBytes);
    OutTxt(24, 246, S, CLR_BLACK, CLR_PALEGRAY);
    If State = ST_GET Then
    Begin
      Sp := Speed;
      S := 'Vitesse : ' + SizeStr(Sp) + '/s';
      If Sp > 0 Then
      Begin
        Rest := (TotBytes - DoneBytes) Div Sp;
        If Rest >= 60 Then S := S + '    Temps restant : ' + IStr(Rest Div 60) + ' min ' + IStr(Rest Mod 60) + ' s'
        Else S := S + '    Temps restant : ' + IStr(Rest) + ' s';
      End;
      OutTxt(24, 266, S, CLR_DARKGRAY, CLR_PALEGRAY);
    End;
  End;
End;

Procedure DrawState;
Var S : String; C : LongInt;
Begin
  C := CLR_BLACK;
  Case State Of
    ST_IDLE : S := 'Choisissez T' + Chr(130) + 'l' + Chr(130) + 'charger ou Mettre ' + Chr(133) + ' jour.';
    ST_LIST : S := 'Lecture de la liste des fichiers sur GitHub...';
    ST_GET : S := 'T' + Chr(130) + 'l' + Chr(130) + 'chargement en cours...';
    ST_DONE :
      Begin
        S := 'Termin' + Chr(130) + ' : ' + NStr(NDone) + ' copi' + Chr(130) + '(s)';
        If NSkipped > 0 Then S := S + ', ' + NStr(NSkipped) + ' d' + Chr(130) + 'j' + Chr(133) + ' ' + Chr(133) + ' jour';
        If NDeleted > 0 Then S := S + ', ' + NStr(NDeleted) + ' retir' + Chr(130) + '(s)';
        S := S + '.';
        C := CLR_DARKGREEN;
      End;
    ST_CANCEL : Begin S := 'T' + Chr(130) + 'l' + Chr(130) + 'chargement annul' + Chr(130) + '.'; C := CLR_DARKRED; End;
  Else
    Begin S := ErrMsg; C := CLR_DARKRED; End;
  End;
  FBar(14, 304, CW - 14, BtnY - 2, CLR_PALEGRAY);
  If Length(S) > 62 Then
  Begin
    { message long : sur la ligne des boutons, a gauche, en deux morceaux }
    OutTxt(16, 302, Copy(S, 1, 62), C, CLR_PALEGRAY);
  End
  Else OutTxt(16, 302, S, C, CLR_PALEGRAY);
End;

Procedure PaintAll(H : LongInt);
Var B : LongInt;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  FBar(0, 66, CW - 1, CH - 1, CLR_PALEGRAY);
  DrawHeader;
  DrawInfo;
  DrawCheck;
  DrawProgress;
  DrawState;
  FBar(0, BtnY - 4, CW - 1, CH - 1, CLR_PALEGRAY);
  For B := 0 To 2 Do DrawButton(B);
  Dummy := WinEndPaint(Hps);
End;

Procedure Redraw;
Begin
  If Client <> 0 Then Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ mise a jour rapide (sans tout effacer) }
Procedure Refresh;
Var B : LongInt;
Begin
  If Client = 0 Then Exit;
  Hps := WinGetPS(Client);
  If Hps = 0 Then Exit;
  DrawProgress;
  DrawState;
  For B := 0 To 2 Do DrawButton(B);
  Dummy := WinReleasePS(Hps);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Procedure CountLocal;
Var Buf : Array[0..23] Of Byte;
Begin
  LoadList;
  LocalCount := NMan;
  FreeKb := 0;
  If DosQueryFSInfo(Ord(UpCase(Dest[1])) - 64, 1, LongInt(@Buf), 18) = 0 Then
    FreeKb := RdL(LongInt(@Buf) + 12) * (RdL(LongInt(@Buf) + 4) * (RdB(LongInt(@Buf) + 16) Or (RdB(LongInt(@Buf) + 17) Shl 8)) Div 512) Div 2;
End;

Procedure Start(M : LongInt);
Var K : LongInt;
Begin
  If Busy Then Exit;
  Mode := M; Abort := 0; Explored := 0;
  State := ST_LIST;
  NFiles := 0; NDone := 0; TotBytes := 0; DoneBytes := 0;
  SpN := 0; LastTick := 0;
  For K := 0 To 7 Do Begin SpT[K] := 0; SpB[K] := 0; End;
  CurName := 'Connexion ' + Chr(133) + ' GitHub...';
  Redraw;
  If DosCreateThread(LongInt(@WorkTid), LongInt(@Worker), 0, 0, 131072) <> 0 Then Dummy := Worker(0);
End;

{ l'Explorateur OS2-0 sur le dossier copie }
Procedure OpenExplorer;
Var Res : Array[0..1] Of LongInt; P : String;
Begin
  If NoExplorer <> 0 Then Exit;
  P := 'C:\EXPLORER.EXE';
  PutZ(LongInt(@ArgBuf), P);
  PutZ(LongInt(@ArgBuf) + Length(P) + 1, Dest);
  WrB(LongInt(@ArgBuf) + Length(P) + Length(Dest) + 2, 0);
  PutZ(LongInt(@NameZ2), P);
  Res[0] := 0; Res[1] := 0;
  Dummy := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), LongInt(@NameZ2));
End;

Procedure CancelOrClose;
Begin
  If Busy Then
  Begin
    Abort := 1;
    CurName := 'Arr' + Chr(136) + 't en cours...';
    Refresh;
    Exit;
  End;
  Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
End;

Procedure Press(B : LongInt);
Begin
  If Not BtnOn(B) Then Exit;
  Case B Of
    B_GET : Start(0);
    B_UPD : Start(1);
  Else
    CancelOrClose;
  End;
End;

Procedure TimerTick;
Var T : LongInt;
Begin
  { mesure de la vitesse, une fois par seconde }
  If State = ST_GET Then
  Begin
    T := NowCs;
    If (LastTick = 0) Or (T - LastTick >= 100) Or (T < LastTick) Then
    Begin
      SpT[SpN Mod 8] := T; SpB[SpN Mod 8] := DoneBytes;
      Inc(SpN);
      LastTick := T;
    End;
  End;
  If (State = ST_DONE) And (Explored = 0) Then
  Begin
    Explored := 1;
    CountLocal;
    Redraw;
    OpenExplorer;
    Exit;
  End;
  If (State = ST_CANCEL) Or (State = ST_ERROR) Then
    If Explored = 0 Then
    Begin
      Explored := 1;
      CountLocal;
      Redraw;
      If State = ST_ERROR Then
      Begin
        LClr;
        LAdd(ErrMsg);
        If NDone > 0 Then
          LAdd(Chr(10) + Chr(10) + NStr(NDone) + ' fichier(s) d' + Chr(130) + 'j' + Chr(133) + ' copi' + Chr(130) +
               '(s) : Mettre ' + Chr(133) + ' jour reprendra l' + Chr(133) + ' o' + Chr(151) + ' le t' + Chr(130) +
               'l' + Chr(130) + 'chargement s''est arr' + Chr(136) + 't' + Chr(130) + '.');
        Dummy := LMsgBox('T' + Chr(130) + 'l' + Chr(130) + 'charger le code source', MB_OK Or MB_ERROR);
      End;
      Exit;
    End;
  { changement d'etape : tout redessiner (branche, case a cocher, boutons) }
  If State <> LastState Then
  Begin
    LastState := State;
    Redraw;
    Exit;
  End;
  If Busy Then Refresh;
End;

Function ButtonAt(X, Y : LongInt) : LongInt;
Var B : LongInt;
Begin
  ButtonAt := -1;
  For B := 0 To 2 Do
    If (X >= BtnX(B)) And (X < BtnX(B) + BtnW) And (Y >= BtnY) And (Y < BtnY + BtnH) Then ButtonAt := B;
End;

Function KeyChar(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Ch, Vk : LongInt;
Begin
  KeyChar := True;
  Fl := Lo16(Mp1); Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
  If (Fl And KC_KEYUP) <> 0 Then Begin KeyChar := False; Exit; End;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    If Vk = VK_ESC Then Begin Press(B_CANCEL); Exit; End;
    If (Vk = VK_NEWLINE) Or (Vk = VK_ENTER) Then Begin Press(DefBtn); Exit; End;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    Case UpCase(Chr(Ch)) Of
      'T' : Press(B_GET);
      'M' : Press(B_UPD);
      'I' : If Not Busy Then Begin WithIso := 1 - WithIso; Redraw; End;
    Else
      KeyChar := False;
    End;
    Exit;
  End;
  KeyChar := False;
End;

Function MainProc(H, Msg0, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; X, Y, B : LongInt;
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
        X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
        B := ButtonAt(X, Y);
        If (B >= 0) And BtnOn(B) Then
        Begin
          Pressed := B; Hover := B;
          Refresh;
        End
        Else If (X >= 16) And (X < 16 + 20 + 57 * 8) And (Y >= 146) And (Y < 164) And Not Busy Then
        Begin
          WithIso := 1 - WithIso;
          Redraw;
        End;
        MainProc := 1;
      End;
    WM_MOUSEMOVE :
      Begin
        If Pressed >= 0 Then
        Begin
          X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
          B := ButtonAt(X, Y);
          If B <> Hover Then Begin Hover := B; Refresh; End;
        End;
        MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
      End;
    WM_BUTTON1UP :
      Begin
        If Pressed >= 0 Then
        Begin
          B := Pressed;
          X := S16(Mp1); Y := CH - 1 - S16(Mp1 Shr 16);
          Pressed := -1;
          Refresh;
          If ButtonAt(X, Y) = B Then Press(B);
        End;
        MainProc := 1;
      End;
    WM_CHAR :
      If Not KeyChar(Mp1, Mp2) Then MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2) Else MainProc := 1;
    WM_CLOSE :
      Begin
        If Busy Then
        Begin
          Abort := 1;
          { le fil s'arrete au prochain bloc recu }
          Dummy := DosSleep(300);
        End;
        Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
      End;
  Else
    MainProc := WinDefWindowProc(H, Msg0, Mp1, Mp2);
  End;
End;

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
  Flg, Sw, Sh, Fw, Fh, K, E, X, Y : LongInt;
  Dt : Array[0..15] Of Byte;
  Rc : Array[0..3] Of LongInt;
  S, S0 : String;

BEGIN
  FillChar(Dt, SizeOf(Dt), 0);
  Dummy := DosGetDateTime(LongInt(@Dt));
  Seed := Dt[0] * 3600 + Dt[1] * 60 + Dt[2] + Dt[3] * 7919;
  Client := 0; Frame := 0; State := ST_IDLE; Abort := 0; Pressed := -1; Hover := -1; WithIso := 0;
  NoExplorer := 0; AutoStart := -1; Explored := 0; CConn := 0; NetReady := 0; Branch := '';
  Dest := 'C:\SOURCE\OS2-0';
  ApiBase := 'https://api.github.com'; RawBase := 'https://raw.githubusercontent.com';
  CurName := 'Seuls les fichiers du projet sont copi' + Chr(130) + 's, sans Git.';
  For K := 1 To ParamCount Do
  Begin
    S0 := ParamStr(K);
    S := UpS(S0);
    If Copy(S, 1, 6) = '/DEST:' Then Dest := UpS(Copy(S0, 7, 200));
    If Copy(S, 1, 5) = '/API:' Then ApiBase := Copy(S0, 6, 200);
    If Copy(S, 1, 5) = '/RAW:' Then RawBase := Copy(S0, 6, 200);
    If S = '/AUTO' Then AutoStart := 0;
    If S = '/UPDATE' Then AutoStart := 1;
    If S = '/ISO' Then WithIso := 1;
    If S = '/NOEXPLORER' Then NoExplorer := 1;
  End;
  While (Length(Dest) > 3) And (Dest[Length(Dest)] = '\') Do Delete(Dest, Length(Dest), 1);
  ListFile := Dest + '.LST';
  { proxy (comme le Navigateur Web) }
  S := GetEnvS('HTTP_PROXY');
  Token := GetEnvS('GITHUB_TOKEN');
  If LowS(Copy(S, 1, 7)) = 'http://' Then Delete(S, 1, 7);
  While (Length(S) > 0) And (S[Length(S)] = '/') Do Delete(S, Length(S), 1);
  ProxyHost := ''; ProxyPort := 0;
  K := Pos(':', S);
  If K > 1 Then
  Begin
    ProxyHost := Copy(S, 1, K - 1);
    ProxyPort := SVal(Copy(S, K + 1, 6), 0);
    If ProxyPort <= 0 Then ProxyHost := '';
  End;
  JsonBuf := 0; Pool := 0; MPool := 0;
  If DosAllocMem(LongInt(@JsonBuf), JsonCap, $13) <> 0 Then Halt(8);
  If DosAllocMem(LongInt(@Pool), PoolCap, $13) <> 0 Then Halt(8);
  If DosAllocMem(LongInt(@MPool), PoolCap, $13) <> 0 Then Halt(8);
  CountLocal;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  LoadFont;
  Dummy := WinRegisterClass(Hab, Z('GETSRC'), LongInt(@MainProc), 0, 0);
  Flg := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER Or FCF_TASKLIST;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flg), Z('GETSRC'),
                              Z2('T' + Chr(130) + 'l' + Chr(130) + 'charger le code source d''OS2-Zero'), 0, 0, 0,
                              LongInt(@Client));
  Rc[0] := 0; Rc[1] := 0; Rc[2] := CWant; Rc[3] := CHWant;
  Dummy := WinCalcFrameRect(Frame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  X := (Sw - Fw) Div 2; Y := (Sh - Fh) Div 2;
  If X < 0 Then X := 0;
  If Y < 0 Then Y := Sh - Fh;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, X, Y, Fw, Fh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or
                           SWP_ACTIVATE);
  Dummy := WinStartTimer(Hab, Client, 1, 200);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  If AutoStart >= 0 Then Start(AutoStart);
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
