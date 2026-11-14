{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: WGET - telecharger une page ou un fichier par HTTP
                (TCPIP32.DLL) d'OS/2-0.
}

Program WGET;

{$R-,S-,I-}

{ Compilation : OS2PC WGET.PAS   (produit WGET.EXE)

  WGET http://hote[:port]/chemin [fichier]
  Requete HTTP/1.0 GET sur une connexion TCP ; la reponse (ligne d'etat
  et en-tetes) est affichee, le contenu est ecrit dans le fichier donne
  (ou dans le nom du chemin) ; sans fichier ni nom, il est affiche. }

Function SockInit : LongInt; External 'TCPIP32' Name 'sock_init';
Function Socket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function Connect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function Send(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function Recv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function SoClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function SockErrno : LongInt; External 'TCPIP32' Name 'sock_errno';
Function GetHostByName(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';

Var
  Buf : Array[0..4095] Of Byte;
  Addr : Array[0..15] Of Byte;
  NameB : Array[0..255] Of Byte;
  Url, HostS, Path, OutF, Req, Hdr : String;
  S, H, A, K, N, Port, C, Fh, Act, W, Total, Body, State : LongInt;
  InBody, ToFile : Boolean;
  Dummy : LongInt;

Function RdL(X : LongInt) : LongInt;
Type PL = ^LongInt;
Var Q : PL;
Begin
  Q := Pointer(X);
  RdL := Q^;
End;

Function RdB(X : LongInt) : LongInt;
Type PB = ^Byte;
Var Q : PB;
Begin
  Q := Pointer(X);
  RdB := Q^;
End;

Procedure Fail(M : String);
Begin
  Writeln('WGET : ', M);
  Halt(1);
End;

Procedure Emit(P, L : LongInt);
Var I : LongInt;
Begin
  If L <= 0 Then Exit;
  Body := Body + L;
  If ToFile Then Dummy := DosWrite(Fh, P, L, LongInt(@W))
  Else
    For I := 0 To L - 1 Do
      If (RdB(P + I) = 10) Or (RdB(P + I) = 13) Or (RdB(P + I) >= 32) Then Write(Chr(RdB(P + I)));
End;

BEGIN
  If ParamCount < 1 Then Fail('WGET http://hote[:port]/chemin [fichier]');
  Url := ParamStr(1);
  If (Copy(Url, 1, 7) = 'http://') Or (Copy(Url, 1, 7) = 'HTTP://') Then Delete(Url, 1, 7)
  Else If Pos('://', Url) > 0 Then Fail('seul le protocole http:// est pris en charge.');
  K := Pos('/', Url);
  If K > 0 Then
  Begin
    HostS := Copy(Url, 1, K - 1); Path := Copy(Url, K, 255);
  End
  Else
  Begin
    HostS := Url; Path := '/';
  End;
  Port := 80;
  K := Pos(':', HostS);
  If K > 0 Then
  Begin
    Val(Copy(HostS, K + 1, 10), Port, C);
    HostS := Copy(HostS, 1, K - 1);
  End;
  OutF := '';
  If ParamCount >= 2 Then OutF := ParamStr(2);
  If SockInit <> 0 Then Fail('le reseau n''est pas disponible (carte, DHCP).');
  For K := 1 To Length(HostS) Do NameB[K - 1] := Ord(HostS[K]);
  NameB[Length(HostS)] := 0;
  H := GetHostByName(LongInt(@NameB));
  If H = 0 Then Fail('hote inconnu : ' + HostS);
  A := RdL(RdL(H + 16));
  For K := 0 To 15 Do Addr[K] := 0;
  Addr[0] := 16; Addr[1] := 2; Addr[2] := Port Shr 8; Addr[3] := Port And 255;
  For K := 0 To 3 Do Addr[4 + K] := RdB(A + K);
  S := Socket(2, 1, 0);
  If S < 0 Then Fail('socket impossible.');
  Writeln('Connexion a ', HostS, ' (', Addr[4], '.', Addr[5], '.', Addr[6], '.', Addr[7], '), port ', Port, '...');
  If Connect(S, LongInt(@Addr), 16) <> 0 Then
  Begin
    Str(SockErrno, Hdr);
    Fail('connexion impossible (erreur ' + Hdr + ').');
  End;
  Req := 'GET ' + Path + ' HTTP/1.0' + #13#10 + 'Host: ' + HostS + #13#10 + 'User-Agent: OS2-0-WGET/1.0' + #13#10 +
         'Connection: close' + #13#10#13#10;
  For K := 1 To Length(Req) Do Buf[K - 1] := Ord(Req[K]);
  If Send(S, LongInt(@Buf), Length(Req), 0) <> Length(Req) Then Fail('envoi de la requete impossible.');
  ToFile := OutF <> '';
  If ToFile Then
  Begin
    For K := 1 To Length(OutF) Do NameB[K - 1] := Ord(OutF[K]);
    NameB[Length(OutF)] := 0;
    Fh := 0; Act := 0;
    If DosOpen(LongInt(@NameB), LongInt(@Fh), LongInt(@Act), 0, 0, $12, $41, 0) <> 0 Then
      Fail('impossible de creer ' + OutF);
  End;
  { en-tetes jusqu'a la ligne vide (CR LF CR LF) }
  InBody := False; State := 0; Total := 0; Body := 0; Hdr := '';
  Repeat
    N := Recv(S, LongInt(@Buf), 4096, 0);
    If N > 0 Then
    Begin
      Total := Total + N;
      If InBody Then Emit(LongInt(@Buf), N)
      Else
      Begin
        K := 0;
        While (K < N) And Not InBody Do
        Begin
          If (Buf[K] = 13) Or (Buf[K] = 10) Then
          Begin
            If Buf[K] = 10 Then
            Begin
              If Hdr <> '' Then Writeln(Hdr);
              If Hdr = '' Then InBody := True;
              Hdr := '';
            End;
          End
          Else If Length(Hdr) < 250 Then Hdr := Hdr + Chr(Buf[K]);
          Inc(K);
        End;
        If InBody Then Emit(LongInt(@Buf) + K, N - K);
      End;
    End;
  Until N <= 0;
  If N < 0 Then Writeln('WGET : reception interrompue (erreur ', SockErrno, ').');
  K := SoClose(S);
  If ToFile Then
  Begin
    K := DosClose(Fh);
    Writeln;
    Writeln(Body, ' octets ecrits dans ', OutF, '.');
  End
  Else
  Begin
    Writeln;
    Writeln('(', Body, ' octets recus)');
  End;
END.
