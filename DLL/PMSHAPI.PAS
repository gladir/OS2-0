{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMSHAPI.DLL de OS/2-0 (interface de
                l'interpreteur de commandes de Presentation Manager :
                profils, liste des programmes, liste des taches).
}

Library PMSHAPI;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC PMSHAPI.PAS   (produit PMSHAPI.DLL)

  PMSHAPI.DLL est la bibliotheque d'OS/2 1.x, 2.x et Warp 3 qui contient
  l'interface de l'interpreteur de Presentation Manager (le "Shell") :

    - les profils (Prf*, WinQueryProfile*, WinWriteProfile*) : fichiers
      INI au format binaire d'OS/2 (OS2.INI de l'utilisateur, OS2SYS.INI
      du systeme, fichiers ouverts par PrfOpenProfile) ;
    - la liste des programmes et des groupes (PrfAddProgram,
      PrfQueryProgramTitles, PrfCreateGroup, WinAddProgram...) ;
    - la liste des taches (WinAddSwitchEntry, WinQuerySwitchList,
      WinSwitchToProgram...) et le demarrage des programmes (WinStartApp,
      WinTerminateApp, WinHAPPfromPID...) ;
    - les points d'entree internes de l'interpreteur (ShePI*, Shp*,
      SheSystemShutdown, StartSystemExecutables, WinInitSessionMgr,
      ShellWindow...).

  Sous OS/2 Warp 4, ces fonctions sont passees dans PMMERGE.DLL et
  PMSHAPI.DLL n'en garde que les noms. OS/2-0 fait de meme : chaque point
  d'entree de PMSHAPI appelle, par son nom, la fonction de PMMERGE.DLL qui
  la realise (PMMERGE garde les profils, la liste des programmes, et
  transmet la liste des taches a OS2SM.DLL et les fenetres a PMWIN.DLL).
  Un programme peut donc utiliser indifferemment PMSHAPI et PMMERGE : il
  voit les memes profils, les memes programmes et la meme liste des
  taches.

  Ordinaux : les ordinaux 1 a 99 sont les points d'entree 16 bits
  d'OS/2 1.x, 101 a 160 et 201 a 213 les points d'entree 32 bits. Quand
  un nom figure deux fois (PrfQueryProfileInt 32 et 114, WinStartApp 119
  et 201...), l'ordinal le plus bas est exporte sous le nom en MAJUSCULES
  (PRFQUERYPROFILEINT, WINSTARTAPP), comme les noms 16 bits ; le nom en
  casse mixte designe l'ordinal 32 bits. startSystemExecutables (89) et
  StartSystemExecutables (152) sont deux noms distincts. Toutes les
  fonctions suivent la convention _System (valeurs de 32 bits, pointeurs
  lineaires), y compris aux ordinaux 16 bits.

  Crochet des profils (propre a PMSHAPI) :
    SheSetProfileHook(pfnHook) : installe (pfnHook <> 0) ou retire
      (pfnHook = 0) le crochet des profils du processus appelant ; rend
      TRUE (FALSE si la table de 16 processus est pleine).
    pfnHook(fl, pszApp, pszKey) : appele apres chaque ecriture reussie
      faite par PMSHAPI (PrfWriteProfileString, PrfWriteProfileData,
      WinWriteProfileString, WinWriteProfileData ; fl = le HINI ecrit,
      HINI_USERPROFILE -1 pour les fonctions Win*) ; pszKey = 0 quand une
      application ou une cle est supprimee.
    SheProfileHook(fl, pszApp, pszKey) : appelle le crochet du processus
      appelant et rend sa valeur (0 si aucun crochet n'est installe).

  Limites (celles de PMMERGE.DLL, voir PMMERGE.PAS) : les points d'entree
  de l'interpreteur graphique (lpfnShellWndProc, lpfnIconWndProc,
  fnBadAppDlgProc) rendent la reponse par defaut ; ShlLoadPublicFonts et
  ShlUnloadPublicFonts ne chargent aucune police ; SheConvert190...,
  SheUpdateIniFile et SheInitializeIniFile se contentent de verifier les
  profils.
}

Const
  HINI_USERPROFILE = -1;
  MAX_HOOK = 16;

Var
  HookPid, HookPfn : Array[0..15] Of LongInt;
  HookI : LongInt;

{ --- noyau --- }
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

