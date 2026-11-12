{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMMERGE.DLL de OS/2-0 (Presentation
                Manager fusionne d'OS/2 Warp 4 : fenetres, profils,
                programmes, points d'entree internes).
}

Library PMMERGE;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC PMMERGE.PAS   (produit PMMERGE.DLL)

  PMMERGE.DLL est la bibliotheque d'OS/2 Warp 4 qui reunit PMWIN.DLL,
  PMSHAPI.DLL (profils et liste des programmes) et une partie de
  PMGRE.DLL et de PMVIOP.DLL. Les programmes lies a PMMERGE (ordinaux
  2000 a 10021) y trouvent :

    - les fonctions du gestionnaire de fenetres (Win*, et leurs noms
      Win32* d'OS/2 Warp 4), qui sont celles de PMWIN.DLL : PMMERGE les
      transmet a PMWIN, qui garde l'etat (fenetres, files, ecran) ;
    - les fonctions de la liste des taches et du demarrage des programmes
      (WinAddSwitchEntry, WinQuerySwitchList, WinSwitchToProgram,
      WinStartApp...), transmises a OS2SM.DLL ;
    - les profils (Prf*, Prf32*, WinQueryProfile*, WinWriteProfile*) :
      fichiers INI au format binaire d'OS/2, profil de l'utilisateur
      (OS2.INI) et profil du systeme (OS2SYS.INI) ou fichiers ouverts par
      PrfOpenProfile ;
    - la liste des programmes et des groupes (PrfAddProgram,
      PrfQueryProgramTitles, PrfCreateGroup, WinAddProgram...), gardee
      dans le profil de l'utilisateur ;
    - les fonctions internes de Warp 4 : champ de saisie (Edit*),
      proprietes des fenetres et des classes, curseur DAX, zone de
      travail du bureau, couleurs des controles, tas (WinXX*), memoire
      (SS*), semaphores en memoire (RamSem*), entrees du moteur graphique
      (Gre*, Dispatch*, PFN*, mode 16 bits) ; voir les limites plus bas.

  Profils : HINI_PROFILE (0 : utilisateur puis systeme), HINI_USERPROFILE
  (-1, OS2.INI), HINI_SYSTEMPROFILE (-2, OS2SYS.INI) ; noms des fichiers
  pris dans USER_INI et SYSTEM_INI (CONFIG.SYS : SET USER_INI=...), par
  defaut C:\OS2.INI et C:\OS2SYS.INI ; PrfOpenProfile rend un HINI
  494E00xxh. Format des fichiers (celui d'OS/2) :
    en-tete     FFFFFFFFh, position de la premiere application, taille du
                fichier, 0, 0                                    20 octets
    application suivante, premiere cle, 0, longueur du nom (2 fois, nul
                compris), position du nom                         20 octets
    cle         suivante, 0, longueur du nom (2 fois), position du nom,
                longueur des donnees (2 fois), position des donnees
                                                                  24 octets
  Les noms d'applications et de cles distinguent les majuscules. Un
  profil est ecrit sur le disque a chaque modification (PrfChangeWriteThru
  et PrfSuspendWriteToDisk le retardent ; PrfWriteToDisk, PrfCloseProfile
  et ShpPIShutdown l'ecrivent).

  Liste des programmes : application PM_Programs du profil (cle P + handle
  en hexadecimal : groupe, PROGTYPE, SWP, titre, programme, parametres,
  repertoire, icone, environnement) et PM_Groups (cle G + handle :
  visibilite, titre) ; SGH_ROOT (-1) designe la racine (les groupes).
  PROGDETAILS : Length, progc, fbVisible, pszTitle, pszExecutable,
  pszParameters, pszStartupDir, pszIcon, pszEnvironment, swpInitial
  (72 octets) ; PROGTITLE : hprog, progc, fbVisible, pszTitle (16 octets).

  Convention _System : valeurs de 32 bits, pointeurs lineaires.

  Limites : OS/2-0 n'a pas de code 16 bits ni de moteur graphique PMGRE
  separe (le dessin est dans PMWIN.DLL et PMGPI.DLL) : les points
  d'entree Gre*, Dispatch16Gate*, PFN*R2, *_Call_16 et GRE16* rendent 0
  (fonction inconnue) ; les fonctions Edit* agissent sur un champ de
  saisie de PMWIN designe par son HWND (au lieu des donnees internes du
  champ) ; GetIconWindows* ne lit pas les icones de Windows ; les entrees
  de donnees de Warp 4 (ShellWindow, PMSemaphores, PHandleTable,
  PSharedHeap, GreMemptrs, FPen, VPAULDefaultColors) sont des fonctions
  qui rendent l'adresse de la donnee. Les codes PMERR_* sont ceux de
  PMWIN.DLL (approches pour les profils).
}

Const
  HINI_PROFILE = 0;
  HINI_USERPROFILE = -1;
  HINI_SYSTEMPROFILE = -2;
  SGH_ROOT = -1;
  HiniBase = $494E0001;
  MaxPf = 16;
  MaxProp = 256;
  MaxDrv = 64;
  MaxCb = 16;
  MaxClipV = 16;
  ArenaSize = 524288;

  PMERR_INVALID_PARM = $1303;
  PMERR_INVALID_INI_FILE_HANDLE = $1104;
  PMERR_INI_FILE_NOT_FOUND = $1112;
  PMERR_NOT_IN_IDX = $1106;
  PMERR_INVALID_HPROGRAM = $1118;
  PMERR_INSUFFICIENT_MEMORY = $1209;
  PMERR_INVALID_FUNCTION = $1001;

  WM_CHAR = $007A;
  WM_CONTROL = $0030;
  WM_SETWINDOWPARAMS = $000B;
  WM_SYSCOMMAND = $0021;
  EM_QUERYSEL = $0141; EM_SETSEL = $0142; EM_SETTEXTLIMIT = $0143; EM_CUT = $0144;
  EM_COPY = $0145; EM_CLEAR = $0146; EM_PASTE = $0147; EM_QUERYFIRSTCHAR = $0148;
  EM_SETFIRSTCHAR = $0149; EM_QUERYCHANGED = $0140; EM_SETINSERTMODE = $014C;
  KC_CHAR = 1; KC_VIRTUALKEY = 2;
  VK_BACKSPACE = 5;
  QWL_STYLE = -2;
  ES_UNREADABLE = $80;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

{ --- services des autres DLL --- }
Function DcOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS' Name 'DosOpen';
Function DcClose(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosClose';
Function DcRead(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRead';
Function DcWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosWrite';
Function DcSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSetFilePtr';
Function DcScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS' Name 'DosScanEnv';
Function DcAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS' Name 'DosAllocMem';
Function DcFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosFreeMem';
Function DcRequestMutexSem(H, T : LongInt) : LongInt; External 'DOSCALLS' Name 'DosRequestMutexSem';
Function DcReleaseMutexSem(H : LongInt) : LongInt; External 'DOSCALLS' Name 'DosReleaseMutexSem';
Function DcExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS' Name 'DosExecPgm';
Function DcSleep(Ms : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSleep';
Function DcLoadModule(PObj, CbObj, PName, PHmod : LongInt) : LongInt; External 'DOSCALLS' Name 'DosLoadModule';
Function DcQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryProcAddr';
Function DcQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryPathInfo';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KGetTickCount : LongInt; External 'DOSCALLS' Name 'GetTickCount';

Var
  { profils : 0 utilisateur, 1 systeme, 2... ouverts par PrfOpenProfile }
  PfUse, PfBuf, PfLen, PfCap, PfDirty, PfThru, PfSusp, PfRef, PfLoaded : Array[0..MaxPf - 1] Of LongInt;
  PfName : Array[0..MaxPf * 128 - 1] Of Byte;
  PfInitDone, PrgLock, IniLock : LongInt;
  { proprietes des fenetres (PrWin <> 0) et des classes (PrCls <> '') }
  PrUse, PrWin, PrVal : Array[0..MaxProp - 1] Of LongInt;
  PrName, PrCls : Array[0..MaxProp * 32 - 1] Of Byte;
  { informations des pilotes, AFC, pointeurs du systeme }
  DvKey, DvIdx, DvVal : Array[0..MaxDrv - 1] Of LongInt;
  SysPtrData : Array[0..63] Of LongInt;
  { procedures enregistrees (PMExecRegister, WinCplRegister...) }
  CbUse, CbKind, CbProc : Array[0..MaxCb - 1] Of LongInt;
  { visualiseurs du presse-papiers }
  ClipV : Array[0..MaxClipV - 1] Of LongInt;
  { etat divers }
  PalMode, WorkX1, WorkY1, WorkX2, WorkY2, WorkSet, ClipX1, ClipY1, ClipX2, ClipY2, ClipSet : LongInt;
  LangInfo, LangViewer, KbdLayer, QimInfo, DaxData, DaxDefProc, FileExtOpts, CaretBlink : LongInt;
  CaretWin, CaretSave : LongInt;
  GreLastFn, HeapFlags : LongInt;
  DataShellWindow, DataPMSem, DataHandleTable, DataSharedHeap, DataGreMem, DataFPen : LongInt;
  DataColors : Array[0..31] Of LongInt;
  PmgpiMod : LongInt;
  { memoire partagee entre les processus (profils, tas WinXX) }
  Arena : Array[0..ArenaSize - 1] Of Byte;
  NameZ, NameZ2 : Array[0..259] Of Byte;
  Dummy : LongInt;
  XhUse, XhBase, XhSize, XhFlags : Array[0..15] Of LongInt;
  QmBuf : Array[0..7] Of LongInt;


{ --- relais : fonctions de PMWIN.DLL, OS2SM.DLL et PMGPI.DLL --- }
Function X_AAB32GETREG(N : LongInt) : LongInt; External 'PMWIN' Name 'AAB32GETREG';
Function X_AAB32SETREG(N, V : LongInt) : LongInt; External 'PMWIN' Name 'AAB32SETREG';
Function X_AabGetReg(N : LongInt) : LongInt; External 'PMWIN' Name 'AabGetReg';
Function X_AabSetReg(N, V : LongInt) : LongInt; External 'PMWIN' Name 'AabSetReg';
Function X_AbnormalProcessExit(Pid : LongInt) : LongInt; External 'PMWIN' Name 'AbnormalProcessExit';
Function X_DEBUG32CLS : LongInt; External 'PMWIN' Name 'DEBUG32CLS';
Function X_DEBUG32CURPOS(Row, Col : LongInt) : LongInt; External 'PMWIN' Name 'DEBUG32CURPOS';
Function X_DEBUG32INPUT : LongInt; External 'PMWIN' Name 'DEBUG32INPUT';
Function X_DEBUG32OUTPUT(P : LongInt) : LongInt; External 'PMWIN' Name 'DEBUG32OUTPUT';
Function X_DebugCls : LongInt; External 'PMWIN' Name 'DebugCls';
Function X_DebugCurPos(Row, Col : LongInt) : LongInt; External 'PMWIN' Name 'DebugCurPos';
Function X_DebugInput : LongInt; External 'PMWIN' Name 'DebugInput';
Function X_DebugInputEnable(F : LongInt) : LongInt; External 'PMWIN' Name 'DebugInputEnable';
Function X_DebugOutput(P : LongInt) : LongInt; External 'PMWIN' Name 'DebugOutput';
Function X_DebugRedirect(F : LongInt) : LongInt; External 'PMWIN' Name 'DebugRedirect';
Function X_DestroyTimers(Hab : LongInt) : LongInt; External 'PMWIN' Name 'DestroyTimers';
Function X_DummyHelpEntry : LongInt; External 'PMWIN' Name 'DummyHelpEntry';
Function X_FarCallHook(Pfn, A1, A2, A3 : LongInt) : LongInt; External 'PMWIN' Name 'FarCallHook';
Function X_FNBADAPPDLGPROC(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'OS2SM' Name 'FNBADAPPDLGPROC';
Function X_FsrSemCheck : LongInt; External 'PMWIN' Name 'FsrSemCheck';
Function X_FsrSemEnter : LongInt; External 'PMWIN' Name 'FsrSemEnter';
Function X_FsrSemExit : LongInt; External 'PMWIN' Name 'FsrSemExit';
Function X_FsrSemLeave : LongInt; External 'PMWIN' Name 'FsrSemLeave';
Function X_GetPMDDCodeSelector : LongInt; External 'PMWIN' Name 'GetPMDDCodeSelector';
Function X_GetScreenSelector : LongInt; External 'PMWIN' Name 'GetScreenSelector';
Function X_GpiLoadBitmap(Hps, Hmod, Id, Cx, Cy : LongInt) : LongInt; External 'PMWIN' Name 'GpiLoadBitmap';
Function X_IdentifyCodeSelector(Sel : LongInt) : LongInt; External 'PMWIN' Name 'IdentifyCodeSelector';
Function X_InputGetDeviceInfo(N, P : LongInt) : LongInt; External 'PMWIN' Name 'InputGetDeviceInfo';
Function X_KbdPacket(Ch, Sc, St : LongInt) : LongInt; External 'PMWIN' Name 'KbdPacket';
Function X_LoadModuleHandle(P : LongInt) : LongInt; External 'PMWIN' Name 'LoadModuleHandle';
Function X_LPFNICONWNDPROC(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'OS2SM' Name 'LPFNICONWNDPROC';
Function X_LPFNSHELLWNDPROC(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'OS2SM' Name 'LPFNSHELLWNDPROC';
Function X_OldWinQueryPointerInfo(H, P : LongInt) : LongInt; External 'PMWIN' Name 'OldWinQueryPointerInfo';
Function X_SHEINITIALIZEINIFILE(PIni : LongInt) : LongInt; External 'OS2SM' Name 'SHEINITIALIZEINIFILE';
Function X_SHESTARTLONGPROGRAM(PProg, PParams, PTitle, Bg, PSid : LongInt) : LongInt; External 'OS2SM' Name 'SHESTARTLONGPROGRAM';
Function X_SHESYSTEMSHUTDOWN(Fl : LongInt) : LongInt; External 'OS2SM' Name 'SHESYSTEMSHUTDOWN';
Function X_SHLLOADPUBLICFONTS(PIni : LongInt) : LongInt; External 'OS2SM' Name 'SHLLOADPUBLICFONTS';
Function X_SHLUNLOADPUBLICFONTS : LongInt; External 'OS2SM' Name 'SHLUNLOADPUBLICFONTS';
Function X_STARTSYSTEMEXECUTABLES(PIni : LongInt) : LongInt; External 'OS2SM' Name 'STARTSYSTEMEXECUTABLES';
Function X_StartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN' Name 'StartTimer';
Function X_ValidateSelector(Sel : LongInt) : LongInt; External 'PMWIN' Name 'ValidateSelector';
Function X_WIN32DEBUGBREAK : LongInt; External 'PMWIN' Name 'WIN32DEBUGBREAK';
Function X_WinAddAtom(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinAddAtom';
Function X_WINADDSWITCHENTRY(P : LongInt) : LongInt; External 'OS2SM' Name 'WINADDSWITCHENTRY';
Function X_WinAlarm(HDesk, Typ : LongInt) : LongInt; External 'PMWIN' Name 'WinAlarm';
Function X_WinAllocFarMem(H, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinAllocFarMem';
Function X_WinAllocMem(H, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinAllocMem';
Function X_WinAssociateHelpInstance(HHelp, HApp : LongInt) : LongInt; External 'PMWIN' Name 'WinAssociateHelpInstance';
Function X_WinAvailMem(H, FCompact, CbMin : LongInt) : LongInt; External 'PMWIN' Name 'WinAvailMem';
Function X_WinBeginEnumWindows(H : LongInt) : LongInt; External 'PMWIN' Name 'WinBeginEnumWindows';
Function X_WinBeginPaint(H, Hps, PRcl : LongInt) : LongInt; External 'PMWIN' Name 'WinBeginPaint';
Function X_WinBroadcastMsg(HPar, Msg, Mp1, Mp2, Rgf : LongInt) : LongInt; External 'PMWIN' Name 'WinBroadcastMsg';
Function X_WinBuildPtrHandle(P : LongInt) : LongInt; External 'PMWIN' Name 'WinBuildPtrHandle';
Function X_WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN' Name 'WinCalcFrameRect';
Function X_WinCallHelpHook(Hab, Mode, Topic, Sub, PRc : LongInt) : LongInt; External 'PMWIN' Name 'WinCallHelpHook';
Function X_WinCallMsgFilter(Hab, P, Msgf : LongInt) : LongInt; External 'PMWIN' Name 'WinCallMsgFilter';
Function X_WinCancelMode(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinCancelMode';
Function X_WinCancelShutdown(Hmq, FAlways : LongInt) : LongInt; External 'PMWIN' Name 'WinCancelShutdown';
Function X_WinCatch(P : LongInt) : LongInt; External 'PMWIN' Name 'WinCatch';
Function X_WINCHANGESWITCHENTRY(H, P : LongInt) : LongInt; External 'OS2SM' Name 'WINCHANGESWITCHENTRY';
Function X_WinCheckInput(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinCheckInput';
Function X_WinCloseClipbrd(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinCloseClipbrd';
Function X_WinCompareStrings(Hab, Cp, Cc, P1, P2, Rsvd : LongInt) : LongInt; External 'PMWIN' Name 'WinCompareStrings';
Function X_WinCopyAccelTable(H, P, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinCopyAccelTable';
Function X_WinCopyRect(Hab, PD, PS : LongInt) : LongInt; External 'PMWIN' Name 'WinCopyRect';
Function X_WINCPLREGISTER(PName : LongInt) : LongInt; External 'OS2SM' Name 'WINCPLREGISTER';
Function X_WinCpTranslateChar(Hab, CpS, C, CpD : LongInt) : LongInt; External 'PMWIN' Name 'WinCpTranslateChar';
Function X_WinCpTranslateString(Hab, CpS, PSrc, CpD, Cch, PDst : LongInt) : LongInt; External 'PMWIN' Name 'WinCpTranslateString';
Function X_WinCreateAccelTable(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateAccelTable';
Function X_WinCreateAtomTable(CbInit, CBuckets : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateAtomTable';
Function X_WinCreateCursor(H, X, Y, Cx, Cy, Fs, PClip : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateCursor';
Function X_WinCreateDlg(HPar, HOwn, Proc, T, PCreate : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateDlg';
Function X_WinCreateFarHeap(Hab, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateFarHeap';
Function X_WinCreateFrameControls(H, P, PTitle : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateFrameControls';
Function X_WinCreateHeap(Sel, Cb, Grow, MinD, MaxD, Opt : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateHeap';
Function X_WinCreateHelpInstance(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateHelpInstance';
Function X_WinCreateHelpTable(HHelp, P : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateHelpTable';
Function X_WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateMenu';
Function X_WinCreateMsgQueue(Hab, N : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateMsgQueue';
Function X_WinCreatePointer(HDesk, Hbm, FPtr, HotX, HotY : LongInt) : LongInt; External 'PMWIN' Name 'WinCreatePointer';
Function X_WinCreatePointerIndirect(HDesk, P : LongInt) : LongInt; External 'PMWIN' Name 'WinCreatePointerIndirect';
Function X_WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, IdRes, PClient : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateStdWindow';
Function X_WINCREATESWITCHENTRY(Hab, P : LongInt) : LongInt; External 'OS2SM' Name 'WINCREATESWITCHENTRY';
Function X_WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN' Name 'WinCreateWindow';
Function X_WinDdeInitiate(HClient, PApp, PTopic, PCtx : LongInt) : LongInt; External 'PMWIN' Name 'WinDdeInitiate';
Function X_WinDdePostMsg(HTo, HFrom, Msg, P, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinDdePostMsg';
Function X_WinDdeRespond(HClient, HServer, PApp, PTopic, PCtx : LongInt) : LongInt; External 'PMWIN' Name 'WinDdeRespond';
Function X_WinDebugBreak : LongInt; External 'PMWIN' Name 'WinDebugBreak';
Function X_WinDefDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinDefDlgProc';
Function X_WinDefQueueProc(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinDefQueueProc';
Function X_WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinDefWindowProc';
Function X_WinDeleteAtom(H, A : LongInt) : LongInt; External 'PMWIN' Name 'WinDeleteAtom';
Function X_WinDeleteLibrary(Hab, H : LongInt) : LongInt; External 'PMWIN' Name 'WinDeleteLibrary';
Function X_WinDeleteProcedure(Hab, Pfn : LongInt) : LongInt; External 'PMWIN' Name 'WinDeleteProcedure';
Function X_WinDestoryFarHeap(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestoryFarHeap';
Function X_WinDestroyAccelTable(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyAccelTable';
Function X_WinDestroyAniPointer(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyAniPointer';
Function X_WinDestroyAtomTable(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyAtomTable';
Function X_WinDestroyCursor(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyCursor';
Function X_WinDestroyHeap(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyHeap';
Function X_WinDestroyHelpInstance(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyHelpInstance';
Function X_WinDestroyMsgQueue(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyMsgQueue';
Function X_WinDestroyPointer(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyPointer';
Function X_WinDestroyWindow(H : LongInt) : LongInt; External 'PMWIN' Name 'WinDestroyWindow';
Function X_WinDismissDlg(H, R : LongInt) : LongInt; External 'PMWIN' Name 'WinDismissDlg';
Function X_WinDispatchMsg(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinDispatchMsg';
Function X_WinDlgBox(HPar, HOwn, Proc, Hmod, Id, PCreate : LongInt) : LongInt; External 'PMWIN' Name 'WinDlgBox';
Function X_WinDrawBitmap(Hps, Hbm, PSrc, PDst, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinDrawBitmap';
Function X_WinDrawBorder(Hps, P, Cx, Cy, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinDrawBorder';
Function X_WinDrawPointer(Hps, X, Y, H, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinDrawPointer';
Function X_WinDrawText(Hps, Cch, P, PRcl, Fg, Bg, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinDrawText';
Function X_WinEmptyClipbrd(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinEmptyClipbrd';
Function X_WinEnablePhysInput(HDesk, En : LongInt) : LongInt; External 'PMWIN' Name 'WinEnablePhysInput';
Function X_WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN' Name 'WinEnableWindow';
Function X_WinEnableWindowUpdate(H, En : LongInt) : LongInt; External 'PMWIN' Name 'WinEnableWindowUpdate';
Function X_WinEndEnumWindows(He : LongInt) : LongInt; External 'PMWIN' Name 'WinEndEnumWindows';
Function X_WinEndPaint(Hps : LongInt) : LongInt; External 'PMWIN' Name 'WinEndPaint';
Function X_WINENDPROGRAM(H : LongInt) : LongInt; External 'OS2SM' Name 'WINENDPROGRAM';
Function X_WINENDSESSION(S : LongInt) : LongInt; External 'OS2SM' Name 'WINENDSESSION';
Function X_WINENDWINDOWSESSION(H : LongInt) : LongInt; External 'OS2SM' Name 'WINENDWINDOWSESSION';
Function X_WinEnumClipbrdFmts(Hab, Fmt : LongInt) : LongInt; External 'PMWIN' Name 'WinEnumClipbrdFmts';
Function X_WinEnumDlgItem(HDlg, H, Code : LongInt) : LongInt; External 'PMWIN' Name 'WinEnumDlgItem';
Function X_WinEnumVKeyScanIDs(Hab, Vk, P, N : LongInt) : LongInt; External 'PMWIN' Name 'WinEnumVKeyScanIDs';
Function X_WinEqualRect(Hab, P1, P2 : LongInt) : LongInt; External 'PMWIN' Name 'WinEqualRect';
Function X_WinExcludeUpdateRegion(Hps, H : LongInt) : LongInt; External 'PMWIN' Name 'WinExcludeUpdateRegion';
Function X_WinExplodeWindow(H, PSwp : LongInt) : LongInt; External 'PMWIN' Name 'WinExplodeWindow';
Function X_WinFillRect(Hps, P, Clr : LongInt) : LongInt; External 'PMWIN' Name 'WinFillRect';
Function X_WinFindAtom(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinFindAtom';
Function X_WinFlashWindow(H, FFlash : LongInt) : LongInt; External 'PMWIN' Name 'WinFlashWindow';
Function X_WinFocusChange(HDesk, H, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinFocusChange';
Function X_WinForceMenuRedraw(HMenu : LongInt) : LongInt; External 'PMWIN' Name 'WinForceMenuRedraw';
Function X_WinFormatFrame(H, PFr, PSwp, Max, PCl : LongInt) : LongInt; External 'PMWIN' Name 'WinFormatFrame';
Function X_WinFreeErrorInfo(P : LongInt) : LongInt; External 'PMWIN' Name 'WinFreeErrorInfo';
Function X_WinFreeFarMem(H, P, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinFreeFarMem';
Function X_WinFreeMem(H, P, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinFreeMem';
Function X_WinGetClipPS(H, HClip, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinGetClipPS';
Function X_WinGetCurrentTime(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinGetCurrentTime';
Function X_WinGetDlgMsg(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinGetDlgMsg';
Function X_WinGetErasePS(H : LongInt) : LongInt; External 'PMWIN' Name 'WinGetErasePS';
Function X_WinGetErrorInfo(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinGetErrorInfo';
Function X_WinGetFrameTreePPs(H, Cb, P : LongInt) : LongInt; External 'PMWIN' Name 'WinGetFrameTreePPs';
Function X_WinGetFrameTreePPSize(H : LongInt) : LongInt; External 'PMWIN' Name 'WinGetFrameTreePPSize';
Function X_WinGetKeyState(HDesk, Vk : LongInt) : LongInt; External 'PMWIN' Name 'WinGetKeyState';
Function X_WinGetLastError(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinGetLastError';
Function X_WinGetMaxPosition(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinGetMaxPosition';
Function X_WinGetMinPosition(H, P, PPtl : LongInt) : LongInt; External 'PMWIN' Name 'WinGetMinPosition';
Function X_WinGetMinWindowViewer(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinGetMinWindowViewer';
Function X_WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt; External 'PMWIN' Name 'WinGetMsg';
Function X_WinGetNextWindow(He : LongInt) : LongInt; External 'PMWIN' Name 'WinGetNextWindow';
Function X_WinGetPhysKeyState(HDesk, Sc : LongInt) : LongInt; External 'PMWIN' Name 'WinGetPhysKeyState';
Function X_WinGetPS(H : LongInt) : LongInt; External 'PMWIN' Name 'WinGetPS';
Function X_WinGetScanState(HDesk, Sc : LongInt) : LongInt; External 'PMWIN' Name 'WinGetScanState';
Function X_WinGetScreenPS(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinGetScreenPS';
Function X_WinGetSysBitmap(HDesk, Ibm : LongInt) : LongInt; External 'PMWIN' Name 'WinGetSysBitmap';
Function X_WinInflateRect(Hab, P, Cx, Cy : LongInt) : LongInt; External 'PMWIN' Name 'WinInflateRect';
Function X_WinInitialize(Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinInitialize';
Function X_WinInitializeSystem : LongInt; External 'PMWIN' Name 'WinInitializeSystem';
Function X_WININITSESSION(S, PTitle : LongInt) : LongInt; External 'OS2SM' Name 'WININITSESSION';
Function X_WININITSESSIONMGR(Reserved : LongInt) : LongInt; External 'OS2SM' Name 'WININITSESSIONMGR';
Function X_WININITSWENTRY(P : LongInt) : LongInt; External 'OS2SM' Name 'WININITSWENTRY';
Function X_WinInSendMsg(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinInSendMsg';
Function X_WININSTSTARTAPP(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt; External 'OS2SM' Name 'WININSTSTARTAPP';
Function X_WinIntersectRect(Hab, PD, P1, P2 : LongInt) : LongInt; External 'PMWIN' Name 'WinIntersectRect';
Function X_WinInvalidateRect(H, PRcl, Incl : LongInt) : LongInt; External 'PMWIN' Name 'WinInvalidateRect';
Function X_WinInvalidateRegion(H, Hrgn, Incl : LongInt) : LongInt; External 'PMWIN' Name 'WinInvalidateRegion';
Function X_WinInvertRect(Hps, P : LongInt) : LongInt; External 'PMWIN' Name 'WinInvertRect';
Function X_WinIsChild(H, HPar : LongInt) : LongInt; External 'PMWIN' Name 'WinIsChild';
Function X_WinIsPhysInputEnabled(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinIsPhysInputEnabled';
Function X_WinIsRectEmpty(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinIsRectEmpty';
Function X_WinIsShuttingDown : LongInt; External 'PMWIN' Name 'WinIsShuttingDown';
Function X_WinIsThreadActive(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinIsThreadActive';
Function X_WinIsWindow(Hab, H : LongInt) : LongInt; External 'PMWIN' Name 'WinIsWindow';
Function X_WinIsWindowEnabled(H : LongInt) : LongInt; External 'PMWIN' Name 'WinIsWindowEnabled';
Function X_WinIsWindowShowing(H : LongInt) : LongInt; External 'PMWIN' Name 'WinIsWindowShowing';
Function X_WinIsWindowVisible(H : LongInt) : LongInt; External 'PMWIN' Name 'WinIsWindowVisible';
Function X_WinJiggleMouse : LongInt; External 'PMWIN' Name 'WinJiggleMouse';
Function X_WinLangsupDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinLangsupDlgProc';
Function X_WinLangsupWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinLangsupWindowProc';
Function X_WinLoadAccelTable(Hab, Hmod, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadAccelTable';
Function X_WinLoadAniPointer(Hmod, Id, PRes : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadAniPointer';
Function X_WinLoadCharXlatetbl(Hab, Hmod, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadCharXlatetbl';
Function X_WinLoadDlg(HPar, HOwn, Proc, Hmod, Id, PCreate : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadDlg';
Function X_WinLoadHelpTable(HHelp, Id, Hmod : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadHelpTable';
Function X_WinLoadLibrary(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadLibrary';
Function X_WinLoadMenu(HFrame, Hmod, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadMenu';
Function X_WinLoadMessage(Hab, Hmod, Id, Cch, P : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadMessage';
Function X_WinLoadPointer(HDesk, Hmod, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadPointer';
Function X_WinLoadProcedure(Hab, H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadProcedure';
Function X_WinLoadString(Hab, Hmod, Id, Cch, P : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadString';
Function X_WinLoadStringTable(Hab, Hmod, Id, Cb, P : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadStringTable';
Function X_WinLoadTranslationTable(Hab, Hmod, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadTranslationTable';
Function X_WinLoadVkeyGlyphXlatetbl(Hab, Hmod, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinLoadVkeyGlyphXlatetbl';
Function X_WinLockHeap(H : LongInt) : LongInt; External 'PMWIN' Name 'WinLockHeap';
Function X_WinLockInput(Hmq, Lock : LongInt) : LongInt; External 'PMWIN' Name 'WinLockInput';
Function X_WinLockPointerUpdate(HDesk, Hptr, Interval : LongInt) : LongInt; External 'PMWIN' Name 'WinLockPointerUpdate';
Function X_WinLockStartInput(Hab, Lock : LongInt) : LongInt; External 'PMWIN' Name 'WinLockStartInput';
Function X_WinLockVisRegions(HDesk, Lock : LongInt) : LongInt; External 'PMWIN' Name 'WinLockVisRegions';
Function X_WinLockWindow(H, Lock : LongInt) : LongInt; External 'PMWIN' Name 'WinLockWindow';
Function X_WinLockWindowUpdate(HDesk, HLock : LongInt) : LongInt; External 'PMWIN' Name 'WinLockWindowUpdate';
Function X_WinMakePoints(Hab, P, N : LongInt) : LongInt; External 'PMWIN' Name 'WinMakePoints';
Function X_WinMakeRect(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinMakeRect';
Function X_WinMapDlgPoints(HDlg, P, N, FWin : LongInt) : LongInt; External 'PMWIN' Name 'WinMapDlgPoints';
Function X_WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt; External 'PMWIN' Name 'WinMapWindowPoints';
Function X_WinMenuIndexFromID(HMenu, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinMenuIndexFromID';
Function X_WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinMessageBox';
Function X_WinMoveCursor(H, X, Y : LongInt) : LongInt; External 'PMWIN' Name 'WinMoveCursor';
Function X_WinMsgMuxSemWait(PI, PL, T : LongInt) : LongInt; External 'PMWIN' Name 'WinMsgMuxSemWait';
Function X_WinMsgSemWait(H, T : LongInt) : LongInt; External 'PMWIN' Name 'WinMsgSemWait';
Function X_WinMultWindowFromIDs(HPar, P, IdF, IdL : LongInt) : LongInt; External 'PMWIN' Name 'WinMultWindowFromIDs';
Function X_WinNextChar(Hab, Cp, Cc, P : LongInt) : LongInt; External 'PMWIN' Name 'WinNextChar';
Function X_WINNOSHUTDOWN(Block : LongInt) : LongInt; External 'OS2SM' Name 'WINNOSHUTDOWN';
Function X_WinOffsetRect(Hab, P, Dx, Dy : LongInt) : LongInt; External 'PMWIN' Name 'WinOffsetRect';
Function X_WinOpenClipbrd(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinOpenClipbrd';
Function X_WinOpenWindowDC(H : LongInt) : LongInt; External 'PMWIN' Name 'WinOpenWindowDC';
Function X_WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinPeekMsg';
Function X_WINPMFILEREGISTER(PName : LongInt) : LongInt; External 'OS2SM' Name 'WINPMFILEREGISTER';
Function X_WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinPopupMenu';
Function X_WinPortHoleUtil(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinPortHoleUtil';
Function X_WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinPostMsg';
Function X_WinPostQueueMsg(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinPostQueueMsg';
Function X_WinPrevChar(Hab, Cp, Cc, PStart, P : LongInt) : LongInt; External 'PMWIN' Name 'WinPrevChar';
Function X_WinProcessDlg(H : LongInt) : LongInt; External 'PMWIN' Name 'WinProcessDlg';
Function X_WINPROCESSHOTKEY(Scan, State : LongInt) : LongInt; External 'OS2SM' Name 'WINPROCESSHOTKEY';
Function X_WinProfControl(Fl, P : LongInt) : LongInt; External 'PMWIN' Name 'WinProfControl';
Function X_WinPtInRect(Hab, P, PPt : LongInt) : LongInt; External 'PMWIN' Name 'WinPtInRect';
Function X_WinQueryAccelTable(Hab, HFrame : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryAccelTable';
Function X_WinQueryAccelTableValue(H, Ix, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryAccelTableValue';
Function X_WinQueryActiveWindow(HPar : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryActiveWindow';
Function X_WinQueryAnchorBlock(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryAnchorBlock';
Function X_WinQueryAtomLength(H, A : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryAtomLength';
Function X_WinQueryAtomName(H, A, P, Cch : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryAtomName';
Function X_WinQueryAtomUsage(H, A : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryAtomUsage';
Function X_WinQueryCapture(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryCapture';
Function X_WinQueryCharXlatetbl(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryCharXlatetbl';
Function X_WinQueryClassInfo(Hab, PName, PInfo : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryClassInfo';
Function X_WinQueryClassName(H, Cch, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryClassName';
Function X_WinQueryClassThunkProc(PCls : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryClassThunkProc';
Function X_WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryClipbrdData';
Function X_WinQueryClipbrdFmtInfo(Hab, Fmt, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryClipbrdFmtInfo';
Function X_WinQueryClipbrdOwner(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryClipbrdOwner';
Function X_WinQueryClipbrdViewer(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryClipbrdViewer';
Function X_WinQueryCp(Hmq : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryCp';
Function X_WinQueryCpList(Hab, N, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryCpList';
Function X_WinQueryCursorInfo(HDesk, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryCursorInfo';
Function X_WinQueryDesktopBkgnd(HDesk, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryDesktopBkgnd';
Function X_WinQueryDesktopWindow(Hab, Hdc : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryDesktopWindow';
Function X_WinQueryDlgItemShort(HDlg, Id, P, FSigned : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryDlgItemShort';
Function X_WinQueryDlgItemText(HDlg, Id, Cch, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryDlgItemText';
Function X_WinQueryDlgItemTextLength(HDlg, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryDlgItemTextLength';
Function X_WINQUERYEXTIDFOCUS(PId : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYEXTIDFOCUS';
Function X_WinQueryFocus(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryFocus';
Function X_WinQueryHelpInstance(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryHelpInstance';
Function X_WinQueryHungProcess(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryHungProcess';
Function X_WinQueryKbdLayout(HDesk, P, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryKbdLayout';
Function X_WinQueryMenuData(HMenu, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryMenuData';
Function X_WinQueryMsgPos(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryMsgPos';
Function X_WinQueryMsgTime(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryMsgTime';
Function X_WinQueryObjectWindow(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryObjectWindow';
Function X_WinQueryPointer(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryPointer';
Function X_WinQueryPointerInfo(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryPointerInfo';
Function X_WinQueryPointerPos(HDesk, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryPointerPos';
Function X_WinQueryPresParam(H, Id1, Id2, PId, Cb, P, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryPresParam';
Function X_WinQueryProcessCP(Hmq : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryProcessCP';
Function X_WinQueryPwnd(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryPwnd';
Function X_WinQueryQueueInfo(Hmq, P, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryQueueInfo';
Function X_WinQueryQueueStatus(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryQueueStatus';
Function X_WinQuerySendMsg(Hab, HmqSender, HmqReceiver, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQuerySendMsg';
Function X_WINQUERYSESSIONTITLE(Hab, S, PTitle, Cb : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYSESSIONTITLE';
Function X_WinQueryState(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryState';
Function X_WINQUERYSWITCHENTRY(H, P : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYSWITCHENTRY';
Function X_WINQUERYSWITCHHANDLE(Hwnd, Pid : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYSWITCHHANDLE';
Function X_WINQUERYSWITCHLIST(Hab, PBlk, Cb : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYSWITCHLIST';
Function X_WinQuerySysColor(HDesk, Clr, Rsvd : LongInt) : LongInt; External 'PMWIN' Name 'WinQuerySysColor';
Function X_WinQuerySysModalWindow(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinQuerySysModalWindow';
Function X_WinQuerySysPointer(HDesk, Iptr, Load : LongInt) : LongInt; External 'PMWIN' Name 'WinQuerySysPointer';
Function X_WinQuerySystemAtomTable : LongInt; External 'PMWIN' Name 'WinQuerySystemAtomTable';
Function X_WinQuerySysValue(HDesk, I : LongInt) : LongInt; External 'PMWIN' Name 'WinQuerySysValue';
Function X_WINQUERYTASKSIZEPOS(Hab, S, P : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYTASKSIZEPOS';
Function X_WINQUERYTASKTITLE(S, PTitle, Cb : LongInt) : LongInt; External 'OS2SM' Name 'WINQUERYTASKTITLE';
Function X_WinQueryUpdateRect(H, PRcl : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryUpdateRect';
Function X_WinQueryUpdateRegion(H, Hrgn : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryUpdateRegion';
Function X_WinQueryVersion(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryVersion';
Function X_WinQueryVkeyGlyphXlatetbl(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryVkeyGlyphXlatetbl';
Function X_WinQueryWindow(H, Cmd : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindow';
Function X_WinQueryWindowDC(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowDC';
Function X_WinQueryWindowLockCount(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowLockCount';
Function X_WinQueryWindowModel(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowModel';
Function X_WinQueryWindowPos(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowPos';
Function X_WinQueryWindowProcess(H, PPid, PTid : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowProcess';
Function X_WinQueryWindowPtr(H, Index : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowPtr';
Function X_WinQueryWindowRect(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowRect';
Function X_WinQueryWindowSGId(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowSGId';
Function X_WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowText';
Function X_WinQueryWindowTextLength(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowTextLength';
Function X_WinQueryWindowThunkProc(H : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowThunkProc';
Function X_WinQueryWindowULong(H, Index : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowULong';
Function X_WinQueryWindowUShort(H, Index : LongInt) : LongInt; External 'PMWIN' Name 'WinQueryWindowUShort';
Function X_WinQueueFromId(Hab, Pid, Tid : LongInt) : LongInt; External 'PMWIN' Name 'WinQueueFromId';
Function X_WinRealizePalette(H, Hps, P : LongInt) : LongInt; External 'PMWIN' Name 'WinRealizePalette';
Function X_WinReallocFarMem(H, P, CbOld, CbNew : LongInt) : LongInt; External 'PMWIN' Name 'WinReallocFarMem';
Function X_WinReallocMem(H, P, CbOld, CbNew : LongInt) : LongInt; External 'PMWIN' Name 'WinReallocMem';
Function X_WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt; External 'PMWIN' Name 'WinRegisterClass';
Function X_WinRegisterSeamlessProc(Pfn : LongInt) : LongInt; External 'PMWIN' Name 'WinRegisterSeamlessProc';
Function X_WinRegisterUserDatatype(Hab, T, N, P : LongInt) : LongInt; External 'PMWIN' Name 'WinRegisterUserDatatype';
Function X_WinRegisterUserMsg(Hab, Msg, T1, D1, T2, D2, Tr : LongInt) : LongInt; External 'PMWIN' Name 'WinRegisterUserMsg';
Function X_WinRegisterWindowDestroy(H, Reg : LongInt) : LongInt; External 'PMWIN' Name 'WinRegisterWindowDestroy';
Function X_WinReleaseErasePS(Hps : LongInt) : LongInt; External 'PMWIN' Name 'WinReleaseErasePS';
Function X_WinReleaseHook(Hab, Hmq, Typ, Pfn, Hmod : LongInt) : LongInt; External 'PMWIN' Name 'WinReleaseHook';
Function X_WinReleasePS(Hps : LongInt) : LongInt; External 'PMWIN' Name 'WinReleasePS';
Function X_WinRemovePresParam(H, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinRemovePresParam';
Function X_WINREMOVESWITCHENTRY(H : LongInt) : LongInt; External 'OS2SM' Name 'WINREMOVESWITCHENTRY';
Function X_WinReplyMsg(Hab, HmqSender, HmqReceiver, Mres : LongInt) : LongInt; External 'PMWIN' Name 'WinReplyMsg';
Function X_WinRequestMutexSem(H, T : LongInt) : LongInt; External 'PMWIN' Name 'WinRequestMutexSem';
Function X_WinResetSystem(HDesk : LongInt) : LongInt; External 'PMWIN' Name 'WinResetSystem';
Function X_WinSaveWindowPos(Hsv, P, N : LongInt) : LongInt; External 'PMWIN' Name 'WinSaveWindowPos';
Function X_WinScreenSwitch(H, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinScreenSwitch';
Function X_WinScrollWindow(H, Dx, Dy, PScroll, PClip, Hrgn, PUpd, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinScrollWindow';
Function X_WinSeamlessBox(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSeamlessBox';
Function X_WinSemEnter : LongInt; External 'PMWIN' Name 'WinSemEnter';
Function X_WinSemLeave : LongInt; External 'PMWIN' Name 'WinSemLeave';
Function X_WinSemQuery : LongInt; External 'PMWIN' Name 'WinSemQuery';
Function X_WinSendDlgItemMsg(HDlg, Id, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinSendDlgItemMsg';
Function X_WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinSendMsg';
Function X_WinSendQueueMsg(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN' Name 'WinSendQueueMsg';
Function X_WinSetAccelTable(Hab, H, HFrame : LongInt) : LongInt; External 'PMWIN' Name 'WinSetAccelTable';
Function X_WinSetAccelTableValue(H, Ix, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetAccelTableValue';
Function X_WinSetActiveWindow(HDesk, H : LongInt) : LongInt; External 'PMWIN' Name 'WinSetActiveWindow';
Function X_WinSetAniPointer(H, FAnimate : LongInt) : LongInt; External 'PMWIN' Name 'WinSetAniPointer';
Function X_WinSetAtomTableOwner(H, Pid : LongInt) : LongInt; External 'PMWIN' Name 'WinSetAtomTableOwner';
Function X_WinSetCapture(HDesk, H : LongInt) : LongInt; External 'PMWIN' Name 'WinSetCapture';
Function X_WinSetCharXlatetbl(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetCharXlatetbl';
Function X_WinSetClassMsgInterest(Hab, PCls, MsgCls, Ctl : LongInt) : LongInt; External 'PMWIN' Name 'WinSetClassMsgInterest';
Function X_WinSetClassThunkProc(PCls, Pfn : LongInt) : LongInt; External 'PMWIN' Name 'WinSetClassThunkProc';
Function X_WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt; External 'PMWIN' Name 'WinSetClipbrdData';
Function X_WinSetClipbrdOwner(Hab, H : LongInt) : LongInt; External 'PMWIN' Name 'WinSetClipbrdOwner';
Function X_WinSetClipbrdViewer(Hab, H : LongInt) : LongInt; External 'PMWIN' Name 'WinSetClipbrdViewer';
Function X_WinSetCp(Hmq, Cp : LongInt) : LongInt; External 'PMWIN' Name 'WinSetCp';
Function X_WinSetDesktopBkgnd(HDesk, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetDesktopBkgnd';
Function X_WinSetDlgItemShort(HDlg, Id, V, FSigned : LongInt) : LongInt; External 'PMWIN' Name 'WinSetDlgItemShort';
Function X_WinSetDlgItemText(HDlg, Id, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetDlgItemText';
Function X_WinSetErrorInfo(E, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinSetErrorInfo';
Function X_WINSETEXTIDFOCUS(Id : LongInt) : LongInt; External 'OS2SM' Name 'WINSETEXTIDFOCUS';
Function X_WINSETFGNDWINDOW(Hwnd : LongInt) : LongInt; External 'OS2SM' Name 'WINSETFGNDWINDOW';
Function X_WinSetFocus(HDesk, H : LongInt) : LongInt; External 'PMWIN' Name 'WinSetFocus';
Function X_WinSetFrameTreePPs(H, Cb, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetFrameTreePPs';
Function X_WinSetHook(Hab, Hmq, Typ, Pfn, Hmod : LongInt) : LongInt; External 'PMWIN' Name 'WinSetHook';
Function X_WinSetKbdLayout(HDesk, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetKbdLayout';
Function X_WinSetKbdLayout2(HDesk, P, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinSetKbdLayout2';
Function X_WinSetKeyboardStateTable(HDesk, P, FSet : LongInt) : LongInt; External 'PMWIN' Name 'WinSetKeyboardStateTable';
Function X_WinSetLastError(Hab, E : LongInt) : LongInt; External 'PMWIN' Name 'WinSetLastError';
Function X_WinSetMenuData(HMenu, Id, Data : LongInt) : LongInt; External 'PMWIN' Name 'WinSetMenuData';
Function X_WinSetMsgInterest(H, MsgCls, Ctl : LongInt) : LongInt; External 'PMWIN' Name 'WinSetMsgInterest';
Function X_WinSetMsgMode(Hab, PCls, Ctl : LongInt) : LongInt; External 'PMWIN' Name 'WinSetMsgMode';
Function X_WinSetMultWindowPos(Hab, P, N : LongInt) : LongInt; External 'PMWIN' Name 'WinSetMultWindowPos';
Function X_WinSetOwner(H, HOwn : LongInt) : LongInt; External 'PMWIN' Name 'WinSetOwner';
Function X_WinSetParent(H, HPar, Redraw : LongInt) : LongInt; External 'PMWIN' Name 'WinSetParent';
Function X_WinSetPointer(HDesk, Hptr : LongInt) : LongInt; External 'PMWIN' Name 'WinSetPointer';
Function X_WinSetPointerOwner(H, Pid, FDestroy : LongInt) : LongInt; External 'PMWIN' Name 'WinSetPointerOwner';
Function X_WinSetPointerPos(HDesk, X, Y : LongInt) : LongInt; External 'PMWIN' Name 'WinSetPointerPos';
Function X_WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetPresParam';
Function X_WinSetQueueProc(Hmq, Pfn : LongInt) : LongInt; External 'PMWIN' Name 'WinSetQueueProc';
Function X_WinSetRect(Hab, P, X1, Y1, X2, Y2 : LongInt) : LongInt; External 'PMWIN' Name 'WinSetRect';
Function X_WinSetRectEmpty(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetRectEmpty';
Function X_WinSetScanStateTable(HDesk, P, FSet : LongInt) : LongInt; External 'PMWIN' Name 'WinSetScanStateTable';
Function X_WINSETSWENTRY(H, P : LongInt) : LongInt; External 'OS2SM' Name 'WINSETSWENTRY';
Function X_WinSetSynchroMode(Hab, Mode : LongInt) : LongInt; External 'PMWIN' Name 'WinSetSynchroMode';
Function X_WinSetSysClipbrdViewer(Hab, H : LongInt) : LongInt; External 'PMWIN' Name 'WinSetSysClipbrdViewer';
Function X_WinSetSysColors(HDesk, Opt, Fmt, First, N, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetSysColors';
Function X_WinSetSysFont(HDesk, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetSysFont';
Function X_WinSetSysModalWindow(HDesk, H : LongInt) : LongInt; External 'PMWIN' Name 'WinSetSysModalWindow';
Function X_WinSetSysValue(HDesk, I, V : LongInt) : LongInt; External 'PMWIN' Name 'WinSetSysValue';
Function X_WINSETTITLE(PTitle : LongInt) : LongInt; External 'OS2SM' Name 'WINSETTITLE';
Function X_WinSetVkeyGlyphXlatetbl(Hab, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetVkeyGlyphXlatetbl';
Function X_WinSetWindowBits(H, Index, Data, Mask : LongInt) : LongInt; External 'PMWIN' Name 'WinSetWindowBits';
Function X_WinSetWindowDC(H, Hdc : LongInt) : LongInt; External 'PMWIN' Name 'WinSetWindowDC';
Function X_WinSetWindowPos(H, HBehind, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMWIN' Name 'WinSetWindowPos';
Function X_WinSetWindowPtr(H, Index, V : LongInt) : LongInt; External 'PMWIN' Name 'WinSetWindowPtr';
Function X_WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinSetWindowText';
Function X_WinSetWindowThunkProc(H, Pfn : LongInt) : LongInt; External 'PMWIN' Name 'WinSetWindowThunkProc';
Function X_WinSetWindowULong(H, Index, V : LongInt) : LongInt; External 'PMWIN' Name 'WinSetWindowULong';
Function X_WinSetWindowUShort(H, Index, V : LongInt) : LongInt; External 'PMWIN' Name 'WinSetWindowUShort';
Function X_WinShowCursor(H, Show : LongInt) : LongInt; External 'PMWIN' Name 'WinShowCursor';
Function X_WinShowPointer(HDesk, Show : LongInt) : LongInt; External 'PMWIN' Name 'WinShowPointer';
Function X_WinShowTrackRect(H, FShow : LongInt) : LongInt; External 'PMWIN' Name 'WinShowTrackRect';
Function X_WinShowWindow(H, Show : LongInt) : LongInt; External 'PMWIN' Name 'WinShowWindow';
Function X_WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN' Name 'WinStartTimer';
Function X_WINSTOPPROGRAM(H : LongInt) : LongInt; External 'OS2SM' Name 'WINSTOPPROGRAM';
Function X_WinStopTimer(Hab, H, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinStopTimer';
Function X_WINSTPREGISTER(Hwnd : LongInt) : LongInt; External 'OS2SM' Name 'WINSTPREGISTER';
Function X_WinStretchPointer(Hps, X, Y, Cx, Cy, H, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinStretchPointer';
Function X_WinSubclassWindow(H, Proc : LongInt) : LongInt; External 'PMWIN' Name 'WinSubclassWindow';
Function X_WinSubstituteStrings(H, PSrc, Cch, PDst : LongInt) : LongInt; External 'PMWIN' Name 'WinSubstituteStrings';
Function X_WinSubtractRect(Hab, PD, P1, P2 : LongInt) : LongInt; External 'PMWIN' Name 'WinSubtractRect';
Function X_WINSWITCHPROGRAMREGISTER(Hwnd : LongInt) : LongInt; External 'OS2SM' Name 'WINSWITCHPROGRAMREGISTER';
Function X_WINSWITCHTOPROGRAM(H : LongInt) : LongInt; External 'OS2SM' Name 'WINSWITCHTOPROGRAM';
Function X_WINSWITCHTOPROGRAM2(H, Fl : LongInt) : LongInt; External 'OS2SM' Name 'WINSWITCHTOPROGRAM2';
Function X_WINSWITCHTOTASKMANAGER : LongInt; External 'OS2SM' Name 'WINSWITCHTOTASKMANAGER';
Function X_WinSyncStartPgm(P : LongInt) : LongInt; External 'PMWIN' Name 'WinSyncStartPgm';
Function X_WinSystemShutdown(Hab, Hmq : LongInt) : LongInt; External 'PMWIN' Name 'WinSystemShutdown';
Function X_WinTerminate(Hab : LongInt) : LongInt; External 'PMWIN' Name 'WinTerminate';
Function X_WINTERMINATEAPP(Happ : LongInt) : LongInt; External 'OS2SM' Name 'WINTERMINATEAPP';
Function X_WinTerminateShutdown : LongInt; External 'PMWIN' Name 'WinTerminateShutdown';
Function X_WinTerminateSystem : LongInt; External 'PMWIN' Name 'WinTerminateSystem';
Function X_WinThreadAssocQueue(Hab, Hmq : LongInt) : LongInt; External 'PMWIN' Name 'WinThreadAssocQueue';
Function X_WinThrow(P, V : LongInt) : LongInt; External 'PMWIN' Name 'WinThrow';
Function X_WinTrackRect(H, Hps, P : LongInt) : LongInt; External 'PMWIN' Name 'WinTrackRect';
Function X_WinTrackSeamless(H, P : LongInt) : LongInt; External 'PMWIN' Name 'WinTrackSeamless';
Function X_WinTranslateAccel(Hab, H, HAcc, P : LongInt) : LongInt; External 'PMWIN' Name 'WinTranslateAccel';
Function X_WinTranslateChar(Hab, Ch : LongInt) : LongInt; External 'PMWIN' Name 'WinTranslateChar';
Function X_WinUnionRect(Hab, PD, P1, P2 : LongInt) : LongInt; External 'PMWIN' Name 'WinUnionRect';
Function X_WinUpdateWindow(H : LongInt) : LongInt; External 'PMWIN' Name 'WinUpdateWindow';
Function X_WinUpper(Hab, Cp, Cc, P : LongInt) : LongInt; External 'PMWIN' Name 'WinUpper';
Function X_WinUpperChar(Hab, Cp, Cc, C : LongInt) : LongInt; External 'PMWIN' Name 'WinUpperChar';
Function X_WinValidateRect(H, PRcl, Incl : LongInt) : LongInt; External 'PMWIN' Name 'WinValidateRect';
Function X_WinValidateRegion(H, Hrgn, Incl : LongInt) : LongInt; External 'PMWIN' Name 'WinValidateRegion';
Function X_WinVisRegionNotify(H, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinVisRegionNotify';
Function X_WinVkeyGlyphCharXlate(Hab, Vk, Fs : LongInt) : LongInt; External 'PMWIN' Name 'WinVkeyGlyphCharXlate';
Function X_WinVkeyToScanId(Hab, Vk : LongInt) : LongInt; External 'PMWIN' Name 'WinVkeyToScanId';
Function X_WinWaitEventSem(H, T : LongInt) : LongInt; External 'PMWIN' Name 'WinWaitEventSem';
Function X_WinWaitMsg(Hab, First, Last : LongInt) : LongInt; External 'PMWIN' Name 'WinWaitMsg';
Function X_WinWaitMuxWaitSem(H, T, PU : LongInt) : LongInt; External 'PMWIN' Name 'WinWaitMuxWaitSem';
Function X_WinWakeThread(Hmq : LongInt) : LongInt; External 'PMWIN' Name 'WinWakeThread';
Function X_WinWindowFromDC(Hdc : LongInt) : LongInt; External 'PMWIN' Name 'WinWindowFromDC';
Function X_WinWindowFromID(HPar, Id : LongInt) : LongInt; External 'PMWIN' Name 'WinWindowFromID';
Function X_WinWindowFromPoint(HPar, PPtl, Children : LongInt) : LongInt; External 'PMWIN' Name 'WinWindowFromPoint';

{ ==================================================================== }
{ Partie 1 - Utilitaires                                               }
{ ==================================================================== }

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  P := Pointer(A);
  P^ := V;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V And 255;
End;

Procedure MemMove(Src, Dst, N : LongInt);
Var K : LongInt;
Begin
  If (N <= 0) Or (Src = Dst) Then Exit;
  If Dst < Src Then
  Begin
    K := 0;
    While K < N Do
    Begin
      WrB(Dst + K, RdB(Src + K));
      Inc(K);
    End;
  End
  Else
  Begin
    K := N - 1;
    While K >= 0 Do
    Begin
      WrB(Dst + K, RdB(Src + K));
      Dec(K);
    End;
  End;
End;

Procedure MemZero(A, N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do WrB(A + K, 0);
End;

{ chaine terminee par un nul (au plus 255 caracteres) }
Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (N < 255) And (RdB(A + N) <> 0) Do
    Begin
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Function LenZ(A : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  If A <> 0 Then
    While RdB(A + N) <> 0 Do Inc(N);
  LenZ := N;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function HexStr(V : LongInt) : String;
Var S : String; K, D : LongInt;
Begin
  S := '';
  For K := 7 DownTo 0 Do
  Begin
    D := (V Shr (K * 4)) And 15;
    If D < 10 Then S := S + Chr(48 + D) Else S := S + Chr(55 + D);
  End;
  HexStr := S;
End;

Function IntStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IntStr := S;
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

Function Alive(Pid : LongInt) : Boolean;
Begin
  Alive := (Pid = 0) Or (Pid = MyPid) Or (KrnMonIo(0, 4, Pid) <> 0);
End;

{ --- tas dans l'arena partagee : bloc = taille (bit 0 : occupe),
  processus, donnees --- }
Procedure HeapInit(Base, Size : LongInt);
Begin
  WrL(Base, Size And Not 7);
  WrL(Base + 4, 0);
End;

Function HeapAlloc(Base, Size, N : LongInt) : LongInt;
Var P, BS, Need, R : LongInt;
Begin
  R := 0;
  Need := ((N + 7) And Not 7) + 8;
  P := 0;
  While (R = 0) And (P < Size) Do
  Begin
    BS := RdL(Base + P) And Not 1;
    If BS <= 0 Then P := Size
    Else
    Begin
      If (RdL(Base + P) And 1) = 0 Then
      Begin
        While (P + BS < Size) And ((RdL(Base + P + BS) And 1) = 0) And (RdL(Base + P + BS) > 0) Do
        Begin
          BS := BS + RdL(Base + P + BS);
          WrL(Base + P, BS);
        End;
        If BS >= Need Then
        Begin
          If BS - Need >= 16 Then
          Begin
            WrL(Base + P + Need, BS - Need);
            BS := Need;
          End;
          WrL(Base + P, BS Or 1);
          WrL(Base + P + 4, MyPid);
          R := Base + P + 8;
          MemZero(R, BS - 8);
        End;
      End;
      P := P + BS;
    End;
  End;
  HeapAlloc := R;
End;

Procedure HeapFree(A : LongInt);
Begin
  If A <> 0 Then WrL(A - 8, RdL(A - 8) And Not 1);
End;

Function HeapSize(A : LongInt) : LongInt;
Begin
  HeapSize := (RdL(A - 8) And Not 1) - 8;
End;

{ plus grand bloc libre }
Function HeapAvail(Base, Size : LongInt) : LongInt;
Var P, BS, M, Run : LongInt;
Begin
  M := 0; P := 0; Run := 0;
  While P < Size Do
  Begin
    BS := RdL(Base + P) And Not 1;
    If BS <= 0 Then P := Size
    Else
    Begin
      If (RdL(Base + P) And 1) = 0 Then Run := Run + BS Else Run := 0;
      If Run - 8 > M Then M := Run - 8;
      P := P + BS;
    End;
  End;
  HeapAvail := M;
End;

Function MemAlloc(N : LongInt) : LongInt;
Begin
  MemAlloc := HeapAlloc(LongInt(@Arena), ArenaSize, N);
End;

Procedure MemFree(A : LongInt);
Begin
  If (A >= LongInt(@Arena) + 8) And (A < LongInt(@Arena) + ArenaSize) Then HeapFree(A);
End;

{ --- appels de procedures (programme OS2PC : convention Pascal) --- }
Function CallSys4(F, A1, A2, A3, A4 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A4
    push eax
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,16
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys4 := R;
End;

Function CallPas4(F, A1, A2, A3, A4 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,A2
    push eax
    mov eax,A3
    push eax
    mov eax,A4
    push eax
    mov eax,F
    call eax
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPas4 := R;
End;

Function Call4(F, A1, A2, A3, A4 : LongInt) : LongInt;
Begin
  If (F >= $00400000) And (F < $00800000) Then Call4 := CallPas4(F, A1, A2, A3, A4)
  Else Call4 := CallSys4(F, A1, A2, A3, A4);
End;

{ point d'entree _System de 6 parametres (fonctions de PMGPI.DLL) }
Function CallSys6(F, A1, A2, A3, A4, A5, A6 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A6
    push eax
    mov eax,A5
    push eax
    mov eax,A4
    push eax
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,24
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys6 := R;
End;

{ point d'entree de PMGPI.DLL (charge a la demande) ; 0 s'il n'y est pas }
Function GpiProc(N : String) : LongInt;
Var A : LongInt;
Begin
  GpiProc := 0;
  If PmgpiMod = 0 Then
  Begin
    PutZ(LongInt(@NameZ2), 'PMGPI');
    If DcLoadModule(0, 0, LongInt(@NameZ2), LongInt(@PmgpiMod)) <> 0 Then PmgpiMod := 0;
  End;
  If PmgpiMod = 0 Then Exit;
  PutZ(LongInt(@NameZ2), N);
  A := 0;
  If DcQueryProcAddr(PmgpiMod, 0, LongInt(@NameZ2), LongInt(@A)) = 0 Then GpiProc := A;
End;


{ ==================================================================== }
{ Partie 2 - Profils (fichiers INI d'OS/2)                             }
{ ==================================================================== }
{ En memoire, un profil est une suite d'enregistrements : longueur du
  nom de l'application (2), nom, longueur du nom de la cle (2), nom,
  longueur des donnees (4), donnees ; les cles d'une application se
  suivent. }

Procedure SetErr(Code : LongInt);
Begin
  Dummy := X_WinSetErrorInfo($40000 Or Code, 0);
End;

Function PfNameGet(K : LongInt) : String;
Begin
  PfNameGet := GetZ(LongInt(@PfName) + K * 128);
End;

{ taille d'un enregistrement a la position Ofs }
Function RecSize(B, Ofs : LongInt) : LongInt;
Var A, K : LongInt;
Begin
  A := RdW(B + Ofs);
  K := RdW(B + Ofs + 2 + A);
  RecSize := 2 + A + 2 + K + 4 + RdL(B + Ofs + 4 + A + K);
End;

Function RecApp(B, Ofs : LongInt) : String;
Var S : String; N, J : LongInt;
Begin
  S := ''; N := RdW(B + Ofs);
  For J := 0 To MinI(N, 255) - 1 Do S := S + Chr(RdB(B + Ofs + 2 + J));
  RecApp := S;
End;

Function RecKey(B, Ofs : LongInt) : String;
Var S : String; N, A, J : LongInt;
Begin
  S := ''; A := RdW(B + Ofs); N := RdW(B + Ofs + 2 + A);
  For J := 0 To MinI(N, 255) - 1 Do S := S + Chr(RdB(B + Ofs + 4 + A + J));
  RecKey := S;
End;

{ donnees : adresse et longueur }
Function RecData(B, Ofs : LongInt; Var N : LongInt) : LongInt;
Var A, K : LongInt;
Begin
  A := RdW(B + Ofs); K := RdW(B + Ofs + 2 + A);
  N := RdL(B + Ofs + 4 + A + K);
  RecData := B + Ofs + 8 + A + K;
End;

{ enregistrement (App, Key) ; -1 s'il n'existe pas ; Last : position
  apres le dernier enregistrement de l'application (-1 : aucune) }
Function PfFind(K : LongInt; App, Key : String; Var Last : LongInt) : LongInt;
Var Ofs, R, B : LongInt; A : String;
Begin
  R := -1; Last := -1; Ofs := 0; B := PfBuf[K];
  While Ofs < PfLen[K] Do
  Begin
    A := RecApp(B, Ofs);
    If A = App Then
    Begin
      If (R < 0) And (RecKey(B, Ofs) = Key) Then R := Ofs;
      Last := Ofs + RecSize(B, Ofs);
    End;
    Ofs := Ofs + RecSize(B, Ofs);
  End;
  PfFind := R;
End;

{ place libre pour N octets de plus }
Function PfGrow(K, N : LongInt) : Boolean;
Var Nc, Nb : LongInt;
Begin
  PfGrow := True;
  If PfLen[K] + N <= PfCap[K] Then Exit;
  Nc := MaxI(PfCap[K] * 2, PfLen[K] + N + 1024);
  Nb := MemAlloc(Nc);
  If Nb = 0 Then
  Begin
    PfGrow := False;
    Exit;
  End;
  If PfBuf[K] <> 0 Then
  Begin
    MemMove(PfBuf[K], Nb, PfLen[K]);
    MemFree(PfBuf[K]);
  End;
  PfBuf[K] := Nb; PfCap[K] := Nc;
End;

Procedure PfDelRec(K, Ofs : LongInt);
Var N : LongInt;
Begin
  N := RecSize(PfBuf[K], Ofs);
  MemMove(PfBuf[K] + Ofs + N, PfBuf[K] + Ofs, PfLen[K] - Ofs - N);
  PfLen[K] := PfLen[K] - N;
End;

{ ecrire (App, Key) = N octets en P }
Function PfSet(K : LongInt; App, Key : String; P, N : LongInt) : Boolean;
Var Ofs, Last, Sz, At, B : LongInt; J : LongInt;
Begin
  PfSet := False;
  Ofs := PfFind(K, App, Key, Last);
  If Ofs >= 0 Then
  Begin
    PfDelRec(K, Ofs);
    Ofs := PfFind(K, App, Key, Last);
  End;
  Sz := 2 + Length(App) + 2 + Length(Key) + 4 + N;
  If Not PfGrow(K, Sz) Then Exit;
  If Last >= 0 Then At := Last Else At := PfLen[K];
  B := PfBuf[K];
  MemMove(B + At, B + At + Sz, PfLen[K] - At);
  WrW(B + At, Length(App));
  For J := 1 To Length(App) Do WrB(B + At + 1 + J, Ord(App[J]));
  WrW(B + At + 2 + Length(App), Length(Key));
  For J := 1 To Length(Key) Do WrB(B + At + 3 + Length(App) + J, Ord(Key[J]));
  WrL(B + At + 4 + Length(App) + Length(Key), N);
  If (N > 0) And (P <> 0) Then MemMove(P, B + At + 8 + Length(App) + Length(Key), N);
  PfLen[K] := PfLen[K] + Sz;
  PfSet := True;
End;

{ supprimer une cle, ou toute l'application (Key = #0) ; vrai si trouvee }
Function PfDel(K : LongInt; App, Key : String) : Boolean;
Var Ofs, R : LongInt; Found : Boolean;
Begin
  Found := False;
  If Key = #0 Then
  Begin
    Ofs := 0;
    While Ofs < PfLen[K] Do
      If RecApp(PfBuf[K], Ofs) = App Then
      Begin
        PfDelRec(K, Ofs);
        Found := True;
      End
      Else Ofs := Ofs + RecSize(PfBuf[K], Ofs);
  End
  Else
  Begin
    Ofs := PfFind(K, App, Key, R);
    If Ofs >= 0 Then
    Begin
      PfDelRec(K, Ofs);
      Found := True;
    End;
  End;
  PfDel := Found;
End;

{ --- fichier : lecture et ecriture du format d'OS/2 --- }
Procedure PfLoad(K : LongInt);
Var H, Act, Sz, B, Got, A, Kp, Na, Ok, Nk, Dk, Guard, Gk : LongInt; App, Key : String; J : LongInt;
Begin
  PfLen[K] := 0; PfDirty[K] := 0; PfLoaded[K] := 1;
  PutZ(LongInt(@NameZ), PfNameGet(K));
  H := 0; Act := 0;
  If DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), 0, 0, 1, $40, 0) <> 0 Then Exit;
  Sz := 0;
  Dummy := DcSetFilePtr(H, 0, 2, LongInt(@Sz));
  Dummy := DcSetFilePtr(H, 0, 0, LongInt(@Act));
  If (Sz >= 20) And (Sz < ArenaSize Div 2) Then
  Begin
    B := MemAlloc(Sz);
    If B <> 0 Then
    Begin
      Got := 0;
      Dummy := DcRead(H, B, Sz, LongInt(@Got));
      If (Got = Sz) And (RdL(B) = -1) Then
      Begin
        A := RdL(B + 4); Guard := 0;
        While (A > 0) And (A + 20 <= Sz) And (Guard < 4096) Do
        Begin
          Na := RdW(B + A + 12); Ok := RdL(B + A + 16);
          App := '';
          If (Ok > 0) And (Ok + Na <= Sz) Then
            For J := 0 To MinI(Na, 256) - 2 Do App := App + Chr(RdB(B + Ok + J));
          Kp := RdL(B + A + 4); Gk := 0;
          While (Kp > 0) And (Kp + 24 <= Sz) And (Gk < 16384) Do
          Begin
            Nk := RdW(B + Kp + 8); Ok := RdL(B + Kp + 12);
            Key := '';
            If (Ok > 0) And (Ok + Nk <= Sz) Then
              For J := 0 To MinI(Nk, 256) - 2 Do Key := Key + Chr(RdB(B + Ok + J));
            Dk := RdW(B + Kp + 16); Ok := RdL(B + Kp + 20);
            If (Ok >= 0) And (Ok + Dk <= Sz) Then Dummy := LongInt(PfSet(K, App, Key, B + Ok, Dk));
            Kp := RdL(B + Kp); Inc(Gk);
          End;
          A := RdL(B + A); Inc(Guard);
        End;
      End;
      MemFree(B);
    End;
  End;
  Dummy := DcClose(H);
  PfDirty[K] := 0;
End;

Procedure PfSave(K : LongInt);
Var Sz, Ofs, B, Out, P, AppStart, KeyPos, H, Act, Wr, J, Dn, Dp, NextOfs : LongInt; App, Prev, Key : String;
Begin
  If PfLoaded[K] = 0 Then Exit;
  { taille : en-tete, applications (20 + nom), cles (24 + nom + donnees) }
  Sz := 20; Ofs := 0; Prev := #1#2;
  While Ofs < PfLen[K] Do
  Begin
    App := RecApp(PfBuf[K], Ofs);
    If App <> Prev Then
    Begin
      Sz := Sz + 20 + Length(App) + 1;
      Prev := App;
    End;
    Key := RecKey(PfBuf[K], Ofs);
    Dp := RecData(PfBuf[K], Ofs, Dn);
    Sz := Sz + 24 + Length(Key) + 1 + Dn;
    Ofs := Ofs + RecSize(PfBuf[K], Ofs);
  End;
  Out := MemAlloc(Sz);
  If Out = 0 Then Exit;
  WrL(Out, -1); WrL(Out + 8, Sz); WrL(Out + 12, 0); WrL(Out + 16, 0);
  If PfLen[K] > 0 Then WrL(Out + 4, 20) Else WrL(Out + 4, 0);
  P := 20; Ofs := 0; Prev := #1#2; AppStart := 0; KeyPos := 0;
  While Ofs < PfLen[K] Do
  Begin
    App := RecApp(PfBuf[K], Ofs);
    If App <> Prev Then
    Begin
      If AppStart > 0 Then WrL(Out + AppStart, P);       { application suivante }
      If KeyPos > 0 Then WrL(Out + KeyPos, 0);
      AppStart := P;
      WrL(Out + P, 0); WrL(Out + P + 4, 0); WrL(Out + P + 8, 0);
      WrW(Out + P + 12, Length(App) + 1); WrW(Out + P + 14, Length(App) + 1); WrL(Out + P + 16, P + 20);
      For J := 1 To Length(App) Do WrB(Out + P + 19 + J, Ord(App[J]));
      WrB(Out + P + 20 + Length(App), 0);
      P := P + 20 + Length(App) + 1;
      WrL(Out + AppStart + 4, P);                        { premiere cle }
      KeyPos := 0;
      Prev := App;
    End;
    Key := RecKey(PfBuf[K], Ofs);
    Dp := RecData(PfBuf[K], Ofs, Dn);
    NextOfs := P + 24 + Length(Key) + 1 + Dn;
    WrL(Out + P, NextOfs); WrL(Out + P + 4, 0);
    WrW(Out + P + 8, Length(Key) + 1); WrW(Out + P + 10, Length(Key) + 1); WrL(Out + P + 12, P + 24);
    For J := 1 To Length(Key) Do WrB(Out + P + 23 + J, Ord(Key[J]));
    WrB(Out + P + 24 + Length(Key), 0);
    WrW(Out + P + 16, Dn); WrW(Out + P + 18, Dn); WrL(Out + P + 20, P + 24 + Length(Key) + 1);
    MemMove(Dp, Out + P + 24 + Length(Key) + 1, Dn);
    KeyPos := P;
    P := NextOfs;
    Ofs := Ofs + RecSize(PfBuf[K], Ofs);
  End;
  If KeyPos > 0 Then WrL(Out + KeyPos, 0);
  PutZ(LongInt(@NameZ), PfNameGet(K));
  H := 0; Act := 0;
  If DcOpen(LongInt(@NameZ), LongInt(@H), LongInt(@Act), Sz, 0, $12, $22, 0) = 0 Then
  Begin
    Wr := 0;
    Dummy := DcWrite(H, Out, Sz, LongInt(@Wr));
    Dummy := DcClose(H);
    PfDirty[K] := 0;
  End;
  MemFree(Out);
End;

{ modification : ecriture immediate sauf si retardee }
Procedure PfChanged(K : LongInt);
Begin
  PfDirty[K] := 1;
  If (PfThru[K] <> 0) And (PfSusp[K] = 0) And (IniLock = 0) Then PfSave(K);
End;

{ profils de l'utilisateur et du systeme (USER_INI, SYSTEM_INI) }
Procedure PfInit;
Var P : LongInt; S : String;
Begin
  If PfInitDone <> 0 Then Exit;
  PfInitDone := 1;
  If (RdL(LongInt(@Arena)) = 0) Then HeapInit(LongInt(@Arena), ArenaSize);
  P := 0; S := '';
  PutZ(LongInt(@NameZ2), 'USER_INI');
  If DcScanEnv(LongInt(@NameZ2), LongInt(@P)) = 0 Then S := GetZ(P);
  If S = '' Then S := 'C:\OS2.INI';
  PutZ(LongInt(@PfName), UpStr(S));
  P := 0; S := '';
  PutZ(LongInt(@NameZ2), 'SYSTEM_INI');
  If DcScanEnv(LongInt(@NameZ2), LongInt(@P)) = 0 Then S := GetZ(P);
  If S = '' Then S := 'C:\OS2SYS.INI';
  PutZ(LongInt(@PfName) + 128, UpStr(S));
  PfUse[0] := 1; PfUse[1] := 1; PfThru[0] := 1; PfThru[1] := 1; PfRef[0] := 1; PfRef[1] := 1;
  PfLoad(0); PfLoad(1);
End;

{ HINI -> profil (HINI_PROFILE : utilisateur) ; -1 : erreur }
Function PfIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  PfInit;
  If (H = HINI_PROFILE) Or (H = HINI_USERPROFILE) Then I := 0
  Else If H = HINI_SYSTEMPROFILE Then I := 1
  Else
  Begin
    I := H - HiniBase + 2;
    If (I < 2) Or (I >= MaxPf) Then I := -1
    Else If PfUse[I] = 0 Then I := -1;
  End;
  If I < 0 Then SetErr(PMERR_INVALID_INI_FILE_HANDLE);
  PfIdx := I;
End;

{ recherche (HINI_PROFILE : utilisateur puis systeme) ; profil trouve }
Function PfLookup(H : LongInt; App, Key : String; Var K, Ofs : LongInt) : Boolean;
Var L : LongInt;
Begin
  PfLookup := False;
  K := PfIdx(H);
  If K < 0 Then Exit;
  Ofs := PfFind(K, App, Key, L);
  If (Ofs < 0) And (H = HINI_PROFILE) Then
  Begin
    K := 1;
    Ofs := PfFind(K, App, Key, L);
  End;
  PfLookup := Ofs >= 0;
End;

{ liste des applications (Key faux) ou des cles de App, noms termines par
  un nul, liste terminee par un nul de plus ; rend sa taille (copie si
  P <> 0, au plus Max octets) }
Function PfList(H : LongInt; ByKey : Boolean; App : String; P, Max : LongInt) : LongInt;
Var Ofs, N, J, K, Pass, K1 : LongInt; Name, Prev : String; Seen : Boolean;
Begin
  N := 0;
  K1 := PfIdx(H);
  If K1 < 0 Then
  Begin
    PfList := 0;
    Exit;
  End;
  For Pass := 0 To 1 Do
    If (Pass = 0) Or (H = HINI_PROFILE) Then
    Begin
      If Pass = 0 Then K := K1 Else K := 1;
      Ofs := 0; Prev := #1#2;
      While Ofs < PfLen[K] Do
      Begin
        If ByKey Then
        Begin
          If RecApp(PfBuf[K], Ofs) = App Then Name := RecKey(PfBuf[K], Ofs) Else Name := #1#2;
        End
        Else Name := RecApp(PfBuf[K], Ofs);
        If (Name <> #1#2) And (Name <> Prev) Then
        Begin
          Seen := False;
          If (Pass = 1) And Not ByKey Then
          Begin
            J := -1;
            Dummy := PfFind(0, Name, #1, J);
            Seen := J >= 0;
          End;
          If Not Seen Then
          Begin
            For J := 1 To Length(Name) Do
            Begin
              If (P <> 0) And (N < Max) Then WrB(P + N, Ord(Name[J]));
              Inc(N);
            End;
            If (P <> 0) And (N < Max) Then WrB(P + N, 0);
            Inc(N);
          End;
          If Not ByKey Then Prev := Name;
        End;
        Ofs := Ofs + RecSize(PfBuf[K], Ofs);
      End;
    End;
  If (P <> 0) And (N < Max) Then WrB(P + N, 0);
  Inc(N);
  PfList := N;
End;

{ ==================================================================== }
{ PrfQueryProfile*, PrfWriteProfile*                                    }
{ ==================================================================== }

{ PrfQueryProfileInt(hini, pszApp, pszKey, sDefault) : nombre au debut de
  la chaine, ou sDefault }
Function PrfQueryProfileInt(Hini, PApp, PKey, Def : LongInt) : LongInt;
Var K, Ofs, D, N, J, V, Sg : LongInt; Digit : Boolean;
Begin
  PrfQueryProfileInt := Def;
  If (PApp = 0) Or (PKey = 0) Then Exit;
  If Not PfLookup(Hini, GetZ(PApp), GetZ(PKey), K, Ofs) Then Exit;
  D := RecData(PfBuf[K], Ofs, N);
  J := 0; V := 0; Sg := 1; Digit := False;
  While (J < N) And (RdB(D + J) = 32) Do Inc(J);
  If (J < N) And (RdB(D + J) = 45) Then
  Begin
    Sg := -1; Inc(J);
  End
  Else If (J < N) And (RdB(D + J) = 43) Then Inc(J);
  While (J < N) And (RdB(D + J) >= 48) And (RdB(D + J) <= 57) Do
  Begin
    V := V * 10 + RdB(D + J) - 48;
    Digit := True;
    Inc(J);
  End;
  If Digit Then PrfQueryProfileInt := V * Sg Else PrfQueryProfileInt := 0;
End;

{ PrfQueryProfileString(hini, pszApp, pszKey, pszDefault, pBuffer,
  cchBufferMax) : longueur copiee (nul compris) ; pszApp nul : noms des
  applications, pszKey nul : noms des cles }
Function PrfQueryProfileString(Hini, PApp, PKey, PDef, PBuf, Max : LongInt) : LongInt;
Var K, Ofs, D, N, M : LongInt;
Begin
  PrfQueryProfileString := 0;
  If (PBuf = 0) Or (Max <= 0) Then Exit;
  If PApp = 0 Then
  Begin
    PrfQueryProfileString := MinI(PfList(Hini, False, '', PBuf, Max), Max);
    Exit;
  End;
  If PKey = 0 Then
  Begin
    PrfQueryProfileString := MinI(PfList(Hini, True, GetZ(PApp), PBuf, Max), Max);
    Exit;
  End;
  If PfLookup(Hini, GetZ(PApp), GetZ(PKey), K, Ofs) Then
  Begin
    D := RecData(PfBuf[K], Ofs, N);
    M := MinI(N, Max);
    MemMove(D, PBuf, M);
    If (M = 0) Or (RdB(PBuf + M - 1) <> 0) Then
    Begin
      If M >= Max Then M := Max - 1;
      WrB(PBuf + M, 0);
      Inc(M);
    End;
    PrfQueryProfileString := M;
  End
  Else If PDef <> 0 Then
  Begin
    M := MinI(LenZ(PDef), Max - 1);
    MemMove(PDef, PBuf, M);
    WrB(PBuf + M, 0);
    PrfQueryProfileString := M + 1;
  End
  Else SetErr(PMERR_NOT_IN_IDX);
End;

{ PrfWriteProfileString(hini, pszApp, pszKey, pszData) : pszData nul :
  supprimer la cle ; pszKey nul : supprimer l'application }
Function PrfWriteProfileString(Hini, PApp, PKey, PData : LongInt) : LongInt;
Var K : LongInt; Ok : Boolean;
Begin
  PrfWriteProfileString := 0;
  K := PfIdx(Hini);
  If (K < 0) Or (PApp = 0) Then Exit;
  If PKey = 0 Then Ok := PfDel(K, GetZ(PApp), #0)
  Else If PData = 0 Then Ok := PfDel(K, GetZ(PApp), GetZ(PKey))
  Else Ok := PfSet(K, GetZ(PApp), GetZ(PKey), PData, LenZ(PData) + 1);
  If Ok Then
  Begin
    PfChanged(K);
    PrfWriteProfileString := 1;
  End
  Else SetErr(PMERR_NOT_IN_IDX);
End;

{ PrfQueryProfileSize(hini, pszApp, pszKey, pulReqLen) : BOOL }
Function PrfQueryProfileSize(Hini, PApp, PKey, PLen : LongInt) : LongInt;
Var K, Ofs, N : LongInt;
Begin
  PrfQueryProfileSize := 0;
  If PLen = 0 Then Exit;
  If PApp = 0 Then N := PfList(Hini, False, '', 0, 0)
  Else If PKey = 0 Then N := PfList(Hini, True, GetZ(PApp), 0, 0)
  Else If PfLookup(Hini, GetZ(PApp), GetZ(PKey), K, Ofs) Then Dummy := RecData(PfBuf[K], Ofs, N)
  Else
  Begin
    SetErr(PMERR_NOT_IN_IDX);
    Exit;
  End;
  WrL(PLen, N);
  PrfQueryProfileSize := 1;
End;

{ PrfQueryProfileData(hini, pszApp, pszKey, pBuffer, pulBuffLen) : BOOL }
Function PrfQueryProfileData(Hini, PApp, PKey, PBuf, PLen : LongInt) : LongInt;
Var K, Ofs, D, N, M : LongInt;
Begin
  PrfQueryProfileData := 0;
  If PLen = 0 Then Exit;
  If (PApp = 0) Or (PKey = 0) Then
  Begin
    If PApp = 0 Then N := PfList(Hini, False, '', PBuf, RdL(PLen))
    Else N := PfList(Hini, True, GetZ(PApp), PBuf, RdL(PLen));
    WrL(PLen, MinI(N, RdL(PLen)));
    PrfQueryProfileData := 1;
    Exit;
  End;
  If Not PfLookup(Hini, GetZ(PApp), GetZ(PKey), K, Ofs) Then
  Begin
    SetErr(PMERR_NOT_IN_IDX);
    Exit;
  End;
  D := RecData(PfBuf[K], Ofs, N);
  M := MinI(N, RdL(PLen));
  If PBuf <> 0 Then MemMove(D, PBuf, M);
  WrL(PLen, M);
  PrfQueryProfileData := 1;
End;

{ PrfWriteProfileData(hini, pszApp, pszKey, pData, cchDataLen) : BOOL }
Function PrfWriteProfileData(Hini, PApp, PKey, PData, Cb : LongInt) : LongInt;
Var K : LongInt; Ok : Boolean;
Begin
  PrfWriteProfileData := 0;
  K := PfIdx(Hini);
  If (K < 0) Or (PApp = 0) Then Exit;
  If PKey = 0 Then Ok := PfDel(K, GetZ(PApp), #0)
  Else If PData = 0 Then Ok := PfDel(K, GetZ(PApp), GetZ(PKey))
  Else Ok := PfSet(K, GetZ(PApp), GetZ(PKey), PData, MaxI(Cb, 0));
  If Ok Then
  Begin
    PfChanged(K);
    PrfWriteProfileData := 1;
  End
  Else SetErr(PMERR_NOT_IN_IDX);
End;

{ PrfOpenProfile(hab, pszFileName) : HINI }
Function PrfOpenProfile(Hab, PName : LongInt) : LongInt;
Var I, F : LongInt; S : String;
Begin
  PrfOpenProfile := 0;
  PfInit;
  If PName = 0 Then
  Begin
    SetErr(PMERR_INVALID_PARM);
    Exit;
  End;
  S := UpStr(GetZ(PName));
  If S = PfNameGet(0) Then
  Begin
    PrfOpenProfile := HINI_USERPROFILE;
    Exit;
  End;
  If S = PfNameGet(1) Then
  Begin
    PrfOpenProfile := HINI_SYSTEMPROFILE;
    Exit;
  End;
  F := -1;
  For I := MaxPf - 1 DownTo 2 Do
    If (PfUse[I] <> 0) And (PfNameGet(I) = S) Then F := I;
  If F >= 0 Then
  Begin
    Inc(PfRef[F]);
    PrfOpenProfile := HiniBase + F - 2;
    Exit;
  End;
  For I := MaxPf - 1 DownTo 2 Do
    If PfUse[I] = 0 Then F := I;
  If F < 0 Then
  Begin
    SetErr(PMERR_INSUFFICIENT_MEMORY);
    Exit;
  End;
  PfUse[F] := 1; PfRef[F] := 1; PfThru[F] := 1; PfSusp[F] := 0; PfBuf[F] := 0; PfCap[F] := 0;
  PutZ(LongInt(@PfName) + F * 128, S);
  PfLoad(F);
  { un profil nouveau est cree sur le disque }
  If PfLen[F] = 0 Then PfSave(F);
  PrfOpenProfile := HiniBase + F - 2;
End;

{ PrfCloseProfile(hini) : BOOL }
Function PrfCloseProfile(Hini : LongInt) : LongInt;
Var K : LongInt;
Begin
  PrfCloseProfile := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  If PfDirty[K] <> 0 Then PfSave(K);
  If K >= 2 Then
  Begin
    Dec(PfRef[K]);
    If PfRef[K] <= 0 Then
    Begin
      MemFree(PfBuf[K]);
      PfUse[K] := 0; PfBuf[K] := 0; PfLen[K] := 0; PfCap[K] := 0;
    End;
  End;
  PrfCloseProfile := 1;
End;

{ PrfQueryProfile(hab, pPrfProfile) : PRFPROFILE (cchUserName,
  pszUserName, cchSysName, pszSysName) ; BOOL }
Function PrfQueryProfile(Hab, P : LongInt) : LongInt;
Var U, S : String; Ok : Boolean;
Begin
  PrfQueryProfile := 0;
  PfInit;
  If P = 0 Then Exit;
  U := PfNameGet(0); S := PfNameGet(1);
  Ok := True;
  If (RdL(P + 4) <> 0) And (RdL(P) > Length(U)) Then PutZ(RdL(P + 4), U) Else Ok := RdL(P + 4) = 0;
  WrL(P, Length(U) + 1);
  If (RdL(P + 12) <> 0) And (RdL(P + 8) > Length(S)) Then PutZ(RdL(P + 12), S) Else Ok := Ok And (RdL(P + 12) = 0);
  WrL(P + 8, Length(S) + 1);
  If Ok Then PrfQueryProfile := 1;
End;

{ PrfReset(hab, pPrfProfile) : changer les profils de l'utilisateur et du
  systeme ; BOOL }
Function PrfReset(Hab, P : LongInt) : LongInt;
Var K : LongInt;
Begin
  PrfReset := 0;
  PfInit;
  If (P = 0) Or (RdL(P + 4) = 0) Or (RdL(P + 12) = 0) Then
  Begin
    SetErr(PMERR_INVALID_PARM);
    Exit;
  End;
  For K := 0 To 1 Do
    If PfDirty[K] <> 0 Then PfSave(K);
  PutZ(LongInt(@PfName), UpStr(GetZ(RdL(P + 4))));
  PutZ(LongInt(@PfName) + 128, UpStr(GetZ(RdL(P + 12))));
  PfLoad(0); PfLoad(1);
  PrfReset := 1;
End;

{ PrfChangeWriteThru(hini, fWriteThru) : ecriture a chaque modification }
Function PrfChangeWriteThru(Hini, F : LongInt) : LongInt;
Var K : LongInt;
Begin
  PrfChangeWriteThru := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  PrfChangeWriteThru := PfThru[K];
  If F <> 0 Then PfThru[K] := 1 Else PfThru[K] := 0;
  If (F <> 0) And (PfDirty[K] <> 0) Then PfSave(K);
End;

{ PrfSuspendWriteToDisk(hini, fSuspend) : BOOL }
Function PrfSuspendWriteToDisk(Hini, F : LongInt) : LongInt;
Var K : LongInt;
Begin
  PrfSuspendWriteToDisk := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  If F <> 0 Then PfSusp[K] := 1
  Else
  Begin
    PfSusp[K] := 0;
    If PfDirty[K] <> 0 Then PfSave(K);
  End;
  PrfSuspendWriteToDisk := 1;
End;

{ PrfWriteToDisk(hini) : BOOL }
Function PrfWriteToDisk(Hini : LongInt) : LongInt;
Var K : LongInt;
Begin
  PrfWriteToDisk := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  PfSave(K);
  PrfWriteToDisk := 1;
End;

{ ecrire tous les profils modifies }
Procedure PfFlushAll;
Var K : LongInt;
Begin
  For K := 0 To MaxPf - 1 Do
    If (PfUse[K] <> 0) And (PfDirty[K] <> 0) Then PfSave(K);
End;

{ --- profils de Presentation Manager 1.x (HAB : profil de l'utilisateur
  pour l'ecriture, les deux pour la lecture) --- }
Function WinQueryProfileInt(Hab, PApp, PKey, Def : LongInt) : LongInt;
Begin
  WinQueryProfileInt := PrfQueryProfileInt(HINI_PROFILE, PApp, PKey, Def);
End;

Function WinQueryProfileString(Hab, PApp, PKey, PDef, PBuf, Max : LongInt) : LongInt;
Begin
  WinQueryProfileString := PrfQueryProfileString(HINI_PROFILE, PApp, PKey, PDef, PBuf, Max);
End;

Function WinWriteProfileString(Hab, PApp, PKey, PData : LongInt) : LongInt;
Begin
  WinWriteProfileString := PrfWriteProfileString(HINI_USERPROFILE, PApp, PKey, PData);
End;

Function WinQueryProfileSize(Hab, PApp, PKey, PLen : LongInt) : LongInt;
Begin
  WinQueryProfileSize := PrfQueryProfileSize(HINI_PROFILE, PApp, PKey, PLen);
End;

Function WinQueryProfileData(Hab, PApp, PKey, PBuf, PLen : LongInt) : LongInt;
Begin
  WinQueryProfileData := PrfQueryProfileData(HINI_PROFILE, PApp, PKey, PBuf, PLen);
End;

Function WinWriteProfileData(Hab, PApp, PKey, PData, Cb : LongInt) : LongInt;
Begin
  WinWriteProfileData := PrfWriteProfileData(HINI_USERPROFILE, PApp, PKey, PData, Cb);
End;

{ --- initialisation de l'interpreteur (SHELL) --- }
Function ShePIInitialise : LongInt;
Begin
  PfInit;
  ShePIInitialise := 1;
End;

{ ShePIInitIniFiles : ouvrir les profils de l'utilisateur et du systeme }
Function ShePIInitIniFiles : LongInt;
Begin
  PfInit;
  ShePIInitIniFiles := 1;
End;

{ SheUpdateIniFile(hini) : ecrire le profil (0 : tous) }
Function SheUpdateIniFile(Hini : LongInt) : LongInt;
Var K : LongInt;
Begin
  PfInit;
  If Hini = 0 Then PfFlushAll
  Else
  Begin
    K := PfIdx(Hini);
    If K >= 0 Then PfSave(K);
  End;
  SheUpdateIniFile := 1;
End;

{ SheProfileHook(fl, pszApp, pszKey) : crochet des profils (aucun) }
Function SheProfileHook(Fl, PApp, PKey : LongInt) : LongInt;
Begin
  SheProfileHook := 0;
End;

{ ShpPILockIniFile(fLock) : retarder l'ecriture des profils ; BOOL }
Function ShpPILockIniFile(F : LongInt) : LongInt;
Begin
  PfInit;
  If F <> 0 Then Inc(IniLock)
  Else If IniLock > 0 Then
  Begin
    Dec(IniLock);
    If IniLock = 0 Then PfFlushAll;
  End;
  ShpPILockIniFile := 1;
End;

{ ShpPIShutdown : ecrire tous les profils (arret) }
Function ShpPIShutdown : LongInt;
Begin
  PfInit;
  IniLock := 0;
  PfFlushAll;
  ShpPIShutdown := 1;
End;

{ SheConvert190ProgramListTo300 : liste des programmes deja au format
  d'OS/2 2.0 }
Function SheConvert190ProgramListTo300 : LongInt;
Begin
  SheConvert190ProgramListTo300 := 1;
End;

{ ==================================================================== }
{ Liste des programmes et groupes                                       }
{ ==================================================================== }
Const
  AppProg = 'PM_Programs';
  AppGroup = 'PM_Groups';

{ handle nouveau (cle !NEXT de PM_Programs) }
Function PrgNewHandle(K : LongInt) : LongInt;
Var Ofs, L, N, V : LongInt;
Begin
  V := 1;
  Ofs := PfFind(K, AppProg, '!NEXT', L);
  If Ofs >= 0 Then V := RdL(RecData(PfBuf[K], Ofs, N));
  If V < 1 Then V := 1;
  N := V + 1;
  Dummy := LongInt(PfSet(K, AppProg, '!NEXT', LongInt(@N), 4));
  PrgNewHandle := V;
End;

{ enregistrement d'un programme : groupe (4), progc (4), fbVisible (4),
  SWP (36), 6 chaines terminees par un nul }
Function PrgPack(Grp, PDet, Buf : LongInt) : LongInt;
Var N, J, S : LongInt;
Begin
  WrL(Buf, Grp);
  If PDet = 0 Then
  Begin
    PrgPack := 0;
    Exit;
  End;
  WrL(Buf + 4, RdL(PDet + 4)); WrL(Buf + 8, RdL(PDet + 8));
  If RdL(PDet) >= 72 Then MemMove(PDet + 36, Buf + 12, 36) Else MemZero(Buf + 12, 36);
  N := 48;
  For J := 0 To 5 Do
  Begin
    If RdL(PDet) >= 16 + J * 4 Then S := RdL(PDet + 12 + J * 4) Else S := 0;
    If S <> 0 Then
    Begin
      MemMove(S, Buf + N, MinI(LenZ(S), 250));
      N := N + MinI(LenZ(S), 250);
    End;
    WrB(Buf + N, 0);
    Inc(N);
  End;
  PrgPack := N;
End;

{ chaine J (0 titre, 1 programme, 2 parametres, 3 repertoire, 4 icone,
  5 environnement) d'un enregistrement de programme }
Function PrgStr(D, J : LongInt) : LongInt;
Var P : LongInt;
Begin
  P := D + 48;
  While J > 0 Do
  Begin
    P := P + LenZ(P) + 1;
    Dec(J);
  End;
  PrgStr := P;
End;

Function PrgFind(K, H : LongInt; Var D : LongInt) : Boolean;
Var Ofs, L, N : LongInt;
Begin
  Ofs := PfFind(K, AppProg, 'P' + HexStr(H), L);
  If Ofs >= 0 Then D := RecData(PfBuf[K], Ofs, N) Else D := 0;
  PrgFind := Ofs >= 0;
End;

Function GrpExists(K, H : LongInt) : Boolean;
Var L : LongInt;
Begin
  GrpExists := (H = SGH_ROOT) Or (H = 0) Or (PfFind(K, AppGroup, 'G' + HexStr(H), L) >= 0);
End;

{ PrfAddProgram(hini, pProgDetails, hprogGroup) : HPROGRAM }
Function PrfAddProgram(Hini, PDet, Grp : LongInt) : LongInt;
Var K, H, N : LongInt; Buf : Array[0..1599] Of Byte;
Begin
  PrfAddProgram := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  If (PDet = 0) Or Not GrpExists(K, Grp) Then
  Begin
    SetErr(PMERR_INVALID_PARM);
    Exit;
  End;
  If Grp = 0 Then Grp := SGH_ROOT;
  H := PrgNewHandle(K);
  N := PrgPack(Grp, PDet, LongInt(@Buf));
  If PfSet(K, AppProg, 'P' + HexStr(H), LongInt(@Buf), N) Then
  Begin
    PfChanged(K);
    PrfAddProgram := H;
  End;
End;

{ PrfChangeProgram(hini, hprog, pProgDetails) : BOOL }
Function PrfChangeProgram(Hini, H, PDet : LongInt) : LongInt;
Var K, D, N : LongInt; Buf : Array[0..1599] Of Byte;
Begin
  PrfChangeProgram := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  If (PDet = 0) Or Not PrgFind(K, H, D) Then
  Begin
    SetErr(PMERR_INVALID_HPROGRAM);
    Exit;
  End;
  N := PrgPack(RdL(D), PDet, LongInt(@Buf));
  If PfSet(K, AppProg, 'P' + HexStr(H), LongInt(@Buf), N) Then
  Begin
    PfChanged(K);
    PrfChangeProgram := 1;
  End;
End;

{ PrfRemoveProgram(hini, hprog) : BOOL }
Function PrfRemoveProgram(Hini, H : LongInt) : LongInt;
Var K : LongInt;
Begin
  PrfRemoveProgram := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  If PfDel(K, AppProg, 'P' + HexStr(H)) Then
  Begin
    PfChanged(K);
    PrfRemoveProgram := 1;
  End
  Else SetErr(PMERR_INVALID_HPROGRAM);
End;

{ PrfQueryDefinition(hini, hprog, pProgDetails, cchBufferMax) : taille
  necessaire (PROGDETAILS et chaines) ; copie si elle tient }
Function PrfQueryDefinition(Hini, H, PDet, Max : LongInt) : LongInt;
Var K, D, J, Need, P, S : LongInt;
Begin
  PrfQueryDefinition := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  If Not PrgFind(K, H, D) Then
  Begin
    SetErr(PMERR_INVALID_HPROGRAM);
    Exit;
  End;
  Need := 72;
  For J := 0 To 5 Do Need := Need + LenZ(PrgStr(D, J)) + 1;
  PrfQueryDefinition := Need;
  If (PDet = 0) Or (Max < Need) Then Exit;
  WrL(PDet, 72); WrL(PDet + 4, RdL(D + 4)); WrL(PDet + 8, RdL(D + 8));
  MemMove(D + 12, PDet + 36, 36);
  P := PDet + 72;
  For J := 0 To 5 Do
  Begin
    S := PrgStr(D, J);
    WrL(PDet + 12 + J * 4, P);
    MemMove(S, P, LenZ(S) + 1);
    P := P + LenZ(S) + 1;
  End;
End;

{ PrfCreateGroup(hini, pszTitle, chVisibility) : HPROGRAM du groupe }
Function PrfCreateGroup(Hini, PTitle, Vis : LongInt) : LongInt;
Var K, H, N : LongInt; Buf : Array[0..299] Of Byte;
Begin
  PrfCreateGroup := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  If PTitle = 0 Then
  Begin
    SetErr(PMERR_INVALID_PARM);
    Exit;
  End;
  H := PrgNewHandle(K);
  WrL(LongInt(@Buf), Vis And 255);
  N := MinI(LenZ(PTitle), 250);
  MemMove(PTitle, LongInt(@Buf) + 4, N);
  WrB(LongInt(@Buf) + 4 + N, 0);
  If PfSet(K, AppGroup, 'G' + HexStr(H), LongInt(@Buf), N + 5) Then
  Begin
    PfChanged(K);
    PrfCreateGroup := H;
  End;
End;

{ PrfDestroyGroup(hini, hprogGroup) : le groupe et ses programmes ; BOOL }
Function PrfDestroyGroup(Hini, Grp : LongInt) : LongInt;
Var K, Ofs, N : LongInt; Again : Boolean;
Begin
  PrfDestroyGroup := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  If Not PfDel(K, AppGroup, 'G' + HexStr(Grp)) Then
  Begin
    SetErr(PMERR_INVALID_HPROGRAM);
    Exit;
  End;
  Again := True;
  While Again Do
  Begin
    Again := False;
    Ofs := 0;
    While (Ofs < PfLen[K]) And Not Again Do
    Begin
      If (RecApp(PfBuf[K], Ofs) = AppProg) And (Copy(RecKey(PfBuf[K], Ofs), 1, 1) = 'P') And
         (RdL(RecData(PfBuf[K], Ofs, N)) = Grp) Then
      Begin
        PfDelRec(K, Ofs);
        Again := True;
      End
      Else Ofs := Ofs + RecSize(PfBuf[K], Ofs);
    End;
  End;
  PfChanged(K);
  PrfDestroyGroup := 1;
End;

{ handle d'une cle P/G (hexadecimal) }
Function KeyHandle(S : String) : LongInt;
Var V, J, D : LongInt;
Begin
  V := 0;
  For J := 2 To Length(S) Do
  Begin
    D := Ord(S[J]);
    If D >= 65 Then D := D - 55 Else D := D - 48;
    V := (V Shl 4) Or (D And 15);
  End;
  KeyHandle := V;
End;

{ PrfQueryProgramTitles(hini, hprogGroup, pTitles, cchBufferMax,
  pulCount) : taille necessaire ; SGH_ROOT : les groupes. PROGTITLE
  (hprog, progc, fbVisible, pszTitle) suivis des titres }
Function PrfQueryProgramTitles(Hini, Grp, P, Max, PCount : LongInt) : LongInt;
Var K, Ofs, N, D, Cnt, Need, Pass, Sp, Tp, H, L : LongInt; Key, T : String; Hit : Boolean;
Begin
  PrfQueryProgramTitles := 0;
  K := PfIdx(Hini);
  If K < 0 Then Exit;
  Cnt := 0; Need := 0;
  L := 0;
  For Pass := 0 To 1 Do
    If (Pass = 0) Or ((P <> 0) And (Max >= Need)) Then
  Begin
    If Pass = 1 Then
    Begin
      Sp := P + Cnt * 16; Tp := P; Cnt := 0;
    End;
    Ofs := 0;
    While Ofs < PfLen[K] Do
    Begin
      Key := RecKey(PfBuf[K], Ofs);
      D := RecData(PfBuf[K], Ofs, N);
      Hit := False;
      If (Grp = SGH_ROOT) And (RecApp(PfBuf[K], Ofs) = AppGroup) And (Copy(Key, 1, 1) = 'G') Then
      Begin
        Hit := True; T := GetZ(D + 4);
      End
      Else If (Grp <> SGH_ROOT) And (RecApp(PfBuf[K], Ofs) = AppProg) And (Copy(Key, 1, 1) = 'P') And
              (RdL(D) = Grp) Then
      Begin
        Hit := True; T := GetZ(D + 48);
      End;
      If Hit Then
      Begin
        H := KeyHandle(Key);
        If Pass = 0 Then Need := Need + 16 + Length(T) + 1
        Else
        Begin
          WrL(Tp, H);
          If Grp = SGH_ROOT Then
          Begin
            WrL(Tp + 4, 0); WrL(Tp + 8, RdL(D));
          End
          Else
          Begin
            WrL(Tp + 4, RdL(D + 4)); WrL(Tp + 8, RdL(D + 8));
          End;
          WrL(Tp + 12, Sp);
          PutZ(Sp, T);
          Sp := Sp + Length(T) + 1;
          Tp := Tp + 16;
        End;
        Inc(Cnt);
      End;
      Ofs := Ofs + RecSize(PfBuf[K], Ofs);
    End;
    { les titres sont apres le tableau : recompter la place }
    If Pass = 0 Then L := Cnt;
  End;
  If PCount <> 0 Then WrL(PCount, L);
  PrfQueryProgramTitles := Need;
End;

{ PrfQueryProgramHandle(hini, pszExe, phprogArray, cchBufferMax,
  pulCount) : programmes de ce fichier ; BOOL }
Function PrfQueryProgramHandle(Hini, PExe, PArr, Max, PCount : LongInt) : LongInt;
Var K, Ofs, N, D, Cnt : LongInt; Exe : String;
Begin
  PrfQueryProgramHandle := 0;
  K := PfIdx(Hini);
  If (K < 0) Or (PExe = 0) Then Exit;
  Exe := UpStr(GetZ(PExe));
  Cnt := 0; Ofs := 0;
  While Ofs < PfLen[K] Do
  Begin
    If (RecApp(PfBuf[K], Ofs) = AppProg) And (Copy(RecKey(PfBuf[K], Ofs), 1, 1) = 'P') Then
    Begin
      D := RecData(PfBuf[K], Ofs, N);
      If UpStr(GetZ(PrgStr(D, 1))) = Exe Then
      Begin
        If (PArr <> 0) And ((Cnt + 1) * 4 <= Max) Then WrL(PArr + Cnt * 4, KeyHandle(RecKey(PfBuf[K], Ofs)));
        Inc(Cnt);
      End;
    End;
    Ofs := Ofs + RecSize(PfBuf[K], Ofs);
  End;
  If PCount <> 0 Then WrL(PCount, Cnt);
  If Cnt > 0 Then PrfQueryProgramHandle := 1 Else SetErr(PMERR_NOT_IN_IDX);
End;

{ PrfQueryProgramCategory(hini, pszExe) : PROGCATEGORY du programme
  (PROG_DEFAULT 0 s'il est inconnu) }
Function PrfQueryProgramCategory(Hini, PExe : LongInt) : LongInt;
Var K, Ofs, N, D : LongInt; Exe : String;
Begin
  PrfQueryProgramCategory := 0;
  K := PfIdx(Hini);
  If (K < 0) Or (PExe = 0) Then Exit;
  Exe := UpStr(GetZ(PExe));
  Ofs := 0;
  While Ofs < PfLen[K] Do
  Begin
    If (RecApp(PfBuf[K], Ofs) = AppProg) And (Copy(RecKey(PfBuf[K], Ofs), 1, 1) = 'P') Then
    Begin
      D := RecData(PfBuf[K], Ofs, N);
      If UpStr(GetZ(PrgStr(D, 1))) = Exe Then
      Begin
        PrfQueryProgramCategory := RdL(D + 4);
        Exit;
      End;
    End;
    Ofs := Ofs + RecSize(PfBuf[K], Ofs);
  End;
End;

{ --- versions de Presentation Manager 1.x (profil de l'utilisateur) --- }
Function WinAddProgram(Hab, PDet, Grp : LongInt) : LongInt;
Begin
  WinAddProgram := PrfAddProgram(HINI_USERPROFILE, PDet, Grp);
End;

{ WinChangeProgram(hprog, pDetails, cbDetails) }
Function WinChangeProgram(H, PDet, Cb : LongInt) : LongInt;
Begin
  WinChangeProgram := PrfChangeProgram(HINI_USERPROFILE, H, PDet);
End;

Function WinRemoveProgram(Hab, H : LongInt) : LongInt;
Begin
  WinRemoveProgram := PrfRemoveProgram(HINI_USERPROFILE, H);
End;

Function WinQueryDefinition(Hab, H, PDet, Max : LongInt) : LongInt;
Begin
  WinQueryDefinition := PrfQueryDefinition(HINI_USERPROFILE, H, PDet, Max);
End;

Function WinQueryProgramTitles(Hab, Grp, P, Max, PCount : LongInt) : LongInt;
Begin
  WinQueryProgramTitles := PrfQueryProgramTitles(HINI_USERPROFILE, Grp, P, Max, PCount);
End;

{ WinCreateGroup(hab, pszTitle, ucVisibility, flres1, flres2) }
Function WinCreateGroup(Hab, PTitle, Vis, R1, R2 : LongInt) : LongInt;
Begin
  WinCreateGroup := PrfCreateGroup(HINI_USERPROFILE, PTitle, Vis);
End;

Function WinDestroyGroup(Hab, Grp : LongInt) : LongInt;
Begin
  WinDestroyGroup := PrfDestroyGroup(HINI_USERPROFILE, Grp);
End;

{ WinAddToGroup(hab, hprogGroup, hprog) : mettre le programme dans le
  groupe ; BOOL }
Function WinAddToGroup(Hab, Grp, H : LongInt) : LongInt;
Var K, D, N : LongInt; Buf : Array[0..1599] Of Byte;
Begin
  WinAddToGroup := 0;
  K := PfIdx(HINI_USERPROFILE);
  If (K < 0) Or Not GrpExists(K, Grp) Or Not PrgFind(K, H, D) Then
  Begin
    SetErr(PMERR_INVALID_HPROGRAM);
    Exit;
  End;
  D := RecData(PfBuf[K], PfFind(K, AppProg, 'P' + HexStr(H), N), N);
  N := MinI(N, 1600);
  MemMove(D, LongInt(@Buf), N);
  WrL(LongInt(@Buf), Grp);
  If PfSet(K, AppProg, 'P' + HexStr(H), LongInt(@Buf), N) Then
  Begin
    PfChanged(K);
    WinAddToGroup := 1;
  End;
End;

{ WinRemoveFromGroup(hab, hprog) : le programme revient a la racine }
Function WinRemoveFromGroup(Hab, H : LongInt) : LongInt;
Begin
  WinRemoveFromGroup := WinAddToGroup(Hab, SGH_ROOT, H);
End;

{ WinQueryProgramType(hab, pszExe) : PROGCATEGORY }
Function WinQueryProgramType(Hab, PExe : LongInt) : LongInt;
Begin
  WinQueryProgramType := PrfQueryProgramCategory(HINI_USERPROFILE, PExe);
End;

{ WinQueryProgramUse(hab, pszExe) : nombre de programmes de ce fichier }
Function WinQueryProgramUse(Hab, PExe : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  Dummy := PrfQueryProgramHandle(HINI_USERPROFILE, PExe, 0, 0, LongInt(@N));
  WinQueryProgramUse := N;
End;

{ ShpLockProgramList / ShpUnlockProgramList : verrou de la liste }
Function ShpLockProgramList : LongInt;
Begin
  Inc(PrgLock);
  ShpLockProgramList := 1;
End;

Function ShpUnlockProgramList : LongInt;
Begin
  If PrgLock > 0 Then Dec(PrgLock);
  ShpUnlockProgramList := 1;
End;


{ ==================================================================== }
{ Partie 3 - Fonctions propres a Warp 4                                }
{ ==================================================================== }


Function Mk2(A, B : LongInt) : LongInt;
Begin
  Mk2 := (A And $FFFF) Or (B Shl 16);
End;

{ --- moteur graphique : fonction inconnue (pas de PMGRE separe) --- }
Function GreFn(F : LongInt) : LongInt;
Begin
  GreLastFn := F;
  SetErr(PMERR_INVALID_FUNCTION);
  GreFn := 0;
End;

Function EnablePMPre : LongInt;
Begin
  EnablePMPre := 1;
End;

Function GreInitialize : LongInt;
Begin
  GreInitialize := 1;
End;

{ InnerGreEntry(ulFunction) }
Function InnerGreEntry(F : LongInt) : LongInt;
Begin
  InnerGreEntry := GreFn(F);
End;

{ --- informations des pilotes : (hdc, index) -> valeur --- }
Function DrvSlot(Key, Idx : LongInt; Create : Boolean) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxDrv - 1 DownTo 0 Do
    If (DvKey[I] = Key) And (DvIdx[I] = Idx) And ((DvKey[I] <> 0) Or (DvIdx[I] <> 0)) Then F := I;
  If (F < 0) And Create Then
    For I := MaxDrv - 1 DownTo 0 Do
      If (DvKey[I] = 0) And (DvIdx[I] = 0) Then F := I;
  DrvSlot := F;
End;

{ SetDriverInfo(hdc, ulIndex, ulValue, fl) : BOOL }
Function SetDriverInfo(Hdc, Idx, V, Fl : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := DrvSlot(Hdc Or $80000000, Idx, True);
  If I < 0 Then SetDriverInfo := 0
  Else
  Begin
    DvKey[I] := Hdc Or $80000000; DvIdx[I] := Idx; DvVal[I] := V;
    SetDriverInfo := 1;
  End;
End;

{ GetDriverInfo(hdc, ulIndex, fl) : valeur (0 : aucune) }
Function GetDriverInfo(Hdc, Idx, Fl : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := DrvSlot(Hdc Or $80000000, Idx, False);
  If I < 0 Then GetDriverInfo := 0 Else GetDriverInfo := DvVal[I];
End;

{ PostDeviceModes(pDrivData, pszDriverName, pszDeviceName, pszName, fl) :
  DevPostDeviceModes de PMGPI.DLL }
Function PostDeviceModes(PDrv, PDriver, PDevice, PName, Fl : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := GpiProc('DevPostDeviceModes');
  If F = 0 Then PostDeviceModes := -1
  Else PostDeviceModes := CallSys6(F, 0, PDrv, PDriver, PDevice, PName, Fl);
End;

{ PostEscape32(hdc, lCode, lInCount, pbInData, plOutCount, pbOutData) :
  DevEscape de PMGPI.DLL }
Function PostEscape32(Hdc, Code, InCnt, PIn, POutCnt, POut : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := GpiProc('DevEscape');
  If F = 0 Then PostEscape32 := 0 Else PostEscape32 := CallSys6(F, Hdc, Code, InCnt, PIn, POutCnt, POut);
End;

{ BitmapLimitWarning(cx, cy) : pas de limite }
Function BitmapLimitWarning(Cx, Cy : LongInt) : LongInt;
Begin
  BitmapLimitWarning := 0;
End;

{ DeleteBitmap16Call(hbm) : GpiDeleteBitmap }
Function DeleteBitmap16Call(Hbm : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := GpiProc('GpiDeleteBitmap');
  If F = 0 Then DeleteBitmap16Call := 0 Else DeleteBitmap16Call := CallSys6(F, Hbm, 0, 0, 0, 0, 0);
End;

{ SetDeviceSurface(hdc, pSurface) }
Function SetDeviceSurface(Hdc, P : LongInt) : LongInt;
Begin
  SetDeviceSurface := 1;
End;

{ --- code 16 bits (absent d'OS/2-0) --- }
Function Devmode_Call_16(P : LongInt) : LongInt;
Begin
  Devmode_Call_16 := 0;
End;

Function Devname_Call_16(P : LongInt) : LongInt;
Begin
  Devname_Call_16 := 0;
End;

Function Enable_Call_16(P : LongInt) : LongInt;
Begin
  Enable_Call_16 := 0;
End;

Function GRE16Callback(P : LongInt) : LongInt;
Begin
  GRE16Callback := 0;
End;

Function GRE16CallForwardReturn(P : LongInt) : LongInt;
Begin
  GRE16CallForwardReturn := 0;
End;

Function Dispatch32Gate(P : LongInt) : LongInt;
Begin
  Dispatch32Gate := 0;
End;

Function FirePSProbe(P : LongInt) : LongInt;
Begin
  FirePSProbe := 0;
End;

Function Far32LockupHook(P : LongInt) : LongInt;
Begin
  Far32LockupHook := 0;
End;

Function FarFlushBufHook(P : LongInt) : LongInt;
Begin
  FarFlushBufHook := 0;
End;

Function ThkDos16SetFgnd(Pid : LongInt) : LongInt;
Begin
  ThkDos16SetFgnd := 0;
End;

{ Do16CLI / Do16STI : masquer et autoriser les interruptions }
Function Do16CLI : LongInt;
Begin
  asm
    cli
  end;
  Do16CLI := 0;
End;

Function Do16STI : LongInt;
Begin
  asm
    sti
  end;
  Do16STI := 0;
End;

{ TidCurrent : processus leger courant (un seul par processus) }
Function TidCurrent : LongInt;
Begin
  TidCurrent := 1;
End;

{ --- memoire (segments d'OS/2 1.x : blocs de DosAllocMem) --- }
{ SSAllocSeg(cbSize, pSel, fsAlloc) : *pSel = adresse du bloc }
Function SSAllocSeg(Cb, PSel, Fl : LongInt) : LongInt;
Var P, R : LongInt;
Begin
  Cb := Cb And $FFFF;
  If Cb = 0 Then Cb := 65536;
  P := 0;
  R := DcAllocMem(LongInt(@P), Cb, $13);
  If (R = 0) And (PSel <> 0) Then WrL(PSel, P);
  SSAllocSeg := R;
End;

{ SSAllocHuge(cSegs, cbLast, pSel, cMaxSegs, fsAlloc) }
Function SSAllocHuge(NSeg, CbLast, PSel, MaxSeg, Fl : LongInt) : LongInt;
Var P, R : LongInt;
Begin
  P := 0;
  R := DcAllocMem(LongInt(@P), NSeg * 65536 + (CbLast And $FFFF) + 1, $13);
  If (R = 0) And (PSel <> 0) Then WrL(PSel, P);
  SSAllocHuge := R;
End;

Function SSFreeSeg(Sel : LongInt) : LongInt;
Begin
  SSFreeSeg := DcFreeMem(Sel);
End;

Function SSFlushSegs : LongInt;
Begin
  SSFlushSegs := 0;
End;

{ SSAllocMem(ppb, cb, flag) / SSFreeMem(pb) }
Function SSAllocMem(PPb, Cb, Fl : LongInt) : LongInt;
Begin
  SSAllocMem := DcAllocMem(PPb, Cb, $13);
End;

Function SSFreeMem(Pb : LongInt) : LongInt;
Begin
  SSFreeMem := DcFreeMem(Pb);
End;

{ --- semaphores en memoire : LongInt (0 libre, sinon processus) --- }
{ RamSemRequest32(psem, ulTimeout) : 0 ou ERROR_SEM_TIMEOUT (121) }
Function RamSemRequest32(PSem, T : LongInt) : LongInt;
Var T0, V : LongInt;
Begin
  RamSemRequest32 := 0;
  If PSem = 0 Then
  Begin
    RamSemRequest32 := 87;
    Exit;
  End;
  T0 := KGetTickCount;
  While True Do
  Begin
    V := RdL(PSem);
    If (V = 0) Or (V = MyPid) Or Not Alive(V) Then
    Begin
      WrL(PSem, MyPid);
      Exit;
    End;
    If (T <> -1) And (KGetTickCount - T0 >= T) Then
    Begin
      RamSemRequest32 := 121;
      Exit;
    End;
    Dummy := DcSleep(10);
  End;
End;

Function RamSemClear32(PSem : LongInt) : LongInt;
Begin
  If PSem <> 0 Then WrL(PSem, 0);
  RamSemClear32 := 0;
End;

{ PMRequestMutexSem(hmtx, ulTimeout) / PMReleaseMutexSem(hmtx) }
Function PMRequestMutexSem(H, T : LongInt) : LongInt;
Begin
  PMRequestMutexSem := DcRequestMutexSem(H, T);
End;

Function PMRequestMutexSemSetWait(H, T : LongInt) : LongInt;
Begin
  PMRequestMutexSemSetWait := DcRequestMutexSem(H, T);
End;

Function PMReleaseMutexSem(H : LongInt) : LongInt;
Begin
  PMReleaseMutexSem := DcReleaseMutexSem(H);
End;

{ Win32SemEnterTimeout(ulTimeout) }
Function Win32SemEnterTimeout(T : LongInt) : LongInt;
Begin
  Win32SemEnterTimeout := X_WinSemEnter;
End;

{ --- champ de saisie (Edit*) : hwnd d'un champ de saisie de PMWIN --- }
Function EditFirst(H : LongInt) : LongInt;
Begin
  EditFirst := X_WinSendMsg(H, EM_QUERYFIRSTCHAR, 0, 0);
End;

{ EDITAllocSpace(hwnd, cb) : bloc de memoire partagee }
Function EDITAllocSpace(H, Cb : LongInt) : LongInt;
Begin
  EDITAllocSpace := MemAlloc(Cb);
End;

{ EditAutoSize(hwnd) : largeur ajustee au texte }
Function EditAutoSize(H : LongInt) : LongInt;
Var R : Array[0..3] Of LongInt;
Begin
  Dummy := X_WinQueryWindowRect(H, LongInt(@R));
  EditAutoSize := X_WinSetWindowPos(H, 0, 0, 0, (X_WinQueryWindowTextLength(H) + 1) * 8 + 6, R[3] - R[1], 1);
End;

Function EditBackSpace(H : LongInt) : LongInt;
Begin
  EditBackSpace := X_WinSendMsg(H, WM_CHAR, KC_VIRTUALKEY, VK_BACKSPACE Shl 16);
End;

{ EditChangeFocus(hwnd, fFocus) }
Function EditChangeFocus(H, F : LongInt) : LongInt;
Begin
  If F <> 0 Then EditChangeFocus := X_WinSetFocus(1, H) Else EditChangeFocus := 1;
End;

{ EditChangeSelection(hwnd, ichStart, ichEnd) }
Function EditChangeSelection(H, S, E : LongInt) : LongInt;
Begin
  EditChangeSelection := X_WinSendMsg(H, EM_SETSEL, Mk2(S, E), 0);
End;

{ EditChar(hwnd, ch) : caractere tape }
Function EditChar(H, Ch : LongInt) : LongInt;
Begin
  EditChar := X_WinSendMsg(H, WM_CHAR, KC_CHAR, Ch And $FFFF);
End;

Function EditCheckScroll(H : LongInt) : LongInt;
Begin
  EditCheckScroll := X_WinInvalidateRect(H, 0, 0);
End;

Function EditClear(H : LongInt) : LongInt;
Begin
  EditClear := X_WinSendMsg(H, EM_CLEAR, 0, 0);
End;

Function EditCopy(H : LongInt) : LongInt;
Begin
  EditCopy := X_WinSendMsg(H, EM_COPY, 0, 0);
End;

Function EditCut(H : LongInt) : LongInt;
Begin
  EditCut := X_WinSendMsg(H, EM_CUT, 0, 0);
End;

Function EditPaste(H : LongInt) : LongInt;
Begin
  EditPaste := X_WinSendMsg(H, EM_PASTE, 0, 0);
End;

{ EditCreate(hwndParent, x, y, cx, cy, id) : HWND d'un champ de saisie }
Function EditCreate(HPar, X, Y, Cx, Cy, Id : LongInt) : LongInt;
Begin
  WrB(LongInt(@NameZ2), 0);
  EditCreate := X_WinCreateWindow(HPar, $FFFF0006, LongInt(@NameZ2), $80000000, X, Y, Cx, Cy, HPar, 3, Id, 0, 0);
End;

{ EditCreatePassword(hwndParent, x, y, cx, cy, id) : texte cache }
Function EditCreatePassword(HPar, X, Y, Cx, Cy, Id : LongInt) : LongInt;
Begin
  WrB(LongInt(@NameZ2), 0);
  EditCreatePassword := X_WinCreateWindow(HPar, $FFFF0006, LongInt(@NameZ2), $80000000 Or ES_UNREADABLE, X, Y, Cx, Cy,
                                          HPar, 3, Id, 0, 0);
End;

{ EditCreateCursor(hwnd) : le champ recoit le focus (curseur) }
Function EditCreateCursor(H : LongInt) : LongInt;
Begin
  EditCreateCursor := X_WinSetFocus(1, H);
End;

{ EditCXFromICH(hwnd, ich) : position x du caractere (police 8 pels) }
Function EditCXFromICH(H, Ich : LongInt) : LongInt;
Begin
  EditCXFromICH := (Ich - EditFirst(H)) * 8;
End;

{ EditICHFromPt(hwnd, x, y) : caractere sous le point }
Function EditICHFromPt(H, X, Y : LongInt) : LongInt;
Begin
  EditICHFromPt := MinI(EditFirst(H) + MaxI(X, 0) Div 8, X_WinQueryWindowTextLength(H));
End;

{ EditPtFromICH(hwnd, ich, pptl) }
Function EditPtFromICH(H, Ich, P : LongInt) : LongInt;
Begin
  EditPtFromICH := 0;
  If P = 0 Then Exit;
  WrL(P, (Ich - EditFirst(H)) * 8); WrL(P + 4, 0);
  EditPtFromICH := 1;
End;

{ EditDrawSubString(hps, pchText, ich, cch, x, y) }
Function EditDrawSubString(Hps, P, Ich, Cch, X, Y : LongInt) : LongInt;
Var R : Array[0..3] Of LongInt;
Begin
  R[0] := X; R[1] := Y; R[2] := X + Cch * 8; R[3] := Y + 16;
  EditDrawSubString := X_WinDrawText(Hps, Cch, P + Ich, LongInt(@R), -1, -2, 0);
End;

Function EditGetFlags(H : LongInt) : LongInt;
Begin
  EditGetFlags := X_WinQueryWindowULong(H, QWL_STYLE);
End;

Function EditGetWindowRect(H, P : LongInt) : LongInt;
Begin
  EditGetWindowRect := X_WinQueryWindowRect(H, P);
End;

{ EditNotify(hwnd, usCode) : WM_CONTROL au proprietaire }
Function EditNotify(H, Code : LongInt) : LongInt;
Begin
  EditNotify := X_WinSendMsg(X_WinQueryWindow(H, 4), WM_CONTROL, Mk2(X_WinQueryWindowUShort(H, -1), Code), H);
End;

Function EditPaint(H : LongInt) : LongInt;
Begin
  Dummy := X_WinInvalidateRect(H, 0, 0);
  EditPaint := X_WinUpdateWindow(H);
End;

Function EditShowChange(H : LongInt) : LongInt;
Begin
  EditShowChange := X_WinInvalidateRect(H, 0, 0);
End;

{ EditQueryPresParams(hwnd, idAttr, pBuf, cb) }
Function EditQueryPresParams(H, Id, P, Cb : LongInt) : LongInt;
Begin
  EditQueryPresParams := X_WinQueryPresParam(H, Id, 0, 0, Cb, P, 0);
End;

{ EditReplace(hwnd, pszText) : remplacer la selection }
Function EditReplace(H, P : LongInt) : LongInt;
Var Sel, A, B, N : LongInt; S, T : String;
Begin
  Sel := X_WinSendMsg(H, EM_QUERYSEL, 0, 0);
  A := MinI(Sel And $FFFF, Sel Shr 16); B := MaxI(Sel And $FFFF, Sel Shr 16);
  N := X_WinQueryWindowText(H, 256, LongInt(@NameZ2));
  S := GetZ(LongInt(@NameZ2));
  T := Copy(S, 1, A) + GetZ(P) + Copy(S, B + 1, 255);
  PutZ(LongInt(@NameZ2), T);
  Dummy := X_WinSetWindowText(H, LongInt(@NameZ2));
  N := A + LenZ(P);
  EditReplace := X_WinSendMsg(H, EM_SETSEL, Mk2(N, N), 0);
End;

{ EditSetCursorPos(hwnd, ich) }
Function EditSetCursorPos(H, Ich : LongInt) : LongInt;
Begin
  EditSetCursorPos := X_WinSendMsg(H, EM_SETSEL, Mk2(Ich, Ich), 0);
End;

Function EditSetFirstIndex(H, Ich : LongInt) : LongInt;
Begin
  EditSetFirstIndex := X_WinSendMsg(H, EM_SETFIRSTCHAR, Ich, 0);
End;

Function EditSetInsertMode(H, F : LongInt) : LongInt;
Begin
  EditSetInsertMode := X_WinSendMsg(H, EM_SETINSERTMODE, F, 0);
End;

Function EditSetSelection(H, S, E : LongInt) : LongInt;
Begin
  EditSetSelection := X_WinSendMsg(H, EM_SETSEL, Mk2(S, E), 0);
End;

Function EditSetText(H, P : LongInt) : LongInt;
Begin
  EditSetText := X_WinSetWindowText(H, P);
End;

Function EditSetWindowParams(H, P : LongInt) : LongInt;
Begin
  EditSetWindowParams := X_WinSendMsg(H, WM_SETWINDOWPARAMS, P, 0);
End;

Function EditStopMouseTracking(H : LongInt) : LongInt;
Begin
  EditStopMouseTracking := X_WinSetCapture(1, 0);
End;

Function EditTimerScroll(H : LongInt) : LongInt;
Begin
  EditTimerScroll := 1;
End;

{ EditTrackMouse(hwnd, x, y) : etendre la selection jusqu'au point }
Function EditTrackMouse(H, X, Y : LongInt) : LongInt;
Var Sel : LongInt;
Begin
  Sel := X_WinSendMsg(H, EM_QUERYSEL, 0, 0);
  EditTrackMouse := X_WinSendMsg(H, EM_SETSEL, Mk2(Sel And $FFFF, EditICHFromPt(H, X, Y)), 0);
End;

{ EditVirtualKey(hwnd, vk) }
Function EditVirtualKey(H, Vk : LongInt) : LongInt;
Begin
  EditVirtualKey := X_WinSendMsg(H, WM_CHAR, KC_VIRTUALKEY, Vk Shl 16);
End;

Function EditWMChar(H, Mp1, Mp2 : LongInt) : LongInt;
Begin
  EditWMChar := X_WinSendMsg(H, WM_CHAR, Mp1, Mp2);
End;

{ --- icones de Windows (non lues) --- }
Function GetIconWindowsEXE(PFile, Idx, PInfo : LongInt) : LongInt;
Begin
  GetIconWindowsEXE := 0;
End;

Function GetIconWindowsICO(PFile, PInfo : LongInt) : LongInt;
Begin
  GetIconWindowsICO := 0;
End;

{ --- procedures enregistrees --- }
Function CbAdd(Kind, P : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxCb - 1 DownTo 0 Do
    If CbUse[I] = 0 Then F := I;
  If F >= 0 Then
  Begin
    CbUse[F] := 1; CbKind[F] := Kind; CbProc[F] := P;
    CbAdd := 1;
  End
  Else CbAdd := 0;
End;

{ PMExecRegister(pfn) / PM32ExecRegister(pfn) : procedure d'execution }
Function PMExecRegister(P : LongInt) : LongInt;
Begin
  PMExecRegister := CbAdd(1, P);
End;

Function SLEC_InitPen : LongInt;
Begin
  SLEC_InitPen := 1;
End;

Function Win32RegisterPen(Hab : LongInt) : LongInt;
Begin
  Win32RegisterPen := 1;
End;

{ --- programmes et liste des taches (OS2SM.DLL) --- }
{ SWENTRY de la liste des taches qui verifie (champ Ofs = V) ; -1 }
Function SwFind(Ofs, V : LongInt; Var Hsw, Ses : LongInt) : Boolean;
Var B, N, I, E : LongInt;
Begin
  SwFind := False;
  B := MemAlloc(4 + 64 * 100);
  If B = 0 Then Exit;
  N := X_WinQuerySwitchList(0, B, 4 + 64 * 100);
  For I := 0 To MinI(N, 64) - 1 Do
  Begin
    E := B + 4 + I * 100;
    If RdL(E + 4 + Ofs) = V Then
    Begin
      Hsw := RdL(E); Ses := RdL(E + 20);
      SwFind := True;
    End;
  End;
  MemFree(B);
End;

{ WinHAPPfromPID(pid) : HAPP (1000h + session) }
Function WinHAPPfromPID(Pid : LongInt) : LongInt;
Var Hsw, Ses : LongInt;
Begin
  If SwFind(12, Pid, Hsw, Ses) Then WinHAPPfromPID := $1000 + Ses Else WinHAPPfromPID := 0;
End;

{ WinHSWITCHfromHAPP(happ) : HSWITCH }
Function WinHSWITCHfromHAPP(Happ : LongInt) : LongInt;
Var Hsw, Ses : LongInt;
Begin
  If SwFind(16, Happ - $1000, Hsw, Ses) Then WinHSWITCHfromHAPP := Hsw Else WinHSWITCHfromHAPP := 0;
End;

{ WinStartApp(hwndNotify, pDetails, pszParams, pReserved, fsOptions) :
  HAPP ; un programme de Presentation Manager demarre comme les autres }
Function WinStartApp(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt;
Var D : Array[0..17] Of LongInt;
Begin
  WinStartApp := 0;
  If PDet = 0 Then Exit;
  MemZero(LongInt(@D), 72);
  MemMove(PDet, LongInt(@D), MinI(MaxI(RdL(PDet), 16), 72));
  D[0] := 72;
  If D[1] = 3 Then D[1] := 0;
  WinStartApp := X_WinInstStartApp(HNotify, LongInt(@D), PParams, PRes, Opt);
End;

{ WinSetTitleAndIcon(pszTitle, pszIcon) / WinSetTitleAndHwndIcon(pszTitle,
  hptrIcon) : titre de la tache (l'icone est gardee) }
Function WinSetTitleAndIcon(PTitle, PIcon : LongInt) : LongInt;
Begin
  WinSetTitleAndIcon := X_WinSetTitle(PTitle);
End;

Function WinSetTitleAndHwndIcon(PTitle, Hptr : LongInt) : LongInt;
Begin
  WinSetTitleAndHwndIcon := X_WinSetTitle(PTitle);
End;

{ StartStartUpDotCmd : executer C:\STARTUP.CMD (CMD.EXE /C) s'il existe }
Function StartStartUpDotCmd : LongInt;
Var Info : Array[0..15] Of LongInt; Res : Array[0..1] Of LongInt; A : LongInt;
Begin
  StartStartUpDotCmd := 0;
  PutZ(LongInt(@NameZ), 'C:\STARTUP.CMD');
  If DcQueryPathInfo(LongInt(@NameZ), 1, LongInt(@Info), 24) <> 0 Then Exit;
  PutZ(LongInt(@NameZ2), 'CMD.EXE');
  A := LongInt(@NameZ2) + 8;
  PutZ(A, '/C C:\STARTUP.CMD');
  WrB(A + 18, 0);
  If DcExecPgm(0, 0, 0, LongInt(@NameZ2), 0, LongInt(@Res), LongInt(@NameZ2)) = 0 Then StartStartUpDotCmd := 1;
End;

Function WinCanTerminate(Hab : LongInt) : LongInt;
Begin
  WinCanTerminate := 1;
End;

Function WinInitializePL(Hab : LongInt) : LongInt;
Begin
  WinInitializePL := 1;
End;

{ WinQueryWorkplaceWindow : pas d'interpreteur Workplace Shell }
Function WinQueryWorkplaceWindow : LongInt;
Begin
  WinQueryWorkplaceWindow := 0;
End;

{ --- mode de la palette, pointeurs du systeme, region visible --- }
Function WinQueryPaletteMode : LongInt;
Begin
  WinQueryPaletteMode := PalMode;
End;

Function WinSetPaletteMode(M : LongInt) : LongInt;
Begin
  WinSetPaletteMode := PalMode;
  PalMode := M;
End;

{ Win32SetSysPointerData(hwndDesktop, iptr, pIconInfo) : ICONINFO (28
  octets) garde pour le pointeur iptr }
Function Win32SetSysPointerData(HDesk, IPtr, P : LongInt) : LongInt;
Var B : LongInt;
Begin
  Win32SetSysPointerData := 0;
  If (IPtr < 1) Or (IPtr > 63) Then Exit;
  If SysPtrData[IPtr] <> 0 Then MemFree(SysPtrData[IPtr]);
  SysPtrData[IPtr] := 0;
  If P = 0 Then
  Begin
    Win32SetSysPointerData := 1;
    Exit;
  End;
  B := MemAlloc(28);
  If B = 0 Then Exit;
  MemMove(P, B, 28);
  SysPtrData[IPtr] := B;
  Win32SetSysPointerData := 1;
End;

Function Win32QuerySysPointerData(HDesk, IPtr, P : LongInt) : LongInt;
Begin
  Win32QuerySysPointerData := 0;
  If (IPtr < 1) Or (IPtr > 63) Or (P = 0) Then Exit;
  If SysPtrData[IPtr] = 0 Then Exit;
  MemMove(SysPtrData[IPtr], P, 28);
  Win32QuerySysPointerData := 1;
End;

{ Win32QueryVisibleRegion(hwnd, hrgn) : rectangle de la fenetre ;
  RGN_RECT (2) }
Function Win32QueryVisibleRegion(H, Hrgn : LongInt) : LongInt;
Var R : Array[0..3] Of LongInt; F, Hps : LongInt;
Begin
  Win32QueryVisibleRegion := 0;
  If X_WinQueryWindowRect(H, LongInt(@R)) = 0 Then Exit;
  F := GpiProc('GpiSetRegion');
  If F = 0 Then Exit;
  Hps := X_WinGetPS(H);
  If CallSys6(F, Hps, Hrgn, 1, LongInt(@R), 0, 0) <> 0 Then Win32QueryVisibleRegion := 2;
  Dummy := X_WinReleasePS(Hps);
End;

{ Win32SetClipRegion(hps, hrgn) / Win32QueryClipRegion(hps) : PMGPI }
Function Win32SetClipRegion(Hps, Hrgn : LongInt) : LongInt;
Var F, Old : LongInt;
Begin
  F := GpiProc('GpiSetClipRegion');
  Old := 0;
  If F = 0 Then Win32SetClipRegion := -1 Else Win32SetClipRegion := CallSys6(F, Hps, Hrgn, LongInt(@Old), 0, 0, 0);
End;

Function Win32QueryClipRegion(Hps : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := GpiProc('GpiQueryClipRegion');
  If F = 0 Then Win32QueryClipRegion := 0 Else Win32QueryClipRegion := CallSys6(F, Hps, 0, 0, 0, 0, 0);
End;

{ WinAugmentPointer(hptr) : le pointeur tel quel }
Function WinAugmentPointer(Hptr : LongInt) : LongInt;
Begin
  WinAugmentPointer := Hptr;
End;

{ WinMessageBox2(hwndParent, hwndOwner, pszText, pszTitle, idWindow,
  pmb2info) : MB2INFO (cb, hIcon, cButtons, flStyle, hwndNotify, MB2D[] de
  80 octets : achText[71], idButton, flStyle) ; rend l'idButton choisi }
Function WinMessageBox2(HPar, HOwn, PText, PTitle, Id, P : LongInt) : LongInt;
Var N, Fl, R, B : LongInt;
Begin
  WinMessageBox2 := $FFFF;
  If P = 0 Then Exit;
  N := RdL(P + 8);
  If N <= 1 Then Fl := 0 Else If N = 2 Then Fl := 1 Else Fl := 5;
  Fl := Fl Or (RdL(P + 12) And $70F0);
  R := X_WinMessageBox(HPar, HOwn, PText, PTitle, Id, Fl);
  If (R = 1) Or (R = 6) Then B := 0
  Else If R = 7 Then B := 1
  Else If R = 2 Then B := MinI(N - 1, 2)
  Else B := -1;
  If (B >= 0) And (B < N) Then WinMessageBox2 := RdL(P + 20 + B * 80 + 72);
End;

{ --- tas WinXX (arena partagee) : handle 57580001h + rang --- }
Function XhIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - $57580001;
  If (I < 0) Or (I > 15) Then I := -1
  Else If XhUse[I] = 0 Then I := -1;
  XhIdx := I;
End;

{ WinXXCreateHeap(selHeapBase, cbHeap, cbGrow, cbMinDed, cbMaxDed, fOptions) }
Function WinXXCreateHeap(Sel, Cb, Grow, MinD, MaxD, Opt : LongInt) : LongInt;
Var I, F, B : LongInt;
Begin
  WinXXCreateHeap := 0;
  PfInit;
  F := -1;
  For I := 15 DownTo 0 Do
    If XhUse[I] = 0 Then F := I;
  If F < 0 Then Exit;
  If Cb < 256 Then Cb := 4096;
  B := MemAlloc(Cb);
  If B = 0 Then Exit;
  HeapInit(B, HeapSize(B));
  XhUse[F] := 1; XhBase[F] := B; XhSize[F] := HeapSize(B); XhFlags[F] := Opt;
  WinXXCreateHeap := $57580001 + F;
End;

{ WinXXCreateHeap2(selHeapBase, cbHeap, cbGrow, cbMinDed, cbMaxDed,
  fOptions) : meme tas }
Function WinXXCreateHeap2(Sel, Cb, Grow, MinD, MaxD, Opt : LongInt) : LongInt;
Begin
  WinXXCreateHeap2 := WinXXCreateHeap(Sel, Cb, Grow, MinD, MaxD, Opt);
End;

Function WinXXDestroyHeap(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := XhIdx(H);
  If I < 0 Then WinXXDestroyHeap := H
  Else
  Begin
    MemFree(XhBase[I]);
    XhUse[I] := 0;
    WinXXDestroyHeap := 0;
  End;
End;

Function WinXXAllocMem(H, Cb : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := XhIdx(H);
  If I < 0 Then WinXXAllocMem := 0 Else WinXXAllocMem := HeapAlloc(XhBase[I], XhSize[I], Cb);
End;

{ WinXXAllocFill(hHeap, cb, bFill) }
Function WinXXAllocFill(H, Cb, V : LongInt) : LongInt;
Var P, K : LongInt;
Begin
  P := WinXXAllocMem(H, Cb);
  If P <> 0 Then
    For K := 0 To Cb - 1 Do WrB(P + K, V);
  WinXXAllocFill := P;
End;

Function WinXXIsMemInHeap(H, P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := XhIdx(H);
  WinXXIsMemInHeap := 0;
  If I >= 0 Then
    If (P >= XhBase[I] + 8) And (P < XhBase[I] + XhSize[I]) Then WinXXIsMemInHeap := 1;
End;

Function PMHeapIsMemInChain(H, P : LongInt) : LongInt;
Begin
  PMHeapIsMemInChain := WinXXIsMemInHeap(H, P);
End;

{ WinXXFreeMem(hHeap, p, cb) : 0 ou p (erreur) }
Function WinXXFreeMem(H, P, Cb : LongInt) : LongInt;
Begin
  If WinXXIsMemInHeap(H, P) = 0 Then WinXXFreeMem := P
  Else
  Begin
    HeapFree(P);
    WinXXFreeMem := 0;
  End;
End;

Function WinXXQueryMemSize(H, P : LongInt) : LongInt;
Begin
  If WinXXIsMemInHeap(H, P) = 0 Then WinXXQueryMemSize := 0 Else WinXXQueryMemSize := HeapSize(P);
End;

{ WinXXReallocMem(hHeap, p, cbOld, cbNew) }
Function WinXXReallocMem(H, P, CbOld, CbNew : LongInt) : LongInt;
Var Q : LongInt;
Begin
  WinXXReallocMem := 0;
  If P = 0 Then
  Begin
    WinXXReallocMem := WinXXAllocMem(H, CbNew);
    Exit;
  End;
  If WinXXIsMemInHeap(H, P) = 0 Then Exit;
  If CbNew <= HeapSize(P) Then
  Begin
    WinXXReallocMem := P;
    Exit;
  End;
  Q := WinXXAllocMem(H, CbNew);
  If Q = 0 Then Exit;
  MemMove(P, Q, MinI(HeapSize(P), CbNew));
  HeapFree(P);
  WinXXReallocMem := Q;
End;

Function WinQueryHeapFlags(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := XhIdx(H);
  If I < 0 Then WinQueryHeapFlags := HeapFlags Else WinQueryHeapFlags := XhFlags[I];
End;

{ WinQuerySharedHeapData(p) : base, taille et plus grand bloc libre de la
  memoire partagee }
Function WinQuerySharedHeapData(P : LongInt) : LongInt;
Begin
  WinQuerySharedHeapData := 0;
  PfInit;
  If P = 0 Then Exit;
  WrL(P, LongInt(@Arena)); WrL(P + 4, ArenaSize); WrL(P + 8, HeapAvail(LongInt(@Arena), ArenaSize));
  WinQuerySharedHeapData := 1;
End;

{ WinMspInit / WinMspAlloc(cb) / WinMspFree(p) : memoire partagee }
Function WinMspInit : LongInt;
Begin
  PfInit;
  WinMspInit := 1;
End;

Function WinMspAlloc(Cb : LongInt) : LongInt;
Begin
  PfInit;
  WinMspAlloc := MemAlloc(Cb);
End;

Function WinMspFree(P : LongInt) : LongInt;
Begin
  MemFree(P);
  WinMspFree := 1;
End;

{ WinDrawTabbedText(hps, cchText, pchText, prcl, clrFore, clrBack, flCmd) :
  tabulations toutes les 8 colonnes }
Function WinDrawTabbedText(Hps, Cch, P, PRcl, Fg, Bg, Fl : LongInt) : LongInt;
Var N, J, C : LongInt;
Begin
  If Cch < 0 Then Cch := LenZ(P);
  N := 0;
  For J := 0 To Cch - 1 Do
  Begin
    C := RdB(P + J);
    If C = 9 Then
    Begin
      Repeat
        If N < 255 Then WrB(LongInt(@NameZ) + N, 32);
        Inc(N);
      Until (N Mod 8) = 0;
    End
    Else
    Begin
      If N < 255 Then WrB(LongInt(@NameZ) + N, C);
      Inc(N);
    End;
  End;
  N := MinI(N, 255);
  WrB(LongInt(@NameZ) + N, 0);
  WinDrawTabbedText := X_WinDrawText(Hps, N, LongInt(@NameZ), PRcl, Fg, Bg, Fl);
End;

{ --- zone du pointeur, zone de travail du bureau --- }
Function Win32SetPointerClipRect(HDesk, P : LongInt) : LongInt;
Begin
  If P = 0 Then ClipSet := 0
  Else
  Begin
    ClipX1 := RdL(P); ClipY1 := RdL(P + 4); ClipX2 := RdL(P + 8); ClipY2 := RdL(P + 12);
    ClipSet := 1;
  End;
  Win32SetPointerClipRect := 1;
End;

Function Win32QueryPointerClipRect(HDesk, P : LongInt) : LongInt;
Begin
  Win32QueryPointerClipRect := 0;
  If P = 0 Then Exit;
  If ClipSet <> 0 Then
  Begin
    WrL(P, ClipX1); WrL(P + 4, ClipY1); WrL(P + 8, ClipX2); WrL(P + 12, ClipY2);
  End
  Else
  Begin
    WrL(P, 0); WrL(P + 4, 0); WrL(P + 8, X_WinQuerySysValue(1, 20)); WrL(P + 12, X_WinQuerySysValue(1, 21));
  End;
  Win32QueryPointerClipRect := 1;
End;

Function WinSetDesktopWorkArea(HDesk, P : LongInt) : LongInt;
Begin
  If P = 0 Then WorkSet := 0
  Else
  Begin
    WorkX1 := RdL(P); WorkY1 := RdL(P + 4); WorkX2 := RdL(P + 8); WorkY2 := RdL(P + 12);
    WorkSet := 1;
  End;
  WinSetDesktopWorkArea := 1;
End;

Function WinQueryDesktopWorkArea(HDesk, P : LongInt) : LongInt;
Begin
  WinQueryDesktopWorkArea := 0;
  If P = 0 Then Exit;
  If WorkSet <> 0 Then
  Begin
    WrL(P, WorkX1); WrL(P + 4, WorkY1); WrL(P + 8, WorkX2); WrL(P + 12, WorkY2);
  End
  Else
  Begin
    WrL(P, 0); WrL(P + 4, 0); WrL(P + 8, X_WinQuerySysValue(1, 20)); WrL(P + 12, X_WinQuerySysValue(1, 21));
  End;
  WinQueryDesktopWorkArea := 1;
End;

{ Win32WaitMsgTimeout(hab, msgFirst, msgLast, ulTimeout) : 1 si un
  message arrive, 0 au bout du delai }
Function Win32WaitMsgTimeout(Hab, First, Last, T : LongInt) : LongInt;
Var T0 : LongInt;
Begin
  T0 := KGetTickCount;
  While True Do
  Begin
    If X_WinPeekMsg(Hab, LongInt(@QmBuf), 0, First, Last, 0) <> 0 Then
    Begin
      Win32WaitMsgTimeout := 1;
      Exit;
    End;
    If (T <> -1) And (KGetTickCount - T0 >= T) Then
    Begin
      Win32WaitMsgTimeout := 0;
      Exit;
    End;
    Dummy := DcSleep(10);
  End;
End;

{ Win32IsWindowOfClass(hwnd, pszClass) : BOOL }
Function Win32IsWindowOfClass(H, PCls : LongInt) : LongInt;
Var S : String;
Begin
  Win32IsWindowOfClass := 0;
  If PCls = 0 Then Exit;
  If X_WinQueryClassName(H, 64, LongInt(@NameZ2)) = 0 Then Exit;
  If (PCls And $FFFF0000) = $FFFF0000 Then S := '#' + IntStr(PCls And $FFFF) Else S := GetZ(PCls);
  If UpStr(GetZ(LongInt(@NameZ2))) = UpStr(S) Then Win32IsWindowOfClass := 1;
End;

{ --- chaine des visualiseurs du presse-papiers --- }
Function Win32AddClipbrdViewer(H : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxClipV - 1 DownTo 0 Do
    If ClipV[I] = 0 Then F := I;
  For I := 0 To MaxClipV - 1 Do
    If ClipV[I] = H Then F := -2;
  If F = -1 Then
  Begin
    Win32AddClipbrdViewer := 0;
    Exit;
  End;
  If F >= 0 Then ClipV[F] := H;
  Dummy := X_WinSetClipbrdViewer(0, H);
  Win32AddClipbrdViewer := 1;
End;

Function Win32RemoveClipbrdViewer(H : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  For I := 0 To MaxClipV - 1 Do
    If ClipV[I] = H Then
    Begin
      ClipV[I] := 0;
      R := 1;
    End;
  If X_WinQueryClipbrdViewer(0) = H Then
  Begin
    Dummy := X_WinSetClipbrdViewer(0, 0);
    For I := MaxClipV - 1 DownTo 0 Do
      If ClipV[I] <> 0 Then Dummy := X_WinSetClipbrdViewer(0, ClipV[I]);
  End;
  Win32RemoveClipbrdViewer := R;
End;

{ Win32QueryClipbrdViewerChain(phwnd, cMax) : nombre de visualiseurs }
Function Win32QueryClipbrdViewerChain(P, Max : LongInt) : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxClipV - 1 Do
    If ClipV[I] <> 0 Then
    Begin
      If (P <> 0) And (N < Max) Then WrL(P + N * 4, ClipV[I]);
      Inc(N);
    End;
  Win32QueryClipbrdViewerChain := N;
End;

{ DaxQueryOpenClipbrdWindow : proprietaire du presse-papiers }
Function DaxQueryOpenClipbrdWindow : LongInt;
Begin
  DaxQueryOpenClipbrdWindow := X_WinQueryClipbrdOwner(0);
End;

{ --- atomes --- }
{ Win32IncrementAtomUsage(hatomtbl, atom) }
Function Win32IncrementAtomUsage(Hat, A : LongInt) : LongInt;
Begin
  Win32IncrementAtomUsage := 0;
  If X_WinQueryAtomName(Hat, A, LongInt(@NameZ2), 256) = 0 Then Exit;
  Win32IncrementAtomUsage := X_WinAddAtom(Hat, LongInt(@NameZ2));
End;

{ LookupAtom(hatomtbl, pszName) }
Function LookupAtom(Hat, P : LongInt) : LongInt;
Begin
  LookupAtom := X_WinFindAtom(Hat, P);
End;

{ --- donnees DAX, langue, clavier, file de messages --- }
Function WinQueryDaxData : LongInt;
Begin
  WinQueryDaxData := DaxData;
End;

Function WinSetDaxData(V : LongInt) : LongInt;
Begin
  DaxData := V;
  WinSetDaxData := 1;
End;

Function WinSetDAXDefWndProc(P : LongInt) : LongInt;
Begin
  WinSetDAXDefWndProc := DaxDefProc;
  DaxDefProc := P;
End;

Function WinSetLangInfo(V : LongInt) : LongInt;
Begin
  LangInfo := V;
  WinSetLangInfo := 1;
End;

Function WinQueryLangInfo : LongInt;
Begin
  WinQueryLangInfo := LangInfo;
End;

{ WinSetKbdLayer(hwnd, ulLayer) / WinQueryKbdLayer(hwnd) }
Function WinSetKbdLayer(H, V : LongInt) : LongInt;
Begin
  KbdLayer := V;
  WinSetKbdLayer := 1;
End;

Function WinQueryKbdLayer(H : LongInt) : LongInt;
Begin
  WinQueryKbdLayer := KbdLayer;
End;

Function WinSetLangViewer(H : LongInt) : LongInt;
Begin
  LangViewer := H;
  WinSetLangViewer := 1;
End;

Function WinQueryLangViewer : LongInt;
Begin
  WinQueryLangViewer := LangViewer;
End;

{ WinPourEvent(hwnd, msg, mp1, mp2) : message poste }
Function WinPourEvent(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  WinPourEvent := X_WinPostMsg(H, Msg, Mp1, Mp2);
End;

Function WinSetMsgQimInfo(Hmq, V : LongInt) : LongInt;
Begin
  QimInfo := V;
  WinSetMsgQimInfo := 1;
End;

Function WinQueryMsgQimInfo(Hmq : LongInt) : LongInt;
Begin
  WinQueryMsgQimInfo := QimInfo;
End;

Function WinSetFileExtOpts(V : LongInt) : LongInt;
Begin
  FileExtOpts := V;
  WinSetFileExtOpts := 1;
End;

Function WinQueryFileExtOpts : LongInt;
Begin
  WinQueryFileExtOpts := FileExtOpts;
End;

{ Win32GetAFCValue(index) / Win32SetAFCValue(index, value) }
Function Win32SetAFCValue(Idx, V : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := DrvSlot(-1, Idx, True);
  If I < 0 Then Win32SetAFCValue := 0
  Else
  Begin
    DvKey[I] := -1; DvIdx[I] := Idx; DvVal[I] := V;
    Win32SetAFCValue := 1;
  End;
End;

Function Win32GetAFCValue(Idx : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := DrvSlot(-1, Idx, False);
  If I < 0 Then Win32GetAFCValue := 0 Else Win32GetAFCValue := DvVal[I];
End;

{ WinTrackWindow(hwndFrame, fl) : deplacer (TF_MOVE 0Fh) ou dimensionner
  le cadre au clavier }
Function WinTrackWindow(H, Fl : LongInt) : LongInt;
Begin
  If (Fl And $0F) = $0F Then WinTrackWindow := X_WinSendMsg(H, WM_SYSCOMMAND, $8001, 0)
  Else WinTrackWindow := X_WinSendMsg(H, WM_SYSCOMMAND, $8000, 0);
End;

Function Win32WaitForIdleThread(Tid, T : LongInt) : LongInt;
Begin
  Win32WaitForIdleThread := 1;
End;

{ Win32QueryActiveOtherWindow(hwnd) : fenetre active autre que hwnd }
Function Win32QueryActiveOtherWindow(H : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := X_WinQueryActiveWindow(1);
  If A = H Then Win32QueryActiveOtherWindow := 0 Else Win32QueryActiveOtherWindow := A;
End;

{ WinQueryCpType(cp) : 1 page de codes a deux octets (DBCS), 0 sinon }
Function WinQueryCpType(Cp : LongInt) : LongInt;
Begin
  If (Cp = 932) Or (Cp = 936) Or (Cp = 938) Or (Cp = 942) Or (Cp = 943) Or (Cp = 944) Or (Cp = 946) Or
     (Cp = 948) Or (Cp = 949) Or (Cp = 950) Or (Cp = 1381) Or (Cp = 1386) Then WinQueryCpType := 1
  Else WinQueryCpType := 0;
End;

{ --- couleurs des controles : CTLCOLOR (clrIndex, clrValue) ; CCI_
  FOREGROUND 1 et CCI_BACKGROUND 2 -> parametres de presentation 1 et 3 }
Function CtlPP(Idx : LongInt) : LongInt;
Begin
  Case Idx Of
    1 : CtlPP := 1;
    2 : CtlPP := 3;
    3 : CtlPP := 5;
    4 : CtlPP := 7;
  Else
    CtlPP := 0;
  End;
End;

{ CtlQueryColor(hwnd, ulIndex) : couleur RVB }
Function CtlQueryColor(H, Idx : LongInt) : LongInt;
Var V, Id : LongInt;
Begin
  Id := CtlPP(Idx);
  V := 0;
  If (Id <> 0) And (X_WinQueryPresParam(H, Id, 0, 0, 4, LongInt(@V), 0) = 4) Then CtlQueryColor := V
  Else If Idx = 2 Then CtlQueryColor := X_WinQuerySysColor(1, -20, 0)
  Else CtlQueryColor := X_WinQuerySysColor(1, -17, 0);
End;

{ WinQueryControlColors(hwnd, flType, flOptions, cctlclr, pctlclr) :
  nombre de couleurs rendues }
Function WinQueryControlColors(H, FlType, Fl, N, P : LongInt) : LongInt;
Var J : LongInt;
Begin
  For J := 0 To N - 1 Do WrL(P + J * 8 + 4, CtlQueryColor(H, RdL(P + J * 8)));
  WinQueryControlColors := MaxI(N, 0);
End;

{ WinSetControlColors(hwnd, flType, flOptions, cctlclr, pctlclr) }
Function WinSetControlColors(H, FlType, Fl, N, P : LongInt) : LongInt;
Var J, Id, V : LongInt;
Begin
  For J := 0 To N - 1 Do
  Begin
    Id := CtlPP(RdL(P + J * 8));
    V := RdL(P + J * 8 + 4);
    If Id <> 0 Then Dummy := X_WinSetPresParam(H, Id, 4, LongInt(@V));
  End;
  WinSetControlColors := MaxI(N, 0);
End;

{ --- proprietes (paires nom, valeur) des fenetres et des classes --- }
Function PrNameGet(I : LongInt) : String;
Begin
  PrNameGet := GetZ(LongInt(@PrName) + I * 32);
End;

Function PrClsGet(I : LongInt) : String;
Begin
  PrClsGet := GetZ(LongInt(@PrCls) + I * 32);
End;

{ propriete (fenetre H ou classe C) ; -1 }
Function PrFind(H : LongInt; C, N : String; Create : Boolean) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxProp - 1 DownTo 0 Do
    If (PrUse[I] <> 0) And (PrWin[I] = H) And (PrClsGet(I) = C) And (PrNameGet(I) = N) Then F := I;
  If (F < 0) And Create Then
  Begin
    For I := MaxProp - 1 DownTo 0 Do
      If PrUse[I] = 0 Then F := I;
    If F >= 0 Then
    Begin
      PrUse[F] := 1; PrWin[F] := H; PrVal[F] := 0;
      PutZ(LongInt(@PrCls) + F * 32, Copy(C, 1, 31));
      PutZ(LongInt(@PrName) + F * 32, Copy(N, 1, 31));
    End;
  End;
  PrFind := F;
End;

Function ClsKey(P : LongInt) : String;
Begin
  If (P And $FFFF0000) = $FFFF0000 Then ClsKey := '#' + IntStr(P And $FFFF)
  Else ClsKey := UpStr(GetZ(P));
End;

{ WinSetProperty(hwnd, pszName, ulValue, fl) : BOOL }
Function WinSetProperty(H, PName, V, Fl : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinSetProperty := 0;
  If (H = 0) Or (PName = 0) Then Exit;
  I := PrFind(H, '', GetZ(PName), True);
  If I < 0 Then Exit;
  PrVal[I] := V;
  WinSetProperty := 1;
End;

{ WinQueryProperty(hwnd, pszName) : valeur (0 : aucune) }
Function WinQueryProperty(H, PName : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := PrFind(H, '', GetZ(PName), False);
  If I < 0 Then WinQueryProperty := 0 Else WinQueryProperty := PrVal[I];
End;

{ WinRemoveProperty(hwnd, pszName) : valeur retiree }
Function WinRemoveProperty(H, PName : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := PrFind(H, '', GetZ(PName), False);
  If I < 0 Then WinRemoveProperty := 0
  Else
  Begin
    WinRemoveProperty := PrVal[I];
    PrUse[I] := 0;
  End;
End;

{ WinEnumProperties(hwnd, pfnEnum, ulParam) : pfn(hwnd, pszName, ulValue,
  ulParam) pour chaque propriete (arret si elle rend 0) ; derniere valeur
  rendue (-1 : aucune propriete) }
Function WinEnumProperties(H, Pfn, Prm : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1; I := 0;
  While I < MaxProp Do
  Begin
    If (PrUse[I] <> 0) And (PrWin[I] = H) And (PrClsGet(I) = '') And (Pfn <> 0) Then
    Begin
      PutZ(LongInt(@NameZ2), PrNameGet(I));
      R := Call4(Pfn, H, LongInt(@NameZ2), PrVal[I], Prm);
      If R = 0 Then I := MaxProp;
    End;
    Inc(I);
  End;
  WinEnumProperties := R;
End;

{ WinSetClassProperty(hab, pszClass, pszName, ulValue) : BOOL }
Function WinSetClassProperty(Hab, PCls, PName, V : LongInt) : LongInt;
Var I : LongInt;
Begin
  WinSetClassProperty := 0;
  If (PCls = 0) Or (PName = 0) Then Exit;
  I := PrFind(0, ClsKey(PCls), GetZ(PName), True);
  If I < 0 Then Exit;
  PrVal[I] := V;
  WinSetClassProperty := 1;
End;

Function WinQueryClassProperty(Hab, PCls, PName : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := PrFind(0, ClsKey(PCls), GetZ(PName), False);
  If I < 0 Then WinQueryClassProperty := 0 Else WinQueryClassProperty := PrVal[I];
End;

Function WinRemoveClassProperty(Hab, PCls, PName : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := PrFind(0, ClsKey(PCls), GetZ(PName), False);
  If I < 0 Then WinRemoveClassProperty := 0
  Else
  Begin
    WinRemoveClassProperty := PrVal[I];
    PrUse[I] := 0;
  End;
End;

{ WinEnumClassProperties(hab, pszClass, pfnEnum, ulParam) }
Function WinEnumClassProperties(Hab, PCls, Pfn, Prm : LongInt) : LongInt;
Var I, R : LongInt; C : String;
Begin
  R := -1; I := 0; C := ClsKey(PCls);
  While I < MaxProp Do
  Begin
    If (PrUse[I] <> 0) And (PrWin[I] = 0) And (PrClsGet(I) = C) And (Pfn <> 0) Then
    Begin
      PutZ(LongInt(@NameZ2), PrNameGet(I));
      R := Call4(Pfn, Hab, LongInt(@NameZ2), PrVal[I], Prm);
      If R = 0 Then I := MaxProp;
    End;
    Inc(I);
  End;
  WinEnumClassProperties := R;
End;

{ --- curseur de DAX (caret) --- }
{ DAXCREATECARET(hwnd, hbm, cx, cy) }
Function DAXCREATECARET(H, Hbm, Cx, Cy : LongInt) : LongInt;
Begin
  CaretWin := H;
  DAXCREATECARET := X_WinCreateCursor(H, 0, 0, Cx, Cy, 0, 0);
End;

Function DaxDestroyCaret : LongInt;
Begin
  If CaretWin <> 0 Then DaxDestroyCaret := X_WinDestroyCursor(CaretWin) Else DaxDestroyCaret := 0;
  CaretWin := 0;
End;

{ DaxHideCaret(hwnd) / DaxShowCaret(hwnd) }
Function DaxHideCaret(H : LongInt) : LongInt;
Begin
  If H = 0 Then H := CaretWin;
  DaxHideCaret := X_WinShowCursor(H, 0);
End;

Function DaxShowCaret(H : LongInt) : LongInt;
Begin
  If H = 0 Then H := CaretWin;
  DaxShowCaret := X_WinShowCursor(H, 1);
End;

{ temps de clignotement : SV_CURSORRATE (9) }
Function DaxGetCaretBlinkTime : LongInt;
Begin
  DaxGetCaretBlinkTime := X_WinQuerySysValue(1, 9);
End;

Function DaxSetCaretBlinkTime(Ms : LongInt) : LongInt;
Begin
  DaxSetCaretBlinkTime := X_WinSetSysValue(1, 9, Ms);
End;

{ DaxShowCursor(fShow) : pointeur de la souris }
Function DaxShowCursor(F : LongInt) : LongInt;
Begin
  DaxShowCursor := X_WinShowPointer(1, F);
End;

{ DaxSwapMouseButton(fSwap) : ancienne valeur de SV_SWAPBUTTON }
Function DaxSwapMouseButton(F : LongInt) : LongInt;
Begin
  DaxSwapMouseButton := X_WinQuerySysValue(1, 0);
  Dummy := X_WinSetSysValue(1, 0, F);
End;

{ DaxOpenClipbrd(hab, hwnd) }
Function DaxOpenClipbrd(Hab, H : LongInt) : LongInt;
Begin
  DaxOpenClipbrd := X_WinOpenClipbrd(Hab);
End;

{ --- divers --- }
Function InitGameFrameProc(H : LongInt) : LongInt;
Begin
  InitGameFrameProc := 1;
End;

Function GreNLS(P : LongInt) : LongInt;
Begin
  GreNLS := 0;
End;

{ ValidateDCHandle(hdc) : contexte de PMGPI (4447xxxxh) ou de fenetre de
  PMWIN (4443xxxxh) }
Function ValidateDCHandle(Hdc : LongInt) : LongInt;
Begin
  If ((Hdc Shr 16) = $4447) Or ((Hdc Shr 16) = $4443) Then ValidateDCHandle := 1 Else ValidateDCHandle := 0;
End;

Function HookMan(P : LongInt) : LongInt;
Begin
  HookMan := 0;
End;

Function CCHSetHailing(F : LongInt) : LongInt;
Begin
  CCHSetHailing := 0;
End;

Function EnableCoachMsgHook(F : LongInt) : LongInt;
Begin
  EnableCoachMsgHook := 0;
End;

Function FCallGRECoach(P : LongInt) : LongInt;
Begin
  FCallGRECoach := 0;
End;

Function GRE32CallForward(P : LongInt) : LongInt;
Begin
  GRE32CallForward := 0;
End;

{ --- donnees de Warp 4 : adresse de la donnee --- }
Function ShellWindow : LongInt;
Begin
  DataShellWindow := $00010001;
  ShellWindow := LongInt(@DataShellWindow);
End;

Function PMSemaphores : LongInt;
Begin
  PMSemaphores := LongInt(@DataPMSem);
End;

Function PHandleTable : LongInt;
Begin
  PHandleTable := LongInt(@DataHandleTable);
End;

Function PSharedHeap : LongInt;
Begin
  PfInit;
  DataSharedHeap := LongInt(@Arena);
  PSharedHeap := LongInt(@DataSharedHeap);
End;

Function GreMemptrs : LongInt;
Begin
  GreMemptrs := LongInt(@DataGreMem);
End;

Function FPen : LongInt;
Begin
  FPen := LongInt(@DataFPen);
End;

{ VPAULDefaultColors : couleurs du systeme SYSCLR_* (-1 a -31 ; RVB) }
Function VPAULDefaultColors : LongInt;
Var I : LongInt;
Begin
  For I := 1 To 31 Do DataColors[I] := X_WinQuerySysColor(1, -I, 0);
  VPAULDefaultColors := LongInt(@DataColors);
End;

{ --- entrees du moteur graphique et du code 16 bits --- }
Function Dispatch16Gate10(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10 : LongInt) : LongInt;
Begin
  Dispatch16Gate10 := 0;
End;

Function Dispatch16Gate3(A1, A2, A3 : LongInt) : LongInt;
Begin
  Dispatch16Gate3 := 0;
End;

Function Dispatch16Gate4(A1, A2, A3, A4 : LongInt) : LongInt;
Begin
  Dispatch16Gate4 := 0;
End;

Function Dispatch16Gate5(A1, A2, A3, A4, A5 : LongInt) : LongInt;
Begin
  Dispatch16Gate5 := 0;
End;

Function Dispatch16Gate6(A1, A2, A3, A4, A5, A6 : LongInt) : LongInt;
Begin
  Dispatch16Gate6 := 0;
End;

Function Dispatch16Gate7(A1, A2, A3, A4, A5, A6, A7 : LongInt) : LongInt;
Begin
  Dispatch16Gate7 := 0;
End;

Function Dispatch16Gate8(A1, A2, A3, A4, A5, A6, A7, A8 : LongInt) : LongInt;
Begin
  Dispatch16Gate8 := 0;
End;

Function Dispatch16Gate9(A1, A2, A3, A4, A5, A6, A7, A8, A9 : LongInt) : LongInt;
Begin
  Dispatch16Gate9 := 0;
End;

Function Gre32Entry10(A1, A2, A3, A4, A5, A6, A7, A8, A9, F : LongInt) : LongInt;
Begin
  Gre32Entry10 := GreFn(F);
End;

Function Gre32Entry2(A1, F : LongInt) : LongInt;
Begin
  Gre32Entry2 := GreFn(F);
End;

Function Gre32Entry3(A1, A2, F : LongInt) : LongInt;
Begin
  Gre32Entry3 := GreFn(F);
End;

Function Gre32Entry4(A1, A2, A3, F : LongInt) : LongInt;
Begin
  Gre32Entry4 := GreFn(F);
End;

Function Gre32Entry5(A1, A2, A3, A4, F : LongInt) : LongInt;
Begin
  Gre32Entry5 := GreFn(F);
End;

Function Gre32Entry6(A1, A2, A3, A4, A5, F : LongInt) : LongInt;
Begin
  Gre32Entry6 := GreFn(F);
End;

Function Gre32Entry7(A1, A2, A3, A4, A5, A6, F : LongInt) : LongInt;
Begin
  Gre32Entry7 := GreFn(F);
End;

Function Gre32Entry8(A1, A2, A3, A4, A5, A6, A7, F : LongInt) : LongInt;
Begin
  Gre32Entry8 := GreFn(F);
End;

Function Gre32Entry9(A1, A2, A3, A4, A5, A6, A7, A8, F : LongInt) : LongInt;
Begin
  Gre32Entry9 := GreFn(F);
End;

Function GreEntry10(A1, A2, A3, A4, A5, A6, A7, A8, A9, F : LongInt) : LongInt;
Begin
  GreEntry10 := GreFn(F);
End;

Function GreEntry2(A1, F : LongInt) : LongInt;
Begin
  GreEntry2 := GreFn(F);
End;

Function GreEntry3(A1, A2, F : LongInt) : LongInt;
Begin
  GreEntry3 := GreFn(F);
End;

Function GreEntry4(A1, A2, A3, F : LongInt) : LongInt;
Begin
  GreEntry4 := GreFn(F);
End;

Function GreEntry5(A1, A2, A3, A4, F : LongInt) : LongInt;
Begin
  GreEntry5 := GreFn(F);
End;

Function GreEntry6(A1, A2, A3, A4, A5, F : LongInt) : LongInt;
Begin
  GreEntry6 := GreFn(F);
End;

Function GreEntry7(A1, A2, A3, A4, A5, A6, F : LongInt) : LongInt;
Begin
  GreEntry7 := GreFn(F);
End;

Function GreEntry8(A1, A2, A3, A4, A5, A6, A7, F : LongInt) : LongInt;
Begin
  GreEntry8 := GreFn(F);
End;

Function GreEntry9(A1, A2, A3, A4, A5, A6, A7, A8, F : LongInt) : LongInt;
Begin
  GreEntry9 := GreFn(F);
End;

Function InnerGre32Entry10(A1, A2, A3, A4, A5, A6, A7, A8, A9, F : LongInt) : LongInt;
Begin
  InnerGre32Entry10 := GreFn(F);
End;

Function InnerGre32Entry2(A1, F : LongInt) : LongInt;
Begin
  InnerGre32Entry2 := GreFn(F);
End;

Function InnerGre32Entry3(A1, A2, F : LongInt) : LongInt;
Begin
  InnerGre32Entry3 := GreFn(F);
End;

Function InnerGre32Entry4(A1, A2, A3, F : LongInt) : LongInt;
Begin
  InnerGre32Entry4 := GreFn(F);
End;

Function InnerGre32Entry5(A1, A2, A3, A4, F : LongInt) : LongInt;
Begin
  InnerGre32Entry5 := GreFn(F);
End;

Function InnerGre32Entry6(A1, A2, A3, A4, A5, F : LongInt) : LongInt;
Begin
  InnerGre32Entry6 := GreFn(F);
End;

Function InnerGre32Entry7(A1, A2, A3, A4, A5, A6, F : LongInt) : LongInt;
Begin
  InnerGre32Entry7 := GreFn(F);
End;

Function InnerGre32Entry8(A1, A2, A3, A4, A5, A6, A7, F : LongInt) : LongInt;
Begin
  InnerGre32Entry8 := GreFn(F);
End;

Function InnerGre32Entry9(A1, A2, A3, A4, A5, A6, A7, A8, F : LongInt) : LongInt;
Begin
  InnerGre32Entry9 := GreFn(F);
End;

Function PFN10R2(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10 : LongInt) : LongInt;
Begin
  PFN10R2 := 0;
End;

Function PFN4R2(A1, A2, A3, A4 : LongInt) : LongInt;
Begin
  PFN4R2 := 0;
End;

Function PFN5R2(A1, A2, A3, A4, A5 : LongInt) : LongInt;
Begin
  PFN5R2 := 0;
End;

Function PFN6R2(A1, A2, A3, A4, A5, A6 : LongInt) : LongInt;
Begin
  PFN6R2 := 0;
End;

Function PFN7R2(A1, A2, A3, A4, A5, A6, A7 : LongInt) : LongInt;
Begin
  PFN7R2 := 0;
End;

Function PFN8R2(A1, A2, A3, A4, A5, A6, A7, A8 : LongInt) : LongInt;
Begin
  PFN8R2 := 0;
End;

Function PFN9R2(A1, A2, A3, A4, A5, A6, A7, A8, A9 : LongInt) : LongInt;
Begin
  PFN9R2 := 0;
End;

Function PmWinGreEntry10(A1, A2, A3, A4, A5, A6, A7, A8, A9, F : LongInt) : LongInt;
Begin
  PmWinGreEntry10 := GreFn(F);
End;

Function PmWinGreEntry2(A1, F : LongInt) : LongInt;
Begin
  PmWinGreEntry2 := GreFn(F);
End;

Function PmWinGreEntry3(A1, A2, F : LongInt) : LongInt;
Begin
  PmWinGreEntry3 := GreFn(F);
End;

Function PmWinGreEntry4(A1, A2, A3, F : LongInt) : LongInt;
Begin
  PmWinGreEntry4 := GreFn(F);
End;

Function PmWinGreEntry5(A1, A2, A3, A4, F : LongInt) : LongInt;
Begin
  PmWinGreEntry5 := GreFn(F);
End;

Function PmWinGreEntry6(A1, A2, A3, A4, A5, F : LongInt) : LongInt;
Begin
  PmWinGreEntry6 := GreFn(F);
End;

Function PmWinGreEntry7(A1, A2, A3, A4, A5, A6, F : LongInt) : LongInt;
Begin
  PmWinGreEntry7 := GreFn(F);
End;

Function PmWinGreEntry8(A1, A2, A3, A4, A5, A6, A7, F : LongInt) : LongInt;
Begin
  PmWinGreEntry8 := GreFn(F);
End;

Function PmWinGreEntry9(A1, A2, A3, A4, A5, A6, A7, A8, F : LongInt) : LongInt;
Begin
  PmWinGreEntry9 := GreFn(F);
End;


{ ==================================================================== }
{ Partie 4 - Relais vers PMWIN.DLL, OS2SM.DLL et PMGPI.DLL           }
{ ==================================================================== }

Function F_AAB32GETREG(N : LongInt) : LongInt;
Begin
  F_AAB32GETREG := X_AAB32GETREG(N);
End;

Function F_AAB32SETREG(N, V : LongInt) : LongInt;
Begin
  F_AAB32SETREG := X_AAB32SETREG(N, V);
End;

Function F_AabGetReg(N : LongInt) : LongInt;
Begin
  F_AabGetReg := X_AabGetReg(N);
End;

Function F_AabSetReg(N, V : LongInt) : LongInt;
Begin
  F_AabSetReg := X_AabSetReg(N, V);
End;

Function F_AbnormalProcessExit(Pid : LongInt) : LongInt;
Begin
  F_AbnormalProcessExit := X_AbnormalProcessExit(Pid);
End;

Function F_DEBUG32CLS : LongInt;
Begin
  F_DEBUG32CLS := X_DEBUG32CLS;
End;

Function F_DEBUG32CURPOS(Row, Col : LongInt) : LongInt;
Begin
  F_DEBUG32CURPOS := X_DEBUG32CURPOS(Row, Col);
End;

Function F_DEBUG32INPUT : LongInt;
Begin
  F_DEBUG32INPUT := X_DEBUG32INPUT;
End;

Function F_DEBUG32OUTPUT(P : LongInt) : LongInt;
Begin
  F_DEBUG32OUTPUT := X_DEBUG32OUTPUT(P);
End;

Function F_DebugCls : LongInt;
Begin
  F_DebugCls := X_DebugCls;
End;

Function F_DebugCurPos(Row, Col : LongInt) : LongInt;
Begin
  F_DebugCurPos := X_DebugCurPos(Row, Col);
End;

Function F_DebugInput : LongInt;
Begin
  F_DebugInput := X_DebugInput;
End;

Function F_DebugInputEnable(F : LongInt) : LongInt;
Begin
  F_DebugInputEnable := X_DebugInputEnable(F);
End;

Function F_DebugOutput(P : LongInt) : LongInt;
Begin
  F_DebugOutput := X_DebugOutput(P);
End;

Function F_DebugRedirect(F : LongInt) : LongInt;
Begin
  F_DebugRedirect := X_DebugRedirect(F);
End;

Function F_DestroyTimers(Hab : LongInt) : LongInt;
Begin
  F_DestroyTimers := X_DestroyTimers(Hab);
End;

Function F_DummyHelpEntry : LongInt;
Begin
  F_DummyHelpEntry := X_DummyHelpEntry;
End;

Function F_FarCallHook(Pfn, A1, A2, A3 : LongInt) : LongInt;
Begin
  F_FarCallHook := X_FarCallHook(Pfn, A1, A2, A3);
End;

Function F_FNBADAPPDLGPROC(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_FNBADAPPDLGPROC := X_FNBADAPPDLGPROC(Hwnd, Msg, Mp1, Mp2);
End;

Function F_FsrSemCheck : LongInt;
Begin
  F_FsrSemCheck := X_FsrSemCheck;
End;

Function F_FsrSemEnter : LongInt;
Begin
  F_FsrSemEnter := X_FsrSemEnter;
End;

Function F_FsrSemExit : LongInt;
Begin
  F_FsrSemExit := X_FsrSemExit;
End;

Function F_FsrSemLeave : LongInt;
Begin
  F_FsrSemLeave := X_FsrSemLeave;
End;

Function F_GetPMDDCodeSelector : LongInt;
Begin
  F_GetPMDDCodeSelector := X_GetPMDDCodeSelector;
End;

Function F_GetScreenSelector : LongInt;
Begin
  F_GetScreenSelector := X_GetScreenSelector;
End;

Function F_GpiLoadBitmap(Hps, Hmod, Id, Cx, Cy : LongInt) : LongInt;
Begin
  F_GpiLoadBitmap := X_GpiLoadBitmap(Hps, Hmod, Id, Cx, Cy);
End;

Function F_IdentifyCodeSelector(Sel : LongInt) : LongInt;
Begin
  F_IdentifyCodeSelector := X_IdentifyCodeSelector(Sel);
End;

Function F_InputGetDeviceInfo(N, P : LongInt) : LongInt;
Begin
  F_InputGetDeviceInfo := X_InputGetDeviceInfo(N, P);
End;

Function F_KbdPacket(Ch, Sc, St : LongInt) : LongInt;
Begin
  F_KbdPacket := X_KbdPacket(Ch, Sc, St);
End;

Function F_LoadModuleHandle(P : LongInt) : LongInt;
Begin
  F_LoadModuleHandle := X_LoadModuleHandle(P);
End;

Function F_LPFNICONWNDPROC(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_LPFNICONWNDPROC := X_LPFNICONWNDPROC(Hwnd, Msg, Mp1, Mp2);
End;

Function F_LPFNSHELLWNDPROC(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_LPFNSHELLWNDPROC := X_LPFNSHELLWNDPROC(Hwnd, Msg, Mp1, Mp2);
End;

Function F_OldWinQueryPointerInfo(H, P : LongInt) : LongInt;
Begin
  F_OldWinQueryPointerInfo := X_OldWinQueryPointerInfo(H, P);
End;

Function F_SHEINITIALIZEINIFILE(PIni : LongInt) : LongInt;
Begin
  F_SHEINITIALIZEINIFILE := X_SHEINITIALIZEINIFILE(PIni);
End;

Function F_SHESTARTLONGPROGRAM(PProg, PParams, PTitle, Bg, PSid : LongInt) : LongInt;
Begin
  F_SHESTARTLONGPROGRAM := X_SHESTARTLONGPROGRAM(PProg, PParams, PTitle, Bg, PSid);
End;

Function F_SHESYSTEMSHUTDOWN(Fl : LongInt) : LongInt;
Begin
  F_SHESYSTEMSHUTDOWN := X_SHESYSTEMSHUTDOWN(Fl);
End;

Function F_SHLLOADPUBLICFONTS(PIni : LongInt) : LongInt;
Begin
  F_SHLLOADPUBLICFONTS := X_SHLLOADPUBLICFONTS(PIni);
End;

Function F_SHLUNLOADPUBLICFONTS : LongInt;
Begin
  F_SHLUNLOADPUBLICFONTS := X_SHLUNLOADPUBLICFONTS;
End;

Function F_STARTSYSTEMEXECUTABLES(PIni : LongInt) : LongInt;
Begin
  F_STARTSYSTEMEXECUTABLES := X_STARTSYSTEMEXECUTABLES(PIni);
End;

Function F_StartTimer(Hab, H, Id, Dt : LongInt) : LongInt;
Begin
  F_StartTimer := X_StartTimer(Hab, H, Id, Dt);
End;

Function F_ValidateSelector(Sel : LongInt) : LongInt;
Begin
  F_ValidateSelector := X_ValidateSelector(Sel);
End;

Function F_WIN32DEBUGBREAK : LongInt;
Begin
  F_WIN32DEBUGBREAK := X_WIN32DEBUGBREAK;
End;

Function F_WinAddAtom(H, P : LongInt) : LongInt;
Begin
  F_WinAddAtom := X_WinAddAtom(H, P);
End;

Function F_WINADDSWITCHENTRY(P : LongInt) : LongInt;
Begin
  F_WINADDSWITCHENTRY := X_WINADDSWITCHENTRY(P);
End;

Function F_WinAlarm(HDesk, Typ : LongInt) : LongInt;
Begin
  F_WinAlarm := X_WinAlarm(HDesk, Typ);
End;

Function F_WinAllocFarMem(H, Cb : LongInt) : LongInt;
Begin
  F_WinAllocFarMem := X_WinAllocFarMem(H, Cb);
End;

Function F_WinAllocMem(H, Cb : LongInt) : LongInt;
Begin
  F_WinAllocMem := X_WinAllocMem(H, Cb);
End;

Function F_WinAssociateHelpInstance(HHelp, HApp : LongInt) : LongInt;
Begin
  F_WinAssociateHelpInstance := X_WinAssociateHelpInstance(HHelp, HApp);
End;

Function F_WinAvailMem(H, FCompact, CbMin : LongInt) : LongInt;
Begin
  F_WinAvailMem := X_WinAvailMem(H, FCompact, CbMin);
End;

Function F_WinBeginEnumWindows(H : LongInt) : LongInt;
Begin
  F_WinBeginEnumWindows := X_WinBeginEnumWindows(H);
End;

Function F_WinBeginPaint(H, Hps, PRcl : LongInt) : LongInt;
Begin
  F_WinBeginPaint := X_WinBeginPaint(H, Hps, PRcl);
End;

Function F_WinBroadcastMsg(HPar, Msg, Mp1, Mp2, Rgf : LongInt) : LongInt;
Begin
  F_WinBroadcastMsg := X_WinBroadcastMsg(HPar, Msg, Mp1, Mp2, Rgf);
End;

Function F_WinBuildPtrHandle(P : LongInt) : LongInt;
Begin
  F_WinBuildPtrHandle := X_WinBuildPtrHandle(P);
End;

Function F_WinCalcFrameRect(H, P, FClient : LongInt) : LongInt;
Begin
  F_WinCalcFrameRect := X_WinCalcFrameRect(H, P, FClient);
End;

Function F_WinCallHelpHook(Hab, Mode, Topic, Sub, PRc : LongInt) : LongInt;
Begin
  F_WinCallHelpHook := X_WinCallHelpHook(Hab, Mode, Topic, Sub, PRc);
End;

Function F_WinCallMsgFilter(Hab, P, Msgf : LongInt) : LongInt;
Begin
  F_WinCallMsgFilter := X_WinCallMsgFilter(Hab, P, Msgf);
End;

Function F_WinCancelMode(HDesk : LongInt) : LongInt;
Begin
  F_WinCancelMode := X_WinCancelMode(HDesk);
End;

Function F_WinCancelShutdown(Hmq, FAlways : LongInt) : LongInt;
Begin
  F_WinCancelShutdown := X_WinCancelShutdown(Hmq, FAlways);
End;

Function F_WinCatch(P : LongInt) : LongInt;
Begin
  F_WinCatch := X_WinCatch(P);
End;

Function F_WINCHANGESWITCHENTRY(H, P : LongInt) : LongInt;
Begin
  F_WINCHANGESWITCHENTRY := X_WINCHANGESWITCHENTRY(H, P);
End;

Function F_WinCheckInput(Hab : LongInt) : LongInt;
Begin
  F_WinCheckInput := X_WinCheckInput(Hab);
End;

Function F_WinCloseClipbrd(Hab : LongInt) : LongInt;
Begin
  F_WinCloseClipbrd := X_WinCloseClipbrd(Hab);
End;

Function F_WinCompareStrings(Hab, Cp, Cc, P1, P2, Rsvd : LongInt) : LongInt;
Begin
  F_WinCompareStrings := X_WinCompareStrings(Hab, Cp, Cc, P1, P2, Rsvd);
End;

Function F_WinCopyAccelTable(H, P, Cb : LongInt) : LongInt;
Begin
  F_WinCopyAccelTable := X_WinCopyAccelTable(H, P, Cb);
End;

Function F_WinCopyRect(Hab, PD, PS : LongInt) : LongInt;
Begin
  F_WinCopyRect := X_WinCopyRect(Hab, PD, PS);
End;

Function F_WINCPLREGISTER(PName : LongInt) : LongInt;
Begin
  F_WINCPLREGISTER := X_WINCPLREGISTER(PName);
End;

Function F_WinCpTranslateChar(Hab, CpS, C, CpD : LongInt) : LongInt;
Begin
  F_WinCpTranslateChar := X_WinCpTranslateChar(Hab, CpS, C, CpD);
End;

Function F_WinCpTranslateString(Hab, CpS, PSrc, CpD, Cch, PDst : LongInt) : LongInt;
Begin
  F_WinCpTranslateString := X_WinCpTranslateString(Hab, CpS, PSrc, CpD, Cch, PDst);
End;

Function F_WinCreateAccelTable(Hab, P : LongInt) : LongInt;
Begin
  F_WinCreateAccelTable := X_WinCreateAccelTable(Hab, P);
End;

Function F_WinCreateAtomTable(CbInit, CBuckets : LongInt) : LongInt;
Begin
  F_WinCreateAtomTable := X_WinCreateAtomTable(CbInit, CBuckets);
End;

Function F_WinCreateCursor(H, X, Y, Cx, Cy, Fs, PClip : LongInt) : LongInt;
Begin
  F_WinCreateCursor := X_WinCreateCursor(H, X, Y, Cx, Cy, Fs, PClip);
End;

Function F_WinCreateDlg(HPar, HOwn, Proc, T, PCreate : LongInt) : LongInt;
Begin
  F_WinCreateDlg := X_WinCreateDlg(HPar, HOwn, Proc, T, PCreate);
End;

Function F_WinCreateFarHeap(Hab, Cb : LongInt) : LongInt;
Begin
  F_WinCreateFarHeap := X_WinCreateFarHeap(Hab, Cb);
End;

Function F_WinCreateFrameControls(H, P, PTitle : LongInt) : LongInt;
Begin
  F_WinCreateFrameControls := X_WinCreateFrameControls(H, P, PTitle);
End;

Function F_WinCreateHeap(Sel, Cb, Grow, MinD, MaxD, Opt : LongInt) : LongInt;
Begin
  F_WinCreateHeap := X_WinCreateHeap(Sel, Cb, Grow, MinD, MaxD, Opt);
End;

Function F_WinCreateHelpInstance(Hab, P : LongInt) : LongInt;
Begin
  F_WinCreateHelpInstance := X_WinCreateHelpInstance(Hab, P);
End;

Function F_WinCreateHelpTable(HHelp, P : LongInt) : LongInt;
Begin
  F_WinCreateHelpTable := X_WinCreateHelpTable(HHelp, P);
End;

Function F_WinCreateMenu(HPar, P : LongInt) : LongInt;
Begin
  F_WinCreateMenu := X_WinCreateMenu(HPar, P);
End;

Function F_WinCreateMsgQueue(Hab, N : LongInt) : LongInt;
Begin
  F_WinCreateMsgQueue := X_WinCreateMsgQueue(Hab, N);
End;

Function F_WinCreatePointer(HDesk, Hbm, FPtr, HotX, HotY : LongInt) : LongInt;
Begin
  F_WinCreatePointer := X_WinCreatePointer(HDesk, Hbm, FPtr, HotX, HotY);
End;

Function F_WinCreatePointerIndirect(HDesk, P : LongInt) : LongInt;
Begin
  F_WinCreatePointerIndirect := X_WinCreatePointerIndirect(HDesk, P);
End;

Function F_WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, IdRes, PClient : LongInt) : LongInt;
Begin
  F_WinCreateStdWindow := X_WinCreateStdWindow(HPar, Style, PFl, PCls, PTitle, CStyle, Hmod, IdRes, PClient);
End;

Function F_WINCREATESWITCHENTRY(Hab, P : LongInt) : LongInt;
Begin
  F_WINCREATESWITCHENTRY := X_WINCREATESWITCHENTRY(Hab, P);
End;

Function F_WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt;
Begin
  F_WinCreateWindow := X_WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres);
End;

Function F_WinDdeInitiate(HClient, PApp, PTopic, PCtx : LongInt) : LongInt;
Begin
  F_WinDdeInitiate := X_WinDdeInitiate(HClient, PApp, PTopic, PCtx);
End;

Function F_WinDdePostMsg(HTo, HFrom, Msg, P, Fl : LongInt) : LongInt;
Begin
  F_WinDdePostMsg := X_WinDdePostMsg(HTo, HFrom, Msg, P, Fl);
End;

Function F_WinDdeRespond(HClient, HServer, PApp, PTopic, PCtx : LongInt) : LongInt;
Begin
  F_WinDdeRespond := X_WinDdeRespond(HClient, HServer, PApp, PTopic, PCtx);
End;

Function F_WinDebugBreak : LongInt;
Begin
  F_WinDebugBreak := X_WinDebugBreak;
End;

Function F_WinDefDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinDefDlgProc := X_WinDefDlgProc(H, Msg, Mp1, Mp2);
End;

Function F_WinDefQueueProc(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinDefQueueProc := X_WinDefQueueProc(Hmq, Msg, Mp1, Mp2);
End;

Function F_WinDefWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinDefWindowProc := X_WinDefWindowProc(H, Msg, Mp1, Mp2);
End;

Function F_WinDeleteAtom(H, A : LongInt) : LongInt;
Begin
  F_WinDeleteAtom := X_WinDeleteAtom(H, A);
End;

Function F_WinDeleteLibrary(Hab, H : LongInt) : LongInt;
Begin
  F_WinDeleteLibrary := X_WinDeleteLibrary(Hab, H);
End;

Function F_WinDeleteProcedure(Hab, Pfn : LongInt) : LongInt;
Begin
  F_WinDeleteProcedure := X_WinDeleteProcedure(Hab, Pfn);
End;

Function F_WinDestoryFarHeap(H : LongInt) : LongInt;
Begin
  F_WinDestoryFarHeap := X_WinDestoryFarHeap(H);
End;

Function F_WinDestroyAccelTable(H : LongInt) : LongInt;
Begin
  F_WinDestroyAccelTable := X_WinDestroyAccelTable(H);
End;

Function F_WinDestroyAniPointer(H : LongInt) : LongInt;
Begin
  F_WinDestroyAniPointer := X_WinDestroyAniPointer(H);
End;

Function F_WinDestroyAtomTable(H : LongInt) : LongInt;
Begin
  F_WinDestroyAtomTable := X_WinDestroyAtomTable(H);
End;

Function F_WinDestroyCursor(H : LongInt) : LongInt;
Begin
  F_WinDestroyCursor := X_WinDestroyCursor(H);
End;

Function F_WinDestroyHeap(H : LongInt) : LongInt;
Begin
  F_WinDestroyHeap := X_WinDestroyHeap(H);
End;

Function F_WinDestroyHelpInstance(H : LongInt) : LongInt;
Begin
  F_WinDestroyHelpInstance := X_WinDestroyHelpInstance(H);
End;

Function F_WinDestroyMsgQueue(H : LongInt) : LongInt;
Begin
  F_WinDestroyMsgQueue := X_WinDestroyMsgQueue(H);
End;

Function F_WinDestroyPointer(H : LongInt) : LongInt;
Begin
  F_WinDestroyPointer := X_WinDestroyPointer(H);
End;

Function F_WinDestroyWindow(H : LongInt) : LongInt;
Begin
  F_WinDestroyWindow := X_WinDestroyWindow(H);
End;

Function F_WinDismissDlg(H, R : LongInt) : LongInt;
Begin
  F_WinDismissDlg := X_WinDismissDlg(H, R);
End;

Function F_WinDispatchMsg(Hab, P : LongInt) : LongInt;
Begin
  F_WinDispatchMsg := X_WinDispatchMsg(Hab, P);
End;

Function F_WinDlgBox(HPar, HOwn, Proc, Hmod, Id, PCreate : LongInt) : LongInt;
Begin
  F_WinDlgBox := X_WinDlgBox(HPar, HOwn, Proc, Hmod, Id, PCreate);
End;

Function F_WinDrawBitmap(Hps, Hbm, PSrc, PDst, Fg, Bg, Fl : LongInt) : LongInt;
Begin
  F_WinDrawBitmap := X_WinDrawBitmap(Hps, Hbm, PSrc, PDst, Fg, Bg, Fl);
End;

Function F_WinDrawBorder(Hps, P, Cx, Cy, Fg, Bg, Fl : LongInt) : LongInt;
Begin
  F_WinDrawBorder := X_WinDrawBorder(Hps, P, Cx, Cy, Fg, Bg, Fl);
End;

Function F_WinDrawPointer(Hps, X, Y, H, Fs : LongInt) : LongInt;
Begin
  F_WinDrawPointer := X_WinDrawPointer(Hps, X, Y, H, Fs);
End;

Function F_WinDrawText(Hps, Cch, P, PRcl, Fg, Bg, Fl : LongInt) : LongInt;
Begin
  F_WinDrawText := X_WinDrawText(Hps, Cch, P, PRcl, Fg, Bg, Fl);
End;

Function F_WinEmptyClipbrd(Hab : LongInt) : LongInt;
Begin
  F_WinEmptyClipbrd := X_WinEmptyClipbrd(Hab);
End;

Function F_WinEnablePhysInput(HDesk, En : LongInt) : LongInt;
Begin
  F_WinEnablePhysInput := X_WinEnablePhysInput(HDesk, En);
End;

Function F_WinEnableWindow(H, En : LongInt) : LongInt;
Begin
  F_WinEnableWindow := X_WinEnableWindow(H, En);
End;

Function F_WinEnableWindowUpdate(H, En : LongInt) : LongInt;
Begin
  F_WinEnableWindowUpdate := X_WinEnableWindowUpdate(H, En);
End;

Function F_WinEndEnumWindows(He : LongInt) : LongInt;
Begin
  F_WinEndEnumWindows := X_WinEndEnumWindows(He);
End;

Function F_WinEndPaint(Hps : LongInt) : LongInt;
Begin
  F_WinEndPaint := X_WinEndPaint(Hps);
End;

Function F_WINENDPROGRAM(H : LongInt) : LongInt;
Begin
  F_WINENDPROGRAM := X_WINENDPROGRAM(H);
End;

Function F_WINENDSESSION(S : LongInt) : LongInt;
Begin
  F_WINENDSESSION := X_WINENDSESSION(S);
End;

Function F_WINENDWINDOWSESSION(H : LongInt) : LongInt;
Begin
  F_WINENDWINDOWSESSION := X_WINENDWINDOWSESSION(H);
End;

Function F_WinEnumClipbrdFmts(Hab, Fmt : LongInt) : LongInt;
Begin
  F_WinEnumClipbrdFmts := X_WinEnumClipbrdFmts(Hab, Fmt);
End;

Function F_WinEnumDlgItem(HDlg, H, Code : LongInt) : LongInt;
Begin
  F_WinEnumDlgItem := X_WinEnumDlgItem(HDlg, H, Code);
End;

Function F_WinEnumVKeyScanIDs(Hab, Vk, P, N : LongInt) : LongInt;
Begin
  F_WinEnumVKeyScanIDs := X_WinEnumVKeyScanIDs(Hab, Vk, P, N);
End;

Function F_WinEqualRect(Hab, P1, P2 : LongInt) : LongInt;
Begin
  F_WinEqualRect := X_WinEqualRect(Hab, P1, P2);
End;

Function F_WinExcludeUpdateRegion(Hps, H : LongInt) : LongInt;
Begin
  F_WinExcludeUpdateRegion := X_WinExcludeUpdateRegion(Hps, H);
End;

Function F_WinExplodeWindow(H, PSwp : LongInt) : LongInt;
Begin
  F_WinExplodeWindow := X_WinExplodeWindow(H, PSwp);
End;

Function F_WinFillRect(Hps, P, Clr : LongInt) : LongInt;
Begin
  F_WinFillRect := X_WinFillRect(Hps, P, Clr);
End;

Function F_WinFindAtom(H, P : LongInt) : LongInt;
Begin
  F_WinFindAtom := X_WinFindAtom(H, P);
End;

Function F_WinFlashWindow(H, FFlash : LongInt) : LongInt;
Begin
  F_WinFlashWindow := X_WinFlashWindow(H, FFlash);
End;

Function F_WinFocusChange(HDesk, H, Fl : LongInt) : LongInt;
Begin
  F_WinFocusChange := X_WinFocusChange(HDesk, H, Fl);
End;

Function F_WinForceMenuRedraw(HMenu : LongInt) : LongInt;
Begin
  F_WinForceMenuRedraw := X_WinForceMenuRedraw(HMenu);
End;

Function F_WinFormatFrame(H, PFr, PSwp, Max, PCl : LongInt) : LongInt;
Begin
  F_WinFormatFrame := X_WinFormatFrame(H, PFr, PSwp, Max, PCl);
End;

Function F_WinFreeErrorInfo(P : LongInt) : LongInt;
Begin
  F_WinFreeErrorInfo := X_WinFreeErrorInfo(P);
End;

Function F_WinFreeFarMem(H, P, Cb : LongInt) : LongInt;
Begin
  F_WinFreeFarMem := X_WinFreeFarMem(H, P, Cb);
End;

Function F_WinFreeMem(H, P, Cb : LongInt) : LongInt;
Begin
  F_WinFreeMem := X_WinFreeMem(H, P, Cb);
End;

Function F_WinGetClipPS(H, HClip, Fl : LongInt) : LongInt;
Begin
  F_WinGetClipPS := X_WinGetClipPS(H, HClip, Fl);
End;

Function F_WinGetCurrentTime(Hab : LongInt) : LongInt;
Begin
  F_WinGetCurrentTime := X_WinGetCurrentTime(Hab);
End;

Function F_WinGetDlgMsg(H, P : LongInt) : LongInt;
Begin
  F_WinGetDlgMsg := X_WinGetDlgMsg(H, P);
End;

Function F_WinGetErasePS(H : LongInt) : LongInt;
Begin
  F_WinGetErasePS := X_WinGetErasePS(H);
End;

Function F_WinGetErrorInfo(Hab : LongInt) : LongInt;
Begin
  F_WinGetErrorInfo := X_WinGetErrorInfo(Hab);
End;

Function F_WinGetFrameTreePPs(H, Cb, P : LongInt) : LongInt;
Begin
  F_WinGetFrameTreePPs := X_WinGetFrameTreePPs(H, Cb, P);
End;

Function F_WinGetFrameTreePPSize(H : LongInt) : LongInt;
Begin
  F_WinGetFrameTreePPSize := X_WinGetFrameTreePPSize(H);
End;

Function F_WinGetKeyState(HDesk, Vk : LongInt) : LongInt;
Begin
  F_WinGetKeyState := X_WinGetKeyState(HDesk, Vk);
End;

Function F_WinGetLastError(Hab : LongInt) : LongInt;
Begin
  F_WinGetLastError := X_WinGetLastError(Hab);
End;

Function F_WinGetMaxPosition(H, P : LongInt) : LongInt;
Begin
  F_WinGetMaxPosition := X_WinGetMaxPosition(H, P);
End;

Function F_WinGetMinPosition(H, P, PPtl : LongInt) : LongInt;
Begin
  F_WinGetMinPosition := X_WinGetMinPosition(H, P, PPtl);
End;

Function F_WinGetMinWindowViewer(HDesk : LongInt) : LongInt;
Begin
  F_WinGetMinWindowViewer := X_WinGetMinWindowViewer(HDesk);
End;

Function F_WinGetMsg(Hab, P, HF, First, Last : LongInt) : LongInt;
Begin
  F_WinGetMsg := X_WinGetMsg(Hab, P, HF, First, Last);
End;

Function F_WinGetNextWindow(He : LongInt) : LongInt;
Begin
  F_WinGetNextWindow := X_WinGetNextWindow(He);
End;

Function F_WinGetPhysKeyState(HDesk, Sc : LongInt) : LongInt;
Begin
  F_WinGetPhysKeyState := X_WinGetPhysKeyState(HDesk, Sc);
End;

Function F_WinGetPS(H : LongInt) : LongInt;
Begin
  F_WinGetPS := X_WinGetPS(H);
End;

Function F_WinGetScanState(HDesk, Sc : LongInt) : LongInt;
Begin
  F_WinGetScanState := X_WinGetScanState(HDesk, Sc);
End;

Function F_WinGetScreenPS(HDesk : LongInt) : LongInt;
Begin
  F_WinGetScreenPS := X_WinGetScreenPS(HDesk);
End;

Function F_WinGetSysBitmap(HDesk, Ibm : LongInt) : LongInt;
Begin
  F_WinGetSysBitmap := X_WinGetSysBitmap(HDesk, Ibm);
End;

Function F_WinInflateRect(Hab, P, Cx, Cy : LongInt) : LongInt;
Begin
  F_WinInflateRect := X_WinInflateRect(Hab, P, Cx, Cy);
End;

Function F_WinInitialize(Fl : LongInt) : LongInt;
Begin
  F_WinInitialize := X_WinInitialize(Fl);
End;

Function F_WinInitializeSystem : LongInt;
Begin
  F_WinInitializeSystem := X_WinInitializeSystem;
End;

Function F_WININITSESSION(S, PTitle : LongInt) : LongInt;
Begin
  F_WININITSESSION := X_WININITSESSION(S, PTitle);
End;

Function F_WININITSESSIONMGR(Reserved : LongInt) : LongInt;
Begin
  F_WININITSESSIONMGR := X_WININITSESSIONMGR(Reserved);
End;

Function F_WININITSWENTRY(P : LongInt) : LongInt;
Begin
  F_WININITSWENTRY := X_WININITSWENTRY(P);
End;

Function F_WinInSendMsg(Hab : LongInt) : LongInt;
Begin
  F_WinInSendMsg := X_WinInSendMsg(Hab);
End;

Function F_WININSTSTARTAPP(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt;
Begin
  F_WININSTSTARTAPP := X_WININSTSTARTAPP(HNotify, PDet, PParams, PRes, Opt);
End;

Function F_WinIntersectRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Begin
  F_WinIntersectRect := X_WinIntersectRect(Hab, PD, P1, P2);
End;

Function F_WinInvalidateRect(H, PRcl, Incl : LongInt) : LongInt;
Begin
  F_WinInvalidateRect := X_WinInvalidateRect(H, PRcl, Incl);
End;

Function F_WinInvalidateRegion(H, Hrgn, Incl : LongInt) : LongInt;
Begin
  F_WinInvalidateRegion := X_WinInvalidateRegion(H, Hrgn, Incl);
End;

Function F_WinInvertRect(Hps, P : LongInt) : LongInt;
Begin
  F_WinInvertRect := X_WinInvertRect(Hps, P);
End;

Function F_WinIsChild(H, HPar : LongInt) : LongInt;
Begin
  F_WinIsChild := X_WinIsChild(H, HPar);
End;

Function F_WinIsPhysInputEnabled(HDesk : LongInt) : LongInt;
Begin
  F_WinIsPhysInputEnabled := X_WinIsPhysInputEnabled(HDesk);
End;

Function F_WinIsRectEmpty(Hab, P : LongInt) : LongInt;
Begin
  F_WinIsRectEmpty := X_WinIsRectEmpty(Hab, P);
End;

Function F_WinIsShuttingDown : LongInt;
Begin
  F_WinIsShuttingDown := X_WinIsShuttingDown;
End;

Function F_WinIsThreadActive(Hab : LongInt) : LongInt;
Begin
  F_WinIsThreadActive := X_WinIsThreadActive(Hab);
End;

Function F_WinIsWindow(Hab, H : LongInt) : LongInt;
Begin
  F_WinIsWindow := X_WinIsWindow(Hab, H);
End;

Function F_WinIsWindowEnabled(H : LongInt) : LongInt;
Begin
  F_WinIsWindowEnabled := X_WinIsWindowEnabled(H);
End;

Function F_WinIsWindowShowing(H : LongInt) : LongInt;
Begin
  F_WinIsWindowShowing := X_WinIsWindowShowing(H);
End;

Function F_WinIsWindowVisible(H : LongInt) : LongInt;
Begin
  F_WinIsWindowVisible := X_WinIsWindowVisible(H);
End;

Function F_WinJiggleMouse : LongInt;
Begin
  F_WinJiggleMouse := X_WinJiggleMouse;
End;

Function F_WinLangsupDlgProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinLangsupDlgProc := X_WinLangsupDlgProc(H, Msg, Mp1, Mp2);
End;

Function F_WinLangsupWindowProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinLangsupWindowProc := X_WinLangsupWindowProc(H, Msg, Mp1, Mp2);
End;

Function F_WinLoadAccelTable(Hab, Hmod, Id : LongInt) : LongInt;
Begin
  F_WinLoadAccelTable := X_WinLoadAccelTable(Hab, Hmod, Id);
End;

Function F_WinLoadAniPointer(Hmod, Id, PRes : LongInt) : LongInt;
Begin
  F_WinLoadAniPointer := X_WinLoadAniPointer(Hmod, Id, PRes);
End;

Function F_WinLoadCharXlatetbl(Hab, Hmod, Id : LongInt) : LongInt;
Begin
  F_WinLoadCharXlatetbl := X_WinLoadCharXlatetbl(Hab, Hmod, Id);
End;

Function F_WinLoadDlg(HPar, HOwn, Proc, Hmod, Id, PCreate : LongInt) : LongInt;
Begin
  F_WinLoadDlg := X_WinLoadDlg(HPar, HOwn, Proc, Hmod, Id, PCreate);
End;

Function F_WinLoadHelpTable(HHelp, Id, Hmod : LongInt) : LongInt;
Begin
  F_WinLoadHelpTable := X_WinLoadHelpTable(HHelp, Id, Hmod);
End;

Function F_WinLoadLibrary(Hab, P : LongInt) : LongInt;
Begin
  F_WinLoadLibrary := X_WinLoadLibrary(Hab, P);
End;

Function F_WinLoadMenu(HFrame, Hmod, Id : LongInt) : LongInt;
Begin
  F_WinLoadMenu := X_WinLoadMenu(HFrame, Hmod, Id);
End;

Function F_WinLoadMessage(Hab, Hmod, Id, Cch, P : LongInt) : LongInt;
Begin
  F_WinLoadMessage := X_WinLoadMessage(Hab, Hmod, Id, Cch, P);
End;

Function F_WinLoadPointer(HDesk, Hmod, Id : LongInt) : LongInt;
Begin
  F_WinLoadPointer := X_WinLoadPointer(HDesk, Hmod, Id);
End;

Function F_WinLoadProcedure(Hab, H, P : LongInt) : LongInt;
Begin
  F_WinLoadProcedure := X_WinLoadProcedure(Hab, H, P);
End;

Function F_WinLoadString(Hab, Hmod, Id, Cch, P : LongInt) : LongInt;
Begin
  F_WinLoadString := X_WinLoadString(Hab, Hmod, Id, Cch, P);
End;

Function F_WinLoadStringTable(Hab, Hmod, Id, Cb, P : LongInt) : LongInt;
Begin
  F_WinLoadStringTable := X_WinLoadStringTable(Hab, Hmod, Id, Cb, P);
End;

Function F_WinLoadTranslationTable(Hab, Hmod, Id : LongInt) : LongInt;
Begin
  F_WinLoadTranslationTable := X_WinLoadTranslationTable(Hab, Hmod, Id);
End;

Function F_WinLoadVkeyGlyphXlatetbl(Hab, Hmod, Id : LongInt) : LongInt;
Begin
  F_WinLoadVkeyGlyphXlatetbl := X_WinLoadVkeyGlyphXlatetbl(Hab, Hmod, Id);
End;

Function F_WinLockHeap(H : LongInt) : LongInt;
Begin
  F_WinLockHeap := X_WinLockHeap(H);
End;

Function F_WinLockInput(Hmq, Lock : LongInt) : LongInt;
Begin
  F_WinLockInput := X_WinLockInput(Hmq, Lock);
End;

Function F_WinLockPointerUpdate(HDesk, Hptr, Interval : LongInt) : LongInt;
Begin
  F_WinLockPointerUpdate := X_WinLockPointerUpdate(HDesk, Hptr, Interval);
End;

Function F_WinLockStartInput(Hab, Lock : LongInt) : LongInt;
Begin
  F_WinLockStartInput := X_WinLockStartInput(Hab, Lock);
End;

Function F_WinLockVisRegions(HDesk, Lock : LongInt) : LongInt;
Begin
  F_WinLockVisRegions := X_WinLockVisRegions(HDesk, Lock);
End;

Function F_WinLockWindow(H, Lock : LongInt) : LongInt;
Begin
  F_WinLockWindow := X_WinLockWindow(H, Lock);
End;

Function F_WinLockWindowUpdate(HDesk, HLock : LongInt) : LongInt;
Begin
  F_WinLockWindowUpdate := X_WinLockWindowUpdate(HDesk, HLock);
End;

Function F_WinMakePoints(Hab, P, N : LongInt) : LongInt;
Begin
  F_WinMakePoints := X_WinMakePoints(Hab, P, N);
End;

Function F_WinMakeRect(Hab, P : LongInt) : LongInt;
Begin
  F_WinMakeRect := X_WinMakeRect(Hab, P);
End;

Function F_WinMapDlgPoints(HDlg, P, N, FWin : LongInt) : LongInt;
Begin
  F_WinMapDlgPoints := X_WinMapDlgPoints(HDlg, P, N, FWin);
End;

Function F_WinMapWindowPoints(HFrom, HTo, P, N : LongInt) : LongInt;
Begin
  F_WinMapWindowPoints := X_WinMapWindowPoints(HFrom, HTo, P, N);
End;

Function F_WinMenuIndexFromID(HMenu, Id : LongInt) : LongInt;
Begin
  F_WinMenuIndexFromID := X_WinMenuIndexFromID(HMenu, Id);
End;

Function F_WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt;
Begin
  F_WinMessageBox := X_WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl);
End;

Function F_WinMoveCursor(H, X, Y : LongInt) : LongInt;
Begin
  F_WinMoveCursor := X_WinMoveCursor(H, X, Y);
End;

Function F_WinMsgMuxSemWait(PI, PL, T : LongInt) : LongInt;
Begin
  F_WinMsgMuxSemWait := X_WinMsgMuxSemWait(PI, PL, T);
End;

Function F_WinMsgSemWait(H, T : LongInt) : LongInt;
Begin
  F_WinMsgSemWait := X_WinMsgSemWait(H, T);
End;

Function F_WinMultWindowFromIDs(HPar, P, IdF, IdL : LongInt) : LongInt;
Begin
  F_WinMultWindowFromIDs := X_WinMultWindowFromIDs(HPar, P, IdF, IdL);
End;

Function F_WinNextChar(Hab, Cp, Cc, P : LongInt) : LongInt;
Begin
  F_WinNextChar := X_WinNextChar(Hab, Cp, Cc, P);
End;

Function F_WINNOSHUTDOWN(Block : LongInt) : LongInt;
Begin
  F_WINNOSHUTDOWN := X_WINNOSHUTDOWN(Block);
End;

Function F_WinOffsetRect(Hab, P, Dx, Dy : LongInt) : LongInt;
Begin
  F_WinOffsetRect := X_WinOffsetRect(Hab, P, Dx, Dy);
End;

Function F_WinOpenClipbrd(Hab : LongInt) : LongInt;
Begin
  F_WinOpenClipbrd := X_WinOpenClipbrd(Hab);
End;

Function F_WinOpenWindowDC(H : LongInt) : LongInt;
Begin
  F_WinOpenWindowDC := X_WinOpenWindowDC(H);
End;

Function F_WinPeekMsg(Hab, P, HF, First, Last, Fl : LongInt) : LongInt;
Begin
  F_WinPeekMsg := X_WinPeekMsg(Hab, P, HF, First, Last, Fl);
End;

Function F_WINPMFILEREGISTER(PName : LongInt) : LongInt;
Begin
  F_WINPMFILEREGISTER := X_WINPMFILEREGISTER(PName);
End;

Function F_WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt;
Begin
  F_WinPopupMenu := X_WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs);
End;

Function F_WinPortHoleUtil(H, P : LongInt) : LongInt;
Begin
  F_WinPortHoleUtil := X_WinPortHoleUtil(H, P);
End;

Function F_WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinPostMsg := X_WinPostMsg(H, Msg, Mp1, Mp2);
End;

Function F_WinPostQueueMsg(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinPostQueueMsg := X_WinPostQueueMsg(Hmq, Msg, Mp1, Mp2);
End;

Function F_WinPrevChar(Hab, Cp, Cc, PStart, P : LongInt) : LongInt;
Begin
  F_WinPrevChar := X_WinPrevChar(Hab, Cp, Cc, PStart, P);
End;

Function F_WinProcessDlg(H : LongInt) : LongInt;
Begin
  F_WinProcessDlg := X_WinProcessDlg(H);
End;

Function F_WINPROCESSHOTKEY(Scan, State : LongInt) : LongInt;
Begin
  F_WINPROCESSHOTKEY := X_WINPROCESSHOTKEY(Scan, State);
End;

Function F_WinProfControl(Fl, P : LongInt) : LongInt;
Begin
  F_WinProfControl := X_WinProfControl(Fl, P);
End;

Function F_WinPtInRect(Hab, P, PPt : LongInt) : LongInt;
Begin
  F_WinPtInRect := X_WinPtInRect(Hab, P, PPt);
End;

Function F_WinQueryAccelTable(Hab, HFrame : LongInt) : LongInt;
Begin
  F_WinQueryAccelTable := X_WinQueryAccelTable(Hab, HFrame);
End;

Function F_WinQueryAccelTableValue(H, Ix, P : LongInt) : LongInt;
Begin
  F_WinQueryAccelTableValue := X_WinQueryAccelTableValue(H, Ix, P);
End;

Function F_WinQueryActiveWindow(HPar : LongInt) : LongInt;
Begin
  F_WinQueryActiveWindow := X_WinQueryActiveWindow(HPar);
End;

Function F_WinQueryAnchorBlock(H : LongInt) : LongInt;
Begin
  F_WinQueryAnchorBlock := X_WinQueryAnchorBlock(H);
End;

Function F_WinQueryAtomLength(H, A : LongInt) : LongInt;
Begin
  F_WinQueryAtomLength := X_WinQueryAtomLength(H, A);
End;

Function F_WinQueryAtomName(H, A, P, Cch : LongInt) : LongInt;
Begin
  F_WinQueryAtomName := X_WinQueryAtomName(H, A, P, Cch);
End;

Function F_WinQueryAtomUsage(H, A : LongInt) : LongInt;
Begin
  F_WinQueryAtomUsage := X_WinQueryAtomUsage(H, A);
End;

Function F_WinQueryCapture(HDesk : LongInt) : LongInt;
Begin
  F_WinQueryCapture := X_WinQueryCapture(HDesk);
End;

Function F_WinQueryCharXlatetbl(Hab : LongInt) : LongInt;
Begin
  F_WinQueryCharXlatetbl := X_WinQueryCharXlatetbl(Hab);
End;

Function F_WinQueryClassInfo(Hab, PName, PInfo : LongInt) : LongInt;
Begin
  F_WinQueryClassInfo := X_WinQueryClassInfo(Hab, PName, PInfo);
End;

Function F_WinQueryClassName(H, Cch, P : LongInt) : LongInt;
Begin
  F_WinQueryClassName := X_WinQueryClassName(H, Cch, P);
End;

Function F_WinQueryClassThunkProc(PCls : LongInt) : LongInt;
Begin
  F_WinQueryClassThunkProc := X_WinQueryClassThunkProc(PCls);
End;

Function F_WinQueryClipbrdData(Hab, Fmt : LongInt) : LongInt;
Begin
  F_WinQueryClipbrdData := X_WinQueryClipbrdData(Hab, Fmt);
End;

Function F_WinQueryClipbrdFmtInfo(Hab, Fmt, P : LongInt) : LongInt;
Begin
  F_WinQueryClipbrdFmtInfo := X_WinQueryClipbrdFmtInfo(Hab, Fmt, P);
End;

Function F_WinQueryClipbrdOwner(Hab : LongInt) : LongInt;
Begin
  F_WinQueryClipbrdOwner := X_WinQueryClipbrdOwner(Hab);
End;

Function F_WinQueryClipbrdViewer(Hab : LongInt) : LongInt;
Begin
  F_WinQueryClipbrdViewer := X_WinQueryClipbrdViewer(Hab);
End;

Function F_WinQueryCp(Hmq : LongInt) : LongInt;
Begin
  F_WinQueryCp := X_WinQueryCp(Hmq);
End;

Function F_WinQueryCpList(Hab, N, P : LongInt) : LongInt;
Begin
  F_WinQueryCpList := X_WinQueryCpList(Hab, N, P);
End;

Function F_WinQueryCursorInfo(HDesk, P : LongInt) : LongInt;
Begin
  F_WinQueryCursorInfo := X_WinQueryCursorInfo(HDesk, P);
End;

Function F_WinQueryDesktopBkgnd(HDesk, P : LongInt) : LongInt;
Begin
  F_WinQueryDesktopBkgnd := X_WinQueryDesktopBkgnd(HDesk, P);
End;

Function F_WinQueryDesktopWindow(Hab, Hdc : LongInt) : LongInt;
Begin
  F_WinQueryDesktopWindow := X_WinQueryDesktopWindow(Hab, Hdc);
End;

Function F_WinQueryDlgItemShort(HDlg, Id, P, FSigned : LongInt) : LongInt;
Begin
  F_WinQueryDlgItemShort := X_WinQueryDlgItemShort(HDlg, Id, P, FSigned);
End;

Function F_WinQueryDlgItemText(HDlg, Id, Cch, P : LongInt) : LongInt;
Begin
  F_WinQueryDlgItemText := X_WinQueryDlgItemText(HDlg, Id, Cch, P);
End;

Function F_WinQueryDlgItemTextLength(HDlg, Id : LongInt) : LongInt;
Begin
  F_WinQueryDlgItemTextLength := X_WinQueryDlgItemTextLength(HDlg, Id);
End;

Function F_WINQUERYEXTIDFOCUS(PId : LongInt) : LongInt;
Begin
  F_WINQUERYEXTIDFOCUS := X_WINQUERYEXTIDFOCUS(PId);
End;

Function F_WinQueryFocus(HDesk : LongInt) : LongInt;
Begin
  F_WinQueryFocus := X_WinQueryFocus(HDesk);
End;

Function F_WinQueryHelpInstance(H : LongInt) : LongInt;
Begin
  F_WinQueryHelpInstance := X_WinQueryHelpInstance(H);
End;

Function F_WinQueryHungProcess(Hab : LongInt) : LongInt;
Begin
  F_WinQueryHungProcess := X_WinQueryHungProcess(Hab);
End;

Function F_WinQueryKbdLayout(HDesk, P, Cb : LongInt) : LongInt;
Begin
  F_WinQueryKbdLayout := X_WinQueryKbdLayout(HDesk, P, Cb);
End;

Function F_WinQueryMenuData(HMenu, Id : LongInt) : LongInt;
Begin
  F_WinQueryMenuData := X_WinQueryMenuData(HMenu, Id);
End;

Function F_WinQueryMsgPos(Hab, P : LongInt) : LongInt;
Begin
  F_WinQueryMsgPos := X_WinQueryMsgPos(Hab, P);
End;

Function F_WinQueryMsgTime(Hab : LongInt) : LongInt;
Begin
  F_WinQueryMsgTime := X_WinQueryMsgTime(Hab);
End;

Function F_WinQueryObjectWindow(HDesk : LongInt) : LongInt;
Begin
  F_WinQueryObjectWindow := X_WinQueryObjectWindow(HDesk);
End;

Function F_WinQueryPointer(HDesk : LongInt) : LongInt;
Begin
  F_WinQueryPointer := X_WinQueryPointer(HDesk);
End;

Function F_WinQueryPointerInfo(H, P : LongInt) : LongInt;
Begin
  F_WinQueryPointerInfo := X_WinQueryPointerInfo(H, P);
End;

Function F_WinQueryPointerPos(HDesk, P : LongInt) : LongInt;
Begin
  F_WinQueryPointerPos := X_WinQueryPointerPos(HDesk, P);
End;

Function F_WinQueryPresParam(H, Id1, Id2, PId, Cb, P, Fs : LongInt) : LongInt;
Begin
  F_WinQueryPresParam := X_WinQueryPresParam(H, Id1, Id2, PId, Cb, P, Fs);
End;

Function F_WinQueryProcessCP(Hmq : LongInt) : LongInt;
Begin
  F_WinQueryProcessCP := X_WinQueryProcessCP(Hmq);
End;

Function F_WinQueryPwnd(H : LongInt) : LongInt;
Begin
  F_WinQueryPwnd := X_WinQueryPwnd(H);
End;

Function F_WinQueryQueueInfo(Hmq, P, Cb : LongInt) : LongInt;
Begin
  F_WinQueryQueueInfo := X_WinQueryQueueInfo(Hmq, P, Cb);
End;

Function F_WinQueryQueueStatus(HDesk : LongInt) : LongInt;
Begin
  F_WinQueryQueueStatus := X_WinQueryQueueStatus(HDesk);
End;

Function F_WinQuerySendMsg(Hab, HmqSender, HmqReceiver, P : LongInt) : LongInt;
Begin
  F_WinQuerySendMsg := X_WinQuerySendMsg(Hab, HmqSender, HmqReceiver, P);
End;

Function F_WINQUERYSESSIONTITLE(Hab, S, PTitle, Cb : LongInt) : LongInt;
Begin
  F_WINQUERYSESSIONTITLE := X_WINQUERYSESSIONTITLE(Hab, S, PTitle, Cb);
End;

Function F_WinQueryState(Hab : LongInt) : LongInt;
Begin
  F_WinQueryState := X_WinQueryState(Hab);
End;

Function F_WINQUERYSWITCHENTRY(H, P : LongInt) : LongInt;
Begin
  F_WINQUERYSWITCHENTRY := X_WINQUERYSWITCHENTRY(H, P);
End;

Function F_WINQUERYSWITCHHANDLE(Hwnd, Pid : LongInt) : LongInt;
Begin
  F_WINQUERYSWITCHHANDLE := X_WINQUERYSWITCHHANDLE(Hwnd, Pid);
End;

Function F_WINQUERYSWITCHLIST(Hab, PBlk, Cb : LongInt) : LongInt;
Begin
  F_WINQUERYSWITCHLIST := X_WINQUERYSWITCHLIST(Hab, PBlk, Cb);
End;

Function F_WinQuerySysColor(HDesk, Clr, Rsvd : LongInt) : LongInt;
Begin
  F_WinQuerySysColor := X_WinQuerySysColor(HDesk, Clr, Rsvd);
End;

Function F_WinQuerySysModalWindow(HDesk : LongInt) : LongInt;
Begin
  F_WinQuerySysModalWindow := X_WinQuerySysModalWindow(HDesk);
End;

Function F_WinQuerySysPointer(HDesk, Iptr, Load : LongInt) : LongInt;
Begin
  F_WinQuerySysPointer := X_WinQuerySysPointer(HDesk, Iptr, Load);
End;

Function F_WinQuerySystemAtomTable : LongInt;
Begin
  F_WinQuerySystemAtomTable := X_WinQuerySystemAtomTable;
End;

Function F_WinQuerySysValue(HDesk, I : LongInt) : LongInt;
Begin
  F_WinQuerySysValue := X_WinQuerySysValue(HDesk, I);
End;

Function F_WINQUERYTASKSIZEPOS(Hab, S, P : LongInt) : LongInt;
Begin
  F_WINQUERYTASKSIZEPOS := X_WINQUERYTASKSIZEPOS(Hab, S, P);
End;

Function F_WINQUERYTASKTITLE(S, PTitle, Cb : LongInt) : LongInt;
Begin
  F_WINQUERYTASKTITLE := X_WINQUERYTASKTITLE(S, PTitle, Cb);
End;

Function F_WinQueryUpdateRect(H, PRcl : LongInt) : LongInt;
Begin
  F_WinQueryUpdateRect := X_WinQueryUpdateRect(H, PRcl);
End;

Function F_WinQueryUpdateRegion(H, Hrgn : LongInt) : LongInt;
Begin
  F_WinQueryUpdateRegion := X_WinQueryUpdateRegion(H, Hrgn);
End;

Function F_WinQueryVersion(Hab : LongInt) : LongInt;
Begin
  F_WinQueryVersion := X_WinQueryVersion(Hab);
End;

Function F_WinQueryVkeyGlyphXlatetbl(Hab : LongInt) : LongInt;
Begin
  F_WinQueryVkeyGlyphXlatetbl := X_WinQueryVkeyGlyphXlatetbl(Hab);
End;

Function F_WinQueryWindow(H, Cmd : LongInt) : LongInt;
Begin
  F_WinQueryWindow := X_WinQueryWindow(H, Cmd);
End;

Function F_WinQueryWindowDC(H : LongInt) : LongInt;
Begin
  F_WinQueryWindowDC := X_WinQueryWindowDC(H);
End;

Function F_WinQueryWindowLockCount(H : LongInt) : LongInt;
Begin
  F_WinQueryWindowLockCount := X_WinQueryWindowLockCount(H);
End;

Function F_WinQueryWindowModel(H : LongInt) : LongInt;
Begin
  F_WinQueryWindowModel := X_WinQueryWindowModel(H);
End;

Function F_WinQueryWindowPos(H, P : LongInt) : LongInt;
Begin
  F_WinQueryWindowPos := X_WinQueryWindowPos(H, P);
End;

Function F_WinQueryWindowProcess(H, PPid, PTid : LongInt) : LongInt;
Begin
  F_WinQueryWindowProcess := X_WinQueryWindowProcess(H, PPid, PTid);
End;

Function F_WinQueryWindowPtr(H, Index : LongInt) : LongInt;
Begin
  F_WinQueryWindowPtr := X_WinQueryWindowPtr(H, Index);
End;

Function F_WinQueryWindowRect(H, P : LongInt) : LongInt;
Begin
  F_WinQueryWindowRect := X_WinQueryWindowRect(H, P);
End;

Function F_WinQueryWindowSGId(H : LongInt) : LongInt;
Begin
  F_WinQueryWindowSGId := X_WinQueryWindowSGId(H);
End;

Function F_WinQueryWindowText(H, Cch, P : LongInt) : LongInt;
Begin
  F_WinQueryWindowText := X_WinQueryWindowText(H, Cch, P);
End;

Function F_WinQueryWindowTextLength(H : LongInt) : LongInt;
Begin
  F_WinQueryWindowTextLength := X_WinQueryWindowTextLength(H);
End;

Function F_WinQueryWindowThunkProc(H : LongInt) : LongInt;
Begin
  F_WinQueryWindowThunkProc := X_WinQueryWindowThunkProc(H);
End;

Function F_WinQueryWindowULong(H, Index : LongInt) : LongInt;
Begin
  F_WinQueryWindowULong := X_WinQueryWindowULong(H, Index);
End;

Function F_WinQueryWindowUShort(H, Index : LongInt) : LongInt;
Begin
  F_WinQueryWindowUShort := X_WinQueryWindowUShort(H, Index);
End;

Function F_WinQueueFromId(Hab, Pid, Tid : LongInt) : LongInt;
Begin
  F_WinQueueFromId := X_WinQueueFromId(Hab, Pid, Tid);
End;

Function F_WinRealizePalette(H, Hps, P : LongInt) : LongInt;
Begin
  F_WinRealizePalette := X_WinRealizePalette(H, Hps, P);
End;

Function F_WinReallocFarMem(H, P, CbOld, CbNew : LongInt) : LongInt;
Begin
  F_WinReallocFarMem := X_WinReallocFarMem(H, P, CbOld, CbNew);
End;

Function F_WinReallocMem(H, P, CbOld, CbNew : LongInt) : LongInt;
Begin
  F_WinReallocMem := X_WinReallocMem(H, P, CbOld, CbNew);
End;

Function F_WinRegisterClass(Hab, PName, Proc, Style, Cb : LongInt) : LongInt;
Begin
  F_WinRegisterClass := X_WinRegisterClass(Hab, PName, Proc, Style, Cb);
End;

Function F_WinRegisterSeamlessProc(Pfn : LongInt) : LongInt;
Begin
  F_WinRegisterSeamlessProc := X_WinRegisterSeamlessProc(Pfn);
End;

Function F_WinRegisterUserDatatype(Hab, T, N, P : LongInt) : LongInt;
Begin
  F_WinRegisterUserDatatype := X_WinRegisterUserDatatype(Hab, T, N, P);
End;

Function F_WinRegisterUserMsg(Hab, Msg, T1, D1, T2, D2, Tr : LongInt) : LongInt;
Begin
  F_WinRegisterUserMsg := X_WinRegisterUserMsg(Hab, Msg, T1, D1, T2, D2, Tr);
End;

Function F_WinRegisterWindowDestroy(H, Reg : LongInt) : LongInt;
Begin
  F_WinRegisterWindowDestroy := X_WinRegisterWindowDestroy(H, Reg);
End;

Function F_WinReleaseErasePS(Hps : LongInt) : LongInt;
Begin
  F_WinReleaseErasePS := X_WinReleaseErasePS(Hps);
End;

Function F_WinReleaseHook(Hab, Hmq, Typ, Pfn, Hmod : LongInt) : LongInt;
Begin
  F_WinReleaseHook := X_WinReleaseHook(Hab, Hmq, Typ, Pfn, Hmod);
End;

Function F_WinReleasePS(Hps : LongInt) : LongInt;
Begin
  F_WinReleasePS := X_WinReleasePS(Hps);
End;

Function F_WinRemovePresParam(H, Id : LongInt) : LongInt;
Begin
  F_WinRemovePresParam := X_WinRemovePresParam(H, Id);
End;

Function F_WINREMOVESWITCHENTRY(H : LongInt) : LongInt;
Begin
  F_WINREMOVESWITCHENTRY := X_WINREMOVESWITCHENTRY(H);
End;

Function F_WinReplyMsg(Hab, HmqSender, HmqReceiver, Mres : LongInt) : LongInt;
Begin
  F_WinReplyMsg := X_WinReplyMsg(Hab, HmqSender, HmqReceiver, Mres);
End;

Function F_WinRequestMutexSem(H, T : LongInt) : LongInt;
Begin
  F_WinRequestMutexSem := X_WinRequestMutexSem(H, T);
End;

Function F_WinResetSystem(HDesk : LongInt) : LongInt;
Begin
  F_WinResetSystem := X_WinResetSystem(HDesk);
End;

Function F_WinSaveWindowPos(Hsv, P, N : LongInt) : LongInt;
Begin
  F_WinSaveWindowPos := X_WinSaveWindowPos(Hsv, P, N);
End;

Function F_WinScreenSwitch(H, Fl : LongInt) : LongInt;
Begin
  F_WinScreenSwitch := X_WinScreenSwitch(H, Fl);
End;

Function F_WinScrollWindow(H, Dx, Dy, PScroll, PClip, Hrgn, PUpd, Fs : LongInt) : LongInt;
Begin
  F_WinScrollWindow := X_WinScrollWindow(H, Dx, Dy, PScroll, PClip, Hrgn, PUpd, Fs);
End;

Function F_WinSeamlessBox(H, P : LongInt) : LongInt;
Begin
  F_WinSeamlessBox := X_WinSeamlessBox(H, P);
End;

Function F_WinSemEnter : LongInt;
Begin
  F_WinSemEnter := X_WinSemEnter;
End;

Function F_WinSemLeave : LongInt;
Begin
  F_WinSemLeave := X_WinSemLeave;
End;

Function F_WinSemQuery : LongInt;
Begin
  F_WinSemQuery := X_WinSemQuery;
End;

Function F_WinSendDlgItemMsg(HDlg, Id, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinSendDlgItemMsg := X_WinSendDlgItemMsg(HDlg, Id, Msg, Mp1, Mp2);
End;

Function F_WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinSendMsg := X_WinSendMsg(H, Msg, Mp1, Mp2);
End;

Function F_WinSendQueueMsg(Hmq, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_WinSendQueueMsg := X_WinSendQueueMsg(Hmq, Msg, Mp1, Mp2);
End;

Function F_WinSetAccelTable(Hab, H, HFrame : LongInt) : LongInt;
Begin
  F_WinSetAccelTable := X_WinSetAccelTable(Hab, H, HFrame);
End;

Function F_WinSetAccelTableValue(H, Ix, P : LongInt) : LongInt;
Begin
  F_WinSetAccelTableValue := X_WinSetAccelTableValue(H, Ix, P);
End;

Function F_WinSetActiveWindow(HDesk, H : LongInt) : LongInt;
Begin
  F_WinSetActiveWindow := X_WinSetActiveWindow(HDesk, H);
End;

Function F_WinSetAniPointer(H, FAnimate : LongInt) : LongInt;
Begin
  F_WinSetAniPointer := X_WinSetAniPointer(H, FAnimate);
End;

Function F_WinSetAtomTableOwner(H, Pid : LongInt) : LongInt;
Begin
  F_WinSetAtomTableOwner := X_WinSetAtomTableOwner(H, Pid);
End;

Function F_WinSetCapture(HDesk, H : LongInt) : LongInt;
Begin
  F_WinSetCapture := X_WinSetCapture(HDesk, H);
End;

Function F_WinSetCharXlatetbl(Hab, P : LongInt) : LongInt;
Begin
  F_WinSetCharXlatetbl := X_WinSetCharXlatetbl(Hab, P);
End;

Function F_WinSetClassMsgInterest(Hab, PCls, MsgCls, Ctl : LongInt) : LongInt;
Begin
  F_WinSetClassMsgInterest := X_WinSetClassMsgInterest(Hab, PCls, MsgCls, Ctl);
End;

Function F_WinSetClassThunkProc(PCls, Pfn : LongInt) : LongInt;
Begin
  F_WinSetClassThunkProc := X_WinSetClassThunkProc(PCls, Pfn);
End;

Function F_WinSetClipbrdData(Hab, Data, Fmt, Info : LongInt) : LongInt;
Begin
  F_WinSetClipbrdData := X_WinSetClipbrdData(Hab, Data, Fmt, Info);
End;

Function F_WinSetClipbrdOwner(Hab, H : LongInt) : LongInt;
Begin
  F_WinSetClipbrdOwner := X_WinSetClipbrdOwner(Hab, H);
End;

Function F_WinSetClipbrdViewer(Hab, H : LongInt) : LongInt;
Begin
  F_WinSetClipbrdViewer := X_WinSetClipbrdViewer(Hab, H);
End;

Function F_WinSetCp(Hmq, Cp : LongInt) : LongInt;
Begin
  F_WinSetCp := X_WinSetCp(Hmq, Cp);
End;

Function F_WinSetDesktopBkgnd(HDesk, P : LongInt) : LongInt;
Begin
  F_WinSetDesktopBkgnd := X_WinSetDesktopBkgnd(HDesk, P);
End;

Function F_WinSetDlgItemShort(HDlg, Id, V, FSigned : LongInt) : LongInt;
Begin
  F_WinSetDlgItemShort := X_WinSetDlgItemShort(HDlg, Id, V, FSigned);
End;

Function F_WinSetDlgItemText(HDlg, Id, P : LongInt) : LongInt;
Begin
  F_WinSetDlgItemText := X_WinSetDlgItemText(HDlg, Id, P);
End;

Function F_WinSetErrorInfo(E, Fs : LongInt) : LongInt;
Begin
  F_WinSetErrorInfo := X_WinSetErrorInfo(E, Fs);
End;

Function F_WINSETEXTIDFOCUS(Id : LongInt) : LongInt;
Begin
  F_WINSETEXTIDFOCUS := X_WINSETEXTIDFOCUS(Id);
End;

Function F_WINSETFGNDWINDOW(Hwnd : LongInt) : LongInt;
Begin
  F_WINSETFGNDWINDOW := X_WINSETFGNDWINDOW(Hwnd);
End;

Function F_WinSetFocus(HDesk, H : LongInt) : LongInt;
Begin
  F_WinSetFocus := X_WinSetFocus(HDesk, H);
End;

Function F_WinSetFrameTreePPs(H, Cb, P : LongInt) : LongInt;
Begin
  F_WinSetFrameTreePPs := X_WinSetFrameTreePPs(H, Cb, P);
End;

Function F_WinSetHook(Hab, Hmq, Typ, Pfn, Hmod : LongInt) : LongInt;
Begin
  F_WinSetHook := X_WinSetHook(Hab, Hmq, Typ, Pfn, Hmod);
End;

Function F_WinSetKbdLayout(HDesk, P : LongInt) : LongInt;
Begin
  F_WinSetKbdLayout := X_WinSetKbdLayout(HDesk, P);
End;

Function F_WinSetKbdLayout2(HDesk, P, Fl : LongInt) : LongInt;
Begin
  F_WinSetKbdLayout2 := X_WinSetKbdLayout2(HDesk, P, Fl);
End;

Function F_WinSetKeyboardStateTable(HDesk, P, FSet : LongInt) : LongInt;
Begin
  F_WinSetKeyboardStateTable := X_WinSetKeyboardStateTable(HDesk, P, FSet);
End;

Function F_WinSetLastError(Hab, E : LongInt) : LongInt;
Begin
  F_WinSetLastError := X_WinSetLastError(Hab, E);
End;

Function F_WinSetMenuData(HMenu, Id, Data : LongInt) : LongInt;
Begin
  F_WinSetMenuData := X_WinSetMenuData(HMenu, Id, Data);
End;

Function F_WinSetMsgInterest(H, MsgCls, Ctl : LongInt) : LongInt;
Begin
  F_WinSetMsgInterest := X_WinSetMsgInterest(H, MsgCls, Ctl);
End;

Function F_WinSetMsgMode(Hab, PCls, Ctl : LongInt) : LongInt;
Begin
  F_WinSetMsgMode := X_WinSetMsgMode(Hab, PCls, Ctl);
End;

Function F_WinSetMultWindowPos(Hab, P, N : LongInt) : LongInt;
Begin
  F_WinSetMultWindowPos := X_WinSetMultWindowPos(Hab, P, N);
End;

Function F_WinSetOwner(H, HOwn : LongInt) : LongInt;
Begin
  F_WinSetOwner := X_WinSetOwner(H, HOwn);
End;

Function F_WinSetParent(H, HPar, Redraw : LongInt) : LongInt;
Begin
  F_WinSetParent := X_WinSetParent(H, HPar, Redraw);
End;

Function F_WinSetPointer(HDesk, Hptr : LongInt) : LongInt;
Begin
  F_WinSetPointer := X_WinSetPointer(HDesk, Hptr);
End;

Function F_WinSetPointerOwner(H, Pid, FDestroy : LongInt) : LongInt;
Begin
  F_WinSetPointerOwner := X_WinSetPointerOwner(H, Pid, FDestroy);
End;

Function F_WinSetPointerPos(HDesk, X, Y : LongInt) : LongInt;
Begin
  F_WinSetPointerPos := X_WinSetPointerPos(HDesk, X, Y);
End;

Function F_WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt;
Begin
  F_WinSetPresParam := X_WinSetPresParam(H, Id, Cb, P);
End;

Function F_WinSetQueueProc(Hmq, Pfn : LongInt) : LongInt;
Begin
  F_WinSetQueueProc := X_WinSetQueueProc(Hmq, Pfn);
End;

Function F_WinSetRect(Hab, P, X1, Y1, X2, Y2 : LongInt) : LongInt;
Begin
  F_WinSetRect := X_WinSetRect(Hab, P, X1, Y1, X2, Y2);
End;

Function F_WinSetRectEmpty(Hab, P : LongInt) : LongInt;
Begin
  F_WinSetRectEmpty := X_WinSetRectEmpty(Hab, P);
End;

Function F_WinSetScanStateTable(HDesk, P, FSet : LongInt) : LongInt;
Begin
  F_WinSetScanStateTable := X_WinSetScanStateTable(HDesk, P, FSet);
End;

Function F_WINSETSWENTRY(H, P : LongInt) : LongInt;
Begin
  F_WINSETSWENTRY := X_WINSETSWENTRY(H, P);
End;

Function F_WinSetSynchroMode(Hab, Mode : LongInt) : LongInt;
Begin
  F_WinSetSynchroMode := X_WinSetSynchroMode(Hab, Mode);
End;

Function F_WinSetSysClipbrdViewer(Hab, H : LongInt) : LongInt;
Begin
  F_WinSetSysClipbrdViewer := X_WinSetSysClipbrdViewer(Hab, H);
End;

Function F_WinSetSysColors(HDesk, Opt, Fmt, First, N, P : LongInt) : LongInt;
Begin
  F_WinSetSysColors := X_WinSetSysColors(HDesk, Opt, Fmt, First, N, P);
End;

Function F_WinSetSysFont(HDesk, P : LongInt) : LongInt;
Begin
  F_WinSetSysFont := X_WinSetSysFont(HDesk, P);
End;

Function F_WinSetSysModalWindow(HDesk, H : LongInt) : LongInt;
Begin
  F_WinSetSysModalWindow := X_WinSetSysModalWindow(HDesk, H);
End;

Function F_WinSetSysValue(HDesk, I, V : LongInt) : LongInt;
Begin
  F_WinSetSysValue := X_WinSetSysValue(HDesk, I, V);
End;

Function F_WINSETTITLE(PTitle : LongInt) : LongInt;
Begin
  F_WINSETTITLE := X_WINSETTITLE(PTitle);
End;

Function F_WinSetVkeyGlyphXlatetbl(Hab, P : LongInt) : LongInt;
Begin
  F_WinSetVkeyGlyphXlatetbl := X_WinSetVkeyGlyphXlatetbl(Hab, P);
End;

Function F_WinSetWindowBits(H, Index, Data, Mask : LongInt) : LongInt;
Begin
  F_WinSetWindowBits := X_WinSetWindowBits(H, Index, Data, Mask);
End;

Function F_WinSetWindowDC(H, Hdc : LongInt) : LongInt;
Begin
  F_WinSetWindowDC := X_WinSetWindowDC(H, Hdc);
End;

Function F_WinSetWindowPos(H, HBehind, X, Y, Cx, Cy, Fl : LongInt) : LongInt;
Begin
  F_WinSetWindowPos := X_WinSetWindowPos(H, HBehind, X, Y, Cx, Cy, Fl);
End;

Function F_WinSetWindowPtr(H, Index, V : LongInt) : LongInt;
Begin
  F_WinSetWindowPtr := X_WinSetWindowPtr(H, Index, V);
End;

Function F_WinSetWindowText(H, P : LongInt) : LongInt;
Begin
  F_WinSetWindowText := X_WinSetWindowText(H, P);
End;

Function F_WinSetWindowThunkProc(H, Pfn : LongInt) : LongInt;
Begin
  F_WinSetWindowThunkProc := X_WinSetWindowThunkProc(H, Pfn);
End;

Function F_WinSetWindowULong(H, Index, V : LongInt) : LongInt;
Begin
  F_WinSetWindowULong := X_WinSetWindowULong(H, Index, V);
End;

Function F_WinSetWindowUShort(H, Index, V : LongInt) : LongInt;
Begin
  F_WinSetWindowUShort := X_WinSetWindowUShort(H, Index, V);
End;

Function F_WinShowCursor(H, Show : LongInt) : LongInt;
Begin
  F_WinShowCursor := X_WinShowCursor(H, Show);
End;

Function F_WinShowPointer(HDesk, Show : LongInt) : LongInt;
Begin
  F_WinShowPointer := X_WinShowPointer(HDesk, Show);
End;

Function F_WinShowTrackRect(H, FShow : LongInt) : LongInt;
Begin
  F_WinShowTrackRect := X_WinShowTrackRect(H, FShow);
End;

Function F_WinShowWindow(H, Show : LongInt) : LongInt;
Begin
  F_WinShowWindow := X_WinShowWindow(H, Show);
End;

Function F_WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt;
Begin
  F_WinStartTimer := X_WinStartTimer(Hab, H, Id, Dt);
End;

Function F_WINSTOPPROGRAM(H : LongInt) : LongInt;
Begin
  F_WINSTOPPROGRAM := X_WINSTOPPROGRAM(H);
End;

Function F_WinStopTimer(Hab, H, Id : LongInt) : LongInt;
Begin
  F_WinStopTimer := X_WinStopTimer(Hab, H, Id);
End;

Function F_WINSTPREGISTER(Hwnd : LongInt) : LongInt;
Begin
  F_WINSTPREGISTER := X_WINSTPREGISTER(Hwnd);
End;

Function F_WinStretchPointer(Hps, X, Y, Cx, Cy, H, Fs : LongInt) : LongInt;
Begin
  F_WinStretchPointer := X_WinStretchPointer(Hps, X, Y, Cx, Cy, H, Fs);
End;

Function F_WinSubclassWindow(H, Proc : LongInt) : LongInt;
Begin
  F_WinSubclassWindow := X_WinSubclassWindow(H, Proc);
End;

Function F_WinSubstituteStrings(H, PSrc, Cch, PDst : LongInt) : LongInt;
Begin
  F_WinSubstituteStrings := X_WinSubstituteStrings(H, PSrc, Cch, PDst);
End;

Function F_WinSubtractRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Begin
  F_WinSubtractRect := X_WinSubtractRect(Hab, PD, P1, P2);
End;

Function F_WINSWITCHPROGRAMREGISTER(Hwnd : LongInt) : LongInt;
Begin
  F_WINSWITCHPROGRAMREGISTER := X_WINSWITCHPROGRAMREGISTER(Hwnd);
End;

Function F_WINSWITCHTOPROGRAM(H : LongInt) : LongInt;
Begin
  F_WINSWITCHTOPROGRAM := X_WINSWITCHTOPROGRAM(H);
End;

Function F_WINSWITCHTOPROGRAM2(H, Fl : LongInt) : LongInt;
Begin
  F_WINSWITCHTOPROGRAM2 := X_WINSWITCHTOPROGRAM2(H, Fl);
End;

Function F_WINSWITCHTOTASKMANAGER : LongInt;
Begin
  F_WINSWITCHTOTASKMANAGER := X_WINSWITCHTOTASKMANAGER;
End;

Function F_WinSyncStartPgm(P : LongInt) : LongInt;
Begin
  F_WinSyncStartPgm := X_WinSyncStartPgm(P);
End;

Function F_WinSystemShutdown(Hab, Hmq : LongInt) : LongInt;
Begin
  F_WinSystemShutdown := X_WinSystemShutdown(Hab, Hmq);
End;

Function F_WinTerminate(Hab : LongInt) : LongInt;
Begin
  F_WinTerminate := X_WinTerminate(Hab);
End;

Function F_WINTERMINATEAPP(Happ : LongInt) : LongInt;
Begin
  F_WINTERMINATEAPP := X_WINTERMINATEAPP(Happ);
End;

Function F_WinTerminateShutdown : LongInt;
Begin
  F_WinTerminateShutdown := X_WinTerminateShutdown;
End;

Function F_WinTerminateSystem : LongInt;
Begin
  F_WinTerminateSystem := X_WinTerminateSystem;
End;

Function F_WinThreadAssocQueue(Hab, Hmq : LongInt) : LongInt;
Begin
  F_WinThreadAssocQueue := X_WinThreadAssocQueue(Hab, Hmq);
End;

Function F_WinThrow(P, V : LongInt) : LongInt;
Begin
  F_WinThrow := X_WinThrow(P, V);
End;

Function F_WinTrackRect(H, Hps, P : LongInt) : LongInt;
Begin
  F_WinTrackRect := X_WinTrackRect(H, Hps, P);
End;

Function F_WinTrackSeamless(H, P : LongInt) : LongInt;
Begin
  F_WinTrackSeamless := X_WinTrackSeamless(H, P);
End;

Function F_WinTranslateAccel(Hab, H, HAcc, P : LongInt) : LongInt;
Begin
  F_WinTranslateAccel := X_WinTranslateAccel(Hab, H, HAcc, P);
End;

Function F_WinTranslateChar(Hab, Ch : LongInt) : LongInt;
Begin
  F_WinTranslateChar := X_WinTranslateChar(Hab, Ch);
End;

Function F_WinUnionRect(Hab, PD, P1, P2 : LongInt) : LongInt;
Begin
  F_WinUnionRect := X_WinUnionRect(Hab, PD, P1, P2);
End;

Function F_WinUpdateWindow(H : LongInt) : LongInt;
Begin
  F_WinUpdateWindow := X_WinUpdateWindow(H);
End;

Function F_WinUpper(Hab, Cp, Cc, P : LongInt) : LongInt;
Begin
  F_WinUpper := X_WinUpper(Hab, Cp, Cc, P);
End;

Function F_WinUpperChar(Hab, Cp, Cc, C : LongInt) : LongInt;
Begin
  F_WinUpperChar := X_WinUpperChar(Hab, Cp, Cc, C);
End;

Function F_WinValidateRect(H, PRcl, Incl : LongInt) : LongInt;
Begin
  F_WinValidateRect := X_WinValidateRect(H, PRcl, Incl);
End;

Function F_WinValidateRegion(H, Hrgn, Incl : LongInt) : LongInt;
Begin
  F_WinValidateRegion := X_WinValidateRegion(H, Hrgn, Incl);
End;

Function F_WinVisRegionNotify(H, Fs : LongInt) : LongInt;
Begin
  F_WinVisRegionNotify := X_WinVisRegionNotify(H, Fs);
End;

Function F_WinVkeyGlyphCharXlate(Hab, Vk, Fs : LongInt) : LongInt;
Begin
  F_WinVkeyGlyphCharXlate := X_WinVkeyGlyphCharXlate(Hab, Vk, Fs);
End;

Function F_WinVkeyToScanId(Hab, Vk : LongInt) : LongInt;
Begin
  F_WinVkeyToScanId := X_WinVkeyToScanId(Hab, Vk);
End;

Function F_WinWaitEventSem(H, T : LongInt) : LongInt;
Begin
  F_WinWaitEventSem := X_WinWaitEventSem(H, T);
End;

Function F_WinWaitMsg(Hab, First, Last : LongInt) : LongInt;
Begin
  F_WinWaitMsg := X_WinWaitMsg(Hab, First, Last);
End;

Function F_WinWaitMuxWaitSem(H, T, PU : LongInt) : LongInt;
Begin
  F_WinWaitMuxWaitSem := X_WinWaitMuxWaitSem(H, T, PU);
End;

Function F_WinWakeThread(Hmq : LongInt) : LongInt;
Begin
  F_WinWakeThread := X_WinWakeThread(Hmq);
End;

Function F_WinWindowFromDC(Hdc : LongInt) : LongInt;
Begin
  F_WinWindowFromDC := X_WinWindowFromDC(Hdc);
End;

Function F_WinWindowFromID(HPar, Id : LongInt) : LongInt;
Begin
  F_WinWindowFromID := X_WinWindowFromID(HPar, Id);
End;

Function F_WinWindowFromPoint(HPar, PPtl, Children : LongInt) : LongInt;
Begin
  F_WinWindowFromPoint := X_WinWindowFromPoint(HPar, PPtl, Children);
End;

exports
  ShePIInitialise Index 2000 Name 'ShePIInitialise',
  WinQueryProfileInt Index 2001 Name 'WinQueryProfileInt',
  WinQueryProfileString Index 2002 Name 'WinQueryProfileString',
  WinWriteProfileString Index 2003 Name 'WinWriteProfileString',
  WinQueryProfileSize Index 2004 Name 'WinQueryProfileSize',
  WinQueryProfileData Index 2005 Name 'WinQueryProfileData',
  WinWriteProfileData Index 2006 Name 'WinWriteProfileData',
  PrfChangeWriteThru Index 2007 Name 'PrfChangeWriteThru',
  PMExecRegister Index 2008 Name 'PMExecRegister',
  ShePIInitIniFiles Index 2009 Name 'ShePIInitIniFiles',
  SheConvert190ProgramListTo300 Index 2010 Name 'SheConvert190ProgramListTo300',
  PrfQueryProfileInt Index 2011 Name 'PrfQueryProfileInt',
  PrfQueryProfileString Index 2012 Name 'PrfQueryProfileString',
  PrfWriteProfileString Index 2013 Name 'PrfWriteProfileString',
  PrfQueryProfileSize Index 2014 Name 'PrfQueryProfileSize',
  PrfQueryProfileData Index 2015 Name 'PrfQueryProfileData',
  PrfWriteProfileData Index 2016 Name 'PrfWriteProfileData',
  PrfOpenProfile Index 2017 Name 'PrfOpenProfile',
  PrfCloseProfile Index 2018 Name 'PrfCloseProfile',
  PrfReset Index 2019 Name 'PrfReset',
  PrfQueryProfile Index 2020 Name 'PrfQueryProfile',
  PrfAddProgram Index 2021 Name 'PrfAddProgram',
  PrfRemoveProgram Index 2022 Name 'PrfRemoveProgram',
  PrfChangeProgram Index 2023 Name 'PrfChangeProgram',
  PrfQueryDefinition Index 2024 Name 'PrfQueryDefinition',
  PrfQueryProgramTitles Index 2025 Name 'PrfQueryProgramTitles',
  PrfCreateGroup Index 2026 Name 'PrfCreateGroup',
  PrfQueryProgramHandle Index 2027 Name 'PrfQueryProgramHandle',
  PrfQueryProgramCategory Index 2028 Name 'PrfQueryProgramCategory',
  PrfDestroyGroup Index 2029 Name 'PrfDestroyGroup',
  SheProfileHook Index 2030 Name 'SheProfileHook',
  F_SHEINITIALIZEINIFILE Index 2031 Name 'SheInitializeIniFile',
  ShpPILockIniFile Index 2032 Name 'ShpPI16LockIniFile',
  ShpPIShutdown Index 2033 Name 'ShpPI16Shutdown',
  EnablePMPre Index 2034 Name 'EnablePMPre',
  InnerGreEntry Index 2035 Name 'InnerGreEntry',
  GreInitialize Index 2036 Name 'GreInitialize',
  GreEntry2 Index 2037 Name 'GreEntry2',
  GreEntry3 Index 2038 Name 'GreEntry3',
  GreEntry4 Index 2039 Name 'GreEntry4',
  GreEntry5 Index 2040 Name 'GreEntry5',
  GreEntry6 Index 2041 Name 'GreEntry6',
  GreEntry7 Index 2042 Name 'GreEntry7',
  GreEntry8 Index 2043 Name 'GreEntry8',
  GreEntry9 Index 2044 Name 'GreEntry9',
  GreEntry10 Index 2045 Name 'GreEntry10',
  GetDriverInfo Index 2046 Name 'GetDriverInfo',
  SetDriverInfo Index 2047 Name 'SetDriverInfo',
  PostDeviceModes Index 2048 Name 'PostDeviceModes',
  BitmapLimitWarning Index 2049 Name 'BitmapLimitWarning',
  PmWinGreEntry2 Index 2050 Name 'PmWinGreEntry2',
  PmWinGreEntry3 Index 2051 Name 'PmWinGreEntry3',
  PmWinGreEntry4 Index 2052 Name 'PmWinGreEntry4',
  PmWinGreEntry5 Index 2053 Name 'PmWinGreEntry5',
  PmWinGreEntry6 Index 2054 Name 'PmWinGreEntry6',
  PmWinGreEntry7 Index 2055 Name 'PmWinGreEntry7',
  PmWinGreEntry8 Index 2056 Name 'PmWinGreEntry8',
  PmWinGreEntry9 Index 2057 Name 'PmWinGreEntry9',
  PmWinGreEntry10 Index 2058 Name 'PmWinGreEntry10',
  SSAllocSeg Index 2059 Name 'SSAllocSeg',
  SSAllocHuge Index 2060 Name 'SSAllocHuge',
  SSFreeSeg Index 2061 Name 'SSFreeSeg',
  SSFlushSegs Index 2062 Name 'SSFlushSegs',
  RamSemRequest32 Index 2063 Name 'RamSemRequest16',
  RamSemClear32 Index 2064 Name 'RamSemClear16',
  F_WinQueryClassInfo Index 2065 Name 'WinQueryClassInfo',
  F_WinMultWindowFromIDs Index 2066 Name 'WinMultWindowFromIDs',
  F_WinLockWindow Index 2067 Name 'WinLockWindow',
  F_WinQueryWindowLockCount Index 2068 Name 'WinQueryWindowLockCount',
  F_WinLoadPointer Index 2069 Name 'WinLoadPointer',
  F_WinCreatePointer Index 2070 Name 'WinCreatePointer',
  F_WinDestroyPointer Index 2071 Name 'WinDestroyPointer',
  F_OldWinQueryPointerInfo Index 2072 Name 'OldWinQueryPointerInfo',
  F_WinQuerySysPointer Index 2073 Name 'WinQuerySysPointer',
  F_WinGetSysBitmap Index 2074 Name 'WinGetSysBitmap',
  F_WinQueryCursorInfo Index 2075 Name 'WinQueryCursorInfo',
  F_WinLoadAccelTable Index 2076 Name 'WinLoadAccelTable',
  F_WinCreateAccelTable Index 2077 Name 'WinCreateAccelTable',
  F_WinDestroyAccelTable Index 2078 Name 'WinDestroyAccelTable',
  F_WinCopyAccelTable Index 2079 Name 'WinCopyAccelTable',
  F_WinSetClipbrdData Index 2080 Name 'WinSetClipbrdData',
  F_WinQueryClipbrdFmtInfo Index 2081 Name 'WinQueryClipbrdFmtInfo',
  F_GpiLoadBitmap Index 2082 Name 'GpiLoadBitmap',
  F_WinLoadString Index 2083 Name 'WinLoadString',
  F_WinLoadMessage Index 2084 Name 'WinLoadMessage',
  F_WinSetRectEmpty Index 2085 Name 'WinSetRectEmpty',
  F_WinSetRect Index 2086 Name 'WinSetRect',
  F_WinCopyRect Index 2087 Name 'WinCopyRect',
  F_WinIsRectEmpty Index 2088 Name 'WinIsRectEmpty',
  F_WinPtInRect Index 2089 Name 'WinPtInRect',
  F_WinOffsetRect Index 2090 Name 'WinOffsetRect',
  F_WinInflateRect Index 2091 Name 'WinInflateRect',
  F_WinMakeRect Index 2092 Name 'WinMakeRect',
  F_WinMakePoints Index 2093 Name 'WinMakePoints',
  F_WinDefWindowProc Index 2094 Name 'WinDefWindowProc',
  F_WinDefDlgProc Index 2095 Name 'WinDefDlgProc',
  F_WinQueryHungProcess Index 2096 Name 'WinQueryHungProcess',
  F_WinLoadStringTable Index 2097 Name 'WinLoadStringTable',
  F_WinLoadVkeyGlyphXlatetbl Index 2098 Name 'WinLoadVkeyGlyphXlatetbl',
  F_WinLoadCharXlatetbl Index 2099 Name 'WinLoadCharXlatetbl',
  F_WinSetVkeyGlyphXlatetbl Index 2100 Name 'WinSetVkeyGlyphXlatetbl',
  F_WinQueryVkeyGlyphXlatetbl Index 2101 Name 'WinQueryVkeyGlyphXlatetbl',
  F_WinVkeyToScanId Index 2102 Name 'WinVkeyToScanID',
  F_WinQueryProcessCP Index 2103 Name 'WinQueryProcessCP',
  F_WinGetKeyState Index 2104 Name 'WinGetKeyState',
  F_WinSetCp Index 2105 Name 'WinSetCp',
  F_WinQueryCp Index 2106 Name 'WinQueryCp',
  F_WinQueryCpList Index 2107 Name 'WinQueryCpList',
  F_WinCpTranslateString Index 2108 Name 'WinCpTranslateString',
  F_WinCpTranslateChar Index 2109 Name 'WinCpTranslateChar',
  F_WinCompareStrings Index 2110 Name 'WinCompareStrings',
  F_WinUpper Index 2111 Name 'WinUpper',
  F_WinUpperChar Index 2112 Name 'WinUpperChar',
  F_WinNextChar Index 2113 Name 'WinNextChar',
  F_WinPrevChar Index 2114 Name 'WinPrevChar',
  F_WinCreateHeap Index 2115 Name 'WinCreateHeap',
  F_WinDestroyHeap Index 2116 Name 'WinDestroyHeap',
  F_WinAvailMem Index 2117 Name 'WinAvailMem',
  F_WinAllocMem Index 2118 Name 'WinAllocMem',
  F_WinReallocMem Index 2119 Name 'WinReallocMem',
  F_WinFreeMem Index 2120 Name 'WinFreeMem',
  F_WinLockHeap Index 2121 Name 'WinLockHeap',
  F_WinCreateAtomTable Index 2122 Name 'WinCreateAtomTable',
  F_WinDestroyAtomTable Index 2123 Name 'WinDestroyAtomTable',
  F_WinAddAtom Index 2124 Name 'WinAddAtom',
  F_WinFindAtom Index 2125 Name 'WinFindAtom',
  F_WinDeleteAtom Index 2126 Name 'WinDeleteAtom',
  F_WinQueryAtomUsage Index 2127 Name 'WinQueryAtomUsage',
  F_WinQueryAtomLength Index 2128 Name 'WinQueryAtomLength',
  F_WinQueryAtomName Index 2129 Name 'WinQueryAtomName',
  F_WinQuerySystemAtomTable Index 2130 Name 'WinQuerySystemAtomTable',
  F_WinSetLastError Index 2131 Name 'WinSetLastError',
  F_WinGetLastError Index 2132 Name 'WinGetLastError',
  F_WinGetErrorInfo Index 2133 Name 'WinGetErrorInfo',
  F_WinFreeErrorInfo Index 2134 Name 'WinFreeErrorInfo',
  F_WinInitialize Index 2135 Name 'WinInitialize',
  F_WinTerminate Index 2136 Name 'WinTerminate',
  F_WinCatch Index 2137 Name 'WinCatch',
  F_WinThrow Index 2138 Name 'WinThrow',
  F_WinQueryVersion Index 2139 Name 'WinQueryVersion',
  F_FsrSemExit Index 2140 Name 'FsrSemExit',
  F_FsrSemCheck Index 2141 Name 'FsrSemCheck',
  F_AabGetReg Index 2142 Name 'AabGetReg',
  F_AabSetReg Index 2143 Name 'AabSetReg',
  F_ValidateSelector Index 2144 Name 'ValidateSelector',
  F_LoadModuleHandle Index 2145 Name 'LoadModuleHandle',
  F_GetScreenSelector Index 2146 Name 'GetScreenSelector',
  F_IdentifyCodeSelector Index 2147 Name 'IdentifyCodeSelector',
  F_WinSetErrorInfo Index 2148 Name '_WinSetErrorInfo',
  F_WinTerminateSystem Index 2149 Name 'WinTerminateSystem',
  F_WinDefQueueProc Index 2150 Name 'WinDefQueueProc',
  F_WinVisRegionNotify Index 2151 Name 'WinVisRegionNotify',
  F_WinQueryKbdLayout Index 2152 Name 'WinQueryKbdLayout',
  F_WinSetKbdLayout Index 2153 Name 'WinSetKbdLayout',
  F_WinBuildPtrHandle Index 2154 Name 'WinBuildPtrHandle',
  F_WinCreateHelpInstance Index 2155 Name 'DumWinCreateHelpInstance',
  F_WinDestroyHelpInstance Index 2156 Name 'DimWinDestroyHelpInstance',
  F_WinAssociateHelpInstance Index 2157 Name 'DumWinAssociateHelpInstance',
  F_WinCreateHelpTable Index 2158 Name 'DimWinCreateHelpTable',
  F_WinLoadHelpTable Index 2159 Name 'DumWinLoadHelpTable',
  F_WinQueryHelpInstance Index 2160 Name 'DumWinQueryHelpInstance',
  F_DummyHelpEntry Index 2161 Name 'DummyHelpEntry',
  F_GetPMDDCodeSelector Index 2162 Name 'GetPMDDCodeSelector',
  F_WinQueryPwnd Index 2163 Name 'WinQueryPwnd',
  F_WinEnumVKeyScanIDs Index 2164 Name 'WinEnumVKeyScanIDs',
  F_WinLoadTranslationTable Index 2165 Name 'WinLoadTranslationTable',
  F_WinSetKbdLayout2 Index 2166 Name 'WinSetKbdLayout2',
  F_DebugInputEnable Index 2167 Name 'DebugInputEnable',
  F_DebugInput Index 2168 Name 'DebugInput',
  F_DebugOutput Index 2169 Name 'DebugOutput',
  F_DebugCurPos Index 2170 Name 'DebugCurPos',
  F_DebugCls Index 2171 Name 'DebugCls',
  F_DebugRedirect Index 2172 Name 'DebugRedirect',
  F_WinLangsupWindowProc Index 2173 Name 'WinLangsupWindowProc',
  F_WinLangsupDlgProc Index 2174 Name 'WinLangsupDlgProc',
  F_WinCreatePointerIndirect Index 2175 Name 'WinCreatePointerIndirect',
  F_WinQueryPointerInfo Index 2176 Name 'WinQueryPointerInfo',
  F_WinPortHoleUtil Index 2177 Name 'WinPortHoleUtil',
  F_WinCreateFarHeap Index 2178 Name 'WinCreateFarHeap',
  F_WinDestoryFarHeap Index 2179 Name 'WinDestroyFarHeap',
  F_WinAllocFarMem Index 2180 Name 'WinAllocFarMem',
  F_WinFreeFarMem Index 2181 Name 'WinFreeFarMem',
  F_WinReallocFarMem Index 2182 Name 'WinReallocFarMem',
  F_WinSetQueueProc Index 2183 Name 'WinSetQueueProc',
  FarFlushBufHook Index 3000 Name 'FarFlushBufHook',
  F_FNBADAPPDLGPROC Index 3001 Name 'fnBadAppDlgProc',
  F_InputGetDeviceInfo Index 3002 Name 'InputGetDeviceInfo16',
  F_LPFNICONWNDPROC Index 3003 Name 'lpfnIconWndProc',
  F_LPFNSHELLWNDPROC Index 3004 Name 'lpfnShellWndProc',
  F_SHESTARTLONGPROGRAM Index 3005 Name 'SheStartLongProgram',
  F_SHESYSTEMSHUTDOWN Index 3006 Name 'SheSystemShutdown',
  SheUpdateIniFile Index 3007 Name 'SheUpdateIniFile',
  F_SHLLOADPUBLICFONTS Index 3008 Name 'ShlLoadPublicFonts',
  F_SHLUNLOADPUBLICFONTS Index 3009 Name 'ShlUnloadPublicFonts',
  ShpLockProgramList Index 3010 Name 'ShpLockProgramList',
  ShpUnlockProgramList Index 3011 Name 'ShpUnlockProgramList',
  StartStartUpDotCmd Index 3012 Name 'StartStartUpDotCmd',
  F_STARTSYSTEMEXECUTABLES Index 3013 Name 'StartSystemExecutables',
  F_WinAlarm Index 3014 Name 'WinAlarm',
  F_WinBeginEnumWindows Index 3015 Name 'WinBeginEnumWindows',
  F_WinBeginPaint Index 3016 Name 'WinBeginPaint',
  F_WinBroadcastMsg Index 3017 Name 'WinBroadcastMsg',
  F_WinCancelMode Index 3018 Name 'WinCancelMode',
  F_WinCancelShutdown Index 3019 Name 'WinCancelShutdown',
  F_WinCreateMsgQueue Index 3020 Name 'WinCreateMsgQueue',
  F_WinCreateStdWindow Index 3021 Name 'WinCreateStdWindow',
  F_WinCreateWindow Index 3022 Name 'WinCreateWindow',
  F_WinDestroyMsgQueue Index 3023 Name 'WinDestroyMsgQueue',
  F_WinDestroyWindow Index 3024 Name 'WinDestroyWindow',
  F_WinDispatchMsg Index 3025 Name 'WinDispatchMsg',
  F_WinDrawText Index 3026 Name 'WinDrawText',
  F_WinEndPaint Index 3027 Name 'WinEndPaint',
  F_WinFillRect Index 3028 Name 'WinFillRect',
  F_WinGetMinWindowViewer Index 3029 Name 'WinGetMinWindowViewer',
  F_WinGetMsg Index 3030 Name 'WinGetMsg',
  F_WinGetNextWindow Index 3031 Name 'WinGetNextWindow',
  F_WinInitializeSystem Index 3032 Name 'WinInitializeSystem',
  F_WinInvalidateRect Index 3033 Name 'WinInvalidateRect',
  F_WinIsChild Index 3034 Name 'WinIsChild',
  F_WinIsWindow Index 3035 Name 'WinIsWindow',
  F_WinIsWindowVisible Index 3036 Name 'WinIsWindowVisible',
  F_WinLoadDlg Index 3037 Name 'WinLoadDlg',
  F_WinLockStartInput Index 3038 Name 'WinLockStartInput',
  F_WinMessageBox Index 3039 Name 'WinMessageBox',
  F_WinMsgSemWait Index 3040 Name 'WinMsgSemWait',
  F_WinOpenWindowDC Index 3041 Name 'WinOpenWindowDC',
  F_WinPeekMsg Index 3042 Name 'WinPeekMsg',
  F_WinPostMsg Index 3043 Name 'WinPostMsg',
  F_WinProcessDlg Index 3044 Name 'WinProcessDlg',
  F_WinQueryActiveWindow Index 3045 Name 'WinQueryActiveWindow',
  F_WinQueryAnchorBlock Index 3046 Name 'WinQueryAnchorBlock',
  F_WinQueryDesktopWindow Index 3047 Name 'WinQueryDesktopWindow',
  F_WinQueryFocus Index 3048 Name 'WinQueryFocus',
  F_WinQueryQueueInfo Index 3049 Name 'WinQueryQueueInfo',
  F_WinQuerySysModalWindow Index 3050 Name 'WinQuerySysModalWindow',
  F_WinQuerySysValue Index 3051 Name 'WinQuerySysValue',
  F_WinQueryWindow Index 3052 Name 'WinQueryWindow',
  F_WinQueryWindowPos Index 3053 Name 'WinQueryWindowPos',
  F_WinQueryWindowProcess Index 3054 Name 'WinQueryWindowProcess',
  F_WinQueryWindowRect Index 3055 Name 'WinQueryWindowRect',
  F_WinQueryWindowULong Index 3056 Name 'WinQueryWindowULong',
  F_WinQueryWindowUShort Index 3057 Name 'WinQueryWindowUShort',
  F_WinRegisterClass Index 3058 Name 'WinRegisterClass',
  F_WinResetSystem Index 3059 Name 'WinResetSystem',
  F_WinScreenSwitch Index 3060 Name 'WinScreenSwitch',
  F_WinSendDlgItemMsg Index 3061 Name 'WinSendDlgItemMsg',
  F_WinSendMsg Index 3062 Name 'WinSendMsg',
  F_WinSetActiveWindow Index 3063 Name 'WinSetActiveWindow',
  F_WinSetDlgItemText Index 3064 Name 'WinSetDlgItemText',
  F_WinSetFocus Index 3065 Name 'WinSetFocus',
  F_WinSetMultWindowPos Index 3066 Name 'WinSetMultWindowPos',
  F_WinSetParent Index 3067 Name 'WinSetParent',
  F_WinSetPresParam Index 3068 Name 'WinSetPresParam',
  F_WinSetSysModalWindow Index 3069 Name 'WinSetSysModalWindow',
  F_WinSetSysValue Index 3070 Name 'WinSetSysValue',
  F_WinSetWindowBits Index 3071 Name 'WinSetWindowBits',
  F_WinSetWindowPos Index 3072 Name 'WinSetWindowPos',
  F_WinSetWindowText Index 3073 Name 'WinSetWindowText',
  F_WinShowWindow Index 3074 Name 'WinShowWindow',
  F_WinSubclassWindow Index 3075 Name 'WinSubclassWindow',
  F_WinTerminateShutdown Index 3076 Name 'WinTerminateShutdown',
  F_WinTrackRect Index 3077 Name 'WinTrackRect',
  F_WinWindowFromID Index 3078 Name 'WinWindowFromID',
  WinAddProgram Index 3079 Name 'WinAddProgram',
  F_WINADDSWITCHENTRY Index 3080 Name 'WinAddSwitchEntry',
  WinAddToGroup Index 3081 Name 'WinAddToGroup',
  F_WinCalcFrameRect Index 3082 Name 'WinCalcFrameRect',
  F_WinCallHelpHook Index 3083 Name 'WinCallHelpHook',
  F_WinCallMsgFilter Index 3084 Name 'WinCallMsgFilter',
  WinCanTerminate Index 3085 Name 'WinCanTerminate',
  WinChangeProgram Index 3086 Name 'WinChangeProgram',
  F_WINCHANGESWITCHENTRY Index 3087 Name 'WinChangeSwitchEntry',
  F_WinCheckInput Index 3088 Name 'WinCheckInput',
  F_WinCloseClipbrd Index 3089 Name 'WinCloseClipbrd',
  F_WINCPLREGISTER Index 3090 Name 'WinCplRegister',
  F_WinCreateCursor Index 3091 Name 'WinCreateCursor',
  F_WinCreateDlg Index 3092 Name 'WinCreateDlg',
  F_WinCreateFrameControls Index 3093 Name 'WinCreateFrameControls',
  WinCreateGroup Index 3094 Name 'WinCreateGroup',
  F_WinCreateMenu Index 3095 Name 'WinCreateMenu',
  F_WINCREATESWITCHENTRY Index 3096 Name 'WinCreateSwitchEntry',
  F_WinDdeInitiate Index 3097 Name 'WinDdeInitiate',
  F_WinDdePostMsg Index 3098 Name 'WinDdePostMsg',
  F_WinDdeRespond Index 3099 Name 'WinDdeRespond',
  F_WinDebugBreak Index 3100 Name 'WinDebugBreak',
  F_WinDeleteLibrary Index 3101 Name 'WinDeleteLibrary',
  F_WinDeleteProcedure Index 3102 Name 'WinDeleteProcedure',
  F_WinDestroyAniPointer Index 3103 Name 'WinDestroyAniPointer',
  F_WinDestroyCursor Index 3104 Name 'WinDestroyCursor',
  WinDestroyGroup Index 3105 Name 'WinDestroyGroup',
  F_WinDismissDlg Index 3106 Name 'WinDismissDlg',
  F_WinDlgBox Index 3107 Name 'WinDlgBox',
  F_WinDrawBitmap Index 3108 Name 'WinDrawBitmap',
  F_WinDrawBorder Index 3109 Name 'WinDrawBorder',
  F_WinDrawPointer Index 3110 Name 'WinDrawPointer',
  F_WinEmptyClipbrd Index 3111 Name 'WinEmptyClipbrd',
  F_WinEnablePhysInput Index 3112 Name 'WinEnablePhysInput',
  F_WinEnableWindow Index 3113 Name 'WinEnableWindow',
  F_WinEnableWindowUpdate Index 3114 Name 'WinEnableWindowUpdate',
  F_WinEndEnumWindows Index 3115 Name 'WinEndEnumWindows',
  F_WINENDPROGRAM Index 3116 Name 'WinEndProgram',
  F_WINENDSESSION Index 3117 Name 'WinEndSession',
  F_WINENDWINDOWSESSION Index 3118 Name 'WinEndWindowSession',
  F_WinEnumClipbrdFmts Index 3119 Name 'WinEnumClipbrdFmts',
  F_WinEnumDlgItem Index 3120 Name 'WinEnumDlgItem',
  F_WinEqualRect Index 3121 Name 'WinEqualRect',
  F_WinExcludeUpdateRegion Index 3122 Name 'WinExcludeUpdateRegion',
  F_WinExplodeWindow Index 3123 Name 'WinExplodeWindow',
  F_WinFlashWindow Index 3124 Name 'WinFlashWindow',
  F_WinFocusChange Index 3125 Name 'WinFocusChange',
  F_WinForceMenuRedraw Index 3126 Name 'WinForceMenuRedraw',
  F_WinFormatFrame Index 3127 Name 'WinFormatFrame',
  F_WinGetClipPS Index 3128 Name 'WinGetClipPS',
  F_WinGetCurrentTime Index 3129 Name 'WinGetCurrentTime',
  F_WinGetDlgMsg Index 3130 Name 'WinGetDlgMsg',
  F_WinGetErasePS Index 3131 Name 'WinGetErasePS',
  F_WinGetFrameTreePPs Index 3132 Name 'WinGetFrameTreePPs',
  F_WinGetFrameTreePPSize Index 3133 Name 'WinGetFrameTreePPSize',
  F_WinGetMaxPosition Index 3134 Name 'WinGetMaxPosition',
  F_WinGetMinPosition Index 3135 Name 'WinGetMinPosition',
  F_WinGetPhysKeyState Index 3136 Name 'WinGetPhysKeyState',
  F_WinGetPS Index 3137 Name 'WinGetPS',
  F_WinGetScanState Index 3138 Name 'WinGetScanState',
  F_WinGetScreenPS Index 3139 Name 'WinGetScreenPS',
  WinHAPPfromPID Index 3140 Name 'WinHAPPfromPID',
  WinHSWITCHfromHAPP Index 3141 Name 'WinHSWITCHfromHAPP',
  WinInitializePL Index 3142 Name 'WinInitializePL',
  F_WININITSESSION Index 3143 Name 'WinInitSession',
  F_WININITSESSIONMGR Index 3144 Name 'WinInitSessionMgr',
  F_WININITSWENTRY Index 3145 Name 'WinInitSwEntry',
  F_WinInSendMsg Index 3146 Name 'WinInSendMsg',
  F_WININSTSTARTAPP Index 3147 Name 'WinInstStartApp',
  F_WinIntersectRect Index 3148 Name 'WinIntersectRect',
  F_WinInvalidateRegion Index 3149 Name 'WinInvalidateRegion',
  F_WinInvertRect Index 3150 Name 'WinInvertRect',
  F_WinIsPhysInputEnabled Index 3151 Name 'WinIsPhysInputEnabled',
  F_WinIsShuttingDown Index 3152 Name 'WinIsShuttingDown',
  F_WinIsThreadActive Index 3153 Name 'WinIsThreadActive',
  F_WinIsWindowEnabled Index 3154 Name 'WinIsWindowEnabled',
  F_WinIsWindowShowing Index 3155 Name 'WinIsWindowShowing',
  F_WinJiggleMouse Index 3156 Name 'WinJiggleMouse',
  F_WinLoadAniPointer Index 3157 Name 'WinLoadAniPointer',
  F_WinLoadLibrary Index 3158 Name 'WinLoadLibrary',
  F_WinLoadMenu Index 3159 Name 'WinLoadMenu',
  F_WinLoadProcedure Index 3160 Name 'WinLoadProcedure',
  F_WinLockInput Index 3161 Name 'WinLockInput',
  F_WinLockPointerUpdate Index 3162 Name 'WinLockPointerUpdate',
  F_WinLockVisRegions Index 3163 Name 'WinLockVisRegions',
  F_WinLockWindowUpdate Index 3164 Name 'WinLockWindowUpdate',
  F_WinMapDlgPoints Index 3165 Name 'WinMapDlgPoints',
  F_WinMapWindowPoints Index 3166 Name 'WinMapWindowPoints',
  F_WinMenuIndexFromID Index 3167 Name 'WinMenuIndexFromID',
  F_WinMsgMuxSemWait Index 3168 Name 'WinMsgMuxSemWait',
  F_WINNOSHUTDOWN Index 3169 Name 'WinNoShutdown',
  F_WinOpenClipbrd Index 3170 Name 'WinOpenClipbrd',
  F_WINPMFILEREGISTER Index 3171 Name 'WinPMFileRegister',
  F_WinPopupMenu Index 3172 Name 'WinPopupMenu',
  F_WinPostQueueMsg Index 3173 Name 'WinPostQueueMsg',
  F_WinQueryAccelTable Index 3174 Name 'WinQueryAccelTable',
  F_WinQueryAccelTableValue Index 3175 Name 'WinQueryAccelTableValue',
  F_WinQueryCapture Index 3176 Name 'WinQueryCapture',
  F_WinQueryCharXlatetbl Index 3177 Name 'WinQueryCharXlatetbl',
  F_WinQueryClassName Index 3178 Name 'WinQueryClassName',
  F_WinQueryClassThunkProc Index 3179 Name 'WinQueryClassThunkProc',
  F_WinQueryClipbrdData Index 3180 Name 'WinQueryClipbrdData',
  F_WinQueryClipbrdOwner Index 3181 Name 'WinQueryClipbrdOwner',
  F_WinQueryClipbrdViewer Index 3182 Name 'WinQueryClipbrdViewer',
  WinQueryDefinition Index 3183 Name 'WinQueryDefinition',
  F_WinQueryDesktopBkgnd Index 3184 Name 'WinQueryDesktopBkgnd',
  F_WinQueryDlgItemShort Index 3185 Name 'WinQueryDlgItemShort',
  F_WinQueryDlgItemText Index 3186 Name 'WinQueryDlgItemText',
  F_WinQueryDlgItemTextLength Index 3187 Name 'WinQueryDlgItemTextLength',
  F_WINQUERYEXTIDFOCUS Index 3188 Name 'WinQueryExtIDFocus',
  WinQueryFileExtOpts Index 3189 Name 'WinQueryFileExtOpts',
  F_WinQueryMenuData Index 3190 Name 'WinQueryMenuData',
  F_WinQueryMsgPos Index 3191 Name 'WinQueryMsgPos',
  F_WinQueryMsgTime Index 3192 Name 'WinQueryMsgTime',
  F_WinQueryObjectWindow Index 3193 Name 'WinQueryObjectWindow',
  F_WinQueryPointer Index 3194 Name 'WinQueryPointer',
  F_WinQueryPointerPos Index 3195 Name 'WinQueryPointerPos',
  F_WinQueryPresParam Index 3196 Name 'WinQueryPresParam',
  WinQueryProgramTitles Index 3197 Name 'WinQueryProgramTitles',
  WinQueryProgramType Index 3198 Name 'WinQueryProgramType',
  WinQueryProgramUse Index 3199 Name 'WinQueryProgramUse',
  F_WinQueryQueueStatus Index 3200 Name 'WinQueryQueueStatus',
  F_WinQuerySendMsg Index 3201 Name 'WinQuerySendMsg',
  F_WINQUERYSESSIONTITLE Index 3202 Name 'WinQuerySessionTitle',
  F_WinQueryState Index 3203 Name 'WinQueryState',
  F_WINQUERYSWITCHENTRY Index 3204 Name 'WinQuerySwitchEntry',
  F_WINQUERYSWITCHHANDLE Index 3205 Name 'WinQuerySwitchHandle',
  F_WINQUERYSWITCHLIST Index 3206 Name 'WinQuerySwitchList',
  F_WinQuerySysColor Index 3207 Name 'WinQuerySysColor',
  F_WINQUERYTASKSIZEPOS Index 3208 Name 'WinQueryTaskSizePos',
  F_WINQUERYTASKTITLE Index 3209 Name 'WinQueryTaskTitle',
  F_WinQueryUpdateRect Index 3210 Name 'WinQueryUpdateRect',
  F_WinQueryUpdateRegion Index 3211 Name 'WinQueryUpdateRegion',
  F_WinQueryWindowDC Index 3212 Name 'WinQueryWindowDC',
  F_WinQueryWindowModel Index 3213 Name 'WinQueryWindowModel',
  F_WinQueryWindowPtr Index 3214 Name 'WinQueryWindowPtr',
  F_WinQueryWindowSGId Index 3215 Name 'WinQueryWindowSGID',
  F_WinQueryWindowText Index 3216 Name 'WinQueryWindowText',
  F_WinQueryWindowTextLength Index 3217 Name 'WinQueryWindowTextLength',
  F_WinQueryWindowThunkProc Index 3218 Name 'WinQueryWindowThunkProc',
  WinQueryWorkplaceWindow Index 3219 Name 'WinQueryWorkplaceWindow',
  F_WinQueueFromId Index 3220 Name 'WinQueueFromID',
  F_WinRealizePalette Index 3221 Name 'WinRealizePalette',
  F_WinRegisterSeamlessProc Index 3222 Name 'WinRegisterSeamlessProc',
  F_WinRegisterUserDatatype Index 3223 Name 'WinRegisterUserDatatype',
  F_WinRegisterUserMsg Index 3224 Name 'WinRegisterUserMsg',
  F_WinRegisterWindowDestroy Index 3225 Name 'WinRegisterWindowDestroy',
  F_WinReleaseErasePS Index 3226 Name 'WinReleaseErasePS',
  F_WinReleaseHook Index 3227 Name 'WinReleaseHook',
  F_WinReleasePS Index 3228 Name 'WinReleasePS',
  WinRemoveFromGroup Index 3229 Name 'WinRemoveFromGroup',
  F_WinRemovePresParam Index 3230 Name 'WinRemovePresParam',
  WinRemoveProgram Index 3231 Name 'WinRemoveProgram',
  F_WINREMOVESWITCHENTRY Index 3232 Name 'WinRemoveSwitchEntry',
  F_WinReplyMsg Index 3233 Name 'WinReplyMsg',
  F_WinSaveWindowPos Index 3234 Name 'WinSaveWindowPos',
  F_WinScrollWindow Index 3235 Name 'WinScrollWindow',
  F_WinSeamlessBox Index 3236 Name 'WinSeamlessBox',
  F_WinSemEnter Index 3237 Name 'WinSemEnter',
  F_WinSemLeave Index 3238 Name 'WinSemLeave',
  F_WinSemQuery Index 3239 Name 'WinSemQuery',
  F_WinSendQueueMsg Index 3240 Name 'WinSendQueueMsg',
  F_WinSetAccelTable Index 3241 Name 'WinSetAccelTable',
  F_WinSetAccelTableValue Index 3242 Name 'WinSetAccelTableValue',
  F_WinSetAniPointer Index 3243 Name 'WinSetAniPointer',
  F_WinSetAtomTableOwner Index 3244 Name 'WinSetAtomTableOwner',
  F_WinSetCapture Index 3245 Name 'WinSetCapture',
  F_WinSetCharXlatetbl Index 3246 Name 'WinSetCharXlatetbl',
  F_WinSetClassMsgInterest Index 3247 Name 'WinSetClassMsgInterest',
  F_WinSetClassThunkProc Index 3248 Name 'WinSetClassThunkProc',
  F_WinSetClipbrdOwner Index 3249 Name 'WinSetClipbrdOwner',
  F_WinSetClipbrdViewer Index 3250 Name 'WinSetClipbrdViewer',
  F_WinSetDesktopBkgnd Index 3251 Name 'WinSetDesktopBkgnd',
  F_WinSetDlgItemShort Index 3252 Name 'WinSetDlgItemShort',
  F_WINSETEXTIDFOCUS Index 3253 Name 'WinSetExtIDFocus',
  F_WINSETFGNDWINDOW Index 3254 Name 'WinSetFgndWindow',
  WinSetFileExtOpts Index 3255 Name 'WinSetFileExtOpts',
  F_WinSetFrameTreePPs Index 3256 Name 'WinSetFrameTreePPs',
  F_WinSetHook Index 3257 Name 'WinSetHook',
  F_WinSetKeyboardStateTable Index 3258 Name 'WinSetKeyboardStateTable',
  F_WinSetMenuData Index 3259 Name 'WinSetMenuData',
  F_WinSetMsgInterest Index 3260 Name 'WinSetMsgInterest',
  F_WinSetMsgMode Index 3261 Name 'WinSetMsgMode',
  F_WinSetOwner Index 3262 Name 'WinSetOwner',
  F_WinSetPointer Index 3263 Name 'WinSetPointer',
  F_WinSetPointerOwner Index 3264 Name 'WinSetPointerOwner',
  F_WinSetPointerPos Index 3265 Name 'WinSetPointerPos',
  F_WinSetScanStateTable Index 3266 Name 'WinSetScanStateTable',
  F_WINSETSWENTRY Index 3267 Name 'WinSetSwEntry',
  F_WinSetSynchroMode Index 3268 Name 'WinSetSynchroMode',
  F_WinSetSysClipbrdViewer Index 3269 Name 'WinSetSysClipbrdViewer',
  F_WinSetSysColors Index 3270 Name 'WinSetSysColors',
  F_WINSETTITLE Index 3271 Name 'WinSetTitle',
  WinSetTitleAndIcon Index 3272 Name 'WinSetTitleAndIcon',
  F_WinSetWindowDC Index 3273 Name 'WinSetWindowDC',
  F_WinSetWindowPtr Index 3274 Name 'WinSetWindowPtr',
  F_WinSetWindowThunkProc Index 3275 Name 'WinSetWindowThunkProc',
  F_WinSetWindowULong Index 3276 Name 'WinSetWindowULong',
  F_WinSetWindowUShort Index 3277 Name 'WinSetWindowUShort',
  F_WinShowCursor Index 3278 Name 'WinShowCursor',
  F_WinShowPointer Index 3279 Name 'WinShowPointer',
  F_WinShowTrackRect Index 3280 Name 'WinShowTrackRect',
  WinStartApp Index 3281 Name 'WinStartApp',
  F_WinStartTimer Index 3282 Name 'WinStartTimer',
  F_WINSTOPPROGRAM Index 3283 Name 'WinStopProgram',
  F_WinStopTimer Index 3284 Name 'WinStopTimer',
  F_WINSTPREGISTER Index 3285 Name 'WinStpRegister',
  F_WinStretchPointer Index 3286 Name 'WinStretchPointer',
  F_WinSubstituteStrings Index 3287 Name 'WinSubstituteStrings',
  F_WinSubtractRect Index 3288 Name 'WinSubtractRect',
  F_WINSWITCHPROGRAMREGISTER Index 3289 Name 'WinSwitchProgramRegister',
  F_WINSWITCHTOPROGRAM2 Index 3290 Name 'WinSwitchToProgram2',
  F_WINSWITCHTOPROGRAM Index 3291 Name 'WinSwitchToProgram',
  F_WINSWITCHTOTASKMANAGER Index 3292 Name 'WinSwitchToTaskManager',
  F_WinSyncStartPgm Index 3293 Name 'WinSyncStartPgm',
  F_WinSystemShutdown Index 3294 Name 'WinSystemShutdown',
  F_WINTERMINATEAPP Index 3295 Name 'WinTerminateApp',
  F_WinThreadAssocQueue Index 3296 Name 'WinThreadAssocQueue',
  F_WinTrackSeamless Index 3297 Name 'WinTrackSeamless',
  F_WinTranslateAccel Index 3298 Name 'WinTranslateAccel',
  F_WinTranslateChar Index 3299 Name 'WinTranslateChar',
  F_WinUnionRect Index 3300 Name 'WinUnionRect',
  F_WinUpdateWindow Index 3301 Name 'WinUpdateWindow',
  F_WinValidateRect Index 3302 Name 'WinValidateRect',
  F_WinValidateRegion Index 3303 Name 'WinValidateRegion',
  F_WinVkeyGlyphCharXlate Index 3304 Name 'WinVkeyGlyphCharXlate',
  F_WinWaitMsg Index 3305 Name 'WinWaitMsg',
  F_WinWakeThread Index 3306 Name 'WinWakeThread',
  F_WinWindowFromDC Index 3307 Name 'WinWindowFromDC',
  F_WinWindowFromPoint Index 3308 Name 'WinWindowFromPoint',
  WinSetTitleAndHwndIcon Index 3309 Name 'WinSetTitleAndHwndIcon',
  WinTrackWindow Index 3310 Name 'WinTrackWindow',
  WinSetLangInfo Index 3500 Name 'WinSetLangInfo',
  WinQueryLangInfo Index 3501 Name 'WinQueryLangInfo',
  WinSetKbdLayer Index 3502 Name 'WinSetKbdLayer',
  WinQueryKbdLayer Index 3503 Name 'WinQueryKbdLayer',
  WinSetLangViewer Index 3504 Name 'WinSetLangViewer',
  WinQueryLangViewer Index 3505 Name 'WinQueryLangViewer',
  WinPourEvent Index 3600 Name 'WinPourEvent',
  WinSetMsgQimInfo Index 3601 Name 'WinSetMsgQimInfo',
  WinQueryMsgQimInfo Index 3602 Name 'WinQueryMsgQimInfo',
  Devmode_Call_16 Index 4000 Name 'Devmode_Call_16',
  Devname_Call_16 Index 4001 Name 'Devname_Call_16',
  Dispatch16Gate10 Index 4002 Name 'Dispatch16Gate10',
  Dispatch16Gate3 Index 4003 Name 'Dispatch16Gate3',
  Dispatch16Gate4 Index 4004 Name 'Dispatch16Gate4',
  Dispatch16Gate5 Index 4005 Name 'Dispatch16Gate5',
  Dispatch16Gate6 Index 4006 Name 'Dispatch16Gate6',
  Dispatch16Gate7 Index 4007 Name 'Dispatch16Gate7',
  Dispatch16Gate8 Index 4008 Name 'Dispatch16Gate8',
  Dispatch16Gate9 Index 4009 Name 'Dispatch16Gate9',
  Enable_Call_16 Index 4010 Name 'Enable_Call_16',
  F_FsrSemEnter Index 4011 Name 'FsrSemEnter',
  F_FsrSemEnter Index 4012 Name 'FsrSemEnterP',
  F_FsrSemLeave Index 4013 Name 'FsrSemLeave',
  PFN10R2 Index 4014 Name 'PFN10R2',
  PFN4R2 Index 4015 Name 'PFN4R2',
  PFN5R2 Index 4016 Name 'PFN5R2',
  PFN6R2 Index 4017 Name 'PFN6R2',
  PFN7R2 Index 4018 Name 'PFN7R2',
  PFN8R2 Index 4019 Name 'PFN8R2',
  PFN9R2 Index 4020 Name 'PFN9R2',
  DeleteBitmap16Call Index 4021 Name 'DeleteBitmap16Call',
  Do16CLI Index 4022 Name 'Do16CLI',
  Do16STI Index 4023 Name 'Do16STI',
  GRE16Callback Index 4024 Name 'GRE16Callback',
  Dispatch32Gate Index 4025 Name 'Dispatch32Gate',
  GRE16CallForwardReturn Index 4026 Name 'GRE16CallForwardReturn',
  FirePSProbe Index 4027 Name 'FirePSProbe',
  F_AAB32GETREG Index 5000 Name 'AAB32GETREG',
  F_AAB32SETREG Index 5001 Name 'AAB32SETREG',
  F_AbnormalProcessExit Index 5002 Name 'AbnormalProcessExit',
  F_DEBUG32CLS Index 5003 Name 'DEBUG32CLS',
  F_DEBUG32CURPOS Index 5004 Name 'DEBUG32CURPOS',
  F_DEBUG32INPUT Index 5005 Name 'DEBUG32INPUT',
  F_DEBUG32OUTPUT Index 5006 Name 'DEBUG32OUTPUT',
  F_DestroyTimers Index 5007 Name 'DestroyTimers',
  EDITAllocSpace Index 5008 Name 'EDITAllocSpace',
  EditAutoSize Index 5009 Name 'EditAutoSize',
  EditBackSpace Index 5010 Name 'EditBackSpace',
  EditChangeFocus Index 5011 Name 'EditChangeFocus',
  EditChangeSelection Index 5012 Name 'EditChangeSelection',
  EditChar Index 5013 Name 'EditChar',
  EditCheckScroll Index 5014 Name 'EditCheckScroll',
  EditClear Index 5015 Name 'EditClear',
  EditCopy Index 5016 Name 'EditCopy',
  EditCreate Index 5017 Name 'EditCreate',
  EditCreateCursor Index 5018 Name 'EditCreateCursor',
  EditCreatePassword Index 5019 Name 'EditCreatePassword',
  EditCut Index 5020 Name 'EditCut',
  EditCXFromICH Index 5021 Name 'EditCXFromICH',
  EditDrawSubString Index 5022 Name 'EditDrawSubString',
  EditGetFlags Index 5023 Name 'EditGetFlags',
  EditGetWindowRect Index 5024 Name 'EditGetWindowRect',
  EditICHFromPt Index 5025 Name 'EditICHFromPt',
  EditNotify Index 5026 Name 'EditNotify',
  EditPaint Index 5027 Name 'EditPaint',
  EditPaste Index 5028 Name 'EditPaste',
  EditPtFromICH Index 5029 Name 'EditPtFromICH',
  EditQueryPresParams Index 5030 Name 'EditQueryPresParams',
  EditReplace Index 5031 Name 'EditReplace',
  EditSetCursorPos Index 5032 Name 'EditSetCursorPos',
  EditSetFirstIndex Index 5033 Name 'EditSetFirstIndex',
  EditSetInsertMode Index 5034 Name 'EditSetInsertMode',
  EditSetSelection Index 5035 Name 'EditSetSelection',
  EditSetText Index 5036 Name 'EditSetText',
  EditSetWindowParams Index 5037 Name 'EditSetWindowParams',
  EditShowChange Index 5038 Name 'EditShowChange',
  EditStopMouseTracking Index 5039 Name 'EditStopMouseTracking',
  EditTimerScroll Index 5040 Name 'EditTimerScroll',
  EditTrackMouse Index 5041 Name 'EditTrackMouse',
  EditVirtualKey Index 5042 Name 'EditVirtualKey',
  EditWMChar Index 5043 Name 'EditWMChar',
  Far32LockupHook Index 5044 Name 'Far32LockupHook',
  F_FarCallHook Index 5045 Name 'FarCallHook',
  GetDriverInfo Index 5046 Name 'GetDriverInfo32',
  F_GpiLoadBitmap Index 5047 Name 'Gpi32LoadBitmap',
  Gre32Entry10 Index 5048 Name 'Gre32Entry10',
  Gre32Entry2 Index 5049 Name 'Gre32Entry2',
  Gre32Entry3 Index 5050 Name 'Gre32Entry3',
  Gre32Entry4 Index 5051 Name 'Gre32Entry4',
  Gre32Entry5 Index 5052 Name 'Gre32Entry5',
  Gre32Entry6 Index 5053 Name 'Gre32Entry6',
  Gre32Entry7 Index 5054 Name 'Gre32Entry7',
  Gre32Entry8 Index 5055 Name 'Gre32Entry8',
  Gre32Entry9 Index 5056 Name 'Gre32Entry9',
  GetIconWindowsEXE Index 5057 Name 'GetIconWindowsEXE',
  GetIconWindowsICO Index 5058 Name 'GetIconWindowsICO',
  InnerGre32Entry10 Index 5059 Name 'InnerGre32Entry10',
  InnerGre32Entry2 Index 5060 Name 'InnerGre32Entry2',
  InnerGre32Entry3 Index 5061 Name 'InnerGre32Entry3',
  InnerGre32Entry4 Index 5062 Name 'InnerGre32Entry4',
  InnerGre32Entry5 Index 5063 Name 'InnerGre32Entry5',
  InnerGre32Entry6 Index 5064 Name 'InnerGre32Entry6',
  InnerGre32Entry7 Index 5065 Name 'InnerGre32Entry7',
  InnerGre32Entry8 Index 5066 Name 'InnerGre32Entry8',
  InnerGre32Entry9 Index 5067 Name 'InnerGre32Entry9',
  F_InputGetDeviceInfo Index 5068 Name 'InputGetDeviceInfo',
  PMExecRegister Index 5069 Name 'PM32ExecRegister',
  PMReleaseMutexSem Index 5070 Name 'PMReleaseMutexSem',
  PMRequestMutexSem Index 5071 Name 'PMRequestMutexSem',
  PMRequestMutexSemSetWait Index 5072 Name 'PMRequestMutexSemSetWait',
  PostDeviceModes Index 5073 Name 'PostDeviceModes32',
  PrfAddProgram Index 5074 Name 'Prf32AddProgram',
  PrfChangeProgram Index 5075 Name 'Prf32ChangeProgram',
  PrfChangeWriteThru Index 5076 Name 'Prf32ChangeWriteThru',
  PrfCloseProfile Index 5077 Name 'Prf32CloseProfile',
  PrfCreateGroup Index 5078 Name 'Prf32CreateGroup',
  PrfDestroyGroup Index 5079 Name 'Prf32DestroyGroup',
  PrfOpenProfile Index 5080 Name 'Prf32OpenProfile',
  PrfQueryDefinition Index 5081 Name 'Prf32QueryDefinition',
  PrfQueryProfile Index 5082 Name 'Prf32QueryProfile',
  PrfQueryProfileData Index 5083 Name 'Prf32QueryProfileData',
  PrfQueryProfileInt Index 5084 Name 'Prf32QueryProfileInt',
  PrfQueryProfileSize Index 5085 Name 'Prf32QueryProfileSize',
  PrfQueryProfileString Index 5086 Name 'Prf32QueryProfileString',
  PrfQueryProgramCategory Index 5087 Name 'Prf32QueryProgramCategory',
  PrfQueryProgramHandle Index 5088 Name 'Prf32QueryProgramHandle',
  PrfQueryProgramTitles Index 5089 Name 'Prf32QueryProgramTitles',
  PrfRemoveProgram Index 5090 Name 'Prf32RemoveProgram',
  PrfReset Index 5091 Name 'Prf32Reset',
  PrfWriteProfileData Index 5092 Name 'Prf32WriteProfileData',
  PrfWriteProfileString Index 5093 Name 'Prf32WriteProfileString',
  PrfSuspendWriteToDisk Index 5094 Name 'PrfSuspendWriteToDisk',
  PrfWriteToDisk Index 5095 Name 'PrfWriteToDisk',
  RamSemClear32 Index 5096 Name 'RamSemClear32',
  RamSemRequest32 Index 5097 Name 'RamSemRequest32',
  SetDriverInfo Index 5098 Name 'SetDriverInfo32',
  ShePIInitIniFiles Index 5099 Name 'She32PIInitIniFiles',
  F_SHESYSTEMSHUTDOWN Index 5100 Name 'She32SystemShutdown',
  ShpPILockIniFile Index 5101 Name 'ShpPILockIniFile',
  ShpPIShutdown Index 5102 Name 'ShpPIShutdown',
  SLEC_InitPen Index 5103 Name 'SLEC_InitPen',
  SSAllocMem Index 5104 Name 'SSAllocMem',
  SSFreeMem Index 5105 Name 'SSFreeMem',
  F_STARTSYSTEMEXECUTABLES Index 5106 Name 'Start32SystemExecutables',
  F_StartTimer Index 5107 Name 'StartTimer',
  SetDeviceSurface Index 5108 Name 'SetDeviceSurface',
  ThkDos16SetFgnd Index 5109 Name 'ThkDos16SetFgnd',
  TidCurrent Index 5110 Name 'TidCurrent',
  F_WinAddAtom Index 5111 Name 'Win32AddAtom',
  F_WINADDSWITCHENTRY Index 5112 Name 'Win32AddSwitchEntry',
  F_WinAlarm Index 5113 Name 'Win32Alarm',
  F_WinBeginEnumWindows Index 5114 Name 'Win32BeginEnumWindows',
  F_WinBeginPaint Index 5115 Name 'Win32BeginPaint',
  F_WinBroadcastMsg Index 5116 Name 'Win32BroadcastMsg',
  F_WinCalcFrameRect Index 5117 Name 'Win32CalcFrameRect',
  F_WinCalcFrameRect Index 5118 Name 'WIN32CALCFRAMERECT',
  F_WinCallHelpHook Index 5119 Name 'Win32CallHelpHook',
  F_WinCallMsgFilter Index 5120 Name 'Win32CallMsgFilter',
  F_WinCancelShutdown Index 5121 Name 'Win32CancelShutdown',
  F_WINCHANGESWITCHENTRY Index 5122 Name 'Win32ChangeSwitchEntry',
  F_WinCheckInput Index 5123 Name 'Win32CheckInput',
  F_WinCloseClipbrd Index 5124 Name 'Win32CloseClipbrd',
  F_WinCompareStrings Index 5125 Name 'Win32CompareStrings',
  F_WinCopyAccelTable Index 5126 Name 'Win32CopyAccelTable',
  F_WinCopyRect Index 5127 Name 'Win32CopyRect',
  F_WinCpTranslateChar Index 5128 Name 'Win32CpTranslateChar',
  F_WinCpTranslateString Index 5129 Name 'Win32CpTranslateString',
  F_WinCreateAccelTable Index 5130 Name 'Win32CreateAccelTable',
  F_WinCreateAtomTable Index 5131 Name 'Win32CreateAtomTable',
  F_WinCreateCursor Index 5132 Name 'Win32CreateCursor',
  F_WinCreateDlg Index 5133 Name 'Win32CreateDlg',
  F_WinCreateFrameControls Index 5134 Name 'Win32CreateFrameControls',
  F_WinCreateMenu Index 5135 Name 'Win32CreateMenu',
  F_WinCreateMsgQueue Index 5136 Name 'Win32CreateMsgQueue',
  F_WinCreatePointer Index 5137 Name 'Win32CreatePointer',
  F_WinCreatePointerIndirect Index 5138 Name 'Win32CreatePointerIndirect',
  F_WinCreateStdWindow Index 5139 Name 'Win32CreateStdWindow',
  F_WINCREATESWITCHENTRY Index 5140 Name 'Win32CreateSwitchEntry',
  F_WinCreateWindow Index 5141 Name 'Win32CreateWindow',
  F_WinDdeInitiate Index 5142 Name 'Win32DdeInitiate',
  F_WinDdePostMsg Index 5143 Name 'Win32DdePostMsg',
  F_WinDdeRespond Index 5144 Name 'Win32DdeRespond',
  F_WIN32DEBUGBREAK Index 5145 Name 'Win32DebugBreak',
  F_WinDefDlgProc Index 5146 Name 'Win32DefDlgProc',
  F_WinDefWindowProc Index 5147 Name 'Win32DefWindowProc',
  F_WinDeleteAtom Index 5148 Name 'Win32DeleteAtom',
  F_WinDeleteLibrary Index 5149 Name 'Win32DeleteLibrary',
  F_WinDeleteProcedure Index 5150 Name 'Win32DeleteProcedure',
  F_WinDestroyAccelTable Index 5151 Name 'Win32DestroyAccelTable',
  F_WinDestroyAtomTable Index 5152 Name 'Win32DestroyAtomTable',
  F_WinDestroyCursor Index 5153 Name 'Win32DestroyCursor',
  F_WinDestroyMsgQueue Index 5154 Name 'Win32DestroyMsgQueue',
  F_WinDestroyPointer Index 5155 Name 'Win32DestroyPointer',
  F_WinDestroyWindow Index 5156 Name 'Win32DestroyWindow',
  F_WinDismissDlg Index 5157 Name 'Win32DismissDlg',
  F_WinDispatchMsg Index 5158 Name 'Win32DispatchMsg',
  F_WinDlgBox Index 5159 Name 'Win32DlgBox',
  F_WinDrawBitmap Index 5160 Name 'Win32DrawBitmap',
  F_WinDrawBorder Index 5161 Name 'Win32DrawBorder',
  F_WinDrawPointer Index 5162 Name 'Win32DrawPointer',
  F_WinDrawText Index 5163 Name 'Win32DrawText',
  F_WinEmptyClipbrd Index 5164 Name 'Win32EmptyClipbrd',
  F_WinEnablePhysInput Index 5165 Name 'Win32EnablePhysInput',
  F_WinEnableWindow Index 5166 Name 'Win32EnableWindow',
  F_WinEnableWindowUpdate Index 5167 Name 'Win32EnableWindowUpdate',
  F_WinEndEnumWindows Index 5168 Name 'Win32EndEnumWindows',
  F_WinEndPaint Index 5169 Name 'Win32EndPaint',
  F_WINENDPROGRAM Index 5170 Name 'Win32EndProgram',
  F_WinEnumClipbrdFmts Index 5171 Name 'Win32EnumClipbrdFmts',
  F_WinEnumDlgItem Index 5172 Name 'Win32EnumDlgItem',
  F_WinEqualRect Index 5173 Name 'Win32EqualRect',
  F_WinExcludeUpdateRegion Index 5174 Name 'Win32ExcludeUpdateRegion',
  F_WinExplodeWindow Index 5175 Name 'Win32ExplodeWindow',
  F_WinFillRect Index 5176 Name 'Win32FillRect',
  F_WinFindAtom Index 5177 Name 'Win32FindAtom',
  F_WinFlashWindow Index 5178 Name 'Win32FlashWindow',
  F_WinFocusChange Index 5179 Name 'Win32FocusChange',
  F_WinFreeErrorInfo Index 5180 Name 'Win32FreeErrorInfo',
  F_WinGetClipPS Index 5181 Name 'Win32GetClipPS',
  F_WinGetCurrentTime Index 5182 Name 'Win32GetCurrentTime',
  F_WinGetDlgMsg Index 5183 Name 'Win32GetDlgMsg',
  F_WinGetErasePS Index 5184 Name 'Win32GetErasePS',
  F_WinGetErrorInfo Index 5185 Name 'Win32GetErrorInfo',
  F_WinGetFrameTreePPs Index 5186 Name 'Win32GetFrameTreePPs',
  F_WinGetFrameTreePPSize Index 5187 Name 'Win32GetFrameTreePPSize',
  F_WinGetKeyState Index 5188 Name 'Win32GetKeyState',
  F_WinGetLastError Index 5189 Name 'Win32GetLastError',
  F_WinGetMaxPosition Index 5190 Name 'Win32GetMaxPosition',
  F_WinGetMinPosition Index 5191 Name 'Win32GetMinPosition',
  F_WinGetMsg Index 5192 Name 'Win32GetMsg',
  F_WinGetNextWindow Index 5193 Name 'Win32GetNextWindow',
  F_WinGetPhysKeyState Index 5194 Name 'Win32GetPhysKeyState',
  F_WinGetPS Index 5195 Name 'Win32GetPS',
  F_WinGetScreenPS Index 5196 Name 'Win32GetScreenPS',
  F_WinGetSysBitmap Index 5197 Name 'Win32GetSysBitmap',
  WinHAPPfromPID Index 5198 Name 'Win32HAPPfromPID',
  WinHSWITCHfromHAPP Index 5199 Name 'Win32HSWITCHfromHAPP',
  F_WinInflateRect Index 5200 Name 'Win32InflateRect',
  F_WinInitialize Index 5201 Name 'Win32Initialize',
  F_WinInSendMsg Index 5202 Name 'Win32InSendMsg',
  F_WinIntersectRect Index 5203 Name 'Win32IntersectRect',
  F_WinInvalidateRect Index 5204 Name 'Win32InvalidateRect',
  F_WinInvalidateRegion Index 5205 Name 'Win32InvalidateRegion',
  F_WinInvertRect Index 5206 Name 'Win32InvertRect',
  F_WinIsChild Index 5207 Name 'Win32IsChild',
  F_WinIsPhysInputEnabled Index 5208 Name 'Win32IsPhysInputEnabled',
  F_WinIsRectEmpty Index 5209 Name 'Win32IsRectEmpty',
  F_WinIsThreadActive Index 5210 Name 'Win32IsThreadActive',
  F_WinIsWindow Index 5211 Name 'Win32IsWindow',
  F_WinIsWindowEnabled Index 5212 Name 'Win32IsWindowEnabled',
  F_WinIsWindowShowing Index 5213 Name 'Win32IsWindowShowing',
  F_WinIsWindowVisible Index 5214 Name 'Win32IsWindowVisible',
  F_WinJiggleMouse Index 5215 Name 'Win32JiggleMouse',
  F_WinLoadAccelTable Index 5216 Name 'Win32LoadAccelTable',
  F_WinLoadCharXlatetbl Index 5217 Name 'Win32LoadCharXlatetbl',
  F_WinLoadDlg Index 5218 Name 'Win32LoadDlg',
  F_WinLoadLibrary Index 5219 Name 'Win32LoadLibrary',
  F_WinLoadMenu Index 5220 Name 'Win32LoadMenu',
  F_WinLoadMessage Index 5221 Name 'Win32LoadMessage',
  F_WinLoadPointer Index 5222 Name 'Win32LoadPointer',
  F_WinLoadProcedure Index 5223 Name 'Win32LoadProcedure',
  F_WinLoadString Index 5224 Name 'Win32LoadString',
  F_WinLockInput Index 5225 Name 'Win32LockInput',
  F_WinLockPointerUpdate Index 5226 Name 'Win32LockPointerUpdate',
  F_WinLockVisRegions Index 5227 Name 'Win32LockVisRegions',
  F_WinLockWindowUpdate Index 5228 Name 'Win32LockWindowUpdate',
  F_WinMakePoints Index 5229 Name 'Win32MakePoints',
  F_WinMakeRect Index 5230 Name 'Win32MakeRect',
  F_WinMapDlgPoints Index 5231 Name 'Win32MapDlgPoints',
  F_WinMapWindowPoints Index 5232 Name 'Win32MapWindowPoints',
  F_WinMessageBox Index 5233 Name 'Win32MessageBox',
  F_WinMoveCursor Index 5234 Name 'Win32MoveCursor',
  F_WinMsgMuxSemWait Index 5235 Name 'Win32MsgMuxSemWait',
  F_WinMsgSemWait Index 5236 Name 'Win32MsgSemWait',
  F_WinMultWindowFromIDs Index 5237 Name 'Win32MultWindowFromIDs',
  F_WinNextChar Index 5238 Name 'Win32NextChar',
  F_WinOffsetRect Index 5239 Name 'Win32OffsetRect',
  F_WinOpenClipbrd Index 5240 Name 'Win32OpenClipbrd',
  F_WinOpenWindowDC Index 5241 Name 'Win32OpenWindowDC',
  F_WinPeekMsg Index 5242 Name 'Win32PeekMsg',
  F_WinPopupMenu Index 5243 Name 'Win32PopupMenu',
  F_WinPostMsg Index 5244 Name 'Win32PostMsg',
  F_WinPostQueueMsg Index 5245 Name 'Win32PostQueueMsg',
  F_WinPrevChar Index 5246 Name 'Win32PrevChar',
  F_WinProcessDlg Index 5247 Name 'Win32ProcessDlg',
  F_WinPtInRect Index 5248 Name 'Win32PtInRect',
  F_WinQueryAccelTable Index 5249 Name 'Win32QueryAccelTable',
  F_WinQueryAccelTableValue Index 5250 Name 'Win32QueryAccelTableValue',
  F_WinQueryActiveWindow Index 5251 Name 'Win32QueryActiveWindow',
  F_WinQueryAnchorBlock Index 5252 Name 'Win32QueryAnchorBlock',
  F_WinQueryAtomLength Index 5253 Name 'Win32QueryAtomLength',
  F_WinQueryAtomName Index 5254 Name 'Win32QueryAtomName',
  F_WinQueryAtomUsage Index 5255 Name 'Win32QueryAtomUsage',
  F_WinQueryCapture Index 5256 Name 'Win32QueryCapture',
  F_WinQueryClassInfo Index 5257 Name 'Win32QueryClassInfo',
  F_WinQueryClassName Index 5258 Name 'Win32QueryClassName',
  F_WinQueryClassThunkProc Index 5259 Name 'Win32QueryClassThunkProc',
  F_WinQueryClipbrdData Index 5260 Name 'Win32QueryClipbrdData',
  F_WinQueryClipbrdFmtInfo Index 5261 Name 'Win32QueryClipbrdFmtInfo',
  F_WinQueryClipbrdOwner Index 5262 Name 'Win32QueryClipbrdOwner',
  F_WinQueryClipbrdViewer Index 5263 Name 'Win32QueryClipbrdViewer',
  F_WinQueryCp Index 5264 Name 'Win32QueryCp',
  F_WinQueryCpList Index 5265 Name 'Win32QueryCpList',
  F_WinQueryCursorInfo Index 5266 Name 'Win32QueryCursorInfo',
  F_WinQueryDesktopBkgnd Index 5267 Name 'Win32QueryDesktopBkgnd',
  F_WinQueryDesktopWindow Index 5268 Name 'Win32QueryDesktopWindow',
  F_WinQueryDlgItemShort Index 5269 Name 'Win32QueryDlgItemShort',
  F_WinQueryDlgItemText Index 5270 Name 'Win32QueryDlgItemText',
  F_WinQueryDlgItemTextLength Index 5271 Name 'Win32QueryDlgItemTextLength',
  F_WinQueryFocus Index 5272 Name 'Win32QueryFocus',
  F_WinQueryMsgPos Index 5273 Name 'Win32QueryMsgPos',
  F_WinQueryMsgTime Index 5274 Name 'Win32QueryMsgTime',
  F_WinQueryObjectWindow Index 5275 Name 'Win32QueryObjectWindow',
  WinQueryPaletteMode Index 5276 Name 'WinQueryPaletteMode',
  F_WinQueryPointer Index 5277 Name 'Win32QueryPointer',
  F_WinQueryPointerInfo Index 5278 Name 'Win32QueryPointerInfo',
  F_WinQueryPointerPos Index 5279 Name 'Win32QueryPointerPos',
  F_WinQueryPresParam Index 5280 Name 'Win32QueryPresParam',
  F_WinQueryProcessCP Index 5281 Name 'Win32QueryProcessCP',
  F_WinQueryQueueInfo Index 5282 Name 'Win32QueryQueueInfo',
  F_WinQueryQueueStatus Index 5283 Name 'Win32QueryQueueStatus',
  F_WinQuerySendMsg Index 5284 Name 'Win32QuerySendMsg',
  F_WINQUERYSESSIONTITLE Index 5285 Name 'Win32QuerySessionTitle',
  F_WINQUERYSWITCHENTRY Index 5286 Name 'Win32QuerySwitchEntry',
  F_WINQUERYSWITCHHANDLE Index 5287 Name 'Win32QuerySwitchHandle',
  F_WINQUERYSWITCHLIST Index 5288 Name 'Win32QuerySwitchList',
  F_WinQuerySysColor Index 5289 Name 'Win32QuerySysColor',
  F_WinQuerySysModalWindow Index 5290 Name 'Win32QuerySysModalWindow',
  F_WinQuerySysPointer Index 5291 Name 'Win32QuerySysPointer',
  Win32QuerySysPointerData Index 5292 Name 'Win32QuerySysPointerData',
  F_WinQuerySystemAtomTable Index 5293 Name 'Win32QuerySystemAtomTable',
  F_WinQuerySysValue Index 5294 Name 'Win32QuerySysValue',
  F_WINQUERYTASKSIZEPOS Index 5295 Name 'Win32QueryTaskSizePos',
  F_WINQUERYTASKTITLE Index 5296 Name 'Win32QueryTaskTitle',
  F_WinQueryUpdateRect Index 5297 Name 'Win32QueryUpdateRect',
  F_WinQueryUpdateRegion Index 5298 Name 'Win32QueryUpdateRegion',
  F_WinQueryVersion Index 5299 Name 'Win32QueryVersion',
  Win32QueryVisibleRegion Index 5300 Name 'Win32QueryVisibleRegion',
  F_WinQueryWindow Index 5301 Name 'Win32QueryWindow',
  F_WinQueryWindowDC Index 5302 Name 'Win32QueryWindowDC',
  F_WinQueryWindowModel Index 5303 Name 'Win32QueryWindowModel',
  F_WinQueryWindowPos Index 5304 Name 'Win32QueryWindowPos',
  F_WinQueryWindowProcess Index 5305 Name 'Win32QueryWindowProcess',
  F_WinQueryWindowPtr Index 5306 Name 'Win32QueryWindowPtr',
  F_WinQueryWindowRect Index 5307 Name 'Win32QueryWindowRect',
  F_WinQueryWindowText Index 5308 Name 'Win32QueryWindowText',
  F_WinQueryWindowTextLength Index 5309 Name 'Win32QueryWindowTextLength',
  F_WinQueryWindowThunkProc Index 5310 Name 'Win32QueryWindowThunkProc',
  F_WinQueryWindowULong Index 5311 Name 'Win32QueryWindowULong',
  F_WinQueryWindowUShort Index 5312 Name 'Win32QueryWindowUShort',
  F_WinQueueFromId Index 5313 Name 'Win32QueueFromID',
  F_WinRealizePalette Index 5314 Name 'Win32RealizePalette',
  F_WinRegisterClass Index 5315 Name 'Win32RegisterClass',
  Win32RegisterPen Index 5316 Name 'Win32RegisterPen',
  F_WinRegisterSeamlessProc Index 5317 Name 'Win32RegisterSeamlessProc',
  F_WinRegisterUserDatatype Index 5318 Name 'Win32RegisterUserDatatype',
  F_WinRegisterUserMsg Index 5319 Name 'Win32RegisterUserMsg',
  F_WinReleaseErasePS Index 5320 Name 'Win32ReleaseErasePS',
  F_WinReleaseHook Index 5321 Name 'Win32ReleaseHook',
  F_WinReleasePS Index 5322 Name 'Win32ReleasePS',
  F_WinRemovePresParam Index 5323 Name 'Win32RemovePresParam',
  F_WINREMOVESWITCHENTRY Index 5324 Name 'Win32RemoveSwitchEntry',
  F_WinReplyMsg Index 5325 Name 'Win32ReplyMsg',
  F_WinRequestMutexSem Index 5326 Name 'Win32RequestMutexSem',
  F_WinSaveWindowPos Index 5327 Name 'Win32SaveWindowPos',
  F_WinScrollWindow Index 5328 Name 'Win32ScrollWindow',
  F_WinSeamlessBox Index 5329 Name 'Win32SeamlessBox',
  F_WinSemEnter Index 5330 Name 'Win32SemEnter',
  F_WinSemLeave Index 5331 Name 'Win32SemLeave',
  F_WinSemQuery Index 5332 Name 'Win32SemQuery',
  F_WinSendDlgItemMsg Index 5333 Name 'Win32SendDlgItemMsg',
  F_WinSendMsg Index 5334 Name 'Win32SendMsg',
  F_WinSetAccelTable Index 5335 Name 'Win32SetAccelTable',
  F_WinSetAccelTableValue Index 5336 Name 'Win32SetAccelTableValue',
  F_WinSetActiveWindow Index 5337 Name 'Win32SetActiveWindow',
  F_WinSetCapture Index 5338 Name 'Win32SetCapture',
  F_WinSetCharXlatetbl Index 5339 Name 'Win32SetCharXlateTbl',
  F_WinSetClassMsgInterest Index 5340 Name 'Win32SetClassMsgInterest',
  F_WinSetClassThunkProc Index 5341 Name 'Win32SetClassThunkProc',
  F_WinSetClipbrdData Index 5342 Name 'Win32SetClipbrdData',
  F_WinSetClipbrdOwner Index 5343 Name 'Win32SetClipbrdOwner',
  F_WinSetClipbrdViewer Index 5344 Name 'Win32SetClipbrdViewer',
  F_WinSetCp Index 5345 Name 'Win32SetCp',
  F_WinSetDesktopBkgnd Index 5346 Name 'Win32SetDesktopBkgnd',
  F_WinSetDlgItemShort Index 5347 Name 'Win32SetDlgItemShort',
  F_WinSetDlgItemText Index 5348 Name 'Win32SetDlgItemText',
  F_WinSetErrorInfo Index 5349 Name 'Win32SetErrorInfo',
  F_WinSetFocus Index 5350 Name 'Win32SetFocus',
  F_WinSetFrameTreePPs Index 5351 Name 'Win32SetFrameTreePPs',
  F_WinSetHook Index 5352 Name 'Win32SetHook',
  F_WinSetKeyboardStateTable Index 5353 Name 'Win32SetKeyboardStateTable',
  F_WinSetMsgInterest Index 5354 Name 'Win32SetMsgInterest',
  F_WinSetMsgMode Index 5355 Name 'Win32SetMsgMode',
  F_WinSetMultWindowPos Index 5356 Name 'Win32SetMultWindowPos',
  F_WinSetOwner Index 5357 Name 'Win32SetOwner',
  WinSetPaletteMode Index 5358 Name 'WinSetPaletteMode',
  F_WinSetParent Index 5359 Name 'Win32SetParent',
  F_WinSetPointer Index 5360 Name 'Win32SetPointer',
  F_WinSetPointerOwner Index 5361 Name 'Win32SetPointerOwner',
  F_WinSetPointerPos Index 5362 Name 'Win32SetPointerPos',
  F_WinSetPresParam Index 5363 Name 'Win32SetPresParam',
  F_WinSetRect Index 5364 Name 'Win32SetRect',
  F_WinSetRectEmpty Index 5365 Name 'Win32SetRectEmpty',
  F_WinSetSynchroMode Index 5366 Name 'Win32SetSynchroMode',
  F_WinSetSysClipbrdViewer Index 5367 Name 'Win32SetSysClipbrdViewer',
  F_WinSetSysColors Index 5368 Name 'Win32SetSysColors',
  F_WinSetSysFont Index 5369 Name 'Win32SetSysFont',
  F_WinSetSysModalWindow Index 5370 Name 'Win32SetSysModalWindow',
  Win32SetSysPointerData Index 5371 Name 'Win32SetSysPointerData',
  F_WinSetSysValue Index 5372 Name 'Win32SetSysValue',
  F_WinVisRegionNotify Index 5373 Name 'Win32SetVisibleRegionNotify',
  F_WinSetWindowBits Index 5374 Name 'Win32SetWindowBits',
  F_WinSetWindowPos Index 5375 Name 'Win32SetWindowPos',
  F_WinSetWindowPtr Index 5376 Name 'Win32SetWindowPtr',
  F_WinSetWindowText Index 5377 Name 'Win32SetWindowText',
  F_WinSetWindowThunkProc Index 5378 Name 'Win32SetWindowThunkProc',
  F_WinSetWindowULong Index 5379 Name 'Win32SetWindowULong',
  F_WinSetWindowUShort Index 5380 Name 'Win32SetWindowUShort',
  F_WinShowCursor Index 5381 Name 'Win32ShowCursor',
  F_WinShowPointer Index 5382 Name 'Win32ShowPointer',
  F_WinShowTrackRect Index 5383 Name 'Win32ShowTrackRect',
  F_WinShowWindow Index 5384 Name 'Win32ShowWindow',
  WinStartApp Index 5385 Name 'Win32StartApp',
  F_WinStartTimer Index 5386 Name 'Win32StartTimer',
  F_WinStopTimer Index 5387 Name 'Win32StopTimer',
  F_WinStretchPointer Index 5388 Name 'Win32StretchPointer',
  F_WinSubclassWindow Index 5389 Name 'Win32SubclassWindow',
  F_WinSubstituteStrings Index 5390 Name 'Win32SubstituteStrings',
  F_WinSubtractRect Index 5391 Name 'Win32SubtractRect',
  F_WINSWITCHPROGRAMREGISTER Index 5392 Name 'Win32SwitchProgramRegister',
  F_WINSWITCHTOPROGRAM Index 5393 Name 'Win32SwitchToProgram',
  F_WINSWITCHTOPROGRAM2 Index 5394 Name 'Win32SwitchToProgram2',
  F_WinSystemShutdown Index 5395 Name 'Win32SystemShutdown',
  F_WinTerminate Index 5396 Name 'Win32Terminate',
  F_WINTERMINATEAPP Index 5397 Name 'Win32TerminateApp',
  F_WinThreadAssocQueue Index 5398 Name 'Win32ThreadAssocQueue',
  F_WinTrackRect Index 5399 Name 'Win32TrackRect',
  F_WinTrackSeamless Index 5400 Name 'Win32TrackSeamless',
  F_WinTranslateAccel Index 5401 Name 'Win32TranslateAccel',
  F_WinUnionRect Index 5402 Name 'Win32UnionRect',
  F_WinUpdateWindow Index 5403 Name 'Win32UpdateWindow',
  F_WinUpper Index 5404 Name 'Win32Upper',
  F_WinUpperChar Index 5405 Name 'Win32UpperChar',
  F_WinValidateRect Index 5406 Name 'Win32ValidateRect',
  F_WinValidateRegion Index 5407 Name 'Win32ValidateRegion',
  F_WinVisRegionNotify Index 5408 Name 'Win32VisRegionNotify',
  F_WinWaitEventSem Index 5409 Name 'Win32WaitEventSem',
  F_WinWaitMsg Index 5410 Name 'Win32WaitMsg',
  F_WinWaitMuxWaitSem Index 5411 Name 'Win32WaitMuxWaitSem',
  F_WinWakeThread Index 5412 Name 'Win32WakeThread',
  F_WinWindowFromDC Index 5413 Name 'Win32WindowFromDC',
  F_WinWindowFromID Index 5414 Name 'Win32WindowFromID',
  F_WinWindowFromPoint Index 5415 Name 'Win32WindowFromPoint',
  WinAugmentPointer Index 5416 Name 'WinAugmentPointer',
  WinMessageBox2 Index 5417 Name 'WinMessageBox2',
  WinMspAlloc Index 5418 Name 'WinMspAlloc',
  WinMspFree Index 5419 Name 'WinMspFree',
  WinMspInit Index 5420 Name 'WinMspInit',
  F_WINPROCESSHOTKEY Index 5421 Name 'WinProcessHotKey',
  F_WinProfControl Index 5422 Name 'WinProfControl',
  WinXXAllocFill Index 5423 Name 'WinXXAllocFill',
  WinXXAllocMem Index 5424 Name 'WinXXAllocMem',
  WinXXCreateHeap Index 5425 Name 'WinXXCreateHeap',
  WinXXDestroyHeap Index 5426 Name 'WinXXDestroyHeap',
  WinXXFreeMem Index 5427 Name 'WinXXFreeMem',
  WinXXIsMemInHeap Index 5428 Name 'WinXXIsMemInHeap',
  WinXXReallocMem Index 5429 Name 'WinXXReallocMem',
  PMHeapIsMemInChain Index 5430 Name 'PMHeapIsMemInChain',
  F_WINNOSHUTDOWN Index 5431 Name 'Win32NoShutdown',
  WinDrawTabbedText Index 5432 Name 'WinDrawTabbedText',
  Win32QueryPointerClipRect Index 5433 Name 'Win32QueryPointerClipRect',
  Win32SetPointerClipRect Index 5434 Name 'Win32SetPointerClipRect',
  Win32WaitMsgTimeout Index 5436 Name 'Win32WaitMsgTimeout',
  Win32IsWindowOfClass Index 5437 Name 'Win32IsWindowOfClass',
  F_WinSetAtomTableOwner Index 5438 Name 'Win32SetAtomTableOwner',
  WinXXQueryMemSize Index 5439 Name 'WinXXQueryMemSize',
  Win32SetClipRegion Index 5440 Name 'Win32SetClipRegion',
  Win32QueryClipRegion Index 5441 Name 'Win32QueryClipRegion',
  Win32AddClipbrdViewer Index 5442 Name 'Win32AddClipbrdViewer',
  Win32RemoveClipbrdViewer Index 5443 Name 'Win32RemoveClipbrdViewer',
  Win32QueryClipbrdViewerChain Index 5444 Name 'Win32QueryClipbrdViewerChain',
  Win32IncrementAtomUsage Index 5445 Name 'Win32IncrementAtomUsage',
  DaxQueryOpenClipbrdWindow Index 5446 Name 'DaxQueryOpenClipbrdWindow',
  WinQueryDaxData Index 5447 Name 'WinQueryDaxData',
  WinSetDaxData Index 5448 Name 'WinSetDaxData',
  WinEnumProperties Index 5449 Name 'WinEnumProperties',
  WinQueryProperty Index 5450 Name 'WinQueryProperty',
  WinRemoveProperty Index 5451 Name 'WinRemoveProperty',
  WinSetProperty Index 5452 Name 'WinSetProperty',
  WinEnumClassProperties Index 5453 Name 'WinEnumClassProperties',
  WinQueryClassProperty Index 5454 Name 'WinQueryClassProperty',
  WinRemoveClassProperty Index 5455 Name 'WinRemoveClassProperty',
  WinSetClassProperty Index 5456 Name 'WinSetClassProperty',
  WinQueryHeapFlags Index 5457 Name 'WinQueryHeapFlags',
  F_WinSetKbdLayout Index 5458 Name 'Win32SetKbdLayout',
  WinSetDAXDefWndProc Index 5459 Name 'WinSetDAXDefWndProc',
  PostEscape32 Index 5460 Name 'PostEscape32',
  Win32GetAFCValue Index 5461 Name 'Win32GetAFCValue',
  Win32SetAFCValue Index 5462 Name 'Win32SetAFCValue',
  F_WinLoadVkeyGlyphXlatetbl Index 5463 Name 'Win32LoadVkeyGlyphXlateTbl',
  F_WinSetVkeyGlyphXlatetbl Index 5464 Name 'Win32SetVkeyGlyphXlateTbl',
  F_WinQueryVkeyGlyphXlatetbl Index 5465 Name 'Win32QueryVkeyGlyphXlateTbl',
  WinTrackWindow Index 5466 Name 'Win32TrackWindow',
  Win32SemEnterTimeout Index 5467 Name 'Win32SemEnterTimeout',
  WinSetDesktopWorkArea Index 5468 Name 'WinSetDesktopWorkArea',
  WinQueryDesktopWorkArea Index 5469 Name 'WinQueryDesktopWorkArea',
  WinQueryControlColors Index 5470 Name 'WinQueryControlColors',
  WinSetControlColors Index 5471 Name 'WinSetControlColors',
  CtlQueryColor Index 5472 Name 'CtlQueryColor',
  F_WinTranslateChar Index 5473 Name 'Win32TranslateChar2',
  Win32WaitForIdleThread Index 5474 Name 'Win32WaitForIdleThread',
  WinXXCreateHeap2 Index 5475 Name 'WinXXCreateHeap2',
  WinQuerySharedHeapData Index 5476 Name 'WinQuerySharedHeapData',
  Win32QueryActiveOtherWindow Index 5477 Name 'Win32QueryActiveOtherWindow',
  F_WinEnumVKeyScanIDs Index 5478 Name 'Win32EnumVkeyScanIDs',
  F_WinQueryKbdLayout Index 5479 Name 'Win32QueryKbdLayout',
  WinQueryCpType Index 5480 Name 'WinQueryCpType',
  F_WinQueryCharXlatetbl Index 5481 Name 'Win32QueryCharXlatetbl',
  F_KbdPacket Index 6000 Name 'KbdPacket',
  InitGameFrameProc Index 6099 Name 'InitGameFrameProc',
  GreNLS Index 6100 Name 'GreNLS',
  ValidateDCHandle Index 6194 Name 'ValidateDCHandle',
  HookMan Index 6195 Name 'HookMan',
  CCHSetHailing Index 6196 Name 'CCHSetHailing',
  EnableCoachMsgHook Index 6197 Name 'EnableCoachMsgHook',
  FCallGRECoach Index 6198 Name 'FCallGRECoach',
  GRE32CallForward Index 6199 Name 'GRE32CallForward',
  GreMemptrs Index 6200 Name 'GreMemptrs',
  FPen Index 6201 Name 'FPen',
  ShellWindow Index 6202 Name 'ShellWindow',
  PMSemaphores Index 6203 Name 'PMSemaphores',
  PHandleTable Index 6204 Name 'PHandleTable',
  PSharedHeap Index 6205 Name 'PSharedHeap',
  VPAULDefaultColors Index 6206 Name 'VPAULDefaultColors',
  DAXCREATECARET Index 10000 Name 'DAXCREATECARET',
  DaxDestroyCaret Index 10001 Name 'DaxDestroyCaret',
  DaxGetCaretBlinkTime Index 10002 Name 'DaxGetCaretBlinkTime',
  DaxHideCaret Index 10004 Name 'DaxHideCaret',
  DaxSetCaretBlinkTime Index 10005 Name 'DaxSetCaretBlinkTime',
  DaxShowCaret Index 10007 Name 'DaxShowCaret',
  DaxShowCursor Index 10018 Name 'DaxShowCursor',
  DaxSwapMouseButton Index 10019 Name 'DaxSwapMouseButton',
  LookupAtom Index 10020 Name 'LookupAtom',
  DaxOpenClipbrd Index 10021 Name 'DaxOpenClipbrd';

BEGIN
END.
