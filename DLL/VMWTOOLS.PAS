{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote VMWTOOLS.DLL de OS/2-0 : VMware Tools (VMware
                Workstation, Player, ESXi) - souris absolue, taille de
                l'ecran demandee par l'hote.
}

Library VMWTOOLS;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC VMWTOOLS.PAS   (produit VMWTOOLS.DLL)

  Les "VMware Tools" d'OS/2-0. Tout passe par la porte derobee de VMware
  (port 5658h : EAX = 564D5868h, ECX = commande, EBX = parametre, puis
  IN EAX,DX ; la machine virtuelle repond dans les registres) :
    - GETVERSION (10) : presence de VMware ;
    - souris absolue "vmmouse" (ABSPOINTER_COMMAND 41 : READ_ID puis
      REQUEST_ABSOLUTE ; ABSPOINTER_STATUS 40 : nombre de mots en
      attente ; ABSPOINTER_DATA 39 : etat des boutons, x et y de 0 a 65535,
      molette) : la souris PS/2 n'est plus qu'un signal (MOUCALLS.DLL lit
      la position et les boutons ici) ; le pointeur de l'hote est rendu
      invisible par le curseur materiel transparent de la carte SVGA II
      (VIOCALLS.DLL) : un seul pointeur, celui d'OS/2-0 ;
    - messages (commande 30, protocole "GuestRPC" des VMware Tools) :
      canal RPCI (l'invite parle : "tools.set.version", "tools.capability.
      resolution_set 1"...) et canal TCLO (l'hote commande : "reset",
      "ping", "Capabilities_Register", "Resolution_Set largeur hauteur",
      "Set_Option" ; reponses "OK ..." ou "ERROR ..."), interroge toutes
      les 300 ms par PMWIN.DLL : la taille demandee par l'hote (fenetre
      redimensionnee, "Autofit Guest", plein ecran) est appliquee par
      PMWIN (carte VMware SVGA II, toute resolution).

  Point d'entree unique GUESTREQUEST (ordinal 1), meme paquet que
  VBOXGST.DLL :
    1 INITIALISER   : 1 si la machine est une machine VMware
    2 SOURIS        : 1 si la souris est absolue : +4 x, +8 y (0..65535),
                      +12 boutons (1 gauche, 2 droit, 4 milieu), +16 = 1
                      (boutons fournis)
    3 ECRAN         : 1 si l'hote demande une nouvelle taille : +4 largeur,
                      +8 hauteur, +12 bits par pel (0 : garder)
    4 DESCRIPTION   : +4 tampon, +8 taille
    5 VERSION       : +4 version de la machine virtuelle (porte derobee) }

Const
  BDOOR_MAGIC = $564D5868;
  BDOOR_PORT = $5658;
  CMD_GETVERSION = 10; CMD_ABSDATA = 39; CMD_ABSSTATUS = 40; CMD_ABSCOMMAND = 41; CMD_MESSAGE = 30;
  VMMOUSE_READ_ID = $45414552; VMMOUSE_REQUEST_ABSOLUTE = $53424152; VMMOUSE_VERSION = $3442554A;
  PROTO_RPCI = $49435052; PROTO_TCLO = $4F4C4354;
  ST_SUCCESS = 1; ST_DORECV = 2;

