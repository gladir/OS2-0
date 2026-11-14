{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 MOUCALLS.DLL de OS/2-0 (sous-systeme
                souris : fonctions Mou*).
}

Library MOUCALLS;

{$IMAGEBASE $00F40000}
{$R-,S-,I-}

{ Compilation : OS2PC MOUCALLS.PAS   (produit MOUCALLS.DLL)

  MOUCALLS.DLL est le sous-systeme souris d'OS/2 : ouverture de la souris
  dans la session, file d'evenements (deplacements et boutons), position
  du pointeur en coordonnees de l'ecran texte (ligne, colonne), dessin du
  pointeur, masque d'evenements, facteurs d'echelle, seuils
  d'acceleration, etat du peripherique, touche de session et
  remplacement du sous-systeme.

  Les paquets de la souris PS/2 sont recus par le noyau OS2KRNL (IRQ 12)
  et lus par KrnMouRead ; la DLL les transforme en evenements a chaque
  appel d'une fonction Mou* (une lecture avec attente interroge la file
  du noyau toutes les 10 ms). Le pointeur est dessine dans l'ecran texte
  (000B8000h) en combinant la cellule avec les masques ET et OU exclusif
  de sa forme (par defaut FFFFh et 7700h : couleurs inversees) ; comme
  sous OS/2, il n'apparait qu'apres MouDrawPtr. Quand l'ecran est en mode
  graphique (VioSetMode), les lignes et colonnes sont des pels (0 a 479 et
  0 a 639 en 640 x 480) et le pointeur est dessine par le programme (PM :
  PMWIN.DLL).

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires. Un pointeur vers une valeur simple (pcButtons, pfsEvents,
  pfWait...) designe un LongInt ; les structures gardent leur
  disposition d'OS/2 (champs USHORT de 16 bits) :
    MOUEVENTINFO  fs (2), Time (4, ms), row (2), col (2)
    MOUQUEINFO    cEvents, cmaxEvents
    PTRLOC        row, col
    PTRSHAPE      cb, col, row, colHot, rowHot (mode texte : masques ET
                  et OU exclusif d'une cellule, cb = 4)
    NOPTRRECT     row, col, cRow, cCol
    SCALEFACT     rowScale, colScale (mickeys pour 8 pels)
    THRESHOLD     Length (10), Level1, Lev1Mult, Level2, Lev2Mult
  Exemple :
    Function MouOpen(PDrvName, PHmou : LongInt) : LongInt; External 'MOUCALLS';

  Evenements (fs, et masque de MouSetEventMask) : 01h deplacement sans
  bouton, 02h deplacement avec le bouton 1 (gauche), 04h bouton 1, 08h
  deplacement avec le bouton 2 (droit), 10h bouton 2, 20h deplacement
  avec le bouton 3 (milieu), 40h bouton 3 ; fs = 0 : tous les boutons
  relaches.

  Fonctions exportees (ordinaux d'origine de MOUCALLS.DLL) :
     1 MouGetPtrShape    11 MouSetScaleFact    21 MouSetPtrPos
     2 MouSetPtrShape    12 MouFree            22 MouGetDevStatus
     3 MouGetNumMickeys  13 MouGetNumQueEl     23 MouSynch
     4 MouGetHotKey      14 MouDeRegister      24 MouRegister
     5 MouShellInit      15 MouGetEventMask    25 MouSetDevStatus
     6 MouGetScaleFact   16 MouSetEventMask    26 MouDrawPtr
     7 MouFlushQue       17 MouOpen            27 MouInitReal
     8 MouGetNumButtons  18 MouRemovePtr       29 MouGetThreshold
     9 MouClose          19 MouGetPtrPos       30 MouSetThreshold
    10 MouSetHotKey      20 MouReadEventQue

  Remplacement (MouRegister) : pour chaque fonction choisie par flFuns
  (bits MR_* d'OS/2 : 0 MouGetNumButtons, 1 MouGetNumMickeys,
  2 MouGetDevStatus, 3 MouGetNumQueEl, 4 MouReadEventQue,
  5 MouGetScaleFact, 6 MouGetEventMask, 7 MouSetScaleFact,
  8 MouSetEventMask, 9 MouGetHotKey, 10 MouSetHotKey, 11 MouOpen,
  12 MouClose, 13 MouGetPtrShape, 14 MouSetPtrShape, 15 MouDrawPtr,
  16 MouRemovePtr, 17 MouGetPtrPos, 18 MouSetPtrPos, 19 MouInitReal,
  20 MouSetDevStatus), la fonction de remplacement est appelee
  (_System) par Entree(Fonction, pParametres, Nombre) ; si elle rend -1,
  la fonction de base est executee, sinon sa valeur est rendue.

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services du noyau et de DOSCALLS.DLL
    Partie 3 - Utilitaires
    Partie 4 - Pointeur (dessin dans l'ecran texte)
    Partie 5 - Paquets de la souris et file d'evenements
    Partie 6 - Remplacement du sous-systeme
    Partie 7 - Fonctions Mou*
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR                 = 0;
  ERROR_INVALID_PARAMETER  = 87;
  ERROR_MOUSE_NO_DEVICE    = 385;
  ERROR_MOUSE_INV_HANDLE   = 386;
  ERROR_MOUSE_INV_PARMS    = 387;
  ERROR_MOUSE_CANT_RESET   = 388;
  ERROR_MOUSE_DISPLAY_PARMS = 389;
  ERROR_MOUSE_INV_MODULE   = 390;
  ERROR_MOUSE_INV_ENTRY_PT = 391;
  ERROR_MOUSE_INV_MASK     = 392;
  ERROR_MOUSE_INVALID_ASCIIZ = 413;
  ERROR_MOUSE_INVALID_MASK = 414;
  ERROR_MOUSE_REGISTER     = 415;
  ERROR_MOUSE_DEREGISTER   = 416;

  ScrBase   = $000B8000;
  NCols     = 80;
  NRows     = 25;
  MaxH      = 8;               { handles (ouvertures) }
  QMax      = 64;              { evenements en file }

  { etat du peripherique }
  MOUSE_QUEUEBUSY  = $0001;
  MOUSE_BLOCKREAD  = $0002;
  MOUSE_FLUSH      = $0004;
  MOUSE_UNSUPPORTED_MODE = $0008;
  MOUSE_DISABLED   = $0100;
  MOUSE_MICKEYS    = $0200;

  { bits MR_* (MouRegister) }
  MB_GETNUMBUTTONS = 0;  MB_GETNUMMICKEYS = 1; MB_GETDEVSTATUS = 2;  MB_GETNUMQUEEL = 3;
  MB_READEVENTQUE = 4;   MB_GETSCALEFACT = 5;  MB_GETEVENTMASK = 6;  MB_SETSCALEFACT = 7;
  MB_SETEVENTMASK = 8;   MB_GETHOTKEY = 9;     MB_SETHOTKEY = 10;    MB_OPEN = 11;
  MB_CLOSE = 12;         MB_GETPTRSHAPE = 13;  MB_SETPTRSHAPE = 14;  MB_DRAWPTR = 15;
  MB_REMOVEPTR = 16;     MB_GETPTRPOS = 17;    MB_SETPTRPOS = 18;    MB_INITREAL = 19;
  MB_SETDEVSTATUS = 20;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { ouvertures : handle = numero 1..MaxH }
  HUsed     : Array[1..MaxH] Of Boolean;
  HPid      : Array[1..MaxH] Of LongInt;
  OpenCount : LongInt;

  { position : mickeys accumules ; ligne = PosY div RowScale,
    colonne = PosX div ColScale }
  PosX, PosY : LongInt;
  RowScale, ColScale : LongInt;
  Lev1, Mult1, Lev2, Mult2 : LongInt;   { seuils d'acceleration }
  EvMask    : LongInt;
  DevStatus : LongInt;
  HotKey    : LongInt;
  Buttons   : LongInt;                   { boutons enfonces (bits 0 a 2) }
  NumButtons, Mickeys : LongInt;
  Present   : Boolean;

  { pointeur }
  AndMask, XorMask : LongInt;
  DrawOn    : Boolean;                   { MouDrawPtr appele }
  ExclOn    : Boolean;                   { zone d'exclusion (MouRemovePtr) }
  ExRow, ExCol, ExRows, ExCols : LongInt;
  Shown     : Boolean;
  ShownAddr, SavedCell, DrawnCell : LongInt;

  { file d'evenements }
  QFs, QTime, QRow, QCol : Array[0..QMax - 1] Of LongInt;
  QHead, QCount : LongInt;
  Lost      : LongInt;

  { remplacement }
  RegEntry, RegFuns : LongInt;
  InHook    : Boolean;
  HookRet   : LongInt;
  Prm       : Array[0..7] Of LongInt;

  Pk        : Array[0..3] Of LongInt;
  GrW, GrH  : LongInt;                   { mode graphique : pels (0 : texte) }
  InfoK     : Array[0..3] Of LongInt;
  FailName  : Array[0..63] Of Byte;
  { souris integree de VirtualBox (VBOXGST.DLL) : 0 pas encore cherchee,
    -1 absente, sinon adresse de VBOXGUESTREQUEST }
  VbFn      : LongInt;
  VbPk      : Array[0..7] Of LongInt;
  VbName    : Array[0..15] Of Byte;
  RealDrv   : String;

{ ==================================================================== }
{ Partie 2 - Services du noyau et de DOSCALLS.DLL                      }
{ ==================================================================== }

Function KrnMouRead(P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMouRead';
Function KrnMouInfo(P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMouInfo';
Function KSleep(Ms : LongInt) : LongInt; External 'DOSCALLS' Name 'Sleep';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function DosLoadModule(PFail, CbFail, PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function VioGetMode(PMode, Hvio : LongInt) : LongInt; External 'VIOCALLS';

{ ==================================================================== }
{ Partie 3 - Utilitaires                                               }
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
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
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
      S := S + UpCase(Chr(RdB(A + N)));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ Le handle appartient-il au processus ? }
Function HErr(Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := ERROR_MOUSE_INV_HANDLE;
  If (Hmou >= 1) And (Hmou <= MaxH) Then
    If HUsed[Hmou] And (HPid[Hmou] = MyPid) Then R := NO_ERROR;
  HErr := R;
End;

{ ecran : nombre de lignes et de colonnes (pels en mode graphique), pels
  par unite de l'echelle (une cellule : 8 x 16 pels) }
Function MaxRows : LongInt;
Begin
  If GrH > 0 Then MaxRows := GrH Else MaxRows := NRows;
End;

Function MaxCols : LongInt;
Begin
  If GrW > 0 Then MaxCols := GrW Else MaxCols := NCols;
End;

Function UnitY : LongInt;
Begin
  If GrH > 0 Then UnitY := 16 Else UnitY := 1;
End;

Function UnitX : LongInt;
Begin
  If GrW > 0 Then UnitX := 8 Else UnitX := 1;
End;

Function CurRow : LongInt;
Begin
  CurRow := (PosY * UnitY) Div RowScale;
End;

Function CurCol : LongInt;
Begin
  CurCol := (PosX * UnitX) Div ColScale;
End;

{ mickeys de la ligne et de la colonne }
Function RowPos(Row : LongInt) : LongInt;
Begin
  RowPos := (Row * RowScale + UnitY - 1) Div UnitY;
End;

Function ColPos(Col : LongInt) : LongInt;
Begin
  ColPos := (Col * ColScale + UnitX - 1) Div UnitX;
End;

Procedure ClampPos;
Begin
  If PosX < 0 Then PosX := 0;
  If PosY < 0 Then PosY := 0;
  If PosX > ColPos(MaxCols) - 1 Then PosX := ColPos(MaxCols) - 1;
  If PosY > RowPos(MaxRows) - 1 Then PosY := RowPos(MaxRows) - 1;
End;

{ mode de l'ecran (VioGetMode) : en passant au mode graphique ou au mode
  texte, la position garde sa proportion }
Procedure ModeCheck;
Var Mi : Array[0..39] Of Byte; K, W, H, R, C, OR_, OC : LongInt;
Begin
  For K := 0 To 39 Do Mi[K] := 0;
  Mi[0] := 12;
  W := 0; H := 0;
  If VioGetMode(LongInt(@Mi), 0) = 0 Then
    If (Mi[2] And 2) <> 0 Then
    Begin
      W := Mi[8] Or (Mi[9] Shl 8); H := Mi[10] Or (Mi[11] Shl 8);
    End;
  If (W <> GrW) Or (H <> GrH) Then
  Begin
    R := CurRow; C := CurCol; OR_ := MaxRows; OC := MaxCols;
    Shown := False;
    GrW := W; GrH := H;
    If (OR_ > 0) And (OC > 0) Then
    Begin
      PosY := RowPos((R * MaxRows) Div OR_);
      PosX := ColPos((C * MaxCols) Div OC);
    End;
    ClampPos;
  End;
End;

{ ==================================================================== }
{ Partie 4 - Pointeur (dessin dans l'ecran texte)                      }
{ ==================================================================== }

Procedure HidePtr;
Begin
  If Shown Then
  Begin
    { la cellule n'est rendue que si l'application ne l'a pas recrite }
    If RdW(ShownAddr) = DrawnCell Then WrW(ShownAddr, SavedCell);
    Shown := False;
  End;
End;

Function PtrVisible : Boolean;
Var R, C : LongInt; V : Boolean;
Begin
  V := (OpenCount > 0) And DrawOn And ((DevStatus And MOUSE_DISABLED) = 0);
  If V And ExclOn Then
  Begin
    R := CurRow; C := CurCol;
    If (R >= ExRow) And (R < ExRow + ExRows) And (C >= ExCol) And (C < ExCol + ExCols) Then V := False;
  End;
  PtrVisible := V;
End;

Procedure ShowPtr;
Begin
  If GrW > 0 Then Exit;
  If (Not Shown) And PtrVisible Then
  Begin
    ShownAddr := ScrBase + (CurRow * NCols + CurCol) * 2;
    SavedCell := RdW(ShownAddr);
    DrawnCell := ((SavedCell And AndMask) Xor XorMask) And $FFFF;
    WrW(ShownAddr, DrawnCell);
    Shown := True;
  End;
End;

Procedure Refresh;
Begin
  HidePtr;
  ShowPtr;
End;

{ ==================================================================== }
{ Partie 5 - Paquets de la souris et file d'evenements                 }
{ ==================================================================== }

Procedure Enqueue(Fs, Time, Row, Col : LongInt);
Var I : LongInt;
Begin
  If QCount >= QMax Then Inc(Lost)
  Else
  Begin
    I := (QHead + QCount) Mod QMax;
    QFs[I] := Fs; QTime[I] := Time; QRow[I] := Row; QCol[I] := Col;
    Inc(QCount);
  End;
End;

{ Acceleration : seuils en mickeys par paquet }
Function Accel(D : LongInt) : LongInt;
Var A : LongInt;
Begin
  A := Abs(D);
  If (Lev2 > 0) And (A > Lev2) Then D := D * Mult2
  Else If (Lev1 > 0) And (A > Lev1) Then D := D * Mult1;
  Accel := D;
End;

{ appel d'une fonction d'une DLL par son adresse (un parametre) }
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

{ le VMMDev de VirtualBox (PCI 80EEh:CAFEh) est-il sur le bus 0 ? }
Function VmmDevOnPci : Boolean;
Var D, V : LongInt;
Begin
  VmmDevOnPci := False;
  For D := 0 To 31 Do
  Begin
    V := $80000000 Or (D Shl 11);
    asm
      mov edx,3320
      mov eax,V
      out dx,eax
      mov edx,3324
      in eax,dx
      mov V,eax
    end;
    If V = $CAFE80EE Then VmmDevOnPci := True;
  End;
End;

{ position absolue de la souris integree de VirtualBox (0..65535) ;
  faux si la machine n'est pas une machine VirtualBox ou si l'hote ne
  veut pas la souris absolue (souris capturee) }
Function VBoxAbs(Var X, Y : LongInt) : Boolean;
Var H, F, K : LongInt; S : String;
Begin
  VBoxAbs := False;
  If VbFn = 0 Then
  Begin
    VbFn := -1;
    If Not VmmDevOnPci Then Exit;
    S := 'VBOXGST';
    For K := 1 To Length(S) Do VbName[K - 1] := Ord(S[K]);
    VbName[Length(S)] := 0;
    H := 0; F := 0;
    If DosLoadModule(LongInt(@FailName), 64, LongInt(@VbName), LongInt(@H)) = NO_ERROR Then
      If (DosQueryProcAddr(H, 1, 0, LongInt(@F)) = NO_ERROR) And (F <> 0) Then
      Begin
        VbPk[0] := 1;
        If CallPtr1(F, LongInt(@VbPk)) <> 0 Then VbFn := F;
      End;
  End;
  If VbFn = -1 Then Exit;
  VbPk[0] := 2;
  If CallPtr1(VbFn, LongInt(@VbPk)) = 0 Then Exit;
  X := VbPk[1]; Y := VbPk[2];
  VBoxAbs := True;
End;

{ Traiter les paquets en attente dans le noyau }
Procedure Poll;
Var Dx, Dy, B, T, Fs, OldR, OldC, Ax, Ay, Px, Py : LongInt; Moved : Boolean;
Begin
  If Not Present Then Exit;
  ModeCheck;
  OldR := CurRow; OldC := CurCol;
  While KrnMouRead(LongInt(@Pk)) <> 0 Do
  Begin
    Dx := Accel(Pk[0]); Dy := Accel(Pk[1]); B := Pk[2]; T := Pk[3];
    Px := PosX; Py := PosY;
    If VBoxAbs(Ax, Ay) Then
    Begin
      { VirtualBox : position absolue (le paquet PS/2 ne porte que les
        boutons) ; le pointeur d'OS/2-0 est sous celui de l'hote }
      PosX := ColPos((Ax * MaxCols) Div 65536);
      PosY := RowPos((Ay * MaxRows) Div 65536);
    End
    Else
    Begin
      PosX := PosX + Dx;
      PosY := PosY + Dy;
    End;
    ClampPos;
    Moved := (PosX <> Px) Or (PosY <> Py) Or (Dx <> 0) Or (Dy <> 0);
    { etat : bouton 1 = gauche (bit 0), 2 = droit (bit 1), 3 = milieu (bit 2) }
    Fs := 0;
    If Moved Then
    Begin
      If B = 0 Then Fs := $01;
      If (B And 1) <> 0 Then Fs := Fs Or $02;
      If (B And 2) <> 0 Then Fs := Fs Or $08;
      If (B And 4) <> 0 Then Fs := Fs Or $20;
    End
    Else
    Begin
      If (B And 1) <> 0 Then Fs := Fs Or $04;
      If (B And 2) <> 0 Then Fs := Fs Or $10;
      If (B And 4) <> 0 Then Fs := Fs Or $40;
    End;
    If OpenCount > 0 Then
    Begin
      If (DevStatus And MOUSE_MICKEYS) <> 0 Then
      Begin
        If ((Fs And EvMask) <> 0) Or ((Fs = 0) And (B <> Buttons)) Then Enqueue(Fs, T, Dy, Dx);
      End
      Else If ((Fs And EvMask) <> 0) Or ((Fs = 0) And (B <> Buttons) And (EvMask <> 0)) Then
        Enqueue(Fs, T, CurRow, CurCol);
    End;
    Buttons := B;
  End;
  If (CurRow <> OldR) Or (CurCol <> OldC) Then Refresh;
End;

{ ==================================================================== }
{ Partie 6 - Remplacement du sous-systeme                              }
{ ==================================================================== }

Function CallPtr3(F, A1, A2, A3 : LongInt) : LongInt;
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
  CallPtr3 := R;
End;

{ La fonction Bit est-elle remplacee ? Si oui, appeler le remplacant ;
  vrai si sa valeur (HookRet) doit etre rendue a l'appelant }
Function Hooked(Bit, N, A1, A2, A3 : LongInt) : Boolean;
Var R : LongInt; Res : Boolean;
Begin
  Res := False;
  If (Not InHook) And (RegEntry <> 0) And (((RegFuns Shr Bit) And 1) <> 0) Then
  Begin
    Prm[0] := A1; Prm[1] := A2; Prm[2] := A3;
    InHook := True;
    R := CallPtr3(RegEntry, Bit, LongInt(@Prm), N);
    InHook := False;
    If R <> -1 Then
    Begin
      HookRet := R;
      Res := True;
    End;
  End;
  Hooked := Res;
End;

{ ==================================================================== }
{ Partie 7 - Fonctions Mou*                                            }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  MouOpen(pszDvrName, phmou) : ouvrir la souris pour le processus.
  pszDvrName : pilote de dessin du pointeur ("POINTER$") ou 0 ;
  *phmou <- handle }
Function MouOpen(PDrv, PHmou : LongInt) : LongInt;
Var R, I, F : LongInt; S : String;
Begin
  If Hooked(MB_OPEN, 2, PDrv, PHmou, 0) Then
  Begin
    MouOpen := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  S := GetZ(PDrv);
  If PHmou = 0 Then R := ERROR_MOUSE_INV_PARMS
  Else If Not Present Then R := ERROR_MOUSE_NO_DEVICE
  Else If (S <> '') And (S <> 'POINTER$') Then R := ERROR_MOUSE_INV_MODULE
  Else
  Begin
    F := 0;
    For I := MaxH DownTo 1 Do
      If Not HUsed[I] Then F := I;
    If F = 0 Then R := ERROR_MOUSE_INV_HANDLE
    Else
    Begin
      Poll;
      HUsed[F] := True;
      HPid[F] := MyPid;
      If OpenCount = 0 Then
      Begin
        QHead := 0; QCount := 0;
        DrawOn := False;
        ExclOn := False;
      End;
      Inc(OpenCount);
      WrL(PHmou, F);
    End;
  End;
  MouOpen := R;
End;

{ ---------------------------------------------------------------------
  MouClose(hmou) : fermer la souris (le pointeur disparait a la derniere
  fermeture) }
Function MouClose(Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_CLOSE, 1, Hmou, 0, 0) Then
  Begin
    MouClose := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If R = NO_ERROR Then
  Begin
    Poll;
    HUsed[Hmou] := False;
    Dec(OpenCount);
    If OpenCount <= 0 Then
    Begin
      OpenCount := 0;
      HidePtr;
      DrawOn := False;
    End;
  End;
  MouClose := R;
End;

{ ---------------------------------------------------------------------
  MouReadEventQue(pEvent, pfWait, hmou) : lire l'evenement suivant
  (MOUEVENTINFO). *pfWait 0 : sans attente (fs = 0 et Time = 0 si la
  file est vide), 1 : attendre un evenement }
Function MouReadEventQue(PEvent, PWait, Hmou : LongInt) : LongInt;
Var R, W : LongInt;
Begin
  If Hooked(MB_READEVENTQUE, 3, PEvent, PWait, Hmou) Then
  Begin
    MouReadEventQue := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And ((PEvent = 0) Or (PWait = 0)) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    W := RdL(PWait);
    If (W <> 0) And (W <> 1) Then R := ERROR_MOUSE_INV_PARMS;
  End;
  If R = NO_ERROR Then
  Begin
    Poll;
    If W = 1 Then
    Begin
      DevStatus := DevStatus Or MOUSE_BLOCKREAD;
      While QCount = 0 Do
      Begin
        KSleep(10);
        Poll;
      End;
      DevStatus := DevStatus And Not MOUSE_BLOCKREAD;
    End;
    If QCount = 0 Then
    Begin
      WrW(PEvent, 0); WrL(PEvent + 2, 0);
      WrW(PEvent + 6, CurRow); WrW(PEvent + 8, CurCol);
    End
    Else
    Begin
      WrW(PEvent, QFs[QHead]);
      WrL(PEvent + 2, QTime[QHead]);
      WrW(PEvent + 6, QRow[QHead]);
      WrW(PEvent + 8, QCol[QHead]);
      QHead := (QHead + 1) Mod QMax;
      Dec(QCount);
    End;
  End;
  MouReadEventQue := R;
End;

{ ---------------------------------------------------------------------
  MouGetNumQueEl(pQueInfo, hmou) : MOUQUEINFO (evenements en file,
  taille de la file) }
Function MouGetNumQueEl(PQue, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETNUMQUEEL, 2, PQue, Hmou, 0) Then
  Begin
    MouGetNumQueEl := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PQue = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    Poll;
    WrW(PQue, QCount);
    WrW(PQue + 2, QMax);
  End;
  MouGetNumQueEl := R;
End;

{ ---------------------------------------------------------------------
  MouFlushQue(hmou) : vider la file d'evenements }
Function MouFlushQue(Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := HErr(Hmou);
  If R = NO_ERROR Then
  Begin
    Poll;
    QHead := 0; QCount := 0;
  End;
  MouFlushQue := R;
End;

{ ---------------------------------------------------------------------
  MouGetPtrPos(pPtrLoc, hmou) : position du pointeur (ligne, colonne) }
Function MouGetPtrPos(PPos, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETPTRPOS, 2, PPos, Hmou, 0) Then
  Begin
    MouGetPtrPos := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PPos = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    Poll;
    WrW(PPos, CurRow);
    WrW(PPos + 2, CurCol);
  End;
  MouGetPtrPos := R;
End;

{ ---------------------------------------------------------------------
  MouSetPtrPos(pPtrLoc, hmou) : placer le pointeur (ligne 0 a 24,
  colonne 0 a 79) }
Function MouSetPtrPos(PPos, Hmou : LongInt) : LongInt;
Var R, Row, Col : LongInt;
Begin
  If Hooked(MB_SETPTRPOS, 2, PPos, Hmou, 0) Then
  Begin
    MouSetPtrPos := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PPos = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    Row := RdW(PPos); Col := RdW(PPos + 2);
    Poll;
    If (Row >= MaxRows) Or (Col >= MaxCols) Then R := ERROR_MOUSE_INV_PARMS
    Else
    Begin
      HidePtr;
      PosY := RowPos(Row);
      PosX := ColPos(Col);
      ShowPtr;
    End;
  End;
  MouSetPtrPos := R;
End;

{ ---------------------------------------------------------------------
  MouGetPtrShape(pBuf, pPtrShape, hmou) : forme du pointeur. En mode
  texte : 2 mots (masque ET, masque OU exclusif de la cellule) ; si
  pPtrShape->cb est trop petit, il recoit la taille necessaire (4). }
Function MouGetPtrShape(PBuf, PShape, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETPTRSHAPE, 3, PBuf, PShape, Hmou) Then
  Begin
    MouGetPtrShape := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PShape = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    If (RdW(PShape) < 4) Or (PBuf = 0) Then
    Begin
      WrW(PShape, 4);
      R := ERROR_MOUSE_INV_PARMS;
    End
    Else
    Begin
      WrW(PBuf, AndMask);
      WrW(PBuf + 2, XorMask);
      WrW(PShape, 4);
      WrW(PShape + 2, 1);
      WrW(PShape + 4, 1);
      WrW(PShape + 6, 0);
      WrW(PShape + 8, 0);
    End;
  End;
  MouGetPtrShape := R;
End;

{ ---------------------------------------------------------------------
  MouSetPtrShape(pBuf, pPtrShape, hmou) : changer la forme du pointeur
  (mode texte : cb = 4, col = row = 1, point chaud 0, 0) }
Function MouSetPtrShape(PBuf, PShape, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_SETPTRSHAPE, 3, PBuf, PShape, Hmou) Then
  Begin
    MouSetPtrShape := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And ((PShape = 0) Or (PBuf = 0)) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    If (RdW(PShape) <> 4) Or (RdW(PShape + 2) <> 1) Or (RdW(PShape + 4) <> 1) Or
       (RdW(PShape + 6) <> 0) Or (RdW(PShape + 8) <> 0) Then R := ERROR_MOUSE_INV_PARMS
    Else
    Begin
      Poll;
      HidePtr;
      AndMask := RdW(PBuf);
      XorMask := RdW(PBuf + 2);
      ShowPtr;
    End;
  End;
  MouSetPtrShape := R;
End;

{ ---------------------------------------------------------------------
  MouDrawPtr(hmou) : la zone d'exclusion est levee ; le pointeur est
  dessine }
Function MouDrawPtr(Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_DRAWPTR, 1, Hmou, 0, 0) Then
  Begin
    MouDrawPtr := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If R = NO_ERROR Then
  Begin
    Poll;
    ExclOn := False;
    DrawOn := True;
    Refresh;
  End;
  MouDrawPtr := R;
End;

{ ---------------------------------------------------------------------
  MouRemovePtr(pRect, hmou) : zone d'exclusion (NOPTRRECT : ligne,
  colonne, nombre de lignes, nombre de colonnes) ou le pointeur n'est
  pas dessine, jusqu'a MouDrawPtr }
Function MouRemovePtr(PRect, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_REMOVEPTR, 2, PRect, Hmou, 0) Then
  Begin
    MouRemovePtr := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PRect = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    If (RdW(PRect) >= MaxRows) Or (RdW(PRect + 2) >= MaxCols) Or (RdW(PRect + 4) = 0) Or
       (RdW(PRect + 6) = 0) Then R := ERROR_MOUSE_INV_PARMS
    Else
    Begin
      Poll;
      ExRow := RdW(PRect); ExCol := RdW(PRect + 2);
      ExRows := RdW(PRect + 4); ExCols := RdW(PRect + 6);
      ExclOn := True;
      Refresh;
    End;
  End;
  MouRemovePtr := R;
End;

{ ---------------------------------------------------------------------
  MouGetEventMask(pfsEvents, hmou) / MouSetEventMask(pfsEvents, hmou) :
  evenements rapportes (bits 01h a 40h) }
Function MouGetEventMask(PMask, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETEVENTMASK, 2, PMask, Hmou, 0) Then
  Begin
    MouGetEventMask := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PMask = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then WrL(PMask, EvMask);
  MouGetEventMask := R;
End;

Function MouSetEventMask(PMask, Hmou : LongInt) : LongInt;
Var R, M : LongInt;
Begin
  If Hooked(MB_SETEVENTMASK, 2, PMask, Hmou, 0) Then
  Begin
    MouSetEventMask := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PMask = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    M := RdL(PMask);
    If (M And Not $7F) <> 0 Then R := ERROR_MOUSE_INV_MASK
    Else
    Begin
      Poll;
      EvMask := M;
    End;
  End;
  MouSetEventMask := R;
End;

{ ---------------------------------------------------------------------
  MouGetScaleFact(pScale, hmou) / MouSetScaleFact(pScale, hmou) :
  SCALEFACT (mickeys pour 8 pels : lignes, colonnes ; 1 a 32767) }
Function MouGetScaleFact(PScale, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETSCALEFACT, 2, PScale, Hmou, 0) Then
  Begin
    MouGetScaleFact := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PScale = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    WrW(PScale, RowScale);
    WrW(PScale + 2, ColScale);
  End;
  MouGetScaleFact := R;
End;

Function MouSetScaleFact(PScale, Hmou : LongInt) : LongInt;
Var R, Rs, Cs, Row, Col : LongInt;
Begin
  If Hooked(MB_SETSCALEFACT, 2, PScale, Hmou, 0) Then
  Begin
    MouSetScaleFact := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PScale = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    Rs := RdW(PScale); Cs := RdW(PScale + 2);
    If (Rs < 1) Or (Rs > 32767) Or (Cs < 1) Or (Cs > 32767) Then R := ERROR_MOUSE_INV_PARMS
    Else
    Begin
      Poll;
      Row := CurRow; Col := CurCol;
      RowScale := Rs; ColScale := Cs;
      PosY := RowPos(Row); PosX := ColPos(Col);
    End;
  End;
  MouSetScaleFact := R;
End;

{ ---------------------------------------------------------------------
  MouGetThreshold(pthreshold, hmou) / MouSetThreshold(pthreshold, hmou) :
  THRESHOLD (Length = 10, Level1, Lev1Mult, Level2, Lev2Mult) : au-dela
  de LevelN mickeys par paquet, le deplacement est multiplie par
  LevNMult }
Function MouGetThreshold(PThr, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PThr = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If (R = NO_ERROR) And (RdW(PThr) < 10) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    WrW(PThr, 10);
    WrW(PThr + 2, Lev1); WrW(PThr + 4, Mult1);
    WrW(PThr + 6, Lev2); WrW(PThr + 8, Mult2);
  End;
  MouGetThreshold := R;
End;

Function MouSetThreshold(PThr, Hmou : LongInt) : LongInt;
Var R, L1, M1, L2, M2 : LongInt;
Begin
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PThr = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If (R = NO_ERROR) And (RdW(PThr) <> 10) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    L1 := RdW(PThr + 2); M1 := RdW(PThr + 4); L2 := RdW(PThr + 6); M2 := RdW(PThr + 8);
    If (M1 < 1) Or (M2 < 1) Or (M1 > 32) Or (M2 > 32) Or (L2 < L1) Then R := ERROR_MOUSE_INV_PARMS
    Else
    Begin
      Poll;
      Lev1 := L1; Mult1 := M1; Lev2 := L2; Mult2 := M2;
    End;
  End;
  MouSetThreshold := R;
End;

{ ---------------------------------------------------------------------
  MouGetDevStatus(pfsDevStatus, hmou) / MouSetDevStatus : etat (01h file
  occupee, 02h lecture en attente, 04h vidage, 08h mode non gere,
  100h pointeur desactive, 200h evenements en mickeys relatifs ; seuls
  100h et 200h peuvent etre fixes) }
Function MouGetDevStatus(PStatus, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETDEVSTATUS, 2, PStatus, Hmou, 0) Then
  Begin
    MouGetDevStatus := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PStatus = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then WrL(PStatus, DevStatus);
  MouGetDevStatus := R;
End;

Function MouSetDevStatus(PStatus, Hmou : LongInt) : LongInt;
Var R, S : LongInt;
Begin
  If Hooked(MB_SETDEVSTATUS, 2, PStatus, Hmou, 0) Then
  Begin
    MouSetDevStatus := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PStatus = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    S := RdL(PStatus);
    If (S And Not (MOUSE_DISABLED Or MOUSE_MICKEYS)) <> 0 Then R := ERROR_MOUSE_INV_PARMS
    Else
    Begin
      Poll;
      HidePtr;
      DevStatus := (DevStatus And Not (MOUSE_DISABLED Or MOUSE_MICKEYS)) Or S;
      ShowPtr;
    End;
  End;
  MouSetDevStatus := R;
End;

{ ---------------------------------------------------------------------
  MouGetNumButtons(pcButtons, hmou) : nombre de boutons (3) }
Function MouGetNumButtons(PCount, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETNUMBUTTONS, 2, PCount, Hmou, 0) Then
  Begin
    MouGetNumButtons := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PCount = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then WrL(PCount, NumButtons);
  MouGetNumButtons := R;
End;

{ ---------------------------------------------------------------------
  MouGetNumMickeys(pcMickeys, hmou) : mickeys par centimetre (40 : 4
  points par millimetre, resolution par defaut de la souris PS/2) }
Function MouGetNumMickeys(PCount, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETNUMMICKEYS, 2, PCount, Hmou, 0) Then
  Begin
    MouGetNumMickeys := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PCount = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then WrL(PCount, Mickeys);
  MouGetNumMickeys := R;
End;

{ ---------------------------------------------------------------------
  MouGetHotKey(pfsButtons, hmou) / MouSetHotKey : boutons de la touche
  de session (1 bouton 1, 2 bouton 2, 4 bouton 3 ; 0 aucune) }
Function MouGetHotKey(PButtons, Hmou : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(MB_GETHOTKEY, 2, PButtons, Hmou, 0) Then
  Begin
    MouGetHotKey := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PButtons = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then WrL(PButtons, HotKey);
  MouGetHotKey := R;
End;

Function MouSetHotKey(PButtons, Hmou : LongInt) : LongInt;
Var R, B : LongInt;
Begin
  If Hooked(MB_SETHOTKEY, 2, PButtons, Hmou, 0) Then
  Begin
    MouSetHotKey := HookRet;
    Exit;
  End;
  R := HErr(Hmou);
  If (R = NO_ERROR) And (PButtons = 0) Then R := ERROR_MOUSE_INV_PARMS;
  If R = NO_ERROR Then
  Begin
    B := RdL(PButtons);
    If (B And Not 7) <> 0 Then R := ERROR_MOUSE_INV_PARMS Else HotKey := B;
  End;
  MouSetHotKey := R;
End;

{ ---------------------------------------------------------------------
  MouSynch(fWait) : acces exclusif du sous-systeme au pilote (fWait 0
  sans attente, 1 avec attente) ; un seul processus leger s'execute dans
  OS/2-0, l'acces est toujours accorde }
Function MouSynch(FWait : LongInt) : LongInt;
Begin
  If (FWait <> 0) And (FWait <> 1) Then MouSynch := ERROR_MOUSE_INV_PARMS
  Else
  Begin
    Poll;
    MouSynch := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  MouInitReal(pszDvrName) : pilote de dessin du pointeur pour les
  programmes DOS en mode reel ("POINTER$" ou 0) ; memorise }
Function MouInitReal(PDrv : LongInt) : LongInt;
Var S : String;
Begin
  If Hooked(MB_INITREAL, 1, PDrv, 0, 0) Then
  Begin
    MouInitReal := HookRet;
    Exit;
  End;
  S := GetZ(PDrv);
  If (S <> '') And (S <> 'POINTER$') Then MouInitReal := ERROR_MOUSE_INV_MODULE
  Else
  Begin
    If S = '' Then RealDrv := 'POINTER$' Else RealDrv := S;
    MouInitReal := NO_ERROR;
  End;
End;

{ Valeurs par defaut de la session }
Procedure ResetSession;
Begin
  HidePtr;
  RowScale := 16; ColScale := 8;
  Lev1 := 4; Mult1 := 1; Lev2 := 12; Mult2 := 1;
  EvMask := $7F;
  DevStatus := 0;
  HotKey := 0;
  AndMask := $FFFF; XorMask := $7700;
  DrawOn := False;
  ExclOn := False;
  PosY := RowPos(MaxRows Div 2);
  PosX := ColPos(MaxCols Div 2);
  QHead := 0; QCount := 0;
End;

{ ---------------------------------------------------------------------
  MouShellInit : initialiser la souris pour l'interpreteur de commandes
  (valeurs par defaut de la session : masque, echelle, seuils, forme,
  pointeur au centre de l'ecran et non dessine) }
Function MouShellInit : LongInt;
Begin
  Poll;
  ResetSession;
  MouShellInit := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  MouFree(usReserved) : liberer la souris : les ouvertures du processus
  sont fermees (le pointeur disparait s'il n'en reste aucune) }
Function MouFree(Reserved : LongInt) : LongInt;
Var I, Pid : LongInt;
Begin
  Pid := MyPid;
  For I := 1 To MaxH Do
    If HUsed[I] And (HPid[I] = Pid) Then
    Begin
      HUsed[I] := False;
      Dec(OpenCount);
    End;
  If OpenCount <= 0 Then
  Begin
    OpenCount := 0;
    HidePtr;
    DrawOn := False;
  End;
  MouFree := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  MouRegister(pszModName, pszEntryName, flFuns) : remplacer les
  fonctions choisies (bits MR_*) par la fonction pszEntryName du module
  pszModName (voir l'en-tete) }
Function MouRegister(PMod, PEntry, Funs : LongInt) : LongInt;
Var R, H, E : LongInt;
Begin
  R := NO_ERROR;
  If RegEntry <> 0 Then R := ERROR_MOUSE_REGISTER
  Else If (PMod = 0) Or (PEntry = 0) Then R := ERROR_MOUSE_INVALID_ASCIIZ
  Else If (Funs = 0) Or ((Funs And Not $1FFFFF) <> 0) Then R := ERROR_MOUSE_INVALID_MASK
  Else
  Begin
    E := 0;
    If DosLoadModule(LongInt(@FailName), 64, PMod, LongInt(@H)) <> NO_ERROR Then R := ERROR_MOUSE_INV_MODULE
    Else If (DosQueryProcAddr(H, 0, PEntry, LongInt(@E)) <> NO_ERROR) Or (E = 0) Then
      R := ERROR_MOUSE_INV_ENTRY_PT;
    If R = NO_ERROR Then
    Begin
      RegEntry := E;
      RegFuns := Funs;
    End;
  End;
  MouRegister := R;
End;

{ ---------------------------------------------------------------------
  MouDeRegister : retirer le remplacement }
Function MouDeRegister : LongInt;
Begin
  If RegEntry = 0 Then MouDeRegister := ERROR_MOUSE_DEREGISTER
  Else
  Begin
    RegEntry := 0;
    RegFuns := 0;
    MouDeRegister := NO_ERROR;
  End;
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  MouGetPtrShape Index 1, MouSetPtrShape Index 2, MouGetNumMickeys Index 3,
  MouGetHotKey Index 4, MouShellInit Index 5, MouGetScaleFact Index 6,
  MouFlushQue Index 7, MouGetNumButtons Index 8, MouClose Index 9,
  MouSetHotKey Index 10, MouSetScaleFact Index 11, MouFree Index 12,
  MouGetNumQueEl Index 13, MouDeRegister Index 14, MouGetEventMask Index 15,
  MouSetEventMask Index 16, MouOpen Index 17, MouRemovePtr Index 18,
  MouGetPtrPos Index 19, MouReadEventQue Index 20, MouSetPtrPos Index 21,
  MouGetDevStatus Index 22, MouSynch Index 23, MouRegister Index 24,
  MouSetDevStatus Index 25, MouDrawPtr Index 26, MouInitReal Index 27,
  MouGetThreshold Index 29, MouSetThreshold Index 30;

Var
  InitI : LongInt;

BEGIN
  VbFn := 0;
  For InitI := 1 To MaxH Do HUsed[InitI] := False;
  OpenCount := 0;
  Shown := False;
  RegEntry := 0; RegFuns := 0;
  InHook := False;
  Buttons := 0;
  Lost := 0;
  RealDrv := 'POINTER$';
  Present := KrnMouInfo(LongInt(@InfoK)) <> 0;
  NumButtons := InfoK[1];
  Mickeys := InfoK[3];
  If NumButtons = 0 Then NumButtons := 3;
  If Mickeys = 0 Then Mickeys := 40;
  ResetSession;
END.
