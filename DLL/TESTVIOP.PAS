{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de PMVIOP.DLL sous OS/2-0.
}

Program TESTVIOP;

{$R-,S-,I-}

{ Compilation : OS2PC TESTVIOP.PAS   (produit TESTVIOP.EXE)

  TESTVIOP verifie PMVIOP.DLL : ses 73 ordinaux, une console privee
  (WinCreateConsole, fenetre a cadre, QueryConsole), son tampon rempli
  depuis un espace AVIO de VIOCALLS (WinSyncWithPS, dessin dans la
  fenetre), l'etat, la page de codes, la traduction du clavier, le focus,
  les evenements du clavier (WM_CHAR, KeyboardEvent, lecture, vidage) et
  de la souris (filtre, position), le marquage a la souris et la copie
  dans le presse-papiers, le menu de la console, les entrees "seamless"
  et des VDM, les donnees 101 a 122, puis une vraie fenetre OS/2 : CMD.EXE
  lance dans une nouvelle session, montree dans une console (CON_SESSION,
  ScreenGroupToFPConsole), commandes tapees par KeyboardEvent et par
  Coller, copie de l'ecran, et WinShieldAbort (fin de CMD, session
  liberee). Sans intervention : tout passe par des messages. }

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';

Function WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN';
Function WinTerminate(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyMsgQueue(Hmq : LongInt) : LongInt; External 'PMWIN';
Function WinPeekMsg(Hab, P, HF, F, L, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN';
Function WinGetCurrentTime(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindow(Hab, H : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindowVisible(H : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindow(H, Cmd : LongInt) : LongInt; External 'PMWIN';
Function WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN';
Function WinQueryScreenText(Row, Col, N, P : LongInt) : LongInt; External 'PMWIN' Name 'WINQUERYSCREENTEXT';

Function VioCreatePS(PHvps, Depth, Width, Format, Attrs, Reserved : LongInt) : LongInt; External 'VIOCALLS';
Function VioDestroyPS(Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioWrtCharStrAtt(PStr, Cb, Row, Col, PAttr, Hvio : LongInt) : LongInt; External 'VIOCALLS';

Function WinCreateConsole(Own, PTitle, Fl, PH : LongInt) : LongInt; External 'PMVIOP' Name 'WinCreateConsole';
Function WinDestroyConsole(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinDestroyConsole';
Function WinSyncWithPS(H, Hvps : LongInt) : LongInt; External 'PMVIOP' Name 'WinSyncWithPS';
Function WinConsoleOpenKbd(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleOpenKbd';
Function WinConsoleCloseKbd(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleCloseKbd';
Function WinConsoleSetStatus(H, Fl : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleSetStatus';
Function WinConsoleGetStatus(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleGetStatus';
Function WinConsoleSetCP(H, Cp : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleSetCP';
Function WinConsoleGetCP(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleGetCP';
Function WinConsoleKbdXlate(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleKbdXlate';
Function WinConsoleSetCustXt(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleSetCustXt';
Function WinConsoleGetFocus(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleGetFocus';
Function WinConsoleFreeFocus(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleFreeFocus';
Function WinConsoleReadKeyEvent(H, P, W : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleReadKeyEvent';
Function WinConsoleFlushKeyEvents(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleFlushKeyEvents';
Function WinConsoleQueuedPointerEvents(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleQueuedPointerEvents';
Function WinConsoleReadPointerEvent(H, P, W : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleReadPointerEvent';
Function WinConsoleFlushPointerEvents(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleFlushPointerEvents';
Function WinConsoleGetPointerFilterMask(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleGetPointerFilterMask';
Function WinConsoleSetPointerFilterMask(H, Fl : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleSetPointerFilterMask';
Function WinConsoleGetPtrPos(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleGetPtrPos';
Function WinConsoleSetPtrPos(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleSetPtrPos';
Function WinShieldAbort(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinShieldAbort';
Function ShieldFrameProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMVIOP' Name 'ShieldFrameProc';
Function VioShieldWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMVIOP' Name 'VioShieldWindowProc';
Function LockVioPS(H : LongInt) : LongInt; External 'PMVIOP' Name 'LockVioPS';
Function UnlockVioPS(H : LongInt) : LongInt; External 'PMVIOP' Name 'UnlockVioPS';
Function MarkingWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMVIOP' Name 'MarkingWindowProc';
Function WinDefAVioWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMVIOP' Name 'WinDefAVioWindowProc';
Function WinConsoleGetKbdHandle(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleGetKbdHandle';
Function WinConsoleAttachMouseUser(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleAttachMouseUser';
Function WinConsoleDetachMouseUser(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinConsoleDetachMouseUser';
Function TaskMgrSubClassProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMVIOP' Name 'TaskMgrSubClassProc';
Function WinShieldPreThaw(H : LongInt) : LongInt; External 'PMVIOP' Name 'WinShieldPreThaw';
Function WinInitShield(Hab, Hmq : LongInt) : LongInt; External 'PMVIOP' Name 'WinInitShield';
Function Mortician(Pid : LongInt) : LongInt; External 'PMVIOP' Name 'Mortician';
Function UnlockSemaphores : LongInt; External 'PMVIOP' Name 'UnlockSemaphores';
Function ClearData(H : LongInt) : LongInt; External 'PMVIOP' Name 'ClearData';
Function QueryConsole(H, P : LongInt) : LongInt; External 'PMVIOP' Name 'QueryConsole';
Function MakeVisible(H : LongInt) : LongInt; External 'PMVIOP' Name 'MakeVisible';
Function GetPasteChar(H : LongInt) : LongInt; External 'PMVIOP' Name 'GetPasteChar';
Function SeamlessCommonVDM(P1, P2 : LongInt) : LongInt; External 'PMVIOP' Name 'SeamlessCommonVDM';
Function SeamlessControlProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMVIOP' Name 'SeamlessControlProc';
Function TerminateClipDDE : LongInt; External 'PMVIOP' Name 'TerminateClipDDE';
Function VDMClipDDENotify(Fmt : LongInt) : LongInt; External 'PMVIOP' Name 'VDMClipDDENotify';
Function PM32ClipDDENotify(Fmt : LongInt) : LongInt; External 'PMVIOP' Name 'PM32ClipDDENotify';
Function Seamless32RegisterObject(H, Obj : LongInt) : LongInt; External 'PMVIOP' Name 'Seamless32RegisterObject';
Function Seamless32ActivateWindow(H : LongInt) : LongInt; External 'PMVIOP' Name 'Seamless32ActivateWindow';
Function NotifyAllVDMs(Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMVIOP' Name 'NotifyAllVDMs';
Function VDMSwapButtonNotify(F : LongInt) : LongInt; External 'PMVIOP' Name 'VDMSwapButtonNotify';
Function Get32DisplayType : LongInt; External 'PMVIOP' Name 'Get32DisplayType';
Function Seamless32RegisterAssocObj(H, Obj : LongInt) : LongInt; External 'PMVIOP' Name 'Seamless32RegisterAssocObj';
Function VdmRegisterHook(Pfn : LongInt) : LongInt; External 'PMVIOP' Name 'VdmRegisterHook';
Function VdmDeregisterHook(Pfn : LongInt) : LongInt; External 'PMVIOP' Name 'VdmDeregisterHook';
Function ScreenGroupToFPConsole(Sg : LongInt) : LongInt; External 'PMVIOP' Name 'ScreenGroupToFPConsole';
Function APFNVDMServ : LongInt; External 'PMVIOP' Name 'APFNVDMServ';
Function GetSelAccess(Sel : LongInt) : LongInt; External 'PMVIOP' Name 'GetSelAccess';
Function NPSZStrings : LongInt; External 'PMVIOP' Name 'NPSZStrings';
Function KeyboardEvent(H, Ch, Sc, St : LongInt) : LongInt; External 'PMVIOP' Name 'KeyboardEvent';
Function EstablishKbdEnvironment(H : LongInt) : LongInt; External 'PMVIOP' Name 'EstablishKbdEnvironment';
Function HMyModuleHandle : LongInt; External 'PMVIOP' Name 'HMyModuleHandle';
Function FSeamlessCaptured : LongInt; External 'PMVIOP' Name 'FSeamlessCaptured';
Function HMQTaskmgr : LongInt; External 'PMVIOP' Name 'HMQTaskmgr';
Function PCharXlateTblDefault : LongInt; External 'PMVIOP' Name 'PCharXlateTblDefault';
Function HAPPSeamlessCommonVDM : LongInt; External 'PMVIOP' Name 'HAPPSeamlessCommonVDM';
Function HAPPSeamlessCommonVDM31 : LongInt; External 'PMVIOP' Name 'HAPPSeamlessCommonVDM31';
Function HAPPSeamlessCommonVDM31Enh : LongInt; External 'PMVIOP' Name 'HAPPSeamlessCommonVDM31Enh';
Function FKbdHook : LongInt; External 'PMVIOP' Name 'FKbdHook';
Function FMouHook : LongInt; External 'PMVIOP' Name 'FMouHook';
Function SelCommonList : LongInt; External 'PMVIOP' Name 'SelCommonList';
Function usCommonSegSize : LongInt; External 'PMVIOP' Name 'usCommonSegSize';
Function HMODSeamless : LongInt; External 'PMVIOP' Name 'HMODSeamless';
Function HFrameWindowFromConsole(H : LongInt) : LongInt; External 'PMVIOP' Name 'HFrameWindowFromConsole';

Const
  NOrd = 73;
  Ords : Array[0..NOrd - 1] Of LongInt = (1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
    23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 39, 40, 41, 42, 43, 44, 45, 46, 47, 49, 50, 51, 52, 53,
    54, 55, 56, 57, 101, 102, 103, 104, 105, 106, 107, 108, 110, 111, 112, 114, 116, 117, 118, 119, 120, 121, 122);
  HWND_DESKTOP = 1; QW_PARENT = 5;
  CON_VISIBLE = 1; CON_SESSION = 2; CON_KBD = 4;
  CS_FROZEN = 1; CS_MARKING = 2; CS_SELECTED = 4;
  WM_COMMAND = $0020; WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_CHAR = $007A;
  WM_USER = $1000;
  KC_CHAR = 1; KC_SCANCODE = 4;
  CF_TEXT = 1; CFI_POINTER = $400;

Var
  Ok, Fail, R, R2, I, N, A, B, P, Hmod, Hab, Hmq, Hc, Hc2, Hvps, Frame, Client, Frame2, Client2, S, Pid : LongInt;
  Info, Info2 : Array[0..15] Of LongInt;
  Kk : Array[0..15] Of Byte;
  Xt : Array[0..255] Of Byte;
  Buf : Array[0..1023] Of Byte;
  Name, Name2, ArgBuf, FailBuf : Array[0..255] Of Byte;
  Res : Array[0..1] Of LongInt;
  Qm : Array[0..7] Of LongInt;
  OutBuf : Array[0..8191] Of Byte;
  OutLen, ScrH, Cx, Cy : LongInt;
  T : String;
  Bo : Boolean;

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

Function RdW(A : LongInt) : LongInt;
Begin
  RdW := RdB(A) Or (RdB(A + 1) Shl 8);
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function HStr(V : LongInt) : String;
Const Hx : String = '0123456789ABCDEF';
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 7 DownTo 0 Do S := S + Hx[((V Shr (K * 4)) And 15) + 1];
  HStr := S;
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
  S := ''; K := 0;
  If A <> 0 Then
    While (K < 250) And (RdB(A + K) <> 0) Do
    Begin
      S := S + Chr(RdB(A + K));
      Inc(K);
    End;
  GetZ := S;
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name), S);
  Z := LongInt(@Name);
End;

Function Z2(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name2), S);
  Z2 := LongInt(@Name2);
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 8190 Then
    Begin
      OutBuf[OutLen] := Ord(T[K]);
      Inc(OutLen);
    End;
End;

Procedure Check(What : String; Cond : Boolean);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    OutStr('  OK     ' + What + Chr(13) + Chr(10));
  End
  Else
  Begin
    Inc(Fail);
    OutStr('  ECHEC  ' + What + '  (code ' + IStr(R) + ')' + Chr(13) + Chr(10));
  End;
End;

Procedure Pump(Ms : LongInt);
Var T0 : LongInt;
Begin
  T0 := WinGetCurrentTime(Hab);
  While WinGetCurrentTime(Hab) - T0 < Ms Do
    If WinPeekMsg(Hab, LongInt(@Qm), 0, 0, 0, 1) <> 0 Then R2 := WinDispatchMsg(Hab, LongInt(@Qm))
    Else R2 := DosSleep(10);
End;

{ un programme de PM n'est pas preempte : sans message, il cede la main
  (DosSleep) pour que CMD.EXE avance dans sa session }
{ texte affiche par la console (cellules de 8 x 16 de l'ecran) : ligne
  Row, colonnes Col a Col + Len - 1 du client C }
Function ConText(C, Row, Col, Len : LongInt) : String;
Var Pt : Array[0..1] Of LongInt; X, Y, Sr, Sc, K : LongInt; S : String;
Begin
  Pt[0] := 0; Pt[1] := 0;
  R2 := WinMapWindowPoints(C, HWND_DESKTOP, LongInt(@Pt), 1);
  X := Pt[0] + Col * 8; Y := Pt[1] + (24 - Row) * 16;
  Sc := (X + 4) Div 8; Sr := (ScrH - Y - 16 + 8) Div 16;
  R2 := WinQueryScreenText(Sr, Sc, Len, LongInt(@Buf));
  S := '';
  For K := 0 To Len - 1 Do S := S + Chr(Buf[K]);
  ConText := S;
End;

{ texte d'une ligne du tampon video d'une session (KrnSesCtl 18) }
Function SesLine(Sg, Row : LongInt) : String;
Var Inf : Array[0..7] Of LongInt; K : LongInt; S : String;
Begin
  S := '';
  If KSes(18, Sg, LongInt(@Inf)) <> 0 Then
    For K := 0 To Inf[4] - 1 Do S := S + Chr(RdB(Inf[0] + (Row * Inf[4] + K) * 2));
  SesLine := S;
End;

{ nombre de lignes de l'ecran de la session contenant T }
Function SesCount(Sg : LongInt; T : String) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To 24 Do
    If Pos(T, SesLine(Sg, K)) > 0 Then Inc(N);
  SesCount := N;
End;

{ attendre (en traitant les messages) que T apparaisse Cnt fois }
Function WaitSes(Sg : LongInt; T : String; Cnt, Ms : LongInt) : Boolean;
Var T0 : LongInt;
Begin
  T0 := WinGetCurrentTime(Hab);
  While (SesCount(Sg, T) < Cnt) And (WinGetCurrentTime(Hab) - T0 < Ms) Do Pump(100);
  WaitSes := SesCount(Sg, T) >= Cnt;
End;

Procedure TypeStr(H : LongInt; T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do R2 := KeyboardEvent(H, Ord(T[K]), 0, 0);
  R2 := KeyboardEvent(H, 13, $1C, 0);
End;

Function Clip : String;
Var P : LongInt;
Begin
  Clip := '';
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    P := WinQueryClipbrdData(Hab, CF_TEXT);
    Clip := GetZ(P);
    R2 := WinCloseClipbrd(Hab);
  End;
End;

Function Cell(Row, Col : LongInt) : LongInt;
Begin
  Cell := (Col * 8 + 2) Or (((24 - Row) * 16 + 4) Shl 16);
End;

Function HookFn(V : LongInt) : LongInt;
Begin
  HookFn := V;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTVIOP : essai de PMVIOP.DLL');

  { --- ordinaux --- }
  Hmod := 0;
  R := DosQueryModuleHandle(Z('PMVIOP'), LongInt(@Hmod));
  N := 0;
  For I := 0 To NOrd - 1 Do
  Begin
    P := 0;
    If DosQueryProcAddr(Hmod, Ords[I], 0, LongInt(@P)) = 0 Then
      If P <> 0 Then Inc(N);
  End;
  P := 0;
  R2 := DosQueryProcAddr(Hmod, 0, Z('WinConsoleGetPointerFilterMask'), LongInt(@P));
  Check('73 ordinaux de PMVIOP (' + IStr(N) + '), nom WinConsoleGetPointerFilterMask', (R = 0) And (N = NOrd) And
        (R2 = 0) And (P <> 0));

  { --- bouclier --- }
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  ScrH := WinQuerySysValue(HWND_DESKTOP, 21);
  R := WinInitShield(Hab, Hmq);
  Check('WinInitShield, HMQTaskmgr, HMyModuleHandle', (R = 1) And (HMQTaskmgr = Hmq) And (HMyModuleHandle = Hmod));

  { --- console privee --- }
  R := WinCreateConsole(HWND_DESKTOP, Z('Console PMVIOP'), CON_VISIBLE, LongInt(@Hc));
  Frame := HFrameWindowFromConsole(Hc);
  R2 := QueryConsole(Hc, LongInt(@Info));
  Client := Info[7];
  Check('WinCreateConsole (handle ' + HStr(Hc) + '), HFrameWindowFromConsole, QueryConsole 25 x 80',
        (R = 0) And (Hc <> 0) And (Frame <> 0) And (WinIsWindow(Hab, Frame) <> 0) And (WinIsWindowVisible(Frame) <> 0) And
        (R2 = 0) And (Info[0] = 25) And (Info[1] = 80) And (Info[5] = -1) And (Info[6] = Frame) And (Client <> 0) And
        (WinQueryWindow(Client, QW_PARENT) = Frame) And (Info[8] = 850));
  R2 := WinQueryWindowText(Frame, 64, LongInt(@Buf));
  Check('titre de la fenetre (' + GetZ(LongInt(@Buf)) + ')', GetZ(LongInt(@Buf)) = 'Console PMVIOP');
  R := WinCreateConsole(HWND_DESKTOP, 0, 0, 0);
  Check('WinCreateConsole sans phcon : ERROR_INVALID_PARAMETER', R = 87);
  R := WinCreateConsole(HWND_DESKTOP, 0, CON_SESSION Or (15 Shl 8), LongInt(@A));
  Check('WinCreateConsole d''une session absente refuse', R = 87);

  { --- espace AVIO -> console --- }
  Hvps := 0;
  R := VioCreatePS(LongInt(@Hvps), 25, 80, 0, 1, 0);
  Buf[0] := $1E;
  PutZ(LongInt(@Name2), 'Bonjour PMVIOP');
  R2 := VioWrtCharStrAtt(LongInt(@Name2), 14, 2, 3, LongInt(@Buf), Hvps);
  R := WinSyncWithPS(Hc, Hvps);
  Pump(400);
  T := ConText(Client, 2, 3, 14);
  Check('WinSyncWithPS : cellules du PS dessinees dans la fenetre (' + T + ')', (R = 0) And (T = 'Bonjour PMVIOP'));
  Check('WinSyncWithPS : handle de PS invalide refuse', WinSyncWithPS(Hc, 9999) = 87);
  Check('WinSyncWithPS : console invalide (ERROR_INVALID_HANDLE)', WinSyncWithPS(12345, Hvps) = 6);

  { --- etat --- }
  R := WinConsoleSetStatus(Hc, CS_FROZEN);
  R2 := WinConsoleGetStatus(Hc, LongInt(@A));
  Check('WinConsoleSetStatus / GetStatus (gelee)', (R = 0) And (R2 = 0) And (A = CS_FROZEN));
  R := WinShieldPreThaw(Hc);
  R2 := WinConsoleGetStatus(Hc, LongInt(@A));
  Check('WinShieldPreThaw : degel', (R = 0) And (A = 0));
  R := LockVioPS(Hc);
  R2 := LockVioPS(Hc);
  A := UnlockSemaphores;
  Check('LockVioPS (2), UnlockSemaphores', (R = 0) And (R2 = 0) And (A >= 1));
  Check('UnlockVioPS', (LockVioPS(Hc) = 0) And (UnlockVioPS(Hc) = 0) And (UnlockVioPS(77) = 6));

  { --- page de codes --- }
  R := WinConsoleSetCP(Hc, 437);
  R2 := WinConsoleGetCP(Hc, LongInt(@A));
  Check('WinConsoleSetCP 437 / WinConsoleGetCP', (R = 0) And (R2 = 0) And (A = 437));
  Check('WinConsoleSetCP 1234 refuse', WinConsoleSetCP(Hc, 1234) = 87);

  { --- traduction du clavier --- }
  P := PCharXlateTblDefault;
  Kk[0] := Ord('q'); Kk[1] := $10; Kk[2] := 0;
  R := WinConsoleKbdXlate(Hc, LongInt(@Kk));
  Check('PCharXlateTblDefault (identite), WinConsoleKbdXlate', (P <> 0) And (RdB(P + 65) = 65) And (R = 0) And
        (Kk[0] = Ord('q')) And ((Kk[2] And $40) <> 0));
  For I := 0 To 255 Do Xt[I] := I;
  For I := Ord('a') To Ord('z') Do Xt[I] := I - 32;
  R := WinConsoleSetCustXt(Hc, LongInt(@Xt));
  Kk[0] := Ord('q');
  R2 := WinConsoleKbdXlate(Hc, LongInt(@Kk));
  Check('WinConsoleSetCustXt (minuscules -> majuscules)', (R = 0) And (R2 = 0) And (Kk[0] = Ord('Q')));

  { --- focus, evenements du clavier --- }
  R := WinConsoleGetFocus(Hc);
  R2 := WinConsoleGetKbdHandle(Hc, LongInt(@A));
  Check('WinConsoleGetFocus, WinConsoleGetKbdHandle', (R = 0) And (R2 = 0) And (A <> 0));
  R := WinConsoleReadKeyEvent(Hc, LongInt(@Kk), 0);
  Check('WinConsoleReadKeyEvent sans clavier ouvert : rien (ERROR_NO_DATA)', R = 232);
  R := WinConsoleOpenKbd(Hc);
  R2 := WinPostMsg(Client, WM_CHAR, KC_CHAR Or KC_SCANCODE Or ($1E Shl 24), Ord('a'));
  Pump(200);
  R := WinConsoleReadKeyEvent(Hc, LongInt(@Kk), 0);
  Check('WM_CHAR "a" dans la fenetre -> WinConsoleReadKeyEvent ("A" par la table, code 1Eh)', (R = 0) And
        (Kk[0] = Ord('A')) And (Kk[1] = $1E));
  R := KeyboardEvent(Hc, Ord('7'), 8, 2);
  R2 := WinConsoleReadKeyEvent(Hc, LongInt(@Kk), 1);
  Check('KeyboardEvent, WinConsoleReadKeyEvent (attente)', (R = 0) And (R2 = 0) And (Kk[0] = Ord('7')) And
        (Kk[1] = 8) And (RdW(LongInt(@Kk) + 4) = 2));
  R := KeyboardEvent(Hc, Ord('x'), 0, 0);
  R2 := WinConsoleFlushKeyEvents(Hc);
  Check('WinConsoleFlushKeyEvents', (R = 0) And (R2 = 0) And (WinConsoleReadKeyEvent(Hc, LongInt(@Kk), 0) = 232));
  R := WinConsoleSetCustXt(Hc, 0);
  R := WinConsoleCloseKbd(Hc);
  R2 := EstablishKbdEnvironment(Hc);
  Check('WinConsoleCloseKbd, EstablishKbdEnvironment', (R = 0) And (R2 = 0));
  R := WinConsoleFreeFocus(Hc);
  Check('WinConsoleFreeFocus', R = 0);

  { --- souris --- }
  R := WinConsoleAttachMouseUser(Hc);
  Check('WinConsoleAttachMouseUser, FMouHook', (R = 0) And (FMouHook = 1));
  R2 := WinPostMsg(Client, WM_BUTTON1DOWN, Cell(5, 10), 0);
  R2 := WinPostMsg(Client, WM_BUTTON1UP, Cell(5, 10), 0);
  Pump(200);
  A := WinConsoleQueuedPointerEvents(Hc);
  R := WinConsoleReadPointerEvent(Hc, LongInt(@Info2), 0);
  Check('bouton 1 dans la fenetre -> WinConsoleReadPointerEvent (ligne 5, colonne 10)', (A = 1) And (R = 0) And
        (RdW(LongInt(@Info2)) = 4) And (RdW(LongInt(@Info2) + 6) = 5) And (RdW(LongInt(@Info2) + 8) = 10));
  R := WinConsoleGetPtrPos(Hc, LongInt(@Info2));
  Check('WinConsoleGetPtrPos (5, 10)', (R = 0) And (RdW(LongInt(@Info2)) = 5) And (RdW(LongInt(@Info2) + 2) = 10));
  WrW(LongInt(@Info2), 7); WrW(LongInt(@Info2) + 2, 40);
  R := WinConsoleSetPtrPos(Hc, LongInt(@Info2));
  R2 := WinConsoleGetPtrPos(Hc, LongInt(@Info2) + 8);
  Check('WinConsoleSetPtrPos (7, 40)', (R = 0) And (RdW(LongInt(@Info2) + 8) = 7) And (RdW(LongInt(@Info2) + 10) = 40));
  WrW(LongInt(@Info2), 30);
  Check('WinConsoleSetPtrPos hors de l''ecran refuse', WinConsoleSetPtrPos(Hc, LongInt(@Info2)) = 87);
  R := WinConsoleSetPointerFilterMask(Hc, 1);
  R2 := WinConsoleGetPointerFilterMask(Hc, LongInt(@A));
  Check('WinConsoleSetPointerFilterMask / Get (mouvements ignores)', (R = 0) And (R2 = 0) And (A = 1));
  R2 := WinPostMsg(Client, WM_MOUSEMOVE, Cell(3, 3), 0);
  R2 := WinPostMsg(Client, WM_BUTTON1DOWN, Cell(3, 3), 0);
  R2 := WinPostMsg(Client, WM_BUTTON1UP, Cell(3, 3), 0);
  Pump(200);
  Check('filtre : seul le clic est garde', WinConsoleQueuedPointerEvents(Hc) = 1);
  R := WinConsoleFlushPointerEvents(Hc);
  Check('WinConsoleFlushPointerEvents', (R = 0) And (WinConsoleQueuedPointerEvents(Hc) = 0) And
        (WinConsoleReadPointerEvent(Hc, LongInt(@Info2), 0) = 232));
  R := WinConsoleDetachMouseUser(Hc);
  Check('WinConsoleDetachMouseUser', (R = 0) And (FMouHook = 0));

  { --- marquage et presse-papiers --- }
  R := WinConsoleSetStatus(Hc, CS_MARKING);
  R2 := WinPostMsg(Client, WM_BUTTON1DOWN, Cell(2, 3), 0);
  R2 := WinPostMsg(Client, WM_MOUSEMOVE, Cell(2, 10), 0);
  R2 := WinPostMsg(Client, WM_BUTTON1UP, Cell(2, 16), 0);
  Pump(300);
  R2 := WinConsoleGetStatus(Hc, LongInt(@A));
  R2 := WinSendMsg(Client, WM_COMMAND, 2, 0);
  T := Clip;
  Check('marquage (glisser, MarkingWindowProc), Copier : "' + T + '"', (R = 0) And (A = CS_SELECTED) And
        (T = 'Bonjour PMVIOP'));
  R2 := WinSendMsg(Client, WM_COMMAND, 3, 0);
  T := Clip;
  Check('Tout copier (25 lignes)', (Pos('Bonjour PMVIOP', T) > 0) And (Length(T) >= 2 * 24));
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    R2 := WinEmptyClipbrd(Hab);
    R2 := WinSetClipbrdData(Hab, Z('ab'), CF_TEXT, CFI_POINTER);
    R2 := WinCloseClipbrd(Hab);
  End;
  R2 := WinSendMsg(Client, WM_COMMAND, 4, 0);
  A := GetPasteChar(Hc); B := GetPasteChar(Hc);
  Check('Coller, GetPasteChar ("a", "b", puis -1)', (A = Ord('a')) And (B = Ord('b')) And (GetPasteChar(Hc) = -1));
  R := ClearData(Hc);
  Pump(300);
  Check('ClearData (tampon vide)', (R = 0) And (ConText(Client, 2, 3, 14) = '              '));

  { --- procedures de fenetre --- }
  Check('WinDefAVioWindowProc, VioShieldWindowProc, MarkingWindowProc, ShieldFrameProc, SeamlessControlProc',
        (WinDefAVioWindowProc(Client, WM_USER, 0, 0) = 0) And (VioShieldWindowProc(Client, WM_USER, 0, 0) = 0) And
        (MarkingWindowProc(Client, WM_USER, 0, 0) = 0) And (ShieldFrameProc(Frame, WM_USER, 0, 0) = 0) And
        (SeamlessControlProc(Frame, WM_USER, 0, 0) = 0));
  Check('TaskMgrSubClassProc (commande 1F00h + rang : console montree)',
        TaskMgrSubClassProc(Frame, WM_COMMAND, $1F00 + (Hc - $56430001), 0) = 1);
  Check('MakeVisible', MakeVisible(Hc) = 0);

  { --- seamless, VDM --- }
  Check('SeamlessCommonVDM : ERROR_NOT_SUPPORTED, FSeamlessCaptured, HAPPSeamlessCommonVDM*, HMODSeamless',
        (SeamlessCommonVDM(0, 0) = 50) And (FSeamlessCaptured = 0) And (HAPPSeamlessCommonVDM = 0) And
        (HAPPSeamlessCommonVDM31 = 0) And (HAPPSeamlessCommonVDM31Enh = 0) And (HMODSeamless = 0));
  R := Seamless32RegisterObject(Frame, 77);
  R2 := Seamless32RegisterAssocObj(Frame, 78);
  Check('Seamless32RegisterObject, Seamless32RegisterAssocObj, Seamless32ActivateWindow', (R > 0) And (R2 = 1) And
        (Seamless32ActivateWindow(Frame) <> 0) And (Seamless32ActivateWindow(12345) = 0));
  Check('VDMClipDDENotify, PM32ClipDDENotify, TerminateClipDDE', (VDMClipDDENotify(1) = 1) And
        (PM32ClipDDENotify(1) = 1) And (TerminateClipDDE = 1));
  Check('VDMSwapButtonNotify', (VDMSwapButtonNotify(1) = 1) And (VDMSwapButtonNotify(0) = 1));
  A := NotifyAllVDMs(WM_USER, 0, 0);
  Check('NotifyAllVDMs (' + IStr(A) + ' console)', A = 1);
  A := Get32DisplayType;
  Check('Get32DisplayType (' + IStr(A) + ')', (A = 3) Or (A = 8));
  R := VdmRegisterHook(LongInt(@HookFn));
  A := FKbdHook;
  R2 := VdmDeregisterHook(LongInt(@HookFn));
  Check('VdmRegisterHook, FKbdHook, VdmDeregisterHook', (R = 1) And (A = 1) And (R2 = 1) And (FKbdHook = 0) And
        (VdmDeregisterHook(LongInt(@HookFn)) = 0));

  { --- donnees 101 a 122 --- }
  P := 0;
  R2 := DosQueryProcAddr(Hmod, 101, 0, LongInt(@P));
  Check('APFNVDMServ (table : ScreenGroupToFPConsole...)', (APFNVDMServ <> 0) And (RdL(APFNVDMServ) = P));
  Check('GetSelAccess', (GetSelAccess(0) = 0) And (GetSelAccess($1234) = 3));
  Check('NPSZStrings (' + GetZ(NPSZStrings) + ')', GetZ(NPSZStrings) = 'PMVIOP_SHIELD');
  P := SelCommonList;
  Check('SelCommonList, usCommonSegSize', (P <> 0) And (RdL(P + (Hc - $56430001) * 4) = Hc) And (usCommonSegSize = 64));
  Check('ScreenGroupToFPConsole (session sans console : 0)', ScreenGroupToFPConsole(0) = 0);
  Check('Mortician (processus sans console)', Mortician(9999) = 0);

  { --- fin de la console privee --- }
  R := VioDestroyPS(Hvps);
  R := WinDestroyConsole(Hc);
  Pump(100);
  Check('WinDestroyConsole (fenetre detruite, handle refuse)', (R = 0) And (WinIsWindow(Hab, Frame) = 0) And
        (WinDestroyConsole(Hc) = 6) And (QueryConsole(Hc, LongInt(@Info)) = 6) And (HFrameWindowFromConsole(Hc) = 0));

  { --- fenetre OS/2 : CMD.EXE dans une session montree par une console --- }
  S := KSes(4, Z('Fenetre OS/2'), 0);
  R := KSes(12, S, 0);
  PutZ(LongInt(@ArgBuf), 'CMD.EXE');
  ArgBuf[8] := 0; ArgBuf[9] := 0;
  Res[0] := 0; Res[1] := 0;
  R := DosExecPgm(LongInt(@FailBuf), 64, 4, LongInt(@ArgBuf), 0, LongInt(@Res), Z2('C:\CMD.EXE'));
  R2 := WinCreateConsole(HWND_DESKTOP, Z('Fenetre OS/2'), CON_VISIBLE Or CON_SESSION Or (S Shl 8), LongInt(@Hc2));
  Frame2 := HFrameWindowFromConsole(Hc2);
  A := QueryConsole(Hc2, LongInt(@Info));
  Client2 := Info[7];
  Check('CMD.EXE dans la session ' + IStr(S) + ', WinCreateConsole CON_SESSION, ScreenGroupToFPConsole',
        (S > 0) And (R = 0) And (R2 = 0) And (Frame2 <> 0) And (A = 0) And (Info[5] = S) And
        (ScreenGroupToFPConsole(S) = Hc2));
  Bo := WaitSes(S, '[C:', 1, 8000);
  Check('invite de CMD.EXE dans la session', Bo);
  TypeStr(Hc2, 'ECHO VIOP42');
  Bo := WaitSes(S, 'VIOP42', 2, 6000);
  Check('KeyboardEvent -> CMD.EXE : "ECHO VIOP42" execute', Bo);
  Pump(500);
  T := '';
  For I := 0 To 24 Do
    If (T = '') And (Pos('VIOP42', SesLine(S, I)) = 1) Then T := ConText(Client2, I, 0, 6);
  Check('sortie de CMD dessinee dans la fenetre OS/2 (' + T + ')', T = 'VIOP42');
  R2 := QueryConsole(Hc2, LongInt(@Info));
  Check('QueryConsole : curseur de la session (ligne ' + IStr(Info[2]) + ', colonne ' + IStr(Info[3]) + ')',
        (R2 = 0) And (Info[2] > 0) And (Info[3] > 0) And (Pos(']', SesLine(S, Info[2])) > 0));
  If WinOpenClipbrd(Hab) <> 0 Then
  Begin
    R2 := WinEmptyClipbrd(Hab);
    R2 := WinSetClipbrdData(Hab, Z('ECHO COLLE7' + Chr(13) + Chr(10)), CF_TEXT, CFI_POINTER);
    R2 := WinCloseClipbrd(Hab);
  End;
  R2 := WinSendMsg(Client2, WM_COMMAND, 4, 0);
  Bo := WaitSes(S, 'COLLE7', 2, 6000);
  Check('Coller dans la fenetre OS/2 : "ECHO COLLE7" execute', Bo);
  R2 := WinSendMsg(Client2, WM_COMMAND, 3, 0);
  T := Clip;
  Check('Tout copier : ecran de CMD dans le presse-papiers', (Pos('VIOP42', T) > 0) And (Pos('COLLE7', T) > 0));
  R2 := WinPostMsg(Client2, WM_CHAR, KC_CHAR Or KC_SCANCODE Or ($30 Shl 24), Ord('b'));
  R2 := WinPostMsg(Client2, WM_CHAR, KC_CHAR Or KC_SCANCODE Or ($1C Shl 24), 13);
  Bo := WaitSes(S, ']b', 1, 4000);
  Check('WM_CHAR dans la fenetre OS/2 -> clavier de la session ("b" tape a l''invite)', Bo);
  R := WinShieldAbort(Hc2);
  Pump(1500);
  Check('WinShieldAbort : CMD.EXE termine, session liberee, fenetre detruite', (R = 0) And
        (KSes(18, S, LongInt(@Info)) = 0) And (WinIsWindow(Hab, Frame2) = 0) And (ScreenGroupToFPConsole(S) = 0));

  R := WinDestroyMsgQueue(Hmq);
  R2 := WinTerminate(Hab);
  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTVIOP : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
