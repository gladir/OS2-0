{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote VBOXGST.DLL de OS/2-0 : peripherique d'integration
                de VirtualBox (VMMDev) - souris integree, taille de l'ecran.
}

Library VBOXGST;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC VBOXGST.PAS   (produit VBOXGST.DLL)

  Le "VirtualBox Guest Service" (peripherique PCI 80EEh:CAFEh, VMMDev)
  est le lien entre une machine virtuelle de VirtualBox et l'hote.
  VBOXGST.DLL le programme pour OS/2-0, comme le pilote VBoxGuest des
  Additions invitee :
    - il se presente a l'hote (ReportGuestInfo, ReportGuestInfo2 avec la
      version de l'hote, ReportGuestStatus : pilote actif) et annonce
      qu'il sait changer la taille de l'ecran (SetGuestCapabilities :
      VMMDEV_GUEST_SUPPORTS_GRAPHICS) ;
    - souris integree : il annonce la souris absolue
      (VMMDEV_MOUSE_GUEST_CAN_ABSOLUTE) ; quand l'hote la veut, la
      position absolue (0 a 65535) est lue a chaque paquet de la souris
      PS/2 (MOUCALLS.DLL) et le pointeur de l'hote est cache au-dessus de
      la machine (SetPointerShape invisible) : un seul pointeur, celui
      d'OS/2-0, toujours sous la souris de l'hote ;
    - taille de l'ecran : les demandes de l'hote (redimensionnement de la
      fenetre, "Ajuster automatiquement la taille de l'ecran", menu Ecran
      virtuel) sont lues par GetDisplayChangeRequest2 ; PMWIN.DLL passe
      alors l'ecran a cette taille (adaptateur VBE DISPI de VirtualBox).
  Les requetes sont des blocs en memoire (en-tete de 24 octets : taille,
  version 10001h, type, code de retour) dont l'adresse physique est
  ecrite dans le port d'entree-sortie du peripherique (BAR0) ; les
  evenements de l'hote sont lus par AcknowledgeEvents (sans
  interruption).

  Point d'entree unique VBOXGUESTREQUEST (ordinal 1), paquet de LongInt :
    +0 commande, +4.. resultats ; la fonction rend 1 (vrai) ou 0 :
    1 INITIALISER   : 1 si le peripherique est la (une seule fois)
    2 SOURIS        : 1 si la souris est absolue : +4 x, +8 y (0..65535)
    3 ECRAN         : 1 si l'hote demande une nouvelle taille : +4
                      largeur, +8 hauteur, +12 bits par pel (0 : garder)
    4 DESCRIPTION   : +4 tampon, +8 taille : texte (gestionnaire de
                      peripheriques) ; rend les possibilites
    5 VERSION       : +4 version de l'hote (majeure * 65536 + mineure),
                      +8 revision }

Const
  VMMDEV_VERSION = $00010004;
  HDR_VERSION = $10001;
  REQ_GETMOUSE = 1; REQ_SETMOUSE = 2; REQ_SETPOINTER = 3; REQ_HOSTVERSION = 4; REQ_ACKEVENTS = 41;
  REQ_FILTERMASK = 42; REQ_GUESTINFO = 50; REQ_DISPLAY = 51; REQ_DISPLAY2 = 54; REQ_REPORTCAPS = 55;
  REQ_SETCAPS = 56; REQ_GUESTINFO2 = 58; REQ_GUESTSTATUS = 59;
  EV_MOUSE_CAPS = $001; EV_DISPLAY = $004; EV_MOUSE_POS = $200;
  MOUSE_GUEST_CAN_ABSOLUTE = 1; MOUSE_HOST_WANTS_ABSOLUTE = 2;
  CAPS_GRAPHICS = 4;
  OSTYPE_OS2WARP3 = $41000;

