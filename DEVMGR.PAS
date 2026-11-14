{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: DEVMGR - Gestionnaire de peripheriques (materiel et
                pilotes) du Presentation Manager d'OS/2-0.
}

Program DEVMGR;

{$R-,S-,I-}

{ Compilation : OS2PC DEVMGR.PAS   (produit DEVMGR.EXE)

  Le Gestionnaire de peripheriques (comme le "Gestionnaire de materiel"
  de Warp 4 et l'outil RMVIEW) : la liste du materiel par categorie
  (Affichage, Reseau, Multimedia, Stockage, Entree, Ports, Systeme,
  Ponts, Bus serie), avec pour chacun ses ressources (identificateur PCI,
  ports, memoire, IRQ), son pilote d'OS/2-0 et son etat. Sources : le bus
  PCI (configuration par les ports CF8h/CFCh), la zone de donnees du BIOS
  (ports serie et parallele), les disques du noyau (KrnDiskCtl) et les
  pilotes eux-memes : VBOXGST.DLL (VirtualBox), E1000.DLL et PCNET.DLL
  (reseau), MDM.DLL (son), VIOCALLS.DLL (affichage).
  Souris ou fleches : choisir un peripherique ; F5 : actualiser. }

Const
  WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_CLOSE = $0029; WM_QUIT = $002A;
  WM_BUTTON1DOWN = $0071; WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_MINBUTTON = $10; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MB_OK = 0; MB_INFORMATION = $30; MB_MOVEABLE = $4000;
  KC_VIRTUALKEY = 2; KC_KEYUP = $40;
  VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14; VK_UP = $16; VK_DOWN = $18; VK_F1 = $20;
  VK_F5 = $24;
  CLR_WHITE = -2; CLR_BLACK = -1; CLR_BLUE = 1; CLR_RED = 2; CLR_GREEN = 4; CLR_CYAN = 5; CLR_YELLOW = 6;
  CLR_DARKGRAY = 8; CLR_DARKBLUE = 9; CLR_DARKRED = 10; CLR_DARKGREEN = 12; CLR_DARKCYAN = 13; CLR_BROWN = 14;
  CLR_PALEGRAY = 15;
  DRO_FILL = 1; DRO_OUTLINE = 2;
  CM_REFRESH = 101; CM_QUIT = 102; CM_HELP = 201; CM_ABOUT = 202;
  MAXD = 64;
  ROWH = 16;
  { categories }
  NCAT = 10;

Var
  Hab, Hmq, Frame, Client, Dummy, CW, CH, Hps : LongInt;
  { peripheriques }
  NDev : LongInt;
  DCat, DOk : Array[0..MAXD - 1] Of LongInt;
  DName : Array[0..MAXD - 1] Of String[60];
  DRes : Array[0..MAXD - 1] Of String[120];
  DDrv : Array[0..MAXD - 1] Of String[60];
  DInfo : Array[0..MAXD - 1] Of String[200];
  { lignes affichees : -1 - categorie, sinon numero du peripherique }
  NRow : LongInt;
  RowDev : Array[0..MAXD + NCAT - 1] Of LongInt;
  Sel, Top : LongInt;
  IsVBox, VbFn, NetFn : LongInt;
  NameZ, NameZ2, TxtBuf, FailBuf : Array[0..511] Of Byte;
  MenuT : Array[0..1023] Of Byte;
  MenuLen : LongInt;
  Qmsg : Array[0..7] Of LongInt;
  Pk : Array[0..15] Of LongInt;

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
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiBox(Hps, Fl, P, H, V : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function DosLoadModule(PObj, Cb, PName, PH : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(P, Lev, Buf, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function KDisk(Op, P1, P2 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnDiskCtl';

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function RdB(A : LongInt) : LongInt;
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  RdB := Q^;
End;

Procedure WrB(A, V : LongInt);
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
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
  S := '';
  K := 0;
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

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function HexN(V, N : LongInt) : String;
Var S : String; K, D : LongInt;
Begin
  S := '';
  For K := N - 1 DownTo 0 Do
  Begin
    D := (V Shr (K * 4)) And 15;
    If D < 10 Then S := S + Chr(48 + D) Else S := S + Chr(55 + D);
  End;
  HexN := S;
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

Function PciRead(A, R : LongInt) : LongInt;
Begin
  OutL($CF8, A Or (R And $FC));
  PciRead := InL($CFC);
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

Function FileExists(S : String) : Boolean;
Var Info : Array[0..63] Of Byte;
Begin
  FileExists := DosQueryPathInfo(Z(S), 1, LongInt(@Info), 64) = 0;
End;

{ point d'entree 1 d'une DLL de pilote (0 : absente) }
Function DrvEntry(N : String) : LongInt;
Var H, F : LongInt;
Begin
  DrvEntry := 0;
  H := 0; F := 0;
  If DosLoadModule(LongInt(@FailBuf), 128, Z(N), LongInt(@H)) <> 0 Then Exit;
  If DosQueryProcAddr(H, 1, 0, LongInt(@F)) <> 0 Then F := 0;
  DrvEntry := F;
End;

Function CatName(C : LongInt) : String;
Begin
  Case C Of
    0 : CatName := 'Affichage';
    1 : CatName := 'Reseau';
    2 : CatName := 'Multimedia';
    3 : CatName := 'Stockage';
    4 : CatName := 'Entree (clavier et souris)';
    5 : CatName := 'Ports';
    6 : CatName := 'Peripheriques systeme';
    7 : CatName := 'Ponts et bus PCI';
    8 : CatName := 'Bus serie (USB)';
  Else
    CatName := 'Autres';
  End;
End;

{ carte son de MDM.DLL (chargee a la demande : le composant Multimedia
  peut manquer) ; rend les possibilites, texte dans TxtBuf }
Function MdmAudioInfo(PBuf, Len : LongInt) : LongInt;
Var H, F, R : LongInt;
Begin
  MdmAudioInfo := 0;
  PutZ(PBuf, '');
  H := 0; F := 0;
  If DosLoadModule(LongInt(@FailBuf), 128, Z('MDM'), LongInt(@H)) <> 0 Then Exit;
  If (DosQueryProcAddr(H, 0, Z('MDMAUDIOINFO'), LongInt(@F)) <> 0) Or (F = 0) Then Exit;
  asm
    push ebx
    push esi
    push edi
    mov eax,PBuf
    push eax
    mov eax,Len
    push eax
    mov eax,F
    call eax
    add esp,8
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  MdmAudioInfo := R;
End;

{ ==================================================================== }
{ Recensement du materiel                                               }
{ ==================================================================== }

Procedure AddDev(Cat : LongInt; Name, Res, Drv, Info : String; Ok : LongInt);
Begin
  If NDev >= MAXD Then Exit;
  DCat[NDev] := Cat; DName[NDev] := Name; DRes[NDev] := Res; DDrv[NDev] := Drv; DInfo[NDev] := Info;
  DOk[NDev] := Ok;
  Inc(NDev);
End;

{ nom d'un appareil PCI connu }
Function PciName(Id : LongInt; Var Cat : LongInt) : String;
Var V, D : LongInt;
Begin
  V := Id And $FFFF; D := (Id Shr 16) And $FFFF;
  PciName := '';
  Case V Of
    $80EE :
      Case D Of
        $CAFE : PciName := 'VirtualBox Guest Service (VMMDev)';
        $BEEF : PciName := 'Adaptateur graphique VirtualBox (VBoxVGA)';
        $0021 : PciName := 'Controleur USB VirtualBox';
      End;
    $15AD :
      If D = $0405 Then PciName := 'Adaptateur graphique VMware SVGA II (VirtualBox VMSVGA)';
    $1234 :
      If D = $1111 Then PciName := 'Adaptateur graphique standard (QEMU, Bochs : VBE DISPI)';
    $1B36 :
      If D = $0100 Then PciName := 'Adaptateur graphique QXL' Else If D = $000D Then PciName := 'Controleur USB xHCI (QEMU)';
    $1AF4 :
      If D = $1000 Then PciName := 'Carte reseau virtio' Else If D = $1050 Then PciName := 'Adaptateur graphique virtio';
    $1022 :
      If D = $2000 Then PciName := 'AMD PCnet-PCI II / PCnet-FAST III';
    $1274 :
      If D = $5000 Then PciName := 'Ensoniq AudioPCI ES1370';
    $106B :
      If D = $003F Then PciName := 'Controleur USB OHCI (VirtualBox)';
    $8086 :
      Case D Of
        $1237 : PciName := 'Pont hote Intel 440FX (PCI)';
        $7000 : PciName := 'Pont PCI-ISA Intel PIIX3';
        $7010 : PciName := 'Controleur IDE Intel PIIX3';
        $7020 : PciName := 'Controleur USB Intel PIIX3 (UHCI)';
        $7110 : PciName := 'Pont PCI-ISA Intel PIIX4';
        $7111 : PciName := 'Controleur IDE Intel PIIX4';
        $7112 : PciName := 'Controleur USB Intel PIIX4 (UHCI)';
        $7113 : PciName := 'Controleur ACPI Intel PIIX4';
        $27B9 : PciName := 'Pont LPC Intel ICH7';
        $2918 : PciName := 'Pont LPC Intel ICH9';
        $29C0 : PciName := 'Pont hote Intel Q35';
        $2922 : PciName := 'Controleur SATA AHCI Intel ICH9';
        $2829 : PciName := 'Controleur SATA AHCI Intel ICH8M';
        $2930 : PciName := 'Controleur SMBus Intel ICH9';
        $265C : PciName := 'Controleur USB 2.0 Intel ICH6 (EHCI)';
        $24CD : PciName := 'Controleur USB 2.0 Intel ICH4 (EHCI)';
        $2415 : PciName := 'Intel 82801AA AC''97 Audio';
        $2668 : PciName := 'Intel ICH6 High Definition Audio';
        $293E : PciName := 'Intel ICH9 High Definition Audio';
        $100E : PciName := 'Intel PRO/1000 MT Desktop (82540EM)';
        $1004 : PciName := 'Intel PRO/1000 T Server (82543GC)';
        $100F : PciName := 'Intel PRO/1000 MT Server (82545EM)';
        $10D3 : PciName := 'Intel 82574L Gigabit';
      End;
  End;
End;

Function PciClass(Cls : LongInt; Var Cat : LongInt) : String;
Var B, S : LongInt;
Begin
  B := (Cls Shr 16) And 255; S := (Cls Shr 8) And 255;
  Cat := 9;
  Case B Of
    1 :
      Begin
        Cat := 3;
        If S = 1 Then PciClass := 'Controleur IDE' Else If S = 6 Then PciClass := 'Controleur SATA'
        Else PciClass := 'Controleur de stockage';
      End;
    2 :
      Begin
        Cat := 1; PciClass := 'Carte reseau';
      End;
    3 :
      Begin
        Cat := 0; PciClass := 'Adaptateur graphique';
      End;
    4 :
      Begin
        Cat := 2; PciClass := 'Peripherique multimedia';
      End;
    6 :
      Begin
        Cat := 7; PciClass := 'Pont';
      End;
    8 :
      Begin
        Cat := 6; PciClass := 'Peripherique systeme';
      End;
    $0C :
      Begin
        If S = 3 Then
        Begin
          Cat := 8; PciClass := 'Controleur USB';
        End
        Else
        Begin
          Cat := 6; PciClass := 'Controleur de bus serie';
        End;
      End;
  Else
    PciClass := 'Peripherique PCI (classe ' + HexN(B, 2) + 'h)';
  End;
End;

{ ressources : barres d'adresses et IRQ }
Function PciRes(A, Id : LongInt) : String;
Var K, B, S, Irq : LongInt;
Begin
  S := 'PCI ' + HexN(Id And $FFFF, 4) + ':' + HexN((Id Shr 16) And $FFFF, 4) + ', bus ' + IStr((A Shr 16) And 255) +
       ' appareil ' + IStr((A Shr 11) And 31) + ' fonction ' + IStr((A Shr 8) And 7);
  For K := 0 To 5 Do
  Begin
    B := PciRead(A, $10 + K * 4);
    If (B <> 0) And (B <> -1) Then
    Begin
      If (B And 1) <> 0 Then S := S + ', ports ' + HexN(B And $FFFC, 4) + 'h'
      Else If (B And $FFFFFFF0) <> 0 Then S := S + ', memoire ' + HexN(B And $FFFFFFF0, 8) + 'h';
    End;
  End;
  Irq := PciRead(A, $3C) And 255;
  If (Irq > 0) And (Irq < 255) Then S := S + ', IRQ ' + IStr(Irq);
  PciRes := S;
End;

Procedure ScanPci;
Var Bus, Dev, Fn, A, Id, Cls, Cat, Cc, NFn, Ok : LongInt; Name, Drv, Info, Cn : String;
Begin
  For Bus := 0 To 7 Do
    For Dev := 0 To 31 Do
    Begin
      NFn := 1;
      For Fn := 0 To 7 Do
        If Fn < NFn Then
        Begin
          A := $80000000 Or (Bus Shl 16) Or (Dev Shl 11) Or (Fn Shl 8);
          Id := PciRead(A, 0);
          If (Id <> -1) And ((Id And $FFFF) <> $FFFF) And (Id <> 0) Then
          Begin
            If (Fn = 0) And ((PciRead(A, $0C) And $00800000) <> 0) Then NFn := 8;
            Cls := PciRead(A, 8);
            Cn := PciClass(Cls, Cat);
            Name := PciName(Id, Cc);
            If Name = '' Then Name := Cn;
            Drv := 'Aucun pilote'; Info := ''; Ok := 0;
            Cc := (Cls Shr 16) And 255;
            If (Id And $FFFF) = $80EE Then IsVBox := 1;
            If Id = $CAFE80EE Then
            Begin
              Drv := 'VBOXGST.DLL (Additions VirtualBox d''OS/2-0)';
              If VbFn <> 0 Then
              Begin
                Pk[0] := 4; Pk[1] := LongInt(@TxtBuf); Pk[2] := 200;
                If CallPtr1(VbFn, LongInt(@Pk)) <> 0 Then
                Begin
                  Info := GetZ(LongInt(@TxtBuf));
                  Ok := 1;
                End;
              End;
              If Ok = 0 Then Info := 'VBOXGST.DLL ne repond pas.';
            End
            Else If Cc = 3 Then
            Begin
              Drv := 'VIOCALLS.DLL, PMWIN.DLL';
              Info := 'VGA (640 x 480 x 16 couleurs) et modes VESA du BIOS';
              If ((Id And $FFFF) = $80EE) Or (Id = $11111234) Or (Id = $040515AD) Then
                Info := Info + ' ; interface VBE DISPI : toute resolution (taille choisie par l''hote VirtualBox)';
              Ok := 1;
            End
            Else If Cc = 2 Then
            Begin
              If (Id = $20001022) Or ((Id And $FFFF) = $8086) Then
              Begin
                If Id = $20001022 Then Drv := 'PCNET.DLL' Else Drv := 'E1000.DLL';
                Drv := Drv + ' (pile TCPIP32.DLL)';
                If Id = $20001022 Then NetFn := DrvEntry('PCNET') Else NetFn := DrvEntry('E1000');
                If NetFn <> 0 Then
                Begin
                  Pk[0] := 1;
                  If CallPtr1(NetFn, LongInt(@Pk)) = 0 Then Ok := 1;
                  Pk[0] := 5; Pk[2] := LongInt(@TxtBuf); Pk[3] := 200;
                  Dummy := CallPtr1(NetFn, LongInt(@Pk));
                  Info := GetZ(LongInt(@TxtBuf));
                End
                Else Info := 'Le pilote n''est pas installe.';
              End;
            End
            Else If (Cc = 4) And ((Id = $24158086) Or (Id = $50001274)) Then
            Begin
              If Id = $24158086 Then Drv := 'ICHAUDIO.DLL (MDM.DLL)' Else Drv := 'ESAUDIO.DLL (MDM.DLL)';
              If FileExists('C:\MDM.DLL') Then
              Begin
                Dummy := MdmAudioInfo(LongInt(@TxtBuf), 200);
                Info := 'Carte son utilisee par MDM.DLL : ' + GetZ(LongInt(@TxtBuf));
                Ok := 1;
              End;
            End
            Else If (Cc = 1) And ((Cls Shr 8 And 255) = 1) Then
            Begin
              Drv := 'Pilote IDE du noyau (OS2KRNL), HPFS.IFS';
              Info := 'Disques durs et CD-ROM ATAPI en mode PIO';
              Ok := 1;
            End
            Else If (Cc = 6) Or ((Cc = 8) And (Id <> $CAFE80EE)) Then
            Begin
              Drv := 'Aucun pilote necessaire';
              Ok := 1;
            End;
            AddDev(Cat, Name, PciRes(A, Id), Drv, Info, Ok);
          End;
        End;
    End;
End;

Procedure ScanLegacy;
Var K, P, N : LongInt; Info : Array[0..15] Of LongInt; S : String;
Begin
  AddDev(4, 'Clavier PS/2 (8042)', 'Ports 60h et 64h, IRQ 1', 'Noyau (OS2KRNL), KBDCALLS.DLL', 'Clavier americain (QWERTY)', 1);
  If IsVBox <> 0 Then
  Begin
    S := 'Souris integree (absolue) : le pointeur d''OS/2-0 suit celui de l''hote, qui est cache au-dessus de ' +
         'la machine (un seul pointeur)';
    If VbFn = 0 Then S := 'Additions VirtualBox absentes : souris relative';
    AddDev(4, 'Souris VirtualBox (PS/2 + integration du pointeur)', 'Ports 60h et 64h, IRQ 12',
           'Noyau, MOUCALLS.DLL, VBOXGST.DLL', S, 1);
  End
  Else AddDev(4, 'Souris PS/2', 'Ports 60h et 64h, IRQ 12', 'Noyau (OS2KRNL), MOUCALLS.DLL', '', 1);
  { ports serie et parallele (zone de donnees du BIOS) }
  For K := 0 To 3 Do
  Begin
    P := RdW($400 + K * 2);
    If P <> 0 Then AddDev(5, 'Port serie COM' + IStr(K + 1), 'Ports ' + HexN(P, 4) + 'h', 'Noyau', '', 1);
  End;
  For K := 0 To 2 Do
  Begin
    P := RdW($408 + K * 2);
    If P <> 0 Then
      AddDev(5, 'Port parallele LPT' + IStr(K + 1), 'Ports ' + HexN(P, 4) + 'h', 'Noyau, PMSPL.DLL (imprimante)', '', 1);
  End;
  { disques du noyau }
  N := KDisk(0, 0, 0);
  For K := 0 To N - 1 Do
  Begin
    For P := 0 To 15 Do Info[P] := 0;
    If KDisk(1, K, LongInt(@Info)) <> 0 Then
      AddDev(3, 'Disque dur : ' + GetZ(LongInt(@Info) + 12), 'Port ' + HexN(Info[1], 4) + 'h, ' + IStr(Info[0] Div 2048) +
             ' Mo', 'Pilote IDE du noyau, HPFS.IFS', '', 1);
  End;
  AddDev(3, 'Lecteur de CD-ROM ATAPI', 'IDE', 'Pilote ATAPI du noyau (ISO 9660)', 'Unite C: au demarrage du CD-ROM', 1);
  AddDev(6, 'Minuterie systeme (8254)', 'Ports 40h-43h, IRQ 0', 'Noyau (100 Hz)', '', 1);
  AddDev(6, 'Horloge temps reel (CMOS)', 'Ports 70h-71h', 'Noyau', '', 1);
  AddDev(6, 'Controleur d''interruptions (8259)', 'Ports 20h-21h, A0h-A1h', 'Noyau', '', 1);
  { carte son ISA (Sound Blaster) }
  If FileExists('C:\SBAUDIO.DLL') And FileExists('C:\MDM.DLL') Then
    If MdmAudioInfo(LongInt(@TxtBuf), 200) <> 0 Then
    Begin
      S := GetZ(LongInt(@TxtBuf));
      If Pos('SBAUDIO', S) > 0 Then AddDev(2, 'Carte son Sound Blaster', 'ISA (variable BLASTER)', 'SBAUDIO.DLL (MDM.DLL)', S, 1);
    End;
End;

Procedure BuildRows;
Var C, K : LongInt;
Begin
  NRow := 0;
  For C := 0 To NCAT - 1 Do
  Begin
    K := 0;
    While (K < NDev) And (DCat[K] <> C) Do Inc(K);
    If K < NDev Then
    Begin
      RowDev[NRow] := -1 - C;
      Inc(NRow);
      For K := 0 To NDev - 1 Do
        If DCat[K] = C Then
        Begin
          RowDev[NRow] := K;
          Inc(NRow);
        End;
    End;
  End;
End;

Procedure Scan;
Begin
  NDev := 0; IsVBox := 0;
  VbFn := DrvEntry('VBOXGST');
  If VbFn <> 0 Then
  Begin
    Pk[0] := 1;
    If CallPtr1(VbFn, LongInt(@Pk)) = 0 Then VbFn := 0;
  End;
  ScanPci;
  ScanLegacy;
  BuildRows;
  Sel := -1;
  For Dummy := NRow - 1 DownTo 0 Do
    If RowDev[Dummy] >= 0 Then Sel := Dummy;
  Top := 0;
End;

{ ==================================================================== }
{ Dessin                                                                }
{ ==================================================================== }

Procedure GBox(X1, Y1, X2, Y2, C, Fl : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiBox(Hps, Fl, LongInt(@P), 0, 0);
End;

Procedure GLn(X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := Y2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

{ texte a la ligne Yt (pels depuis le haut) }
Procedure TextT(X, Yt : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(LongInt(@TxtBuf), S);
  Rc[0] := X; Rc[1] := CH - Yt - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Yt;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ icone d'une categorie (16 x 14) au coin haut gauche X, Yt }
Procedure CatIcon(C, X, Yt : LongInt);
Var Y : LongInt;
Begin
  Y := CH - Yt - 14;
  Case C Of
    0 :
      Begin
        GBox(X + 1, Y + 4, X + 14, Y + 13, CLR_DARKBLUE, DRO_FILL);
        GBox(X + 2, Y + 5, X + 13, Y + 12, CLR_CYAN, DRO_FILL);
        GBox(X + 5, Y + 1, X + 10, Y + 3, CLR_DARKGRAY, DRO_FILL);
      End;
    1 :
      Begin
        GBox(X + 1, Y + 5, X + 6, Y + 10, CLR_DARKGREEN, DRO_FILL);
        GBox(X + 9, Y + 5, X + 14, Y + 10, CLR_DARKGREEN, DRO_FILL);
        GLn(X + 6, Y + 7, X + 9, Y + 7, CLR_BLACK);
        GLn(X + 3, Y + 1, X + 12, Y + 1, CLR_BLACK);
      End;
    2 :
      Begin
        GBox(X + 2, Y + 4, X + 6, Y + 9, CLR_DARKGRAY, DRO_FILL);
        GLn(X + 6, Y + 4, X + 10, Y + 1, CLR_BLACK); GLn(X + 6, Y + 9, X + 10, Y + 12, CLR_BLACK);
        GLn(X + 10, Y + 1, X + 10, Y + 12, CLR_BLACK); GLn(X + 13, Y + 4, X + 13, Y + 9, CLR_BLUE);
      End;
    3 :
      Begin
        GBox(X + 1, Y + 3, X + 14, Y + 10, CLR_PALEGRAY, DRO_FILL);
        GBox(X + 1, Y + 3, X + 14, Y + 10, CLR_BLACK, DRO_OUTLINE);
        GBox(X + 11, Y + 5, X + 12, Y + 6, CLR_GREEN, DRO_FILL);
      End;
    4 :
      Begin
        GBox(X + 4, Y + 1, X + 11, Y + 12, CLR_WHITE, DRO_FILL);
        GBox(X + 4, Y + 1, X + 11, Y + 12, CLR_BLACK, DRO_OUTLINE);
        GLn(X + 4, Y + 8, X + 11, Y + 8, CLR_BLACK); GLn(X + 7, Y + 8, X + 7, Y + 12, CLR_BLACK);
      End;
    5 :
      Begin
        GBox(X + 1, Y + 4, X + 14, Y + 9, CLR_BROWN, DRO_FILL);
        GBox(X + 3, Y + 6, X + 4, Y + 7, CLR_YELLOW, DRO_FILL); GBox(X + 7, Y + 6, X + 8, Y + 7, CLR_YELLOW, DRO_FILL);
        GBox(X + 11, Y + 6, X + 12, Y + 7, CLR_YELLOW, DRO_FILL);
      End;
  Else
    Begin
      GBox(X + 2, Y + 2, X + 13, Y + 11, CLR_DARKGREEN, DRO_FILL);
      GLn(X + 4, Y + 5, X + 11, Y + 5, CLR_YELLOW); GLn(X + 4, Y + 8, X + 11, Y + 8, CLR_YELLOW);
    End;
  End;
End;

Function ListW : LongInt;
Begin
  ListW := (CW * 52) Div 100;
End;

Function VisRows : LongInt;
Begin
  VisRows := (CH - 12) Div ROWH;
End;

{ texte coupe en lignes de N caracteres }
Procedure WrapText(X, Yt, N : LongInt; S : String; Fg : LongInt; Var Lines : LongInt);
Var K : LongInt;
Begin
  Lines := 0;
  While S <> '' Do
  Begin
    If Length(S) <= N Then K := Length(S) + 1
    Else
    Begin
      K := N + 1;
      While (K > 1) And (S[K] <> ' ') Do Dec(K);
      If K <= 1 Then K := N + 1;
    End;
    TextT(X, Yt + Lines * 16, Copy(S, 1, K - 1), Fg, CLR_PALEGRAY);
    Delete(S, 1, K);
    Inc(Lines);
  End;
End;

Procedure PaintAll(H : LongInt);
Var Rc : Array[0..3] Of LongInt; R, K, D, Yt, Lw, X, N, L : LongInt; S : String;
Begin
  Hps := WinBeginPaint(H, 0, 0);
  If Hps = 0 Then Exit;
  Dummy := WinQueryWindowRect(H, LongInt(@Rc));
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_PALEGRAY);
  Lw := ListW;
  { liste (fond blanc) }
  Rc[0] := 4; Rc[1] := 4; Rc[2] := Lw; Rc[3] := CH - 4;
  Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_WHITE);
  GBox(3, 3, Lw, CH - 4, CLR_DARKGRAY, DRO_OUTLINE);
  For R := 0 To VisRows - 1 Do
    If Top + R < NRow Then
    Begin
      K := Top + R;
      D := RowDev[K];
      Yt := 6 + R * ROWH;
      If D < 0 Then
      Begin
        CatIcon(-1 - D, 8, Yt);
        TextT(28, Yt, CatName[-1 - D], CLR_DARKBLUE, CLR_WHITE);
      End
      Else
      Begin
        S := DName[D];
        N := (Lw - 50) Div 8;
        If Length(S) > N Then S := Copy(S, 1, N - 1) + '>';
        GLn(16, CH - Yt - 8, 26, CH - Yt - 8, CLR_DARKGRAY);
        If K = Sel Then
        Begin
          Rc[0] := 30; Rc[1] := CH - Yt - 16; Rc[2] := 34 + Length(S) * 8; Rc[3] := CH - Yt;
          Dummy := WinFillRect(Hps, LongInt(@Rc), CLR_DARKBLUE);
          TextT(32, Yt, S, CLR_WHITE, CLR_DARKBLUE);
        End
        Else If DOk[D] = 0 Then TextT(32, Yt, S, CLR_DARKRED, CLR_WHITE)
        Else TextT(32, Yt, S, CLR_BLACK, CLR_WHITE);
      End;
    End;
  { barre de defilement simple }
  If NRow > VisRows Then
  Begin
    GBox(Lw - 6, 5, Lw - 2, CH - 6, CLR_PALEGRAY, DRO_FILL);
    L := MaxI(10, ((CH - 12) * VisRows) Div NRow);
    K := CH - 6 - ((CH - 12 - L) * Top) Div MaxI(1, NRow - VisRows);
    GBox(Lw - 6, K - L, Lw - 2, K, CLR_DARKGRAY, DRO_FILL);
  End;
  { proprietes }
  X := Lw + 12;
  N := (CW - X - 8) Div 8;
  If (Sel >= 0) And (Sel < NRow) And (RowDev[Sel] >= 0) Then
  Begin
    D := RowDev[Sel];
    Yt := 8;
    WrapText(X, Yt, N, DName[D], CLR_DARKBLUE, L);
    Yt := Yt + L * 16 + 8;
    TextT(X, Yt, 'Categorie :', CLR_BLACK, CLR_PALEGRAY);
    TextT(X + 96, Yt, CatName[DCat[D]], CLR_DARKBLUE, CLR_PALEGRAY);
    Yt := Yt + 24;
    TextT(X, Yt, 'Ressources :', CLR_BLACK, CLR_PALEGRAY);
    WrapText(X, Yt + 16, N, DRes[D], CLR_DARKBLUE, L);
    Yt := Yt + 16 + L * 16 + 8;
    TextT(X, Yt, 'Pilote :', CLR_BLACK, CLR_PALEGRAY);
    WrapText(X, Yt + 16, N, DDrv[D], CLR_DARKBLUE, L);
    Yt := Yt + 16 + L * 16 + 8;
    If DInfo[D] <> '' Then
    Begin
      WrapText(X, Yt, N, DInfo[D], CLR_DARKGRAY, L);
      Yt := Yt + L * 16 + 8;
    End;
    TextT(X, Yt, 'Etat :', CLR_BLACK, CLR_PALEGRAY);
    If DOk[D] <> 0 Then WrapText(X, Yt + 16, N, 'Ce peripherique fonctionne correctement.', CLR_DARKGREEN, L)
    Else WrapText(X, Yt + 16, N, 'Aucun pilote d''OS/2-0 n''est charge pour ce peripherique.', CLR_DARKRED, L);
  End;
  If IsVBox <> 0 Then
  Begin
    If VbFn <> 0 Then S := 'Machine virtuelle VirtualBox : Additions d''OS/2-0 actives'
    Else S := 'Machine virtuelle VirtualBox (VBOXGST.DLL absent)';
    WrapText(X, CH - 40, N, S, CLR_DARKBLUE, L);
  End;
  Dummy := WinEndPaint(Hps);
End;

{ ==================================================================== }
{ Fenetre                                                               }
{ ==================================================================== }

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 1);
End;

Procedure ShowSel;
Begin
  If Sel < Top Then Top := Sel;
  If Sel >= Top + VisRows Then Top := Sel - VisRows + 1;
  If Top < 0 Then Top := 0;
  Redraw;
End;

Procedure MoveSel(D : LongInt);
Var K : LongInt;
Begin
  K := Sel;
  Repeat
    K := K + D;
  Until (K < 0) Or (K >= NRow) Or (RowDev[K] >= 0);
  If (K >= 0) And (K < NRow) Then Sel := K;
  ShowSel;
End;

Procedure ShowMsg(T, C : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(T), Z2(C), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure Command(Id : LongInt);
Begin
  Case Id Of
    CM_REFRESH :
      Begin
        Scan;
        Redraw;
      End;
    CM_QUIT : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    CM_HELP : ShowMsg('La liste montre le materiel trouve, par categorie. Choisissez un peripherique (souris ou ' +
                      'fleches) pour voir ses ressources, son pilote et son etat ; en rouge : aucun pilote. F5 : ' +
                      'actualiser.', 'Gestionnaire de peripheriques - Aide');
    CM_ABOUT : ShowMsg('Gestionnaire de peripheriques d''OS/2-0 : bus PCI, peripheriques du BIOS, disques, ' +
                       'pilotes (VirtualBox, reseau, son, affichage). Programme ecrit en Pascal et compile par OS2PC.',
                       'A propos');
  End;
End;

Function MainProc(H, Msg, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt; Yt, R : LongInt;
Begin
  MainProc := 0;
  Case Msg Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
      End;
    WM_PAINT : PaintAll(H);
    WM_BUTTON1DOWN :
      Begin
        Yt := CH - 1 - S16(Mp1 Shr 16);
        If (S16(Mp1) < ListW) And (Yt >= 6) Then
        Begin
          R := Top + (Yt - 6) Div ROWH;
          If (R < NRow) And (RowDev[R] >= 0) Then
          Begin
            Sel := R;
            Redraw;
          End;
        End;
        MainProc := 1;
      End;
    WM_COMMAND : Command(Lo16(Mp1));
    WM_CHAR :
      If ((Lo16(Mp1) And KC_KEYUP) = 0) And ((Lo16(Mp1) And KC_VIRTUALKEY) <> 0) Then
        Case Hi16(Mp2) Of
          VK_UP : MoveSel(-1);
          VK_DOWN : MoveSel(1);
          VK_PAGEUP : MoveSel(-VisRows);
          VK_PAGEDOWN : MoveSel(VisRows);
          VK_HOME : MoveSel(-NRow);
          VK_END : MoveSel(NRow);
          VK_F5 : Command(CM_REFRESH);
          VK_F1 : Command(CM_HELP);
        Else
          MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
        End
      Else MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
    WM_CLOSE : Dummy := WinPostMsg(H, WM_QUIT, 0, 0);
  Else
    MainProc := WinDefWindowProc(H, Msg, Mp1, Mp2);
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
  MenuT[H] := (MenuLen - H) And 255; MenuT[H + 1] := ((MenuLen - H) Shr 8) And 255;
  MenuT[H + 4] := Count And 255; MenuT[H + 5] := 0;
End;

Procedure MItem(Style, Id : LongInt; S : String);
Var K : LongInt;
Begin
  MW(Style); MW(0); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

Var
  Fl, H0, H1, Sw, Sh : LongInt;

BEGIN
  NDev := 0; NRow := 0; Sel := -1; Top := 0; VbFn := 0;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 64);
  Dummy := WinRegisterClass(Hab, Z('DEVMGR'), LongInt(@MainProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_MINBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('DEVMGR'), Z2('Gestionnaire de p'#130'riph'#130'riques'),
                              0, 0, 0, LongInt(@Client));
  MenuLen := 0;
  H0 := MenuOpen;
  MItem(MIS_TEXT Or MIS_SUBMENU, 100, '~Peripheriques');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_REFRESH, '~Actualiser' + Chr(9) + 'F5');
  MItem(MIS_SEPARATOR, 0, '');
  MItem(MIS_TEXT, CM_QUIT, '~Quitter');
  MenuClose(H1, 3);
  MItem(MIS_TEXT Or MIS_SUBMENU, 200, 'A~ide');
  H1 := MenuOpen;
  MItem(MIS_TEXT, CM_HELP, '~Comment utiliser' + Chr(9) + 'F1');
  MItem(MIS_TEXT, CM_ABOUT, '~A propos');
  MenuClose(H1, 2);
  MenuClose(H0, 2);
  Dummy := WinCreateMenu(Frame, LongInt(@MenuT));
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - 620) Div 2), MaxI(0, (Sh - 440) Div 2), MinI(Sw, 620),
                           MinI(Sh, 440), SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Scan;
  Redraw;
  While WinGetMsg(Hab, LongInt(@Qmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@Qmsg));
  Dummy := WinDestroyWindow(Frame);
END.
