{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMVIOP.DLL de OS/2-0 (soutien VIO de
                Presentation Manager : "bouclier VIO", fenetres OS/2).
}

Library PMVIOP;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC PMVIOP.PAS   (produit PMVIOP.DLL)

  PMVIOP.DLL est le "bouclier VIO" (VIO Shield) de Presentation Manager :
  il montre un ecran de caracteres (cellules caractere + attribut, comme
  le tampon video du mode texte) dans une fenetre de PM. Les fenetres OS/2
  (et, sous le vrai OS/2, les fenetres DOS et WIN-OS/2) reposent sur lui.

  Console : une fenetre (cadre a titre, menu systeme et bouton de
  reduction ; zone client de la classe PMVIOP_SHIELD, procedure
  VioShieldWindowProc, cadre sous-classe par ShieldFrameProc) qui montre
  soit son propre tampon de cellules (rempli par WinSyncWithPS a partir
  d'un espace de presentation AVIO de VIOCALLS.DLL), soit l'ecran d'une
  session plein ecran du noyau (WinCreateConsole avec CON_SESSION, ou
  ScreenGroupToFPConsole) : le tampon video logique de la session est
  relu toutes les 120 ms (KrnSesCtl 18) et les lignes changees sont
  redessinees, avec le curseur ; les touches frappees dans la fenetre
  vont au clavier de la session (KrnSesCtl 19). C'est une "fenetre
  OS/2" : CMD.EXE et les programmes en mode texte s'y executent pendant
  que le bureau reste visible. Fermer la fenetre termine les programmes
  de la session (apres confirmation ; KrnSesCtl 20).

  Bouton 2 de la souris dans la fenetre : menu Marquer, Copier, Tout
  copier, Coller, Plein ecran, Fermer. Marquer : glisser avec le bouton
  1 choisit un rectangle de cellules (MarkingWindowProc), copie dans le
  presse-papiers de PM (texte) ; Coller envoie le texte du presse-papiers
  au programme, quelques caracteres a la fois (GetPasteChar).

  Handle de console : 56430001h + rang (16 consoles au plus). Codes
  d'erreur : 0, 6 (handle), 50 (non pris en charge : sessions WIN-OS/2
  "seamless" absentes), 87 (parametre), 170 (focus du clavier pris par un
  autre processus), 232 (pas d'evenement), 640 (delai depasse).

  Points d'entree (73 ordinaux, ceux de l'original) :
     1 WinCreateConsole(hwndOwner, pszTitre, fl, phcon) : fl 1 visible,
       2 session (numero dans les bits 8 a 15), 4 clavier ouvert
     2 WinDestroyConsole(hcon)        3 WinSyncWithPS(hcon, hvps)
     4 WinConsoleOpenKbd(hcon)        5 WinConsoleCloseKbd(hcon)
     6 WinConsoleSetStatus(hcon, fl)  7 WinConsoleGetStatus(hcon, pfl) :
       1 gelee, 2 marquage, 4 selection faite
     8 WinConsoleSetCP(hcon, cp)     10 WinConsoleGetCP(hcon, pcp)
    11 WinConsoleKbdXlate(hcon, pKbdKeyInfo) : table de traduction
    12 WinConsoleSetCustXt(hcon, pTable256)
    13 WinConsoleGetFocus(hcon)      14 WinConsoleFreeFocus(hcon)
    15 WinConsoleReadKeyEvent(hcon, pKbdKeyInfo, fWait)
    16 WinConsoleFlushKeyEvents(hcon)
    17 WinConsoleQueuedPointerEvents(hcon) : nombre
    18 WinConsoleReadPointerEvent(hcon, pMouEventInfo, fWait)
    19 WinConsoleFlushPointerEvents(hcon)
    20 WinConsoleGetPointerFilterMask(hcon, pfl)
    21 WinConsoleSetPointerFilterMask(hcon, fl) : evenements ignores
    22 WinConsoleGetPtrPos(hcon, pPos) 23 WinConsoleSetPtrPos(hcon, pPos)
    24 WinShieldAbort(hcon)          25 ShieldFrameProc (procedure)
    26 VioShieldWindowProc           27 LockVioPS(hcon) 28 UnlockVioPS
    29 MarkingWindowProc             30 WinDefAVioWindowProc
    31 WinConsoleGetKbdHandle(hcon, phkbd)
    32 WinConsoleAttachMouseUser(hcon) 33 WinConsoleDetachMouseUser
    34 TaskMgrSubClassProc (procedure)  35 WinShieldPreThaw(hcon)
    36 WinInitShield(hab, hmqTaches)  37 Mortician(pid)
    39 UnlockSemaphores               40 ClearData(hcon)
    41 QueryConsole(hcon, pInfo)      42 MakeVisible(hcon)
    43 GetPasteChar(hcon)             44 SeamlessCommonVDM
    45 SeamlessControlProc            46 TerminateClipDDE
    47 VDMClipDDENotify(fmt)          49 PM32ClipDDENotify(fmt)
    50 Seamless32RegisterObject(hwnd, obj)
    51 Seamless32ActivateWindow(hwnd) 52 NotifyAllVDMs(msg, mp1, mp2)
    53 VDMSwapButtonNotify(fSwap)     54 Get32DisplayType
    55 Seamless32RegisterAssocObj(hwnd, obj)
    56 VdmRegisterHook(pfn)           57 VdmDeregisterHook(pfn)
   Donnees de l'original, rendues ici par des fonctions (OS2PC n'exporte
   que des constantes) :
   101 ScreenGroupToFPConsole(sg)    102 APFNVDMServ (table de services)
   103 GetSelAccess(sel)             104 NPSZStrings (chaines)
   105 KeyboardEvent(hcon, car, code, etat)
   106 EstablishKbdEnvironment(hcon) 107 HMyModuleHandle
   108 FSeamlessCaptured             110 HMQTaskmgr
   111 PCharXlateTblDefault          112, 114, 116 HAPPSeamlessCommonVDM*
   117 FKbdHook                      118 FMouHook
   119 SelCommonList                 120 usCommonSegSize
   121 HMODSeamless                  122 HFrameWindowFromConsole(hcon) }

Const
  NO_ERROR = 0; ERROR_INVALID_HANDLE = 6; ERROR_NOT_SUPPORTED = 50; ERROR_INVALID_PARAMETER = 87;
  ERROR_BUSY = 170; ERROR_NO_DATA = 232; ERROR_TIMEOUT = 640;
  MaxCon = 16; MaxRows = 25; MaxCols = 80; ConCells = 4000; HconBase = $56430001;
  CON_VISIBLE = 1; CON_SESSION = 2; CON_KBD = 4;
  CS_FROZEN = 1; CS_MARKING = 2; CS_SELECTED = 4;
  WM_CREATE = $0001; WM_DESTROY = $0002; WM_SIZE = $0007; WM_SETFOCUS = $000F; WM_COMMAND = $0020;
  WM_PAINT = $0023; WM_TIMER = $0024; WM_CLOSE = $0029; WM_MOUSEMOVE = $0070; WM_BUTTON1DOWN = $0071;
  WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074; WM_BUTTON2UP = $0075;
  WM_BUTTON3DOWN = $0077; WM_BUTTON3UP = $0078; WM_CHAR = $007A; WM_BUTTON2CLICK = $0416; WM_CONTEXTMENU = $0424;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_BACKSPACE = 5; VK_TAB = 6; VK_NEWLINE = 8; VK_ESC = $0F; VK_ENTER = $1E;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80; SWP_RESTORE = $1000;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_DLGBORDER = $200;
  MB_YESNO = 4; MB_WARNING = $20; MB_MOVEABLE = $4000; MBID_YES = 6;
  CF_TEXT = 1; CFI_POINTER = $400;
  { menu de la fenetre }
  CM_MARK = 1; CM_COPY = 2; CM_COPYALL = 3; CM_PASTE = 4; CM_FULL = 5; CM_CLOSE = 6;
  { couleurs du VGA -> couleurs de PM }
  VgaClr : Array[0..15] Of LongInt = (-1, 9, 12, 13, 10, 11, 14, 15, 8, 1, 4, 5, 2, 3, 6, -2);

Var
  CUse, CPid, CFrame, CClient, CSess, CRows, CCols, CCurR, CCurC, CStatus, CCp, CKbd, CFocus : Array[0..MaxCon - 1] Of LongInt;
  CLock, CMou, CFilter, CPtrR, CPtrC, CXlt, CKH, CKT, CPH, CPT, CMark, CMR1, CMC1, CMR2, CMC2 : Array[0..MaxCon - 1] Of LongInt;
  CPLen, CPPos, COldFrame, CSnapR, CSnapC, CFull, CVisR, CVisC, COrgR, COrgC : Array[0..MaxCon - 1] Of LongInt;
  CKV, CKX, CKTm : Array[0..MaxCon * 32 - 1] Of LongInt;      { evenements du clavier }
  CPF, CPTm, CPR, CPC : Array[0..MaxCon * 32 - 1] Of LongInt; { evenements de la souris }
  CBuf, CSnap : Array[0..MaxCon * ConCells - 1] Of Byte;      { cellules, image affichee }
  CPaste : Array[0..MaxCon * 256 - 1] Of Byte;
  CTitle : Array[0..MaxCon - 1] Of String[60];
  Creating, ClassesOk, ShieldHab, TaskHmq, SwapBtn, ClipDirty, MenuH, MenuCon, Dummy, InitI : LongInt;
  HookFn, HookPid : Array[0..7] Of LongInt;
  SeamH, SeamObj, SeamAssoc : Array[0..15] Of LongInt;
  VdmSvc : Array[0..7] Of LongInt;
  CommonList : Array[0..MaxCon - 1] Of LongInt;
  DefXlt : Array[0..255] Of Byte;
  Strs : Array[0..255] Of Byte;
  NameZ, NameZ2 : Array[0..127] Of Byte;
  MenuTpl : Array[0..511] Of Byte;
  MenuLen, MenuCnt : LongInt;
  TextBuf : Array[0..4095] Of Byte;
  Qd : Array[0..7] Of LongInt;