{ --- fonctions de PMMERGE.DLL --- }
Function X_ShePIInitialise : LongInt; External 'PMMERGE' Name 'ShePIInitialise';
Function X_WinQueryProfileInt(Hab, PApp, PKey, Def : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryProfileInt';
Function X_WinQueryProfileString(Hab, PApp, PKey, PDef, PBuf, Max : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryProfileString';
Function X_WinWriteProfileString(Hab, PApp, PKey, PData : LongInt) : LongInt; External 'PMMERGE' Name 'WinWriteProfileString';
Function X_WinQueryProfileSize(Hab, PApp, PKey, PLen : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryProfileSize';
Function X_WinQueryProfileData(Hab, PApp, PKey, PBuf, PLen : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryProfileData';
Function X_WinWriteProfileData(Hab, PApp, PKey, PData, Cb : LongInt) : LongInt; External 'PMMERGE' Name 'WinWriteProfileData';
Function X_WinInitSessionMgr(Reserved : LongInt) : LongInt; External 'PMMERGE' Name 'WinInitSessionMgr';
Function X_WinSetFgndWindow(Hwnd : LongInt) : LongInt; External 'PMMERGE' Name 'WinSetFgndWindow';
Function X_ShlUnloadPublicFonts : LongInt; External 'PMMERGE' Name 'ShlUnloadPublicFonts';
Function X_WinStpRegister(Hwnd : LongInt) : LongInt; External 'PMMERGE' Name 'WinStpRegister';
Function X_WinAddProgram(Hab, PDet, Grp : LongInt) : LongInt; External 'PMMERGE' Name 'WinAddProgram';
Function X_WinRemoveProgram(Hab, H : LongInt) : LongInt; External 'PMMERGE' Name 'WinRemoveProgram';
Function X_WinChangeProgram(H, PDet, Cb : LongInt) : LongInt; External 'PMMERGE' Name 'WinChangeProgram';
Function X_WinQueryDefinition(Hab, H, PDet, Max : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryDefinition';
Function X_WinQueryProgramTitles(Hab, Grp, P, Max, PCount : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryProgramTitles';
Function X_WinCreateGroup(Hab, PTitle, Vis, R1, R2 : LongInt) : LongInt; External 'PMMERGE' Name 'WinCreateGroup';
Function X_WinInitializePL(Hab : LongInt) : LongInt; External 'PMMERGE' Name 'WinInitializePL';
Function X_WinAddToGroup(Hab, Grp, H : LongInt) : LongInt; External 'PMMERGE' Name 'WinAddToGroup';
Function X_WinQueryProgramUse(Hab, PExe : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryProgramUse';
Function X_WinRemoveFromGroup(Hab, H : LongInt) : LongInt; External 'PMMERGE' Name 'WinRemoveFromGroup';
Function X_StartStartUpDotCmd : LongInt; External 'PMMERGE' Name 'StartStartUpDotCmd';
Function X_WinDestroyGroup(Hab, Grp : LongInt) : LongInt; External 'PMMERGE' Name 'WinDestroyGroup';
Function X_WinQueryFileExtOpts : LongInt; External 'PMMERGE' Name 'WinQueryFileExtOpts';
Function X_WinSetFileExtOpts(V : LongInt) : LongInt; External 'PMMERGE' Name 'WinSetFileExtOpts';
Function X_WinQueryProgramType(Hab, PExe : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryProgramType';
Function X_PrfChangeWriteThru(Hini, F : LongInt) : LongInt; External 'PMMERGE' Name 'PrfChangeWriteThru';
Function X_PMExecRegister(P : LongInt) : LongInt; External 'PMMERGE' Name 'PMExecRegister';
Function X_ShePIInitIniFiles : LongInt; External 'PMMERGE' Name 'ShePIInitIniFiles';
Function X_SheUpdateIniFile(Hini : LongInt) : LongInt; External 'PMMERGE' Name 'SheUpdateIniFile';
Function X_SheConvert190ProgramListTo300 : LongInt; External 'PMMERGE' Name 'SheConvert190ProgramListTo300';
Function X_PrfQueryProfileInt(Hini, PApp, PKey, Def : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProfileInt';
Function X_PrfQueryProfileString(Hini, PApp, PKey, PDef, PBuf, Max : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProfileString';
Function X_PrfWriteProfileString(Hini, PApp, PKey, PData : LongInt) : LongInt; External 'PMMERGE' Name 'PrfWriteProfileString';
Function X_PrfQueryProfileSize(Hini, PApp, PKey, PLen : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProfileSize';
Function X_PrfQueryProfileData(Hini, PApp, PKey, PBuf, PLen : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProfileData';
Function X_PrfWriteProfileData(Hini, PApp, PKey, PData, Cb : LongInt) : LongInt; External 'PMMERGE' Name 'PrfWriteProfileData';
Function X_PrfOpenProfile(Hab, PName : LongInt) : LongInt; External 'PMMERGE' Name 'PrfOpenProfile';
Function X_PrfCloseProfile(Hini : LongInt) : LongInt; External 'PMMERGE' Name 'PrfCloseProfile';
Function X_PrfReset(Hab, P : LongInt) : LongInt; External 'PMMERGE' Name 'PrfReset';
Function X_PrfQueryProfile(Hab, P : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProfile';
Function X_WinInstStartApp(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt; External 'PMMERGE' Name 'WinInstStartApp';
Function X_WinTerminateApp(Happ : LongInt) : LongInt; External 'PMMERGE' Name 'WinTerminateApp';
Function X_WinCreateSwitchEntry(Hab, P : LongInt) : LongInt; External 'PMMERGE' Name 'WinCreateSwitchEntry';
Function X_WinQuerySessionTitle(Hab, S, PTitle, Cb : LongInt) : LongInt; External 'PMMERGE' Name 'WinQuerySessionTitle';
Function X_WinAddSwitchEntry(P : LongInt) : LongInt; External 'PMMERGE' Name 'WinAddSwitchEntry';
Function X_WinChangeSwitchEntry(H, P : LongInt) : LongInt; External 'PMMERGE' Name 'WinChangeSwitchEntry';
Function X_PrfAddProgram(Hini, PDet, Grp : LongInt) : LongInt; External 'PMMERGE' Name 'PrfAddProgram';
Function X_PrfRemoveProgram(Hini, H : LongInt) : LongInt; External 'PMMERGE' Name 'PrfRemoveProgram';
Function X_PrfChangeProgram(Hini, H, PDet : LongInt) : LongInt; External 'PMMERGE' Name 'PrfChangeProgram';
Function X_PrfQueryDefinition(Hini, H, PDet, Max : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryDefinition';
Function X_PrfQueryProgramTitles(Hini, Grp, P, Max, PCount : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProgramTitles';
Function X_PrfCreateGroup(Hini, PTitle, Vis : LongInt) : LongInt; External 'PMMERGE' Name 'PrfCreateGroup';
Function X_WinQuerySwitchEntry(H, P : LongInt) : LongInt; External 'PMMERGE' Name 'WinQuerySwitchEntry';
Function X_WinQuerySwitchHandle(Hwnd, Pid : LongInt) : LongInt; External 'PMMERGE' Name 'WinQuerySwitchHandle';
Function X_PrfQueryProgramHandle(Hini, PExe, PArr, Max, PCount : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProgramHandle';
Function X_PrfQueryProgramCategory(Hini, PExe : LongInt) : LongInt; External 'PMMERGE' Name 'PrfQueryProgramCategory';
Function X_PrfDestroyGroup(Hini, Grp : LongInt) : LongInt; External 'PMMERGE' Name 'PrfDestroyGroup';
Function X_ShpLockProgramList : LongInt; External 'PMMERGE' Name 'ShpLockProgramList';
Function X_ShpUnlockProgramList : LongInt; External 'PMMERGE' Name 'ShpUnlockProgramList';
Function X_WinQueryTaskTitle(S, PTitle, Cb : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryTaskTitle';
Function X_WinQueryTaskSizePos(Hab, S, P : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryTaskSizePos';
Function X_WinQuerySwitchList(Hab, PBlk, Cb : LongInt) : LongInt; External 'PMMERGE' Name 'WinQuerySwitchList';
Function X_WinRemoveSwitchEntry(H : LongInt) : LongInt; External 'PMMERGE' Name 'WinRemoveSwitchEntry';
Function X_WinSwitchToProgram(H : LongInt) : LongInt; External 'PMMERGE' Name 'WinSwitchToProgram';
Function X_WinSwitchProgramRegister(Hwnd : LongInt) : LongInt; External 'PMMERGE' Name 'WinSwitchProgramRegister';
Function X_WinEndProgram(H : LongInt) : LongInt; External 'PMMERGE' Name 'WinEndProgram';
Function X_WinStopProgram(H : LongInt) : LongInt; External 'PMMERGE' Name 'WinStopProgram';
Function X_WinEndWindowSession(H : LongInt) : LongInt; External 'PMMERGE' Name 'WinEndWindowSession';
Function X_lpfnShellWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMMERGE' Name 'lpfnShellWndProc';
Function X_lpfnIconWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMMERGE' Name 'lpfnIconWndProc';
Function X_WinSwitchToTaskManager : LongInt; External 'PMMERGE' Name 'WinSwitchToTaskManager';
Function X_fnBadAppDlgProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMMERGE' Name 'fnBadAppDlgProc';
Function X_WinSwitchToProgram2(H, Fl : LongInt) : LongInt; External 'PMMERGE' Name 'WinSwitchToProgram2';
Function X_WinProcessHotKey(Scan, State : LongInt) : LongInt; External 'PMMERGE' Name 'WinProcessHotKey';
Function X_WinInitSession(S, PTitle : LongInt) : LongInt; External 'PMMERGE' Name 'WinInitSession';
Function X_WinEndSession(S : LongInt) : LongInt; External 'PMMERGE' Name 'WinEndSession';
Function X_WinInitSwEntry(P : LongInt) : LongInt; External 'PMMERGE' Name 'WinInitSwEntry';
Function X_WinSetSwEntry(H, P : LongInt) : LongInt; External 'PMMERGE' Name 'WinSetSwEntry';
Function X_WinQueryExtIDFocus(PId : LongInt) : LongInt; External 'PMMERGE' Name 'WinQueryExtIDFocus';
Function X_WinSetExtIDFocus(Id : LongInt) : LongInt; External 'PMMERGE' Name 'WinSetExtIDFocus';
Function X_SheSystemShutdown(Fl : LongInt) : LongInt; External 'PMMERGE' Name 'SheSystemShutdown';
Function X_StartSystemExecutables(PIni : LongInt) : LongInt; External 'PMMERGE' Name 'StartSystemExecutables';
Function X_ShlLoadPublicFonts(PIni : LongInt) : LongInt; External 'PMMERGE' Name 'ShlLoadPublicFonts';
Function X_WinNoShutdown(Block : LongInt) : LongInt; External 'PMMERGE' Name 'WinNoShutdown';
Function X_SheInitializeIniFile(PIni : LongInt) : LongInt; External 'PMMERGE' Name 'SheInitializeIniFile';
Function X_WinSetTitle(PTitle : LongInt) : LongInt; External 'PMMERGE' Name 'WinSetTitle';
Function X_WinCplRegister(PName : LongInt) : LongInt; External 'PMMERGE' Name 'WinCplRegister';
Function X_WinPMFileRegister(PName : LongInt) : LongInt; External 'PMMERGE' Name 'WinPMFileRegister';
Function X_SheStartLongProgram(PProg, PParams, PTitle, Bg, PSid : LongInt) : LongInt; External 'PMMERGE' Name 'SheStartLongProgram';
Function X_WinSetTitleAndIcon(PTitle, PIcon : LongInt) : LongInt; External 'PMMERGE' Name 'WinSetTitleAndIcon';
Function X_ShellWindow : LongInt; External 'PMMERGE' Name 'ShellWindow';
Function X_WinStartApp(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt; External 'PMMERGE' Name 'WinStartApp';
Function X_WinHAPPfromPID(Pid : LongInt) : LongInt; External 'PMMERGE' Name 'WinHAPPfromPID';
Function X_WinHSWITCHfromHAPP(Happ : LongInt) : LongInt; External 'PMMERGE' Name 'WinHSWITCHfromHAPP';
Function X_WinCanTerminate(Hab : LongInt) : LongInt; External 'PMMERGE' Name 'WinCanTerminate';
Function X_ShpPILockIniFile(F : LongInt) : LongInt; External 'PMMERGE' Name 'ShpPILockIniFile';
Function X_ShpPI16LockIniFile(F : LongInt) : LongInt; External 'PMMERGE' Name 'ShpPI16LockIniFile';
Function X_ShpPIShutdown : LongInt; External 'PMMERGE' Name 'ShpPIShutdown';
Function X_ShpPI16Shutdown : LongInt; External 'PMMERGE' Name 'ShpPI16Shutdown';

{ --- appels du crochet --- }
Function CallSys3(F, A1, A2, A3 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,12
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallSys3 := R;
End;

Function CallPas3(F, A1, A2, A3 : LongInt) : LongInt;
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
    mov eax,F
    call eax
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPas3 := R;
End;

{ un programme OS2PC (charge en 00400000h) suit la convention Pascal }
Function Call3(F, A1, A2, A3 : LongInt) : LongInt;
Begin
  If (F >= $00400000) And (F < $00800000) Then Call3 := CallPas3(F, A1, A2, A3)
  Else Call3 := CallSys3(F, A1, A2, A3);
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

Function HookOf(Pid : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  For I := 0 To MAX_HOOK - 1 Do
    If (HookPfn[I] <> 0) And (HookPid[I] = Pid) Then R := HookPfn[I];
  HookOf := R;
End;

{ SheSetProfileHook(pfnHook) : crochet des profils du processus appelant }
Function SheSetProfileHook(Pfn : LongInt) : LongInt;
Var I, P, Slot : LongInt;
Begin
  P := MyPid;
  Slot := -1;
  For I := 0 To MAX_HOOK - 1 Do
  Begin
    If (HookPfn[I] <> 0) And (HookPid[I] <> P) And (KrnMonIo(0, 4, HookPid[I]) = 0) Then
      HookPfn[I] := 0;
    If (HookPfn[I] <> 0) And (HookPid[I] = P) Then HookPfn[I] := 0;
  End;
  If Pfn = 0 Then
    SheSetProfileHook := 1
  Else
  Begin
    For I := MAX_HOOK - 1 DownTo 0 Do
      If HookPfn[I] = 0 Then Slot := I;
    If Slot < 0 Then
      SheSetProfileHook := 0
    Else
    Begin
      HookPid[Slot] := P;
      HookPfn[Slot] := Pfn;
      SheSetProfileHook := 1;
    End;
  End;
End;

{ SheProfileHook(fl, pszApp, pszKey) : appelle le crochet du processus }
Function SheProfileHook(Fl, PApp, PKey : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := HookOf(MyPid);
  If F = 0 Then SheProfileHook := 0
  Else SheProfileHook := Call3(F, Fl, PApp, PKey);
End;

Procedure Notify(Hini, PApp, PKey : LongInt);
Var F : LongInt;
Begin
  F := HookOf(MyPid);
  If F <> 0 Then
  Begin
    F := Call3(F, Hini, PApp, PKey);
    HookI := HookI + 1;
  End;
End;

{ --- points d'entree de PMSHAPI --- }
Function F_ShePIInitialise : LongInt;
Begin
  F_ShePIInitialise := X_ShePIInitialise;
End;

Function F_WinQueryProfileInt(Hab, PApp, PKey, Def : LongInt) : LongInt;
Begin
  F_WinQueryProfileInt := X_WinQueryProfileInt(Hab, PApp, PKey, Def);
End;

Function F_WinQueryProfileString(Hab, PApp, PKey, PDef, PBuf, Max : LongInt) : LongInt;
Begin
  F_WinQueryProfileString := X_WinQueryProfileString(Hab, PApp, PKey, PDef, PBuf, Max);
End;

Function F_WinWriteProfileString(Hab, PApp, PKey, PData : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := X_WinWriteProfileString(Hab, PApp, PKey, PData);
  If R <> 0 Then Notify(HINI_USERPROFILE, PApp, PKey);
  F_WinWriteProfileString := R;
End;

Function F_WinQueryProfileSize(Hab, PApp, PKey, PLen : LongInt) : LongInt;
Begin
  F_WinQueryProfileSize := X_WinQueryProfileSize(Hab, PApp, PKey, PLen);
End;

Function F_WinQueryProfileData(Hab, PApp, PKey, PBuf, PLen : LongInt) : LongInt;
Begin
  F_WinQueryProfileData := X_WinQueryProfileData(Hab, PApp, PKey, PBuf, PLen);
End;

Function F_WinWriteProfileData(Hab, PApp, PKey, PData, Cb : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := X_WinWriteProfileData(Hab, PApp, PKey, PData, Cb);
  If R <> 0 Then Notify(HINI_USERPROFILE, PApp, PKey);
  F_WinWriteProfileData := R;
End;

Function F_WinInitSessionMgr(Reserved : LongInt) : LongInt;
Begin
  F_WinInitSessionMgr := X_WinInitSessionMgr(Reserved);
End;

Function F_WinSetFgndWindow(Hwnd : LongInt) : LongInt;
Begin
  F_WinSetFgndWindow := X_WinSetFgndWindow(Hwnd);
End;

Function F_ShlUnloadPublicFonts : LongInt;
Begin
  F_ShlUnloadPublicFonts := X_ShlUnloadPublicFonts;
End;

Function F_WinStpRegister(Hwnd : LongInt) : LongInt;
Begin
  F_WinStpRegister := X_WinStpRegister(Hwnd);
End;

Function F_WinAddProgram(Hab, PDet, Grp : LongInt) : LongInt;
Begin
  F_WinAddProgram := X_WinAddProgram(Hab, PDet, Grp);
End;

Function F_WinRemoveProgram(Hab, H : LongInt) : LongInt;
Begin
  F_WinRemoveProgram := X_WinRemoveProgram(Hab, H);
End;

Function F_WinChangeProgram(H, PDet, Cb : LongInt) : LongInt;
Begin
  F_WinChangeProgram := X_WinChangeProgram(H, PDet, Cb);
End;

Function F_WinQueryDefinition(Hab, H, PDet, Max : LongInt) : LongInt;
Begin
  F_WinQueryDefinition := X_WinQueryDefinition(Hab, H, PDet, Max);
End;

Function F_WinQueryProgramTitles(Hab, Grp, P, Max, PCount : LongInt) : LongInt;
Begin
  F_WinQueryProgramTitles := X_WinQueryProgramTitles(Hab, Grp, P, Max, PCount);
End;

Function F_WinCreateGroup(Hab, PTitle, Vis, R1, R2 : LongInt) : LongInt;
Begin
  F_WinCreateGroup := X_WinCreateGroup(Hab, PTitle, Vis, R1, R2);
End;

Function F_WinInitializePL(Hab : LongInt) : LongInt;
Begin
  F_WinInitializePL := X_WinInitializePL(Hab);
End;

Function F_WinAddToGroup(Hab, Grp, H : LongInt) : LongInt;
Begin
  F_WinAddToGroup := X_WinAddToGroup(Hab, Grp, H);
End;

Function F_WinQueryProgramUse(Hab, PExe : LongInt) : LongInt;
Begin
  F_WinQueryProgramUse := X_WinQueryProgramUse(Hab, PExe);
End;

Function F_WinRemoveFromGroup(Hab, H : LongInt) : LongInt;
Begin
  F_WinRemoveFromGroup := X_WinRemoveFromGroup(Hab, H);
End;

Function F_StartStartUpDotCmd : LongInt;
Begin
  F_StartStartUpDotCmd := X_StartStartUpDotCmd;
End;

Function F_WinDestroyGroup(Hab, Grp : LongInt) : LongInt;
Begin
  F_WinDestroyGroup := X_WinDestroyGroup(Hab, Grp);
End;

Function F_WinQueryFileExtOpts : LongInt;
Begin
  F_WinQueryFileExtOpts := X_WinQueryFileExtOpts;
End;

Function F_WinSetFileExtOpts(V : LongInt) : LongInt;
Begin
  F_WinSetFileExtOpts := X_WinSetFileExtOpts(V);
End;

Function F_WinQueryProgramType(Hab, PExe : LongInt) : LongInt;
Begin
  F_WinQueryProgramType := X_WinQueryProgramType(Hab, PExe);
End;

Function F_PrfChangeWriteThru(Hini, F : LongInt) : LongInt;
Begin
  F_PrfChangeWriteThru := X_PrfChangeWriteThru(Hini, F);
End;

Function F_PMExecRegister(P : LongInt) : LongInt;
Begin
  F_PMExecRegister := X_PMExecRegister(P);
End;

Function F_ShePIInitIniFiles : LongInt;
Begin
  F_ShePIInitIniFiles := X_ShePIInitIniFiles;
End;

Function F_SheUpdateIniFile(Hini : LongInt) : LongInt;
Begin
  F_SheUpdateIniFile := X_SheUpdateIniFile(Hini);
End;

Function F_SheConvert190ProgramListTo300 : LongInt;
Begin
  F_SheConvert190ProgramListTo300 := X_SheConvert190ProgramListTo300;
End;

Function F_PrfQueryProfileInt(Hini, PApp, PKey, Def : LongInt) : LongInt;
Begin
  F_PrfQueryProfileInt := X_PrfQueryProfileInt(Hini, PApp, PKey, Def);
End;

Function F_PrfQueryProfileString(Hini, PApp, PKey, PDef, PBuf, Max : LongInt) : LongInt;
Begin
  F_PrfQueryProfileString := X_PrfQueryProfileString(Hini, PApp, PKey, PDef, PBuf, Max);
End;

Function F_PrfWriteProfileString(Hini, PApp, PKey, PData : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := X_PrfWriteProfileString(Hini, PApp, PKey, PData);
  If R <> 0 Then Notify(Hini, PApp, PKey);
  F_PrfWriteProfileString := R;
End;

Function F_PrfQueryProfileSize(Hini, PApp, PKey, PLen : LongInt) : LongInt;
Begin
  F_PrfQueryProfileSize := X_PrfQueryProfileSize(Hini, PApp, PKey, PLen);
End;

Function F_PrfQueryProfileData(Hini, PApp, PKey, PBuf, PLen : LongInt) : LongInt;
Begin
  F_PrfQueryProfileData := X_PrfQueryProfileData(Hini, PApp, PKey, PBuf, PLen);
End;

Function F_PrfWriteProfileData(Hini, PApp, PKey, PData, Cb : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := X_PrfWriteProfileData(Hini, PApp, PKey, PData, Cb);
  If R <> 0 Then Notify(Hini, PApp, PKey);
  F_PrfWriteProfileData := R;
End;

Function F_PrfOpenProfile(Hab, PName : LongInt) : LongInt;
Begin
  F_PrfOpenProfile := X_PrfOpenProfile(Hab, PName);
End;

Function F_PrfCloseProfile(Hini : LongInt) : LongInt;
Begin
  F_PrfCloseProfile := X_PrfCloseProfile(Hini);
End;

Function F_PrfReset(Hab, P : LongInt) : LongInt;
Begin
  F_PrfReset := X_PrfReset(Hab, P);
End;

Function F_PrfQueryProfile(Hab, P : LongInt) : LongInt;
Begin
  F_PrfQueryProfile := X_PrfQueryProfile(Hab, P);
End;

Function F_WinInstStartApp(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt;
Begin
  F_WinInstStartApp := X_WinInstStartApp(HNotify, PDet, PParams, PRes, Opt);
End;

Function F_WinTerminateApp(Happ : LongInt) : LongInt;
Begin
  F_WinTerminateApp := X_WinTerminateApp(Happ);
End;

Function F_WinCreateSwitchEntry(Hab, P : LongInt) : LongInt;
Begin
  F_WinCreateSwitchEntry := X_WinCreateSwitchEntry(Hab, P);
End;

Function F_WinQuerySessionTitle(Hab, S, PTitle, Cb : LongInt) : LongInt;
Begin
  F_WinQuerySessionTitle := X_WinQuerySessionTitle(Hab, S, PTitle, Cb);
End;

Function F_WinAddSwitchEntry(P : LongInt) : LongInt;
Begin
  F_WinAddSwitchEntry := X_WinAddSwitchEntry(P);
End;

Function F_WinChangeSwitchEntry(H, P : LongInt) : LongInt;
Begin
  F_WinChangeSwitchEntry := X_WinChangeSwitchEntry(H, P);
End;

Function F_PrfAddProgram(Hini, PDet, Grp : LongInt) : LongInt;
Begin
  F_PrfAddProgram := X_PrfAddProgram(Hini, PDet, Grp);
End;

Function F_PrfRemoveProgram(Hini, H : LongInt) : LongInt;
Begin
  F_PrfRemoveProgram := X_PrfRemoveProgram(Hini, H);
End;

Function F_PrfChangeProgram(Hini, H, PDet : LongInt) : LongInt;
Begin
  F_PrfChangeProgram := X_PrfChangeProgram(Hini, H, PDet);
End;

Function F_PrfQueryDefinition(Hini, H, PDet, Max : LongInt) : LongInt;
Begin
  F_PrfQueryDefinition := X_PrfQueryDefinition(Hini, H, PDet, Max);
End;

Function F_PrfQueryProgramTitles(Hini, Grp, P, Max, PCount : LongInt) : LongInt;
Begin
  F_PrfQueryProgramTitles := X_PrfQueryProgramTitles(Hini, Grp, P, Max, PCount);
End;

Function F_PrfCreateGroup(Hini, PTitle, Vis : LongInt) : LongInt;
Begin
  F_PrfCreateGroup := X_PrfCreateGroup(Hini, PTitle, Vis);
End;

Function F_WinQuerySwitchEntry(H, P : LongInt) : LongInt;
Begin
  F_WinQuerySwitchEntry := X_WinQuerySwitchEntry(H, P);
End;

Function F_WinQuerySwitchHandle(Hwnd, Pid : LongInt) : LongInt;
Begin
  F_WinQuerySwitchHandle := X_WinQuerySwitchHandle(Hwnd, Pid);
End;

Function F_PrfQueryProgramHandle(Hini, PExe, PArr, Max, PCount : LongInt) : LongInt;
Begin
  F_PrfQueryProgramHandle := X_PrfQueryProgramHandle(Hini, PExe, PArr, Max, PCount);
End;

Function F_PrfQueryProgramCategory(Hini, PExe : LongInt) : LongInt;
Begin
  F_PrfQueryProgramCategory := X_PrfQueryProgramCategory(Hini, PExe);
End;

Function F_PrfDestroyGroup(Hini, Grp : LongInt) : LongInt;
Begin
  F_PrfDestroyGroup := X_PrfDestroyGroup(Hini, Grp);
End;

Function F_ShpLockProgramList : LongInt;
Begin
  F_ShpLockProgramList := X_ShpLockProgramList;
End;

Function F_ShpUnlockProgramList : LongInt;
Begin
  F_ShpUnlockProgramList := X_ShpUnlockProgramList;
End;

Function F_WinQueryTaskTitle(S, PTitle, Cb : LongInt) : LongInt;
Begin
  F_WinQueryTaskTitle := X_WinQueryTaskTitle(S, PTitle, Cb);
End;

Function F_WinQueryTaskSizePos(Hab, S, P : LongInt) : LongInt;
Begin
  F_WinQueryTaskSizePos := X_WinQueryTaskSizePos(Hab, S, P);
End;

Function F_WinQuerySwitchList(Hab, PBlk, Cb : LongInt) : LongInt;
Begin
  F_WinQuerySwitchList := X_WinQuerySwitchList(Hab, PBlk, Cb);
End;

Function F_WinRemoveSwitchEntry(H : LongInt) : LongInt;
Begin
  F_WinRemoveSwitchEntry := X_WinRemoveSwitchEntry(H);
End;

Function F_WinSwitchToProgram(H : LongInt) : LongInt;
Begin
  F_WinSwitchToProgram := X_WinSwitchToProgram(H);
End;

Function F_WinSwitchProgramRegister(Hwnd : LongInt) : LongInt;
Begin
  F_WinSwitchProgramRegister := X_WinSwitchProgramRegister(Hwnd);
End;

Function F_WinEndProgram(H : LongInt) : LongInt;
Begin
  F_WinEndProgram := X_WinEndProgram(H);
End;

Function F_WinStopProgram(H : LongInt) : LongInt;
Begin
  F_WinStopProgram := X_WinStopProgram(H);
End;

Function F_WinEndWindowSession(H : LongInt) : LongInt;
Begin
  F_WinEndWindowSession := X_WinEndWindowSession(H);
End;

Function F_lpfnShellWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_lpfnShellWndProc := X_lpfnShellWndProc(Hwnd, Msg, Mp1, Mp2);
End;

Function F_lpfnIconWndProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_lpfnIconWndProc := X_lpfnIconWndProc(Hwnd, Msg, Mp1, Mp2);
End;

Function F_WinSwitchToTaskManager : LongInt;
Begin
  F_WinSwitchToTaskManager := X_WinSwitchToTaskManager;
End;

Function F_fnBadAppDlgProc(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  F_fnBadAppDlgProc := X_fnBadAppDlgProc(Hwnd, Msg, Mp1, Mp2);
End;

Function F_WinSwitchToProgram2(H, Fl : LongInt) : LongInt;
Begin
  F_WinSwitchToProgram2 := X_WinSwitchToProgram2(H, Fl);
End;

Function F_WinProcessHotKey(Scan, State : LongInt) : LongInt;
Begin
  F_WinProcessHotKey := X_WinProcessHotKey(Scan, State);
End;

Function F_WinInitSession(S, PTitle : LongInt) : LongInt;
Begin
  F_WinInitSession := X_WinInitSession(S, PTitle);
End;

Function F_WinEndSession(S : LongInt) : LongInt;
Begin
  F_WinEndSession := X_WinEndSession(S);
End;

Function F_WinInitSwEntry(P : LongInt) : LongInt;
Begin
  F_WinInitSwEntry := X_WinInitSwEntry(P);
End;

Function F_WinSetSwEntry(H, P : LongInt) : LongInt;
Begin
  F_WinSetSwEntry := X_WinSetSwEntry(H, P);
End;

Function F_WinQueryExtIDFocus(PId : LongInt) : LongInt;
Begin
  F_WinQueryExtIDFocus := X_WinQueryExtIDFocus(PId);
End;

Function F_WinSetExtIDFocus(Id : LongInt) : LongInt;
Begin
  F_WinSetExtIDFocus := X_WinSetExtIDFocus(Id);
End;

Function F_SheSystemShutdown(Fl : LongInt) : LongInt;
Begin
  F_SheSystemShutdown := X_SheSystemShutdown(Fl);
End;

Function F_StartSystemExecutables(PIni : LongInt) : LongInt;
Begin
  F_StartSystemExecutables := X_StartSystemExecutables(PIni);
End;

Function F_ShlLoadPublicFonts(PIni : LongInt) : LongInt;
Begin
  F_ShlLoadPublicFonts := X_ShlLoadPublicFonts(PIni);
End;

Function F_WinNoShutdown(Block : LongInt) : LongInt;
Begin
  F_WinNoShutdown := X_WinNoShutdown(Block);
End;

Function F_SheInitializeIniFile(PIni : LongInt) : LongInt;
Begin
  F_SheInitializeIniFile := X_SheInitializeIniFile(PIni);
End;

Function F_WinSetTitle(PTitle : LongInt) : LongInt;
Begin
  F_WinSetTitle := X_WinSetTitle(PTitle);
End;

Function F_WinCplRegister(PName : LongInt) : LongInt;
Begin
  F_WinCplRegister := X_WinCplRegister(PName);
End;

Function F_WinPMFileRegister(PName : LongInt) : LongInt;
Begin
  F_WinPMFileRegister := X_WinPMFileRegister(PName);
End;

Function F_SheStartLongProgram(PProg, PParams, PTitle, Bg, PSid : LongInt) : LongInt;
Begin
  F_SheStartLongProgram := X_SheStartLongProgram(PProg, PParams, PTitle, Bg, PSid);
End;

Function F_WinSetTitleAndIcon(PTitle, PIcon : LongInt) : LongInt;
Begin
  F_WinSetTitleAndIcon := X_WinSetTitleAndIcon(PTitle, PIcon);
End;

Function F_ShellWindow : LongInt;
Begin
  F_ShellWindow := X_ShellWindow;
End;

Function F_WinStartApp(HNotify, PDet, PParams, PRes, Opt : LongInt) : LongInt;
Begin
  F_WinStartApp := X_WinStartApp(HNotify, PDet, PParams, PRes, Opt);
End;

Function F_WinHAPPfromPID(Pid : LongInt) : LongInt;
Begin
  F_WinHAPPfromPID := X_WinHAPPfromPID(Pid);
End;

Function F_WinHSWITCHfromHAPP(Happ : LongInt) : LongInt;
Begin
  F_WinHSWITCHfromHAPP := X_WinHSWITCHfromHAPP(Happ);
End;

Function F_WinCanTerminate(Hab : LongInt) : LongInt;
Begin
  F_WinCanTerminate := X_WinCanTerminate(Hab);
End;

Function F_ShpPILockIniFile(F : LongInt) : LongInt;
Begin
  F_ShpPILockIniFile := X_ShpPILockIniFile(F);
End;

Function F_ShpPI16LockIniFile(F : LongInt) : LongInt;
Begin
  F_ShpPI16LockIniFile := X_ShpPI16LockIniFile(F);
End;

Function F_ShpPIShutdown : LongInt;
Begin
  F_ShpPIShutdown := X_ShpPIShutdown;
End;

Function F_ShpPI16Shutdown : LongInt;
Begin
  F_ShpPI16Shutdown := X_ShpPI16Shutdown;
End;


Exports
  F_ShePIInitialise Index 1 Name 'ShePIInitialise',
  F_WinQueryProfileInt Index 2 Name 'WinQueryProfileInt',
  F_WinQueryProfileString Index 3 Name 'WinQueryProfileString',
  F_WinWriteProfileString Index 4 Name 'WinWriteProfileString',
  F_WinQueryProfileSize Index 5 Name 'WinQueryProfileSize',
  F_WinQueryProfileData Index 6 Name 'WinQueryProfileData',
  F_WinWriteProfileData Index 7 Name 'WinWriteProfileData',
  F_WinInitSessionMgr Index 8 Name 'WinInitSessionMgr',
  F_WinSetFgndWindow Index 9 Name 'WinSetFgndWindow',
  F_ShlUnloadPublicFonts Index 10 Name 'ShlUnloadPublicFonts',
  F_WinStpRegister Index 11 Name 'WinStPRegister',
  F_WinAddProgram Index 12 Name 'WinAddProgram',
  F_WinRemoveProgram Index 13 Name 'WinRemoveProgram',
  F_WinChangeProgram Index 14 Name 'WinChangeProgram',
  F_WinQueryDefinition Index 15 Name 'WinQueryDefinition',
  F_WinQueryProgramTitles Index 16 Name 'WinQueryProgramTitles',
  F_WinCreateGroup Index 17 Name 'WinCreateGroup',
  F_WinInitializePL Index 18 Name 'WinInitializePL',
  F_WinAddToGroup Index 19 Name 'WinAddToGroup',
  F_WinQueryProgramUse Index 20 Name 'WinQueryProgramUse',
  F_WinRemoveFromGroup Index 21 Name 'WinRemoveFromGroup',
  F_StartStartUpDotCmd Index 22 Name 'StartStartUpDotCmd',
  F_WinDestroyGroup Index 23 Name 'WinDestroyGroup',
  F_WinQueryFileExtOpts Index 24 Name 'WinQueryFileExtOpts',
  F_WinSetFileExtOpts Index 25 Name 'WinSetFileExtOpts',
  F_WinQueryProgramType Index 26 Name 'WinQueryProgramType',
  F_PrfChangeWriteThru Index 27 Name 'PRFCHANGEWRITETHRU',
  F_PMExecRegister Index 28 Name 'PMEXECREGISTER',
  F_ShePIInitIniFiles Index 29 Name 'SHEPIINITINIFILES',
  F_SheUpdateIniFile Index 30 Name 'SheUpdateIniFile',
  F_SheConvert190ProgramListTo300 Index 31 Name 'SheConvert190ProgramListTo300',
  F_PrfQueryProfileInt Index 32 Name 'PRFQUERYPROFILEINT',
  F_PrfQueryProfileString Index 33 Name 'PRFQUERYPROFILESTRING',
  F_PrfWriteProfileString Index 34 Name 'PRFWRITEPROFILESTRING',
  F_PrfQueryProfileSize Index 35 Name 'PRFQUERYPROFILESIZE',
  F_PrfQueryProfileData Index 36 Name 'PRFQUERYPROFILEDATA',
  F_PrfWriteProfileData Index 37 Name 'PRFWRITEPROFILEDATA',
  F_PrfOpenProfile Index 38 Name 'PRFOPENPROFILE',
  F_PrfCloseProfile Index 39 Name 'PRFCLOSEPROFILE',
  F_PrfReset Index 42 Name 'PRFRESET',
  F_PrfQueryProfile Index 43 Name 'PRFQUERYPROFILE',
  F_WinInstStartApp Index 44 Name 'WinInstStartApp',
  F_WinTerminateApp Index 45 Name 'WINTERMINATEAPP',
  F_WinCreateSwitchEntry Index 46 Name 'WINCREATESWITCHENTRY',
  F_WinQuerySessionTitle Index 47 Name 'WINQUERYSESSIONTITLE',
  F_WinAddSwitchEntry Index 48 Name 'WINADDSWITCHENTRY',
  F_WinChangeSwitchEntry Index 49 Name 'WINCHANGESWITCHENTRY',
  F_PrfAddProgram Index 50 Name 'PRFADDPROGRAM',
  F_PrfRemoveProgram Index 51 Name 'PRFREMOVEPROGRAM',
  F_PrfChangeProgram Index 52 Name 'PRFCHANGEPROGRAM',
  F_PrfQueryDefinition Index 53 Name 'PRFQUERYDEFINITION',
  F_PrfQueryProgramTitles Index 54 Name 'PRFQUERYPROGRAMTITLES',
  F_PrfCreateGroup Index 55 Name 'PRFCREATEGROUP',
  F_WinQuerySwitchEntry Index 56 Name 'WINQUERYSWITCHENTRY',
  F_WinQuerySwitchHandle Index 57 Name 'WINQUERYSWITCHHANDLE',
  F_PrfQueryProgramHandle Index 58 Name 'PRFQUERYPROGRAMHANDLE',
  F_PrfQueryProgramCategory Index 59 Name 'PRFQUERYPROGRAMCATEGORY',
  F_PrfDestroyGroup Index 60 Name 'PRFDESTROYGROUP',
  SheSetProfileHook Index 61 Name 'SheSetProfileHook',
  SheProfileHook Index 62 Name 'SheProfileHook',
  F_ShpLockProgramList Index 63 Name 'ShpLockProgramList',
  F_ShpUnlockProgramList Index 64 Name 'ShpUnlockProgramList',
  F_WinQueryTaskTitle Index 65 Name 'WINQUERYTASKTITLE',
  F_WinQueryTaskSizePos Index 66 Name 'WINQUERYTASKSIZEPOS',
  F_WinQuerySwitchList Index 67 Name 'WINQUERYSWITCHLIST',
  F_WinRemoveSwitchEntry Index 68 Name 'WINREMOVESWITCHENTRY',
  F_WinSwitchToProgram Index 69 Name 'WINSWITCHTOPROGRAM',
  F_WinSwitchProgramRegister Index 70 Name 'WINSWITCHPROGRAMREGISTER',
  F_WinEndProgram Index 73 Name 'WINENDPROGRAM',
  F_WinStopProgram Index 74 Name 'WinStopProgram',
  F_WinEndWindowSession Index 75 Name 'WinEndWindowSession',
  F_lpfnShellWndProc Index 76 Name 'lpfnShellWndProc',
  F_lpfnIconWndProc Index 77 Name 'lpfnIconWndProc',
  F_WinSwitchToTaskManager Index 78 Name 'WinSwitchToTaskManager',
  F_fnBadAppDlgProc Index 79 Name 'fnBadAppDlgProc',
  F_WinSwitchToProgram2 Index 80 Name 'WINSWITCHTOPROGRAM2',
  F_WinProcessHotKey Index 81 Name 'WinProcessHotKey',
  F_WinInitSession Index 82 Name 'WinInitSession',
  F_WinEndSession Index 83 Name 'WinEndSession',
  F_WinInitSwEntry Index 84 Name 'WinInitSwEntry',
  F_WinSetSwEntry Index 85 Name 'WinSetSwEntry',
  F_WinQueryExtIDFocus Index 86 Name 'WinQueryExtIdFocus',
  F_WinSetExtIDFocus Index 87 Name 'WinSetExtIdFocus',
  F_SheSystemShutdown Index 88 Name 'SHESYSTEMSHUTDOWN',
  F_StartSystemExecutables Index 89 Name 'startSystemExecutables',
  F_ShlLoadPublicFonts Index 90 Name 'ShlLoadPublicFonts',
  F_WinNoShutdown Index 91 Name 'WinNoShutdown',
  F_SheInitializeIniFile Index 92 Name 'SheInitializeIniFile',
  F_WinSetTitle Index 93 Name 'WinSetTitle',
  F_WinCplRegister Index 94 Name 'WinCplRegister',
  F_WinPMFileRegister Index 95 Name 'WinPMFileRegister',
  F_SheStartLongProgram Index 96 Name 'SheStartLongProgram',
  F_WinSetTitleAndIcon Index 97 Name 'WinSetTitleAndIcon',
  F_ShellWindow Index 100 Name 'ShellWindow',
  F_PrfQueryProfileSize Index 101 Name 'PrfQueryProfileSize',
  F_PrfOpenProfile Index 102 Name 'PrfOpenProfile',
  F_PrfCloseProfile Index 103 Name 'PrfCloseProfile',
  F_PrfRemoveProgram Index 104 Name 'PrfRemoveProgram',
  F_PrfCreateGroup Index 105 Name 'PrfCreateGroup',
  F_PrfDestroyGroup Index 106 Name 'PrfDestroyGroup',
  F_PrfQueryProfile Index 107 Name 'PrfQueryProfile',
  F_PrfReset Index 108 Name 'PrfReset',
  F_PrfAddProgram Index 109 Name 'PrfAddProgram',
  F_PrfChangeProgram Index 110 Name 'PrfChangeProgram',
  F_PrfQueryDefinition Index 111 Name 'PrfQueryDefinition',
  F_PrfQueryProgramHandle Index 112 Name 'PrfQueryProgramHandle',
  F_PrfQueryProgramTitles Index 113 Name 'PrfQueryProgramTitles',
  F_PrfQueryProfileInt Index 114 Name 'PrfQueryProfileInt',
  F_PrfQueryProfileString Index 115 Name 'PrfQueryProfileString',
  F_PrfWriteProfileString Index 116 Name 'PrfWriteProfileString',
  F_PrfQueryProfileData Index 117 Name 'PrfQueryProfileData',
  F_PrfWriteProfileData Index 118 Name 'PrfWriteProfileData',
  F_WinStartApp Index 119 Name 'WINSTARTAPP',
  F_WinAddSwitchEntry Index 120 Name 'WinAddSwitchEntry',
  F_WinCreateSwitchEntry Index 121 Name 'WinCreateSwitchEntry',
  F_WinQuerySessionTitle Index 122 Name 'WinQuerySessionTitle',
  F_WinChangeSwitchEntry Index 123 Name 'WinChangeSwitchEntry',
  F_WinQuerySwitchEntry Index 124 Name 'WinQuerySwitchEntry',
  F_WinQuerySwitchHandle Index 125 Name 'WinQuerySwitchHandle',
  F_WinQuerySwitchList Index 126 Name 'WinQuerySwitchList',
  F_WinQueryTaskSizePos Index 127 Name 'WinQueryTaskSizePos',
  F_WinQueryTaskTitle Index 128 Name 'WinQueryTaskTitle',
  F_WinRemoveSwitchEntry Index 129 Name 'WinRemoveSwitchEntry',
  F_WinTerminateApp Index 130 Name 'WinTerminateApp',
  F_WinSwitchToProgram Index 131 Name 'WinSwitchToProgram',
  F_PrfQueryProgramCategory Index 132 Name 'PrfQueryProgramCategory',
  F_PrfChangeWriteThru Index 133 Name 'PrfChangeWriteThru',
  F_ShePIInitIniFiles Index 134 Name 'ShePIInitIniFiles',
  F_SheSystemShutdown Index 151 Name 'SheSystemShutdown',
  F_StartSystemExecutables Index 152 Name 'StartSystemExecutables',
  F_PMExecRegister Index 153 Name 'PMExecRegister',
  F_WinHAPPfromPID Index 154 Name 'WINHAPPFROMPID',
  F_WinHSWITCHfromHAPP Index 155 Name 'WINHSWITCHFROMHAPP',
  F_WinSwitchProgramRegister Index 156 Name 'WinSwitchProgramRegister',
  F_WinEndProgram Index 157 Name 'WinEndProgram',
  F_WinSwitchToProgram2 Index 158 Name 'WinSwitchToProgram2',
  F_WinCanTerminate Index 160 Name 'WinCanTerminate',
  F_WinStartApp Index 201 Name 'WinStartApp',
  F_WinHAPPfromPID Index 208 Name 'WinHAPPfromPID',
  F_WinHSWITCHfromHAPP Index 209 Name 'WinHSWITCHfromHAPP',
  F_ShpPILockIniFile Index 210 Name 'ShpPILockIniFile',
  F_ShpPI16LockIniFile Index 211 Name 'ShpPI16LockIniFile',
  F_ShpPIShutdown Index 212 Name 'ShpPIShutdown',
  F_ShpPI16Shutdown Index 213 Name 'ShpPI16Shutdown';

Begin
End.
