{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de PMDRAG.DLL sous OS/2-0.
}

Program TESTDRG;

{$R-,S-,I-}

{ Compilation : OS2PC TESTDRG.PAS   (produit TESTDRG.EXE)

  TESTDRG verifie les 76 points d'entree de PMDRAG.DLL. Trois fenetres
  sont inscrites (DRGREGISTERWINDOW, procedures OS2PC) : A ($A001,
  moitie gauche de
  l'ecran), B ($B002, moitie droite) et C ($C003, qui accepte les
  fichiers). La fin de l'essai glisse a la souris (DrgDrag) ; avec QEMU :
    DRAG1 : mouse_button 1 ; mouse_move 100 0 (trois fois) ; mouse_button 0
            (de A vers B : depose sur B)
    DRAG2 : mouse_button 1 ; touche Echap (annule) ; mouse_button 0
    DRAG3 : mouse_button 1 ; mouse_button 0 (fichier depose sur C) }

Function DrgAccessDraginfo(P : LongInt) : LongInt; External 'PMDRAG';
Function DrgAddStrHandle(P : LongInt) : LongInt; External 'PMDRAG';
Function DrgAllocDraginfo(N : LongInt) : LongInt; External 'PMDRAG';
Function DrgAllocDragtransfer(N : LongInt) : LongInt; External 'PMDRAG';
Function DrgDeleteDraginfoStrHandles(P : LongInt) : LongInt; External 'PMDRAG';
Function DrgDeleteStrHandle(H : LongInt) : LongInt; External 'PMDRAG';
Function DrgDrag(Src, P, PImg, NImg, Vk, Rsvd : LongInt) : LongInt; External 'PMDRAG';
Function DrgFreeDraginfo(P : LongInt) : LongInt; External 'PMDRAG';
Function DrgFreeDragtransfer(P : LongInt) : LongInt; External 'PMDRAG';
Function DrgGetPS(Hwnd : LongInt) : LongInt; External 'PMDRAG';
Function DrgPostTransferMsg(Hwnd, Msg, PX, Fl, Rsvd, Retry : LongInt) : LongInt; External 'PMDRAG';
Function DrgPushDraginfo(P, Hwnd : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryDragitem(P, Cb, PItem, I : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryDragitemCount(P : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryDragitemPtr(P, I : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryNativeRMF(PItem, Cb, P : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryNativeRMFLen(PItem : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryStrName(H, Cb, P : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryStrNameLen(H : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryTrueType(PItem, Cb, P : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryTrueTypeLen(PItem : LongInt) : LongInt; External 'PMDRAG';
Function DrgReleasePS(Hps : LongInt) : LongInt; External 'PMDRAG';
Function DrgSendTransferMsg(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMDRAG';
Function DrgSetDragPointer(P, Hptr : LongInt) : LongInt; External 'PMDRAG';
Function DrgSetDragImage(P, PImg, NImg, Rsvd : LongInt) : LongInt; External 'PMDRAG';
Function DrgSetDragitem(P, PItem, Cb, I : LongInt) : LongInt; External 'PMDRAG';
Function DrgVerifyNativeRMF(PItem, P : LongInt) : LongInt; External 'PMDRAG';
Function DrgVerifyRMF(PItem, PM, PF : LongInt) : LongInt; External 'PMDRAG';
Function DrgVerifyTrueType(PItem, P : LongInt) : LongInt; External 'PMDRAG';
Function DrgVerifyType(PItem, P : LongInt) : LongInt; External 'PMDRAG';
Function DrgVerifyTypeSet(PItem, P, Cb, PMatch : LongInt) : LongInt; External 'PMDRAG';
Function DrgDragFiles(Hwnd, PFiles, PTypes, PTargets, N, Hptr, Vk, SrcRender, Rsvd : LongInt) : LongInt; External 'PMDRAG';
Function DrgAcceptDroppedFiles(Hwnd, PPath, PTypes, DefOp, Rsvd : LongInt) : LongInt; External 'PMDRAG';
Function DrgLazyDrag(Src, P, PImg, NImg, Rsvd : LongInt) : LongInt; External 'PMDRAG';
Function DrgCancelLazyDrag : LongInt; External 'PMDRAG';
Function DrgLazyDrop(Hwnd, Op, PPtl : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryDraginfoPtr(PRsvd : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryDraginfoPtrFromHwnd(Hwnd : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryDraginfoPtrFromDragitem(PItem : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryDragStatus : LongInt; External 'PMDRAG';
Function DrgReallocDraginfo(P, N : LongInt) : LongInt; External 'PMDRAG';
Function DrgQueryFormat(PItem, PM, Cb, P : LongInt) : LongInt; External 'PMDRAG';
Function DrgGetClipPS(Hwnd, HwndClip, Fl : LongInt) : LongInt; External 'PMDRAG';
Function DrgRegisterWindow(Hwnd, Proc, X, Y, Cx, Cy, Fl : LongInt) : LongInt; External 'PMDRAG' Name 'DRGREGISTERWINDOW';
Function DrgQueryDropTarget(X, Y : LongInt) : LongInt; External 'PMDRAG' Name 'DRGQUERYDROPTARGET';

Function MouOpen(PDrv, PHmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouSetPtrPos(PPos, Hmou : LongInt) : LongInt; External 'MOUCALLS';
Function MouFlushQue(Hmou : LongInt) : LongInt; External 'MOUCALLS';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosOpen(PName, PHf, PAction, CbFile, Attr, Flags, Mode, PEaop2 : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';

Const
  DM_RENDERFILE       = $0322;
  DM_DRAGFILECOMPLETE = $0326;
  DM_RENDERCOMPLETE   = $0328;
  DM_RENDER           = $0329;
  DM_ENDCONVERSATION  = $032B;
  DM_DRAGLEAVE        = $032D;
  DM_DRAGOVER         = $032E;
  DM_DROP             = $032F;
  DO_DEFAULT = $BFFE;
  DO_COPY    = $0010;
  DO_MOVE    = $0020;
  DOR_NODROP = 0;
  DOR_DROP   = 1;
  DMFL_TARGETSUCCESSFUL = 1;
  DMFL_RENDEROK = $10;
  DF_SOURCE     = 2;
  DF_SUCCESSFUL = 4;
  VK_BUTTON1 = 1;
  HA = $A001;
  HB = $B002;
  HC = $C003;
  HD = $D004;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, C, P, P2, X, Hm : LongInt;
  Name, Name2, Buf : Array[0..255] Of Byte;
  It, It2 : Array[0..35] Of Byte;
  Img : Array[0..23] Of Byte;
  Ptl : Array[0..1] Of LongInt;
  PosRC : Array[0..1] Of Word;
  Files, Types : Array[0..1] Of LongInt;
  FName, FType : Array[0..63] Of Byte;
  Info : Array[0..63] Of Byte;
  { journal des fenetres }
  LogA, LogB, Seq, Txt0 : String;
  AcceptB, DropX, DropY, DropOp, EndA, FileA, Dm : LongInt;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
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
  P^ := V;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
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
  While (RdB(A + K) <> 0) And (K < 250) Do
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
    If OutLen < 16380 Then
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

Function MakeFile(F : String) : LongInt;
Var Hf, Act, W, D : LongInt;
Begin
  D := DosOpen(Z(F), LongInt(@Hf), LongInt(@Act), 0, 0, $12, $41, 0);
  If D = 0 Then
  Begin
    PutZ(LongInt(@Buf), 'Bonjour');
    D := DosWrite(Hf, LongInt(@Buf), 7, LongInt(@W));
    A := DosClose(Hf);
  End;
  MakeFile := D;
End;

Function Exists(F : String) : Boolean;
Begin
  Exists := DosQueryPathInfo(Z(F), 1, LongInt(@Info), 24) = 0;
End;

{ DRAGITEM : fenetre, identificateur, types, RMF, repertoire, nom }
Procedure SetItem(Hw, Id : LongInt; Ty, Rmf, Dir, Fn : String);
Var K : LongInt;
Begin
  For K := 0 To 35 Do It[K] := 0;
  WrL(LongInt(@It), Hw);
  WrL(LongInt(@It) + 4, Id);
  WrL(LongInt(@It) + 8, DrgAddStrHandle(Z(Ty)));
  WrL(LongInt(@It) + 12, DrgAddStrHandle(Z(Rmf)));
  If Dir <> '' Then WrL(LongInt(@It) + 16, DrgAddStrHandle(Z(Dir)));
  If Fn <> '' Then WrL(LongInt(@It) + 20, DrgAddStrHandle(Z(Fn)));
  WrW(LongInt(@It) + 34, 3);
End;

Function CallPtr1(F, A1 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,4
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr1 := R;
End;

{ --- procedures des fenetres --- }
Function WndA(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If Msg = DM_DRAGOVER Then LogA := LogA + 'O'
  Else If Msg = DM_DRAGLEAVE Then LogA := LogA + 'L'
  Else If Msg = DM_DROP Then LogA := LogA + 'D'
  Else If Msg = DM_RENDER Then
  Begin
    LogA := LogA + 'R';
    R := 77;
  End
  Else If Msg = $1234 Then
  Begin
    Seq := Seq + 'A';
    Dm := DrgPostTransferMsg(HB, DM_ENDCONVERSATION, 0, 0, 0, 0);
    Seq := Seq + 'a';
  End
  Else If Msg = DM_ENDCONVERSATION Then
  Begin
    LogA := LogA + 'E';
    EndA := Mp2;
  End
  Else If Msg = DM_DRAGFILECOMPLETE Then
  Begin
    LogA := LogA + 'F';
    FileA := Mp2;
  End;
  WndA := R;
End;

Function WndB(Hwnd, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  If Msg = DM_DRAGOVER Then
  Begin
    LogB := LogB + 'O';
    If AcceptB = 1 Then R := DOR_DROP Or (RdW(Mp1 + 6) Shl 16) Else R := DOR_NODROP;
  End
  Else If Msg = DM_DRAGLEAVE Then LogB := LogB + 'L'
  Else If Msg = DM_DROP Then
  Begin
    LogB := LogB + 'D';
    DropX := RdW(Mp1 + 12);
    DropY := RdW(Mp1 + 14);
    DropOp := RdW(Mp1 + 6);
    { la cible libere le DRAGINFO }
    Dm := DrgFreeDraginfo(Mp1);
  End
  Else If Msg = DM_RENDERCOMPLETE Then LogB := LogB + 'C'
  Else If Msg = DM_ENDCONVERSATION Then Seq := Seq + 'B';
  WndB := R;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  LogA := ''; LogB := ''; Seq := ''; AcceptB := 0;
  WriteLn('TESTDRG : essai de PMDRAG.DLL');

  { --- module, ordinaux --- }
  R := DosQueryModuleHandle(Z('PMDRAG'), LongInt(@H));
  N := 0;
  For I := 1 To 76 Do
    If DosQueryProcAddr(H, I, 0, LongInt(@A)) = 0 Then Inc(N);
  Check('DosQueryModuleHandle PMDRAG, 76 ordinaux', (R = 0) And (N = 76));
  A := 0; B := 0;
  R := DosQueryProcAddr(H, 0, Z('DrgAccessDraginfo'), LongInt(@A));
  R2 := DosQueryProcAddr(H, 0, Z('DrgQueryFormat'), LongInt(@B));
  Check('noms DrgAccessDraginfo, DrgQueryFormat ; ordinaux 77, 200, 201',
        (R = 0) And (A <> 0) And (R2 = 0) And (B <> 0) And (DosQueryProcAddr(H, 77, 0, LongInt(@C)) <> 0) And
        (DosQueryProcAddr(H, 200, 0, LongInt(@C)) = 0) And (DosQueryProcAddr(H, 201, 0, LongInt(@C)) = 0));
  A := 0; B := 0;
  R := DosQueryProcAddr(H, 3, 0, LongInt(@A));
  R2 := DosQueryProcAddr(H, 39, 0, LongInt(@B));
  P := CallPtr1(A, 2);
  C := CallPtr1(B, P);
  Check('ordinal 3 (16 bits) DrgAllocDraginfo, ordinal 39 (32 bits) DrgFreeDraginfo', (P <> 0) And (C = 1));

  { --- chaines --- }
  A := DrgAddStrHandle(Z('DRT_TEXT'));
  B := DrgAddStrHandle(Z('DRT_TEXT'));
  C := DrgAddStrHandle(Z('DRT_BITMAP'));
  Check('DrgAddStrHandle : meme chaine, meme handle', (A >= $C000) And (A <= $C0FF) And (A = B) And (C <> A));
  R := DrgQueryStrName(A, 5, LongInt(@Buf));
  Check('DrgQueryStrName tronque, DrgQueryStrNameLen', (R = 4) And (GetZ(LongInt(@Buf)) = 'DRT_') And
        (DrgQueryStrNameLen(A) = 8) And (DrgQueryStrNameLen($1234) = 0));
  R := DrgDeleteStrHandle(A);
  R2 := DrgDeleteStrHandle(A);
  N := DrgDeleteStrHandle(A);
  Check('DrgDeleteStrHandle (compte de references)', (R = 1) And (R2 = 1) And (N = 0) And (DrgQueryStrNameLen(A) = 0) And
        (DrgAddStrHandle(0) = 0));
  Dm := DrgDeleteStrHandle(C);

  { --- DRAGINFO --- }
  P := DrgAllocDraginfo(2);
  Check('DrgAllocDraginfo(2) : taille, cbDragitem, operation, cditem', (P <> 0) And (RdL(P) = 92) And (RdW(P + 4) = 36) And
        (RdW(P + 6) = DO_DEFAULT) And (RdW(P + 16) = 2) And (DrgQueryDragitemCount(P) = 2));
  Check('DrgQueryDragitemPtr, DrgQueryDraginfoPtrFromDragitem', (DrgQueryDragitemPtr(P, 0) = P + 20) And
        (DrgQueryDragitemPtr(P, 2) = 0) And (DrgQueryDraginfoPtrFromDragitem(P + 56) = P) And
        (DrgQueryDraginfoPtrFromDragitem(P + 21) = 0));
  SetItem($1001, 7, 'Plain Text,Bitmap', '<DRM_OS2FILE,DRF_TEXT>,(DRM_PRINT,DRM_DDE)x(DRF_UNKNOWN,DRF_TEXT)', 'C:\', 'ESSAI.TXT');
  R := DrgSetDragitem(P, LongInt(@It), 36, 0);
  R2 := DrgSetDragitem(P, LongInt(@It), 36, 5);
  For I := 0 To 35 Do It2[I] := 0;
  A := DrgQueryDragitem(P, 36, LongInt(@It2), 0);
  Check('DrgSetDragitem, DrgQueryDragitem ; element inexistant', (R = 1) And (R2 = 0) And (A = 1) And
        (RdL(LongInt(@It2) + 4) = 7) And (RdL(LongInt(@It2)) = $1001));
  C := DrgQueryDragitemPtr(P, 0);

  { --- mecanismes, formats, types --- }
  R := DrgQueryNativeRMF(C, 64, LongInt(@Buf));
  Check('DrgQueryNativeRMF, DrgQueryNativeRMFLen', (R = 1) And (GetZ(LongInt(@Buf)) = '<DRM_OS2FILE,DRF_TEXT>') And
        (DrgQueryNativeRMFLen(C) = 22));
  Check('DrgVerifyRMF (paires et produit, nul : tout)', (DrgVerifyRMF(C, Z('DRM_PRINT'), Z2('DRF_TEXT')) = 1) And
        (DrgVerifyRMF(C, Z('DRM_DDE'), Z2('DRF_UNKNOWN')) = 1) And (DrgVerifyRMF(C, Z('DRM_OS2FILE'), Z2('DRF_UNKNOWN')) = 0) And
        (DrgVerifyRMF(C, 0, Z2('DRF_TEXT')) = 1) And (DrgVerifyRMF(C, Z('DRM_XYZ'), 0) = 0));
  Check('DrgVerifyNativeRMF', (DrgVerifyNativeRMF(C, Z('<DRM_PRINT,DRF_TEXT>,<DRM_OS2FILE,DRF_TEXT>')) = 1) And
        (DrgVerifyNativeRMF(C, Z('<DRM_PRINT,DRF_TEXT>')) = 0));
  R := DrgQueryFormat(C, Z('DRM_PRINT'), 32, LongInt(@Buf));
  Txt0 := GetZ(LongInt(@Buf));
  R2 := DrgQueryFormat(C, 0, 32, LongInt(@Buf));
  Check('DrgQueryFormat : mecanisme DRM_PRINT, natif, inconnu', (R = 11) And (Txt0 = 'DRF_UNKNOWN') And (R2 = 8) And
        (GetZ(LongInt(@Buf)) = 'DRF_TEXT') And (DrgQueryFormat(C, Z('DRM_X'), 32, LongInt(@Buf)) = 0));
  R := DrgQueryTrueType(C, 64, LongInt(@Buf));
  Check('DrgQueryTrueType, DrgQueryTrueTypeLen', (R = 1) And (GetZ(LongInt(@Buf)) = 'Plain Text') And
        (DrgQueryTrueTypeLen(C) = 10));
  Check('DrgVerifyTrueType, DrgVerifyType', (DrgVerifyTrueType(C, Z('Bitmap,Plain Text')) = 1) And
        (DrgVerifyTrueType(C, Z('Bitmap')) = 0) And (DrgVerifyType(C, Z('Bitmap')) = 1) And (DrgVerifyType(C, Z('Icon')) = 0));
  R := DrgVerifyTypeSet(C, Z('Icon,Bitmap,Plain Text'), 64, LongInt(@Buf));
  Txt0 := GetZ(LongInt(@Buf));
  R2 := DrgVerifyTypeSet(C, Z('Icon'), 64, LongInt(@Buf));
  Check('DrgVerifyTypeSet : intersection, aucune', (R = 1) And (Txt0 = 'Plain Text,Bitmap') And (R2 = 0));

  { --- acces, liberation --- }
  A := RdL(C + 8);
  R := DrgAccessDraginfo(P);
  R2 := DrgAccessDraginfo(P + 4);
  Check('DrgAccessDraginfo', (R = 1) And (R2 = 0));
  R := DrgDeleteDraginfoStrHandles(P);
  Check('DrgDeleteDraginfoStrHandles', (R = 1) And (DrgQueryStrNameLen(A) = 0) And (RdL(C + 8) = 0));
  R := DrgPushDraginfo(P, $2002);
  R2 := DrgFreeDraginfo(P);
  A := DrgAccessDraginfo(P);
  B := DrgFreeDraginfo(P);
  Check('DrgPushDraginfo, DrgFreeDraginfo (libere au dernier acces)', (R = 1) And (R2 = 1) And (A = 1) And (B = 1) And
        (DrgAccessDraginfo(P) = 0) And (DrgFreeDraginfo(P) = 0));
  P := DrgAllocDraginfo(1);
  WrL(P + 8, $1001);
  WrL(DrgQueryDragitemPtr(P, 0) + 4, 42);
  P2 := DrgReallocDraginfo(P, 3);
  Check('DrgReallocDraginfo : 3 elements, element et source gardes, ancien libere', (P2 <> 0) And
        (DrgQueryDragitemCount(P2) = 3) And (RdL(DrgQueryDragitemPtr(P2, 0) + 4) = 42) And (RdL(P2 + 8) = $1001) And
        (DrgQueryDraginfoPtrFromHwnd($1001) = P2) And ((P2 = P) Or (DrgAccessDraginfo(P) = 0)));
  R := DrgFreeDraginfo(P2);

  { --- DRAGTRANSFER --- }
  X := DrgAllocDragtransfer(3);
  Check('DrgAllocDragtransfer(3)', (X <> 0) And (RdL(X) = 28) And (RdL(X + 28) = 28) And (RdL(X + 56) = 28));
  R := DrgFreeDragtransfer(X + 28);
  R2 := DrgFreeDragtransfer(X + 5);
  A := DrgFreeDragtransfer(X);
  B := DrgFreeDragtransfer(X + 56);
  C := DrgFreeDragtransfer(X);
  Check('DrgFreeDragtransfer : par structure, tableau libere avec la derniere', (R = 1) And (R2 = 0) And (A = 1) And
        (B = 1) And (C = 0));

  { --- espaces de presentation --- }
  A := DrgGetPS($1001);
  B := DrgGetClipPS($1001, 0, 0);
  R := DrgReleasePS(A);
  R2 := DrgReleasePS(B);
  Check('DrgGetPS, DrgGetClipPS, DrgReleasePS', (A <> 0) And (B <> 0) And (A <> B) And (R = 1) And (R2 = 1) And
        (DrgReleasePS(A) = 0) And (DrgGetPS(0) = 0));

  { --- fenetres et messages --- }
  R := DrgRegisterWindow(HA, LongInt(@WndA), 0, 0, 320, 400, 1);
  R2 := DrgRegisterWindow(HB, LongInt(@WndB), 320, 0, 320, 400, 1);
  Check('DRGREGISTERWINDOW A et B, DRGQUERYDROPTARGET', (R = 1) And (R2 = 1) And (DrgQueryDropTarget(100, 100) = HA) And
        (DrgQueryDropTarget(500, 100) = HB) And (DrgQueryDropTarget(700, 100) = 0));
  X := DrgAllocDragtransfer(1);
  R := DrgSendTransferMsg(HA, DM_RENDER, X, 0);
  R2 := DrgSendTransferMsg($9999, DM_RENDER, X, 0);
  Check('DrgSendTransferMsg (reponse de la fenetre ; fenetre inconnue : 0)', (R = 77) And (LogA = 'R') And (R2 = 0));
  R := DrgPostTransferMsg(HB, DM_RENDERCOMPLETE, X, DMFL_RENDEROK, 0, 0);
  R2 := DrgPostTransferMsg($9999, DM_RENDERCOMPLETE, X, 0, 0, 0);
  Check('DrgPostTransferMsg : fsReply, remis ; fenetre inconnue (B : ' + LogB + ')', (R = 1) And (RdW(X + 26) = DMFL_RENDEROK) And
        (LogB = 'C') And (R2 = 0));
  R := DrgSendTransferMsg(HA, $1234, 0, 0);
  Check('message poste pendant un envoi : remis a la fin (' + Seq + ')', (Seq = 'AaB') And (Dm = 1));
  R := DrgFreeDragtransfer(X);

  { --- glissement differe --- }
  P := DrgAllocDraginfo(1);
  SetItem(HA, 1, 'Plain Text', '<DRM_OS2FILE,DRF_TEXT>', 'C:\', 'X.TXT');
  R := DrgSetDragitem(P, LongInt(@It), 36, 0);
  R := DrgLazyDrag(HA, P, LongInt(@Img), 1, 0);
  R2 := DrgLazyDrag(HA, P, 0, 0, 0);
  Check('DrgLazyDrag ; deuxieme glissement refuse ; DrgQueryDragStatus', (R = 1) And (R2 = 0) And
        (DrgQueryDragStatus = 2));
  Check('DrgQueryDraginfoPtr, DrgQueryDraginfoPtrFromHwnd', (DrgQueryDraginfoPtr(0) = P) And
        (DrgQueryDraginfoPtrFromHwnd(HA) = P));
  Check('DrgSetDragPointer, DrgSetDragImage pendant le glissement', (DrgSetDragPointer(P, $77) = 1) And
        (DrgSetDragImage(P, LongInt(@Img), 1, 0) = 1) And (DrgSetDragImage(P, 0, 1, 0) = 0));
  LogB := '';
  Ptl[0] := 500; Ptl[1] := 120;
  R := DrgLazyDrop(HB, DO_MOVE, LongInt(@Ptl));
  Check('DrgLazyDrop refuse par la cible : le glissement continue', (R = 0) And (DrgQueryDragStatus = 2) And (LogB = 'O'));
  AcceptB := 1;
  R := DrgLazyDrop(HB, DO_MOVE, LongInt(@Ptl));
  Check('DrgLazyDrop accepte : DM_DROP (point, operation), DRAGINFO libere par la cible', (R = 1) And
        (DrgQueryDragStatus = 0) And (LogB = 'OOD') And (DropX = 500) And (DropY = 120) And (DropOp = DO_MOVE) And
        (DrgAccessDraginfo(P) = 0));
  P := DrgAllocDraginfo(1);
  LogA := '';
  R := DrgLazyDrag(HB, P, 0, 0, 0);
  R2 := DrgLazyDrop(HA, DO_COPY, 0);
  A := DrgCancelLazyDrag;
  B := DrgCancelLazyDrag;
  Check('DrgCancelLazyDrag : DM_DRAGLEAVE a la cible ; sans glissement refuse', (R = 1) And (R2 = 0) And (A = 1) And
        (B = 0) And (LogA = 'OL') And (DrgQueryDragStatus = 0) And (DrgLazyDrop(HA, DO_COPY, 0) = 0) And
        (DrgSetDragPointer(P, 1) = 0));
  R := DrgFreeDraginfo(P);

  { --- fichiers deposes (glissement differe) --- }
  R := MakeFile('C:\DRGSRC.TXT');
  A := DosDelete(Z('D:\DRGSRC.TXT'));
  R := DrgAcceptDroppedFiles(HC, Z('D:\'), Z2('Plain Text'), DO_COPY, 0);
  Check('DrgAcceptDroppedFiles C (D:\, Plain Text)', R = 1);
  P := DrgAllocDraginfo(1);
  SetItem(HA, 5, 'Plain Text', '<DRM_OS2FILE,DRF_TEXT>', 'C:\', 'DRGSRC.TXT');
  R := DrgSetDragitem(P, LongInt(@It), 36, 0);
  LogA := ''; EndA := 0;
  R := DrgLazyDrag(HA, P, 0, 0, 0);
  R2 := DrgLazyDrop(HC, DO_DEFAULT, 0);
  Check('fichier copie dans D:\, DM_ENDCONVERSATION a la source', (R = 1) And (R2 = 1) And Exists('D:\DRGSRC.TXT') And
        Exists('C:\DRGSRC.TXT') And (LogA = 'E') And (EndA = DMFL_TARGETSUCCESSFUL) And (DrgAccessDraginfo(P) = 0));
  P := DrgAllocDraginfo(1);
  SetItem(HA, 6, 'Bitmap', '<DRM_OS2FILE,DRF_BITMAP>', 'C:\', 'DRGSRC.TXT');
  R := DrgSetDragitem(P, LongInt(@It), 36, 0);
  R := DrgLazyDrag(HA, P, 0, 0, 0);
  R2 := DrgLazyDrop(HC, DO_DEFAULT, 0);
  A := DrgCancelLazyDrag;
  Check('type non accepte : depot refuse', (R = 1) And (R2 = 0) And (A = 1));
  R := DrgDeleteDraginfoStrHandles(P);
  R := DrgFreeDraginfo(P);
  R := MakeFile('C:\DRGMOV.TXT');
  A := DosDelete(Z('D:\DRGMOV.TXT'));
  R := DrgAcceptDroppedFiles(HD, Z('D:\'), 0, DO_MOVE, 0);
  P := DrgAllocDraginfo(1);
  SetItem(HA, 7, 'Plain Text', '<DRM_OS2FILE,DRF_TEXT>', 'C:\', 'DRGMOV.TXT');
  R := DrgSetDragitem(P, LongInt(@It), 36, 0);
  R := DrgLazyDrag(HA, P, 0, 0, 0);
  R2 := DrgLazyDrop(HD, DO_DEFAULT, 0);
  Check('DrgAcceptDroppedFiles DO_MOVE : fichier deplace', (R = 1) And (R2 = 1) And Exists('D:\DRGMOV.TXT') And
        Not Exists('C:\DRGMOV.TXT'));
  R := DrgAcceptDroppedFiles(HD, 0, 0, 0, 0);
  Check('DrgAcceptDroppedFiles(hwnd, 0) : plus de fichiers ; fenetre nulle refusee', (R = 1) And
        (DrgAcceptDroppedFiles(0, Z('D:\'), 0, 0, 0) = 0));

  { --- glissements a la souris --- }
  R := MouOpen(0, LongInt(@Hm));
  P := DrgAllocDraginfo(1);
  SetItem(HA, 9, 'Plain Text', '<DRM_OS2FILE,DRF_TEXT>', 'C:\', 'X.TXT');
  R := DrgSetDragitem(P, LongInt(@It), 36, 0);
  PosRC[0] := 5; PosRC[1] := 10;
  R := MouFlushQue(Hm);
  R := MouSetPtrPos(LongInt(@PosRC), Hm);
  LogA := ''; LogB := '';
  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  OutLen := 0;
  WriteLn('DRAG1 : bouton 1, deplacement vers la droite, relachement');
  R := DrgDrag(HA, P, 0, 0, VK_BUTTON1, 0);
  Check('DrgDrag : de A vers B, depose sur B (A : ' + LogA + ', B : ' + LogB + ', x ' + IStr(RdW(P + 12)) + ', y ' +
        IStr(RdW(P + 14)) + ')', (R = HB) And (Pos('O', LogA) = 1) And
        (Pos('L', LogA) > 0) And (Pos('D', LogB) > 0) And (DropX >= 320) And (DrgAccessDraginfo(P) = 0) And
        (DrgQueryDragStatus = 0));
  P := DrgAllocDraginfo(1);
  R := DrgSetDragitem(P, LongInt(@It), 36, 0);
  LogA := ''; LogB := '';
  WriteLn('DRAG2 : bouton 1, Echap');
  R := DrgDrag(HA, P, 0, 0, VK_BUTTON1, 0);
  Check('DrgDrag annule par Echap : 0, DM_DRAGLEAVE (B : ' + LogB + ')', (R = 0) And (Pos('L', LogB) > 0) And
        (Pos('D', LogB) = 0) And (DrgAccessDraginfo(P) = 1));
  R := DrgDeleteDraginfoStrHandles(P);
  R := DrgFreeDraginfo(P);
  { C au-dessus de A }
  R := DrgRegisterWindow(HC, 0, 0, 0, 320, 400, 0);
  A := DosDelete(Z('D:\DRGF1.TXT'));
  R := MakeFile('C:\DRGF1.TXT');
  PutZ(LongInt(@FName), 'C:\DRGF1.TXT');
  PutZ(LongInt(@FType), 'Plain Text');
  Files[0] := LongInt(@FName);
  Types[0] := LongInt(@FType);
  R := MouFlushQue(Hm);
  R := MouSetPtrPos(LongInt(@PosRC), Hm);
  LogA := ''; FileA := 0;
  WriteLn('DRAG3 : bouton 1, relachement (fichier)');
  R := DrgDragFiles(HA, LongInt(@Files), LongInt(@Types), 0, 1, 0, VK_BUTTON1, 0, 0);
  Check('DrgDragFiles : fichier copie par C, DM_DRAGFILECOMPLETE (A : ' + LogA + ')', (R = 1) And
        Exists('D:\DRGF1.TXT') And (Pos('E', LogA) > 0) And (Pos('F', LogA) > 0) And
        (FileA = DF_SOURCE + DF_SUCCESSFUL));
  R := DrgRegisterWindow(HB, 0, 0, 0, 0, 0, 0);
  Check('DRGREGISTERWINDOW : retrait', (R = 1) And (DrgQueryDropTarget(500, 100) = 0));
  A := DosDelete(Z('C:\DRGSRC.TXT'));
  A := DosDelete(Z('D:\DRGSRC.TXT'));
  A := DosDelete(Z('D:\DRGMOV.TXT'));
  A := DosDelete(Z('C:\DRGF1.TXT'));
  A := DosDelete(Z('D:\DRGF1.TXT'));

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTDRG : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