{ --- DOSCALLS.DLL et noyau --- }
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryModuleHandle(PName, PH : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function KSes(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnSesCtl';
Function KGetTickCount : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';

{ --- PMWIN.DLL --- }
Function WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN';
Function WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, Id, PClient : LongInt) : LongInt; External 'PMWIN';
Function WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN';
Function WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSysClassProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WINSYSCLASSPROC';
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
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSubclassWindow(H, Proc : LongInt) : LongInt; External 'PMWIN';
Function WinIsWindow(Hab, H : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN';
Function WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt; External 'PMWIN';
Function WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';

{ --- VIOCALLS.DLL --- }
Function VioGetPSAddress(PPBuf, Hvps : LongInt) : LongInt; External 'VIOCALLS';
Function VioQueryVbe(P : LongInt) : LongInt; External 'VIOCALLS' Name 'VIOQUERYVBE';
Function VioGetMode(PMode, Hvio : LongInt) : LongInt; External 'VIOCALLS';

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

Procedure WrL(A, V : LongInt);
Type PLong = ^LongInt;
Var Q : PLong;
Begin
  Q := Pointer(A);
  Q^ := V;
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

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ adresse exportee (convention _System, celle qu'attend PMWIN pour une
  procedure de DLL) du point d'entree d'ordinal N de PMVIOP }
Function ExpAddr(N : LongInt) : LongInt;
Var H, P : LongInt;
Begin
  H := 0; P := 0;
  If DosQueryModuleHandle(Z2('PMVIOP'), LongInt(@H)) = 0 Then
    If DosQueryProcAddr(H, N, 0, LongInt(@P)) <> 0 Then P := 0;
  ExpAddr := P;
End;

Function Alive(Pid : LongInt) : Boolean;
Begin
  Alive := (Pid = 0) Or (Pid = MyPid) Or (KrnMonIo(0, 4, Pid) <> 0);
End;

{ rang de la console du handle H (-1 : invalide) }
Function ConIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - HconBase;
  If (I < 0) Or (I >= MaxCon) Then I := -1
  Else If CUse[I] = 0 Then I := -1;
  ConIdx := I;
End;

Function ConOfClient(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxCon - 1 Do
    If (CUse[I] <> 0) And (CClient[I] = H) And (H <> 0) Then R := I;
  ConOfClient := R;
End;

Function ConOfFrame(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 0 To MaxCon - 1 Do
    If (CUse[I] <> 0) And (CFrame[I] = H) And (H <> 0) Then R := I;
  ConOfFrame := R;
End;

{ adresse des cellules affichees : tampon de la session, ou propre tampon }
Function SrcOf(I : LongInt) : LongInt;
Var Inf : Array[0..7] Of LongInt;
Begin
  SrcOf := LongInt(@CBuf) + I * ConCells;
  If CSess[I] >= 0 Then
    If KSes(18, CSess[I], LongInt(@Inf)) <> 0 Then SrcOf := Inf[0];
End;

{ zone visible : la fenetre (bornee par l'ecran) montre CVisR x CVisC
  cellules a partir de la ligne COrgR et de la colonne COrgC ; la
  cellule (R, C) est en (XOf, YOf) dans la zone client }
Function XOf(I, C : LongInt) : LongInt;
Begin
  XOf := (C - COrgC[I]) * 8;
End;

Function YOf(I, R : LongInt) : LongInt;
Begin
  YOf := (CVisR[I] - 1 - (R - COrgR[I])) * 16;
End;

{ cellule sous le point (x, y) de la zone client }
Function CellC(I, X : LongInt) : LongInt;
Begin
  CellC := MaxI(0, MinI(CCols[I] - 1, COrgC[I] + S16(X) Div 8));
End;

Function CellR(I, Y : LongInt) : LongInt;
Begin
  Y := S16(Y);
  If Y < 0 Then Y := -16;
  CellR := MaxI(0, MinI(CRows[I] - 1, COrgR[I] + CVisR[I] - 1 - Y Div 16));
End;

Procedure InvalCell(I, R, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If CClient[I] = 0 Then Exit;
  Rc[0] := XOf(I, C); Rc[2] := Rc[0] + 8;
  Rc[1] := YOf(I, R); Rc[3] := Rc[1] + 16;
  Dummy := WinInvalidateRect(CClient[I], LongInt(@Rc), 0);
End;

Procedure InvalRow(I, R : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If CClient[I] = 0 Then Exit;
  Rc[0] := 0; Rc[2] := CVisC[I] * 8;
  Rc[1] := YOf(I, R); Rc[3] := Rc[1] + 16;
  Dummy := WinInvalidateRect(CClient[I], LongInt(@Rc), 0);
End;

{ la zone visible suit le curseur de la session }
Procedure Follow(I, R, C : LongInt);
Var R0, C0 : LongInt;
Begin
  R0 := COrgR[I]; C0 := COrgC[I];
  If R < COrgR[I] Then COrgR[I] := R;
  If R >= COrgR[I] + CVisR[I] Then COrgR[I] := R - CVisR[I] + 1;
  If C < COrgC[I] Then COrgC[I] := C;
  If C >= COrgC[I] + CVisC[I] Then COrgC[I] := C - CVisC[I] + 1;
  COrgR[I] := MaxI(0, MinI(COrgR[I], CRows[I] - CVisR[I]));
  COrgC[I] := MaxI(0, MinI(COrgC[I], CCols[I] - CVisC[I]));
  If ((R0 <> COrgR[I]) Or (C0 <> COrgC[I])) And (CClient[I] <> 0) Then
    Dummy := WinInvalidateRect(CClient[I], 0, 0);
End;

{ ==================================================================== }
{ Evenements du clavier et de la souris                                 }
{ ==================================================================== }

Procedure KeyQueue(I, V, Xt : LongInt);
Var N : LongInt;
Begin
  N := (CKH[I] + 1) And 31;
  If N = CKT[I] Then Exit;
  CKV[I * 32 + CKH[I]] := V; CKX[I * 32 + CKH[I]] := Xt; CKTm[I * 32 + CKH[I]] := KGetTickCount;
  CKH[I] := N;
End;

Procedure PtrQueue(I, Fs : LongInt);
Var N : LongInt;
Begin
  If (CMou[I] = 0) Or ((Fs And CFilter[I]) = Fs) Then Exit;
  N := (CPH[I] + 1) And 31;
  If N = CPT[I] Then Exit;
  CPF[I * 32 + CPH[I]] := Fs; CPTm[I * 32 + CPH[I]] := KGetTickCount;
  CPR[I * 32 + CPH[I]] := CPtrR[I]; CPC[I * 32 + CPH[I]] := CPtrC[I];
  CPH[I] := N;
End;

{ touche (caractere + code Shl 8, etat) : a la session, et aux lecteurs
  de la console (WinConsoleReadKeyEvent) }
Procedure KeyTo(I, V, Xt : LongInt);
Var Kv : Array[0..1] Of LongInt;
Begin
  If CSess[I] >= 0 Then
  Begin
    Kv[0] := V; Kv[1] := Xt;
    Dummy := KSes(19, CSess[I], LongInt(@Kv));
  End;
  If CKbd[I] <> 0 Then KeyQueue(I, V, Xt);
End;

{ ==================================================================== }
{ Dessin de la console                                                  }
{ ==================================================================== }

Function InSel(I, R, C : LongInt) : Boolean;
Begin
  InSel := (CMark[I] <> 0) And (R >= MinI(CMR1[I], CMR2[I])) And (R <= MaxI(CMR1[I], CMR2[I])) And
           (C >= MinI(CMC1[I], CMC2[I])) And (C <= MaxI(CMC1[I], CMC2[I]));
End;

Procedure PaintCon(I, H : LongInt);
Var Hps, R, C, C0, A, A0, Src, N, Fg, Bg, Ch, RE, CE : LongInt; Rc, Rp : Array[0..3] Of LongInt; B : Array[0..95] Of Byte;
    S0, S : Boolean;
Begin
  Hps := WinBeginPaint(H, 0, LongInt(@Rp));
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Src := SrcOf(I);
  RE := MinI(CRows[I], COrgR[I] + CVisR[I]); CE := MinI(CCols[I], COrgC[I] + CVisC[I]);
  For R := COrgR[I] To RE - 1 Do
  Begin
    C := COrgC[I];
    While C < CE Do
    Begin
      C0 := C; A0 := RdB(Src + (R * CCols[I] + C) * 2 + 1); S0 := InSel(I, R, C);
      N := 0;
      While C < CE Do
      Begin
        A := RdB(Src + (R * CCols[I] + C) * 2 + 1); S := InSel(I, R, C);
        If (A <> A0) Or (S <> S0) Then Break;
        Ch := RdB(Src + (R * CCols[I] + C) * 2);
        If Ch = 0 Then Ch := 32;
        B[N] := Ch;
        Inc(N); Inc(C);
      End;
      Fg := VgaClr[A0 And 15]; Bg := VgaClr[(A0 Shr 4) And 7];
      If S0 Then
      Begin
        A := Fg; Fg := Bg; Bg := A;
      End;
      Rc[0] := XOf(I, C0); Rc[2] := XOf(I, C); Rc[1] := YOf(I, R); Rc[3] := Rc[1] + 16;
      Dummy := WinDrawText(Hps, N, LongInt(@B), LongInt(@Rc), Fg, Bg, 0);
    End;
  End;
  { curseur (session) : trait sous la cellule }
  If (CSess[I] >= 0) And (CSnapR[I] >= COrgR[I]) And (CSnapR[I] < RE) And (CSnapC[I] >= COrgC[I]) And (CSnapC[I] < CE) Then
  Begin
    Rc[0] := XOf(I, CSnapC[I]); Rc[2] := Rc[0] + 8; Rc[1] := YOf(I, CSnapR[I]) + 1; Rc[3] := Rc[1] + 2;
    Dummy := WinFillRect(Hps, LongInt(@Rc), -2);
  End;
  Dummy := WinEndPaint(Hps);
End;

{ session : lignes changees et curseur redessines ; fermeture quand la
  session n'existe plus (programme termine) }
Procedure RefreshCon(I : LongInt);
Var Inf : Array[0..7] Of LongInt; R, K, Src, Base : LongInt; Diff : Boolean; Kv : Array[0..1] Of LongInt;
Begin
  If CSess[I] < 0 Then Exit;
  If KSes(18, CSess[I], LongInt(@Inf)) = 0 Then
  Begin
    { la session n'existe plus }
    Dummy := WinPostMsg(CFrame[I], WM_CLOSE, 0, 1);
    Exit;
  End;
  { texte colle : envoye au programme quelques caracteres a la fois }
  K := 0;
  While (CPPos[I] < CPLen[I]) And (K < 6) Do
  Begin
    Kv[0] := CPaste[I * 256 + CPPos[I]]; Kv[1] := 0;
    If KSes(19, CSess[I], LongInt(@Kv)) = 0 Then K := 99
    Else
    Begin
      Inc(CPPos[I]); Inc(K);
    End;
  End;
  If (CStatus[I] And CS_FROZEN) <> 0 Then Exit;
  If CLock[I] > 0 Then Exit;
  Src := Inf[0]; Base := I * ConCells;
  For R := 0 To CRows[I] - 1 Do
  Begin
    Diff := CFull[I] <> 0;
    K := 0;
    While (Not Diff) And (K < CCols[I] * 2) Do
    Begin
      If RdB(Src + R * CCols[I] * 2 + K) <> CSnap[Base + R * CCols[I] * 2 + K] Then Diff := True;
      Inc(K);
    End;
    If Diff Then
    Begin
      For K := 0 To CCols[I] * 2 - 1 Do CSnap[Base + R * CCols[I] * 2 + K] := RdB(Src + R * CCols[I] * 2 + K);
      InvalRow(I, R);
    End;
  End;
  CFull[I] := 0;
  If (Inf[1] <> CSnapR[I]) Or (Inf[2] <> CSnapC[I]) Then
  Begin
    If CSnapR[I] >= 0 Then InvalCell(I, CSnapR[I], CSnapC[I]);
    CSnapR[I] := Inf[1]; CSnapC[I] := Inf[2];
    InvalCell(I, CSnapR[I], CSnapC[I]);
    Follow(I, CSnapR[I], CSnapC[I]);
  End;
End;

{ ==================================================================== }
{ Presse-papiers : copier, coller                                       }
{ ==================================================================== }

Procedure CopyCells(I : LongInt; All : Boolean);
Var R, C, R1, R2, C1, C2, N, L, Src, Ch : LongInt;
Begin
  Src := SrcOf(I);
  If All Or (CMark[I] = 0) Then
  Begin
    R1 := 0; R2 := CRows[I] - 1; C1 := 0; C2 := CCols[I] - 1;
  End
  Else
  Begin
    R1 := MinI(CMR1[I], CMR2[I]); R2 := MaxI(CMR1[I], CMR2[I]);
    C1 := MinI(CMC1[I], CMC2[I]); C2 := MaxI(CMC1[I], CMC2[I]);
  End;
  N := 0;
  For R := R1 To R2 Do
  Begin
    L := N;
    For C := C1 To C2 Do
    Begin
      Ch := RdB(Src + (R * CCols[I] + C) * 2);
      If Ch = 0 Then Ch := 32;
      TextBuf[N] := Ch;
      Inc(N);
      If Ch <> 32 Then L := N;
    End;
    N := L;
    If R < R2 Then
    Begin
      TextBuf[N] := 13; TextBuf[N + 1] := 10; N := N + 2;
    End;
  End;
  TextBuf[N] := 0;
  If WinOpenClipbrd(ShieldHab) <> 0 Then
  Begin
    Dummy := WinEmptyClipbrd(ShieldHab);
    Dummy := WinSetClipbrdData(ShieldHab, LongInt(@TextBuf), CF_TEXT, CFI_POINTER);
    Dummy := WinCloseClipbrd(ShieldHab);
  End;
End;

Procedure PasteText(I : LongInt);
Var P, K, N, Ch : LongInt;
Begin
  If WinOpenClipbrd(ShieldHab) = 0 Then Exit;
  P := WinQueryClipbrdData(ShieldHab, CF_TEXT);
  N := 0;
  If P <> 0 Then
  Begin
    K := 0;
    While (RdB(P + K) <> 0) And (N < 255) Do
    Begin
      Ch := RdB(P + K);
      If Ch <> 10 Then
      Begin
        CPaste[I * 256 + N] := Ch;
        Inc(N);
      End;
      Inc(K);
    End;
  End;
  Dummy := WinCloseClipbrd(ShieldHab);
  CPLen[I] := N; CPPos[I] := 0;
End;

{ ==================================================================== }
{ Procedures de fenetre                                                 }
{ ==================================================================== }

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

Procedure ConMenu(I, X, Y : LongInt);
Begin
  MenuLen := 6; MenuCnt := 0;
  MenuAdd(CM_MARK, '~Marquer');
  MenuAdd(CM_COPY, '~Copier');
  MenuAdd(CM_COPYALL, '~Tout copier');
  MenuAdd(CM_PASTE, 'C~oller');
  MenuAdd(0, '');
  If CSess[I] >= 0 Then MenuAdd(CM_FULL, '~Plein ecran');
  MenuAdd(CM_CLOSE, '~Fermer');
  WrW(LongInt(@MenuTpl), MenuLen); WrW(LongInt(@MenuTpl) + 2, 0); WrW(LongInt(@MenuTpl) + 4, MenuCnt);
  If MenuH <> 0 Then Dummy := WinDestroyWindow(MenuH);
  MenuH := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuTpl));
  MenuCon := I;
  If MenuH <> 0 Then Dummy := WinPopupMenu(CClient[I], CClient[I], MenuH, X, Y, CM_MARK, 0);
End;

Procedure DestroyCon(I : LongInt);
Var F : LongInt;
Begin
  If (I < 0) Or (I >= MaxCon) Or (CUse[I] = 0) Then Exit;
  F := CFrame[I];
  CUse[I] := 0;
  If CClient[I] <> 0 Then Dummy := WinStopTimer(ShieldHab, CClient[I], 1);
  CClient[I] := 0; CFrame[I] := 0;
  CommonList[I] := 0;
  If F <> 0 Then Dummy := WinDestroyWindow(F);
End;

{ fermer : avec un programme en cours dans la session, confirmation puis
  fin des processus de la session }
Procedure CloseCon(I : LongInt; Ask : Boolean);
Var Inf : Array[0..7] Of LongInt;
Begin
  If (CSess[I] >= 0) And (KSes(18, CSess[I], LongInt(@Inf)) <> 0) And (Inf[5] > 0) Then
  Begin
    If Ask Then
      If WinMessageBox(HWND_DESKTOP, CFrame[I], Z('Fermer cette fenetre met fin au programme qui s''y execute. ' +
                       'Continuer ?'), Z2(CTitle[I]), 0, MB_YESNO Or MB_WARNING Or MB_MOVEABLE) <> MBID_YES Then Exit;
    Dummy := KSes(20, CSess[I], 0);
  End;
  DestroyCon(I);
End;

Function VioShieldWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; Forward;

{ marquage : glisser avec le bouton 1 choisit un rectangle de cellules }
Function MarkingWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, R, C : LongInt;
Begin
  MarkingWindowProc := 1;
  I := ConOfClient(H);
  If I < 0 Then
  Begin
    MarkingWindowProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  C := CellC(I, Mp1); R := CellR(I, Mp1 Shr 16);
  Case Msg Of
    WM_BUTTON1DOWN :
      Begin
        CMark[I] := 1; CMR1[I] := R; CMC1[I] := C; CMR2[I] := R; CMC2[I] := C;
        Dummy := WinSetCapture(HWND_DESKTOP, H);
        Dummy := WinInvalidateRect(H, 0, 0);
      End;
    WM_MOUSEMOVE :
      Begin
        If CMark[I] = 1 Then
          If (R <> CMR2[I]) Or (C <> CMC2[I]) Then
          Begin
            CMR2[I] := R; CMC2[I] := C;
            Dummy := WinInvalidateRect(H, 0, 0);
          End;
        MarkingWindowProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
      End;
    WM_BUTTON1UP :
      If CMark[I] = 1 Then
      Begin
        Dummy := WinSetCapture(HWND_DESKTOP, 0);
        CMark[I] := 2; CMR2[I] := R; CMC2[I] := C;
        CStatus[I] := (CStatus[I] And Not CS_MARKING) Or CS_SELECTED;
        Dummy := WinInvalidateRect(H, 0, 0);
      End;
  Else
    MarkingWindowProc := VioShieldWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

Function VioShieldWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, Fl, Ch, Sc, Vk, Xt, Fs : LongInt;
Begin
  VioShieldWindowProc := 0;
  I := ConOfClient(H);
  If (I < 0) And (Msg = WM_CREATE) And (Creating >= 0) Then
  Begin
    CClient[Creating] := H;
    Exit;
  End;
  If I < 0 Then
  Begin
    VioShieldWindowProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  { marquage en cours : souris a MarkingWindowProc }
  If ((CStatus[I] And CS_MARKING) <> 0) And ((Msg = WM_BUTTON1DOWN) Or (Msg = WM_BUTTON1UP) Or (Msg = WM_MOUSEMOVE)) Then
  Begin
    VioShieldWindowProc := MarkingWindowProc(H, Msg, Mp1, Mp2);
    Exit;
  End;
  If CMark[I] = 1 Then
  Begin
    If (Msg = WM_MOUSEMOVE) Or (Msg = WM_BUTTON1UP) Then
    Begin
      VioShieldWindowProc := MarkingWindowProc(H, Msg, Mp1, Mp2);
      Exit;
    End;
  End;
  Case Msg Of
    WM_PAINT : PaintCon(I, H);
    WM_TIMER : If Lo16(Mp1) = 1 Then RefreshCon(I);
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1);
        VioShieldWindowProc := 1;
        If (Fl And KC_KEYUP) <> 0 Then Exit;
        Sc := (Mp1 Shr 24) And 255; Ch := Lo16(Mp2) And 255; Vk := Hi16(Mp2);
        If (Fl And KC_CHAR) = 0 Then Ch := 0;
        If (Fl And KC_VIRTUALKEY) <> 0 Then
          Case Vk Of
            VK_NEWLINE, VK_ENTER : Ch := 13;
            VK_BACKSPACE : Ch := 8;
            VK_TAB : Ch := 9;
            VK_ESC : Ch := 27;
          End;
        If ((Fl And KC_CTRL) <> 0) And (((Ch >= 65) And (Ch <= 90)) Or ((Ch >= 97) And (Ch <= 122))) Then
          Ch := Ch And $1F;
        If (Fl And KC_ALT) <> 0 Then Ch := 0;
        { traduction de la console (WinConsoleSetCustXt) }
        If CXlt[I] <> 0 Then Ch := RdB(CXlt[I] + Ch);
        Xt := 0;
        If (Fl And KC_SHIFT) <> 0 Then Xt := Xt Or 2;
        If (Fl And KC_CTRL) <> 0 Then Xt := Xt Or 4;
        If (Fl And KC_ALT) <> 0 Then Xt := Xt Or 8;
        If (Ch = 0) And (Sc >= $47) And (Sc <= $53) Then Xt := Xt Or $10000;
        If CMark[I] <> 0 Then
        Begin
          CMark[I] := 0; CStatus[I] := CStatus[I] And Not (CS_SELECTED Or CS_MARKING);
          Dummy := WinInvalidateRect(H, 0, 0);
        End;
        KeyTo(I, (Sc Shl 8) Or Ch, Xt);
      End;
    WM_MOUSEMOVE, WM_BUTTON1DOWN, WM_BUTTON1UP, WM_BUTTON2DOWN, WM_BUTTON2UP, WM_BUTTON3DOWN, WM_BUTTON3UP :
      Begin
        CPtrC[I] := CellC(I, Mp1); CPtrR[I] := CellR(I, Mp1 Shr 16);
        Fs := 0;
        Case Msg Of
          WM_MOUSEMOVE : Fs := 1;
          WM_BUTTON1DOWN : If SwapBtn <> 0 Then Fs := 16 Else Fs := 4;
          WM_BUTTON2DOWN : If SwapBtn <> 0 Then Fs := 4 Else Fs := 16;
          WM_BUTTON3DOWN : Fs := 64;
        End;
        If Fs <> 0 Then PtrQueue(I, Fs);
        If Msg = WM_BUTTON1DOWN Then
        Begin
          Dummy := WinSetFocus(HWND_DESKTOP, H);
          If CMark[I] <> 0 Then
          Begin
            CMark[I] := 0; CStatus[I] := CStatus[I] And Not CS_SELECTED;
            Dummy := WinInvalidateRect(H, 0, 0);
          End;
        End;
        If Msg = WM_MOUSEMOVE Then VioShieldWindowProc := WinDefWindowProc(H, Msg, Mp1, Mp2)
        Else VioShieldWindowProc := 1;
      End;
    WM_BUTTON2CLICK :
      Begin
        ConMenu(I, S16(Mp1), S16(Mp1 Shr 16));
        VioShieldWindowProc := 1;
      End;
    WM_CONTEXTMENU :
      Begin
        ConMenu(I, CVisC[I] * 4, CVisR[I] * 8);
        VioShieldWindowProc := 1;
      End;
    WM_COMMAND :
      Case Lo16(Mp1) Of
        CM_MARK : CStatus[I] := CStatus[I] Or CS_MARKING;
        CM_COPY : CopyCells(I, False);
        CM_COPYALL : CopyCells(I, True);
        CM_PASTE : PasteText(I);
        CM_FULL : If CSess[I] >= 0 Then Dummy := KSes(3, CSess[I], 0);
        CM_CLOSE : CloseCon(I, True);
      End;
    WM_CLOSE : CloseCon(I, Mp2 = 0);
    WM_DESTROY :
      Begin
        If CUse[I] <> 0 Then
        Begin
          CUse[I] := 0; CommonList[I] := 0; CClient[I] := 0; CFrame[I] := 0;
        End;
      End;
  Else
    VioShieldWindowProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
  End;
End;

{ cadre de la console : fermeture (confirmation si un programme tourne),
  le reste au cadre de PMWIN }
Function ShieldFrameProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConOfFrame(H);
  If (I >= 0) And (Msg = WM_CLOSE) Then
  Begin
    CloseCon(I, Mp2 = 0);
    ShieldFrameProc := 0;
    Exit;
  End;
  ShieldFrameProc := WinSysClassProc(H, Msg, Mp1, Mp2);
End;

{ classes de PMVIOP (une fois par systeme : PMVIOP.DLL est partagee) }
Procedure InitClasses(Hab : LongInt);
Begin
  If ClassesOk <> 0 Then Exit;
  Dummy := WinRegisterClass(Hab, Z('PMVIOP_SHIELD'), ExpAddr(26), $10, 8);
  Dummy := WinRegisterClass(Hab, Z('PMVIOP_MARKING'), ExpAddr(29), $10, 8);
  ClassesOk := 1;
End;

{ ==================================================================== }
{ Points d'entree                                                       }
{ ==================================================================== }

Function WinCreateConsole(HwndOwner, PTitle, Fl, PHcon : LongInt) : LongInt;
Var I, K, F, Flags, Cl, S, W, Hh, X, Y : LongInt; Inf : Array[0..7] Of LongInt;
Begin
  WinCreateConsole := ERROR_INVALID_PARAMETER;
  If PHcon = 0 Then Exit;
  S := -1;
  If (Fl And CON_SESSION) <> 0 Then
  Begin
    S := (Fl Shr 8) And 255;
    If KSes(18, S, LongInt(@Inf)) = 0 Then Exit;
  End;
  F := -1;
  For I := MaxCon - 1 DownTo 0 Do
    If CUse[I] = 0 Then F := I;
  If F < 0 Then
  Begin
    WinCreateConsole := ERROR_NOT_SUPPORTED;
    Exit;
  End;
  InitClasses(ShieldHab);
  CUse[F] := 1; CPid[F] := MyPid; CSess[F] := S; CRows[F] := MaxRows; CCols[F] := MaxCols;
  If S >= 0 Then
  Begin
    CRows[F] := MinI(MaxRows, Inf[3]); CCols[F] := MinI(MaxCols, Inf[4]);
  End;
  CCurR[F] := 0; CCurC[F] := 0; CStatus[F] := 0; CCp[F] := 850; CKbd[F] := 0; CFocus[F] := 0; CLock[F] := 0;
  CMou[F] := 0; CFilter[F] := 0; CPtrR[F] := 0; CPtrC[F] := 0; CXlt[F] := 0; CKH[F] := 0; CKT[F] := 0;
  CPH[F] := 0; CPT[F] := 0; CMark[F] := 0; CPLen[F] := 0; CPPos[F] := 0; CSnapR[F] := -1; CSnapC[F] := 0;
  CFull[F] := 1;
  If (Fl And CON_KBD) <> 0 Then CKbd[F] := 1;
  For K := 0 To ConCells - 1 Do
    If (K And 1) = 0 Then CBuf[F * ConCells + K] := 32 Else CBuf[F * ConCells + K] := 7;
  If PTitle <> 0 Then CTitle[F] := GetZ(PTitle) Else CTitle[F] := 'Fenetre OS/2';
  Flags := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_DLGBORDER;
  Cl := 0;
  Creating := F;
  CFrame[F] := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Flags), Z('PMVIOP_SHIELD'), Z2(CTitle[F]), 0, 0, 0,
                                  LongInt(@Cl));
  Creating := -1;
  If (CFrame[F] = 0) Or (Cl = 0) Then
  Begin
    CUse[F] := 0;
    WinCreateConsole := ERROR_NOT_SUPPORTED;
    Exit;
  End;
  CClient[F] := Cl;
  COldFrame[F] := WinSubclassWindow(CFrame[F], ExpAddr(25));
  { fenetre bornee par l'ecran (640 x 480 : 79 colonnes visibles, la zone
    visible suit le curseur) }
  W := MinI(CCols[F] * 8 + 8, WinQuerySysValue(HWND_DESKTOP, 20));
  Hh := MinI(CRows[F] * 16 + 28, WinQuerySysValue(HWND_DESKTOP, 21) - 16);
  CVisC[F] := MinI(CCols[F], (W - 8) Div 8); CVisR[F] := MinI(CRows[F], (Hh - 28) Div 16);
  W := CVisC[F] * 8 + 8; Hh := CVisR[F] * 16 + 28;
  COrgR[F] := 0; COrgC[F] := 0;
  X := MaxI(0, MinI(WinQuerySysValue(HWND_DESKTOP, 20) - W, 24 + F * 20));
  Y := MaxI(0, WinQuerySysValue(HWND_DESKTOP, 21) - Hh - 24 - F * 20);
  If (Fl And CON_VISIBLE) <> 0 Then
    Dummy := WinSetWindowPos(CFrame[F], HWND_TOP, X, Y, W, Hh, SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE)
  Else Dummy := WinSetWindowPos(CFrame[F], HWND_TOP, X, Y, W, Hh, SWP_SIZE Or SWP_MOVE);
  Dummy := WinStartTimer(ShieldHab, Cl, 1, 120);
  If (Fl And CON_VISIBLE) <> 0 Then Dummy := WinSetFocus(HWND_DESKTOP, Cl);
  CommonList[F] := HconBase + F;
  WrL(PHcon, HconBase + F);
  WinCreateConsole := NO_ERROR;
End;

Function WinDestroyConsole(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    WinDestroyConsole := ERROR_INVALID_HANDLE;
    Exit;
  End;
  DestroyCon(I);
  WinDestroyConsole := NO_ERROR;
End;

{ cellules (2 octets : caractere, attribut) d'un espace AVIO de VIOCALLS
  vers le tampon de la console (sans session) }
Function WinSyncWithPS(Hcon, Hvps : LongInt) : LongInt;
Var I, P, K, R, C, Pc, Pr, Cs : LongInt; Md : Array[0..9] Of LongInt;
Begin
  WinSyncWithPS := ERROR_INVALID_HANDLE;
  I := ConIdx(Hcon);
  If I < 0 Then Exit;
  If CSess[I] >= 0 Then
  Begin
    WinSyncWithPS := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  P := 0;
  If (VioGetPSAddress(LongInt(@P), Hvps) <> 0) Or (P = 0) Then
  Begin
    WinSyncWithPS := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  { dimensions et format du PS : VIOMODEINFO (colonnes, lignes, taille
    du tampon -> 2 ou 4 octets par cellule) }
  WrW(LongInt(@Md), 34);
  If VioGetMode(LongInt(@Md), Hvps) <> 0 Then
  Begin
    WinSyncWithPS := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Pc := RdW(LongInt(@Md) + 4); Pr := RdW(LongInt(@Md) + 6);
  Cs := 2;
  If (Pc > 0) And (Pr > 0) Then
    If RdL(LongInt(@Md) + 18) >= Pc * Pr * 4 Then Cs := 4;
  For R := 0 To CRows[I] - 1 Do
    For C := 0 To CCols[I] - 1 Do
    Begin
      K := I * ConCells + (R * CCols[I] + C) * 2;
      If (R < Pr) And (C < Pc) Then
      Begin
        CBuf[K] := RdB(P + (R * Pc + C) * Cs); CBuf[K + 1] := RdB(P + (R * Pc + C) * Cs + 1);
      End
      Else
      Begin
        CBuf[K] := 32; CBuf[K + 1] := 7;
      End;
    End;
  If CClient[I] <> 0 Then Dummy := WinInvalidateRect(CClient[I], 0, 0);
  WinSyncWithPS := NO_ERROR;
End;

Function WinConsoleOpenKbd(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleOpenKbd := ERROR_INVALID_HANDLE
  Else
  Begin
    CKbd[I] := 1;
    WinConsoleOpenKbd := NO_ERROR;
  End;
End;

Function WinConsoleCloseKbd(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleCloseKbd := ERROR_INVALID_HANDLE
  Else
  Begin
    CKbd[I] := 0; CKH[I] := 0; CKT[I] := 0;
    WinConsoleCloseKbd := NO_ERROR;
  End;
End;

Function WinConsoleSetStatus(Hcon, Fl : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    WinConsoleSetStatus := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If ((CStatus[I] And CS_FROZEN) <> 0) And ((Fl And CS_FROZEN) = 0) Then CFull[I] := 1;
  If (Fl And (CS_MARKING Or CS_SELECTED)) = 0 Then CMark[I] := 0;
  CStatus[I] := Fl And 7;
  If CClient[I] <> 0 Then Dummy := WinInvalidateRect(CClient[I], 0, 0);
  WinConsoleSetStatus := NO_ERROR;
End;

Function WinConsoleGetStatus(Hcon, PFl : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleGetStatus := ERROR_INVALID_HANDLE
  Else If PFl = 0 Then WinConsoleGetStatus := ERROR_INVALID_PARAMETER
  Else
  Begin
    WrL(PFl, CStatus[I]);
    WinConsoleGetStatus := NO_ERROR;
  End;
End;

Function WinConsoleSetCP(Hcon, Cp : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleSetCP := ERROR_INVALID_HANDLE
  Else If (Cp <> 437) And (Cp <> 850) And (Cp <> 852) And (Cp <> 857) And (Cp <> 860) And (Cp <> 861) And
          (Cp <> 863) And (Cp <> 865) And (Cp <> 866) And (Cp <> 869) Then WinConsoleSetCP := ERROR_INVALID_PARAMETER
  Else
  Begin
    CCp[I] := Cp;
    WinConsoleSetCP := NO_ERROR;
  End;
End;

Function WinConsoleGetCP(Hcon, PCp : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleGetCP := ERROR_INVALID_HANDLE
  Else If PCp = 0 Then WinConsoleGetCP := ERROR_INVALID_PARAMETER
  Else
  Begin
    WrL(PCp, CCp[I]);
    WinConsoleGetCP := NO_ERROR;
  End;
End;

{ KBDKEYINFO : chChar, chScan, fbStatus, bNlsShift, fsState (2), time (4) ;
  le caractere passe par la table de la console (ou la table identite) }
Function WinConsoleKbdXlate(Hcon, PKey : LongInt) : LongInt;
Var I, Ch : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    WinConsoleKbdXlate := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If PKey = 0 Then
  Begin
    WinConsoleKbdXlate := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Ch := RdB(PKey);
  If CXlt[I] <> 0 Then Ch := RdB(CXlt[I] + Ch) Else Ch := DefXlt[Ch];
  WrB(PKey, Ch);
  WrB(PKey + 2, RdB(PKey + 2) Or $40);      { traduction terminee }
  WinConsoleKbdXlate := NO_ERROR;
End;

Function WinConsoleSetCustXt(Hcon, PTable : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleSetCustXt := ERROR_INVALID_HANDLE
  Else
  Begin
    CXlt[I] := PTable;
    WinConsoleSetCustXt := NO_ERROR;
  End;
End;

Function WinConsoleGetFocus(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleGetFocus := ERROR_INVALID_HANDLE
  Else If (CFocus[I] <> 0) And (CFocus[I] <> MyPid) And Alive(CFocus[I]) Then WinConsoleGetFocus := ERROR_BUSY
  Else
  Begin
    CFocus[I] := MyPid;
    WinConsoleGetFocus := NO_ERROR;
  End;
End;

Function WinConsoleFreeFocus(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleFreeFocus := ERROR_INVALID_HANDLE
  Else If (CFocus[I] <> 0) And (CFocus[I] <> MyPid) And Alive(CFocus[I]) Then WinConsoleFreeFocus := ERROR_BUSY
  Else
  Begin
    CFocus[I] := 0;
    WinConsoleFreeFocus := NO_ERROR;
  End;
End;

Function WinConsoleReadKeyEvent(Hcon, PKey, Wait : LongInt) : LongInt;
Var I, K, T0, V : LongInt;
Begin
  WinConsoleReadKeyEvent := ERROR_INVALID_HANDLE;
  I := ConIdx(Hcon);
  If I < 0 Then Exit;
  If PKey = 0 Then
  Begin
    WinConsoleReadKeyEvent := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  If (CFocus[I] <> 0) And (CFocus[I] <> MyPid) And Alive(CFocus[I]) Then
  Begin
    WinConsoleReadKeyEvent := ERROR_BUSY;
    Exit;
  End;
  T0 := KGetTickCount;
  While (CKH[I] = CKT[I]) And (Wait <> 0) And (CUse[I] <> 0) And (KGetTickCount - T0 < 30000) Do
    Dummy := DosSleep(20);
  If CUse[I] = 0 Then Exit;
  If CKH[I] = CKT[I] Then
  Begin
    If Wait <> 0 Then WinConsoleReadKeyEvent := ERROR_TIMEOUT Else WinConsoleReadKeyEvent := ERROR_NO_DATA;
    Exit;
  End;
  K := I * 32 + CKT[I];
  V := CKV[K];
  WrB(PKey, V And 255); WrB(PKey + 1, (V Shr 8) And 255); WrB(PKey + 2, $40); WrB(PKey + 3, 0);
  WrW(PKey + 4, CKX[K] And $FFFF); WrL(PKey + 6, CKTm[K]);
  CKT[I] := (CKT[I] + 1) And 31;
  WinConsoleReadKeyEvent := NO_ERROR;
End;

Function WinConsoleFlushKeyEvents(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleFlushKeyEvents := ERROR_INVALID_HANDLE
  Else
  Begin
    CKT[I] := CKH[I];
    WinConsoleFlushKeyEvents := NO_ERROR;
  End;
End;

Function WinConsoleQueuedPointerEvents(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleQueuedPointerEvents := 0
  Else WinConsoleQueuedPointerEvents := (CPH[I] - CPT[I]) And 31;
End;

{ MOUEVENTINFO : fs (2), time (4), row (2), col (2) }
Function WinConsoleReadPointerEvent(Hcon, PEv, Wait : LongInt) : LongInt;
Var I, K, T0 : LongInt;
Begin
  WinConsoleReadPointerEvent := ERROR_INVALID_HANDLE;
  I := ConIdx(Hcon);
  If I < 0 Then Exit;
  If PEv = 0 Then
  Begin
    WinConsoleReadPointerEvent := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  T0 := KGetTickCount;
  While (CPH[I] = CPT[I]) And (Wait <> 0) And (CUse[I] <> 0) And (KGetTickCount - T0 < 30000) Do
    Dummy := DosSleep(20);
  If CUse[I] = 0 Then Exit;
  If CPH[I] = CPT[I] Then
  Begin
    If Wait <> 0 Then WinConsoleReadPointerEvent := ERROR_TIMEOUT Else WinConsoleReadPointerEvent := ERROR_NO_DATA;
    Exit;
  End;
  K := I * 32 + CPT[I];
  WrW(PEv, CPF[K]); WrL(PEv + 2, CPTm[K]); WrW(PEv + 6, CPR[K]); WrW(PEv + 8, CPC[K]);
  CPT[I] := (CPT[I] + 1) And 31;
  WinConsoleReadPointerEvent := NO_ERROR;
End;

Function WinConsoleFlushPointerEvents(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleFlushPointerEvents := ERROR_INVALID_HANDLE
  Else
  Begin
    CPT[I] := CPH[I];
    WinConsoleFlushPointerEvents := NO_ERROR;
  End;
End;

Function WinConsoleGetPointerFilterMask(Hcon, PFl : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleGetPointerFilterMask := ERROR_INVALID_HANDLE
  Else If PFl = 0 Then WinConsoleGetPointerFilterMask := ERROR_INVALID_PARAMETER
  Else
  Begin
    WrL(PFl, CFilter[I]);
    WinConsoleGetPointerFilterMask := NO_ERROR;
  End;
End;

Function WinConsoleSetPointerFilterMask(Hcon, Fl : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleSetPointerFilterMask := ERROR_INVALID_HANDLE
  Else
  Begin
    CFilter[I] := Fl And $7F;
    WinConsoleSetPointerFilterMask := NO_ERROR;
  End;
End;

{ position du pointeur en cellules : ligne (2), colonne (2) }
Function WinConsoleGetPtrPos(Hcon, PPos : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleGetPtrPos := ERROR_INVALID_HANDLE
  Else If PPos = 0 Then WinConsoleGetPtrPos := ERROR_INVALID_PARAMETER
  Else
  Begin
    WrW(PPos, CPtrR[I]); WrW(PPos + 2, CPtrC[I]);
    WinConsoleGetPtrPos := NO_ERROR;
  End;
End;

Function WinConsoleSetPtrPos(Hcon, PPos : LongInt) : LongInt;
Var I, R, C : LongInt;
Begin
  WinConsoleSetPtrPos := ERROR_INVALID_HANDLE;
  I := ConIdx(Hcon);
  If I < 0 Then Exit;
  If PPos = 0 Then
  Begin
    WinConsoleSetPtrPos := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  R := RdW(PPos); C := RdW(PPos + 2);
  If (R >= CRows[I]) Or (C >= CCols[I]) Then
  Begin
    WinConsoleSetPtrPos := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  CPtrR[I] := R; CPtrC[I] := C;
  WinConsoleSetPtrPos := NO_ERROR;
End;

{ abandon : fin des programmes de la session, console detruite }
Function WinShieldAbort(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    WinShieldAbort := ERROR_INVALID_HANDLE;
    Exit;
  End;
  CloseCon(I, False);
  WinShieldAbort := NO_ERROR;
End;

Function LockVioPS(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then LockVioPS := ERROR_INVALID_HANDLE
  Else
  Begin
    Inc(CLock[I]);
    LockVioPS := NO_ERROR;
  End;
End;

Function UnlockVioPS(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    UnlockVioPS := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If CLock[I] > 0 Then Dec(CLock[I]);
  If (CLock[I] = 0) And (CClient[I] <> 0) Then
  Begin
    CFull[I] := 1;
    Dummy := WinInvalidateRect(CClient[I], 0, 0);
  End;
  UnlockVioPS := NO_ERROR;
End;

{ procedure par defaut des fenetres AVIO : celles de PMVIOP sont des
  consoles, les autres vont a WinDefWindowProc }
Function WinDefAVioWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  If ConOfClient(H) >= 0 Then WinDefAVioWindowProc := VioShieldWindowProc(H, Msg, Mp1, Mp2)
  Else WinDefAVioWindowProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

Function WinConsoleGetKbdHandle(Hcon, PHkbd : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleGetKbdHandle := ERROR_INVALID_HANDLE
  Else If PHkbd = 0 Then WinConsoleGetKbdHandle := ERROR_INVALID_PARAMETER
  Else
  Begin
    WrL(PHkbd, $4B00 + I);
    WinConsoleGetKbdHandle := NO_ERROR;
  End;
End;

Function WinConsoleAttachMouseUser(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleAttachMouseUser := ERROR_INVALID_HANDLE
  Else
  Begin
    Inc(CMou[I]);
    WinConsoleAttachMouseUser := NO_ERROR;
  End;
End;

Function WinConsoleDetachMouseUser(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then WinConsoleDetachMouseUser := ERROR_INVALID_HANDLE
  Else
  Begin
    If CMou[I] > 0 Then Dec(CMou[I]);
    If CMou[I] = 0 Then CPT[I] := CPH[I];
    WinConsoleDetachMouseUser := NO_ERROR;
  End;
End;

{ sous-classe de la liste des taches : commande 1F00h + rang = montrer la
  console }
Function TaskMgrSubClassProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I : LongInt;
Begin
  If (Msg = WM_COMMAND) And (Lo16(Mp1) >= $1F00) And (Lo16(Mp1) < $1F00 + MaxCon) Then
  Begin
    I := Lo16(Mp1) - $1F00;
    If CUse[I] <> 0 Then
      Dummy := WinSetWindowPos(CFrame[I], HWND_TOP, 0, 0, 0, 0, SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE Or SWP_RESTORE);
    TaskMgrSubClassProc := 1;
  End
  Else TaskMgrSubClassProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

{ avant le degel : l'ecran est redessine en entier }
Function WinShieldPreThaw(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    WinShieldPreThaw := ERROR_INVALID_HANDLE;
    Exit;
  End;
  CStatus[I] := CStatus[I] And Not CS_FROZEN;
  CFull[I] := 1;
  If CClient[I] <> 0 Then Dummy := WinInvalidateRect(CClient[I], 0, 0);
  WinShieldPreThaw := NO_ERROR;
End;

Function WinInitShield(Hab, Hmq : LongInt) : LongInt;
Begin
  ShieldHab := Hab;
  If Hmq <> 0 Then TaskHmq := Hmq;
  InitClasses(Hab);
  WinInitShield := 1;
End;

{ consoles d'un processus termine (pid, 0 : tous les morts) }
Function Mortician(Pid : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxCon - 1 Do
    If (CUse[I] <> 0) And (((Pid <> 0) And (CPid[I] = Pid)) Or ((Pid = 0) And Not Alive(CPid[I]))) Then
    Begin
      DestroyCon(I);
      Inc(N);
    End;
  Mortician := N;
End;

Function UnlockSemaphores : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxCon - 1 Do
    If (CUse[I] <> 0) And (CLock[I] > 0) Then
    Begin
      CLock[I] := 0;
      CFull[I] := 1;
      Inc(N);
    End;
  UnlockSemaphores := N;
End;

{ tampon de la console vide, marquage et texte colle oublies }
Function ClearData(Hcon : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    ClearData := ERROR_INVALID_HANDLE;
    Exit;
  End;
  For K := 0 To ConCells - 1 Do
    If (K And 1) = 0 Then CBuf[I * ConCells + K] := 32 Else CBuf[I * ConCells + K] := 7;
  CMark[I] := 0; CPLen[I] := 0; CPPos[I] := 0;
  CStatus[I] := CStatus[I] And Not (CS_MARKING Or CS_SELECTED);
  If CClient[I] <> 0 Then Dummy := WinInvalidateRect(CClient[I], 0, 0);
  ClearData := NO_ERROR;
End;

{ description : lignes, colonnes, ligne et colonne du curseur, etat,
  session (-1), cadre, client, page de codes (9 x 4 octets) }
Function QueryConsole(Hcon, PInfo : LongInt) : LongInt;
Var I : LongInt; Inf : Array[0..7] Of LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then QueryConsole := ERROR_INVALID_HANDLE
  Else If PInfo = 0 Then QueryConsole := ERROR_INVALID_PARAMETER
  Else
  Begin
    If (CSess[I] >= 0) And (KSes(18, CSess[I], LongInt(@Inf)) <> 0) Then
    Begin
      CCurR[I] := Inf[1]; CCurC[I] := Inf[2];
    End;
    WrL(PInfo, CRows[I]); WrL(PInfo + 4, CCols[I]); WrL(PInfo + 8, CCurR[I]); WrL(PInfo + 12, CCurC[I]);
    WrL(PInfo + 16, CStatus[I]); WrL(PInfo + 20, CSess[I]); WrL(PInfo + 24, CFrame[I]); WrL(PInfo + 28, CClient[I]);
    WrL(PInfo + 32, CCp[I]);
    QueryConsole := NO_ERROR;
  End;
End;

Function MakeVisible(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    MakeVisible := ERROR_INVALID_HANDLE;
    Exit;
  End;
  Dummy := WinSetWindowPos(CFrame[I], HWND_TOP, 0, 0, 0, 0, SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE Or SWP_RESTORE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, CFrame[I]);
  Dummy := WinSetFocus(HWND_DESKTOP, CClient[I]);
  MakeVisible := NO_ERROR;
End;

{ caractere suivant du texte colle (-1 : aucun) }
Function GetPasteChar(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  GetPasteChar := -1;
  I := ConIdx(Hcon);
  If I < 0 Then Exit;
  If CPPos[I] < CPLen[I] Then
  Begin
    GetPasteChar := CPaste[I * 256 + CPPos[I]];
    Inc(CPPos[I]);
  End;
End;

{ sessions WIN-OS/2 "seamless" : pas de WIN-OS/2 dans OS/2-0 }
Function SeamlessCommonVDM(P1, P2 : LongInt) : LongInt;
Begin
  SeamlessCommonVDM := ERROR_NOT_SUPPORTED;
End;

Function SeamlessControlProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  SeamlessControlProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

{ presse-papiers des VDM : changement note, consoles prevenues }
Function TerminateClipDDE : LongInt;
Begin
  ClipDirty := 0;
  TerminateClipDDE := 1;
End;

Function VDMClipDDENotify(Fmt : LongInt) : LongInt;
Begin
  ClipDirty := Fmt Or 1;
  VDMClipDDENotify := 1;
End;

Function PM32ClipDDENotify(Fmt : LongInt) : LongInt;
Begin
  ClipDirty := Fmt Or 1;
  PM32ClipDDENotify := 1;
End;

{ table des objets "seamless" (fenetre, objet, objet associe) }
Function SeamSlot(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  For I := 15 DownTo 0 Do
    If SeamH[I] = H Then R := I;
  SeamSlot := R;
End;

Function Seamless32RegisterObject(H, Obj : LongInt) : LongInt;
Var I : LongInt;
Begin
  Seamless32RegisterObject := 0;
  If H = 0 Then Exit;
  I := SeamSlot(H);
  If I < 0 Then I := SeamSlot(0);
  If I < 0 Then Exit;
  SeamH[I] := H; SeamObj[I] := Obj;
  Seamless32RegisterObject := I + 1;
End;

Function Seamless32RegisterAssocObj(H, Obj : LongInt) : LongInt;
Var I : LongInt;
Begin
  Seamless32RegisterAssocObj := 0;
  I := SeamSlot(H);
  If (H = 0) Or (I < 0) Then Exit;
  SeamAssoc[I] := Obj;
  Seamless32RegisterAssocObj := 1;
End;

Function Seamless32ActivateWindow(H : LongInt) : LongInt;
Begin
  Seamless32ActivateWindow := 0;
  If (H = 0) Or (SeamSlot(H) < 0) Then Exit;
  Seamless32ActivateWindow := WinSetActiveWindow(HWND_DESKTOP, H);
End;

{ message poste a toutes les consoles ; rend leur nombre }
Function NotifyAllVDMs(Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxCon - 1 Do
    If (CUse[I] <> 0) And (CClient[I] <> 0) Then
      If WinPostMsg(CClient[I], Msg, Mp1, Mp2) <> 0 Then Inc(N);
  NotifyAllVDMs := N;
End;

Function VDMSwapButtonNotify(Swap : LongInt) : LongInt;
Begin
  If Swap <> 0 Then SwapBtn := 1 Else SwapBtn := 0;
  VDMSwapButtonNotify := 1;
End;

{ genre de l'ecran : 3 VGA, 8 VGA avec BIOS VESA (SVGA) }
Function Get32DisplayType : LongInt;
Var Vb : Array[0..31] Of LongInt;
Begin
  Vb[0] := 0;
  If VioQueryVbe(LongInt(@Vb)) <> 0 Then Get32DisplayType := 8 Else Get32DisplayType := 3;
End;

Function VdmRegisterHook(Pfn : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  VdmRegisterHook := 0;
  If Pfn = 0 Then Exit;
  F := -1;
  For I := 7 DownTo 0 Do
    If (HookFn[I] = 0) Or ((HookFn[I] = Pfn) And (HookPid[I] = MyPid)) Then F := I;
  If F < 0 Then Exit;
  HookFn[F] := Pfn; HookPid[F] := MyPid;
  VdmRegisterHook := 1;
End;

Function VdmDeregisterHook(Pfn : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  For I := 0 To 7 Do
    If (HookFn[I] = Pfn) And (Pfn <> 0) Then
    Begin
      HookFn[I] := 0; HookPid[I] := 0;
      R := 1;
    End;
  VdmDeregisterHook := R;
End;

{ --- 101 a 122 : donnees de l'original, rendues par des fonctions --- }
Function ScreenGroupToFPConsole(Sg : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  For I := MaxCon - 1 DownTo 0 Do
    If (CUse[I] <> 0) And (CSess[I] = Sg) Then R := HconBase + I;
  ScreenGroupToFPConsole := R;
End;

Function APFNVDMServ : LongInt;
Begin
  If VdmSvc[0] = 0 Then
  Begin
    VdmSvc[0] := ExpAddr(101); VdmSvc[1] := ExpAddr(105); VdmSvc[2] := ExpAddr(43); VdmSvc[3] := ExpAddr(42);
    VdmSvc[4] := ExpAddr(1); VdmSvc[5] := ExpAddr(2); VdmSvc[6] := ExpAddr(41); VdmSvc[7] := 0;
  End;
  APFNVDMServ := LongInt(@VdmSvc);
End;

{ droits d'acces (modele plat : 3 lecture et ecriture, 0 nul) }
Function GetSelAccess(Sel : LongInt) : LongInt;
Begin
  If Sel = 0 Then GetSelAccess := 0 Else GetSelAccess := 3;
End;

Function NPSZStrings : LongInt;
Begin
  NPSZStrings := LongInt(@Strs);
End;

{ touche envoyee a la console (comme une frappe dans la fenetre) }
Function KeyboardEvent(Hcon, Ch, Scan, State : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    KeyboardEvent := ERROR_INVALID_HANDLE;
    Exit;
  End;
  KeyTo(I, ((Scan And 255) Shl 8) Or (Ch And 255), State);
  KeyboardEvent := NO_ERROR;
End;

Function EstablishKbdEnvironment(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then
  Begin
    EstablishKbdEnvironment := ERROR_INVALID_HANDLE;
    Exit;
  End;
  CKbd[I] := 1;
  EstablishKbdEnvironment := WinConsoleGetFocus(Hcon);
End;

Function HMyModuleHandle : LongInt;
Var H : LongInt;
Begin
  H := 0;
  If DosQueryModuleHandle(Z('PMVIOP'), LongInt(@H)) <> 0 Then H := 0;
  HMyModuleHandle := H;
End;

Function FSeamlessCaptured : LongInt;
Begin
  FSeamlessCaptured := 0;
End;

Function HMQTaskmgr : LongInt;
Begin
  HMQTaskmgr := TaskHmq;
End;

Function PCharXlateTblDefault : LongInt;
Begin
  PCharXlateTblDefault := LongInt(@DefXlt);
End;

Function HAPPSeamlessCommonVDM : LongInt;
Begin
  HAPPSeamlessCommonVDM := 0;
End;

Function HAPPSeamlessCommonVDM31 : LongInt;
Begin
  HAPPSeamlessCommonVDM31 := 0;
End;

Function HAPPSeamlessCommonVDM31Enh : LongInt;
Begin
  HAPPSeamlessCommonVDM31Enh := 0;
End;

Function FKbdHook : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To 7 Do
    If HookFn[I] <> 0 Then Inc(N);
  FKbdHook := N;
End;

Function FMouHook : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxCon - 1 Do
    If (CUse[I] <> 0) And (CMou[I] > 0) Then Inc(N);
  FMouHook := N;
End;

Function SelCommonList : LongInt;
Begin
  SelCommonList := LongInt(@CommonList);
End;

Function usCommonSegSize : LongInt;
Begin
  usCommonSegSize := SizeOf(CommonList);
End;

Function HMODSeamless : LongInt;
Begin
  HMODSeamless := 0;
End;

Function HFrameWindowFromConsole(Hcon : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := ConIdx(Hcon);
  If I < 0 Then HFrameWindowFromConsole := 0 Else HFrameWindowFromConsole := CFrame[I];
End;

Exports
  WinCreateConsole Index 1 Name 'WinCreateConsole',
  WinDestroyConsole Index 2 Name 'WinDestroyConsole',
  WinSyncWithPS Index 3 Name 'WinSyncWithPS',
  WinConsoleOpenKbd Index 4 Name 'WinConsoleOpenKbd',
  WinConsoleCloseKbd Index 5 Name 'WinConsoleCloseKbd',
  WinConsoleSetStatus Index 6 Name 'WinConsoleSetStatus',
  WinConsoleGetStatus Index 7 Name 'WinConsoleGetStatus',
  WinConsoleSetCP Index 8 Name 'WinConsoleSetCP',
  WinConsoleGetCP Index 10 Name 'WinConsoleGetCP',
  WinConsoleKbdXlate Index 11 Name 'WinConsoleKbdXlate',
  WinConsoleSetCustXt Index 12 Name 'WinConsoleSetCustXt',
  WinConsoleGetFocus Index 13 Name 'WinConsoleGetFocus',
  WinConsoleFreeFocus Index 14 Name 'WinConsoleFreeFocus',
  WinConsoleReadKeyEvent Index 15 Name 'WinConsoleReadKeyEvent',
  WinConsoleFlushKeyEvents Index 16 Name 'WinConsoleFlushKeyEvents',
  WinConsoleQueuedPointerEvents Index 17 Name 'WinConsoleQueuedPointerEvents',
  WinConsoleReadPointerEvent Index 18 Name 'WinConsoleReadPointerEvent',
  WinConsoleFlushPointerEvents Index 19 Name 'WinConsoleFlushPointerEvents',
  WinConsoleGetPointerFilterMask Index 20 Name 'WinConsoleGetPointerFilterMask',
  WinConsoleSetPointerFilterMask Index 21 Name 'WinConsoleSetPointerFilterMask',
  WinConsoleGetPtrPos Index 22 Name 'WinConsoleGetPtrPos',
  WinConsoleSetPtrPos Index 23 Name 'WinConsoleSetPtrPos',
  WinShieldAbort Index 24 Name 'WinShieldAbort',
  ShieldFrameProc Index 25 Name 'ShieldFrameProc',
  VioShieldWindowProc Index 26 Name 'VioShieldWindowProc',
  LockVioPS Index 27 Name 'LockVioPS',
  UnlockVioPS Index 28 Name 'UnlockVioPS',
  MarkingWindowProc Index 29 Name 'MarkingWindowProc',
  WinDefAVioWindowProc Index 30 Name 'WinDefAVioWindowProc',
  WinConsoleGetKbdHandle Index 31 Name 'WinConsoleGetKbdHandle',
  WinConsoleAttachMouseUser Index 32 Name 'WinConsoleAttachMouseUser',
  WinConsoleDetachMouseUser Index 33 Name 'WinConsoleDetachMouseUser',
  TaskMgrSubClassProc Index 34 Name 'TaskMgrSubClassProc',
  WinShieldPreThaw Index 35 Name 'WinShieldPreThaw',
  WinInitShield Index 36 Name 'WinInitShield',
  Mortician Index 37 Name 'Mortician',
  UnlockSemaphores Index 39 Name 'UnlockSemaphores',
  ClearData Index 40 Name 'ClearData',
  QueryConsole Index 41 Name 'QueryConsole',
  MakeVisible Index 42 Name 'MakeVisible',
  GetPasteChar Index 43 Name 'GetPasteChar',
  SeamlessCommonVDM Index 44 Name 'SeamlessCommonVDM',
  SeamlessControlProc Index 45 Name 'SeamlessControlProc',
  TerminateClipDDE Index 46 Name 'TerminateClipDDE',
  VDMClipDDENotify Index 47 Name 'VDMClipDDENotify',
  PM32ClipDDENotify Index 49 Name 'PM32ClipDDENotify',
  Seamless32RegisterObject Index 50 Name 'Seamless32RegisterObject',
  Seamless32ActivateWindow Index 51 Name 'Seamless32ActivateWindow',
  NotifyAllVDMs Index 52 Name 'NotifyAllVDMs',
  VDMSwapButtonNotify Index 53 Name 'VDMSwapButtonNotify',
  Get32DisplayType Index 54 Name 'Get32DisplayType',
  Seamless32RegisterAssocObj Index 55 Name 'Seamless32RegisterAssocObj',
  VdmRegisterHook Index 56 Name 'VdmRegisterHook',
  VdmDeregisterHook Index 57 Name 'VdmDeregisterHook',
  ScreenGroupToFPConsole Index 101 Name 'ScreenGroupToFPConsole',
  APFNVDMServ Index 102 Name 'APFNVDMServ',
  GetSelAccess Index 103 Name 'GetSelAccess',
  NPSZStrings Index 104 Name 'NPSZStrings',
  KeyboardEvent Index 105 Name 'KeyboardEvent',
  EstablishKbdEnvironment Index 106 Name 'EstablishKbdEnvironment',
  HMyModuleHandle Index 107 Name 'HMyModuleHandle',
  FSeamlessCaptured Index 108 Name 'FSeamlessCaptured',
  HMQTaskmgr Index 110 Name 'HMQTaskmgr',
  PCharXlateTblDefault Index 111 Name 'PCharXlateTblDefault',
  HAPPSeamlessCommonVDM Index 112 Name 'HAPPSeamlessCommonVDM',
  HAPPSeamlessCommonVDM31 Index 114 Name 'HAPPSeamlessCommonVDM31',
  HAPPSeamlessCommonVDM31Enh Index 116 Name 'HAPPSeamlessCommonVDM31Enh',
  FKbdHook Index 117 Name 'FKbdHook',
  FMouHook Index 118 Name 'FMouHook',
  SelCommonList Index 119 Name 'SelCommonList',
  usCommonSegSize Index 120 Name 'usCommonSegSize',
  HMODSeamless Index 121 Name 'HMODSeamless',
  HFrameWindowFromConsole Index 122 Name 'HFrameWindowFromConsole';

Var
  SK : LongInt;
  S0 : String;

BEGIN
  Creating := -1; ClassesOk := 0; ShieldHab := 0; TaskHmq := 0; SwapBtn := 0; ClipDirty := 0; MenuH := 0;
  For InitI := 0 To MaxCon - 1 Do
  Begin
    CUse[InitI] := 0; CommonList[InitI] := 0;
  End;
  For InitI := 0 To 7 Do
  Begin
    HookFn[InitI] := 0; HookPid[InitI] := 0;
  End;
  For InitI := 0 To 15 Do
  Begin
    SeamH[InitI] := 0; SeamObj[InitI] := 0; SeamAssoc[InitI] := 0;
  End;
  For InitI := 0 To 255 Do DefXlt[InitI] := InitI;
  { services offerts aux VDM (APFNVDMServ) }
  VdmSvc[0] := 0;
  { chaines (NPSZStrings) : classes et titres, ASCIIZ a la suite }
  S0 := 'PMVIOP_SHIELD|PMVIOP_MARKING|Fenetre OS/2|Fenetre DOS||';
  For SK := 1 To Length(S0) Do
    If S0[SK] = '|' Then Strs[SK - 1] := 0 Else Strs[SK - 1] := Ord(S0[SK]);
END.