Var
  State, VmVersion, VmType : LongInt;
  MouseOn, MouseX, MouseY, MouseB, MouseErr : LongInt;
  { canal TCLO (commandes de l'hote) : ouvert, numero, temoins }
  TcloOpen, TcloCh, TcloSi, TcloDi : LongInt;
  Reply : String;
  ResW, ResH, ResNew, Pings, LastCmd : LongInt;
  { registres de la porte derobee }
  RA, RB, RC, RD, RS, RDI : LongInt;
  MsgBuf : Array[0..1023] Of Byte;
  MsgLen : LongInt;
  Dummy0 : LongInt;

{ ==================================================================== }
{ Porte derobee                                                         }
{ ==================================================================== }

{ appel : Cmd (ECX), Bx (EBX), Dx haut (EDX, numero de canal), Si, Di ;
  resultats dans RA, RB, RC, RD, RS, RDI }
Procedure Bdoor(Cmd, Bx, Ch, Si, Di : LongInt);
Var A, B, C, D, S, I : LongInt;
Begin
  A := BDOOR_MAGIC; B := Bx; C := Cmd; D := (Ch Shl 16) Or BDOOR_PORT; S := Si; I := Di;
  asm
    push ebx
    push esi
    push edi
    mov eax,A
    mov ebx,B
    mov ecx,C
    mov edx,D
    mov esi,S
    mov edi,I
    in eax,dx
    mov A,eax
    mov B,ebx
    mov C,ecx
    mov D,edx
    mov S,esi
    mov I,edi
    pop edi
    pop esi
    pop ebx
  end;
  RA := A; RB := B; RC := C; RD := D; RS := S; RDI := I;
End;

Function Present : Boolean;
Begin
  Bdoor(CMD_GETVERSION, -1, 0, 0, 0);
  Present := (RB = BDOOR_MAGIC) And (RA <> -1);
  VmVersion := RA; VmType := RC;
End;

{ ==================================================================== }
{ Souris absolue (vmmouse)                                              }
{ ==================================================================== }

Function MouseEnable : Boolean;
Begin
  MouseEnable := False;
  Bdoor(CMD_ABSCOMMAND, VMMOUSE_READ_ID, 0, 0, 0);
  Bdoor(CMD_ABSSTATUS, 0, 0, 0, 0);
  If ((RA And $FFFF) = 0) Or ((RA And $FFFF0000) = $FFFF0000) Then Exit;
  Bdoor(CMD_ABSDATA, 1, 0, 0, 0);
  If RA <> VMMOUSE_VERSION Then Exit;
  Bdoor(CMD_ABSCOMMAND, VMMOUSE_REQUEST_ABSOLUTE, 0, 0, 0);
  MouseOn := 1; MouseX := 32768; MouseY := 32768; MouseB := 0;
  MouseEnable := True;
End;

{ vider la file : dernier etat (position et boutons) }
Procedure MouseRead;
Var N, F, K : LongInt;
Begin
  Bdoor(CMD_ABSSTATUS, 0, 0, 0, 0);
  If (RA And $FFFF0000) = $FFFF0000 Then
  Begin
    { erreur de la file : la souris est reactivee }
    Inc(MouseErr);
    MouseOn := 0;
    Dummy0 := Ord(MouseEnable);
    Exit;
  End;
  N := RA And $FFFF;
  K := 0;
  While (N >= 4) And (K < 64) Do
  Begin
    Bdoor(CMD_ABSDATA, 4, 0, 0, 0);
    F := RA;
    MouseX := RB And $FFFF; MouseY := RC And $FFFF;
    MouseB := 0;
    If (F And $20) <> 0 Then MouseB := MouseB Or 1;
    If (F And $10) <> 0 Then MouseB := MouseB Or 2;
    If (F And $08) <> 0 Then MouseB := MouseB Or 4;
    N := N - 4;
    Inc(K);
  End;
End;

{ ==================================================================== }
{ Messages (GuestRPC)                                                   }
{ ==================================================================== }

Function MsgOpen(Proto : LongInt; Var Ch, Si, Di : LongInt) : Boolean;
Begin
  { canal avec temoins (cookies) }
  Bdoor(CMD_MESSAGE Or (0 Shl 16), Proto Or $80000000, 0, 0, 0);
  MsgOpen := ((RC Shr 16) And ST_SUCCESS) <> 0;
  Ch := (RD Shr 16) And $FFFF; Si := RS; Di := RDI;
End;

Procedure MsgClose(Ch, Si, Di : LongInt);
Begin
  Bdoor(CMD_MESSAGE Or (6 Shl 16), 0, Ch, Si, Di);
End;

Function MsgSend(Ch, Si, Di : LongInt; S : String) : Boolean;
Var K, V, J : LongInt;
Begin
  MsgSend := False;
  Bdoor(CMD_MESSAGE Or (1 Shl 16), Length(S), Ch, Si, Di);
  If ((RC Shr 16) And ST_SUCCESS) = 0 Then Exit;
  K := 1;
  While K <= Length(S) Do
  Begin
    V := 0;
    For J := 0 To 3 Do
      If K + J <= Length(S) Then V := V Or (Ord(S[K + J]) Shl (J * 8));
    Bdoor(CMD_MESSAGE Or (2 Shl 16), V, Ch, Si, Di);
    If ((RC Shr 16) And ST_SUCCESS) = 0 Then Exit;
    K := K + 4;
  End;
  MsgSend := True;
End;

{ message recu dans MsgBuf (MsgLen octets ; 0 : aucun) }
Function MsgRecv(Ch, Si, Di : LongInt) : Boolean;
Var Size, K, V, J : LongInt;
Begin
  MsgRecv := False;
  MsgLen := 0;
  Bdoor(CMD_MESSAGE Or (3 Shl 16), 0, Ch, Si, Di);
  If ((RC Shr 16) And ST_SUCCESS) = 0 Then Exit;
  If ((RC Shr 16) And ST_DORECV) = 0 Then
  Begin
    MsgRecv := True;
    Exit;
  End;
  Size := RB;
  K := 0;
  While K < Size Do
  Begin
    Bdoor(CMD_MESSAGE Or (4 Shl 16), ST_SUCCESS, Ch, Si, Di);
    If ((RC Shr 16) And ST_SUCCESS) = 0 Then Exit;
    V := RB;
    For J := 0 To 3 Do
      If (K + J < Size) And (K + J < 1024) Then MsgBuf[K + J] := (V Shr (J * 8)) And 255;
    K := K + 4;
  End;
  If Size > 1024 Then Size := 1024;
  MsgLen := Size;
  Bdoor(CMD_MESSAGE Or (5 Shl 16), ST_SUCCESS, Ch, Si, Di);
  MsgRecv := True;
End;

Function MsgText : String;
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 0 To MsgLen - 1 Do
    If (K < 250) And (MsgBuf[K] <> 0) Then S := S + Chr(MsgBuf[K]);
  MsgText := S;
End;

{ un message de l'invite a l'hote (canal RPCI) ; rend la reponse }
Function Rpci(S : String) : String;
Var Ch, Si, Di : LongInt;
Begin
  Rpci := '';
  If Not MsgOpen(PROTO_RPCI, Ch, Si, Di) Then Exit;
  If MsgSend(Ch, Si, Di, S) Then
    If MsgRecv(Ch, Si, Di) Then Rpci := MsgText;
  MsgClose(Ch, Si, Di);
End;

Procedure Capabilities;
Begin
  Dummy0 := Length(Rpci('tools.capability.resolution_set 1'));
  Dummy0 := Length(Rpci('tools.capability.resolution_server toolbox 1'));
  Dummy0 := Length(Rpci('tools.capability.resolution_min 640 480'));
End;

Function NumAt(S : String; Var K : LongInt) : LongInt;
Var V : LongInt;
Begin
  While (K <= Length(S)) And (S[K] = ' ') Do Inc(K);
  V := 0;
  While (K <= Length(S)) And (S[K] >= '0') And (S[K] <= '9') Do
  Begin
    V := V * 10 + Ord(S[K]) - 48;
    Inc(K);
  End;
  NumAt := V;
End;

{ une commande de l'hote ; rend la reponse }
Function Command(C : String) : String;
Var K, W, H : LongInt; U : String;
Begin
  U := C;
  For K := 1 To Length(U) Do U[K] := UpCase(U[K]);
  If U = 'RESET' Then Command := 'OK ATR toolbox'
  Else If U = 'PING' Then
  Begin
    Inc(Pings);
    Command := 'OK ';
  End
  Else If U = 'CAPABILITIES_REGISTER' Then
  Begin
    Capabilities;
    Command := 'OK ';
  End
  Else If Copy(U, 1, 15) = 'RESOLUTION_SET ' Then
  Begin
    K := 16;
    W := NumAt(C, K); H := NumAt(C, K);
    If (W >= 320) And (H >= 200) Then
    Begin
      ResW := W; ResH := H; ResNew := 1;
    End;
    Command := 'OK ';
  End
  Else If Copy(U, 1, 11) = 'SET_OPTION ' Then Command := 'OK '
  Else Command := 'ERROR Unknown command';
End;

{ canal TCLO : envoyer la reponse precedente, recevoir la commande
  suivante (quelques-unes a chaque appel) }
Procedure TcloPoll;
Var N : LongInt; C : String;
Begin
  If TcloOpen = 0 Then
  Begin
    If Not MsgOpen(PROTO_TCLO, TcloCh, TcloSi, TcloDi) Then Exit;
    TcloOpen := 1;
    Reply := '';
  End;
  N := 0;
  Repeat
    If Not MsgSend(TcloCh, TcloSi, TcloDi, Reply) Then
    Begin
      MsgClose(TcloCh, TcloSi, TcloDi);
      TcloOpen := 0;
      Exit;
    End;
    Reply := '';
    If Not MsgRecv(TcloCh, TcloSi, TcloDi) Then
    Begin
      MsgClose(TcloCh, TcloSi, TcloDi);
      TcloOpen := 0;
      Exit;
    End;
    If MsgLen > 0 Then
    Begin
      C := MsgText;
      Reply := Command(C);
      Inc(LastCmd);
    End;
    Inc(N);
  Until (MsgLen = 0) Or (N >= 8);
End;

Function Init : Boolean;
Begin
  If State < 0 Then
  Begin
    State := 0;
    If Present Then
    Begin
      State := 1;
      Dummy0 := Ord(MouseEnable);
      { les Tools se presentent (version "non geree" : 2147483647) }
      Dummy0 := Length(Rpci('tools.set.version 2147483647'));
      Capabilities;
      TcloPoll;
    End;
  End;
  Init := State = 1;
End;

Function PutStr(A : LongInt; S : String; Max : LongInt) : LongInt;
Type PB = ^Byte;
Var K : LongInt; Q : PB;
Begin
  If Length(S) > Max - 1 Then S := Copy(S, 1, Max - 1);
  For K := 1 To Length(S) Do
  Begin
    Q := Pointer(A + K - 1);
    Q^ := Ord(S[K]);
  End;
  Q := Pointer(A + Length(S));
  Q^ := 0;
  PutStr := Length(S);
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

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function GuestRequest(P : LongInt) : LongInt;
Var Cmd : LongInt; S : String;
Begin
  GuestRequest := 0;
  Cmd := RdL(P);
  If Not Init Then
  Begin
    If Cmd = 4 Then Dummy0 := PutStr(RdL(P + 4), 'Absent (pas une machine virtuelle VMware)', RdL(P + 8));
    Exit;
  End;
  Case Cmd Of
    1 : GuestRequest := 1;
    2 :
      Begin
        If MouseOn = 0 Then
        Begin
          If Not MouseEnable Then Exit;
        End;
        MouseRead;
        If MouseOn = 0 Then Exit;
        WrL(P + 4, MouseX); WrL(P + 8, MouseY); WrL(P + 12, MouseB); WrL(P + 16, 1);
        GuestRequest := 1;
      End;
    3 :
      Begin
        TcloPoll;
        If ResNew <> 0 Then
        Begin
          ResNew := 0;
          WrL(P + 4, ResW); WrL(P + 8, ResH); WrL(P + 12, 32);
          GuestRequest := 1;
        End;
      End;
    4 :
      Begin
        S := 'VMware Tools d''OS/2-0 (porte derobee 5658h, machine virtuelle version ' + IStr(VmVersion) + ') ; souris ';
        If MouseOn <> 0 Then S := S + 'absolue (vmmouse)' Else S := S + 'relative';
        If TcloOpen <> 0 Then S := S + ' ; canal des Tools ouvert (' + IStr(LastCmd) + ' commandes de l''hote)'
        Else S := S + ' ; canal des Tools ferme';
        Dummy0 := PutStr(RdL(P + 4), S, RdL(P + 8));
        GuestRequest := 1 Or (MouseOn * 2);
      End;
    5 :
      Begin
        WrL(P + 4, VmVersion); WrL(P + 8, VmType);
        GuestRequest := 1;
      End;
  End;
End;

Exports
  GuestRequest Index 1 Name 'GUESTREQUEST';

BEGIN
  State := -1; MouseOn := 0; MouseErr := 0; TcloOpen := 0; ResNew := 0; Pings := 0; LastCmd := 0;
  Reply := '';
END.
