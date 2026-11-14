{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: IFCONFIG - etat et configuration de l'interface reseau
                lan0 (TCPIP32.DLL) d'OS/2-0.
}

Program IFCONFIG;

{$R-,S-,I-}

{ Compilation : OS2PC IFCONFIG.PAS   (produit IFCONFIG.EXE)

  IFCONFIG [lan0] [/RENEW]
  Affiche la carte reseau (pilote, adresse MAC, lien), l'adresse IP, le
  masque, l'adresse de diffusion, la passerelle, le serveur DNS, la
  source de la configuration (DHCP et bail, ou CONFIG.SYS : IP_ADDRESS,
  IP_NETMASK, IP_GATEWAY, IP_DNS) et le nombre de trames. /RENEW refait
  la configuration (nouvelle demande DHCP). }

Function TcpipInfo(P : LongInt) : LongInt; External 'TCPIP32' Name 'TCPIPINFO';
Function TcpipRenew : LongInt; External 'TCPIP32' Name 'TCPIPRENEW';

Var
  Info : Array[0..15] Of LongInt;
  Txt : Array[0..255] Of Byte;
  K, St : LongInt;
  S : String;

Function IpStr(V : LongInt) : String;
Var A, B, C, D : String;
Begin
  Str((V Shr 24) And 255, A); Str((V Shr 16) And 255, B); Str((V Shr 8) And 255, C); Str(V And 255, D);
  IpStr := A + '.' + B + '.' + C + '.' + D;
End;

Function TxtStr : String;
Var R : String; I : LongInt;
Begin
  R := '';
  I := 0;
  While (I < 255) And (Txt[I] <> 0) Do
  Begin
    R := R + Chr(Txt[I]);
    Inc(I);
  End;
  TxtStr := R;
End;

BEGIN
  For K := 1 To ParamCount Do
  Begin
    S := ParamStr(K);
    If (S = '/RENEW') Or (S = '/renew') Or (S = '-renew') Then
    Begin
      Writeln('Nouvelle configuration de lan0 (DHCP)...');
      If TcpipRenew <> 0 Then Writeln('IFCONFIG : aucune adresse obtenue.');
    End
    Else If (S = '/?') Or (S = '-?') Then
    Begin
      Writeln('IFCONFIG [lan0] [/RENEW] : etat de l''interface reseau ; /RENEW : nouvelle demande DHCP.');
      Halt(0);
    End;
  End;
  For K := 0 To 15 Do Info[K] := 0;
  Info[10] := LongInt(@Txt); Info[11] := 255;
  St := TcpipInfo(LongInt(@Info));
  Writeln('lan0: ', TxtStr);
  If St = 0 Then
  Begin
    Writeln('      aucune carte reseau trouvee (Intel PRO/1000 ou AMD PCnet)');
    Halt(1);
  End;
  If Info[6] <> 0 Then Write('      lien actif') Else Write('      lien inactif');
  Writeln(', trames recues ', Info[7], ', envoyees ', Info[8]);
  If St = 1 Then
  Begin
    Writeln('      pas d''adresse IP (le serveur DHCP ne repond pas)');
    Halt(1);
  End;
  Writeln('      inet ', IpStr(Info[1]), '  masque ', IpStr(Info[2]), '  diffusion ',
          IpStr(Info[1] Or Not Info[2]));
  Write('      passerelle ', IpStr(Info[3]), '  DNS ', IpStr(Info[4]));
  If Info[5] <> 0 Then Writeln('  (DHCP, bail ', Info[9], ' s)') Else Writeln('  (adresse fixe, CONFIG.SYS)');
END.
