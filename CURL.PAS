{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: CURL - transfere une URL (http:// ou https://), comme la
                commande curl de Windows 10 (portee de Pasdows 95).
}

Program CURL;

{$R-,S-,I-}

{ Compilation : OS2PC CURL.PAS   (produit CURL.EXE)

  CURL [options...] url
    -o fichier   ecrit le contenu dans un fichier
    -O           ecrit dans un fichier au nom du fichier distant
    -I           en-tetes seulement (methode HEAD)
    -i           en-tetes et contenu
    -X methode   methode HTTP (GET, POST, PUT, DELETE...)
    -d donnees   envoie des donnees (POST)
    -H en-tete   ajoute un en-tete a la requete
    -A agent     nom du client (User-Agent)
    -L           suit les redirections (au plus 10)
    -s           silencieux ;  -v : details de la requete
    -f           echec sans le contenu sur une erreur HTTP (code 22)
    -x hote:port proxy HTTP (sinon SET HTTPS_PROXY ou HTTP_PROXY)
    -k           accepte (le certificat n'est jamais verifie)
    --version, -h

  Pasdows 95 (Win32) passait par WININET.DLL ; OS/2-0 parle HTTP/1.1
  lui-meme sur TCPIP32.DLL (sockets) et TLS32.DLL (https://, TLS 1.2 et
  1.3), comme WGET : corps "chunked" decode, proxy (requete absolue en
  http://, tunnel CONNECT en https://). Codes de sortie de curl : 1
  protocole, 2 option, 5 proxy, 6 hote inconnu, 7 connexion, 22 erreur
  HTTP (-f), 23 ecriture, 35 TLS, 47 trop de redirections. }

Uses DOS;

Function SockInit : LongInt; External 'TCPIP32' Name 'sock_init';
Function Socket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function Connect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function Send(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function Recv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function SoClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function SockErrno : LongInt; External 'TCPIP32' Name 'sock_errno';
Function GetHostByName(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function TlsOpen(S, PHost : LongInt) : LongInt; External 'TLS32' Name 'TLSOPEN';
Function TlsSend(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSSEND';
Function TlsRecv(H, B, L : LongInt) : LongInt; External 'TLS32' Name 'TLSRECV';
Function TlsClose(H : LongInt) : LongInt; External 'TLS32' Name 'TLSCLOSE';
Function TlsError(B, Cb : LongInt) : LongInt; External 'TLS32' Name 'TLSERROR';
Function TlsInfo(H : LongInt) : LongInt; External 'TLS32' Name 'TLSINFO';
Function DosOpen(PName, PHf, PAction, Cb, Attr, Flags, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';

Var
  Buf : Array[0..4095] Of Byte;
  Addr : Array[0..15] Of Byte;
  NameB : Array[0..259] Of Byte;
  Url, OutName, Method, Data, Agent, ProxyS, S, Req, Location, Line : String;
  Scheme, Host, Path, PHost : String;
  Hdrs : Array[0..15] Of String;
  NHdrs, Port, PPort, I, K, N, Err, Status, Redirs : LongInt;
  HeadOnly, Include, Follow, Silent, Verbose, Fail, RemoteName, ToFile, Tls, Chunked, Done : Boolean;
  Sock, Fh, Act, W, Total, Dummy : LongInt;
  CkState, CkLeft : LongInt;            { decodage "chunked" }
  CkLine : String;

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

Function UpStr(S : String) : String;
Var J : LongInt;
Begin
  For J := 1 To Length(S) Do S[J] := UpCase(S[J]);
  UpStr := S;
End;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
End;

Procedure PutZ(S : String);
Var J : LongInt;
Begin
  For J := 1 To Length(S) Do NameB[J - 1] := Ord(S[J]);
  NameB[Length(S)] := 0;
End;

Procedure ShowHelp;
Begin
  WriteLn('Syntaxe : CURL [options...] url');
  WriteLn;
  WriteLn(' -A agent        Nom du client (User-Agent)');
  WriteLn(' -d donnees      Envoie des donnees (POST)');
  WriteLn(' -f              Echoue sans afficher le contenu sur une erreur HTTP');
  WriteLn(' -H en-tete      Ajoute un en-tete a la requete');
  WriteLn(' -i              Affiche les en-tetes de la reponse');
  WriteLn(' -I              En-tetes seulement (methode HEAD)');
  WriteLn(' -k              Accepte tout certificat (jamais verifie)');
  WriteLn(' -L              Suit les redirections');
  WriteLn(' -o fichier      Ecrit le contenu dans un fichier');
  WriteLn(' -O              Ecrit dans un fichier au nom du fichier distant');
  WriteLn(' -s              Silencieux');
  WriteLn(' -v              Affiche les details de la requete');
  WriteLn(' -x hote:port    Proxy HTTP (sinon SET HTTPS_PROXY ou HTTP_PROXY)');
  WriteLn(' -X methode      Methode HTTP (GET, POST, PUT, DELETE...)');
  WriteLn(' --version       Affiche la version');
End;

Procedure Die(Code : LongInt; Const Msg : String);
Begin
  If Not Silent Then WriteLn('curl: (', Code, ') ', Msg);
  Halt(Code);
End;

Procedure SendStr(Const T : String);
Var J : LongInt;
Begin
  For J := 1 To Length(T) Do Buf[J - 1] := Ord(T[J]);
  If Tls Then N := TlsSend(1, LongInt(@Buf), Length(T)) Else N := Send(Sock, LongInt(@Buf), Length(T), 0);
  If N <> Length(T) Then Die(55, 'Echec de l''envoi des donnees');
End;

Function RecvBuf : LongInt;
Begin
  If Tls Then RecvBuf := TlsRecv(1, LongInt(@Buf), 4096) Else RecvBuf := Recv(Sock, LongInt(@Buf), 4096, 0);
End;

{ octets du contenu : fichier ou sortie standard }
Procedure Emit(P, L : LongInt);
Var J : LongInt; C : Byte; T : String;
Begin
  If L <= 0 Then Exit;
  Total := Total + L;
  If ToFile Then
  Begin
    If DosWrite(Fh, P, L, LongInt(@W)) <> 0 Then Die(23, 'Impossible d''ecrire ' + OutName);
    Exit;
  End;
  T := '';
  For J := 0 To L - 1 Do
  Begin
    C := RdB(P + J);
    If (C = 9) Or (C = 10) Or (C = 13) Or (C >= 32) Then T := T + Chr(C);
    If Length(T) >= 200 Then
    Begin
      Write(T);
      T := '';
    End;
  End;
  Write(T);
End;

Function HexVal(Const T : String) : LongInt;
Var J, V, D : LongInt;
Begin
  V := 0;
  For J := 1 To Length(T) Do
  Begin
    D := Pos(UpCase(T[J]), '0123456789ABCDEF') - 1;
    If D < 0 Then Break;
    V := V * 16 + D;
  End;
  HexVal := V;
End;

{ contenu "chunked" : taille en hexadecimal, CR LF, octets, CR LF... }
Procedure Body(P, L : LongInt);
Var J, Q : LongInt;
Begin
  If Not Chunked Then
  Begin
    Emit(P, L);
    Exit;
  End;
  J := 0;
  While J < L Do
  Begin
    Case CkState Of
      0 : Begin
            If RdB(P + J) = 10 Then
            Begin
              K := Pos(';', CkLine);
              If K > 0 Then CkLine := Copy(CkLine, 1, K - 1);
              CkLeft := HexVal(CkLine);
              CkLine := '';
              If CkLeft = 0 Then CkState := 3 Else CkState := 1;
            End
            Else If (RdB(P + J) <> 13) And (Length(CkLine) < 60) Then CkLine := CkLine + Chr(RdB(P + J));
            Inc(J);
          End;
      1 : Begin
            Q := L - J;
            If Q > CkLeft Then Q := CkLeft;
            Emit(P + J, Q);
            J := J + Q; CkLeft := CkLeft - Q;
            If CkLeft = 0 Then CkState := 2;
          End;
      2 : Begin
            If RdB(P + J) = 10 Then CkState := 0;
            Inc(J);
          End;
    Else
      J := L;
    End;
  End;
End;

{ schema://hote[:port]/chemin }
Procedure SplitUrl(U : String);
Begin
  K := Pos('://', U);
  If K > 0 Then
  Begin
    Scheme := UpStr(Copy(U, 1, K - 1));
    U := Copy(U, K + 3, 255);
  End
  Else Scheme := 'HTTP';
  If (Scheme <> 'HTTP') And (Scheme <> 'HTTPS') Then
    Die(1, 'Protocole "' + Copy(Url, 1, Pos('://', Url) - 1) + '" non pris en charge');
  K := Pos('/', U);
  If K > 0 Then
  Begin
    Host := Copy(U, 1, K - 1); Path := Copy(U, K, 255);
  End
  Else
  Begin
    Host := U; Path := '/';
  End;
  If Scheme = 'HTTPS' Then Port := 443 Else Port := 80;
  K := Pos(':', Host);
  If K > 0 Then
  Begin
    Val(Copy(Host, K + 1, 10), Port, Err);
    Host := Copy(Host, 1, K - 1);
  End;
  Tls := Scheme = 'HTTPS';
End;

{ adresse IPv4 de H dans Addr (port P) }
Procedure Resolve(Const H : String; P, Code : LongInt);
Var Hp, A : LongInt;
Begin
  PutZ(H);
  Hp := GetHostByName(LongInt(@NameB));
  If Hp = 0 Then
  Begin
    If Code = 5 Then Die(5, 'Impossible de resoudre le proxy : ' + H);
    Die(6, 'Impossible de resoudre l''hote : ' + H);
  End;
  A := RdL(RdL(Hp + 16));
  For K := 0 To 15 Do Addr[K] := 0;
  Addr[0] := 16; Addr[1] := 2; Addr[2] := P Shr 8; Addr[3] := P And 255;
  For K := 0 To 3 Do Addr[4 + K] := RdB(A + K);
End;

{ une requete : statut, en-tetes, contenu ; Location pour -L }
Procedure Transfer;
Var InBody, UseProxy, FirstLine : Boolean; CPort : LongInt; Hdr, Ip : String;
Begin
  UseProxy := PHost <> '';
  If UseProxy Then
  Begin
    Resolve(PHost, PPort, 5); CPort := PPort;
  End
  Else
  Begin
    Resolve(Host, Port, 6); CPort := Port;
  End;
  Ip := IStr(Addr[4]) + '.' + IStr(Addr[5]) + '.' + IStr(Addr[6]) + '.' + IStr(Addr[7]);
  Sock := Socket(2, 1, 0);
  If Sock < 0 Then Die(7, 'Impossible de creer une socket');
  If Verbose Then
  Begin
    If UseProxy Then WriteLn('*   Trying ', Ip, ':', CPort, ' (proxy ', PHost, ')...')
    Else WriteLn('*   Trying ', Ip, ':', CPort, '...');
  End;
  If Connect(Sock, LongInt(@Addr), 16) <> 0 Then
    Die(7, 'Echec de connexion a ' + Host + ' port ' + IStr(Port) + ' (erreur ' + IStr(SockErrno) + ')');
  If Verbose Then WriteLn('* Connected to ', Host, ' (', Ip, ') port ', CPort);
  { https par un proxy : tunnel CONNECT }
  Tls := False;
  If UseProxy And (Scheme = 'HTTPS') Then
  Begin
    SendStr('CONNECT ' + Host + ':' + IStr(Port) + ' HTTP/1.1' + #13#10 + 'Host: ' + Host + ':' + IStr(Port) + #13#10 +
            #13#10);
    Hdr := ''; FirstLine := True; Status := 0; InBody := False;
    Repeat
      N := RecvBuf;
      For K := 0 To N - 1 Do
        If Not InBody Then
          If Buf[K] = 10 Then
          Begin
            If FirstLine Then Val(Copy(Hdr, 10, 3), Status, Err);
            If Hdr = '' Then InBody := True;
            FirstLine := False;
            Hdr := '';
          End
          Else If (Buf[K] <> 13) And (Length(Hdr) < 250) Then Hdr := Hdr + Chr(Buf[K]);
    Until InBody Or (N <= 0);
    If Status <> 200 Then Die(56, 'Le proxy a refuse le tunnel CONNECT (HTTP ' + IStr(Status) + ')');
  End;
  If Scheme = 'HTTPS' Then
  Begin
    PutZ(Host);
    If TlsOpen(Sock, LongInt(@NameB)) <> 1 Then
    Begin
      Dummy := TlsError(LongInt(@NameB), 250);
      Hdr := '';
      K := 0;
      While (K < 250) And (NameB[K] <> 0) Do
      Begin
        Hdr := Hdr + Chr(NameB[K]);
        Inc(K);
      End;
      Die(35, 'Erreur de connexion TLS : ' + Hdr);
    End;
    Tls := True;
    If Verbose Then
    Begin
      If (TlsInfo(1) Shr 16) = $0304 Then WriteLn('* SSL connection using TLSv1.3 (certificat non verifie)')
      Else WriteLn('* SSL connection using TLSv1.2 (certificat non verifie)');
    End;
  End;
  { requete }
  If UseProxy And (Scheme = 'HTTP') Then
  Begin
    If Port = 80 Then Line := 'http://' + Host + Path Else Line := 'http://' + Host + ':' + IStr(Port) + Path;
  End
  Else Line := Path;
  Req := Method + ' ' + Line + ' HTTP/1.1';
  If Verbose Then WriteLn('> ', Req);
  SendStr(Req + #13#10);
  If ((Port = 80) And (Scheme = 'HTTP')) Or ((Port = 443) And (Scheme = 'HTTPS')) Then Hdr := 'Host: ' + Host
  Else Hdr := 'Host: ' + Host + ':' + IStr(Port);
  If Verbose Then WriteLn('> ', Hdr);
  SendStr(Hdr + #13#10);
  If Verbose Then
  Begin
    WriteLn('> User-Agent: ', Agent);
    WriteLn('> Accept: */*');
  End;
  SendStr('User-Agent: ' + Agent + #13#10 + 'Accept: */*' + #13#10 + 'Connection: close' + #13#10);
  For I := 0 To NHdrs - 1 Do
  Begin
    If Verbose Then WriteLn('> ', Hdrs[I]);
    SendStr(Hdrs[I] + #13#10);
  End;
  If Data <> '' Then
  Begin
    S := 'Content-Length: ' + IStr(Length(Data));
    If Verbose Then WriteLn('> ', S);
    SendStr(S + #13#10);
  End;
  If Verbose Then WriteLn('>');
  SendStr(#13#10);
  If Data <> '' Then SendStr(Data);
  { reponse : ligne de statut et en-tetes jusqu'a la ligne vide }
  InBody := False; FirstLine := True; Status := 0; Chunked := False; Location := ''; Hdr := '';
  CkState := 0; CkLeft := 0; CkLine := '';
  Repeat
    N := RecvBuf;
    If N > 0 Then
    Begin
      If InBody Then
      Begin
        If Not HeadOnly And Not ((Status >= 300) And (Status < 400) And Follow And (Location <> '')) Then
          Body(LongInt(@Buf), N);
      End
      Else
      Begin
        K := 0;
        While (K < N) And Not InBody Do
        Begin
          If Buf[K] = 10 Then
          Begin
            If FirstLine Then Val(Copy(Hdr, 10, 3), Status, Err);
            FirstLine := False;
            If Include Or HeadOnly Then WriteLn(Hdr)
            Else If Verbose Then WriteLn('< ', Hdr);
            If UpStr(Copy(Hdr, 1, 9)) = 'LOCATION:' Then
            Begin
              Location := Copy(Hdr, 10, 255);
              While (Location <> '') And (Location[1] = ' ') Do Delete(Location, 1, 1);
            End;
            If (UpStr(Copy(Hdr, 1, 18)) = 'TRANSFER-ENCODING:') And (Pos('CHUNKED', UpStr(Hdr)) > 0) Then
              Chunked := True;
            If Hdr = '' Then
            Begin
              InBody := True;
              If Fail And (Status >= 400) Then
              Begin
                If Tls Then Dummy := TlsClose(1);
                Dummy := SoClose(Sock);
                Die(22, 'The requested URL returned error: ' + IStr(Status));
              End;
            End;
            Hdr := '';
          End
          Else If (Buf[K] <> 13) And (Length(Hdr) < 250) Then Hdr := Hdr + Chr(Buf[K]);
          Inc(K);
        End;
        If InBody And Not HeadOnly And Not ((Status >= 300) And (Status < 400) And Follow And (Location <> '')) Then
          Body(LongInt(@Buf) + K, N - K);
      End;
    End;
  Until (N <= 0) Or (Chunked And (CkState = 3));
  If Tls Then Dummy := TlsClose(1);
  Dummy := SoClose(Sock);
  If Status = 0 Then Die(52, 'Reponse vide du serveur');
End;

BEGIN
  Url := ''; OutName := ''; Method := ''; Data := ''; Agent := 'curl/8.4.0 (OS/2-0)';
  NHdrs := 0; HeadOnly := False; Include := False; Follow := False; Silent := False;
  Verbose := False; Fail := False; RemoteName := False; ProxyS := '';
  I := 1;
  While I <= ParamCount Do
  Begin
    S := ParamStr(I);
    If (S = '-h') Or (S = '--help') Or (S = '/?') Then
    Begin
      ShowHelp;
      Halt(0);
    End
    Else If S = '--version' Then
    Begin
      WriteLn('curl 8.4.0 (OS/2-0) TCPIP32 TLS32 (TLS 1.2, TLS 1.3)');
      WriteLn('Protocols: http https');
      WriteLn('Features: proxy chunked');
      Halt(0);
    End
    Else If (S = '-o') And (I < ParamCount) Then
    Begin
      Inc(I); OutName := ParamStr(I);
    End
    Else If S = '-O' Then RemoteName := True
    Else If S = '-I' Then HeadOnly := True
    Else If S = '-i' Then Include := True
    Else If S = '-L' Then Follow := True
    Else If S = '-s' Then Silent := True
    Else If S = '-v' Then Verbose := True
    Else If S = '-f' Then Fail := True
    Else If S = '-k' Then
    Else If (S = '-X') And (I < ParamCount) Then
    Begin
      Inc(I); Method := ParamStr(I);
    End
    Else If (S = '-d') And (I < ParamCount) Then
    Begin
      Inc(I); Data := ParamStr(I);
    End
    Else If (S = '-A') And (I < ParamCount) Then
    Begin
      Inc(I); Agent := ParamStr(I);
    End
    Else If ((S = '-x') Or (S = '--proxy')) And (I < ParamCount) Then
    Begin
      Inc(I); ProxyS := ParamStr(I);
    End
    Else If (S = '-H') And (I < ParamCount) Then
    Begin
      Inc(I);
      If NHdrs < 16 Then
      Begin
        Hdrs[NHdrs] := ParamStr(I);
        Inc(NHdrs);
      End;
    End
    Else If (Length(S) > 1) And (S[1] = '-') Then Die(2, 'option ' + S + ' inconnue')
    Else Url := S;
    Inc(I);
  End;
  If Url = '' Then
  Begin
    WriteLn('curl: aucune URL indiquee');
    WriteLn('curl: essayez ''curl -h'' pour plus d''information');
    Halt(2);
  End;
  SplitUrl(Url);
  If RemoteName And (OutName = '') Then
  Begin
    OutName := Path;
    K := Pos('?', OutName);
    If K > 0 Then OutName := Copy(OutName, 1, K - 1);
    While Pos('/', OutName) > 0 Do Delete(OutName, 1, Pos('/', OutName));
    If OutName = '' Then OutName := 'index.html';
  End;
  If Method = '' Then
  Begin
    If HeadOnly Then Method := 'HEAD'
    Else If Data <> '' Then Method := 'POST'
    Else Method := 'GET';
  End;
  If Data <> '' Then
  Begin
    K := 0;
    For I := 0 To NHdrs - 1 Do
      If Pos('CONTENT-TYPE', UpStr(Hdrs[I])) = 1 Then K := 1;
    If (K = 0) And (NHdrs < 16) Then
    Begin
      Hdrs[NHdrs] := 'Content-Type: application/x-www-form-urlencoded';
      Inc(NHdrs);
    End;
  End;
  { proxy : -x, sinon HTTPS_PROXY (https://) ou HTTP_PROXY (CONFIG.SYS) }
  If ProxyS = '' Then
  Begin
    If Scheme = 'HTTPS' Then ProxyS := GetEnv('HTTPS_PROXY');
    If ProxyS = '' Then ProxyS := GetEnv('HTTP_PROXY');
  End;
  PHost := ''; PPort := 8080;
  If ProxyS <> '' Then
  Begin
    K := Pos('://', ProxyS);
    If K > 0 Then ProxyS := Copy(ProxyS, K + 3, 255);
    K := Pos('/', ProxyS);
    If K > 0 Then ProxyS := Copy(ProxyS, 1, K - 1);
    K := Pos(':', ProxyS);
    If K > 0 Then
    Begin
      Val(Copy(ProxyS, K + 1, 10), PPort, Err);
      PHost := Copy(ProxyS, 1, K - 1);
    End
    Else PHost := ProxyS;
  End;
  If SockInit <> 0 Then Die(7, 'Le reseau n''est pas disponible (carte, DHCP)');
  ToFile := OutName <> '';
  If ToFile Then
  Begin
    PutZ(OutName);
    Fh := 0; Act := 0;
    If DosOpen(LongInt(@NameB), LongInt(@Fh), LongInt(@Act), 0, 0, $12, $41, 0) <> 0 Then
      Die(23, 'Impossible d''ecrire ' + OutName);
  End;
  Total := 0;
  Redirs := 0;
  Done := False;
  Repeat
    Transfer;
    If Follow And (Status >= 300) And (Status < 400) And (Location <> '') Then
    Begin
      Inc(Redirs);
      If Redirs > 10 Then Die(47, 'Plus de 10 redirections');
      If Verbose Then WriteLn('* Redirection vers ', Location);
      If Pos('://', Location) > 0 Then SplitUrl(Location)
      Else If Copy(Location, 1, 1) = '/' Then Path := Location
      Else
      Begin
        K := Length(Path);
        While (K > 0) And (Path[K] <> '/') Do Dec(K);
        Path := Copy(Path, 1, K) + Location;
      End;
      { 303 (et 301, 302 apres un POST) : GET sans donnees }
      If (Status = 303) Or (((Status = 301) Or (Status = 302)) And (Method = 'POST')) Then
      Begin
        Method := 'GET'; Data := '';
      End;
    End
    Else Done := True;
  Until Done;
  If ToFile Then
  Begin
    Dummy := DosClose(Fh);
    If Not Silent Then WriteLn(Total, ' octets recus dans ', OutName, ' (HTTP ', Status, ')');
  End;
END.
