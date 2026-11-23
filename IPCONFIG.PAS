{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: IPCONFIG - configuration IP de l'ordinateur, comme la
                commande IPCONFIG de Windows (portee de Pasdows 95).
}

Program IPCONFIG;

{$R-,S-,I-}

{ Compilation : OS2PC IPCONFIG.PAS   (produit IPCONFIG.EXE)

  IPCONFIG [/ALL] [/RENEW]
  Affiche l'adresse IP, le masque de sous-reseau et la passerelle par
  defaut de la carte reseau lan0 ; /ALL ajoute le nom de l'hote, la
  description de la carte, l'adresse physique, le DHCP (serveur, bail) et
  le serveur DNS ; /RENEW refait la configuration (nouvelle demande DHCP).

  Pasdows 95 (Win32) lisait IPHLPAPI.DLL (GetAdaptersInfo et
  GetNetworkParams) ; OS/2-0 lit la pile TCP/IP elle-meme (TCPIP32.DLL,
  point d'entree TCPIPINFO, comme IFCONFIG). La langue suit la variable
  LANGUAGE (EN : anglais). }

Uses DOS;

Function TcpipInfo(P : LongInt) : LongInt; External 'TCPIP32' Name 'TCPIPINFO';
Function TcpipRenew : LongInt; External 'TCPIP32' Name 'TCPIPRENEW';

Var
  Language : (_French, _English);
  TmpLanguage, S, Desc, Mac : String;
  All, Renew : Boolean;
  Info : Array[0..15] Of LongInt;
  Txt : Array[0..255] Of Byte;
  I, K, St : LongInt;

Function StrToUpper(S : String) : String;
Var J : LongInt;
Begin
  For J := 1 To Length(S) Do S[J] := UpCase(S[J]);
  StrToUpper := S;
End;

Function L(Const Fr, En : String) : String;
Begin
  If Language = _English Then L := En Else L := Fr;
End;

Function IpStr(V : LongInt) : String;
Var A, B, C, D : String;
Begin
  Str((V Shr 24) And 255, A); Str((V Shr 16) And 255, B); Str((V Shr 8) And 255, C); Str(V And 255, D);
  IpStr := A + '.' + B + '.' + C + '.' + D;
End;

{ ligne "   Libelle . . . . . . . . : valeur" comme Windows : points dans les
  colonnes impaires (le dernier en 37, parfois colle au libelle comme
  "Physical Address. . ."), deux-points toujours en 39 }
Procedure Row(Const Lbl, V : String);
Var T : String; C : LongInt;
Begin
  T := '   ' + Lbl;
  For C := Length(T) + 1 To 38 Do
    If Odd(C) Then T := T + '.' Else T := T + ' ';
  WriteLn(T, ': ', V);
End;

BEGIN
  Language := _French;
  TmpLanguage := GetEnv('LANGUAGE');
  If StrToUpper(Copy(TmpLanguage, 1, 2)) = 'EN' Then Language := _English;
  All := False; Renew := False;
  For I := 1 To ParamCount Do
  Begin
    S := StrToUpper(ParamStr(I));
    If (S = '/?') Or (S = '-?') Then
    Begin
      WriteLn(L('IPCONFIG : Cette commande affiche la configuration IP de l''ordinateur.',
                'IPCONFIG : Displays the IP configuration of the computer.'));
      WriteLn;
      WriteLn(L('Syntaxe : IPCONFIG [/ALL] [/RENEW]', 'Usage: IPCONFIG [/ALL] [/RENEW]'));
      WriteLn;
      WriteLn(L(' /ALL     Affiche tous les d'#130'tails de la configuration.',
                ' /ALL     Display full configuration information.'));
      WriteLn(L(' /RENEW   Renouvelle l''adresse IP (nouvelle demande DHCP).',
                ' /RENEW   Renew the IP address (new DHCP request).'));
      Halt(0);
    End
    Else If (S = '/ALL') Or (S = '-ALL') Then All := True
    Else If (S = '/RENEW') Or (S = '-RENEW') Then Renew := True
    Else
    Begin
      WriteLn(L('IPCONFIG : option inconnue : ', 'IPCONFIG: unknown option: '), ParamStr(I));
      Halt(1);
    End;
  End;
  If Renew Then
    If TcpipRenew <> 0 Then
      WriteLn(L('IPCONFIG : le serveur DHCP ne r'#130'pond pas.', 'IPCONFIG: the DHCP server does not respond.'));
  WriteLn;
  WriteLn(L('Configuration IP d''OS/2-0', 'OS/2-0 IP Configuration'));
  WriteLn;
  For K := 0 To 15 Do Info[K] := 0;
  For K := 0 To 255 Do Txt[K] := 0;
  Info[10] := LongInt(@Txt); Info[11] := 255;
  St := TcpipInfo(LongInt(@Info));
  If St = 0 Then
  Begin
    WriteLn(L('Aucune carte r'#130'seau : TCP/IP fonctionne seulement en boucle locale (127.0.0.1).',
              'No network adapter: TCP/IP only works on the loopback address (127.0.0.1).'));
    Halt(1);
  End;
  { description de la carte et adresse MAC : "Carte (PILOTE.DLL), MAC aa:bb:..." }
  Desc := '';
  K := 0;
  While (K < 255) And (Txt[K] <> 0) Do
  Begin
    Desc := Desc + Chr(Txt[K]);
    Inc(K);
  End;
  Mac := '';
  K := Pos(', MAC ', Desc);
  If K > 0 Then
  Begin
    Mac := Copy(Desc, K + 6, 17);
    Desc := Copy(Desc, 1, K - 1);
    For K := 1 To Length(Mac) Do
      If Mac[K] = ':' Then Mac[K] := '-' Else Mac[K] := UpCase(Mac[K]);
  End;
  If All Then
  Begin
    S := GetEnv('HOSTNAME');
    If S = '' Then S := 'OS2-0';
    Row(L('Nom de l''h'#147'te', 'Host Name'), S);
    Row(L('Type de noeud', 'Node Type'), L('Diffusion', 'Broadcast'));
    Row(L('Routage IP activ'#130, 'IP Routing Enabled'), L('Non', 'No'));
    WriteLn;
  End;
  WriteLn(L('Carte Ethernet lan0 :', 'Ethernet adapter lan0:'));
  WriteLn;
  If All Then
  Begin
    Row('Description', Desc);
    Row(L('Adresse physique', 'Physical Address'), Mac);
    If Info[5] <> 0 Then Row(L('DHCP activ'#130, 'DHCP Enabled'), L('Oui', 'Yes'))
    Else Row(L('DHCP activ'#130, 'DHCP Enabled'), L('Non', 'No'));
    If Info[6] <> 0 Then Row(L('Etat du lien', 'Media State'), L('Connect'#130, 'Connected'))
    Else Row(L('Etat du lien', 'Media State'), L('D'#130'connect'#130, 'Disconnected'));
  End;
  If St = 1 Then
  Begin
    Row(L('Adresse IP', 'IP Address'), L('aucune (le serveur DHCP ne r'#130'pond pas)',
        'none (the DHCP server does not respond)'));
    Halt(1);
  End;
  Row(L('Adresse IP', 'IP Address'), IpStr(Info[1]));
  Row(L('Masque de sous-r'#130'seau', 'Subnet Mask'), IpStr(Info[2]));
  Row(L('Passerelle par d'#130'faut', 'Default Gateway'), IpStr(Info[3]));
  If All Then
  Begin
    If Info[5] <> 0 Then
    Begin
      Row(L('Serveur DHCP', 'DHCP Server'), IpStr(Info[12]));
      Str(Info[9], S);
      Row(L('Bail (secondes)', 'Lease (seconds)'), S);
    End;
    Row(L('Serveurs DNS', 'DNS Servers'), IpStr(Info[4]));
  End;
END.
