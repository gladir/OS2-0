{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 PMDRAG.DLL de OS/2-0 (manipulation
                directe : glisser-deposer).
}

Library PMDRAG;

{$IMAGEBASE $00A00000}
{$R-,S-,I-}

{ Compilation : OS2PC PMDRAG.PAS   (produit PMDRAG.DLL)

  PMDRAG.DLL est la manipulation directe (glisser-deposer) de Presentation
  Manager : structures DRAGINFO, DRAGITEM et DRAGTRANSFER, chaines par
  handles (HSTR), mecanismes et formats de rendu (RMF), types, glissement
  (DrgDrag, glissement differe DrgLazyDrag), messages de transfert
  (DM_*) et glissement de fichiers (DrgDragFiles, DrgAcceptDroppedFiles).

  OS/2-0 n'a pas Presentation Manager : PMDRAG tient lui-meme un registre
  de fenetres (point d'entree interne DRGREGISTERWINDOW) : une fenetre
  est un handle (HWND), un rectangle de l'ecran en pels (640 x 400,
  origine en bas a gauche, une cellule de l'ecran texte = 8 x 16 pels) et
  une procedure de fenetre (hwnd, msg, mp1, mp2), appelee (_System) pour
  les messages DM_*. Les messages postes (DrgPostTransferMsg) sont remis
  quand le message envoye en cours se termine. DrgDrag suit la souris
  (MOUCALLS.DLL) jusqu'au relachement du bouton de fin (vkTerminate) ou a
  la touche Echap (KBDCALLS.DLL), envoie DM_DRAGOVER et DM_DRAGLEAVE a la
  fenetre sous le pointeur, puis DM_DROP a la cible qui a accepte
  (DOR_DROP) ; il rend son handle (0 si rien n'est depose).
  Les espaces de presentation (HPS de DrgGetPS) sont des handles sans
  dessin (pas de GPI).

  Convention _System : valeurs de 32 bits, pointeurs lineaires ; les
  structures gardent la disposition de PMWIN.H :
    DRAGINFO     cbDraginfo (4), cbDragitem (2), usOperation (2),
                 hwndSource (4), xDrop (2), yDrop (2), cditem (2),
                 usReserved (2) : 20 octets, suivis des DRAGITEM
    DRAGITEM     hwndItem, ulItemID, hstrType, hstrRMF,
                 hstrContainerName, hstrSourceName, hstrTargetName (4),
                 cxOffset, cyOffset, fsControl, fsSupportedOps (2) : 36
    DRAGTRANSFER cb, hwndClient, pditem, hstrSelectedRMF,
                 hstrRenderToName, ulTargetInfo (4), usOperation,
                 fsReply (2) : 28 octets
    DRAGIMAGE    cb, cptl (2), hImage, sizlStretch (cx, cy), fl (4),
                 cxOffset, cyOffset (2) : 24 octets
    RENDERFILE   hwndDragFiles, hstrSource, hstrTarget (4), fMove,
                 usRsvd (2) : 16 octets
  Les DRAGINFO et DRAGTRANSFER sont alloues dans la memoire de la DLL
  (partagee par tous les processus) ; les chaines des HSTR (C000h a
  C0FFh) sont partagees et comptees (la meme chaine rend le meme handle).

  Mecanismes et formats de rendu (RMF) : liste de paires separees par
  des virgules, <mecanisme,format> ou (m1,m2...)x(f1,f2...) (produit) ;
  la premiere paire est la paire native. Types : liste separee par des
  virgules, le premier est le type vrai (true type).
  Operations : DO_DEFAULT BFFEh, DO_UNKNOWN BFFFh, DO_COPY 0010h,
  DO_LINK 0018h, DO_MOVE 0020h, DO_CREATE 0040h. Reponses a DM_DRAGOVER
  (mot bas) : DOR_NODROP 0, DOR_DROP 1, DOR_NODROPOP 2, DOR_NEVERDROP 3 ;
  mot haut : operation. Messages : DM_DISCARDOBJECT 31Fh, DM_PRINTOBJECT
  320h, DM_DRAGOVERNOTIFY 321h, DM_RENDERFILE 322h, DM_FILERENDERED 323h,
  DM_DRAGERROR 324h, DM_EMPHASIZETARGET 325h, DM_DRAGFILECOMPLETE 326h,
  DM_RENDERPREPARE 327h, DM_RENDERCOMPLETE 328h, DM_RENDER 329h,
  DM_PRINT 32Ah, DM_ENDCONVERSATION 32Bh, DM_DROPHELP 32Ch,
  DM_DRAGLEAVE 32Dh, DM_DRAGOVER 32Eh, DM_DROP 32Fh.
  DrgQueryDragStatus : 0, DGS_DRAGINPROGRESS 1, DGS_LAZYDRAGINPROGRESS 2.
  vkTerminate : VK_BUTTON1 1, VK_BUTTON2 2, VK_BUTTON3 3, VK_ENDDRAG 38h
  (bouton 2).

  Glissement de fichiers : DrgDragFiles construit un DRAGITEM par fichier
  (<DRM_OS2FILE,DRF_UNKNOWN>, repertoire et nom) et appelle DrgDrag ;
  une fenetre inscrite par DrgAcceptDroppedFiles accepte les fichiers
  (de ses types) et les copie (DO_COPY) ou les deplace (DO_MOVE) dans son
  repertoire ; la source recoit DM_ENDCONVERSATION pour chaque fichier et
  DM_DRAGFILECOMPLETE (DF_MOVE 1, DF_SOURCE 2, DF_SUCCESSFUL 4). Avec
  fSourceRender, la source recoit d'abord DM_RENDERFILE (RENDERFILE) :
  si elle rend TRUE, elle a fait le transfert.

  Fonctions exportees : ordinaux 1 a 31 (points d'entree 16 bits d'OS/2,
  noms en majuscules) et 32 a 62 (32 bits) : DrgAccessDraginfo,
  DrgAddStrHandle, DrgAllocDraginfo, DrgAllocDragtransfer,
  DrgDeleteDraginfoStrHandles, DrgDeleteStrHandle, DrgDrag,
  DrgFreeDraginfo, DrgFreeDragtransfer, DrgGetPS, DrgPostTransferMsg,
  DrgPushDraginfo, DrgQueryDragitem, DrgQueryDragitemCount,
  DrgQueryDragitemPtr, DrgQueryNativeRMF, DrgQueryNativeRMFLen,
  DrgQueryStrName, DrgQueryStrNameLen, DrgQueryTrueType,
  DrgQueryTrueTypeLen, DrgReleasePS, DrgSendTransferMsg,
  DrgSetDragPointer, DrgSetDragImage, DrgSetDragitem, DrgVerifyNativeRMF,
  DrgVerifyRMF, DrgVerifyTrueType, DrgVerifyType, DrgVerifyTypeSet ;
  63/65 DrgDragFiles, 64/66 DrgAcceptDroppedFiles, 67 DrgLazyDrag,
  68 DrgCancelLazyDrag, 69 DrgLazyDrop, 70 DrgQueryDraginfoPtr,
  71 DrgQueryDraginfoPtrFromHwnd, 72 DrgQueryDraginfoPtrFromDragitem,
  73 DrgQueryDragStatus, 74 DrgReallocDraginfo, 75 DrgQueryFormat
  (Drg32QueryFormat), 76 DrgGetClipPS. Les deux points d'entree d'une
  meme fonction ont le meme effet (OS/2-0 n'a pas de code 16 bits).
  DrgQueryFormat(pditem, pszMecanisme, cb, pszFormat) (interpretation
  d'OS/2-0) : premier format du mecanisme (0 : natif) ; rend sa longueur.
  DrgGetClipPS(hwnd, hwndClip, fl) : comme DrgGetPS.
  Points d'entree internes a OS/2-0 :
   200 DRGREGISTERWINDOW(hwnd, pfnWndProc, x, y, cx, cy, fl) : inscrire
       (ou modifier) une fenetre ; pfnWndProc = 0 et cx = 0 : la retirer ;
       fl = 1 : procedure d'un programme OS2PC (ses fonctions suivent la
       convention Pascal : parametres empiles de gauche a droite, pile
       nettoyee par la procedure), 0 : convention _System
   201 DRGQUERYDROPTARGET(x, y) : fenetre sous un point (pels)

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services des autres DLL, utilitaires
    Partie 3 - Memoire de la DLL
    Partie 4 - Chaines (HSTR)
    Partie 5 - Fenetres et messages
    Partie 6 - DRAGINFO, DRAGITEM, DRAGTRANSFER
    Partie 7 - Mecanismes, formats et types
    Partie 8 - Glissement
    Partie 9 - Fichiers
    Partie 10 - Points d'entree 16 bits
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  DM_DISCARDOBJECT    = $031F;
  DM_PRINTOBJECT      = $0320;
  DM_DRAGOVERNOTIFY   = $0321;
  DM_RENDERFILE       = $0322;
  DM_FILERENDERED     = $0323;
  DM_DRAGERROR        = $0324;
  DM_EMPHASIZETARGET  = $0325;
  DM_DRAGFILECOMPLETE = $0326;
  DM_RENDERPREPARE    = $0327;
  DM_RENDERCOMPLETE   = $0328;
  DM_RENDER           = $0329;
  DM_PRINT            = $032A;
  DM_ENDCONVERSATION  = $032B;
  DM_DROPHELP         = $032C;
  DM_DRAGLEAVE        = $032D;
  DM_DRAGOVER         = $032E;
  DM_DROP             = $032F;

  DO_DEFAULT = $BFFE;
  DO_UNKNOWN = $BFFF;
  DO_COPY    = $0010;
  DO_LINK    = $0018;
  DO_MOVE    = $0020;
  DO_CREATE  = $0040;
  DO_COPYABLE = 1;
  DO_MOVEABLE = 2;

  DOR_NODROP    = 0;
  DOR_DROP      = 1;
  DOR_NODROPOP  = 2;
  DOR_NEVERDROP = 3;

  DMFL_TARGETSUCCESSFUL = 1;
  DMFL_TARGETFAIL       = 2;
  DF_MOVE       = 1;
  DF_SOURCE     = 2;
  DF_SUCCESSFUL = 4;

  DGS_DRAGINPROGRESS     = 1;
  DGS_LAZYDRAGINPROGRESS = 2;

  VK_BUTTON1 = 1;
  VK_BUTTON2 = 2;
  VK_BUTTON3 = 3;
  VK_ENDDRAG = $38;

  CbInfo = 20;               { DRAGINFO }
  CbItem = 36;               { DRAGITEM }
  CbXfer = 28;               { DRAGTRANSFER }

  ArenaSize = 65536;         { memoire des structures }
  MaxStr  = 256;             { chaines (HSTR) }
  StrSlot = 256;
  HstrBase = $C000;
  MaxDi   = 64;              { DRAGINFO alloues }
  MaxDx   = 32;              { tableaux DRAGTRANSFER }
  MaxWin  = 32;              { fenetres inscrites }
  MaxPost = 32;              { messages postes }
  MaxPS   = 8;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { memoire : blocs (en-tete : taille, proprietaire) }
  Arena   : Array[0..ArenaSize - 1] Of Byte;
  { chaines }
  StrBuf  : Array[0..MaxStr * StrSlot - 1] Of Byte;
  StrRef  : Array[0..MaxStr - 1] Of LongInt;
  { DRAGINFO }
  DiAddr, DiRefs, DiOwner : Array[0..MaxDi - 1] Of LongInt;
  { DRAGTRANSFER }
  DxAddr, DxCount, DxLeft : Array[0..MaxDx - 1] Of LongInt;
  { fenetres }
  WHwnd, WProc, WX, WY, WCX, WCY, WConv : Array[0..MaxWin - 1] Of LongInt;
  WAccept, WAccOp : Array[0..MaxWin - 1] Of LongInt;
  WAccBuf : Array[0..MaxWin * 256 - 1] Of Byte;      { repertoire, types }
  { messages postes }
  PHwnd, PMsg, PMp1, PMp2 : Array[0..MaxPost - 1] Of LongInt;
  PCount, SendDepth : LongInt;
  { espaces de presentation }
  PSHwnd  : Array[0..MaxPS - 1] Of LongInt;
  { glissement en cours }
  DragStat, DragInfo, DragPtr, DragImgs, DragFiles, DragFileRender : LongInt;
  LastTarget, LastReply : LongInt;
  { tampons }
  NameZ, Name2 : Array[0..259] Of Byte;
  { paires RMF analysees }
  RmfM, RmfF : Array[0..63] Of String[63];
  RmfN    : LongInt;
  Dummy   : LongInt;

{ ==================================================================== }
{ Partie 2 - Services des autres DLL, utilitaires                      }
{ ==================================================================== }

Function MouOpen(PDrv, PHmou : LongInt) : LongInt; External 'MOUCALLS' Name 'MouOpen';
Function MouClose(Hmou : LongInt) : LongInt; External 'MOUCALLS' Name 'MouClose';
Function MouGetPtrPos(PPos, Hmou : LongInt) : LongInt; External 'MOUCALLS' Name 'MouGetPtrPos';
Function MouReadEventQue(PEv, PWait, Hmou : LongInt) : LongInt; External 'MOUCALLS' Name 'MouReadEventQue';
Function MouDrawPtr(Hmou : LongInt) : LongInt; External 'MOUCALLS' Name 'MouDrawPtr';
Function KbdCharIn(PInfo, Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdCharIn';
Function DcSleep(Ms : LongInt) : LongInt; External 'DOSCALLS' Name 'DosSleep';
Function DcCopy(PSrc, PDst, Opt : LongInt) : LongInt; External 'DOSCALLS' Name 'DosCopy';
Function DcMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS' Name 'DosMove';
Function DcDelete(PName : LongInt) : LongInt; External 'DOSCALLS' Name 'DosDelete';
Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
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
  P^ := V And $FF;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

Function Alive(Pid : LongInt) : Boolean;
Begin
  Alive := (Pid = MyPid) Or (KrnMonIo(0, 4, Pid) <> 0);
End;

Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (RdB(A + N) <> 0) And (N < 255) Do
    Begin
      S := S + Chr(RdB(A + N));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

{ Copier S dans un tampon de Cb octets (avec le zero) ; rend le nombre
  d'octets copies sans le zero }
Function PutZN(A, Cb : LongInt; S : String) : LongInt;
Begin
  If (A = 0) Or (Cb <= 0) Then
  Begin
    PutZN := 0;
    Exit;
  End;
  If Length(S) > Cb - 1 Then S := Copy(S, 1, Cb - 1);
  PutZ(A, S);
  PutZN := Length(S);
End;

Function TrimS(S : String) : String;
Begin
  While (Length(S) > 0) And (Ord(S[1]) = 32) Do S := Copy(S, 2, 255);
  While (Length(S) > 0) And (Ord(S[Length(S)]) = 32) Do S := Copy(S, 1, Length(S) - 1);
  TrimS := S;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

{ Element N (0..) d'une liste separee par des virgules ; '' au-dela }
Function ListItem(S : String; N : LongInt) : String;
Var K, I : LongInt; W : String;
Begin
  W := '';
  I := 0;
  For K := 1 To Length(S) Do
    If Ord(S[K]) = 44 Then Inc(I)
    Else If I = N Then W := W + S[K];
  ListItem := TrimS(W);
End;

Function ListCount(S : String) : LongInt;
Var K, N : LongInt;
Begin
  If TrimS(S) = '' Then N := 0
  Else
  Begin
    N := 1;
    For K := 1 To Length(S) Do
      If Ord(S[K]) = 44 Then Inc(N);
  End;
  ListCount := N;
End;

{ ==================================================================== }
{ Partie 3 - Memoire de la DLL                                         }
{ ==================================================================== }

{ Blocs : +0 taille totale (multiple de 8, bit 0 = utilise), +4 processus }
Function MemAlloc(Size : LongInt) : LongInt;
Var P, BS, Need, R, Base : LongInt;
Begin
  R := 0;
  Need := ((Size + 7) And Not 7) + 8;
  Base := LongInt(@Arena);
  P := 0;
  While (R = 0) And (P < ArenaSize) Do
  Begin
    BS := RdL(Base + P) And Not 1;
    If BS <= 0 Then P := ArenaSize
    Else
    Begin
      If (RdL(Base + P) And 1) = 0 Then
      Begin
        { reunir les blocs libres suivants }
        While (P + BS < ArenaSize) And ((RdL(Base + P + BS) And 1) = 0) And (RdL(Base + P + BS) > 0) Do
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
          For Need := 0 To BS - 9 Do WrB(R + Need, 0);
        End;
      End;
      P := P + BS;
    End;
  End;
  MemAlloc := R;
End;

Procedure MemFree(A : LongInt);
Var P : LongInt;
Begin
  P := A - 8 - LongInt(@Arena);
  If (P >= 0) And (P < ArenaSize) Then
    WrL(A - 8, RdL(A - 8) And Not 1);
End;

{ ==================================================================== }
{ Partie 4 - Chaines (HSTR)                                            }
{ ==================================================================== }

Function StrGet(I : LongInt) : String;
Var S : String; K, N : LongInt;
Begin
  S := '';
  N := StrBuf[I * StrSlot];
  For K := 1 To N Do S := S + Chr(StrBuf[I * StrSlot + K]);
  StrGet := S;
End;

Procedure StrSet(I : LongInt; S : String);
Var K : LongInt;
Begin
  StrBuf[I * StrSlot] := Length(S);
  For K := 1 To Length(S) Do StrBuf[I * StrSlot + K] := Ord(S[K]);
End;

{ Rang d'un HSTR ; -1 si invalide }
Function StrIdx(H : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := H - HstrBase;
  If (I >= 0) And (I < MaxStr) Then
  Begin
    If StrRef[I] <= 0 Then I := -1;
  End
  Else I := -1;
  StrIdx := I;
End;

{ Chaine d'un HSTR ('' si 0 ou invalide) }
Function HStr(H : LongInt) : String;
Var I : LongInt;
Begin
  I := StrIdx(H);
  If I < 0 Then HStr := '' Else HStr := StrGet(I);
End;

Function AddStr(S : String) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxStr - 1 DownTo 0 Do
    If (StrRef[I] > 0) And (StrGet(I) = S) Then F := I;
  If F >= 0 Then
  Begin
    Inc(StrRef[F]);
    AddStr := HstrBase + F;
    Exit;
  End;
  For I := MaxStr - 1 DownTo 0 Do
    If StrRef[I] <= 0 Then F := I;
  If F < 0 Then AddStr := 0
  Else
  Begin
    StrSet(F, S);
    StrRef[F] := 1;
    AddStr := HstrBase + F;
  End;
End;

Function DelStr(H : LongInt) : Boolean;
Var I : LongInt;
Begin
  I := StrIdx(H);
  If I < 0 Then DelStr := False
  Else
  Begin
    Dec(StrRef[I]);
    DelStr := True;
  End;
End;

{ DrgAddStrHandle(psz) : handle de la chaine (0 : erreur) }
Function DrgAddStrHandle(P : LongInt) : LongInt;
Begin
  If P = 0 Then DrgAddStrHandle := 0 Else DrgAddStrHandle := AddStr(GetZ(P));
End;

{ DrgDeleteStrHandle(hstr) : BOOL }
Function DrgDeleteStrHandle(H : LongInt) : LongInt;
Begin
  If DelStr(H) Then DrgDeleteStrHandle := 1 Else DrgDeleteStrHandle := 0;
End;

{ DrgQueryStrName(hstr, cb, psz) : octets copies (sans le zero) }
Function DrgQueryStrName(H, Cb, P : LongInt) : LongInt;
Begin
  If StrIdx(H) < 0 Then DrgQueryStrName := 0 Else DrgQueryStrName := PutZN(P, Cb, HStr(H));
End;

Function DrgQueryStrNameLen(H : LongInt) : LongInt;
Begin
  DrgQueryStrNameLen := Length(HStr(H));
End;

{ ==================================================================== }
{ Partie 5 - Fenetres et messages                                      }
{ ==================================================================== }

Function CallPtr4(F, A1, A2, A3, A4 : LongInt) : LongInt;
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
  CallPtr4 := R;
End;

{ Procedure d'un programme OS2PC (convention Pascal : parametres
  empiles de gauche a droite, pile nettoyee par la procedure) }
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

Function WinIdx(Hwnd : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  If Hwnd <> 0 Then
    For I := MaxWin - 1 DownTo 0 Do
      If WHwnd[I] = Hwnd Then R := I;
  WinIdx := R;
End;

{ Fenetre sous un point (la derniere inscrite est au-dessus) }
Function WinAt(X, Y : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  For I := 0 To MaxWin - 1 Do
    If (WHwnd[I] <> 0) And (X >= WX[I]) And (X < WX[I] + WCX[I]) And (Y >= WY[I]) And (Y < WY[I] + WCY[I]) Then
      R := WHwnd[I];
  WinAt := R;
End;

Procedure FlushPosts; Forward;
Function AcceptProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt; Forward;

{ Envoyer un message a une fenetre inscrite ; 0 si elle n'existe pas }
Function SendMsg(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  I := WinIdx(Hwnd);
  If I >= 0 Then
  Begin
    Inc(SendDepth);
    If (WAccept[I] <> 0) And ((Msg = DM_DRAGOVER) Or (Msg = DM_DROP) Or (Msg = DM_DRAGLEAVE)) Then
      R := AcceptProc(I, Msg, Mp1, Mp2)
    Else If WProc[I] <> 0 Then
    Begin
      If WConv[I] = 1 Then R := CallPas4(WProc[I], Hwnd, Msg, Mp1, Mp2)
      Else R := CallPtr4(WProc[I], Hwnd, Msg, Mp1, Mp2);
    End;
    Dec(SendDepth);
    If SendDepth = 0 Then FlushPosts;
  End;
  SendMsg := R;
End;

{ Remettre les messages postes (quand aucun message n'est en cours) }
Procedure FlushPosts;
Var H, M, A, B, K, N : LongInt;
Begin
  N := 0;
  While (PCount > 0) And (N < 256) Do
  Begin
    H := PHwnd[0]; M := PMsg[0]; A := PMp1[0]; B := PMp2[0];
    For K := 0 To PCount - 2 Do
    Begin
      PHwnd[K] := PHwnd[K + 1]; PMsg[K] := PMsg[K + 1];
      PMp1[K] := PMp1[K + 1]; PMp2[K] := PMp2[K + 1];
    End;
    Dec(PCount);
    Dummy := SendMsg(H, M, A, B);
    Inc(N);
  End;
End;

Function PostMsg(Hwnd, Msg, Mp1, Mp2 : LongInt) : Boolean;
Begin
  If (WinIdx(Hwnd) < 0) Or (PCount >= MaxPost) Then PostMsg := False
  Else
  Begin
    PHwnd[PCount] := Hwnd; PMsg[PCount] := Msg; PMp1[PCount] := Mp1; PMp2[PCount] := Mp2;
    Inc(PCount);
    If SendDepth = 0 Then FlushPosts;
    PostMsg := True;
  End;
End;

{ Inscrire ou modifier une fenetre ; rend son rang (-1 : table pleine) }
Function WinSet(Hwnd, Proc, X, Y, Cx, Cy, Fl : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := WinIdx(Hwnd);
  If I < 0 Then
  Begin
    I := 0;
    While (I < MaxWin) And (WHwnd[I] <> 0) Do Inc(I);
    If I >= MaxWin Then I := -1 Else WAccept[I] := 0;
  End;
  If I >= 0 Then
  Begin
    WHwnd[I] := Hwnd;
    WProc[I] := Proc;
    WX[I] := X; WY[I] := Y; WCX[I] := Cx; WCY[I] := Cy;
    WConv[I] := Fl And 1;
  End;
  WinSet := I;
End;

{ DRGREGISTERWINDOW(hwnd, pfnWndProc, x, y, cx, cy, fl) (OS/2-0) : BOOL ;
  pfnWndProc = 0 et cx = 0 : retirer la fenetre ; fl 1 : procedure d'un
  programme OS2PC (convention Pascal), 0 : _System }
Function DrgRegisterWindow(Hwnd, Proc, X, Y, Cx, Cy, Fl : LongInt) : LongInt;
Var I : LongInt;
Begin
  DrgRegisterWindow := 0;
  If Hwnd = 0 Then Exit;
  If (Proc = 0) And (Cx = 0) Then
  Begin
    I := WinIdx(Hwnd);
    If I >= 0 Then
    Begin
      WHwnd[I] := 0;
      WAccept[I] := 0;
      DrgRegisterWindow := 1;
    End;
  End
  Else If WinSet(Hwnd, Proc, X, Y, Cx, Cy, Fl) >= 0 Then DrgRegisterWindow := 1;
End;

{ DRGQUERYDROPTARGET(x, y) (OS/2-0) }
Function DrgQueryDropTarget(X, Y : LongInt) : LongInt;
Begin
  DrgQueryDropTarget := WinAt(X, Y);
End;

{ DrgSendTransferMsg(hwnd, msg, mp1, mp2) : MRESULT }
Function DrgSendTransferMsg(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  DrgSendTransferMsg := SendMsg(Hwnd, Msg, Mp1, Mp2);
End;

{ DrgPostTransferMsg(hwnd, msg, pdxfer, fl, ulRsvd, fRetry) : BOOL ;
  fsReply <- fl }
Function DrgPostTransferMsg(Hwnd, Msg, PX, Fl, Rsvd, Retry : LongInt) : LongInt;
Begin
  DrgPostTransferMsg := 0;
  If (WinIdx(Hwnd) < 0) Or (PCount >= MaxPost) Then Exit;
  If PX <> 0 Then WrW(PX + 26, Fl);
  If PostMsg(Hwnd, Msg, PX, 0) Then DrgPostTransferMsg := 1;
End;

{ DrgGetPS(hwnd), DrgGetClipPS(hwnd, hwndClip, fl) : HPS (sans dessin) ;
  DrgReleasePS(hps) : BOOL }
Function GetPS(Hwnd : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  If Hwnd <> 0 Then
    For I := MaxPS - 1 DownTo 0 Do
      If PSHwnd[I] = 0 Then F := I;
  If F < 0 Then GetPS := 0
  Else
  Begin
    PSHwnd[F] := Hwnd;
    GetPS := $50530000 + F + 1;
  End;
End;

Function DrgGetPS(Hwnd : LongInt) : LongInt;
Begin
  DrgGetPS := GetPS(Hwnd);
End;

Function DrgGetClipPS(Hwnd, HwndClip, Fl : LongInt) : LongInt;
Begin
  DrgGetClipPS := GetPS(Hwnd);
End;

Function DrgReleasePS(Hps : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := Hps - $50530000 - 1;
  If (I < 0) Or (I >= MaxPS) Then DrgReleasePS := 0
  Else If PSHwnd[I] = 0 Then DrgReleasePS := 0
  Else
  Begin
    PSHwnd[I] := 0;
    DrgReleasePS := 1;
  End;
End;

{ ==================================================================== }
{ Partie 6 - DRAGINFO, DRAGITEM, DRAGTRANSFER                          }
{ ==================================================================== }

Function DiIdx(P : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := -1;
  If P <> 0 Then
    For I := MaxDi - 1 DownTo 0 Do
      If DiAddr[I] = P Then R := I;
  DiIdx := R;
End;

Function ItemCount(P : LongInt) : LongInt;
Begin
  ItemCount := RdW(P + 16);
End;

Function ItemPtr(P, I : LongInt) : LongInt;
Begin
  ItemPtr := P + CbInfo + I * CbItem;
End;

{ DrgAllocDraginfo(cditem) : PDRAGINFO (0 : erreur) }
Function DrgAllocDraginfo(N : LongInt) : LongInt;
Var I, F, P : LongInt;
Begin
  DrgAllocDraginfo := 0;
  If (N < 0) Or (N > 1000) Then Exit;
  F := -1;
  For I := MaxDi - 1 DownTo 0 Do
    If (DiAddr[I] = 0) Or Not Alive(DiOwner[I]) Then F := I;
  If F < 0 Then Exit;
  If DiAddr[F] <> 0 Then MemFree(DiAddr[F]);
  DiAddr[F] := 0;
  P := MemAlloc(CbInfo + N * CbItem);
  If P = 0 Then Exit;
  WrL(P, CbInfo + N * CbItem);
  WrW(P + 4, CbItem);
  WrW(P + 6, DO_DEFAULT);
  WrW(P + 16, N);
  DiAddr[F] := P;
  DiRefs[F] := 1;
  DiOwner[F] := MyPid;
  DrgAllocDraginfo := P;
End;

{ DrgFreeDraginfo(pdinfo) : BOOL ; la memoire est liberee quand tous
  ceux qui y ont acces (DrgAllocDraginfo, DrgPushDraginfo) l'ont liberee.
  Comme sous PM, apres DM_DROP la cible libere le DRAGINFO ; la source
  le libere si DrgDrag rend 0. }
Function DrgFreeDraginfo(P : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := DiIdx(P);
  If I < 0 Then DrgFreeDraginfo := 0
  Else
  Begin
    Dec(DiRefs[I]);
    If DiRefs[I] <= 0 Then
    Begin
      If DragInfo = P Then DragInfo := 0;
      MemFree(P);
      DiAddr[I] := 0;
    End;
    DrgFreeDraginfo := 1;
  End;
End;

{ DrgAccessDraginfo(pdinfo) : BOOL (la memoire est partagee) }
Function DrgAccessDraginfo(P : LongInt) : LongInt;
Begin
  If DiIdx(P) < 0 Then DrgAccessDraginfo := 0 Else DrgAccessDraginfo := 1;
End;

{ DrgPushDraginfo(pdinfo, hwndDest) : la destination recoit un acces
  (a liberer par DrgFreeDraginfo) ; BOOL }
Function DrgPushDraginfo(P, Hwnd : LongInt) : LongInt;
Var I : LongInt;
Begin
  I := DiIdx(P);
  If (I < 0) Or (Hwnd = 0) Then DrgPushDraginfo := 0
  Else
  Begin
    Inc(DiRefs[I]);
    DrgPushDraginfo := 1;
  End;
End;

{ DrgReallocDraginfo(pdinfoOld, cditem) : nouveau DRAGINFO (en-tete et
  elements conserves) ; l'ancien est libere }
Function DrgReallocDraginfo(Old, N : LongInt) : LongInt;
Var P, K, M : LongInt;
Begin
  DrgReallocDraginfo := 0;
  If DiIdx(Old) < 0 Then Exit;
  P := DrgAllocDraginfo(N);
  If P = 0 Then Exit;
  WrW(P + 6, RdW(Old + 6));
  WrL(P + 8, RdL(Old + 8));
  WrL(P + 12, RdL(Old + 12));
  M := ItemCount(Old);
  If M > N Then M := N;
  For K := 0 To M * CbItem - 1 Do WrB(P + CbInfo + K, RdB(Old + CbInfo + K));
  If DragInfo = Old Then DragInfo := P;
  Dummy := DrgFreeDraginfo(Old);
  DrgReallocDraginfo := P;
End;

Function DrgQueryDragitemCount(P : LongInt) : LongInt;
Begin
  If DiIdx(P) < 0 Then DrgQueryDragitemCount := 0 Else DrgQueryDragitemCount := ItemCount(P);
End;

Function DrgQueryDragitemPtr(P, I : LongInt) : LongInt;
Begin
  If (DiIdx(P) < 0) Or (I < 0) Or (I >= ItemCount(P)) Then DrgQueryDragitemPtr := 0
  Else DrgQueryDragitemPtr := ItemPtr(P, I);
End;

{ DrgQueryDragitem(pdinfo, cb, pditem, i) : copier l'element ; BOOL }
Function DrgQueryDragitem(P, Cb, PItem, I : LongInt) : LongInt;
Var K : LongInt;
Begin
  If (DiIdx(P) < 0) Or (I < 0) Or (I >= ItemCount(P)) Or (PItem = 0) Or (Cb <= 0) Then DrgQueryDragitem := 0
  Else
  Begin
    If Cb > CbItem Then Cb := CbItem;
    For K := 0 To Cb - 1 Do WrB(PItem + K, RdB(ItemPtr(P, I) + K));
    DrgQueryDragitem := 1;
  End;
End;

{ DrgSetDragitem(pdinfo, pditem, cb, i) : BOOL }
Function DrgSetDragitem(P, PItem, Cb, I : LongInt) : LongInt;
Var K : LongInt;
Begin
  If (DiIdx(P) < 0) Or (I < 0) Or (I >= ItemCount(P)) Or (PItem = 0) Or (Cb <= 0) Then DrgSetDragitem := 0
  Else
  Begin
    If Cb > CbItem Then Cb := CbItem;
    For K := 0 To Cb - 1 Do WrB(ItemPtr(P, I) + K, RdB(PItem + K));
    DrgSetDragitem := 1;
  End;
End;

{ DrgDeleteDraginfoStrHandles(pdinfo) : retirer les HSTR des elements ;
  BOOL }
Function DrgDeleteDraginfoStrHandles(P : LongInt) : LongInt;
Var I, K : LongInt;
Begin
  If DiIdx(P) < 0 Then DrgDeleteDraginfoStrHandles := 0
  Else
  Begin
    For I := 0 To ItemCount(P) - 1 Do
      For K := 0 To 4 Do
      Begin
        Dummy := DrgDeleteStrHandle(RdL(ItemPtr(P, I) + 8 + K * 4));
        WrL(ItemPtr(P, I) + 8 + K * 4, 0);
      End;
    DrgDeleteDraginfoStrHandles := 1;
  End;
End;

{ DrgQueryDraginfoPtr(pRsvd) : DRAGINFO du glissement en cours }
Function DrgQueryDraginfoPtr(PRsvd : LongInt) : LongInt;
Begin
  If DragStat = 0 Then DrgQueryDraginfoPtr := 0 Else DrgQueryDraginfoPtr := DragInfo;
End;

{ DrgQueryDraginfoPtrFromHwnd(hwndSource) }
Function DrgQueryDraginfoPtrFromHwnd(Hwnd : LongInt) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  If (DragStat <> 0) And (DragInfo <> 0) And (RdL(DragInfo + 8) = Hwnd) Then R := DragInfo;
  If R = 0 Then
    For I := MaxDi - 1 DownTo 0 Do
      If (DiAddr[I] <> 0) And (Hwnd <> 0) And (RdL(DiAddr[I] + 8) = Hwnd) Then R := DiAddr[I];
  DrgQueryDraginfoPtrFromHwnd := R;
End;

{ DrgQueryDraginfoPtrFromDragitem(pditem) }
Function DrgQueryDraginfoPtrFromDragitem(PItem : LongInt) : LongInt;
Var I, R, P : LongInt;
Begin
  R := 0;
  For I := 0 To MaxDi - 1 Do
  Begin
    P := DiAddr[I];
    If (P <> 0) And (PItem >= P + CbInfo) And (PItem < P + CbInfo + ItemCount(P) * CbItem) And
       (((PItem - P - CbInfo) Mod CbItem) = 0) Then R := P;
  End;
  DrgQueryDraginfoPtrFromDragitem := R;
End;

{ DrgAllocDragtransfer(n) : tableau de n DRAGTRANSFER (cb = 28) }
Function DrgAllocDragtransfer(N : LongInt) : LongInt;
Var I, F, P : LongInt;
Begin
  DrgAllocDragtransfer := 0;
  If (N <= 0) Or (N > 1000) Then Exit;
  F := -1;
  For I := MaxDx - 1 DownTo 0 Do
    If DxAddr[I] = 0 Then F := I;
  If F < 0 Then Exit;
  P := MemAlloc(N * CbXfer);
  If P = 0 Then Exit;
  For I := 0 To N - 1 Do WrL(P + I * CbXfer, CbXfer);
  DxAddr[F] := P;
  DxCount[F] := N;
  DxLeft[F] := N;
  DrgAllocDragtransfer := P;
End;

{ DrgFreeDragtransfer(pdxfer) : liberer une structure du tableau ; le
  tableau est libere avec la derniere ; BOOL }
Function DrgFreeDragtransfer(P : LongInt) : LongInt;
Var I, F : LongInt;
Begin
  F := -1;
  For I := MaxDx - 1 DownTo 0 Do
    If (DxAddr[I] <> 0) And (P >= DxAddr[I]) And (P < DxAddr[I] + DxCount[I] * CbXfer) And
       (((P - DxAddr[I]) Mod CbXfer) = 0) Then F := I;
  If F < 0 Then DrgFreeDragtransfer := 0
  Else
  Begin
    Dec(DxLeft[F]);
    If DxLeft[F] <= 0 Then
    Begin
      MemFree(DxAddr[F]);
      DxAddr[F] := 0;
    End;
    DrgFreeDragtransfer := 1;
  End;
End;

{ ==================================================================== }
{ Partie 7 - Mecanismes, formats et types                              }
{ ==================================================================== }

{ Analyser une chaine RMF en paires (RmfM, RmfF) }
Procedure ParseRMF(S : String);
Var K, D, I, J, NM, NF : LongInt; E, A, B, Ms, Fs : String;
Begin
  RmfN := 0;
  K := 1;
  While K <= Length(S) Do
  Begin
    { entree suivante : jusqu'a la virgule hors des < > et ( ) }
    E := '';
    D := 0;
    While (K <= Length(S)) And ((Ord(S[K]) <> 44) Or (D > 0)) Do
    Begin
      If (Ord(S[K]) = 60) Or (Ord(S[K]) = 40) Then Inc(D);
      If (Ord(S[K]) = 62) Or (Ord(S[K]) = 41) Then Dec(D);
      E := E + S[K];
      Inc(K);
    End;
    Inc(K);
    E := TrimS(E);
    If (Length(E) > 2) And (Ord(E[1]) = 60) Then
    Begin
      { <mecanisme,format> }
      E := Copy(E, 2, Length(E) - 2);
      If RmfN < 64 Then
      Begin
        RmfM[RmfN] := ListItem(E, 0);
        RmfF[RmfN] := ListItem(E, 1);
        Inc(RmfN);
      End;
    End
    Else If (Length(E) > 2) And (Ord(E[1]) = 40) Then
    Begin
      { (m1,m2)x(f1,f2) }
      I := Pos(')', E);
      A := Copy(E, 2, I - 2);
      B := TrimS(Copy(E, I + 1, 255));
      If (Length(B) > 0) And ((Ord(B[1]) = 120) Or (Ord(B[1]) = 88)) Then B := TrimS(Copy(B, 2, 255));
      If (Length(B) > 1) And (Ord(B[1]) = 40) Then B := Copy(B, 2, Length(B) - 2);
      NM := ListCount(A); NF := ListCount(B);
      For I := 0 To NM - 1 Do
        For J := 0 To NF - 1 Do
          If RmfN < 64 Then
          Begin
            Ms := ListItem(A, I); Fs := ListItem(B, J);
            RmfM[RmfN] := Ms;
            RmfF[RmfN] := Fs;
            Inc(RmfN);
          End;
    End;
  End;
End;

Function ItemRMF(PItem : LongInt) : String;
Begin
  ItemRMF := HStr(RdL(PItem + 12));
End;

Function ItemTypes(PItem : LongInt) : String;
Begin
  ItemTypes := HStr(RdL(PItem + 8));
End;

Function NativeRMF(PItem : LongInt) : String;
Begin
  ParseRMF(ItemRMF(PItem));
  If RmfN = 0 Then NativeRMF := '' Else NativeRMF := '<' + RmfM[0] + ',' + RmfF[0] + '>';
End;

{ DrgQueryNativeRMF(pditem, cb, pBuffer) : BOOL }
Function DrgQueryNativeRMF(PItem, Cb, P : LongInt) : LongInt;
Var S : String;
Begin
  S := '';
  If PItem <> 0 Then S := NativeRMF(PItem);
  If (S = '') Or (P = 0) Or (Cb <= 0) Then DrgQueryNativeRMF := 0
  Else
  Begin
    Dummy := PutZN(P, Cb, S);
    DrgQueryNativeRMF := 1;
  End;
End;

Function DrgQueryNativeRMFLen(PItem : LongInt) : LongInt;
Begin
  If PItem = 0 Then DrgQueryNativeRMFLen := 0 Else DrgQueryNativeRMFLen := Length(NativeRMF(PItem));
End;

{ DrgQueryTrueType(pditem, cb, psz) : premier type ; BOOL }
Function DrgQueryTrueType(PItem, Cb, P : LongInt) : LongInt;
Var S : String;
Begin
  S := '';
  If PItem <> 0 Then S := ListItem(ItemTypes(PItem), 0);
  If (S = '') Or (P = 0) Or (Cb <= 0) Then DrgQueryTrueType := 0
  Else
  Begin
    Dummy := PutZN(P, Cb, S);
    DrgQueryTrueType := 1;
  End;
End;

Function DrgQueryTrueTypeLen(PItem : LongInt) : LongInt;
Begin
  If PItem = 0 Then DrgQueryTrueTypeLen := 0 Else DrgQueryTrueTypeLen := Length(ListItem(ItemTypes(PItem), 0));
End;

{ La paire (M, F) est-elle offerte par l'element ? ('' : tout) }
Function HasRMF(PItem : LongInt; M, F : String) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  ParseRMF(ItemRMF(PItem));
  For I := 0 To RmfN - 1 Do
    If ((M = '') Or (RmfM[I] = M)) And ((F = '') Or (RmfF[I] = F)) Then R := True;
  HasRMF := R;
End;

{ DrgVerifyRMF(pditem, pszMech, pszFmt) : BOOL (nul : tout) }
Function DrgVerifyRMF(PItem, PM, PF : LongInt) : LongInt;
Begin
  If PItem = 0 Then DrgVerifyRMF := 0
  Else If HasRMF(PItem, TrimS(GetZ(PM)), TrimS(GetZ(PF))) Then DrgVerifyRMF := 1
  Else DrgVerifyRMF := 0;
End;

{ DrgVerifyNativeRMF(pditem, pszRMF) : la paire native est-elle dans la
  chaine RMF de l'application ? }
Function DrgVerifyNativeRMF(PItem, P : LongInt) : LongInt;
Var M, F : String; I : LongInt; R : Boolean;
Begin
  R := False;
  If (PItem <> 0) And (P <> 0) Then
  Begin
    ParseRMF(ItemRMF(PItem));
    If RmfN > 0 Then
    Begin
      M := RmfM[0]; F := RmfF[0];
      ParseRMF(GetZ(P));
      For I := 0 To RmfN - 1 Do
        If (RmfM[I] = M) And (RmfF[I] = F) Then R := True;
    End;
  End;
  If R Then DrgVerifyNativeRMF := 1 Else DrgVerifyNativeRMF := 0;
End;

{ Le type T est-il dans la liste L ? }
Function InList(T, L : String) : Boolean;
Var I : LongInt; R : Boolean;
Begin
  R := False;
  For I := 0 To ListCount(L) - 1 Do
    If ListItem(L, I) = T Then R := True;
  InList := R;
End;

{ DrgVerifyTrueType(pditem, pszType) : le type vrai est-il dans la liste ? }
Function DrgVerifyTrueType(PItem, P : LongInt) : LongInt;
Var T : String;
Begin
  T := '';
  If PItem <> 0 Then T := ListItem(ItemTypes(PItem), 0);
  If (T <> '') And InList(T, GetZ(P)) Then DrgVerifyTrueType := 1 Else DrgVerifyTrueType := 0;
End;

{ DrgVerifyType(pditem, pszType) : un type de la liste est-il offert ? }
Function DrgVerifyType(PItem, P : LongInt) : LongInt;
Var L, A : String; I : LongInt; R : Boolean;
Begin
  R := False;
  If PItem <> 0 Then
  Begin
    L := ItemTypes(PItem);
    A := GetZ(P);
    For I := 0 To ListCount(A) - 1 Do
      If InList(ListItem(A, I), L) Then R := True;
  End;
  If R Then DrgVerifyType := 1 Else DrgVerifyType := 0;
End;

{ DrgVerifyTypeSet(pditem, pszType, cbMatch, pszMatch) : intersection
  des types (separes par des virgules) ; BOOL }
Function DrgVerifyTypeSet(PItem, P, Cb, PMatch : LongInt) : LongInt;
Var L, A, R, T : String; I : LongInt;
Begin
  R := '';
  If PItem <> 0 Then
  Begin
    L := ItemTypes(PItem);
    A := GetZ(P);
    For I := 0 To ListCount(L) - 1 Do
    Begin
      T := ListItem(L, I);
      If InList(T, A) Then
      Begin
        If R <> '' Then R := R + ',';
        R := R + T;
      End;
    End;
  End;
  If PMatch <> 0 Then Dummy := PutZN(PMatch, Cb, R);
  If R <> '' Then DrgVerifyTypeSet := 1 Else DrgVerifyTypeSet := 0;
End;

{ DrgQueryFormat(pditem, pszMech, cb, pszFormat) : premier format du
  mecanisme (0 : mecanisme natif) ; rend sa longueur (0 : aucun) }
Function DrgQueryFormat(PItem, PM, Cb, P : LongInt) : LongInt;
Var M, F : String; I : LongInt;
Begin
  F := '';
  If PItem <> 0 Then
  Begin
    ParseRMF(ItemRMF(PItem));
    If RmfN > 0 Then
    Begin
      If PM = 0 Then M := RmfM[0] Else M := TrimS(GetZ(PM));
      For I := RmfN - 1 DownTo 0 Do
        If RmfM[I] = M Then F := RmfF[I];
    End;
  End;
  If F = '' Then DrgQueryFormat := 0 Else
  Begin
    Dummy := PutZN(P, Cb, F);
    DrgQueryFormat := Length(F);
  End;
End;

{ ==================================================================== }
{ Partie 8 - Glissement                                                }
{ ==================================================================== }

{ DM_DRAGOVER a la fenetre Hwnd au point (X, Y) ; rend la reponse }
Function DragOver(Hwnd, X, Y : LongInt) : LongInt;
Begin
  WrW(DragInfo + 12, X);
  WrW(DragInfo + 14, Y);
  If Hwnd <> LastTarget Then
  Begin
    If LastTarget <> 0 Then Dummy := SendMsg(LastTarget, DM_DRAGLEAVE, DragInfo, 0);
    LastTarget := Hwnd;
  End;
  If Hwnd = 0 Then LastReply := DOR_NODROP
  Else LastReply := SendMsg(Hwnd, DM_DRAGOVER, DragInfo, (X And $FFFF) Or ((Y And $FFFF) Shl 16));
  DragOver := LastReply;
End;

{ Deposer sur la derniere cible si elle accepte ; rend la cible ou 0 }
Function DropNow : LongInt;
Var T : LongInt;
Begin
  T := LastTarget;
  If (T <> 0) And ((LastReply And $FFFF) = DOR_DROP) Then
  Begin
    If ((LastReply Shr 16) And $FFFF) <> 0 Then WrW(DragInfo + 6, (LastReply Shr 16) And $FFFF);
    Dummy := SendMsg(T, DM_DROP, DragInfo, 0);
  End
  Else
  Begin
    If T <> 0 Then Dummy := SendMsg(T, DM_DRAGLEAVE, DragInfo, 0);
    T := 0;
  End;
  DropNow := T;
End;

Procedure StartDrag(Kind, Src, P, PImg, NImg : LongInt);
Begin
  DragStat := Kind;
  DragInfo := P;
  WrL(P + 8, Src);
  DragImgs := 0;
  If (PImg <> 0) And (NImg > 0) Then DragImgs := NImg;
  DragPtr := 0;
  LastTarget := 0;
  LastReply := DOR_NODROP;
End;

{ Masque des bits d'evenement du bouton de fin }
Function TermMask(Vk : LongInt) : LongInt;
Begin
  If Vk = VK_BUTTON1 Then TermMask := $06
  Else If Vk = VK_BUTTON3 Then TermMask := $60
  Else TermMask := $18;
End;

{ DrgDrag(hwndSource, pdinfo, pdimg, cdimg, vkTerminate, pRsvd) : glisser
  avec la souris ; rend la fenetre cible (0 : rien de depose) }
Function DrgDrag(Src, P, PImg, NImg, Vk, Rsvd : LongInt) : LongInt;
Var Hm, M, Down, Done, Cancel, Wait, X, Y, T, N : LongInt;
    Ev : Array[0..11] Of Byte; PosB : Array[0..3] Of Byte; Ki : Array[0..15] Of Byte;
Begin
  DrgDrag := 0;
  If (DiIdx(P) < 0) Or (DragStat <> 0) Then Exit;
  StartDrag(DGS_DRAGINPROGRESS, Src, P, PImg, NImg);
  Hm := 0;
  If MouOpen(0, LongInt(@Hm)) <> 0 Then
  Begin
    DragStat := 0;
    Exit;
  End;
  Dummy := MouDrawPtr(Hm);
  M := TermMask(Vk);
  Dummy := MouGetPtrPos(LongInt(@PosB), Hm);
  X := RdW(LongInt(@PosB) + 2) * 8 + 4;
  Y := (24 - RdW(LongInt(@PosB))) * 16 + 8;
  Dummy := DragOver(WinAt(X, Y), X, Y);
  Down := 0; Done := 0; Cancel := 0;
  N := 0;
  While (Done = 0) And (N < 60000) Do
  Begin
    Wait := 0;
    WrW(LongInt(@Ev), 0);
    WrL(LongInt(@Ev) + 2, 0);
    Dummy := MouReadEventQue(LongInt(@Ev), LongInt(@Wait), Hm);
    If (RdW(LongInt(@Ev)) <> 0) Or (RdL(LongInt(@Ev) + 2) <> 0) Then
    Begin
      X := RdW(LongInt(@Ev) + 8) * 8 + 4;
      Y := (24 - RdW(LongInt(@Ev) + 6)) * 16 + 8;
      If (RdW(LongInt(@Ev)) And M) <> 0 Then Down := 1
      Else If Down = 1 Then Done := 1;
      T := WinAt(X, Y);
      If Done = 0 Then Dummy := DragOver(T, X, Y)
      Else If T <> LastTarget Then Dummy := DragOver(T, X, Y)
      Else
      Begin
        WrW(P + 12, X);
        WrW(P + 14, Y);
      End;
    End
    Else
    Begin
      { Echap : annuler }
      WrB(LongInt(@Ki) + 2, 0);
      If (KbdCharIn(LongInt(@Ki), 1, 0) = 0) And ((RdB(LongInt(@Ki) + 2) And $40) <> 0) And (RdB(LongInt(@Ki)) = 27) Then
      Begin
        Done := 1;
        Cancel := 1;
      End
      Else
      Begin
        Dummy := DcSleep(10);
        Inc(N);
      End;
    End;
  End;
  Dummy := MouClose(Hm);
  If Cancel = 1 Then
  Begin
    If LastTarget <> 0 Then Dummy := SendMsg(LastTarget, DM_DRAGLEAVE, P, 0);
    T := 0;
  End
  Else T := DropNow;
  DragStat := 0;
  DrgDrag := T;
End;

{ DrgLazyDrag(hwndSource, pdinfo, pdimg, cdimg, pRsvd) : glissement
  differe (DrgLazyDrop ou DrgCancelLazyDrag) ; BOOL }
Function DrgLazyDrag(Src, P, PImg, NImg, Rsvd : LongInt) : LongInt;
Begin
  If (DiIdx(P) < 0) Or (DragStat <> 0) Then DrgLazyDrag := 0
  Else
  Begin
    StartDrag(DGS_LAZYDRAGINPROGRESS, Src, P, PImg, NImg);
    DrgLazyDrag := 1;
  End;
End;

Function DrgCancelLazyDrag : LongInt;
Begin
  If DragStat <> DGS_LAZYDRAGINPROGRESS Then DrgCancelLazyDrag := 0
  Else
  Begin
    If LastTarget <> 0 Then Dummy := SendMsg(LastTarget, DM_DRAGLEAVE, DragInfo, 0);
    DragStat := 0;
    DragFiles := 0;
    DrgCancelLazyDrag := 1;
  End;
End;

{ DrgLazyDrop(hwndTarget, ulOperation, pptlDrop) : deposer sur la
  fenetre ; BOOL (FALSE : elle refuse, le glissement continue) }
Function DrgLazyDrop(Hwnd, Op, PPtl : LongInt) : LongInt;
Var X, Y, T : LongInt;
Begin
  DrgLazyDrop := 0;
  If (DragStat <> DGS_LAZYDRAGINPROGRESS) Or (WinIdx(Hwnd) < 0) Then Exit;
  X := 0; Y := 0;
  If PPtl <> 0 Then
  Begin
    X := RdL(PPtl); Y := RdL(PPtl + 4);
  End;
  If Op <> 0 Then WrW(DragInfo + 6, Op);
  If (DragOver(Hwnd, X, Y) And $FFFF) <> DOR_DROP Then Exit;
  T := DropNow;
  DragStat := 0;
  If T <> 0 Then DrgLazyDrop := 1;
End;

Function DrgQueryDragStatus : LongInt;
Begin
  DrgQueryDragStatus := DragStat;
End;

{ DrgSetDragPointer(pdinfo, hptr), DrgSetDragImage(pdinfo, pdimg, cdimg,
  pRsvd) : pendant le glissement de pdinfo ; BOOL }
Function DrgSetDragPointer(P, Hptr : LongInt) : LongInt;
Begin
  If (DragStat = 0) Or (P <> DragInfo) Then DrgSetDragPointer := 0
  Else
  Begin
    DragPtr := Hptr;
    DrgSetDragPointer := 1;
  End;
End;

Function DrgSetDragImage(P, PImg, NImg, Rsvd : LongInt) : LongInt;
Begin
  If (DragStat = 0) Or (P <> DragInfo) Or (PImg = 0) Or (NImg <= 0) Then DrgSetDragImage := 0
  Else
  Begin
    DragImgs := NImg;
    DrgSetDragImage := 1;
  End;
End;

{ ==================================================================== }
{ Partie 9 - Fichiers                                                  }
{ ==================================================================== }

Function WinAccPath(I : LongInt) : String;
Var S : String; K, N : LongInt;
Begin
  S := '';
  N := WAccBuf[I * 256];
  For K := 1 To N Do S := S + Chr(WAccBuf[I * 256 + K]);
  WinAccPath := S;
End;

Function WinAccTypes(I : LongInt) : String;
Var S : String; K, N : LongInt;
Begin
  S := '';
  N := WAccBuf[I * 256 + 128];
  For K := 1 To N Do S := S + Chr(WAccBuf[I * 256 + 128 + K]);
  WinAccTypes := S;
End;

{ Un element est-il un fichier accepte par la fenetre I ? }
Function FileOk(I, PItem : LongInt) : Boolean;
Var T : String; K : LongInt; R : Boolean;
Begin
  R := HasRMF(PItem, 'DRM_OS2FILE', '');
  T := WinAccTypes(I);
  If R And (T <> '') Then
  Begin
    R := False;
    For K := 0 To ListCount(T) - 1 Do
      If InList(ListItem(T, K), ItemTypes(PItem)) Then R := True;
  End;
  FileOk := R;
End;

{ Procedure des fenetres de DrgAcceptDroppedFiles }
Function AcceptProc(I, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var P, K, Op, It, Ok, Fl, Done, Rf, Src : LongInt; Ok2 : Boolean; Dir, Fn, Tn : String;
Begin
  AcceptProc := 0;
  P := Mp1;
  If (Msg <> DM_DRAGOVER) And (Msg <> DM_DROP) Then Exit;
  If DiIdx(P) < 0 Then Exit;
  Op := RdW(P + 6);
  If (Op = DO_DEFAULT) Or (Op = DO_UNKNOWN) Then Op := WAccOp[I];
  If Msg = DM_DRAGOVER Then
  Begin
    Ok2 := ItemCount(P) > 0;
    For K := 0 To ItemCount(P) - 1 Do
      If Not FileOk(I, ItemPtr(P, K)) Then Ok2 := False;
    If Not Ok2 Then AcceptProc := DOR_NEVERDROP
    Else If (Op <> DO_COPY) And (Op <> DO_MOVE) Then AcceptProc := DOR_NODROPOP
    Else AcceptProc := DOR_DROP Or (Op Shl 16);
    Exit;
  End;
  { DM_DROP : copier ou deplacer chaque fichier }
  Done := 0;
  Src := RdL(P + 8);
  For K := 0 To ItemCount(P) - 1 Do
  Begin
    It := ItemPtr(P, K);
    Dir := HStr(RdL(It + 16));
    Fn := HStr(RdL(It + 20));
    Tn := HStr(RdL(It + 24));
    If Tn = '' Then Tn := Fn;
    If (Length(Dir) > 0) And (Ord(Dir[Length(Dir)]) <> 92) Then Dir := Dir + '\';
    Ok := 0;
    Rf := 0;
    If DragFileRender <> 0 Then
    Begin
      { la source fait le transfert (DM_RENDERFILE) }
      Rf := MemAlloc(16);
      If Rf <> 0 Then
      Begin
        WrL(Rf, WHwnd[I]);
        WrL(Rf + 4, AddStr(Dir + Fn));
        WrL(Rf + 8, AddStr(WinAccPath(I) + Tn));
        If Op = DO_MOVE Then WrW(Rf + 12, 1) Else WrW(Rf + 12, 0);
        If SendMsg(Src, DM_RENDERFILE, Rf, 0) <> 0 Then Ok := 1;
        Dummy := DrgDeleteStrHandle(RdL(Rf + 4));
        Dummy := DrgDeleteStrHandle(RdL(Rf + 8));
        MemFree(Rf);
      End;
    End;
    If Ok = 0 Then
    Begin
      PutZ(LongInt(@NameZ), Dir + Fn);
      PutZ(LongInt(@Name2), WinAccPath(I) + Tn);
      If Op = DO_MOVE Then
      Begin
        { DosMove ne change pas d'unite : copier puis supprimer }
        Ok := DcMove(LongInt(@NameZ), LongInt(@Name2));
        If Ok <> 0 Then
        Begin
          Ok := DcCopy(LongInt(@NameZ), LongInt(@Name2), 1);
          If Ok = 0 Then Ok := DcDelete(LongInt(@NameZ));
        End;
      End
      Else Ok := DcCopy(LongInt(@NameZ), LongInt(@Name2), 1);
      If Ok = 0 Then Ok := 1 Else Ok := 0;
    End;
    If Ok = 1 Then
    Begin
      Fl := DMFL_TARGETSUCCESSFUL;
      Inc(Done);
    End
    Else Fl := DMFL_TARGETFAIL;
    Dummy := SendMsg(RdL(It), DM_ENDCONVERSATION, RdL(It + 4), Fl);
  End;
  If DragFiles <> 0 Then
  Begin
    Fl := DF_SOURCE;
    If Op = DO_MOVE Then Fl := Fl Or DF_MOVE;
    If Done = ItemCount(P) Then Fl := Fl Or DF_SUCCESSFUL;
    Dummy := SendMsg(Src, DM_DRAGFILECOMPLETE, WHwnd[I], Fl);
  End;
  { la cible libere le DRAGINFO (et ses chaines) }
  Dummy := DrgDeleteDraginfoStrHandles(P);
  Dummy := DrgFreeDraginfo(P);
  AcceptProc := 1;
End;

{ DrgAcceptDroppedFiles(hwnd, pszPath, pszTypes, ulDefaultOp, ulRsvd) :
  la fenetre accepte les fichiers deposes (pszPath nul : plus de
  fichiers) ; BOOL }
Function DrgAcceptDroppedFiles(Hwnd, PPath, PTypes, DefOp, Rsvd : LongInt) : LongInt;
Var I, K : LongInt; S : String;
Begin
  DrgAcceptDroppedFiles := 0;
  If Hwnd = 0 Then Exit;
  I := WinIdx(Hwnd);
  If PPath = 0 Then
  Begin
    If I >= 0 Then WAccept[I] := 0;
    DrgAcceptDroppedFiles := 1;
    Exit;
  End;
  If I < 0 Then
  Begin
    { fenetre inconnue : inscrite sans rectangle (DrgLazyDrop) }
    I := WinSet(Hwnd, 0, 0, 0, 0, 0, 0);
    If I < 0 Then Exit;
  End;
  S := GetZ(PPath);
  If (Length(S) > 0) And (Ord(S[Length(S)]) <> 92) Then S := S + '\';
  S := Copy(S, 1, 127);
  WAccBuf[I * 256] := Length(S);
  For K := 1 To Length(S) Do WAccBuf[I * 256 + K] := Ord(S[K]);
  S := Copy(GetZ(PTypes), 1, 127);
  WAccBuf[I * 256 + 128] := Length(S);
  For K := 1 To Length(S) Do WAccBuf[I * 256 + 128 + K] := Ord(S[K]);
  If (DefOp <> DO_COPY) And (DefOp <> DO_MOVE) Then DefOp := DO_COPY;
  WAccOp[I] := DefOp;
  WAccept[I] := 1;
  DrgAcceptDroppedFiles := 1;
End;

{ DrgDragFiles(hwnd, apszFiles, apszTypes, apszTargets, cFiles, hptrDrag,
  vkTerm, fSourceRender, ulRsvd) : glisser des fichiers ; BOOL (TRUE :
  deposes) }
Function DrgDragFiles(Hwnd, PFiles, PTypes, PTargets, N, Hptr, Vk, SrcRender, Rsvd : LongInt) : LongInt;
Var P, K, It, J, T : LongInt; F, D, Ty : String;
Begin
  DrgDragFiles := 0;
  If (PFiles = 0) Or (N <= 0) Or (DragStat <> 0) Then Exit;
  P := DrgAllocDraginfo(N);
  If P = 0 Then Exit;
  WrL(P + 8, Hwnd);
  For K := 0 To N - 1 Do
  Begin
    It := ItemPtr(P, K);
    F := GetZ(RdL(PFiles + K * 4));
    J := 0;
    For T := 1 To Length(F) Do
      If (Ord(F[T]) = 92) Or (Ord(F[T]) = 58) Then J := T;
    D := Copy(F, 1, J);
    F := Copy(F, J + 1, 255);
    Ty := '';
    If PTypes <> 0 Then Ty := GetZ(RdL(PTypes + K * 4));
    If Ty = '' Then Ty := 'Unknown';
    WrL(It, Hwnd);
    WrL(It + 4, K);
    WrL(It + 8, AddStr(Ty));
    WrL(It + 12, AddStr('<DRM_OS2FILE,DRF_UNKNOWN>'));
    WrL(It + 16, AddStr(D));
    WrL(It + 20, AddStr(F));
    If PTargets <> 0 Then
      If RdL(PTargets + K * 4) <> 0 Then WrL(It + 24, AddStr(GetZ(RdL(PTargets + K * 4))));
    WrW(It + 34, DO_COPYABLE Or DO_MOVEABLE);
  End;
  DragFiles := 1;
  DragFileRender := SrcRender;
  T := DrgDrag(Hwnd, P, 0, 0, Vk, 0);
  DragFiles := 0;
  DragFileRender := 0;
  { sans cible, la source libere le DRAGINFO (sinon la cible l'a fait) }
  If T = 0 Then
  Begin
    Dummy := DrgDeleteDraginfoStrHandles(P);
    Dummy := DrgFreeDraginfo(P);
  End
  Else DrgDragFiles := 1;
End;

{ ==================================================================== }
{ Partie 10 - Points d'entree 16 bits                                  }
{ ==================================================================== }

Function Drg16AccessDraginfo(P : LongInt) : LongInt;
Begin
  Drg16AccessDraginfo := DrgAccessDraginfo(P);
End;

Function Drg16AddStrHandle(P : LongInt) : LongInt;
Begin
  Drg16AddStrHandle := DrgAddStrHandle(P);
End;

Function Drg16AllocDraginfo(N : LongInt) : LongInt;
Begin
  Drg16AllocDraginfo := DrgAllocDraginfo(N);
End;

Function Drg16AllocDragtransfer(N : LongInt) : LongInt;
Begin
  Drg16AllocDragtransfer := DrgAllocDragtransfer(N);
End;

Function Drg16DeleteDraginfoStrHandles(P : LongInt) : LongInt;
Begin
  Drg16DeleteDraginfoStrHandles := DrgDeleteDraginfoStrHandles(P);
End;

Function Drg16DeleteStrHandle(H : LongInt) : LongInt;
Begin
  Drg16DeleteStrHandle := DrgDeleteStrHandle(H);
End;

Function Drg16Drag(Src, P, PImg, NImg, Vk, Rsvd : LongInt) : LongInt;
Begin
  Drg16Drag := DrgDrag(Src, P, PImg, NImg, Vk, Rsvd);
End;

Function Drg16FreeDraginfo(P : LongInt) : LongInt;
Begin
  Drg16FreeDraginfo := DrgFreeDraginfo(P);
End;

Function Drg16FreeDragtransfer(P : LongInt) : LongInt;
Begin
  Drg16FreeDragtransfer := DrgFreeDragtransfer(P);
End;

Function Drg16GetPS(Hwnd : LongInt) : LongInt;
Begin
  Drg16GetPS := DrgGetPS(Hwnd);
End;

Function Drg16PostTransferMsg(Hwnd, Msg, PX, Fl, Rsvd, Retry : LongInt) : LongInt;
Begin
  Drg16PostTransferMsg := DrgPostTransferMsg(Hwnd, Msg, PX, Fl, Rsvd, Retry);
End;

Function Drg16PushDraginfo(P, Hwnd : LongInt) : LongInt;
Begin
  Drg16PushDraginfo := DrgPushDraginfo(P, Hwnd);
End;

Function Drg16QueryDragitem(P, Cb, PItem, I : LongInt) : LongInt;
Begin
  Drg16QueryDragitem := DrgQueryDragitem(P, Cb, PItem, I);
End;

Function Drg16QueryDragitemCount(P : LongInt) : LongInt;
Begin
  Drg16QueryDragitemCount := DrgQueryDragitemCount(P);
End;

Function Drg16QueryDragitemPtr(P, I : LongInt) : LongInt;
Begin
  Drg16QueryDragitemPtr := DrgQueryDragitemPtr(P, I);
End;

Function Drg16QueryNativeRMF(PItem, Cb, P : LongInt) : LongInt;
Begin
  Drg16QueryNativeRMF := DrgQueryNativeRMF(PItem, Cb, P);
End;

Function Drg16QueryNativeRMFLen(PItem : LongInt) : LongInt;
Begin
  Drg16QueryNativeRMFLen := DrgQueryNativeRMFLen(PItem);
End;

Function Drg16QueryStrName(H, Cb, P : LongInt) : LongInt;
Begin
  Drg16QueryStrName := DrgQueryStrName(H, Cb, P);
End;

Function Drg16QueryStrNameLen(H : LongInt) : LongInt;
Begin
  Drg16QueryStrNameLen := DrgQueryStrNameLen(H);
End;

Function Drg16QueryTrueType(PItem, Cb, P : LongInt) : LongInt;
Begin
  Drg16QueryTrueType := DrgQueryTrueType(PItem, Cb, P);
End;

Function Drg16QueryTrueTypeLen(PItem : LongInt) : LongInt;
Begin
  Drg16QueryTrueTypeLen := DrgQueryTrueTypeLen(PItem);
End;

Function Drg16ReleasePS(Hps : LongInt) : LongInt;
Begin
  Drg16ReleasePS := DrgReleasePS(Hps);
End;

Function Drg16SendTransferMsg(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Begin
  Drg16SendTransferMsg := DrgSendTransferMsg(Hwnd, Msg, Mp1, Mp2);
End;

Function Drg16SetDragPointer(P, Hptr : LongInt) : LongInt;
Begin
  Drg16SetDragPointer := DrgSetDragPointer(P, Hptr);
End;

Function Drg16SetDragImage(P, PImg, NImg, Rsvd : LongInt) : LongInt;
Begin
  Drg16SetDragImage := DrgSetDragImage(P, PImg, NImg, Rsvd);
End;

Function Drg16SetDragitem(P, PItem, Cb, I : LongInt) : LongInt;
Begin
  Drg16SetDragitem := DrgSetDragitem(P, PItem, Cb, I);
End;

Function Drg16VerifyNativeRMF(PItem, P : LongInt) : LongInt;
Begin
  Drg16VerifyNativeRMF := DrgVerifyNativeRMF(PItem, P);
End;

Function Drg16VerifyRMF(PItem, PM, PF : LongInt) : LongInt;
Begin
  Drg16VerifyRMF := DrgVerifyRMF(PItem, PM, PF);
End;

Function Drg16VerifyTrueType(PItem, P : LongInt) : LongInt;
Begin
  Drg16VerifyTrueType := DrgVerifyTrueType(PItem, P);
End;

Function Drg16VerifyType(PItem, P : LongInt) : LongInt;
Begin
  Drg16VerifyType := DrgVerifyType(PItem, P);
End;

Function Drg16VerifyTypeSet(PItem, P, Cb, PMatch : LongInt) : LongInt;
Begin
  Drg16VerifyTypeSet := DrgVerifyTypeSet(PItem, P, Cb, PMatch);
End;

Function Drg16DragFiles(Hwnd, PFiles, PTypes, PTargets, N, Hptr, Vk, SrcRender, Rsvd : LongInt) : LongInt;
Begin
  Drg16DragFiles := DrgDragFiles(Hwnd, PFiles, PTypes, PTargets, N, Hptr, Vk, SrcRender, Rsvd);
End;

Function Drg16AcceptDroppedFiles(Hwnd, PPath, PTypes, DefOp, Rsvd : LongInt) : LongInt;
Begin
  Drg16AcceptDroppedFiles := DrgAcceptDroppedFiles(Hwnd, PPath, PTypes, DefOp, Rsvd);
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  Drg16AccessDraginfo Index 1 Name 'DRGACCESSDRAGINFO',
  Drg16AddStrHandle Index 2 Name 'DRGADDSTRHANDLE',
  Drg16AllocDraginfo Index 3 Name 'DRGALLOCDRAGINFO',
  Drg16AllocDragtransfer Index 4 Name 'DRGALLOCDRAGTRANSFER',
  Drg16DeleteDraginfoStrHandles Index 5 Name 'DRGDELETEDRAGINFOSTRHANDLES',
  Drg16DeleteStrHandle Index 6 Name 'DRGDELETESTRHANDLE',
  Drg16Drag Index 7 Name 'DRGDRAG',
  Drg16FreeDraginfo Index 8 Name 'DRGFREEDRAGINFO',
  Drg16FreeDragtransfer Index 9 Name 'DRGFREEDRAGTRANSFER',
  Drg16GetPS Index 10 Name 'DRGGETPS',
  Drg16PostTransferMsg Index 11 Name 'DRGPOSTTRANSFERMSG',
  Drg16PushDraginfo Index 12 Name 'DRGPUSHDRAGINFO',
  Drg16QueryDragitem Index 13 Name 'DRGQUERYDRAGITEM',
  Drg16QueryDragitemCount Index 14 Name 'DRGQUERYDRAGITEMCOUNT',
  Drg16QueryDragitemPtr Index 15 Name 'DRGQUERYDRAGITEMPTR',
  Drg16QueryNativeRMF Index 16 Name 'DRGQUERYNATIVERMF',
  Drg16QueryNativeRMFLen Index 17 Name 'DRGQUERYNATIVERMFLEN',
  Drg16QueryStrName Index 18 Name 'DRGQUERYSTRNAME',
  Drg16QueryStrNameLen Index 19 Name 'DRGQUERYSTRNAMELEN',
  Drg16QueryTrueType Index 20 Name 'DRGQUERYTRUETYPE',
  Drg16QueryTrueTypeLen Index 21 Name 'DRGQUERYTRUETYPELEN',
  Drg16ReleasePS Index 22 Name 'DRGRELEASEPS',
  Drg16SendTransferMsg Index 23 Name 'DRGSENDTRANSFERMSG',
  Drg16SetDragPointer Index 24 Name 'DRGSETDRAGPOINTER',
  Drg16SetDragImage Index 25 Name 'DRGSETDRAGIMAGE',
  Drg16SetDragitem Index 26 Name 'DRGSETDRAGITEM',
  Drg16VerifyNativeRMF Index 27 Name 'DRGVERIFYNATIVERMF',
  Drg16VerifyRMF Index 28 Name 'DRGVERIFYRMF',
  Drg16VerifyTrueType Index 29 Name 'DRGVERIFYTRUETYPE',
  Drg16VerifyType Index 30 Name 'DRGVERIFYTYPE',
  Drg16VerifyTypeSet Index 31 Name 'DRGVERIFYTYPESET',
  DrgAccessDraginfo Index 32 Name 'DrgAccessDraginfo',
  DrgAddStrHandle Index 33 Name 'DrgAddStrHandle',
  DrgAllocDraginfo Index 34 Name 'DrgAllocDraginfo',
  DrgAllocDragtransfer Index 35 Name 'DrgAllocDragtransfer',
  DrgDeleteDraginfoStrHandles Index 36 Name 'DrgDeleteDraginfoStrHandles',
  DrgDeleteStrHandle Index 37 Name 'DrgDeleteStrHandle',
  DrgDrag Index 38 Name 'DrgDrag',
  DrgFreeDraginfo Index 39 Name 'DrgFreeDraginfo',
  DrgFreeDragtransfer Index 40 Name 'DrgFreeDragtransfer',
  DrgGetPS Index 41 Name 'DrgGetPS',
  DrgPostTransferMsg Index 42 Name 'DrgPostTransferMsg',
  DrgPushDraginfo Index 43 Name 'DrgPushDraginfo',
  DrgQueryDragitem Index 44 Name 'DrgQueryDragitem',
  DrgQueryDragitemCount Index 45 Name 'DrgQueryDragitemCount',
  DrgQueryDragitemPtr Index 46 Name 'DrgQueryDragitemPtr',
  DrgQueryNativeRMF Index 47 Name 'DrgQueryNativeRMF',
  DrgQueryNativeRMFLen Index 48 Name 'DrgQueryNativeRMFLen',
  DrgQueryStrName Index 49 Name 'DrgQueryStrName',
  DrgQueryStrNameLen Index 50 Name 'DrgQueryStrNameLen',
  DrgQueryTrueType Index 51 Name 'DrgQueryTrueType',
  DrgQueryTrueTypeLen Index 52 Name 'DrgQueryTrueTypeLen',
  DrgReleasePS Index 53 Name 'DrgReleasePS',
  DrgSendTransferMsg Index 54 Name 'DrgSendTransferMsg',
  DrgSetDragPointer Index 55 Name 'DrgSetDragPointer',
  DrgSetDragImage Index 56 Name 'DrgSetDragImage',
  DrgSetDragitem Index 57 Name 'DrgSetDragitem',
  DrgVerifyNativeRMF Index 58 Name 'DrgVerifyNativeRMF',
  DrgVerifyRMF Index 59 Name 'DrgVerifyRMF',
  DrgVerifyTrueType Index 60 Name 'DrgVerifyTrueType',
  DrgVerifyType Index 61 Name 'DrgVerifyType',
  DrgVerifyTypeSet Index 62 Name 'DrgVerifyTypeSet',
  Drg16DragFiles Index 63 Name 'DRGDRAGFILES',
  Drg16AcceptDroppedFiles Index 64 Name 'DRGACCEPTDROPPEDFILES',
  DrgDragFiles Index 65 Name 'DrgDragFiles',
  DrgAcceptDroppedFiles Index 66 Name 'DrgAcceptDroppedFiles',
  DrgLazyDrag Index 67 Name 'DrgLazyDrag',
  DrgCancelLazyDrag Index 68 Name 'DrgCancelLazyDrag',
  DrgLazyDrop Index 69 Name 'DrgLazyDrop',
  DrgQueryDraginfoPtr Index 70 Name 'DrgQueryDraginfoPtr',
  DrgQueryDraginfoPtrFromHwnd Index 71 Name 'DrgQueryDraginfoPtrFromHwnd',
  DrgQueryDraginfoPtrFromDragitem Index 72 Name 'DrgQueryDraginfoPtrFromDragitem',
  DrgQueryDragStatus Index 73 Name 'DrgQueryDragStatus',
  DrgReallocDraginfo Index 74 Name 'DrgReallocDraginfo',
  DrgQueryFormat Index 75 Name 'DrgQueryFormat',
  DrgGetClipPS Index 76 Name 'DrgGetClipPS',
  DrgRegisterWindow Index 200 Name 'DRGREGISTERWINDOW',
  DrgQueryDropTarget Index 201 Name 'DRGQUERYDROPTARGET';

Var
  InitI : LongInt;

BEGIN
  { un seul bloc libre }
  For InitI := 0 To 7 Do Arena[InitI] := 0;
  WrL(LongInt(@Arena), ArenaSize);
  For InitI := 0 To MaxStr - 1 Do StrRef[InitI] := 0;
  For InitI := 0 To MaxDi - 1 Do
  Begin
    DiAddr[InitI] := 0; DiRefs[InitI] := 0; DiOwner[InitI] := 0;
  End;
  For InitI := 0 To MaxDx - 1 Do DxAddr[InitI] := 0;
  For InitI := 0 To MaxWin - 1 Do
  Begin
    WHwnd[InitI] := 0; WAccept[InitI] := 0;
  End;
  For InitI := 0 To MaxPS - 1 Do PSHwnd[InitI] := 0;
  PCount := 0; SendDepth := 0;
  DragStat := 0; DragInfo := 0; DragFiles := 0; DragFileRender := 0;
  LastTarget := 0; LastReply := 0;
END.