Var
  State : LongInt;                     { -1 pas encore vu, 0 absent, 1 present }
  IoPort, MmioBase, PciAddr, PciIrq : LongInt;
  HostMajor, HostMinor, HostBuild, HostRev : LongInt;
  MouseAbs, HostHidden : LongInt;
  DispW, DispH, DispB, DispNew : LongInt;
  ReqMem : Array[0..1023] Of Byte;     { blocs des requetes (memoire basse) }
  Req : LongInt;
  Dummy0 : LongInt;

{ ==================================================================== }
{ Ports et memoire                                                      }
{ ==================================================================== }

Procedure OutL(P, V : LongInt);
Begin
  asm
    mov edx,P
    mov eax,V
    out dx,eax
  end;
End;

Function InL(P : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := 0;
  asm
    mov edx,P
    in eax,dx
    mov R,eax
  end;
  InL := R;
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

Procedure WrB(A, V : LongInt);
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

Function RdW(A : LongInt) : LongInt;
Type PB = ^Byte;
Var Q : PB; V : LongInt;
Begin
  Q := Pointer(A);
  V := Q^;
  Q := Pointer(A + 1);
  RdW := V Or (Q^ Shl 8);
End;

Procedure WrW(A, V : LongInt);
Begin
  WrB(A, V And 255);
  WrB(A + 1, (V Shr 8) And 255);
End;

Function PciRead(A, Reg : LongInt) : LongInt;
Begin
  OutL($CF8, A Or (Reg And $FC));
  PciRead := InL($CFC);
End;

Procedure PciWrite(A, Reg, V : LongInt);
Begin
  OutL($CF8, A Or (Reg And $FC));
  OutL($CFC, V);
End;

Procedure PutStr(A : LongInt; S : String; Max : LongInt);
Var K : LongInt;
Begin
  If Length(S) > Max - 1 Then S := Copy(S, 1, Max - 1);
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function Hex4(V : LongInt) : String;
Var S : String; K, D : LongInt;
Begin
  S := '';
  For K := 3 DownTo 0 Do
  Begin
    D := (V Shr (K * 4)) And 15;
    If D < 10 Then S := S + Chr(48 + D) Else S := S + Chr(55 + D);
  End;
  Hex4 := S;
End;

{ ==================================================================== }
{ Requetes au VMMDev                                                    }
{ ==================================================================== }

{ preparer une requete de Size octets (en-tete compris) }
Procedure NewReq(Typ, Size : LongInt);
Var K : LongInt;
Begin
  For K := 0 To Size - 1 Do WrB(Req + K, 0);
  WrL(Req, Size); WrL(Req + 4, HDR_VERSION); WrL(Req + 8, Typ);
  WrL(Req + 12, -1);
End;

{ envoyer la requete preparee ; rend vrai si son code est un succes }
Function Send : Boolean;
Begin
  OutL(IoPort, Req);
  Send := RdL(Req + 12) >= 0;
End;

Function FindDev : Boolean;
Var Bus, Dev, A, Bar : LongInt;
Begin
  FindDev := False;
  PciAddr := 0;
  For Bus := 0 To 3 Do
    For Dev := 0 To 31 Do
    Begin
      A := $80000000 Or (Bus Shl 16) Or (Dev Shl 11);
      If (PciAddr = 0) And (PciRead(A, 0) = $CAFE80EE) Then PciAddr := A;
    End;
  If PciAddr = 0 Then Exit;
  Bar := PciRead(PciAddr, $10);
  If (Bar And 1) = 0 Then Exit;
  IoPort := Bar And $FFFC;
  MmioBase := PciRead(PciAddr, $14) And $FFFFFFF0;
  PciIrq := PciRead(PciAddr, $3C) And 255;
  { entrees-sorties, memoire et bus maitre }
  PciWrite(PciAddr, 4, PciRead(PciAddr, 4) Or 7);
  FindDev := IoPort <> 0;
End;

Procedure GuestInfo;
Begin
  { 1. qui est l'invite : interface du VMMDev, systeme OS/2 }
  NewReq(REQ_GUESTINFO, 32);
  WrL(Req + 24, VMMDEV_VERSION); WrL(Req + 28, OSTYPE_OS2WARP3);
  Dummy0 := Ord(Send);
  { 2. version de l'hote (les Additions se declarent de la meme version) }
  NewReq(REQ_HOSTVERSION, 40);
  If Send Then
  Begin
    HostMajor := RdW(Req + 24); HostMinor := RdW(Req + 26);
    HostBuild := RdL(Req + 28); HostRev := RdL(Req + 32);
  End;
  NewReq(REQ_GUESTINFO2, 168);
  WrW(Req + 24, HostMajor); WrW(Req + 26, HostMinor);
  WrL(Req + 28, HostBuild); WrL(Req + 32, HostRev);
  WrL(Req + 36, 0);
  PutStr(Req + 40, IStr(HostMajor) + '.' + IStr(HostMinor) + '.' + IStr(HostBuild) + '_OS2-0', 128);
  Dummy0 := Ord(Send);
  { 3. pilote actif (facilite 20 : VBoxGuestDriver, etat 50 : actif),
       et affichage (facilite 1100 : Graphics) }
  NewReq(REQ_GUESTSTATUS, 36);
  WrL(Req + 24, 20); WrL(Req + 28, 50); WrL(Req + 32, 0);
  Dummy0 := Ord(Send);
  NewReq(REQ_GUESTSTATUS, 36);
  WrL(Req + 24, 1100); WrL(Req + 28, 50); WrL(Req + 32, 0);
  Dummy0 := Ord(Send);
End;

Procedure SetupEvents;
Begin
  { evenements voulus : souris, taille de l'ecran }
  NewReq(REQ_FILTERMASK, 32);
  WrL(Req + 24, EV_MOUSE_CAPS Or EV_DISPLAY Or EV_MOUSE_POS); WrL(Req + 28, 0);
  Dummy0 := Ord(Send);
  { l'invite sait changer la taille de son ecran }
  NewReq(REQ_SETCAPS, 32);
  WrL(Req + 24, CAPS_GRAPHICS); WrL(Req + 28, 0);
  If Not Send Then
  Begin
    NewReq(REQ_REPORTCAPS, 28);
    WrL(Req + 24, CAPS_GRAPHICS);
    Dummy0 := Ord(Send);
  End;
  { souris absolue }
  NewReq(REQ_SETMOUSE, 36);
  WrL(Req + 24, MOUSE_GUEST_CAN_ABSOLUTE);
  Dummy0 := Ord(Send);
End;

{ pointeur de l'hote cache : seul celui d'OS/2-0 se voit }
Procedure HideHostPointer;
Begin
  NewReq(REQ_SETPOINTER, 48);
  WrL(Req + 24, 0);                     { ni VISIBLE, ni forme }
  If Send Then HostHidden := 1;
End;

Procedure ReadMouse;
Begin
  NewReq(REQ_GETMOUSE, 36);
  If Send Then
  Begin
    If (RdL(Req + 24) And MOUSE_HOST_WANTS_ABSOLUTE) <> 0 Then
    Begin
      If (MouseAbs = 0) Or (HostHidden = 0) Then HideHostPointer;
      MouseAbs := 1;
    End
    Else MouseAbs := 0;
  End;
End;

{ demande de taille de l'ecran ; Ack : evenement a acquitter }
Procedure ReadDisplay(Ack : LongInt);
Var W, H, B : LongInt;
Begin
  NewReq(REQ_DISPLAY2, 44);
  WrL(Req + 36, Ack);
  If Not Send Then
  Begin
    NewReq(REQ_DISPLAY, 40);
    WrL(Req + 36, Ack);
    If Not Send Then Exit;
  End;
  W := RdL(Req + 24); H := RdL(Req + 28); B := RdL(Req + 32);
  { ecran 0 seulement ; 0 x 0 : aucune demande }
  If (W >= 320) And (H >= 200) And ((W <> DispW) Or (H <> DispH) Or ((B <> 0) And (B <> DispB))) Then
  Begin
    DispW := W; DispH := H; DispB := B;
    DispNew := 1;
  End;
End;

Function Init : Boolean;
Begin
  If State < 0 Then
  Begin
    State := 0;
    Req := (LongInt(@ReqMem) + 15) And Not 15;
    If FindDev Then
    Begin
      GuestInfo;
      SetupEvents;
      ReadMouse;
      { taille demandee avant le demarrage (fenetre deja redimensionnee) }
      ReadDisplay(0);
      State := 1;
    End;
  End;
  Init := State = 1;
End;

{ evenements de l'hote (lus et acquittes) }
Procedure Poll;
Var Ev : LongInt;
Begin
  NewReq(REQ_ACKEVENTS, 28);
  If Not Send Then Exit;
  Ev := RdL(Req + 24);
  If (Ev And EV_MOUSE_CAPS) <> 0 Then ReadMouse;
  If (Ev And EV_DISPLAY) <> 0 Then ReadDisplay(EV_DISPLAY);
End;

Function VBoxGuestRequest(P : LongInt) : LongInt;
Var Cmd : LongInt; S : String;
Begin
  VBoxGuestRequest := 0;
  Cmd := RdL(P);
  If Not Init Then
  Begin
    If Cmd = 4 Then PutStr(RdL(P + 4), 'Absent (pas une machine virtuelle VirtualBox)', RdL(P + 8));
    Exit;
  End;
  Case Cmd Of
    1 : VBoxGuestRequest := 1;
    2 :
      Begin
        If MouseAbs = 0 Then
        Begin
          { l'hote a-t-il active l'integration depuis ? }
          Poll;
          If MouseAbs = 0 Then Exit;
        End;
        NewReq(REQ_GETMOUSE, 36);
        If Not Send Then Exit;
        If (RdL(Req + 24) And MOUSE_HOST_WANTS_ABSOLUTE) = 0 Then
        Begin
          MouseAbs := 0;
          Exit;
        End;
        WrL(P + 4, RdL(Req + 28) And $FFFF); WrL(P + 8, RdL(Req + 32) And $FFFF);
        VBoxGuestRequest := 1;
      End;
    3 :
      Begin
        Poll;
        If DispNew <> 0 Then
        Begin
          DispNew := 0;
          WrL(P + 4, DispW); WrL(P + 8, DispH); WrL(P + 12, DispB);
          VBoxGuestRequest := 1;
        End;
      End;
    4 :
      Begin
        S := 'VirtualBox Guest Service (VMMDev 80EE:CAFE), port ' + Hex4(IoPort) + 'h, IRQ ' + IStr(PciIrq) +
             ' ; hote VirtualBox ' + IStr(HostMajor) + '.' + IStr(HostMinor) + '.' + IStr(HostBuild) +
             ' ; souris ';
        If MouseAbs <> 0 Then S := S + 'integree (absolue)' Else S := S + 'relative';
        S := S + ' ; taille de l''ecran par l''hote';
        PutStr(RdL(P + 4), S, RdL(P + 8));
        VBoxGuestRequest := 1 Or (MouseAbs * 2);
      End;
    5 :
      Begin
        WrL(P + 4, HostMajor * 65536 + HostMinor); WrL(P + 8, HostRev);
        VBoxGuestRequest := 1;
      End;
  End;
End;

Exports
  VBoxGuestRequest Index 1 Name 'VBOXGUESTREQUEST';

BEGIN
  State := -1; MouseAbs := 0; HostHidden := 0; DispW := 0; DispH := 0; DispB := 0; DispNew := 0;
  HostMajor := 0; HostMinor := 0; HostBuild := 0; HostRev := 0;
END.
