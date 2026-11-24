{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2 ; Free Pascal 3.2 (-Mtp) pour les essais)
  @description: Serveur Web d'OS/2-0 (HTTP, HTTPS, PSP, ASP, PHP) et sa console
                d'administration dans le style d'IIS.
}

Program WebSrv;

{$R-,S-,I-}

{ Compilation : OS2PC WEBSRV.PAS WEBSRV.EXE

  Serveur Web d'OS/2-0 (groupe Outils reseau du bureau). Un seul programme
  fait les deux travaux, comme les services d'IIS et leur console :

    WEBSRV            console d'administration (Presentation Manager) : arbre
                      des sites et des categories de configuration a gauche,
                      panneau de droite qui suit l'arbre, menus deroulants
                      Fichier, Action, Affichage, Outils et ? ;
    WEBSRV /SERVICE   le serveur lui-meme, sans fenetre ni console (processus
                      detache) : il est lance par la console (Action ->
                      Demarrer le serveur) ou, si la case "Demarrer le serveur
                      Web avec OS/2" est cochee, par la ligne
                      RUN=C:\WEBSRV.EXE /SERVICE de CONFIG.SYS ; par defaut il
                      n'est pas active et rien n'est charge au demarrage ;
    WEBSRV /STOP      arrete le serveur en marche ;
    WEBSRV /STATUS    etat du serveur (texte) ;
    WEBSRV /PSP page  execute une page PSP, ASP ou PHP et ecrit le resultat
                      (essais) ;
    WEBSRV /PSPOUT fichier page [requete]
                      la meme chose, le resultat dans un fichier (Executer la
                      page de Web Developer) ;
    WEBSRV /DBTEST    verifie MD5, SHA-1 et SCRAM-SHA-256 (RFC 7677).

  Le serveur :
    - HTTP/1.1 (connexions persistantes, HEAD, GET, POST, en-tetes If-Modified-
      Since et If-None-Match (reponse 304), Range (206), pages d'erreur
      personnalisees, exploration de repertoire, documents par defaut, types
      MIME, en-tetes de reponse personnalises, repertoires virtuels) ;
    - HTTPS : TLS 1.3 (TLS_AES_128_GCM_SHA256, X25519), certificat ECDSA P-256
      auto-signe cree par la console (Outils -> Certificat du serveur) ou
      certificat et cle PEM fournis ;
    - hotes virtuels comme IIS : chaque site a ses liaisons (protocole,
      adresse IP, port, nom d'hote) ; une requete va au site dont la liaison
      correspond a l'adresse IP et au port ou elle est arrivee et au nom de
      domaine de son en-tete Host (SNI en HTTPS) ;
    - PSP (Pascal Server Pages, le langage des compilateurs PSP86 et PSPCW32
      de DEV-COOLS) : les pages .psp sont compilees une fois en code
      intermediaire (gardees en memoire tant que le fichier ne change pas)
      et executees dans le serveur, sans processus par requete ; objets
      d'ASP : Request, Response, Server, Session, Application, et
      CreateObject (Scripting.Dictionary, Scripting.FileSystemObject) ;
    - ASP (VBScript) : les pages .asp sont compilees vers la meme machine ;
    - bases de donnees externes, sans pilote : PostgreSQL (SCRAM-SHA-256,
      md5, en clair) et MariaDB/MySQL (mysql_native_password) ; PSP :
      Database.Connect(chaine), Connexion.Query(sql), RecordSet['col'],
      .Eof, .Next ; ASP : ADODB.Connection et ADODB.Recordset ; une page
      qui attend sa base ne bloque pas les autres connexions ;
    - PHP (le lexique et les fonctions du compilateur PHPCW32 de DEV-COOLS,
      recrits ici pour la machine du serveur) : les pages .php sont
      compilees une fois, comme les pages PSP, vers la meme machine (code
      opPhp) ; <?php ?>, <?= ?>, interpolation de $x et $a['k'], heredoc et
      nowdoc, syntaxe alternative (endif, endforeach...), fonctions avec
      valeurs par defaut, references &, global et static, include/require,
      tableaux associatifs ordonnes, list()/[...], ??, ??=, <=>, **, ===,
      try/catch ; environ 280 fonctions (chaines, tableaux, maths, dates,
      JSON, sprintf, fichiers, en-tetes, sessions, ob_start) ; superglobales
      $_GET, $_POST, $_REQUEST, $_COOKIE, $_SERVER, $_FILES, $_SESSION ;
      bases de donnees : mysqli (procedural et objet), pg_* et PDO (mysql:
      et pgsql:, requetes preparees ? et :nom) sur les memes pilotes ;
      sorties identiques a PHP 8 pour les essais ;
    - journal W3C par site (C:\WWW\LOGS\W3SVCn\exAAMMJJ.LOG) ;
    - pense pour un fort trafic sans ralentir OS/2 : une seule tache, sockets
      non bloquants et select (jusqu'a 48 connexions par liaison), classe de
      priorite "temps libre" (DosSetPriority : tranches de 10 ms), les pages
      PSP s'executent par tranches de quelques milliers d'instructions entre
      lesquelles les autres connexions avancent ; les fichiers partent par
      blocs de 16 Ko, le journal est ecrit par paquets.

  Fichiers : C:\WWW\WEBSRV.CFG (configuration, texte) ; C:\WWW\ROOT (site Web
  par defaut) ; C:\WWW\LOGS ; C:\WWW\CERTS. Si C: n'est pas accessible en
  ecriture (CD-ROM d'OS/2-0), la configuration, les journaux et les
  certificats vont sur D:\WWW (disque virtuel).

  La console et le serveur se parlent par la memoire partagee
  \SHAREMEM\WEBSRV (etat, compteurs, commandes).

  Sous Free Pascal (Linux), le meme source donne le serveur pour les essais
  (sockets de BaseUnix) ; la console n'existe que sous OS/2-0. }

{$IFDEF FPC}
{$IFNDEF OS2PC}
Uses Dos, BaseUnix, Unix, Sockets;
{$ENDIF}
{$ENDIF}

Const
  AppVer = '1.0';
  MaxConn = 48;             { connexions servies en meme temps }
  MaxSites = 16;
  MaxBind = 6;              { liaisons d'un site }
  MaxListen = 8;            { sockets d'ecoute (adresse:port distincts) }
  MaxDocs = 8;              { documents par defaut }
  MaxErrP = 8;              { pages d'erreur personnalisees }
  MaxHdrs = 8;              { en-tetes de reponse personnalises }
  MaxVDir = 8;              { repertoires virtuels }
  MaxMime = 64;
  RxCap = 17408;            { donnees recues (un enregistrement TLS entier) }
  ReqCap = 16384;           { requete en clair (en-tetes et petit corps) }
  TxCap = 17408;            { donnees pretes a partir (un enregistrement TLS) }
  ChunkSz = 16000;          { bloc d'un fichier ou d'une reponse }
  MaxBody = 4194304;        { corps d'une requete POST au plus }
  MaxOut = 8388608;         { reponse d'une page PSP au plus }
  { etats d'une connexion }
  csFree = 0; csTls = 1; csRead = 2; csBody = 3; csSend = 4; csWaitVm = 5; csVm = 6; csClose = 7;
  { sources du corps de la reponse }
  bsNone = 0; bsMem = 1; bsFile = 2;
  Crlf = #13#10;

Type
  TBytes = Array[0..$3FFFFFFF] Of Byte;
  PBytes = ^TBytes;
  TLongs = Array[0..$FFFFFFF] Of LongInt;
  PLongs = ^TLongs;

  TBind = Record
    Tls : Boolean;          { https }
    Ip : LongInt;           { 0 : toutes les adresses }
    Port : LongInt;
    Host : String[63];      { '' : tous les noms }
  End;

  TSite = Record
    Used : Boolean;
    Id : LongInt;           { numero du site (W3SVCn) }
    Name : String[63];
    Root : String[127];
    Started : Boolean;
    NB : LongInt;
    B : Array[0..MaxBind - 1] Of TBind;
    ND : LongInt;
    Docs : Array[0..MaxDocs - 1] Of String[31];
    Browse : Boolean;       { exploration de repertoire }
    LogOn : Boolean;
    Psp, Asp, Php : Boolean;     { gestionnaires actives }
    NE : LongInt;
    ErrCode : Array[0..MaxErrP - 1] Of LongInt;
    ErrPath : Array[0..MaxErrP - 1] Of String[79];
    NH : LongInt;
    Hdr : Array[0..MaxHdrs - 1] Of String[127];
    NV : LongInt;
    VUrl : Array[0..MaxVDir - 1] Of String[47];
    VPath : Array[0..MaxVDir - 1] Of String[127];
    Cert : String[127];     { certificat (PEM) ; '' : WWW\CERTS\SITEn.PEM }
    AuthUser, AuthPass : String[31];   { authentification de base ; '' : anonyme }
    Requests, BytesOut : LongInt;
    Status : String[79];    { erreur de liaison, etc. }
  End;

  TConn = Record
    State : LongInt;
    Sock : LongInt;
    LIdx : LongInt;         { socket d'ecoute d'origine }
    PeerIp, PeerPort, LocalIp, LocalPort : LongInt;
    IsTls : Boolean;
    Site : LongInt;
    T0, TLast : LongInt;    { debut de la requete, derniere activite }
    NReq : LongInt;
    Rx, Req, Tx : PBytes;   { tampons (dans la reserve des connexions) }
    RxLen, ReqLen, TxLen, TxPos : LongInt;
    HdrEnd : LongInt;       { fin des en-tetes dans Req (0 : pas encore) }
    BodyLen : LongInt;      { Content-Length }
    Body : PBytes;          { corps hors de Req (gros POST) }
    BodyCap, BodyGot : LongInt;
    KeepAlive : Boolean;
    Head : Boolean;         { methode HEAD }
    { reponse }
    BSrc : LongInt;
    BMem : PBytes;
    BMemOwn : Boolean;      { BMem a liberer }
    BMemCap : LongInt;      { taille allouee de BMem }
    BLen, BPos : LongInt;
    BFile : LongInt;        { fichier ouvert }
    BLeft : LongInt;
    Status : LongInt;
    SentBytes : LongInt;
    { requete analysee }
    Method : String[15];
    Uri : String;           { chemin demande (sans la requete) }
    Query : String;
    Ver : String[15];
    Host : String[79];
    LogOk : Boolean;
    { TLS }
    TlsSt : LongInt;        { 0 ClientHello attendu, 1 Finished du client attendu, 2 etabli }
    TIdx : LongInt;         { etat TLS (tables Tls*) }
  End;

Var
  Sites : Array[0..MaxSites - 1] Of TSite;
  Conns : Array[0..MaxConn - 1] Of TConn;
  NMime : LongInt;
  MimeExt : Array[0..MaxMime - 1] Of String[11];
  MimeTyp : Array[0..MaxMime - 1] Of String[63];
  { reglages du serveur }
  KeepAliveS, ConnTimeoutS, ScriptTimeoutS, SessionTimeoutM, MaxConnCfg : LongInt;
  ServerName : String[63];
  WwwBase, WwwData : String[63];      { C:\WWW ; C:\WWW ou D:\WWW (ecriture) }
  CfgPath : String[79];
  { ecoute }
  NListen : LongInt;
  LSock, LPort, LIp : Array[0..MaxListen - 1] Of LongInt;
  LTls : Array[0..MaxListen - 1] Of Boolean;
  { compteurs }
  StartTick, TotReq, TotBytesOut, TotBytesIn, TotErr, CurConn, MaxSeen : LongInt;
  Running : Boolean;
  Pool : PBytes;
  ServiceMode, Quiet : Boolean;
  MyIpAddr : LongInt;
  Dummy : LongInt;
  LogMsg : String;
  TlsGotData : Boolean;

Const
  StatMagic = $53424557;      { 'WEBS' }
  cmdNone = 0; cmdReload = 1; cmdStop = 2;

Type
  TStat = Record
    Magic, Pid, Running, StartTime, Heart : LongInt;
    Requests, BytesOut, BytesIn, Errors, CurConn, MaxConn, PspRuns, PspErr : LongInt;
    Cmd, CmdSeq, CmdAck : LongInt;
    SiteReq : Array[0..MaxSites - 1] Of LongInt;
    SiteOut : Array[0..MaxSites - 1] Of LongInt;
    SiteState : Array[0..MaxSites - 1] Of LongInt;    { 0 arrete, 1 demarre, 2 erreur }
    SiteId : Array[0..MaxSites - 1] Of LongInt;
    LastMsg : String[127];
    ConnIp, ConnUrl : Array[0..15] Of LongInt;        { reserve }
  End;
  PStatRec = ^TStat;

Var
  Shm : PStatRec;
  StatLocal : TStat;
  LastHouse : LongInt;

{ ==================================================================== }
{ Couche du systeme : OS/2-0 (DOSCALLS, TCPIP32) ou Linux (essais)      }
{ ==================================================================== }

{$IFDEF OS2PC}
Function DosOpen(PName, PHf, PAct, Cb, Attr, Fl, Mode, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosRead(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, B, Cb, PA : LongInt) : LongInt; External 'DOSCALLS';
Function DosClose(H : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetFilePtr(H, Ib, Method, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryPathInfo(PName, Level, PInfo, Cb : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindFirst(PSpec, PHDir, Attr, PBuf, CbBuf, PCount, Level : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindNext(HDir, PBuf, CbBuf, PCount : LongInt) : LongInt; External 'DOSCALLS';
Function DosFindClose(HDir : LongInt) : LongInt; External 'DOSCALLS';
Function DosCreateDir(PName, PEa : LongInt) : LongInt; External 'DOSCALLS';
Function DosDelete(PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosMove(POld, PNew : LongInt) : LongInt; External 'DOSCALLS';
Function DosScanEnv(PName, PPValue : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetDateTime(P : LongInt) : LongInt; External 'DOSCALLS';
Function DosSetPriority(Scope, PClass, Delta, Id : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocSharedMem(PPb, PName, Cb, Fl : LongInt) : LongInt; External 'DOSCALLS';
Function DosGetNamedSharedMem(PPb, PName, Fl : LongInt) : LongInt; External 'DOSCALLS';
Function DosExecPgm(PObj, CbObj, Flags, PArg, PEnv, PRes, PName : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function KPid : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KTaskCtl(Op, P1, P2, P3 : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnTaskCtl';
Function Sock_Init : LongInt; External 'TCPIP32' Name 'sock_init';
Function SockSocket(D, T, P : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function SockBind(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'bind';
Function SockListen(S, B : LongInt) : LongInt; External 'TCPIP32' Name 'listen';
Function SockAccept(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'accept';
Function SockSend(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function SockRecv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function SockClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function SockIoctl(S, C, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'ioctl';
Function SockSelect(N, R, W, E, T : LongInt) : LongInt; External 'TCPIP32' Name 'bsdselect';
Function SockErrno : LongInt; External 'TCPIP32' Name 'sock_errno';
Function SockName(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'getsockname';
Function SockHostId : LongInt; External 'TCPIP32' Name 'gethostid';

Var
  ZBuf, ZBuf2 : Array[0..299] Of Byte;
  FindBuf : Array[0..1023] Of Byte;
  FindH : LongInt;

Function Z(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do ZBuf[K - 1] := Ord(S[K]);
  ZBuf[Length(S)] := 0;
  Z := LongInt(@ZBuf);
End;

Function Z2(S : String) : LongInt;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do ZBuf2[K - 1] := Ord(S[K]);
  ZBuf2[Length(S)] := 0;
  Z2 := LongInt(@ZBuf2);
End;

Function PeekB(A : LongInt) : LongInt;
Var P : PBytes;
Begin
  P := Pointer(A);
  PeekB := P^[0];
End;
{$ENDIF}

Function PTicks : LongInt;
{$IFDEF OS2PC}
Begin
  PTicks := KTicks;
End;
{$ELSE}
Var T : TTimeVal;
Begin
  fpGetTimeOfDay(@T, Nil);
  PTicks := LongInt((Int64(T.tv_sec) * 1000 + T.tv_usec Div 1000) And $7FFFFFFF);
End;
{$ENDIF}

Procedure PSleep(Ms : LongInt);
{$IFDEF OS2PC}
Begin
  Dummy := DosSleep(Ms);
End;
{$ELSE}
Var T : TTimeSpec;
Begin
  T.tv_sec := Ms Div 1000;
  T.tv_nsec := (Ms Mod 1000) * 1000000;
  fpNanoSleep(@T, Nil);
End;
{$ENDIF}

Function PEnv(Name : String) : String;
{$IFDEF OS2PC}
Var P, K : LongInt; S : String;
Begin
  P := 0; S := '';
  If DosScanEnv(Z(Name), LongInt(@P)) = 0 Then
  Begin
    K := 0;
    While (PeekB(P + K) <> 0) And (K < 255) Do
    Begin
      S := S + Chr(PeekB(P + K));
      Inc(K);
    End;
  End;
  PEnv := S;
End;
{$ELSE}
Begin
  PEnv := GetEnv(Name);
End;
{$ENDIF}

{ date et heure locales }
Procedure PNow(Var Y, Mo, D, H, Mi, S, Wd : LongInt);
{$IFDEF OS2PC}
Var B : Array[0..11] Of Byte;
Begin
  Dummy := DosGetDateTime(LongInt(@B));
  H := B[0]; Mi := B[1]; S := B[2]; D := B[4]; Mo := B[5]; Y := B[6] + B[7] * 256; Wd := B[10];
End;
{$ELSE}
Var A, B, C, E : Word;
Begin
  GetDate(A, B, C, E);
  Y := A; Mo := B; D := C; Wd := E;
  GetTime(A, B, C, E);
  H := A; Mi := B; S := C;
End;
{$ENDIF}

{ --- fichiers : poignee (OS/2 : handle ; Linux : descripteur) --- }

Function POpenRead(Name : String; Var H : LongInt) : Boolean;
{$IFDEF OS2PC}
Var A : LongInt;
Begin
  H := 0; A := 0;
  POpenRead := DosOpen(Z(Name), LongInt(@H), LongInt(@A), 0, 0, 1, $40, 0) = 0;
End;
{$ELSE}
Var K : LongInt;
Begin
  For K := 1 To Length(Name) Do If Name[K] = '\' Then Name[K] := '/';
  H := fpOpen(Name, O_RDONLY);
  POpenRead := H >= 0;
End;
{$ENDIF}

{ creer (ou vider) ; Append : ajouter a la fin }
Function POpenWrite(Name : String; Append : Boolean; Var H : LongInt) : Boolean;
{$IFDEF OS2PC}
Var A, P : LongInt;
Begin
  H := 0; A := 0;
  If Append Then
  Begin
    If DosOpen(Z(Name), LongInt(@H), LongInt(@A), 0, 0, $11, $41, 0) <> 0 Then
    Begin
      POpenWrite := False;
      Exit;
    End;
    P := 0;
    Dummy := DosSetFilePtr(H, 0, 2, LongInt(@P));
    POpenWrite := True;
  End
  Else POpenWrite := DosOpen(Z(Name), LongInt(@H), LongInt(@A), 0, 0, $12, $41, 0) = 0;
End;
{$ELSE}
Var K : LongInt;
Begin
  For K := 1 To Length(Name) Do If Name[K] = '\' Then Name[K] := '/';
  If Append Then H := fpOpen(Name, O_WRONLY Or O_CREAT Or O_APPEND, 420)
  Else H := fpOpen(Name, O_WRONLY Or O_CREAT Or O_TRUNC, 420);
  POpenWrite := H >= 0;
End;
{$ENDIF}

Function PRead(H : LongInt; P : PBytes; N : LongInt) : LongInt;
{$IFDEF OS2PC}
Var A : LongInt;
Begin
  A := 0;
  If DosRead(H, LongInt(P), N, LongInt(@A)) <> 0 Then PRead := -1 Else PRead := A;
End;
{$ELSE}
Begin
  PRead := fpRead(H, P^, N);
End;
{$ENDIF}

Function PWrite(H : LongInt; P : PBytes; N : LongInt) : LongInt;
{$IFDEF OS2PC}
Var A : LongInt;
Begin
  A := 0;
  If DosWrite(H, LongInt(P), N, LongInt(@A)) <> 0 Then PWrite := -1 Else PWrite := A;
End;
{$ELSE}
Begin
  PWrite := fpWrite(H, P^, N);
End;
{$ENDIF}

Procedure PSeek(H, Pos_ : LongInt);
{$IFDEF OS2PC}
Var A : LongInt;
Begin
  A := 0;
  Dummy := DosSetFilePtr(H, Pos_, 0, LongInt(@A));
End;
{$ELSE}
Begin
  fpLSeek(H, Pos_, Seek_Set);
End;
{$ENDIF}

Procedure PClose(H : LongInt);
Begin
  {$IFDEF OS2PC}
  Dummy := DosClose(H);
  {$ELSE}
  fpClose(H);
  {$ENDIF}
End;

{ secondes depuis le 1er janvier 1970 }
Function UnixTime(Y, Mo, D, H, Mi, S : LongInt) : LongInt;
Var Days, A, Yy, M2 : LongInt;
Begin
  { jours depuis 1970 (calendrier civil) }
  A := (14 - Mo) Div 12;
  Yy := Y + 4800 - A;
  M2 := Mo + 12 * A - 3;
  Days := D + (153 * M2 + 2) Div 5 + 365 * Yy + Yy Div 4 - Yy Div 100 + Yy Div 400 - 32045 - 2440588;
  UnixTime := Days * 86400 + H * 3600 + Mi * 60 + S;
End;

Function DosToUnix(Dt, Tm : LongInt) : LongInt;
Begin
  DosToUnix := UnixTime(1980 + ((Dt Shr 9) And 127), (Dt Shr 5) And 15, Dt And 31,
                        (Tm Shr 11) And 31, (Tm Shr 5) And 63, (Tm And 31) * 2);
End;

{ taille, date (secondes Unix) et genre d'un fichier }
Function PStat(Name : String; Var Size, MTime : LongInt; Var IsDir : Boolean) : Boolean;
{$IFDEF OS2PC}
Var B : Array[0..63] Of Byte;
Begin
  PStat := False;
  While (Length(Name) > 3) And (Name[Length(Name)] = '\') Do Delete(Name, Length(Name), 1);
  If DosQueryPathInfo(Z(Name), 1, LongInt(@B), 24) <> 0 Then Exit;
  Size := B[12] + B[13] * 256 + B[14] * 65536 + B[15] * 16777216;
  MTime := DosToUnix(B[8] + B[9] * 256, B[10] + B[11] * 256);
  IsDir := (B[20] And $10) <> 0;
  PStat := True;
End;
{$ELSE}
Var St : Stat; K : LongInt;
Begin
  For K := 1 To Length(Name) Do If Name[K] = '\' Then Name[K] := '/';
  PStat := fpStat(Name, St) = 0;
  Size := St.st_size; MTime := St.st_mtime;
  IsDir := fpS_ISDIR(St.st_mode);
End;
{$ENDIF}

Function PExists(Name : String) : Boolean;
Var Sz, Mt : LongInt; Dr : Boolean;
Begin
  PExists := PStat(Name, Sz, Mt, Dr);
End;

Procedure PMkDir(Name : String);
{$IFDEF OS2PC}
Begin
  Dummy := DosCreateDir(Z(Name), 0);
End;
{$ELSE}
Var K : LongInt;
Begin
  For K := 1 To Length(Name) Do If Name[K] = '\' Then Name[K] := '/';
  fpMkDir(Name, 493);
End;
{$ENDIF}

Function PDelete(Name : String) : Boolean;
{$IFDEF OS2PC}
Begin
  PDelete := DosDelete(Z(Name)) = 0;
End;
{$ELSE}
Var K : LongInt;
Begin
  For K := 1 To Length(Name) Do If Name[K] = '\' Then Name[K] := '/';
  PDelete := fpUnlink(Name) = 0;
End;
{$ENDIF}

{ parcours d'un repertoire : PFind(dossier, premier) -> nom, taille, date }
{$IFNDEF OS2PC}
Var
  FindDir : PDir;
  FindPath : String;
{$ENDIF}

Function PFindFirst(Dir : String; Var Nm : String; Var Size, MTime : LongInt; Var IsDir : Boolean) : Boolean;
{$IFDEF OS2PC}
Var N : LongInt;
Begin
  PFindFirst := False;
  FindH := -1; N := 1;
  If DosFindFirst(Z(Dir + '\*'), LongInt(@FindH), $37, LongInt(@FindBuf), 1024, LongInt(@N), 1) <> 0 Then Exit;
  Nm := '';
  For N := 0 To FindBuf[28] - 1 Do Nm := Nm + Chr(FindBuf[29 + N]);
  Size := FindBuf[16] + FindBuf[17] * 256 + FindBuf[18] * 65536 + FindBuf[19] * 16777216;
  MTime := DosToUnix(FindBuf[12] + FindBuf[13] * 256, FindBuf[14] + FindBuf[15] * 256);
  IsDir := (FindBuf[24] And $10) <> 0;
  PFindFirst := True;
End;
{$ELSE}
Var E : PDirent; St : Stat; K : LongInt;
Begin
  PFindFirst := False;
  For K := 1 To Length(Dir) Do If Dir[K] = '\' Then Dir[K] := '/';
  FindPath := Dir;
  FindDir := fpOpenDir(Dir);
  If FindDir = Nil Then Exit;
  E := fpReadDir(FindDir^);
  If E = Nil Then Exit;
  Nm := StrPas(@E^.d_name[0]);
  If fpStat(FindPath + '/' + Nm, St) = 0 Then
  Begin
    Size := St.st_size; MTime := St.st_mtime; IsDir := fpS_ISDIR(St.st_mode);
  End;
  PFindFirst := True;
End;
{$ENDIF}

Function PFindNext(Var Nm : String; Var Size, MTime : LongInt; Var IsDir : Boolean) : Boolean;
{$IFDEF OS2PC}
Var N : LongInt;
Begin
  PFindNext := False;
  N := 1;
  If DosFindNext(FindH, LongInt(@FindBuf), 1024, LongInt(@N)) <> 0 Then Exit;
  Nm := '';
  For N := 0 To FindBuf[28] - 1 Do Nm := Nm + Chr(FindBuf[29 + N]);
  Size := FindBuf[16] + FindBuf[17] * 256 + FindBuf[18] * 65536 + FindBuf[19] * 16777216;
  MTime := DosToUnix(FindBuf[12] + FindBuf[13] * 256, FindBuf[14] + FindBuf[15] * 256);
  IsDir := (FindBuf[24] And $10) <> 0;
  PFindNext := True;
End;
{$ELSE}
Var E : PDirent; St : Stat;
Begin
  PFindNext := False;
  If FindDir = Nil Then Exit;
  E := fpReadDir(FindDir^);
  If E = Nil Then Exit;
  Nm := StrPas(@E^.d_name[0]);
  If fpStat(FindPath + '/' + Nm, St) = 0 Then
  Begin
    Size := St.st_size; MTime := St.st_mtime; IsDir := fpS_ISDIR(St.st_mode);
  End;
  PFindNext := True;
End;
{$ENDIF}

Procedure PFindClose;
Begin
  {$IFDEF OS2PC}
  Dummy := DosFindClose(FindH);
  {$ELSE}
  If FindDir <> Nil Then fpCloseDir(FindDir^);
  FindDir := Nil;
  {$ENDIF}
End;

{ --- sockets --- }

Function PNetInit : Boolean;
Begin
  {$IFDEF OS2PC}
  PNetInit := Sock_Init = 0;
  MyIpAddr := SockHostId;
  {$ELSE}
  PNetInit := True;
  MyIpAddr := $7F000001;
  {$ENDIF}
End;

{ socket d'ecoute sur Port ; -1 : impossible }
Function PListen(Port : LongInt) : LongInt;
Var S, One : LongInt;
{$IFDEF OS2PC}
    A : Array[0..15] Of Byte; K : LongInt;
{$ELSE}
    A : TInetSockAddr;
{$ENDIF}
Begin
  PListen := -1;
  {$IFDEF OS2PC}
  S := SockSocket(2, 1, 0);
  If S < 0 Then Exit;
  For K := 0 To 15 Do A[K] := 0;
  A[0] := 16; A[1] := 2; A[2] := (Port Shr 8) And 255; A[3] := Port And 255;
  If (SockBind(S, LongInt(@A), 16) <> 0) Or (SockListen(S, 12) <> 0) Then
  Begin
    Dummy := SockClose(S);
    Exit;
  End;
  One := 1;
  Dummy := SockIoctl(S, $8004667E, LongInt(@One), 4);
  {$ELSE}
  S := fpSocket(AF_INET, SOCK_STREAM, 0);
  If S < 0 Then Exit;
  One := 1;
  fpSetSockOpt(S, SOL_SOCKET, SO_REUSEADDR, @One, 4);
  FillChar(A, SizeOf(A), 0);
  A.sin_family := AF_INET; A.sin_port := htons(Port); A.sin_addr.s_addr := 0;
  If (fpBind(S, @A, SizeOf(A)) <> 0) Or (fpListen(S, 64) <> 0) Then
  Begin
    fpClose(S);
    Exit;
  End;
  fpFcntl(S, F_SETFL, fpFcntl(S, F_GETFL) Or O_NONBLOCK);
  {$ENDIF}
  PListen := S;
End;

{ connexion en attente ; -1 : aucune }
Function PAccept(L : LongInt; Var Ip, Port, LocIp : LongInt) : LongInt;
Var S, One, N : LongInt;
{$IFDEF OS2PC}
    A, B : Array[0..15] Of Byte;
{$ELSE}
    A, B : TInetSockAddr; Len : TSockLen;
{$ENDIF}
Begin
  {$IFDEF OS2PC}
  N := 16;
  S := SockAccept(L, LongInt(@A), LongInt(@N));
  If S >= 0 Then
  Begin
    Port := A[2] * 256 + A[3];
    Ip := (A[4] Shl 24) Or (A[5] Shl 16) Or (A[6] Shl 8) Or A[7];
    One := 1;
    Dummy := SockIoctl(S, $8004667E, LongInt(@One), 4);
    N := 16;
    LocIp := MyIpAddr;
    If SockName(S, LongInt(@B), LongInt(@N)) = 0 Then
      LocIp := (B[4] Shl 24) Or (B[5] Shl 16) Or (B[6] Shl 8) Or B[7];
  End;
  {$ELSE}
  Len := SizeOf(A);
  S := fpAccept(L, @A, @Len);
  If S >= 0 Then
  Begin
    Port := ntohs(A.sin_port);
    Ip := LongInt(ntohl(A.sin_addr.s_addr));
    fpFcntl(S, F_SETFL, fpFcntl(S, F_GETFL) Or O_NONBLOCK);
    One := 1;
    fpSetSockOpt(S, 6, 1, @One, 4);
    Len := SizeOf(B);
    LocIp := $7F000001;
    If fpGetSockName(S, @B, @Len) = 0 Then LocIp := LongInt(ntohl(B.sin_addr.s_addr));
  End;
  N := 0;
  {$ENDIF}
  PAccept := S;
End;

{ > 0 : octets ; 0 : fin de la connexion ; -1 : rien pour l'instant ;
  -2 : erreur }
Function PRecv(S : LongInt; P : PBytes; N : LongInt) : LongInt;
Var R : LongInt;
Begin
  {$IFDEF OS2PC}
  R := SockRecv(S, LongInt(P), N, 0);
  If R < 0 Then
  Begin
    If SockErrno = 10035 Then R := -1 Else R := -2;
  End;
  {$ELSE}
  R := fpRecv(S, P, N, 0);
  If R < 0 Then
  Begin
    If (SocketError = ESysEAGAIN) Or (SocketError = ESysEINTR) Then R := -1 Else R := -2;
  End;
  {$ENDIF}
  PRecv := R;
End;

{ >= 0 : octets partis ; -2 : erreur }
Function PSend(S : LongInt; P : PBytes; N : LongInt) : LongInt;
Var R : LongInt;
Begin
  {$IFDEF OS2PC}
  R := SockSend(S, LongInt(P), N, 0);
  If R < 0 Then
  Begin
    If SockErrno = 10035 Then R := 0 Else R := -2;
  End;
  {$ELSE}
  R := fpSend(S, P, N, MSG_NOSIGNAL);
  If R < 0 Then
  Begin
    If (SocketError = ESysEAGAIN) Or (SocketError = ESysEINTR) Then R := 0 Else R := -2;
  End;
  {$ENDIF}
  PSend := R;
End;

Procedure PSockClose(S : LongInt);
Begin
  {$IFDEF OS2PC}
  Dummy := SockClose(S);
  {$ELSE}
  fpShutdown(S, 1);
  fpClose(S);
  {$ENDIF}
End;

{ attente : ensembles de sockets a lire et a ecrire (masques de bits,
  128 descripteurs sous OS/2, 1024 sous Linux) ; Ms : delai }
Const
  FdWords = 32;
Type
  TFdMask = Array[0..FdWords - 1] Of LongInt;

Procedure FdZero(Var M : TFdMask);
Var K : LongInt;
Begin
  For K := 0 To FdWords - 1 Do M[K] := 0;
End;

Procedure FdSet(Var M : TFdMask; D : LongInt);
Begin
  If (D >= 0) And (D < FdWords * 32) Then M[D Shr 5] := M[D Shr 5] Or (1 Shl (D And 31));
End;

Function FdIsSet(Var M : TFdMask; D : LongInt) : Boolean;
Begin
  If (D < 0) Or (D >= FdWords * 32) Then FdIsSet := False
  Else FdIsSet := ((M[D Shr 5] Shr (D And 31)) And 1) <> 0;
End;

Function PSelect(Var R, W : TFdMask; MaxFd, Ms : LongInt) : LongInt;
{$IFDEF OS2PC}
Var Tv : Array[0..1] Of LongInt;
Begin
  Tv[0] := Ms Div 1000; Tv[1] := (Ms Mod 1000) * 1000;
  If MaxFd > 128 Then MaxFd := 128;
  PSelect := SockSelect(MaxFd, LongInt(@R), LongInt(@W), 0, LongInt(@Tv));
End;
{$ELSE}
Var Tv : TTimeVal;
Begin
  Tv.tv_sec := Ms Div 1000; Tv.tv_usec := (Ms Mod 1000) * 1000;
  PSelect := fpSelect(MaxFd, @R, @W, Nil, @Tv);
End;
{$ENDIF}

{ octets aleatoires (cles TLS, identificateurs de session) }
Var
  RndPool : Array[0..63] Of LongInt;
  RndCtr : LongInt;

Function PRdtsc : LongInt;
{$IFDEF OS2PC}
Var V : LongInt;
Begin
  asm
    db 0Fh, 31h
    mov V,eax
  end;
  PRdtsc := V;
End;
{$ELSE}
Var T : TTimeVal;
Begin
  fpGetTimeOfDay(@T, Nil);
  PRdtsc := LongInt(T.tv_usec * 7919 + T.tv_sec);
End;
{$ENDIF}

{ ==================================================================== }
{ Utilitaires                                                           }
{ ==================================================================== }

Function IStr(V : LongInt) : String;
Var S : String;
Begin
  Str(V, S);
  IStr := S;
End;

Function UpStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do S[K] := UpCase(S[K]);
  UpStr := S;
End;

Function LoStr(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do
    If (S[K] >= 'A') And (S[K] <= 'Z') Then S[K] := Chr(Ord(S[K]) + 32);
  LoStr := S;
End;

Function Trim(S : String) : String;
Begin
  While (Length(S) > 0) And (S[1] <= ' ') Do Delete(S, 1, 1);
  While (Length(S) > 0) And (S[Length(S)] <= ' ') Do Delete(S, Length(S), 1);
  Trim := S;
End;

Function SVal(S : String) : LongInt;
Var V, K : LongInt; Neg : Boolean;
Begin
  S := Trim(S);
  V := 0; Neg := False; K := 1;
  If (Length(S) > 0) And (S[1] = '-') Then
  Begin
    Neg := True; K := 2;
  End;
  While (K <= Length(S)) And (S[K] >= '0') And (S[K] <= '9') Do
  Begin
    V := V * 10 + Ord(S[K]) - 48;
    Inc(K);
  End;
  If Neg Then V := -V;
  SVal := V;
End;

Function IsNum(S : String) : Boolean;
Var K : LongInt;
Begin
  IsNum := False;
  If S = '' Then Exit;
  For K := 1 To Length(S) Do If (S[K] < '0') Or (S[K] > '9') Then Exit;
  IsNum := True;
End;

Function Hex(V, N : LongInt) : String;
Const H : String[16] = '0123456789ABCDEF';
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 1 To N Do
  Begin
    S := H[(V And 15) + 1] + S;
    V := V Shr 4;
  End;
  Hex := S;
End;

Function Pad2(V : LongInt) : String;
Begin
  If V < 10 Then Pad2 := '0' + IStr(V) Else Pad2 := IStr(V);
End;

Function IpStr(V : LongInt) : String;
Begin
  IpStr := IStr((V Shr 24) And 255) + '.' + IStr((V Shr 16) And 255) + '.' + IStr((V Shr 8) And 255) + '.' +
           IStr(V And 255);
End;

{ "a.b.c.d" -> adresse ; 0 : invalide ou "*" }
Function ParseIp(S : String) : LongInt;
Var K, V, N, R : LongInt;
Begin
  ParseIp := 0;
  R := 0; N := 0; V := -1;
  S := Trim(S) + '.';
  For K := 1 To Length(S) Do
    If (S[K] >= '0') And (S[K] <= '9') Then
    Begin
      If V < 0 Then V := 0;
      V := V * 10 + Ord(S[K]) - 48;
      If V > 255 Then Exit;
    End
    Else If S[K] = '.' Then
    Begin
      If V < 0 Then Exit;
      R := (R Shl 8) Or V;
      Inc(N); V := -1;
    End
    Else Exit;
  If N = 4 Then ParseIp := R;
End;

{ taille lisible }
Function SizeStr(V : LongInt) : String;
Begin
  If V < 1024 Then SizeStr := IStr(V) + ' o'
  Else If V < 1048576 Then SizeStr := IStr((V + 512) Div 1024) + ' Ko'
  Else SizeStr := IStr(V Div 1048576) + ',' + IStr((V Mod 1048576) * 10 Div 1048576) + ' Mo';
End;

Const
  DayNames : Array[0..6] Of String[3] = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
  MonNames : Array[1..12] Of String[3] = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct',
                                          'Nov', 'Dec');

{ secondes Unix -> date ; Wd : jour de la semaine (0 dimanche) }
Procedure UnixSplit(T : LongInt; Var Y, Mo, D, H, Mi, S, Wd : LongInt);
Var Days, Z_, Era, Doe, Yoe, Doy, Mp : LongInt;
Begin
  If T < 0 Then T := 0;
  Days := T Div 86400;
  T := T Mod 86400;
  H := T Div 3600; Mi := (T Div 60) Mod 60; S := T Mod 60;
  Wd := (Days + 4) Mod 7;
  Z_ := Days + 719468;
  Era := Z_ Div 146097;
  Doe := Z_ - Era * 146097;
  Yoe := (Doe - Doe Div 1460 + Doe Div 36524 - Doe Div 146096) Div 365;
  Y := Yoe + Era * 400;
  Doy := Doe - (365 * Yoe + Yoe Div 4 - Yoe Div 100);
  Mp := (5 * Doy + 2) Div 153;
  D := Doy - (153 * Mp + 2) Div 5 + 1;
  If Mp < 10 Then Mo := Mp + 3 Else Mo := Mp - 9;
  If Mo <= 2 Then Inc(Y);
End;

{ date du protocole HTTP (RFC 1123), heure locale tenue pour l'heure GMT }
Function HttpDate(T : LongInt) : String;
Var Y, Mo, D, H, Mi, S, Wd : LongInt;
Begin
  UnixSplit(T, Y, Mo, D, H, Mi, S, Wd);
  HttpDate := DayNames[Wd] + ', ' + Pad2(D) + ' ' + MonNames[Mo] + ' ' + IStr(Y) + ' ' + Pad2(H) + ':' + Pad2(Mi) +
              ':' + Pad2(S) + ' GMT';
End;

Function NowUnix : LongInt;
Var Y, Mo, D, H, Mi, S, Wd : LongInt;
Begin
  PNow(Y, Mo, D, H, Mi, S, Wd);
  NowUnix := UnixTime(Y, Mo, D, H, Mi, S);
End;

{ "Sun, 06 Nov 1994 08:49:37 GMT" -> secondes ; -1 : illisible }
Function ParseHttpDate(S : String) : LongInt;
Var P, D, Mo, Y, H, Mi, Sc, K : LongInt; W : String;
Begin
  ParseHttpDate := -1;
  P := Pos(',', S);
  If P = 0 Then Exit;
  S := Trim(Copy(S, P + 1, 255));
  P := Pos(' ', S);
  If P = 0 Then Exit;
  D := SVal(Copy(S, 1, P - 1));
  S := Trim(Copy(S, P + 1, 255));
  W := Copy(S, 1, 3);
  Mo := 0;
  For K := 1 To 12 Do If UpStr(MonNames[K]) = UpStr(W) Then Mo := K;
  If Mo = 0 Then Exit;
  S := Trim(Copy(S, 4, 255));
  P := Pos(' ', S);
  If P = 0 Then Exit;
  Y := SVal(Copy(S, 1, P - 1));
  S := Trim(Copy(S, P + 1, 255));
  H := SVal(Copy(S, 1, 2)); Mi := SVal(Copy(S, 4, 2)); Sc := SVal(Copy(S, 7, 2));
  ParseHttpDate := UnixTime(Y, Mo, D, H, Mi, Sc);
End;

{ %xx et + (requete) }
Function UrlDecode(S : String; Plus : Boolean) : String;
Var R : String; K, V : LongInt;

  Function HV(C : Char) : LongInt;
  Begin
    C := UpCase(C);
    If (C >= '0') And (C <= '9') Then HV := Ord(C) - 48
    Else If (C >= 'A') And (C <= 'F') Then HV := Ord(C) - 55
    Else HV := -1;
  End;

Begin
  R := '';
  K := 1;
  While K <= Length(S) Do
  Begin
    If (S[K] = '%') And (K + 2 <= Length(S)) And (HV(S[K + 1]) >= 0) And (HV(S[K + 2]) >= 0) Then
    Begin
      V := HV(S[K + 1]) * 16 + HV(S[K + 2]);
      R := R + Chr(V);
      K := K + 3;
    End
    Else
    Begin
      If Plus And (S[K] = '+') Then R := R + ' ' Else R := R + S[K];
      Inc(K);
    End;
  End;
  UrlDecode := R;
End;

Function UrlEncode(S : String) : String;
Var R : String; K : LongInt; C : Char;
Begin
  R := '';
  For K := 1 To Length(S) Do
  Begin
    C := S[K];
    If ((C >= 'A') And (C <= 'Z')) Or ((C >= 'a') And (C <= 'z')) Or ((C >= '0') And (C <= '9')) Or
       (C = '-') Or (C = '_') Or (C = '.') Or (C = '~') Then R := R + C
    Else If C = ' ' Then R := R + '+'
    Else R := R + '%' + Hex(Ord(C), 2);
  End;
  UrlEncode := R;
End;

{ chemin d'une URL (les / restent) }
Function UrlPathEncode(S : String) : String;
Var R : String; K : LongInt; C : Char;
Begin
  R := '';
  For K := 1 To Length(S) Do
  Begin
    C := S[K];
    If (C <= ' ') Or (C >= #127) Or (C = '%') Or (C = '"') Or (C = '#') Or (C = '?') Or (C = '<') Or (C = '>') Then
      R := R + '%' + Hex(Ord(C), 2)
    Else R := R + C;
  End;
  UrlPathEncode := R;
End;

Function HtmlEnc(S : String) : String;
Var R : String; K : LongInt;
Begin
  R := '';
  For K := 1 To Length(S) Do
    Case S[K] Of
      '<' : R := R + '&lt;';
      '>' : R := R + '&gt;';
      '&' : R := R + '&amp;';
      '"' : R := R + '&quot;';
    Else
      R := R + S[K];
    End;
  HtmlEnc := R;
End;

{ CP850 (OS/2) -> UTF-8 pour les pages produites par le serveur }
Function Cp850Utf8(S : String) : String;
Const
  T : Array[128..255] Of Word = (
    $C7, $FC, $E9, $E2, $E4, $E0, $E5, $E7, $EA, $EB, $E8, $EF, $EE, $EC, $C4, $C5,
    $C9, $E6, $C6, $F4, $F6, $F2, $FB, $F9, $FF, $D6, $DC, $F8, $A3, $D8, $D7, $192,
    $E1, $ED, $F3, $FA, $F1, $D1, $AA, $BA, $BF, $AE, $AC, $BD, $BC, $A1, $AB, $BB,
    $2591, $2592, $2593, $2502, $2524, $C1, $C2, $C0, $A9, $2563, $2551, $2557, $255D, $A2, $A5, $2510,
    $2514, $2534, $252C, $251C, $2500, $253C, $E3, $C3, $255A, $2554, $2569, $2566, $2560, $2550, $256C, $A4,
    $F0, $D0, $CA, $CB, $C8, $131, $CD, $CE, $CF, $2518, $250C, $2588, $2584, $A6, $CC, $2580,
    $D3, $DF, $D4, $D2, $F5, $D5, $B5, $FE, $DE, $DA, $DB, $D9, $FD, $DD, $AF, $B4,
    $AD, $B1, $2017, $BE, $B6, $A7, $F7, $B8, $B0, $A8, $B7, $B9, $B3, $B2, $25A0, $A0);
Var R : String; K, U : LongInt;
Begin
  R := '';
  For K := 1 To Length(S) Do
    If Ord(S[K]) < 128 Then R := R + S[K]
    Else
    Begin
      U := T[Ord(S[K])];
      If U < $800 Then R := R + Chr($C0 Or (U Shr 6)) + Chr($80 Or (U And $3F))
      Else R := R + Chr($E0 Or (U Shr 12)) + Chr($80 Or ((U Shr 6) And $3F)) + Chr($80 Or (U And $3F));
    End;
  Cp850Utf8 := R;
End;

{ --- tampon d'octets qui grandit (reponses, pages compilees) --- }
Type
  TBuf = Record
    P : PBytes;
    Len, Cap : LongInt;
  End;

Procedure BufInit(Var B : TBuf);
Begin
  B.P := Nil; B.Len := 0; B.Cap := 0;
End;

Procedure BufFree(Var B : TBuf);
Begin
  If B.P <> Nil Then FreeMem(B.P, B.Cap);
  B.P := Nil; B.Len := 0; B.Cap := 0;
End;

Function BufGrow(Var B : TBuf; Need : LongInt) : Boolean;
Var N : LongInt; Q : PBytes;
Begin
  BufGrow := True;
  If B.Len + Need <= B.Cap Then Exit;
  If (Need < 0) Or (Need > 134217728) Or (B.Len + Need > 134217728) Then
  Begin
    BufGrow := False;
    Exit;
  End;
  N := B.Cap * 2;
  If N < 4096 Then N := 4096;
  While N < B.Len + Need Do N := N * 2;
  GetMem(Q, N);
  If Q = Nil Then
  Begin
    BufGrow := False;
    Exit;
  End;
  If B.Len > 0 Then Move(B.P^[0], Q^[0], B.Len);
  If B.P <> Nil Then FreeMem(B.P, B.Cap);
  B.P := Q; B.Cap := N;
End;

Procedure BufAdd(Var B : TBuf; Const S : String);
Begin
  If Length(S) = 0 Then Exit;
  If Not BufGrow(B, Length(S)) Then Exit;
  Move(S[1], B.P^[B.Len], Length(S));
  B.Len := B.Len + Length(S);
End;

Procedure BufAddB(Var B : TBuf; P : PBytes; N : LongInt);
Begin
  If N <= 0 Then Exit;
  If Not BufGrow(B, N) Then Exit;
  Move(P^[0], B.P^[B.Len], N);
  B.Len := B.Len + N;
End;

Procedure BufAddC(Var B : TBuf; V : LongInt);
Begin
  If Not BufGrow(B, 1) Then Exit;
  B.P^[B.Len] := V;
  Inc(B.Len);
End;

{ --- base64 --- }
Const
  B64 : String[64] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

Procedure B64Enc(P : PBytes; N : LongInt; Var B : TBuf; LineLen : LongInt);
Var K, V, Col : LongInt;
Begin
  K := 0; Col := 0;
  While K < N Do
  Begin
    V := P^[K] Shl 16;
    If K + 1 < N Then V := V Or (P^[K + 1] Shl 8);
    If K + 2 < N Then V := V Or P^[K + 2];
    BufAddC(B, Ord(B64[((V Shr 18) And 63) + 1]));
    BufAddC(B, Ord(B64[((V Shr 12) And 63) + 1]));
    If K + 1 < N Then BufAddC(B, Ord(B64[((V Shr 6) And 63) + 1])) Else BufAddC(B, Ord('='));
    If K + 2 < N Then BufAddC(B, Ord(B64[(V And 63) + 1])) Else BufAddC(B, Ord('='));
    K := K + 3;
    Col := Col + 4;
    If (LineLen > 0) And (Col >= LineLen) And (K < N) Then
    Begin
      BufAddC(B, 10);
      Col := 0;
    End;
  End;
End;

{ decode (les caracteres hors de l'alphabet sont sautes) ; rend la taille }
Function B64Dec(Src : PBytes; N : LongInt; Dst : PBytes; Max : LongInt) : LongInt;
Var K, V, Bits, O, C, D : LongInt;
Begin
  V := 0; Bits := 0; O := 0;
  For K := 0 To N - 1 Do
  Begin
    C := Src^[K];
    If (C >= 65) And (C <= 90) Then D := C - 65
    Else If (C >= 97) And (C <= 122) Then D := C - 71
    Else If (C >= 48) And (C <= 57) Then D := C + 4
    Else If C = 43 Then D := 62
    Else If C = 47 Then D := 63
    Else D := -1;
    If D >= 0 Then
    Begin
      V := (V Shl 6) Or D;
      Bits := Bits + 6;
      If Bits >= 8 Then
      Begin
        Bits := Bits - 8;
        If O < Max Then Dst^[O] := (V Shr Bits) And 255;
        Inc(O);
      End;
    End;
  End;
  B64Dec := O;
End;

Function B64Str(S : String) : String;
Var B : TBuf; R : String; K : LongInt;
Begin
  BufInit(B);
  B64Enc(@S[1], Length(S), B, 0);
  R := '';
  For K := 0 To B.Len - 1 Do If Length(R) < 255 Then R := R + Chr(B.P^[K]);
  BufFree(B);
  B64Str := R;
End;

Function B64DecStr(S : String) : String;
Var R : String; N : LongInt;
Begin
  N := B64Dec(@S[1], Length(S), @R[1], 255);
  If N > 255 Then N := 255;
  R[0] := Chr(N);
  B64DecStr := R;
End;

{ --- lecture d'un fichier entier --- }
Function ReadFileBuf(Name : String; Var B : TBuf; Max : LongInt) : Boolean;
Var H, N : LongInt;
Begin
  ReadFileBuf := False;
  BufInit(B);
  If Not POpenRead(Name, H) Then Exit;
  Repeat
    If Not BufGrow(B, 16384) Then Break;
    N := PRead(H, @B.P^[B.Len], 16384);
    If N > 0 Then B.Len := B.Len + N;
  Until (N <= 0) Or (B.Len >= Max);
  PClose(H);
  ReadFileBuf := True;
End;

Function WriteFileBuf(Name : String; P : PBytes; N : LongInt) : Boolean;
Var H : LongInt;
Begin
  WriteFileBuf := False;
  If Not POpenWrite(Name, False, H) Then Exit;
  WriteFileBuf := PWrite(H, P, N) = N;
  PClose(H);
End;

{ journal du serveur (WEBSRV.LOG) }
Procedure SysLog(S : String);
Var H, Y, Mo, D, Hh, Mi, Sc, Wd : LongInt; L : String;
Begin
  PNow(Y, Mo, D, Hh, Mi, Sc, Wd);
  L := IStr(Y) + '-' + Pad2(Mo) + '-' + Pad2(D) + ' ' + Pad2(Hh) + ':' + Pad2(Mi) + ':' + Pad2(Sc) + ' ' + S;
  LogMsg := S;
  If (Not ServiceMode) And (Not Quiet) Then WriteLn(L);
  If WwwData = '' Then Exit;
  If POpenWrite(WwwData + '\WEBSRV.LOG', True, H) Then
  Begin
    L := L + Crlf;
    Dummy := PWrite(H, @L[1], Length(L));
    PClose(H);
  End;
End;

{ ==================================================================== }
{ Cryptographie : SHA-256, HMAC, HKDF, AES-128-GCM, X25519 (repris de   }
{ TLS32.DLL), P-256 et ECDSA (signature du serveur), certificats X.509  }
{ Le code tourne dans le programme (preemptible) et non dans une DLL :   }
{ une poignee de main ne bloque jamais le reste du systeme.             }
{ ==================================================================== }

Const
  ShK : Array[0..63] Of LongInt = (
    $428A2F98, $71374491, $B5C0FBCF, $E9B5DBA5, $3956C25B, $59F111F1, $923F82A4, $AB1C5ED5,
    $D807AA98, $12835B01, $243185BE, $550C7DC3, $72BE5D74, $80DEB1FE, $9BDC06A7, $C19BF174,
    $E49B69C1, $EFBE4786, $0FC19DC6, $240CA1CC, $2DE92C6F, $4A7484AA, $5CB0A9DC, $76F988DA,
    $983E5152, $A831C66D, $B00327C8, $BF597FC7, $C6E00BF3, $D5A79147, $06CA6351, $14292967,
    $27B70A85, $2E1B2138, $4D2C6DFC, $53380D13, $650A7354, $766A0ABB, $81C2C92E, $92722C85,
    $A2BFE8A1, $A81A664B, $C24B8B70, $C76C51A3, $D192E819, $D6990624, $F40E3585, $106AA070,
    $19A4C116, $1E376C08, $2748774C, $34B0BCB5, $391C0CB3, $4ED8AA4A, $5B9CCA4F, $682E6FF3,
    $748F82EE, $78A5636F, $84C87814, $8CC70208, $90BEFFFA, $A4506CEB, $BEF9A3F7, $C67178F2);
  ShIv : Array[0..7] Of LongInt = ($6A09E667, $BB67AE85, $3C6EF372, $A54FF53A, $510E527F, $9B05688C,
    $1F83D9AB, $5BE0CD19);
  SBox : Array[0..255] Of Byte = (
    $63, $7C, $77, $7B, $F2, $6B, $6F, $C5, $30, $01, $67, $2B, $FE, $D7, $AB, $76,
    $CA, $82, $C9, $7D, $FA, $59, $47, $F0, $AD, $D4, $A2, $AF, $9C, $A4, $72, $C0,
    $B7, $FD, $93, $26, $36, $3F, $F7, $CC, $34, $A5, $E5, $F1, $71, $D8, $31, $15,
    $04, $C7, $23, $C3, $18, $96, $05, $9A, $07, $12, $80, $E2, $EB, $27, $B2, $75,
    $09, $83, $2C, $1A, $1B, $6E, $5A, $A0, $52, $3B, $D6, $B3, $29, $E3, $2F, $84,
    $53, $D1, $00, $ED, $20, $FC, $B1, $5B, $6A, $CB, $BE, $39, $4A, $4C, $58, $CF,
    $D0, $EF, $AA, $FB, $43, $4D, $33, $85, $45, $F9, $02, $7F, $50, $3C, $9F, $A8,
    $51, $A3, $40, $8F, $92, $9D, $38, $F5, $BC, $B6, $DA, $21, $10, $FF, $F3, $D2,
    $CD, $0C, $13, $EC, $5F, $97, $44, $17, $C4, $A7, $7E, $3D, $64, $5D, $19, $73,
    $60, $81, $4F, $DC, $22, $2A, $90, $88, $46, $EE, $B8, $14, $DE, $5E, $0B, $DB,
    $E0, $32, $3A, $0A, $49, $06, $24, $5C, $C2, $D3, $AC, $62, $91, $95, $E4, $79,
    $E7, $C8, $37, $6D, $8D, $D5, $4E, $A9, $6C, $56, $F4, $EA, $65, $7A, $AE, $08,
    $BA, $78, $25, $2E, $1C, $A6, $B4, $C6, $E8, $DD, $74, $1F, $4B, $BD, $8B, $8A,
    $70, $3E, $B5, $66, $48, $03, $F6, $0E, $61, $35, $57, $B9, $86, $C1, $1D, $9E,
    $E1, $F8, $98, $11, $69, $D9, $8E, $94, $9B, $1E, $87, $E9, $CE, $55, $28, $DF,
    $8C, $A1, $89, $0D, $BF, $E6, $42, $68, $41, $99, $2D, $0F, $B0, $54, $BB, $16);

Type
  TSha = Record
    H : Array[0..7] Of LongInt;
    B : Array[0..63] Of Byte;
    N, T : LongInt;
  End;
  TB32 = Array[0..31] Of Byte;
  TBlk = Array[0..15] Of Byte;
  TFe = Array[0..31] Of LongInt;
  TGx = Array[0..3] Of LongInt;
  TAes = Record
    Rk : Array[0..175] Of Byte;
    H : Array[0..3] Of LongInt;   { cle de GHASH }
    Iv : Array[0..11] Of Byte;
    Seq : LongInt;
  End;

Var
  Xt2 : Array[0..255] Of Byte;

{ decalage logique a droite (1 <= N <= 31) }
Function Sr(X, N : LongInt) : LongInt;
Begin
  Sr := (X Shr N) And ($7FFFFFFF Shr (N - 1));
End;

Function Ror(X, N : LongInt) : LongInt;
Begin
  Ror := Sr(X, N) Or (X Shl (32 - N));
End;

Procedure ShaInit(Var C : TSha);
Var I : LongInt;
Begin
  For I := 0 To 7 Do C.H[I] := ShIv[I];
  C.N := 0; C.T := 0;
End;

Procedure ShaBlock(Var C : TSha);
Var W : Array[0..63] Of LongInt;
    A, B, Cc, D, E, F, G, H, T1, T2, I, X : LongInt;
Begin
  For I := 0 To 15 Do
    W[I] := (C.B[I * 4] Shl 24) Or (C.B[I * 4 + 1] Shl 16) Or (C.B[I * 4 + 2] Shl 8) Or C.B[I * 4 + 3];
  For I := 16 To 63 Do
  Begin
    X := W[I - 15];
    T1 := Ror(X, 7) Xor Ror(X, 18) Xor Sr(X, 3);
    X := W[I - 2];
    T2 := Ror(X, 17) Xor Ror(X, 19) Xor Sr(X, 10);
    W[I] := W[I - 16] + T1 + W[I - 7] + T2;
  End;
  A := C.H[0]; B := C.H[1]; Cc := C.H[2]; D := C.H[3];
  E := C.H[4]; F := C.H[5]; G := C.H[6]; H := C.H[7];
  For I := 0 To 63 Do
  Begin
    T1 := H + (Ror(E, 6) Xor Ror(E, 11) Xor Ror(E, 25)) + ((E And F) Xor ((Not E) And G)) + ShK[I] + W[I];
    T2 := (Ror(A, 2) Xor Ror(A, 13) Xor Ror(A, 22)) + ((A And B) Xor (A And Cc) Xor (B And Cc));
    H := G; G := F; F := E; E := D + T1;
    D := Cc; Cc := B; B := A; A := T1 + T2;
  End;
  C.H[0] := C.H[0] + A; C.H[1] := C.H[1] + B; C.H[2] := C.H[2] + Cc; C.H[3] := C.H[3] + D;
  C.H[4] := C.H[4] + E; C.H[5] := C.H[5] + F; C.H[6] := C.H[6] + G; C.H[7] := C.H[7] + H;
End;

Procedure ShaUpd(Var C : TSha; P : PBytes; N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do
  Begin
    C.B[C.N] := P^[K];
    Inc(C.N);
    If C.N = 64 Then
    Begin
      ShaBlock(C);
      C.N := 0;
    End;
  End;
  C.T := C.T + N;
End;

Procedure ShaStr(Var C : TSha; S : String);
Begin
  If Length(S) > 0 Then ShaUpd(C, @S[1], Length(S));
End;

Procedure ShaFinal(Var C0 : TSha; Var Out_ : TB32);
Var C : TSha; L, I, V : LongInt; Pd : Array[0..71] Of Byte;
Begin
  C := C0;
  L := C.T;
  I := 0;
  Pd[0] := $80;
  I := 1;
  While ((C.N + I) Mod 64) <> 56 Do
  Begin
    Pd[I] := 0;
    Inc(I);
  End;
  Pd[I] := 0; Pd[I + 1] := 0; Pd[I + 2] := 0; Pd[I + 3] := Sr(L, 29);
  V := L Shl 3;
  Pd[I + 4] := Sr(V, 24); Pd[I + 5] := Sr(V, 16) And 255; Pd[I + 6] := Sr(V, 8) And 255; Pd[I + 7] := V And 255;
  ShaUpd(C, @Pd, I + 8);
  For I := 0 To 7 Do
  Begin
    V := C.H[I];
    Out_[I * 4] := Sr(V, 24); Out_[I * 4 + 1] := Sr(V, 16) And 255;
    Out_[I * 4 + 2] := Sr(V, 8) And 255; Out_[I * 4 + 3] := V And 255;
  End;
End;

Procedure Sha256(P : PBytes; N : LongInt; Var Out_ : TB32);
Var C : TSha;
Begin
  ShaInit(C);
  ShaUpd(C, P, N);
  ShaFinal(C, Out_);
End;

Procedure Hmac(K : PBytes; KN : LongInt; M : PBytes; MN : LongInt; Var Out_ : TB32);
Var Kb : Array[0..63] Of Byte; I : LongInt; C : TSha; Inner : TB32;
Begin
  For I := 0 To 63 Do Kb[I] := 0;
  If KN > 64 Then
  Begin
    Sha256(K, KN, Inner);
    For I := 0 To 31 Do Kb[I] := Inner[I];
  End
  Else
    For I := 0 To KN - 1 Do Kb[I] := K^[I];
  For I := 0 To 63 Do Kb[I] := Kb[I] Xor $36;
  ShaInit(C);
  ShaUpd(C, @Kb, 64);
  ShaUpd(C, M, MN);
  ShaFinal(C, Inner);
  For I := 0 To 63 Do Kb[I] := Kb[I] Xor $36 Xor $5C;
  ShaInit(C);
  ShaUpd(C, @Kb, 64);
  ShaUpd(C, @Inner, 32);
  ShaFinal(C, Out_);
End;

{ HKDF-Expand-Label(Secret, Label, Context, L) ; L <= 32 }
Procedure ExpandLabel(Var Sec : TB32; Lbl : String; Ctx : PBytes; CtxN, L : LongInt; Out_ : PBytes);
Var Info : Array[0..127] Of Byte; N, I : LongInt; S : String; T : TB32;
Begin
  S := 'tls13 ' + Lbl;
  Info[0] := L Shr 8; Info[1] := L And 255;
  Info[2] := Length(S);
  For I := 1 To Length(S) Do Info[2 + I] := Ord(S[I]);
  N := 3 + Length(S);
  Info[N] := CtxN; Inc(N);
  For I := 0 To CtxN - 1 Do Info[N + I] := Ctx^[I];
  N := N + CtxN;
  Info[N] := 1; Inc(N);
  Hmac(@Sec, 32, @Info, N, T);
  For I := 0 To L - 1 Do Out_^[I] := T[I];
End;

{ --- AES-128 (chiffrement seulement : mode compteur de GCM) --- }

Procedure AesInitTables;
Var I, V : LongInt;
Begin
  For I := 0 To 255 Do
  Begin
    V := I Shl 1;
    If V > 255 Then V := (V Xor $1B) And 255;
    Xt2[I] := V;
  End;
End;

Procedure AesEnc(Var A : TAes; Var S : TBlk);
Var T : TBlk; R, C, A0, A1, A2, A3, I : LongInt;
Begin
  For I := 0 To 15 Do S[I] := S[I] Xor A.Rk[I];
  For R := 1 To 10 Do
  Begin
    For C := 0 To 3 Do
    Begin
      T[C * 4] := SBox[S[C * 4]];
      T[C * 4 + 1] := SBox[S[((C + 1) And 3) * 4 + 1]];
      T[C * 4 + 2] := SBox[S[((C + 2) And 3) * 4 + 2]];
      T[C * 4 + 3] := SBox[S[((C + 3) And 3) * 4 + 3]];
    End;
    If R < 10 Then
    Begin
      For C := 0 To 3 Do
      Begin
        A0 := T[C * 4]; A1 := T[C * 4 + 1]; A2 := T[C * 4 + 2]; A3 := T[C * 4 + 3];
        S[C * 4] := Xt2[A0] Xor Xt2[A1] Xor A1 Xor A2 Xor A3;
        S[C * 4 + 1] := A0 Xor Xt2[A1] Xor Xt2[A2] Xor A2 Xor A3;
        S[C * 4 + 2] := A0 Xor A1 Xor Xt2[A2] Xor Xt2[A3] Xor A3;
        S[C * 4 + 3] := Xt2[A0] Xor A0 Xor A1 Xor A2 Xor Xt2[A3];
      End;
    End
    Else
      For I := 0 To 15 Do S[I] := T[I];
    For I := 0 To 15 Do S[I] := S[I] Xor A.Rk[R * 16 + I];
  End;
End;

{ cle (16 octets) et vecteur (12 octets) d'un sens de la connexion }
Procedure GcmInit(Var A : TAes; Key, Iv : PBytes);
Var I, J : LongInt; T : Array[0..3] Of Byte; Rc, X : LongInt; B : TBlk;
Begin
  For I := 0 To 15 Do A.Rk[I] := Key^[I];
  Rc := 1;
  I := 16;
  While I < 176 Do
  Begin
    For J := 0 To 3 Do T[J] := A.Rk[I - 4 + J];
    If (I Mod 16) = 0 Then
    Begin
      X := T[0];
      T[0] := SBox[T[1]] Xor Rc; T[1] := SBox[T[2]]; T[2] := SBox[T[3]]; T[3] := SBox[X];
      Rc := Xt2[Rc];
    End;
    For J := 0 To 3 Do A.Rk[I + J] := A.Rk[I - 16 + J] Xor T[J];
    I := I + 4;
  End;
  For I := 0 To 15 Do B[I] := 0;
  AesEnc(A, B);
  For I := 0 To 3 Do A.H[I] := (B[I * 4] Shl 24) Or (B[I * 4 + 1] Shl 16) Or (B[I * 4 + 2] Shl 8) Or B[I * 4 + 3];
  For I := 0 To 11 Do A.Iv[I] := Iv^[I];
  A.Seq := 0;
End;

Procedure GfMul(Var A : TAes; Var GX : TGx);
Var Z0, Z1, Z2, Z3, V0, V1, V2, V3, W, I, J, L : LongInt;
Begin
  Z0 := 0; Z1 := 0; Z2 := 0; Z3 := 0;
  V0 := A.H[0]; V1 := A.H[1]; V2 := A.H[2]; V3 := A.H[3];
  For I := 0 To 3 Do
  Begin
    W := GX[I];
    For J := 31 DownTo 0 Do
    Begin
      If ((W Shr J) And 1) <> 0 Then
      Begin
        Z0 := Z0 Xor V0; Z1 := Z1 Xor V1; Z2 := Z2 Xor V2; Z3 := Z3 Xor V3;
      End;
      L := V3 And 1;
      V3 := Sr(V3, 1) Or (V2 Shl 31);
      V2 := Sr(V2, 1) Or (V1 Shl 31);
      V1 := Sr(V1, 1) Or (V0 Shl 31);
      V0 := Sr(V0, 1);
      If L <> 0 Then V0 := V0 Xor LongInt($E1000000);
    End;
  End;
  GX[0] := Z0; GX[1] := Z1; GX[2] := Z2; GX[3] := Z3;
End;

Procedure GhashBlk(Var A : TAes; Var GX : TGx; P : PBytes; N : LongInt);
Var B : TBlk; I : LongInt;
Begin
  For I := 0 To 15 Do
    If I < N Then B[I] := P^[I] Else B[I] := 0;
  For I := 0 To 3 Do
    GX[I] := GX[I] Xor ((B[I * 4] Shl 24) Or (B[I * 4 + 1] Shl 16) Or (B[I * 4 + 2] Shl 8) Or B[I * 4 + 3]);
  GfMul(A, GX);
End;

{ chiffrer (Dec faux) ou dechiffrer N octets de Src vers Dst (Src = Dst
  permis) ; nombre a usage unique : Iv xor numero de sequence ; Tag :
  etiquette ecrite (chiffrement) ou verifiee (dechiffrement) }
Function GcmRun(Var A : TAes; Aad : PBytes; AadN : LongInt; Src : PBytes; N : LongInt; Dst, Tag : PBytes;
                Dec : Boolean) : Boolean;
Var Ctr, E, Nonce : TBlk; K, I, M, C : LongInt; GX : TGx;
Begin
  For I := 0 To 11 Do Nonce[I] := A.Iv[I];
  Nonce[8] := Nonce[8] Xor (Sr(A.Seq, 24) And 255); Nonce[9] := Nonce[9] Xor (Sr(A.Seq, 16) And 255);
  Nonce[10] := Nonce[10] Xor (Sr(A.Seq, 8) And 255); Nonce[11] := Nonce[11] Xor (A.Seq And 255);
  GX[0] := 0; GX[1] := 0; GX[2] := 0; GX[3] := 0;
  K := 0;
  While K < AadN Do
  Begin
    M := AadN - K;
    If M > 16 Then M := 16;
    GhashBlk(A, GX, @Aad^[K], M);
    K := K + 16;
  End;
  C := 2;
  K := 0;
  While K < N Do
  Begin
    M := N - K;
    If M > 16 Then M := 16;
    If Dec Then GhashBlk(A, GX, @Src^[K], M);
    For I := 0 To 11 Do Ctr[I] := Nonce[I];
    Ctr[12] := Sr(C, 24); Ctr[13] := Sr(C, 16) And 255; Ctr[14] := Sr(C, 8) And 255; Ctr[15] := C And 255;
    AesEnc(A, Ctr);
    For I := 0 To M - 1 Do Dst^[K + I] := Src^[K + I] Xor Ctr[I];
    If Not Dec Then GhashBlk(A, GX, @Dst^[K], M);
    Inc(C);
    K := K + 16;
  End;
  GX[0] := GX[0] Xor Sr(AadN, 29); GX[1] := GX[1] Xor (AadN Shl 3);
  GX[2] := GX[2] Xor Sr(N, 29); GX[3] := GX[3] Xor (N Shl 3);
  GfMul(A, GX);
  For I := 0 To 11 Do E[I] := Nonce[I];
  E[12] := 0; E[13] := 0; E[14] := 0; E[15] := 1;
  AesEnc(A, E);
  For I := 0 To 3 Do
  Begin
    E[I * 4] := E[I * 4] Xor (Sr(GX[I], 24) And 255);
    E[I * 4 + 1] := E[I * 4 + 1] Xor (Sr(GX[I], 16) And 255);
    E[I * 4 + 2] := E[I * 4 + 2] Xor (Sr(GX[I], 8) And 255);
    E[I * 4 + 3] := E[I * 4 + 3] Xor (GX[I] And 255);
  End;
  Inc(A.Seq);
  GcmRun := True;
  If Dec Then
  Begin
    M := 0;
    For I := 0 To 15 Do M := M Or (E[I] Xor Tag^[I]);
    GcmRun := M = 0;
  End
  Else
    For I := 0 To 15 Do Tag^[I] := E[I];
End;

{ --- X25519 (base 2^8, 32 chiffres) --- }

Procedure FeAdd(Var O : TFe; Var A, B : TFe);
Var J, U : LongInt;
Begin
  U := 0;
  For J := 0 To 30 Do
  Begin
    U := U + A[J] + B[J];
    O[J] := U And 255;
    U := Sr(U, 8);
  End;
  O[31] := U + A[31] + B[31];
End;

Procedure FeSub(Var O : TFe; Var A, B : TFe);
Var J, U : LongInt;
Begin
  U := 218;
  For J := 0 To 30 Do
  Begin
    U := U + A[J] + 65280 - B[J];
    O[J] := U And 255;
    U := Sr(U, 8);
  End;
  O[31] := U + A[31] - B[31];
End;

Procedure FeSqueeze(Var A : TFe);
Var J, U : LongInt;
Begin
  U := 0;
  For J := 0 To 30 Do
  Begin
    U := U + A[J];
    A[J] := U And 255;
    U := Sr(U, 8);
  End;
  U := U + A[31];
  A[31] := U And 127;
  U := 19 * Sr(U, 7);
  For J := 0 To 30 Do
  Begin
    U := U + A[J];
    A[J] := U And 255;
    U := Sr(U, 8);
  End;
  A[31] := A[31] + U;
End;

Procedure FeFreeze(Var A : TFe);
Var Orig, M : TFe; J, Neg : LongInt;
Begin
  For J := 0 To 31 Do
  Begin
    Orig[J] := A[J]; M[J] := 0;
  End;
  M[0] := 19; M[31] := 128;
  FeAdd(A, Orig, M);
  Neg := Sr(A[31], 7) And 1;
  If Neg <> 0 Then
    For J := 0 To 31 Do A[J] := Orig[J];
End;

Procedure FeMul(Var O : TFe; Var A, B : TFe);
Var T : TFe; I, J, U : LongInt;
Begin
  For I := 0 To 31 Do
  Begin
    U := 0;
    For J := 0 To I Do U := U + A[J] * B[I - J];
    For J := I + 1 To 31 Do U := U + 38 * A[J] * B[I + 32 - J];
    T[I] := U;
  End;
  FeSqueeze(T);
  For I := 0 To 31 Do O[I] := T[I];
End;

Procedure FeMul121665(Var O : TFe; Var A : TFe);
Var J, U : LongInt;
Begin
  U := 0;
  For J := 0 To 30 Do
  Begin
    U := U + 121665 * A[J];
    O[J] := U And 255;
    U := Sr(U, 8);
  End;
  U := U + 121665 * A[31];
  O[31] := U And 127;
  U := 19 * Sr(U, 7);
  For J := 0 To 30 Do
  Begin
    U := U + O[J];
    O[J] := U And 255;
    U := Sr(U, 8);
  End;
  O[31] := O[31] + U;
End;

Procedure FeInv(Var O : TFe; Var Z : TFe);
Var Z2, Z9, Z11, Z50, Z100, Z200, Z250, T0, T1 : TFe; I : LongInt;
Begin
  FeMul(Z2, Z, Z);
  FeMul(T1, Z2, Z2);
  FeMul(T0, T1, T1);
  FeMul(Z9, T0, Z);
  FeMul(Z11, Z9, Z2);
  FeMul(T0, Z11, Z11);
  FeMul(Z50, T0, Z9);
  T0 := Z50;
  For I := 1 To 5 Do FeMul(T0, T0, T0);
  FeMul(Z100, T0, Z50);
  T0 := Z100;
  For I := 1 To 10 Do FeMul(T0, T0, T0);
  FeMul(Z200, T0, Z100);
  T0 := Z200;
  For I := 1 To 20 Do FeMul(T0, T0, T0);
  FeMul(T1, T0, Z200);
  For I := 1 To 10 Do FeMul(T1, T1, T1);
  FeMul(Z250, T1, Z100);
  T0 := Z250;
  For I := 1 To 50 Do FeMul(T0, T0, T0);
  FeMul(Z200, T0, Z250);
  T0 := Z200;
  For I := 1 To 100 Do FeMul(T0, T0, T0);
  FeMul(T1, T0, Z200);
  For I := 1 To 50 Do FeMul(T1, T1, T1);
  FeMul(T0, T1, Z250);
  For I := 1 To 5 Do FeMul(T0, T0, T0);
  FeMul(O, T0, Z11);
End;

Procedure X25519(Var Q : TB32; Var N : TB32; Var P : TB32);
Var E : TB32;
    U, Xm, Zm, Xm1, Zm1, Xb, Zb, Xb1, Zb1, A0x, A0z, A1x, A1z, B0x, B0z, B1x, B1z,
    C1x, C1z, R, S, T, Uu, Xn, Zn, Xn1, Zn1 : TFe;
    J, Pos_, Bit : LongInt;
Begin
  E := N;
  E[0] := E[0] And 248;
  E[31] := (E[31] And 127) Or 64;
  For J := 0 To 31 Do
  Begin
    U[J] := P[J];
    Xm1[J] := U[J]; Zm1[J] := 0; Xm[J] := 0; Zm[J] := 0;
  End;
  U[31] := U[31] And 127; Xm1[31] := U[31];
  Zm1[0] := 1; Xm[0] := 1;
  For Pos_ := 254 DownTo 0 Do
  Begin
    Bit := (E[Pos_ Div 8] Shr (Pos_ And 7)) And 1;
    If Bit = 0 Then
    Begin
      Xb := Xm; Zb := Zm; Xb1 := Xm1; Zb1 := Zm1;
    End
    Else
    Begin
      Xb := Xm1; Zb := Zm1; Xb1 := Xm; Zb1 := Zm;
    End;
    FeAdd(A0x, Xb, Zb);
    FeSub(A0z, Xb, Zb);
    FeAdd(A1x, Xb1, Zb1);
    FeSub(A1z, Xb1, Zb1);
    FeMul(B0x, A0x, A0x);
    FeMul(B0z, A0z, A0z);
    FeMul(B1x, A1x, A0z);
    FeMul(B1z, A1z, A0x);
    FeAdd(C1x, B1x, B1z);
    FeSub(C1z, B1x, B1z);
    FeMul(R, C1z, C1z);
    FeSub(S, B0x, B0z);
    FeMul121665(T, S);
    FeAdd(Uu, T, B0x);
    FeMul(Xn, B0x, B0z);
    FeMul(Zn, S, Uu);
    FeMul(Xn1, C1x, C1x);
    FeMul(Zn1, R, U);
    If Bit = 0 Then
    Begin
      Xm := Xn; Zm := Zn; Xm1 := Xn1; Zm1 := Zn1;
    End
    Else
    Begin
      Xm := Xn1; Zm := Zn1; Xm1 := Xn; Zm1 := Zn;
    End;
  End;
  FeInv(T, Zm);
  FeMul(R, Xm, T);
  FeFreeze(R);
  For J := 0 To 31 Do Q[J] := R[J];
End;

{ --- aleatoire : SHA-256 d'un reservoir brasse avec le compteur de
  cycles, l'heure et les evenements du reseau --- }
Procedure RandFill(P : PBytes; N : LongInt);
Var C : TSha; T : TB32; K, I, V : LongInt;
Begin
  K := 0;
  While K < N Do
  Begin
    ShaInit(C);
    ShaUpd(C, @RndPool, SizeOf(RndPool));
    Inc(RndCtr);
    V := PRdtsc; ShaUpd(C, @V, 4);
    V := PTicks; ShaUpd(C, @V, 4);
    ShaUpd(C, @RndCtr, 4);
    ShaFinal(C, T);
    For I := 0 To 7 Do RndPool[(RndCtr + I) And 63] := RndPool[(RndCtr + I) And 63] Xor
      ((T[I * 4] Shl 24) Or (T[I * 4 + 1] Shl 16) Or (T[I * 4 + 2] Shl 8) Or T[I * 4 + 3]);
    T[0] := T[0] Xor $5A;
    Sha256(@T, 32, T);
    For I := 0 To 31 Do
      If K + I < N Then P^[K + I] := T[I];
    K := K + 32;
  End;
End;

Procedure RandStir(V : LongInt);
Begin
  Inc(RndCtr);
  RndPool[RndCtr And 63] := RndPool[RndCtr And 63] Xor V Xor PRdtsc;
End;

{ ==================================================================== }
{ P-256 : nombres de 270 bits en 18 chiffres de 15 bits (produits sur   }
{ 30 bits : pas de debordement des entiers de 32 bits), multiplication   }
{ de Montgomery generale (modules p et n)                                }
{ ==================================================================== }

Const
  NL = 18;
  LM = $7FFF;

Type
  TBig = Array[0..NL - 1] Of LongInt;
  TMod = Record
    M, R2, One : TBig;
    MInv : LongInt;
  End;
  TPt = Record
    X, Y, Z : TBig;     { jacobiennes, domaine de Montgomery ; Z = 0 : infini }
  End;

Var
  ModP, ModN : TMod;
  GxM, GyM : TBig;      { point de base (Montgomery) }
  BM : TBig;            { coefficient b (Montgomery) }
  EccReady : Boolean;

Procedure BigZero(Var A : TBig);
Var I : LongInt;
Begin
  For I := 0 To NL - 1 Do A[I] := 0;
End;

Function BigIsZero(Var A : TBig) : Boolean;
Var I, V : LongInt;
Begin
  V := 0;
  For I := 0 To NL - 1 Do V := V Or A[I];
  BigIsZero := V = 0;
End;

{ -1, 0, 1 }
Function BigCmp(Var A, B : TBig) : LongInt;
Var I : LongInt;
Begin
  BigCmp := 0;
  For I := NL - 1 DownTo 0 Do
    If A[I] <> B[I] Then
    Begin
      If A[I] > B[I] Then BigCmp := 1 Else BigCmp := -1;
      Exit;
    End;
End;

{ A := A - B (A >= B) }
Procedure BigSubIn(Var A, B : TBig);
Var I, C, V : LongInt;
Begin
  C := 0;
  For I := 0 To NL - 1 Do
  Begin
    V := A[I] - B[I] - C;
    If V < 0 Then
    Begin
      V := V + 32768; C := 1;
    End
    Else C := 0;
    A[I] := V;
  End;
End;

{ 32 octets gros-boutistes -> nombre }
Procedure BigFromBytes(Var A : TBig; P : PBytes);
Var I, Bit, B : LongInt;
Begin
  BigZero(A);
  For I := 0 To 255 Do
  Begin
    B := (P^[31 - (I Div 8)] Shr (I And 7)) And 1;
    If B <> 0 Then A[I Div 15] := A[I Div 15] Or (1 Shl (I Mod 15));
  End;
  Bit := 0;
End;

Procedure BigToBytes(Var A : TBig; P : PBytes);
Var I : LongInt;
Begin
  For I := 0 To 31 Do P^[I] := 0;
  For I := 0 To 255 Do
    If ((A[I Div 15] Shr (I Mod 15)) And 1) <> 0 Then
      P^[31 - (I Div 8)] := P^[31 - (I Div 8)] Or (1 Shl (I And 7));
End;

Procedure ModAdd(Var R : TBig; Var A, B : TBig; Var Md : TMod);
Var I, C, V : LongInt;
Begin
  C := 0;
  For I := 0 To NL - 1 Do
  Begin
    V := A[I] + B[I] + C;
    R[I] := V And LM;
    C := V Shr 15;
  End;
  If BigCmp(R, Md.M) >= 0 Then BigSubIn(R, Md.M);
End;

Procedure ModSub(Var R : TBig; Var A, B : TBig; Var Md : TMod);
Var I, C, V : LongInt; Neg : Boolean;
Begin
  C := 0;
  For I := 0 To NL - 1 Do
  Begin
    V := A[I] - B[I] - C;
    If V < 0 Then
    Begin
      V := V + 32768; C := 1;
    End
    Else C := 0;
    R[I] := V;
  End;
  Neg := C <> 0;
  If Neg Then
  Begin
    C := 0;
    For I := 0 To NL - 1 Do
    Begin
      V := R[I] + Md.M[I] + C;
      R[I] := V And LM;
      C := V Shr 15;
    End;
  End;
End;

{ R := A * B / 2^270 mod M }
Procedure MontMul(Var R : TBig; Var A, B : TBig; Var Md : TMod);
Var T : Array[0..NL + 1] Of LongInt; I, J, S, C, M : LongInt; Ok : Boolean; Q : TBig;
Begin
  For I := 0 To NL + 1 Do T[I] := 0;
  For I := 0 To NL - 1 Do
  Begin
    C := 0;
    For J := 0 To NL - 1 Do
    Begin
      S := T[J] + A[I] * B[J] + C;
      T[J] := S And LM;
      C := S Shr 15;
    End;
    S := T[NL] + C;
    T[NL] := S And LM;
    T[NL + 1] := S Shr 15;
    M := (T[0] * Md.MInv) And LM;
    S := T[0] + M * Md.M[0];
    C := S Shr 15;
    For J := 1 To NL - 1 Do
    Begin
      S := T[J] + M * Md.M[J] + C;
      T[J - 1] := S And LM;
      C := S Shr 15;
    End;
    S := T[NL] + C;
    T[NL - 1] := S And LM;
    C := S Shr 15;
    T[NL] := T[NL + 1] + C;
  End;
  For I := 0 To NL - 1 Do Q[I] := T[I];
  Ok := T[NL] <> 0;
  If Ok Or (BigCmp(Q, Md.M) >= 0) Then BigSubIn(Q, Md.M);
  R := Q;
End;

{ module : -M^-1 mod 2^15, R mod M, R^2 mod M (R = 2^270) }
Procedure ModSetup(Var Md : TMod; P : PBytes);
Var I, Inv : LongInt; T : TBig;
Begin
  BigFromBytes(Md.M, P);
  Inv := Md.M[0];
  For I := 1 To 5 Do Inv := (Inv * (2 - ((Md.M[0] * Inv) And LM))) And LM;
  Md.MInv := (32768 - Inv) And LM;
  { 1 * 2^540 mod M par doublements }
  BigZero(T);
  T[0] := 1;
  For I := 1 To 540 Do
  Begin
    ModAdd(T, T, T, Md);
    If I = 270 Then Md.One := T;
  End;
  Md.R2 := T;
End;

Procedure ToMont(Var R : TBig; Var A : TBig; Var Md : TMod);
Begin
  MontMul(R, A, Md.R2, Md);
End;

Procedure FromMont(Var R : TBig; Var A : TBig; Var Md : TMod);
Var One : TBig;
Begin
  BigZero(One);
  One[0] := 1;
  MontMul(R, A, One, Md);
End;

{ R := A^(M-2) (inverse, domaine de Montgomery) }
Procedure ModInv(Var R : TBig; Var A : TBig; Var Md : TMod);
Var E, Acc : TBig; I : LongInt;
Begin
  E := Md.M;
  { E := M - 2 }
  I := 0;
  E[0] := E[0] - 2;
  While E[I] < 0 Do
  Begin
    E[I] := E[I] + 32768;
    Inc(I);
    E[I] := E[I] - 1;
  End;
  Acc := Md.One;
  For I := 269 DownTo 0 Do
  Begin
    MontMul(Acc, Acc, Acc, Md);
    If ((E[I Div 15] Shr (I Mod 15)) And 1) <> 0 Then MontMul(Acc, Acc, A, Md);
  End;
  R := Acc;
End;

Const
  P256P : Array[0..31] Of Byte = ($FF, $FF, $FF, $FF, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00,
    $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);
  P256N : Array[0..31] Of Byte = ($FF, $FF, $FF, $FF, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $BC, $E6, $FA, $AD, $A7, $17, $9E, $84, $F3, $B9, $CA, $C2, $FC, $63, $25, $51);
  P256B : Array[0..31] Of Byte = ($5A, $C6, $35, $D8, $AA, $3A, $93, $E7, $B3, $EB, $BD, $55, $76, $98, $86, $BC,
    $65, $1D, $06, $B0, $CC, $53, $B0, $F6, $3B, $CE, $3C, $3E, $27, $D2, $60, $4B);
  P256Gx : Array[0..31] Of Byte = ($6B, $17, $D1, $F2, $E1, $2C, $42, $47, $F8, $BC, $E6, $E5, $63, $A4, $40, $F2,
    $77, $03, $7D, $81, $2D, $EB, $33, $A0, $F4, $A1, $39, $45, $D8, $98, $C2, $96);
  P256Gy : Array[0..31] Of Byte = ($4F, $E3, $42, $E2, $FE, $1A, $7F, $9B, $8E, $E7, $EB, $4A, $7C, $0F, $9E, $16,
    $2B, $CE, $33, $57, $6B, $31, $5E, $CE, $CB, $B6, $40, $68, $37, $BF, $51, $F5);

Procedure EccInit;
Var T : TBig; B : Array[0..31] Of Byte; I : LongInt;
Begin
  If EccReady Then Exit;
  For I := 0 To 31 Do B[I] := P256P[I];
  ModSetup(ModP, @B);
  For I := 0 To 31 Do B[I] := P256N[I];
  ModSetup(ModN, @B);
  For I := 0 To 31 Do B[I] := P256Gx[I];
  BigFromBytes(T, @B); ToMont(GxM, T, ModP);
  For I := 0 To 31 Do B[I] := P256Gy[I];
  BigFromBytes(T, @B); ToMont(GyM, T, ModP);
  For I := 0 To 31 Do B[I] := P256B[I];
  BigFromBytes(T, @B); ToMont(BM, T, ModP);
  EccReady := True;
End;

{ doublement (a = -3) }
Procedure PtDbl(Var R : TPt; Var P : TPt);
Var Delta, Gamma, Beta, Alpha, T1, T2, T3 : TBig;
Begin
  If BigIsZero(P.Z) Then
  Begin
    R := P;
    Exit;
  End;
  MontMul(Delta, P.Z, P.Z, ModP);
  MontMul(Gamma, P.Y, P.Y, ModP);
  MontMul(Beta, P.X, Gamma, ModP);
  ModSub(T1, P.X, Delta, ModP);
  ModAdd(T2, P.X, Delta, ModP);
  MontMul(T3, T1, T2, ModP);
  ModAdd(Alpha, T3, T3, ModP);
  ModAdd(Alpha, Alpha, T3, ModP);
  { Z3 = (Y+Z)^2 - gamma - delta }
  ModAdd(T1, P.Y, P.Z, ModP);
  MontMul(T2, T1, T1, ModP);
  ModSub(T2, T2, Gamma, ModP);
  ModSub(R.Z, T2, Delta, ModP);
  { X3 = alpha^2 - 8 beta }
  ModAdd(Beta, Beta, Beta, ModP);
  ModAdd(Beta, Beta, Beta, ModP);         { 4 beta }
  MontMul(T1, Alpha, Alpha, ModP);
  ModAdd(T2, Beta, Beta, ModP);
  ModSub(R.X, T1, T2, ModP);
  { Y3 = alpha (4 beta - X3) - 8 gamma^2 }
  ModSub(T1, Beta, R.X, ModP);
  MontMul(T2, Alpha, T1, ModP);
  MontMul(T3, Gamma, Gamma, ModP);
  ModAdd(T3, T3, T3, ModP);
  ModAdd(T3, T3, T3, ModP);
  ModAdd(T3, T3, T3, ModP);
  ModSub(R.Y, T2, T3, ModP);
End;

{ R := P + Q, Q affine (Z = 1) : X2, Y2 }
Procedure PtAddAff(Var R : TPt; Var P : TPt; Var X2, Y2 : TBig);
Var Z1Z1, U2, S2, H, HH, I_, J, Rr, V, T1, T2 : TBig; Q : TPt;
Begin
  If BigIsZero(P.Z) Then
  Begin
    R.X := X2; R.Y := Y2; R.Z := ModP.One;
    Exit;
  End;
  MontMul(Z1Z1, P.Z, P.Z, ModP);
  MontMul(U2, X2, Z1Z1, ModP);
  MontMul(T1, P.Z, Z1Z1, ModP);
  MontMul(S2, Y2, T1, ModP);
  ModSub(H, U2, P.X, ModP);
  ModSub(T1, S2, P.Y, ModP);
  If BigIsZero(H) Then
  Begin
    If BigIsZero(T1) Then PtDbl(R, P)
    Else BigZero(R.Z);
    Exit;
  End;
  MontMul(HH, H, H, ModP);
  ModAdd(I_, HH, HH, ModP);
  ModAdd(I_, I_, I_, ModP);
  MontMul(J, H, I_, ModP);
  ModAdd(Rr, T1, T1, ModP);
  MontMul(V, P.X, I_, ModP);
  MontMul(T1, Rr, Rr, ModP);
  ModSub(T1, T1, J, ModP);
  ModSub(T1, T1, V, ModP);
  ModSub(Q.X, T1, V, ModP);
  ModSub(T1, V, Q.X, ModP);
  MontMul(T2, Rr, T1, ModP);
  MontMul(T1, P.Y, J, ModP);
  ModAdd(T1, T1, T1, ModP);
  ModSub(Q.Y, T2, T1, ModP);
  ModAdd(T1, P.Z, H, ModP);
  MontMul(T2, T1, T1, ModP);
  ModSub(T2, T2, Z1Z1, ModP);
  ModSub(Q.Z, T2, HH, ModP);
  R := Q;
End;

{ K * G -> X, Y affines (octets) }
Procedure EcMulG(K : PBytes; X, Y : PBytes);
Var P : TPt; I : LongInt; Zi, Z2, T, A : TBig;
Begin
  EccInit;
  BigZero(P.X); BigZero(P.Y); BigZero(P.Z);
  For I := 255 DownTo 0 Do
  Begin
    PtDbl(P, P);
    If ((K^[31 - (I Div 8)] Shr (I And 7)) And 1) <> 0 Then PtAddAff(P, P, GxM, GyM);
  End;
  ModInv(Zi, P.Z, ModP);
  MontMul(Z2, Zi, Zi, ModP);
  MontMul(T, P.X, Z2, ModP);
  FromMont(A, T, ModP);
  BigToBytes(A, X);
  MontMul(T, Z2, Zi, ModP);
  MontMul(T, P.Y, T, ModP);
  FromMont(A, T, ModP);
  BigToBytes(A, Y);
End;

{ cle privee aleatoire (1 <= d < n) }
Procedure EcKeyGen(D : PBytes);
Var T : TBig;
Begin
  EccInit;
  Repeat
    RandFill(D, 32);
    BigFromBytes(T, D);
  Until (Not BigIsZero(T)) And (BigCmp(T, ModN.M) < 0);
End;

{ signature ECDSA-SHA256 de Hash (32 octets) avec la cle D : R, S }
Procedure EcSign(D, Hash : PBytes; R, S : PBytes);
Var K : Array[0..31] Of Byte; X, Y : Array[0..31] Of Byte; Seed : Array[0..95] Of Byte;
    Kb, Rb, Eb, Db, Km, Rm, Em, Dm, Ki, T, Sb : TBig; I : LongInt; H : TB32;
Begin
  EccInit;
  Repeat
    { k derive de la cle, du condensat et d'aleatoire (jamais repete) }
    For I := 0 To 31 Do Seed[I] := D^[I];
    For I := 0 To 31 Do Seed[32 + I] := Hash^[I];
    RandFill(@Seed[64], 32);
    Hmac(D, 32, @Seed, 96, H);
    For I := 0 To 31 Do K[I] := H[I];
    BigFromBytes(Kb, @K);
    If BigCmp(Kb, ModN.M) >= 0 Then BigSubIn(Kb, ModN.M);
    If BigIsZero(Kb) Then Continue;
    EcMulG(@K, @X, @Y);
    BigFromBytes(Rb, @X);
    If BigCmp(Rb, ModN.M) >= 0 Then BigSubIn(Rb, ModN.M);
    If BigIsZero(Rb) Then Continue;
    BigFromBytes(Eb, Hash);
    If BigCmp(Eb, ModN.M) >= 0 Then BigSubIn(Eb, ModN.M);
    BigFromBytes(Db, D);
    { s = k^-1 (e + r d) mod n }
    ToMont(Km, Kb, ModN); ToMont(Rm, Rb, ModN); ToMont(Em, Eb, ModN); ToMont(Dm, Db, ModN);
    ModInv(Ki, Km, ModN);
    MontMul(T, Rm, Dm, ModN);
    ModAdd(T, T, Em, ModN);
    MontMul(T, Ki, T, ModN);
    FromMont(Sb, T, ModN);
    If BigIsZero(Sb) Then Continue;
    BigToBytes(Rb, R);
    BigToBytes(Sb, S);
    Exit;
  Until False;
End;

{ ==================================================================== }
{ DER (ASN.1) et certificats X.509 auto-signes                          }
{ ==================================================================== }

{ en-tete TLV : etiquette, longueur }
Procedure DerHdr(Var B : TBuf; Tag, Len : LongInt);
Begin
  BufAddC(B, Tag);
  If Len < 128 Then BufAddC(B, Len)
  Else If Len < 256 Then
  Begin
    BufAddC(B, $81); BufAddC(B, Len);
  End
  Else
  Begin
    BufAddC(B, $82); BufAddC(B, Len Shr 8); BufAddC(B, Len And 255);
  End;
End;

Procedure DerWrap(Var Dst : TBuf; Tag : LongInt; Var Src : TBuf);
Begin
  DerHdr(Dst, Tag, Src.Len);
  BufAddB(Dst, Src.P, Src.Len);
End;

{ entier positif (32 octets gros-boutistes, zeros de tete enleves) }
Procedure DerUInt(Var B : TBuf; P : PBytes; N : LongInt);
Var K : LongInt;
Begin
  K := 0;
  While (K < N - 1) And (P^[K] = 0) Do Inc(K);
  If P^[K] >= $80 Then
  Begin
    DerHdr(B, 2, N - K + 1);
    BufAddC(B, 0);
  End
  Else DerHdr(B, 2, N - K);
  BufAddB(B, @P^[K], N - K);
End;

Procedure DerBytes(Var B : TBuf; Const S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do BufAddC(B, Ord(S[K]));
End;

{ signature DER : SEQUENCE (INTEGER r, INTEGER s) }
Procedure EcSigDer(R, S : PBytes; Var Out_ : TBuf);
Var B : TBuf;
Begin
  BufInit(B);
  DerUInt(B, R, 32);
  DerUInt(B, S, 32);
  DerWrap(Out_, $30, B);
  BufFree(B);
End;

{ nom : SEQUENCE (SET (SEQUENCE (OID CN, UTF8String))) }
Procedure DerName(Var Out_ : TBuf; Cn : String);
Var A, B, C : TBuf;
Begin
  BufInit(A); BufInit(B); BufInit(C);
  DerBytes(A, #$06#$03#$55#$04#$03);
  DerHdr(A, $0C, Length(Cn));
  DerBytes(A, Cn);
  DerWrap(B, $30, A);
  DerWrap(C, $31, B);
  DerWrap(Out_, $30, C);
  BufFree(A); BufFree(B); BufFree(C);
End;

Function UtcTime(T : LongInt) : String;
Var Y, Mo, D, H, Mi, S, Wd : LongInt;
Begin
  UnixSplit(T, Y, Mo, D, H, Mi, S, Wd);
  UtcTime := Pad2(Y Mod 100) + Pad2(Mo) + Pad2(D) + Pad2(H) + Pad2(Mi) + Pad2(S) + 'Z';
End;

{ certificat auto-signe (DER) pour le nom Cn (et l'adresse Ip si non
  nulle), cle D ; rend Faux en cas d'echec }
Procedure MakeCert(Cn : String; Ip : LongInt; D : PBytes; Var Cert : TBuf);
Var Tbs, A, B, C, E : TBuf; X, Y, Sr_, Ss : Array[0..31] Of Byte; Serial : Array[0..7] Of Byte;
    H : TB32; Now_ : LongInt;
Begin
  BufInit(Tbs); BufInit(A); BufInit(B); BufInit(C); BufInit(E);
  EcMulG(D, @X, @Y);
  { version 3, numero de serie }
  DerBytes(Tbs, #$A0#$03#$02#$01#$02);
  RandFill(@Serial, 8);
  Serial[0] := Serial[0] And $7F;
  DerUInt(Tbs, @Serial, 8);
  DerBytes(Tbs, #$30#$0A#$06#$08#$2A#$86#$48#$CE#$3D#$04#$03#$02);
  DerName(Tbs, Cn);
  { validite : d'hier a dans 10 ans }
  Now_ := NowUnix;
  DerHdr(A, $17, 13); DerBytes(A, UtcTime(Now_ - 86400));
  DerHdr(A, $17, 13); DerBytes(A, UtcTime(Now_ + 3650 * 86400));
  DerWrap(Tbs, $30, A);
  A.Len := 0;
  DerName(Tbs, Cn);
  { cle publique }
  DerBytes(A, #$30#$13#$06#$07#$2A#$86#$48#$CE#$3D#$02#$01#$06#$08#$2A#$86#$48#$CE#$3D#$03#$01#$07);
  DerHdr(A, $03, 66);
  BufAddC(A, 0); BufAddC(A, 4);
  BufAddB(A, @X, 32); BufAddB(A, @Y, 32);
  DerWrap(Tbs, $30, A);
  A.Len := 0;
  { extension subjectAltName : DNS:Cn, IP }
  DerHdr(B, $82, Length(Cn)); DerBytes(B, Cn);
  If Ip <> 0 Then
  Begin
    DerHdr(B, $87, 4);
    BufAddC(B, (Ip Shr 24) And 255); BufAddC(B, (Ip Shr 16) And 255); BufAddC(B, (Ip Shr 8) And 255);
    BufAddC(B, Ip And 255);
  End;
  DerWrap(C, $30, B);
  DerBytes(A, #$06#$03#$55#$1D#$11);
  DerWrap(A, $04, C);
  B.Len := 0;
  DerWrap(B, $30, A);
  A.Len := 0;
  DerWrap(A, $30, B);
  DerWrap(Tbs, $A3, A);
  A.Len := 0;
  DerWrap(A, $30, Tbs);
  { signature }
  Sha256(A.P, A.Len, H);
  EcSign(D, @H, @Sr_, @Ss);
  B.Len := 0;
  EcSigDer(@Sr_, @Ss, B);
  DerBytes(A, #$30#$0A#$06#$08#$2A#$86#$48#$CE#$3D#$04#$03#$02);
  DerHdr(A, $03, B.Len + 1);
  BufAddC(A, 0);
  BufAddB(A, B.P, B.Len);
  DerWrap(Cert, $30, A);
  BufFree(Tbs); BufFree(A); BufFree(B); BufFree(C); BufFree(E);
End;

{ cle privee SEC1 (EC PRIVATE KEY) }
Procedure MakeKeyDer(D : PBytes; Var Out_ : TBuf);
Var A, B : TBuf; X, Y : Array[0..31] Of Byte;
Begin
  BufInit(A); BufInit(B);
  EcMulG(D, @X, @Y);
  DerBytes(A, #$02#$01#$01);
  DerHdr(A, $04, 32); BufAddB(A, D, 32);
  DerBytes(A, #$A0#$0A#$06#$08#$2A#$86#$48#$CE#$3D#$03#$01#$07);
  DerHdr(B, $03, 66); BufAddC(B, 0); BufAddC(B, 4); BufAddB(B, @X, 32); BufAddB(B, @Y, 32);
  DerWrap(A, $A1, B);
  DerWrap(Out_, $30, A);
  BufFree(A); BufFree(B);
End;

Procedure PemAdd(Var Out_ : TBuf; Lbl : String; P : PBytes; N : LongInt);
Begin
  BufAdd(Out_, '-----BEGIN ' + Lbl + '-----' + #10);
  B64Enc(P, N, Out_, 64);
  BufAdd(Out_, #10 + '-----END ' + Lbl + '-----' + #10);
End;

{ creer un fichier PEM (certificat puis cle) pour le nom Cn }
Function CreateCertFile(Name, Cn : String; Ip : LongInt) : Boolean;
Var D : Array[0..31] Of Byte; Cert, Key, Pem : TBuf;
Begin
  BufInit(Cert); BufInit(Key); BufInit(Pem);
  EcKeyGen(@D);
  MakeCert(Cn, Ip, @D, Cert);
  MakeKeyDer(@D, Key);
  PemAdd(Pem, 'CERTIFICATE', Cert.P, Cert.Len);
  PemAdd(Pem, 'EC PRIVATE KEY', Key.P, Key.Len);
  CreateCertFile := WriteFileBuf(Name, Pem.P, Pem.Len);
  BufFree(Cert); BufFree(Key); BufFree(Pem);
End;

{ ==================================================================== }
{ Configuration : WEBSRV.CFG (texte, sections [Serveur], [Mime],         }
{ [Site:n]) ; certificats des sites                                      }
{ ==================================================================== }

Var
  CertDer : Array[0..MaxSites - 1] Of TBuf;    { liste de certificats (format du message TLS) }
  CertKey : Array[0..MaxSites - 1] Of TB32;
  CertOk : Array[0..MaxSites - 1] Of Boolean;
  CertMsg : Array[0..MaxSites - 1] Of String[79];

Procedure MimeAdd(E, T : String);
Var K : LongInt;
Begin
  E := LoStr(E);
  If (E <> '') And (E[1] <> '.') Then E := '.' + E;
  For K := 0 To NMime - 1 Do
    If MimeExt[K] = E Then
    Begin
      MimeTyp[K] := T;
      Exit;
    End;
  If NMime >= MaxMime Then Exit;
  MimeExt[NMime] := E; MimeTyp[NMime] := T;
  Inc(NMime);
End;

Procedure MimeDefaults;
Begin
  NMime := 0;
  MimeAdd('.html', 'text/html'); MimeAdd('.htm', 'text/html'); MimeAdd('.txt', 'text/plain');
  MimeAdd('.css', 'text/css'); MimeAdd('.js', 'application/javascript'); MimeAdd('.json', 'application/json');
  MimeAdd('.xml', 'text/xml'); MimeAdd('.png', 'image/png'); MimeAdd('.jpg', 'image/jpeg');
  MimeAdd('.jpeg', 'image/jpeg'); MimeAdd('.gif', 'image/gif'); MimeAdd('.bmp', 'image/bmp');
  MimeAdd('.ico', 'image/x-icon'); MimeAdd('.svg', 'image/svg+xml'); MimeAdd('.pdf', 'application/pdf');
  MimeAdd('.zip', 'application/zip'); MimeAdd('.mp3', 'audio/mpeg'); MimeAdd('.wav', 'audio/wav');
  MimeAdd('.mid', 'audio/midi'); MimeAdd('.pas', 'text/plain'); MimeAdd('.cmd', 'text/plain');
  MimeAdd('.iso', 'application/octet-stream'); MimeAdd('.exe', 'application/octet-stream');
  MimeAdd('.woff', 'font/woff'); MimeAdd('.wasm', 'application/wasm');
End;

Function MimeOf(Name : String) : String;
Var K, P : LongInt; E : String;
Begin
  P := 0;
  For K := Length(Name) DownTo 1 Do
    If (P = 0) And (Name[K] = '.') Then P := K
    Else If (Name[K] = '\') Or (Name[K] = '/') Then Break;
  MimeOf := 'application/octet-stream';
  If P = 0 Then Exit;
  E := LoStr(Copy(Name, P, 255));
  For K := 0 To NMime - 1 Do
    If MimeExt[K] = E Then
    Begin
      MimeOf := MimeTyp[K];
      Exit;
    End;
End;

Procedure SiteInit(Var S : TSite; Id : LongInt);
Begin
  FillChar(S, SizeOf(S), 0);
  S.Used := True; S.Id := Id;
  S.Name := 'Site ' + IStr(Id);
  S.Root := WwwData + '\ROOT';
  S.Started := True;
  S.NB := 1; S.B[0].Tls := False; S.B[0].Ip := 0; S.B[0].Port := 80; S.B[0].Host := '';
  S.ND := 6;
  S.Docs[0] := 'index.html'; S.Docs[1] := 'index.htm'; S.Docs[2] := 'default.htm';
  S.Docs[3] := 'index.psp'; S.Docs[4] := 'default.asp'; S.Docs[5] := 'index.php';
  S.Browse := False; S.LogOn := True; S.Psp := True; S.Asp := True; S.Php := True;
End;

Procedure CfgDefaults;
Var K : LongInt;
Begin
  KeepAliveS := 15; ConnTimeoutS := 120; ScriptTimeoutS := 90; SessionTimeoutM := 20; MaxConnCfg := MaxConn;
  ServerName := 'OS2-0-WebSrv/' + AppVer;
  MimeDefaults;
  For K := 0 To MaxSites - 1 Do Sites[K].Used := False;
  SiteInit(Sites[0], 1);
  Sites[0].Name := 'Site Web par d'#130'faut';
  Sites[0].NB := 2;
  Sites[0].B[1].Tls := True; Sites[0].B[1].Ip := 0; Sites[0].B[1].Port := 443; Sites[0].B[1].Host := '';
End;

Function BindStr(Var B : TBind) : String;
Var S : String;
Begin
  If B.Tls Then S := 'https,' Else S := 'http,';
  If B.Ip = 0 Then S := S + '*' Else S := S + IpStr(B.Ip);
  BindStr := S + ',' + IStr(B.Port) + ',' + B.Host;
End;

Function ParseBind(S : String; Var B : TBind) : Boolean;
Var P : LongInt; F : String;
Begin
  ParseBind := False;
  P := Pos(',', S);
  If P = 0 Then Exit;
  F := LoStr(Trim(Copy(S, 1, P - 1)));
  B.Tls := F = 'https';
  If (F <> 'http') And (F <> 'https') Then Exit;
  S := Copy(S, P + 1, 255);
  P := Pos(',', S);
  If P = 0 Then Exit;
  F := Trim(Copy(S, 1, P - 1));
  If (F = '*') Or (F = '') Then B.Ip := 0 Else B.Ip := ParseIp(F);
  S := Copy(S, P + 1, 255);
  P := Pos(',', S);
  If P = 0 Then
  Begin
    B.Port := SVal(S); B.Host := '';
  End
  Else
  Begin
    B.Port := SVal(Copy(S, 1, P - 1));
    B.Host := LoStr(Trim(Copy(S, P + 1, 255)));
  End;
  ParseBind := (B.Port > 0) And (B.Port < 65536);
End;

Function YesNo(B : Boolean) : String;
Begin
  If B Then YesNo := 'Oui' Else YesNo := 'Non';
End;

Function IsYes(S : String) : Boolean;
Begin
  S := UpStr(Trim(S));
  IsYes := (S = 'OUI') Or (S = 'YES') Or (S = '1') Or (S = 'VRAI') Or (S = 'TRUE');
End;

{ C:\WWW (contenu) et l'endroit ou l'on peut ecrire (C:\WWW, sinon
  D:\WWW) }
Procedure PickDirs;
Var H : LongInt; T : String;
Begin
  WwwBase := PEnv('WEBSRV_ROOT');
  {$IFDEF OS2PC}
  If WwwBase = '' Then WwwBase := 'C:\WWW';
  {$ELSE}
  If WwwBase = '' Then WwwBase := '/tmp/www';
  {$ENDIF}
  WwwData := WwwBase;
  T := WwwBase + '\WEBSRV.TMP';
  PMkDir(WwwBase);
  If POpenWrite(T, False, H) Then
  Begin
    PClose(H);
    Dummy := Ord(PDelete(T));
  End
  Else
  Begin
    {$IFDEF OS2PC}
    WwwData := 'D:\WWW';
    {$ENDIF}
    PMkDir(WwwData);
  End;
  PMkDir(WwwData + '\LOGS');
  PMkDir(WwwData + '\CERTS');
  { la configuration : celle qu'on peut ecrire d'abord }
  CfgPath := WwwData + '\WEBSRV.CFG';
  If (Not PExists(CfgPath)) And PExists(WwwBase + '\WEBSRV.CFG') Then CfgPath := WwwBase + '\WEBSRV.CFG';
End;

Procedure CfgLoad;
Var Bf : TBuf; K, Cur, I : LongInt; L, U, V : String; C : Char; Tb : TBind;

  Procedure DoLine;
  Var P, N : LongInt; Key : String;
  Begin
    L := Trim(L);
    If (L = '') Or (L[1] = ';') Or (L[1] = '#') Then Exit;
    If L[1] = '[' Then
    Begin
      U := UpStr(L);
      Cur := -1;
      If U = '[SERVEUR]' Then Cur := -2
      Else If U = '[MIME]' Then
      Begin
        Cur := -3;
        NMime := 0;
      End
      Else If Copy(U, 1, 6) = '[SITE:' Then
      Begin
        N := SVal(Copy(U, 7, 5));
        For P := 0 To MaxSites - 1 Do
          If (Cur = -1) And Not Sites[P].Used Then
          Begin
            SiteInit(Sites[P], N);
            Sites[P].NB := 0;
            Cur := P;
          End;
      End;
      Exit;
    End;
    P := Pos('=', L);
    If P = 0 Then Exit;
    Key := UpStr(Trim(Copy(L, 1, P - 1)));
    V := Trim(Copy(L, P + 1, 255));
    If Cur = -2 Then
    Begin
      If Key = 'CONNEXIONSPERSISTANTES' Then KeepAliveS := SVal(V)
      Else If Key = 'DELAICONNEXION' Then ConnTimeoutS := SVal(V)
      Else If Key = 'DELAISCRIPT' Then ScriptTimeoutS := SVal(V)
      Else If Key = 'DELAISESSION' Then SessionTimeoutM := SVal(V)
      Else If Key = 'MAXCONNEXIONS' Then MaxConnCfg := SVal(V)
      Else If Key = 'NOMSERVEUR' Then ServerName := V;
    End
    Else If Cur = -3 Then MimeAdd(Copy(L, 1, P - 1), V)
    Else If Cur >= 0 Then
      With Sites[Cur] Do
      Begin
        If Key = 'NOM' Then Name := V
        Else If Key = 'RACINE' Then Root := V
        Else If Key = 'ETAT' Then Started := UpStr(V) <> 'ARRETE'
        Else If Key = 'LIAISON' Then
        Begin
          If (NB < MaxBind) And ParseBind(V, Tb) Then
          Begin
            B[NB] := Tb;
            Inc(NB);
          End;
        End
        Else If Key = 'DOCUMENTS' Then
        Begin
          ND := 0;
          V := V + ',';
          While (Pos(',', V) > 0) And (ND < MaxDocs) Do
          Begin
            P := Pos(',', V);
            If Trim(Copy(V, 1, P - 1)) <> '' Then
            Begin
              Docs[ND] := Trim(Copy(V, 1, P - 1));
              Inc(ND);
            End;
            V := Copy(V, P + 1, 255);
          End;
        End
        Else If Key = 'EXPLORATION' Then Browse := IsYes(V)
        Else If Key = 'JOURNAL' Then LogOn := IsYes(V)
        Else If Key = 'PSP' Then Psp := IsYes(V)
        Else If Key = 'ASP' Then Asp := IsYes(V)
        Else If Key = 'PHP' Then Php := IsYes(V)
        Else If Key = 'ERREUR' Then
        Begin
          P := Pos(',', V);
          If (P > 0) And (NE < MaxErrP) Then
          Begin
            ErrCode[NE] := SVal(Copy(V, 1, P - 1));
            ErrPath[NE] := Trim(Copy(V, P + 1, 255));
            Inc(NE);
          End;
        End
        Else If Key = 'ENTETE' Then
        Begin
          If NH < MaxHdrs Then
          Begin
            Hdr[NH] := V;
            Inc(NH);
          End;
        End
        Else If Key = 'VIRTUEL' Then
        Begin
          P := Pos(',', V);
          If (P > 0) And (NV < MaxVDir) Then
          Begin
            VUrl[NV] := Trim(Copy(V, 1, P - 1));
            VPath[NV] := Trim(Copy(V, P + 1, 255));
            Inc(NV);
          End;
        End
        Else If Key = 'CERTIFICAT' Then Cert := V
        Else If Key = 'UTILISATEUR' Then AuthUser := V
        Else If Key = 'MOTDEPASSE' Then AuthPass := V;
      End;
  End;

Begin
  CfgDefaults;
  If Not ReadFileBuf(CfgPath, Bf, 1048576) Then Exit;
  For K := 0 To MaxSites - 1 Do Sites[K].Used := False;
  Cur := -1; L := '';
  For K := 0 To Bf.Len - 1 Do
  Begin
    C := Chr(Bf.P^[K]);
    If (C = #13) Or (C = #10) Then
    Begin
      DoLine;
      L := '';
    End
    Else If Length(L) < 250 Then L := L + C;
  End;
  DoLine;
  BufFree(Bf);
  If NMime = 0 Then MimeDefaults;
  I := 0;
  For K := 0 To MaxSites - 1 Do If Sites[K].Used Then Inc(I);
  If I = 0 Then CfgDefaults;
End;

Function CfgSave : Boolean;
Var Bf : TBuf; K, J : LongInt;
Begin
  BufInit(Bf);
  BufAdd(Bf, '; Configuration du Serveur Web d''OS/2-0 (WEBSRV.EXE)' + Crlf);
  BufAdd(Bf, '[Serveur]' + Crlf);
  BufAdd(Bf, 'NomServeur=' + ServerName + Crlf);
  BufAdd(Bf, 'MaxConnexions=' + IStr(MaxConnCfg) + Crlf);
  BufAdd(Bf, 'ConnexionsPersistantes=' + IStr(KeepAliveS) + Crlf);
  BufAdd(Bf, 'DelaiConnexion=' + IStr(ConnTimeoutS) + Crlf);
  BufAdd(Bf, 'DelaiScript=' + IStr(ScriptTimeoutS) + Crlf);
  BufAdd(Bf, 'DelaiSession=' + IStr(SessionTimeoutM) + Crlf);
  BufAdd(Bf, Crlf + '[Mime]' + Crlf);
  For K := 0 To NMime - 1 Do BufAdd(Bf, MimeExt[K] + '=' + MimeTyp[K] + Crlf);
  For K := 0 To MaxSites - 1 Do
    If Sites[K].Used Then
      With Sites[K] Do
      Begin
        BufAdd(Bf, Crlf + '[Site:' + IStr(Id) + ']' + Crlf);
        BufAdd(Bf, 'Nom=' + Name + Crlf);
        BufAdd(Bf, 'Racine=' + Root + Crlf);
        If Started Then BufAdd(Bf, 'Etat=Demarre' + Crlf) Else BufAdd(Bf, 'Etat=Arrete' + Crlf);
        For J := 0 To NB - 1 Do BufAdd(Bf, 'Liaison=' + BindStr(B[J]) + Crlf);
        BufAdd(Bf, 'Documents=');
        For J := 0 To ND - 1 Do
        Begin
          If J > 0 Then BufAdd(Bf, ',');
          BufAdd(Bf, Docs[J]);
        End;
        BufAdd(Bf, Crlf);
        BufAdd(Bf, 'Exploration=' + YesNo(Browse) + Crlf);
        BufAdd(Bf, 'Journal=' + YesNo(LogOn) + Crlf);
        BufAdd(Bf, 'Psp=' + YesNo(Psp) + Crlf);
        BufAdd(Bf, 'Asp=' + YesNo(Asp) + Crlf);
        BufAdd(Bf, 'Php=' + YesNo(Php) + Crlf);
        For J := 0 To NE - 1 Do BufAdd(Bf, 'Erreur=' + IStr(ErrCode[J]) + ',' + ErrPath[J] + Crlf);
        For J := 0 To NH - 1 Do BufAdd(Bf, 'Entete=' + Hdr[J] + Crlf);
        For J := 0 To NV - 1 Do BufAdd(Bf, 'Virtuel=' + VUrl[J] + ',' + VPath[J] + Crlf);
        If Cert <> '' Then BufAdd(Bf, 'Certificat=' + Cert + Crlf);
        If AuthUser <> '' Then
        Begin
          BufAdd(Bf, 'Utilisateur=' + AuthUser + Crlf);
          BufAdd(Bf, 'MotDePasse=' + AuthPass + Crlf);
        End;
      End;
  CfgPath := WwwData + '\WEBSRV.CFG';
  CfgSave := WriteFileBuf(CfgPath, Bf.P, Bf.Len);
  BufFree(Bf);
End;

{ --- certificats : fichier PEM du site (CERTIFICATE ..., puis la cle
  EC PRIVATE KEY ou PRIVATE KEY d'une courbe P-256) --- }

Function SiteHasTls(I : LongInt) : Boolean;
Var J : LongInt;
Begin
  SiteHasTls := False;
  For J := 0 To Sites[I].NB - 1 Do If Sites[I].B[J].Tls Then SiteHasTls := True;
End;

Function CertFile(I : LongInt) : String;
Begin
  If Sites[I].Cert <> '' Then CertFile := Sites[I].Cert
  Else CertFile := WwwData + '\CERTS\SITE' + IStr(Sites[I].Id) + '.PEM';
End;

{ nom du certificat cree : le premier nom d'hote d'une liaison https, sinon
  le nom de l'ordinateur }
Function CertName(I : LongInt) : String;
Var J : LongInt; S : String;
Begin
  S := '';
  For J := Sites[I].NB - 1 DownTo 0 Do
    If Sites[I].B[J].Tls And (Sites[I].B[J].Host <> '') Then S := Sites[I].B[J].Host;
  If S = '' Then S := PEnv('HOSTNAME');
  If S = '' Then S := 'os2-0';
  CertName := LoStr(S);
End;

Procedure CertLoad(I : LongInt);
Var B, Der : TBuf; K, Bg, En, N, J : LongInt; S, Lbl : String; Have : Boolean;

  Function Find(Const Pat : String; From : LongInt) : LongInt;
  Var A, C : LongInt; Ok : Boolean;
  Begin
    Find := -1;
    For A := From To B.Len - Length(Pat) Do
    Begin
      Ok := True;
      For C := 1 To Length(Pat) Do
        If B.P^[A + C - 1] <> Ord(Pat[C]) Then
        Begin
          Ok := False;
          Break;
        End;
      If Ok Then
      Begin
        Find := A;
        Exit;
      End;
    End;
  End;

Begin
  BufFree(CertDer[I]);
  CertOk[I] := False; CertMsg[I] := '';
  If Not SiteHasTls(I) Then Exit;
  S := CertFile(I);
  If Not PExists(S) Then
  Begin
    If Not CreateCertFile(S, CertName(I), 0) Then
    Begin
      CertMsg[I] := 'certificat impossible a creer : ' + S;
      Exit;
    End;
    SysLog('Certificat auto-signe cree pour ' + CertName(I) + ' : ' + S);
  End;
  If Not ReadFileBuf(S, B, 262144) Then
  Begin
    CertMsg[I] := 'certificat illisible : ' + S;
    Exit;
  End;
  Have := False;
  K := 0;
  Repeat
    Bg := Find('-----BEGIN ', K);
    If Bg < 0 Then Break;
    En := Find('-----', Bg + 11);
    If En < 0 Then Break;
    Lbl := '';
    For J := Bg + 11 To En - 1 Do Lbl := Lbl + Chr(B.P^[J]);
    K := En + 5;
    En := Find('-----END ', K);
    If En < 0 Then Break;
    BufInit(Der);
    BufGrow(Der, En - K);
    N := B64Dec(@B.P^[K], En - K, Der.P, Der.Cap);
    Der.Len := N;
    If Lbl = 'CERTIFICATE' Then
    Begin
      { entree de la liste : longueur (3 octets), certificat, extensions vides }
      BufAddC(CertDer[I], N Shr 16); BufAddC(CertDer[I], (N Shr 8) And 255); BufAddC(CertDer[I], N And 255);
      BufAddB(CertDer[I], Der.P, N);
      BufAddC(CertDer[I], 0); BufAddC(CertDer[I], 0);
    End
    Else If Pos('PRIVATE KEY', Lbl) > 0 Then
    Begin
      { la premiere chaine d'octets de 32 octets : la cle (SEC1 ou PKCS#8) }
      For J := 0 To N - 34 Do
        If (Not Have) And (Der.P^[J] = 4) And (Der.P^[J + 1] = 32) Then
        Begin
          Move(Der.P^[J + 2], CertKey[I], 32);
          Have := True;
        End;
    End;
    BufFree(Der);
    K := En + 9;
  Until False;
  BufFree(B);
  If CertDer[I].Len = 0 Then CertMsg[I] := 'aucun certificat dans ' + S
  Else If Not Have Then CertMsg[I] := 'cle P-256 absente de ' + S + ' (seules les cles ECDSA P-256 conviennent)'
  Else CertOk[I] := True;
  If CertMsg[I] <> '' Then SysLog('Site ' + IStr(Sites[I].Id) + ' : ' + CertMsg[I]);
End;

{ site d'une requete : liaison dont l'adresse et le port correspondent, et
  dont le nom d'hote est celui demande (un nom vide accepte tous les noms) }
Function FindSite(LocIp, Port : LongInt; Tls : Boolean; Host : String) : LongInt;
Var I, J, Best, Score, P : LongInt;
Begin
  Host := LoStr(Host);
  P := Pos(':', Host);
  If P > 0 Then Host := Copy(Host, 1, P - 1);
  Best := -1; Score := -1;
  For I := 0 To MaxSites - 1 Do
    If Sites[I].Used And Sites[I].Started Then
      For J := 0 To Sites[I].NB - 1 Do
        If (Sites[I].B[J].Port = Port) And (Sites[I].B[J].Tls = Tls) And
           ((Sites[I].B[J].Ip = 0) Or (Sites[I].B[J].Ip = LocIp)) And
           ((Sites[I].B[J].Host = '') Or (Sites[I].B[J].Host = Host)) Then
        Begin
          P := 0;
          If Sites[I].B[J].Host <> '' Then P := P + 2;
          If Sites[I].B[J].Ip <> 0 Then P := P + 1;
          If P > Score Then
          Begin
            Score := P; Best := I;
          End;
        End;
  FindSite := Best;
End;

{ ==================================================================== }
{ TLS 1.3 du cote serveur (TLS_AES_128_GCM_SHA256, X25519, signature    }
{ ECDSA P-256) : une machine a etats par connexion, sans attente         }
{ ==================================================================== }

Type
  TTls = Record
    Tr : TSha;                 { transcription de la poignee de main }
    Rd, Wr : TAes;
    RdOn, WrOn : Boolean;
    HsSec, CHs, SHs, CAp, SAp, Ms : TB32;
    Site : LongInt;            { site choisi par SNI }
    Sni : String[79];
    Alert : LongInt;           { alerte a envoyer (-1 : aucune) }
  End;

Var
  Tls : Array[0..MaxConn - 1] Of TTls;
  EmptyHash : TB32;

Procedure TlsInitTables;
Begin
  AesInitTables;
  Sha256(Nil, 0, EmptyHash);
End;

Function Get16(P : PBytes; O : LongInt) : LongInt;
Begin
  Get16 := (P^[O] Shl 8) Or P^[O + 1];
End;

Function Get24(P : PBytes; O : LongInt) : LongInt;
Begin
  Get24 := (P^[O] Shl 16) Or (P^[O + 1] Shl 8) Or P^[O + 2];
End;

{ ajouter un enregistrement a Tx : en clair, ou chiffre (contenu + type
  interieur + etiquette) si la cle d'ecriture est en place }
Function TlsRecord(C, Typ : LongInt; P : PBytes; N : LongInt) : Boolean;
Var H, L : LongInt; Q : PBytes;
Begin
  TlsRecord := False;
  If Conns[C].TxLen + N + 22 > TxCap Then Exit;
  H := Conns[C].TxLen;
  Q := Conns[C].Tx;
  If Not Tls[C].WrOn Then
  Begin
    Q^[H] := Typ; Q^[H + 1] := 3; Q^[H + 2] := 3; Q^[H + 3] := N Shr 8; Q^[H + 4] := N And 255;
    If N > 0 Then Move(P^[0], Q^[H + 5], N);
    Conns[C].TxLen := H + 5 + N;
  End
  Else
  Begin
    L := N + 1 + 16;
    Q^[H] := 23; Q^[H + 1] := 3; Q^[H + 2] := 3; Q^[H + 3] := L Shr 8; Q^[H + 4] := L And 255;
    If N > 0 Then Move(P^[0], Q^[H + 5], N);
    Q^[H + 5 + N] := Typ;
    Dummy := Ord(GcmRun(Tls[C].Wr, @Q^[H], 5, @Q^[H + 5], N + 1, @Q^[H + 5], @Q^[H + 6 + N], False));
    Conns[C].TxLen := H + 5 + L;
  End;
  TlsRecord := True;
End;

Procedure TlsAlert(C, Code : LongInt);
Var A : Array[0..1] Of Byte;
Begin
  If Code = 0 Then A[0] := 1 Else A[0] := 2;
  A[1] := Code;
  Dummy := Ord(TlsRecord(C, 21, @A, 2));
End;

{ cles d'un sens a partir d'un secret de trafic }
Procedure TlsKeys(Var A : TAes; Var Sec : TB32);
Var K : Array[0..15] Of Byte; Iv : Array[0..11] Of Byte;
Begin
  ExpandLabel(Sec, 'key', Nil, 0, 16, @K);
  ExpandLabel(Sec, 'iv', Nil, 0, 12, @Iv);
  GcmInit(A, @K, @Iv);
End;

{ message de poignee de main : ajoute a la transcription et a Out }
Procedure HsMsg(Var Tr : TSha; Var Out_ : TBuf; Typ : LongInt; Var Body : TBuf);
Var H : Array[0..3] Of Byte;
Begin
  H[0] := Typ; H[1] := (Body.Len Shr 16) And 255; H[2] := (Body.Len Shr 8) And 255; H[3] := Body.Len And 255;
  ShaUpd(Tr, @H, 4);
  ShaUpd(Tr, Body.P, Body.Len);
  BufAddB(Out_, @H, 4);
  BufAddB(Out_, Body.P, Body.Len);
End;

Procedure Put16B(Var B : TBuf; V : LongInt);
Begin
  BufAddC(B, (V Shr 8) And 255);
  BufAddC(B, V And 255);
End;

{ ClientHello recu (M : message entier, N octets) : reponse ServerHello,
  puis EncryptedExtensions, Certificate, CertificateVerify et Finished }
Function TlsClientHello(C : LongInt; M : PBytes; N : LongInt) : Boolean;
Var P, E, ELen, ET, EL, SidL, Ns, K, L, Site, J : LongInt;
    Sid : Array[0..31] Of Byte; Peer, Priv, Pub, Shared, Early, Der, Hh, FinKey, Vd : TB32;
    HasSuite, HasV13, HasKey : Boolean; Sni : String;
    Body, Out_, Sig : TBuf; Tbs : Array[0..129] Of Byte; Sr_, Ss : TB32; Zero : TB32; S : String;
Begin
  TlsClientHello := False;
  Tls[C].Alert := 40;
  If N < 4 + 38 Then Exit;
  P := 4 + 2 + 32;
  SidL := M^[P];
  If SidL > 32 Then Exit;
  For K := 0 To SidL - 1 Do Sid[K] := M^[P + 1 + K];
  P := P + 1 + SidL;
  If P + 2 > N Then Exit;
  Ns := Get16(M, P);
  HasSuite := False;
  K := 0;
  While K < Ns Do
  Begin
    If Get16(M, P + 2 + K) = $1301 Then HasSuite := True;
    K := K + 2;
  End;
  P := P + 2 + Ns;
  If P >= N Then Exit;
  P := P + 1 + M^[P];
  HasV13 := False; HasKey := False; Sni := '';
  If P + 2 <= N Then
  Begin
    ELen := Get16(M, P);
    E := P + 2;
    While (E + 4 <= P + 2 + ELen) And (E + 4 <= N) Do
    Begin
      ET := Get16(M, E); EL := Get16(M, E + 2);
      If E + 4 + EL > N Then Break;
      If ET = 0 Then
      Begin
        { server_name : liste, type 0, nom }
        If (EL > 5) And (M^[E + 6] = 0) Then
        Begin
          L := Get16(M, E + 7);
          For K := 0 To L - 1 Do
            If (Length(Sni) < 79) And (E + 9 + K < N) Then Sni := Sni + Chr(M^[E + 9 + K]);
        End;
      End
      Else If ET = 43 Then
      Begin
        For K := 0 To (M^[E + 4] Div 2) - 1 Do
          If Get16(M, E + 5 + K * 2) = $0304 Then HasV13 := True;
      End
      Else If ET = 51 Then
      Begin
        K := E + 6;
        While K + 4 <= E + 4 + EL Do
        Begin
          L := Get16(M, K + 2);
          If (Get16(M, K) = $001D) And (L = 32) Then
          Begin
            For J := 0 To 31 Do Peer[J] := M^[K + 4 + J];
            HasKey := True;
          End;
          K := K + 4 + L;
        End;
      End;
      E := E + 4 + EL;
    End;
  End;
  If Not HasV13 Then
  Begin
    Tls[C].Alert := 70;
    SysLog('TLS : client sans TLS 1.3 (' + IpStr(Conns[C].PeerIp) + ')');
    Exit;
  End;
  If (Not HasSuite) Or (Not HasKey) Then
  Begin
    Tls[C].Alert := 40;
    SysLog('TLS : client sans TLS_AES_128_GCM_SHA256 ou X25519 (' + IpStr(Conns[C].PeerIp) + ')');
    Exit;
  End;
  { site : par le nom (SNI), sinon par la liaison }
  Site := FindSite(Conns[C].LocalIp, Conns[C].LocalPort, True, Sni);
  If Site < 0 Then Site := FindSite(Conns[C].LocalIp, Conns[C].LocalPort, True, '');
  If (Site < 0) Or Not CertOk[Site] Then
  Begin
    Tls[C].Alert := 80;
    Exit;
  End;
  Tls[C].Site := Site; Tls[C].Sni := Sni;
  { transcription : ClientHello }
  ShaInit(Tls[C].Tr);
  ShaUpd(Tls[C].Tr, M, N);
  { ServerHello }
  BufInit(Body); BufInit(Out_); BufInit(Sig);
  RandFill(@Priv, 32);
  For K := 0 To 31 Do Zero[K] := 0;
  Zero[0] := 9;
  X25519(Pub, Priv, Zero);
  Put16B(Body, $0303);
  BufGrow(Body, 32);
  RandFill(@Body.P^[Body.Len], 32);
  Body.Len := Body.Len + 32;
  BufAddC(Body, SidL);
  BufAddB(Body, @Sid, SidL);
  Put16B(Body, $1301);
  BufAddC(Body, 0);
  Put16B(Body, 6 + 40);
  Put16B(Body, 43); Put16B(Body, 2); Put16B(Body, $0304);
  Put16B(Body, 51); Put16B(Body, 36); Put16B(Body, $001D); Put16B(Body, 32);
  BufAddB(Body, @Pub, 32);
  HsMsg(Tls[C].Tr, Out_, 2, Body);
  Dummy := Ord(TlsRecord(C, 22, Out_.P, Out_.Len));
  { changement de chiffrement factice (compatibilite) }
  K := 1;
  Dummy := Ord(TlsRecord(C, 20, @K, 1));
  { secrets de la poignee de main }
  X25519(Shared, Priv, Peer);
  For K := 0 To 31 Do Zero[K] := 0;
  Hmac(@Zero, 32, @Zero, 32, Early);
  ExpandLabel(Early, 'derived', @EmptyHash, 32, 32, @Der);
  Hmac(@Der, 32, @Shared, 32, Tls[C].HsSec);
  ShaFinal(Tls[C].Tr, Hh);
  ExpandLabel(Tls[C].HsSec, 'c hs traffic', @Hh, 32, 32, @Tls[C].CHs);
  ExpandLabel(Tls[C].HsSec, 's hs traffic', @Hh, 32, 32, @Tls[C].SHs);
  TlsKeys(Tls[C].Wr, Tls[C].SHs);
  TlsKeys(Tls[C].Rd, Tls[C].CHs);
  Tls[C].WrOn := True; Tls[C].RdOn := True;
  { EncryptedExtensions (vides), Certificate, CertificateVerify, Finished }
  Out_.Len := 0;
  Body.Len := 0;
  Put16B(Body, 0);
  HsMsg(Tls[C].Tr, Out_, 8, Body);
  Body.Len := 0;
  BufAddC(Body, 0);
  L := CertDer[Site].Len;
  BufAddC(Body, L Shr 16); BufAddC(Body, (L Shr 8) And 255); BufAddC(Body, L And 255);
  BufAddB(Body, CertDer[Site].P, L);
  HsMsg(Tls[C].Tr, Out_, 11, Body);
  ShaFinal(Tls[C].Tr, Hh);
  For K := 0 To 63 Do Tbs[K] := 32;
  S := 'TLS 1.3, server CertificateVerify';
  For K := 1 To Length(S) Do Tbs[63 + K] := Ord(S[K]);
  Tbs[64 + Length(S)] := 0;
  For K := 0 To 31 Do Tbs[65 + Length(S) + K] := Hh[K];
  Sha256(@Tbs, 97 + Length(S), Hh);
  EcSign(@CertKey[Site], @Hh, @Sr_, @Ss);
  EcSigDer(@Sr_, @Ss, Sig);
  Body.Len := 0;
  Put16B(Body, $0403);
  Put16B(Body, Sig.Len);
  BufAddB(Body, Sig.P, Sig.Len);
  HsMsg(Tls[C].Tr, Out_, 15, Body);
  ShaFinal(Tls[C].Tr, Hh);
  ExpandLabel(Tls[C].SHs, 'finished', Nil, 0, 32, @FinKey);
  Hmac(@FinKey, 32, @Hh, 32, Vd);
  Body.Len := 0;
  BufAddB(Body, @Vd, 32);
  HsMsg(Tls[C].Tr, Out_, 20, Body);
  If Not TlsRecord(C, 22, Out_.P, Out_.Len) Then
  Begin
    BufFree(Body); BufFree(Out_); BufFree(Sig);
    Tls[C].Alert := 80;
    Exit;
  End;
  { secrets de l'application (transcription jusqu'au Finished du serveur) }
  ShaFinal(Tls[C].Tr, Hh);
  ExpandLabel(Tls[C].HsSec, 'derived', @EmptyHash, 32, 32, @Der);
  Hmac(@Der, 32, @Zero, 32, Tls[C].Ms);
  ExpandLabel(Tls[C].Ms, 'c ap traffic', @Hh, 32, 32, @Tls[C].CAp);
  ExpandLabel(Tls[C].Ms, 's ap traffic', @Hh, 32, 32, @Tls[C].SAp);
  TlsKeys(Tls[C].Wr, Tls[C].SAp);
  BufFree(Body); BufFree(Out_); BufFree(Sig);
  Tls[C].Alert := -1;
  TlsClientHello := True;
End;

{ Finished du client : verification, puis cle de lecture de l'application }
Function TlsClientFinished(C : LongInt; M : PBytes; N : LongInt) : Boolean;
Var FinKey, Hh, Vd : TB32; K, D : LongInt;
Begin
  TlsClientFinished := False;
  Tls[C].Alert := 51;
  If N <> 36 Then Exit;
  ShaFinal(Tls[C].Tr, Hh);
  ExpandLabel(Tls[C].CHs, 'finished', Nil, 0, 32, @FinKey);
  Hmac(@FinKey, 32, @Hh, 32, Vd);
  D := 0;
  For K := 0 To 31 Do D := D Or (Vd[K] Xor M^[4 + K]);
  If D <> 0 Then Exit;
  TlsKeys(Tls[C].Rd, Tls[C].CAp);
  Tls[C].Alert := -1;
  TlsClientFinished := True;
End;

{ traiter les enregistrements complets de Rx : rend Faux si la connexion
  doit etre fermee ; les donnees de l'application vont dans Req }
Function TlsInput(C : LongInt) : Boolean;
Var L, Typ, N, K, MT, ML : LongInt; Q : PBytes;
Begin
  TlsInput := False;
  Q := Conns[C].Rx;
  While Conns[C].RxLen >= 5 Do
  Begin
    Typ := Q^[0];
    L := Get16(Q, 3);
    If L > 16384 + 256 Then
    Begin
      TlsAlert(C, 22);
      Exit;
    End;
    If Conns[C].RxLen < 5 + L Then Break;
    If Typ = 20 Then
      { ChangeCipherSpec de compatibilite : ignore }
    Else If Typ = 21 Then
    Begin
      If Not Tls[C].RdOn Then Exit;
    End
    Else If (Typ = 22) And Not Tls[C].RdOn Then
    Begin
      { ClientHello en clair : dans Req jusqu'a ce qu'il soit entier }
      If Conns[C].ReqLen + L > ReqCap Then Exit;
      Move(Q^[5], Conns[C].Req^[Conns[C].ReqLen], L);
      Conns[C].ReqLen := Conns[C].ReqLen + L;
      If Conns[C].ReqLen >= 4 Then
      Begin
        ML := Get24(Conns[C].Req, 1);
        If (Conns[C].Req^[0] <> 1) Then
        Begin
          TlsAlert(C, 10);
          Exit;
        End;
        If Conns[C].ReqLen >= 4 + ML Then
        Begin
          If Not TlsClientHello(C, Conns[C].Req, 4 + ML) Then
          Begin
            TlsAlert(C, Tls[C].Alert);
            Exit;
          End;
          Conns[C].ReqLen := 0;
          Conns[C].TlsSt := 1;
        End;
      End;
    End
    Else If (Typ = 23) And Tls[C].RdOn Then
    Begin
      If (L < 17) Or Not GcmRun(Tls[C].Rd, Q, 5, @Q^[5], L - 16, @Q^[5], @Q^[5 + L - 16], True) Then
      Begin
        TlsAlert(C, 20);
        Exit;
      End;
      N := L - 16;
      While (N > 0) And (Q^[5 + N - 1] = 0) Do Dec(N);
      If N = 0 Then Exit;
      MT := Q^[5 + N - 1];
      Dec(N);
      If MT = 21 Then Exit;                { alerte (close_notify...) }
      If MT = 22 Then
      Begin
        If (Conns[C].TlsSt = 1) And (N >= 4) And (Q^[5] = 20) Then
        Begin
          If Not TlsClientFinished(C, @Q^[5], N) Then
          Begin
            TlsAlert(C, Tls[C].Alert);
            Exit;
          End;
          Conns[C].TlsSt := 2;
          Conns[C].State := csRead;
          Conns[C].ReqLen := 0;
        End;
        { les autres messages (KeyUpdate, NewSessionTicket) sont ignores }
      End
      Else If MT = 23 Then
      Begin
        If Conns[C].TlsSt <> 2 Then Exit;
        If (Conns[C].State = csBody) And (Conns[C].Body <> Nil) Then
        Begin
          K := N;
          If Conns[C].BodyGot + K > Conns[C].BodyLen Then K := Conns[C].BodyLen - Conns[C].BodyGot;
          If K > 0 Then Move(Q^[5], Conns[C].Body^[Conns[C].BodyGot], K);
          Conns[C].BodyGot := Conns[C].BodyGot + K;
        End
        Else
        Begin
          If Conns[C].ReqLen + N > ReqCap Then Exit;
          Move(Q^[5], Conns[C].Req^[Conns[C].ReqLen], N);
          Conns[C].ReqLen := Conns[C].ReqLen + N;
        End;
        { un enregistrement a la fois : la requete est analysee entre deux }
        TlsGotData := True;
        K := 5 + L;
        If Conns[C].RxLen > K Then Move(Q^[K], Q^[0], Conns[C].RxLen - K);
        Conns[C].RxLen := Conns[C].RxLen - K;
        TlsInput := True;
        Exit;
      End;
    End
    Else
    Begin
      TlsAlert(C, 10);
      Exit;
    End;
    { enregistrement suivant }
    K := 5 + L;
    If Conns[C].RxLen > K Then Move(Q^[K], Q^[0], Conns[C].RxLen - K);
    Conns[C].RxLen := Conns[C].RxLen - K;
  End;
  TlsInput := True;
End;

{ ==================================================================== }
{ HTTP : connexions, requetes, fichiers, erreurs, journal               }
{ ==================================================================== }

Var
  Scratch : Array[0..ChunkSz - 1] Of Byte;
  LogBuf : Array[0..MaxSites - 1] Of TBuf;     { lignes du journal en attente }
  LogDay : Array[0..MaxSites - 1] Of LongInt;
  LastLogFlush : LongInt;
  { file des pages a executer (PSP, ASP) }
  VmQueue : Array[0..MaxConn - 1] Of LongInt;
  VmQLen : LongInt;

Procedure VmEnqueue(C : LongInt); Forward;
Procedure VmAbort(C : LongInt); Forward;

{ en-tete de la requete (insensible a la casse) ; '' : absent }
Function HdrGet(C : LongInt; Name : String) : String;
Var K, L, E : LongInt; S, U : String; Q : PBytes;
Begin
  HdrGet := '';
  Name := UpStr(Name) + ':';
  Q := Conns[C].Req;
  K := 0;
  { sauter la ligne de requete }
  While (K < Conns[C].HdrEnd) And (Q^[K] <> 10) Do Inc(K);
  Inc(K);
  While K < Conns[C].HdrEnd - 2 Do
  Begin
    E := K;
    While (E < Conns[C].HdrEnd) And (Q^[E] <> 10) Do Inc(E);
    L := E - K;
    If (L > 0) And (Q^[E - 1] = 13) Then Dec(L);
    If L > Length(Name) Then
    Begin
      U := '';
      For E := 0 To Length(Name) - 1 Do U := U + UpCase(Chr(Q^[K + E]));
      If U = Name Then
      Begin
        S := '';
        For E := K + Length(Name) To K + L - 1 Do
          If Length(S) < 255 Then S := S + Chr(Q^[E]);
        HdrGet := Trim(S);
        Exit;
      End;
    End;
    While (K < Conns[C].HdrEnd) And (Q^[K] <> 10) Do Inc(K);
    Inc(K);
  End;
End;

{ ecrire des octets en clair vers le client (chiffres en HTTPS) ; N <= ChunkSz }
Function ConnPut(C : LongInt; P : PBytes; N : LongInt) : Boolean;
Begin
  ConnPut := False;
  If N <= 0 Then
  Begin
    ConnPut := True;
    Exit;
  End;
  If Conns[C].IsTls Then ConnPut := TlsRecord(C, 23, P, N)
  Else
  Begin
    If Conns[C].TxLen + N > TxCap Then Exit;
    Move(P^[0], Conns[C].Tx^[Conns[C].TxLen], N);
    Conns[C].TxLen := Conns[C].TxLen + N;
    ConnPut := True;
  End;
End;

Procedure ConnPutStr(C : LongInt; Const S : String);
Begin
  If Length(S) > 0 Then Dummy := Ord(ConnPut(C, @S[1], Length(S)));
End;

Procedure ConnFreeBody(C : LongInt);
Begin
  With Conns[C] Do
  Begin
    If BFile >= 0 Then PClose(BFile);
    BFile := -1;
    If BMemOwn And (BMem <> Nil) Then FreeMem(BMem, BMemCap);
    BMem := Nil; BMemOwn := False;
    BSrc := bsNone; BLen := 0; BPos := 0; BLeft := 0;
    If Body <> Nil Then FreeMem(Body, BodyCap);
    Body := Nil; BodyCap := 0; BodyGot := 0;
  End;
End;

Procedure ConnClose(C : LongInt);
Begin
  If Conns[C].State = csFree Then Exit;
  If (Conns[C].State = csWaitVm) Or (Conns[C].State = csVm) Then VmAbort(C);
  ConnFreeBody(C);
  PSockClose(Conns[C].Sock);
  Conns[C].State := csFree;
  Dec(CurConn);
End;

{ nouvelle connexion acceptee }
Function ConnNew(S, L, Ip, Port, LocIp : LongInt) : LongInt;
Var C, K : LongInt;
Begin
  ConnNew := -1;
  C := -1;
  For K := MaxConn - 1 DownTo 0 Do
    If Conns[K].State = csFree Then C := K;
  If (C < 0) Or (CurConn >= MaxConnCfg) Then
  Begin
    { trop de connexions : 503 tout de suite }
    LogMsg := 'HTTP/1.1 503 Service Unavailable' + Crlf + 'Content-Length: 0' + Crlf + 'Connection: close' + Crlf + Crlf;
    If Not LTls[L] Then Dummy := PSend(S, @LogMsg[1], Length(LogMsg));
    PSockClose(S);
    Inc(TotErr);
    Exit;
  End;
  FillChar(Conns[C], SizeOf(TConn), 0);
  With Conns[C] Do
  Begin
    Sock := S; LIdx := L; PeerIp := Ip; PeerPort := Port; LocalIp := LocIp; LocalPort := LPort[L];
    IsTls := LTls[L];
    Rx := @Pool^[C * (RxCap + ReqCap + TxCap)];
    Req := @Pool^[C * (RxCap + ReqCap + TxCap) + RxCap];
    Tx := @Pool^[C * (RxCap + ReqCap + TxCap) + RxCap + ReqCap];
    BFile := -1; Site := -1;
    T0 := PTicks; TLast := T0;
    If IsTls Then
    Begin
      State := csTls; TlsSt := 0;
      Tls[C].RdOn := False; Tls[C].WrOn := False; Tls[C].Site := -1; Tls[C].Alert := -1;
    End
    Else State := csRead;
  End;
  Inc(CurConn);
  If CurConn > MaxSeen Then MaxSeen := CurConn;
  RandStir(Ip Xor Port);
  ConnNew := C;
End;

{ --- journal W3C (un fichier par jour et par site), ecrit par paquets --- }

Procedure LogFlush(I : LongInt);
Var H, Y, Mo, D, Hh, Mi, S, Wd : LongInt; Dir, Fn : String; New_ : Boolean;
Begin
  If LogBuf[I].Len = 0 Then Exit;
  PNow(Y, Mo, D, Hh, Mi, S, Wd);
  Dir := WwwData + '\LOGS\W3SVC' + IStr(Sites[I].Id);
  Fn := Dir + '\ex' + Pad2(Y Mod 100) + Pad2(Mo) + Pad2(D) + '.log';
  New_ := Not PExists(Fn);
  If New_ Then PMkDir(Dir);
  If POpenWrite(Fn, True, H) Then
  Begin
    If New_ Then
    Begin
      LogMsg := '#Software: Serveur Web d''OS/2-0 ' + AppVer + Crlf + '#Version: 1.0' + Crlf + '#Date: ' + IStr(Y) +
                '-' + Pad2(Mo) + '-' + Pad2(D) + ' ' + Pad2(Hh) + ':' + Pad2(Mi) + ':' + Pad2(S) + Crlf +
                '#Fields: date time s-ip cs-method cs-uri-stem cs-uri-query s-port c-ip cs(User-Agent) ' +
                'sc-status sc-bytes time-taken' + Crlf;
      Dummy := PWrite(H, @LogMsg[1], Length(LogMsg));
    End;
    Dummy := PWrite(H, LogBuf[I].P, LogBuf[I].Len);
    PClose(H);
  End;
  LogBuf[I].Len := 0;
End;

Procedure LogFlushAll;
Var I : LongInt;
Begin
  For I := 0 To MaxSites - 1 Do
    If LogBuf[I].Len > 0 Then LogFlush(I);
  LastLogFlush := PTicks;
End;

Procedure LogRequest(C : LongInt);
Var Y, Mo, D, H, Mi, S, Wd, I : LongInt; Ua, Q : String;
Begin
  I := Conns[C].Site;
  If (I < 0) Or Not Sites[I].LogOn Then Exit;
  PNow(Y, Mo, D, H, Mi, S, Wd);
  Ua := HdrGet(C, 'User-Agent');
  For Wd := 1 To Length(Ua) Do If Ua[Wd] = ' ' Then Ua[Wd] := '+';
  If Ua = '' Then Ua := '-';
  Q := Conns[C].Query;
  If Q = '' Then Q := '-';
  BufAdd(LogBuf[I], IStr(Y) + '-' + Pad2(Mo) + '-' + Pad2(D) + ' ' + Pad2(H) + ':' + Pad2(Mi) + ':' + Pad2(S) + ' ' +
         IpStr(Conns[C].LocalIp) + ' ' + Conns[C].Method + ' ' + UrlPathEncode(Conns[C].Uri) + ' ' + Q + ' ' +
         IStr(Conns[C].LocalPort) + ' ' + IpStr(Conns[C].PeerIp) + ' ' + Ua + ' ' + IStr(Conns[C].Status) + ' ' +
         IStr(Conns[C].SentBytes) + ' ' + IStr(PTicks - Conns[C].T0) + Crlf);
  If LogBuf[I].Len > 16384 Then LogFlush(I);
End;

{ --- reponses --- }

Function StatusText(Code : LongInt) : String;
Begin
  Case Code Of
    200 : StatusText := 'OK';
    201 : StatusText := 'Created';
    204 : StatusText := 'No Content';
    206 : StatusText := 'Partial Content';
    301 : StatusText := 'Moved Permanently';
    302 : StatusText := 'Found';
    304 : StatusText := 'Not Modified';
    400 : StatusText := 'Bad Request';
    401 : StatusText := 'Unauthorized';
    403 : StatusText := 'Forbidden';
    404 : StatusText := 'Not Found';
    405 : StatusText := 'Method Not Allowed';
    408 : StatusText := 'Request Timeout';
    413 : StatusText := 'Payload Too Large';
    414 : StatusText := 'URI Too Long';
    416 : StatusText := 'Range Not Satisfiable';
    431 : StatusText := 'Request Header Fields Too Large';
    500 : StatusText := 'Internal Server Error';
    501 : StatusText := 'Not Implemented';
    503 : StatusText := 'Service Unavailable';
  Else
    StatusText := 'Status';
  End;
End;

{ en-tetes communs : etat, date, serveur, connexion, en-tetes du site ;
  Ex : en-tetes en plus (lignes completes) }
Procedure PutHeadBuf(C, Code : LongInt; CType : String; Len : LongInt; Var Ex : TBuf);
Var S : String; K, I : LongInt; B : TBuf;
Begin
  Conns[C].Status := Code;
  BufInit(B);
  BufAdd(B, 'HTTP/1.1 ' + IStr(Code) + ' ' + StatusText(Code) + Crlf);
  BufAdd(B, 'Date: ' + HttpDate(NowUnix) + Crlf);
  BufAdd(B, 'Server: ' + ServerName + Crlf);
  If CType <> '' Then BufAdd(B, 'Content-Type: ' + CType + Crlf);
  If Len >= 0 Then BufAdd(B, 'Content-Length: ' + IStr(Len) + Crlf);
  I := Conns[C].Site;
  If I >= 0 Then
    For K := 0 To Sites[I].NH - 1 Do BufAdd(B, Sites[I].Hdr[K] + Crlf);
  BufAddB(B, Ex.P, Ex.Len);
  If Conns[C].KeepAlive Then S := 'Connection: keep-alive' + Crlf + 'Keep-Alive: timeout=' + IStr(KeepAliveS) + Crlf
  Else S := 'Connection: close' + Crlf;
  BufAdd(B, S + Crlf);
  K := 0;
  While K < B.Len Do
  Begin
    I := B.Len - K;
    If I > 4096 Then I := 4096;
    Dummy := Ord(ConnPut(C, @B.P^[K], I));
    K := K + I;
  End;
  Conns[C].SentBytes := Conns[C].SentBytes + B.Len;
  BufFree(B);
End;

Procedure PutHead(C, Code : LongInt; CType : String; Len : LongInt; Extra : String);
Var Ex : TBuf;
Begin
  BufInit(Ex);
  BufAdd(Ex, Extra);
  PutHeadBuf(C, Code, CType, Len, Ex);
  BufFree(Ex);
End;

{ reponse dont le corps est en memoire (B est donne a la connexion) }
Procedure SendMem(C, Code : LongInt; CType : String; Var B : TBuf; Extra : String);
Begin
  PutHead(C, Code, CType, B.Len, Extra);
  With Conns[C] Do
  Begin
    If Head Or (B.Len = 0) Then BufFree(B)
    Else
    Begin
      BSrc := bsMem; BMem := B.P; BLen := B.Len; BPos := 0; BMemOwn := True; BMemCap := B.Cap;
    End;
    State := csSend;
  End;
  BufInit(B);
End;

Procedure PageTop(Var B : TBuf; Title : String);
Begin
  BufAdd(B, '<!DOCTYPE html>' + #10 + '<html><head><meta charset="utf-8"><title>' + Cp850Utf8(HtmlEnc(Title)) +
         '</title>');
  BufAdd(B, '<style>body{font-family:Helv,Helvetica,Arial,sans-serif;background:#fff;margin:0}' +
         'h1{background:#0000aa;color:#fff;font-size:16pt;padding:8px 14px;margin:0}');
  BufAdd(B, 'div{padding:10px 18px}pre{font-family:Courier,monospace}</style></head><body>');
End;

{ page d'erreur : celle du site (Erreur=code,chemin), sinon la page du
  serveur }
Procedure SendError(C, Code : LongInt; Detail : String);
Var B : TBuf; I, K, Sz, Mt : LongInt; T, P : String; Dr : Boolean;
Begin
  Inc(TotErr);
  I := Conns[C].Site;
  If I >= 0 Then
    For K := 0 To Sites[I].NE - 1 Do
      If Sites[I].ErrCode[K] = Code Then
      Begin
        P := Sites[I].ErrPath[K];
        If (P <> '') And ((P[1] = '/') Or (P[1] = '\')) Then P := Sites[I].Root + P;
        For Sz := 1 To Length(P) Do If P[Sz] = '/' Then P[Sz] := '\';
        If PStat(P, Sz, Mt, Dr) And Not Dr And (Sz < 1048576) And ReadFileBuf(P, B, 1048576) Then
        Begin
          SendMem(C, Code, MimeOf(P), B, '');
          Exit;
        End;
      End;
  Case Code Of
    400 : T := 'Requ'#136'te incorrecte';
    401 : T := 'Acc'#138's refus'#130' : identification requise';
    403 : T := 'Interdit : acc'#138's refus'#130;
    404 : T := 'Fichier ou r'#130'pertoire introuvable';
    405 : T := 'M'#130'thode non autoris'#130'e';
    413 : T := 'Requ'#136'te trop grande';
    414 : T := 'Adresse trop longue';
    416 : T := 'Plage demand'#130'e impossible';
    500 : T := 'Erreur interne du serveur';
    501 : T := 'M'#130'thode non prise en charge';
    503 : T := 'Service indisponible';
  Else
    T := StatusText(Code);
  End;
  BufInit(B);
  PageTop(B, IStr(Code) + ' - ' + T);
  BufAdd(B, '<h1>Erreur de serveur</h1><div><h2>' + IStr(Code) + ' - ' + Cp850Utf8(HtmlEnc(T)) + '.</h2>');
  If Detail <> '' Then BufAdd(B, '<p>' + Cp850Utf8(Detail) + '</p>');
  BufAdd(B, '<hr><p><i>' + HtmlEnc(ServerName) + ' (OS/2-0)</i></p></div></body></html>' + #10);
  If Code = 401 Then T := 'WWW-Authenticate: Basic realm="' + Sites[I].Name + '"' + Crlf Else T := '';
  If (Code = 400) Or (Code = 413) Or (Code = 414) Or (Code = 431) Or (Code = 408) Then Conns[C].KeepAlive := False;
  SendMem(C, Code, 'text/html; charset=utf-8', B, T);
End;

Procedure SendRedirect(C : LongInt; Loc : String; Code : LongInt);
Var B : TBuf;
Begin
  BufInit(B);
  PageTop(B, 'Document d'#130'plac'#130);
  BufAdd(B, '<h1>Document d'#130'plac'#130'</h1><div><p><a href="' + HtmlEnc(Loc) + '">' + HtmlEnc(Loc) +
         '</a></p></div></body></html>' + #10);
  SendMem(C, Code, 'text/html; charset=utf-8', B, 'Location: ' + Loc + Crlf);
End;

{ exploration de repertoire (comme IIS : date, taille, nom) }
Procedure SendListing(C : LongInt; Dir, Url : String);
Var B : TBuf; Nm : String; Sz, Mt, Y, Mo, D, H, Mi, S, Wd, N, K, J : LongInt; Dr, Ok : Boolean;
    Names : Array[0..511] Of String[63]; Info : Array[0..511] Of String[40]; IsD : Array[0..511] Of Boolean;
    TmpS : String; TmpB : Boolean;
Begin
  N := 0;
  Ok := PFindFirst(Dir, Nm, Sz, Mt, Dr);
  While Ok And (N < 512) Do
  Begin
    If (Nm <> '.') And (Nm <> '..') Then
    Begin
      UnixSplit(Mt, Y, Mo, D, H, Mi, S, Wd);
      Names[N] := Nm; IsD[N] := Dr;
      If Dr Then TmpS := '&lt;r'#130'pertoire&gt;' Else TmpS := IStr(Sz);
      While Length(TmpS) < 14 Do TmpS := ' ' + TmpS;
      Info[N] := Pad2(D) + '/' + Pad2(Mo) + '/' + IStr(Y) + ' ' + Pad2(H) + ':' + Pad2(Mi) + '  ' + TmpS;
      Inc(N);
    End;
    Ok := PFindNext(Nm, Sz, Mt, Dr);
  End;
  PFindClose;
  { dossiers d'abord, puis par nom }
  For K := 1 To N - 1 Do
    For J := K DownTo 1 Do
      If (IsD[J] And Not IsD[J - 1]) Or ((IsD[J] = IsD[J - 1]) And (UpStr(Names[J]) < UpStr(Names[J - 1]))) Then
      Begin
        TmpS := Names[J]; Names[J] := Names[J - 1]; Names[J - 1] := TmpS;
        TmpS := Info[J]; Info[J] := Info[J - 1]; Info[J - 1] := TmpS;
        TmpB := IsD[J]; IsD[J] := IsD[J - 1]; IsD[J - 1] := TmpB;
      End
      Else Break;
  BufInit(B);
  PageTop(B, Conns[C].Host + ' - ' + Url);
  BufAdd(B, '<h1>' + HtmlEnc(Conns[C].Host) + ' - ' + Cp850Utf8(HtmlEnc(Url)) + '</h1><div><pre>');
  If Url <> '/' Then
  Begin
    K := Length(Url) - 1;
    While (K > 0) And (Url[K] <> '/') Do Dec(K);
    BufAdd(B, '<a href="' + UrlPathEncode(Copy(Url, 1, K)) + '">[R'#195#169'pertoire parent]</a>' + #10 + #10);
  End;
  For K := 0 To N - 1 Do
  Begin
    TmpS := Names[K];
    If IsD[K] Then TmpS := TmpS + '/';
    BufAdd(B, Cp850Utf8(Info[K]) + ' <a href="' + UrlPathEncode(Url + TmpS) + '">' + Cp850Utf8(HtmlEnc(Names[K])) +
           '</a>' + #10);
  End;
  BufAdd(B, '</pre><hr><p><i>' + HtmlEnc(ServerName) + ' (OS/2-0)</i></p></div></body></html>' + #10);
  SendMem(C, 200, 'text/html; charset=utf-8', B, '');
End;

{ fichier statique : conditionnel (304), plages (206) }
Procedure SendFile(C : LongInt; Path : String; Size, MTime : LongInt);
Var ETag, S, Extra : String; St, En, Code, P, H, Ims : LongInt;
Begin
  ETag := '"' + Hex(MTime, 8) + '-' + Hex(Size, 8) + '"';
  S := HdrGet(C, 'If-None-Match');
  Ims := -1;
  If S <> '' Then
  Begin
    If (S = ETag) Or (S = '*') Or (Pos(ETag, S) > 0) Then Ims := MTime Else Ims := -2;
  End
  Else
  Begin
    S := HdrGet(C, 'If-Modified-Since');
    If S <> '' Then Ims := ParseHttpDate(S);
  End;
  Extra := 'Last-Modified: ' + HttpDate(MTime) + Crlf + 'ETag: ' + ETag + Crlf + 'Accept-Ranges: bytes' + Crlf;
  If (Ims >= 0) And (MTime <= Ims) Then
  Begin
    PutHead(C, 304, '', -1, 'ETag: ' + ETag + Crlf);
    Conns[C].State := csSend;
    Exit;
  End;
  Code := 200; St := 0; En := Size - 1;
  S := LoStr(HdrGet(C, 'Range'));
  If (Copy(S, 1, 6) = 'bytes=') And (Pos(',', S) = 0) Then
  Begin
    S := Copy(S, 7, 255);
    P := Pos('-', S);
    If P > 0 Then
    Begin
      If P = 1 Then
      Begin
        St := Size - SVal(Copy(S, 2, 20));
        If St < 0 Then St := 0;
      End
      Else
      Begin
        St := SVal(Copy(S, 1, P - 1));
        If P < Length(S) Then En := SVal(Copy(S, P + 1, 20));
      End;
      If En > Size - 1 Then En := Size - 1;
      If (St > En) Or (St >= Size) Then
      Begin
        SendError(C, 416, '');
        Exit;
      End;
      Code := 206;
      Extra := Extra + 'Content-Range: bytes ' + IStr(St) + '-' + IStr(En) + '/' + IStr(Size) + Crlf;
    End;
  End;
  If Not POpenRead(Path, H) Then
  Begin
    SendError(C, 403, '');
    Exit;
  End;
  PutHead(C, Code, MimeOf(Path), En - St + 1, Extra);
  If Conns[C].Head Or (Size = 0) Then PClose(H)
  Else
  Begin
    If St > 0 Then PSeek(H, St);
    Conns[C].BFile := H;
    Conns[C].BLeft := En - St + 1;
    Conns[C].BSrc := bsFile;
  End;
  Conns[C].State := csSend;
End;

{ URL -> chemin du disque (repertoires virtuels) ; '' : refuse }
Function MapPath(I : LongInt; Url : String) : String;
Var K, Best, L : LongInt; P, U : String;
Begin
  MapPath := '';
  { .. et caracteres interdits }
  If (Pos('..', Url) > 0) Or (Pos('\', Url) > 0) Or (Pos(':', Url) > 0) Or (Pos(#0, Url) > 0) Then Exit;
  U := UpStr(Url);
  Best := -1; L := 0;
  For K := 0 To Sites[I].NV - 1 Do
    If (Copy(U, 1, Length(Sites[I].VUrl[K])) = UpStr(Sites[I].VUrl[K])) And (Length(Sites[I].VUrl[K]) > L) And
       ((Length(U) = Length(Sites[I].VUrl[K])) Or (U[Length(Sites[I].VUrl[K]) + 1] = '/')) Then
    Begin
      Best := K; L := Length(Sites[I].VUrl[K]);
    End;
  If Best >= 0 Then P := Sites[I].VPath[Best] + Copy(Url, L + 1, 255)
  Else P := Sites[I].Root + Url;
  For K := 1 To Length(P) Do If P[K] = '/' Then P[K] := '\';
  While (Length(P) > 3) And (P[Length(P)] = '\') Do Delete(P, Length(P), 1);
  MapPath := P;
End;

Function ExtOf(P : String) : String;
Var K : LongInt;
Begin
  ExtOf := '';
  For K := Length(P) DownTo 1 Do
  Begin
    If P[K] = '.' Then
    Begin
      ExtOf := UpStr(Copy(P, K, 10));
      Exit;
    End;
    If P[K] = '\' Then Exit;
  End;
End;

Var
  ScriptPath : Array[0..MaxConn - 1] Of String[127];
  ScriptAsp : Array[0..MaxConn - 1] Of Boolean;
  ScriptPhp : Array[0..MaxConn - 1] Of Boolean;

{ requete complete (en-tetes et corps) : y repondre }
Procedure Dispatch(C : LongInt);
Var I, K, Sz, Mt : LongInt; Path, Url, S, E : String; Dr : Boolean;
Begin
  With Conns[C] Do
  Begin
    Inc(TotReq);
    I := FindSite(LocalIp, LocalPort, IsTls, Host);
    Site := I;
    If I < 0 Then
    Begin
      SendError(C, 400, 'Nom d''h'#147'te inconnu : ' + HtmlEnc(Host));
      Exit;
    End;
    Inc(Sites[I].Requests);
    If (Method <> 'GET') And (Method <> 'HEAD') And (Method <> 'POST') And (Method <> 'OPTIONS') Then
    Begin
      SendError(C, 501, HtmlEnc(Method));
      Exit;
    End;
    If Method = 'OPTIONS' Then
    Begin
      PutHead(C, 200, '', 0, 'Allow: OPTIONS, GET, HEAD, POST' + Crlf);
      State := csSend;
      Exit;
    End;
    { authentification de base }
    If Sites[I].AuthUser <> '' Then
    Begin
      S := HdrGet(C, 'Authorization');
      If (UpStr(Copy(S, 1, 6)) <> 'BASIC ') Or
         (B64DecStr(Trim(Copy(S, 7, 255))) <> Sites[I].AuthUser + ':' + Sites[I].AuthPass) Then
      Begin
        SendError(C, 401, '');
        Exit;
      End;
    End;
    Url := UrlDecode(Uri, False);
    If (Url = '') Or (Url[1] <> '/') Then
    Begin
      SendError(C, 400, '');
      Exit;
    End;
    Path := MapPath(I, Url);
    If Path = '' Then
    Begin
      SendError(C, 403, '');
      Exit;
    End;
    If Not PStat(Path, Sz, Mt, Dr) Then
    Begin
      SendError(C, 404, '');
      Exit;
    End;
    If Dr Then
    Begin
      If Url[Length(Url)] <> '/' Then
      Begin
        S := Uri + '/';
        If Query <> '' Then S := S + '?' + Query;
        SendRedirect(C, S, 301);
        Exit;
      End;
      For K := 0 To Sites[I].ND - 1 Do
        If PStat(Path + '\' + Sites[I].Docs[K], Sz, Mt, Dr) And Not Dr Then
        Begin
          Path := Path + '\' + Sites[I].Docs[K];
          Url := Url + Sites[I].Docs[K];
          Break;
        End;
      If Dr Or Not PStat(Path, Sz, Mt, Dr) Or Dr Then
      Begin
        If Sites[I].Browse Then SendListing(C, Path, Url)
        Else SendError(C, 403, 'L''exploration de ce r'#130'pertoire n''est pas permise.');
        Exit;
      End;
    End;
    E := ExtOf(Path);
    If ((E = '.PSP') And Sites[I].Psp) Or ((E = '.ASP') And Sites[I].Asp) Or ((E = '.PHP') And Sites[I].Php) Then
    Begin
      ScriptPath[C] := Path;
      ScriptAsp[C] := E = '.ASP';
      ScriptPhp[C] := E = '.PHP';
      VmEnqueue(C);
      Exit;
    End;
    If Method = 'POST' Then
    Begin
      SendError(C, 405, '');
      Exit;
    End;
    SendFile(C, Path, Sz, Mt);
  End;
End;

{ requete suivante (connexion persistante) : les octets deja recus apres
  la requete precedente sont gardes }
Procedure NextRequest(C : LongInt);
Var Used : LongInt;
Begin
  With Conns[C] Do
  Begin
    Used := HdrEnd;
    If (BodyLen > 0) And (Body = Nil) Then Used := Used + BodyLen;
    ConnFreeBody(C);
    If (Used > 0) And (Used < ReqLen) Then Move(Req^[Used], Req^[0], ReqLen - Used)
    Else If Used >= ReqLen Then Used := ReqLen;
    ReqLen := ReqLen - Used;
    HdrEnd := 0; BodyLen := 0;
    State := csRead;
    Inc(NReq);
    T0 := PTicks; TLast := T0;
    SentBytes := 0; Status := 0;
  End;
End;

{ analyser les en-tetes recus ; rend Faux si la requete n'est pas encore
  complete }
Procedure ParseRequest(C : LongInt);
Var K, E, P : LongInt; L, S, Cn : String;
Begin
  With Conns[C] Do
  Begin
    { fin des en-tetes }
    If HdrEnd = 0 Then
    Begin
      E := -1;
      For K := 0 To ReqLen - 4 Do
        If (Req^[K] = 13) And (Req^[K + 1] = 10) And (Req^[K + 2] = 13) And (Req^[K + 3] = 10) Then
        Begin
          E := K + 4;
          Break;
        End;
      If E < 0 Then
      Begin
        If ReqLen >= ReqCap Then
        Begin
          HdrEnd := ReqLen;
          KeepAlive := False;
          Method := 'GET'; Uri := '/'; Query := '';
          SendError(C, 431, '');
        End;
        Exit;
      End;
      HdrEnd := E;
      { ligne de requete }
      L := '';
      K := 0;
      While (K < HdrEnd) And (Req^[K] <> 13) Do
      Begin
        If Length(L) < 255 Then L := L + Chr(Req^[K]);
        Inc(K);
      End;
      P := Pos(' ', L);
      Method := UpStr(Copy(L, 1, P - 1));
      L := Copy(L, P + 1, 255);
      P := Pos(' ', L);
      If P = 0 Then
      Begin
        Uri := L; Ver := 'HTTP/0.9';
      End
      Else
      Begin
        Uri := Copy(L, 1, P - 1); Ver := UpStr(Trim(Copy(L, P + 1, 20)));
      End;
      Query := '';
      P := Pos('?', Uri);
      If P > 0 Then
      Begin
        Query := Copy(Uri, P + 1, 255);
        Uri := Copy(Uri, 1, P - 1);
      End;
      { une adresse absolue (http://hote/chemin) est acceptee }
      If LoStr(Copy(Uri, 1, 7)) = 'http://' Then
      Begin
        Uri := Copy(Uri, 8, 255);
        P := Pos('/', Uri);
        If P = 0 Then Uri := '/' Else Uri := Copy(Uri, P, 255);
      End;
      Head := Method = 'HEAD';
      Host := HdrGet(C, 'Host');
      Cn := LoStr(HdrGet(C, 'Connection'));
      If Ver = 'HTTP/1.1' Then KeepAlive := Pos('close', Cn) = 0
      Else KeepAlive := Pos('keep-alive', Cn) > 0;
      If NReq >= 100 Then KeepAlive := False;
      BodyLen := SVal(HdrGet(C, 'Content-Length'));
      If BodyLen < 0 Then BodyLen := 0;
      If (Method = '') Or (Copy(Ver, 1, 5) <> 'HTTP/') Then
      Begin
        KeepAlive := False;
        SendError(C, 400, '');
        Exit;
      End;
      If (Ver = 'HTTP/1.1') And (Host = '') Then
      Begin
        SendError(C, 400, 'En-t'#136'te Host absent.');
        Exit;
      End;
      If LoStr(HdrGet(C, 'Transfer-Encoding')) <> '' Then
      Begin
        KeepAlive := False;
        SendError(C, 501, 'Transfer-Encoding');
        Exit;
      End;
      If BodyLen > MaxBody Then
      Begin
        SendError(C, 413, '');
        Exit;
      End;
      If HdrEnd + BodyLen > ReqCap Then
      Begin
        { gros corps : dans un tampon a part }
        GetMem(Body, BodyLen + 1);
        BodyCap := BodyLen + 1;
        BodyGot := ReqLen - HdrEnd;
        If BodyGot > BodyLen Then BodyGot := BodyLen;
        If BodyGot > 0 Then Move(Req^[HdrEnd], Body^[0], BodyGot);
        ReqLen := HdrEnd;
        State := csBody;
      End;
    End;
    If State = csBody Then
    Begin
      If BodyGot < BodyLen Then Exit;
    End
    Else If ReqLen < HdrEnd + BodyLen Then Exit;
    State := csSend;
    Dispatch(C);
  End;
End;

{ ==================================================================== }
{ Pages actives (PSP, ASP) : machine a pile commune aux deux langages    }
{ Une page est compilee une fois en code intermediaire (tableau de       }
{ LongInt), puis executee par tranches (VmStep) entre les autres         }
{ connexions. Valeurs : cellules typees (entier, reel, booleen, chaine,  }
{ caractere, adresse, objet, ensemble). Memoire : cellules (variables    }
{ globales, cadres des procedures, tas de New) ; chaines dans une zone   }
{ d'octets propre a la requete.                                          }
{ ==================================================================== }

Const
  { types des cellules }
  vtNil = 0; vtInt = 1; vtReal = 2; vtBool = 3; vtStr = 4; vtKStr = 5; vtChar = 6; vtAddr = 7; vtObj = 8;
  vtSet = 9; vtDate = 10;
  { codes (operandes entre crochets) }
  opNop = 0; opPushI = 1; opPushR = 2; opPushS = 3; opPushC = 4; opPushB = 5; opPushNil = 6;
  opLdG = 7; opStG = 8; opLdL = 9; opStL = 10; opLdGA = 11; opLdLA = 12; opLdUp = 13; opStUp = 14;
  opLdUpA = 15; opLdInd = 16; opStInd = 17; opCopy = 18; opIdx = 19; opFld = 20; opConv = 21;
  opAdd = 22; opSub = 23; opMul = 24; opDivR = 25; opIDiv = 26; opMod = 27; opNeg = 28; opNot = 29;
  opAnd = 30; opOr = 31; opXor = 32; opShl = 33; opShr = 34;
  opEq = 35; opNe = 36; opLt = 37; opLe = 38; opGt = 39; opGe = 40;
  opJmp = 41; opJz = 42; opJnz = 43; opCall = 44; opEnter = 45; opRet = 46; opCallB = 47;
  opWrite = 48; opWriteLn = 49; opPop = 50; opDup = 51; opHalt = 52; opHtml = 53;
  opMember = 54; opSetMember = 55; opInitS = 56; opStrIdx = 57; opStrSet = 58; opSwap = 59;
  opIncV = 60; opSetBit = 61; opInSet = 62; opDup2 = 63; opCatV = 64; opWriteV = 65; opConcat = 66;
  opNewArr = 67; opArrIdx = 68; opForChk = 69; opLdArrR = 70; opEach = 71; opErrClr = 72; opIsObj = 73;
  { conversions (opConv) }
  cvInt = 1; cvReal = 2; cvBool = 3; cvStr = 4; cvChar = 6; cvVar = 0;
  { objets predefinis }
  obRequest = 1; obResponse = 2; obServer = 3; obSession = 4; obApplication = 5; obErr = 6;
  okRequest = 1; okResponse = 2; okServer = 3; okSession = 4; okApp = 5; okErr = 6;
  okColl = 10; okItem = 11; okDict = 12; okFso = 13; okStream = 14; okCookieW = 15; okArr = 16;
  obDatabase = 7; okDbF = 7; okDbConn = 17; okDbRs = 18; okDbFlds = 19; okDbFld = 20;
  okPArr = 21; okDbStmt = 22;      { PHP : tableau, requete preparee de PDO }
  { PHP : opPhp sous-operation }
  opPhp = 74;
  psBool = 1; psNum = 2; psStr = 3; psGet = 4; psSet = 5; psPush = 6; psArrW = 7; psSubW = 8; psSubPushW = 9;
  psNewArr = 10; psAddK = 11; psAddV = 12; psDup2 = 13; psIdent = 14; psNIdent = 15; psSuper = 16; psCopy = 17;
  psIsset = 18; psUnset = 19; psEachNext = 20; psEachKey = 21; psEachVal = 22; psIncE = 23; psCast = 24; psCmp = 25;
  psNotNull = 26; psThrow = 27; psExitMsg = 28; psDrop2 = 29; psSpread = 30; psAdd = 31; psBitAnd = 32;
  psBitOr = 33; psBitXor = 34;
  { collections de Request }
  rcQuery = 1; rcForm = 2; rcCookies = 3; rcServerVars = 4; rcAll = 5;
  { membres }
  mDefault = 0; mQueryString = 1; mForm = 2; mCookies = 3; mServerVariables = 4; mTotalBytes = 5;
  mBinaryRead = 6; mWrite = 7; mRedirect = 8; mAddHeader = 9; mContentType = 10; mBuffer = 11; mStatus = 12;
  mEnd = 13; mClear = 14; mFlush = 15; mAppendToLog = 16; mExpires = 17; mCacheControl = 18; mCharset = 19;
  mMapPath = 20; mURLEncode = 21; mHTMLEncode = 22; mScriptTimeout = 23; mCreateObject = 24; mSessionID = 25;
  mTimeout = 26; mAbandon = 27; mLock = 28; mUnlock = 29; mContents = 30; mCount = 31; mItem = 32;
  mHasKeys = 33; mKey = 34; mAdd = 35; mExists = 36; mRemove = 37; mRemoveAll = 38; mKeys = 39; mItems = 40;
  mFileExists = 41; mFolderExists = 42; mOpenTextFile = 43; mCreateTextFile = 44; mReadLine = 45;
  mReadAll = 46; mAtEndOfStream = 47; mWriteLine = 48; mClose = 49; mDeleteFile = 50; mIsClientConnected = 51;
  mExpiresAbsolute = 52; mNumber = 53; mDescription = 54; mRaise = 55; mSource = 56; mGetFileName = 57;
  mPath = 58; mDomain = 59; mExpiresC = 60; mLCID = 61; mCodePage = 62; mBuildPath = 63;
  { bases de donnees }
  mConnect = 64; mQuery = 65; mExecute = 66; mEof = 67; mNext = 68; mFields = 69; mFieldCount = 70;
  mRecordCount = 71; mMoveFirst = 72; mMoveNext = 73; mOpen = 74; mBof = 75; mName = 76; mValue = 77;
  mRowsAffected = 78; mQuote = 79; mConnected = 80; mFieldName = 81; mState = 82;
  { PHP : mysqli, pg_*, PDO }
  mFetchAssoc = 83; mFetchRow = 84; mFetchArray = 85; mFetchAllM = 86; mFetch = 87; mFetchAllP = 88;
  mFetchColumn = 89; mRowCount = 90; mNumRows = 91; mAffectedRows = 92; mPrepare = 93; mExec = 94;
  mRealEscape = 95; mFree = 96; mInsertId = 97; mLastInsertId = 98; mFieldCountP = 99; mDataSeek = 100;
  mFetchResult = 101; mCloseCursor = 102; mBindValue = 103; mBindParam = 104; mSetCharset = 105;
  mSetAttribute = 106; mGetMessage = 107; mConnectError = 108; mError = 109; mErrno = 110; mFieldNameP = 111;
  mBeginTrans = 112; mCommit = 113; mRollBack = 114; mFetchObject = 115;
  mQueryParams = 116; mGetResult = 117; mBindParamM = 118;
  NMembers = 118;
  MemberNames : Array[0..NMembers] Of String[18] = ('', 'QUERYSTRING', 'FORM', 'COOKIES', 'SERVERVARIABLES',
    'TOTALBYTES', 'BINARYREAD', 'WRITE', 'REDIRECT', 'ADDHEADER', 'CONTENTTYPE', 'BUFFER', 'STATUS', 'END',
    'CLEAR', 'FLUSH', 'APPENDTOLOG', 'EXPIRES', 'CACHECONTROL', 'CHARSET', 'MAPPATH', 'URLENCODE', 'HTMLENCODE',
    'SCRIPTTIMEOUT', 'CREATEOBJECT', 'SESSIONID', 'TIMEOUT', 'ABANDON', 'LOCK', 'UNLOCK', 'CONTENTS', 'COUNT',
    'ITEM', 'HASKEYS', 'KEY', 'ADD', 'EXISTS', 'REMOVE', 'REMOVEALL', 'KEYS', 'ITEMS', 'FILEEXISTS',
    'FOLDEREXISTS', 'OPENTEXTFILE', 'CREATETEXTFILE', 'READLINE', 'READALL', 'ATENDOFSTREAM', 'WRITELINE',
    'CLOSE', 'DELETEFILE', 'ISCLIENTCONNECTED', 'EXPIRESABSOLUTE', 'NUMBER', 'DESCRIPTION', 'RAISE', 'SOURCE',
    'GETFILENAME', 'PATH', 'DOMAIN', 'EXPIRES', 'LCID', 'CODEPAGE', 'BUILDPATH',
    'CONNECT', 'QUERY', 'EXECUTE', 'EOF', 'NEXT', 'FIELDS', 'FIELDCOUNT', 'RECORDCOUNT', 'MOVEFIRST',
    'MOVENEXT', 'OPEN', 'BOF', 'NAME', 'VALUE', 'ROWSAFFECTED', 'QUOTE', 'CONNECTED', 'FIELDNAME', 'STATE',
    'FETCH_ASSOC', 'FETCH_ROW', 'FETCH_ARRAY', 'FETCH_ALL', 'FETCH', 'FETCHALL', 'FETCHCOLUMN', 'ROWCOUNT',
    'NUM_ROWS', 'AFFECTED_ROWS', 'PREPARE', 'EXEC', 'REAL_ESCAPE_STRING', 'FREE', 'INSERT_ID', 'LASTINSERTID',
    'FIELD_COUNT', 'DATA_SEEK', 'FETCH_RESULT', 'CLOSECURSOR', 'BINDVALUE', 'BINDPARAM', 'SET_CHARSET',
    'SETATTRIBUTE', 'GETMESSAGE', 'CONNECT_ERROR', 'ERROR', 'ERRNO', 'FIELD_NAME', 'BEGINTRANSACTION', 'COMMIT',
    'ROLLBACK', 'FETCH_OBJECT', 'QUERY_PARAMS', 'GET_RESULT', 'BIND_PARAM');

  MemCells = 262144;          { cellules de la machine (4 Mo) }
  StkCells = 4096;            { pile d'evaluation }
  MaxObj = 4096;
  MaxDictE = 32768;           { entrees des dictionnaires (et tableaux PHP) d'une requete }
  MaxPage = 16;               { pages compilees gardees }
  MaxSess = 64;               { sessions }
  MaxSVar = 32;               { variables d'une session }
  MaxAVar = 64;               { variables de l'application }
  MaxPair = 128;              { paires d'une collection (QueryString...) }

{ fonctions de PHP (opCallB, 300 et plus) : tableau PhpFnNames }
Const
  pfStrlen = 300; pfStrtoupper = 301; pfStrtolower = 302; pfUcfirst = 303; pfLcfirst = 304; pfUcwords = 305;
  pfTrim = 306; pfLtrim = 307; pfRtrim = 308; pfChop = 309; pfSubstr = 310; pfStrpos = 311; pfStripos = 312;
  pfStrrpos = 313; pfStrripos = 314; pfStrReplace = 315; pfStrIreplace = 316; pfStrRepeat = 317; pfStrPad = 318;
  pfStrSplit = 319; pfStrrev = 320; pfStrcmp = 321; pfStrcasecmp = 322; pfStrncmp = 323; pfStrncasecmp = 324;
  pfStrnatcmp = 325; pfStrstr = 326; pfStristr = 327; pfStrrchr = 328; pfSubstrCount = 329; pfSubstrReplace = 330;
  pfNl2br = 331; pfHtmlspecialchars = 332; pfHtmlentities = 333; pfHtmlEntityDecode = 334;
  pfHtmlspecialcharsDecode = 335; pfStripTags = 336; pfAddslashes = 337; pfStripslashes = 338; pfUrlencode = 339;
  pfRawurlencode = 340; pfUrldecode = 341; pfRawurldecode = 342; pfBase64Encode = 343; pfBase64Decode = 344;
  pfMd5 = 345; pfSha1 = 346; pfCrc32 = 347; pfNumberFormat = 348; pfSprintf = 349; pfPrintf = 350;
  pfVsprintf = 351; pfWordwrap = 352; pfImplode = 353; pfJoin = 354; pfExplode = 355; pfChr = 356; pfOrd = 357;
  pfDechex = 358; pfHexdec = 359; pfDecbin = 360; pfBindec = 361; pfDecoct = 362; pfOctdec = 363; pfBin2hex = 364;
  pfStrContains = 365; pfStrStartsWith = 366; pfStrEndsWith = 367; pfMbStrlen = 368; pfMbSubstr = 369;
  pfMbStrtoupper = 370; pfMbStrtolower = 371; pfStrWordCount = 372; pfUniqid = 373; pfLcgValue = 374;
  pfJsonEncode = 375; pfJsonDecode = 376; pfQuotemeta = 377; pfAbs = 378; pfCeil = 379; pfFloor = 380;
  pfRound = 381; pfSqrt = 382; pfPow = 383; pfIntdiv = 384; pfMax = 385; pfMin = 386; pfRand = 387; pfMtRand = 388;
  pfRandomInt = 389; pfMtSrand = 390; pfSrand = 391; pfMtGetrandmax = 392; pfGetrandmax = 393; pfPi = 394;
  pfFmod = 395; pfExp = 396; pfLog = 397; pfLog10 = 398; pfLog2 = 399; pfSin = 400; pfCos = 401; pfTan = 402;
  pfAsin = 403; pfAcos = 404; pfAtan = 405; pfAtan2 = 406; pfIsNan = 407; pfIsFinite = 408; pfIsInfinite = 409;
  pfDeg2rad = 410; pfRad2deg = 411; pfHypot = 412; pfBaseConvert = 413; pfIntval = 414; pfFloatval = 415;
  pfDoubleval = 416; pfStrval = 417; pfBoolval = 418; pfGettype = 419; pfGetDebugType = 420; pfIsInt = 421;
  pfIsInteger = 422; pfIsLong = 423; pfIsFloat = 424; pfIsDouble = 425; pfIsString = 426; pfIsBool = 427;
  pfIsArray = 428; pfIsNumeric = 429; pfIsNull = 430; pfIsScalar = 431; pfIsObject = 432; pfIsIterable = 433;
  pfIsCountable = 434; pfVarDump = 435; pfPrintR = 436; pfVarExport = 437; pfCount = 438; pfSizeof = 439;
  pfArrayKeys = 440; pfArrayValues = 441; pfInArray = 442; pfArraySearch = 443; pfArrayKeyExists = 444;
  pfKeyExists = 445; pfArrayMerge = 446; pfArrayPush = 447; pfArrayPop = 448; pfArrayShift = 449;
  pfArrayUnshift = 450; pfArraySlice = 451; pfArraySplice = 452; pfArrayReverse = 453; pfArraySum = 454;
  pfArrayProduct = 455; pfSort = 456; pfRsort = 457; pfAsort = 458; pfArsort = 459; pfKsort = 460; pfKrsort = 461;
  pfArrayUnique = 462; pfArrayFlip = 463; pfArrayFill = 464; pfArrayFillKeys = 465; pfRange = 466;
  pfArrayCombine = 467; pfArrayColumn = 468; pfArrayRand = 469; pfShuffle = 470; pfArrayCountValues = 471;
  pfArrayKeyFirst = 472; pfArrayKeyLast = 473; pfArrayFilter = 474; pfArrayPad = 475; pfArrayChunk = 476;
  pfArrayDiff = 477; pfArrayDiffKey = 478; pfArrayIntersect = 479; pfArrayIntersectKey = 480; pfArrayIsList = 481;
  pfReset = 482; pfEnd = 483; pfCurrent = 484; pfKey = 485; pfNext = 486; pfPrev = 487; pfArrayReplace = 488;
  pfDate = 489; pfGmdate = 490; pfTime = 491; pfMktime = 492; pfGmmktime = 493; pfStrtotime = 494;
  pfCheckdate = 495; pfDateDefaultTimezoneSet = 496; pfDateDefaultTimezoneGet = 497; pfMicrotime = 498;
  pfHrtime = 499; pfIdate = 500; pfHeader = 501; pfHeadersSent = 502; pfHttpResponseCode = 503; pfSetcookie = 504;
  pfSessionStart = 505; pfSessionDestroy = 506; pfSessionId = 507; pfSessionUnset = 508; pfSessionStatus = 509;
  pfSessionRegenerateId = 510; pfDefined = 511; pfConstant = 512; pfPhpversion = 513; pfPhpUname = 514;
  pfPhpSapiName = 515; pfErrorReporting = 516; pfIniSet = 517; pfIniGet = 518; pfSetTimeLimit = 519;
  pfObStart = 520; pfObGetClean = 521; pfObGetContents = 522; pfObEndClean = 523; pfObEndFlush = 524;
  pfObGetLevel = 525; pfUsleep = 526; pfSleep = 527; pfFlush = 528; pfGetenv = 529; pfGethostname = 530;
  pfErrorLog = 531; pfTriggerError = 532; pfMail = 533; pfMemoryGetUsage = 534; pfMemoryGetPeakUsage = 535;
  pfGcCollectCycles = 536; pfFileExists = 537; pfFileGetContents = 538; pfFilePutContents = 539; pfFile = 540;
  pfIsFile = 541; pfIsDir = 542; pfIsReadable = 543; pfIsWritable = 544; pfBasename = 545; pfDirname = 546;
  pfPathinfo = 547; pfFilesize = 548; pfFilemtime = 549; pfUnlink = 550; pfMkdir = 551; pfRmdir = 552;
  pfScandir = 553; pfGlob = 554; pfRealpath = 555; pfFopen = 556; pfFgets = 557; pfFgetc = 558; pfFwrite = 559;
  pfFputs = 560; pfFclose = 561; pfFeof = 562; pfFileExt = 563; pfMysqliConnect = 564; pfPgConnect = 565;
  pfMysqliError = 566; pfMysqliErrno = 567; pfMysqliConnectError = 568; pfMysqliConnectErrno = 569;
  pfMysqliSetCharset = 570; pfMysqliSelectDb = 571; pfPgLastError = 572; pfPgEscapeString = 573;
  pfPgEscapeLiteral = 574; pfPgConnectionStatus = 575; pfPdoConnstr = 576; pfMysqliConnstr = 577;
  NPhpFn = 278;
  PhpFnNames : Array[0..NPhpFn - 1] Of String[24] = (
    'STRLEN', 'STRTOUPPER', 'STRTOLOWER', 'UCFIRST', 'LCFIRST', 'UCWORDS', 'TRIM', 'LTRIM', 'RTRIM', 'CHOP',
    'SUBSTR', 'STRPOS', 'STRIPOS', 'STRRPOS', 'STRRIPOS', 'STR_REPLACE', 'STR_IREPLACE', 'STR_REPEAT', 'STR_PAD',
    'STR_SPLIT', 'STRREV', 'STRCMP', 'STRCASECMP', 'STRNCMP', 'STRNCASECMP', 'STRNATCMP', 'STRSTR', 'STRISTR',
    'STRRCHR', 'SUBSTR_COUNT', 'SUBSTR_REPLACE', 'NL2BR', 'HTMLSPECIALCHARS', 'HTMLENTITIES', 'HTML_ENTITY_DECODE',
    'HTMLSPECIALCHARS_DECODE', 'STRIP_TAGS', 'ADDSLASHES', 'STRIPSLASHES', 'URLENCODE', 'RAWURLENCODE',
    'URLDECODE', 'RAWURLDECODE', 'BASE64_ENCODE', 'BASE64_DECODE', 'MD5', 'SHA1', 'CRC32', 'NUMBER_FORMAT',
    'SPRINTF', 'PRINTF', 'VSPRINTF', 'WORDWRAP', 'IMPLODE', 'JOIN', 'EXPLODE', 'CHR', 'ORD', 'DECHEX', 'HEXDEC',
    'DECBIN', 'BINDEC', 'DECOCT', 'OCTDEC', 'BIN2HEX', 'STR_CONTAINS', 'STR_STARTS_WITH', 'STR_ENDS_WITH',
    'MB_STRLEN', 'MB_SUBSTR', 'MB_STRTOUPPER', 'MB_STRTOLOWER', 'STR_WORD_COUNT', 'UNIQID', 'LCG_VALUE',
    'JSON_ENCODE', 'JSON_DECODE', 'QUOTEMETA', 'ABS', 'CEIL', 'FLOOR', 'ROUND', 'SQRT', 'POW', 'INTDIV', 'MAX',
    'MIN', 'RAND', 'MT_RAND', 'RANDOM_INT', 'MT_SRAND', 'SRAND', 'MT_GETRANDMAX', 'GETRANDMAX', 'PI', 'FMOD',
    'EXP', 'LOG', 'LOG10', 'LOG2', 'SIN', 'COS', 'TAN', 'ASIN', 'ACOS', 'ATAN', 'ATAN2', 'IS_NAN', 'IS_FINITE',
    'IS_INFINITE', 'DEG2RAD', 'RAD2DEG', 'HYPOT', 'BASE_CONVERT', 'INTVAL', 'FLOATVAL', 'DOUBLEVAL', 'STRVAL',
    'BOOLVAL', 'GETTYPE', 'GET_DEBUG_TYPE', 'IS_INT', 'IS_INTEGER', 'IS_LONG', 'IS_FLOAT', 'IS_DOUBLE',
    'IS_STRING', 'IS_BOOL', 'IS_ARRAY', 'IS_NUMERIC', 'IS_NULL', 'IS_SCALAR', 'IS_OBJECT', 'IS_ITERABLE',
    'IS_COUNTABLE', 'VAR_DUMP', 'PRINT_R', 'VAR_EXPORT', 'COUNT', 'SIZEOF', 'ARRAY_KEYS', 'ARRAY_VALUES',
    'IN_ARRAY', 'ARRAY_SEARCH', 'ARRAY_KEY_EXISTS', 'KEY_EXISTS', 'ARRAY_MERGE', 'ARRAY_PUSH', 'ARRAY_POP',
    'ARRAY_SHIFT', 'ARRAY_UNSHIFT', 'ARRAY_SLICE', 'ARRAY_SPLICE', 'ARRAY_REVERSE', 'ARRAY_SUM', 'ARRAY_PRODUCT',
    'SORT', 'RSORT', 'ASORT', 'ARSORT', 'KSORT', 'KRSORT', 'ARRAY_UNIQUE', 'ARRAY_FLIP', 'ARRAY_FILL',
    'ARRAY_FILL_KEYS', 'RANGE', 'ARRAY_COMBINE', 'ARRAY_COLUMN', 'ARRAY_RAND', 'SHUFFLE', 'ARRAY_COUNT_VALUES',
    'ARRAY_KEY_FIRST', 'ARRAY_KEY_LAST', 'ARRAY_FILTER', 'ARRAY_PAD', 'ARRAY_CHUNK', 'ARRAY_DIFF',
    'ARRAY_DIFF_KEY', 'ARRAY_INTERSECT', 'ARRAY_INTERSECT_KEY', 'ARRAY_IS_LIST', 'RESET', 'END', 'CURRENT', 'KEY',
    'NEXT', 'PREV', 'ARRAY_REPLACE', 'DATE', 'GMDATE', 'TIME', 'MKTIME', 'GMMKTIME', 'STRTOTIME', 'CHECKDATE',
    'DATE_DEFAULT_TIMEZONE_SET', 'DATE_DEFAULT_TIMEZONE_GET', 'MICROTIME', 'HRTIME', 'IDATE', 'HEADER',
    'HEADERS_SENT', 'HTTP_RESPONSE_CODE', 'SETCOOKIE', 'SESSION_START', 'SESSION_DESTROY', 'SESSION_ID',
    'SESSION_UNSET', 'SESSION_STATUS', 'SESSION_REGENERATE_ID', 'DEFINED', 'CONSTANT', 'PHPVERSION', 'PHP_UNAME',
    'PHP_SAPI_NAME', 'ERROR_REPORTING', 'INI_SET', 'INI_GET', 'SET_TIME_LIMIT', 'OB_START', 'OB_GET_CLEAN',
    'OB_GET_CONTENTS', 'OB_END_CLEAN', 'OB_END_FLUSH', 'OB_GET_LEVEL', 'USLEEP', 'SLEEP', 'FLUSH', 'GETENV',
    'GETHOSTNAME', 'ERROR_LOG', 'TRIGGER_ERROR', 'MAIL', 'MEMORY_GET_USAGE', 'MEMORY_GET_PEAK_USAGE',
    'GC_COLLECT_CYCLES', 'FILE_EXISTS', 'FILE_GET_CONTENTS', 'FILE_PUT_CONTENTS', 'FILE', 'IS_FILE', 'IS_DIR',
    'IS_READABLE', 'IS_WRITABLE', 'BASENAME', 'DIRNAME', 'PATHINFO', 'FILESIZE', 'FILEMTIME', 'UNLINK', 'MKDIR',
    'RMDIR', 'SCANDIR', 'GLOB', 'REALPATH', 'FOPEN', 'FGETS', 'FGETC', 'FWRITE', 'FPUTS', 'FCLOSE', 'FEOF',
    'FILE_EXT', 'MYSQLI_CONNECT', 'PG_CONNECT', 'MYSQLI_ERROR', 'MYSQLI_ERRNO', 'MYSQLI_CONNECT_ERROR',
    'MYSQLI_CONNECT_ERRNO', 'MYSQLI_SET_CHARSET', 'MYSQLI_SELECT_DB', 'PG_LAST_ERROR', 'PG_ESCAPE_STRING',
    'PG_ESCAPE_LITERAL', 'PG_CONNECTION_STATUS', 'PDO_CONNSTR', 'MYSQLI_CONNSTR');

Type
  TCell = Record
    T : Byte;
    Case Byte Of
      0 : (I, L : LongInt);
      1 : (R : Double);
  End;
  TCells = Array[0..$3FFFFFF] Of TCell;
  PCells = ^TCells;
  TDoubles = Array[0..$FFFFFFF] Of Double;
  PDoubles = ^TDoubles;

  { page compilee }
  TProg = Record
    Used : Boolean;
    Path : String[127];
    MTime, Size : LongInt;
    Asp, Php : Boolean;
    Code : PLongs;
    NCode, CodeCap : LongInt;
    Reals : PDoubles;
    NReal, RealCap : LongInt;
    Strs : TBuf;               { chaines constantes (et fragments HTML) }
    Lines : PLongs;            { (adresse du code, ligne) }
    NLine, LineCap : LongInt;
    NGlob : LongInt;           { cellules globales }
    Hits, LastUse : LongInt;
  End;

  { variable persistante (Session, Application) }
  TPVar = Record
    Name : String[31];
    T : Byte;
    I, L : LongInt;
    R : Double;
    P : PBytes;                { chaine (L octets) }
  End;
  TSess = Record
    Used : Boolean;
    Id : String[31];
    Last : LongInt;            { derniere requete (secondes) }
    Timeout : LongInt;         { minutes }
    N : LongInt;
    V : Array[0..MaxSVar - 1] Of TPVar;
  End;

Var
  Pages : Array[0..MaxPage - 1] Of TProg;
  Sess : Array[0..MaxSess - 1] Of TSess;
  AppVars : Array[0..MaxAVar - 1] Of TPVar;
  NAppVar : LongInt;
  { machine }
  Mem : PCells;
  Stk : Array[0..StkCells - 1] Of TCell;
  SP, FP, FsTop, HeapTop, PC, Lvl : LongInt;
  Prog : LongInt;              { page en cours (Pages) }
  VmConn : LongInt;            { connexion servie (-1 : aucune) }
  VmOn : Boolean;
  VmErr : String;              { erreur d'execution }
  VmErrLine : LongInt;
  VmT0 : LongInt;
  VmPool : TBuf;               { chaines de la requete }
  VmOut : TBuf;                { reponse }
  VmHdr : TBuf;                { en-tetes ajoutes }
  VmStatus : String[63];
  VmCType : String[79];
  VmCharset : String[31];
  VmHdrPending, VmEnded, VmBuffer : Boolean;
  VmSess : LongInt;            { session (-1 : aucune) }
  VmNewSess : Boolean;
  VmScriptTo : LongInt;
  VmBinPos : LongInt;          { Request.BinaryRead }
  VmAspErrNum : LongInt;       { Err.Number (ASP) }
  VmAspErrDesc : String;
  VmOnErrResume : Boolean;
  VmStmtSP, VmStmtFP : LongInt;
  { objets de la requete }
  ObjK, ObjA, ObjB, ObjH : Array[0..MaxObj - 1] Of LongInt;
  ObjS : Array[0..MaxObj - 1] Of TCell;
  NObj : LongInt;
  { dictionnaires : entrees chainees par objet }
  DKey, DVal : PCells;       { MaxDictE cellules chacun, alloues au demarrage (hors image) }
  DObj : PLongs;
  NDict : LongInt;
  { collections de la requete (cle, valeur) }
  QsN, FmN, CkN : LongInt;
  QsK, QsV, FmK, FmV, CkK, CkV : Array[0..MaxPair - 1] Of TCell;
  QsDone, FmDone, CkDone : Boolean;

{ --- chaines de la requete --- }

Function PoolPtr(Var C : TCell) : PBytes;
Begin
  If C.T = vtKStr Then PoolPtr := @Pages[Prog].Strs.P^[C.I]
  Else If (C.T = vtStr) And (C.L > 0) Then PoolPtr := @VmPool.P^[C.I]
  Else PoolPtr := Nil;
End;

{ nouvelle chaine de N octets ; rend sa cellule (octets a remplir) }
Function PoolNew(N : LongInt; Var C : TCell) : Boolean;
Begin
  PoolNew := True;
  C.T := vtStr; C.I := VmPool.Len; C.L := N;
  If N <= 0 Then
  Begin
    C.L := 0;
    Exit;
  End;
  If VmPool.Len + N > 33554432 Then
  Begin
    VmErr := 'm'#130'moire des cha'#140'nes '#130'puis'#130'e (32 Mo)';
    C.L := 0;
    PoolNew := False;
    Exit;
  End;
  If Not BufGrow(VmPool, N) Then
  Begin
    VmErr := 'm'#130'moire insuffisante';
    C.L := 0;
    PoolNew := False;
    Exit;
  End;
  VmPool.Len := VmPool.Len + N;
End;

Procedure MkStr(Const S : String; Var C : TCell);
Begin
  If PoolNew(Length(S), C) And (Length(S) > 0) Then Move(S[1], VmPool.P^[C.I], Length(S));
End;

Procedure MkStrB(P : PBytes; N : LongInt; Var C : TCell);
Begin
  If PoolNew(N, C) And (N > 0) Then Move(P^[0], VmPool.P^[C.I], N);
End;

Procedure MkInt(V : LongInt; Var C : TCell);
Begin
  C.T := vtInt; C.I := V; C.L := 0;
End;

Procedure MkBool(V : Boolean; Var C : TCell);
Begin
  C.T := vtBool; C.I := Ord(V); C.L := 0;
End;

Procedure MkReal(V : Double; Var C : TCell);
Begin
  C.T := vtReal; C.R := V;
End;

Procedure MkNil(Var C : TCell);
Begin
  C.T := vtNil; C.I := 0; C.L := 0;
End;

{ longueur d'une valeur chaine (ou caractere) }
Function CellLen(Var C : TCell) : LongInt;
Begin
  If (C.T = vtStr) Or (C.T = vtKStr) Then CellLen := C.L
  Else If C.T = vtChar Then CellLen := 1
  Else CellLen := 0;
End;

{ chaine Pascal (tronquee a 255) d'une cellule chaine }
Function CellPStr(Var C : TCell) : String;
Var S : String; N : LongInt; P : PBytes;
Begin
  S := '';
  If C.T = vtChar Then S := Chr(C.I)
  Else If (C.T = vtStr) Or (C.T = vtKStr) Then
  Begin
    N := C.L;
    If N > 255 Then N := 255;
    P := PoolPtr(C);
    If (N > 0) And (P <> Nil) Then Move(P^[0], S[1], N);
    S[0] := Chr(N);
  End;
  CellPStr := S;
End;

{ --- formats --- }

Function RealStr(R : Double; W, D : LongInt) : String;
Var S : String;
Begin
  If D >= 0 Then
  Begin
    If W < 0 Then W := 0;
    Str(R:W:D, S);
  End
  Else
  Begin
    If W < 0 Then W := 17;
    Str(R:W, S);
  End;
  RealStr := S;
End;

{ reel en texte a la maniere de VBScript (15 chiffres significatifs, sans
  zeros inutiles) }
Function VbRealStr(R : Double) : String;
Var S : String; K, E : LongInt; Neg : Boolean;
Begin
  If (R = Int(R)) And (Abs(R) < 1E15) Then
  Begin
    Str(R:0:0, S);
    VbRealStr := S;
    Exit;
  End;
  Neg := R < 0;
  If Neg Then R := -R;
  If (R >= 1E-4) And (R < 1E15) Then
  Begin
    E := 0;
    While R * 10 < 1E15 Do
    Begin
      R := R * 10; Inc(E);
      If E > 18 Then Break;
    End;
    Str(R:0:0, S);
    While Length(S) <= E Do S := '0' + S;
    Insert('.', S, Length(S) - E + 1);
    While S[Length(S)] = '0' Do Delete(S, Length(S), 1);
    If S[Length(S)] = '.' Then Delete(S, Length(S), 1);
  End
  Else
  Begin
    Str(R:22, S);
    S := Trim(S);
  End;
  If Neg Then S := '-' + S;
  VbRealStr := S;
End;

{ 10 puissance E }
Function Pow10(E : LongInt) : Double;
Var R : Double; K : LongInt;
Begin
  R := 1;
  If E >= 0 Then For K := 1 To E Do R := R * 10
  Else For K := 1 To -E Do R := R / 10;
  Pow10 := R;
End;

{ reel en texte a la maniere de PHP (precision 14 : %.14G, 1.0E+25) }
Function PhpRealStr(R : Double) : String;
Var S, D : String; E, K : LongInt; Neg : Boolean; M : Double; Bt : Array[0..7] Of Byte;
Begin
  If R = 0 Then
  Begin
    Move(R, Bt, 8);
    If (Bt[7] And $80) <> 0 Then PhpRealStr := '-0' Else PhpRealStr := '0';
    Exit;
  End;
  If R <> R Then
  Begin
    PhpRealStr := 'NAN';
    Exit;
  End;
  Neg := R < 0;
  If Neg Then R := -R;
  If R > 1.7E308 Then
  Begin
    If Neg Then PhpRealStr := '-INF' Else PhpRealStr := 'INF';
    Exit;
  End;
  E := Trunc(Ln(R) / Ln(10));
  If R < 1 Then Dec(E);
  While (E > -330) And (Pow10(E) > R) Do Dec(E);
  While (E < 330) And (Pow10(E + 1) <= R) Do Inc(E);
  { 14 chiffres significatifs }
  M := R / Pow10(E) * 1E13;
  M := Int(M + 0.5);
  If M >= 1E14 Then
  Begin
    M := Int(M / 10 + 0.5);
    Inc(E);
  End;
  Str(M:0:0, D);
  While (Length(D) > 1) And (D[Length(D)] = '0') Do Delete(D, Length(D), 1);
  If (E < -4) Or (E >= 14) Then
  Begin
    S := D[1] + '.';
    If Length(D) > 1 Then S := S + Copy(D, 2, 20) Else S := S + '0';
    If E < 0 Then S := S + 'E-' + IStr(-E) Else S := S + 'E+' + IStr(E);
  End
  Else If E >= 0 Then
  Begin
    While Length(D) < E + 1 Do D := D + '0';
    S := Copy(D, 1, E + 1);
    If Length(D) > E + 1 Then S := S + '.' + Copy(D, E + 2, 20);
  End
  Else
  Begin
    S := '0.';
    For K := 1 To -E - 1 Do S := S + '0';
    S := S + D;
  End;
  If Neg Then S := '-' + S;
  PhpRealStr := S;
End;

{ --- dates (jours depuis le 30/12/1899, comme les dates d'OLE) --- }

{ secondes Unix -> date d'OLE (calcul en double precision) }
Function UnixToOle(T : LongInt) : Double;
Var X : Double;
Begin
  X := T;
  X := X / 86400.0;
  UnixToOle := X + 25569.0;
End;

Function DateNow : Double;
Begin
  DateNow := UnixToOle(NowUnix);
End;

Procedure DateSplit(D : Double; Var Y, Mo, Dd, H, Mi, S, Wd : LongInt);
Var T : LongInt; X : Double;
Begin
  X := D - 25569.0;
  X := X * 86400.0;
  T := Round(X);
  UnixSplit(T, Y, Mo, Dd, H, Mi, S, Wd);
End;

Function DateStr(D : Double; Part : LongInt) : String;
Var Y, Mo, Dd, H, Mi, S, Wd : LongInt; R : String;
Begin
  DateSplit(D, Y, Mo, Dd, H, Mi, S, Wd);
  R := '';
  If Part <> 2 Then R := Pad2(Dd) + '/' + Pad2(Mo) + '/' + IStr(Y);
  If (Part = 0) And (Frac(D) <> 0) Then R := R + ' ';
  If (Part = 2) Or ((Part = 0) And (Frac(D) <> 0)) Then R := R + Pad2(H) + ':' + Pad2(Mi) + ':' + Pad2(S);
  DateStr := R;
End;

Procedure VmFail(S : String);
Begin
  If VmErr = '' Then VmErr := S;
End;

{ valeur par defaut d'un objet (Request.QueryString('x'), Session('x')...) }
Procedure ObjValue(Var C : TCell); Forward;

{ conversions }
Function CellInt(Var C0 : TCell) : LongInt;
Var C : TCell; S : String; V, E : LongInt; R : Double;
Begin
  C := C0;
  If C.T = vtObj Then ObjValue(C);
  Case C.T Of
    vtInt, vtBool, vtChar, vtAddr : CellInt := C.I;
    vtReal :
      If (C.R > 2147483647.0) Or (C.R < -2147483648.0) Then
      Begin
        VmFail('d'#130'passement de capacit'#130);
        CellInt := 0;
      End
      Else CellInt := Trunc(C.R);
    vtStr, vtKStr :
      Begin
        S := Trim(CellPStr(C));
        Val(S, V, E);
        If E <> 0 Then
        Begin
          Val(S, R, E);
          If E = 0 Then V := Trunc(R) Else V := 0;
        End;
        CellInt := V;
      End;
  Else
    CellInt := 0;
  End;
End;

Function CellReal(Var C0 : TCell) : Double;
Var C : TCell; S : String; R : Double; E : LongInt;
Begin
  C := C0;
  If C.T = vtObj Then ObjValue(C);
  Case C.T Of
    vtInt, vtBool, vtChar : CellReal := C.I;
    vtReal, vtDate : CellReal := C.R;
    vtStr, vtKStr :
      Begin
        S := Trim(CellPStr(C));
        For E := 1 To Length(S) Do If S[E] = ',' Then S[E] := '.';
        Val(S, R, E);
        If E <> 0 Then R := 0;
        CellReal := R;
      End;
  Else
    CellReal := 0;
  End;
End;

Function CellBool(Var C0 : TCell) : Boolean;
Var C : TCell; S : String;
Begin
  C := C0;
  If C.T = vtObj Then ObjValue(C);
  Case C.T Of
    vtInt, vtBool, vtChar : CellBool := C.I <> 0;
    vtReal : CellBool := C.R <> 0;
    vtStr, vtKStr :
      Begin
        S := UpStr(Trim(CellPStr(C)));
        CellBool := (S = 'TRUE') Or (S = 'VRAI') Or ((S <> '') And (S <> '0') And (S <> 'FALSE') And (S <> 'FAUX'));
      End;
  Else
    CellBool := False;
  End;
End;

Var
  VbStyle : Boolean;          { conversions de VBScript (page ASP) }
  PhpStyle : Boolean;         { conversions de PHP (page PHP) }

{ texte d'une valeur (Write, concatenation) }
Procedure CellToStr(Var C : TCell; Var R : TCell);
Var S : String;
Begin
  If C.T = vtObj Then
  Begin
    R := C;
    ObjValue(R);
    If R.T = vtObj Then
    Begin
      If PhpStyle And (R.I >= 0) And (R.I < MaxObj) And (ObjK[R.I] = okPArr) Then MkStr('Array', R)
      Else MkStr('', R);
      Exit;
    End;
    CellToStr(R, R);
    Exit;
  End;
  Case C.T Of
    vtStr, vtKStr : R := C;
    vtInt : MkStr(IStr(C.I), R);
    vtReal :
      If PhpStyle Then MkStr(PhpRealStr(C.R), R)
      Else If VbStyle Then MkStr(VbRealStr(C.R), R)
      Else MkStr(RealStr(C.R, -1, -1), R);
    vtBool :
      Begin
        If PhpStyle Then
        Begin
          If C.I <> 0 Then S := '1' Else S := '';
        End
        Else If VbStyle Then
        Begin
          If C.I <> 0 Then S := 'True' Else S := 'False';
        End
        Else If C.I <> 0 Then S := 'TRUE' Else S := 'FALSE';
        MkStr(S, R);
      End;
    vtChar :
      Begin
        S := Chr(C.I);
        MkStr(S, R);
      End;
    vtDate :
      If Int(C.R) = 0 Then MkStr(DateStr(C.R, 2), R)
      Else If Frac(C.R) = 0 Then MkStr(DateStr(C.R, 1), R)
      Else MkStr(DateStr(C.R, 0), R);
  Else
    MkStr('', R);
  End;
End;

{ ajouter une valeur a la reponse }
Procedure OutCell(Var C : TCell; W, D : LongInt);
Var R : TCell; S : String; P : PBytes; N : LongInt;
Begin
  If (C.T = vtReal) And (W >= 0) Then MkStr(RealStr(C.R, W, D), R)
  Else CellToStr(C, R);
  N := CellLen(R);
  If W > N Then
  Begin
    S := '';
    While Length(S) < W - N Do S := S + ' ';
    BufAdd(VmOut, S);
  End;
  If N > 0 Then
  Begin
    If R.T = vtChar Then BufAddC(VmOut, R.I)
    Else
    Begin
      P := PoolPtr(R);
      BufAddB(VmOut, P, N);
    End;
    VmHdrPending := False;
  End;
End;

{ comparer deux chaines : -1, 0, 1 }
Function StrCmpCells(Var A, B : TCell; NoCase : Boolean) : LongInt;
Var Pa, Pb : PBytes; La, Lb, K, X, Y : LongInt; Ca, Cb : Byte;
Begin
  If A.T = vtChar Then
  Begin
    Ca := A.I; Pa := @Ca; La := 1;
  End
  Else
  Begin
    Pa := PoolPtr(A); La := A.L;
  End;
  If B.T = vtChar Then
  Begin
    Cb := B.I; Pb := @Cb; Lb := 1;
  End
  Else
  Begin
    Pb := PoolPtr(B); Lb := B.L;
  End;
  K := 0;
  While (K < La) And (K < Lb) Do
  Begin
    X := Pa^[K]; Y := Pb^[K];
    If NoCase Then
    Begin
      If (X >= 97) And (X <= 122) Then X := X - 32;
      If (Y >= 97) And (Y <= 122) Then Y := Y - 32;
    End;
    If X <> Y Then
    Begin
      If X < Y Then StrCmpCells := -1 Else StrCmpCells := 1;
      Exit;
    End;
    Inc(K);
  End;
  If La < Lb Then StrCmpCells := -1
  Else If La > Lb Then StrCmpCells := 1
  Else StrCmpCells := 0;
End;

Function IsStrCell(Var C : TCell) : Boolean;
Begin
  IsStrCell := (C.T = vtStr) Or (C.T = vtKStr) Or (C.T = vtChar);
End;

{ --- objets --- }

Function ObjNew(Kind, A, B : LongInt) : LongInt;
Begin
  If NObj >= MaxObj Then
  Begin
    VmFail('trop d''objets');
    ObjNew := 0;
    Exit;
  End;
  ObjK[NObj] := Kind; ObjA[NObj] := A; ObjB[NObj] := B; ObjH[NObj] := -1;
  MkNil(ObjS[NObj]);
  ObjNew := NObj;
  Inc(NObj);
End;

Procedure MkObj(Id : LongInt; Var C : TCell);
Begin
  C.T := vtObj; C.I := Id; C.L := 0;
End;

{ --- variables persistantes (Session, Application) --- }

Procedure PVarFree(Var V : TPVar);
Begin
  If V.P <> Nil Then FreeMem(V.P, V.L + 1);
  V.P := Nil;
  V.T := vtNil;
End;

Procedure PVarSet(Var V : TPVar; Var C0 : TCell);
Var C : TCell; P : PBytes;
Begin
  C := C0;
  If C.T = vtObj Then ObjValue(C);
  PVarFree(V);
  V.T := C.T; V.I := C.I; V.L := C.L; V.R := C.R;
  If (C.T = vtStr) Or (C.T = vtKStr) Then
  Begin
    V.T := vtStr;
    GetMem(V.P, C.L + 1);
    P := PoolPtr(C);
    If C.L > 0 Then Move(P^[0], V.P^[0], C.L);
  End
  Else If C.T = vtObj Then V.T := vtNil;
End;

Procedure PVarGet(Var V : TPVar; Var C : TCell);
Begin
  If V.T = vtStr Then MkStrB(V.P, V.L, C)
  Else
  Begin
    C.T := V.T;
    If V.T = vtReal Then C.R := V.R
    Else
    Begin
      C.I := V.I; C.L := V.L;
    End;
  End;
End;

Procedure SessFree(K : LongInt);
Var J : LongInt;
Begin
  For J := 0 To Sess[K].N - 1 Do PVarFree(Sess[K].V[J]);
  Sess[K].N := 0;
  Sess[K].Used := False;
End;

{ ==================================================================== }
{ Bases de donnees externes : PostgreSQL et MariaDB (MySQL)              }
{ ==================================================================== }
{ Les pages PSP et ASP parlent directement aux serveurs de bases de      }
{ donnees, sans pilote ni bibliotheque externe :                         }
{   - PostgreSQL : protocole v3 (requete simple), authentification       }
{     SCRAM-SHA-256, md5 ou mot de passe en clair ;                      }
{   - MariaDB et MySQL : protocole client/serveur 4.1,                   }
{     mysql_native_password (et le chemin rapide de caching_sha2).       }
{ PSP :                                                                  }
{   Connexion := Database.Connect('Provider=PostgreSQL;Server=hote;      }
{                Database=base;User Id=nom;Password=mdp');               }
{   Resultats := Connexion.Query('SELECT * FROM ClientsDemo');           }
{   While Not Resultats.Eof Do Begin ... Resultats['Nom'] ...            }
{     Resultats.Next; End;                                               }
{   Resultats.Close; Connexion.Close;                                    }
{   Connexion.Execute('UPDATE ...') : nombre de lignes touchees.         }
{ ASP : Set Cn = Server.CreateObject("ADODB.Connection") : Cn.Open ... ; }
{   Set Rs = Cn.Execute("SELECT ...") : Rs("Nom"), Rs.EOF, Rs.MoveNext.  }
{ Une requete n'arrete pas le serveur : la page attend la reponse de la  }
{ base (la machine reprend l'instruction plus tard) pendant que les      }
{ autres connexions sont servies. Les connexions authentifiees sont      }
{ gardees en reserve (meme chaine de connexion) d'une requete a l'autre. }

Const
  MaxDbConn = 8;
  MaxRs = 16;
  MaxRsCol = 64;
  dbPg = 1; dbMy = 2;
  { etats d'une connexion }
  dsClosed = 0; dsHandshake = 1; dsReady = 2; dsBusy = 3;

Type
  TDbConn = Record
    Used : Boolean;
    Kind, Sock, St, LastUse, Deadline : LongInt;
    Owned : Boolean;            { prise par la requete en cours }
    Key : String;               { chaine de connexion }
    Host : String[79];
    DbPort : LongInt;
    User, Pass, Db : String[63];
    Rx : TBuf;
    Err : String;
    { SCRAM-SHA-256 }
    CNonce : String[63];
    CFirst, SFirst : String;
    Salted : TB32;
    { MySQL }
    Seq, Phase, NCol, ColDone : LongInt;
    Scramble : Array[0..19] Of Byte;
    { requete en cours }
    QRs : LongInt;
    QErr : String;
    QHaveT : Boolean;
    Affected : LongInt;
    InsId : LongInt;           { MariaDB : identifiant de la derniere insertion }
  End;

  TRs = Record
    Used : Boolean;
    NCol, NRow, Cur : LongInt;
    ColNm : Array[0..MaxRsCol - 1] Of String[63];
    ColTy : Array[0..MaxRsCol - 1] Of Byte;    { 0 chaine, 1 entier, 2 reel, 3 booleen }
    Data : TBuf;                { octets des valeurs }
    Idx : TBuf;                 { (debut, longueur ; -1 : NULL) par cellule }
    Affected : LongInt;
  End;

Var
  DbC : Array[0..MaxDbConn - 1] Of TDbConn;
  Rss : Array[0..MaxRs - 1] Of TRs;
  DbPend : LongInt;             { connexion dont la page attend la reponse }
  DbWaitSock : LongInt;         { son socket (select du service) ; -1 : aucun }
  VmWait : Boolean;             { l'appel de membre attend : a reprendre }

{ --- hachages : MD5 et SHA-1 --- }

Function Rol(X, N : LongInt) : LongInt;
Begin
  Rol := (X Shl N) Or Sr(X, 32 - N);
End;

Procedure Md5(P : PBytes; N : LongInt; Var Out_ : TBlk);
Const
  S : Array[0..63] Of Byte = (7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21);
  { T[i] = partie entiere de abs(sin(i + 1)) * 2^32 (en LongInt) }
  T : Array[0..63] Of LongInt = (
    -680876936, -389564586, 606105819, -1044525330, -176418897, 1200080426, -1473231341, -45705983,
    1770035416, -1958414417, -42063, -1990404162, 1804603682, -40341101, -1502002290, 1236535329,
    -165796510, -1069501632, 643717713, -373897302, -701558691, 38016083, -660478335, -405537848,
    568446438, -1019803690, -187363961, 1163531501, -1444681467, -51403784, 1735328473, -1926607734,
    -378558, -2022574463, 1839030562, -35309556, -1530992060, 1272893353, -155497632, -1094730640,
    681279174, -358537222, -722521979, 76029189, -640364487, -421815835, 530742520, -995338651,
    -198630844, 1126891415, -1416354905, -57434055, 1700485571, -1894986606, -1051523, -2054922799,
    1873313359, -30611744, -1560198380, 1309151649, -145523070, -1120210379, 718787259, -343485551);
Var
  M : Array[0..15] Of LongInt; Blk : Array[0..63] Of Byte;
  A0, B0, C0, D0, A, B, C, D, F, G, K, I, Tot, Tmp : LongInt;
Begin
  A0 := $67452301; B0 := LongInt($EFCDAB89); C0 := LongInt($98BADCFE); D0 := $10325476;
  Tot := ((N + 8) Div 64 + 1) * 64;
  K := 0;
  While K < Tot Do
  Begin
    For I := 0 To 63 Do
    Begin
      If K + I < N Then Blk[I] := P^[K + I]
      Else If K + I = N Then Blk[I] := $80
      Else Blk[I] := 0;
    End;
    If K + 64 = Tot Then
    Begin
      Blk[56] := (N Shl 3) And 255; Blk[57] := (N Shr 5) And 255; Blk[58] := (N Shr 13) And 255;
      Blk[59] := (N Shr 21) And 255; Blk[60] := Sr(N, 29);
    End;
    For I := 0 To 15 Do
      M[I] := Blk[I * 4] Or (Blk[I * 4 + 1] Shl 8) Or (Blk[I * 4 + 2] Shl 16) Or (Blk[I * 4 + 3] Shl 24);
    A := A0; B := B0; C := C0; D := D0;
    For I := 0 To 63 Do
    Begin
      If I < 16 Then
      Begin
        F := (B And C) Or ((Not B) And D); G := I;
      End
      Else If I < 32 Then
      Begin
        F := (D And B) Or ((Not D) And C); G := (5 * I + 1) And 15;
      End
      Else If I < 48 Then
      Begin
        F := B Xor C Xor D; G := (3 * I + 5) And 15;
      End
      Else
      Begin
        F := C Xor (B Or (Not D)); G := (7 * I) And 15;
      End;
      Tmp := D; D := C; C := B;
      B := B + Rol(A + F + T[I] + M[G], S[I]);
      A := Tmp;
    End;
    A0 := A0 + A; B0 := B0 + B; C0 := C0 + C; D0 := D0 + D;
    K := K + 64;
  End;
  For I := 0 To 3 Do
  Begin
    Out_[I] := (A0 Shr (I * 8)) And 255; Out_[4 + I] := (B0 Shr (I * 8)) And 255;
    Out_[8 + I] := (C0 Shr (I * 8)) And 255; Out_[12 + I] := (D0 Shr (I * 8)) And 255;
  End;
End;

Type
  TB20 = Array[0..19] Of Byte;

Procedure Sha1(P : PBytes; N : LongInt; Var Out_ : TB20);
Var
  H : Array[0..4] Of LongInt; W : Array[0..79] Of LongInt; Blk : Array[0..63] Of Byte;
  A, B, C, D, E, F, K, I, Tot, Tmp, Kc : LongInt;
Begin
  H[0] := $67452301; H[1] := LongInt($EFCDAB89); H[2] := LongInt($98BADCFE); H[3] := $10325476;
  H[4] := LongInt($C3D2E1F0);
  Tot := ((N + 8) Div 64 + 1) * 64;
  K := 0;
  While K < Tot Do
  Begin
    For I := 0 To 63 Do
    Begin
      If K + I < N Then Blk[I] := P^[K + I]
      Else If K + I = N Then Blk[I] := $80
      Else Blk[I] := 0;
    End;
    If K + 64 = Tot Then
    Begin
      Blk[59] := Sr(N, 29); Blk[60] := (N Shr 21) And 255; Blk[61] := (N Shr 13) And 255;
      Blk[62] := (N Shr 5) And 255; Blk[63] := (N Shl 3) And 255;
    End;
    For I := 0 To 15 Do
      W[I] := (Blk[I * 4] Shl 24) Or (Blk[I * 4 + 1] Shl 16) Or (Blk[I * 4 + 2] Shl 8) Or Blk[I * 4 + 3];
    For I := 16 To 79 Do W[I] := Rol(W[I - 3] Xor W[I - 8] Xor W[I - 14] Xor W[I - 16], 1);
    A := H[0]; B := H[1]; C := H[2]; D := H[3]; E := H[4];
    For I := 0 To 79 Do
    Begin
      If I < 20 Then
      Begin
        F := (B And C) Or ((Not B) And D); Kc := $5A827999;
      End
      Else If I < 40 Then
      Begin
        F := B Xor C Xor D; Kc := $6ED9EBA1;
      End
      Else If I < 60 Then
      Begin
        F := (B And C) Or (B And D) Or (C And D); Kc := LongInt($8F1BBCDC);
      End
      Else
      Begin
        F := B Xor C Xor D; Kc := LongInt($CA62C1D6);
      End;
      Tmp := Rol(A, 5) + F + E + Kc + W[I];
      E := D; D := C; C := Rol(B, 30); B := A; A := Tmp;
    End;
    H[0] := H[0] + A; H[1] := H[1] + B; H[2] := H[2] + C; H[3] := H[3] + D; H[4] := H[4] + E;
    K := K + 64;
  End;
  For I := 0 To 4 Do
  Begin
    Out_[I * 4] := Sr(H[I], 24); Out_[I * 4 + 1] := Sr(H[I], 16) And 255;
    Out_[I * 4 + 2] := Sr(H[I], 8) And 255; Out_[I * 4 + 3] := H[I] And 255;
  End;
End;

Function HexBytes(P : PBytes; N : LongInt) : String;
Const Hx : String[16] = '0123456789abcdef';
Var S : String; K : LongInt;
Begin
  S := '';
  For K := 0 To N - 1 Do S := S + Hx[(P^[K] Shr 4) + 1] + Hx[(P^[K] And 15) + 1];
  HexBytes := S;
End;

{ PBKDF2-HMAC-SHA256, un bloc (32 octets) }
Procedure Pbkdf2(Pw : String; Salt : String; Iter : LongInt; Var Out_ : TB32);
Var U, T : TB32; Msg : String; I, K, L : LongInt;
Begin
  { sel suivi du numero de bloc (00 00 00 01), octet par octet : un
    litteral #0 coupe la chaine sous OS2PC }
  Msg := Salt;
  L := Length(Msg);
  If L > 250 Then L := 250;
  Msg[L + 1] := Chr(0); Msg[L + 2] := Chr(0); Msg[L + 3] := Chr(0); Msg[L + 4] := Chr(1);
  Msg[0] := Chr(L + 4);
  If Length(Pw) = 0 Then
  Begin
    Pw[1] := Chr(0); Pw[0] := Chr(1);    { (cle vide : une cle d'un octet nul est equivalente) }
  End;
  Hmac(@Pw[1], Length(Pw), @Msg[1], Length(Msg), U);
  T := U;
  For I := 2 To Iter Do
  Begin
    Hmac(@Pw[1], Length(Pw), @U, 32, U);
    For K := 0 To 31 Do T[K] := T[K] Xor U[K];
  End;
  Out_ := T;
End;

Procedure HmacStr(Var Key : TB32; S : String; Var R : TB32);
Begin
  Hmac(@Key, 32, @S[1], Length(S), R);
End;

Function B64Bytes(P : PBytes; N : LongInt) : String;
Var B : TBuf; S : String;
Begin
  BufInit(B);
  B64Enc(P, N, B, 0);
  S := '';
  If B.Len > 0 Then
  Begin
    If B.Len > 255 Then B.Len := 255;
    Move(B.P^[0], S[1], B.Len);
    S[0] := Chr(B.Len);
  End;
  While (Length(S) > 0) And (S[Length(S)] < ' ') Do Delete(S, Length(S), 1);
  BufFree(B);
  B64Bytes := S;
End;

{ --- reseau : connexion cliente (bloquante), puis non bloquante --- }

{$IFDEF OS2PC}
Function SockConnect(S, A, L : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function SockGetHost(P : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
{$ENDIF}

Function PResolve(Host : String) : LongInt;
{$IFDEF OS2PC}
Var H, L, A : LongInt; P : PBytes;
Begin
  A := ParseIp(Host);
  PResolve := A;
  If A <> 0 Then Exit;
  H := SockGetHost(Z(Host));
  If H = 0 Then Exit;
  P := Pointer(H);
  L := P^[16] Or (P^[17] Shl 8) Or (P^[18] Shl 16) Or (P^[19] Shl 24);   { h_addr_list (hostent de TCPIP32) }
  If L = 0 Then Exit;
  P := Pointer(L);
  A := P^[0] Or (P^[1] Shl 8) Or (P^[2] Shl 16) Or (P^[3] Shl 24);
  If A = 0 Then Exit;
  P := Pointer(A);
  PResolve := (P^[0] Shl 24) Or (P^[1] Shl 16) Or (P^[2] Shl 8) Or P^[3];
End;
{$ELSE}
Begin
  If LoStr(Host) = 'localhost' Then PResolve := $7F000001 Else PResolve := ParseIp(Host);
End;
{$ENDIF}

{ socket connecte (non bloquant ensuite) ; -1 : echec }
Function PConnect(Ip, DbPort : LongInt) : LongInt;
Var S, One : LongInt;
{$IFDEF OS2PC}
    A : Array[0..15] Of Byte; K : LongInt;
{$ELSE}
    A : TInetSockAddr;
{$ENDIF}
Begin
  PConnect := -1;
  {$IFDEF OS2PC}
  S := SockSocket(2, 1, 0);
  If S < 0 Then Exit;
  For K := 0 To 15 Do A[K] := 0;
  A[0] := 16; A[1] := 2; A[2] := (DbPort Shr 8) And 255; A[3] := DbPort And 255;
  A[4] := Sr(Ip, 24); A[5] := Sr(Ip, 16) And 255; A[6] := Sr(Ip, 8) And 255; A[7] := Ip And 255;
  If SockConnect(S, LongInt(@A), 16) <> 0 Then
  Begin
    Dummy := SockClose(S);
    Exit;
  End;
  One := 1;
  Dummy := SockIoctl(S, $8004667E, LongInt(@One), 4);
  {$ELSE}
  S := fpSocket(AF_INET, SOCK_STREAM, 0);
  If S < 0 Then Exit;
  FillChar(A, SizeOf(A), 0);
  A.sin_family := AF_INET; A.sin_port := htons(DbPort); A.sin_addr.s_addr := htonl(LongWord(Ip));
  If fpConnect(S, @A, SizeOf(A)) <> 0 Then
  Begin
    fpClose(S);
    Exit;
  End;
  fpFcntl(S, F_SETFL, fpFcntl(S, F_GETFL) Or O_NONBLOCK);
  One := 1;
  fpSetSockOpt(S, 6, 1, @One, 4);
  {$ENDIF}
  PConnect := S;
End;

{ envoyer tout (petits messages : quelques essais) }
Function DbSend(K : LongInt; P : PBytes; N : LongInt) : Boolean;
Var R, Done, T : LongInt;
Begin
  DbSend := False;
  Done := 0; T := PTicks;
  While Done < N Do
  Begin
    R := PSend(DbC[K].Sock, @P^[Done], N - Done);
    If R < 0 Then
    Begin
      DbC[K].Err := 'connexion interrompue';
      Exit;
    End;
    Done := Done + R;
    If R = 0 Then
    Begin
      If PTicks - T > 10000 Then
      Begin
        DbC[K].Err := 'envoi impossible (delai)';
        Exit;
      End;
      PSleep(1);
    End;
  End;
  DbSend := True;
End;

{ lire ce qui est arrive ; faux : connexion fermee ou erreur }
Function DbFill(K : LongInt) : Boolean;
Var R : LongInt;
Begin
  DbFill := True;
  Repeat
    If Not BufGrow(DbC[K].Rx, 16384) Then
    Begin
      DbC[K].Err := 'memoire insuffisante';
      DbFill := False;
      Exit;
    End;
    R := PRecv(DbC[K].Sock, @DbC[K].Rx.P^[DbC[K].Rx.Len], 16384);
    If R > 0 Then DbC[K].Rx.Len := DbC[K].Rx.Len + R
    Else If R = 0 Then
    Begin
      DbC[K].Err := 'connexion fermee par le serveur';
      DbFill := False;
    End
    Else If R = -2 Then
    Begin
      DbC[K].Err := 'connexion interrompue';
      DbFill := False;
    End;
  Until R <= 0;
End;

{ retirer N octets du debut du tampon de reception }
Procedure DbEat(K, N : LongInt);
Begin
  With DbC[K] Do
  Begin
    If N >= Rx.Len Then Rx.Len := 0
    Else
    Begin
      Move(Rx.P^[N], Rx.P^[0], Rx.Len - N);
      Rx.Len := Rx.Len - N;
    End;
  End;
End;

Procedure DbClose(K : LongInt);
Var Q : Array[0..7] Of Byte;
Begin
  With DbC[K] Do
  Begin
    If Not Used Then Exit;
    If (Sock >= 0) And (St = dsReady) Then
    Begin
      If Kind = dbPg Then
      Begin
        Q[0] := Ord('X'); Q[1] := 0; Q[2] := 0; Q[3] := 0; Q[4] := 4;
        Dummy := PSend(Sock, @Q, 5);
      End
      Else
      Begin
        Q[0] := 1; Q[1] := 0; Q[2] := 0; Q[3] := 0; Q[4] := 1;
        Dummy := PSend(Sock, @Q, 5);
      End;
    End;
    If Sock >= 0 Then PSockClose(Sock);
    Sock := -1; St := dsClosed; Used := False; Owned := False;
    BufFree(Rx);
  End;
End;

{ --- jeux d'enregistrements --- }

Function RsNew : LongInt;
Var K : LongInt;
Begin
  RsNew := -1;
  For K := 0 To MaxRs - 1 Do
    If Not Rss[K].Used Then
    Begin
      Rss[K].Used := True;
      Rss[K].NCol := 0; Rss[K].NRow := 0; Rss[K].Cur := 0; Rss[K].Affected := 0;
      BufInit(Rss[K].Data); BufInit(Rss[K].Idx);
      RsNew := K;
      Exit;
    End;
End;

Procedure RsFree(K : LongInt);
Begin
  If (K < 0) Or (K >= MaxRs) Or Not Rss[K].Used Then Exit;
  BufFree(Rss[K].Data); BufFree(Rss[K].Idx);
  Rss[K].Used := False;
End;

Procedure RsAddInt(K, V : LongInt);
Var B : Array[0..3] Of Byte;
Begin
  B[0] := V And 255; B[1] := Sr(V, 8) And 255; B[2] := Sr(V, 16) And 255; B[3] := Sr(V, 24);
  BufAddB(Rss[K].Idx, @B, 4);
End;

{ une valeur (P, N octets ; N < 0 : NULL) de la ligne en cours de lecture }
Procedure RsAddVal(K : LongInt; P : PBytes; N : LongInt);
Begin
  RsAddInt(K, Rss[K].Data.Len);
  RsAddInt(K, N);
  If N > 0 Then BufAddB(Rss[K].Data, P, N);
End;

Function RsIdx(K, Pos : LongInt) : LongInt;
Var Q : PBytes;
Begin
  Q := Rss[K].Idx.P;
  RsIdx := Q^[Pos] Or (Q^[Pos + 1] Shl 8) Or (Q^[Pos + 2] Shl 16) Or (Q^[Pos + 3] Shl 24);
End;

{ colonne d'apres un nom (sans egard a la casse) ou un numero (0..) }
Function RsCol(K : LongInt; Var Key : TCell) : LongInt;
Var C : LongInt; S : String; T : TCell;
Begin
  RsCol := -1;
  If (Key.T = vtInt) Or (Key.T = vtReal) Then
  Begin
    C := CellInt(Key);
    If (C >= 0) And (C < Rss[K].NCol) Then RsCol := C;
    Exit;
  End;
  CellToStr(Key, T);
  S := UpStr(CellPStr(T));
  For C := 0 To Rss[K].NCol - 1 Do
    If UpStr(Rss[K].ColNm[C]) = S Then
    Begin
      RsCol := C;
      Exit;
    End;
End;

{ valeur de la colonne C de la ligne en cours }
Procedure RsValue(K, C : LongInt; Var R : TCell);
Var Pos, Ofs, N, V, E : LongInt; P : PBytes; S : String; D : Double;
Begin
  MkNil(R);
  If (Rss[K].Cur < 0) Or (Rss[K].Cur >= Rss[K].NRow) Or (C < 0) Or (C >= Rss[K].NCol) Then Exit;
  Pos := (Rss[K].Cur * Rss[K].NCol + C) * 8;
  Ofs := RsIdx(K, Pos); N := RsIdx(K, Pos + 4);
  If N < 0 Then Exit;
  P := @Rss[K].Data.P^[Ofs];
  If (Rss[K].ColTy[C] = 0) Or (N > 40) Then
  Begin
    MkStrB(P, N, R);
    Exit;
  End;
  S := '';
  If N > 0 Then Move(P^[0], S[1], N);
  S[0] := Chr(N);
  Case Rss[K].ColTy[C] Of
    1 :
      Begin
        Val(S, D, E);
        If (E = 0) And (D >= -2147483648.0) And (D <= 2147483647.0) Then
        Begin
          Val(S, V, E);
          MkInt(V, R);
        End
        Else If E = 0 Then MkReal(D, R)
        Else MkStr(S, R);
      End;
    2 :
      Begin
        Val(S, D, E);
        If E = 0 Then MkReal(D, R) Else MkStr(S, R);
      End;
    3 : MkBool((S = 't') Or (S = 'true') Or (S = '1') Or (S = 'TRUE'), R);
  Else
    MkStr(S, R);
  End;
End;

{ --- chaine de connexion --- }

Function ConnKey(S, Key : String) : String;
Var U, P, Q, K, V : String; I : LongInt;
Begin
  ConnKey := '';
  U := S;
  While U <> '' Do
  Begin
    I := Pos(';', U);
    If I = 0 Then I := Length(U) + 1;
    P := Copy(U, 1, I - 1);
    Delete(U, 1, I);
    I := Pos('=', P);
    If I > 0 Then
    Begin
      K := UpStr(Trim(Copy(P, 1, I - 1)));
      V := Trim(Copy(P, I + 1, 255));
      Q := ',' + Key + ',';
      If Pos(',' + K + ',', Q) > 0 Then
      Begin
        ConnKey := V;
        Exit;
      End;
    End;
  End;
End;

{ remplir la connexion K d'apres la chaine ; faux : chaine incorrecte }
Function ConnParse(K : LongInt; S : String) : Boolean;
Var P, I : LongInt; T, Pv : String;
Begin
  ConnParse := False;
  With DbC[K] Do
  Begin
    Kind := 0; Host := ''; DbPort := 0; User := ''; Pass := ''; Db := '';
    T := LoStr(S);
    { forme URL : postgresql://nom:mdp@hote:port/base, mysql://, mariadb:// }
    If (Copy(T, 1, 13) = 'postgresql://') Or (Copy(T, 1, 11) = 'postgres://') Or
       (Copy(T, 1, 8) = 'mysql://') Or (Copy(T, 1, 10) = 'mariadb://') Then
    Begin
      If Copy(T, 1, 5) = 'postg' Then Kind := dbPg Else Kind := dbMy;
      P := Pos('://', S);
      T := Copy(S, P + 3, 255);
      P := Pos('/', T);
      If P > 0 Then
      Begin
        Db := Copy(T, P + 1, 63);
        T := Copy(T, 1, P - 1);
        I := Pos('?', Db);
        If I > 0 Then Db := Copy(Db, 1, I - 1);
      End;
      P := Pos('@', T);
      If P > 0 Then
      Begin
        User := Copy(T, 1, P - 1);
        T := Copy(T, P + 1, 255);
        I := Pos(':', User);
        If I > 0 Then
        Begin
          Pass := UrlDecode(Copy(User, I + 1, 63), False);
          User := Copy(User, 1, I - 1);
        End;
        User := UrlDecode(User, False);
      End;
      P := Pos(':', T);
      If P > 0 Then
      Begin
        DbPort := SVal(Copy(T, P + 1, 10));
        T := Copy(T, 1, P - 1);
      End;
      Host := T;
    End
    Else
    Begin
      Pv := UpStr(ConnKey(S, 'PROVIDER,DRIVER,TYPE,ENGINE,DBTYPE'));
      If (Pos('POSTGRE', Pv) > 0) Or (Pos('NPGSQL', Pv) > 0) Or (Pv = 'PG') Or (Pv = 'PGSQL') Then Kind := dbPg
      Else If (Pos('MYSQL', Pv) > 0) Or (Pos('MARIA', Pv) > 0) Then Kind := dbMy;
      Host := ConnKey(S, 'SERVER,HOST,DATA SOURCE,ADDRESS,ADDR,HOSTNAME');
      T := ConnKey(S, 'PORT');
      If T <> '' Then DbPort := SVal(T);
      P := Pos(',', Host);
      If P = 0 Then P := Pos(':', Host);
      If P > 0 Then
      Begin
        DbPort := SVal(Copy(Host, P + 1, 10));
        Host := Copy(Host, 1, P - 1);
      End;
      Db := ConnKey(S, 'DATABASE,INITIAL CATALOG,DBNAME,DB');
      User := ConnKey(S, 'USER ID,UID,USER,USERNAME,USER NAME');
      Pass := ConnKey(S, 'PASSWORD,PWD');
    End;
    If Host = '' Then Host := 'localhost';
    If (Kind = 0) And (DbPort = 5432) Then Kind := dbPg;
    If (Kind = 0) And (DbPort = 3306) Then Kind := dbMy;
    If Kind = 0 Then
    Begin
      Err := 'type de base inconnu : pr'#130'cisez Provider=PostgreSQL ou Provider=MariaDB';
      Exit;
    End;
    If DbPort = 0 Then
      If Kind = dbPg Then DbPort := 5432 Else DbPort := 3306;
    If User = '' Then
    Begin
      Err := 'nom d''utilisateur absent de la cha'#140'ne de connexion (User Id=...)';
      Exit;
    End;
    If (Kind = dbPg) And (Db = '') Then Db := User;
  End;
  ConnParse := True;
End;

{ ==================================================================== }
{ PostgreSQL (protocole v3)                                             }
{ ==================================================================== }

Procedure PgPut32(Var B : TBuf; V : LongInt);
Begin
  BufAddC(B, Sr(V, 24)); BufAddC(B, Sr(V, 16) And 255); BufAddC(B, Sr(V, 8) And 255); BufAddC(B, V And 255);
End;

{ envoyer un message : type (0 : demarrage, sans type), corps }
Function PgMsg(K : LongInt; Typ : Char; Var Body : TBuf) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  If Typ <> #0 Then BufAddC(B, Ord(Typ));
  PgPut32(B, Body.Len + 4);
  BufAddB(B, Body.P, Body.Len);
  PgMsg := DbSend(K, B.P, B.Len);
  BufFree(B);
End;

Procedure BufAddZ(Var B : TBuf; S : String);
Begin
  BufAdd(B, S);
  BufAddC(B, 0);
End;

Function PgStart(K : LongInt) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  PgPut32(B, 196608);
  BufAddZ(B, 'user'); BufAddZ(B, DbC[K].User);
  BufAddZ(B, 'database'); BufAddZ(B, DbC[K].Db);
  BufAddZ(B, 'client_encoding'); BufAddZ(B, 'UTF8');
  BufAddZ(B, 'application_name'); BufAddZ(B, 'OS2-0-WebSrv');
  BufAddC(B, 0);
  PgStart := PgMsg(K, #0, B);
  BufFree(B);
End;

Function PgGet32(P : PBytes) : LongInt;
Begin
  PgGet32 := (P^[0] Shl 24) Or (P^[1] Shl 16) Or (P^[2] Shl 8) Or P^[3];
End;

Function PgGet16(P : PBytes) : LongInt;
Begin
  PgGet16 := (P^[0] Shl 8) Or P^[1];
End;

{ texte d'un message d'erreur ('E' : champs code + texte) }
Function PgErrText(P : PBytes; N : LongInt) : String;
Var I : LongInt; F : Char; S, M, C : String;
Begin
  I := 0; M := ''; C := '';
  While (I < N) And (P^[I] <> 0) Do
  Begin
    F := Chr(P^[I]); Inc(I);
    S := '';
    While (I < N) And (P^[I] <> 0) Do
    Begin
      If Length(S) < 200 Then S := S + Chr(P^[I]);
      Inc(I);
    End;
    Inc(I);
    If F = 'M' Then M := S Else If F = 'C' Then C := S;
  End;
  If C <> '' Then M := M + ' (' + C + ')';
  PgErrText := M;
End;

{ SCRAM-SHA-256 : premier message du client }
Procedure PgScramFirst(K : LongInt);
Var R : Array[0..17] Of Byte; B : TBuf; S : String;
Begin
  RandFill(@R, 18);
  DbC[K].CNonce := B64Bytes(@R, 18);
  DbC[K].CFirst := 'n=,r=' + DbC[K].CNonce;
  S := 'n,,' + DbC[K].CFirst;
  BufInit(B);
  BufAddZ(B, 'SCRAM-SHA-256');
  PgPut32(B, Length(S));
  BufAdd(B, S);
  Dummy := Ord(PgMsg(K, 'p', B));
  BufFree(B);
End;

Function ScramAttr(S : String; A : Char) : String;
Var P : LongInt;
Begin
  ScramAttr := '';
  S := ',' + S;
  P := Pos(',' + A + '=', S);
  If P = 0 Then Exit;
  S := Copy(S, P + 3, 255);
  P := Pos(',', S);
  If P > 0 Then S := Copy(S, 1, P - 1);
  ScramAttr := S;
End;

Function PgScramFinal(K : LongInt; SFirst : String) : Boolean;
Var Nonce, Salt, Fin, Auth : String; It, I : LongInt; CKey, SKey, Sig, Proof : TB32; B : TBuf;
Begin
  PgScramFinal := False;
  Nonce := ScramAttr(SFirst, 'r'); Salt := B64DecStr(ScramAttr(SFirst, 's'));
  It := SVal(ScramAttr(SFirst, 'i'));
  If (Copy(Nonce, 1, Length(DbC[K].CNonce)) <> DbC[K].CNonce) Or (It < 1) Or (Salt = '') Then
  Begin
    DbC[K].Err := 'SCRAM : r'#130'ponse du serveur incorrecte';
    Exit;
  End;
  DbC[K].SFirst := SFirst;
  Pbkdf2(DbC[K].Pass, Salt, It, DbC[K].Salted);
  HmacStr(DbC[K].Salted, 'Client Key', CKey);
  Sha256(@CKey, 32, SKey);
  Fin := 'c=biws,r=' + Nonce;
  Auth := DbC[K].CFirst + ',' + SFirst + ',' + Fin;
  HmacStr(SKey, Auth, Sig);
  For I := 0 To 31 Do Proof[I] := CKey[I] Xor Sig[I];
  DbC[K].CFirst := Auth;    { (garde pour verifier la signature du serveur) }
  Fin := Fin + ',p=' + B64Bytes(@Proof, 32);
  BufInit(B);
  BufAdd(B, Fin);
  PgScramFinal := PgMsg(K, 'p', B);
  BufFree(B);
End;

Function PgScramCheck(K : LongInt; SFinal : String) : Boolean;
Var SKey, Sig : TB32;
Begin
  HmacStr(DbC[K].Salted, 'Server Key', SKey);
  HmacStr(SKey, DbC[K].CFirst, Sig);
  PgScramCheck := ScramAttr(SFinal, 'v') = B64Bytes(@Sig, 32);
End;

{ avancer : 1 fini (ReadyForQuery), 0 a suivre, -1 erreur (Err) }
Function PgStep(K : LongInt) : LongInt;
Var Typ : Char; L, Code, N, I, J, C, Ty, O : LongInt; P : PBytes; S : String; B : TBuf; Dg : TBlk;
    Rs : LongInt;
Begin
  PgStep := 0;
  If Not DbFill(K) Then
  Begin
    PgStep := -1;
    Exit;
  End;
  With DbC[K] Do
    While Rx.Len >= 5 Do
    Begin
      Typ := Chr(Rx.P^[0]);
      L := PgGet32(@Rx.P^[1]);
      If (L < 4) Or (L > 64 * 1024 * 1024) Then
      Begin
        Err := 'r'#130'ponse incorrecte du serveur PostgreSQL';
        PgStep := -1;
        Exit;
      End;
      If Rx.Len < L + 1 Then Exit;
      P := @Rx.P^[5]; N := L - 4;
      Case Typ Of
        'R' :
          Begin
            Code := PgGet32(P);
            Case Code Of
              0 : ;
              3 :
                Begin
                  BufInit(B); BufAddZ(B, Pass);
                  Dummy := Ord(PgMsg(K, 'p', B)); BufFree(B);
                End;
              5 :
                Begin
                  S := Pass + User;
                  Md5(@S[1], Length(S), Dg);
                  S := HexBytes(@Dg, 16);
                  For I := 0 To 3 Do S[33 + I] := Chr(P^[4 + I]);    { sel (octets quelconques) }
                  S[0] := Chr(36);
                  Md5(@S[1], Length(S), Dg);
                  BufInit(B); BufAddZ(B, 'md5' + HexBytes(@Dg, 16));
                  Dummy := Ord(PgMsg(K, 'p', B)); BufFree(B);
                End;
              10 :
                Begin
                  S := '';
                  For I := 4 To N - 1 Do If P^[I] = 0 Then S := S + ',' Else S := S + Chr(P^[I]);
                  If Pos('SCRAM-SHA-256,', S + ',') = 0 Then
                  Begin
                    Err := 'm'#130'canisme d''authentification non pris en charge : ' + S;
                    PgStep := -1;
                    Exit;
                  End;
                  PgScramFirst(K);
                End;
              11 :
                Begin
                  S := '';
                  For I := 4 To N - 1 Do If Length(S) < 255 Then S := S + Chr(P^[I]);
                  If Not PgScramFinal(K, S) Then
                  Begin
                    PgStep := -1;
                    Exit;
                  End;
                End;
              12 :
                Begin
                  S := '';
                  For I := 4 To N - 1 Do If Length(S) < 255 Then S := S + Chr(P^[I]);
                  If Not PgScramCheck(K, S) Then
                  Begin
                    Err := 'SCRAM : signature du serveur incorrecte';
                    PgStep := -1;
                    Exit;
                  End;
                End;
            Else
              Begin
                Err := 'authentification PostgreSQL non prise en charge (code ' + IStr(Code) + ')';
                PgStep := -1;
                Exit;
              End;
            End;
          End;
        'E' :
          Begin
            QErr := PgErrText(P, N);
            If St = dsHandshake Then
            Begin
              Err := QErr;
              PgStep := -1;
              Exit;
            End;
          End;
        'T' :
          If (QRs >= 0) And Not QHaveT Then
          Begin
            Rs := QRs;
            QHaveT := True;
            C := PgGet16(P); O := 2;
            If C > MaxRsCol Then C := MaxRsCol;
            Rss[Rs].NCol := C;
            For J := 0 To C - 1 Do
            Begin
              S := '';
              While (O < N) And (P^[O] <> 0) Do
              Begin
                If Length(S) < 63 Then S := S + Chr(P^[O]);
                Inc(O);
              End;
              Inc(O);
              Ty := PgGet32(@P^[O + 6]);
              O := O + 18;
              Rss[Rs].ColNm[J] := S;
              Case Ty Of
                20, 21, 23, 26 : Rss[Rs].ColTy[J] := 1;
                700, 701 : Rss[Rs].ColTy[J] := 2;
                16 : Rss[Rs].ColTy[J] := 3;
              Else
                Rss[Rs].ColTy[J] := 0;
              End;
            End;
          End;
        'D' :
          If (QRs >= 0) And QHaveT And (QErr = '') Then
          Begin
            Rs := QRs;
            C := PgGet16(P); O := 2;
            For J := 0 To Rss[Rs].NCol - 1 Do
            Begin
              If J < C Then
              Begin
                I := PgGet32(@P^[O]); O := O + 4;
                If I < 0 Then RsAddVal(Rs, Nil, -1)
                Else
                Begin
                  RsAddVal(Rs, @P^[O], I);
                  O := O + I;
                End;
              End
              Else RsAddVal(Rs, Nil, -1);
            End;
            Inc(Rss[Rs].NRow);
          End;
        'C' :
          Begin
            { "INSERT 0 3", "UPDATE 2", "SELECT 5" : le dernier nombre }
            S := '';
            For I := 0 To N - 2 Do If Length(S) < 60 Then S := S + Chr(P^[I]);
            I := Length(S);
            While (I > 0) And (S[I] <> ' ') Do Dec(I);
            Affected := SVal(Copy(S, I + 1, 20));
          End;
        'Z' :
          Begin
            DbEat(K, L + 1);
            If St = dsHandshake Then
            Begin
              St := dsReady;
              PgStep := 1;
            End
            Else If QErr <> '' Then
            Begin
              Err := QErr;
              St := dsReady;
              PgStep := -1;
            End
            Else
            Begin
              St := dsReady;
              PgStep := 1;
            End;
            Exit;
          End;
      End;
      DbEat(K, L + 1);
    End;
End;

Function PgQuery(K : LongInt; Var Sql : TBuf) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  BufAddB(B, Sql.P, Sql.Len);
  BufAddC(B, 0);
  PgQuery := PgMsg(K, 'Q', B);
  BufFree(B);
End;

{ ==================================================================== }
{ MariaDB et MySQL                                                      }
{ ==================================================================== }

Function MySend(K : LongInt; Var Body : TBuf) : Boolean;
Var B : TBuf;
Begin
  BufInit(B);
  BufAddC(B, Body.Len And 255); BufAddC(B, Sr(Body.Len, 8) And 255); BufAddC(B, Sr(Body.Len, 16) And 255);
  BufAddC(B, DbC[K].Seq And 255);
  Inc(DbC[K].Seq);
  BufAddB(B, Body.P, Body.Len);
  MySend := DbSend(K, B.P, B.Len);
  BufFree(B);
End;

{ entier code en longueur variable a P^[O] ; O avance }
Function LenEnc(P : PBytes; Var O : LongInt) : LongInt;
Var V : LongInt;
Begin
  V := P^[O];
  Inc(O);
  If V = $FC Then
  Begin
    V := P^[O] Or (P^[O + 1] Shl 8); O := O + 2;
  End
  Else If V = $FD Then
  Begin
    V := P^[O] Or (P^[O + 1] Shl 8) Or (P^[O + 2] Shl 16); O := O + 3;
  End
  Else If V = $FE Then
  Begin
    V := P^[O] Or (P^[O + 1] Shl 8) Or (P^[O + 2] Shl 16) Or (P^[O + 3] Shl 24); O := O + 8;
  End
  Else If V = $FB Then V := -1;
  LenEnc := V;
End;

{ reponse a l'authentification mysql_native_password : 20 octets }
Procedure MyNative(K : LongInt; Var Out_ : TB20);
Var H1, H2, H3 : TB20; S : Array[0..39] Of Byte; I : LongInt; Pw : String;
Begin
  Pw := DbC[K].Pass;
  Sha1(@Pw[1], Length(Pw), H1);
  Sha1(@H1, 20, H2);
  For I := 0 To 19 Do
  Begin
    S[I] := DbC[K].Scramble[I]; S[20 + I] := H2[I];
  End;
  Sha1(@S, 40, H3);
  For I := 0 To 19 Do Out_[I] := H1[I] Xor H3[I];
End;

{ caching_sha2_password (chemin rapide) : XOR(SHA256(mdp), SHA256(SHA256(SHA256(mdp)), brouillage)) }
Procedure MyCachingSha2(K : LongInt; Var Out_ : TB32);
Var H1, H2, H3 : TB32; S : Array[0..51] Of Byte; I : LongInt; Pw : String;
Begin
  Pw := DbC[K].Pass;
  Sha256(@Pw[1], Length(Pw), H1);
  Sha256(@H1, 32, H2);
  For I := 0 To 31 Do S[I] := H2[I];
  For I := 0 To 19 Do S[32 + I] := DbC[K].Scramble[I];
  Sha256(@S, 52, H3);
  For I := 0 To 31 Do Out_[I] := H1[I] Xor H3[I];
End;

Procedure MyAuthData(K : LongInt; Plugin : String; Var B : TBuf);
Var H : TB20; H2 : TB32;
Begin
  If DbC[K].Pass = '' Then Exit;
  If Plugin = 'caching_sha2_password' Then
  Begin
    MyCachingSha2(K, H2);
    BufAddB(B, @H2, 32);
  End
  Else If Plugin = 'mysql_clear_password' Then
  Begin
    BufAdd(B, DbC[K].Pass);
    BufAddC(B, 0);
  End
  Else
  Begin
    MyNative(K, H);
    BufAddB(B, @H, 20);
  End;
End;

Function MyErrText(P : PBytes; N : LongInt) : String;
Var S : String; I, Code : LongInt;
Begin
  Code := P^[1] Or (P^[2] Shl 8);
  S := '';
  I := 3;
  If (I < N) And (P^[I] = Ord('#')) Then I := I + 6;
  While (I < N) And (Length(S) < 200) Do
  Begin
    S := S + Chr(P^[I]);
    Inc(I);
  End;
  MyErrText := S + ' (' + IStr(Code) + ')';
End;

{ salut du serveur -> reponse d'authentification }
Function MyGreeting(K : LongInt; P : PBytes; N : LongInt) : Boolean;
Var O, I, Caps, AuthLen : LongInt; Plugin : String; B : TBuf; Ver : String;
Begin
  MyGreeting := False;
  If P^[0] = $FF Then
  Begin
    DbC[K].Err := MyErrText(P, N);
    Exit;
  End;
  If P^[0] <> 10 Then
  Begin
    DbC[K].Err := 'protocole MySQL non pris en charge (version ' + IStr(P^[0]) + ')';
    Exit;
  End;
  O := 1; Ver := '';
  While (O < N) And (P^[O] <> 0) Do
  Begin
    Ver := Ver + Chr(P^[O]);
    Inc(O);
  End;
  O := O + 1 + 4;
  For I := 0 To 7 Do DbC[K].Scramble[I] := P^[O + I];
  O := O + 9;
  Caps := P^[O] Or (P^[O + 1] Shl 8);
  O := O + 2 + 1 + 2;
  Caps := Caps Or (P^[O] Shl 16) Or (P^[O + 1] Shl 24);
  O := O + 2;
  AuthLen := P^[O];
  O := O + 1 + 10;
  For I := 0 To 11 Do If O + I < N Then DbC[K].Scramble[8 + I] := P^[O + I];
  O := O + 13;
  If AuthLen > 21 Then O := O + AuthLen - 21;
  Plugin := '';
  While (O < N) And (P^[O] <> 0) Do
  Begin
    Plugin := Plugin + Chr(P^[O]);
    Inc(O);
  End;
  If Plugin = '' Then Plugin := 'mysql_native_password';
  { reponse : CLIENT_LONG_PASSWORD, FOUND_ROWS, CONNECT_WITH_DB, PROTOCOL_41, TRANSACTIONS,
    SECURE_CONNECTION, PLUGIN_AUTH }
  BufInit(B);
  Caps := 1 Or 2 Or 8 Or $200 Or $2000 Or $8000 Or $80000;   { + FOUND_ROWS : lignes trouvees }
  BufAddC(B, Caps And 255); BufAddC(B, Sr(Caps, 8) And 255); BufAddC(B, Sr(Caps, 16) And 255); BufAddC(B, 0);
  BufAddC(B, 0); BufAddC(B, 0); BufAddC(B, 0); BufAddC(B, 1);       { paquet de 16 Mo au plus }
  BufAddC(B, 45);                                                    { utf8mb4 }
  For I := 1 To 23 Do BufAddC(B, 0);
  BufAddZ(B, DbC[K].User);
  I := B.Len;
  BufAddC(B, 0);
  MyAuthData(K, Plugin, B);
  B.P^[I] := B.Len - I - 1;
  BufAddZ(B, DbC[K].Db);
  BufAddZ(B, Plugin);
  MyGreeting := MySend(K, B);
  BufFree(B);
End;

{ avancer : 1 fini, 0 a suivre, -1 erreur }
Function MyStep(K : LongInt) : LongInt;
Var L, O, I, J, N, V, Rs, Ty : LongInt; P : PBytes; S, Plugin : String; B : TBuf;
Begin
  MyStep := 0;
  If Not DbFill(K) Then
  Begin
    MyStep := -1;
    Exit;
  End;
  With DbC[K] Do
    While Rx.Len >= 4 Do
    Begin
      L := Rx.P^[0] Or (Rx.P^[1] Shl 8) Or (Rx.P^[2] Shl 16);
      If Rx.Len < L + 4 Then Exit;
      Seq := Rx.P^[3] + 1;
      P := @Rx.P^[4];
      Case Phase Of
        1 :   { salut }
          Begin
            If Not MyGreeting(K, P, L) Then
            Begin
              MyStep := -1;
              Exit;
            End;
            Phase := 2;
          End;
        2 :   { resultat de l'authentification }
          If P^[0] = 0 Then
          Begin
            DbEat(K, L + 4);
            St := dsReady;
            MyStep := 1;
            Exit;
          End
          Else If P^[0] = $FF Then
          Begin
            Err := MyErrText(P, L);
            MyStep := -1;
            Exit;
          End
          Else If P^[0] = $FE Then
          Begin
            { changement de methode : nom, nouveau brouillage }
            O := 1; Plugin := '';
            While (O < L) And (P^[O] <> 0) Do
            Begin
              Plugin := Plugin + Chr(P^[O]);
              Inc(O);
            End;
            Inc(O);
            For I := 0 To 19 Do If O + I < L Then Scramble[I] := P^[O + I];
            BufInit(B);
            MyAuthData(K, Plugin, B);
            Dummy := Ord(MySend(K, B));
            BufFree(B);
          End
          Else If P^[0] = 1 Then
          Begin
            { caching_sha2_password : 3 = chemin rapide reussi, 4 = authentification complete }
            If (L >= 2) And (P^[1] = 4) Then
            Begin
              Err := 'caching_sha2_password : authentification compl'#138'te impossible sans TLS ' +
                     '(cr'#130'ez l''utilisateur avec mysql_native_password)';
              MyStep := -1;
              Exit;
            End;
          End;
        10 :  { premiere reponse a une requete }
          If P^[0] = 0 Then
          Begin
            O := 1;
            Affected := LenEnc(P, O);
            InsId := LenEnc(P, O);
            DbEat(K, L + 4);
            St := dsReady;
            MyStep := 1;
            Exit;
          End
          Else If P^[0] = $FF Then
          Begin
            Err := MyErrText(P, L);
            DbEat(K, L + 4);
            St := dsReady;
            MyStep := -1;
            Exit;
          End
          Else
          Begin
            O := 0;
            NCol := LenEnc(P, O);
            ColDone := 0;
            If QRs >= 0 Then
            Begin
              If NCol > MaxRsCol Then Rss[QRs].NCol := MaxRsCol Else Rss[QRs].NCol := NCol;
            End;
            If NCol <= 0 Then Phase := 13 Else Phase := 11;
          End;
        11 :  { definitions des colonnes }
          Begin
            If (P^[0] = $FE) And (L < 9) Then Phase := 13
            Else
            Begin
              O := 0;
              For J := 1 To 4 Do
              Begin
                N := LenEnc(P, O);
                If N > 0 Then O := O + N;
              End;
              N := LenEnc(P, O);
              S := '';
              For I := 0 To N - 1 Do If Length(S) < 63 Then S := S + Chr(P^[O + I]);
              If N > 0 Then O := O + N;
              N := LenEnc(P, O);
              If N > 0 Then O := O + N;
              O := O + 1 + 2 + 4;
              Ty := P^[O];
              If (QRs >= 0) And (ColDone < Rss[QRs].NCol) Then
              Begin
                Rss[QRs].ColNm[ColDone] := S;
                Case Ty Of
                  1, 2, 3, 8, 9, 13 : Rss[QRs].ColTy[ColDone] := 1;
                  4, 5 : Rss[QRs].ColTy[ColDone] := 2;
                Else
                  Rss[QRs].ColTy[ColDone] := 0;
                End;
              End;
              Inc(ColDone);
              If ColDone >= NCol Then Phase := 12;
            End;
          End;
        12 :  { EOF apres les colonnes (ou deja une ligne) }
          If (P^[0] = $FE) And (L < 9) Then Phase := 13
          Else
          Begin
            Phase := 13;
            Continue;      { la ligne est traitee au tour suivant }
          End;
        13 :  { lignes, puis EOF }
          If (P^[0] = $FE) And (L < 9) Then
          Begin
            DbEat(K, L + 4);
            St := dsReady;
            If QRs >= 0 Then Rss[QRs].Affected := Rss[QRs].NRow;
            Affected := 0;
            MyStep := 1;
            Exit;
          End
          Else If P^[0] = $FF Then
          Begin
            Err := MyErrText(P, L);
            DbEat(K, L + 4);
            St := dsReady;
            MyStep := -1;
            Exit;
          End
          Else If QRs >= 0 Then
          Begin
            Rs := QRs;
            O := 0;
            For J := 0 To NCol - 1 Do
            Begin
              If O >= L Then V := -1
              Else If P^[O] = $FB Then
              Begin
                V := -1; Inc(O);
              End
              Else V := LenEnc(P, O);
              If J < Rss[Rs].NCol Then
              Begin
                If V < 0 Then RsAddVal(Rs, Nil, -1) Else RsAddVal(Rs, @P^[O], V);
              End;
              If V > 0 Then O := O + V;
            End;
            Inc(Rss[Rs].NRow);
          End;
      End;
      DbEat(K, L + 4);
    End;
End;

Function MyQuery(K : LongInt; Var Sql : TBuf) : Boolean;
Var B : TBuf;
Begin
  DbC[K].Seq := 0;
  DbC[K].Phase := 10;
  BufInit(B);
  BufAddC(B, 3);
  BufAddB(B, Sql.P, Sql.Len);
  MyQuery := MySend(K, B);
  BufFree(B);
End;

{ ==================================================================== }
{ Operations (avec attente) pour la machine des pages                  }
{ ==================================================================== }

Function DbStep(K : LongInt) : LongInt;
Begin
  If DbC[K].Kind = dbPg Then DbStep := PgStep(K) Else DbStep := MyStep(K);
End;

Function DbName(K : LongInt) : String;
Begin
  If DbC[K].Kind = dbPg Then DbName := 'PostgreSQL' Else DbName := 'MariaDB';
End;

{ l'operation en cours de la connexion K : fini (1), a suivre (0, la page
  attend), erreur (-1 : la connexion est fermee si elle est inutilisable) }
Function DbWait(K : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := DbStep(K);
  If (R = 0) And (PTicks - DbC[K].Deadline > 0) Then
  Begin
    DbC[K].Err := 'pas de r'#130'ponse du serveur (d'#130'lai d'#130'pass'#130')';
    R := -1;
    DbC[K].St := dsBusy;
  End;
  If R = 0 Then
  Begin
    DbPend := K;
    DbWaitSock := DbC[K].Sock;
    VmWait := True;
  End
  Else
  Begin
    DbPend := -1;
    DbWaitSock := -1;
    VmWait := False;
  End;
  DbWait := R;
End;

Procedure DbFailK(K : LongInt; What : String);
Begin
  VmFail(DbName(K) + ' : ' + What + DbC[K].Err);
  If DbC[K].St <> dsReady Then DbClose(K);
End;

{ Database.Connect(chaine) : rend le numero de la connexion (-1 : erreur
  ou attente) }
Function DbConnect(Var S : String) : LongInt;
Var K, Ip, T : LongInt;
Begin
  DbConnect := -1;
  { reprise d'une connexion en cours }
  If (DbPend >= 0) And DbC[DbPend].Used And (DbC[DbPend].St = dsHandshake) Then
  Begin
    K := DbPend;
    T := DbWait(K);
    If T = 1 Then DbConnect := K
    Else If T < 0 Then DbFailK(K, 'connexion impossible : ');
    Exit;
  End;
  { une connexion libre de la reserve, meme chaine }
  For K := 0 To MaxDbConn - 1 Do
    If DbC[K].Used And Not DbC[K].Owned And (DbC[K].St = dsReady) And (DbC[K].Key = S) Then
    Begin
      DbC[K].Owned := True;
      DbConnect := K;
      Exit;
    End;
  K := -1;
  For T := 0 To MaxDbConn - 1 Do If (K < 0) And Not DbC[T].Used Then K := T;
  If K < 0 Then
  Begin
    { reserve pleine : fermer la plus ancienne connexion libre }
    For T := 0 To MaxDbConn - 1 Do
      If (K < 0) And Not DbC[T].Owned Then K := T;
    If K < 0 Then
    Begin
      VmFail('base de donn'#130'es : trop de connexions ouvertes (' + IStr(MaxDbConn) + ')');
      Exit;
    End;
    DbClose(K);
  End;
  FillChar(DbC[K], SizeOf(TDbConn), 0);
  DbC[K].Sock := -1; DbC[K].QRs := -1;
  If Not ConnParse(K, S) Then
  Begin
    VmFail('base de donn'#130'es : ' + DbC[K].Err);
    Exit;
  End;
  DbC[K].Used := True; DbC[K].Owned := True; DbC[K].Key := S;
  BufInit(DbC[K].Rx);
  Ip := PResolve(DbC[K].Host);
  If Ip = 0 Then
  Begin
    DbC[K].Err := 'h'#147'te inconnu : ' + DbC[K].Host;
    DbFailK(K, '');
    Exit;
  End;
  DbC[K].Sock := PConnect(Ip, DbC[K].DbPort);
  If DbC[K].Sock < 0 Then
  Begin
    DbC[K].Err := 'connexion refus'#130'e par ' + DbC[K].Host + ':' + IStr(DbC[K].DbPort);
    DbFailK(K, '');
    Exit;
  End;
  DbC[K].St := dsHandshake;
  DbC[K].Deadline := PTicks + 15000;
  If DbC[K].Kind = dbPg Then
  Begin
    If Not PgStart(K) Then
    Begin
      DbFailK(K, '');
      Exit;
    End;
  End
  Else DbC[K].Phase := 1;
  T := DbWait(K);
  If T = 1 Then DbConnect := K
  Else If T < 0 Then DbFailK(K, 'connexion impossible : ');
End;

{ requete : rend le jeu d'enregistrements (>= 0), ou -1 (erreur, ou
  attente : VmWait) ; Rows : lignes touchees }
Function DbQuery(K : LongInt; Var Sql : TBuf; Var Rows : LongInt) : LongInt;
Var T, Rs : LongInt;
Begin
  DbQuery := -1;
  Rows := 0;
  If (K < 0) Or (K >= MaxDbConn) Or Not DbC[K].Used Or Not DbC[K].Owned Then
  Begin
    VmFail('base de donn'#130'es : connexion ferm'#130'e');
    Exit;
  End;
  If Not ((DbPend = K) And (DbC[K].St = dsBusy)) Then
  Begin
    If DbC[K].St <> dsReady Then
    Begin
      VmFail(DbName(K) + ' : connexion occup'#130'e ou ferm'#130'e');
      Exit;
    End;
    Rs := RsNew;
    If Rs < 0 Then
    Begin
      VmFail('base de donn'#130'es : trop de jeux d''enregistrements ouverts (' + IStr(MaxRs) + ')');
      Exit;
    End;
    DbC[K].QRs := Rs; DbC[K].QErr := ''; DbC[K].QHaveT := False; DbC[K].Affected := 0; DbC[K].InsId := 0; DbC[K].Err := '';
    DbC[K].St := dsBusy;
    DbC[K].Deadline := PTicks + 60000;
    If DbC[K].Kind = dbPg Then T := Ord(PgQuery(K, Sql)) Else T := Ord(MyQuery(K, Sql));
    If T = 0 Then
    Begin
      RsFree(Rs);
      DbFailK(K, '');
      Exit;
    End;
  End;
  T := DbWait(K);
  If T = 0 Then Exit;
  Rs := DbC[K].QRs;
  DbC[K].QRs := -1;
  If T < 0 Then
  Begin
    RsFree(Rs);
    DbFailK(K, '');
    Exit;
  End;
  Rows := DbC[K].Affected;
  If (Rows = 0) And (Rs >= 0) Then Rows := Rss[Rs].NRow;
  Rss[Rs].Affected := Rows;
  DbQuery := Rs;
End;

{ debut et fin d'une requete HTTP : connexions rendues a la reserve }
Procedure DbEndRequest;
Var K : LongInt;
Begin
  For K := 0 To MaxDbConn - 1 Do
    If DbC[K].Used And DbC[K].Owned Then
    Begin
      If DbC[K].St = dsReady Then
      Begin
        DbC[K].Owned := False;
        DbC[K].LastUse := PTicks;
      End
      Else DbClose(K);
    End;
  For K := 0 To MaxRs - 1 Do RsFree(K);
  DbPend := -1; DbWaitSock := -1; VmWait := False;
End;

{ reserve : connexions libres depuis plus d'une minute fermees }
Procedure DbHouse;
Var K : LongInt;
Begin
  For K := 0 To MaxDbConn - 1 Do
    If DbC[K].Used And Not DbC[K].Owned And (PTicks - DbC[K].LastUse > 60000) Then DbClose(K);
End;

Procedure DbInit;
Var K : LongInt;
Begin
  For K := 0 To MaxDbConn - 1 Do
  Begin
    DbC[K].Used := False; DbC[K].Sock := -1;
  End;
  For K := 0 To MaxRs - 1 Do Rss[K].Used := False;
  DbPend := -1; DbWaitSock := -1; VmWait := False;
End;

{ 'texte' entre apostrophes doublees (litteral SQL) }
Procedure SqlQuote(Var C : TCell; Var R : TCell; Kind : LongInt);
Var T : TCell; P : PBytes; B : TBuf; K : LongInt;
Begin
  CellToStr(C, T);
  P := PoolPtr(T);
  BufInit(B);
  BufAddC(B, 39);
  For K := 0 To T.L - 1 Do
  Begin
    If P^[K] = 39 Then BufAddC(B, 39);
    If (P^[K] = 92) And (Kind = dbMy) Then BufAddC(B, 92);    { (MariaDB : barre oblique inverse) }
    BufAddC(B, P^[K]);
  End;
  BufAddC(B, 39);
  MkStrB(B.P, B.Len, R);
  BufFree(B);
End;

{ --- membres des objets : Database, connexion, jeu d'enregistrements,
  champs --- }

Procedure CellBuf(Var C : TCell; Var B : TBuf);
Var T : TCell;
Begin
  CellToStr(C, T);
  If T.L > 0 Then BufAddB(B, PoolPtr(T), T.L);
End;

Procedure DbRelease(K : LongInt);
Begin
  If (K < 0) Or (K >= MaxDbConn) Or Not DbC[K].Used Then Exit;
  If DbC[K].St = dsReady Then
  Begin
    DbC[K].Owned := False;
    DbC[K].LastUse := PTicks;
  End
  Else DbClose(K);
End;

{ requete sur la connexion K ; Exec : Execute (nombre de lignes si la
  requete ne rend pas de colonnes) }
Procedure DbRun(K : LongInt; Var Sql : TCell; Exec : Boolean; Var R : TCell);
Var B : TBuf; Rs, Rows : LongInt;
Begin
  BufInit(B);
  CellBuf(Sql, B);
  Rs := DbQuery(K, B, Rows);
  BufFree(B);
  If Rs < 0 Then Exit;
  If Exec And (Rss[Rs].NCol = 0) Then
  Begin
    MkInt(Rows, R);
    RsFree(Rs);
  End
  Else MkObj(ObjNew(okDbRs, Rs, 0), R);
End;

Procedure DbMember(Id, M, Argc, ABase : LongInt; Var R : TCell; IsSet : Boolean; Var V : TCell);
Var A0, A1 : TCell; K, Rs, C : LongInt; S : String;
Begin
  If Argc > 0 Then A0 := Stk[ABase] Else MkNil(A0);
  If Argc > 1 Then A1 := Stk[ABase + 1] Else MkNil(A1);
  If (A0.T = vtObj) And (A0.I < NObj) And (ObjK[A0.I] = okItem) Then ObjValue(A0);
  Case ObjK[Id] Of
    okDbF :
      Case M Of
        mConnect, mOpen :
          Begin
            S := CellPStr(A0);
            K := DbConnect(S);
            If K >= 0 Then MkObj(ObjNew(okDbConn, K, 0), R);
          End;
        mQuote : SqlQuote(A0, R, 0);
      Else
        VmFail('Database.' + MemberNames[M] + ' inconnu');
      End;
    okDbConn :
      Begin
        K := ObjA[Id];
        Case M Of
          mOpen :
            Begin
              S := CellPStr(A0);
              K := DbConnect(S);
              If K >= 0 Then ObjA[Id] := K;
            End;
          mQuery, mExecute :
            If K < 0 Then VmFail('base de donn'#130'es : connexion non ouverte')
            Else DbRun(K, A0, M = mExecute, R);
          mClose :
            Begin
              DbRelease(K);
              ObjA[Id] := -1;
            End;
          mConnected, mState :
            If M = mState Then MkInt(Ord((K >= 0) And DbC[K].Used), R)
            Else MkBool((K >= 0) And DbC[K].Used And (DbC[K].St = dsReady), R);
          mQuote :
            If K >= 0 Then SqlQuote(A0, R, DbC[K].Kind) Else SqlQuote(A0, R, 0);
        Else
          VmFail('Connexion.' + MemberNames[M] + ' inconnu');
        End;
      End;
    okDbRs :
      Begin
        Rs := ObjA[Id];
        If (M = mOpen) And (Rs < 0) Then
        Begin
          { ADODB.Recordset : Rs.Open sql, connexion }
          If (A1.T = vtObj) And (A1.I < NObj) And (ObjK[A1.I] = okDbConn) And (ObjA[A1.I] >= 0) Then
          Begin
            DbRun(ObjA[A1.I], A0, False, R);
            If (R.T = vtObj) And (R.I < NObj) And (ObjK[R.I] = okDbRs) Then ObjA[Id] := ObjA[R.I];
            MkNil(R);
          End
          Else VmFail('Recordset.Open : connexion attendue');
          Exit;
        End;
        If (Rs < 0) Or (Rs >= MaxRs) Or Not Rss[Rs].Used Then
        Begin
          If M = mClose Then Exit;
          VmFail('jeu d''enregistrements ferm'#130);
          Exit;
        End;
        Case M Of
          mEof : MkBool(Rss[Rs].Cur >= Rss[Rs].NRow, R);
          mBof : MkBool((Rss[Rs].Cur < 0) Or (Rss[Rs].NRow = 0), R);
          mNext, mMoveNext : If Rss[Rs].Cur < Rss[Rs].NRow Then Inc(Rss[Rs].Cur);
          mMoveFirst : Rss[Rs].Cur := 0;
          mClose :
            Begin
              RsFree(Rs);
              ObjA[Id] := -1;
            End;
          mRecordCount, mCount : MkInt(Rss[Rs].NRow, R);
          mFieldCount : MkInt(Rss[Rs].NCol, R);
          mRowsAffected : MkInt(Rss[Rs].Affected, R);
          mFieldName :
            Begin
              C := CellInt(A0);
              If (C >= 0) And (C < Rss[Rs].NCol) Then MkStr(Rss[Rs].ColNm[C], R) Else MkStr('', R);
            End;
          mFields :
            If Argc = 0 Then MkObj(ObjNew(okDbFlds, Rs, 0), R)
            Else
            Begin
              C := RsCol(Rs, A0);
              If C < 0 Then VmFail('colonne inconnue : ' + CellPStr(A0))
              Else MkObj(ObjNew(okDbFld, Rs, C), R);
            End;
          mDefault, mItem, mValue :
            Begin
              C := RsCol(Rs, A0);
              If C < 0 Then VmFail('colonne inconnue : ' + CellPStr(A0))
              Else RsValue(Rs, C, R);
            End;
        Else
          VmFail('Recordset.' + MemberNames[M] + ' inconnu');
        End;
      End;
    okDbFlds :
      Begin
        Rs := ObjA[Id];
        If (Rs < 0) Or Not Rss[Rs].Used Then
        Begin
          VmFail('jeu d''enregistrements ferm'#130);
          Exit;
        End;
        Case M Of
          mCount : MkInt(Rss[Rs].NCol, R);
          mDefault, mItem :
            Begin
              C := RsCol(Rs, A0);
              If C < 0 Then VmFail('colonne inconnue : ' + CellPStr(A0))
              Else MkObj(ObjNew(okDbFld, Rs, C), R);
            End;
        Else
          VmFail('Fields.' + MemberNames[M] + ' inconnu');
        End;
      End;
    okDbFld :
      Begin
        Rs := ObjA[Id]; C := ObjB[Id];
        If (Rs < 0) Or Not Rss[Rs].Used Then
        Begin
          VmFail('jeu d''enregistrements ferm'#130);
          Exit;
        End;
        Case M Of
          mName : MkStr(Rss[Rs].ColNm[C], R);
          mValue, mDefault : RsValue(Rs, C, R);
        Else
          VmFail('Field.' + MemberNames[M] + ' inconnu');
        End;
      End;
  End;
End;

{ WEBSRV /DBTEST : MD5, SHA-1, PBKDF2 et SCRAM-SHA-256 (vecteur de la
  RFC 7677 : utilisateur "user", mot de passe "pencil") }
Procedure DbSelfTest;
Var D : TBlk; H : TB20; S, Sf, Auth, Fin : String; Ck, Sk, Sig, Pr, Salted : TB32; I : LongInt;
Begin
  S := 'abc';
  Md5(@S[1], 3, D); WriteLn('MD5 abc = ', HexBytes(@D, 16));
  Sha1(@S[1], 3, H); WriteLn('SHA1 abc = ', HexBytes(@H, 20));
  Sf := 'r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,s=W22ZaJ0SNY7soEsUEjb6gQ==,i=4096';
  Pbkdf2('pencil', B64DecStr(ScramAttr(Sf, 's')), 4096, Salted);
  HmacStr(Salted, 'Client Key', Ck);
  Sha256(@Ck, 32, Sk);
  Fin := 'c=biws,r=' + ScramAttr(Sf, 'r');
  Auth := 'n=user,r=rOprNGfwEbeRWgbNEkqO,' + Sf + ',' + Fin;
  HmacStr(Sk, Auth, Sig);
  For I := 0 To 31 Do Pr[I] := Ck[I] Xor Sig[I];
  WriteLn('SCRAM p = ', B64Bytes(@Pr, 32));
End;
{ ==================================================================== }
{ Compilateur PSP (Pascal Server Pages) : le Pascal de PSP86/PSPCW32     }
{ (DEV-COOLS) entre les balises <% %>, <%= %>, <%@ %>, <%-- --%>, et      }
{ <!--#include file|virtual="..." -->. Declarations et instructions      }
{ peuvent se melanger au niveau de la page (comme les compilateurs PSP). }
{ ==================================================================== }

Const
  { lexemes }
  tkEof = 0; tkId = 1; tkInt = 2; tkReal = 3; tkStr = 4; tkSym = 5; tkHtml = 6; tkEcho = 7; tkEchoEnd = 8;
  { types predefinis }
  TyInt = 0; TyReal = 1; TyBool = 2; TyChar = 3; TyStr = 4; TyVar = 5;
  { genres de types }
  ykInt = 0; ykReal = 1; ykBool = 2; ykChar = 3; ykStr = 4; ykVar = 5; ykEnum = 6; ykArray = 7; ykRec = 8;
  ykSet = 9; ykPtr = 10;
  { genres de symboles }
  skConst = 1; skVar = 2; skType = 3; skProc = 4; skFunc = 5; skObj = 6;
  MaxSym = 2048; MaxTy = 512; MaxFld = 1024; MaxPar = 1024;
  { designateurs }
  dkNone = 0; dkVar = 1; dkAddr = 2; dkValue = 3; dkStrIdx = 4; dkMember = 5;

Type
  TSym = Record
    Name : String[31];
    Kind, Lvl : Byte;
    Ty, Adr : LongInt;
    Ref : Boolean;
    CV : TCell;
    NPar, PBase, RetTy, Patch : LongInt;   { procedures }
  End;
  TTy = Record
    Kind : Byte;
    Size, Lo, Hi, Elem, FBase, FCount : LongInt;
  End;
  TDes = Record
    Kind : LongInt;
    Ty : LongInt;
    Mode : LongInt;          { 0 global, 1 local, 2 cadre englobant }
    Up : LongInt;            { niveaux a remonter }
    Adr : LongInt;
    Ref : Boolean;
    Mem, Argc : LongInt;     { membre en attente }
  End;

Var
  Syms : Array[0..MaxSym - 1] Of TSym;
  NSym : LongInt;
  Tys : Array[0..MaxTy - 1] Of TTy;
  NTy : LongInt;
  FName : Array[0..MaxFld - 1] Of String[31];
  FTy, FOff : Array[0..MaxFld - 1] Of LongInt;
  NFld : LongInt;
  PTy : Array[0..MaxPar - 1] Of LongInt;
  PRef : Array[0..MaxPar - 1] Of Boolean;
  PName : Array[0..MaxPar - 1] Of String[31];
  NParT : LongInt;
  { source }
  Src : TBuf;
  SPos, SLine : LongInt;
  InHtml, InEcho : Boolean;
  SrcDir, SiteRoot : String[127];
  Defines : String;
  { lexeme courant }
  Tok : LongInt;
  TokS : String;             { identificateur (majuscules), symbole, chaine }
  TokI : LongInt;
  TokR : Double;
  TokOff, TokLen : LongInt;  { fragment HTML ; chaine longue }
  TokLine : LongInt;
  CErr : String;
  CErrLine : LongInt;
  { compilation }
  CP : LongInt;              { page en cours de compilation }
  CurLvl : LongInt;          { niveau d'imbrication (0 : page) }
  LocTop : LongInt;          { prochaine cellule locale }
  LocMax : LongInt;
  GlobTop : LongInt;
  CurFunc : LongInt;         { symbole de la fonction compilee (-1) }
  ExitList, BreakList, ContList : Array[0..63] Of LongInt;
  NExit, LoopDepth : LongInt;
  BreakChain, ContChain : Array[0..31] Of LongInt;
  WithAdr, WithTy, WithMode : Array[0..7] Of LongInt;
  NWith : LongInt;
  TmpCount : LongInt;
  LastHtml : Boolean;

Procedure CError(S : String);
Begin
  If CErr = '' Then
  Begin
    CErr := S;
    CErrLine := TokLine;
  End;
  Tok := tkEof;
End;

{ --- code --- }

Procedure Emit(V : LongInt);
Var Q : PLongs; N : LongInt;
Begin
  With Pages[CP] Do
  Begin
    If NCode >= CodeCap Then
    Begin
      N := CodeCap * 2;
      If N < 4096 Then N := 4096;
      GetMem(Q, N * 4);
      If NCode > 0 Then Move(Code^[0], Q^[0], NCode * 4);
      If Code <> Nil Then FreeMem(Code, CodeCap * 4);
      Code := Q; CodeCap := N;
    End;
    Code^[NCode] := V;
    Inc(NCode);
  End;
End;

Procedure Emit1(Op, A : LongInt);
Begin
  Emit(Op); Emit(A);
End;

Procedure Emit2(Op, A, B : LongInt);
Begin
  Emit(Op); Emit(A); Emit(B);
End;

Function Here : LongInt;
Begin
  Here := Pages[CP].NCode;
End;

Procedure PatchAt(At, V : LongInt);
Begin
  Pages[CP].Code^[At] := V;
End;

{ ligne du source pour les messages d'erreur }
Procedure EmitLine;
Var Q : PLongs; N : LongInt;
Begin
  With Pages[CP] Do
  Begin
    If (NLine > 0) And (Lines^[NLine * 2 - 1] = TokLine) Then Exit;
    If NLine * 2 + 2 > LineCap Then
    Begin
      N := LineCap * 2;
      If N < 1024 Then N := 1024;
      GetMem(Q, N * 4);
      If NLine > 0 Then Move(Lines^[0], Q^[0], NLine * 8);
      If Lines <> Nil Then FreeMem(Lines, LineCap * 4);
      Lines := Q; LineCap := N;
    End;
    Lines^[NLine * 2] := NCode;
    Lines^[NLine * 2 + 1] := TokLine;
    Inc(NLine);
  End;
End;

Function AddReal(R : Double) : LongInt;
Var Q : PDoubles; N : LongInt;
Begin
  With Pages[CP] Do
  Begin
    If NReal >= RealCap Then
    Begin
      N := RealCap * 2;
      If N < 64 Then N := 64;
      GetMem(Q, N * 8);
      If NReal > 0 Then Move(Reals^[0], Q^[0], NReal * 8);
      If Reals <> Nil Then FreeMem(Reals, RealCap * 8);
      Reals := Q; RealCap := N;
    End;
    Reals^[NReal] := R;
    AddReal := NReal;
    Inc(NReal);
  End;
End;

{ chaine constante : (decalage, longueur) dans Strs }
Function AddStrB(P : PBytes; N : LongInt) : LongInt;
Begin
  AddStrB := Pages[CP].Strs.Len;
  BufAddB(Pages[CP].Strs, P, N);
End;

Function AddStr(Const S : String) : LongInt;
Begin
  AddStr := Pages[CP].Strs.Len;
  BufAdd(Pages[CP].Strs, S);
End;

Procedure EmitStr(Const S : String);
Begin
  Emit2(opPushS, AddStr(S), Length(S));
End;

{ --- source : inclusions du serveur --- }

Function LoadSource(Path : String; Depth : LongInt; Var Out_ : TBuf) : Boolean;
Var B : TBuf; K, E, Q, J : LongInt; Inc_, Dir : String; Virt : Boolean;

  Function Match(At : LongInt; Const S : String) : Boolean;
  Var A : LongInt;
  Begin
    Match := False;
    If At + Length(S) > B.Len Then Exit;
    For A := 1 To Length(S) Do
      If UpCase(Chr(B.P^[At + A - 1])) <> UpCase(S[A]) Then Exit;
    Match := True;
  End;

Begin
  LoadSource := False;
  If Depth > 8 Then Exit;
  If Not ReadFileBuf(Path, B, 4194304) Then Exit;
  Dir := Path;
  While (Length(Dir) > 0) And (Dir[Length(Dir)] <> '\') And (Dir[Length(Dir)] <> '/') Do Delete(Dir, Length(Dir), 1);
  K := 0;
  While K < B.Len Do
  Begin
    If (B.P^[K] = Ord('<')) And Match(K, '<!--#include') Then
    Begin
      E := K + 12;
      While (E < B.Len - 2) And Not Match(E, '-->') Do Inc(E);
      Inc_ := '';
      For J := K + 12 To E - 1 Do If Length(Inc_) < 250 Then Inc_ := Inc_ + Chr(B.P^[J]);
      Virt := Pos('VIRTUAL', UpStr(Inc_)) > 0;
      Q := Pos('"', Inc_);
      If Q > 0 Then
      Begin
        Inc_ := Copy(Inc_, Q + 1, 255);
        Q := Pos('"', Inc_);
        If Q > 0 Then Inc_ := Copy(Inc_, 1, Q - 1);
        For J := 1 To Length(Inc_) Do If Inc_[J] = '/' Then Inc_[J] := '\';
        If Virt Or ((Inc_ <> '') And (Inc_[1] = '\')) Then Inc_ := SiteRoot + '\' + Inc_
        Else Inc_ := Dir + Inc_;
        If (Pos('..\..', Inc_) = 0) And Not LoadSource(Inc_, Depth + 1, Out_) Then
          BufAdd(Out_, '<!-- inclusion introuvable -->');
      End;
      K := E + 3;
    End
    Else
    Begin
      BufAddC(Out_, B.P^[K]);
      Inc(K);
    End;
  End;
  BufFree(B);
  LoadSource := True;
End;

{ --- analyse lexicale --- }

Function SrcCh(K : LongInt) : Char;
Begin
  If K < Src.Len Then SrcCh := Chr(Src.P^[K]) Else SrcCh := #0;
End;

Function IsIdCh(C : Char) : Boolean;
Begin
  IsIdCh := ((C >= 'A') And (C <= 'Z')) Or ((C >= 'a') And (C <= 'z')) Or ((C >= '0') And (C <= '9')) Or (C = '_');
End;

Procedure NextTok; Forward;

{ directive de compilation : $I fichier, $DEFINE, $IFDEF, $IFNDEF, $ELSE, $ENDIF }
Procedure Directive(D : String);
Var U, A : String; P, Depth, K : LongInt; Ins : TBuf; Rest : TBuf;
Begin
  U := UpStr(Trim(D));
  P := Pos(' ', U);
  If P > 0 Then
  Begin
    A := Trim(Copy(Trim(D), P + 1, 255));
    U := Copy(U, 1, P - 1);
  End
  Else A := '';
  If (U = 'I') Or (U = 'INCLUDE') Then
  Begin
    For K := 1 To Length(A) Do If A[K] = '/' Then A[K] := '\';
    If (Length(A) < 2) Or (A[2] <> ':') Then A := SrcDir + A;
    BufInit(Ins);
    If ReadFileBuf(A, Ins, 1048576) Then
    Begin
      { le fichier inclus prend la place de la directive }
      BufInit(Rest);
      BufAddB(Rest, @Src.P^[SPos], Src.Len - SPos);
      Src.Len := SPos;
      BufAddB(Src, Ins.P, Ins.Len);
      BufAddB(Src, Rest.P, Rest.Len);
      BufFree(Rest);
    End
    Else
    Begin
      { chemin de l'exemple (dossier\fichier) : essai a cote de la page }
      K := Length(A);
      While (K > 0) And (A[K] <> '\') Do Dec(K);
      If ReadFileBuf(SrcDir + Copy(A, K + 1, 255), Ins, 1048576) Then
      Begin
        BufInit(Rest);
        BufAddB(Rest, @Src.P^[SPos], Src.Len - SPos);
        Src.Len := SPos;
        BufAddB(Src, Ins.P, Ins.Len);
        BufAddB(Src, Rest.P, Rest.Len);
        BufFree(Rest);
      End
      Else CError('fichier inclus introuvable : ' + A);
    End;
    BufFree(Ins);
  End
  Else If U = 'DEFINE' Then Defines := Defines + '|' + UpStr(A) + '|'
  Else If U = 'UNDEF' Then
  Begin
    P := Pos('|' + UpStr(A) + '|', Defines);
    If P > 0 Then Delete(Defines, P, Length(A) + 2);
  End
  Else If (U = 'IFDEF') Or (U = 'IFNDEF') Or (U = 'ELSE') Then
  Begin
    If U = 'ELSE' Then P := 0
    Else
    Begin
      P := Ord(Pos('|' + UpStr(A) + '|', Defines) > 0);
      If U = 'IFNDEF' Then P := 1 - P;
    End;
    If P = 0 Then
    Begin
      { sauter jusqu'au $ELSE ou $ENDIF correspondant }
      Depth := 0;
      While SPos < Src.Len Do
      Begin
        If (SrcCh(SPos) = '{') And (SrcCh(SPos + 1) = '$') Then
        Begin
          A := '';
          K := SPos + 2;
          While (K < Src.Len) And (SrcCh(K) <> '}') Do
          Begin
            If Length(A) < 40 Then A := A + UpCase(SrcCh(K));
            Inc(K);
          End;
          SPos := K + 1;
          If (Copy(A, 1, 5) = 'IFDEF') Or (Copy(A, 1, 6) = 'IFNDEF') Then Inc(Depth)
          Else If Copy(A, 1, 5) = 'ENDIF' Then
          Begin
            If Depth = 0 Then Exit;
            Dec(Depth);
          End
          Else If (Copy(A, 1, 4) = 'ELSE') And (Depth = 0) And (U <> 'ELSE') Then Exit;
        End
        Else
        Begin
          If SrcCh(SPos) = #10 Then Inc(SLine);
          Inc(SPos);
        End;
      End;
    End;
  End;
  { $ENDIF, $R, $H... : rien }
End;

Procedure NextTok;
Var C : Char; K, St, N, V : LongInt; S : String; Done_ : Boolean; Lit : TBuf;
Begin
  If CErr <> '' Then
  Begin
    Tok := tkEof;
    Exit;
  End;
  Repeat
    Done_ := True;
    TokLine := SLine;
    If SPos >= Src.Len Then
    Begin
      Tok := tkEof;
      Exit;
    End;
    If InHtml Then
    Begin
      St := SPos;
      While (SPos < Src.Len) And Not ((SrcCh(SPos) = '<') And (SrcCh(SPos + 1) = '%')) Do
      Begin
        If SrcCh(SPos) = #10 Then Inc(SLine);
        Inc(SPos);
      End;
      If SPos > St Then
      Begin
        Tok := tkHtml; TokOff := St; TokLen := SPos - St;
        Exit;
      End;
      If SPos >= Src.Len Then
      Begin
        Tok := tkEof;
        Exit;
      End;
      { <% }
      SPos := SPos + 2;
      InHtml := False;
      If SrcCh(SPos) = '=' Then
      Begin
        Inc(SPos);
        InEcho := True;
        Tok := tkEcho;
        Exit;
      End;
      If SrcCh(SPos) = '@' Then
      Begin
        { directive de page : sautee }
        While (SPos < Src.Len) And Not ((SrcCh(SPos) = '%') And (SrcCh(SPos + 1) = '>')) Do
        Begin
          If SrcCh(SPos) = #10 Then Inc(SLine);
          Inc(SPos);
        End;
        SPos := SPos + 2;
        InHtml := True;
        { saut de ligne apres la directive : omis }
        If SrcCh(SPos) = #13 Then Inc(SPos);
        If SrcCh(SPos) = #10 Then
        Begin
          Inc(SPos); Inc(SLine);
        End;
        Done_ := False;
        Continue;
      End;
      If (SrcCh(SPos) = '-') And (SrcCh(SPos + 1) = '-') Then
      Begin
        While (SPos < Src.Len) And Not ((SrcCh(SPos) = '-') And (SrcCh(SPos + 1) = '-') And (SrcCh(SPos + 2) = '%') And
              (SrcCh(SPos + 3) = '>')) Do
        Begin
          If SrcCh(SPos) = #10 Then Inc(SLine);
          Inc(SPos);
        End;
        SPos := SPos + 4;
        InHtml := True;
        Done_ := False;
        Continue;
      End;
    End;
    { code : blancs et commentaires }
    C := SrcCh(SPos);
    If (C = ' ') Or (C = #9) Or (C = #13) Or (C = #10) Then
    Begin
      If C = #10 Then Inc(SLine);
      Inc(SPos);
      Done_ := False;
      Continue;
    End;
    If (C = '%') And (SrcCh(SPos + 1) = '>') Then
    Begin
      SPos := SPos + 2;
      InHtml := True;
      If InEcho Then
      Begin
        InEcho := False;
        Tok := tkEchoEnd;
        Exit;
      End;
      { fin d'un bloc : separateur d'instructions }
      Tok := tkSym; TokS := ';';
      { le saut de ligne qui suit %> n'est pas envoye s'il termine la ligne }
      Exit;
    End;
    If C = '{' Then
    Begin
      If SrcCh(SPos + 1) = '$' Then
      Begin
        S := '';
        K := SPos + 2;
        While (K < Src.Len) And (SrcCh(K) <> '}') Do
        Begin
          If Length(S) < 250 Then S := S + SrcCh(K);
          Inc(K);
        End;
        SPos := K + 1;
        Directive(S);
      End
      Else
      Begin
        While (SPos < Src.Len) And (SrcCh(SPos) <> '}') Do
        Begin
          If SrcCh(SPos) = #10 Then Inc(SLine);
          Inc(SPos);
        End;
        Inc(SPos);
      End;
      Done_ := False;
      Continue;
    End;
    If (C = '(') And (SrcCh(SPos + 1) = '*') Then
    Begin
      SPos := SPos + 2;
      While (SPos < Src.Len) And Not ((SrcCh(SPos) = '*') And (SrcCh(SPos + 1) = ')')) Do
      Begin
        If SrcCh(SPos) = #10 Then Inc(SLine);
        Inc(SPos);
      End;
      SPos := SPos + 2;
      Done_ := False;
      Continue;
    End;
    If (C = '/') And (SrcCh(SPos + 1) = '/') Then
    Begin
      While (SPos < Src.Len) And (SrcCh(SPos) <> #10) And Not ((SrcCh(SPos) = '%') And (SrcCh(SPos + 1) = '>')) Do
        Inc(SPos);
      Done_ := False;
      Continue;
    End;
  Until Done_;
  TokLine := SLine;
  C := SrcCh(SPos);
  If IsIdCh(C) And Not ((C >= '0') And (C <= '9')) Then
  Begin
    S := '';
    While IsIdCh(SrcCh(SPos)) Do
    Begin
      If Length(S) < 31 Then S := S + UpCase(SrcCh(SPos));
      Inc(SPos);
    End;
    Tok := tkId; TokS := S;
    Exit;
  End;
  If ((C >= '0') And (C <= '9')) Or (C = '$') Or ((C = '%') And ((SrcCh(SPos + 1) = '0') Or (SrcCh(SPos + 1) = '1'))) Then
  Begin
    If C = '$' Then
    Begin
      Inc(SPos);
      V := 0;
      While (UpCase(SrcCh(SPos)) In ['0'..'9', 'A'..'F']) Do
      Begin
        C := UpCase(SrcCh(SPos));
        If C <= '9' Then V := V * 16 + Ord(C) - 48 Else V := V * 16 + Ord(C) - 55;
        Inc(SPos);
      End;
      Tok := tkInt; TokI := V;
      Exit;
    End;
    If C = '%' Then
    Begin
      Inc(SPos);
      V := 0;
      While (SrcCh(SPos) = '0') Or (SrcCh(SPos) = '1') Do
      Begin
        V := V * 2 + Ord(SrcCh(SPos)) - 48;
        Inc(SPos);
      End;
      Tok := tkInt; TokI := V;
      Exit;
    End;
    S := '';
    While (SrcCh(SPos) >= '0') And (SrcCh(SPos) <= '9') Do
    Begin
      S := S + SrcCh(SPos);
      Inc(SPos);
    End;
    If (SrcCh(SPos) = '.') And (SrcCh(SPos + 1) >= '0') And (SrcCh(SPos + 1) <= '9') Then
    Begin
      S := S + '.';
      Inc(SPos);
      While (SrcCh(SPos) >= '0') And (SrcCh(SPos) <= '9') Do
      Begin
        S := S + SrcCh(SPos);
        Inc(SPos);
      End;
    End;
    If UpCase(SrcCh(SPos)) = 'E' Then
    Begin
      K := SPos + 1;
      If (SrcCh(K) = '+') Or (SrcCh(K) = '-') Then Inc(K);
      If (SrcCh(K) >= '0') And (SrcCh(K) <= '9') Then
      Begin
        S := S + 'E' + SrcCh(SPos + 1);
        SPos := SPos + 2;
        If (S[Length(S)] = '+') Or (S[Length(S)] = '-') Then
        Begin
          S := S + SrcCh(SPos);
          Inc(SPos);
        End;
        While (SrcCh(SPos) >= '0') And (SrcCh(SPos) <= '9') Do
        Begin
          S := S + SrcCh(SPos);
          Inc(SPos);
        End;
      End;
    End;
    If (Pos('.', S) > 0) Or (Pos('E', S) > 0) Or (Length(S) > 9) Then
    Begin
      Val(S, TokR, K);
      Tok := tkReal;
      If (Pos('.', S) = 0) And (Pos('E', S) = 0) And (TokR <= 2147483647.0) Then
      Begin
        Tok := tkInt; TokI := Trunc(TokR);
      End;
    End
    Else
    Begin
      Val(S, TokI, K);
      Tok := tkInt;
    End;
    Exit;
  End;
  If (C = '''') Or (C = '#') Then
  Begin
    { 'texte' et #nn, enchaines ; une longue chaine va dans Strs }
    BufInit(Lit);
    While (SrcCh(SPos) = '''') Or ((SrcCh(SPos) = '#') And (((SrcCh(SPos + 1) >= '0') And (SrcCh(SPos + 1) <= '9')) Or
          (SrcCh(SPos + 1) = '$'))) Do
    Begin
      If SrcCh(SPos) = '''' Then
      Begin
        Inc(SPos);
        Repeat
          If SPos >= Src.Len Then Break;
          If SrcCh(SPos) = '''' Then
          Begin
            If SrcCh(SPos + 1) = '''' Then
            Begin
              BufAddC(Lit, 39);
              SPos := SPos + 2;
            End
            Else
            Begin
              Inc(SPos);
              Break;
            End;
          End
          Else
          Begin
            If SrcCh(SPos) = #10 Then Inc(SLine);
            BufAddC(Lit, Src.P^[SPos]);
            Inc(SPos);
          End;
        Until False;
      End
      Else
      Begin
        Inc(SPos);
        V := 0;
        If SrcCh(SPos) = '$' Then
        Begin
          Inc(SPos);
          While UpCase(SrcCh(SPos)) In ['0'..'9', 'A'..'F'] Do
          Begin
            C := UpCase(SrcCh(SPos));
            If C <= '9' Then V := V * 16 + Ord(C) - 48 Else V := V * 16 + Ord(C) - 55;
            Inc(SPos);
          End;
        End
        Else
          While (SrcCh(SPos) >= '0') And (SrcCh(SPos) <= '9') Do
          Begin
            V := V * 10 + Ord(SrcCh(SPos)) - 48;
            Inc(SPos);
          End;
        BufAddC(Lit, V And 255);
      End;
    End;
    Tok := tkStr;
    TokOff := AddStrB(Lit.P, Lit.Len);
    TokLen := Lit.Len;
    N := Lit.Len;
    If N > 255 Then N := 255;
    TokS[0] := Chr(N);
    If N > 0 Then Move(Lit.P^[0], TokS[1], N);
    BufFree(Lit);
    Exit;
  End;
  Tok := tkSym;
  Inc(SPos);
  TokS := C;
  Case C Of
    ':' : If SrcCh(SPos) = '=' Then
          Begin
            TokS := ':='; Inc(SPos);
          End;
    '<' : If (SrcCh(SPos) = '=') Or (SrcCh(SPos) = '>') Then
          Begin
            TokS := TokS + SrcCh(SPos); Inc(SPos);
          End;
    '>' : If SrcCh(SPos) = '=' Then
          Begin
            TokS := '>='; Inc(SPos);
          End;
    '.' : If SrcCh(SPos) = '.' Then
          Begin
            TokS := '..'; Inc(SPos);
          End;
    '+', '-', '*', '/' : If SrcCh(SPos) = '=' Then
          Begin
            TokS := TokS + '='; Inc(SPos);
          End;
  End;
End;

Function IsSym(S : String) : Boolean;
Begin
  IsSym := (Tok = tkSym) And (TokS = S);
End;

Function IsKw(S : String) : Boolean;
Begin
  IsKw := (Tok = tkId) And (TokS = S);
End;

Procedure Expect(S : String);
Begin
  If ((Tok = tkSym) Or (Tok = tkId)) And (TokS = S) Then NextTok
  Else If CErr = '' Then
  Begin
    If Tok = tkEof Then CError('''' + S + ''' attendu (fin du fichier)')
    Else If Tok = tkId Then CError('''' + S + ''' attendu au lieu de ' + TokS)
    Else If Tok = tkSym Then CError('''' + S + ''' attendu au lieu de ''' + TokS + '''')
    Else CError('''' + S + ''' attendu');
  End;
End;

Function ExpectId : String;
Begin
  ExpectId := TokS;
  If Tok <> tkId Then CError('identificateur attendu')
  Else NextTok;
End;

{ --- symboles et types --- }

Function NewTy(K, Size : LongInt) : LongInt;
Begin
  If NTy >= MaxTy Then
  Begin
    CError('trop de types');
    NewTy := TyInt;
    Exit;
  End;
  FillChar(Tys[NTy], SizeOf(TTy), 0);
  Tys[NTy].Kind := K; Tys[NTy].Size := Size;
  NewTy := NTy;
  Inc(NTy);
End;

Function TySize(T : LongInt) : LongInt;
Begin
  TySize := Tys[T].Size;
End;

Function IsStruct(T : LongInt) : Boolean;
Begin
  IsStruct := (Tys[T].Kind = ykArray) Or (Tys[T].Kind = ykRec);
End;

Function TyCv(T : LongInt) : LongInt;
Begin
  Case Tys[T].Kind Of
    ykInt, ykEnum : TyCv := cvInt;
    ykReal : TyCv := cvReal;
    ykBool : TyCv := cvBool;
    ykChar : TyCv := cvChar;
    ykStr : TyCv := cvStr;
  Else
    TyCv := cvVar;
  End;
End;

Function AddSym(Name : String; Kind : LongInt) : LongInt;
Var K : LongInt;
Begin
  If NSym >= MaxSym Then
  Begin
    CError('trop de symboles');
    AddSym := 0;
    Exit;
  End;
  { meme nom dans la meme portee : remplace (permis au niveau de la page) }
  FillChar(Syms[NSym], SizeOf(TSym), 0);
  Syms[NSym].Name := Name; Syms[NSym].Kind := Kind; Syms[NSym].Lvl := CurLvl;
  Syms[NSym].Patch := -1;
  AddSym := NSym;
  Inc(NSym);
  K := 0;
End;

Function FindSym(Name : String) : LongInt;
Var K : LongInt;
Begin
  FindSym := -1;
  For K := NSym - 1 DownTo 0 Do
    If Syms[K].Name = Name Then
    Begin
      FindSym := K;
      Exit;
    End;
End;

{ cellule de variable : globale (niveau 0) ou locale }
Function AllocVar(Size : LongInt) : LongInt;
Begin
  If CurLvl = 0 Then
  Begin
    AllocVar := GlobTop;
    GlobTop := GlobTop + Size;
  End
  Else
  Begin
    AllocVar := LocTop;
    LocTop := LocTop + Size;
    If LocTop > LocMax Then LocMax := LocTop;
  End;
End;

{ initialiser des cellules a la valeur par defaut de leur type }
Procedure EmitInit(Mode, Off, T, Count, Stride : LongInt);
Var K, E : LongInt;
Begin
  Case Tys[T].Kind Of
    ykArray :
      Begin
        E := Tys[T].Elem;
        If Count = 1 Then EmitInit(Mode, Off, E, Tys[T].Hi - Tys[T].Lo + 1, TySize(E))
        Else
          For K := 0 To Tys[T].Hi - Tys[T].Lo Do EmitInit(Mode, Off + K * TySize(E), E, Count, Stride);
      End;
    ykRec :
      For K := Tys[T].FBase To Tys[T].FBase + Tys[T].FCount - 1 Do EmitInit(Mode, Off + FOff[K], FTy[K], Count, Stride);
  Else
    Emit(opInitS); Emit(Mode); Emit(Off); Emit(Count); Emit(Stride); Emit(TyCv(T));
  End;
End;

{ comparer deux chaines constantes (Strs) }
Function StrCmpCellsK(Var A, B : TCell) : LongInt;
Var Sa, Sb : String;
Begin
  If A.T = vtChar Then Sa := Chr(A.I) Else
  Begin
    Sa[0] := Chr(A.L And 255);
    If A.L > 0 Then Move(Pages[CP].Strs.P^[A.I], Sa[1], Length(Sa));
  End;
  If B.T = vtChar Then Sb := Chr(B.I) Else
  Begin
    Sb[0] := Chr(B.L And 255);
    If B.L > 0 Then Move(Pages[CP].Strs.P^[B.I], Sb[1], Length(Sb));
  End;
  If Sa < Sb Then StrCmpCellsK := -1 Else If Sa > Sb Then StrCmpCellsK := 1 Else StrCmpCellsK := 0;
End;

Function ParseType : LongInt; Forward;
Function Expr : LongInt; Forward;
Function ConstExpr(Var C : TCell) : LongInt; Forward;

{ valeur ordinale d'une constante (bornes d'intervalle) }
Function OrdConst : LongInt;
Var C : TCell; T : LongInt;
Begin
  T := ConstExpr(C);
  If C.T = vtChar Then OrdConst := C.I
  Else If (C.T = vtKStr) And (C.L = 1) Then OrdConst := Pages[CP].Strs.P^[C.I]
  Else OrdConst := C.I;
End;

Function ParseType : LongInt;
Var S, T, K, E, Lo, Hi, N, First, Off, Cnt : LongInt; Nm : String; C : TCell; Names : Array[0..31] Of String[31];
    Packed_ : Boolean;
Begin
  ParseType := TyInt;
  If IsKw('PACKED') Then NextTok;
  If IsSym('(') Then
  Begin
    { enumeration }
    NextTok;
    T := NewTy(ykEnum, 1);
    N := 0;
    Repeat
      Nm := ExpectId;
      S := AddSym(Nm, skConst);
      Syms[S].Ty := T;
      MkInt(N, Syms[S].CV);
      Inc(N);
      If IsSym(',') Then NextTok Else Break;
    Until CErr <> '';
    Expect(')');
    Tys[T].Lo := 0; Tys[T].Hi := N - 1;
    ParseType := T;
    Exit;
  End;
  If IsSym('^') Then
  Begin
    NextTok;
    T := NewTy(ykPtr, 1);
    Nm := ExpectId;
    S := FindSym(Nm);
    If (S >= 0) And (Syms[S].Kind = skType) Then Tys[T].Elem := Syms[S].Ty Else Tys[T].Elem := TyVar;
    ParseType := T;
    Exit;
  End;
  If IsKw('ARRAY') Then
  Begin
    NextTok;
    If IsSym('[') Then
    Begin
      NextTok;
      { dimensions : array[a..b, c..d] of T = array[a..b] of array[c..d] of T }
      N := 0;
      Repeat
        If (Tok = tkId) And (FindSym(TokS) >= 0) And (Syms[FindSym(TokS)].Kind = skType) Then
        Begin
          E := Syms[FindSym(TokS)].Ty;
          NextTok;
          Lo := Tys[E].Lo; Hi := Tys[E].Hi;
          If Tys[E].Kind = ykChar Then
          Begin
            Lo := 0; Hi := 255;
          End
          Else If Tys[E].Kind = ykBool Then
          Begin
            Lo := 0; Hi := 1;
          End;
        End
        Else
        Begin
          Lo := OrdConst;
          Expect('..');
          Hi := OrdConst;
        End;
        If Hi < Lo Then CError('intervalle vide');
        Names[N] := IStr(Lo) + ':' + IStr(Hi);
        Inc(N);
        If IsSym(',') Then NextTok Else Break;
      Until (CErr <> '') Or (N >= 8);
      Expect(']');
      Expect('OF');
      E := ParseType;
      For K := N - 1 DownTo 0 Do
      Begin
        T := NewTy(ykArray, 0);
        Lo := SVal(Copy(Names[K], 1, Pos(':', Names[K]) - 1));
        Hi := SVal(Copy(Names[K], Pos(':', Names[K]) + 1, 20));
        Tys[T].Lo := Lo; Tys[T].Hi := Hi; Tys[T].Elem := E;
        Tys[T].Size := (Hi - Lo + 1) * TySize(E);
        If Tys[T].Size > 1000000 Then CError('tableau trop grand');
        E := T;
      End;
      ParseType := E;
    End
    Else
    Begin
      { array of T (tableau ouvert, en parametre) : variant }
      Expect('OF');
      Dummy := ParseType;
      ParseType := TyVar;
    End;
    Exit;
  End;
  If IsKw('RECORD') Then
  Begin
    NextTok;
    T := NewTy(ykRec, 0);
    First := NFld; Off := 0;
    While (Tok = tkId) And (TokS <> 'END') And (TokS <> 'CASE') And (CErr = '') Do
    Begin
      Cnt := 0;
      Repeat
        Names[Cnt] := ExpectId;
        If Cnt < 31 Then Inc(Cnt);
        If IsSym(',') Then NextTok Else Break;
      Until CErr <> '';
      Expect(':');
      E := ParseType;
      For K := 0 To Cnt - 1 Do
      Begin
        If NFld >= MaxFld Then
        Begin
          CError('trop de champs');
          Exit;
        End;
        FName[NFld] := Names[K]; FTy[NFld] := E; FOff[NFld] := Off;
        Off := Off + TySize(E);
        Inc(NFld);
      End;
      If IsSym(';') Then NextTok;
    End;
    If IsKw('CASE') Then
    Begin
      { partie variante : champs mis a la suite }
      NextTok;
      Nm := ExpectId;
      If IsSym(':') Then
      Begin
        NextTok;
        Nm := ExpectId;
      End;
      Expect('OF');
      While (CErr = '') And Not IsKw('END') Do
      Begin
        Repeat
          Dummy := OrdConst;
          If IsSym(',') Then NextTok Else Break;
        Until CErr <> '';
        Expect(':');
        Expect('(');
        While (Tok = tkId) And (CErr = '') Do
        Begin
          Cnt := 0;
          Repeat
            Names[Cnt] := ExpectId;
            If Cnt < 31 Then Inc(Cnt);
            If IsSym(',') Then NextTok Else Break;
          Until CErr <> '';
          Expect(':');
          E := ParseType;
          For K := 0 To Cnt - 1 Do
            If NFld < MaxFld Then
            Begin
              FName[NFld] := Names[K]; FTy[NFld] := E; FOff[NFld] := Off;
              Off := Off + TySize(E);
              Inc(NFld);
            End;
          If IsSym(';') Then NextTok;
        End;
        Expect(')');
        If IsSym(';') Then NextTok;
      End;
    End;
    Expect('END');
    Tys[T].FBase := First; Tys[T].FCount := NFld - First; Tys[T].Size := Off;
    If Off = 0 Then Tys[T].Size := 1;
    ParseType := T;
    Exit;
  End;
  If IsKw('SET') Then
  Begin
    NextTok;
    Expect('OF');
    E := ParseType;
    T := NewTy(ykSet, 1);
    Tys[T].Elem := E;
    ParseType := T;
    Exit;
  End;
  If IsKw('FILE') Or IsKw('TEXT') Then
  Begin
    NextTok;
    If IsKw('OF') Then
    Begin
      NextTok;
      Dummy := ParseType;
    End;
    ParseType := TyVar;
    Exit;
  End;
  If IsKw('STRING') Then
  Begin
    NextTok;
    If IsSym('[') Then
    Begin
      NextTok;
      Dummy := OrdConst;
      Expect(']');
    End;
    ParseType := TyStr;
    Exit;
  End;
  If Tok = tkId Then
  Begin
    S := FindSym(TokS);
    If (S >= 0) And (Syms[S].Kind = skType) Then
    Begin
      NextTok;
      ParseType := Syms[S].Ty;
      Exit;
    End;
  End;
  { intervalle a..b }
  Lo := ConstExpr(C);
  K := C.T;
  If C.T = vtChar Then Lo := C.I
  Else If (C.T = vtKStr) And (C.L = 1) Then
  Begin
    Lo := Pages[CP].Strs.P^[C.I]; K := vtChar;
  End
  Else Lo := C.I;
  Expect('..');
  Hi := OrdConst;
  If K = vtChar Then T := NewTy(ykChar, 1) Else T := NewTy(ykInt, 1);
  Tys[T].Lo := Lo; Tys[T].Hi := Hi;
  ParseType := T;
End;

{ --- fonctions predefinies (appelees par opCallB) --- }
Const
  bLength = 1; bCopy = 2; bPos = 3; bUpCase = 4; bUpper = 5; bLower = 6; bTrim = 7; bTrimL = 8; bTrimR = 9;
  bIntToStr = 10; bStrToInt = 11; bStrToIntDef = 12; bFloatToStr = 13; bStrToFloat = 14; bChr = 15; bOrd = 16;
  bSucc = 17; bPred = 18; bAbs = 19; bSqr = 20; bSqrt = 21; bSin = 22; bCos = 23; bArcTan = 24; bExp = 25;
  bLn = 26; bRound = 27; bTrunc = 28; bFrac = 29; bInt = 30; bRandom = 31; bRandomize = 32; bOdd = 33;
  bLo = 34; bHi = 35; bSwap = 36; bNow = 37; bDate = 38; bTime = 39; bDateToStr = 40; bTimeToStr = 41;
  bStringOfChar = 42; bPi = 43; bMax = 44; bMin = 45; bCreateObject = 46; bConcat = 47; bFormatFloat = 48;
  bIntToHex = 49; bFileExists = 50; bHtmlEncode = 51; bUrlEncode = 52; bDateTimeToStr = 53; bTan = 54;
  bPower = 55; bLeft = 56; bRight = 57; bMid = 58; bLen = 59; bInStr = 60; bLCase = 61; bUCase = 62;
  bCStr = 63; bCInt = 64; bCLng = 65; bCDbl = 66; bCBool = 67; bIsNumeric = 68; bIsEmpty = 69; bIsNull = 70;
  bIsObject = 71; bReplace = 72; bSpace = 73; bString = 74; bStrReverse = 75; bInStrRev = 76; bLTrim = 77;
  bRTrim = 78; bAsc = 79; bChrV = 80; bYear = 81; bMonth = 82; bDay = 83; bHour = 84; bMinute = 85;
  bSecond = 86; bWeekday = 87; bFormatNumber = 88; bFix = 89; bSgn = 90; bHex = 91; bOct = 92; bRnd = 93;
  bTimer = 94; bSplit = 95; bJoin = 96; bUBound = 97; bLBound = 98; bArray = 99; bIsArray = 100;
  bTypeName = 101; bVarType = 102; bMonthName = 103; bWeekdayName = 104; bDateSerial = 105;
  bTimeSerial = 106; bDateAdd = 107; bDateDiff = 108; bCDate = 109; bIsDate = 110; bDateValue = 111;
  bFormatDateTime = 112; bEscape = 113; bUnescape = 114; bStrComp = 115; bCSng = 116; bCByte = 117;
  bFormatCurrency = 118; bFormatPercent = 119; bEval = 120; bLog = 121; bAtn = 122; bExpV = 123;
  bTimeValue = 124; bCurDir = 125;
  bMakeArr = 126; bEachCount = 127; bEachItem = 128; bOnError = 129; bReDim = 130;
  { procedures a parametres variables (adresses) }
  vInc = 1; vDec = 2; vStr = 3; vVal = 4; vDelete = 5; vInsert = 6; vNew = 7; vSetLength = 8; vDispose = 9;
  vInclude = 10; vExclude = 11;

Type
  TBi = Record
    Name : String[15];
    Id, MinA, MaxA : LongInt;
    Ret : LongInt;      { type du resultat (-1 : procedure) }
  End;

Const
  NBi = 61;
  Bis : Array[1..NBi] Of TBi = (
    (Name: 'LENGTH'; Id: bLength; MinA: 1; MaxA: 1; Ret: TyInt),
    (Name: 'COPY'; Id: bCopy; MinA: 2; MaxA: 3; Ret: TyStr),
    (Name: 'POS'; Id: bPos; MinA: 2; MaxA: 3; Ret: TyInt),
    (Name: 'UPCASE'; Id: bUpCase; MinA: 1; MaxA: 1; Ret: TyVar),
    (Name: 'UPPERCASE'; Id: bUpper; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'LOWERCASE'; Id: bLower; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'LOWCASE'; Id: bLower; MinA: 1; MaxA: 1; Ret: TyVar),
    (Name: 'TRIM'; Id: bTrim; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'TRIMLEFT'; Id: bTrimL; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'TRIMRIGHT'; Id: bTrimR; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'INTTOSTR'; Id: bIntToStr; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'STRTOINT'; Id: bStrToInt; MinA: 1; MaxA: 1; Ret: TyInt),
    (Name: 'STRTOINTDEF'; Id: bStrToIntDef; MinA: 2; MaxA: 2; Ret: TyInt),
    (Name: 'FLOATTOSTR'; Id: bFloatToStr; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'STRTOFLOAT'; Id: bStrToFloat; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'CHR'; Id: bChr; MinA: 1; MaxA: 1; Ret: TyChar),
    (Name: 'ORD'; Id: bOrd; MinA: 1; MaxA: 1; Ret: TyInt),
    (Name: 'SUCC'; Id: bSucc; MinA: 1; MaxA: 1; Ret: TyVar),
    (Name: 'PRED'; Id: bPred; MinA: 1; MaxA: 1; Ret: TyVar),
    (Name: 'ABS'; Id: bAbs; MinA: 1; MaxA: 1; Ret: TyVar),
    (Name: 'SQR'; Id: bSqr; MinA: 1; MaxA: 1; Ret: TyVar),
    (Name: 'SQRT'; Id: bSqrt; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'SIN'; Id: bSin; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'COS'; Id: bCos; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'ARCTAN'; Id: bArcTan; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'EXP'; Id: bExp; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'LN'; Id: bLn; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'ROUND'; Id: bRound; MinA: 1; MaxA: 1; Ret: TyInt),
    (Name: 'TRUNC'; Id: bTrunc; MinA: 1; MaxA: 1; Ret: TyInt),
    (Name: 'FRAC'; Id: bFrac; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'INT'; Id: bInt; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'RANDOM'; Id: bRandom; MinA: 0; MaxA: 1; Ret: TyVar),
    (Name: 'RANDOMIZE'; Id: bRandomize; MinA: 0; MaxA: 0; Ret: -1),
    (Name: 'ODD'; Id: bOdd; MinA: 1; MaxA: 1; Ret: TyBool),
    (Name: 'LO'; Id: bLo; MinA: 1; MaxA: 1; Ret: TyInt),
    (Name: 'HI'; Id: bHi; MinA: 1; MaxA: 1; Ret: TyInt),
    (Name: 'SWAP'; Id: bSwap; MinA: 1; MaxA: 1; Ret: TyInt),
    (Name: 'NOW'; Id: bNow; MinA: 0; MaxA: 0; Ret: TyStr),
    (Name: 'DATE'; Id: bDate; MinA: 0; MaxA: 0; Ret: TyStr),
    (Name: 'TIME'; Id: bTime; MinA: 0; MaxA: 0; Ret: TyStr),
    (Name: 'DATETOSTR'; Id: bDateToStr; MinA: 0; MaxA: 1; Ret: TyStr),
    (Name: 'TIMETOSTR'; Id: bTimeToStr; MinA: 0; MaxA: 1; Ret: TyStr),
    (Name: 'STRINGOFCHAR'; Id: bStringOfChar; MinA: 2; MaxA: 2; Ret: TyStr),
    (Name: 'PI'; Id: bPi; MinA: 0; MaxA: 0; Ret: TyReal),
    (Name: 'MAX'; Id: bMax; MinA: 2; MaxA: 2; Ret: TyVar),
    (Name: 'MIN'; Id: bMin; MinA: 2; MaxA: 2; Ret: TyVar),
    (Name: 'CREATEOBJECT'; Id: bCreateObject; MinA: 1; MaxA: 1; Ret: TyVar),
    (Name: 'CONCAT'; Id: bConcat; MinA: 1; MaxA: 16; Ret: TyStr),
    (Name: 'FORMATFLOAT'; Id: bFormatFloat; MinA: 2; MaxA: 2; Ret: TyStr),
    (Name: 'INTTOHEX'; Id: bIntToHex; MinA: 2; MaxA: 2; Ret: TyStr),
    (Name: 'FILEEXISTS'; Id: bFileExists; MinA: 1; MaxA: 1; Ret: TyBool),
    (Name: 'HTMLENCODE'; Id: bHtmlEncode; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'URLENCODE'; Id: bUrlEncode; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'DATETIMETOSTR'; Id: bDateTimeToStr; MinA: 0; MaxA: 1; Ret: TyStr),
    (Name: 'TAN'; Id: bTan; MinA: 1; MaxA: 1; Ret: TyReal),
    (Name: 'POWER'; Id: bPower; MinA: 2; MaxA: 2; Ret: TyReal),
    (Name: 'UPPER'; Id: bUpper; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'LOWER'; Id: bLower; MinA: 1; MaxA: 1; Ret: TyStr),
    (Name: 'ISNUMERIC'; Id: bIsNumeric; MinA: 1; MaxA: 1; Ret: TyBool),
    (Name: 'STRREPLACE'; Id: bReplace; MinA: 3; MaxA: 3; Ret: TyStr),
    (Name: 'GETCURRENTDIR'; Id: bCurDir; MinA: 0; MaxA: 0; Ret: TyStr));

Function FindBi(Name : String) : LongInt;
Var K : LongInt;
Begin
  FindBi := 0;
  For K := 1 To NBi Do
    If Bis[K].Name = Name Then
    Begin
      FindBi := K;
      Exit;
    End;
End;

Function MemberCode(Name : String) : LongInt;
Var K : LongInt;
Begin
  MemberCode := -1;
  For K := 1 To NMembers Do
    If MemberNames[K] = Name Then
    Begin
      MemberCode := K;
      Exit;
    End;
End;

{ --- expressions constantes (declarations) --- }

Function ConstFactor(Var C : TCell) : LongInt;
Var S, T : LongInt; N : String; R : TCell;
Begin
  ConstFactor := TyInt;
  MkInt(0, C);
  If Tok = tkInt Then
  Begin
    MkInt(TokI, C);
    NextTok;
  End
  Else If Tok = tkReal Then
  Begin
    MkReal(TokR, C);
    NextTok;
    ConstFactor := TyReal;
  End
  Else If Tok = tkStr Then
  Begin
    If TokLen = 1 Then
    Begin
      C.T := vtChar; C.I := Ord(TokS[1]);
      ConstFactor := TyChar;
    End
    Else
    Begin
      C.T := vtKStr; C.I := TokOff; C.L := TokLen;
      ConstFactor := TyStr;
    End;
    NextTok;
  End
  Else If IsSym('(') Then
  Begin
    NextTok;
    ConstFactor := ConstExpr(C);
    Expect(')');
  End
  Else If IsSym('-') Then
  Begin
    NextTok;
    T := ConstFactor(C);
    If C.T = vtReal Then C.R := -C.R Else C.I := -C.I;
    ConstFactor := T;
  End
  Else If IsSym('+') Then
  Begin
    NextTok;
    ConstFactor := ConstFactor(C);
  End
  Else If IsKw('NOT') Then
  Begin
    NextTok;
    T := ConstFactor(C);
    If C.T = vtBool Then C.I := 1 - C.I Else C.I := Not C.I;
    ConstFactor := T;
  End
  Else If Tok = tkId Then
  Begin
    N := TokS;
    If (N = 'TRUE') Or (N = 'FALSE') Then
    Begin
      MkBool(N = 'TRUE', C);
      NextTok;
      ConstFactor := TyBool;
      Exit;
    End;
    If (N = 'NIL') Then
    Begin
      MkNil(C);
      NextTok;
      ConstFactor := TyVar;
      Exit;
    End;
    If (N = 'CHR') Or (N = 'ORD') Or (N = 'HIGH') Or (N = 'LOW') Or (N = 'SIZEOF') Or (N = 'LENGTH') Then
    Begin
      NextTok;
      Expect('(');
      If (N = 'HIGH') Or (N = 'LOW') Or (N = 'SIZEOF') Then
      Begin
        S := FindSym(TokS);
        NextTok;
        T := TyInt;
        If S >= 0 Then T := Syms[S].Ty;
        If N = 'HIGH' Then MkInt(Tys[T].Hi, C)
        Else If N = 'LOW' Then MkInt(Tys[T].Lo, C)
        Else MkInt(Tys[T].FBase, C);
      End
      Else
      Begin
        T := ConstExpr(R);
        If N = 'CHR' Then
        Begin
          C.T := vtChar; C.I := R.I And 255;
          ConstFactor := TyChar;
        End
        Else If N = 'LENGTH' Then MkInt(CellLen(R), C)
        Else If R.T = vtChar Then MkInt(R.I, C)
        Else MkInt(R.I, C);
      End;
      Expect(')');
      Exit;
    End;
    S := FindSym(N);
    If (S >= 0) And ((Syms[S].Kind = skConst) Or ((Syms[S].Kind = skVar) And (Syms[S].Patch = -2))) Then
    Begin
      C := Syms[S].CV;
      ConstFactor := Syms[S].Ty;
      NextTok;
    End
    Else CError('constante attendue : ' + N);
  End
  Else CError('constante attendue');
End;

Function ConstTerm(Var C : TCell) : LongInt;
Var T, U : LongInt; Op : String; R : TCell;
Begin
  T := ConstFactor(C);
  While ((Tok = tkSym) And ((TokS = '*') Or (TokS = '/'))) Or IsKw('DIV') Or IsKw('MOD') Or IsKw('SHL') Or
        IsKw('SHR') Or IsKw('AND') Do
  Begin
    Op := TokS;
    NextTok;
    U := ConstFactor(R);
    If (Op = '/') Or (C.T = vtReal) Or (R.T = vtReal) Then
    Begin
      If C.T <> vtReal Then MkReal(C.I, C);
      If R.T <> vtReal Then MkReal(R.I, R);
      If Op = '*' Then C.R := C.R * R.R Else If R.R <> 0 Then C.R := C.R / R.R;
      T := TyReal;
    End
    Else If Op = '*' Then C.I := C.I * R.I
    Else If Op = 'DIV' Then
    Begin
      If R.I <> 0 Then C.I := C.I Div R.I;
    End
    Else If Op = 'MOD' Then
    Begin
      If R.I <> 0 Then C.I := C.I Mod R.I;
    End
    Else If Op = 'SHL' Then C.I := C.I Shl R.I
    Else If Op = 'SHR' Then C.I := C.I Shr R.I
    Else C.I := C.I And R.I;
  End;
  ConstTerm := T;
End;

Function ConstSimple(Var C : TCell) : LongInt;
Var T, U : LongInt; Op : String; R : TCell; B : TBuf;
Begin
  T := ConstTerm(C);
  While ((Tok = tkSym) And ((TokS = '+') Or (TokS = '-'))) Or IsKw('OR') Or IsKw('XOR') Do
  Begin
    Op := TokS;
    NextTok;
    U := ConstTerm(R);
    If ((C.T = vtKStr) Or (C.T = vtChar)) And (Op = '+') Then
    Begin
      BufInit(B);
      If C.T = vtChar Then BufAddC(B, C.I) Else BufAddB(B, @Pages[CP].Strs.P^[C.I], C.L);
      If R.T = vtChar Then BufAddC(B, R.I) Else If R.T = vtKStr Then BufAddB(B, @Pages[CP].Strs.P^[R.I], R.L);
      C.T := vtKStr; C.I := AddStrB(B.P, B.Len); C.L := B.Len;
      BufFree(B);
      T := TyStr;
    End
    Else If (C.T = vtReal) Or (R.T = vtReal) Then
    Begin
      If C.T <> vtReal Then MkReal(C.I, C);
      If R.T <> vtReal Then MkReal(R.I, R);
      If Op = '+' Then C.R := C.R + R.R Else C.R := C.R - R.R;
      T := TyReal;
    End
    Else If Op = '+' Then C.I := C.I + R.I
    Else If Op = '-' Then C.I := C.I - R.I
    Else If Op = 'OR' Then C.I := C.I Or R.I
    Else C.I := C.I Xor R.I;
  End;
  ConstSimple := T;
End;

Function ConstExpr(Var C : TCell) : LongInt;
Var T : LongInt; Op : String; R : TCell; K : LongInt;
Begin
  T := ConstSimple(C);
  If IsSym('=') Or IsSym('<>') Or IsSym('<') Or IsSym('<=') Or IsSym('>') Or IsSym('>=') Then
  Begin
    Op := TokS;
    NextTok;
    Dummy := ConstSimple(R);
    If (C.T = vtKStr) Or (R.T = vtKStr) Then K := StrCmpCellsK(C, R)
    Else If (C.T = vtReal) Or (R.T = vtReal) Then
    Begin
      If C.T <> vtReal Then MkReal(C.I, C);
      If R.T <> vtReal Then MkReal(R.I, R);
      If C.R < R.R Then K := -1 Else If C.R > R.R Then K := 1 Else K := 0;
    End
    Else If C.I < R.I Then K := -1 Else If C.I > R.I Then K := 1 Else K := 0;
    If Op = '=' Then MkBool(K = 0, C) Else If Op = '<>' Then MkBool(K <> 0, C) Else If Op = '<' Then MkBool(K < 0, C)
    Else If Op = '<=' Then MkBool(K <= 0, C) Else If Op = '>' Then MkBool(K > 0, C) Else MkBool(K >= 0, C);
    T := TyBool;
  End;
  ConstExpr := T;
End;

{ empiler une constante }
Procedure EmitConst(Var C : TCell);
Begin
  Case C.T Of
    vtInt : Emit1(opPushI, C.I);
    vtReal : Emit1(opPushR, AddReal(C.R));
    vtBool : Emit1(opPushB, C.I);
    vtChar : Emit1(opPushC, C.I);
    vtKStr : Emit2(opPushS, C.I, C.L);
  Else
    Emit(opPushNil);
  End;
End;

{ --- designateurs --- }

Procedure DesFromSym(S : LongInt; Var D : TDes);
Begin
  D.Kind := dkVar; D.Ty := Syms[S].Ty; D.Ref := Syms[S].Ref; D.Adr := Syms[S].Adr;
  If Syms[S].Lvl = 0 Then
  Begin
    D.Mode := 0; D.Up := 0;
  End
  Else If Syms[S].Lvl = CurLvl Then
  Begin
    D.Mode := 1; D.Up := 0;
  End
  Else
  Begin
    D.Mode := 2; D.Up := CurLvl - Syms[S].Lvl;
  End;
End;

{ valeur de la cellule (adresse si Ref) d'une variable directe }
Procedure EmitSlotLoad(Var D : TDes);
Begin
  Case D.Mode Of
    0 : Emit1(opLdG, D.Adr);
    1 : Emit1(opLdL, D.Adr);
  Else
    Emit2(opLdUp, D.Up, D.Adr);
  End;
End;

Procedure EmitSlotAddr(Var D : TDes);
Begin
  Case D.Mode Of
    0 : Emit1(opLdGA, D.Adr);
    1 : Emit1(opLdLA, D.Adr);
  Else
    Emit2(opLdUpA, D.Up, D.Adr);
  End;
End;

{ mettre l'adresse sur la pile }
Procedure DesAddr(Var D : TDes);
Begin
  If D.Kind = dkVar Then
  Begin
    If D.Ref Then EmitSlotLoad(D) Else EmitSlotAddr(D);
    D.Kind := dkAddr;
  End
  Else If D.Kind <> dkAddr Then CError('variable attendue');
End;

{ mettre la valeur sur la pile (structure : son adresse) }
Procedure DesLoad(Var D : TDes);
Begin
  Case D.Kind Of
    dkVar :
      If IsStruct(D.Ty) Then DesAddr(D)
      Else If D.Ref Then
      Begin
        EmitSlotLoad(D);
        Emit(opLdInd);
      End
      Else EmitSlotLoad(D);
    dkAddr : If Not IsStruct(D.Ty) Then Emit(opLdInd);
    dkStrIdx : Emit(opStrIdx);
    dkMember : Emit2(opMember, D.Mem, D.Argc);
  End;
  If (D.Kind <> dkAddr) Or Not IsStruct(D.Ty) Then D.Kind := dkValue;
End;

{ ranger la valeur du sommet de la pile (l'adresse, s'il en faut une, est
  dessous) }
Procedure DesStore(Var D : TDes);
Begin
  Case D.Kind Of
    dkVar :
      If IsStruct(D.Ty) Then CError('affectation de structure')
      Else
      Begin
        If TyCv(D.Ty) <> cvVar Then Emit1(opConv, TyCv(D.Ty));
        If D.Ref Then CError('interne : reference')
        Else
          Case D.Mode Of
            0 : Emit1(opStG, D.Adr);
            1 : Emit1(opStL, D.Adr);
          Else
            Emit2(opStUp, D.Up, D.Adr);
          End;
      End;
    dkAddr :
      If IsStruct(D.Ty) Then Emit1(opCopy, TySize(D.Ty))
      Else
      Begin
        If TyCv(D.Ty) <> cvVar Then Emit1(opConv, TyCv(D.Ty));
        Emit(opStInd);
      End;
    dkStrIdx : Emit(opStrSet);
    dkMember : Emit2(opSetMember, D.Mem, D.Argc);
  Else
    CError('affectation impossible');
  End;
End;

Function ArgList(MaxN : LongInt) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  If IsSym('(') Then
  Begin
    NextTok;
    If Not IsSym(')') Then
      Repeat
        Dummy := Expr;
        Inc(N);
        If IsSym(',') Then NextTok Else Break;
      Until CErr <> '';
    Expect(')');
  End;
  ArgList := N;
End;

{ selecteurs : .champ, [indice], ^, .membre, (arguments) d'un objet }
Procedure Selectors(Var D : TDes);
Var K, F, T, E, M : LongInt; N : String; Found : Boolean;
Begin
  While CErr = '' Do
  Begin
    If IsSym('.') Then
    Begin
      NextTok;
      N := TokS;
      If Tok <> tkId Then
      Begin
        CError('nom attendu apres ''.''');
        Exit;
      End;
      If Tys[D.Ty].Kind = ykRec Then
      Begin
        F := -1;
        For K := Tys[D.Ty].FBase To Tys[D.Ty].FBase + Tys[D.Ty].FCount - 1 Do
          If FName[K] = N Then F := K;
        If F < 0 Then
        Begin
          CError('champ inconnu : ' + N);
          Exit;
        End;
        NextTok;
        If (D.Kind = dkVar) And Not D.Ref Then D.Adr := D.Adr + FOff[F]
        Else
        Begin
          DesAddr(D);
          If FOff[F] <> 0 Then Emit1(opFld, FOff[F]);
        End;
        D.Ty := FTy[F];
        Continue;
      End;
      { membre d'un objet }
      DesLoad(D);
      M := MemberCode(N);
      If M < 0 Then
      Begin
        CError('membre inconnu : ' + N);
        Exit;
      End;
      NextTok;
      D.Argc := ArgList(16);
      D.Kind := dkMember; D.Mem := M; D.Ty := TyVar;
      Continue;
    End;
    If IsSym('[') Then
    Begin
      NextTok;
      Repeat
        If Tys[D.Ty].Kind = ykArray Then
        Begin
          DesAddr(D);
          T := Expr;
          E := Tys[D.Ty].Elem;
          Emit(opIdx); Emit(Tys[D.Ty].Lo); Emit(Tys[D.Ty].Hi); Emit(TySize(E));
          D.Ty := E;
        End
        Else If Tys[D.Ty].Kind = ykStr Then
        Begin
          DesAddr(D);
          T := Expr;
          D.Kind := dkStrIdx; D.Ty := TyChar;
        End
        Else If D.Ty = TyVar Then
        Begin
          { tableau d'un objet (Split...) : element par membre par defaut }
          DesLoad(D);
          T := Expr;
          D.Kind := dkMember; D.Mem := mDefault; D.Argc := 1; D.Ty := TyVar;
        End
        Else
        Begin
          CError('indice sur une variable qui n''est pas un tableau');
          Exit;
        End;
        If IsSym(',') Then NextTok Else Break;
      Until CErr <> '';
      Expect(']');
      Continue;
    End;
    If IsSym('^') Then
    Begin
      NextTok;
      DesLoad(D);
      If Tys[D.Ty].Kind = ykPtr Then D.Ty := Tys[D.Ty].Elem Else D.Ty := TyVar;
      D.Kind := dkAddr;
      Continue;
    End;
    If IsSym('(') And ((D.Ty = TyVar) Or (D.Kind = dkMember)) Then
    Begin
      { appel du membre par defaut : Request.Form('x')(2), Session('nom') }
      DesLoad(D);
      D.Argc := ArgList(16);
      D.Kind := dkMember; D.Mem := mDefault; D.Ty := TyVar;
      Continue;
    End;
    Break;
  End;
End;

{ --- appels --- }

Procedure CallUser(S : LongInt);
Var K, N, T : LongInt; D : TDes;
Begin
  N := 0;
  If IsSym('(') Then
  Begin
    NextTok;
    If Not IsSym(')') Then
      Repeat
        If N >= Syms[S].NPar Then
        Begin
          CError('trop d''arguments pour ' + Syms[S].Name);
          Exit;
        End;
        K := Syms[S].PBase + N;
        If PRef[K] Or IsStruct(PTy[K]) Then
        Begin
          { parametre var, ou structure passee par valeur : son adresse }
          If Tok <> tkId Then
          Begin
            If PRef[K] Then CError('variable attendue pour le parametre var')
            Else Dummy := Expr;
          End
          Else
          Begin
            T := FindSym(TokS);
            If (T < 0) Or (Syms[T].Kind <> skVar) Then
            Begin
              If PRef[K] Then
              Begin
                CError('variable attendue pour le parametre var');
                Exit;
              End;
              Dummy := Expr;
            End
            Else
            Begin
              NextTok;
              DesFromSym(T, D);
              Selectors(D);
              If D.Kind = dkMember Then DesLoad(D) Else DesAddr(D);
            End;
          End;
        End
        Else
        Begin
          T := Expr;
          If TyCv(PTy[K]) <> cvVar Then Emit1(opConv, TyCv(PTy[K]));
        End;
        Inc(N);
        If IsSym(',') Then NextTok Else Break;
      Until CErr <> '';
    Expect(')');
  End;
  If N < Syms[S].NPar Then
  Begin
    CError('arguments manquants pour ' + Syms[S].Name);
    Exit;
  End;
  Emit(opCall);
  If Syms[S].Adr < 0 Then
  Begin
    { procedure declaree forward : chaine des appels a corriger }
    Emit(Syms[S].Patch);
    Syms[S].Patch := Here - 1;
  End
  Else Emit(Syms[S].Adr);
  Emit(N); Emit(CurLvl - Syms[S].Lvl);
End;

{ adresse d'une variable (parametres var des procedures predefinies) }
Function VarAddr : LongInt;
Var S : LongInt; D : TDes;
Begin
  VarAddr := TyVar;
  If Tok <> tkId Then
  Begin
    CError('variable attendue');
    Exit;
  End;
  S := FindSym(TokS);
  If (S < 0) Or (Syms[S].Kind <> skVar) Then
  Begin
    CError('variable attendue : ' + TokS);
    Exit;
  End;
  NextTok;
  DesFromSym(S, D);
  Selectors(D);
  If D.Kind = dkStrIdx Then
  Begin
    CError('variable attendue');
    Exit;
  End;
  DesAddr(D);
  VarAddr := D.Ty;
End;

{ procedures predefinies a parametres variables }
Function VarProc(N : String) : Boolean;
Var T, A : LongInt;
Begin
  VarProc := True;
  If (N = 'INC') Or (N = 'DEC') Then
  Begin
    NextTok;
    Expect('(');
    T := VarAddr;
    If IsSym(',') Then
    Begin
      NextTok;
      Dummy := Expr;
    End
    Else Emit1(opPushI, 1);
    Expect(')');
    If N = 'INC' Then Emit2(opCallB, 1000 + vInc, 2) Else Emit2(opCallB, 1000 + vDec, 2);
  End
  Else If N = 'STR' Then
  Begin
    NextTok;
    Expect('(');
    Dummy := Expr;
    A := -1;
    If IsSym(':') Then
    Begin
      NextTok;
      Dummy := Expr;
      If IsSym(':') Then
      Begin
        NextTok;
        Dummy := Expr;
      End
      Else Emit1(opPushI, -1);
    End
    Else
    Begin
      Emit1(opPushI, -1); Emit1(opPushI, -1);
    End;
    Expect(',');
    T := VarAddr;
    Expect(')');
    Emit2(opCallB, 1000 + vStr, 4);
  End
  Else If N = 'VAL' Then
  Begin
    NextTok;
    Expect('(');
    Dummy := Expr;
    Expect(',');
    T := VarAddr;
    Emit1(opPushI, TyCv(T));
    Expect(',');
    Dummy := VarAddr;
    Expect(')');
    Emit2(opCallB, 1000 + vVal, 4);
  End
  Else If N = 'DELETE' Then
  Begin
    NextTok;
    Expect('(');
    Dummy := VarAddr;
    Expect(','); Dummy := Expr;
    Expect(','); Dummy := Expr;
    Expect(')');
    Emit2(opCallB, 1000 + vDelete, 3);
  End
  Else If N = 'INSERT' Then
  Begin
    NextTok;
    Expect('(');
    Dummy := Expr;
    Expect(',');
    Dummy := VarAddr;
    Expect(','); Dummy := Expr;
    Expect(')');
    Emit2(opCallB, 1000 + vInsert, 3);
  End
  Else If N = 'SETLENGTH' Then
  Begin
    NextTok;
    Expect('(');
    Dummy := VarAddr;
    Expect(','); Dummy := Expr;
    Expect(')');
    Emit2(opCallB, 1000 + vSetLength, 2);
  End
  Else If (N = 'NEW') Or (N = 'GETMEM') Then
  Begin
    NextTok;
    Expect('(');
    T := VarAddr;
    If Tys[T].Kind = ykPtr Then Emit1(opPushI, TySize(Tys[T].Elem)) Else Emit1(opPushI, 1);
    If IsSym(',') Then
    Begin
      NextTok;
      Dummy := Expr;
      Emit(opPop);
    End;
    Expect(')');
    Emit2(opCallB, 1000 + vNew, 2);
  End
  Else If (N = 'DISPOSE') Or (N = 'FREEMEM') Then
  Begin
    NextTok;
    Expect('(');
    Dummy := Expr;
    Emit(opPop);
    If IsSym(',') Then
    Begin
      NextTok;
      Dummy := Expr;
      Emit(opPop);
    End;
    Expect(')');
  End
  Else If (N = 'INCLUDE') Or (N = 'EXCLUDE') Then
  Begin
    NextTok;
    Expect('(');
    Dummy := VarAddr;
    Expect(','); Dummy := Expr;
    Expect(')');
    If N = 'INCLUDE' Then Emit2(opCallB, 1000 + vInclude, 2) Else Emit2(opCallB, 1000 + vExclude, 2);
  End
  Else VarProc := False;
End;

{ Write et WriteLn : arguments [:largeur[:decimales]] }
Procedure CompileWrite(Ln : Boolean);
Var N : LongInt;
Begin
  NextTok;
  N := 0;
  If IsSym('(') Then
  Begin
    NextTok;
    If Not IsSym(')') Then
      Repeat
        Dummy := Expr;
        If IsSym(':') Then
        Begin
          NextTok;
          Dummy := Expr;
          If IsSym(':') Then
          Begin
            NextTok;
            Dummy := Expr;
          End
          Else Emit1(opPushI, -1);
        End
        Else
        Begin
          Emit1(opPushI, -1); Emit1(opPushI, -1);
        End;
        Emit(opWrite);
        Inc(N);
        If IsSym(',') Then NextTok Else Break;
      Until CErr <> '';
    Expect(')');
  End;
  If Ln Then Emit1(opWriteLn, N);
End;

{ Low, High, SizeOf : type ou variable }
Function TypeArg : LongInt;
Var S : LongInt; D : TDes;
Begin
  TypeArg := TyInt;
  If Tok <> tkId Then
  Begin
    CError('type ou variable attendu');
    Exit;
  End;
  S := FindSym(TokS);
  If S < 0 Then
  Begin
    CError('identificateur inconnu : ' + TokS);
    Exit;
  End;
  If Syms[S].Kind = skType Then
  Begin
    NextTok;
    TypeArg := Syms[S].Ty;
    Exit;
  End;
  If Syms[S].Kind = skVar Then
  Begin
    { variable : sans code (seul son type compte) }
    NextTok;
    TypeArg := Syms[S].Ty;
    While IsSym('[') Or IsSym('.') Do
    Begin
      If IsSym('[') Then
      Begin
        While (Tok <> tkEof) And Not IsSym(']') Do NextTok;
        NextTok;
        If Tys[Syms[S].Ty].Kind = ykArray Then TypeArg := Tys[Syms[S].Ty].Elem;
      End
      Else
      Begin
        NextTok;
        NextTok;
      End;
    End;
    Exit;
  End;
  TypeArg := Syms[S].Ty;
  NextTok;
End;

{ --- expressions --- }

Function IsOrdTy(T : LongInt) : Boolean;
Begin
  IsOrdTy := Tys[T].Kind In [ykInt, ykEnum, ykChar, ykBool];
End;

Function Factor : LongInt;
Var S, T, K, N, Bi, W : LongInt; D : TDes; Nm : String; C : TCell;
Begin
  Factor := TyVar;
  If Tok = tkInt Then
  Begin
    Emit1(opPushI, TokI);
    NextTok;
    Factor := TyInt;
    Exit;
  End;
  If Tok = tkReal Then
  Begin
    Emit1(opPushR, AddReal(TokR));
    NextTok;
    Factor := TyReal;
    Exit;
  End;
  If Tok = tkStr Then
  Begin
    If TokLen = 1 Then
    Begin
      Emit1(opPushC, Ord(TokS[1]));
      Factor := TyChar;
    End
    Else
    Begin
      Emit2(opPushS, TokOff, TokLen);
      Factor := TyStr;
    End;
    NextTok;
    Exit;
  End;
  If IsSym('(') Then
  Begin
    NextTok;
    Factor := Expr;
    Expect(')');
    Exit;
  End;
  If IsKw('NOT') Then
  Begin
    NextTok;
    T := Factor;
    Emit(opNot);
    Factor := T;
    Exit;
  End;
  If IsSym('-') Then
  Begin
    NextTok;
    T := Factor;
    Emit(opNeg);
    Factor := T;
    Exit;
  End;
  If IsSym('+') Then
  Begin
    NextTok;
    Factor := Factor;
    Exit;
  End;
  If IsSym('@') Then
  Begin
    NextTok;
    Dummy := VarAddr;
    Exit;
  End;
  If IsSym('[') Then
  Begin
    { ensemble : bits 0 a 63 }
    NextTok;
    Emit(opPushNil);
    Emit1(opConv, 9);
    If Not IsSym(']') Then
      Repeat
        T := Expr;
        If IsSym('..') Then
        Begin
          NextTok;
          Dummy := Expr;
          Emit1(opSetBit, 1);
        End
        Else Emit1(opSetBit, 0);
        If IsSym(',') Then NextTok Else Break;
      Until CErr <> '';
    Expect(']');
    Factor := TyVar;
    Exit;
  End;
  If Tok <> tkId Then
  Begin
    If Tok = tkEof Then CError('expression attendue (fin du fichier)')
    Else CError('expression attendue');
    Exit;
  End;
  Nm := TokS;
  If (Nm = 'NIL') Or (Nm = 'NOTHING') Or (Nm = 'NULL') Or (Nm = 'EMPTY') Then
  Begin
    NextTok;
    Emit(opPushNil);
    Exit;
  End;
  If (Nm = 'TRUE') Or (Nm = 'FALSE') Then
  Begin
    NextTok;
    Emit1(opPushB, Ord(Nm = 'TRUE'));
    Factor := TyBool;
    Exit;
  End;
  { champs d'un With }
  For K := NWith - 1 DownTo 0 Do
    For S := Tys[WithTy[K]].FBase To Tys[WithTy[K]].FBase + Tys[WithTy[K]].FCount - 1 Do
      If FName[S] = Nm Then
      Begin
        NextTok;
        D.Kind := dkVar; D.Ref := True; D.Adr := WithAdr[K]; D.Mode := WithMode[K]; D.Up := 0;
        If (WithMode[K] = 1) And (CurLvl <> WithTy[K + 0] * 0 + CurLvl) Then D.Mode := 1;
        D.Ty := WithTy[K];
        DesAddr(D);
        If FOff[S] <> 0 Then Emit1(opFld, FOff[S]);
        D.Ty := FTy[S];
        Selectors(D);
        DesLoad(D);
        Factor := D.Ty;
        Exit;
      End;
  S := FindSym(Nm);
  If S >= 0 Then
  Begin
    Case Syms[S].Kind Of
      skConst :
        Begin
          NextTok;
          EmitConst(Syms[S].CV);
          Factor := Syms[S].Ty;
          Exit;
        End;
      skVar :
        Begin
          NextTok;
          DesFromSym(S, D);
          Selectors(D);
          DesLoad(D);
          Factor := D.Ty;
          Exit;
        End;
      skFunc :
        Begin
          NextTok;
          CallUser(S);
          D.Kind := dkValue; D.Ty := Syms[S].RetTy;
          Selectors(D);
          DesLoad(D);
          Factor := D.Ty;
          Exit;
        End;
      skObj :
        Begin
          NextTok;
          Emit1(opIsObj, Syms[S].Adr);
          D.Kind := dkValue; D.Ty := TyVar;
          Selectors(D);
          DesLoad(D);
          Exit;
        End;
      skType :
        Begin
          { conversion de type : Integer(x), TCouleur(2), Char(65) }
          NextTok;
          T := Syms[S].Ty;
          Expect('(');
          Dummy := Expr;
          Expect(')');
          If TyCv(T) <> cvVar Then Emit1(opConv, TyCv(T));
          Factor := T;
          Exit;
        End;
      skProc :
        Begin
          CError('procedure employee dans une expression : ' + Nm);
          Exit;
        End;
    End;
  End;
  If (Nm = 'LOW') Or (Nm = 'HIGH') Or (Nm = 'SIZEOF') Then
  Begin
    NextTok;
    Expect('(');
    T := TypeArg;
    Expect(')');
    If Nm = 'SIZEOF' Then
    Begin
      If Tys[T].Kind In [ykInt, ykBool, ykChar, ykReal, ykEnum] Then N := Tys[T].FBase
      Else If Tys[T].Kind = ykStr Then N := 256
      Else N := TySize(T) * 4;
      If N = 0 Then N := 4;
      Emit1(opPushI, N);
      Factor := TyInt;
    End
    Else
    Begin
      If Nm = 'LOW' Then N := Tys[T].Lo Else N := Tys[T].Hi;
      If Tys[T].Kind = ykChar Then
      Begin
        Emit1(opPushC, N And 255);
        Factor := TyChar;
      End
      Else If Tys[T].Kind = ykBool Then
      Begin
        Emit1(opPushB, N);
        Factor := TyBool;
      End
      Else
      Begin
        Emit1(opPushI, N);
        Factor := TyInt;
      End;
    End;
    Exit;
  End;
  Bi := FindBi(Nm);
  If Bi > 0 Then
  Begin
    NextTok;
    N := ArgList(16);
    If (N < Bis[Bi].MinA) Or (N > Bis[Bi].MaxA) Then
    Begin
      CError('nombre d''arguments incorrect pour ' + Nm);
      Exit;
    End;
    Emit2(opCallB, Bis[Bi].Id, N);
    If Bis[Bi].Ret < 0 Then Emit(opPushNil);
    Factor := Bis[Bi].Ret;
    If Bis[Bi].Ret < 0 Then Factor := TyVar;
    D.Kind := dkValue; D.Ty := TyVar;
    If (Bis[Bi].Id = bCreateObject) And (IsSym('.') Or IsSym('(')) Then
    Begin
      Selectors(D);
      DesLoad(D);
    End;
    Exit;
  End;
  CError('identificateur inconnu : ' + Nm);
End;

Function ResTy(A, B : LongInt) : LongInt;
Begin
  If (A = TyReal) Or (B = TyReal) Then ResTy := TyReal
  Else If IsOrdTy(A) And IsOrdTy(B) And (Tys[A].Kind = ykInt) And (Tys[B].Kind = ykInt) Then ResTy := TyInt
  Else ResTy := TyVar;
End;

Function Term : LongInt;
Var T, U, J : LongInt; Op : String;
Begin
  T := Factor;
  While (CErr = '') And (IsSym('*') Or IsSym('/') Or IsKw('DIV') Or IsKw('MOD') Or IsKw('AND') Or IsKw('SHL') Or
        IsKw('SHR')) Do
  Begin
    Op := TokS;
    NextTok;
    If (Op = 'AND') And (T = TyBool) Then
    Begin
      { et logique court-circuite }
      Emit(opDup);
      Emit1(opJz, 0);
      J := Here - 1;
      Emit(opPop);
      U := Factor;
      PatchAt(J, Here);
      T := TyBool;
      Continue;
    End;
    U := Factor;
    If Op = '*' Then
    Begin
      Emit(opMul);
      T := ResTy(T, U);
    End
    Else If Op = '/' Then
    Begin
      Emit(opDivR);
      T := TyReal;
    End
    Else If Op = 'DIV' Then
    Begin
      Emit(opIDiv);
      T := TyInt;
    End
    Else If Op = 'MOD' Then
    Begin
      Emit(opMod);
      T := TyInt;
    End
    Else If Op = 'AND' Then
    Begin
      Emit(opAnd);
      If (T = TyBool) Or (U = TyBool) Then T := TyBool Else T := ResTy(T, U);
    End
    Else If Op = 'SHL' Then
    Begin
      Emit(opShl);
      T := TyInt;
    End
    Else
    Begin
      Emit(opShr);
      T := TyInt;
    End;
  End;
  Term := T;
End;

Function SimpleExpr : LongInt;
Var T, U, J : LongInt; Op : String;
Begin
  T := Term;
  While (CErr = '') And (IsSym('+') Or IsSym('-') Or IsKw('OR') Or IsKw('XOR')) Do
  Begin
    Op := TokS;
    NextTok;
    If (Op = 'OR') And (T = TyBool) Then
    Begin
      Emit(opDup);
      Emit1(opJnz, 0);
      J := Here - 1;
      Emit(opPop);
      U := Term;
      PatchAt(J, Here);
      T := TyBool;
      Continue;
    End;
    U := Term;
    If Op = '+' Then
    Begin
      Emit(opAdd);
      If (T = TyStr) Or (U = TyStr) Or (T = TyChar) Or (U = TyChar) Then T := TyStr Else T := ResTy(T, U);
    End
    Else If Op = '-' Then
    Begin
      Emit(opSub);
      T := ResTy(T, U);
    End
    Else If Op = 'OR' Then
    Begin
      Emit(opOr);
      If (T = TyBool) Or (U = TyBool) Then T := TyBool Else T := ResTy(T, U);
    End
    Else
    Begin
      Emit(opXor);
      If (T = TyBool) Or (U = TyBool) Then T := TyBool Else T := ResTy(T, U);
    End;
  End;
  SimpleExpr := T;
End;

Function Expr : LongInt;
Var T, U, Tmp, N : LongInt; Op : String;
Begin
  T := SimpleExpr;
  If (CErr = '') And (IsSym('=') Or IsSym('<>') Or IsSym('<') Or IsSym('<=') Or IsSym('>') Or IsSym('>=')) Then
  Begin
    Op := TokS;
    NextTok;
    U := SimpleExpr;
    If Op = '=' Then Emit(opEq)
    Else If Op = '<>' Then Emit(opNe)
    Else If Op = '<' Then Emit(opLt)
    Else If Op = '<=' Then Emit(opLe)
    Else If Op = '>' Then Emit(opGt)
    Else Emit(opGe);
    T := TyBool;
  End
  Else If (CErr = '') And IsKw('IN') Then
  Begin
    NextTok;
    If IsSym('[') Then
    Begin
      { x in [a, b..c] : comparaisons }
      NextTok;
      Tmp := AllocVar(1);
      If CurLvl = 0 Then Emit1(opStG, Tmp) Else Emit1(opStL, Tmp);
      Emit1(opPushB, 0);
      N := 0;
      If Not IsSym(']') Then
        Repeat
          If CurLvl = 0 Then Emit1(opLdG, Tmp) Else Emit1(opLdL, Tmp);
          Dummy := Expr;
          If IsSym('..') Then
          Begin
            NextTok;
            Emit(opGe);
            If CurLvl = 0 Then Emit1(opLdG, Tmp) Else Emit1(opLdL, Tmp);
            Dummy := Expr;
            Emit(opLe);
            Emit(opAnd);
          End
          Else Emit(opEq);
          Emit(opOr);
          Inc(N);
          If IsSym(',') Then NextTok Else Break;
        Until CErr <> '';
      Expect(']');
    End
    Else
    Begin
      Dummy := SimpleExpr;
      Emit(opInSet);
    End;
    T := TyBool;
  End;
  Expr := T;
End;

{ --- instructions --- }

Procedure Statement; Forward;
Procedure Declarations(Root : Boolean); Forward;

Procedure StmtList(Stop1, Stop2 : String);
Begin
  While (CErr = '') And (Tok <> tkEof) And Not IsKw(Stop1) And Not IsKw(Stop2) Do
  Begin
    Statement;
    If IsSym(';') Then NextTok
    Else If (Tok <> tkHtml) And (Tok <> tkEcho) And Not IsKw(Stop1) And Not IsKw(Stop2) And (CErr = '') And
            Not LastHtml Then
    Begin
      { instruction sans point-virgule devant du HTML : permis }
      If Tok = tkEof Then Exit;
      CError(''';'' attendu');
    End;
  End;
End;

Procedure PushTmp(Tmp : LongInt);
Begin
  If CurLvl = 0 Then Emit1(opLdG, Tmp) Else Emit1(opLdL, Tmp);
End;

Procedure PopTmp(Tmp : LongInt);
Begin
  If CurLvl = 0 Then Emit1(opStG, Tmp) Else Emit1(opStL, Tmp);
End;

Procedure BeginLoop;
Begin
  Inc(LoopDepth);
  BreakChain[LoopDepth] := -1; ContChain[LoopDepth] := -1;
End;

{ resoudre les sauts d'une chaine (chaque operande pointe le suivant) }
Procedure PatchChain(Ch, Target : LongInt);
Var N : LongInt;
Begin
  While Ch >= 0 Do
  Begin
    N := Pages[CP].Code^[Ch];
    Pages[CP].Code^[Ch] := Target;
    Ch := N;
  End;
End;

Procedure EndLoop(ContTarget, BreakTarget : LongInt);
Begin
  PatchChain(ContChain[LoopDepth], ContTarget);
  PatchChain(BreakChain[LoopDepth], BreakTarget);
  Dec(LoopDepth);
End;

Procedure AssignTo(Var D : TDes);
Var T, Op : LongInt; S : String;
Begin
  If IsSym(':=') Then
  Begin
    NextTok;
    If (D.Kind = dkVar) And D.Ref Then DesAddr(D);
    If (D.Kind = dkAddr) And IsStruct(D.Ty) Then
    Begin
      { structure : copie d'une autre }
      T := Expr;
      Emit1(opCopy, TySize(D.Ty));
      Exit;
    End;
    T := Expr;
    DesStore(D);
  End
  Else If IsSym('+=') Or IsSym('-=') Or IsSym('*=') Or IsSym('/=') Then
  Begin
    S := TokS;
    NextTok;
    If D.Kind = dkVar Then
    Begin
      If D.Ref Then DesAddr(D);
    End;
    If D.Kind = dkAddr Then Emit(opDup);
    If D.Kind = dkVar Then EmitSlotLoad(D) Else Emit(opLdInd);
    T := Expr;
    If S = '+=' Then Emit(opAdd) Else If S = '-=' Then Emit(opSub) Else If S = '*=' Then Emit(opMul)
    Else Emit(opDivR);
    DesStore(D);
  End
  Else If D.Kind = dkMember Then
  Begin
    { appel de methode : Response.Write('...'), dict.Add(k, v) }
    Emit2(opMember, D.Mem, D.Argc);
    Emit(opPop);
  End
  Else CError(''':='' attendu');
End;

Procedure Statement;
Var S, T, J, J2, L0, Tmp, Tmp2, K, N, Up, Save, WSave : LongInt; D : TDes; Down : Boolean; Nm : String; C : TCell;
Begin
  If CErr <> '' Then Exit;
  EmitLine;
  LastHtml := False;
  If Tok = tkHtml Then
  Begin
    Emit2(opHtml, AddStrB(@Src.P^[TokOff], TokLen), TokLen);
    NextTok;
    LastHtml := True;
    Exit;
  End;
  If Tok = tkEcho Then
  Begin
    LastHtml := True;
    NextTok;
    Dummy := Expr;
    Emit1(opPushI, -1); Emit1(opPushI, -1);
    Emit(opWrite);
    If IsSym(';') Then NextTok;
    If Tok = tkEchoEnd Then NextTok Else CError('''%>'' attendu');
    Exit;
  End;
  If IsSym(';') Or IsKw('END') Then Exit;
  If Tok <> tkId Then
  Begin
    CError('instruction attendue');
    Exit;
  End;
  Nm := TokS;
  If Nm = 'BEGIN' Then
  Begin
    NextTok;
    StmtList('END', 'END');
    Expect('END');
    Exit;
  End;
  If Nm = 'IF' Then
  Begin
    NextTok;
    Dummy := Expr;
    Expect('THEN');
    Emit1(opJz, 0);
    J := Here - 1;
    If Not IsKw('ELSE') Then Statement;
    If IsSym(';') And Not InHtml Then
    Begin
      { ... ; else (permis entre des blocs <% %>) }
    End;
    If IsKw('ELSE') Then
    Begin
      Emit1(opJmp, 0);
      J2 := Here - 1;
      PatchAt(J, Here);
      NextTok;
      Statement;
      PatchAt(J2, Here);
    End
    Else PatchAt(J, Here);
    Exit;
  End;
  If Nm = 'WHILE' Then
  Begin
    NextTok;
    L0 := Here;
    Dummy := Expr;
    Expect('DO');
    Emit1(opJz, 0);
    J := Here - 1;
    BeginLoop;
    Statement;
    Emit1(opJmp, L0);
    PatchAt(J, Here);
    EndLoop(L0, Here);
    Exit;
  End;
  If Nm = 'REPEAT' Then
  Begin
    NextTok;
    L0 := Here;
    BeginLoop;
    StmtList('UNTIL', 'UNTIL');
    Expect('UNTIL');
    J := Here;
    Dummy := Expr;
    Emit1(opJz, L0);
    EndLoop(J, Here);
    Exit;
  End;
  If Nm = 'FOR' Then
  Begin
    NextTok;
    If Tok <> tkId Then
    Begin
      CError('variable de boucle attendue');
      Exit;
    End;
    S := FindSym(TokS);
    If (S < 0) Or (Syms[S].Kind <> skVar) Then
    Begin
      CError('variable de boucle attendue : ' + TokS);
      Exit;
    End;
    NextTok;
    DesFromSym(S, D);
    Expect(':=');
    If D.Ref Then
    Begin
      CError('la variable de boucle doit etre une variable simple');
      Exit;
    End;
    Dummy := Expr;
    DesStore(D);
    Down := IsKw('DOWNTO');
    If Not Down Then Expect('TO') Else NextTok;
    Tmp := AllocVar(1);
    Dummy := Expr;
    PopTmp(Tmp);
    Expect('DO');
    L0 := Here;
    D.Kind := dkVar;
    EmitSlotLoad(D);
    PushTmp(Tmp);
    If Down Then Emit(opLt) Else Emit(opGt);
    Emit1(opJnz, 0);
    J := Here - 1;
    BeginLoop;
    Statement;
    J2 := Here;
    EmitSlotLoad(D);
    Emit1(opPushI, 1);
    If Down Then Emit(opSub) Else Emit(opAdd);
    DesStore(D);
    Emit1(opJmp, L0);
    PatchAt(J, Here);
    EndLoop(J2, Here);
    Exit;
  End;
  If Nm = 'CASE' Then
  Begin
    NextTok;
    Tmp := AllocVar(1);
    Dummy := Expr;
    PopTmp(Tmp);
    Expect('OF');
    Tmp2 := -1;    { chaine des sauts vers la fin }
    While (CErr = '') And Not IsKw('END') And Not IsKw('ELSE') And Not IsKw('OTHERWISE') Do
    Begin
      Emit1(opPushB, 0);
      Repeat
        PushTmp(Tmp);
        T := ConstExpr(C);
        EmitConst(C);
        If IsSym('..') Then
        Begin
          NextTok;
          Emit(opGe);
          PushTmp(Tmp);
          T := ConstExpr(C);
          EmitConst(C);
          Emit(opLe);
          Emit(opAnd);
        End
        Else Emit(opEq);
        Emit(opOr);
        If IsSym(',') Then NextTok Else Break;
      Until CErr <> '';
      Expect(':');
      Emit1(opJz, 0);
      J := Here - 1;
      Statement;
      Emit1(opJmp, Tmp2);
      Tmp2 := Here - 1;
      PatchAt(J, Here);
      If IsSym(';') Then NextTok;
    End;
    If IsKw('ELSE') Or IsKw('OTHERWISE') Then
    Begin
      NextTok;
      StmtList('END', 'END');
    End;
    Expect('END');
    PatchChain(Tmp2, Here);
    Exit;
  End;
  If Nm = 'WITH' Then
  Begin
    NextTok;
    WSave := NWith;
    Repeat
      If Tok <> tkId Then
      Begin
        CError('variable attendue');
        Exit;
      End;
      S := FindSym(TokS);
      If (S < 0) Or (Syms[S].Kind <> skVar) Then
      Begin
        CError('variable attendue : ' + TokS);
        Exit;
      End;
      NextTok;
      DesFromSym(S, D);
      Selectors(D);
      If Tys[D.Ty].Kind <> ykRec Then
      Begin
        CError('enregistrement attendu dans With');
        Exit;
      End;
      DesAddr(D);
      Tmp := AllocVar(1);
      PopTmp(Tmp);
      If NWith < 8 Then
      Begin
        WithAdr[NWith] := Tmp; WithTy[NWith] := D.Ty;
        If CurLvl = 0 Then WithMode[NWith] := 0 Else WithMode[NWith] := 1;
        Inc(NWith);
      End;
      If IsSym(',') Then NextTok Else Break;
    Until CErr <> '';
    Expect('DO');
    Statement;
    NWith := WSave;
    Exit;
  End;
  If Nm = 'EXIT' Then
  Begin
    NextTok;
    If IsSym('(') And (CurFunc >= 0) Then
    Begin
      NextTok;
      Dummy := Expr;
      Expect(')');
      If TyCv(Syms[CurFunc].RetTy) <> cvVar Then Emit1(opConv, TyCv(Syms[CurFunc].RetTy));
      Emit1(opStL, 3);
    End;
    If CurLvl = 0 Then Emit(opHalt)
    Else
    Begin
      Emit1(opJmp, 0);
      If NExit < 64 Then
      Begin
        ExitList[NExit] := Here - 1;
        Inc(NExit);
      End;
    End;
    Exit;
  End;
  If (Nm = 'BREAK') Or (Nm = 'CONTINUE') Then
  Begin
    NextTok;
    If LoopDepth = 0 Then
    Begin
      CError(Nm + ' hors d''une boucle');
      Exit;
    End;
    If Nm = 'BREAK' Then
    Begin
      Emit1(opJmp, BreakChain[LoopDepth]);
      BreakChain[LoopDepth] := Here - 1;
    End
    Else
    Begin
      Emit1(opJmp, ContChain[LoopDepth]);
      ContChain[LoopDepth] := Here - 1;
    End;
    Exit;
  End;
  If Nm = 'HALT' Then
  Begin
    NextTok;
    If IsSym('(') Then
    Begin
      NextTok;
      Dummy := Expr;
      Emit(opPop);
      Expect(')');
    End;
    Emit(opHalt);
    Exit;
  End;
  If (Nm = 'WRITE') Or (Nm = 'WRITELN') Then
  Begin
    CompileWrite(Nm = 'WRITELN');
    Exit;
  End;
  If (Nm = 'VAR') Or (Nm = 'CONST') Or (Nm = 'TYPE') Then
  Begin
    Declarations(CurLvl = 0);
    LastHtml := True;
    Exit;
  End;
  If (Nm = 'GOTO') Or (Nm = 'LABEL') Then
  Begin
    CError(Nm + ' n''est pas pris en charge');
    Exit;
  End;
  { champs d'un With }
  For K := NWith - 1 DownTo 0 Do
    For S := Tys[WithTy[K]].FBase To Tys[WithTy[K]].FBase + Tys[WithTy[K]].FCount - 1 Do
      If FName[S] = Nm Then
      Begin
        NextTok;
        D.Kind := dkVar; D.Ref := True; D.Adr := WithAdr[K]; D.Mode := WithMode[K]; D.Up := 0;
        D.Ty := WithTy[K];
        DesAddr(D);
        If FOff[S] <> 0 Then Emit1(opFld, FOff[S]);
        D.Ty := FTy[S];
        Selectors(D);
        AssignTo(D);
        Exit;
      End;
  S := FindSym(Nm);
  If S >= 0 Then
  Begin
    Case Syms[S].Kind Of
      skVar :
        Begin
          NextTok;
          DesFromSym(S, D);
          Selectors(D);
          AssignTo(D);
          Exit;
        End;
      skProc :
        Begin
          NextTok;
          CallUser(S);
          Exit;
        End;
      skFunc :
        Begin
          NextTok;
          If IsSym(':=') Then
          Begin
            { resultat de la fonction (elle-meme ou une fonction englobante) }
            NextTok;
            Dummy := Expr;
            If TyCv(Syms[S].RetTy) <> cvVar Then Emit1(opConv, TyCv(Syms[S].RetTy));
            Up := CurLvl - (Syms[S].Lvl + 1);
            If Up = 0 Then Emit1(opStL, 3) Else If Up > 0 Then Emit2(opStUp, Up, 3)
            Else CError('affectation du resultat hors de la fonction ' + Nm);
            Exit;
          End;
          CallUser(S);
          D.Kind := dkValue; D.Ty := Syms[S].RetTy;
          Selectors(D);
          If D.Kind = dkMember Then AssignTo(D) Else Emit(opPop);
          Exit;
        End;
      skObj :
        Begin
          NextTok;
          Emit1(opIsObj, Syms[S].Adr);
          D.Kind := dkValue; D.Ty := TyVar;
          Selectors(D);
          If D.Kind = dkMember Then AssignTo(D)
          Else Emit(opPop);
          Exit;
        End;
    End;
  End;
  If VarProc(Nm) Then Exit;
  K := FindBi(Nm);
  If K > 0 Then
  Begin
    NextTok;
    N := ArgList(16);
    Emit2(opCallB, Bis[K].Id, N);
    If Bis[K].Ret >= 0 Then Emit(opPop);
    Exit;
  End;
  If S >= 0 Then CError('instruction attendue : ' + Nm)
  Else CError('identificateur inconnu : ' + Nm);
End;

{ --- declarations --- }

{ valeur initiale d'une constante typee ou d'une variable : (a, b, ...) }
Procedure InitValue(Mode, Off, T : LongInt);
Var K, F : LongInt; N : String;
Begin
  If Tys[T].Kind = ykArray Then
  Begin
    Expect('(');
    For K := 0 To Tys[T].Hi - Tys[T].Lo Do
    Begin
      InitValue(Mode, Off + K * TySize(Tys[T].Elem), Tys[T].Elem);
      If K < Tys[T].Hi - Tys[T].Lo Then Expect(',');
    End;
    Expect(')');
  End
  Else If Tys[T].Kind = ykRec Then
  Begin
    Expect('(');
    While (CErr = '') And Not IsSym(')') Do
    Begin
      N := ExpectId;
      Expect(':');
      F := -1;
      For K := Tys[T].FBase To Tys[T].FBase + Tys[T].FCount - 1 Do
        If FName[K] = N Then F := K;
      If F < 0 Then
      Begin
        CError('champ inconnu : ' + N);
        Exit;
      End;
      InitValue(Mode, Off + FOff[F], FTy[F]);
      If IsSym(';') Then NextTok Else Break;
    End;
    Expect(')');
  End
  Else
  Begin
    Dummy := Expr;
    If TyCv(T) <> cvVar Then Emit1(opConv, TyCv(T));
    If Mode = 0 Then Emit1(opStG, Off) Else Emit1(opStL, Off);
  End;
End;

Type
  TLexSave = Record
    P, L, Tk, I, Off, Len, Ln : LongInt;
    H, E : Boolean;
    S : String;
    R : Double;
  End;

Procedure LexSave(Var X : TLexSave);
Begin
  X.P := SPos; X.L := SLine; X.H := InHtml; X.E := InEcho; X.Tk := Tok; X.S := TokS; X.I := TokI; X.R := TokR;
  X.Off := TokOff; X.Len := TokLen; X.Ln := TokLine;
End;

Procedure LexRestore(Var X : TLexSave);
Begin
  SPos := X.P; SLine := X.L; InHtml := X.H; InEcho := X.E; Tok := X.Tk; TokS := X.S; TokI := X.I; TokR := X.R;
  TokOff := X.Off; TokLen := X.Len; TokLine := X.Ln;
End;

{ lexeme suivant (sans avancer) }
Function PeekSym : String;
Var X : TLexSave;
Begin
  LexSave(X);
  NextTok;
  If (Tok = tkSym) Or (Tok = tkId) Then PeekSym := TokS Else PeekSym := '';
  LexRestore(X);
End;

Function IsReserved(S : String) : Boolean;
Begin
  IsReserved := (S = 'BEGIN') Or (S = 'END') Or (S = 'VAR') Or (S = 'CONST') Or (S = 'TYPE') Or
                (S = 'PROCEDURE') Or (S = 'FUNCTION') Or (S = 'IF') Or (S = 'WHILE') Or (S = 'FOR') Or
                (S = 'REPEAT') Or (S = 'CASE') Or (S = 'WITH') Or (S = 'LABEL') Or (S = 'USES') Or (S = 'PROGRAM');
End;

Procedure ProcDecl(IsFunc : Boolean);
Var S, K, N, T, Cnt, J, Save, SLoc, SMax, SFunc, SNExit, SNWith, SLoop, EnterAt, P, Area : LongInt;
    Nm : String; Names : Array[0..31] Of String[31]; IsRef : Boolean; Ex : Array[0..63] Of LongInt;
Begin
  NextTok;
  Nm := ExpectId;
  If CErr <> '' Then Exit;
  S := -1;
  For K := NSym - 1 DownTo 0 Do
    If (Syms[K].Name = Nm) And (Syms[K].Lvl = CurLvl) And ((Syms[K].Kind = skProc) Or (Syms[K].Kind = skFunc)) And
       (Syms[K].Adr < 0) Then
    Begin
      S := K;
      Break;
    End;
  If S < 0 Then
  Begin
    If IsFunc Then S := AddSym(Nm, skFunc) Else S := AddSym(Nm, skProc);
    Syms[S].Adr := -1;
    Syms[S].PBase := NParT;
    N := 0;
    If IsSym('(') Then
    Begin
      NextTok;
      While (CErr = '') And Not IsSym(')') Do
      Begin
        IsRef := False;
        If IsKw('VAR') Or IsKw('OUT') Then
        Begin
          IsRef := True;
          NextTok;
        End
        Else If IsKw('CONST') Then NextTok;
        Cnt := 0;
        Repeat
          Names[Cnt] := ExpectId;
          If Cnt < 31 Then Inc(Cnt);
          If IsSym(',') Then NextTok Else Break;
        Until CErr <> '';
        If IsSym(':') Then
        Begin
          NextTok;
          T := ParseType;
        End
        Else T := TyVar;
        For K := 0 To Cnt - 1 Do
        Begin
          If NParT >= MaxPar Then
          Begin
            CError('trop de parametres');
            Exit;
          End;
          PTy[NParT] := T; PRef[NParT] := IsRef; PName[NParT] := Names[K];
          Inc(NParT);
          Inc(N);
        End;
        If IsSym(';') Then NextTok Else Break;
      End;
      Expect(')');
    End;
    Syms[S].NPar := N;
    If IsFunc Then
    Begin
      Expect(':');
      Syms[S].RetTy := ParseType;
    End
    Else Syms[S].RetTy := -1;
    Syms[S].Ty := TyVar;
    If IsFunc Then Syms[S].Ty := Syms[S].RetTy;
    Expect(';');
  End
  Else
  Begin
    { definition d'une procedure declaree forward : en-tete repete ou non }
    If IsSym('(') Then
    Begin
      While (CErr = '') And Not IsSym(')') And (Tok <> tkEof) Do NextTok;
      NextTok;
    End;
    If IsSym(':') Then
    Begin
      NextTok;
      Dummy := ParseType;
    End;
    Expect(';');
  End;
  If IsKw('FORWARD') Then
  Begin
    NextTok;
    Expect(';');
    Exit;
  End;
  { corps : saute par le code qui l'entoure }
  Emit1(opJmp, 0);
  J := Here - 1;
  Syms[S].Adr := Here;
  PatchChain(Syms[S].Patch, Here);
  Syms[S].Patch := -1;
  Save := NSym; SLoc := LocTop; SMax := LocMax; SFunc := CurFunc; SNExit := NExit; SNWith := NWith; SLoop := LoopDepth;
  For K := 0 To NExit - 1 Do Ex[K] := ExitList[K];
  Inc(CurLvl);
  NExit := 0; NWith := 0; LoopDepth := 0;
  LocTop := 4 + Syms[S].NPar; LocMax := LocTop;
  If IsFunc Then CurFunc := S Else CurFunc := -1;
  Emit2(opEnter, 0, Syms[S].NPar);
  EnterAt := Here - 2;
  For K := 0 To Syms[S].NPar - 1 Do
  Begin
    P := Syms[S].PBase + K;
    T := AddSym(PName[P], skVar);
    Syms[T].Ty := PTy[P]; Syms[T].Lvl := CurLvl;
    If PRef[P] Then
    Begin
      Syms[T].Adr := 4 + K; Syms[T].Ref := True;
    End
    Else If IsStruct(PTy[P]) Then
    Begin
      { structure par valeur : copie locale }
      Area := AllocVar(TySize(PTy[P]));
      Emit1(opLdLA, Area);
      Emit1(opLdL, 4 + K);
      Emit1(opCopy, TySize(PTy[P]));
      Syms[T].Adr := Area;
    End
    Else Syms[T].Adr := 4 + K;
  End;
  If IsFunc Then
  Begin
    T := AddSym('RESULT', skVar);
    Syms[T].Ty := Syms[S].RetTy; Syms[T].Lvl := CurLvl; Syms[T].Adr := 3;
    If Not IsStruct(Syms[S].RetTy) Then EmitInit(1, 3, Syms[S].RetTy, 1, 1);
  End;
  Declarations(False);
  Expect('BEGIN');
  StmtList('END', 'END');
  Expect('END');
  For K := 0 To NExit - 1 Do PatchAt(ExitList[K], Here);
  Emit1(opRet, Ord(IsFunc));
  PatchAt(EnterAt, LocMax);
  NSym := Save;
  Dec(CurLvl);
  LocTop := SLoc; LocMax := SMax; CurFunc := SFunc; NExit := SNExit; NWith := SNWith; LoopDepth := SLoop;
  For K := 0 To NExit - 1 Do ExitList[K] := Ex[K];
  If IsSym(';') Then NextTok;
  PatchAt(J, Here);
End;

Procedure VarSection;
Var Cnt, K, T, A, S : LongInt; Names : Array[0..31] Of String[31]; Mode : LongInt;
Begin
  NextTok;
  If CurLvl = 0 Then Mode := 0 Else Mode := 1;
  While (CErr = '') And (Tok = tkId) And Not IsReserved(TokS) Do
  Begin
    If (PeekSym <> ':') And (PeekSym <> ',') Then Exit;
    Cnt := 0;
    Repeat
      Names[Cnt] := ExpectId;
      If Cnt < 31 Then Inc(Cnt);
      If IsSym(',') Then NextTok Else Break;
    Until CErr <> '';
    Expect(':');
    T := ParseType;
    For K := 0 To Cnt - 1 Do
    Begin
      A := AllocVar(TySize(T));
      S := AddSym(Names[K], skVar);
      Syms[S].Ty := T; Syms[S].Adr := A;
      EmitInit(Mode, A, T, 1, 1);
      If (K = Cnt - 1) And (IsSym('=') Or IsKw('ABSOLUTE')) Then
      Begin
        NextTok;
        InitValue(Mode, A, T);
      End;
    End;
    Expect(';');
  End;
End;

Procedure ConstSection;
Var S, T, A, Mode : LongInt; Nm, Nx : String; C : TCell;
Begin
  NextTok;
  If CurLvl = 0 Then Mode := 0 Else Mode := 1;
  While (CErr = '') And (Tok = tkId) And Not IsReserved(TokS) Do
  Begin
    Nx := PeekSym;
    If (Nx <> '=') And (Nx <> ':') Then Exit;
    Nm := ExpectId;
    If IsSym(':') Then
    Begin
      { constante typee : variable initialisee }
      NextTok;
      T := ParseType;
      Expect('=');
      A := AllocVar(TySize(T));
      S := AddSym(Nm, skVar);
      Syms[S].Ty := T; Syms[S].Adr := A;
      EmitInit(Mode, A, T, 1, 1);
      If IsStruct(T) Then InitValue(Mode, A, T)
      Else
      Begin
        { constante typee simple : sa valeur sert aussi aux expressions
          constantes }
        Dummy := ConstExpr(C);
        EmitConst(C);
        If TyCv(T) <> cvVar Then Emit1(opConv, TyCv(T));
        If Mode = 0 Then Emit1(opStG, A) Else Emit1(opStL, A);
        Syms[S].CV := C; Syms[S].Patch := -2;
      End;
    End
    Else
    Begin
      Expect('=');
      T := ConstExpr(C);
      S := AddSym(Nm, skConst);
      Syms[S].CV := C; Syms[S].Ty := T;
    End;
    Expect(';');
  End;
End;

Procedure TypeSection;
Var S, T : LongInt; Nm : String;
Begin
  NextTok;
  While (CErr = '') And (Tok = tkId) And Not IsReserved(TokS) Do
  Begin
    If PeekSym <> '=' Then Exit;
    Nm := ExpectId;
    Expect('=');
    S := AddSym(Nm, skType);
    Syms[S].Ty := TyVar;
    T := ParseType;
    Syms[S].Ty := T;
    Expect(';');
  End;
End;

Procedure Declarations(Root : Boolean);
Begin
  While CErr = '' Do
  Begin
    If IsKw('VAR') Then VarSection
    Else If IsKw('CONST') Then ConstSection
    Else If IsKw('TYPE') Then TypeSection
    Else If IsKw('PROCEDURE') Then ProcDecl(False)
    Else If IsKw('FUNCTION') Then ProcDecl(True)
    Else If IsKw('LABEL') Or IsKw('USES') Then
    Begin
      While (CErr = '') And Not IsSym(';') And (Tok <> tkEof) Do NextTok;
      NextTok;
    End
    Else Exit;
  End;
End;

{ types et symboles predefinis }
Procedure PredefSyms;
Var S, T : LongInt;

  Procedure AddTy(Nm : String; Ty, Lo, Hi, PSize : LongInt);
  Var X, K : LongInt;
  Begin
    K := NewTy(Tys[Ty].Kind, 1);
    Tys[K].Lo := Lo; Tys[K].Hi := Hi; Tys[K].FBase := PSize;
    X := AddSym(Nm, skType);
    Syms[X].Ty := K;
  End;

  Procedure AddObj(Nm : String; Id : LongInt);
  Var X : LongInt;
  Begin
    X := AddSym(Nm, skObj);
    Syms[X].Adr := Id; Syms[X].Ty := TyVar;
  End;

Begin
  NTy := 0; NSym := 0; NFld := 0; NParT := 0;
  T := NewTy(ykInt, 1); Tys[T].Lo := -2147483647 - 1; Tys[T].Hi := 2147483647; Tys[T].FBase := 4;
  T := NewTy(ykReal, 1); Tys[T].FBase := 8;
  T := NewTy(ykBool, 1); Tys[T].Lo := 0; Tys[T].Hi := 1; Tys[T].FBase := 1;
  T := NewTy(ykChar, 1); Tys[T].Lo := 0; Tys[T].Hi := 255; Tys[T].FBase := 1;
  T := NewTy(ykStr, 1); Tys[T].FBase := 256;
  T := NewTy(ykVar, 1); Tys[T].FBase := 16;
  AddTy('INTEGER', TyInt, -32768, 32767, 2);
  AddTy('SMALLINT', TyInt, -32768, 32767, 2);
  AddTy('SHORTINT', TyInt, -128, 127, 1);
  AddTy('BYTE', TyInt, 0, 255, 1);
  AddTy('WORD', TyInt, 0, 65535, 2);
  AddTy('LONGINT', TyInt, -2147483647 - 1, 2147483647, 4);
  AddTy('CARDINAL', TyInt, 0, 2147483647, 4);
  AddTy('LONGWORD', TyInt, 0, 2147483647, 4);
  AddTy('INT64', TyInt, -2147483647 - 1, 2147483647, 8);
  AddTy('REAL', TyReal, 0, 0, 6);
  AddTy('DOUBLE', TyReal, 0, 0, 8);
  AddTy('SINGLE', TyReal, 0, 0, 4);
  AddTy('EXTENDED', TyReal, 0, 0, 10);
  AddTy('CURRENCY', TyReal, 0, 0, 8);
  AddTy('BOOLEAN', TyBool, 0, 1, 1);
  AddTy('CHAR', TyChar, 0, 255, 1);
  S := AddSym('STRING', skType); Syms[S].Ty := TyStr;
  S := AddSym('SHORTSTRING', skType); Syms[S].Ty := TyStr;
  S := AddSym('ANSISTRING', skType); Syms[S].Ty := TyStr;
  S := AddSym('VARIANT', skType); Syms[S].Ty := TyVar;
  S := AddSym('OBJECT', skType); Syms[S].Ty := TyVar;
  S := AddSym('POINTER', skType); Syms[S].Ty := TyVar;
  S := AddSym('TEXT', skType); Syms[S].Ty := TyVar;
  S := AddSym('MAXINT', skConst); MkInt(32767, Syms[S].CV); Syms[S].Ty := TyInt;
  S := AddSym('MAXLONGINT', skConst); MkInt(2147483647, Syms[S].CV); Syms[S].Ty := TyInt;
  AddObj('REQUEST', obRequest);
  AddObj('RESPONSE', obResponse);
  AddObj('SERVER', obServer);
  AddObj('SESSION', obSession);
  AddObj('APPLICATION', obApplication);
  AddObj('DATABASE', obDatabase);
  { types des objets des bases de donnees }
  S := AddSym('DATABASECONNECTION', skType); Syms[S].Ty := TyVar;
  S := AddSym('TDATABASECONNECTION', skType); Syms[S].Ty := TyVar;
  S := AddSym('RECORDSET', skType); Syms[S].Ty := TyVar;
  S := AddSym('TRECORDSET', skType); Syms[S].Ty := TyVar;
  S := AddSym('DATASET', skType); Syms[S].Ty := TyVar;
End;

Procedure ResetPage(K : LongInt);
Begin
  With Pages[K] Do
  Begin
    If Code <> Nil Then FreeMem(Code, CodeCap * 4);
    If Reals <> Nil Then FreeMem(Reals, RealCap * 8);
    If Lines <> Nil Then FreeMem(Lines, LineCap * 4);
    BufFree(Strs);
    Code := Nil; Reals := Nil; Lines := Nil;
    NCode := 0; CodeCap := 0; NReal := 0; RealCap := 0; NLine := 0; LineCap := 0;
    Used := False;
  End;
End;

{ compiler une page PSP dans Pages[K] ; '' si tout va bien }
Function CompilePsp(K : LongInt; Path, Root : String) : String;
Var P : LongInt;
Begin
  CP := K;
  ResetPage(K);
  BufInit(Src);
  CErr := ''; CErrLine := 0;
  SiteRoot := Root;
  SrcDir := Path;
  While (Length(SrcDir) > 0) And (SrcDir[Length(SrcDir)] <> '\') Do Delete(SrcDir, Length(SrcDir), 1);
  If Not LoadSource(Path, 0, Src) Then
  Begin
    CompilePsp := 'fichier illisible : ' + Path;
    Exit;
  End;
  SPos := 0; SLine := 1; InHtml := True; InEcho := False; Defines := '|OS2|PSP|';
  CurLvl := 0; LocTop := 0; LocMax := 0; GlobTop := 0; CurFunc := -1; NExit := 0; LoopDepth := 0; NWith := 0;
  PredefSyms;
  NextTok;
  While (CErr = '') And (Tok <> tkEof) Do
  Begin
    If IsKw('PROGRAM') Then
    Begin
      NextTok;
      Dummy := Length(ExpectId);
      If IsSym(';') Then NextTok;
    End
    Else If IsKw('VAR') Or IsKw('CONST') Or IsKw('TYPE') Or IsKw('PROCEDURE') Or IsKw('FUNCTION') Or
            IsKw('LABEL') Or IsKw('USES') Then Declarations(True)
    Else If IsKw('BEGIN') Then
    Begin
      NextTok;
      StmtList('END', 'END');
      Expect('END');
      If IsSym('.') Or IsSym(';') Then NextTok;
    End
    Else If IsSym('.') Then NextTok
    Else
    Begin
      Statement;
      If IsSym(';') Then NextTok
      Else If (CErr = '') And (Tok <> tkHtml) And (Tok <> tkEcho) And (Tok <> tkEof) And Not IsKw('END') And
              Not LastHtml Then
        CError(''';'' attendu');
      If IsKw('END') Then
      Begin
        NextTok;
        If IsSym('.') Or IsSym(';') Then NextTok;
      End;
    End;
  End;
  Emit(opHalt);
  Pages[K].NGlob := GlobTop;
  BufFree(Src);
  If CErr <> '' Then
  Begin
    CompilePsp := 'ligne ' + IStr(CErrLine) + ' : ' + CErr;
    ResetPage(K);
  End
  Else
  Begin
    Pages[K].Used := True;
    CompilePsp := '';
  End;
End;
{ ==================================================================== }
{ Execution des pages                                                   }
{ ==================================================================== }

Const
  MaxStream = 16;

Var
  FsBase : LongInt;
  VmPendLoc : String[127];
  StrmBuf : Array[0..MaxStream - 1] Of TBuf;     { fichiers ouverts par FileSystemObject }
  StrmPos : Array[0..MaxStream - 1] Of LongInt;
  StrmPath : Array[0..MaxStream - 1] Of String[127];
  StrmWrite : Array[0..MaxStream - 1] Of Boolean;
  StrmUsed : Array[0..MaxStream - 1] Of Boolean;
  RndSeed : LongInt;

Function VmRand : LongInt;
Begin
  RndSeed := RndSeed * 1103515245 + 12345;
  VmRand := (RndSeed Shr 8) And $7FFFFF;
End;

{ --- pile --- }

Procedure Push(Var C : TCell);
Begin
  If SP >= StkCells - 2 Then
  Begin
    VmFail('pile d''evaluation pleine');
    Exit;
  End;
  Inc(SP);
  Stk[SP] := C;
End;

Procedure PushInt(V : LongInt);
Begin
  If SP >= StkCells - 2 Then
  Begin
    VmFail('pile d''evaluation pleine');
    Exit;
  End;
  Inc(SP);
  Stk[SP].T := vtInt; Stk[SP].I := V; Stk[SP].L := 0;
End;

Function MemOk(A : LongInt) : Boolean;
Begin
  MemOk := (A >= 0) And (A < MemCells);
  If (A < 0) Or (A >= MemCells) Then VmFail('acc'#138's m'#130'moire invalide (pointeur nil ?)');
End;

{ adresse d'une cellule (vtAddr) }
Function AddrOf(Var C : TCell) : LongInt;
Begin
  If C.T <> vtAddr Then
  Begin
    VmFail('adresse attendue (pointeur nil ?)');
    AddrOf := 0;
  End
  Else AddrOf := C.I;
End;

{ --- collections de la requete --- }

{ octets d'un en-tete entier (Cookie long) : debut et longueur dans Req }
Function HdrRaw(C : LongInt; Name : String; Var St, Len : LongInt) : Boolean;
Var K, E, J : LongInt; Q : PBytes; Ok : Boolean;
Begin
  HdrRaw := False;
  Name := UpStr(Name) + ':';
  Q := Conns[C].Req;
  K := 0;
  While (K < Conns[C].HdrEnd) And (Q^[K] <> 10) Do Inc(K);
  Inc(K);
  While K < Conns[C].HdrEnd - 2 Do
  Begin
    E := K;
    While (E < Conns[C].HdrEnd) And (Q^[E] <> 10) Do Inc(E);
    Ok := E - K > Length(Name);
    If Ok Then
      For J := 1 To Length(Name) Do
        If UpCase(Chr(Q^[K + J - 1])) <> Name[J] Then
        Begin
          Ok := False;
          Break;
        End;
    If Ok Then
    Begin
      St := K + Length(Name);
      While (St < E) And (Q^[St] = 32) Do Inc(St);
      Len := E - St;
      If (Len > 0) And (Q^[St + Len - 1] = 13) Then Dec(Len);
      HdrRaw := True;
      Exit;
    End;
    K := E + 1;
  End;
End;

{ decoder (%xx, +) des octets vers une chaine de la requete }
Procedure DecodeCell(P : PBytes; N : LongInt; Plus : Boolean; Var C : TCell);
Var K, O, V, H1, H2 : LongInt; Q : PBytes;

  Function HV(B : LongInt) : LongInt;
  Begin
    If (B >= 48) And (B <= 57) Then HV := B - 48
    Else If (B >= 65) And (B <= 70) Then HV := B - 55
    Else If (B >= 97) And (B <= 102) Then HV := B - 87
    Else HV := -1;
  End;

Begin
  If Not PoolNew(N, C) Then Exit;
  Q := @VmPool.P^[C.I];
  K := 0; O := 0;
  While K < N Do
  Begin
    V := P^[K];
    If (V = 37) And (K + 2 < N) Then
    Begin
      H1 := HV(P^[K + 1]); H2 := HV(P^[K + 2]);
      If (H1 >= 0) And (H2 >= 0) Then
      Begin
        V := H1 * 16 + H2;
        K := K + 2;
      End;
    End
    Else If Plus And (V = 43) Then V := 32;
    Q^[O] := V;
    Inc(O); Inc(K);
  End;
  C.L := O;
  VmPool.Len := C.I + O;
End;

{ paires cle=valeur separees par Sep }
Procedure ParsePairs(P : PBytes; N : LongInt; Sep : Byte; Plus : Boolean; Var Cnt : LongInt;
                     Var Ks, Vs : Array Of TCell);
Var K, St, Eq, E : LongInt;
Begin
  Cnt := 0;
  K := 0;
  While (K < N) And (Cnt < MaxPair) Do
  Begin
    While (K < N) And (P^[K] = 32) Do Inc(K);
    St := K;
    While (K < N) And (P^[K] <> Sep) Do Inc(K);
    E := K;
    Inc(K);
    If E <= St Then Continue;
    Eq := St;
    While (Eq < E) And (P^[Eq] <> 61) Do Inc(Eq);
    DecodeCell(@P^[St], Eq - St, Plus, Ks[Cnt]);
    If Eq < E Then DecodeCell(@P^[Eq + 1], E - Eq - 1, Plus, Vs[Cnt]) Else MkStr('', Vs[Cnt]);
    Inc(Cnt);
  End;
End;

Procedure LoadQuery;
Var K, St, N : LongInt; Q : PBytes;
Begin
  If QsDone Then Exit;
  QsDone := True;
  QsN := 0;
  Q := Conns[VmConn].Req;
  { requete brute : entre ? et l'espace de la premiere ligne }
  K := 0;
  While (K < Conns[VmConn].HdrEnd) And (Q^[K] <> 63) And (Q^[K] <> 13) Do Inc(K);
  If (K >= Conns[VmConn].HdrEnd) Or (Q^[K] <> 63) Then Exit;
  St := K + 1;
  N := 0;
  While (St + N < Conns[VmConn].HdrEnd) And (Q^[St + N] <> 32) And (Q^[St + N] <> 13) Do Inc(N);
  ParsePairs(@Q^[St], N, 38, True, QsN, QsK, QsV);
End;

Function BodyPtr : PBytes;
Begin
  With Conns[VmConn] Do
    If Body <> Nil Then BodyPtr := Body Else BodyPtr := @Req^[HdrEnd];
End;

Procedure LoadForm;
Begin
  If FmDone Then Exit;
  FmDone := True;
  FmN := 0;
  If Pos('MULTIPART', UpStr(HdrGet(VmConn, 'Content-Type'))) > 0 Then Exit;
  If Conns[VmConn].BodyLen > 0 Then ParsePairs(BodyPtr, Conns[VmConn].BodyLen, 38, True, FmN, FmK, FmV);
End;

Procedure LoadCookies;
Var St, Len : LongInt;
Begin
  If CkDone Then Exit;
  CkDone := True;
  CkN := 0;
  If HdrRaw(VmConn, 'Cookie', St, Len) Then ParsePairs(@Conns[VmConn].Req^[St], Len, 59, False, CkN, CkK, CkV);
End;

{ variable du serveur (Request.ServerVariables) }
Function ServerVar(N : String) : String;
Var S, H : String; I : LongInt;
Begin
  N := UpStr(N);
  S := '';
  With Conns[VmConn] Do
  Begin
    H := Host;
    I := Pos(':', H);
    If I > 0 Then H := Copy(H, 1, I - 1);
    If N = 'REQUEST_METHOD' Then S := Method
    Else If N = 'QUERY_STRING' Then S := Query
    Else If (N = 'SERVER_NAME') Or (N = 'HTTP_HOST') And (H = '') Then
    Begin
      If H = '' Then S := IpStr(LocalIp) Else S := H;
      If N = 'HTTP_HOST' Then S := Host;
    End
    Else If N = 'SERVER_PORT' Then S := IStr(LocalPort)
    Else If N = 'SERVER_PORT_SECURE' Then S := IStr(Ord(IsTls))
    Else If N = 'HTTPS' Then
    Begin
      If IsTls Then S := 'on' Else S := 'off';
    End
    Else If (N = 'REMOTE_ADDR') Or (N = 'REMOTE_HOST') Then S := IpStr(PeerIp)
    Else If N = 'REMOTE_PORT' Then S := IStr(PeerPort)
    Else If N = 'LOCAL_ADDR' Then S := IpStr(LocalIp)
    Else If N = 'SERVER_SOFTWARE' Then S := ServerName
    Else If N = 'SERVER_PROTOCOL' Then S := Ver
    Else If (N = 'SCRIPT_NAME') Or (N = 'PATH_INFO') Or (N = 'URL') Then S := UrlDecode(Uri, False)
    Else If N = 'PATH_TRANSLATED' Then S := ScriptPath[VmConn]
    Else If N = 'APPL_PHYSICAL_PATH' Then S := Sites[Site].Root + '\'
    Else If N = 'APPL_MD_PATH' Then S := '/LM/W3SVC/' + IStr(Sites[Site].Id) + '/ROOT'
    Else If N = 'INSTANCE_ID' Then S := IStr(Sites[Site].Id)
    Else If N = 'CONTENT_TYPE' Then S := HdrGet(VmConn, 'Content-Type')
    Else If N = 'CONTENT_LENGTH' Then S := IStr(BodyLen)
    Else If N = 'GATEWAY_INTERFACE' Then S := 'CGI/1.1'
    Else If (N = 'AUTH_USER') Or (N = 'REMOTE_USER') Or (N = 'LOGON_USER') Then
    Begin
      If Sites[Site].AuthUser <> '' Then S := Sites[Site].AuthUser;
    End
    Else If N = 'AUTH_TYPE' Then
    Begin
      If Sites[Site].AuthUser <> '' Then S := 'Basic';
    End
    Else If Copy(N, 1, 5) = 'HTTP_' Then
    Begin
      N := Copy(N, 6, 255);
      For I := 1 To Length(N) Do If N[I] = '_' Then N[I] := '-';
      S := HdrGet(VmConn, N);
    End;
  End;
  ServerVar := S;
End;

{ valeurs d'une cle dans une collection : indices des paires }
Function CollFind(Coll : LongInt; Var Key : TCell; Nth : LongInt) : LongInt;
Var K, N, Cnt : LongInt;
Begin
  CollFind := -1;
  Cnt := 0;
  Case Coll Of
    rcQuery : N := QsN;
    rcForm : N := FmN;
  Else
    N := CkN;
  End;
  For K := 0 To N - 1 Do
  Begin
    Case Coll Of
      rcQuery : If StrCmpCells(QsK[K], Key, True) <> 0 Then Continue;
      rcForm : If StrCmpCells(FmK[K], Key, True) <> 0 Then Continue;
    Else
      If StrCmpCells(CkK[K], Key, True) <> 0 Then Continue;
    End;
    Inc(Cnt);
    If Cnt = Nth Then
    Begin
      CollFind := K;
      Exit;
    End;
  End;
End;

Function CollCount(Coll : LongInt; Var Key : TCell) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  K := 1;
  While CollFind(Coll, Key, K) >= 0 Do
  Begin
    Inc(N); Inc(K);
  End;
  CollCount := N;
End;

Procedure CollLoad(Coll : LongInt);
Begin
  Case Coll Of
    rcQuery : LoadQuery;
    rcForm : LoadForm;
    rcCookies : LoadCookies;
  End;
End;

Procedure CollVal(Coll, K : LongInt; Var R : TCell);
Begin
  Case Coll Of
    rcQuery : R := QsV[K];
    rcForm : R := FmV[K];
  Else
    R := CkV[K];
  End;
End;

{ valeur d'un element (toutes ses valeurs, separees par ", ") }
Procedure ItemValue(Coll : LongInt; Var Key : TCell; Var R : TCell);
Var K, N, I : LongInt; B : TBuf; V : TCell;
Begin
  If Coll = rcServerVars Then
  Begin
    MkStr(ServerVar(CellPStr(Key)), R);
    Exit;
  End;
  CollLoad(Coll);
  N := CollCount(Coll, Key);
  If N = 0 Then
  Begin
    MkStr('', R);
    Exit;
  End;
  If N = 1 Then
  Begin
    CollVal(Coll, CollFind(Coll, Key, 1), R);
    Exit;
  End;
  BufInit(B);
  For I := 1 To N Do
  Begin
    If I > 1 Then BufAdd(B, ', ');
    CollVal(Coll, CollFind(Coll, Key, I), V);
    BufAddB(B, PoolPtr(V), V.L);
  End;
  MkStrB(B.P, B.Len, R);
  BufFree(B);
End;

Procedure ObjValue(Var C : TCell);
Var Id : LongInt; R : TCell;
Begin
  Id := C.I;
  If (Id < 0) Or (Id >= NObj) Then Exit;
  Case ObjK[Id] Of
    okItem :
      Begin
        ItemValue(ObjA[Id], ObjS[Id], R);
        C := R;
      End;
    okDbFld :
      If (ObjA[Id] >= 0) And Rss[ObjA[Id]].Used Then
      Begin
        RsValue(ObjA[Id], ObjB[Id], R);
        C := R;
      End;
  End;
End;

{ --- sessions --- }

Function SessFind(Id : String) : LongInt;
Var K : LongInt;
Begin
  SessFind := -1;
  For K := 0 To MaxSess - 1 Do
    If Sess[K].Used And (Sess[K].Id = Id) Then
    Begin
      SessFind := K;
      Exit;
    End;
End;

{ session de la requete (cookie ASPSESSIONID), creee au besoin }
Procedure SessEnsure;
Var K, Old, J : LongInt; Key, V : TCell; Id : String; B : Array[0..23] Of Byte;
Begin
  If VmSess >= 0 Then Exit;
  LoadCookies;
  MkStr('ASPSESSIONID', Key);
  K := CollFind(rcCookies, Key, 1);
  If K >= 0 Then
  Begin
    Id := CellPStr(CkV[K]);
    VmSess := SessFind(Id);
    If (VmSess >= 0) And (NowUnix - Sess[VmSess].Last > Sess[VmSess].Timeout * 60) Then
    Begin
      SessFree(VmSess);
      VmSess := -1;
    End;
  End;
  If VmSess < 0 Then
  Begin
    K := -1; Old := 0;
    For J := 0 To MaxSess - 1 Do
      If Not Sess[J].Used Then
      Begin
        K := J;
        Break;
      End
      Else If (K < 0) And ((Old = 0) Or (Sess[J].Last < Sess[Old].Last)) Then Old := J;
    If K < 0 Then
    Begin
      SessFree(Old);
      K := Old;
    End;
    RandFill(@B, 24);
    Id := '';
    For J := 0 To 23 Do Id := Id + Chr(65 + B[J] Mod 26);
    Sess[K].Used := True; Sess[K].Id := Id; Sess[K].N := 0; Sess[K].Timeout := SessionTimeoutM;
    VmSess := K;
    VmNewSess := True;
  End;
  Sess[VmSess].Last := NowUnix;
End;

Function PVarFind(Var Vars : Array Of TPVar; N : LongInt; Name : String) : LongInt;
Var K : LongInt;
Begin
  PVarFind := -1;
  Name := UpStr(Name);
  For K := 0 To N - 1 Do
    If UpStr(Vars[K].Name) = Name Then
    Begin
      PVarFind := K;
      Exit;
    End;
End;

{ --- objets de Scripting --- }

Function DictFind(Ob : LongInt; Var Key : TCell) : LongInt;
Var K : LongInt;
Begin
  DictFind := -1;
  For K := 0 To NDict - 1 Do
    If DObj^[K] = Ob Then
    Begin
      If (IsStrCell(DKey^[K]) And IsStrCell(Key) And (StrCmpCells(DKey^[K], Key, False) = 0)) Or
         ((Not IsStrCell(DKey^[K])) And (Not IsStrCell(Key)) And (CellReal(DKey^[K]) = CellReal(Key))) Then
      Begin
        DictFind := K;
        Exit;
      End;
    End;
End;

Function DictCount(Ob : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NDict - 1 Do If DObj^[K] = Ob Then Inc(N);
  DictCount := N;
End;

Procedure DictAdd(Ob : LongInt; Var Key, V : TCell);
Begin
  If NDict >= MaxDictE Then
  Begin
    VmFail('dictionnaire plein');
    Exit;
  End;
  DObj^[NDict] := Ob; DKey^[NDict] := Key; DVal^[NDict] := V;
  Inc(NDict);
End;

{ tableau (Split, Array, dict.Keys) : objet okArr, elements dans les
  entrees de dictionnaire (cle = indice) }
Function ArrNew(N : LongInt) : LongInt;
Var Ob, K : LongInt; Ki, V : TCell;
Begin
  Ob := ObjNew(okArr, N, 0);
  MkNil(V);
  For K := 0 To N - 1 Do
  Begin
    MkInt(K, Ki);
    DictAdd(Ob, Ki, V);
  End;
  ArrNew := Ob;
End;

Function ArrSlot(Ob, Idx : LongInt) : LongInt;
Var K, N : LongInt;
Begin
  ArrSlot := -1;
  N := 0;
  For K := 0 To NDict - 1 Do
    If DObj^[K] = Ob Then
    Begin
      If N = Idx Then
      Begin
        ArrSlot := K;
        Exit;
      End;
      Inc(N);
    End;
End;

Function FsPath(S : String) : String;
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do If S[K] = '/' Then S[K] := '\';
  If (Length(S) >= 1) And (S[1] = '\') And ((Length(S) < 2) Or (S[2] <> '\')) Then
    S := Sites[Conns[VmConn].Site].Root + S;
  FsPath := S;
End;

Function MapUrl(S : String) : String;
Var Dir : String; K : LongInt;
Begin
  For K := 1 To Length(S) Do If S[K] = '\' Then S[K] := '/';
  If (S <> '') And (S[1] = '/') Then
  Begin
    S := MapPath(Conns[VmConn].Site, S);
    MapUrl := S;
    Exit;
  End;
  Dir := ScriptPath[VmConn];
  While (Length(Dir) > 0) And (Dir[Length(Dir)] <> '\') Do Delete(Dir, Length(Dir), 1);
  For K := 1 To Length(S) Do If S[K] = '/' Then S[K] := '\';
  MapUrl := Dir + S;
End;

Procedure CreateObj(Name : String; Var R : TCell);
Begin
  Name := UpStr(Name);
  If Name = 'SCRIPTING.DICTIONARY' Then MkObj(ObjNew(okDict, 0, 0), R)
  Else If Name = 'SCRIPTING.FILESYSTEMOBJECT' Then MkObj(ObjNew(okFso, 0, 0), R)
  Else If Name = 'ADODB.CONNECTION' Then MkObj(ObjNew(okDbConn, -1, 0), R)
  Else If Name = 'ADODB.RECORDSET' Then MkObj(ObjNew(okDbRs, -1, 0), R)
  Else
  Begin
    VmFail('CreateObject : objet inconnu (' + Name + ')');
    MkNil(R);
  End;
End;

Function StreamOpen(Path : String; Wr : Boolean) : LongInt;
Var K : LongInt;
Begin
  StreamOpen := -1;
  For K := 0 To MaxStream - 1 Do
    If Not StrmUsed[K] Then
    Begin
      BufInit(StrmBuf[K]);
      If Not Wr Then
        If Not ReadFileBuf(Path, StrmBuf[K], 4194304) Then
        Begin
          VmFail('fichier introuvable : ' + Path);
          Exit;
        End;
      StrmUsed[K] := True; StrmPos[K] := 0; StrmPath[K] := Path; StrmWrite[K] := Wr;
      StreamOpen := K;
      Exit;
    End;
  VmFail('trop de fichiers ouverts');
End;

Procedure StreamClose(K : LongInt);
Begin
  If (K < 0) Or (K >= MaxStream) Or Not StrmUsed[K] Then Exit;
  If StrmWrite[K] Then Dummy := Ord(WriteFileBuf(StrmPath[K], StrmBuf[K].P, StrmBuf[K].Len));
  BufFree(StrmBuf[K]);
  StrmUsed[K] := False;
End;

{ --- membres des objets : lecture (R) ; Set : affectation de V --- }

Procedure AddHdr(N, V : String);
Begin
  BufAdd(VmHdr, N + ': ' + V + Crlf);
  If VmOut.Len = 0 Then VmHdrPending := True;
End;

Function PhpMember(Var Ob : TCell; M, Argc, ABase : LongInt; Var R : TCell; IsSet : Boolean; Var V : TCell) : Boolean;
  Forward;

Procedure MemberCall(Var Ob : TCell; M, Argc, ABase : LongInt; Var R : TCell; IsSet : Boolean; Var V : TCell);
Var Id, K, N, Coll, J : LongInt; S, S2 : String; Key : TCell; A0, A1 : TCell; Tb : TBuf; Dr : Boolean; Pq : PBytes;
Begin
  MkNil(R);
  If Argc > 0 Then A0 := Stk[ABase] Else MkNil(A0);
  If Argc > 1 Then A1 := Stk[ABase + 1] Else MkNil(A1);
  If (A0.T = vtObj) And (ObjK[A0.I] = okItem) Then ObjValue(A0);
  If Ob.T <> vtObj Then
  Begin
    { valeur simple : tableau d'une chaine ? }
    VmFail('objet attendu (membre ' + MemberNames[M] + ')');
    Exit;
  End;
  Id := Ob.I;
  If (Id < 0) Or (Id >= NObj) Then
  Begin
    VmFail('objet nil');
    Exit;
  End;
  { PHP : tableaux, mysqli, pg_*, PDO }
  If PhpStyle And (ObjK[Id] In [okPArr, okDbConn, okDbRs, okDbStmt]) Then
    If PhpMember(Ob, M, Argc, ABase, R, IsSet, V) Then Exit;
  Case ObjK[Id] Of
    okRequest :
      Case M Of
        mDefault :
          Begin
            { Request("x") : QueryString, Form, Cookies, ServerVariables }
            LoadQuery; LoadForm; LoadCookies;
            Coll := 0;
            If CollCount(rcQuery, A0) > 0 Then Coll := rcQuery
            Else If CollCount(rcForm, A0) > 0 Then Coll := rcForm
            Else If CollCount(rcCookies, A0) > 0 Then Coll := rcCookies;
            If Coll = 0 Then MkStr(ServerVar(CellPStr(A0)), R)
            Else
            Begin
              K := ObjNew(okItem, Coll, 0);
              ObjS[K] := A0;
              MkObj(K, R);
            End;
          End;
        mQueryString, mForm, mCookies, mServerVariables :
          Begin
            Case M Of
              mQueryString : Coll := rcQuery;
              mForm : Coll := rcForm;
              mCookies : Coll := rcCookies;
            Else
              Coll := rcServerVars;
            End;
            CollLoad(Coll);
            If Argc = 0 Then MkObj(ObjNew(okColl, Coll, 0), R)
            Else If (A0.T = vtInt) And (Coll <> rcServerVars) Then
            Begin
              { par indice (1, 2...) }
              Case Coll Of
                rcQuery : N := QsN;
                rcForm : N := FmN;
              Else
                N := CkN;
              End;
              If (A0.I >= 1) And (A0.I <= N) Then CollVal(Coll, A0.I - 1, R) Else MkStr('', R);
            End
            Else
            Begin
              K := ObjNew(okItem, Coll, 0);
              ObjS[K] := A0;
              MkObj(K, R);
            End;
          End;
        mTotalBytes : MkInt(Conns[VmConn].BodyLen, R);
        mBinaryRead :
          Begin
            N := CellInt(A0);
            If N > Conns[VmConn].BodyLen - VmBinPos Then N := Conns[VmConn].BodyLen - VmBinPos;
            If N < 0 Then N := 0;
            Pq := BodyPtr;
            MkStrB(@Pq^[VmBinPos], N, R);
            VmBinPos := VmBinPos + N;
          End;
      Else
        VmFail('Request.' + MemberNames[M] + ' inconnu');
      End;
    okColl :
      Begin
        Coll := ObjA[Id];
        Case Coll Of
          rcQuery : N := QsN;
          rcForm : N := FmN;
          rcCookies : N := CkN;
        Else
          N := 0;
        End;
        Case M Of
          mCount : MkInt(N, R);
          mKey :
            Begin
              K := CellInt(A0);
              If (K >= 1) And (K <= N) Then
                Case Coll Of
                  rcQuery : R := QsK[K - 1];
                  rcForm : R := FmK[K - 1];
                Else
                  R := CkK[K - 1];
                End
              Else MkStr('', R);
            End;
          mDefault, mItem :
            If A0.T = vtInt Then
            Begin
              If (A0.I >= 1) And (A0.I <= N) Then CollVal(Coll, A0.I - 1, R) Else MkStr('', R);
            End
            Else
            Begin
              K := ObjNew(okItem, Coll, 0);
              ObjS[K] := A0;
              MkObj(K, R);
            End;
        Else
          VmFail('membre inconnu : ' + MemberNames[M]);
        End;
      End;
    okItem :
      Begin
        Coll := ObjA[Id]; Key := ObjS[Id];
        Case M Of
          mCount : MkInt(CollCount(Coll, Key), R);
          mHasKeys :
            Begin
              ItemValue(Coll, Key, R);
              MkBool(Pos('=', CellPStr(R)) > 0, R);
            End;
          mDefault, mItem :
            If (Coll = rcCookies) And IsStrCell(A0) Then
            Begin
              { sous-cle d'un cookie "dictionnaire" : a=1&b=2 }
              ItemValue(Coll, Key, R);
              S := CellPStr(R) + '&';
              S2 := UpStr(CellPStr(A0)) + '=';
              MkStr('', R);
              While Pos('&', S) > 0 Do
              Begin
                K := Pos('&', S);
                If UpStr(Copy(S, 1, Length(S2))) = S2 Then
                Begin
                  MkStr(UrlDecode(Copy(S, Length(S2) + 1, K - Length(S2) - 1), True), R);
                  Break;
                End;
                Delete(S, 1, K);
              End;
            End
            Else
            Begin
              K := CollFind(Coll, Key, CellInt(A0));
              If K >= 0 Then CollVal(Coll, K, R) Else MkStr('', R);
            End;
        Else
          VmFail('membre inconnu : ' + MemberNames[M]);
        End;
      End;
    okResponse :
      Case M Of
        mWrite : OutCell(A0, -1, -1);
        mRedirect :
          Begin
            VmStatus := '302 Object moved';
            VmPendLoc := CellPStr(A0);
            AddHdr('Location', VmPendLoc);
            VmEnded := True;
          End;
        mAddHeader : AddHdr(CellPStr(A0), CellPStr(A1));
        mContentType :
          If IsSet Then
          Begin
            VmCType := CellPStr(V);
            If VmOut.Len = 0 Then VmHdrPending := True;
          End
          Else MkStr(VmCType, R);
        mCharset :
          If IsSet Then VmCharset := CellPStr(V) Else MkStr(VmCharset, R);
        mStatus :
          If IsSet Then
          Begin
            VmStatus := CellPStr(V);
            If VmOut.Len = 0 Then VmHdrPending := True;
          End
          Else MkStr(VmStatus, R);
        mBuffer :
          If IsSet Then VmBuffer := CellBool(V) Else MkBool(VmBuffer, R);
        mEnd : VmEnded := True;
        mClear : VmOut.Len := 0;
        mFlush : ;
        mAppendToLog : SysLog('Page ' + ScriptPath[VmConn] + ' : ' + CellPStr(A0));
        mExpires :
          If IsSet Then
          Begin
            K := CellInt(V);
            If K <= 0 Then AddHdr('Cache-Control', 'no-cache')
            Else AddHdr('Cache-Control', 'max-age=' + IStr(K * 60));
            AddHdr('Expires', HttpDate(NowUnix + K * 60));
          End;
        mExpiresAbsolute : If IsSet Then AddHdr('Expires', CellPStr(V));
        mCacheControl : If IsSet Then AddHdr('Cache-Control', CellPStr(V));
        mCookies :
          If IsSet Then
            AddHdr('Set-Cookie', CellPStr(A0) + '=' + UrlEncode(CellPStr(V)) + '; path=/')
          Else
          Begin
            K := ObjNew(okCookieW, 0, 0);
            ObjS[K] := A0;
            MkObj(K, R);
          End;
        mIsClientConnected : MkBool(True, R);
      Else
        VmFail('Response.' + MemberNames[M] + ' inconnu');
      End;
    okCookieW :
      If IsSet Then
        AddHdr('Set-Cookie', CellPStr(ObjS[Id]) + '=' + UrlEncode(CellPStr(V)) + '; path=/');
    okServer :
      Case M Of
        mMapPath : MkStr(MapUrl(CellPStr(A0)), R);
        mURLEncode : MkStr(UrlEncode(CellPStr(A0)), R);
        mHTMLEncode :
          Begin
            CellToStr(A0, Key);
            BufInit(Tb);
            For K := 0 To Key.L - 1 Do
            Begin
              J := PoolPtr(Key)^[K];
              Case J Of
                60 : BufAdd(Tb, '&lt;');
                62 : BufAdd(Tb, '&gt;');
                38 : BufAdd(Tb, '&amp;');
                34 : BufAdd(Tb, '&quot;');
              Else
                BufAddC(Tb, J);
              End;
            End;
            MkStrB(Tb.P, Tb.Len, R);
            BufFree(Tb);
          End;
        mScriptTimeout :
          If IsSet Then VmScriptTo := CellInt(V) Else MkInt(VmScriptTo, R);
        mCreateObject : CreateObj(CellPStr(A0), R);
      Else
        VmFail('Server.' + MemberNames[M] + ' inconnu');
      End;
    okSession :
      Begin
        SessEnsure;
        Case M Of
          mDefault, mContents :
            Begin
              K := PVarFind(Sess[VmSess].V, Sess[VmSess].N, CellPStr(A0));
              If IsSet Then
              Begin
                If K < 0 Then
                Begin
                  If Sess[VmSess].N >= MaxSVar Then
                  Begin
                    VmFail('trop de variables de session');
                    Exit;
                  End;
                  K := Sess[VmSess].N;
                  Inc(Sess[VmSess].N);
                  Sess[VmSess].V[K].Name := CellPStr(A0);
                  Sess[VmSess].V[K].P := Nil;
                End;
                PVarSet(Sess[VmSess].V[K], V);
              End
              Else If K >= 0 Then PVarGet(Sess[VmSess].V[K], R)
              Else MkNil(R);
            End;
          mSessionID : MkStr(Sess[VmSess].Id, R);
          mTimeout :
            If IsSet Then Sess[VmSess].Timeout := CellInt(V) Else MkInt(Sess[VmSess].Timeout, R);
          mAbandon : Sess[VmSess].Timeout := 0;
        Else
          VmFail('Session.' + MemberNames[M] + ' inconnu');
        End;
      End;
    okApp :
      Case M Of
        mDefault, mContents :
          Begin
            K := PVarFind(AppVars, NAppVar, CellPStr(A0));
            If IsSet Then
            Begin
              If K < 0 Then
              Begin
                If NAppVar >= MaxAVar Then
                Begin
                  VmFail('trop de variables d''application');
                  Exit;
                End;
                K := NAppVar;
                Inc(NAppVar);
                AppVars[K].Name := CellPStr(A0);
                AppVars[K].P := Nil;
              End;
              PVarSet(AppVars[K], V);
            End
            Else If K >= 0 Then PVarGet(AppVars[K], R)
            Else MkNil(R);
          End;
        mLock, mUnlock : ;
      Else
        VmFail('Application.' + MemberNames[M] + ' inconnu');
      End;
    okDict :
      Case M Of
        mAdd :
          If DictFind(Id, A0) >= 0 Then VmFail('cette cl'#130' existe d'#130'j'#133' dans le dictionnaire')
          Else DictAdd(Id, A0, A1);
        mDefault, mItem :
          Begin
            K := DictFind(Id, A0);
            If IsSet Then
            Begin
              If K >= 0 Then DVal^[K] := V Else DictAdd(Id, A0, V);
            End
            Else If K >= 0 Then R := DVal^[K]
            Else MkNil(R);
          End;
        mExists : MkBool(DictFind(Id, A0) >= 0, R);
        mRemove :
          Begin
            K := DictFind(Id, A0);
            If K >= 0 Then DObj^[K] := -1;
          End;
        mRemoveAll : For K := 0 To NDict - 1 Do If DObj^[K] = Id Then DObj^[K] := -1;
        mCount : MkInt(DictCount(Id), R);
        mKeys, mItems :
          Begin
            N := DictCount(Id);
            J := ObjNew(okArr, N, 0);
            For K := 0 To NDict - 1 Do
              If DObj^[K] = Id Then
              Begin
                If M = mKeys Then DictAdd(J, DKey^[K], DKey^[K]) Else DictAdd(J, DKey^[K], DVal^[K]);
              End;
            { les elements du tableau : les valeurs (cles en DKey) }
            For K := 0 To NDict - 1 Do If DObj^[K] = J Then DKey^[K] := DVal^[K];
            For K := 0 To NDict - 1 Do If DObj^[K] = J Then DVal^[K] := DKey^[K];
            MkObj(J, R);
          End;
      Else
        VmFail('Dictionary.' + MemberNames[M] + ' inconnu');
      End;
    okArr :
      Case M Of
        mDefault, mItem :
          Begin
            If (Argc > 1) And (ObjB[Id] > 0) Then K := ArrSlot(Id, CellInt(A0) * ObjB[Id] + CellInt(A1))
            Else K := ArrSlot(Id, CellInt(A0));
            If K < 0 Then VmFail('indice hors limites')
            Else If IsSet Then DVal^[K] := V
            Else R := DVal^[K];
          End;
        mCount : MkInt(DictCount(Id), R);
      Else
        VmFail('membre inconnu : ' + MemberNames[M]);
      End;
    okFso :
      Case M Of
        mFileExists :
          Begin
            S := FsPath(CellPStr(A0));
            MkBool(PStat(S, K, N, Dr) And Not Dr, R);
          End;
        mFolderExists : MkBool(PStat(FsPath(CellPStr(A0)), K, N, Dr) And Dr, R);
        mOpenTextFile :
          Begin
            K := StreamOpen(FsPath(CellPStr(A0)), (Argc > 1) And (CellInt(A1) >= 2));
            If K >= 0 Then MkObj(ObjNew(okStream, K, 0), R);
          End;
        mCreateTextFile :
          Begin
            K := StreamOpen(FsPath(CellPStr(A0)), True);
            If K >= 0 Then MkObj(ObjNew(okStream, K, 0), R);
          End;
        mDeleteFile : Dummy := Ord(PDelete(FsPath(CellPStr(A0))));
        mGetFileName :
          Begin
            S := CellPStr(A0);
            K := Length(S);
            While (K > 0) And (S[K] <> '\') And (S[K] <> '/') Do Dec(K);
            MkStr(Copy(S, K + 1, 255), R);
          End;
        mBuildPath :
          Begin
            S := CellPStr(A0);
            If (S <> '') And (S[Length(S)] <> '\') Then S := S + '\';
            MkStr(S + CellPStr(A1), R);
          End;
      Else
        VmFail('FileSystemObject.' + MemberNames[M] + ' inconnu');
      End;
    okStream :
      Begin
        K := ObjA[Id];
        If (K < 0) Or Not StrmUsed[K] Then
        Begin
          VmFail('fichier ferm'#130);
          Exit;
        End;
        Case M Of
          mReadLine :
            Begin
              J := StrmPos[K];
              While (J < StrmBuf[K].Len) And (StrmBuf[K].P^[J] <> 10) Do Inc(J);
              N := J - StrmPos[K];
              If (N > 0) And (StrmBuf[K].P^[StrmPos[K] + N - 1] = 13) Then Dec(N);
              MkStrB(@StrmBuf[K].P^[StrmPos[K]], N, R);
              StrmPos[K] := J + 1;
            End;
          mReadAll :
            Begin
              MkStrB(@StrmBuf[K].P^[StrmPos[K]], StrmBuf[K].Len - StrmPos[K], R);
              StrmPos[K] := StrmBuf[K].Len;
            End;
          mAtEndOfStream : MkBool(StrmPos[K] >= StrmBuf[K].Len, R);
          mWrite, mWriteLine :
            Begin
              CellToStr(A0, Key);
              BufAddB(StrmBuf[K], PoolPtr(Key), Key.L);
              If M = mWriteLine Then BufAdd(StrmBuf[K], Crlf);
            End;
          mClose : StreamClose(K);
        Else
          VmFail('TextStream.' + MemberNames[M] + ' inconnu');
        End;
      End;
    okDbF, okDbConn, okDbRs, okDbFlds, okDbFld : DbMember(Id, M, Argc, ABase, R, IsSet, V);
    okErr :
      Case M Of
        mNumber, mDefault : If IsSet Then VmAspErrNum := CellInt(V) Else MkInt(VmAspErrNum, R);
        mDescription : If IsSet Then VmAspErrDesc := CellPStr(V) Else MkStr(VmAspErrDesc, R);
        mSource : MkStr('Microsoft VBScript runtime error', R);
        mClear :
          Begin
            VmAspErrNum := 0; VmAspErrDesc := '';
          End;
        mRaise :
          Begin
            VmAspErrNum := CellInt(A0);
            If Argc > 2 Then VmAspErrDesc := CellPStr(Stk[ABase + 2]) Else VmAspErrDesc := 'Erreur ' + IStr(VmAspErrNum);
            VmFail(VmAspErrDesc);
          End;
      End;
  Else
    VmFail('objet invalide');
  End;
End;

{ ==================================================================== }
{ PHP : conversions, tableaux, arithmetique et comparaisons de PHP 8    }
{ Un tableau de PHP est un objet okPArr de la requete ; ses elements    }
{ sont des entrees de dictionnaire (cle, valeur) dans l'ordre           }
{ d'insertion ; ObjA : prochain indice entier (ajout $a[] = ...).       }
{ ==================================================================== }

Procedure PhpBuiltin(Id, Argc : LongInt; Var Arg : Array Of TCell; Var R : TCell); Forward;

Function HexV(C : Char) : LongInt;
Begin
  C := UpCase(C);
  If (C >= '0') And (C <= '9') Then HexV := Ord(C) - 48
  Else If (C >= 'A') And (C <= 'F') Then HexV := Ord(C) - 55
  Else HexV := -1;
End;

{ UTF-8 d'un point de code }
Procedure AddUtf8(Var B : TBuf; U : LongInt);
Begin
  If U < 128 Then BufAddC(B, U)
  Else If U < 2048 Then
  Begin
    BufAddC(B, 192 Or (U Shr 6)); BufAddC(B, 128 Or (U And 63));
  End
  Else If U < 65536 Then
  Begin
    BufAddC(B, 224 Or (U Shr 12)); BufAddC(B, 128 Or ((U Shr 6) And 63)); BufAddC(B, 128 Or (U And 63));
  End
  Else
  Begin
    BufAddC(B, 240 Or (U Shr 18)); BufAddC(B, 128 Or ((U Shr 12) And 63));
    BufAddC(B, 128 Or ((U Shr 6) And 63)); BufAddC(B, 128 Or (U And 63));
  End;
End;

Function PIsArr(Var C : TCell) : Boolean;
Begin
  PIsArr := (C.T = vtObj) And (C.I >= 0) And (C.I < NObj) And (ObjK[C.I] = okPArr);
End;

{ chaine d'une valeur (cellule vtStr ou vtKStr ; caractere converti) }
Procedure PStrCell(Var C : TCell; Var R : TCell);
Var Cb : Byte;
Begin
  If C.T = vtChar Then
  Begin
    Cb := C.I;
    MkStrB(@Cb, 1, R);
  End
  Else If (C.T = vtStr) Or (C.T = vtKStr) Then R := C
  Else If C.T = vtNil Then
  Begin
    R.T := vtKStr; R.I := 0; R.L := 0;
  End
  Else CellToStr(C, R);
End;

{ nombre en tete d'une chaine (PHP) : True si toute la chaine est un nombre }
Function PParseNum(P : PBytes; N : LongInt; Var IsReal : Boolean; Var IV : LongInt; Var RV : Double) : Boolean;
Var K, St, E : LongInt; S : String; Dig : Boolean;
Begin
  IsReal := False; IV := 0; RV := 0;
  K := 0;
  While (K < N) And (P^[K] In [32, 9, 10, 13, 11, 12]) Do Inc(K);
  St := K;
  If (K < N) And (P^[K] In [43, 45]) Then Inc(K);
  Dig := False;
  While (K < N) And (P^[K] >= 48) And (P^[K] <= 57) Do
  Begin
    Inc(K);
    Dig := True;
  End;
  If (K < N) And (P^[K] = 46) Then
  Begin
    Inc(K);
    IsReal := True;
    While (K < N) And (P^[K] >= 48) And (P^[K] <= 57) Do
    Begin
      Inc(K);
      Dig := True;
    End;
  End;
  If Dig And (K < N) And (P^[K] In [69, 101]) Then
  Begin
    E := K + 1;
    If (E < N) And (P^[E] In [43, 45]) Then Inc(E);
    If (E < N) And (P^[E] >= 48) And (P^[E] <= 57) Then
    Begin
      IsReal := True;
      K := E;
      While (K < N) And (P^[K] >= 48) And (P^[K] <= 57) Do Inc(K);
    End;
  End;
  If Not Dig Then
  Begin
    PParseNum := False;
    Exit;
  End;
  S := '';
  For E := St To K - 1 Do If Length(S) < 60 Then S := S + Chr(P^[E]);
  If (Length(S) > 0) And (S[1] = '+') Then Delete(S, 1, 1);
  If (S <> '') And (S[1] = '.') Then S := '0' + S;
  If (Length(S) > 1) And (S[1] = '-') And (S[2] = '.') Then Insert('0', S, 2);
  If S[Length(S)] = '.' Then S := S + '0';
  Val(S, RV, E);
  If Not IsReal Then
  Begin
    If (RV > 2147483647.0) Or (RV < -2147483648.0) Then IsReal := True
    Else IV := Trunc(RV);
  End;
  { espaces de fin permis }
  While (K < N) And (P^[K] In [32, 9, 10, 13, 11, 12]) Do Inc(K);
  PParseNum := K >= N;
End;

Function PIsNumStr(Var C : TCell) : Boolean;
Var T : TCell; R_ : Boolean; I : LongInt; D : Double;
Begin
  PIsNumStr := False;
  If Not IsStrCell(C) Then Exit;
  PStrCell(C, T);
  If T.L = 0 Then Exit;
  PIsNumStr := PParseNum(PoolPtr(T), T.L, R_, I, D);
End;

{ valeur numerique (entier ou reel) d'une valeur de PHP }
Procedure PNumCell(Var C : TCell; Var R : TCell);
Var T : TCell; Rl : Boolean; I : LongInt; D : Double;
Begin
  Case C.T Of
    vtInt : R := C;
    vtReal : R := C;
    vtBool : MkInt(C.I, R);
    vtNil : MkInt(0, R);
    vtDate : MkReal(C.R, R);
    vtStr, vtKStr, vtChar :
      Begin
        PStrCell(C, T);
        Dummy := Ord(PParseNum(PoolPtr(T), T.L, Rl, I, D));
        If Rl Then MkReal(D, R) Else MkInt(I, R);
      End;
    vtObj :
      Begin
        T := C;
        ObjValue(T);
        If T.T = vtObj Then
        Begin
          If PIsArr(T) Then MkInt(Ord(DictCount(T.I) > 0), R) Else MkInt(1, R);
        End
        Else PNumCell(T, R);
      End;
  Else
    MkInt(CellInt(C), R);
  End;
End;

{ verite d'une valeur (PHP) }
Function PBool(Var C : TCell) : Boolean;
Var T : TCell; P : PBytes;
Begin
  Case C.T Of
    vtNil : PBool := False;
    vtBool, vtInt : PBool := C.I <> 0;
    vtReal, vtDate : PBool := C.R <> 0;
    vtChar : PBool := C.I <> 48;
    vtStr, vtKStr :
      Begin
        If C.L = 0 Then PBool := False
        Else If C.L = 1 Then
        Begin
          P := PoolPtr(C);
          PBool := P^[0] <> 48;
        End
        Else PBool := True;
      End;
    vtObj :
      Begin
        T := C;
        ObjValue(T);
        If T.T = vtObj Then
        Begin
          If PIsArr(T) Then PBool := DictCount(T.I) > 0 Else PBool := True;
        End
        Else PBool := PBool(T);
      End;
  Else
    PBool := CellBool(C);
  End;
End;

{ --- tableaux --- }

Function PArrNew : LongInt;
Begin
  PArrNew := ObjNew(okPArr, 0, 0);
End;

{ cle d'un tableau : "12" -> 12, reel -> entier, booleen -> 0/1, null -> "" }
Procedure PKey(Var C : TCell; Var R : TCell);
Var T : TCell; Rl : Boolean; I, K : LongInt; D : Double; P : PBytes; Ok : Boolean;
Begin
  Case C.T Of
    vtInt : R := C;
    vtReal, vtDate : MkInt(Trunc(C.R), R);
    vtBool : MkInt(C.I, R);
    vtNil : MkStr('', R);
    vtStr, vtKStr, vtChar :
      Begin
        PStrCell(C, T);
        R := T;
        { entier decimal canonique seulement }
        P := PoolPtr(T);
        If (T.L = 0) Or (T.L > 10) Then Exit;
        Ok := True;
        For K := 0 To T.L - 1 Do
          If Not (((P^[K] >= 48) And (P^[K] <= 57)) Or ((K = 0) And (P^[K] = 45) And (T.L > 1))) Then Ok := False;
        If Ok And (T.L > 1) And (P^[0] = 48) Then Ok := False;
        If Ok And (T.L > 2) And (P^[0] = 45) And (P^[1] = 48) Then Ok := False;
        If Ok And PParseNum(P, T.L, Rl, I, D) And Not Rl Then MkInt(I, R);
      End;
    vtObj :
      Begin
        T := C;
        ObjValue(T);
        If T.T = vtObj Then MkInt(T.I, R) Else PKey(T, R);
      End;
  Else
    R := C;
  End;
End;

Function PArrFind(Id : LongInt; Var Key : TCell) : LongInt;
Var K : TCell;
Begin
  PKey(Key, K);
  PArrFind := DictFind(Id, K);
End;

Procedure PArrGet(Id : LongInt; Var Key : TCell; Var R : TCell);
Var K : LongInt;
Begin
  K := PArrFind(Id, Key);
  If K >= 0 Then R := DVal^[K] Else MkNil(R);
End;

Procedure PArrSet(Id : LongInt; Var Key, V : TCell);
Var K : LongInt; Kc : TCell;
Begin
  PKey(Key, Kc);
  K := DictFind(Id, Kc);
  If K >= 0 Then DVal^[K] := V
  Else
  Begin
    DictAdd(Id, Kc, V);
    If (Kc.T = vtInt) And (Kc.I >= ObjA[Id]) Then ObjA[Id] := Kc.I + 1;
  End;
End;

Procedure PArrPush(Id : LongInt; Var V : TCell);
Var Kc : TCell;
Begin
  MkInt(ObjA[Id], Kc);
  DictAdd(Id, Kc, V);
  ObjA[Id] := ObjA[Id] + 1;
End;

{ entree suivante (indice brut >= Pos) ; -1 : fin }
Function PArrNext(Id, Pos_ : LongInt) : LongInt;
Var K : LongInt;
Begin
  PArrNext := -1;
  If Pos_ < 0 Then Pos_ := 0;
  For K := Pos_ To NDict - 1 Do
    If DObj^[K] = Id Then
    Begin
      PArrNext := K;
      Exit;
    End;
End;

{ entree numero N (0..) }
Function PArrNth(Id, N : LongInt) : LongInt;
Var K, C : LongInt;
Begin
  PArrNth := -1;
  C := 0;
  For K := 0 To NDict - 1 Do
    If DObj^[K] = Id Then
    Begin
      If C = N Then
      Begin
        PArrNth := K;
        Exit;
      End;
      Inc(C);
    End;
End;

{ copie (les tableaux contenus sont copies aussi : valeurs de PHP) }
Function PArrCopy(Id : LongInt) : LongInt;
Var K, N, Cnt : LongInt; V : TCell;
Begin
  N := PArrNew;
  ObjA[N] := ObjA[Id];
  Cnt := NDict;
  For K := 0 To Cnt - 1 Do
    If DObj^[K] = Id Then
    Begin
      V := DVal^[K];
      If PIsArr(V) And (V.I <> Id) Then MkObj(PArrCopy(V.I), V);
      DictAdd(N, DKey^[K], V);
    End;
  PArrCopy := N;
End;

{ renumeroter les cles entieres 0, 1, 2... (les cles chaines gardees) }
Procedure PArrRenumber(Id : LongInt);
Var K, N : LongInt;
Begin
  N := 0;
  For K := 0 To NDict - 1 Do
    If (DObj^[K] = Id) And (DKey^[K].T = vtInt) Then
    Begin
      DKey^[K].I := N;
      Inc(N);
    End;
  ObjA[Id] := N;
End;

{ --- arithmetique de PHP --- }

Procedure PhpArith(Op : LongInt; Var A0, B0 : TCell; Var R : TCell);
Var A, B : TCell; X, Y : Double; I, J : LongInt;
Begin
  If (A0.T = vtObj) And Not PIsArr(A0) Then ObjValue(A0);
  If (B0.T = vtObj) And Not PIsArr(B0) Then ObjValue(B0);
  If PIsArr(A0) Or PIsArr(B0) Then
  Begin
    VmFail('Unsupported operand types: array');
    MkNil(R);
    Exit;
  End;
  PNumCell(A0, A); PNumCell(B0, B);
  If (A.T = vtInt) And (B.T = vtInt) Then
  Begin
    I := A.I; J := B.I;
    Case Op Of
      opAdd :
        Begin
          X := I;
          X := X + J;
          If (X > 2147483647.0) Or (X < -2147483648.0) Then MkReal(X, R) Else MkInt(I + J, R);
        End;
      opSub :
        Begin
          X := I;
          X := X - J;
          If (X > 2147483647.0) Or (X < -2147483648.0) Then MkReal(X, R) Else MkInt(I - J, R);
        End;
      opMul :
        Begin
          X := I;
          X := X * J;
          If (X > 2147483647.0) Or (X < -2147483648.0) Then MkReal(X, R) Else MkInt(I * J, R);
        End;
      opDivR :
        If J = 0 Then VmFail('Division by zero')
        Else If (I Mod J = 0) And Not ((I = -2147483647 - 1) And (J = -1)) Then MkInt(I Div J, R)
        Else MkReal(I / J, R);
      opIDiv :
        If J = 0 Then VmFail('Division by zero') Else MkInt(I Div J, R);
      opMod :
        If J = 0 Then VmFail('Modulo by zero') Else MkInt(I Mod J, R);
    End;
    Exit;
  End;
  If A.T = vtInt Then X := A.I Else X := A.R;
  If B.T = vtInt Then Y := B.I Else Y := B.R;
  Case Op Of
    opAdd : MkReal(X + Y, R);
    opSub : MkReal(X - Y, R);
    opMul : MkReal(X * Y, R);
    opDivR : If Y = 0 Then VmFail('Division by zero') Else MkReal(X / Y, R);
    opIDiv : If Trunc(Y) = 0 Then VmFail('Division by zero') Else MkInt(Trunc(X) Div Trunc(Y), R);
    opMod :
      If Trunc(Y) = 0 Then VmFail('Modulo by zero')
      Else If (Abs(X) > 2147483647.0) Or (Abs(Y) > 2147483647.0) Then MkReal(X - Int(X / Y) * Y, R)
      Else MkInt(Trunc(X) Mod Trunc(Y), R);
  End;
End;

{ --- comparaison de PHP 8 (==, <, >) : -1, 0, 1 --- }

Function PhpCompare(Var A0, B0 : TCell) : LongInt;
Var A, B, Na, Nb, Sa, Sb : TCell; X, Y : Double; Ab, Bb : Boolean;
Begin
  A := A0; B := B0;
  If (A.T = vtObj) And Not PIsArr(A) Then ObjValue(A);
  If (B.T = vtObj) And Not PIsArr(B) Then ObjValue(B);
  { null <=> chaine : chaine vide }
  If (A.T = vtNil) And IsStrCell(B) Then
  Begin
    PStrCell(B, Sb);
    If Sb.L = 0 Then PhpCompare := 0 Else PhpCompare := -1;
    Exit;
  End;
  If (B.T = vtNil) And IsStrCell(A) Then
  Begin
    PStrCell(A, Sa);
    If Sa.L = 0 Then PhpCompare := 0 Else PhpCompare := 1;
    Exit;
  End;
  { booleen ou null : comparaison en booleens }
  If (A.T = vtBool) Or (B.T = vtBool) Or (A.T = vtNil) Or (B.T = vtNil) Then
  Begin
    Ab := PBool(A); Bb := PBool(B);
    If Ab = Bb Then PhpCompare := 0 Else If Ab Then PhpCompare := 1 Else PhpCompare := -1;
    Exit;
  End;
  If PIsArr(A) Or PIsArr(B) Then
  Begin
    If PIsArr(A) And PIsArr(B) Then
    Begin
      If A.I = B.I Then PhpCompare := 0
      Else If DictCount(A.I) < DictCount(B.I) Then PhpCompare := -1
      Else If DictCount(A.I) > DictCount(B.I) Then PhpCompare := 1
      Else PhpCompare := 0;
    End
    Else If PIsArr(A) Then PhpCompare := 1
    Else PhpCompare := -1;
    Exit;
  End;
  If IsStrCell(A) And IsStrCell(B) Then
  Begin
    If PIsNumStr(A) And PIsNumStr(B) Then
    Begin
      PNumCell(A, Na); PNumCell(B, Nb);
    End
    Else
    Begin
      PStrCell(A, Sa); PStrCell(B, Sb);
      PhpCompare := StrCmpCells(Sa, Sb, False);
      Exit;
    End;
  End
  Else If IsStrCell(A) Or IsStrCell(B) Then
  Begin
    { nombre et chaine : numerique si la chaine est un nombre, sinon en chaines }
    If (IsStrCell(A) And Not PIsNumStr(A)) Or (IsStrCell(B) And Not PIsNumStr(B)) Then
    Begin
      PStrCell(A, Sa); PStrCell(B, Sb);
      PhpCompare := StrCmpCells(Sa, Sb, False);
      Exit;
    End;
    PNumCell(A, Na); PNumCell(B, Nb);
  End
  Else
  Begin
    PNumCell(A, Na); PNumCell(B, Nb);
  End;
  If Na.T = vtInt Then X := Na.I Else X := Na.R;
  If Nb.T = vtInt Then Y := Nb.I Else Y := Nb.R;
  If X < Y Then PhpCompare := -1 Else If X > Y Then PhpCompare := 1 Else PhpCompare := 0;
End;

{ === et !== }
Function PhpIdent(Var A0, B0 : TCell) : Boolean;
Var A, B, Sa, Sb : TCell; K, J, Ka, Kb : LongInt;
Begin
  A := A0; B := B0;
  If (A.T = vtObj) And Not PIsArr(A) Then ObjValue(A);
  If (B.T = vtObj) And Not PIsArr(B) Then ObjValue(B);
  PhpIdent := False;
  If IsStrCell(A) And IsStrCell(B) Then
  Begin
    PStrCell(A, Sa); PStrCell(B, Sb);
    PhpIdent := StrCmpCells(Sa, Sb, False) = 0;
    Exit;
  End;
  If (A.T = vtDate) Then A.T := vtReal;
  If (B.T = vtDate) Then B.T := vtReal;
  If A.T <> B.T Then Exit;
  Case A.T Of
    vtNil : PhpIdent := True;
    vtInt, vtBool : PhpIdent := A.I = B.I;
    vtReal : PhpIdent := A.R = B.R;
    vtObj :
      If A.I = B.I Then PhpIdent := True
      Else If PIsArr(A) And PIsArr(B) And (DictCount(A.I) = DictCount(B.I)) Then
      Begin
        { memes cles et valeurs dans le meme ordre }
        Ka := PArrNext(A.I, 0); Kb := PArrNext(B.I, 0);
        While (Ka >= 0) And (Kb >= 0) Do
        Begin
          If Not PhpIdent(DKey^[Ka], DKey^[Kb]) Or Not PhpIdent(DVal^[Ka], DVal^[Kb]) Then Exit;
          Ka := PArrNext(A.I, Ka + 1); Kb := PArrNext(B.I, Kb + 1);
        End;
        PhpIdent := True;
      End;
  End;
  K := 0; J := 0;
End;
{ date d'un texte "jj/mm/aaaa [hh:mm[:ss]]" ou "aaaa-mm-jj" }
Function ParseDate(S : String; Var D : Double) : Boolean;
Var A, B, C, H, Mi, Sc, P : LongInt; T : String;
Begin
  ParseDate := False;
  S := Trim(S);
  H := 0; Mi := 0; Sc := 0;
  P := Pos(' ', S);
  If P > 0 Then
  Begin
    T := Trim(Copy(S, P + 1, 20));
    S := Copy(S, 1, P - 1);
    H := SVal(Copy(T, 1, Pos(':', T) - 1));
    T := Copy(T, Pos(':', T) + 1, 20);
    If Pos(':', T) > 0 Then
    Begin
      Mi := SVal(Copy(T, 1, Pos(':', T) - 1));
      Sc := SVal(Copy(T, Pos(':', T) + 1, 5));
    End
    Else Mi := SVal(T);
  End;
  If Pos('-', S) > 0 Then
  Begin
    A := SVal(Copy(S, 1, Pos('-', S) - 1));
    S := Copy(S, Pos('-', S) + 1, 20);
    B := SVal(Copy(S, 1, Pos('-', S) - 1));
    C := SVal(Copy(S, Pos('-', S) + 1, 20));
    If (B < 1) Or (B > 12) Or (C < 1) Or (C > 31) Then Exit;
    D := UnixToOle(UnixTime(A, B, C, H, Mi, Sc));
    ParseDate := True;
    Exit;
  End;
  If Pos('/', S) = 0 Then Exit;
  A := SVal(Copy(S, 1, Pos('/', S) - 1));
  S := Copy(S, Pos('/', S) + 1, 20);
  If Pos('/', S) = 0 Then Exit;
  B := SVal(Copy(S, 1, Pos('/', S) - 1));
  C := SVal(Copy(S, Pos('/', S) + 1, 20));
  If C < 100 Then C := C + 2000;
  If (A < 1) Or (A > 31) Or (B < 1) Or (B > 12) Then Exit;
  D := UnixToOle(UnixTime(C, B, A, H, Mi, Sc));
  ParseDate := True;
End;

Function CellDate(Var C : TCell) : Double;
Var D : Double;
Begin
  If C.T = vtDate Then CellDate := C.R
  Else If IsStrCell(C) And ParseDate(CellPStr(C), D) Then CellDate := D
  Else CellDate := CellReal(C);
End;

{ format numerique : '0.00', '#,##0.00', '0', '0.###' }
Function FmtNum(V : Double; Fmt : String) : String;
Var Dec, K, P : LongInt; Sep, Neg : Boolean; S, Ip : String;
Begin
  P := Pos('.', Fmt);
  Dec := 0;
  If P > 0 Then
    For K := P + 1 To Length(Fmt) Do If (Fmt[K] = '0') Or (Fmt[K] = '#') Then Inc(Dec);
  Sep := Pos(',', Fmt) > 0;
  Neg := V < 0;
  If Neg Then V := -V;
  Str(V:0:Dec, S);
  If Sep Then
  Begin
    P := Pos('.', S);
    If P = 0 Then P := Length(S) + 1;
    Ip := Copy(S, 1, P - 1);
    K := Length(Ip) - 3;
    While K > 0 Do
    Begin
      Insert(' ', Ip, K + 1);
      K := K - 3;
    End;
    S := Ip + Copy(S, P, 255);
  End;
  If (Pos('#', Copy(Fmt, Pos('.', Fmt) + 1, 255)) > 0) And (Pos('.', S) > 0) Then
  Begin
    While S[Length(S)] = '0' Do Delete(S, Length(S), 1);
    If S[Length(S)] = '.' Then Delete(S, Length(S), 1);
  End;
  For K := 1 To Length(S) Do If S[K] = '.' Then S[K] := ',';
  If Neg Then S := '-' + S;
  FmtNum := S;
End;

{ --- operations arithmetiques et comparaisons --- }

Function NumKind(Var C : TCell) : LongInt;
Begin
  { 0 entier, 1 reel }
  If (C.T = vtReal) Or (C.T = vtDate) Then NumKind := 1
  Else If (C.T = vtStr) Or (C.T = vtKStr) Then
  Begin
    If Pos('.', CellPStr(C)) > 0 Then NumKind := 1 Else NumKind := 0;
  End
  Else NumKind := 0;
End;

Procedure Concat2(Var A, B : TCell; Var R : TCell);
Var Sa, Sb : TCell; Pb, Pa : PBytes; N : LongInt; Cb : Byte;
Begin
  If A.T = vtObj Then ObjValue(A);
  If B.T = vtObj Then ObjValue(B);
  If A.T = vtChar Then
  Begin
    Cb := A.I;
    MkStrB(@Cb, 1, Sa);
  End
  Else If (A.T = vtStr) Or (A.T = vtKStr) Then Sa := A
  Else CellToStr(A, Sa);
  If B.T = vtChar Then
  Begin
    Cb := B.I;
    Pb := @Cb; N := 1;
  End
  Else
  Begin
    If (B.T = vtStr) Or (B.T = vtKStr) Then Sb := B Else CellToStr(B, Sb);
    Pb := PoolPtr(Sb); N := Sb.L;
    If (Sb.T = vtStr) And (N > 0) Then
    Begin
      { Sb peut bouger si la zone grandit : copie }
      MkStrB(Pb, N, Sb);
      Pb := Nil;
    End;
  End;
  { ajout en place si Sa est la derniere chaine de la zone }
  If (Sa.T = vtStr) And (Sa.I + Sa.L = VmPool.Len) And (Sa.L > 0) And (Pb <> Nil) Then
  Begin
    If BufGrow(VmPool, N) Then
    Begin
      Move(Pb^[0], VmPool.P^[VmPool.Len], N);
      VmPool.Len := VmPool.Len + N;
      R := Sa;
      R.L := Sa.L + N;
    End;
    Exit;
  End;
  If Pb = Nil Then
  Begin
    { Sb est en fin de zone : nouvelle chaine Sa + Sb }
    If Not PoolNew(Sa.L + Sb.L, R) Then Exit;
    Pa := PoolPtr(Sa);
    If Sa.L > 0 Then Move(Pa^[0], VmPool.P^[R.I], Sa.L);
    If Sb.L > 0 Then Move(VmPool.P^[Sb.I], VmPool.P^[R.I + Sa.L], Sb.L);
    Exit;
  End;
  If Not PoolNew(Sa.L + N, R) Then Exit;
  Pa := PoolPtr(Sa);
  If Sa.L > 0 Then Move(Pa^[0], VmPool.P^[R.I], Sa.L);
  If N > 0 Then Move(Pb^[0], VmPool.P^[R.I + Sa.L], N);
End;

Function IsNumStr(Var C : TCell) : Boolean;
Var S : String; R : Double; E : LongInt;
Begin
  S := Trim(CellPStr(C));
  For E := 1 To Length(S) Do If S[E] = ',' Then S[E] := '.';
  Val(S, R, E);
  IsNumStr := (E = 0) And (S <> '');
End;

Procedure Arith(Op : LongInt; Var A, B : TCell; Var R : TCell);
Var X, Y : Double; I, J : LongInt;
Begin
  If PhpStyle Then
  Begin
    PhpArith(Op, A, B, R);
    Exit;
  End;
  If A.T = vtObj Then ObjValue(A);
  If B.T = vtObj Then ObjValue(B);
  If (Op = opAdd) And (IsStrCell(A) Or IsStrCell(B)) Then
  Begin
    { chaine + chaine : concatenation ; chaine numerique (ou vide) + nombre :
      addition (valeurs de Session, Request...) }
    If ((IsStrCell(A) Or (A.T = vtNil)) And (IsStrCell(B) Or (B.T = vtNil))) Or
       (IsStrCell(A) And (CellLen(A) > 0) And Not IsNumStr(A)) Or
       (IsStrCell(B) And (CellLen(B) > 0) And Not IsNumStr(B)) Or (A.T = vtChar) Or (B.T = vtChar) Then
    Begin
      Concat2(A, B, R);
      Exit;
    End;
  End;
  If (A.T = vtSet) Or (B.T = vtSet) Then
  Begin
    R.T := vtSet;
    Case Op Of
      opAdd :
        Begin
          R.I := A.I Or B.I; R.L := A.L Or B.L;
        End;
      opSub :
        Begin
          R.I := A.I And Not B.I; R.L := A.L And Not B.L;
        End;
      opMul :
        Begin
          R.I := A.I And B.I; R.L := A.L And B.L;
        End;
    End;
    Exit;
  End;
  If (Op = opDivR) Or (NumKind(A) = 1) Or (NumKind(B) = 1) Then
  Begin
    X := CellReal(A); Y := CellReal(B);
    Case Op Of
      opAdd : MkReal(X + Y, R);
      opSub : MkReal(X - Y, R);
      opMul : MkReal(X * Y, R);
      opDivR :
        If Y = 0 Then VmFail('division par z'#130'ro') Else MkReal(X / Y, R);
      opIDiv :
        If Trunc(Y) = 0 Then VmFail('division par z'#130'ro') Else MkInt(Round(X) Div Round(Y), R);
      opMod :
        If Round(Y) = 0 Then VmFail('division par z'#130'ro') Else MkInt(Round(X) Mod Round(Y), R);
    End;
    If (A.T = vtDate) And ((Op = opAdd) Or (Op = opSub)) And (B.T <> vtDate) Then R.T := vtDate;
    Exit;
  End;
  I := CellInt(A); J := CellInt(B);
  Case Op Of
    opAdd : MkInt(I + J, R);
    opSub : MkInt(I - J, R);
    opMul :
      Begin
        X := I * 1.0 * J;
        If (X > 2147483647.0) Or (X < -2147483648.0) Then MkReal(X, R) Else MkInt(I * J, R);
      End;
    opIDiv : If J = 0 Then VmFail('division par z'#130'ro') Else MkInt(I Div J, R);
    opMod : If J = 0 Then VmFail('division par z'#130'ro') Else MkInt(I Mod J, R);
  End;
End;

{ comparaison : -1, 0, 1 }
Function Compare(Var A, B : TCell) : LongInt;
Var X, Y : Double;
Begin
  If (A.T = vtObj) And (ObjK[A.I] = okItem) Then ObjValue(A);
  If (B.T = vtObj) And (ObjK[B.I] = okItem) Then ObjValue(B);
  If (A.T = vtNil) And (B.T = vtNil) Then Compare := 0
  Else If (A.T = vtObj) Or (B.T = vtObj) Then
  Begin
    If (A.T = B.T) And (A.I = B.I) Then Compare := 0 Else Compare := 1;
  End
  Else If (A.T = vtNil) And (B.T = vtObj) Or (A.T = vtObj) And (B.T = vtNil) Then Compare := 1
  Else If IsStrCell(A) And IsStrCell(B) Then Compare := StrCmpCells(A, B, False)
  Else If (IsStrCell(A) And (B.T = vtNil)) Or (IsStrCell(B) And (A.T = vtNil)) Then
  Begin
    If CellLen(A) + CellLen(B) = 0 Then Compare := 0 Else If A.T = vtNil Then Compare := -1 Else Compare := 1;
  End
  Else
  Begin
    If (A.T = vtChar) And Not IsStrCell(B) Then X := A.I Else X := CellReal(A);
    If (B.T = vtChar) And Not IsStrCell(A) Then Y := B.I Else Y := CellReal(B);
    If X < Y Then Compare := -1 Else If X > Y Then Compare := 1 Else Compare := 0;
  End;
End;

Procedure Convert(Var C : TCell; Cv : LongInt);
Var R : TCell;
Begin
  Case Cv Of
    cvInt :
      If C.T <> vtInt Then
      Begin
        If (C.T = vtReal) And ((C.R > 2147483647.0) Or (C.R < -2147483648.0)) Then Exit;
        MkInt(CellInt(C), C);
      End;
    cvReal : If C.T <> vtReal Then MkReal(CellReal(C), C);
    cvBool : If C.T <> vtBool Then MkBool(CellBool(C), C);
    cvStr :
      If (C.T <> vtStr) And (C.T <> vtKStr) Then
      Begin
        If C.T = vtNil Then MkStr('', C)
        Else
        Begin
          CellToStr(C, R);
          C := R;
        End;
      End;
    cvChar :
      If C.T <> vtChar Then
      Begin
        If (C.T = vtStr) Or (C.T = vtKStr) Then
        Begin
          If C.L > 0 Then
          Begin
            R.T := vtChar; R.I := PoolPtr(C)^[0];
          End
          Else
          Begin
            R.T := vtChar; R.I := 0;
          End;
          C := R;
        End
        Else
        Begin
          R.T := vtChar; R.I := CellInt(C) And 255; R.L := 0;
          C := R;
        End;
      End;
    9 :
      Begin
        C.T := vtSet; C.I := 0; C.L := 0;
      End;
  End;
End;

{ chaine d'un argument (copie pascale tronquee a 255) }
Function ArgPStr(Var C : TCell) : String;
Var R : TCell;
Begin
  If IsStrCell(C) Then ArgPStr := CellPStr(C)
  Else
  Begin
    CellToStr(C, R);
    ArgPStr := CellPStr(R);
  End;
End;

{ forme chaine d'une cellule (dans la zone) }
Procedure AsStr(Var C : TCell; Var R : TCell);
Var Cb : Byte;
Begin
  If C.T = vtChar Then
  Begin
    Cb := C.I;
    MkStrB(@Cb, 1, R);
  End
  Else If (C.T = vtStr) Or (C.T = vtKStr) Then R := C
  Else CellToStr(C, R);
End;

{ --- fonctions predefinies --- }

Procedure CallBuiltin(Id, Argc : LongInt);
Var B0, K, N, St, A, I, J, Y, Mo, Dd, H, Mi, Sc, Wd : LongInt; R, S, T, U : TCell; X : Double; Ps : String;
    P, Q : PBytes; Tb : TBuf; Arg : Array[0..15] Of TCell; Up : Boolean;
Begin
  B0 := SP - Argc + 1;
  For K := 0 To Argc - 1 Do Arg[K] := Stk[B0 + K];
  For K := Argc To 15 Do MkNil(Arg[K]);
  For K := 0 To Argc - 1 Do
    If (Arg[K].T = vtObj) And (Arg[K].I < NObj) And (ObjK[Arg[K].I] = okItem) Then ObjValue(Arg[K]);
  SP := B0 - 1;
  MkNil(R);
  If (Id >= 300) And (Id < 1000) Then
  Begin
    PhpBuiltin(Id, Argc, Arg, R);
    Push(R);
    Exit;
  End;
  If Id >= 1000 Then
  Begin
    { procedures a parametres variables : Arg[0] adresse }
    Case Id - 1000 Of
      vInc, vDec :
        Begin
          A := AddrOf(Arg[0]);
          If Not MemOk(A) Then Exit;
          N := CellInt(Arg[1]);
          If Id - 1000 = vDec Then N := -N;
          If Mem^[A].T = vtChar Then Mem^[A].I := (Mem^[A].I + N) And 255
          Else If Mem^[A].T = vtReal Then Mem^[A].R := Mem^[A].R + N
          Else MkInt(CellInt(Mem^[A]) + N, Mem^[A]);
        End;
      vStr :
        Begin
          A := AddrOf(Arg[3]);
          If Not MemOk(A) Then Exit;
          If Arg[0].T = vtReal Then MkStr(RealStr(Arg[0].R, CellInt(Arg[1]), CellInt(Arg[2])), Mem^[A])
          Else
          Begin
            Ps := IStr(CellInt(Arg[0]));
            While Length(Ps) < CellInt(Arg[1]) Do Ps := ' ' + Ps;
            MkStr(Ps, Mem^[A]);
          End;
        End;
      vVal :
        Begin
          Ps := ArgPStr(Arg[0]);
          A := AddrOf(Arg[1]);
          If Not MemOk(A) Then Exit;
          If CellInt(Arg[2]) = cvReal Then
          Begin
            Val(Ps, X, K);
            MkReal(X, Mem^[A]);
          End
          Else
          Begin
            Val(Ps, N, K);
            MkInt(N, Mem^[A]);
          End;
          A := AddrOf(Arg[3]);
          If MemOk(A) Then MkInt(K, Mem^[A]);
        End;
      vDelete :
        Begin
          A := AddrOf(Arg[0]);
          If Not MemOk(A) Then Exit;
          AsStr(Mem^[A], S);
          St := CellInt(Arg[1]); N := CellInt(Arg[2]);
          If (St >= 1) And (St <= S.L) And (N > 0) Then
          Begin
            If St + N - 1 > S.L Then N := S.L - St + 1;
            BufInit(Tb);
            BufAddB(Tb, PoolPtr(S), St - 1);
            P := PoolPtr(S);
            BufAddB(Tb, @P^[St - 1 + N], S.L - (St - 1 + N));
            MkStrB(Tb.P, Tb.Len, Mem^[A]);
            BufFree(Tb);
          End;
        End;
      vInsert :
        Begin
          AsStr(Arg[0], T);
          A := AddrOf(Arg[1]);
          If Not MemOk(A) Then Exit;
          AsStr(Mem^[A], S);
          St := CellInt(Arg[2]);
          If St < 1 Then St := 1;
          If St > S.L + 1 Then St := S.L + 1;
          BufInit(Tb);
          BufAddB(Tb, PoolPtr(S), St - 1);
          BufAddB(Tb, PoolPtr(T), T.L);
          P := PoolPtr(S);
          BufAddB(Tb, @P^[St - 1], S.L - St + 1);
          MkStrB(Tb.P, Tb.Len, Mem^[A]);
          BufFree(Tb);
        End;
      vSetLength :
        Begin
          A := AddrOf(Arg[0]);
          If Not MemOk(A) Then Exit;
          AsStr(Mem^[A], S);
          N := CellInt(Arg[1]);
          If N < 0 Then N := 0;
          If N <= S.L Then
          Begin
            S.L := N;
            Mem^[A] := S;
          End
          Else
          Begin
            BufInit(Tb);
            BufAddB(Tb, PoolPtr(S), S.L);
            While Tb.Len < N Do BufAddC(Tb, 32);
            MkStrB(Tb.P, Tb.Len, Mem^[A]);
            BufFree(Tb);
          End;
        End;
      vNew :
        Begin
          A := AddrOf(Arg[0]);
          N := CellInt(Arg[1]);
          If N < 1 Then N := 1;
          If HeapTop - N <= FsTop + 64 Then
          Begin
            VmFail('m'#130'moire de New '#130'puis'#130'e');
            Exit;
          End;
          HeapTop := HeapTop - N;
          For K := HeapTop To HeapTop + N - 1 Do MkNil(Mem^[K]);
          If MemOk(A) Then
          Begin
            Mem^[A].T := vtAddr; Mem^[A].I := HeapTop; Mem^[A].L := 0;
          End;
        End;
      vInclude, vExclude :
        Begin
          A := AddrOf(Arg[0]);
          If Not MemOk(A) Then Exit;
          N := CellInt(Arg[1]);
          If (N < 0) Or (N > 63) Then
          Begin
            VmFail('ensemble : '#130'l'#130'ment hors de 0..63');
            Exit;
          End;
          If Mem^[A].T <> vtSet Then
          Begin
            Mem^[A].T := vtSet; Mem^[A].I := 0; Mem^[A].L := 0;
          End;
          If Id - 1000 = vInclude Then
          Begin
            If N < 32 Then Mem^[A].I := Mem^[A].I Or (1 Shl N) Else Mem^[A].L := Mem^[A].L Or (1 Shl (N - 32));
          End
          Else If N < 32 Then Mem^[A].I := Mem^[A].I And Not (1 Shl N)
          Else Mem^[A].L := Mem^[A].L And Not (1 Shl (N - 32));
        End;
    End;
    Exit;
  End;
  Case Id Of
    bLength, bLen :
      If Arg[0].T = vtObj Then MkInt(0, R) Else
      Begin
        AsStr(Arg[0], S);
        MkInt(S.L, R);
      End;
    bCopy, bMid :
      Begin
        AsStr(Arg[0], S);
        St := CellInt(Arg[1]);
        If Argc > 2 Then N := CellInt(Arg[2]) Else N := S.L;
        If St < 1 Then
        Begin
          N := N + St - 1;
          St := 1;
        End;
        If St > S.L Then N := 0;
        If N > S.L - St + 1 Then N := S.L - St + 1;
        If N < 0 Then N := 0;
        R := S; R.I := S.I + St - 1; R.L := N;
        If N = 0 Then MkStr('', R);
      End;
    bLeft, bRight :
      Begin
        AsStr(Arg[0], S);
        N := CellInt(Arg[1]);
        If N > S.L Then N := S.L;
        If N < 0 Then N := 0;
        R := S; R.L := N;
        If Id = bRight Then R.I := S.I + S.L - N;
      End;
    bPos, bInStr, bInStrRev :
      Begin
        { Pos(sous, chaine) ; InStr([debut,] chaine, sous) }
        If Id = bPos Then
        Begin
          AsStr(Arg[0], T); AsStr(Arg[1], S); St := 1;
          If Argc > 2 Then St := CellInt(Arg[2]);
        End
        Else If (Id = bInStr) And (Argc >= 3) And Not IsStrCell(Arg[0]) Then
        Begin
          St := CellInt(Arg[0]); AsStr(Arg[1], S); AsStr(Arg[2], T);
        End
        Else
        Begin
          AsStr(Arg[0], S); AsStr(Arg[1], T); St := 1;
          If (Id = bInStrRev) And (Argc > 2) Then St := CellInt(Arg[2]);
        End;
        P := PoolPtr(S); Q := PoolPtr(T);
        N := 0;
        If Id = bInStrRev Then
        Begin
          If (Argc <= 2) Or (St < 0) Then St := S.L;
          For K := St - T.L DownTo 0 Do
          Begin
            J := 0;
            While (J < T.L) And (P^[K + J] = Q^[J]) Do Inc(J);
            If J = T.L Then
            Begin
              N := K + 1;
              Break;
            End;
          End;
        End
        Else If T.L = 0 Then N := St
        Else
          For K := St - 1 To S.L - T.L Do
          Begin
            J := 0;
            While (J < T.L) And (P^[K + J] = Q^[J]) Do Inc(J);
            If J = T.L Then
            Begin
              N := K + 1;
              Break;
            End;
          End;
        MkInt(N, R);
      End;
    bUpCase, bUpper, bLower, bLCase, bUCase :
      Begin
        Up := (Id = bUpCase) Or (Id = bUpper) Or (Id = bUCase);
        If Arg[0].T = vtChar Then
        Begin
          R := Arg[0];
          If Up And (R.I >= 97) And (R.I <= 122) Then R.I := R.I - 32
          Else If Not Up And (R.I >= 65) And (R.I <= 90) Then R.I := R.I + 32;
        End
        Else
        Begin
          AsStr(Arg[0], S);
          MkStrB(PoolPtr(S), S.L, R);
          P := PoolPtr(R);
          For K := 0 To R.L - 1 Do
            If Up And (P^[K] >= 97) And (P^[K] <= 122) Then P^[K] := P^[K] - 32
            Else If Not Up And (P^[K] >= 65) And (P^[K] <= 90) Then P^[K] := P^[K] + 32;
        End;
      End;
    bTrim, bTrimL, bTrimR, bLTrim, bRTrim :
      Begin
        AsStr(Arg[0], S);
        R := S;
        P := PoolPtr(S);
        If (Id = bTrim) Or (Id = bTrimL) Or (Id = bLTrim) Then
          While (R.L > 0) And (P^[R.I - S.I] <= 32) Do
          Begin
            Inc(R.I); Dec(R.L);
          End;
        If (Id = bTrim) Or (Id = bTrimR) Or (Id = bRTrim) Then
          While (R.L > 0) And (P^[R.I - S.I + R.L - 1] <= 32) Do Dec(R.L);
      End;
    bIntToStr, bCStr :
      If Arg[0].T = vtInt Then MkStr(IStr(Arg[0].I), R) Else CellToStr(Arg[0], R);
    bStrToInt, bCInt, bCLng, bCByte :
      If (Id = bCInt) Or (Id = bCLng) Then MkInt(Round(CellReal(Arg[0])), R)
      Else MkInt(CellInt(Arg[0]), R);
    bStrToIntDef :
      Begin
        Val(Trim(ArgPStr(Arg[0])), N, K);
        If K <> 0 Then N := CellInt(Arg[1]);
        MkInt(N, R);
      End;
    bFloatToStr : MkStr(VbRealStr(CellReal(Arg[0])), R);
    bStrToFloat, bCDbl, bCSng : MkReal(CellReal(Arg[0]), R);
    bCBool : MkBool(CellBool(Arg[0]), R);
    bChr, bChrV :
      Begin
        R.T := vtChar; R.I := CellInt(Arg[0]) And 255; R.L := 0;
        If VbStyle Then AsStr(R, R);
      End;
    bOrd, bAsc :
      If Arg[0].T = vtChar Then MkInt(Arg[0].I, R)
      Else If IsStrCell(Arg[0]) Then
      Begin
        If CellLen(Arg[0]) > 0 Then MkInt(PoolPtr(Arg[0])^[0], R) Else MkInt(0, R);
      End
      Else MkInt(CellInt(Arg[0]), R);
    bSucc, bPred :
      Begin
        R := Arg[0];
        If Id = bSucc Then N := 1 Else N := -1;
        If R.T = vtChar Then R.I := (R.I + N) And 255
        Else If R.T = vtBool Then R.I := (R.I + N) And 1
        Else MkInt(CellInt(R) + N, R);
      End;
    bAbs :
      If Arg[0].T = vtReal Then MkReal(Abs(Arg[0].R), R) Else MkInt(Abs(CellInt(Arg[0])), R);
    bSqr :
      If Arg[0].T = vtReal Then MkReal(Sqr(Arg[0].R), R) Else MkInt(Sqr(CellInt(Arg[0])), R);
    bSqrt :
      Begin
        X := CellReal(Arg[0]);
        If X < 0 Then VmFail('racine carr'#130'e d''un nombre n'#130'gatif') Else MkReal(Sqrt(X), R);
      End;
    bSin : MkReal(Sin(CellReal(Arg[0])), R);
    bCos : MkReal(Cos(CellReal(Arg[0])), R);
    bTan : MkReal(Sin(CellReal(Arg[0])) / Cos(CellReal(Arg[0])), R);
    bArcTan, bAtn : MkReal(ArcTan(CellReal(Arg[0])), R);
    bExp, bExpV : MkReal(Exp(CellReal(Arg[0])), R);
    bLn, bLog :
      Begin
        X := CellReal(Arg[0]);
        If X <= 0 Then VmFail('logarithme d''un nombre n'#130'gatif ou nul') Else MkReal(Ln(X), R);
      End;
    bPower : MkReal(Exp(CellReal(Arg[1]) * Ln(Abs(CellReal(Arg[0])) + 1E-300)), R);
    bRound : MkInt(Round(CellReal(Arg[0])), R);
    bTrunc, bFix : MkInt(Trunc(CellReal(Arg[0])), R);
    bInt :
      If VbStyle Then MkInt(Trunc(CellReal(Arg[0])) - Ord((CellReal(Arg[0]) < 0) And (Frac(CellReal(Arg[0])) <> 0)), R)
      Else MkReal(Int(CellReal(Arg[0])), R);
    bFrac : MkReal(Frac(CellReal(Arg[0])), R);
    bRandom :
      If Argc = 0 Then MkReal(VmRand / 8388608.0, R)
      Else
      Begin
        N := CellInt(Arg[0]);
        If N <= 0 Then MkInt(0, R) Else MkInt(VmRand Mod N, R);
      End;
    bRnd : MkReal(VmRand / 8388608.0, R);
    bRandomize : RndSeed := PRdtsc Xor PTicks;
    bOdd : MkBool(Odd(CellInt(Arg[0])), R);
    bLo : MkInt(CellInt(Arg[0]) And 255, R);
    bHi : MkInt((CellInt(Arg[0]) Shr 8) And 255, R);
    bSwap :
      Begin
        N := CellInt(Arg[0]);
        MkInt(((N And 255) Shl 8) Or ((N Shr 8) And 255), R);
      End;
    bNow, bDate, bTime :
      Begin
        If Id = bNow Then MkReal(DateNow, R) Else If Id = bDate Then MkReal(Int(DateNow), R)
        Else MkReal(Frac(DateNow), R);
        R.T := vtDate;
      End;
    bTimer : MkReal((NowUnix Mod 86400) + (PTicks Mod 1000) / 1000.0, R);
    bDateToStr, bTimeToStr, bDateTimeToStr :
      Begin
        If Argc > 0 Then X := CellDate(Arg[0]) Else X := DateNow;
        If Id = bDateToStr Then MkStr(DateStr(X, 1), R)
        Else If Id = bTimeToStr Then MkStr(DateStr(X, 2), R)
        Else MkStr(DateStr(X, 0), R);
      End;
    bStringOfChar, bString, bSpace :
      Begin
        If Id = bSpace Then
        Begin
          N := CellInt(Arg[0]); K := 32;
        End
        Else If Id = bString Then
        Begin
          N := CellInt(Arg[0]);
          If IsStrCell(Arg[1]) And (Arg[1].T <> vtChar) Then K := PoolPtr(Arg[1])^[0] Else K := CellInt(Arg[1]);
          If Arg[1].T = vtChar Then K := Arg[1].I;
        End
        Else
        Begin
          N := CellInt(Arg[1]);
          If Arg[0].T = vtChar Then K := Arg[0].I Else If IsStrCell(Arg[0]) Then K := PoolPtr(Arg[0])^[0]
          Else K := CellInt(Arg[0]);
        End;
        If N < 0 Then N := 0;
        If PoolNew(N, R) Then FillChar(VmPool.P^[R.I], N, K);
      End;
    bPi : MkReal(Pi, R);
    bMax, bMin :
      Begin
        K := Compare(Arg[0], Arg[1]);
        If ((Id = bMax) And (K >= 0)) Or ((Id = bMin) And (K <= 0)) Then R := Arg[0] Else R := Arg[1];
      End;
    bCreateObject : CreateObj(ArgPStr(Arg[0]), R);
    bConcat, bJoin :
      If Id = bConcat Then
      Begin
        R := Arg[0];
        AsStr(R, R);
        For K := 1 To Argc - 1 Do Concat2(R, Arg[K], R);
      End
      Else
      Begin
        { Join(tableau [, separateur]) }
        If Argc > 1 Then AsStr(Arg[1], T) Else MkStr(' ', T);
        MkStr('', R);
        If Arg[0].T = vtObj Then
        Begin
          N := 0;
          For K := 0 To NDict - 1 Do
            If DObj^[K] = Arg[0].I Then
            Begin
              If N > 0 Then Concat2(R, T, R);
              Concat2(R, DVal^[K], R);
              Inc(N);
            End;
        End;
      End;
    bFormatFloat : MkStr(FmtNum(CellReal(Arg[1]), ArgPStr(Arg[0])), R);
    bFormatNumber, bFormatCurrency, bFormatPercent :
      Begin
        If Argc > 1 Then N := CellInt(Arg[1]) Else N := 2;
        X := CellReal(Arg[0]);
        If Id = bFormatPercent Then X := X * 100;
        Ps := '#,##0';
        If N > 0 Then
        Begin
          Ps := Ps + '.';
          For K := 1 To N Do Ps := Ps + '0';
        End;
        Ps := FmtNum(X, Ps);
        If Id = bFormatCurrency Then Ps := Ps + ' $';
        If Id = bFormatPercent Then Ps := Ps + ' %';
        MkStr(Ps, R);
      End;
    bIntToHex, bHex :
      Begin
        N := 1;
        If (Id = bIntToHex) Then N := CellInt(Arg[1]);
        Ps := Hex(CellInt(Arg[0]), 8);
        While (Length(Ps) > N) And (Ps[1] = '0') Do Delete(Ps, 1, 1);
        MkStr(Ps, R);
      End;
    bOct :
      Begin
        N := CellInt(Arg[0]);
        Ps := '';
        Repeat
          Ps := Chr(48 + (N And 7)) + Ps;
          N := (N Shr 3) And $1FFFFFFF;
        Until N = 0;
        MkStr(Ps, R);
      End;
    bFileExists : MkBool(PExists(FsPath(ArgPStr(Arg[0]))), R);
    bHtmlEncode, bEscape :
      Begin
        AsStr(Arg[0], S);
        BufInit(Tb);
        P := PoolPtr(S);
        For K := 0 To S.L - 1 Do
          If Id = bEscape Then
          Begin
            If Chr(P^[K]) In ['A'..'Z', 'a'..'z', '0'..'9', '@', '*', '_', '+', '-', '.', '/'] Then BufAddC(Tb, P^[K])
            Else BufAdd(Tb, '%' + Hex(P^[K], 2));
          End
          Else
            Case P^[K] Of
              60 : BufAdd(Tb, '&lt;');
              62 : BufAdd(Tb, '&gt;');
              38 : BufAdd(Tb, '&amp;');
              34 : BufAdd(Tb, '&quot;');
            Else
              BufAddC(Tb, P^[K]);
            End;
        MkStrB(Tb.P, Tb.Len, R);
        BufFree(Tb);
      End;
    bUrlEncode : MkStr(UrlEncode(ArgPStr(Arg[0])), R);
    bUnescape :
      Begin
        AsStr(Arg[0], S);
        DecodeCell(PoolPtr(S), S.L, False, R);
      End;
    bIsNumeric : MkBool((Arg[0].T = vtInt) Or (Arg[0].T = vtReal) Or (IsStrCell(Arg[0]) And IsNumStr(Arg[0])), R);
    bIsEmpty : MkBool((Arg[0].T = vtNil) Or (IsStrCell(Arg[0]) And (CellLen(Arg[0]) = 0) And Not VbStyle), R);
    bIsNull : MkBool(False, R);
    bIsObject : MkBool(Arg[0].T = vtObj, R);
    bIsArray : MkBool((Arg[0].T = vtObj) And (ObjK[Arg[0].I] = okArr), R);
    bReplace :
      Begin
        AsStr(Arg[0], S); AsStr(Arg[1], T); AsStr(Arg[2], U);
        BufInit(Tb);
        P := PoolPtr(S); Q := PoolPtr(T);
        K := 0;
        While K < S.L Do
        Begin
          J := 0;
          If T.L > 0 Then
            While (J < T.L) And (K + J < S.L) And
                  ((P^[K + J] = Q^[J]) Or (VbStyle And (UpCase(Chr(P^[K + J])) = UpCase(Chr(Q^[J]))) And False)) Do Inc(J);
          If (T.L > 0) And (J = T.L) Then
          Begin
            BufAddB(Tb, PoolPtr(U), U.L);
            K := K + T.L;
          End
          Else
          Begin
            BufAddC(Tb, P^[K]);
            Inc(K);
          End;
        End;
        MkStrB(Tb.P, Tb.Len, R);
        BufFree(Tb);
      End;
    bStrReverse :
      Begin
        AsStr(Arg[0], S);
        If PoolNew(S.L, R) Then
          For K := 0 To S.L - 1 Do VmPool.P^[R.I + K] := PoolPtr(S)^[S.L - 1 - K];
      End;
    bStrComp :
      Begin
        AsStr(Arg[0], S); AsStr(Arg[1], T);
        MkInt(StrCmpCells(S, T, (Argc > 2) And (CellInt(Arg[2]) = 1)), R);
      End;
    bYear, bMonth, bDay, bHour, bMinute, bSecond, bWeekday :
      Begin
        DateSplit(CellDate(Arg[0]), Y, Mo, Dd, H, Mi, Sc, Wd);
        Case Id Of
          bYear : MkInt(Y, R);
          bMonth : MkInt(Mo, R);
          bDay : MkInt(Dd, R);
          bHour : MkInt(H, R);
          bMinute : MkInt(Mi, R);
          bSecond : MkInt(Sc, R);
        Else
          MkInt(Wd + 1, R);
        End;
      End;
    bMonthName :
      Begin
        N := CellInt(Arg[0]);
        Case N Of
          1 : Ps := 'janvier'; 2 : Ps := 'f'#130'vrier'; 3 : Ps := 'mars'; 4 : Ps := 'avril'; 5 : Ps := 'mai';
          6 : Ps := 'juin'; 7 : Ps := 'juillet'; 8 : Ps := 'ao'#150't'; 9 : Ps := 'septembre';
          10 : Ps := 'octobre'; 11 : Ps := 'novembre'; 12 : Ps := 'd'#130'cembre';
        Else
          Ps := '';
        End;
        MkStr(Ps, R);
      End;
    bWeekdayName :
      Begin
        Case CellInt(Arg[0]) Of
          1 : Ps := 'dimanche'; 2 : Ps := 'lundi'; 3 : Ps := 'mardi'; 4 : Ps := 'mercredi'; 5 : Ps := 'jeudi';
          6 : Ps := 'vendredi'; 7 : Ps := 'samedi';
        Else
          Ps := '';
        End;
        MkStr(Ps, R);
      End;
    bDateSerial :
      Begin
        MkReal(UnixToOle(UnixTime(CellInt(Arg[0]), CellInt(Arg[1]), CellInt(Arg[2]), 0, 0, 0)), R);
        R.T := vtDate;
      End;
    bTimeSerial :
      Begin
        MkReal(UnixToOle(CellInt(Arg[0]) * 3600 + CellInt(Arg[1]) * 60 + CellInt(Arg[2])) - 25569.0, R);
        R.T := vtDate;
      End;
    bCDate, bDateValue, bTimeValue :
      Begin
        MkReal(CellDate(Arg[0]), R);
        R.T := vtDate;
      End;
    bIsDate : MkBool((Arg[0].T = vtDate) Or (IsStrCell(Arg[0]) And ParseDate(CellPStr(Arg[0]), X)), R);
    bDateAdd :
      Begin
        Ps := LoStr(ArgPStr(Arg[0]));
        X := CellDate(Arg[2]);
        N := CellInt(Arg[1]);
        If Ps = 'd' Then X := X + N Else If Ps = 'ww' Then X := X + 7 * N
        Else If Ps = 'h' Then X := X + N / 24.0 Else If Ps = 'n' Then X := X + N / 1440.0
        Else If Ps = 's' Then X := X + N / 86400.0
        Else If (Ps = 'm') Or (Ps = 'yyyy') Then
        Begin
          DateSplit(X, Y, Mo, Dd, H, Mi, Sc, Wd);
          If Ps = 'yyyy' Then Y := Y + N Else
          Begin
            Mo := Mo + N;
            While Mo > 12 Do
            Begin
              Mo := Mo - 12; Inc(Y);
            End;
            While Mo < 1 Do
            Begin
              Mo := Mo + 12; Dec(Y);
            End;
          End;
          X := UnixToOle(UnixTime(Y, Mo, Dd, H, Mi, Sc));
        End;
        MkReal(X, R);
        R.T := vtDate;
      End;
    bDateDiff :
      Begin
        Ps := LoStr(ArgPStr(Arg[0]));
        X := CellDate(Arg[2]) - CellDate(Arg[1]);
        If Ps = 'h' Then X := X * 24 Else If Ps = 'n' Then X := X * 1440 Else If Ps = 's' Then X := X * 86400
        Else If Ps = 'ww' Then X := X / 7 Else If Ps = 'm' Then X := X / 30.4375 Else If Ps = 'yyyy' Then X := X / 365.25;
        MkInt(Trunc(X), R);
      End;
    bFormatDateTime :
      Begin
        X := CellDate(Arg[0]);
        N := 0;
        If Argc > 1 Then N := CellInt(Arg[1]);
        Case N Of
          2 : MkStr(DateStr(X, 1), R);
          3, 4 : MkStr(DateStr(X, 2), R);
        Else
          MkStr(DateStr(X, 0), R);
        End;
      End;
    bSgn :
      Begin
        X := CellReal(Arg[0]);
        If X > 0 Then MkInt(1, R) Else If X < 0 Then MkInt(-1, R) Else MkInt(0, R);
      End;
    bSplit :
      Begin
        AsStr(Arg[0], S);
        If Argc > 1 Then AsStr(Arg[1], T) Else MkStr(' ', T);
        A := ObjNew(okArr, 0, 0);
        P := PoolPtr(S); Q := PoolPtr(T);
        St := 0; K := 0; I := 0;
        While K <= S.L Do
        Begin
          J := 0;
          If (K < S.L) And (T.L > 0) Then
            While (J < T.L) And (K + J < S.L) And (P^[K + J] = Q^[J]) Do Inc(J);
          If (K = S.L) Or ((T.L > 0) And (J = T.L)) Then
          Begin
            MkInt(I, U);
            R := S; R.I := S.I + St; R.L := K - St;
            If S.T = vtKStr Then
            Begin
              R.I := S.I + St;
            End;
            DictAdd(A, U, R);
            Inc(I);
            K := K + T.L;
            St := K;
            If K > S.L Then Break;
            If K = S.L Then
            Begin
              MkInt(I, U);
              MkStr('', R);
              If (T.L > 0) And (J = T.L) Then DictAdd(A, U, R);
              Break;
            End;
          End
          Else Inc(K);
        End;
        MkObj(A, R);
      End;
    bUBound, bLBound :
      If Id = bLBound Then MkInt(0, R)
      Else If Arg[0].T = vtObj Then MkInt(DictCount(Arg[0].I) - 1, R)
      Else MkInt(-1, R);
    bArray :
      Begin
        A := ObjNew(okArr, 0, 0);
        For K := 0 To Argc - 1 Do
        Begin
          MkInt(K, U);
          DictAdd(A, U, Arg[K]);
        End;
        MkObj(A, R);
      End;
    bTypeName, bVarType :
      Begin
        Case Arg[0].T Of
          vtNil : Begin Ps := 'Empty'; N := 0; End;
          vtInt : Begin Ps := 'Long'; N := 3; End;
          vtReal : Begin Ps := 'Double'; N := 5; End;
          vtBool : Begin Ps := 'Boolean'; N := 11; End;
          vtStr, vtKStr, vtChar : Begin Ps := 'String'; N := 8; End;
          vtDate : Begin Ps := 'Date'; N := 7; End;
          vtObj : Begin Ps := 'Object'; N := 9; End;
        Else
          Begin Ps := 'Variant'; N := 12; End;
        End;
        If Id = bTypeName Then MkStr(Ps, R) Else MkInt(N, R);
      End;
    bCurDir : MkStr(Sites[Conns[VmConn].Site].Root, R);
    bMakeArr, bReDim :
      Begin
        { Dim a(n [, m]) ; ReDim Preserve a(n) (ancien tableau en tete) }
        St := 0;
        If Id = bReDim Then St := 1;
        I := CellInt(Arg[St]) + 1;
        J := 0;
        If Argc > St + 1 Then J := CellInt(Arg[St + 1]) + 1;
        If I < 0 Then I := 0;
        If J > 0 Then N := I * J Else N := I;
        If N > 100000 Then
        Begin
          VmFail('tableau trop grand');
          Exit;
        End;
        A := ObjNew(okArr, I, J);
        For K := 0 To N - 1 Do
        Begin
          MkInt(K, U);
          MkNil(T);
          If (Id = bReDim) And (Arg[0].T = vtObj) And (ObjK[Arg[0].I] = okArr) Then
          Begin
            B0 := ArrSlot(Arg[0].I, K);
            If B0 >= 0 Then T := DVal^[B0];
          End;
          DictAdd(A, U, T);
        End;
        MkObj(A, R);
      End;
    bEachCount :
      If Arg[0].T <> vtObj Then MkInt(0, R)
      Else
        Case ObjK[Arg[0].I] Of
          okArr, okDict : MkInt(DictCount(Arg[0].I), R);
          okColl :
            Begin
              CollLoad(ObjA[Arg[0].I]);
              Case ObjA[Arg[0].I] Of
                rcQuery : MkInt(QsN, R);
                rcForm : MkInt(FmN, R);
                rcCookies : MkInt(CkN, R);
              Else
                MkInt(0, R);
              End;
            End;
          okItem :
            Begin
              CollLoad(ObjA[Arg[0].I]);
              MkInt(CollCount(ObjA[Arg[0].I], ObjS[Arg[0].I]), R);
            End;
        Else
          MkInt(0, R);
        End;
    bEachItem :
      Begin
        K := CellInt(Arg[1]);
        Case ObjK[Arg[0].I] Of
          okArr :
            Begin
              A := ArrSlot(Arg[0].I, K);
              If A >= 0 Then R := DVal^[A];
            End;
          okDict :
            Begin
              A := ArrSlot(Arg[0].I, K);
              If A >= 0 Then R := DKey^[A];
            End;
          okColl :
            Case ObjA[Arg[0].I] Of
              rcQuery : R := QsK[K];
              rcForm : R := FmK[K];
              rcCookies : R := CkK[K];
            End;
          okItem :
            Begin
              A := CollFind(ObjA[Arg[0].I], ObjS[Arg[0].I], K + 1);
              If A >= 0 Then CollVal(ObjA[Arg[0].I], A, R);
            End;
        End;
      End;
    bOnError :
      Begin
        VmOnErrResume := CellInt(Arg[0]) <> 0;
        Exit;
      End;
  Else
    VmFail('fonction predefinie inconnue (' + IStr(Id) + ')');
  End;
  Push(R);
End;

{ ==================================================================== }
{ PHP : execution (opPhp), superglobales, bases de donnees (mysqli,      }
{ pg_*, PDO) et fonctions de la bibliotheque de PHP (opCallB >= 300)    }
{ ==================================================================== }

Var
  PSupObj : Array[1..9] Of LongInt;      { superglobales de la requete }
  PObMark : Array[0..7] Of LongInt;      { ob_start : debut des tampons }
  PNOb : LongInt;
  PRandSeed : LongInt;

Procedure PhpReset;
Var K : LongInt;
Begin
  For K := 1 To 9 Do PSupObj[K] := -1;
  PNOb := 0;
End;

Procedure PSetStrKey(Id : LongInt; Const K : String; Var V : TCell);
Var Kc : TCell;
Begin
  MkStr(K, Kc);
  PArrSet(Id, Kc, V);
End;

{ nom=valeur d'un formulaire : a[]=1, a[x]=2 (tableaux de PHP) }
Procedure PAddPair(Id : LongInt; Var K, V : TCell);
Var T, Kc, Sub : TCell; P : PBytes; B, E, J : LongInt; Child : LongInt;
Begin
  PStrCell(K, T);
  P := PoolPtr(T);
  B := -1;
  For J := 0 To T.L - 1 Do If (B < 0) And (P^[J] = 91) Then B := J;
  If (B <= 0) Or (P^[T.L - 1] <> 93) Then
  Begin
    PArrSet(Id, T, V);
    Exit;
  End;
  MkStrB(P, B, Kc);
  P := PoolPtr(T);
  PArrGet(Id, Kc, Sub);
  If PIsArr(Sub) Then Child := Sub.I
  Else
  Begin
    Child := PArrNew;
    MkObj(Child, Sub);
    PArrSet(Id, Kc, Sub);
  End;
  E := T.L - 1;
  If E = B + 1 Then PArrPush(Child, V)
  Else
  Begin
    P := PoolPtr(T);
    MkStrB(@P^[B + 1], E - B - 1, Kc);
    PArrSet(Child, Kc, V);
  End;
End;

Function PSuperBuild(N : LongInt) : LongInt;
Var Id, K : LongInt; V : TCell; S : String;
Const
  SvNames : Array[0..21] Of String[24] = ('REQUEST_METHOD', 'QUERY_STRING', 'SERVER_NAME', 'SERVER_PORT', 'HTTPS',
    'REMOTE_ADDR', 'REMOTE_PORT', 'SERVER_ADDR', 'SERVER_SOFTWARE', 'SERVER_PROTOCOL', 'SCRIPT_NAME',
    'PHP_SELF', 'SCRIPT_FILENAME', 'DOCUMENT_ROOT', 'REQUEST_URI', 'HTTP_HOST', 'HTTP_USER_AGENT',
    'HTTP_ACCEPT', 'HTTP_ACCEPT_LANGUAGE', 'HTTP_REFERER', 'HTTP_COOKIE', 'CONTENT_TYPE');
Begin
  Id := PArrNew;
  Case N Of
    1, 3 :
      Begin
        LoadQuery;
        For K := 0 To QsN - 1 Do PAddPair(Id, QsK[K], QsV[K]);
        If N = 3 Then
        Begin
          LoadForm;
          For K := 0 To FmN - 1 Do PAddPair(Id, FmK[K], FmV[K]);
        End;
      End;
    2 :
      Begin
        LoadForm;
        For K := 0 To FmN - 1 Do PAddPair(Id, FmK[K], FmV[K]);
      End;
    4 :
      Begin
        LoadCookies;
        For K := 0 To CkN - 1 Do PArrSet(Id, CkK[K], CkV[K]);
      End;
    5 :
      Begin
        For K := 0 To 21 Do
        Begin
          S := SvNames[K];
          If S = 'SERVER_ADDR' Then MkStr(ServerVar('LOCAL_ADDR'), V)
          Else If S = 'PHP_SELF' Then MkStr(ServerVar('SCRIPT_NAME'), V)
          Else If S = 'SCRIPT_FILENAME' Then MkStr(ScriptPath[VmConn], V)
          Else If S = 'DOCUMENT_ROOT' Then MkStr(Sites[Conns[VmConn].Site].Root, V)
          Else If S = 'REQUEST_URI' Then
          Begin
            S := Conns[VmConn].Uri;
            If Conns[VmConn].Query <> '' Then S := S + '?' + Conns[VmConn].Query;
            MkStr(S, V);
            S := 'REQUEST_URI';
          End
          Else If S = 'HTTPS' Then
          Begin
            If Not Conns[VmConn].IsTls Then Continue;
            MkStr('on', V);
          End
          Else MkStr(ServerVar(S), V);
          If (S = 'HTTP_REFERER') Or (S = 'HTTP_COOKIE') Or (S = 'CONTENT_TYPE') Or (S = 'HTTP_ACCEPT_LANGUAGE') Then
            If V.L = 0 Then Continue;
          PSetStrKey(Id, S, V);
        End;
        MkInt(NowUnix, V);
        PSetStrKey(Id, 'REQUEST_TIME', V);
        MkStr('CGI/1.1', V);
        PSetStrKey(Id, 'GATEWAY_INTERFACE', V);
      End;
  End;
  PSuperBuild := Id;
End;

{ element C[K] (sans le creer) }
Procedure PGetElem(Var C0 : TCell; Var K : TCell; KPos : LongInt; Var R : TCell);
Var C, T, V : TCell; I, N : LongInt; P : PBytes;
Begin
  MkNil(R);
  C := C0;
  If (C.T = vtObj) And Not PIsArr(C) And (C.I < NObj) And (ObjK[C.I] = okItem) Then ObjValue(C);
  If PIsArr(C) Then
  Begin
    PArrGet(C.I, K, R);
    Exit;
  End;
  If C.T = vtObj Then
  Begin
    { Session, dictionnaire, jeu d'enregistrements... : membre par defaut }
    MkNil(V);
    MemberCall(C, mDefault, 1, KPos, R, False, V);
    If (R.T = vtObj) And (R.I < NObj) And (ObjK[R.I] = okItem) Then ObjValue(R);
    Exit;
  End;
  If IsStrCell(C) Then
  Begin
    PStrCell(C, T);
    I := CellInt(K);
    N := T.L;
    If I < 0 Then I := N + I;
    If (I >= 0) And (I < N) Then
    Begin
      P := PoolPtr(T);
      MkStrB(@P^[I], 1, R);
    End
    Else MkStr('', R);
  End;
End;

Procedure PSetElem(Var C : TCell; Var K, V : TCell; KPos : LongInt);
Var R : TCell;
Begin
  If PIsArr(C) Then PArrSet(C.I, K, V)
  Else If C.T = vtObj Then MemberCall(C, mDefault, 1, KPos, R, True, V)
  Else VmFail('Cannot use a scalar value as an array');
End;

{ ligne en cours d'un jeu d'enregistrements : Mode 1 associatif, 2 numerique, 3 les deux }
Function PRowArr(Rs, Mode : LongInt) : LongInt;
Var Id, C : LongInt; V, S, Kc : TCell;
Begin
  Id := PArrNew;
  For C := 0 To Rss[Rs].NCol - 1 Do
  Begin
    RsValue(Rs, C, V);
    { PHP rend les colonnes en chaines (NULL : null) }
    If V.T = vtBool Then MkStr(Copy('01', V.I + 1, 1), S)
    Else If V.T <> vtNil Then PStrCell(V, S)
    Else S := V;
    If (Mode And 2) <> 0 Then
    Begin
      MkInt(C, Kc);
      PArrSet(Id, Kc, S);
    End;
    If (Mode And 1) <> 0 Then PSetStrKey(Id, Rss[Rs].ColNm[C], S);
  End;
  PRowArr := Id;
End;

{ suivant pour foreach : tableau (indice brut), jeu d'enregistrements (ligne) }
Function PEachRs(Var C : TCell) : LongInt;
Var K : LongInt;
Begin
  PEachRs := -1;
  If (C.T <> vtObj) Or (C.I < 0) Or (C.I >= NObj) Then Exit;
  K := -1;
  If ObjK[C.I] = okDbRs Then K := ObjA[C.I]
  Else If ObjK[C.I] = okDbStmt Then K := ObjB[C.I];
  If (K >= 0) And ((K >= MaxRs) Or Not Rss[K].Used) Then K := -1;
  PEachRs := K;
End;

Procedure PhpOp(Sub, A : LongInt);
Var X, Y, Z, R : TCell; K, Id, Rs, I : LongInt;
Begin
  Case Sub Of
    psBool : MkBool(PBool(Stk[SP]), Stk[SP]);
    psNum :
      Begin
        X := Stk[SP];
        PNumCell(X, Stk[SP]);
      End;
    psStr :
      Begin
        X := Stk[SP];
        PStrCell(X, Stk[SP]);
      End;
    psGet :
      Begin
        X := Stk[SP - 1];
        PGetElem(X, Stk[SP], SP, R);
        Dec(SP);
        Stk[SP] := R;
      End;
    psSet :
      Begin
        Y := Stk[SP];
        X := Stk[SP - 2];
        PSetElem(X, Stk[SP - 1], Y, SP - 1);
        SP := SP - 2;
        Stk[SP] := Y;
      End;
    psPush :
      Begin
        Y := Stk[SP];
        X := Stk[SP - 1];
        Dec(SP);
        If PIsArr(X) Then PArrPush(X.I, Y) Else VmFail('[] : tableau attendu');
        Stk[SP] := Y;
      End;
    psArrW :
      Begin
        K := AddrOf(Stk[SP]);
        If Not MemOk(K) Then Exit;
        X := Mem^[K];
        If (X.T = vtObj) And (X.I < NObj) And (ObjK[X.I] = okItem) Then ObjValue(X);
        If X.T = vtObj Then Stk[SP] := X
        Else If (X.T = vtNil) Or ((X.T = vtBool) And (X.I = 0)) Or (IsStrCell(X) And (CellLen(X) = 0)) Then
        Begin
          MkObj(PArrNew, Mem^[K]);
          Stk[SP] := Mem^[K];
        End
        Else If IsStrCell(X) Then
        Begin
          VmFail('cha'#140'ne modifi'#130'e par [] : non pris en charge');
        End
        Else VmFail('Cannot use a scalar value as an array');
      End;
    psSubW :
      Begin
        X := Stk[SP - 1];
        PGetElem(X, Stk[SP], SP, R);
        If (R.T <> vtObj) Then
        Begin
          If (R.T <> vtNil) And Not (IsStrCell(R) And (CellLen(R) = 0)) Then
          Begin
            VmFail('Cannot use a scalar value as an array');
            Exit;
          End;
          MkObj(PArrNew, R);
          PSetElem(X, Stk[SP], R, SP);
        End;
        Dec(SP);
        Stk[SP] := R;
      End;
    psSubPushW :
      Begin
        X := Stk[SP];
        MkObj(PArrNew, R);
        If PIsArr(X) Then PArrPush(X.I, R) Else VmFail('[] : tableau attendu');
        Stk[SP] := R;
      End;
    psNewArr :
      Begin
        MkObj(PArrNew, X);
        Push(X);
      End;
    psAddK :
      Begin
        Y := Stk[SP]; X := Stk[SP - 1];
        SP := SP - 2;
        If PIsArr(Stk[SP]) Then PArrSet(Stk[SP].I, X, Y);
      End;
    psAddV :
      Begin
        Y := Stk[SP];
        Dec(SP);
        If PIsArr(Stk[SP]) Then PArrPush(Stk[SP].I, Y);
      End;
    psSpread :
      Begin
        Y := Stk[SP];
        Dec(SP);
        If PIsArr(Stk[SP]) And PIsArr(Y) Then
        Begin
          K := PArrNext(Y.I, 0);
          While K >= 0 Do
          Begin
            Z := DVal^[K];
            If DKey^[K].T = vtInt Then PArrPush(Stk[SP].I, Z) Else PArrSet(Stk[SP].I, DKey^[K], Z);
            K := PArrNext(Y.I, K + 1);
          End;
        End;
      End;
    psDup2 :
      Begin
        X := Stk[SP - 1]; Y := Stk[SP];
        Push(X); Push(Y);
      End;
    psDrop2 :
      Begin
        X := Stk[SP];
        SP := SP - 2;
        Stk[SP] := X;
      End;
    psIdent, psNIdent :
      Begin
        X := Stk[SP - 1]; Y := Stk[SP];
        Dec(SP);
        MkBool(PhpIdent(X, Y) = (Sub = psIdent), Stk[SP]);
      End;
    psCmp :
      Begin
        X := Stk[SP - 1]; Y := Stk[SP];
        Dec(SP);
        MkInt(PhpCompare(X, Y), Stk[SP]);
      End;
    psAdd :
      Begin
        X := Stk[SP - 1]; Y := Stk[SP];
        Dec(SP);
        If PIsArr(X) And PIsArr(Y) Then
        Begin
          { union : les cles de Y absentes de X }
          Id := PArrCopy(X.I);
          K := PArrNext(Y.I, 0);
          While K >= 0 Do
          Begin
            If DictFind(Id, DKey^[K]) < 0 Then
            Begin
              Z := DVal^[K];
              PArrSet(Id, DKey^[K], Z);
            End;
            K := PArrNext(Y.I, K + 1);
          End;
          MkObj(Id, Stk[SP]);
        End
        Else PhpArith(opAdd, X, Y, Stk[SP]);
      End;
    psBitAnd, psBitOr, psBitXor :
      Begin
        PNumCell(Stk[SP - 1], X); PNumCell(Stk[SP], Y);
        Dec(SP);
        If Sub = psBitAnd Then MkInt(CellInt(X) And CellInt(Y), Stk[SP])
        Else If Sub = psBitOr Then MkInt(CellInt(X) Or CellInt(Y), Stk[SP])
        Else MkInt(CellInt(X) Xor CellInt(Y), Stk[SP]);
      End;
    psSuper :
      Begin
        If (A < 1) Or (A > 9) Then A := 8;
        If PSupObj[A] < 0 Then PSupObj[A] := PSuperBuild(A);
        MkObj(PSupObj[A], X);
        Push(X);
      End;
    psCopy :
      If PIsArr(Stk[SP]) Then MkObj(PArrCopy(Stk[SP].I), Stk[SP]);
    psIsset :
      Begin
        X := Stk[SP - 1];
        PGetElem(X, Stk[SP], SP, R);
        Dec(SP);
        MkBool(R.T <> vtNil, Stk[SP]);
      End;
    psNotNull :
      Begin
        X := Stk[SP];
        If (X.T = vtObj) And (X.I < NObj) And (ObjK[X.I] = okItem) Then ObjValue(X);
        MkBool(X.T <> vtNil, Stk[SP]);
      End;
    psUnset :
      Begin
        X := Stk[SP - 1];
        If PIsArr(X) Then
        Begin
          K := PArrFind(X.I, Stk[SP]);
          If K >= 0 Then DObj^[K] := -1;
        End
        Else If X.T = vtObj Then
        Begin
          MkNil(Y);
          MemberCall(X, mDefault, 1, SP, R, True, Y);
        End;
        SP := SP - 2;
      End;
    psEachNext :
      Begin
        X := Stk[SP - 1];
        I := CellInt(Stk[SP]);
        Dec(SP);
        K := -1;
        If (X.T = vtObj) And (X.I < NObj) And (ObjK[X.I] = okItem) Then ObjValue(X);
        If PIsArr(X) Or ((X.T = vtObj) And (X.I < NObj) And (ObjK[X.I] In [okDict, okArr])) Then K := PArrNext(X.I, I)
        Else
        Begin
          Rs := PEachRs(X);
          If (Rs >= 0) And (I < Rss[Rs].NRow) Then K := I;
        End;
        MkInt(K, Stk[SP]);
      End;
    psEachKey, psEachVal :
      Begin
        X := Stk[SP - 1];
        I := CellInt(Stk[SP]);
        Dec(SP);
        MkNil(R);
        If (X.T = vtObj) And (X.I < NObj) And (ObjK[X.I] = okItem) Then ObjValue(X);
        If PIsArr(X) Or ((X.T = vtObj) And (X.I < NObj) And (ObjK[X.I] In [okDict, okArr])) Then
        Begin
          If (I >= 0) And (I < NDict) Then
          Begin
            If Sub = psEachKey Then R := DKey^[I] Else R := DVal^[I];
            { Scripting.Dictionary : la valeur de la cle }
          End;
        End
        Else
        Begin
          Rs := PEachRs(X);
          If Rs >= 0 Then
          Begin
            If Sub = psEachKey Then MkInt(I, R)
            Else
            Begin
              Rss[Rs].Cur := I;
              MkObj(PRowArr(Rs, 1), R);
              Rss[Rs].Cur := I + 1;
            End;
          End;
        End;
        Stk[SP] := R;
      End;
    psIncE :
      Begin
        X := Stk[SP - 1];
        PGetElem(X, Stk[SP], SP, R);
        If (R.T = vtNil) And ((A = 2) Or (A = 4)) Then Z := R
        Else
        Begin
          MkInt(1, Y);
          If (A = 1) Or (A = 3) Then PhpArith(opAdd, R, Y, Z) Else PhpArith(opSub, R, Y, Z);
        End;
        PSetElem(X, Stk[SP], Z, SP);
        Dec(SP);
        If A <= 2 Then Stk[SP] := R Else Stk[SP] := Z;
      End;
    psCast :
      Begin
        X := Stk[SP];
        Case A Of
          1 :
            Begin
              PNumCell(X, Y);
              If Y.T = vtReal Then
              Begin
                If (Y.R > 2147483647.0) Or (Y.R < -2147483648.0) Then MkInt(0, Y) Else MkInt(Trunc(Y.R), Y);
              End;
              Stk[SP] := Y;
            End;
          2 :
            Begin
              PNumCell(X, Y);
              If Y.T = vtInt Then MkReal(Y.I, Y);
              Stk[SP] := Y;
            End;
          3 : PStrCell(X, Stk[SP]);
          4 : MkBool(PBool(X), Stk[SP]);
          5 :
            If Not PIsArr(X) Then
            Begin
              Id := PArrNew;
              If X.T <> vtNil Then PArrPush(Id, X);
              MkObj(Id, Stk[SP]);
            End;
          7 : MkNil(Stk[SP]);
        End;
      End;
    psThrow :
      Begin
        PStrCell(Stk[SP], X);
        Dec(SP);
        VmFail('exception non attrap'#130'e : ' + CellPStr(X));
      End;
    psExitMsg :
      Begin
        X := Stk[SP];
        Dec(SP);
        If IsStrCell(X) Then OutCell(X, -1, -1);
      End;
  Else
    VmFail('PHP : op'#130'ration ' + IStr(Sub) + ' inconnue');
  End;
End;

{ ==================================================================== }
{ Bases de donnees : mysqli, pg_*, PDO                                  }
{ ==================================================================== }

{ chaine echappee (sans guillemets) : MariaDB \ ' " ; PostgreSQL '' }
Procedure PEscapeSql(Var C : TCell; Kind : LongInt; Var R : TCell);
Var T : TCell; P : PBytes; B : TBuf; K : LongInt;
Begin
  PStrCell(C, T);
  P := PoolPtr(T);
  BufInit(B);
  For K := 0 To T.L - 1 Do
  Begin
    If Kind = dbMy Then
    Begin
      Case P^[K] Of
        0 : BufAdd(B, '\0');
        10 : BufAdd(B, '\n');
        13 : BufAdd(B, '\r');
        26 : BufAdd(B, '\Z');
        39, 34, 92 :
          Begin
            BufAddC(B, 92); BufAddC(B, P^[K]);
          End;
      Else
        BufAddC(B, P^[K]);
      End;
    End
    Else
    Begin
      If P^[K] = 39 Then BufAddC(B, 39);
      BufAddC(B, P^[K]);
    End;
  End;
  MkStrB(B.P, B.Len, R);
  BufFree(B);
End;

{ valeur d'un parametre de requete preparee : texte SQL }
Procedure PSqlValue(Var V : TCell; Kind : LongInt; Var B : TBuf);
Var T, Q : TCell; P : PBytes;
Begin
  Case V.T Of
    vtNil : BufAdd(B, 'NULL');
    vtInt : BufAdd(B, IStr(V.I));
    vtBool : BufAdd(B, IStr(V.I));
    vtReal :
      Begin
        CellToStr(V, T);
        P := PoolPtr(T);
        BufAddB(B, P, T.L);
      End;
  Else
    Begin
      SqlQuote(V, Q, Kind);
      P := PoolPtr(Q);
      BufAddB(B, P, Q.L);
    End;
  End;
End;

{ requete de PDO : ? et :nom remplaces par les valeurs (tableau Params) }
Procedure PBindSql(Var Sql : TCell; Params, Kind : LongInt; Var Out_ : TBuf);
Var T, V, Kc : TCell; P : PBytes; K, N, Q, J, Np : LongInt; Nm : String;
Begin
  PStrCell(Sql, T);
  N := 0; Q := 0;
  K := 0;
  While K < T.L Do
  Begin
    P := PoolPtr(T);
    If (Q = 0) And ((P^[K] = 39) Or (P^[K] = 34)) Then Q := P^[K]
    Else If (Q <> 0) And (P^[K] = Q) Then Q := 0;
    If (Q = 0) And (P^[K] = 63) Then
    Begin
      MkNil(V);
      If Params >= 0 Then
      Begin
        J := PArrNth(Params, N);
        If J >= 0 Then V := DVal^[J];
      End;
      PSqlValue(V, Kind, Out_);
      Inc(N);
      Inc(K);
      Continue;
    End;
    If (Q = 0) And (P^[K] = 36) And (K + 1 < T.L) And (P^[K + 1] >= 49) And (P^[K + 1] <= 57) Then
    Begin
      { $1, $2... de PostgreSQL (pg_query_params) }
      J := K + 1; Np := 0;
      While (J < T.L) And (P^[J] >= 48) And (P^[J] <= 57) Do
      Begin
        Np := Np * 10 + P^[J] - 48;
        Inc(J);
      End;
      MkNil(V);
      If Params >= 0 Then
      Begin
        Np := PArrNth(Params, Np - 1);
        If Np >= 0 Then V := DVal^[Np];
      End;
      PSqlValue(V, Kind, Out_);
      K := J;
      Continue;
    End;
    If (Q = 0) And (P^[K] = 58) And (K + 1 < T.L) And (P^[K + 1] <> 58) And
       (((P^[K + 1] Or 32) >= 97) And ((P^[K + 1] Or 32) <= 122) Or (P^[K + 1] = 95)) And
       Not ((K > 0) And (P^[K - 1] = 58)) Then
    Begin
      Nm := '';
      J := K + 1;
      While (J < T.L) And (((P^[J] Or 32) >= 97) And ((P^[J] Or 32) <= 122) Or (P^[J] = 95) Or
            ((P^[J] >= 48) And (P^[J] <= 57))) Do
      Begin
        Nm := Nm + Chr(P^[J]);
        Inc(J);
      End;
      MkNil(V);
      If Params >= 0 Then
      Begin
        MkStr(Nm, Kc);
        PArrGet(Params, Kc, V);
        If V.T = vtNil Then
        Begin
          MkStr(':' + Nm, Kc);
          PArrGet(Params, Kc, V);
        End;
      End;
      PSqlValue(V, Kind, Out_);
      K := J;
      Continue;
    End;
    BufAddC(Out_, P^[K]);
    Inc(K);
  End;
End;

Function PConnKind(ConnObj : LongInt) : LongInt;
Begin
  PConnKind := 0;
  If (ConnObj >= 0) And (ConnObj < NObj) And (ObjK[ConnObj] = okDbConn) And (ObjA[ConnObj] >= 0) Then
    PConnKind := DbC[ObjA[ConnObj]].Kind;
End;

{ membres de PHP des objets ; False : membre laisse aux objets d'ASP/PSP }
Function PhpMember(Var Ob : TCell; M, Argc, ABase : LongInt; Var R : TCell; IsSet : Boolean; Var V : TCell) : Boolean;
Var Id, K, Rs, Mode, I, C : LongInt; A0, A1, T, Kc : TCell; B : TBuf; S : String;
Begin
  PhpMember := True;
  If Argc > 0 Then A0 := Stk[ABase] Else MkNil(A0);
  If Argc > 1 Then A1 := Stk[ABase + 1] Else MkNil(A1);
  Id := Ob.I;
  MkNil(R);
  Case ObjK[Id] Of
    okPArr :
      Case M Of
        mCount : MkInt(DictCount(Id), R);
        mDefault, mItem :
          If IsSet Then PArrSet(Id, A0, V) Else PArrGet(Id, A0, R);
      Else
        VmFail('tableau : ->' + MemberNames[M] + ' impossible (classes non prises en charge)');
      End;
    okDbConn :
      Begin
        K := ObjA[Id];
        Case M Of
          mQuery, mExec :
            If K < 0 Then VmFail('base de donn'#130'es : connexion non ouverte')
            Else
            Begin
              DbRun(K, A0, M = mExec, R);
              If (R.T = vtObj) And (R.I < NObj) And (ObjK[R.I] = okDbRs) Then
              Begin
                Rs := ObjA[R.I];
                ObjB[Id] := Rss[Rs].Affected;
                If Rss[Rs].NCol = 0 Then
                Begin
                  { INSERT, UPDATE... : vrai (mysqli), jeu vide (PDO) }
                  If Rss[Rs].NRow = 0 Then Rss[Rs].NRow := 0;
                End;
              End
              Else If R.T = vtInt Then ObjB[Id] := R.I;
            End;
          mQueryParams :
            If K < 0 Then VmFail('base de donn'#130'es : connexion non ouverte')
            Else
            Begin
              { pg_query_params($c, 'SELECT ... $1', [valeurs]) }
              If PIsArr(A1) Then I := A1.I Else I := -1;
              BufInit(B);
              PBindSql(A0, I, DbC[K].Kind, B);
              MkStrB(B.P, B.Len, T);
              BufFree(B);
              DbRun(K, T, False, R);
              If (R.T = vtObj) And (R.I < NObj) And (ObjK[R.I] = okDbRs) Then ObjB[Id] := Rss[ObjA[R.I]].Affected;
            End;
          mPrepare :
            Begin
              I := ObjNew(okDbStmt, Id, -1);
              PStrCell(A0, ObjS[I]);
              MkObj(I, R);
            End;
          mRealEscape, mQuote :
            Begin
              If K >= 0 Then C := DbC[K].Kind Else C := dbMy;
              PEscapeSql(A0, C, R);
              If M = mQuote Then
              Begin
                T := R;
                MkStr('''', Kc);
                Concat2(Kc, T, R);
                T := R;
                Concat2(T, Kc, R);
              End;
            End;
          mAffectedRows : MkInt(ObjB[Id], R);
          mInsertId, mLastInsertId : If K >= 0 Then MkInt(DbC[K].InsId, R) Else MkInt(0, R);
          mSetCharset, mSetAttribute : MkBool(True, R);
          mError, mConnectError : MkStr('', R);
          mErrno : MkInt(0, R);
          mBeginTrans, mCommit, mRollBack :
            If K >= 0 Then
            Begin
              If M = mBeginTrans Then MkStr('BEGIN', T) Else If M = mCommit Then MkStr('COMMIT', T)
              Else MkStr('ROLLBACK', T);
              DbRun(K, T, True, R);
              If Not VmWait Then MkBool(True, R);
            End;
        Else
          PhpMember := False;
        End;
      End;
    okDbStmt :
      Begin
        Case M Of
          mExecute :
            Begin
              C := ObjA[Id];
              If (C < 0) Or (ObjK[C] <> okDbConn) Or (ObjA[C] < 0) Then
              Begin
                VmFail('PDO : connexion ferm'#130'e');
                Exit;
              End;
              If PIsArr(A0) Then I := A0.I Else I := ObjH[Id];
              BufInit(B);
              PBindSql(ObjS[Id], I, DbC[ObjA[C]].Kind, B);
              MkStrB(B.P, B.Len, T);
              BufFree(B);
              DbRun(ObjA[C], T, False, R);
              If (R.T = vtObj) And (R.I < NObj) And (ObjK[R.I] = okDbRs) Then
              Begin
                If (ObjB[Id] >= 0) And (ObjB[Id] <> ObjA[R.I]) Then RsFree(ObjB[Id]);
                ObjB[Id] := ObjA[R.I];
                ObjB[C] := Rss[ObjB[Id]].Affected;
                MkBool(True, R);
              End;
            End;
          mBindValue, mBindParam :
            Begin
              If ObjH[Id] < 0 Then ObjH[Id] := PArrNew;
              If A0.T = vtInt Then
              Begin
                MkInt(A0.I - 1, Kc);
                PArrSet(ObjH[Id], Kc, A1);
              End
              Else
              Begin
                PStrCell(A0, T);
                S := CellPStr(T);
                If (S <> '') And (S[1] = ':') Then Delete(S, 1, 1);
                MkStr(S, Kc);
                PArrSet(ObjH[Id], Kc, A1);
              End;
              MkBool(True, R);
            End;
          mBindParamM :
            Begin
              { mysqli : bind_param('is', $a, $b) ; les valeurs sont prises a l'appel }
              If ObjH[Id] < 0 Then ObjH[Id] := PArrNew;
              For I := 1 To Argc - 1 Do
              Begin
                MkInt(I - 1, Kc);
                PArrSet(ObjH[Id], Kc, Stk[ABase + I]);
              End;
              MkBool(True, R);
            End;
          mGetResult :
            Begin
              Rs := ObjB[Id];
              If (Rs < 0) Or (Rs >= MaxRs) Or Not Rss[Rs].Used Then MkBool(False, R)
              Else
              Begin
                MkObj(ObjNew(okDbRs, Rs, 0), R);
                ObjB[Id] := -1;               { le jeu appartient maintenant au resultat }
              End;
            End;
          mCloseCursor, mClose, mFree :
            Begin
              If ObjB[Id] >= 0 Then RsFree(ObjB[Id]);
              ObjB[Id] := -1;
              MkBool(True, R);
            End;
        Else
          Begin
            { fetch, fetchAll, rowCount... : le jeu de la derniere execution }
            Rs := ObjB[Id];
            If (Rs < 0) Or (Rs >= MaxRs) Or Not Rss[Rs].Used Then
            Begin
              If (M = mFetch) Or (M = mFetchColumn) Then MkBool(False, R)
              Else If (M = mRowCount) Then MkInt(0, R)
              Else If (M = mFetchAllP) Then MkObj(PArrNew, R)
              Else VmFail('PDOStatement : execute() d''abord');
              Exit;
            End;
            I := ObjNew(okDbRs, Rs, 0);
            MkObj(I, T);
            PhpMember := PhpMember(T, M, Argc, ABase, R, IsSet, V);
            ObjA[I] := -1;
          End;
        End;
      End;
    okDbRs :
      Begin
        Rs := ObjA[Id];
        If (Rs < 0) Or (Rs >= MaxRs) Or Not Rss[Rs].Used Then
        Begin
          If (M = mFree) Or (M = mClose) Or (M = mCloseCursor) Then Exit;
          If (M = mFetchAssoc) Or (M = mFetchRow) Or (M = mFetchArray) Or (M = mFetchObject) Then Exit;
          PhpMember := False;
          Exit;
        End;
        Case M Of
          mFetchAssoc, mFetchObject, mFetchRow, mFetchArray, mFetch :
            Begin
              If Rss[Rs].Cur >= Rss[Rs].NRow Then
              Begin
                If M = mFetch Then MkBool(False, R);
                Exit;
              End;
              Mode := 1;
              If M = mFetchRow Then Mode := 2
              Else If M = mFetchArray Then
              Begin
                Mode := 3;
                If Argc > 0 Then Mode := CellInt(A0);
              End
              Else If (M = mFetch) And (Argc > 0) Then
              Begin
                Case CellInt(A0) Of
                  3 : Mode := 2;
                  4 : Mode := 3;
                  7 : Mode := 7;
                Else
                  Mode := 1;
                End;
              End;
              If Mode = 7 Then RsValue(Rs, 0, R)
              Else MkObj(PRowArr(Rs, Mode), R);
              Inc(Rss[Rs].Cur);
            End;
          mFetchColumn :
            Begin
              If Rss[Rs].Cur >= Rss[Rs].NRow Then
              Begin
                MkBool(False, R);
                Exit;
              End;
              RsValue(Rs, CellInt(A0), T);
              If T.T <> vtNil Then PStrCell(T, R);
              Inc(Rss[Rs].Cur);
            End;
          mFetchAllM, mFetchAllP :
            Begin
              Mode := 1;
              If Argc > 0 Then
              Begin
                I := CellInt(A0);
                If M = mFetchAllM Then
                Begin
                  If I = 2 Then Mode := 2 Else If I = 3 Then Mode := 3;
                End
                Else If I = 3 Then Mode := 2 Else If I = 4 Then Mode := 3 Else If I = 7 Then Mode := 7;
              End;
              I := PArrNew;
              While Rss[Rs].Cur < Rss[Rs].NRow Do
              Begin
                If Mode = 7 Then
                Begin
                  RsValue(Rs, 0, T);
                  If T.T <> vtNil Then PStrCell(T, Kc) Else Kc := T;
                  PArrPush(I, Kc);
                End
                Else
                Begin
                  MkObj(PRowArr(Rs, Mode), T);
                  PArrPush(I, T);
                End;
                Inc(Rss[Rs].Cur);
              End;
              MkObj(I, R);
            End;
          mRowCount, mNumRows :
            If (Rss[Rs].NCol = 0) Or (M = mRowCount) And (Rss[Rs].NRow = 0) Then MkInt(Rss[Rs].Affected, R)
            Else MkInt(Rss[Rs].NRow, R);
          mAffectedRows : MkInt(Rss[Rs].Affected, R);
          mFieldCountP : MkInt(Rss[Rs].NCol, R);
          mFieldNameP :
            Begin
              C := CellInt(A0);
              If (C >= 0) And (C < Rss[Rs].NCol) Then MkStr(Rss[Rs].ColNm[C], R) Else MkBool(False, R);
            End;
          mDataSeek :
            Begin
              Rss[Rs].Cur := CellInt(A0);
              MkBool(True, R);
            End;
          mFetchResult :
            Begin
              { pg_fetch_result(res, ligne, colonne) }
              I := Rss[Rs].Cur;
              If Argc >= 2 Then
              Begin
                Rss[Rs].Cur := CellInt(A0);
                C := RsCol(Rs, A1);
              End
              Else C := RsCol(Rs, A0);
              If C >= 0 Then
              Begin
                RsValue(Rs, C, T);
                If T.T <> vtNil Then PStrCell(T, R);
              End;
              Rss[Rs].Cur := I;
            End;
          mFree, mCloseCursor :
            Begin
              RsFree(Rs);
              ObjA[Id] := -1;
              MkBool(True, R);
            End;
        Else
          PhpMember := False;
        End;
      End;
  Else
    PhpMember := False;
  End;
End;

{ ==================================================================== }
{ Bibliotheque de fonctions de PHP                                      }
{ ==================================================================== }

Var
  PFhH, PFhMode, PFhPos : Array[0..15] Of LongInt;     { fopen }
  PFhBuf : Array[0..15] Of TBuf;
  PFhUsed : Array[0..15] Of Boolean;
  PMd5Out : TBlk;
  PShaOut : TB20;

{ hasard dans [0, 1[ (en double precision) }
Function PRnd : Double;
Var D : Double;
Begin
  D := VmRand;
  PRnd := D / 2147483648.0;
End;

Function PDiff(A, B : LongInt) : Double;
Var D : Double;
Begin
  D := A;
  PDiff := D - B;
End;

Procedure PRet(Var B : TBuf; Var R : TCell);
Begin
  MkStrB(B.P, B.Len, R);
  BufFree(B);
End;

Function PInt(Var C : TCell) : LongInt;
Var T : TCell;
Begin
  PNumCell(C, T);
  If T.T = vtReal Then
  Begin
    If (T.R > 2147483647.0) Or (T.R < -2147483648.0) Then PInt := 0 Else PInt := Trunc(T.R);
  End
  Else PInt := T.I;
End;

Function PReal(Var C : TCell) : Double;
Var T : TCell;
Begin
  PNumCell(C, T);
  If T.T = vtReal Then PReal := T.R Else PReal := T.I;
End;

Function PLow(C : Byte) : Byte;
Begin
  If (C >= 65) And (C <= 90) Then PLow := C + 32 Else PLow := C;
End;

Function PUp(C : Byte) : Byte;
Begin
  If (C >= 97) And (C <= 122) Then PUp := C - 32 Else PUp := C;
End;

{ position de N dans H a partir de From (-1 : absent) }
Function PFind(H : PBytes; HN : LongInt; N : PBytes; NN, From : LongInt; NoCase : Boolean) : LongInt;
Var K, J : LongInt;
Begin
  PFind := -1;
  If NN = 0 Then
  Begin
    If From <= HN Then PFind := From;
    Exit;
  End;
  For K := From To HN - NN Do
  Begin
    J := 0;
    If NoCase Then
      While (J < NN) And (PLow(H^[K + J]) = PLow(N^[J])) Do Inc(J)
    Else
      While (J < NN) And (H^[K + J] = N^[J]) Do Inc(J);
    If J = NN Then
    Begin
      PFind := K;
      Exit;
    End;
  End;
End;

Function PFindRev(H : PBytes; HN : LongInt; N : PBytes; NN : LongInt; NoCase : Boolean) : LongInt;
Var K, J : LongInt;
Begin
  PFindRev := -1;
  For K := HN - NN DownTo 0 Do
  Begin
    J := 0;
    If NoCase Then
      While (J < NN) And (PLow(H^[K + J]) = PLow(N^[J])) Do Inc(J)
    Else
      While (J < NN) And (H^[K + J] = N^[J]) Do Inc(J);
    If J = NN Then
    Begin
      PFindRev := K;
      Exit;
    End;
  End;
End;

Function PSp(N : LongInt) : String;
Var S : String;
Begin
  S := '';
  While Length(S) < N Do S := S + ' ';
  PSp := S;
End;

{ texte d'une cle (print_r, json...) }
Procedure PAddCell(Var B : TBuf; Var C : TCell);
Var T : TCell;
Begin
  PStrCell(C, T);
  If T.L > 0 Then BufAddB(B, PoolPtr(T), T.L);
End;

Procedure PPrintR(Var V : TCell; Ind : LongInt; Var B : TBuf);
Var K : LongInt; X : TCell;
Begin
  If PIsArr(V) Then
  Begin
    BufAdd(B, 'Array' + #10 + PSp(Ind) + '(' + #10);
    K := PArrNext(V.I, 0);
    While K >= 0 Do
    Begin
      BufAdd(B, PSp(Ind + 4) + '[');
      PAddCell(B, DKey^[K]);
      BufAdd(B, '] => ');
      X := DVal^[K];
      PPrintR(X, Ind + 8, B);
      BufAdd(B, #10);
      K := PArrNext(V.I, K + 1);
    End;
    BufAdd(B, PSp(Ind) + ')' + #10);
  End
  Else PAddCell(B, V);
End;

Procedure PVarDump(Var V : TCell; Ind : LongInt; Var B : TBuf);
Var K : LongInt; X, T : TCell;
Begin
  BufAdd(B, PSp(Ind));
  X := V;
  If (X.T = vtObj) And Not PIsArr(X) Then ObjValue(X);
  If PIsArr(X) Then
  Begin
    BufAdd(B, 'array(' + IStr(DictCount(X.I)) + ') {' + #10);
    K := PArrNext(X.I, 0);
    While K >= 0 Do
    Begin
      BufAdd(B, PSp(Ind + 2) + '[');
      If DKey^[K].T = vtInt Then BufAdd(B, IStr(DKey^[K].I))
      Else
      Begin
        BufAdd(B, '"');
        PAddCell(B, DKey^[K]);
        BufAdd(B, '"');
      End;
      BufAdd(B, ']=>' + #10);
      T := DVal^[K];
      PVarDump(T, Ind + 2, B);
      K := PArrNext(X.I, K + 1);
    End;
    BufAdd(B, PSp(Ind) + '}' + #10);
    Exit;
  End;
  Case X.T Of
    vtNil : BufAdd(B, 'NULL');
    vtInt : BufAdd(B, 'int(' + IStr(X.I) + ')');
    vtReal, vtDate : BufAdd(B, 'float(' + PhpRealStr(X.R) + ')');
    vtBool : If X.I <> 0 Then BufAdd(B, 'bool(true)') Else BufAdd(B, 'bool(false)');
    vtObj : BufAdd(B, 'object(' + IStr(X.I) + ')');
  Else
    Begin
      PStrCell(X, T);
      BufAdd(B, 'string(' + IStr(T.L) + ') "');
      PAddCell(B, T);
      BufAdd(B, '"');
    End;
  End;
  BufAdd(B, #10);
End;

Procedure PVarExport(Var V : TCell; Ind : LongInt; Var B : TBuf);
Var K, J : LongInt; X, T : TCell; P : PBytes;
Begin
  X := V;
  If PIsArr(X) Then
  Begin
    BufAdd(B, 'array (' + #10);
    K := PArrNext(X.I, 0);
    While K >= 0 Do
    Begin
      BufAdd(B, PSp(Ind + 2));
      T := DKey^[K];
      PVarExport(T, Ind + 2, B);
      BufAdd(B, ' => ');
      T := DVal^[K];
      If PIsArr(T) Then BufAdd(B, #10 + PSp(Ind + 2));
      PVarExport(T, Ind + 2, B);
      BufAdd(B, ',' + #10);
      K := PArrNext(X.I, K + 1);
    End;
    BufAdd(B, PSp(Ind) + ')');
    Exit;
  End;
  Case X.T Of
    vtNil : BufAdd(B, 'NULL');
    vtInt : BufAdd(B, IStr(X.I));
    vtReal :
      Begin
        BufAdd(B, PhpRealStr(X.R));
        If (X.R = Int(X.R)) And (Abs(X.R) < 1E15) Then BufAdd(B, '.0');
      End;
    vtBool : If X.I <> 0 Then BufAdd(B, 'true') Else BufAdd(B, 'false');
  Else
    Begin
      PStrCell(X, T);
      BufAddC(B, 39);
      P := PoolPtr(T);
      For J := 0 To T.L - 1 Do
      Begin
        If (P^[J] = 39) Or (P^[J] = 92) Then BufAddC(B, 92);
        BufAddC(B, P^[J]);
      End;
      BufAddC(B, 39);
    End;
  End;
End;

{ --- JSON --- }

Function PIsList(Id : LongInt) : Boolean;
Var K, N : LongInt;
Begin
  PIsList := True;
  N := 0;
  K := PArrNext(Id, 0);
  While K >= 0 Do
  Begin
    If (DKey^[K].T <> vtInt) Or (DKey^[K].I <> N) Then
    Begin
      PIsList := False;
      Exit;
    End;
    Inc(N);
    K := PArrNext(Id, K + 1);
  End;
End;

Procedure PJsonStr(P : PBytes; N, Flags : LongInt; Var B : TBuf);
Var K, U, L : LongInt; C : Byte;
Begin
  BufAddC(B, 34);
  K := 0;
  While K < N Do
  Begin
    C := P^[K];
    Case C Of
      34 : BufAdd(B, '\"');
      92 : BufAdd(B, '\\');
      47 : If (Flags And 64) <> 0 Then BufAddC(B, 47) Else BufAdd(B, '\/');
      8 : BufAdd(B, '\b');
      12 : BufAdd(B, '\f');
      10 : BufAdd(B, '\n');
      13 : BufAdd(B, '\r');
      9 : BufAdd(B, '\t');
    Else
      If C < 32 Then BufAdd(B, '\u' + LoStr(Hex(C, 4)))
      Else If (C < 128) Or ((Flags And 256) <> 0) Then BufAddC(B, C)
      Else
      Begin
        { UTF-8 -> \uXXXX }
        If (C And $E0) = $C0 Then
        Begin
          U := C And $1F; L := 1;
        End
        Else If (C And $F0) = $E0 Then
        Begin
          U := C And $0F; L := 2;
        End
        Else If (C And $F8) = $F0 Then
        Begin
          U := C And $07; L := 3;
        End
        Else
        Begin
          U := C; L := 0;
        End;
        While (L > 0) And (K + 1 < N) Do
        Begin
          Inc(K);
          U := (U Shl 6) Or (P^[K] And $3F);
          Dec(L);
        End;
        If U >= $10000 Then
        Begin
          U := U - $10000;
          BufAdd(B, '\u' + LoStr(Hex($D800 + (U Shr 10), 4)) + '\u' + LoStr(Hex($DC00 + (U And $3FF), 4)));
        End
        Else BufAdd(B, '\u' + LoStr(Hex(U, 4)));
      End;
    End;
    Inc(K);
  End;
  BufAddC(B, 34);
End;

Procedure PJsonEnc(Var V : TCell; Flags, Ind : LongInt; Var B : TBuf);
Var K, N : LongInt; X, T : TCell; List, Pretty : Boolean;
Begin
  X := V;
  If (X.T = vtObj) And Not PIsArr(X) Then ObjValue(X);
  Pretty := (Flags And 128) <> 0;
  If PIsArr(X) Then
  Begin
    List := PIsList(X.I);
    If List Then BufAddC(B, 91) Else BufAddC(B, 123);
    N := 0;
    K := PArrNext(X.I, 0);
    While K >= 0 Do
    Begin
      If N > 0 Then BufAddC(B, 44);
      If Pretty Then BufAdd(B, #10 + PSp(Ind + 4));
      If Not List Then
      Begin
        PStrCell(DKey^[K], T);
        PJsonStr(PoolPtr(T), T.L, Flags, B);
        BufAddC(B, 58);
        If Pretty Then BufAddC(B, 32);
      End;
      T := DVal^[K];
      PJsonEnc(T, Flags, Ind + 4, B);
      Inc(N);
      K := PArrNext(X.I, K + 1);
    End;
    If Pretty And (N > 0) Then BufAdd(B, #10 + PSp(Ind));
    If List Then BufAddC(B, 93) Else BufAddC(B, 125);
    Exit;
  End;
  Case X.T Of
    vtNil : BufAdd(B, 'null');
    vtInt : BufAdd(B, IStr(X.I));
    vtBool : If X.I <> 0 Then BufAdd(B, 'true') Else BufAdd(B, 'false');
    vtReal :
      Begin
        BufAdd(B, PhpRealStr(X.R));
        If (X.R = Int(X.R)) And (Abs(X.R) < 1E15) Then BufAdd(B, '.0');
      End;
  Else
    Begin
      PStrCell(X, T);
      PJsonStr(PoolPtr(T), T.L, Flags, B);
    End;
  End;
End;

{ decodage JSON (objets -> tableaux associatifs) }
Var
  JP : PBytes;
  JN, JK : LongInt;
  JErr : Boolean;

Procedure JWs;
Begin
  While (JK < JN) And (JP^[JK] In [32, 9, 10, 13]) Do Inc(JK);
End;

Procedure JValue(Var R : TCell);
Var B : TBuf; U, K : LongInt; S : String; Id : LongInt; Kc, V : TCell; D : Double; E : LongInt; Rl : Boolean;
Begin
  MkNil(R);
  JWs;
  If JK >= JN Then
  Begin
    JErr := True;
    Exit;
  End;
  Case JP^[JK] Of
    123, 91 :
      Begin
        Id := PArrNew;
        MkObj(Id, R);
        If JP^[JK] = 91 Then
        Begin
          Inc(JK);
          JWs;
          If (JK < JN) And (JP^[JK] = 93) Then
          Begin
            Inc(JK);
            Exit;
          End;
          Repeat
            JValue(V);
            If JErr Then Exit;
            PArrPush(Id, V);
            JWs;
            If (JK < JN) And (JP^[JK] = 44) Then Inc(JK) Else Break;
          Until False;
          If (JK < JN) And (JP^[JK] = 93) Then Inc(JK) Else JErr := True;
        End
        Else
        Begin
          Inc(JK);
          JWs;
          If (JK < JN) And (JP^[JK] = 125) Then
          Begin
            Inc(JK);
            Exit;
          End;
          Repeat
            JValue(Kc);
            If JErr Or Not IsStrCell(Kc) Then
            Begin
              JErr := True;
              Exit;
            End;
            JWs;
            If (JK < JN) And (JP^[JK] = 58) Then Inc(JK) Else
            Begin
              JErr := True;
              Exit;
            End;
            JValue(V);
            If JErr Then Exit;
            PArrSet(Id, Kc, V);
            JWs;
            If (JK < JN) And (JP^[JK] = 44) Then Inc(JK) Else Break;
          Until False;
          If (JK < JN) And (JP^[JK] = 125) Then Inc(JK) Else JErr := True;
        End;
      End;
    34 :
      Begin
        BufInit(B);
        Inc(JK);
        While (JK < JN) And (JP^[JK] <> 34) Do
        Begin
          If (JP^[JK] = 92) And (JK + 1 < JN) Then
          Begin
            Inc(JK);
            Case JP^[JK] Of
              110 : BufAddC(B, 10);
              116 : BufAddC(B, 9);
              114 : BufAddC(B, 13);
              98 : BufAddC(B, 8);
              102 : BufAddC(B, 12);
              117 :
                Begin
                  U := 0;
                  For K := 1 To 4 Do
                    If JK + 1 < JN Then
                    Begin
                      Inc(JK);
                      U := U * 16 + HexV(Chr(JP^[JK]));
                    End;
                  AddUtf8(B, U);
                End;
            Else
              BufAddC(B, JP^[JK]);
            End;
          End
          Else BufAddC(B, JP^[JK]);
          Inc(JK);
        End;
        Inc(JK);
        PRet(B, R);
      End;
    116 :
      Begin
        MkBool(True, R);
        JK := JK + 4;
      End;
    102 :
      Begin
        MkBool(False, R);
        JK := JK + 5;
      End;
    110 : JK := JK + 4;
  Else
    Begin
      S := '';
      While (JK < JN) And (JP^[JK] In [43, 45, 46, 48..57, 69, 101]) Do
      Begin
        S := S + Chr(JP^[JK]);
        Inc(JK);
      End;
      If S = '' Then
      Begin
        JErr := True;
        Exit;
      End;
      If PParseNum(@S[1], Length(S), Rl, E, D) Then
      Begin
        If Rl Then MkReal(D, R) Else MkInt(E, R);
      End
      Else JErr := True;
    End;
  End;
End;

{ --- tri --- }
Var
  SortFlags : LongInt;
  SortByKey, SortRev : Boolean;

Function SortCmp(A, B : LongInt) : LongInt;
Var X, Y, Sx, Sy : TCell; R : LongInt;
Begin
  If SortByKey Then
  Begin
    X := DKey^[A]; Y := DKey^[B];
  End
  Else
  Begin
    X := DVal^[A]; Y := DVal^[B];
  End;
  If (SortFlags And 2) <> 0 Then
  Begin
    PStrCell(X, Sx); PStrCell(Y, Sy);
    R := StrCmpCells(Sx, Sy, (SortFlags And 8) <> 0);
  End
  Else R := PhpCompare(X, Y);
  If SortRev Then R := -R;
  SortCmp := R;
End;

{ trier les entrees du tableau (tri par fusion, stable) ; Renum : cles 0.. }
Procedure PSortArr(Id : LongInt; ByKey, Rev, Renum : Boolean; Flags : LongInt);
Var Idx, Tmp : PLongs; N, K, W, L, M, H, I, J, O : LongInt; KCopy, VCopy : PCells;
Begin
  N := DictCount(Id);
  If N < 2 Then
  Begin
    If Renum Then PArrRenumber(Id);
    Exit;
  End;
  SortByKey := ByKey; SortRev := Rev; SortFlags := Flags;
  GetMem(Idx, N * 4); GetMem(Tmp, N * 4);
  N := 0;
  K := PArrNext(Id, 0);
  While K >= 0 Do
  Begin
    Idx^[N] := K;
    Inc(N);
    K := PArrNext(Id, K + 1);
  End;
  W := 1;
  While W < N Do
  Begin
    L := 0;
    While L < N Do
    Begin
      M := L + W; If M > N Then M := N;
      H := L + 2 * W; If H > N Then H := N;
      I := L; J := M; O := L;
      While (I < M) And (J < H) Do
      Begin
        If SortCmp(Idx^[J], Idx^[I]) < 0 Then
        Begin
          Tmp^[O] := Idx^[J]; Inc(J);
        End
        Else
        Begin
          Tmp^[O] := Idx^[I]; Inc(I);
        End;
        Inc(O);
      End;
      While I < M Do
      Begin
        Tmp^[O] := Idx^[I]; Inc(I); Inc(O);
      End;
      While J < H Do
      Begin
        Tmp^[O] := Idx^[J]; Inc(J); Inc(O);
      End;
      L := L + 2 * W;
    End;
    For I := 0 To N - 1 Do Idx^[I] := Tmp^[I];
    W := W * 2;
  End;
  { recopier dans l'ordre trie, dans les memes entrees }
  GetMem(KCopy, N * SizeOf(TCell)); GetMem(VCopy, N * SizeOf(TCell));
  For I := 0 To N - 1 Do
  Begin
    KCopy^[I] := DKey^[Idx^[I]]; VCopy^[I] := DVal^[Idx^[I]];
  End;
  I := 0;
  K := PArrNext(Id, 0);
  While (K >= 0) And (I < N) Do
  Begin
    DKey^[K] := KCopy^[I]; DVal^[K] := VCopy^[I];
    Inc(I);
    K := PArrNext(Id, K + 1);
  End;
  FreeMem(KCopy, N * SizeOf(TCell)); FreeMem(VCopy, N * SizeOf(TCell));
  FreeMem(Idx, N * 4); FreeMem(Tmp, N * 4);
  If Renum Then
  Begin
    K := PArrNext(Id, 0);
    I := 0;
    While K >= 0 Do
    Begin
      MkInt(I, DKey^[K]);
      Inc(I);
      K := PArrNext(Id, K + 1);
    End;
    ObjA[Id] := I;
  End;
End;

{ nombre en base 2..36 (negatif : sur 32 bits, comme un entier non signe) }
Function PBaseStr(D : Double; Base : LongInt; Upper : Boolean) : String;
Var S : String; J : LongInt;
Begin
  D := Int(D);
  If D < 0 Then D := D + 4294967296.0;
  If D = 0 Then
  Begin
    PBaseStr := '0';
    Exit;
  End;
  S := '';
  While D >= 1 Do
  Begin
    J := Trunc(D - Int(D / Base) * Base);
    D := Int(D / Base);
    If J < 10 Then S := Chr(48 + J) + S
    Else If Upper Then S := Chr(55 + J) + S
    Else S := Chr(87 + J) + S;
  End;
  PBaseStr := S;
End;

{ --- sprintf --- }
Procedure PSprintf(Var Arg : Array Of TCell; Argc, First : LongInt; Var B : TBuf);
Var F, T, X : TCell; P : PBytes; K, N, An, W, Pr, J, V, Base : LongInt; Left, Plus, Zero : Boolean; PadC : Byte;
    Cv : Char; S, Ds : String; D : Double; Neg : Boolean;
Begin
  PStrCell(Arg[First], F);
  An := First + 1;
  K := 0;
  While K < F.L Do
  Begin
    P := PoolPtr(F);
    If P^[K] <> 37 Then
    Begin
      BufAddC(B, P^[K]);
      Inc(K);
      Continue;
    End;
    Inc(K);
    If (K < F.L) And (P^[K] = 37) Then
    Begin
      BufAddC(B, 37);
      Inc(K);
      Continue;
    End;
    { numero d'argument n$ }
    J := K; V := 0;
    While (J < F.L) And (P^[J] >= 48) And (P^[J] <= 57) Do
    Begin
      V := V * 10 + P^[J] - 48;
      Inc(J);
    End;
    If (J < F.L) And (P^[J] = 36) And (V > 0) Then
    Begin
      An := First + V;
      K := J + 1;
    End;
    Left := False; Plus := False; Zero := False; PadC := 32;
    While (K < F.L) And (P^[K] In [45, 43, 48, 32, 39]) Do
    Begin
      Case P^[K] Of
        45 : Left := True;
        43 : Plus := True;
        48 : PadC := 48;
        32 : PadC := 32;
        39 :
          Begin
            Inc(K);
            If K < F.L Then PadC := P^[K];
          End;
      End;
      Inc(K);
    End;
    W := 0;
    While (K < F.L) And (P^[K] >= 48) And (P^[K] <= 57) Do
    Begin
      W := W * 10 + P^[K] - 48;
      Inc(K);
    End;
    Pr := -1;
    If (K < F.L) And (P^[K] = 46) Then
    Begin
      Inc(K);
      Pr := 0;
      While (K < F.L) And (P^[K] >= 48) And (P^[K] <= 57) Do
      Begin
        Pr := Pr * 10 + P^[K] - 48;
        Inc(K);
      End;
    End;
    If K >= F.L Then Break;
    Cv := Chr(P^[K]);
    Inc(K);
    If An < Argc Then X := Arg[An] Else MkNil(X);
    Inc(An);
    S := '';
    Case Cv Of
      'd', 'i', 'u' :
        Begin
          D := PReal(X);
          If Abs(D) < 2147483648.0 Then S := IStr(Trunc(D)) Else Str(Int(D):0:0, S);
          If Plus And (D >= 0) Then S := '+' + S;
        End;
      'f', 'F', 'e', 'E', 'g', 'G' :
        Begin
          D := PReal(X);
          If Pr < 0 Then Pr := 6;
          If (Cv = 'e') Or (Cv = 'E') Then
          Begin
            Str(D:Pr + 8, S);
            S := Trim(S);
            { 1.234560E+002 -> 1.234560e+2 }
            J := Pos('E', S);
            If J > 0 Then
            Begin
              Ds := Copy(S, J + 2, 10);
              While (Length(Ds) > 1) And (Ds[1] = '0') Do Delete(Ds, 1, 1);
              S := Copy(S, 1, J - 1) + Cv + S[J + 1] + Ds;
            End;
          End
          Else If (Cv = 'g') Or (Cv = 'G') Then S := PhpRealStr(D)
          Else Str(D:0:Pr, S);
          If Plus And (D >= 0) Then S := '+' + S;
        End;
      'x', 'X', 'o', 'b' :
        Begin
          If Cv = 'o' Then Base := 8 Else If Cv = 'b' Then Base := 2 Else Base := 16;
          S := PBaseStr(PReal(X), Base, Cv = 'X');
        End;
      'c' : S := Chr(PInt(X) And 255);
      's' :
        Begin
          PStrCell(X, T);
          If (T.L > 255) And (W <= T.L) And ((Pr < 0) Or (Pr >= T.L)) Then
          Begin
            BufAddB(B, PoolPtr(T), T.L);
            Continue;
          End;
          S := CellPStr(T);
          If (Pr >= 0) And (Pr < Length(S)) Then S := Copy(S, 1, Pr);
        End;
    Else
      S := '';
    End;
    { largeur }
    While Length(S) < W Do
      If Left Then S := S + ' '
      Else If (PadC = 48) And (Length(S) > 0) And (S[1] In ['-', '+']) And (Cv In ['d', 'f', 'F', 'e', 'E']) Then
        Insert('0', S, 2)
      Else S := Chr(PadC) + S;
    BufAdd(B, S);
  End;
End;

{ arrondi de PHP (moitie loin de zero) }
Function PRound(X : Double; Prec : LongInt) : Double;
Var M, Y : Double;
Begin
  M := Pow10(Abs(Prec));
  If Prec >= 0 Then Y := X * M Else Y := X / M;
  { petites erreurs de representation : 1.005 * 100 = 100.49999... }
  If Abs(Y - Int(Y)) > 0.4999999999 Then
    If Abs(Y - Int(Y)) < 0.5000000001 Then
      If Y >= 0 Then Y := Int(Y) + 1 Else Y := Int(Y) - 1
    Else If Y >= 0 Then Y := Int(Y + 0.5) Else Y := -Int(-Y + 0.5)
  Else If Y >= 0 Then Y := Int(Y + 0.5) Else Y := -Int(-Y + 0.5);
  If Prec >= 0 Then PRound := Y / M Else PRound := Y * M;
End;

Function PNumFmt(X : Double; Dec : LongInt; Dp, Ts : String) : String;
Var S, I, F : String; K, N : LongInt; Neg : Boolean;
Begin
  X := PRound(X, Dec);
  Neg := X < 0;
  If Neg Then X := -X;
  Str(X:0:Dec, S);
  K := Pos('.', S);
  If K > 0 Then
  Begin
    I := Copy(S, 1, K - 1);
    F := Copy(S, K + 1, 255);
  End
  Else
  Begin
    I := S;
    F := '';
  End;
  S := '';
  N := 0;
  For K := Length(I) DownTo 1 Do
  Begin
    If (N > 0) And (N Mod 3 = 0) Then S := Ts + S;
    S := I[K] + S;
    Inc(N);
  End;
  If Dec > 0 Then S := S + Dp + F;
  If Neg And (X <> 0) Then S := '-' + S;
  PNumFmt := S;
End;

{ --- dates --- }
Const
  PDayL : Array[0..6] Of String[9] = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
  PMonL : Array[1..12] Of String[9] = ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December');

Function PDaysIn(Mo, Y : LongInt) : LongInt;
Begin
  Case Mo Of
    4, 6, 9, 11 : PDaysIn := 30;
    2 : If ((Y Mod 4 = 0) And (Y Mod 100 <> 0)) Or (Y Mod 400 = 0) Then PDaysIn := 29 Else PDaysIn := 28;
  Else
    PDaysIn := 31;
  End;
End;

{ mktime : mois, jours, heures hors limites normalises }
Function PMkTime(H, Mi, S, Mo, D, Y : LongInt) : LongInt;
Var T : LongInt;
Begin
  Dec(Mo);
  Y := Y + Mo Div 12;
  Mo := Mo Mod 12;
  If Mo < 0 Then
  Begin
    Mo := Mo + 12;
    Dec(Y);
  End;
  T := UnixTime(Y, Mo + 1, 1, 0, 0, 0);
  PMkTime := T + (D - 1) * 86400 + H * 3600 + Mi * 60 + S;
End;

Procedure PDate(Var F : TCell; T : LongInt; Var B : TBuf);
Var Y, Mo, D, H, Mi, S, Wd, K, Doy, Wk : LongInt; P : PBytes; C : Char;
Begin
  UnixSplit(T, Y, Mo, D, H, Mi, S, Wd);
  Doy := (T - UnixTime(Y, 1, 1, 0, 0, 0)) Div 86400;
  K := 0;
  While K < F.L Do
  Begin
    P := PoolPtr(F);
    C := Chr(P^[K]);
    Case C Of
      'd' : BufAdd(B, Pad2(D));
      'D' : BufAdd(B, Copy(PDayL[Wd], 1, 3));
      'j' : BufAdd(B, IStr(D));
      'l' : BufAdd(B, PDayL[Wd]);
      'N' : If Wd = 0 Then BufAdd(B, '7') Else BufAdd(B, IStr(Wd));
      'S' :
        If (D = 1) Or (D = 21) Or (D = 31) Then BufAdd(B, 'st')
        Else If (D = 2) Or (D = 22) Then BufAdd(B, 'nd')
        Else If (D = 3) Or (D = 23) Then BufAdd(B, 'rd')
        Else BufAdd(B, 'th');
      'w' : BufAdd(B, IStr(Wd));
      'z' : BufAdd(B, IStr(Doy));
      'W' :
        Begin
          Wk := (Doy - ((Wd + 6) Mod 7) + 10) Div 7;
          If Wk < 1 Then Wk := 52;
          BufAdd(B, Pad2(Wk));
        End;
      'F' : BufAdd(B, PMonL[Mo]);
      'm' : BufAdd(B, Pad2(Mo));
      'M' : BufAdd(B, Copy(PMonL[Mo], 1, 3));
      'n' : BufAdd(B, IStr(Mo));
      't' : BufAdd(B, IStr(PDaysIn(Mo, Y)));
      'L' : BufAdd(B, IStr(Ord(PDaysIn(2, Y) = 29)));
      'Y', 'o' : BufAdd(B, IStr(Y));
      'y' : BufAdd(B, Pad2(Y Mod 100));
      'a' : If H < 12 Then BufAdd(B, 'am') Else BufAdd(B, 'pm');
      'A' : If H < 12 Then BufAdd(B, 'AM') Else BufAdd(B, 'PM');
      'g' : If H Mod 12 = 0 Then BufAdd(B, '12') Else BufAdd(B, IStr(H Mod 12));
      'G' : BufAdd(B, IStr(H));
      'h' : If H Mod 12 = 0 Then BufAdd(B, '12') Else BufAdd(B, Pad2(H Mod 12));
      'H' : BufAdd(B, Pad2(H));
      'i' : BufAdd(B, Pad2(Mi));
      's' : BufAdd(B, Pad2(S));
      'u' : BufAdd(B, '000000');
      'v' : BufAdd(B, '000');
      'e' : BufAdd(B, 'UTC');
      'T' : BufAdd(B, 'UTC');
      'P' : BufAdd(B, '+00:00');
      'p' : BufAdd(B, 'Z');
      'O' : BufAdd(B, '+0000');
      'Z' : BufAdd(B, '0');
      'I' : BufAdd(B, '0');
      'U' : BufAdd(B, IStr(T));
      'c' : BufAdd(B, IStr(Y) + '-' + Pad2(Mo) + '-' + Pad2(D) + 'T' + Pad2(H) + ':' + Pad2(Mi) + ':' + Pad2(S) + '+00:00');
      'r' : BufAdd(B, Copy(PDayL[Wd], 1, 3) + ', ' + Pad2(D) + ' ' + Copy(PMonL[Mo], 1, 3) + ' ' + IStr(Y) + ' ' +
                      Pad2(H) + ':' + Pad2(Mi) + ':' + Pad2(S) + ' +0000');
      '\' :
        Begin
          Inc(K);
          If K < F.L Then BufAddC(B, PoolPtr(F)^[K]);
        End;
    Else
      BufAddC(B, Ord(C));
    End;
    Inc(K);
  End;
End;

{ strtotime : maintenant, aujourd'hui, demain, hier, AAAA-MM-JJ [HH:MM[:SS]], +n unite }
Function PStrToTime(S : String; Base : LongInt; Var T : LongInt) : Boolean;
Var Y, Mo, D, H, Mi, Sc, Wd, N, K, E : LongInt; U, W : String; Sign : LongInt;
Begin
  PStrToTime := True;
  S := LoStr(Trim(S));
  T := Base;
  UnixSplit(Base, Y, Mo, D, H, Mi, Sc, Wd);
  If (S = 'now') Or (S = '') Then Exit;
  If S = 'today' Then
  Begin
    T := UnixTime(Y, Mo, D, 0, 0, 0);
    Exit;
  End;
  If S = 'tomorrow' Then
  Begin
    T := UnixTime(Y, Mo, D, 0, 0, 0) + 86400;
    Exit;
  End;
  If S = 'yesterday' Then
  Begin
    T := UnixTime(Y, Mo, D, 0, 0, 0) - 86400;
    Exit;
  End;
  If (Length(S) >= 10) And (S[5] = '-') And (S[8] = '-') Then
  Begin
    Y := SVal(Copy(S, 1, 4)); Mo := SVal(Copy(S, 6, 2)); D := SVal(Copy(S, 9, 2));
    H := 0; Mi := 0; Sc := 0;
    If (Length(S) >= 16) And (S[14] = ':') Then
    Begin
      H := SVal(Copy(S, 12, 2)); Mi := SVal(Copy(S, 15, 2));
      If (Length(S) >= 19) And (S[17] = ':') Then Sc := SVal(Copy(S, 18, 2));
    End;
    T := PMkTime(H, Mi, Sc, Mo, D, Y);
    Exit;
  End;
  { +1 day, -2 weeks, +3 months... (plusieurs termes) }
  While S <> '' Do
  Begin
    Sign := 1;
    If S[1] = '+' Then Delete(S, 1, 1)
    Else If S[1] = '-' Then
    Begin
      Sign := -1;
      Delete(S, 1, 1);
    End;
    S := Trim(S);
    K := 1;
    While (K <= Length(S)) And (S[K] In ['0'..'9']) Do Inc(K);
    If K = 1 Then
    Begin
      PStrToTime := False;
      Exit;
    End;
    Val(Copy(S, 1, K - 1), N, E);
    Delete(S, 1, K - 1);
    S := Trim(S);
    K := 1;
    While (K <= Length(S)) And (S[K] In ['a'..'z']) Do Inc(K);
    W := Copy(S, 1, K - 1);
    Delete(S, 1, K - 1);
    S := Trim(S);
    N := N * Sign;
    If Copy(W, 1, 3) = 'sec' Then T := T + N
    Else If Copy(W, 1, 3) = 'min' Then T := T + N * 60
    Else If Copy(W, 1, 4) = 'hour' Then T := T + N * 3600
    Else If Copy(W, 1, 3) = 'day' Then T := T + N * 86400
    Else If Copy(W, 1, 4) = 'week' Then T := T + N * 604800
    Else If Copy(W, 1, 5) = 'month' Then
    Begin
      UnixSplit(T, Y, Mo, D, H, Mi, Sc, Wd);
      T := PMkTime(H, Mi, Sc, Mo + N, D, Y);
    End
    Else If Copy(W, 1, 4) = 'year' Then
    Begin
      UnixSplit(T, Y, Mo, D, H, Mi, Sc, Wd);
      T := PMkTime(H, Mi, Sc, Mo, D, Y + N);
    End
    Else
    Begin
      PStrToTime := False;
      Exit;
    End;
  End;
End;

{ chemin d'un fichier : relatif au dossier de la page }
Function PPath(S : String) : String;
Var Dir : String; K : LongInt;
Begin
  {$IFDEF OS2PC}
  For K := 1 To Length(S) Do If S[K] = '/' Then S[K] := '\';
  If (Length(S) >= 2) And (S[2] = ':') Then
  Begin
    PPath := S;
    Exit;
  End;
  If (S <> '') And (S[1] = '\') Then
  Begin
    PPath := Copy(ScriptPath[VmConn], 1, 2) + S;
    Exit;
  End;
  Dir := ScriptPath[VmConn];
  While (Length(Dir) > 0) And (Dir[Length(Dir)] <> '\') Do Delete(Dir, Length(Dir), 1);
  PPath := Dir + S;
  {$ELSE}
  If (S <> '') And (S[1] = '/') Then
  Begin
    PPath := S;
    Exit;
  End;
  Dir := ScriptPath[VmConn];
  While (Length(Dir) > 0) And (Dir[Length(Dir)] <> '/') Do Delete(Dir, Length(Dir), 1);
  PPath := Dir + S;
  K := 0;
  {$ENDIF}
End;

Function PWild(Pat, S : String) : Boolean;
Var P, K : LongInt;
Begin
  If Pat = '' Then
  Begin
    PWild := S = '';
    Exit;
  End;
  If Pat[1] = '*' Then
  Begin
    For K := 0 To Length(S) Do
      If PWild(Copy(Pat, 2, 255), Copy(S, K + 1, 255)) Then
      Begin
        PWild := True;
        Exit;
      End;
    PWild := False;
    Exit;
  End;
  If (S <> '') And ((Pat[1] = '?') Or (UpCase(Pat[1]) = UpCase(S[1]))) Then
    PWild := PWild(Copy(Pat, 2, 255), Copy(S, 2, 255))
  Else PWild := False;
  P := 0;
End;

{ chaine de connexion : mysqli(hote, utilisateur, mot de passe, base, port) }
Function PConnMy(Var Arg : Array Of TCell; Argc : LongInt) : String;
Var H, S : String; K : LongInt;
Begin
  H := '';
  If Argc > 0 Then H := ArgPStr(Arg[0]);
  If Copy(H, 1, 2) = 'p:' Then Delete(H, 1, 2);
  If H = '' Then H := 'localhost';
  S := 'Driver=MariaDB;Server=' + H;
  If Argc > 1 Then S := S + ';User=' + ArgPStr(Arg[1]);
  If Argc > 2 Then S := S + ';Password=' + ArgPStr(Arg[2]);
  If (Argc > 3) And (Arg[3].T <> vtNil) Then S := S + ';Database=' + ArgPStr(Arg[3]);
  If (Argc > 4) And (Arg[4].T <> vtNil) Then S := S + ';Port=' + IStr(PInt(Arg[4]));
  PConnMy := S;
  K := 0;
End;

{ pg_connect("host=... port=... dbname=... user=... password=...") }
Function PConnPg(S : String) : String;
Var R, K, V : String; I : LongInt; Q : Char;
Begin
  If (Copy(LoStr(S), 1, 11) = 'postgres://') Or (Copy(LoStr(S), 1, 13) = 'postgresql://') Then
  Begin
    PConnPg := S;
    Exit;
  End;
  R := 'Driver=PostgreSQL';
  I := 1;
  While I <= Length(S) Do
  Begin
    While (I <= Length(S)) And (S[I] = ' ') Do Inc(I);
    K := '';
    While (I <= Length(S)) And (S[I] <> '=') And (S[I] <> ' ') Do
    Begin
      K := K + S[I];
      Inc(I);
    End;
    While (I <= Length(S)) And (S[I] = ' ') Do Inc(I);
    If (I <= Length(S)) And (S[I] = '=') Then Inc(I);
    While (I <= Length(S)) And (S[I] = ' ') Do Inc(I);
    V := '';
    If (I <= Length(S)) And (S[I] = '''') Then
    Begin
      Q := S[I];
      Inc(I);
      While (I <= Length(S)) And (S[I] <> Q) Do
      Begin
        V := V + S[I];
        Inc(I);
      End;
      Inc(I);
    End
    Else
      While (I <= Length(S)) And (S[I] <> ' ') Do
      Begin
        V := V + S[I];
        Inc(I);
      End;
    K := LoStr(K);
    If (K = 'host') Or (K = 'hostaddr') Then R := R + ';Server=' + V
    Else If K = 'port' Then R := R + ';Port=' + V
    Else If K = 'dbname' Then R := R + ';Database=' + V
    Else If K = 'user' Then R := R + ';User=' + V
    Else If K = 'password' Then R := R + ';Password=' + V;
  End;
  PConnPg := R;
End;

{ new PDO('mysql:host=...;dbname=...', utilisateur, mot de passe) }
Function PConnPdo(Var Arg : Array Of TCell; Argc : LongInt) : String;
Var D, Drv, R : String; K : LongInt;
Begin
  D := '';
  If Argc > 0 Then D := ArgPStr(Arg[0]);
  K := Pos(':', D);
  Drv := LoStr(Copy(D, 1, K - 1));
  D := Copy(D, K + 1, 255);
  If Drv = 'pgsql' Then R := 'Driver=PostgreSQL' Else R := 'Driver=MariaDB';
  { les cles de la DSN (host, port, dbname, user, password) : comme la chaine d'ADO }
  R := R + ';' + D;
  If (Argc > 1) And (Arg[1].T <> vtNil) Then R := R + ';User=' + ArgPStr(Arg[1]);
  If (Argc > 2) And (Arg[2].T <> vtNil) Then R := R + ';Password=' + ArgPStr(Arg[2]);
  PConnPdo := R;
End;

{ --- tableaux : aides --- }
Function PArrArg(Var C : TCell; Fn : String) : LongInt;
Begin
  If PIsArr(C) Then PArrArg := C.I
  Else
  Begin
    VmFail(Fn + '() : tableau attendu');
    PArrArg := -1;
  End;
End;

{ entree derniere (indice brut) }
Function PArrLast(Id : LongInt) : LongInt;
Var K : LongInt;
Begin
  PArrLast := -1;
  For K := NDict - 1 DownTo 0 Do
    If DObj^[K] = Id Then
    Begin
      PArrLast := K;
      Exit;
    End;
End;

{ valeur dans le tableau ? (Strict : ===) ; rend l'entree ou -1 }
Function PArrSearch(Id : LongInt; Var V : TCell; Strict : Boolean) : LongInt;
Var K : LongInt; X : TCell;
Begin
  PArrSearch := -1;
  K := PArrNext(Id, 0);
  While K >= 0 Do
  Begin
    X := DVal^[K];
    If (Strict And PhpIdent(X, V)) Or (Not Strict And (PhpCompare(X, V) = 0)) Then
    Begin
      PArrSearch := K;
      Exit;
    End;
    K := PArrNext(Id, K + 1);
  End;
End;

Procedure PhpBuiltin(Id, Argc : LongInt; Var Arg : Array Of TCell; Var R : TCell);
Var T, T2, T3, X, Y, Kc : TCell; P, Q : PBytes; B : TBuf; K, J, N, M, I, A, St, Len, Ob, Ob2, Pos_ : LongInt;
    D, D2 : Double; S, S2, S3 : String; Ok, NoCase : Boolean; Y_, Mo_, D_, H_, Mi_, Sc_, Wd_ : LongInt;
Begin
  MkNil(R);
  BufInit(B);
  Case Id Of
    { --- chaines --- }
    pfStrlen, pfMbStrlen :
      Begin
        PStrCell(Arg[0], T);
        If Id = pfMbStrlen Then
        Begin
          P := PoolPtr(T);
          N := 0;
          For K := 0 To T.L - 1 Do If (P^[K] And $C0) <> $80 Then Inc(N);
          MkInt(N, R);
        End
        Else MkInt(T.L, R);
      End;
    pfStrtoupper, pfStrtolower, pfMbStrtoupper, pfMbStrtolower, pfUcfirst, pfLcfirst, pfUcwords :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        BufAddB(B, P, T.L);
        For K := 0 To B.Len - 1 Do
          Case Id Of
            pfStrtoupper, pfMbStrtoupper : B.P^[K] := PUp(B.P^[K]);
            pfStrtolower, pfMbStrtolower : B.P^[K] := PLow(B.P^[K]);
            pfUcfirst : If K = 0 Then B.P^[K] := PUp(B.P^[K]);
            pfLcfirst : If K = 0 Then B.P^[K] := PLow(B.P^[K]);
            pfUcwords : If (K = 0) Or (B.P^[K - 1] In [32, 9, 10, 13, 11, 12]) Then B.P^[K] := PUp(B.P^[K]);
          End;
        PRet(B, R);
      End;
    pfTrim, pfLtrim, pfRtrim, pfChop :
      Begin
        PStrCell(Arg[0], T);
        If Argc > 1 Then S := ArgPStr(Arg[1])
        Else
        Begin
          S := ' '#9#10#13#11' ';
          S[Length(S)] := Chr(0);        { NUL : pas de #0 dans un litteral (OS2PC) }
        End;
        { a..z : intervalle }
        K := Pos('..', S);
        While K > 1 Do
        Begin
          S2 := '';
          For J := Ord(S[K - 1]) To Ord(S[K + 2]) Do S2 := S2 + Chr(J);
          S := Copy(S, 1, K - 2) + S2 + Copy(S, K + 3, 255);
          K := Pos('..', S);
        End;
        P := PoolPtr(T);
        St := 0; Len := T.L;
        If (Id = pfTrim) Or (Id = pfLtrim) Then
          While (St < Len) And (Pos(Chr(P^[St]), S) > 0) Do Inc(St);
        If Id <> pfLtrim Then
          While (Len > St) And (Pos(Chr(P^[Len - 1]), S) > 0) Do Dec(Len);
        BufAddB(B, @P^[St], Len - St);
        PRet(B, R);
      End;
    pfSubstr, pfMbSubstr :
      Begin
        PStrCell(Arg[0], T);
        N := T.L;
        St := PInt(Arg[1]);
        If St < 0 Then St := N + St;
        If St < 0 Then St := 0;
        If St > N Then St := N;
        If (Argc > 2) And (Arg[2].T <> vtNil) Then
        Begin
          Len := PInt(Arg[2]);
          If Len < 0 Then Len := N - St + Len;
        End
        Else Len := N - St;
        If Len < 0 Then Len := 0;
        If St + Len > N Then Len := N - St;
        P := PoolPtr(T);
        BufAddB(B, @P^[St], Len);
        PRet(B, R);
      End;
    pfStrpos, pfStripos, pfStrrpos, pfStrripos, pfStrContains, pfStrStartsWith, pfStrEndsWith :
      Begin
        PStrCell(Arg[0], T); PStrCell(Arg[1], T2);
        St := 0;
        If Argc > 2 Then St := PInt(Arg[2]);
        If St < 0 Then St := T.L + St;
        If St < 0 Then St := 0;
        P := PoolPtr(T); Q := PoolPtr(T2);
        NoCase := (Id = pfStripos) Or (Id = pfStrripos);
        If Id = pfStrContains Then MkBool(PFind(P, T.L, Q, T2.L, 0, False) >= 0, R)
        Else If Id = pfStrStartsWith Then MkBool((T2.L <= T.L) And (PFind(P, T2.L, Q, T2.L, 0, False) = 0), R)
        Else If Id = pfStrEndsWith Then
          MkBool((T2.L <= T.L) And (PFind(@P^[T.L - T2.L], T2.L, Q, T2.L, 0, False) = 0), R)
        Else
        Begin
          If (Id = pfStrrpos) Or (Id = pfStrripos) Then K := PFindRev(P, T.L, Q, T2.L, NoCase)
          Else K := PFind(P, T.L, Q, T2.L, St, NoCase);
          If (K >= 0) And (K >= St) Then MkInt(K, R) Else MkBool(False, R);
        End;
      End;
    pfStrReplace, pfStrIreplace :
      Begin
        { str_replace(cherche, remplace, sujet) : chaines ou tableaux }
        If PIsArr(Arg[2]) Then
        Begin
          Ob := PArrNew;
          Ob2 := Arg[2].I;
          T := Arg[0]; T2 := Arg[1];
          K := PArrNext(Ob2, 0);
          While K >= 0 Do
          Begin
            Arg[0] := T; Arg[1] := T2; Arg[2] := DVal^[K];
            PhpBuiltin(Id, 3, Arg, T3);
            PArrSet(Ob, DKey^[K], T3);
            K := PArrNext(Ob2, K + 1);
          End;
          MkObj(Ob, R);
          Exit;
        End;
        If PIsArr(Arg[0]) Then
        Begin
          Ob := Arg[0].I;
          X := Arg[1];
          PStrCell(Arg[2], T3);
          N := 0;
          K := PArrNext(Ob, 0);
          While K >= 0 Do
          Begin
            If PIsArr(X) Then
            Begin
              J := PArrNth(X.I, N);
              If J >= 0 Then Y := DVal^[J] Else MkStr('', Y);
            End
            Else Y := X;
            Arg[0] := DVal^[K]; Arg[1] := Y; Arg[2] := T3;
            PhpBuiltin(Id, 3, Arg, T);
            T3 := T;
            Inc(N);
            K := PArrNext(Ob, K + 1);
          End;
          R := T3;
          Exit;
        End;
        PStrCell(Arg[2], T3);
        PStrCell(Arg[0], T); PStrCell(Arg[1], T2);
        B.Len := 0;
        P := PoolPtr(T3); Q := PoolPtr(T);
        If T.L = 0 Then
        Begin
          BufAddB(B, P, T3.L);
          PRet(B, R);
          Exit;
        End;
        K := 0;
        While K < T3.L Do
        Begin
          J := PFind(P, T3.L, Q, T.L, K, Id = pfStrIreplace);
          If J < 0 Then
          Begin
            BufAddB(B, @P^[K], T3.L - K);
            Break;
          End;
          BufAddB(B, @P^[K], J - K);
          BufAddB(B, PoolPtr(T2), T2.L);
          K := J + T.L;
        End;
        PRet(B, R);
      End;
    pfStrRepeat :
      Begin
        PStrCell(Arg[0], T);
        N := PInt(Arg[1]);
        For K := 1 To N Do BufAddB(B, PoolPtr(T), T.L);
        PRet(B, R);
      End;
    pfStrPad :
      Begin
        PStrCell(Arg[0], T);
        N := PInt(Arg[1]);
        If Argc > 2 Then PStrCell(Arg[2], T2) Else MkStr(' ', T2);
        If Argc > 3 Then M := PInt(Arg[3]) Else M := 1;
        Len := N - T.L;
        If (Len <= 0) Or (T2.L = 0) Then
        Begin
          R := T;
          Exit;
        End;
        If M = 0 Then A := Len Else If M = 2 Then A := Len Div 2 Else A := 0;
        Q := PoolPtr(T2);
        For K := 0 To A - 1 Do BufAddC(B, Q^[K Mod T2.L]);
        BufAddB(B, PoolPtr(T), T.L);
        For K := 0 To Len - A - 1 Do BufAddC(B, Q^[K Mod T2.L]);
        PRet(B, R);
      End;
    pfStrSplit :
      Begin
        PStrCell(Arg[0], T);
        If Argc > 1 Then N := PInt(Arg[1]) Else N := 1;
        If N < 1 Then N := 1;
        Ob := PArrNew;
        K := 0;
        Repeat
          P := PoolPtr(T);
          Len := N;
          If K + Len > T.L Then Len := T.L - K;
          MkStrB(@P^[K], Len, X);
          PArrPush(Ob, X);
          K := K + N;
        Until K >= T.L;
        MkObj(Ob, R);
      End;
    pfStrrev :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        For K := T.L - 1 DownTo 0 Do BufAddC(B, P^[K]);
        PRet(B, R);
      End;
    pfStrcmp, pfStrcasecmp, pfStrncmp, pfStrncasecmp, pfStrnatcmp :
      Begin
        PStrCell(Arg[0], T); PStrCell(Arg[1], T2);
        If (Id = pfStrncmp) Or (Id = pfStrncasecmp) Then
        Begin
          N := PInt(Arg[2]);
          If T.L > N Then T.L := N;
          If T2.L > N Then T2.L := N;
        End;
        If (Id = pfStrnatcmp) And PIsNumStr(T) And PIsNumStr(T2) Then MkInt(PhpCompare(T, T2), R)
        Else MkInt(StrCmpCells(T, T2, (Id = pfStrcasecmp) Or (Id = pfStrncasecmp)), R);
      End;
    pfStrstr, pfStristr, pfStrrchr :
      Begin
        PStrCell(Arg[0], T); PStrCell(Arg[1], T2);
        P := PoolPtr(T); Q := PoolPtr(T2);
        If Id = pfStrrchr Then
        Begin
          K := -1;
          If T2.L > 0 Then For J := 0 To T.L - 1 Do If P^[J] = Q^[0] Then K := J;
        End
        Else K := PFind(P, T.L, Q, T2.L, 0, Id = pfStristr);
        If K < 0 Then MkBool(False, R)
        Else
        Begin
          If (Argc > 2) And PBool(Arg[2]) Then BufAddB(B, P, K) Else BufAddB(B, @P^[K], T.L - K);
          PRet(B, R);
        End;
      End;
    pfSubstrCount :
      Begin
        PStrCell(Arg[0], T); PStrCell(Arg[1], T2);
        N := 0; K := 0;
        If T2.L > 0 Then
          Repeat
            K := PFind(PoolPtr(T), T.L, PoolPtr(T2), T2.L, K, False);
            If K >= 0 Then
            Begin
              Inc(N);
              K := K + T2.L;
            End;
          Until K < 0;
        MkInt(N, R);
      End;
    pfSubstrReplace :
      Begin
        PStrCell(Arg[0], T); PStrCell(Arg[1], T2);
        N := T.L;
        St := PInt(Arg[2]);
        If St < 0 Then St := N + St;
        If St < 0 Then St := 0;
        If St > N Then St := N;
        If (Argc > 3) And (Arg[3].T <> vtNil) Then
        Begin
          Len := PInt(Arg[3]);
          If Len < 0 Then Len := N - St + Len;
        End
        Else Len := N - St;
        If Len < 0 Then Len := 0;
        If St + Len > N Then Len := N - St;
        P := PoolPtr(T);
        BufAddB(B, P, St);
        BufAddB(B, PoolPtr(T2), T2.L);
        BufAddB(B, @P^[St + Len], N - St - Len);
        PRet(B, R);
      End;
    pfNl2br :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        For K := 0 To T.L - 1 Do
        Begin
          If (P^[K] = 10) And Not ((K > 0) And (P^[K - 1] = 13)) Then BufAdd(B, '<br />')
          Else If P^[K] = 13 Then BufAdd(B, '<br />');
          BufAddC(B, P^[K]);
        End;
        PRet(B, R);
      End;
    pfHtmlspecialchars, pfHtmlentities :
      Begin
        PStrCell(Arg[0], T);
        If Argc > 1 Then M := PInt(Arg[1]) Else M := 3;
        P := PoolPtr(T);
        For K := 0 To T.L - 1 Do
          Case P^[K] Of
            38 : BufAdd(B, '&amp;');
            60 : BufAdd(B, '&lt;');
            62 : BufAdd(B, '&gt;');
            34 : If (M And 2) <> 0 Then BufAdd(B, '&quot;') Else BufAddC(B, 34);
            39 : If (M And 1) <> 0 Then BufAdd(B, '&#039;') Else BufAddC(B, 39);
          Else
            BufAddC(B, P^[K]);
          End;
        PRet(B, R);
      End;
    pfHtmlEntityDecode, pfHtmlspecialcharsDecode :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        K := 0;
        While K < T.L Do
        Begin
          If P^[K] = 38 Then
          Begin
            S := '';
            J := K + 1;
            While (J < T.L) And (J - K < 10) And (P^[J] <> 59) Do
            Begin
              S := S + Chr(P^[J]);
              Inc(J);
            End;
            If (J < T.L) And (P^[J] = 59) Then
            Begin
              N := -1;
              If S = 'amp' Then N := 38 Else If S = 'lt' Then N := 60 Else If S = 'gt' Then N := 62
              Else If S = 'quot' Then N := 34 Else If (S = '#039') Or (S = '#39') Or (S = 'apos') Then N := 39
              Else If (S = 'nbsp') And (Id = pfHtmlEntityDecode) Then N := 160
              Else If (Length(S) > 1) And (S[1] = '#') And (Id = pfHtmlEntityDecode) Then
              Begin
                If UpCase(S[2]) = 'X' Then
                Begin
                  N := 0;
                  For J := 3 To Length(S) Do If HexV(S[J]) >= 0 Then N := N * 16 + HexV(S[J]);
                End
                Else N := SVal(Copy(S, 2, 10));
              End;
              If N >= 0 Then
              Begin
                AddUtf8(B, N);
                K := J + 1;
                Continue;
              End;
            End;
          End;
          BufAddC(B, P^[K]);
          Inc(K);
        End;
        PRet(B, R);
      End;
    pfStripTags :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        N := 0;
        For K := 0 To T.L - 1 Do
          If P^[K] = 60 Then Inc(N)
          Else If (P^[K] = 62) And (N > 0) Then Dec(N)
          Else If N = 0 Then BufAddC(B, P^[K]);
        PRet(B, R);
      End;
    pfAddslashes, pfQuotemeta :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        For K := 0 To T.L - 1 Do
        Begin
          If Id = pfAddslashes Then
          Begin
            If P^[K] = 0 Then
            Begin
              BufAdd(B, '\0');
              Continue;
            End;
            If P^[K] In [39, 34, 92] Then BufAddC(B, 92);
          End
          Else If Chr(P^[K]) In ['.', '\', '+', '*', '?', '[', '^', ']', '$', '(', ')'] Then BufAddC(B, 92);
          BufAddC(B, P^[K]);
        End;
        PRet(B, R);
      End;
    pfStripslashes :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        K := 0;
        While K < T.L Do
        Begin
          If (P^[K] = 92) And (K + 1 < T.L) Then
          Begin
            Inc(K);
            If P^[K] = 48 Then BufAddC(B, 0) Else BufAddC(B, P^[K]);
          End
          Else If P^[K] <> 92 Then BufAddC(B, P^[K]);
          Inc(K);
        End;
        PRet(B, R);
      End;
    pfUrlencode, pfRawurlencode :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        For K := 0 To T.L - 1 Do
          If Chr(P^[K]) In ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.'] Then BufAddC(B, P^[K])
          Else If (P^[K] = 126) And (Id = pfRawurlencode) Then BufAddC(B, 126)
          Else If (P^[K] = 32) And (Id = pfUrlencode) Then BufAddC(B, 43)
          Else BufAdd(B, '%' + Hex(P^[K], 2));
        PRet(B, R);
      End;
    pfUrldecode, pfRawurldecode :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        K := 0;
        While K < T.L Do
        Begin
          If (P^[K] = 37) And (K + 2 < T.L) And (HexV(Chr(P^[K + 1])) >= 0) And (HexV(Chr(P^[K + 2])) >= 0) Then
          Begin
            BufAddC(B, HexV(Chr(P^[K + 1])) * 16 + HexV(Chr(P^[K + 2])));
            K := K + 3;
            Continue;
          End;
          If (P^[K] = 43) And (Id = pfUrldecode) Then BufAddC(B, 32) Else BufAddC(B, P^[K]);
          Inc(K);
        End;
        PRet(B, R);
      End;
    pfBase64Encode :
      Begin
        PStrCell(Arg[0], T);
        B64Enc(PoolPtr(T), T.L, B, 0);
        PRet(B, R);
      End;
    pfBase64Decode :
      Begin
        PStrCell(Arg[0], T);
        BufGrow(B, T.L + 4);
        B.Len := B64Dec(PoolPtr(T), T.L, B.P, T.L + 4);
        If B.Len < 0 Then B.Len := 0;
        PRet(B, R);
      End;
    pfMd5, pfSha1 :
      Begin
        PStrCell(Arg[0], T);
        BufAddB(B, PoolPtr(T), T.L);
        If Id = pfMd5 Then
        Begin
          Md5(B.P, B.Len, PMd5Out);
          S := LoStr(HexBytes(@PMd5Out, 16));
        End
        Else
        Begin
          Sha1(B.P, B.Len, PShaOut);
          S := LoStr(HexBytes(@PShaOut, 20));
        End;
        BufFree(B);
        MkStr(S, R);
      End;
    pfCrc32 :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        A := -1;
        For K := 0 To T.L - 1 Do
        Begin
          A := A Xor P^[K];
          For J := 1 To 8 Do
            If (A And 1) <> 0 Then A := ((A Shr 1) And $7FFFFFFF) Xor LongInt($EDB88320)
            Else A := (A Shr 1) And $7FFFFFFF;
        End;
        A := Not A;
        D := A;
        If A < 0 Then MkReal(D + 4294967296.0, R) Else MkInt(A, R);
      End;
    pfNumberFormat :
      Begin
        If Argc > 1 Then N := PInt(Arg[1]) Else N := 0;
        If Argc > 2 Then S := ArgPStr(Arg[2]) Else S := '.';
        If Argc > 3 Then S2 := ArgPStr(Arg[3]) Else S2 := ',';
        MkStr(PNumFmt(PReal(Arg[0]), N, S, S2), R);
      End;
    pfSprintf, pfPrintf, pfVsprintf :
      Begin
        If Id = pfVsprintf Then
        Begin
          { vsprintf(format, tableau) : les valeurs en arguments }
          X := Arg[1];
          N := 1;
          If PIsArr(X) Then
          Begin
            K := PArrNext(X.I, 0);
            While (K >= 0) And (N < 16) Do
            Begin
              Arg[N] := DVal^[K];
              Inc(N);
              K := PArrNext(X.I, K + 1);
            End;
          End;
          Argc := N;
        End;
        PSprintf(Arg, Argc, 0, B);
        If Id = pfPrintf Then
        Begin
          BufAddB(VmOut, B.P, B.Len);
          If B.Len > 0 Then VmHdrPending := False;
          MkInt(B.Len, R);
          BufFree(B);
        End
        Else PRet(B, R);
      End;
    pfWordwrap :
      Begin
        { wordwrap(texte, largeur, coupure, couper) : coupe aux espaces }
        PStrCell(Arg[0], T);
        If Argc > 1 Then N := PInt(Arg[1]) Else N := 75;
        If Argc > 2 Then S := ArgPStr(Arg[2]) Else S := #10;
        Ok := (Argc > 3) And PBool(Arg[3]);
        P := PoolPtr(T);
        Len := 0;           { longueur de la ligne en cours }
        K := 0;
        While K < T.L Do
        Begin
          If P^[K] = 10 Then
          Begin
            BufAddC(B, 10);
            Len := 0;
            Inc(K);
            Continue;
          End;
          If P^[K] = 32 Then
          Begin
            { mot suivant : coupure si la ligne deborde }
            J := K + 1;
            While (J < T.L) And (P^[J] <> 32) And (P^[J] <> 10) Do Inc(J);
            If (Len > 0) And (Len + 1 + (J - K - 1) > N) Then
            Begin
              BufAdd(B, S);
              Len := 0;
            End
            Else
            Begin
              BufAddC(B, 32);
              Inc(Len);
            End;
            Inc(K);
            Continue;
          End;
          If Ok And (Len >= N) Then
          Begin
            BufAdd(B, S);
            Len := 0;
          End;
          BufAddC(B, P^[K]);
          Inc(Len);
          Inc(K);
        End;
        PRet(B, R);
      End;
    pfImplode, pfJoin :
      Begin
        If PIsArr(Arg[0]) Then
        Begin
          X := Arg[0];
          If Argc > 1 Then PStrCell(Arg[1], T) Else MkStr('', T);
        End
        Else
        Begin
          PStrCell(Arg[0], T);
          X := Arg[1];
        End;
        If Not PIsArr(X) Then
        Begin
          VmFail('implode() : tableau attendu');
          Exit;
        End;
        N := 0;
        K := PArrNext(X.I, 0);
        While K >= 0 Do
        Begin
          If N > 0 Then BufAddB(B, PoolPtr(T), T.L);
          Y := DVal^[K];
          PAddCell(B, Y);
          Inc(N);
          K := PArrNext(X.I, K + 1);
        End;
        PRet(B, R);
      End;
    pfExplode :
      Begin
        PStrCell(Arg[0], T); PStrCell(Arg[1], T2);
        If T.L = 0 Then
        Begin
          VmFail('explode() : s'#130'parateur vide');
          Exit;
        End;
        If Argc > 2 Then M := PInt(Arg[2]) Else M := 2147483647;
        Ob := PArrNew;
        K := 0;
        N := 0;
        Repeat
          If (M > 0) And (N >= M - 1) Then J := -1
          Else J := PFind(PoolPtr(T2), T2.L, PoolPtr(T), T.L, K, False);
          P := PoolPtr(T2);
          If J < 0 Then
          Begin
            MkStrB(@P^[K], T2.L - K, X);
            PArrPush(Ob, X);
            Break;
          End;
          MkStrB(@P^[K], J - K, X);
          PArrPush(Ob, X);
          Inc(N);
          K := J + T.L;
        Until False;
        If M < 0 Then
          For K := 1 To -M Do
          Begin
            J := PArrLast(Ob);
            If J >= 0 Then DObj^[J] := -1;
          End;
        MkObj(Ob, R);
      End;
    pfChr :
      Begin
        S := Chr(PInt(Arg[0]) And 255);
        MkStr(S, R);
      End;
    pfOrd :
      Begin
        PStrCell(Arg[0], T);
        If T.L > 0 Then MkInt(PoolPtr(T)^[0], R) Else MkInt(0, R);
      End;
    pfDechex : MkStr(PBaseStr(PReal(Arg[0]), 16, False), R);
    pfDecbin : MkStr(PBaseStr(PReal(Arg[0]), 2, False), R);
    pfDecoct : MkStr(PBaseStr(PReal(Arg[0]), 8, False), R);
    pfHexdec, pfBindec, pfOctdec, pfBaseConvert :
      Begin
        PStrCell(Arg[0], T);
        If Id = pfHexdec Then A := 16 Else If Id = pfBindec Then A := 2 Else If Id = pfOctdec Then A := 8
        Else A := PInt(Arg[1]);
        P := PoolPtr(T);
        D := 0;
        For K := 0 To T.L - 1 Do
        Begin
          J := HexV(Chr(P^[K]));
          If (J < 0) And (Chr(P^[K]) In ['g'..'z', 'G'..'Z']) Then J := Ord(UpCase(Chr(P^[K]))) - 55;
          If (J >= 0) And (J < A) Then D := D * A + J;
        End;
        If Id = pfBaseConvert Then MkStr(PBaseStr(D, PInt(Arg[2]), False), R)
        Else If D <= 2147483647.0 Then MkInt(Trunc(D), R) Else MkReal(D, R);
      End;
    pfBin2hex :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        For K := 0 To T.L - 1 Do BufAdd(B, LoStr(Hex(P^[K], 2)));
        PRet(B, R);
      End;
    pfStrWordCount :
      Begin
        PStrCell(Arg[0], T);
        P := PoolPtr(T);
        N := 0; Ok := False;
        For K := 0 To T.L - 1 Do
          If Chr(P^[K]) In ['A'..'Z', 'a'..'z', '''', '-'] Then
          Begin
            If Not Ok Then Inc(N);
            Ok := True;
          End
          Else Ok := False;
        MkInt(N, R);
      End;
    pfUniqid :
      Begin
        If Argc > 0 Then S := ArgPStr(Arg[0]) Else S := '';
        MkStr(S + LoStr(Hex(NowUnix, 8)) + LoStr(Hex(PTicks And $FFFFF, 5)), R);
      End;
    pfLcgValue : MkReal(PRnd, R);
    pfJsonEncode :
      Begin
        If Argc > 1 Then N := PInt(Arg[1]) Else N := 0;
        PJsonEnc(Arg[0], N, 0, B);
        PRet(B, R);
      End;
    pfJsonDecode :
      Begin
        PStrCell(Arg[0], T);
        JP := PoolPtr(T); JN := T.L; JK := 0; JErr := False;
        JValue(R);
        JWs;
        If JErr Or (JK < JN) Then MkNil(R);
      End;
    { --- mathematiques --- }
    pfAbs :
      Begin
        PNumCell(Arg[0], X);
        If X.T = vtInt Then
        Begin
          If X.I < 0 Then MkInt(-X.I, R) Else R := X;
        End
        Else MkReal(Abs(X.R), R);
      End;
    pfCeil :
      Begin
        D := PReal(Arg[0]);
        If (D > 0) And (Frac(D) <> 0) Then MkReal(Int(D) + 1, R) Else MkReal(Int(D), R);
      End;
    pfFloor :
      Begin
        D := PReal(Arg[0]);
        If (D < 0) And (Frac(D) <> 0) Then MkReal(Int(D) - 1, R) Else MkReal(Int(D), R);
      End;
    pfRound :
      Begin
        If Argc > 1 Then N := PInt(Arg[1]) Else N := 0;
        MkReal(PRound(PReal(Arg[0]), N), R);
      End;
    pfSqrt :
      Begin
        D := PReal(Arg[0]);
        If D < 0 Then MkReal(0, R) Else MkReal(Sqrt(D), R);
      End;
    pfPow :
      Begin
        PNumCell(Arg[0], X); PNumCell(Arg[1], Y);
        If (X.T = vtInt) And (Y.T = vtInt) And (Y.I >= 0) Then
        Begin
          D := 1;
          For K := 1 To Y.I Do
          Begin
            D := D * X.I;
            If Abs(D) > 1E300 Then Break;
          End;
          If Abs(D) <= 2147483647.0 Then MkInt(Trunc(D), R) Else MkReal(D, R);
        End
        Else
        Begin
          If X.T = vtInt Then D := X.I Else D := X.R;
          If Y.T = vtInt Then D2 := Y.I Else D2 := Y.R;
          If D = 0 Then MkReal(0, R)
          Else If D > 0 Then MkReal(Exp(D2 * Ln(D)), R)
          Else If D2 = Int(D2) Then
          Begin
            If Trunc(D2) Mod 2 = 0 Then MkReal(Exp(D2 * Ln(-D)), R) Else MkReal(-Exp(D2 * Ln(-D)), R);
          End
          Else MkReal(0, R);
        End;
      End;
    pfIntdiv :
      Begin
        N := PInt(Arg[1]);
        If N = 0 Then VmFail('Division by zero') Else MkInt(PInt(Arg[0]) Div N, R);
      End;
    pfMax, pfMin :
      Begin
        If (Argc = 1) And PIsArr(Arg[0]) Then
        Begin
          K := PArrNext(Arg[0].I, 0);
          If K < 0 Then
          Begin
            VmFail('max()/min() : tableau vide');
            Exit;
          End;
          R := DVal^[K];
          K := PArrNext(Arg[0].I, K + 1);
          While K >= 0 Do
          Begin
            X := DVal^[K];
            If ((Id = pfMax) And (PhpCompare(X, R) > 0)) Or ((Id = pfMin) And (PhpCompare(X, R) < 0)) Then R := X;
            K := PArrNext(Arg[0].I, K + 1);
          End;
        End
        Else
        Begin
          R := Arg[0];
          For K := 1 To Argc - 1 Do
            If ((Id = pfMax) And (PhpCompare(Arg[K], R) > 0)) Or ((Id = pfMin) And (PhpCompare(Arg[K], R) < 0)) Then
              R := Arg[K];
        End;
      End;
    pfRand, pfMtRand, pfRandomInt :
      Begin
        If Argc >= 2 Then
        Begin
          A := PInt(Arg[0]); N := PInt(Arg[1]);
          If N < A Then MkInt(A, R)
          Else MkInt(A + Trunc(PRnd * (PDiff(N, A) + 1)), R);
        End
        Else MkInt(VmRand, R);
      End;
    pfMtSrand, pfSrand : ;
    pfMtGetrandmax, pfGetrandmax : MkInt(2147483647, R);
    pfPi : MkReal(Pi, R);
    pfFmod :
      Begin
        D := PReal(Arg[0]); D2 := PReal(Arg[1]);
        If D2 = 0 Then MkReal(0, R) Else MkReal(D - Int(D / D2) * D2, R);
      End;
    pfExp : MkReal(Exp(PReal(Arg[0])), R);
    pfLog, pfLog10, pfLog2 :
      Begin
        D := PReal(Arg[0]);
        If D <= 0 Then MkReal(-1.7976931348623157E308, R)
        Else If Id = pfLog10 Then MkReal(Ln(D) / Ln(10), R)
        Else If Id = pfLog2 Then MkReal(Ln(D) / Ln(2), R)
        Else If Argc > 1 Then MkReal(Ln(D) / Ln(PReal(Arg[1])), R)
        Else MkReal(Ln(D), R);
      End;
    pfSin : MkReal(Sin(PReal(Arg[0])), R);
    pfCos : MkReal(Cos(PReal(Arg[0])), R);
    pfTan : MkReal(Sin(PReal(Arg[0])) / Cos(PReal(Arg[0])), R);
    pfAtan : MkReal(ArcTan(PReal(Arg[0])), R);
    pfAsin, pfAcos :
      Begin
        D := PReal(Arg[0]);
        If Abs(D) >= 1 Then D2 := Pi / 2 * D Else D2 := ArcTan(D / Sqrt(1 - D * D));
        If Id = pfAcos Then D2 := Pi / 2 - D2;
        MkReal(D2, R);
      End;
    pfAtan2 :
      Begin
        D := PReal(Arg[0]); D2 := PReal(Arg[1]);
        If D2 > 0 Then MkReal(ArcTan(D / D2), R)
        Else If (D2 < 0) And (D >= 0) Then MkReal(ArcTan(D / D2) + Pi, R)
        Else If D2 < 0 Then MkReal(ArcTan(D / D2) - Pi, R)
        Else If D > 0 Then MkReal(Pi / 2, R)
        Else If D < 0 Then MkReal(-Pi / 2, R)
        Else MkReal(0, R);
      End;
    pfIsNan : MkBool(PReal(Arg[0]) <> PReal(Arg[0]), R);
    pfIsFinite : MkBool(Abs(PReal(Arg[0])) < 1.7E308, R);
    pfIsInfinite : MkBool(Abs(PReal(Arg[0])) >= 1.7E308, R);
    pfDeg2rad : MkReal(PReal(Arg[0]) * Pi / 180, R);
    pfRad2deg : MkReal(PReal(Arg[0]) * 180 / Pi, R);
    pfHypot : MkReal(Sqrt(Sqr(PReal(Arg[0])) + Sqr(PReal(Arg[1]))), R);
    { --- types --- }
    pfIntval :
      Begin
        If (Argc > 1) And (PInt(Arg[1]) <> 10) Then
        Begin
          MkInt(10, Arg[2]);
          PhpBuiltin(pfBaseConvert, 3, Arg, T);
          MkInt(SVal(CellPStr(T)), R);
        End
        Else
        Begin
          X := Arg[0];
          PNumCell(X, Y);
          If Y.T = vtReal Then
          Begin
            If (Y.R > 2147483647.0) Or (Y.R < -2147483648.0) Then MkInt(0, R) Else MkInt(Trunc(Y.R), R);
          End
          Else R := Y;
          If PIsArr(X) Then MkInt(Ord(DictCount(X.I) > 0), R);
        End;
      End;
    pfFloatval, pfDoubleval :
      Begin
        PNumCell(Arg[0], Y);
        If Y.T = vtInt Then MkReal(Y.I, R) Else R := Y;
      End;
    pfStrval : PStrCell(Arg[0], R);
    pfBoolval : MkBool(PBool(Arg[0]), R);
    pfGettype, pfGetDebugType :
      Begin
        X := Arg[0];
        If (X.T = vtObj) And Not PIsArr(X) Then ObjValue(X);
        If PIsArr(X) Then S := 'array'
        Else
          Case X.T Of
            vtNil : If Id = pfGettype Then S := 'NULL' Else S := 'null';
            vtInt : If Id = pfGettype Then S := 'integer' Else S := 'int';
            vtReal, vtDate : If Id = pfGettype Then S := 'double' Else S := 'float';
            vtBool : If Id = pfGettype Then S := 'boolean' Else S := 'bool';
            vtObj : S := 'object';
          Else
            S := 'string';
          End;
        MkStr(S, R);
      End;
    pfIsInt, pfIsInteger, pfIsLong : MkBool(Arg[0].T = vtInt, R);
    pfIsFloat, pfIsDouble : MkBool(Arg[0].T = vtReal, R);
    pfIsString : MkBool(IsStrCell(Arg[0]), R);
    pfIsBool : MkBool(Arg[0].T = vtBool, R);
    pfIsArray, pfIsIterable, pfIsCountable : MkBool(PIsArr(Arg[0]), R);
    pfIsNumeric : MkBool((Arg[0].T = vtInt) Or (Arg[0].T = vtReal) Or PIsNumStr(Arg[0]), R);
    pfIsNull : MkBool(Arg[0].T = vtNil, R);
    pfIsScalar : MkBool(Arg[0].T In [vtInt, vtReal, vtBool, vtStr, vtKStr, vtChar], R);
    pfIsObject : MkBool((Arg[0].T = vtObj) And Not PIsArr(Arg[0]), R);
    pfVarDump :
      Begin
        For K := 0 To Argc - 1 Do PVarDump(Arg[K], 0, B);
        BufAddB(VmOut, B.P, B.Len);
        If B.Len > 0 Then VmHdrPending := False;
        BufFree(B);
      End;
    pfPrintR, pfVarExport :
      Begin
        If Id = pfPrintR Then PPrintR(Arg[0], 0, B) Else PVarExport(Arg[0], 0, B);
        If (Argc > 1) And PBool(Arg[1]) Then PRet(B, R)
        Else
        Begin
          BufAddB(VmOut, B.P, B.Len);
          If B.Len > 0 Then VmHdrPending := False;
          BufFree(B);
          If Id = pfPrintR Then MkBool(True, R);
        End;
      End;
    { --- tableaux --- }
    pfCount, pfSizeof :
      If PIsArr(Arg[0]) Then
      Begin
        If (Argc > 1) And (PInt(Arg[1]) = 1) Then
        Begin
          { recursif }
          N := 0;
          Ob := Arg[0].I;
          K := PArrNext(Ob, 0);
          While K >= 0 Do
          Begin
            Inc(N);
            X := DVal^[K];
            If PIsArr(X) Then
            Begin
              Arg[0] := X;
              PhpBuiltin(pfCount, 2, Arg, T);
              N := N + T.I;
            End;
            K := PArrNext(Ob, K + 1);
          End;
          MkInt(N, R);
        End
        Else MkInt(DictCount(Arg[0].I), R);
      End
      Else If Arg[0].T = vtNil Then MkInt(0, R)
      Else If (Arg[0].T = vtObj) And (Arg[0].I < NObj) And (ObjK[Arg[0].I] = okDbRs) And (ObjA[Arg[0].I] >= 0) Then
        MkInt(Rss[ObjA[Arg[0].I]].NRow, R)
      Else MkInt(1, R);
    pfArrayKeys, pfArrayValues :
      Begin
        A := PArrArg(Arg[0], 'array_keys');
        If A < 0 Then Exit;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          If Id = pfArrayKeys Then
          Begin
            X := DVal^[K];
            If (Argc < 2) Or (PhpCompare(X, Arg[1]) = 0) Then
            Begin
              X := DKey^[K];
              PArrPush(Ob, X);
            End;
          End
          Else
          Begin
            X := DVal^[K];
            PArrPush(Ob, X);
          End;
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfInArray, pfArraySearch :
      Begin
        A := PArrArg(Arg[1], 'in_array');
        If A < 0 Then Exit;
        K := PArrSearch(A, Arg[0], (Argc > 2) And PBool(Arg[2]));
        If Id = pfInArray Then MkBool(K >= 0, R)
        Else If K >= 0 Then R := DKey^[K]
        Else MkBool(False, R);
      End;
    pfArrayKeyExists, pfKeyExists :
      If PIsArr(Arg[1]) Then MkBool(PArrFind(Arg[1].I, Arg[0]) >= 0, R)
      Else If Arg[1].T = vtObj Then
      Begin
        PGetElem(Arg[1], Arg[0], -1, T);
        MkBool(T.T <> vtNil, R);
      End
      Else MkBool(False, R);
    pfArrayMerge, pfArrayReplace :
      Begin
        Ob := PArrNew;
        For J := 0 To Argc - 1 Do
          If PIsArr(Arg[J]) Then
          Begin
            K := PArrNext(Arg[J].I, 0);
            While K >= 0 Do
            Begin
              X := DVal^[K];
              If (DKey^[K].T = vtInt) And (Id = pfArrayMerge) Then PArrPush(Ob, X)
              Else PArrSet(Ob, DKey^[K], X);
              K := PArrNext(Arg[J].I, K + 1);
            End;
          End;
        MkObj(Ob, R);
      End;
    pfArrayPush :
      Begin
        A := PArrArg(Arg[0], 'array_push');
        If A < 0 Then Exit;
        For K := 1 To Argc - 1 Do PArrPush(A, Arg[K]);
        MkInt(DictCount(A), R);
      End;
    pfArrayPop, pfArrayShift :
      Begin
        A := PArrArg(Arg[0], 'array_pop');
        If A < 0 Then Exit;
        If Id = pfArrayPop Then K := PArrLast(A) Else K := PArrNext(A, 0);
        If K >= 0 Then
        Begin
          R := DVal^[K];
          DObj^[K] := -1;
          If Id = pfArrayShift Then PArrRenumber(A)
          Else
          Begin
            { prochain indice : le plus grand + 1 }
            ObjA[A] := 0;
            J := PArrNext(A, 0);
            While J >= 0 Do
            Begin
              If (DKey^[J].T = vtInt) And (DKey^[J].I >= ObjA[A]) Then ObjA[A] := DKey^[J].I + 1;
              J := PArrNext(A, J + 1);
            End;
          End;
        End;
      End;
    pfArrayUnshift :
      Begin
        A := PArrArg(Arg[0], 'array_unshift');
        If A < 0 Then Exit;
        { nouvelles entrees : les valeurs puis les anciennes (meme objet) }
        Ob := PArrCopy(A);
        For K := 0 To NDict - 1 Do If DObj^[K] = A Then DObj^[K] := -1;
        ObjA[A] := 0;
        For K := 1 To Argc - 1 Do PArrPush(A, Arg[K]);
        K := PArrNext(Ob, 0);
        While K >= 0 Do
        Begin
          X := DVal^[K];
          If DKey^[K].T = vtInt Then PArrPush(A, X) Else PArrSet(A, DKey^[K], X);
          K := PArrNext(Ob, K + 1);
        End;
        MkInt(DictCount(A), R);
      End;
    pfArraySlice, pfArraySplice :
      Begin
        A := PArrArg(Arg[0], 'array_slice');
        If A < 0 Then Exit;
        N := DictCount(A);
        St := PInt(Arg[1]);
        If St < 0 Then St := N + St;
        If St < 0 Then St := 0;
        If (Argc > 2) And (Arg[2].T <> vtNil) Then
        Begin
          Len := PInt(Arg[2]);
          If Len < 0 Then Len := N - St + Len;
        End
        Else Len := N - St;
        If Len < 0 Then Len := 0;
        Ok := (Id = pfArraySlice) And (Argc > 3) And PBool(Arg[3]);
        Ob := PArrNew;
        I := 0;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          If (I >= St) And (I < St + Len) Then
          Begin
            X := DVal^[K];
            If (DKey^[K].T = vtInt) And Not Ok Then PArrPush(Ob, X) Else PArrSet(Ob, DKey^[K], X);
            If Id = pfArraySplice Then DObj^[K] := -1;
          End;
          Inc(I);
          K := PArrNext(A, K + 1);
        End;
        If Id = pfArraySplice Then
        Begin
          { remplacement : insere a la place (reconstruit le tableau) }
          If Argc > 3 Then
          Begin
            Ob2 := PArrCopy(A);
            For K := 0 To NDict - 1 Do If DObj^[K] = A Then DObj^[K] := -1;
            ObjA[A] := 0;
            I := 0;
            K := PArrNext(Ob2, 0);
            Ok := False;
            While (K >= 0) Or Not Ok Do
            Begin
              If (I = St) And Not Ok Then
              Begin
                If PIsArr(Arg[3]) Then
                Begin
                  J := PArrNext(Arg[3].I, 0);
                  While J >= 0 Do
                  Begin
                    X := DVal^[J];
                    PArrPush(A, X);
                    J := PArrNext(Arg[3].I, J + 1);
                  End;
                End
                Else PArrPush(A, Arg[3]);
                Ok := True;
              End;
              If K < 0 Then Break;
              X := DVal^[K];
              If DKey^[K].T = vtInt Then PArrPush(A, X) Else PArrSet(A, DKey^[K], X);
              Inc(I);
              K := PArrNext(Ob2, K + 1);
            End;
          End
          Else PArrRenumber(A);
        End;
        MkObj(Ob, R);
      End;
    pfArrayReverse :
      Begin
        A := PArrArg(Arg[0], 'array_reverse');
        If A < 0 Then Exit;
        Ob := PArrNew;
        K := PArrLast(A);
        While K >= 0 Do
        Begin
          X := DVal^[K];
          If (DKey^[K].T = vtInt) And Not ((Argc > 1) And PBool(Arg[1])) Then PArrPush(Ob, X)
          Else PArrSet(Ob, DKey^[K], X);
          J := K - 1;
          K := -1;
          While J >= 0 Do
          Begin
            If DObj^[J] = A Then
            Begin
              K := J;
              Break;
            End;
            Dec(J);
          End;
        End;
        MkObj(Ob, R);
      End;
    pfArraySum, pfArrayProduct :
      Begin
        A := PArrArg(Arg[0], 'array_sum');
        If A < 0 Then Exit;
        If Id = pfArraySum Then MkInt(0, R) Else MkInt(1, R);
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          X := DVal^[K];
          T := R;
          If Id = pfArraySum Then PhpArith(opAdd, T, X, R) Else PhpArith(opMul, T, X, R);
          K := PArrNext(A, K + 1);
        End;
      End;
    pfSort, pfRsort, pfAsort, pfArsort, pfKsort, pfKrsort :
      Begin
        A := PArrArg(Arg[0], 'sort');
        If A < 0 Then Exit;
        If Argc > 1 Then N := PInt(Arg[1]) Else N := 0;
        PSortArr(A, (Id = pfKsort) Or (Id = pfKrsort), (Id = pfRsort) Or (Id = pfArsort) Or (Id = pfKrsort),
                 (Id = pfSort) Or (Id = pfRsort), N);
        MkBool(True, R);
      End;
    pfArrayUnique :
      Begin
        A := PArrArg(Arg[0], 'array_unique');
        If A < 0 Then Exit;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          X := DVal^[K];
          PStrCell(X, T);
          Ok := True;
          J := PArrNext(Ob, 0);
          While J >= 0 Do
          Begin
            PStrCell(DVal^[J], T2);
            If StrCmpCells(T, T2, False) = 0 Then
            Begin
              Ok := False;
              Break;
            End;
            J := PArrNext(Ob, J + 1);
          End;
          If Ok Then PArrSet(Ob, DKey^[K], X);
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfArrayFlip :
      Begin
        A := PArrArg(Arg[0], 'array_flip');
        If A < 0 Then Exit;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          X := DKey^[K];
          PArrSet(Ob, DVal^[K], X);
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfArrayFill :
      Begin
        Ob := PArrNew;
        St := PInt(Arg[0]);
        For K := 0 To PInt(Arg[1]) - 1 Do
        Begin
          MkInt(St + K, Kc);
          PArrSet(Ob, Kc, Arg[2]);
        End;
        MkObj(Ob, R);
      End;
    pfArrayFillKeys :
      Begin
        A := PArrArg(Arg[0], 'array_fill_keys');
        If A < 0 Then Exit;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          PArrSet(Ob, DVal^[K], Arg[1]);
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfRange :
      Begin
        Ob := PArrNew;
        If IsStrCell(Arg[0]) And IsStrCell(Arg[1]) And Not PIsNumStr(Arg[0]) And (CellLen(Arg[0]) = 1) Then
        Begin
          { range('a', 'e') }
          PStrCell(Arg[0], T); PStrCell(Arg[1], T2);
          A := PoolPtr(T)^[0]; N := PoolPtr(T2)^[0];
          If Argc > 2 Then M := Abs(PInt(Arg[2])) Else M := 1;
          If M = 0 Then M := 1;
          K := A;
          While ((A <= N) And (K <= N)) Or ((A > N) And (K >= N)) Do
          Begin
            S := Chr(K);
            MkStr(S, X);
            PArrPush(Ob, X);
            If A <= N Then K := K + M Else K := K - M;
          End;
        End
        Else
        Begin
          PNumCell(Arg[0], X); PNumCell(Arg[1], Y);
          If Argc > 2 Then PNumCell(Arg[2], T) Else MkInt(1, T);
          If (X.T = vtInt) And (Y.T = vtInt) And (T.T = vtInt) Then
          Begin
            M := Abs(T.I);
            If M = 0 Then M := 1;
            K := X.I;
            While ((X.I <= Y.I) And (K <= Y.I)) Or ((X.I > Y.I) And (K >= Y.I)) Do
            Begin
              MkInt(K, T2);
              PArrPush(Ob, T2);
              If X.I <= Y.I Then K := K + M Else K := K - M;
              If DictCount(Ob) > 100000 Then Break;
            End;
          End
          Else
          Begin
            D := PReal(X); D2 := PReal(Y);
            If T.T = vtInt Then Y.R := Abs(T.I) Else Y.R := Abs(T.R);
            If Y.R = 0 Then Y.R := 1;
            N := 0;
            While ((D <= D2) And (D + N * Y.R <= D2 + 1E-9)) Or ((D > D2) And (D - N * Y.R >= D2 - 1E-9)) Do
            Begin
              If D <= D2 Then MkReal(D + N * Y.R, T2) Else MkReal(D - N * Y.R, T2);
              PArrPush(Ob, T2);
              Inc(N);
              If N > 100000 Then Break;
            End;
          End;
        End;
        MkObj(Ob, R);
      End;
    pfArrayCombine :
      Begin
        A := PArrArg(Arg[0], 'array_combine');
        If (A < 0) Or Not PIsArr(Arg[1]) Then Exit;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        J := PArrNext(Arg[1].I, 0);
        While (K >= 0) And (J >= 0) Do
        Begin
          X := DVal^[J];
          PArrSet(Ob, DVal^[K], X);
          K := PArrNext(A, K + 1);
          J := PArrNext(Arg[1].I, J + 1);
        End;
        MkObj(Ob, R);
      End;
    pfArrayColumn :
      Begin
        A := PArrArg(Arg[0], 'array_column');
        If A < 0 Then Exit;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          X := DVal^[K];
          If PIsArr(X) Then
          Begin
            If Arg[1].T = vtNil Then Y := X Else PArrGet(X.I, Arg[1], Y);
            If (Argc > 2) And (Arg[2].T <> vtNil) Then
            Begin
              PArrGet(X.I, Arg[2], T);
              PArrSet(Ob, T, Y);
            End
            Else If (Arg[1].T = vtNil) Or (PArrFind(X.I, Arg[1]) >= 0) Then PArrPush(Ob, Y);
          End;
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfArrayRand :
      Begin
        A := PArrArg(Arg[0], 'array_rand');
        If A < 0 Then Exit;
        N := DictCount(A);
        If N = 0 Then Exit;
        K := PArrNth(A, Trunc(PRnd * N));
        If K >= 0 Then R := DKey^[K];
      End;
    pfShuffle :
      Begin
        A := PArrArg(Arg[0], 'shuffle');
        If A < 0 Then Exit;
        N := DictCount(A);
        For I := N - 1 DownTo 1 Do
        Begin
          J := Trunc(PRnd * (I + 1));
          K := PArrNth(A, I); M := PArrNth(A, J);
          X := DVal^[K]; DVal^[K] := DVal^[M]; DVal^[M] := X;
        End;
        PArrRenumber(A);
        MkBool(True, R);
      End;
    pfArrayCountValues :
      Begin
        A := PArrArg(Arg[0], 'array_count_values');
        If A < 0 Then Exit;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          PArrGet(Ob, DVal^[K], X);
          MkInt(CellInt(X) + 1, X);
          PArrSet(Ob, DVal^[K], X);
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfArrayKeyFirst, pfArrayKeyLast :
      Begin
        A := PArrArg(Arg[0], 'array_key_first');
        If A < 0 Then Exit;
        If Id = pfArrayKeyFirst Then K := PArrNext(A, 0) Else K := PArrLast(A);
        If K >= 0 Then R := DKey^[K];
      End;
    pfArrayFilter :
      Begin
        A := PArrArg(Arg[0], 'array_filter');
        If A < 0 Then Exit;
        If Argc > 1 Then
        Begin
          VmFail('array_filter() : fonction de rappel non prise en charge');
          Exit;
        End;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          X := DVal^[K];
          If PBool(X) Then PArrSet(Ob, DKey^[K], X);
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfArrayPad :
      Begin
        A := PArrArg(Arg[0], 'array_pad');
        If A < 0 Then Exit;
        N := PInt(Arg[1]);
        Ob := PArrNew;
        M := DictCount(A);
        If N < 0 Then For K := 1 To -N - M Do PArrPush(Ob, Arg[2]);
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          X := DVal^[K];
          If DKey^[K].T = vtInt Then PArrPush(Ob, X) Else PArrSet(Ob, DKey^[K], X);
          K := PArrNext(A, K + 1);
        End;
        If N > 0 Then For K := 1 To N - M Do PArrPush(Ob, Arg[2]);
        MkObj(Ob, R);
      End;
    pfArrayChunk :
      Begin
        A := PArrArg(Arg[0], 'array_chunk');
        If A < 0 Then Exit;
        N := PInt(Arg[1]);
        If N < 1 Then N := 1;
        Ob := PArrNew;
        Ob2 := -1;
        I := 0;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          If I Mod N = 0 Then
          Begin
            Ob2 := PArrNew;
            MkObj(Ob2, T);
            PArrPush(Ob, T);
          End;
          X := DVal^[K];
          If (Argc > 2) And PBool(Arg[2]) Then PArrSet(Ob2, DKey^[K], X) Else PArrPush(Ob2, X);
          Inc(I);
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfArrayDiff, pfArrayDiffKey, pfArrayIntersect, pfArrayIntersectKey :
      Begin
        A := PArrArg(Arg[0], 'array_diff');
        If A < 0 Then Exit;
        Ob := PArrNew;
        K := PArrNext(A, 0);
        While K >= 0 Do
        Begin
          { present dans tous (intersect) / dans aucun (diff) des autres }
          N := 0;
          For J := 1 To Argc - 1 Do
            If PIsArr(Arg[J]) Then
            Begin
              If (Id = pfArrayDiffKey) Or (Id = pfArrayIntersectKey) Then
              Begin
                If PArrFind(Arg[J].I, DKey^[K]) >= 0 Then Inc(N);
              End
              Else
              Begin
                PStrCell(DVal^[K], T);
                M := PArrNext(Arg[J].I, 0);
                While M >= 0 Do
                Begin
                  PStrCell(DVal^[M], T2);
                  If StrCmpCells(T, T2, False) = 0 Then
                  Begin
                    Inc(N);
                    Break;
                  End;
                  M := PArrNext(Arg[J].I, M + 1);
                End;
              End;
            End;
          If ((Id = pfArrayDiff) Or (Id = pfArrayDiffKey)) And (N = 0) Or
             ((Id = pfArrayIntersect) Or (Id = pfArrayIntersectKey)) And (N = Argc - 1) Then
          Begin
            X := DVal^[K];
            PArrSet(Ob, DKey^[K], X);
          End;
          K := PArrNext(A, K + 1);
        End;
        MkObj(Ob, R);
      End;
    pfArrayIsList : If PIsArr(Arg[0]) Then MkBool(PIsList(Arg[0].I), R) Else MkBool(False, R);
    pfReset, pfEnd, pfCurrent, pfKey, pfNext, pfPrev :
      Begin
        A := PArrArg(Arg[0], 'reset');
        If A < 0 Then Exit;
        { pointeur interne : ObjB (indice brut) }
        Case Id Of
          pfReset : ObjB[A] := PArrNext(A, 0);
          pfEnd : ObjB[A] := PArrLast(A);
          pfNext : If ObjB[A] >= 0 Then ObjB[A] := PArrNext(A, ObjB[A] + 1);
          pfPrev :
            Begin
              K := ObjB[A] - 1;
              ObjB[A] := -1;
              While K >= 0 Do
              Begin
                If DObj^[K] = A Then
                Begin
                  ObjB[A] := K;
                  Break;
                End;
                Dec(K);
              End;
            End;
          pfCurrent, pfKey :
            If (ObjB[A] = 0) And (PArrNext(A, 0) > 0) Then ObjB[A] := PArrNext(A, 0);
        End;
        K := ObjB[A];
        If (K < 0) Or (K >= NDict) Or (DObj^[K] <> A) Then
        Begin
          If Id = pfKey Then MkNil(R) Else MkBool(False, R);
        End
        Else If Id = pfKey Then R := DKey^[K]
        Else R := DVal^[K];
      End;
    { --- dates --- }
    pfDate, pfGmdate :
      Begin
        If Argc > 1 Then K := PInt(Arg[1]) Else K := NowUnix;
        PStrCell(Arg[0], T);
        PDate(T, K, B);
        PRet(B, R);
      End;
    pfTime : MkInt(NowUnix, R);
    pfMktime, pfGmmktime :
      Begin
        UnixSplit(NowUnix, Y_, Mo_, D_, H_, Mi_, Sc_, Wd_);
        If Argc > 0 Then H_ := PInt(Arg[0]);
        If Argc > 1 Then Mi_ := PInt(Arg[1]);
        If Argc > 2 Then Sc_ := PInt(Arg[2]);
        If Argc > 3 Then Mo_ := PInt(Arg[3]);
        If Argc > 4 Then D_ := PInt(Arg[4]);
        If Argc > 5 Then Y_ := PInt(Arg[5]);
        MkInt(PMkTime(H_, Mi_, Sc_, Mo_, D_, Y_), R);
      End;
    pfStrtotime :
      Begin
        If Argc > 1 Then N := PInt(Arg[1]) Else N := NowUnix;
        If PStrToTime(ArgPStr(Arg[0]), N, K) Then MkInt(K, R) Else MkBool(False, R);
      End;
    pfCheckdate :
      Begin
        Mo_ := PInt(Arg[0]); D_ := PInt(Arg[1]); Y_ := PInt(Arg[2]);
        MkBool((Mo_ >= 1) And (Mo_ <= 12) And (D_ >= 1) And (Y_ >= 1) And (D_ <= PDaysIn(Mo_, Y_)), R);
      End;
    pfDateDefaultTimezoneSet : MkBool(True, R);
    pfDateDefaultTimezoneGet : MkStr('UTC', R);
    pfMicrotime :
      Begin
        D := NowUnix + (PTicks Mod 1000) / 1000.0;
        If (Argc > 0) And PBool(Arg[0]) Then MkReal(D, R)
        Else MkStr('0.' + Copy(IStr(1000 + PTicks Mod 1000), 2, 3) + '00000 ' + IStr(NowUnix), R);
      End;
    pfHrtime :
      Begin
        If (Argc > 0) And PBool(Arg[0]) Then MkReal(PDiff(PTicks, 0) * 1000000.0, R)
        Else
        Begin
          Ob := PArrNew;
          MkInt(PTicks Div 1000, X); PArrPush(Ob, X);
          MkInt((PTicks Mod 1000) * 1000000, X); PArrPush(Ob, X);
          MkObj(Ob, R);
        End;
      End;
    pfIdate :
      Begin
        PStrCell(Arg[0], T);
        If Argc > 1 Then K := PInt(Arg[1]) Else K := NowUnix;
        PDate(T, K, B);
        S := '';
        For K := 0 To B.Len - 1 Do If Length(S) < 20 Then S := S + Chr(B.P^[K]);
        MkInt(SVal(S), R);
        BufFree(B);
      End;
    { --- reponse, session, divers --- }
    pfHeader :
      Begin
        S := ArgPStr(Arg[0]);
        If UpStr(Copy(S, 1, 5)) = 'HTTP/' Then
        Begin
          K := Pos(' ', S);
          VmStatus := Copy(S, K + 1, 63);
          If VmOut.Len = 0 Then VmHdrPending := True;
        End
        Else
        Begin
          K := Pos(':', S);
          S2 := Trim(Copy(S, 1, K - 1)); S3 := Trim(Copy(S, K + 1, 255));
          If UpStr(S2) = 'LOCATION' Then
          Begin
            If (Copy(VmStatus, 1, 1) <> '3') Then VmStatus := '302 Found';
            VmPendLoc := S3;
            AddHdr('Location', S3);
          End
          Else If UpStr(S2) = 'CONTENT-TYPE' Then
          Begin
            VmCType := S3;
            If VmOut.Len = 0 Then VmHdrPending := True;
          End
          Else If K > 0 Then AddHdr(S2, S3);
        End;
        If (Argc > 2) And (PInt(Arg[2]) > 0) Then VmStatus := IStr(PInt(Arg[2])) + Copy(VmStatus, 4, 60);
      End;
    pfHeadersSent : MkBool(False, R);
    pfHttpResponseCode :
      Begin
        MkInt(SVal(Copy(VmStatus, 1, 3)), R);
        If (Argc > 0) And (PInt(Arg[0]) > 0) Then
        Begin
          N := PInt(Arg[0]);
          Case N Of
            200 : S := 'OK'; 201 : S := 'Created'; 204 : S := 'No Content'; 301 : S := 'Moved Permanently';
            302 : S := 'Found'; 303 : S := 'See Other'; 304 : S := 'Not Modified'; 400 : S := 'Bad Request';
            401 : S := 'Unauthorized'; 403 : S := 'Forbidden'; 404 : S := 'Not Found'; 405 : S := 'Method Not Allowed';
            500 : S := 'Internal Server Error'; 503 : S := 'Service Unavailable';
          Else
            S := 'Status';
          End;
          VmStatus := IStr(N) + ' ' + S;
          If VmOut.Len = 0 Then VmHdrPending := True;
        End;
      End;
    pfSetcookie :
      Begin
        S := ArgPStr(Arg[0]) + '=';
        If Argc > 1 Then
        Begin
          PStrCell(Arg[1], T);
          S := S + UrlEncode(CellPStr(T));
        End;
        If (Argc > 2) And (PInt(Arg[2]) > 0) Then S := S + '; expires=' + HttpDate(PInt(Arg[2]));
        If (Argc > 3) And (CellLen(Arg[3]) > 0) Then S := S + '; path=' + ArgPStr(Arg[3]) Else S := S + '; path=/';
        If (Argc > 4) And (CellLen(Arg[4]) > 0) Then S := S + '; domain=' + ArgPStr(Arg[4]);
        If (Argc > 5) And PBool(Arg[5]) Then S := S + '; secure';
        If (Argc > 6) And PBool(Arg[6]) Then S := S + '; HttpOnly';
        AddHdr('Set-Cookie', S);
        MkBool(True, R);
      End;
    pfSessionStart, pfSessionRegenerateId :
      Begin
        SessEnsure;
        MkBool(True, R);
      End;
    pfSessionId :
      Begin
        SessEnsure;
        MkStr(Sess[VmSess].Id, R);
      End;
    pfSessionDestroy, pfSessionUnset :
      Begin
        SessEnsure;
        For K := 0 To Sess[VmSess].N - 1 Do PVarFree(Sess[VmSess].V[K]);
        Sess[VmSess].N := 0;
        If Id = pfSessionDestroy Then Sess[VmSess].Timeout := 0;
        MkBool(True, R);
      End;
    pfSessionStatus : MkInt(2, R);
    pfPhpversion : MkStr('8.2.0', R);
    pfPhpUname : MkStr('OS/2-0 ' + ServerName, R);
    pfPhpSapiName : MkStr('os2-0', R);
    pfErrorReporting : MkInt(32767, R);
    pfIniSet, pfIniGet, pfSetTimeLimit : MkBool(False, R);
    pfObStart :
      Begin
        If PNOb < 8 Then
        Begin
          PObMark[PNOb] := VmOut.Len;
          Inc(PNOb);
        End;
        MkBool(True, R);
      End;
    pfObGetClean, pfObGetContents, pfObEndClean, pfObEndFlush :
      If PNOb > 0 Then
      Begin
        K := PObMark[PNOb - 1];
        If (Id = pfObGetClean) Or (Id = pfObGetContents) Then MkStrB(@VmOut.P^[K], VmOut.Len - K, R)
        Else MkBool(True, R);
        If (Id = pfObGetClean) Or (Id = pfObEndClean) Then VmOut.Len := K;
        If Id <> pfObGetContents Then Dec(PNOb);
      End
      Else MkBool(False, R);
    pfObGetLevel : MkInt(PNOb, R);
    pfUsleep, pfSleep, pfFlush, pfGcCollectCycles : MkInt(0, R);
    pfGetenv : If Argc > 0 Then MkStr(PEnv(ArgPStr(Arg[0])), R) Else MkObj(PArrNew, R);
    pfGethostname : MkStr(ServerName, R);
    pfErrorLog :
      Begin
        SysLog('PHP : ' + ArgPStr(Arg[0]));
        MkBool(True, R);
      End;
    pfTriggerError :
      Begin
        If Argc > 1 Then N := PInt(Arg[1]) Else N := 1024;
        If N = 256 Then VmFail(ArgPStr(Arg[0]))
        Else
        Begin
          If N = 512 Then S := 'Warning' Else If N = 8192 Then S := 'Deprecated' Else S := 'Notice';
          PStrCell(Arg[0], T);
          BufAdd(VmOut, #10 + '<br />' + #10 + '<b>' + S + '</b>:  ');
          BufAddB(VmOut, PoolPtr(T), T.L);
          BufAdd(VmOut, '<br />' + #10);
          VmHdrPending := False;
          MkBool(True, R);
        End;
      End;
    pfMail : MkBool(False, R);
    pfMemoryGetUsage, pfMemoryGetPeakUsage : MkInt(VmPool.Len + NDict * 32 + 2097152, R);
    { --- fichiers --- }
    pfFileExists, pfIsFile, pfIsDir, pfIsReadable, pfIsWritable, pfFilesize, pfFilemtime :
      Begin
        S := PPath(ArgPStr(Arg[0]));
        Ok := PStat(S, N, M, NoCase);
        Case Id Of
          pfFileExists, pfIsReadable, pfIsWritable : MkBool(Ok, R);
          pfIsFile : MkBool(Ok And Not NoCase, R);
          pfIsDir : MkBool(Ok And NoCase, R);
          pfFilesize : If Ok Then MkInt(N, R) Else MkBool(False, R);
          pfFilemtime : If Ok Then MkInt(M, R) Else MkBool(False, R);
        End;
      End;
    pfFileGetContents, pfFile :
      Begin
        S := ArgPStr(Arg[0]);
        If Pos('://', S) > 0 Then
        Begin
          MkBool(False, R);
          Exit;
        End;
        If Not ReadFileBuf(PPath(S), B, 33554432) Then
        Begin
          MkBool(False, R);
          Exit;
        End;
        If Id = pfFileGetContents Then PRet(B, R)
        Else
        Begin
          If Argc > 1 Then M := PInt(Arg[1]) Else M := 0;
          Ob := PArrNew;
          St := 0;
          For K := 0 To B.Len Do
            If (K = B.Len) Or (B.P^[K] = 10) Then
            Begin
              If K = B.Len Then N := K Else N := K + 1;
              If (M And 2) <> 0 Then
              Begin
                Len := K - St;
                If (Len > 0) And (K > 0) And (B.P^[K - 1] = 13) And (K < B.Len) Then Dec(Len);
              End
              Else Len := N - St;
              If (St < B.Len) And Not (((M And 4) <> 0) And (Len = 0)) Then
              Begin
                MkStrB(@B.P^[St], Len, X);
                PArrPush(Ob, X);
              End;
              St := K + 1;
            End;
          BufFree(B);
          MkObj(Ob, R);
        End;
      End;
    pfFilePutContents :
      Begin
        S := PPath(ArgPStr(Arg[0]));
        If PIsArr(Arg[1]) Then
        Begin
          K := PArrNext(Arg[1].I, 0);
          While K >= 0 Do
          Begin
            X := DVal^[K];
            PAddCell(B, X);
            K := PArrNext(Arg[1].I, K + 1);
          End;
        End
        Else PAddCell(B, Arg[1]);
        Ok := (Argc > 2) And ((PInt(Arg[2]) And 8) <> 0);
        If POpenWrite(S, Ok, N) Then
        Begin
          If B.Len > 0 Then Dummy := PWrite(N, B.P, B.Len);
          PClose(N);
          MkInt(B.Len, R);
        End
        Else MkBool(False, R);
        BufFree(B);
      End;
    pfBasename, pfDirname :
      Begin
        S := ArgPStr(Arg[0]);
        While (Length(S) > 1) And (S[Length(S)] In ['/', '\']) Do Delete(S, Length(S), 1);
        K := Length(S);
        While (K > 0) And Not (S[K] In ['/', '\']) Do Dec(K);
        If Id = pfBasename Then
        Begin
          S := Copy(S, K + 1, 255);
          If (Argc > 1) And (Copy(S, Length(S) - CellLen(Arg[1]) + 1, 255) = ArgPStr(Arg[1])) Then
            S := Copy(S, 1, Length(S) - CellLen(Arg[1]));
        End
        Else If K = 0 Then S := '.'
        Else If K = 1 Then S := Copy(S, 1, 1)
        Else S := Copy(S, 1, K - 1);
        MkStr(S, R);
      End;
    pfPathinfo :
      Begin
        S := ArgPStr(Arg[0]);
        Ob := PArrNew;
        K := Length(S);
        While (K > 0) And Not (S[K] In ['/', '\']) Do Dec(K);
        If K > 0 Then
        Begin
          MkStr(Copy(S, 1, K - 1), X);
          PSetStrKey(Ob, 'dirname', X);
        End;
        S2 := Copy(S, K + 1, 255);
        MkStr(S2, X);
        PSetStrKey(Ob, 'basename', X);
        J := Length(S2);
        While (J > 0) And (S2[J] <> '.') Do Dec(J);
        If J > 0 Then
        Begin
          MkStr(Copy(S2, J + 1, 255), X);
          PSetStrKey(Ob, 'extension', X);
          MkStr(Copy(S2, 1, J - 1), X);
        End
        Else MkStr(S2, X);
        PSetStrKey(Ob, 'filename', X);
        MkObj(Ob, R);
      End;
    pfRealpath :
      Begin
        S := PPath(ArgPStr(Arg[0]));
        If PExists(S) Then MkStr(S, R) Else MkBool(False, R);
      End;
    pfUnlink : MkBool(PDelete(PPath(ArgPStr(Arg[0]))), R);
    pfMkdir :
      Begin
        S := PPath(ArgPStr(Arg[0]));
        PMkDir(S);
        MkBool(PExists(S), R);
      End;
    pfRmdir : MkBool(False, R);
    pfScandir, pfGlob :
      Begin
        S := ArgPStr(Arg[0]);
        S2 := '*';
        If Id = pfGlob Then
        Begin
          K := Length(S);
          While (K > 0) And Not (S[K] In ['/', '\']) Do Dec(K);
          S2 := Copy(S, K + 1, 255);
          S3 := Copy(S, 1, K);
          If K > 0 Then S := Copy(S, 1, K - 1) Else S := '.';
        End;
        Ob := PArrNew;
        If Id = pfScandir Then
        Begin
          MkStr('.', X); PArrPush(Ob, X);
          MkStr('..', X); PArrPush(Ob, X);
        End;
        If PFindFirst(PPath(S), S, N, M, NoCase) Then
        Begin
          Repeat
            If (S <> '.') And (S <> '..') And PWild(S2, S) Then
            Begin
              If Id = pfGlob Then MkStr(S3 + S, X) Else MkStr(S, X);
              PArrPush(Ob, X);
            End;
          Until Not PFindNext(S, N, M, NoCase);
          PFindClose;
        End;
        PSortArr(Ob, False, False, True, 2);
        MkObj(Ob, R);
      End;
    pfFopen :
      Begin
        S := ArgPStr(Arg[0]);
        S2 := LoStr(ArgPStr(Arg[1]));
        K := -1;
        For J := 15 DownTo 0 Do If Not PFhUsed[J] Then K := J;
        If (K < 0) Or (Pos('://', S) > 0) Then
        Begin
          MkBool(False, R);
          Exit;
        End;
        S := PPath(S);
        BufInit(PFhBuf[K]);
        PFhPos[K] := 0;
        If (S2 <> '') And (S2[1] = 'r') Then
        Begin
          If Not ReadFileBuf(S, PFhBuf[K], 33554432) Then
          Begin
            MkBool(False, R);
            Exit;
          End;
          PFhMode[K] := 0;
        End
        Else
        Begin
          If Not POpenWrite(S, (S2 <> '') And (S2[1] = 'a'), N) Then
          Begin
            MkBool(False, R);
            Exit;
          End;
          PFhH[K] := N;
          PFhMode[K] := 1;
        End;
        PFhUsed[K] := True;
        MkInt(K + 1, R);
      End;
    pfFgets, pfFgetc, pfFeof :
      Begin
        K := PInt(Arg[0]) - 1;
        If (K < 0) Or (K > 15) Or Not PFhUsed[K] Or (PFhMode[K] <> 0) Then
        Begin
          MkBool(Id = pfFeof, R);
          Exit;
        End;
        If Id = pfFeof Then MkBool(PFhPos[K] >= PFhBuf[K].Len, R)
        Else If PFhPos[K] >= PFhBuf[K].Len Then MkBool(False, R)
        Else
        Begin
          St := PFhPos[K];
          J := St;
          If Id = pfFgets Then
          Begin
            While (J < PFhBuf[K].Len) And (PFhBuf[K].P^[J] <> 10) Do Inc(J);
            If J < PFhBuf[K].Len Then Inc(J);
          End
          Else Inc(J);
          MkStrB(@PFhBuf[K].P^[St], J - St, R);
          PFhPos[K] := J;
        End;
      End;
    pfFwrite, pfFputs :
      Begin
        K := PInt(Arg[0]) - 1;
        If (K < 0) Or (K > 15) Or Not PFhUsed[K] Or (PFhMode[K] <> 1) Then
        Begin
          MkBool(False, R);
          Exit;
        End;
        PStrCell(Arg[1], T);
        If T.L > 0 Then Dummy := PWrite(PFhH[K], PoolPtr(T), T.L);
        MkInt(T.L, R);
      End;
    pfFclose :
      Begin
        K := PInt(Arg[0]) - 1;
        If (K >= 0) And (K <= 15) And PFhUsed[K] Then
        Begin
          If PFhMode[K] = 1 Then PClose(PFhH[K]);
          BufFree(PFhBuf[K]);
          PFhUsed[K] := False;
        End;
        MkBool(True, R);
      End;
    pfFileExt : ;
    { --- bases de donnees --- }
    pfMysqliConnstr : MkStr(PConnMy(Arg, Argc), R);
    pfPgConnect : MkStr(PConnPg(ArgPStr(Arg[0])), R);
    pfPdoConnstr : MkStr(PConnPdo(Arg, Argc), R);
    pfMysqliError, pfMysqliConnectError, pfPgLastError : MkStr('', R);
    pfMysqliErrno, pfMysqliConnectErrno, pfPgConnectionStatus : MkInt(0, R);
    pfMysqliSetCharset, pfMysqliSelectDb : MkBool(True, R);
    pfPgEscapeString, pfPgEscapeLiteral :
      Begin
        T := Arg[Argc - 1];
        If Id = pfPgEscapeString Then PEscapeSql(T, dbPg, R) Else SqlQuote(T, R, dbPg);
      End;
  Else
    VmFail('fonction PHP non disponible : ' + LoStr(PhpFnNames[Id - 300]) + '()');
  End;
  If B.P <> Nil Then BufFree(B);
End;
{ --- boucle de la machine : Budget instructions au plus --- }

Function LineOf(Pc_ : LongInt) : LongInt;
Var K : LongInt;
Begin
  LineOf := 0;
  With Pages[Prog] Do
    For K := 0 To NLine - 1 Do
      If Lines^[K * 2] <= Pc_ Then LineOf := Lines^[K * 2 + 1] Else Exit;
End;

Procedure VmRun(Budget : LongInt);
Var Code : PLongs; Op, A, B, C, D, E, K, F, N_ : LongInt; X, Y : TCell; Pc0 : LongInt; Q : PBytes;
Begin
  Code := Pages[Prog].Code;
  While (Budget > 0) And VmOn And (VmErr = '') Do
  Begin
    Dec(Budget);
    Pc0 := PC;
    Op := Code^[PC];
    Inc(PC);
    Case Op Of
      opNop : ;
      opErrClr :
        Begin
          { debut d'une instruction (ASP) : point de reprise de On Error Resume Next }
          VmStmtSP := SP; VmStmtFP := FP;
        End;
      opPushI :
        Begin
          PushInt(Code^[PC]);
          Inc(PC);
        End;
      opPushR :
        Begin
          X.T := vtReal; X.R := Pages[Prog].Reals^[Code^[PC]];
          Inc(PC);
          Push(X);
        End;
      opPushS :
        Begin
          X.T := vtKStr; X.I := Code^[PC]; X.L := Code^[PC + 1];
          PC := PC + 2;
          Push(X);
        End;
      opPushC :
        Begin
          X.T := vtChar; X.I := Code^[PC]; X.L := 0;
          Inc(PC);
          Push(X);
        End;
      opPushB :
        Begin
          MkBool(Code^[PC] <> 0, X);
          Inc(PC);
          Push(X);
        End;
      opPushNil :
        Begin
          MkNil(X);
          Push(X);
        End;
      opIsObj :
        Begin
          MkObj(Code^[PC], X);
          Inc(PC);
          Push(X);
        End;
      opLdG :
        Begin
          Push(Mem^[Code^[PC]]);
          Inc(PC);
        End;
      opStG :
        Begin
          Mem^[Code^[PC]] := Stk[SP];
          Dec(SP);
          Inc(PC);
        End;
      opLdL :
        Begin
          Push(Mem^[FP + Code^[PC]]);
          Inc(PC);
        End;
      opStL :
        Begin
          Mem^[FP + Code^[PC]] := Stk[SP];
          Dec(SP);
          Inc(PC);
        End;
      opLdGA, opLdLA :
        Begin
          X.T := vtAddr; X.I := Code^[PC]; X.L := 0;
          If Op = opLdLA Then X.I := X.I + FP;
          Inc(PC);
          Push(X);
        End;
      opLdUp, opStUp, opLdUpA :
        Begin
          F := FP;
          For K := 1 To Code^[PC] Do F := Mem^[F + 2].I;
          A := F + Code^[PC + 1];
          PC := PC + 2;
          If Op = opLdUp Then Push(Mem^[A])
          Else If Op = opStUp Then
          Begin
            Mem^[A] := Stk[SP];
            Dec(SP);
          End
          Else
          Begin
            X.T := vtAddr; X.I := A; X.L := 0;
            Push(X);
          End;
        End;
      opLdInd :
        Begin
          A := AddrOf(Stk[SP]);
          If MemOk(A) Then Stk[SP] := Mem^[A];
        End;
      opStInd :
        Begin
          A := AddrOf(Stk[SP - 1]);
          If MemOk(A) Then Mem^[A] := Stk[SP];
          SP := SP - 2;
        End;
      opCopy :
        Begin
          N_ := Code^[PC];
          Inc(PC);
          A := AddrOf(Stk[SP]); B := AddrOf(Stk[SP - 1]);
          SP := SP - 2;
          If MemOk(A) And MemOk(B) And MemOk(A + N_ - 1) And MemOk(B + N_ - 1) And (A <> B) Then
            Move(Mem^[A], Mem^[B], N_ * SizeOf(TCell));
        End;
      opIdx :
        Begin
          A := Code^[PC]; B := Code^[PC + 1]; C := Code^[PC + 2];
          PC := PC + 3;
          X := Stk[SP];
          If X.T = vtChar Then E := X.I Else E := CellInt(X);
          Dec(SP);
          If (E < A) Or (E > B) Then
          Begin
            VmFail('indice hors limites (' + IStr(E) + ', ' + IStr(A) + '..' + IStr(B) + ')');
          End
          Else Stk[SP].I := AddrOf(Stk[SP]) + (E - A) * C;
        End;
      opFld :
        Begin
          Stk[SP].I := AddrOf(Stk[SP]) + Code^[PC];
          Inc(PC);
        End;
      opConv :
        Begin
          Convert(Stk[SP], Code^[PC]);
          Inc(PC);
        End;
      opAdd, opSub, opMul, opDivR, opIDiv, opMod :
        Begin
          X := Stk[SP - 1]; Y := Stk[SP];
          Dec(SP);
          If (Op = opAdd) And (X.T = vtInt) And (Y.T = vtInt) Then Stk[SP].I := X.I + Y.I
          Else If (Op = opSub) And (X.T = vtInt) And (Y.T = vtInt) Then Stk[SP].I := X.I - Y.I
          Else Arith(Op, X, Y, Stk[SP]);
        End;
      opConcat :
        Begin
          X := Stk[SP - 1]; Y := Stk[SP];
          Dec(SP);
          Concat2(X, Y, Stk[SP]);
        End;
      opNeg :
        If Stk[SP].T = vtReal Then Stk[SP].R := -Stk[SP].R
        Else MkInt(-CellInt(Stk[SP]), Stk[SP]);
      opNot :
        If (Stk[SP].T = vtBool) Then Stk[SP].I := 1 - Stk[SP].I
        Else If VbStyle And (Stk[SP].T = vtNil) Then MkInt(-1, Stk[SP])
        Else MkInt(Not CellInt(Stk[SP]), Stk[SP]);
      opAnd, opOr, opXor :
        Begin
          X := Stk[SP - 1]; Y := Stk[SP];
          Dec(SP);
          If (X.T = vtObj) Then ObjValue(X);
          If (Y.T = vtObj) Then ObjValue(Y);
          If (X.T = vtBool) And (Y.T = vtBool) Then
          Begin
            Case Op Of
              opAnd : MkBool((X.I <> 0) And (Y.I <> 0), Stk[SP]);
              opOr : MkBool((X.I <> 0) Or (Y.I <> 0), Stk[SP]);
            Else
              MkBool((X.I <> 0) Xor (Y.I <> 0), Stk[SP]);
            End;
          End
          Else If (X.T = vtSet) Or (Y.T = vtSet) Then
          Begin
            Stk[SP].T := vtSet;
            Stk[SP].I := X.I Or Y.I; Stk[SP].L := X.L Or Y.L;
          End
          Else
          Begin
            A := CellInt(X); B := CellInt(Y);
            Case Op Of
              opAnd : MkInt(A And B, Stk[SP]);
              opOr : MkInt(A Or B, Stk[SP]);
            Else
              MkInt(A Xor B, Stk[SP]);
            End;
          End;
        End;
      opShl, opShr :
        Begin
          A := CellInt(Stk[SP - 1]); B := CellInt(Stk[SP]);
          Dec(SP);
          If Op = opShl Then MkInt(A Shl B, Stk[SP]) Else MkInt(A Shr B, Stk[SP]);
        End;
      opEq, opNe, opLt, opLe, opGt, opGe :
        Begin
          X := Stk[SP - 1]; Y := Stk[SP];
          Dec(SP);
          If (X.T = vtInt) And (Y.T = vtInt) Then
          Begin
            If X.I < Y.I Then K := -1 Else If X.I > Y.I Then K := 1 Else K := 0;
          End
          Else If PhpStyle Then K := PhpCompare(X, Y)
          Else K := Compare(X, Y);
          Case Op Of
            opEq : MkBool(K = 0, Stk[SP]);
            opNe : MkBool(K <> 0, Stk[SP]);
            opLt : MkBool(K < 0, Stk[SP]);
            opLe : MkBool(K <= 0, Stk[SP]);
            opGt : MkBool(K > 0, Stk[SP]);
          Else
            MkBool(K >= 0, Stk[SP]);
          End;
        End;
      opJmp : PC := Code^[PC];
      opJz, opJnz :
        Begin
          If Stk[SP].T = vtBool Then K := Stk[SP].I Else K := Ord(CellBool(Stk[SP]));
          Dec(SP);
          If ((Op = opJz) And (K = 0)) Or ((Op = opJnz) And (K <> 0)) Then PC := Code^[PC] Else Inc(PC);
        End;
      opCall :
        Begin
          A := Code^[PC]; N_ := Code^[PC + 1]; B := Code^[PC + 2];
          PC := PC + 3;
          F := FsTop;
          If F + 4 + N_ + 16 >= HeapTop Then
          Begin
            VmFail('pile des appels pleine (r'#130'cursion trop profonde ?)');
            Continue;
          End;
          C := FP;
          For K := 1 To B Do C := Mem^[C + 2].I;
          MkInt(PC, Mem^[F]); MkInt(FP, Mem^[F + 1]); MkInt(C, Mem^[F + 2]); MkNil(Mem^[F + 3]);
          For K := 0 To N_ - 1 Do Mem^[F + 4 + K] := Stk[SP - N_ + 1 + K];
          SP := SP - N_;
          FP := F;
          FsTop := F + 4 + N_;
          PC := A;
        End;
      opEnter :
        Begin
          A := Code^[PC]; B := Code^[PC + 1];
          PC := PC + 2;
          FsTop := FP + A;
          If FsTop + 16 >= HeapTop Then
          Begin
            VmFail('pile des appels pleine');
            Continue;
          End;
          For K := FP + 4 + B To FsTop - 1 Do MkNil(Mem^[K]);
        End;
      opRet :
        Begin
          X := Mem^[FP + 3];
          FsTop := FP;
          PC := Mem^[FP].I;
          FP := Mem^[FP + 1].I;
          If Code^[Pc0 + 1] <> 0 Then Push(X);
        End;
      opCallB :
        Begin
          A := Code^[PC]; B := Code^[PC + 1];
          PC := PC + 2;
          CallBuiltin(A, B);
        End;
      opWrite :
        Begin
          A := CellInt(Stk[SP - 1]); B := CellInt(Stk[SP]);
          X := Stk[SP - 2];
          SP := SP - 3;
          OutCell(X, A, B);
        End;
      opWriteLn :
        Begin
          If (Code^[PC] = 0) And VmHdrPending And (VmOut.Len = 0) Then VmHdrPending := False
          Else
          Begin
            BufAdd(VmOut, Crlf);
            VmHdrPending := False;
          End;
          Inc(PC);
        End;
      opPop : Dec(SP);
      opDup : Push(Stk[SP]);
      opSwap :
        Begin
          X := Stk[SP]; Stk[SP] := Stk[SP - 1]; Stk[SP - 1] := X;
        End;
      opHalt : VmEnded := True;
      opHtml :
        Begin
          A := Code^[PC]; B := Code^[PC + 1];
          PC := PC + 2;
          BufAddB(VmOut, @Pages[Prog].Strs.P^[A], B);
          If B > 0 Then VmHdrPending := False;
        End;
      opMember, opSetMember :
        Begin
          A := Code^[PC]; B := Code^[PC + 1];
          PC := PC + 2;
          If Op = opSetMember Then
          Begin
            Y := Stk[SP];
            Dec(SP);
          End
          Else MkNil(Y);
          X := Stk[SP - B];
          { Err.xxx dans une page ASP }
          MemberCall(X, A, B, SP - B + 1, Stk[SP - B], Op = opSetMember, Y);
          If VmWait Then
          Begin
            { la base de donnees n'a pas encore repondu : reprendre cette
              instruction plus tard (pile remise), les autres connexions
              sont servies entre-temps }
            Stk[SP - B] := X;
            If Op = opSetMember Then Inc(SP);
            PC := Pc0;
            Budget := 0;
          End
          Else
          Begin
            SP := SP - B;
            If Op = opSetMember Then Dec(SP);
          End;
        End;
      opInitS :
        Begin
          A := Code^[PC]; B := Code^[PC + 1]; C := Code^[PC + 2]; D := Code^[PC + 3]; E := Code^[PC + 4];
          PC := PC + 5;
          If A = 1 Then B := B + FP;
          For K := 0 To C - 1 Do
          Begin
            F := B + K * D;
            If (F < 0) Or (F >= MemCells) Then Break;
            Case E Of
              cvInt : MkInt(0, Mem^[F]);
              cvReal : MkReal(0, Mem^[F]);
              cvBool : MkBool(False, Mem^[F]);
              cvStr :
                Begin
                  Mem^[F].T := vtKStr; Mem^[F].I := 0; Mem^[F].L := 0;
                End;
              cvChar :
                Begin
                  Mem^[F].T := vtChar; Mem^[F].I := 0; Mem^[F].L := 0;
                End;
            Else
              MkNil(Mem^[F]);
            End;
          End;
        End;
      opStrIdx :
        Begin
          E := CellInt(Stk[SP]);
          Dec(SP);
          A := AddrOf(Stk[SP]);
          If MemOk(A) Then
          Begin
            X := Mem^[A];
            If X.T = vtChar Then
            Begin
              If E = 1 Then Stk[SP] := X Else VmFail('indice de cha'#140'ne hors limites');
            End
            Else If (E < 1) Or (E > CellLen(X)) Then VmFail('indice de cha'#140'ne hors limites (' + IStr(E) + ')')
            Else
            Begin
              Stk[SP].T := vtChar; Stk[SP].I := PoolPtr(X)^[E - 1]; Stk[SP].L := 0;
            End;
          End;
        End;
      opStrSet :
        Begin
          Y := Stk[SP]; E := CellInt(Stk[SP - 1]); A := AddrOf(Stk[SP - 2]);
          SP := SP - 3;
          If MemOk(A) Then
          Begin
            AsStr(Mem^[A], X);
            If (E < 1) Or (E > X.L) Then VmFail('indice de cha'#140'ne hors limites (' + IStr(E) + ')')
            Else
            Begin
              MkStrB(PoolPtr(X), X.L, Mem^[A]);
              If Y.T = vtChar Then K := Y.I Else K := CellInt(Y);
              If IsStrCell(Y) And (Y.T <> vtChar) And (Y.L > 0) Then K := PoolPtr(Y)^[0];
              VmPool.P^[Mem^[A].I + E - 1] := K;
            End;
          End;
        End;
      opSetBit :
        Begin
          A := Code^[PC];
          Inc(PC);
          If A = 1 Then
          Begin
            C := CellInt(Stk[SP]); B := CellInt(Stk[SP - 1]);
            If Stk[SP].T = vtChar Then C := Stk[SP].I;
            If Stk[SP - 1].T = vtChar Then B := Stk[SP - 1].I;
            SP := SP - 2;
          End
          Else
          Begin
            If Stk[SP].T = vtChar Then B := Stk[SP].I Else B := CellInt(Stk[SP]);
            C := B;
            Dec(SP);
          End;
          For K := B To C Do
            If (K < 0) Or (K > 63) Then
            Begin
              VmFail('ensemble : '#130'l'#130'ment hors de 0..63 (employer x in [...])');
              Break;
            End
            Else If K < 32 Then Stk[SP].I := Stk[SP].I Or (1 Shl K)
            Else Stk[SP].L := Stk[SP].L Or (1 Shl (K - 32));
        End;
      opPhp :
        Begin
          A := Code^[PC];
          Inc(PC);
          If (A = psSuper) Or (A = psIncE) Or (A = psCast) Or (A = psDrop2) Then
          Begin
            B := Code^[PC];
            Inc(PC);
          End
          Else B := 0;
          PhpOp(A, B);
        End;
      opInSet :
        Begin
          X := Stk[SP];
          Dec(SP);
          If Stk[SP].T = vtChar Then K := Stk[SP].I Else K := CellInt(Stk[SP]);
          If (K < 0) Or (K > 63) Then MkBool(False, Stk[SP])
          Else If K < 32 Then MkBool(((X.I Shr K) And 1) <> 0, Stk[SP])
          Else MkBool(((X.L Shr (K - 32)) And 1) <> 0, Stk[SP]);
        End;
    Else
      VmFail('code invalide ' + IStr(Op) + ' en ' + IStr(Pc0));
    End;
    If VmEnded Then VmOn := False;
    If (VmErr <> '') And VmOnErrResume And (FP = VmStmtFP) Then
    Begin
      { On Error Resume Next : Err.Number, Err.Description, ligne suivante }
      VmAspErrNum := 5;
      If Pos('division', VmErr) > 0 Then VmAspErrNum := 11 Else If Pos('indice', VmErr) > 0 Then VmAspErrNum := 9;
      VmAspErrDesc := Cp850Utf8(VmErr);
      VmErr := '';
      SP := VmStmtSP;
      K := LineOf(Pc0);
      F := -1;
      With Pages[Prog] Do
        For A := 0 To NLine - 1 Do
          If (Lines^[A * 2] > Pc0) And (Lines^[A * 2 + 1] > K) Then
          Begin
            F := Lines^[A * 2];
            Break;
          End;
      If F < 0 Then VmOn := False Else PC := F;
    End;
  End;
  If VmErr <> '' Then
  Begin
    VmErrLine := LineOf(Pc0);
    VmOn := False;
  End;
End;

{ --- pages : cache et compilation --- }

Function CompileAsp(K : LongInt; Path, Root : String) : String; Forward;
Function CompilePhp(K : LongInt; Path, Root : String) : String; Forward;

{ Lang : 0 PSP, 1 ASP, 2 PHP }
Function PageFor(Path : String; Lang : LongInt; Var Err : String) : LongInt;
Var K, Best, Sz, Mt : LongInt; Dr : Boolean;
Begin
  PageFor := -1;
  Err := '';
  If Not PStat(Path, Sz, Mt, Dr) Then
  Begin
    Err := 'fichier introuvable';
    Exit;
  End;
  For K := 0 To MaxPage - 1 Do
    If Pages[K].Used And (Pages[K].Path = Path) Then
    Begin
      If (Pages[K].MTime = Mt) And (Pages[K].Size = Sz) Then
      Begin
        Inc(Pages[K].Hits);
        Pages[K].LastUse := PTicks;
        PageFor := K;
        Exit;
      End;
      ResetPage(K);
    End;
  Best := -1;
  For K := 0 To MaxPage - 1 Do
    If Not Pages[K].Used Then
    Begin
      Best := K;
      Break;
    End;
  If Best < 0 Then
  Begin
    Best := 0;
    For K := 1 To MaxPage - 1 Do If Pages[K].LastUse < Pages[Best].LastUse Then Best := K;
    ResetPage(Best);
  End;
  If Lang = 1 Then Err := CompileAsp(Best, Path, Sites[Conns[VmConn].Site].Root)
  Else If Lang = 2 Then Err := CompilePhp(Best, Path, Sites[Conns[VmConn].Site].Root)
  Else Err := CompilePsp(Best, Path, Sites[Conns[VmConn].Site].Root);
  If Err <> '' Then Exit;
  Pages[Best].Path := Path; Pages[Best].MTime := Mt; Pages[Best].Size := Sz; Pages[Best].Asp := Lang = 1;
  Pages[Best].Php := Lang = 2;
  Pages[Best].Hits := 1; Pages[Best].LastUse := PTicks;
  PageFor := Best;
End;

{ page d'erreur d'ASP (compilation ou execution) }
Procedure ScriptError(C : LongInt; Kind, Msg : String; Line : LongInt);
Var B : TBuf; L, K, N : LongInt; Src_ : TBuf; S : String;
Begin
  Inc(TotErr);
  SysLog(Kind + ' : ' + ScriptPath[C] + ', ligne ' + IStr(Line) + ' : ' + Msg);
  BufInit(B);
  PageTop(B, Kind);
  BufAdd(B, '<h1>' + Cp850Utf8(Kind) + '</h1><div><p><b>' + Cp850Utf8(HtmlEnc(Msg)) + '</b></p><p>' +
         Cp850Utf8(HtmlEnc(Conns[C].Uri)) + ', ligne ' + IStr(Line) + '</p>');
  { la ligne du source }
  If (Line > 0) And ReadFileBuf(ScriptPath[C], Src_, 4194304) Then
  Begin
    L := 1; K := 0;
    While (K < Src_.Len) And (L < Line) Do
    Begin
      If Src_.P^[K] = 10 Then Inc(L);
      Inc(K);
    End;
    S := '';
    N := 0;
    While (K < Src_.Len) And (Src_.P^[K] <> 10) And (N < 200) Do
    Begin
      If Src_.P^[K] <> 13 Then S := S + Chr(Src_.P^[K]);
      Inc(K); Inc(N);
    End;
    BufAdd(B, '<pre>' + HtmlEnc(S) + '</pre>');
    BufFree(Src_);
  End;
  BufAdd(B, '<hr><p><i>' + HtmlEnc(ServerName) + ' (OS/2-0)</i></p></div></body></html>' + #10);
  Conns[C].State := csSend;
  SendMem(C, 500, 'text/html; charset=utf-8', B, '');
  Conns[C].State := csSend;
End;

Procedure VmStart(C : LongInt);
Var Err : String; K : LongInt;
Begin
  VmConn := C;
  If ScriptPhp[C] Then K := 2 Else K := Ord(ScriptAsp[C]);
  Prog := PageFor(ScriptPath[C], K, Err);
  If Prog < 0 Then
  Begin
    If ScriptPhp[C] Then ScriptError(C, 'Erreur de compilation PHP', Err, CErrLine)
    Else If ScriptAsp[C] Then ScriptError(C, 'Erreur de compilation ASP', Err, CErrLine)
    Else ScriptError(C, 'Erreur de compilation PSP', Err, CErrLine);
    VmConn := -1;
    Exit;
  End;
  Inc(Shm^.PspRuns);
  FsBase := Pages[Prog].NGlob;
  For K := 0 To FsBase + 3 Do MkNil(Mem^[K]);
  FP := FsBase; FsTop := FsBase + 4; HeapTop := MemCells; SP := -1; PC := 0;
  VmPool.Len := 0; VmOut.Len := 0; VmHdr.Len := 0;
  VmStatus := '200 OK'; VmCType := 'text/html'; VmCharset := ''; VmPendLoc := '';
  VmHdrPending := False; VmEnded := False; VmBuffer := True; VmSess := -1; VmNewSess := False;
  VmBinPos := 0; VmErr := ''; VmErrLine := 0; VmT0 := PTicks; VmScriptTo := ScriptTimeoutS;
  VmAspErrNum := 0; VmAspErrDesc := ''; VmOnErrResume := False;
  VbStyle := Pages[Prog].Asp;
  PhpStyle := Pages[Prog].Php;
  PhpReset;
  DbEndRequest;
  NObj := 8;
  For K := 1 To 7 Do
  Begin
    ObjK[K] := K; ObjA[K] := 0; ObjB[K] := 0;
  End;
  NDict := 0;
  QsDone := False; FmDone := False; CkDone := False;
  For K := 0 To MaxStream - 1 Do StrmUsed[K] := False;
  Conns[C].State := csVm;
  VmOn := True;
End;

{ fin de l'execution : la reponse }
Procedure VmFinish;
Var C, K, Code : LongInt; Extra, Ct : String; B : TBuf;
Begin
  C := VmConn;
  VmConn := -1;
  VmOn := False;
  DbEndRequest;
  For K := 0 To MaxStream - 1 Do If StrmUsed[K] Then StreamClose(K);
  If C < 0 Then Exit;
  If Conns[C].State <> csVm Then Exit;
  If VmErr <> '' Then
  Begin
    Inc(Shm^.PspErr);
    If Pages[Prog].Asp Then ScriptError(C, 'Erreur d''ex'#130'cution VBScript', VmErr, VmErrLine)
    Else ScriptError(C, 'Erreur d''ex'#130'cution PSP', VmErr, VmErrLine);
    Exit;
  End;
  Code := SVal(Copy(VmStatus, 1, 3));
  If (Code < 100) Or (Code > 599) Then Code := 200;
  Extra := '';
  B := VmHdr;
  BufInit(VmHdr);
  If VmNewSess And (VmSess >= 0) Then
    BufAdd(B, 'Set-Cookie: ASPSESSIONID=' + Sess[VmSess].Id + '; path=/' + Crlf);
  If (VmSess >= 0) And (Sess[VmSess].Timeout = 0) Then SessFree(VmSess);
  BufAdd(B, 'Cache-Control: private' + Crlf);
  Ct := VmCType;
  If VmCharset <> '' Then Ct := Ct + '; charset=' + VmCharset;
  { en-tetes (memoire) : texte de PutHead (taille limitee a 255 : par
    morceaux) }
  Conns[C].State := csSend;
  PutHeadBuf(C, Code, Ct, VmOut.Len, B);
  BufFree(B);
  With Conns[C] Do
    If Head Or (VmOut.Len = 0) Then
    Begin
      VmOut.Len := 0;
    End
    Else
    Begin
      BSrc := bsMem; BMem := VmOut.P; BLen := VmOut.Len; BPos := 0; BMemOwn := True; BMemCap := VmOut.Cap;
      BufInit(VmOut);
    End;
End;

Procedure VmEnqueue(C : LongInt);
Begin
  Conns[C].State := csWaitVm;
  If VmQLen < MaxConn Then
  Begin
    VmQueue[VmQLen] := C;
    Inc(VmQLen);
  End;
End;

Procedure VmAbort(C : LongInt);
Var K, J : LongInt;
Begin
  If (VmConn = C) And VmOn Then
  Begin
    VmOn := False;
    VmConn := -1;
    DbEndRequest;
  End;
  J := 0;
  For K := 0 To VmQLen - 1 Do
    If VmQueue[K] <> C Then
    Begin
      VmQueue[J] := VmQueue[K];
      Inc(J);
    End;
  VmQLen := J;
End;

Function VmBusy : Boolean;
Begin
  { (une page qui attend sa base de donnees n'occupe pas le processeur :
    le socket de la base est dans le select du service) }
  VmBusy := (VmOn And Not VmWait) Or ((Not VmOn) And (VmQLen > 0));
End;

{ une tranche : environ 20000 instructions, puis les connexions }
Procedure VmStep;
Var K, C : LongInt;
Begin
  If Not VmOn Then
  Begin
    While (VmQLen > 0) And Not VmOn Do
    Begin
      C := VmQueue[0];
      For K := 1 To VmQLen - 1 Do VmQueue[K - 1] := VmQueue[K];
      Dec(VmQLen);
      If Conns[C].State = csWaitVm Then VmStart(C);
    End;
    If Not VmOn Then Exit;
  End;
  VmRun(20000);
  If VmOn And (PTicks - VmT0 > VmScriptTo * 1000) Then
  Begin
    VmFail('d'#130'lai d''ex'#130'cution d'#130'pass'#130' (Server.ScriptTimeout = ' + IStr(VmScriptTo) + ' s)');
    VmErrLine := LineOf(PC);
    VmOn := False;
  End;
  If Not VmOn Then VmFinish;
End;

Procedure VmHouse;
Var K : LongInt;
Begin
  For K := 0 To MaxSess - 1 Do
    If Sess[K].Used And (NowUnix - Sess[K].Last > Sess[K].Timeout * 60 + 60) Then SessFree(K);
  DbHouse;
End;

Procedure VmInit;
Begin
  GetMem(Mem, MemCells * SizeOf(TCell));
  GetMem(DKey, MaxDictE * SizeOf(TCell)); GetMem(DVal, MaxDictE * SizeOf(TCell));
  GetMem(DObj, MaxDictE * 4);
  BufInit(VmPool); BufInit(VmOut); BufInit(VmHdr);
  VmOn := False; VmConn := -1; VmQLen := 0;
  DbInit;
  RndSeed := PRdtsc;
End;

{ ==================================================================== }
{ Compilateur ASP (VBScript) vers la meme machine que PSP               }
{ Dim, Const, ReDim [Preserve], Set, If/ElseIf/Else, For/Next (Step),    }
{ For Each, Do/Loop While|Until, While/Wend, Select Case, Sub,          }
{ Function, Call, Exit, With, On Error Resume Next ; parametres ByRef   }
{ (par defaut) et ByVal ; Sub et Function utilisables avant leur        }
{ definition ; variables implicites ; operateurs & \ Mod ^ Is.           }
{ ==================================================================== }

Const
  vtkEol = 20;

Var
  VbWith : Array[0..7] Of LongInt;      { variables temporaires des With }
  NVbWith : LongInt;
  VbExitSub, VbExitFor, VbExitDo : LongInt;   { chaines de sauts }
  VbInSub : LongInt;                    { symbole de la Sub/Function en cours }

{ --- lexique : comme PSP pour le HTML ; dans le code, fin de ligne et ':'
  separent les instructions --- }
Procedure VNext;
Var C : Char; S : String; V, K : LongInt; Lit : TBuf; Done_ : Boolean;
Begin
  If CErr <> '' Then
  Begin
    Tok := tkEof;
    Exit;
  End;
  Repeat
    Done_ := True;
    TokLine := SLine;
    If SPos >= Src.Len Then
    Begin
      Tok := tkEof;
      Exit;
    End;
    If InHtml Then
    Begin
      V := SPos;
      While (SPos < Src.Len) And Not ((SrcCh(SPos) = '<') And (SrcCh(SPos + 1) = '%')) Do
      Begin
        If SrcCh(SPos) = #10 Then Inc(SLine);
        Inc(SPos);
      End;
      If SPos > V Then
      Begin
        Tok := tkHtml; TokOff := V; TokLen := SPos - V;
        Exit;
      End;
      If SPos >= Src.Len Then
      Begin
        Tok := tkEof;
        Exit;
      End;
      SPos := SPos + 2;
      InHtml := False;
      If SrcCh(SPos) = '=' Then
      Begin
        Inc(SPos);
        InEcho := True;
        Tok := tkEcho;
        Exit;
      End;
      If SrcCh(SPos) = '@' Then
      Begin
        While (SPos < Src.Len) And Not ((SrcCh(SPos) = '%') And (SrcCh(SPos + 1) = '>')) Do
        Begin
          If SrcCh(SPos) = #10 Then Inc(SLine);
          Inc(SPos);
        End;
        SPos := SPos + 2;
        InHtml := True;
        If SrcCh(SPos) = #13 Then Inc(SPos);
        If SrcCh(SPos) = #10 Then
        Begin
          Inc(SPos); Inc(SLine);
        End;
        Done_ := False;
        Continue;
      End;
      Tok := vtkEol;
      Exit;
    End;
    C := SrcCh(SPos);
    If (C = ' ') Or (C = #9) Or (C = #13) Then
    Begin
      Inc(SPos);
      Done_ := False;
      Continue;
    End;
    { suite de ligne : _ en fin de ligne }
    If (C = '_') And ((SrcCh(SPos + 1) = #13) Or (SrcCh(SPos + 1) = #10)) Then
    Begin
      Inc(SPos);
      While SrcCh(SPos) In [#13, #10] Do
      Begin
        If SrcCh(SPos) = #10 Then Inc(SLine);
        Inc(SPos);
        If SrcCh(SPos - 1) = #10 Then Break;
      End;
      Done_ := False;
      Continue;
    End;
    { commentaire ' ou Rem }
    If (C = '''') Or ((UpCase(C) = 'R') And (UpCase(SrcCh(SPos + 1)) = 'E') And (UpCase(SrcCh(SPos + 2)) = 'M') And
       ((SrcCh(SPos + 3) = ' ') Or (SrcCh(SPos + 3) = #9) Or (SrcCh(SPos + 3) = #13) Or (SrcCh(SPos + 3) = #10)) And
       ((SPos = 0) Or Not IsIdCh(SrcCh(SPos - 1)))) Then
    Begin
      While (SPos < Src.Len) And (SrcCh(SPos) <> #10) And Not ((SrcCh(SPos) = '%') And (SrcCh(SPos + 1) = '>')) Do
        Inc(SPos);
      Done_ := False;
      Continue;
    End;
  Until Done_;
  TokLine := SLine;
  C := SrcCh(SPos);
  If C = #10 Then
  Begin
    Inc(SPos); Inc(SLine);
    Tok := vtkEol;
    Exit;
  End;
  If (C = '%') And (SrcCh(SPos + 1) = '>') Then
  Begin
    SPos := SPos + 2;
    InHtml := True;
    If InEcho Then
    Begin
      InEcho := False;
      Tok := tkEchoEnd;
      Exit;
    End;
    Tok := vtkEol;
    Exit;
  End;
  If C = ':' Then
  Begin
    Inc(SPos);
    Tok := vtkEol;
    Exit;
  End;
  If IsIdCh(C) And Not ((C >= '0') And (C <= '9')) Then
  Begin
    S := '';
    While IsIdCh(SrcCh(SPos)) Do
    Begin
      If Length(S) < 31 Then S := S + UpCase(SrcCh(SPos));
      Inc(SPos);
    End;
    Tok := tkId; TokS := S;
    Exit;
  End;
  If (C = '&') And (UpCase(SrcCh(SPos + 1)) = 'H') Then
  Begin
    SPos := SPos + 2;
    V := 0;
    While UpCase(SrcCh(SPos)) In ['0'..'9', 'A'..'F'] Do
    Begin
      C := UpCase(SrcCh(SPos));
      If C <= '9' Then V := V * 16 + Ord(C) - 48 Else V := V * 16 + Ord(C) - 55;
      Inc(SPos);
    End;
    If SrcCh(SPos) = '&' Then Inc(SPos);
    Tok := tkInt; TokI := V;
    Exit;
  End;
  If ((C >= '0') And (C <= '9')) Or ((C = '.') And (SrcCh(SPos + 1) >= '0') And (SrcCh(SPos + 1) <= '9')) Then
  Begin
    S := '';
    While ((SrcCh(SPos) >= '0') And (SrcCh(SPos) <= '9')) Or (SrcCh(SPos) = '.') Do
    Begin
      S := S + SrcCh(SPos);
      Inc(SPos);
    End;
    If (UpCase(SrcCh(SPos)) = 'E') And (SrcCh(SPos + 1) In ['0'..'9', '+', '-']) Then
    Begin
      S := S + 'E';
      Inc(SPos);
      While SrcCh(SPos) In ['0'..'9', '+', '-'] Do
      Begin
        S := S + SrcCh(SPos);
        Inc(SPos);
      End;
    End;
    If S[1] = '.' Then S := '0' + S;
    If (Pos('.', S) > 0) Or (Pos('E', S) > 0) Or (Length(S) > 9) Then
    Begin
      Val(S, TokR, K);
      Tok := tkReal;
    End
    Else
    Begin
      Val(S, TokI, K);
      Tok := tkInt;
    End;
    Exit;
  End;
  If C = '"' Then
  Begin
    BufInit(Lit);
    Inc(SPos);
    Repeat
      If SPos >= Src.Len Then Break;
      If SrcCh(SPos) = '"' Then
      Begin
        If SrcCh(SPos + 1) = '"' Then
        Begin
          BufAddC(Lit, 34);
          SPos := SPos + 2;
        End
        Else
        Begin
          Inc(SPos);
          Break;
        End;
      End
      Else
      Begin
        If SrcCh(SPos) = #10 Then
        Begin
          CError('cha'#140'ne non termin'#130'e');
          Break;
        End;
        BufAddC(Lit, Src.P^[SPos]);
        Inc(SPos);
      End;
    Until False;
    Tok := tkStr;
    TokOff := AddStrB(Lit.P, Lit.Len);
    TokLen := Lit.Len;
    V := Lit.Len;
    If V > 255 Then V := 255;
    TokS[0] := Chr(V);
    If V > 0 Then Move(Lit.P^[0], TokS[1], V);
    BufFree(Lit);
    Exit;
  End;
  If C = '#' Then
  Begin
    { date #jj/mm/aaaa# }
    S := '';
    Inc(SPos);
    While (SPos < Src.Len) And (SrcCh(SPos) <> '#') And (SrcCh(SPos) <> #10) Do
    Begin
      S := S + SrcCh(SPos);
      Inc(SPos);
    End;
    Inc(SPos);
    Tok := tkReal;
    If Not ParseDate(S, TokR) Then TokR := 0;
    TokI := -7;
    Exit;
  End;
  Tok := tkSym;
  Inc(SPos);
  TokS := C;
  If ((C = '<') And ((SrcCh(SPos) = '=') Or (SrcCh(SPos) = '>'))) Or ((C = '>') And (SrcCh(SPos) = '=')) Then
  Begin
    TokS := TokS + SrcCh(SPos);
    Inc(SPos);
  End;
End;

Function VIsEol : Boolean;
Begin
  VIsEol := (Tok = vtkEol) Or (Tok = tkEof) Or (Tok = tkHtml) Or (Tok = tkEcho);
End;

Procedure VExpect(S : String);
Begin
  If ((Tok = tkSym) Or (Tok = tkId)) And (TokS = S) Then VNext
  Else If Tok = tkEof Then CError('''' + S + ''' attendu (fin du fichier)')
  Else If Tok = vtkEol Then CError('''' + S + ''' attendu (fin de ligne)')
  Else CError('''' + S + ''' attendu au lieu de ''' + TokS + '''');
End;

Procedure VSkipEol;
Begin
  While Tok = vtkEol Do VNext;
End;

{ variable implicite (ou trouvee) }
Function VVar(Name : String; Create : Boolean) : LongInt;
Var S : LongInt;
Begin
  S := FindSym(Name);
  If (S >= 0) And (Syms[S].Kind In [skVar, skConst, skProc, skFunc, skObj]) Then
  Begin
    { variable locale d'une autre procedure : pas visible }
    If (Syms[S].Kind = skVar) And (Syms[S].Lvl > 0) And (Syms[S].Lvl <> CurLvl) Then S := -1
    Else
    Begin
      VVar := S;
      Exit;
    End;
  End;
  VVar := -1;
  If Not Create Then Exit;
  S := AddSym(Name, skVar);
  Syms[S].Ty := TyVar;
  Syms[S].Adr := AllocVar(1);
  If CurLvl = 0 Then Emit2(opInitS, 0, 0) Else Emit2(opInitS, 1, 0);
  Pages[CP].Code^[Pages[CP].NCode - 1] := Syms[S].Adr;
  Emit(1); Emit(1); Emit(cvVar);
  VVar := S;
End;

Function VExpr : LongInt; Forward;
Procedure VStatement; Forward;
Procedure VBlock(Stop1, Stop2, Stop3, Stop4 : String); Forward;

{ arguments entre parentheses (ou, pour une instruction, sans parentheses) }
Function VArgs(Paren : Boolean) : LongInt;
Var N : LongInt;
Begin
  N := 0;
  If Paren Then
  Begin
    If Not IsSym('(') Then
    Begin
      VArgs := 0;
      Exit;
    End;
    VNext;
    If Not IsSym(')') Then
      Repeat
        If IsSym(',') Then Emit(opPushNil) Else Dummy := VExpr;
        Inc(N);
        If IsSym(',') Then VNext Else Break;
      Until CErr <> '';
    VExpect(')');
  End
  Else
  Begin
    If Not VIsEol And Not IsKw('ELSE') Then
      Repeat
        Dummy := VExpr;
        Inc(N);
        If IsSym(',') Then VNext Else Break;
      Until CErr <> '';
  End;
  VArgs := N;
End;

{ appel d'une Sub/Function : arguments ByRef (adresse d'une variable, ou
  d'une variable temporaire) ou ByVal }
Procedure VCall(S : LongInt; Paren : Boolean);
Var N, K, T, Tmp : LongInt; D : TDes; Open_ : Boolean; X : TLexSave; Simple : Boolean;
Begin
  N := 0;
  Open_ := False;
  If Paren Then
  Begin
    If IsSym('(') Then
    Begin
      Open_ := True;
      VNext;
    End;
  End
  Else If IsSym('(') Then
  Begin
    Open_ := True;
    VNext;
  End;
  If (Open_ And Not IsSym(')')) Or ((Not Open_) And Not Paren And Not VIsEol) Then
    Repeat
      If N >= Syms[S].NPar Then
      Begin
        CError('trop d''arguments pour ' + Syms[S].Name);
        Exit;
      End;
      K := Syms[S].PBase + N;
      If PRef[K] Then
      Begin
        { variable simple : son adresse ; sinon une variable temporaire }
        Simple := False;
        If Tok = tkId Then
        Begin
          LexSave(X);
          VNext;
          Simple := IsSym(',') Or IsSym(')') Or VIsEol;
          LexRestore(X);
          If Simple Then
          Begin
            T := VVar(TokS, False);
            Simple := (T >= 0) And (Syms[T].Kind = skVar);
          End;
        End;
        If Simple Then
        Begin
          VNext;
          DesFromSym(T, D);
          DesAddr(D);
        End
        Else
        Begin
          Dummy := VExpr;
          Tmp := AllocVar(1);
          If CurLvl = 0 Then
          Begin
            Emit1(opStG, Tmp); Emit1(opLdGA, Tmp);
          End
          Else
          Begin
            Emit1(opStL, Tmp); Emit1(opLdLA, Tmp);
          End;
        End;
      End
      Else Dummy := VExpr;
      Inc(N);
      If IsSym(',') Then VNext Else Break;
    Until CErr <> '';
  If Open_ Then VExpect(')');
  { arguments omis : vides }
  While N < Syms[S].NPar Do
  Begin
    K := Syms[S].PBase + N;
    If PRef[K] Then
    Begin
      Tmp := AllocVar(1);
      If CurLvl = 0 Then Emit1(opLdGA, Tmp) Else Emit1(opLdLA, Tmp);
    End
    Else Emit(opPushNil);
    Inc(N);
  End;
  Emit(opCall);
  If Syms[S].Adr < 0 Then
  Begin
    Emit(Syms[S].Patch);
    Syms[S].Patch := Here - 1;
  End
  Else Emit(Syms[S].Adr);
  Emit(N); Emit(CurLvl - Syms[S].Lvl);
End;

{ fonctions de VBScript : nom -> fonction de la machine }
Function VbBuiltin(N : String; Var Id : LongInt) : Boolean;
Begin
  Id := 0;
  If N = 'LEN' Then Id := bLen Else If N = 'LEFT' Then Id := bLeft Else If N = 'RIGHT' Then Id := bRight
  Else If N = 'MID' Then Id := bMid Else If N = 'INSTR' Then Id := bInStr Else If N = 'INSTRREV' Then Id := bInStrRev
  Else If N = 'LCASE' Then Id := bLCase Else If N = 'UCASE' Then Id := bUCase Else If N = 'TRIM' Then Id := bTrim
  Else If N = 'LTRIM' Then Id := bLTrim Else If N = 'RTRIM' Then Id := bRTrim Else If N = 'REPLACE' Then Id := bReplace
  Else If N = 'SPLIT' Then Id := bSplit Else If N = 'JOIN' Then Id := bJoin Else If N = 'UBOUND' Then Id := bUBound
  Else If N = 'LBOUND' Then Id := bLBound Else If N = 'CSTR' Then Id := bCStr Else If N = 'CINT' Then Id := bCInt
  Else If N = 'CLNG' Then Id := bCLng Else If N = 'CDBL' Then Id := bCDbl Else If N = 'CSNG' Then Id := bCSng
  Else If N = 'CBOOL' Then Id := bCBool Else If N = 'CDATE' Then Id := bCDate Else If N = 'CBYTE' Then Id := bCByte
  Else If N = 'CCUR' Then Id := bCDbl
  Else If N = 'ISNUMERIC' Then Id := bIsNumeric Else If N = 'ISEMPTY' Then Id := bIsEmpty
  Else If N = 'ISNULL' Then Id := bIsNull Else If N = 'ISARRAY' Then Id := bIsArray Else If N = 'ISOBJECT' Then Id := bIsObject
  Else If N = 'ISDATE' Then Id := bIsDate Else If N = 'NOW' Then Id := bNow Else If N = 'DATE' Then Id := bDate
  Else If N = 'TIME' Then Id := bTime Else If N = 'YEAR' Then Id := bYear Else If N = 'MONTH' Then Id := bMonth
  Else If N = 'DAY' Then Id := bDay Else If N = 'HOUR' Then Id := bHour Else If N = 'MINUTE' Then Id := bMinute
  Else If N = 'SECOND' Then Id := bSecond Else If N = 'WEEKDAY' Then Id := bWeekday
  Else If N = 'WEEKDAYNAME' Then Id := bWeekdayName Else If N = 'MONTHNAME' Then Id := bMonthName
  Else If N = 'DATEADD' Then Id := bDateAdd Else If N = 'DATEDIFF' Then Id := bDateDiff
  Else If N = 'DATESERIAL' Then Id := bDateSerial Else If N = 'TIMESERIAL' Then Id := bTimeSerial
  Else If N = 'DATEVALUE' Then Id := bDateValue Else If N = 'TIMEVALUE' Then Id := bTimeValue
  Else If N = 'FORMATNUMBER' Then Id := bFormatNumber Else If N = 'FORMATCURRENCY' Then Id := bFormatCurrency
  Else If N = 'FORMATPERCENT' Then Id := bFormatPercent Else If N = 'FORMATDATETIME' Then Id := bFormatDateTime
  Else If N = 'ABS' Then Id := bAbs Else If N = 'SGN' Then Id := bSgn Else If N = 'INT' Then Id := bInt
  Else If N = 'FIX' Then Id := bFix Else If N = 'ROUND' Then Id := bRound Else If N = 'SQR' Then Id := bSqrt
  Else If N = 'SIN' Then Id := bSin Else If N = 'COS' Then Id := bCos Else If N = 'TAN' Then Id := bTan
  Else If N = 'ATN' Then Id := bAtn Else If N = 'EXP' Then Id := bExpV Else If N = 'LOG' Then Id := bLog
  Else If N = 'RND' Then Id := bRnd Else If N = 'RANDOMIZE' Then Id := bRandomize Else If N = 'ASC' Then Id := bAsc
  Else If N = 'ASCW' Then Id := bAsc Else If N = 'CHR' Then Id := bChrV Else If N = 'CHRW' Then Id := bChrV
  Else If N = 'HEX' Then Id := bHex Else If N = 'OCT' Then Id := bOct
  Else If N = 'SPACE' Then Id := bSpace Else If N = 'STRING' Then Id := bString Else If N = 'STRREVERSE' Then Id := bStrReverse
  Else If N = 'STRCOMP' Then Id := bStrComp Else If N = 'ARRAY' Then Id := bArray Else If N = 'TYPENAME' Then Id := bTypeName
  Else If N = 'VARTYPE' Then Id := bVarType Else If N = 'TIMER' Then Id := bTimer Else If N = 'ESCAPE' Then Id := bEscape
  Else If N = 'UNESCAPE' Then Id := bUnescape Else If N = 'CREATEOBJECT' Then Id := bCreateObject;
  VbBuiltin := Id <> 0;
End;

{ suite d'un designateur : .membre [(args)], (args) }
Procedure VSelectors(Var D : TDes; Stmt : Boolean);
Var N : String; M, A : LongInt;
Begin
  While CErr = '' Do
  Begin
    If IsSym('.') Then
    Begin
      VNext;
      N := TokS;
      If Tok <> tkId Then
      Begin
        CError('nom attendu apr'#138's ''.''');
        Exit;
      End;
      DesLoad(D);
      M := MemberCode(N);
      If M < 0 Then
      Begin
        CError('membre inconnu : ' + N);
        Exit;
      End;
      VNext;
      If IsSym('(') Then A := VArgs(True)
      Else If Stmt And Not VIsEol And Not IsSym('=') And Not IsSym('.') Then
      Begin
        { Response.Write x : arguments sans parentheses (instruction) }
        A := VArgs(False);
        D.Kind := dkMember; D.Mem := M; D.Argc := A; D.Ty := TyVar;
        Exit;
      End
      Else A := 0;
      D.Kind := dkMember; D.Mem := M; D.Argc := A; D.Ty := TyVar;
      Continue;
    End;
    If IsSym('(') Then
    Begin
      DesLoad(D);
      A := VArgs(True);
      D.Kind := dkMember; D.Mem := mDefault; D.Argc := A; D.Ty := TyVar;
      Continue;
    End;
    Break;
  End;
End;

Function VFactor : LongInt;
Var S, Id, N, K : LongInt; D : TDes; Nm : String;
Begin
  VFactor := TyVar;
  If Tok = tkInt Then
  Begin
    Emit1(opPushI, TokI);
    VNext;
    Exit;
  End;
  If Tok = tkReal Then
  Begin
    Emit1(opPushR, AddReal(TokR));
    If TokI = -7 Then Emit1(opCallB, bCDate) ;
    If TokI = -7 Then Emit(1);
    VNext;
    Exit;
  End;
  If Tok = tkStr Then
  Begin
    Emit2(opPushS, TokOff, TokLen);
    VNext;
    VFactor := TyStr;
    Exit;
  End;
  If IsSym('(') Then
  Begin
    VNext;
    VFactor := VExpr;
    VExpect(')');
    Exit;
  End;
  If IsSym('-') Then
  Begin
    VNext;
    Dummy := VFactor;
    Emit(opNeg);
    Exit;
  End;
  If IsSym('+') Then
  Begin
    VNext;
    VFactor := VFactor;
    Exit;
  End;
  If IsSym('.') And (NVbWith > 0) Then
  Begin
    { .membre d'un With }
    D.Kind := dkVar; D.Ty := TyVar; D.Ref := False; D.Adr := VbWith[NVbWith - 1]; D.Up := 0;
    If CurLvl = 0 Then D.Mode := 0 Else D.Mode := 1;
    VSelectors(D, False);
    DesLoad(D);
    Exit;
  End;
  If Tok <> tkId Then
  Begin
    CError('expression attendue');
    Exit;
  End;
  Nm := TokS;
  If (Nm = 'TRUE') Or (Nm = 'FALSE') Then
  Begin
    Emit1(opPushB, Ord(Nm = 'TRUE'));
    VNext;
    VFactor := TyBool;
    Exit;
  End;
  If (Nm = 'NOTHING') Or (Nm = 'EMPTY') Or (Nm = 'NULL') Then
  Begin
    Emit(opPushNil);
    VNext;
    Exit;
  End;
  If (Nm = 'VBCRLF') Or (Nm = 'VBNEWLINE') Then
  Begin
    EmitStr(#13#10);
    VNext;
    Exit;
  End;
  If (Nm = 'VBCR') Or (Nm = 'VBLF') Or (Nm = 'VBTAB') Or (Nm = 'VBNULLSTRING') Or (Nm = 'VBNULLCHAR') Then
  Begin
    If Nm = 'VBCR' Then EmitStr(#13) Else If Nm = 'VBLF' Then EmitStr(#10) Else If Nm = 'VBTAB' Then EmitStr(#9)
    Else If Nm = 'VBNULLCHAR' Then EmitStr(#0) Else EmitStr('');
    VNext;
    Exit;
  End;
  If (Nm = 'VBTRUE') Or (Nm = 'VBFALSE') Or (Nm = 'VBBINARYCOMPARE') Or (Nm = 'VBTEXTCOMPARE') Or
     (Nm = 'VBGENERALDATE') Or (Nm = 'VBLONGDATE') Or (Nm = 'VBSHORTDATE') Or (Nm = 'VBLONGTIME') Or
     (Nm = 'VBSHORTTIME') Or (Nm = 'VBSUNDAY') Or (Nm = 'VBMONDAY') Then
  Begin
    If Nm = 'VBTRUE' Then K := -1 Else If Nm = 'VBTEXTCOMPARE' Then K := 1 Else If Nm = 'VBLONGDATE' Then K := 1
    Else If Nm = 'VBSHORTDATE' Then K := 2 Else If Nm = 'VBLONGTIME' Then K := 3 Else If Nm = 'VBSHORTTIME' Then K := 4
    Else If Nm = 'VBSUNDAY' Then K := 1 Else If Nm = 'VBMONDAY' Then K := 2 Else K := 0;
    Emit1(opPushI, K);
    VNext;
    Exit;
  End;
  S := VVar(Nm, False);
  If (S >= 0) And (Syms[S].Kind = skObj) Then
  Begin
    VNext;
    Emit1(opIsObj, Syms[S].Adr);
    D.Kind := dkValue; D.Ty := TyVar;
    VSelectors(D, False);
    DesLoad(D);
    Exit;
  End;
  If (S >= 0) And (Syms[S].Kind = skConst) Then
  Begin
    VNext;
    EmitConst(Syms[S].CV);
    Exit;
  End;
  If (S >= 0) And (Syms[S].Kind = skFunc) Then
  Begin
    VNext;
    VCall(S, True);
    D.Kind := dkValue; D.Ty := TyVar;
    VSelectors(D, False);
    DesLoad(D);
    Exit;
  End;
  If (S < 0) And VbBuiltin(Nm, Id) Then
  Begin
    VNext;
    N := VArgs(True);
    Emit2(opCallB, Id, N);
    If Id = bRandomize Then Emit(opPushNil);
    D.Kind := dkValue; D.Ty := TyVar;
    VSelectors(D, False);
    DesLoad(D);
    Exit;
  End;
  If (S >= 0) And (Syms[S].Kind = skProc) Then
  Begin
    CError('Sub employ'#130'e dans une expression : ' + Nm);
    Exit;
  End;
  { variable (creee si besoin) }
  VNext;
  S := VVar(Nm, True);
  DesFromSym(S, D);
  VSelectors(D, False);
  DesLoad(D);
End;

Function VPow : LongInt;
Begin
  VPow := VFactor;
  While (CErr = '') And IsSym('^') Do
  Begin
    VNext;
    Dummy := VFactor;
    Emit2(opCallB, bPower, 2);
  End;
End;

Function VUnary : LongInt;
Begin
  If IsSym('-') Then
  Begin
    VNext;
    VUnary := VUnary;
    Emit(opNeg);
  End
  Else VUnary := VPow;
End;

Function VMul : LongInt;
Var Op : String;
Begin
  VMul := VUnary;
  While (CErr = '') And (IsSym('*') Or IsSym('/')) Do
  Begin
    Op := TokS;
    VNext;
    Dummy := VUnary;
    If Op = '*' Then Emit(opMul) Else Emit(opDivR);
  End;
End;

Function VIntDiv : LongInt;
Begin
  VIntDiv := VMul;
  While (CErr = '') And IsSym('\') Do
  Begin
    VNext;
    Dummy := VMul;
    Emit(opIDiv);
  End;
End;

Function VModE : LongInt;
Begin
  VModE := VIntDiv;
  While (CErr = '') And IsKw('MOD') Do
  Begin
    VNext;
    Dummy := VIntDiv;
    Emit(opMod);
  End;
End;

Function VAdd : LongInt;
Var Op : String;
Begin
  VAdd := VModE;
  While (CErr = '') And (IsSym('+') Or IsSym('-')) Do
  Begin
    Op := TokS;
    VNext;
    Dummy := VModE;
    If Op = '+' Then Emit(opAdd) Else Emit(opSub);
  End;
End;

Function VCat : LongInt;
Begin
  VCat := VAdd;
  While (CErr = '') And IsSym('&') Do
  Begin
    VNext;
    Dummy := VAdd;
    Emit(opConcat);
  End;
End;

Function VRel : LongInt;
Var Op : String;
Begin
  VRel := VCat;
  While (CErr = '') And (IsSym('=') Or IsSym('<>') Or IsSym('<') Or IsSym('<=') Or IsSym('>') Or IsSym('>=') Or
        IsKw('IS')) Do
  Begin
    Op := TokS;
    VNext;
    If (Op = 'IS') And IsKw('NOT') Then
    Begin
      VNext;
      Op := '<>';
    End;
    Dummy := VCat;
    If (Op = '=') Or (Op = 'IS') Then Emit(opEq) Else If Op = '<>' Then Emit(opNe) Else If Op = '<' Then Emit(opLt)
    Else If Op = '<=' Then Emit(opLe) Else If Op = '>' Then Emit(opGt) Else Emit(opGe);
    VRel := TyBool;
  End;
End;

Function VNot : LongInt;
Begin
  If IsKw('NOT') Then
  Begin
    VNext;
    VNot := VNot;
    Emit(opNot);
  End
  Else VNot := VRel;
End;

Function VAnd : LongInt;
Begin
  VAnd := VNot;
  While (CErr = '') And IsKw('AND') Do
  Begin
    VNext;
    Dummy := VNot;
    Emit(opAnd);
  End;
End;

Function VExpr : LongInt;
Var Op : String;
Begin
  VExpr := VAnd;
  While (CErr = '') And (IsKw('OR') Or IsKw('XOR') Or IsKw('EQV')) Do
  Begin
    Op := TokS;
    VNext;
    Dummy := VAnd;
    If Op = 'OR' Then Emit(opOr) Else If Op = 'XOR' Then Emit(opXor)
    Else
    Begin
      Emit(opXor); Emit(opNot);
    End;
  End;
End;

{ variable (ou element) a gauche d'une affectation }
Procedure VAssignTarget(Var D : TDes);
Var S : LongInt; Nm : String;
Begin
  If IsSym('.') And (NVbWith > 0) Then
  Begin
    D.Kind := dkVar; D.Ty := TyVar; D.Ref := False; D.Adr := VbWith[NVbWith - 1]; D.Up := 0;
    If CurLvl = 0 Then D.Mode := 0 Else D.Mode := 1;
    VSelectors(D, True);
    Exit;
  End;
  Nm := TokS;
  S := VVar(Nm, False);
  If (S >= 0) And (Syms[S].Kind = skObj) Then
  Begin
    VNext;
    Emit1(opIsObj, Syms[S].Adr);
    D.Kind := dkValue; D.Ty := TyVar;
    VSelectors(D, True);
    Exit;
  End;
  If (S >= 0) And (Syms[S].Kind = skFunc) And (CurLvl = Syms[S].Lvl + 1) Then
  Begin
    { valeur de la fonction : cellule 3 du cadre }
    VNext;
    D.Kind := dkVar; D.Ty := TyVar; D.Ref := False; D.Adr := 3; D.Mode := 1; D.Up := 0;
    Exit;
  End;
  VNext;
  S := VVar(Nm, True);
  DesFromSym(S, D);
  VSelectors(D, True);
End;

Procedure VDim(Re : Boolean);
Var S, N, A : LongInt; Nm : String; Pres : Boolean;
Begin
  Pres := False;
  If Re And IsKw('PRESERVE') Then
  Begin
    Pres := True;
    VNext;
  End;
  Repeat
    If Tok <> tkId Then
    Begin
      CError('nom de variable attendu');
      Exit;
    End;
    Nm := TokS;
    VNext;
    S := -1;
    If Re Then S := VVar(Nm, True)
    Else
    Begin
      S := FindSym(Nm);
      If (S < 0) Or (Syms[S].Kind <> skVar) Or (Syms[S].Lvl <> CurLvl) Then
      Begin
        S := AddSym(Nm, skVar);
        Syms[S].Ty := TyVar;
        Syms[S].Adr := AllocVar(1);
      End;
      If CurLvl = 0 Then Emit2(opInitS, 0, Syms[S].Adr) Else Emit2(opInitS, 1, Syms[S].Adr);
      Emit(1); Emit(1); Emit(cvVar);
    End;
    If IsSym('(') Then
    Begin
      VNext;
      N := 0;
      If Not IsSym(')') Then
        Repeat
          Dummy := VExpr;
          Inc(N);
          If IsSym(',') Then VNext Else Break;
        Until CErr <> '';
      VExpect(')');
      If N > 0 Then
      Begin
        If Re And Pres Then
        Begin
          { ancien tableau en premier argument }
          A := Syms[S].Adr;
          If CurLvl = 0 Then Emit1(opLdG, A) Else Emit1(opLdL, A);
          Emit2(opCallB, bReDim, N + 1);
        End
        Else Emit2(opCallB, bMakeArr, N);
        If CurLvl = 0 Then Emit1(opStG, Syms[S].Adr) Else Emit1(opStL, Syms[S].Adr);
      End;
    End;
    If IsSym(',') Then VNext Else Break;
  Until CErr <> '';
End;

Procedure VIf;
Var J, JEnd, Line : LongInt;
Begin
  VNext;
  Dummy := VExpr;
  VExpect('THEN');
  Emit1(opJz, 0);
  J := Here - 1;
  If Not VIsEol Then
  Begin
    { If ... Then instruction [Else instruction] sur une ligne }
    VStatement;
    If IsKw('ELSE') Then
    Begin
      Emit1(opJmp, 0);
      JEnd := Here - 1;
      PatchAt(J, Here);
      VNext;
      VStatement;
      PatchAt(JEnd, Here);
    End
    Else PatchAt(J, Here);
    If IsKw('END') Then
    Begin
      VNext;
      If IsKw('IF') Then VNext;
    End;
    Exit;
  End;
  JEnd := -1;
  VBlock('ELSEIF', 'ELSE', 'END', '');
  While (CErr = '') And IsKw('ELSEIF') Do
  Begin
    Emit1(opJmp, JEnd);
    JEnd := Here - 1;
    PatchAt(J, Here);
    VNext;
    Dummy := VExpr;
    VExpect('THEN');
    Emit1(opJz, 0);
    J := Here - 1;
    VBlock('ELSEIF', 'ELSE', 'END', '');
  End;
  If IsKw('ELSE') Then
  Begin
    Emit1(opJmp, JEnd);
    JEnd := Here - 1;
    PatchAt(J, Here);
    J := -1;
    VNext;
    VBlock('END', '', '', '');
  End;
  If J >= 0 Then PatchAt(J, Here);
  PatchChain(JEnd, Here);
  VExpect('END');
  VExpect('IF');
End;

Procedure VFor;
Var S, Tmp, TmpStep, L0, J, J2, SaveExit, Cnt, Idx, Coll : LongInt; D : TDes; Nm : String; HasStep : Boolean;
Begin
  VNext;
  SaveExit := VbExitFor;
  VbExitFor := -1;
  If IsKw('EACH') Then
  Begin
    VNext;
    Nm := TokS;
    VNext;
    S := VVar(Nm, True);
    VExpect('IN');
    Coll := AllocVar(1); Cnt := AllocVar(1); Idx := AllocVar(1);
    Dummy := VExpr;
    PopTmp(Coll);
    PushTmp(Coll);
    Emit2(opCallB, bEachCount, 1);
    PopTmp(Cnt);
    Emit1(opPushI, 0);
    PopTmp(Idx);
    L0 := Here;
    PushTmp(Idx); PushTmp(Cnt);
    Emit(opGe);
    Emit1(opJnz, 0);
    J := Here - 1;
    PushTmp(Coll); PushTmp(Idx);
    Emit2(opCallB, bEachItem, 2);
    DesFromSym(S, D);
    If D.Ref Then
    Begin
      EmitSlotLoad(D);
      Emit(opSwap);
      Emit(opStInd);
    End
    Else DesStore(D);
    VBlock('NEXT', '', '', '');
    VExpect('NEXT');
    PushTmp(Idx);
    Emit1(opPushI, 1);
    Emit(opAdd);
    PopTmp(Idx);
    Emit1(opJmp, L0);
    PatchAt(J, Here);
    PatchChain(VbExitFor, Here);
    VbExitFor := SaveExit;
    Exit;
  End;
  Nm := TokS;
  VNext;
  S := VVar(Nm, True);
  DesFromSym(S, D);
  VExpect('=');
  Dummy := VExpr;
  If D.Ref Then
  Begin
    DesAddr(D);
    Emit(opSwap);
    D.Kind := dkAddr;
  End;
  DesStore(D);
  DesFromSym(S, D);
  VExpect('TO');
  Tmp := AllocVar(1);
  Dummy := VExpr;
  PopTmp(Tmp);
  TmpStep := AllocVar(1);
  HasStep := IsKw('STEP');
  If HasStep Then
  Begin
    VNext;
    Dummy := VExpr;
  End
  Else Emit1(opPushI, 1);
  PopTmp(TmpStep);
  { tant que (pas >= 0 et i <= fin) ou (pas < 0 et i >= fin) }
  L0 := Here;
  PushTmp(TmpStep); Emit1(opPushI, 0); Emit(opGe);
  DesLoad(D); DesFromSym(S, D);
  PushTmp(Tmp); Emit(opLe); Emit(opAnd);
  PushTmp(TmpStep); Emit1(opPushI, 0); Emit(opLt);
  DesLoad(D); DesFromSym(S, D);
  PushTmp(Tmp); Emit(opGe); Emit(opAnd);
  Emit(opOr);
  Emit1(opJz, 0);
  J := Here - 1;
  VBlock('NEXT', '', '', '');
  VExpect('NEXT');
  If Tok = tkId Then VNext;
  If D.Ref Then
  Begin
    DesAddr(D);
    D.Kind := dkAddr;
    Emit(opDup);
    Emit(opLdInd);
  End
  Else DesLoad(D);
  PushTmp(TmpStep);
  Emit(opAdd);
  DesFromSym(S, D);
  If D.Ref Then
  Begin
    { adresse deja sous la valeur }
    Emit(opStInd);
  End
  Else DesStore(D);
  Emit1(opJmp, L0);
  PatchAt(J, Here);
  PatchChain(VbExitFor, Here);
  VbExitFor := SaveExit;
End;

Procedure VDo;
Var L0, J, SaveExit, Cond : LongInt; Until_ : Boolean;
Begin
  VNext;
  SaveExit := VbExitDo;
  VbExitDo := -1;
  L0 := Here;
  J := -1;
  If IsKw('WHILE') Or IsKw('UNTIL') Then
  Begin
    Until_ := IsKw('UNTIL');
    VNext;
    Dummy := VExpr;
    If Until_ Then Emit1(opJnz, 0) Else Emit1(opJz, 0);
    J := Here - 1;
  End;
  VBlock('LOOP', '', '', '');
  VExpect('LOOP');
  If IsKw('WHILE') Or IsKw('UNTIL') Then
  Begin
    Until_ := IsKw('UNTIL');
    VNext;
    Dummy := VExpr;
    If Until_ Then Emit1(opJz, L0) Else Emit1(opJnz, L0);
  End
  Else Emit1(opJmp, L0);
  If J >= 0 Then PatchAt(J, Here);
  PatchChain(VbExitDo, Here);
  VbExitDo := SaveExit;
End;

Procedure VWhile;
Var L0, J, SaveExit : LongInt;
Begin
  VNext;
  SaveExit := VbExitDo;
  VbExitDo := -1;
  L0 := Here;
  Dummy := VExpr;
  Emit1(opJz, 0);
  J := Here - 1;
  VBlock('WEND', '', '', '');
  VExpect('WEND');
  Emit1(opJmp, L0);
  PatchAt(J, Here);
  PatchChain(VbExitDo, Here);
  VbExitDo := SaveExit;
End;

Procedure VSelect;
Var Tmp, JEnd, J : LongInt;
Begin
  VNext;
  VExpect('CASE');
  Tmp := AllocVar(1);
  Dummy := VExpr;
  PopTmp(Tmp);
  VSkipEol;
  JEnd := -1;
  While (CErr = '') And IsKw('CASE') Do
  Begin
    VNext;
    If IsKw('ELSE') Then
    Begin
      VNext;
      VBlock('CASE', 'END', '', '');
      Break;
    End;
    Emit1(opPushB, 0);
    Repeat
      PushTmp(Tmp);
      If IsKw('IS') Then
      Begin
        VNext;
        If IsSym('<') Or IsSym('<=') Or IsSym('>') Or IsSym('>=') Or IsSym('=') Or IsSym('<>') Then
        Begin
          TokS := TokS;
        End;
      End;
      Dummy := VCat;
      If IsKw('TO') Then
      Begin
        VNext;
        Emit(opGe);
        PushTmp(Tmp);
        Dummy := VCat;
        Emit(opLe);
        Emit(opAnd);
      End
      Else Emit(opEq);
      Emit(opOr);
      If IsSym(',') Then VNext Else Break;
    Until CErr <> '';
    Emit1(opJz, 0);
    J := Here - 1;
    VBlock('CASE', 'END', '', '');
    Emit1(opJmp, JEnd);
    JEnd := Here - 1;
    PatchAt(J, Here);
  End;
  VExpect('END');
  VExpect('SELECT');
  PatchChain(JEnd, Here);
End;

{ Sub et Function (deja declarees par le premier passage) }
Procedure VSubDef(IsFunc : Boolean);
Var S, K, J, Save, SLoc, SMax, SExit, SIn, EnterAt, T, P : LongInt; Nm : String;
Begin
  VNext;
  Nm := TokS;
  VNext;
  S := -1;
  For K := NSym - 1 DownTo 0 Do
    If (Syms[K].Name = Nm) And ((Syms[K].Kind = skProc) Or (Syms[K].Kind = skFunc)) Then
    Begin
      S := K;
      Break;
    End;
  If S < 0 Then
  Begin
    CError('Sub ou Function inconnue : ' + Nm);
    Exit;
  End;
  { parametres : deja connus ; sauter la liste }
  If IsSym('(') Then
  Begin
    While (CErr = '') And Not IsSym(')') And (Tok <> tkEof) And (Tok <> vtkEol) Do VNext;
    VExpect(')');
  End;
  Emit1(opJmp, 0);
  J := Here - 1;
  Syms[S].Adr := Here;
  PatchChain(Syms[S].Patch, Here);
  Syms[S].Patch := -1;
  Save := NSym; SLoc := LocTop; SMax := LocMax; SExit := VbExitSub; SIn := VbInSub;
  Inc(CurLvl);
  VbExitSub := -1; VbInSub := S;
  LocTop := 4 + Syms[S].NPar; LocMax := LocTop;
  Emit2(opEnter, 0, Syms[S].NPar);
  EnterAt := Here - 2;
  For K := 0 To Syms[S].NPar - 1 Do
  Begin
    P := Syms[S].PBase + K;
    T := AddSym(PName[P], skVar);
    Syms[T].Ty := TyVar; Syms[T].Lvl := CurLvl; Syms[T].Adr := 4 + K; Syms[T].Ref := PRef[P];
  End;
  VBlock('END', '', '', '');
  VExpect('END');
  If IsFunc Then VExpect('FUNCTION') Else VExpect('SUB');
  PatchChain(VbExitSub, Here);
  Emit1(opRet, Ord(IsFunc));
  PatchAt(EnterAt, LocMax);
  NSym := Save;
  Dec(CurLvl);
  LocTop := SLoc; LocMax := SMax; VbExitSub := SExit; VbInSub := SIn;
  PatchAt(J, Here);
End;

Procedure VStatement;
Var S, K, N : LongInt; D : TDes; Nm : String; C : TCell; T : LongInt;
Begin
  If CErr <> '' Then Exit;
  EmitLine;
  Emit(opErrClr);
  If Tok = tkHtml Then
  Begin
    Emit2(opHtml, AddStrB(@Src.P^[TokOff], TokLen), TokLen);
    VNext;
    Exit;
  End;
  If Tok = tkEcho Then
  Begin
    VNext;
    Dummy := VExpr;
    Emit1(opPushI, -1); Emit1(opPushI, -1);
    Emit(opWrite);
    If Tok = tkEchoEnd Then VNext Else CError('''%>'' attendu');
    Exit;
  End;
  If VIsEol Then Exit;
  If IsSym('.') Then
  Begin
    VAssignTarget(D);
    If IsSym('=') Then
    Begin
      VNext;
      Dummy := VExpr;
      DesStore(D);
    End
    Else If D.Kind = dkMember Then
    Begin
      Emit2(opMember, D.Mem, D.Argc);
      Emit(opPop);
    End;
    Exit;
  End;
  If Tok <> tkId Then
  Begin
    CError('instruction attendue');
    Exit;
  End;
  Nm := TokS;
  If (Nm = 'DIM') Or (Nm = 'PUBLIC') Or (Nm = 'PRIVATE') Then
  Begin
    VNext;
    If IsKw('SUB') Or IsKw('FUNCTION') Then
    Begin
      VSubDef(IsKw('FUNCTION'));
      Exit;
    End;
    If IsKw('CONST') Then
    Begin
      Nm := 'CONST';
    End
    Else
    Begin
      VDim(False);
      Exit;
    End;
  End;
  If Nm = 'REDIM' Then
  Begin
    VNext;
    VDim(True);
    Exit;
  End;
  If Nm = 'CONST' Then
  Begin
    VNext;
    Repeat
      Nm := TokS;
      VNext;
      VExpect('=');
      If Tok = tkStr Then
      Begin
        C.T := vtKStr; C.I := TokOff; C.L := TokLen;
        VNext;
      End
      Else If Tok = tkInt Then
      Begin
        MkInt(TokI, C);
        VNext;
      End
      Else If IsSym('-') Then
      Begin
        VNext;
        If Tok = tkInt Then MkInt(-TokI, C) Else MkReal(-TokR, C);
        VNext;
      End
      Else If Tok = tkReal Then
      Begin
        MkReal(TokR, C);
        VNext;
      End
      Else If IsKw('TRUE') Or IsKw('FALSE') Then
      Begin
        MkBool(IsKw('TRUE'), C);
        VNext;
      End
      Else
      Begin
        T := VVar(TokS, False);
        If (T >= 0) And (Syms[T].Kind = skConst) Then C := Syms[T].CV Else CError('constante attendue');
        VNext;
      End;
      S := AddSym(Nm, skConst);
      Syms[S].CV := C; Syms[S].Ty := TyVar;
      If IsSym(',') Then VNext Else Break;
    Until CErr <> '';
    Exit;
  End;
  If Nm = 'OPTION' Then
  Begin
    While Not VIsEol Do VNext;
    Exit;
  End;
  If (Nm = 'SUB') Or (Nm = 'FUNCTION') Then
  Begin
    VSubDef(Nm = 'FUNCTION');
    Exit;
  End;
  If Nm = 'IF' Then
  Begin
    VIf;
    Exit;
  End;
  If Nm = 'FOR' Then
  Begin
    VFor;
    Exit;
  End;
  If Nm = 'DO' Then
  Begin
    VDo;
    Exit;
  End;
  If Nm = 'WHILE' Then
  Begin
    VWhile;
    Exit;
  End;
  If Nm = 'SELECT' Then
  Begin
    VSelect;
    Exit;
  End;
  If Nm = 'WITH' Then
  Begin
    VNext;
    Dummy := VExpr;
    K := AllocVar(1);
    PopTmp(K);
    If NVbWith < 8 Then
    Begin
      VbWith[NVbWith] := K;
      Inc(NVbWith);
    End;
    VBlock('END', '', '', '');
    VExpect('END');
    VExpect('WITH');
    Dec(NVbWith);
    Exit;
  End;
  If Nm = 'EXIT' Then
  Begin
    VNext;
    If IsKw('FOR') Then
    Begin
      Emit1(opJmp, VbExitFor);
      VbExitFor := Here - 1;
    End
    Else If IsKw('DO') Then
    Begin
      Emit1(opJmp, VbExitDo);
      VbExitDo := Here - 1;
    End
    Else If IsKw('SUB') Or IsKw('FUNCTION') Then
    Begin
      If CurLvl = 0 Then Emit(opHalt)
      Else
      Begin
        Emit1(opJmp, VbExitSub);
        VbExitSub := Here - 1;
      End;
    End;
    VNext;
    Exit;
  End;
  If Nm = 'ON' Then
  Begin
    VNext;
    VExpect('ERROR');
    If IsKw('RESUME') Then
    Begin
      VNext;
      VExpect('NEXT');
      Emit1(opPushI, 1);
    End
    Else
    Begin
      VExpect('GOTO');
      VNext;
      Emit1(opPushI, 0);
    End;
    Emit2(opCallB, bOnError, 1);
    Exit;
  End;
  If Nm = 'CALL' Then
  Begin
    VNext;
    Nm := TokS;
    S := VVar(Nm, False);
    If (S >= 0) And ((Syms[S].Kind = skProc) Or (Syms[S].Kind = skFunc)) Then
    Begin
      VNext;
      VCall(S, True);
      If Syms[S].Kind = skFunc Then Emit(opPop);
    End
    Else
    Begin
      VAssignTarget(D);
      If D.Kind = dkMember Then
      Begin
        Emit2(opMember, D.Mem, D.Argc);
        Emit(opPop);
      End;
    End;
    Exit;
  End;
  If Nm = 'SET' Then VNext;
  Nm := TokS;
  S := VVar(Nm, False);
  If (S >= 0) And ((Syms[S].Kind = skProc) Or ((Syms[S].Kind = skFunc) And (CurLvl <> Syms[S].Lvl + 1))) Then
  Begin
    VNext;
    VCall(S, False);
    If Syms[S].Kind = skFunc Then Emit(opPop);
    Exit;
  End;
  If (S < 0) And VbBuiltin(Nm, K) Then
  Begin
    VNext;
    N := VArgs(IsSym('('));
    Emit2(opCallB, K, N);
    If K <> bRandomize Then Emit(opPop);
    Exit;
  End;
  VAssignTarget(D);
  If IsSym('=') Then
  Begin
    VNext;
    If (D.Kind = dkVar) And D.Ref Then DesAddr(D);
    Dummy := VExpr;
    DesStore(D);
  End
  Else If D.Kind = dkMember Then
  Begin
    Emit2(opMember, D.Mem, D.Argc);
    Emit(opPop);
  End
  Else CError('''='' attendu');
End;

Procedure VBlock(Stop1, Stop2, Stop3, Stop4 : String);
Begin
  While (CErr = '') And (Tok <> tkEof) Do
  Begin
    If (Tok = tkId) And ((TokS = Stop1) Or (TokS = Stop2) Or (TokS = Stop3) Or ((Stop4 <> '') And (TokS = Stop4))) Then
    Begin
      { END IF / END SUB... : END suivi du bon mot }
      Exit;
    End;
    VStatement;
    If Not VIsEol And Not IsKw(Stop1) And Not IsKw(Stop2) And Not IsKw(Stop3) And (CErr = '') And (Tok <> tkHtml) And
       (Tok <> tkEcho) And (Tok <> tkEchoEnd) Then CError('fin de ligne attendue');
    While Tok = vtkEol Do VNext;
  End;
End;

{ premier passage : Sub, Function (parametres) et variables de la page }
Procedure VPrescan;
Var X : TLexSave; Depth, S, N : LongInt; Nm : String; IsF, Ref : Boolean; LineStart : Boolean;
Begin
  LineStart := True;
  Depth := 0;
  While (CErr = '') And (Tok <> tkEof) Do
  Begin
    If LineStart And (Tok = tkId) And ((TokS = 'SUB') Or (TokS = 'FUNCTION') Or
       (((TokS = 'PUBLIC') Or (TokS = 'PRIVATE')))) Then
    Begin
      If (TokS = 'PUBLIC') Or (TokS = 'PRIVATE') Then
      Begin
        VNext;
        If Not (IsKw('SUB') Or IsKw('FUNCTION')) Then
        Begin
          LineStart := False;
          Continue;
        End;
      End;
      IsF := TokS = 'FUNCTION';
      VNext;
      Nm := TokS;
      If Depth = 0 Then
      Begin
        If IsF Then S := AddSym(Nm, skFunc) Else S := AddSym(Nm, skProc);
        Syms[S].Adr := -1; Syms[S].PBase := NParT; Syms[S].Lvl := 0; Syms[S].RetTy := TyVar; Syms[S].Ty := TyVar;
        VNext;
        N := 0;
        If IsSym('(') Then
        Begin
          VNext;
          While (CErr = '') And Not IsSym(')') And (Tok <> tkEof) And (Tok <> vtkEol) Do
          Begin
            Ref := True;
            If IsKw('BYVAL') Then
            Begin
              Ref := False;
              VNext;
            End
            Else If IsKw('BYREF') Then VNext;
            If (Tok = tkId) And (NParT < MaxPar) Then
            Begin
              PName[NParT] := TokS; PTy[NParT] := TyVar; PRef[NParT] := Ref;
              Inc(NParT);
              Inc(N);
            End;
            VNext;
            If IsSym('(') Then
            Begin
              VNext;
              VNext;
            End;
            If IsKw('AS') Then
            Begin
              VNext;
              VNext;
            End;
            If IsSym(',') Then VNext;
          End;
        End;
        Syms[S].NPar := N;
      End;
      Inc(Depth);
    End
    Else If LineStart And IsKw('END') Then
    Begin
      VNext;
      If (IsKw('SUB') Or IsKw('FUNCTION')) And (Depth > 0) Then Dec(Depth);
    End;
    LineStart := (Tok = vtkEol) Or (Tok = tkHtml);
    VNext;
  End;
End;

Function CompileAsp(K : LongInt; Path, Root : String) : String;
Var X : TLexSave;
Begin
  CP := K;
  ResetPage(K);
  BufInit(Src);
  CErr := ''; CErrLine := 0;
  SiteRoot := Root;
  SrcDir := Path;
  While (Length(SrcDir) > 0) And (SrcDir[Length(SrcDir)] <> '\') Do Delete(SrcDir, Length(SrcDir), 1);
  If Not LoadSource(Path, 0, Src) Then
  Begin
    CompileAsp := 'fichier illisible : ' + Path;
    Exit;
  End;
  CurLvl := 0; LocTop := 0; LocMax := 0; GlobTop := 0; CurFunc := -1; NExit := 0; LoopDepth := 0; NWith := 0;
  NVbWith := 0; VbExitSub := -1; VbExitFor := -1; VbExitDo := -1; VbInSub := -1;
  PredefSyms;
  Dummy := AddSym('ERR', skObj);
  Syms[NSym - 1].Adr := obErr; Syms[NSym - 1].Ty := TyVar;
  { premier passage }
  SPos := 0; SLine := 1; InHtml := True; InEcho := False;
  VNext;
  VPrescan;
  { compilation }
  CErr := '';
  SPos := 0; SLine := 1; InHtml := True; InEcho := False;
  VNext;
  While (CErr = '') And (Tok <> tkEof) Do
  Begin
    VStatement;
    If (CErr = '') And Not VIsEol And (Tok <> tkEchoEnd) Then CError('fin de ligne attendue (' + TokS + ')');
    While Tok = vtkEol Do VNext;
  End;
  Emit(opHalt);
  Pages[K].NGlob := GlobTop;
  BufFree(Src);
  If CErr <> '' Then
  Begin
    CompileAsp := 'ligne ' + IStr(CErrLine) + ' : ' + CErr;
    ResetPage(K);
  End
  Else
  Begin
    Pages[K].Used := True;
    CompileAsp := '';
  End;
End;

{ ==================================================================== }
{ Compilateur PHP vers la meme machine que PSP et ASP                   }
{ Le lexique (nombres decimaux, hexadecimaux 0x, octaux 0o et 0,        }
{ binaires 0b, separateurs _, echappements des chaines \n \t \xHH \u(n) }
{ \0..\777, mots-cles, constantes PHP_EOL, M_PI...) vient du            }
{ compilateur PHPCW32.PAS de DEV-COOLS ; l'analyse et la generation     }
{ visent ici la machine du Serveur Web (pages compilees une fois,       }
{ executees par tranches) au lieu de l'assembleur 80386.                }
{ Langage : HTML et <?php ?>, <?= ?>, <? ?> ; variables, tableaux        }
{ ordonnes (cles entieres et chaines), chaines "..." interpolees        }
{ ($x, $a[k], $o->p, accolades $expr), heredoc et nowdoc ; if/elseif/else,}
{ while, do-while, for, foreach, switch (et la syntaxe : ... endif;) ;   }
{ break n, continue n ; fonctions (valeurs par defaut, &references,     }
{ global, static, recursion, appel avant la definition) ; include et    }
{ require (_once) ; list() et [...] = ; operateurs de PHP 8 (. apres +, }
{ ??, ??=, <=>, **, ===) ; superglobales $_GET, $_POST, $_REQUEST,      }
{ $_COOKIE, $_SERVER, $_SESSION ; mysqli, pg_* et PDO.                   }
{ ==================================================================== }

Const
  tkVar = 31; tkIStr = 32; tkCast = 33;
  MaxPGlob = 1024;

Var
  PTokRaw : String;              { identificateur tel qu'ecrit }
  PIRaw : TBuf;                  { chaine interpolee (texte brut) }
  PGName : Array[0..MaxPGlob - 1] Of String[47];
  PGAdr : Array[0..MaxPGlob - 1] Of LongInt;
  NPG : LongInt;
  PDefK : Array[0..MaxPar - 1] Of Byte;    { 0 aucune, 1 constante, 2 tableau vide }
  PDefC : Array[0..MaxPar - 1] Of TCell;
  PFnExit : LongInt;
  PInFn : LongInt;
  PVarLoad : Boolean;            { la derniere expression : une variable lue }
  PSuperAt : Array[0..7] Of LongInt;

Function PNext0 : Boolean; Forward;
Procedure PNext; Forward;
Function ConstExprP(Var C : TCell) : Boolean; Forward;
Procedure PIssetOne; Forward;

{ --- source : include et require d'un nom constant, recopies --- }
Var PIncCode : Boolean;            { le dernier fichier lu finit dans le code PHP }

Function LoadPhpSource(Path : String; Depth : LongInt; Var Out_ : TBuf; Var Done_ : String) : Boolean;
Var B : TBuf; K, E, J, Q, St : LongInt; InCode : Boolean; W, Nm, Dir, Full : String; Once : Boolean; Ch : Byte;

  Function At(I : LongInt) : Byte;
  Begin
    If I < B.Len Then At := B.P^[I] Else At := 0;
  End;

  Function IsW(C : Byte) : Boolean;
  Begin
    IsW := ((C >= 65) And (C <= 90)) Or ((C >= 97) And (C <= 122)) Or ((C >= 48) And (C <= 57)) Or (C = 95);
  End;

Begin
  LoadPhpSource := False;
  If Depth > 8 Then Exit;
  If Not ReadFileBuf(Path, B, 4194304) Then Exit;
  Dir := Path;
  While (Length(Dir) > 0) And (Dir[Length(Dir)] <> '\') And (Dir[Length(Dir)] <> '/') Do Delete(Dir, Length(Dir), 1);
  InCode := False;
  K := 0;
  While K < B.Len Do
  Begin
    Ch := B.P^[K];
    If Not InCode Then
    Begin
      If (Ch = 60) And (At(K + 1) = 63) Then InCode := True;
      BufAddC(Out_, Ch);
      Inc(K);
      Continue;
    End;
    { dans le code : chaines et commentaires recopies tels quels }
    If (Ch = 63) And (At(K + 1) = 62) Then
    Begin
      InCode := False;
      BufAddC(Out_, Ch);
      Inc(K);
      Continue;
    End;
    If (Ch = 39) Or (Ch = 34) Then
    Begin
      BufAddC(Out_, Ch);
      Inc(K);
      While (K < B.Len) And (B.P^[K] <> Ch) Do
      Begin
        If B.P^[K] = 92 Then
        Begin
          BufAddC(Out_, B.P^[K]);
          Inc(K);
        End;
        If K < B.Len Then BufAddC(Out_, B.P^[K]);
        Inc(K);
      End;
      If K < B.Len Then BufAddC(Out_, B.P^[K]);
      Inc(K);
      Continue;
    End;
    If ((Ch = 47) And (At(K + 1) = 47)) Or (Ch = 35) Then
    Begin
      While (K < B.Len) And (B.P^[K] <> 10) And Not ((B.P^[K] = 63) And (At(K + 1) = 62)) Do
      Begin
        BufAddC(Out_, B.P^[K]);
        Inc(K);
      End;
      Continue;
    End;
    If (Ch = 47) And (At(K + 1) = 42) Then
    Begin
      While (K < B.Len) And Not ((B.P^[K] = 42) And (At(K + 1) = 47)) Do
      Begin
        BufAddC(Out_, B.P^[K]);
        Inc(K);
      End;
      Continue;
    End;
    { include 'nom.php'; require_once("nom.php"); }
    If ((Ch Or 32) = Ord('i')) Or ((Ch Or 32) = Ord('r')) Then
      If (K = 0) Or Not IsW(At(K - 1)) Then
      Begin
        W := '';
        E := K;
        While IsW(At(E)) And (Length(W) < 20) Do
        Begin
          W := W + UpCase(Chr(At(E)));
          Inc(E);
        End;
        If (W = 'INCLUDE') Or (W = 'REQUIRE') Or (W = 'INCLUDE_ONCE') Or (W = 'REQUIRE_ONCE') Then
        Begin
          Once := Pos('_ONCE', W) > 0;
          J := E;
          While At(J) In [32, 9, 13, 10] Do Inc(J);
          If At(J) = 40 Then
          Begin
            Inc(J);
            While At(J) In [32, 9] Do Inc(J);
          End;
          Q := At(J);
          If (Q = 39) Or (Q = 34) Then
          Begin
            Nm := '';
            Inc(J);
            While (J < B.Len) And (At(J) <> Q) And (Length(Nm) < 200) Do
            Begin
              Nm := Nm + Chr(At(J));
              Inc(J);
            End;
            Inc(J);
            While At(J) In [32, 9] Do Inc(J);
            If At(J) = 41 Then Inc(J);
            While At(J) In [32, 9] Do Inc(J);
            If (At(J) = 59) And (Pos('$', Nm) = 0) Then
            Begin
              Inc(J);
              For St := 1 To Length(Nm) Do If Nm[St] = '/' Then Nm[St] := '\';
              If (Nm <> '') And (Nm[1] = '\') Then Full := SiteRoot + Nm
              Else If (Length(Nm) > 1) And (Nm[2] = ':') Then Full := Nm
              Else Full := Dir + Nm;
              If Not (Once And (Pos('|' + UpStr(Full) + '|', Done_) > 0)) Then
              Begin
                Done_ := Done_ + '|' + UpStr(Full) + '|';
                BufAdd(Out_, '?>');
                If Not LoadPhpSource(Full, Depth + 1, Out_, Done_) Then
                  BufAdd(Out_, '<?php trigger_error(''include : fichier introuvable : ' + Nm + '''); ?>')
                Else If PIncCode Then
                  BufAdd(Out_, #10'?>');           { le fichier inclus finit dans le code (sans ?>) }
                BufAdd(Out_, '<?php ');
              End;
              K := J;
              Continue;
            End;
          End;
        End;
      End;
    BufAddC(Out_, Ch);
    Inc(K);
  End;
  BufFree(B);
  PIncCode := InCode;
  LoadPhpSource := True;
End;

{ ==================================================================== }
{ Lexique                                                               }
{ ==================================================================== }

Function PIsW(C : Char) : Boolean;
Begin
  PIsW := ((C >= 'A') And (C <= 'Z')) Or ((C >= 'a') And (C <= 'z')) Or ((C >= '0') And (C <= '9')) Or (C = '_') Or
          (Ord(C) >= 128);
End;

{ sequence d'echappement d'une chaine "..." en Src[SPos] (apres \) }
Procedure PEscape(Var B : TBuf; Var I : LongInt; Var S_ : TBuf);
Var C : Char; V, N : LongInt;
Begin
  C := Chr(S_.P^[I]);
  Case C Of
    'n' : BufAddC(B, 10);
    't' : BufAddC(B, 9);
    'r' : BufAddC(B, 13);
    'v' : BufAddC(B, 11);
    'e' : BufAddC(B, 27);
    'f' : BufAddC(B, 12);
    '\', '$', '"' : BufAddC(B, Ord(C));
    'x' :
      If (I + 1 < S_.Len) And (HexV(Chr(S_.P^[I + 1])) >= 0) Then
      Begin
        V := 0; N := 0;
        While (N < 2) And (I + 1 < S_.Len) And (HexV(Chr(S_.P^[I + 1])) >= 0) Do
        Begin
          V := V * 16 + HexV(Chr(S_.P^[I + 1]));
          Inc(I); Inc(N);
        End;
        BufAddC(B, V);
      End
      Else
      Begin
        BufAddC(B, 92); BufAddC(B, Ord(C));
      End;
    'u' :
      If (I + 1 < S_.Len) And (S_.P^[I + 1] = 123) Then
      Begin
        Inc(I);
        V := 0;
        While (I + 1 < S_.Len) And (HexV(Chr(S_.P^[I + 1])) >= 0) Do
        Begin
          V := V * 16 + HexV(Chr(S_.P^[I + 1]));
          Inc(I);
        End;
        If (I + 1 < S_.Len) And (S_.P^[I + 1] = 125) Then Inc(I);
        AddUtf8(B, V);
      End
      Else
      Begin
        BufAddC(B, 92); BufAddC(B, Ord(C));
      End;
    '0'..'7' :
      Begin
        V := Ord(C) - 48; N := 1;
        While (N < 3) And (I + 1 < S_.Len) And (S_.P^[I + 1] >= 48) And (S_.P^[I + 1] <= 55) Do
        Begin
          V := V * 8 + S_.P^[I + 1] - 48;
          Inc(I); Inc(N);
        End;
        BufAddC(B, V And 255);
      End;
  Else
    BufAddC(B, 92); BufAddC(B, Ord(C));
  End;
End;

Procedure PSetStr(Var B : TBuf);
Var V : LongInt;
Begin
  Tok := tkStr;
  TokOff := AddStrB(B.P, B.Len);
  TokLen := B.Len;
  V := B.Len;
  If V > 255 Then V := 255;
  TokS[0] := Chr(V);
  If V > 0 Then Move(B.P^[0], TokS[1], V);
End;

{ chaine "..." ou heredoc : texte brut en Raw ; sans $ a interpoler :
  lexeme chaine, sinon tkIStr (PIRaw) }
Procedure PDqString(Var Raw : TBuf);
Var B : TBuf; K : LongInt; Interp : Boolean; C : Byte;
Begin
  Interp := False;
  K := 0;
  While K < Raw.Len Do
  Begin
    C := Raw.P^[K];
    If C = 92 Then Inc(K)
    Else If (C = 36) And (K + 1 < Raw.Len) And (PIsW(Chr(Raw.P^[K + 1])) And Not ((Raw.P^[K + 1] >= 48) And
            (Raw.P^[K + 1] <= 57))) Then Interp := True
    Else If (C = 123) And (K + 1 < Raw.Len) And (Raw.P^[K + 1] = 36) Then Interp := True;
    Inc(K);
  End;
  If Interp Then
  Begin
    PIRaw.Len := 0;
    BufAddB(PIRaw, Raw.P, Raw.Len);
    Tok := tkIStr;
    Exit;
  End;
  BufInit(B);
  K := 0;
  While K < Raw.Len Do
  Begin
    If (Raw.P^[K] = 92) And (K + 1 < Raw.Len) Then
    Begin
      Inc(K);
      PEscape(B, K, Raw);
    End
    Else BufAddC(B, Raw.P^[K]);
    Inc(K);
  End;
  PSetStr(B);
  BufFree(B);
End;

Function PNext0 : Boolean;
Var C, Q : Char; S, U : String; V, K, Base, J, Ind : LongInt; Lit, Raw : TBuf; R : Double; Real_ : Boolean;
    Id, Lbl : String; Nowdoc : Boolean;
Begin
  PNext0 := True;
  TokLine := SLine;
  If SPos >= Src.Len Then
  Begin
    Tok := tkEof;
    Exit;
  End;
  If InHtml Then
  Begin
    V := SPos;
    While (SPos < Src.Len) And Not ((SrcCh(SPos) = '<') And (SrcCh(SPos + 1) = '?') And
          Not ((UpCase(SrcCh(SPos + 2)) = 'X') And (UpCase(SrcCh(SPos + 3)) = 'M') And (UpCase(SrcCh(SPos + 4)) = 'L'))) Do
    Begin
      If SrcCh(SPos) = #10 Then Inc(SLine);
      Inc(SPos);
    End;
    If SPos > V Then
    Begin
      Tok := tkHtml; TokOff := V; TokLen := SPos - V;
      Exit;
    End;
    If SPos >= Src.Len Then
    Begin
      Tok := tkEof;
      Exit;
    End;
    SPos := SPos + 2;
    InHtml := False;
    If SrcCh(SPos) = '=' Then
    Begin
      Inc(SPos);
      InEcho := True;
      Tok := tkEcho;
      Exit;
    End;
    If (UpCase(SrcCh(SPos)) = 'P') And (UpCase(SrcCh(SPos + 1)) = 'H') And (UpCase(SrcCh(SPos + 2)) = 'P') Then
      SPos := SPos + 3;
    PNext0 := False;
    Exit;
  End;
  C := SrcCh(SPos);
  If (C = ' ') Or (C = #9) Or (C = #13) Then
  Begin
    Inc(SPos);
    PNext0 := False;
    Exit;
  End;
  If C = #10 Then
  Begin
    Inc(SPos); Inc(SLine);
    PNext0 := False;
    Exit;
  End;
  { commentaires }
  If ((C = '/') And (SrcCh(SPos + 1) = '/')) Or ((C = '#') And (SrcCh(SPos + 1) <> '[')) Then
  Begin
    While (SPos < Src.Len) And (SrcCh(SPos) <> #10) And Not ((SrcCh(SPos) = '?') And (SrcCh(SPos + 1) = '>')) Do
      Inc(SPos);
    PNext0 := False;
    Exit;
  End;
  If (C = '#') And (SrcCh(SPos + 1) = '[') Then
  Begin
    { attribut #[...] : ignore }
    While (SPos < Src.Len) And (SrcCh(SPos) <> ']') Do Inc(SPos);
    Inc(SPos);
    PNext0 := False;
    Exit;
  End;
  If (C = '/') And (SrcCh(SPos + 1) = '*') Then
  Begin
    SPos := SPos + 2;
    While (SPos < Src.Len) And Not ((SrcCh(SPos) = '*') And (SrcCh(SPos + 1) = '/')) Do
    Begin
      If SrcCh(SPos) = #10 Then Inc(SLine);
      Inc(SPos);
    End;
    SPos := SPos + 2;
    PNext0 := False;
    Exit;
  End;
  TokLine := SLine;
  { fin du code : ?> vaut un ; (et mange une fin de ligne) }
  If (C = '?') And (SrcCh(SPos + 1) = '>') Then
  Begin
    SPos := SPos + 2;
    InHtml := True;
    If SrcCh(SPos) = #10 Then
    Begin
      Inc(SPos); Inc(SLine);
    End
    Else If (SrcCh(SPos) = #13) And (SrcCh(SPos + 1) = #10) Then
    Begin
      SPos := SPos + 2; Inc(SLine);
    End;
    If InEcho Then
    Begin
      InEcho := False;
      Tok := tkEchoEnd;
      Exit;
    End;
    Tok := tkSym; TokS := ';';
    Exit;
  End;
  { variable }
  If (C = '$') And PIsW(SrcCh(SPos + 1)) And Not ((SrcCh(SPos + 1) >= '0') And (SrcCh(SPos + 1) <= '9')) Then
  Begin
    Inc(SPos);
    S := '';
    While PIsW(SrcCh(SPos)) Do
    Begin
      If Length(S) < 40 Then S := S + SrcCh(SPos);
      Inc(SPos);
    End;
    Tok := tkVar; TokS := S;
    Exit;
  End;
  { identificateur (\ de tete d'un nom d'espace ignore) }
  If (C = '\') And PIsW(SrcCh(SPos + 1)) Then
  Begin
    Inc(SPos);
    C := SrcCh(SPos);
  End;
  If PIsW(C) And Not ((C >= '0') And (C <= '9')) Then
  Begin
    S := ''; U := '';
    While PIsW(SrcCh(SPos)) Or ((SrcCh(SPos) = '\') And PIsW(SrcCh(SPos + 1))) Do
    Begin
      If SrcCh(SPos) = '\' Then
      Begin
        { Espace\Nom : on garde le dernier nom }
        S := ''; U := '';
      End
      Else If Length(S) < 40 Then
      Begin
        S := S + SrcCh(SPos);
        U := U + UpCase(SrcCh(SPos));
      End;
      Inc(SPos);
    End;
    { heredoc ou nowdoc ? non : seulement apres <<< }
    Tok := tkId; TokS := U; PTokRaw := S;
    Exit;
  End;
  { nombre }
  If ((C >= '0') And (C <= '9')) Or ((C = '.') And (SrcCh(SPos + 1) >= '0') And (SrcCh(SPos + 1) <= '9')) Then
  Begin
    Base := 10;
    If (C = '0') And (UpCase(SrcCh(SPos + 1)) = 'X') Then Base := 16
    Else If (C = '0') And (UpCase(SrcCh(SPos + 1)) = 'B') Then Base := 2
    Else If (C = '0') And (UpCase(SrcCh(SPos + 1)) = 'O') Then Base := 8
    Else If (C = '0') And (SrcCh(SPos + 1) >= '0') And (SrcCh(SPos + 1) <= '7') Then Base := 9;
    If Base <> 10 Then
    Begin
      If Base = 9 Then
      Begin
        Base := 8;
        Inc(SPos);
      End
      Else SPos := SPos + 2;
      R := 0;
      While (HexV(SrcCh(SPos)) >= 0) And (HexV(SrcCh(SPos)) < Base) Or (SrcCh(SPos) = '_') Do
      Begin
        If SrcCh(SPos) <> '_' Then R := R * Base + HexV(SrcCh(SPos));
        Inc(SPos);
      End;
      If R <= 2147483647.0 Then
      Begin
        Tok := tkInt; TokI := Trunc(R);
      End
      Else
      Begin
        Tok := tkReal; TokR := R;
      End;
      Exit;
    End;
    S := '';
    Real_ := False;
    While ((SrcCh(SPos) >= '0') And (SrcCh(SPos) <= '9')) Or (SrcCh(SPos) = '_') Or
          ((SrcCh(SPos) = '.') And Not Real_ And (SrcCh(SPos + 1) <> '.')) Do
    Begin
      If SrcCh(SPos) = '.' Then Real_ := True;
      If SrcCh(SPos) <> '_' Then S := S + SrcCh(SPos);
      Inc(SPos);
    End;
    If (UpCase(SrcCh(SPos)) = 'E') And ((SrcCh(SPos + 1) In ['0'..'9']) Or
       ((SrcCh(SPos + 1) In ['+', '-']) And (SrcCh(SPos + 2) In ['0'..'9']))) Then
    Begin
      Real_ := True;
      S := S + 'E';
      Inc(SPos);
      If SrcCh(SPos) In ['+', '-'] Then
      Begin
        S := S + SrcCh(SPos);
        Inc(SPos);
      End;
      While SrcCh(SPos) In ['0'..'9'] Do
      Begin
        S := S + SrcCh(SPos);
        Inc(SPos);
      End;
    End;
    If S[1] = '.' Then S := '0' + S;
    If S[Length(S)] = '.' Then S := S + '0';
    Val(S, R, K);
    If Real_ Or (R > 2147483647.0) Then
    Begin
      Tok := tkReal; TokR := R;
    End
    Else
    Begin
      Tok := tkInt; TokI := Trunc(R);
    End;
    Exit;
  End;
  { chaine '...' }
  If C = '''' Then
  Begin
    BufInit(Lit);
    Inc(SPos);
    While (SPos < Src.Len) And (SrcCh(SPos) <> '''') Do
    Begin
      If (SrcCh(SPos) = '\') And ((SrcCh(SPos + 1) = '''') Or (SrcCh(SPos + 1) = '\')) Then Inc(SPos);
      If SrcCh(SPos) = #10 Then Inc(SLine);
      BufAddC(Lit, Src.P^[SPos]);
      Inc(SPos);
    End;
    Inc(SPos);
    PSetStr(Lit);
    BufFree(Lit);
    Exit;
  End;
  { chaine "..." }
  If C = '"' Then
  Begin
    BufInit(Raw);
    Inc(SPos);
    While (SPos < Src.Len) And (SrcCh(SPos) <> '"') Do
    Begin
      If SrcCh(SPos) = '\' Then
      Begin
        BufAddC(Raw, 92);
        Inc(SPos);
      End;
      If SrcCh(SPos) = #10 Then Inc(SLine);
      If SPos < Src.Len Then BufAddC(Raw, Src.P^[SPos]);
      Inc(SPos);
    End;
    Inc(SPos);
    PDqString(Raw);
    BufFree(Raw);
    Exit;
  End;
  { heredoc <<<ID et nowdoc <<<'ID' }
  If (C = '<') And (SrcCh(SPos + 1) = '<') And (SrcCh(SPos + 2) = '<') Then
  Begin
    SPos := SPos + 3;
    While SrcCh(SPos) In [' ', #9] Do Inc(SPos);
    Nowdoc := SrcCh(SPos) = '''';
    If (SrcCh(SPos) = '''') Or (SrcCh(SPos) = '"') Then Inc(SPos);
    Lbl := '';
    While PIsW(SrcCh(SPos)) Do
    Begin
      Lbl := Lbl + SrcCh(SPos);
      Inc(SPos);
    End;
    If (SrcCh(SPos) = '''') Or (SrcCh(SPos) = '"') Then Inc(SPos);
    While (SPos < Src.Len) And (SrcCh(SPos) <> #10) Do Inc(SPos);
    Inc(SPos); Inc(SLine);
    BufInit(Raw);
    { lignes jusqu'a celle qui ne contient que l'etiquette (en retrait) }
    Ind := 0;
    Repeat
      J := SPos;
      K := 0;
      While SrcCh(J) In [' ', #9] Do
      Begin
        Inc(J); Inc(K);
      End;
      Id := '';
      V := J;
      While PIsW(SrcCh(V)) Do
      Begin
        Id := Id + SrcCh(V);
        Inc(V);
      End;
      If (Id = Lbl) And Not PIsW(SrcCh(V)) Then
      Begin
        Ind := K;
        SPos := V;
        Break;
      End;
      While (SPos < Src.Len) And (SrcCh(SPos) <> #10) Do
      Begin
        BufAddC(Raw, Src.P^[SPos]);
        Inc(SPos);
      End;
      If SPos >= Src.Len Then Break;
      BufAddC(Raw, 10);
      Inc(SPos); Inc(SLine);
    Until False;
    { derniere fin de ligne retiree ; CR des fins de ligne retires }
    If (Raw.Len > 0) And (Raw.P^[Raw.Len - 1] = 10) Then Dec(Raw.Len);
    BufInit(Lit);
    K := 0; J := 0;
    While K < Raw.Len Do
    Begin
      { retrait de la ligne de fin retire de chaque ligne }
      If (J < Ind) And (Raw.P^[K] In [32, 9]) Then
      Begin
        Inc(J); Inc(K);
        Continue;
      End;
      J := Ind;
      If Raw.P^[K] = 10 Then J := 0;
      If Raw.P^[K] <> 13 Then BufAddC(Lit, Raw.P^[K]);
      Inc(K);
    End;
    BufFree(Raw);
    If Nowdoc Then PSetStr(Lit) Else PDqString(Lit);
    BufFree(Lit);
    Exit;
  End;
  { conversion (int) (string)... }
  If C = '(' Then
  Begin
    J := SPos + 1;
    While SrcCh(J) In [' ', #9] Do Inc(J);
    Id := '';
    While PIsW(SrcCh(J)) Do
    Begin
      Id := Id + UpCase(SrcCh(J));
      Inc(J);
    End;
    While SrcCh(J) In [' ', #9] Do Inc(J);
    If SrcCh(J) = ')' Then
    Begin
      K := 0;
      If (Id = 'INT') Or (Id = 'INTEGER') Then K := 1
      Else If (Id = 'FLOAT') Or (Id = 'DOUBLE') Or (Id = 'REAL') Then K := 2
      Else If Id = 'STRING' Then K := 3
      Else If (Id = 'BOOL') Or (Id = 'BOOLEAN') Then K := 4
      Else If Id = 'ARRAY' Then K := 5
      Else If Id = 'OBJECT' Then K := 6
      Else If Id = 'UNSET' Then K := 7;
      If K > 0 Then
      Begin
        SPos := J + 1;
        Tok := tkCast; TokI := K;
        Exit;
      End;
    End;
  End;
  { symboles (le plus long d'abord) }
  Tok := tkSym;
  S := C + SrcCh(SPos + 1) + SrcCh(SPos + 2);
  If (S = '===') Or (S = '!==') Or (S = '<=>') Or (S = '**=') Or (S = '...') Or (S = '<<=') Or (S = '>>=') Or
     (S = '??=') Or (S = '?->') Then
  Begin
    TokS := S;
    SPos := SPos + 3;
    Exit;
  End;
  S := Copy(S, 1, 2);
  If (S = '==') Or (S = '!=') Or (S = '<>') Or (S = '<=') Or (S = '>=') Or (S = '&&') Or (S = '||') Or (S = '++') Or
     (S = '--') Or (S = '+=') Or (S = '-=') Or (S = '*=') Or (S = '/=') Or (S = '.=') Or (S = '%=') Or (S = '->') Or
     (S = '=>') Or (S = '::') Or (S = '<<') Or (S = '>>') Or (S = '??') Or (S = '**') Or (S = '&=') Or (S = '|=') Or
     (S = '^=') Then
  Begin
    TokS := S;
    SPos := SPos + 2;
    Exit;
  End;
  TokS := C;
  Inc(SPos);
End;

Procedure PNext;
Begin
  If CErr <> '' Then
  Begin
    Tok := tkEof;
    Exit;
  End;
  Repeat
  Until PNext0 Or (CErr <> '');
  If CErr <> '' Then Tok := tkEof;
End;

{ lexeme suivant (sans avancer) }
Function PPeekSym : String;
Var X : TLexSave;
Begin
  LexSave(X);
  PNext;
  If (Tok = tkSym) Or (Tok = tkId) Then PPeekSym := TokS Else PPeekSym := '';
  LexRestore(X);
End;

Procedure PExpect(S : String);
Begin
  If ((Tok = tkSym) Or (Tok = tkId)) And (TokS = S) Then PNext
  Else If CErr = '' Then
  Begin
    If Tok = tkEof Then CError('''' + S + ''' attendu (fin du fichier)')
    Else If Tok = tkVar Then CError('''' + S + ''' attendu au lieu de $' + TokS)
    Else If (Tok = tkSym) Or (Tok = tkId) Then CError('''' + S + ''' attendu au lieu de ''' + TokS + '''')
    Else CError('''' + S + ''' attendu');
  End;
End;

{ fin d'instruction : ; (ou ?> qui en tient lieu) }
Procedure PSemi;
Begin
  If IsSym(';') Then PNext
  Else If (Tok = tkEchoEnd) Or (Tok = tkEof) Or (Tok = tkHtml) Then
  Else PExpect(';');
End;

{ ==================================================================== }
{ Variables                                                             }
{ ==================================================================== }

Function PGlobSlot(Name : String) : LongInt;
Var K : LongInt;
Begin
  For K := 0 To NPG - 1 Do
    If PGName[K] = Name Then
    Begin
      PGlobSlot := PGAdr[K];
      Exit;
    End;
  If NPG >= MaxPGlob Then
  Begin
    CError('trop de variables globales');
    PGlobSlot := 0;
    Exit;
  End;
  PGName[NPG] := Name;
  PGAdr[NPG] := GlobTop;
  Inc(GlobTop);
  PGlobSlot := PGAdr[NPG];
  Inc(NPG);
End;

{ symbole (dans une fonction) ou cellule globale de la variable $Name }
Procedure PVarDes(Name : String; Var D : TDes);
Var S, K : LongInt;
Begin
  D.Kind := dkVar; D.Ty := TyVar; D.Ref := False; D.Up := 0;
  If CurLvl = 0 Then
  Begin
    D.Mode := 0;
    D.Adr := PGlobSlot(Name);
    Exit;
  End;
  S := -1;
  For K := NSym - 1 DownTo 0 Do
    If (Syms[K].Kind = skVar) And (Syms[K].Name = '$' + Copy(Name, 1, 30)) Then
    Begin
      S := K;
      Break;
    End;
  If S < 0 Then
  Begin
    S := AddSym('$' + Copy(Name, 1, 30), skVar);
    Syms[S].Ty := TyVar;
    Syms[S].Adr := AllocVar(1);
  End;
  DesFromSym(S, D);
End;

Procedure PAddrOf(Var D : TDes);
Begin
  If D.Ref Then EmitSlotLoad(D) Else EmitSlotAddr(D);
End;

Procedure PLoad(Var D : TDes);
Var X : TDes;
Begin
  X := D;
  DesLoad(X);
End;

{ ranger le sommet de la pile dans la variable (la valeur est retiree) }
Procedure PStore(Var D : TDes);
Var X : TDes;
Begin
  X := D;
  If X.Ref Then
  Begin
    EmitSlotLoad(X);
    Emit(opSwap);
    Emit(opStInd);
  End
  Else DesStore(X);
End;

Function PSuperNo(N : String) : LongInt;
Begin
  If N = '_GET' Then PSuperNo := 1 Else If N = '_POST' Then PSuperNo := 2 Else If N = '_REQUEST' Then PSuperNo := 3
  Else If N = '_COOKIE' Then PSuperNo := 4 Else If N = '_SERVER' Then PSuperNo := 5 Else If N = '_SESSION' Then PSuperNo := 6
  Else If N = '_FILES' Then PSuperNo := 7 Else If N = '_ENV' Then PSuperNo := 8 Else If N = 'GLOBALS' Then PSuperNo := 9
  Else PSuperNo := 0;
End;

Procedure PEmitSuper(N : LongInt);
Begin
  If N = 6 Then Emit1(opIsObj, obSession)
  Else Emit2(opPhp, psSuper, N);
End;

{ ==================================================================== }
{ Expressions                                                           }
{ ==================================================================== }

Function PExpr : LongInt; Forward;
Function PAssignE : LongInt; Forward;
Procedure PStatement; Forward;
Function PUnary : LongInt; Forward;

Procedure PToBool(T : LongInt);
Begin
  If T <> TyBool Then Emit1(opPhp, psBool);
End;

Procedure PCopyIfVar;
Begin
  If PVarLoad Then Emit1(opPhp, psCopy);
  PVarLoad := False;
End;

{ l'assignation qui suit un designateur : '=' '+=' ... '++' '--' ('' : aucune) }
Function PAssignAhead : String;
Var X : TLexSave; Depth : LongInt; Op : String;
Begin
  PAssignAhead := '';
  LexSave(X);
  PNext;
  Repeat
    If IsSym('[') Or IsSym('{') Then
    Begin
      Depth := 0;
      Repeat
        If IsSym('[') Or IsSym('{') Or IsSym('(') Then Inc(Depth)
        Else If IsSym(']') Or IsSym('}') Or IsSym(')') Then Dec(Depth);
        PNext;
      Until (Depth = 0) Or (Tok = tkEof);
    End
    Else If IsSym('->') Or IsSym('?->') Then
    Begin
      PNext;
      PNext;
      If IsSym('(') Then Break;
    End
    Else Break;
  Until CErr <> '';
  If Tok = tkSym Then
  Begin
    Op := TokS;
    If (Op = '=') Or (Op = '+=') Or (Op = '-=') Or (Op = '*=') Or (Op = '/=') Or (Op = '.=') Or (Op = '%=') Or
       (Op = '**=') Or (Op = '??=') Or (Op = '&=') Or (Op = '|=') Or (Op = '^=') Or (Op = '<<=') Or (Op = '>>=') Or
       (Op = '++') Or (Op = '--') Then PAssignAhead := Op;
  End;
  LexRestore(X);
End;

{ cible d'une assignation : variable (Kind 1), element (2 : conteneur et
  cle sur la pile ; 3 : conteneur, ajout []), propriete (4 : objet sur la
  pile, membre Mem) }
Type
  TPTarget = Record
    Kind : LongInt;
    D : TDes;
    Mem : LongInt;
  End;

Procedure PTarget(Var T : TPTarget);
Var Nm : String; Sn, M : LongInt;
Begin
  T.Kind := 1;
  If Tok <> tkVar Then
  Begin
    CError('variable attendue');
    Exit;
  End;
  Nm := TokS;
  PNext;
  Sn := PSuperNo(Nm);
  If (Sn > 0) And Not (IsSym('[')) Then
  Begin
    CError('$' + Nm + ' : un '#130'l'#130'ment est attendu ($' + Nm + '[...])');
    Exit;
  End;
  If Sn = 0 Then PVarDes(Nm, T.D);
  If Not IsSym('[') And Not IsSym('->') And Not IsSym('{') Then Exit;
  If IsSym('->') Then
  Begin
    PLoad(T.D);
    While IsSym('->') Do
    Begin
      PNext;
      M := MemberCode(TokS);
      If (Tok <> tkId) Or (M < 0) Then
      Begin
        CError('propri'#130't'#130' inconnue : ' + TokS);
        Exit;
      End;
      PNext;
      If IsSym('->') Then Emit2(opMember, M, 0)
      Else
      Begin
        T.Kind := 4; T.Mem := M;
        Exit;
      End;
    End;
    Exit;
  End;
  If Sn > 0 Then PEmitSuper(Sn)
  Else
  Begin
    PAddrOf(T.D);
    Emit1(opPhp, psArrW);
  End;
  While CErr = '' Do
  Begin
    If IsSym('[') Or IsSym('{') Then PNext Else Break;
    If IsSym(']') Then
    Begin
      PNext;
      If IsSym('[') Then
      Begin
        Emit1(opPhp, psSubPushW);
        Continue;
      End;
      T.Kind := 3;
      Exit;
    End;
    Dummy := PExpr;
    If IsSym('}') Then PNext Else PExpect(']');
    If IsSym('[') Then
    Begin
      Emit1(opPhp, psSubW);
      Continue;
    End;
    T.Kind := 2;
    Exit;
  End;
End;

{ valeur de la cible (la cible reste utilisable : Kind 2 dupliquee) }
Procedure PTargetLoad(Var T : TPTarget);
Begin
  Case T.Kind Of
    1 : PLoad(T.D);
    2 :
      Begin
        Emit1(opPhp, psDup2);
        Emit1(opPhp, psGet);
      End;
    4 :
      Begin
        Emit(opDup);
        Emit2(opMember, T.Mem, 0);
      End;
  End;
End;

{ ranger la valeur du sommet ; la valeur reste sur la pile }
Procedure PTargetStore(Var T : TPTarget);
Var Tmp : LongInt;
Begin
  Case T.Kind Of
    1 :
      Begin
        Emit(opDup);
        PStore(T.D);
      End;
    2 : Emit1(opPhp, psSet);
    3 : Emit1(opPhp, psPush);
    4 :
      Begin
        Tmp := AllocVar(1);
        Emit(opDup);
        PopTmp(Tmp);
        Emit2(opSetMember, T.Mem, 0);
        PushTmp(Tmp);
      End;
  End;
End;

{ operateur arithmetique ou de chaine d'une assignation composee }
Procedure PEmitOp(Op : String);
Begin
  If (Op = '+') Or (Op = '+=') Then Emit(opAdd)
  Else If (Op = '-') Or (Op = '-=') Then Emit(opSub)
  Else If (Op = '*') Or (Op = '*=') Then Emit(opMul)
  Else If (Op = '/') Or (Op = '/=') Then Emit(opDivR)
  Else If (Op = '%') Or (Op = '%=') Then Emit(opMod)
  Else If (Op = '.') Or (Op = '.=') Then Emit(opConcat)
  Else If (Op = '**') Or (Op = '**=') Then Emit2(opCallB, pfPow, 2)
  Else If (Op = '&') Or (Op = '&=') Then Emit(opAnd)
  Else If (Op = '|') Or (Op = '|=') Then Emit(opOr)
  Else If (Op = '^') Or (Op = '^=') Then Emit(opXor)
  Else If (Op = '<<') Or (Op = '<<=') Then Emit(opShl)
  Else If (Op = '>>') Or (Op = '>>=') Then Emit(opShr);
End;

{ assignation : la cible est en Tok (variable) ; la valeur reste sur la pile }
Procedure PAssign;
Var T : TPTarget; Op : String; J, J2 : LongInt;
Begin
  PTarget(T);
  If CErr <> '' Then Exit;
  Op := TokS;
  PNext;
  If Op = '=' Then
  Begin
    If IsSym('&') Then PNext;           { =& : copie (references non gerees) }
    If T.Kind = 2 Then
    Begin
      Dummy := PAssignE;
      PCopyIfVar;
      Emit1(opPhp, psSet);
    End
    Else
    Begin
      Dummy := PAssignE;
      PCopyIfVar;
      PTargetStore(T);
    End;
    Exit;
  End;
  If T.Kind = 3 Then
  Begin
    CError('[] ne peut '#136'tre lu');
    Exit;
  End;
  If (Op = '++') Or (Op = '--') Then
  Begin
    { postfixe : la valeur d'avant reste }
    If T.Kind = 1 Then
    Begin
      PLoad(T.D);
      Emit(opDup);
      Emit1(opPushI, 1);
      If Op = '++' Then Emit(opAdd) Else Emit(opSub);
      PStore(T.D);
    End
    Else If T.Kind = 2 Then
    Begin
      If Op = '++' Then Emit2(opPhp, psIncE, 1) Else Emit2(opPhp, psIncE, 2);
    End
    Else
    Begin
      PTargetLoad(T);
      Emit1(opPushI, 1);
      If Op = '++' Then Emit(opAdd) Else Emit(opSub);
      PTargetStore(T);
      Emit1(opPushI, 1);
      If Op = '++' Then Emit(opSub) Else Emit(opAdd);
    End;
    Exit;
  End;
  If Op = '??=' Then
  Begin
    PTargetLoad(T);
    Emit(opDup);
    Emit1(opPhp, psNotNull);
    Emit1(opJnz, 0);
    J := Here - 1;
    Emit(opPop);
    Dummy := PAssignE;
    PCopyIfVar;
    PTargetStore(T);
    Emit1(opJmp, 0);
    J2 := Here - 1;
    PatchAt(J, Here);
    { valeur deja presente : la cible (cle et conteneur) est retiree }
    If T.Kind = 2 Then Emit2(opPhp, psDrop2, 0)
    Else If T.Kind = 4 Then
    Begin
      Emit(opSwap);
      Emit(opPop);
    End;
    PatchAt(J2, Here);
    Exit;
  End;
  PTargetLoad(T);
  Dummy := PAssignE;
  PEmitOp(Op);
  PTargetStore(T);
End;

{ arguments d'un appel : nombre d'arguments }
Function PArgs : LongInt;
Var N : LongInt;
Begin
  N := 0;
  PExpect('(');
  If Not IsSym(')') Then
    Repeat
      If IsSym('...') Then PNext;
      { argument nomme nom: valeur (ignore le nom) }
      If (Tok = tkId) And (PPeekSym = ':') Then
      Begin
        PNext;
        PNext;
      End;
      Dummy := PExpr;
      PVarLoad := False;
      Inc(N);
      If IsSym(',') Then PNext Else Break;
    Until (CErr <> '') Or IsSym(')');
  PExpect(')');
  PArgs := N;
End;

{ appel d'une fonction de l'utilisateur }
Procedure PCallUser(S : LongInt);
Var N, K, P, Tmp : LongInt; T : TPTarget; X : TLexSave; Simple : Boolean;
Begin
  N := 0;
  PExpect('(');
  If Not IsSym(')') Then
    Repeat
      If N >= Syms[S].NPar Then
      Begin
        { arguments en trop : evalues puis oublies }
        Dummy := PExpr;
        Emit(opPop);
      End
      Else
      Begin
        P := Syms[S].PBase + N;
        If PRef[P] Then
        Begin
          { &$x : adresse de la variable }
          Simple := False;
          If Tok = tkVar Then
          Begin
            LexSave(X);
            PNext;
            Simple := IsSym(',') Or IsSym(')');
            LexRestore(X);
          End;
          If Simple And (PSuperNo(TokS) = 0) Then
          Begin
            PVarDes(TokS, T.D);
            PNext;
            PAddrOf(T.D);
          End
          Else
          Begin
            Dummy := PExpr;
            Tmp := AllocVar(1);
            PopTmp(Tmp);
            If CurLvl = 0 Then Emit1(opLdGA, Tmp) Else Emit1(opLdLA, Tmp);
          End;
        End
        Else
        Begin
          Dummy := PExpr;
          PCopyIfVar;
        End;
      End;
      PVarLoad := False;
      Inc(N);
      If IsSym(',') Then PNext Else Break;
    Until (CErr <> '') Or IsSym(')');
  PExpect(')');
  If N > Syms[S].NPar Then N := Syms[S].NPar;
  { valeurs par defaut }
  While N < Syms[S].NPar Do
  Begin
    K := Syms[S].PBase + N;
    If PRef[K] Then
    Begin
      Tmp := AllocVar(1);
      If CurLvl = 0 Then Emit1(opLdGA, Tmp) Else Emit1(opLdLA, Tmp);
    End
    Else If PDefK[K] = 1 Then EmitConst(PDefC[K])
    Else If PDefK[K] = 2 Then Emit1(opPhp, psNewArr)
    Else If CErr = '' Then
    Begin
      CError('argument manquant pour ' + Syms[S].Name + '()');
      Exit;
    End;
    Inc(N);
  End;
  Emit(opCall);
  If Syms[S].Adr < 0 Then
  Begin
    Emit(Syms[S].Patch);
    Syms[S].Patch := Here - 1;
  End
  Else Emit(Syms[S].Adr);
  Emit(N); Emit(CurLvl);
End;

Function PFindFn(Nm : String) : LongInt;
Var K : LongInt;
Begin
  PFindFn := -1;
  For K := 0 To NSym - 1 Do
    If (Syms[K].Kind = skFunc) And (Syms[K].Name = Nm) Then
    Begin
      PFindFn := K;
      Exit;
    End;
End;

Function PBuiltinId(Nm : String) : LongInt;
Var K : LongInt;
Begin
  PBuiltinId := 0;
  For K := 0 To NPhpFn - 1 Do
    If PhpFnNames[K] = Nm Then
    Begin
      PBuiltinId := 300 + K;
      Exit;
    End;
End;

{ constantes predefinies de PHP }
Function PConst(Nm : String; Var C : TCell) : Boolean;
Var R : Double;
Begin
  PConst := True;
  R := 0;
  If Nm = 'PHP_EOL' Then
  Begin
    C.T := vtKStr; C.I := AddStr(#10); C.L := 1;
  End
  Else If (Nm = 'PHP_INT_MAX') Then MkInt(2147483647, C)
  Else If (Nm = 'PHP_INT_MIN') Then MkInt(-2147483647 - 1, C)
  Else If (Nm = 'PHP_INT_SIZE') Then MkInt(4, C)
  Else If Nm = 'PHP_VERSION' Then
  Begin
    C.T := vtKStr; C.I := AddStr('8.2.0'); C.L := 5;
  End
  Else If (Nm = 'PHP_MAJOR_VERSION') Then MkInt(8, C)
  Else If (Nm = 'PHP_MINOR_VERSION') Then MkInt(2, C)
  Else If Nm = 'PHP_OS' Then
  Begin
    C.T := vtKStr; C.I := AddStr('OS2'); C.L := 3;
  End
  Else If Nm = 'PHP_OS_FAMILY' Then
  Begin
    C.T := vtKStr; C.I := AddStr('OS/2'); C.L := 4;
  End
  Else If Nm = 'DIRECTORY_SEPARATOR' Then
  Begin
    C.T := vtKStr; C.I := AddStr('\'); C.L := 1;
  End
  Else If Nm = 'PHP_FLOAT_EPSILON' Then MkReal(2.220446049250313E-16, C)
  Else If Nm = 'PHP_FLOAT_MAX' Then MkReal(1.7976931348623157E308, C)
  Else If Nm = 'M_PI' Then MkReal(Pi, C)
  Else If Nm = 'M_E' Then MkReal(Exp(1), C)
  Else If Nm = 'M_SQRT2' Then MkReal(Sqrt(2), C)
  Else If Nm = 'M_PI_2' Then MkReal(Pi / 2, C)
  Else If Nm = 'M_PI_4' Then MkReal(Pi / 4, C)
  Else If Nm = 'M_1_PI' Then MkReal(1 / Pi, C)
  Else If Nm = 'M_LN2' Then MkReal(Ln(2), C)
  Else If Nm = 'M_LN10' Then MkReal(Ln(10), C)
  Else If Nm = 'NAN' Then MkReal(0, C)
  Else If Nm = 'INF' Then MkReal(1.7976931348623157E308, C)
  Else If (Nm = 'E_ALL') Then MkInt(32767, C)
  Else If (Nm = 'E_ERROR') Then MkInt(1, C)
  Else If (Nm = 'E_WARNING') Then MkInt(2, C)
  Else If (Nm = 'E_NOTICE') Then MkInt(8, C)
  Else If (Nm = 'E_STRICT') Then MkInt(2048, C)
  Else If (Nm = 'E_DEPRECATED') Then MkInt(8192, C)
  Else If (Nm = 'E_USER_ERROR') Then MkInt(256, C)
  Else If (Nm = 'E_USER_WARNING') Then MkInt(512, C)
  Else If (Nm = 'E_USER_NOTICE') Then MkInt(1024, C)
  Else If (Nm = 'ENT_QUOTES') Then MkInt(3, C)
  Else If (Nm = 'ENT_COMPAT') Then MkInt(2, C)
  Else If (Nm = 'ENT_NOQUOTES') Then MkInt(0, C)
  Else If (Nm = 'ENT_HTML5') Or (Nm = 'ENT_HTML401') Or (Nm = 'ENT_SUBSTITUTE') Then MkInt(0, C)
  Else If (Nm = 'SORT_REGULAR') Then MkInt(0, C)
  Else If (Nm = 'SORT_NUMERIC') Then MkInt(1, C)
  Else If (Nm = 'SORT_STRING') Then MkInt(2, C)
  Else If (Nm = 'SORT_FLAG_CASE') Then MkInt(8, C)
  Else If (Nm = 'SORT_NATURAL') Then MkInt(6, C)
  Else If (Nm = 'COUNT_RECURSIVE') Then MkInt(1, C)
  Else If (Nm = 'JSON_PRETTY_PRINT') Then MkInt(128, C)
  Else If (Nm = 'JSON_UNESCAPED_SLASHES') Then MkInt(64, C)
  Else If (Nm = 'JSON_UNESCAPED_UNICODE') Then MkInt(256, C)
  Else If (Nm = 'JSON_THROW_ON_ERROR') Or (Nm = 'JSON_NUMERIC_CHECK') Or (Nm = 'JSON_HEX_TAG') Then MkInt(0, C)
  Else If (Nm = 'STR_PAD_RIGHT') Then MkInt(1, C)
  Else If (Nm = 'STR_PAD_LEFT') Then MkInt(0, C)
  Else If (Nm = 'STR_PAD_BOTH') Then MkInt(2, C)
  Else If (Nm = 'PHP_ROUND_HALF_UP') Then MkInt(1, C)
  Else If (Nm = 'MYSQLI_ASSOC') Then MkInt(1, C)
  Else If (Nm = 'MYSQLI_NUM') Then MkInt(2, C)
  Else If (Nm = 'MYSQLI_BOTH') Then MkInt(3, C)
  Else If (Nm = 'PGSQL_ASSOC') Then MkInt(1, C)
  Else If (Nm = 'PGSQL_NUM') Then MkInt(2, C)
  Else If (Nm = 'PGSQL_BOTH') Then MkInt(3, C)
  Else If (Nm = 'PGSQL_CONNECTION_OK') Then MkInt(0, C)
  Else If (Nm = 'PDO::FETCH_ASSOC') Then MkInt(2, C)
  Else If (Nm = 'PDO::FETCH_NUM') Then MkInt(3, C)
  Else If (Nm = 'PDO::FETCH_BOTH') Then MkInt(4, C)
  Else If (Nm = 'PDO::FETCH_OBJ') Then MkInt(2, C)
  Else If (Nm = 'PDO::FETCH_COLUMN') Then MkInt(7, C)
  Else If (Nm = 'PDO::ATTR_ERRMODE') Or (Nm = 'PDO::ERRMODE_EXCEPTION') Or (Nm = 'PDO::ATTR_DEFAULT_FETCH_MODE') Or
          (Nm = 'PDO::ERRMODE_SILENT') Or (Nm = 'PDO::ATTR_EMULATE_PREPARES') Or (Nm = 'PDO::PARAM_STR') Or
          (Nm = 'PDO::PARAM_INT') Or (Nm = 'PDO::PARAM_BOOL') Or (Nm = 'PDO::PARAM_NULL') Then MkInt(0, C)
  Else If (Nm = 'PHP_SESSION_ACTIVE') Then MkInt(2, C)
  Else If (Nm = 'PHP_SESSION_NONE') Then MkInt(1, C)
  Else If (Nm = 'LC_ALL') Or (Nm = 'LOCK_EX') Or (Nm = 'FILE_APPEND') Or (Nm = 'FILE_IGNORE_NEW_LINES') Then
  Begin
    If Nm = 'FILE_APPEND' Then MkInt(8, C) Else If Nm = 'FILE_IGNORE_NEW_LINES' Then MkInt(2, C)
    Else If Nm = 'LOCK_EX' Then MkInt(2, C) Else MkInt(6, C);
  End
  Else If Nm = 'FILE_SKIP_EMPTY_LINES' Then MkInt(4, C)
  Else If (Nm = '__LINE__') Then MkInt(TokLine, C)
  Else PConst := False;
End;

{ mysqli_..., pg_... : membres de l'objet du premier argument }
Function PProcMember(Nm : String) : LongInt;
Var M : String;
Begin
  PProcMember := -1;
  M := '';
  If Copy(Nm, 1, 7) = 'MYSQLI_' Then M := Copy(Nm, 8, 40)
  Else If Copy(Nm, 1, 3) = 'PG_' Then M := Copy(Nm, 4, 40)
  Else Exit;
  If (M = 'QUERY') Or (M = 'FETCH_ASSOC') Or (M = 'FETCH_ROW') Or (M = 'FETCH_ARRAY') Or (M = 'FETCH_ALL') Or
     (M = 'NUM_ROWS') Or (M = 'AFFECTED_ROWS') Or (M = 'REAL_ESCAPE_STRING') Or (M = 'CLOSE') Or
     (M = 'FREE_RESULT') Or (M = 'INSERT_ID') Or (M = 'NUM_FIELDS') Or (M = 'FETCH_RESULT') Or (M = 'DATA_SEEK') Or
     (M = 'FIELD_NAME') Or (M = 'FETCH_OBJECT') Or (M = 'QUERY_PARAMS') Then
  Begin
    If M = 'NUM_FIELDS' Then M := 'FIELD_COUNT';
    If M = 'FETCH_OBJECT' Then M := 'FETCH_ASSOC';
    If M = 'FREE_RESULT' Then M := 'FREE';
    PProcMember := MemberCode(M);
  End;
End;

{ appel d'une fonction (nom en Nm, Tok sur '(') }
Function PCall(Nm : String) : LongInt;
Var S, Id, N, M, J, Tmp : LongInt; T : TPTarget; C : TCell;
Begin
  PCall := TyVar;
  S := PFindFn(Nm);
  If S >= 0 Then
  Begin
    PCallUser(S);
    Exit;
  End;
  { formes particulieres }
  If Nm = 'ISSET' Then
  Begin
    PNext;
    J := -1;
    N := 0;
    Repeat
      If Tok <> tkVar Then
      Begin
        CError('isset : variable attendue');
        Exit;
      End;
      PIssetOne;
      If N > 0 Then Emit(opAnd);
      Inc(N);
      If IsSym(',') Then PNext Else Break;
    Until CErr <> '';
    PExpect(')');
    PCall := TyBool;
    Exit;
  End;
  If Nm = 'EMPTY' Then
  Begin
    PNext;
    Dummy := PExpr;
    PExpect(')');
    Emit1(opPhp, psBool);
    Emit(opNot);
    PCall := TyBool;
    Exit;
  End;
  If (Nm = 'ARRAY') Then
  Begin
    PNext;
    Emit1(opPhp, psNewArr);
    While (CErr = '') And Not IsSym(')') Do
    Begin
      Dummy := PExpr;
      PCopyIfVar;
      If IsSym('=>') Then
      Begin
        PNext;
        Dummy := PExpr;
        PCopyIfVar;
        Emit1(opPhp, psAddK);
      End
      Else Emit1(opPhp, psAddV);
      If IsSym(',') Then PNext Else Break;
    End;
    PExpect(')');
    Exit;
  End;
  If Nm = 'DEFINE' Then
  Begin
    { define('NOM', valeur) : constante de la page }
    PNext;
    If Tok <> tkStr Then
    Begin
      CError('define : nom constant attendu');
      Exit;
    End;
    S := AddSym(UpStr(TokS), skConst);
    Syms[S].Lvl := 0;
    PNext;
    PExpect(',');
    If ConstExprP(C) Then
    Begin
      Syms[S].CV := C;
      Syms[S].Ty := TyVar;
    End;
    PExpect(')');
    Emit1(opPushB, 1);
    PCall := TyBool;
    Exit;
  End;
  If (Nm = 'DEFINED') Or (Nm = 'CONSTANT') Then
  Begin
    PNext;
    If Tok <> tkStr Then
    Begin
      CError(Nm + ' : nom constant attendu');
      Exit;
    End;
    J := FindSym(UpStr(TokS));
    If Not ((J >= 0) And (Syms[J].Kind = skConst)) Then J := -1;
    If Nm = 'DEFINED' Then
    Begin
      Emit1(opPushB, Ord((J >= 0) Or PConst(UpStr(TokS), C)));
      PCall := TyBool;
    End
    Else If J >= 0 Then EmitConst(Syms[J].CV)
    Else If PConst(UpStr(TokS), C) Then EmitConst(C)
    Else CError('constante inconnue : ' + TokS);
    PNext;
    PExpect(')');
    Exit;
  End;
  If Nm = 'FUNCTION_EXISTS' Then
  Begin
    PNext;
    If Tok = tkStr Then
    Begin
      Emit1(opPushB, Ord((PFindFn(UpStr(TokS)) >= 0) Or (PBuiltinId(UpStr(TokS)) > 0)));
      PNext;
    End
    Else
    Begin
      Dummy := PExpr;
      Emit(opPop);
      Emit1(opPushB, 0);
    End;
    PExpect(')');
    PCall := TyBool;
    Exit;
  End;
  If (Nm = 'COMPACT') Then
  Begin
    { compact('a', 'b') : tableau des variables nommees }
    PNext;
    Emit1(opPhp, psNewArr);
    While (CErr = '') And (Tok = tkStr) Do
    Begin
      EmitStr(TokS);
      PVarDes(TokS, T.D);
      PLoad(T.D);
      Emit1(opPhp, psAddK);
      PNext;
      If IsSym(',') Then PNext Else Break;
    End;
    PExpect(')');
    Exit;
  End;
  { mysqli_query($c, $sql)... : membre du premier argument }
  M := PProcMember(Nm);
  If M >= 0 Then
  Begin
    PNext;
    Dummy := PExpr;
    PVarLoad := False;
    N := 0;
    While IsSym(',') Do
    Begin
      PNext;
      Dummy := PExpr;
      PVarLoad := False;
      Inc(N);
    End;
    PExpect(')');
    Emit2(opMember, M, N);
    Exit;
  End;
  { connexions : Database.Connect(chaine faite des arguments) }
  If (Nm = 'MYSQLI_CONNECT') Or (Nm = 'PG_CONNECT') Or (Nm = 'PG_PCONNECT') Or (Nm = 'MYSQLI_INIT') Then
  Begin
    Emit1(opIsObj, obDatabase);
    N := PArgs;
    If Nm = 'MYSQLI_CONNECT' Then Emit2(opCallB, pfMysqliConnstr, N) Else Emit2(opCallB, pfPgConnect, N);
    Emit2(opMember, mConnect, 1);
    Exit;
  End;
  If (Nm = 'EXIT') Or (Nm = 'DIE') Then
  Begin
    PNext;
    If Not IsSym(')') Then
    Begin
      Dummy := PExpr;
      Emit1(opPhp, psExitMsg);
    End;
    PExpect(')');
    Emit(opHalt);
    Emit(opPushNil);
    Exit;
  End;
  Id := PBuiltinId(Nm);
  If Id = 0 Then
  Begin
    CError('fonction inconnue : ' + PTokRaw + '()');
    Exit;
  End;
  N := PArgs;
  Emit2(opCallB, Id, N);
  If (Id = pfIsInt) Or (Id = pfIsString) Or (Id = pfIsArray) Or (Id = pfIsNumeric) Or (Id = pfInArray) Or
     (Id = pfIsNull) Or (Id = pfIsBool) Or (Id = pfIsFloat) Or (Id = pfFileExists) Or (Id = pfArrayKeyExists) Then
    PCall := TyBool
  Else If (Id = pfStrlen) Or (Id = pfCount) Then PCall := TyInt;
End;

{ expression constante (valeur par defaut, define, const) }
Function ConstExprP(Var C : TCell) : Boolean;
Var Neg : Boolean; Nm : String; S : LongInt;
Begin
  ConstExprP := True;
  Neg := False;
  If IsSym('-') Then
  Begin
    Neg := True;
    PNext;
  End;
  If Tok = tkInt Then
  Begin
    If Neg Then MkInt(-TokI, C) Else MkInt(TokI, C);
    PNext;
  End
  Else If Tok = tkReal Then
  Begin
    If Neg Then MkReal(-TokR, C) Else MkReal(TokR, C);
    PNext;
  End
  Else If Tok = tkStr Then
  Begin
    C.T := vtKStr; C.I := TokOff; C.L := TokLen;
    PNext;
  End
  Else If Tok = tkId Then
  Begin
    Nm := TokS;
    PNext;
    If IsSym('::') Then
    Begin
      PNext;
      Nm := Nm + '::' + TokS;
      PNext;
    End;
    If Nm = 'TRUE' Then MkBool(True, C)
    Else If Nm = 'FALSE' Then MkBool(False, C)
    Else If Nm = 'NULL' Then MkNil(C)
    Else If PConst(Nm, C) Then
    Begin
      If Neg Then
        If C.T = vtInt Then C.I := -C.I Else If C.T = vtReal Then C.R := -C.R;
    End
    Else
    Begin
      S := FindSym(Nm);
      If (S >= 0) And (Syms[S].Kind = skConst) Then C := Syms[S].CV
      Else
      Begin
        CError('constante attendue : ' + Nm);
        ConstExprP := False;
      End;
    End;
  End
  Else
  Begin
    CError('valeur constante attendue');
    ConstExprP := False;
  End;
End;

{ isset(x) : sans creer les elements absents }
Procedure PIssetOne;
Var Nm : String; Sn, M : LongInt; D : TDes;
Begin
  Nm := TokS;
  PNext;
  Sn := PSuperNo(Nm);
  If Sn > 0 Then PEmitSuper(Sn)
  Else
  Begin
    PVarDes(Nm, D);
    PLoad(D);
  End;
  If Not IsSym('[') And Not IsSym('->') Then
  Begin
    Emit1(opPhp, psNotNull);
    Exit;
  End;
  While CErr = '' Do
  Begin
    If IsSym('[') Then
    Begin
      PNext;
      Dummy := PExpr;
      PExpect(']');
      If IsSym('[') Or IsSym('->') Then Emit1(opPhp, psGet)
      Else
      Begin
        Emit1(opPhp, psIsset);
        Exit;
      End;
    End
    Else If IsSym('->') Then
    Begin
      PNext;
      M := MemberCode(TokS);
      If M < 0 Then
      Begin
        CError('propri'#130't'#130' inconnue : ' + TokS);
        Exit;
      End;
      PNext;
      Emit2(opMember, M, 0);
      If Not IsSym('[') And Not IsSym('->') Then
      Begin
        Emit1(opPhp, psNotNull);
        Exit;
      End;
    End
    Else Break;
  End;
End;

{ ==================================================================== }
{ Chaines interpolees                                                   }
{ ==================================================================== }

{ compiler une expression ecrite dans Text (sous-lexique) }
Procedure PSubExpr(Var Text : TBuf);
Var X : TLexSave; SaveSrc : TBuf;
Begin
  LexSave(X);
  SaveSrc := Src;
  Src := Text;
  SPos := 0; InHtml := False; InEcho := False;
  PNext;
  Dummy := PExpr;
  PVarLoad := False;
  If (CErr = '') And (Tok <> tkEof) Then CError('expression incorrecte dans une cha'#140'ne');
  Src := SaveSrc;
  If CErr = '' Then LexRestore(X);
End;

Procedure PInterp;
Var Raw, Lit, Ex : TBuf; K, N, Depth, Parts : LongInt; C : Byte; Nm, Key : String; Q : Byte;

  Procedure FlushLit;
  Begin
    If Lit.Len = 0 Then Exit;
    Emit2(opPushS, AddStrB(Lit.P, Lit.Len), Lit.Len);
    If Parts > 0 Then Emit(opConcat);
    Inc(Parts);
    Lit.Len := 0;
  End;

  Procedure DoExpr;
  Begin
    FlushLit;
    PSubExpr(Ex);
    If Parts > 0 Then Emit(opConcat)
    Else
    Begin
      { premiere partie : chaine (une valeur seule doit rester du texte) }
      EmitStr('');
      Emit(opSwap);
      Emit(opConcat);
    End;
    Inc(Parts);
    Ex.Len := 0;
  End;

Begin
  BufInit(Raw); BufInit(Lit); BufInit(Ex);
  BufAddB(Raw, PIRaw.P, PIRaw.Len);
  Parts := 0;
  K := 0;
  While (K < Raw.Len) And (CErr = '') Do
  Begin
    C := Raw.P^[K];
    If (C = 92) And (K + 1 < Raw.Len) Then
    Begin
      Inc(K);
      PEscape(Lit, K, Raw);
      Inc(K);
      Continue;
    End;
    If (C = 123) And (K + 1 < Raw.Len) And (Raw.P^[K + 1] = 36) Then
    Begin
      { accolade dollar : expression jusqu'a l'accolade fermante }
      Inc(K);
      Depth := 1;
      While (K < Raw.Len) And (Depth > 0) Do
      Begin
        C := Raw.P^[K];
        If C = 123 Then Inc(Depth)
        Else If C = 125 Then
        Begin
          Dec(Depth);
          If Depth = 0 Then Break;
        End
        Else If (C = 39) Or (C = 34) Then
        Begin
          Q := C;
          BufAddC(Ex, C);
          Inc(K);
          While (K < Raw.Len) And (Raw.P^[K] <> Q) Do
          Begin
            BufAddC(Ex, Raw.P^[K]);
            Inc(K);
          End;
          C := Q;
        End;
        BufAddC(Ex, C);
        Inc(K);
      End;
      Inc(K);
      DoExpr;
      Continue;
    End;
    If (C = 36) And (K + 1 < Raw.Len) And PIsW(Chr(Raw.P^[K + 1])) And
       Not ((Raw.P^[K + 1] >= 48) And (Raw.P^[K + 1] <= 57)) Then
    Begin
      Inc(K);
      Nm := '';
      While (K < Raw.Len) And PIsW(Chr(Raw.P^[K])) Do
      Begin
        Nm := Nm + Chr(Raw.P^[K]);
        Inc(K);
      End;
      BufAdd(Ex, '$' + Nm);
      If (K < Raw.Len) And (Raw.P^[K] = 91) Then
      Begin
        { $a[cle] : cle sans guillemets, nombre ou $variable }
        Inc(K);
        Key := '';
        While (K < Raw.Len) And (Raw.P^[K] <> 93) Do
        Begin
          Key := Key + Chr(Raw.P^[K]);
          Inc(K);
        End;
        Inc(K);
        If (Key <> '') And ((Key[1] = '$') Or (Key[1] In ['0'..'9', '-']) Or (Key[1] = '''') Or (Key[1] = '"')) Then
          BufAdd(Ex, '[' + Key + ']')
        Else BufAdd(Ex, '[''' + Key + ''']');
      End
      Else If (K + 2 < Raw.Len) And (Raw.P^[K] = 45) And (Raw.P^[K + 1] = 62) And PIsW(Chr(Raw.P^[K + 2])) Then
      Begin
        K := K + 2;
        BufAdd(Ex, '->');
        While (K < Raw.Len) And PIsW(Chr(Raw.P^[K])) Do
        Begin
          BufAddC(Ex, Raw.P^[K]);
          Inc(K);
        End;
      End;
      DoExpr;
      Continue;
    End;
    BufAddC(Lit, C);
    Inc(K);
  End;
  FlushLit;
  If Parts = 0 Then EmitStr('');
  BufFree(Raw); BufFree(Lit); BufFree(Ex);
End;

{ ==================================================================== }
{ Expressions                                                           }
{ ==================================================================== }

{ tableau [a, k => v] ou array(...) ; Close : ']' ou ')' }
Procedure PArrayLit(Close : String);
Begin
  Emit1(opPhp, psNewArr);
  While (CErr = '') And Not IsSym(Close) Do
  Begin
    If IsSym('...') Then
    Begin
      PNext;
      Dummy := PExpr;
      Emit1(opPhp, psSpread);
    End
    Else
    Begin
      Dummy := PExpr;
      PCopyIfVar;
      If IsSym('=>') Then
      Begin
        PNext;
        Dummy := PExpr;
        PCopyIfVar;
        Emit1(opPhp, psAddK);
      End
      Else Emit1(opPhp, psAddV);
    End;
    If IsSym(',') Then PNext Else Break;
  End;
  PExpect(Close);
End;

{ selecteurs apres une valeur : [cle], ->membre, ->methode(...) }
Procedure PSelectors;
Var M, N : LongInt;
Begin
  While CErr = '' Do
  Begin
    If IsSym('[') Or IsSym('{') Then
    Begin
      PNext;
      If IsSym(']') Then
      Begin
        CError('[] ne peut '#136'tre lu');
        Exit;
      End;
      Dummy := PExpr;
      If IsSym('}') Then PNext Else PExpect(']');
      Emit1(opPhp, psGet);
      Continue;
    End;
    If IsSym('->') Or IsSym('?->') Then
    Begin
      PNext;
      M := MemberCode(TokS);
      If (Tok <> tkId) Or (M < 0) Then
      Begin
        CError('m'#130'thode ou propri'#130't'#130' inconnue : ' + PTokRaw);
        Exit;
      End;
      PNext;
      If IsSym('(') Then N := PArgs Else N := 0;
      Emit2(opMember, M, N);
      PVarLoad := False;
      Continue;
    End;
    Break;
  End;
End;

Function PPrimary : LongInt;
Var Nm : String; S, Sn, N : LongInt; D : TDes; C : TCell; Ty : LongInt;
Begin
  PPrimary := TyVar;
  PVarLoad := False;
  Case Tok Of
    tkInt :
      Begin
        Emit1(opPushI, TokI);
        PNext;
        PPrimary := TyInt;
        Exit;
      End;
    tkReal :
      Begin
        Emit1(opPushR, AddReal(TokR));
        PNext;
        PPrimary := TyReal;
        Exit;
      End;
    tkStr :
      Begin
        Emit2(opPushS, TokOff, TokLen);
        PNext;
        PSelectors;
        PPrimary := TyStr;
        Exit;
      End;
    tkIStr :
      Begin
        PInterp;
        PNext;
        PPrimary := TyStr;
        Exit;
      End;
    tkVar :
      Begin
        If PAssignAhead <> '' Then
        Begin
          PAssign;
          PVarLoad := False;
          Exit;
        End;
        Nm := TokS;
        PNext;
        Sn := PSuperNo(Nm);
        If Sn > 0 Then PEmitSuper(Sn)
        Else
        Begin
          PVarDes(Nm, D);
          PLoad(D);
        End;
        PVarLoad := True;
        PSelectors;
        Exit;
      End;
  End;
  If IsSym('(') Then
  Begin
    PNext;
    Ty := PExpr;
    PExpect(')');
    PVarLoad := False;
    PSelectors;
    PPrimary := Ty;
    Exit;
  End;
  If IsSym('[') Then
  Begin
    PNext;
    PArrayLit(']');
    PSelectors;
    Exit;
  End;
  If Tok <> tkId Then
  Begin
    If Tok = tkEof Then CError('expression attendue (fin du fichier)')
    Else CError('expression attendue au lieu de ''' + TokS + '''');
    Exit;
  End;
  Nm := TokS;
  If (Nm = 'TRUE') Or (Nm = 'FALSE') Then
  Begin
    Emit1(opPushB, Ord(Nm = 'TRUE'));
    PNext;
    PPrimary := TyBool;
    Exit;
  End;
  If Nm = 'NULL' Then
  Begin
    Emit(opPushNil);
    PNext;
    Exit;
  End;
  If Nm = 'NEW' Then
  Begin
    PNext;
    Nm := TokS;
    PNext;
    If Nm = 'PDO' Then
    Begin
      Emit1(opIsObj, obDatabase);
      N := PArgs;
      Emit2(opCallB, pfPdoConnstr, N);
      Emit2(opMember, mConnect, 1);
    End
    Else If Nm = 'MYSQLI' Then
    Begin
      Emit1(opIsObj, obDatabase);
      N := PArgs;
      Emit2(opCallB, pfMysqliConnstr, N);
      Emit2(opMember, mConnect, 1);
    End
    Else If (Nm = 'STDCLASS') Or (Nm = 'ARRAYOBJECT') Then
    Begin
      If IsSym('(') Then
      Begin
        PNext;
        PExpect(')');
      End;
      Emit1(opPhp, psNewArr);
    End
    Else If (Pos('EXCEPTION', Nm) > 0) Or (Pos('ERROR', Nm) > 0) Then
    Begin
      { exception : son message }
      If IsSym('(') Then
      Begin
        N := PArgs;
        While N > 1 Do
        Begin
          Emit(opPop);
          Dec(N);
        End;
        If N = 0 Then EmitStr(PTokRaw);
      End
      Else EmitStr(PTokRaw);
    End
    Else CError('classe non prise en charge : ' + Nm);
    PSelectors;
    Exit;
  End;
  If Nm = 'PRINT' Then
  Begin
    PNext;
    Dummy := PAssignE;
    Emit1(opPushI, -1); Emit1(opPushI, -1);
    Emit(opWrite);
    Emit1(opPushI, 1);
    PPrimary := TyInt;
    Exit;
  End;
  If (Nm = 'EXIT') Or (Nm = 'DIE') Then
  Begin
    PNext;
    If IsSym('(') Then
    Begin
      PNext;
      If Not IsSym(')') Then
      Begin
        Dummy := PExpr;
        Emit1(opPhp, psExitMsg);
      End;
      PExpect(')');
    End;
    Emit(opHalt);
    Emit(opPushNil);
    Exit;
  End;
  If (Nm = 'FUNCTION') Or (Nm = 'FN') Or (Nm = 'MATCH') Then
  Begin
    CError(PTokRaw + ' : fonctions anonymes et match non pris en charge');
    Exit;
  End;
  If (Nm = 'INCLUDE') Or (Nm = 'REQUIRE') Or (Nm = 'INCLUDE_ONCE') Or (Nm = 'REQUIRE_ONCE') Then
  Begin
    CError(PTokRaw + ' : nom de fichier constant attendu (include ''fichier.php'';)');
    Exit;
  End;
  PNext;
  If IsSym('(') Then
  Begin
    PPrimary := PCall(Nm);
    PSelectors;
    Exit;
  End;
  If IsSym('::') Then
  Begin
    PNext;
    Nm := Nm + '::' + TokS;
    PNext;
  End;
  If PConst(Nm, C) Then
  Begin
    EmitConst(C);
    Exit;
  End;
  S := FindSym(Nm);
  If (S >= 0) And (Syms[S].Kind = skConst) Then
  Begin
    EmitConst(Syms[S].CV);
    Exit;
  End;
  If (Nm = '__FILE__') Or (Nm = '__DIR__') Then
  Begin
    If Nm = '__DIR__' Then EmitStr(Copy(SrcDir, 1, Length(SrcDir) - 1)) Else EmitStr(SrcDir);
    Exit;
  End;
  If (Nm = '__FUNCTION__') Then
  Begin
    If PInFn >= 0 Then EmitStr(Syms[PInFn].Name) Else EmitStr('');
    Exit;
  End;
  CError('constante inconnue : ' + Nm);
End;

{ ++$x, --$x }
Procedure PPreInc(Op : String);
Var T : TPTarget;
Begin
  If Tok <> tkVar Then
  Begin
    CError('variable attendue apr'#138's ' + Op);
    Exit;
  End;
  PTarget(T);
  Case T.Kind Of
    1 :
      Begin
        PLoad(T.D);
        Emit1(opPushI, 1);
        If Op = '++' Then Emit(opAdd) Else Emit(opSub);
        Emit(opDup);
        PStore(T.D);
      End;
    2 : If Op = '++' Then Emit2(opPhp, psIncE, 3) Else Emit2(opPhp, psIncE, 4);
    4 :
      Begin
        PTargetLoad(T);
        Emit1(opPushI, 1);
        If Op = '++' Then Emit(opAdd) Else Emit(opSub);
        PTargetStore(T);
      End;
  Else
    CError('[] ne peut '#136'tre incr'#130'ment'#130);
  End;
End;

Function PPow : LongInt;
Begin
  PPow := PPrimary;
  If (CErr = '') And IsSym('**') Then
  Begin
    PNext;
    Dummy := PUnary;
    Emit2(opCallB, pfPow, 2);
    PPow := TyVar;
    PVarLoad := False;
  End;
End;

Function PUnary : LongInt;
Var K : LongInt; Op : String;
Begin
  If IsSym('-') Then
  Begin
    PNext;
    K := PUnary;
    Emit(opNeg);
    PUnary := K;
  End
  Else If IsSym('+') Then
  Begin
    PNext;
    Dummy := PUnary;
    Emit1(opPhp, psNum);
    PUnary := TyVar;
  End
  Else If IsSym('~') Then
  Begin
    PNext;
    Dummy := PUnary;
    Emit1(opPhp, psNum);
    Emit(opNot);
    PUnary := TyInt;
  End
  Else If IsSym('@') Then
  Begin
    PNext;
    PUnary := PUnary;
  End
  Else If IsSym('&') Then
  Begin
    { &$x (references) : la valeur }
    PNext;
    PUnary := PUnary;
  End
  Else If Tok = tkCast Then
  Begin
    K := TokI;
    PNext;
    Dummy := PUnary;
    Emit2(opPhp, psCast, K);
    PVarLoad := False;
    Case K Of
      1 : PUnary := TyInt;
      2 : PUnary := TyReal;
      3 : PUnary := TyStr;
      4 : PUnary := TyBool;
    Else
      PUnary := TyVar;
    End;
  End
  Else If IsSym('++') Or IsSym('--') Then
  Begin
    Op := TokS;
    PNext;
    PPreInc(Op);
    PUnary := TyVar;
  End
  Else PUnary := PPow;
End;

Function PNot : LongInt;
Var T : LongInt;
Begin
  If IsSym('!') Then
  Begin
    PNext;
    T := PNot;
    PToBool(T);
    Emit(opNot);
    PVarLoad := False;
    PNot := TyBool;
  End
  Else PNot := PUnary;
End;

Function PMul : LongInt;
Var Op : String;
Begin
  PMul := PNot;
  While (CErr = '') And (IsSym('*') Or IsSym('/') Or IsSym('%')) Do
  Begin
    Op := TokS;
    PNext;
    Dummy := PNot;
    PEmitOp(Op);
    PVarLoad := False;
    PMul := TyVar;
  End;
End;

Function PAdd : LongInt;
Var Op : String;
Begin
  PAdd := PMul;
  While (CErr = '') And (IsSym('+') Or IsSym('-')) Do
  Begin
    Op := TokS;
    PNext;
    Dummy := PMul;
    If Op = '+' Then Emit1(opPhp, psAdd) Else Emit(opSub);
    PVarLoad := False;
    PAdd := TyVar;
  End;
End;

Function PShift : LongInt;
Var Op : String;
Begin
  PShift := PAdd;
  While (CErr = '') And (IsSym('<<') Or IsSym('>>')) Do
  Begin
    Op := TokS;
    PNext;
    Dummy := PAdd;
    PEmitOp(Op);
    PVarLoad := False;
    PShift := TyInt;
  End;
End;

Function PCat : LongInt;
Begin
  PCat := PShift;
  While (CErr = '') And IsSym('.') Do
  Begin
    PNext;
    Dummy := PShift;
    Emit(opConcat);
    PVarLoad := False;
    PCat := TyStr;
  End;
End;

Function PRel : LongInt;
Var Op : String;
Begin
  PRel := PCat;
  While (CErr = '') And (IsSym('<') Or IsSym('<=') Or IsSym('>') Or IsSym('>=')) Do
  Begin
    Op := TokS;
    PNext;
    Dummy := PCat;
    If Op = '<' Then Emit(opLt) Else If Op = '<=' Then Emit(opLe) Else If Op = '>' Then Emit(opGt) Else Emit(opGe);
    PVarLoad := False;
    PRel := TyBool;
  End;
End;

Function PEqual : LongInt;
Var Op : String;
Begin
  PEqual := PRel;
  While (CErr = '') And (IsSym('==') Or IsSym('!=') Or IsSym('<>') Or IsSym('===') Or IsSym('!==') Or IsSym('<=>')) Do
  Begin
    Op := TokS;
    PNext;
    Dummy := PRel;
    If Op = '==' Then Emit(opEq) Else If (Op = '!=') Or (Op = '<>') Then Emit(opNe)
    Else If Op = '===' Then Emit1(opPhp, psIdent) Else If Op = '!==' Then Emit1(opPhp, psNIdent)
    Else Emit1(opPhp, psCmp);
    PVarLoad := False;
    If Op = '<=>' Then PEqual := TyInt Else PEqual := TyBool;
  End;
End;

Function PBitAnd : LongInt;
Begin
  PBitAnd := PEqual;
  While (CErr = '') And IsSym('&') Do
  Begin
    PNext;
    Dummy := PEqual;
    Emit1(opPhp, psBitAnd);
    PVarLoad := False;
    PBitAnd := TyInt;
  End;
End;

Function PBitXor : LongInt;
Begin
  PBitXor := PBitAnd;
  While (CErr = '') And IsSym('^') Do
  Begin
    PNext;
    Dummy := PBitAnd;
    Emit1(opPhp, psBitXor);
    PVarLoad := False;
    PBitXor := TyInt;
  End;
End;

Function PBitOr : LongInt;
Begin
  PBitOr := PBitXor;
  While (CErr = '') And IsSym('|') Do
  Begin
    PNext;
    Dummy := PBitXor;
    Emit1(opPhp, psBitOr);
    PVarLoad := False;
    PBitOr := TyInt;
  End;
End;

Function PAndAnd : LongInt;
Var T, J : LongInt;
Begin
  T := PBitOr;
  While (CErr = '') And IsSym('&&') Do
  Begin
    PToBool(T);
    PNext;
    Emit(opDup);
    Emit1(opJz, 0);
    J := Here - 1;
    Emit(opPop);
    T := PBitOr;
    PToBool(T);
    PatchAt(J, Here);
    T := TyBool;
    PVarLoad := False;
  End;
  PAndAnd := T;
End;

Function POrOr : LongInt;
Var T, J : LongInt;
Begin
  T := PAndAnd;
  While (CErr = '') And IsSym('||') Do
  Begin
    PToBool(T);
    PNext;
    Emit(opDup);
    Emit1(opJnz, 0);
    J := Here - 1;
    Emit(opPop);
    T := PAndAnd;
    PToBool(T);
    PatchAt(J, Here);
    T := TyBool;
    PVarLoad := False;
  End;
  POrOr := T;
End;

Function PCoalesce : LongInt;
Var J : LongInt;
Begin
  PCoalesce := POrOr;
  If (CErr = '') And IsSym('??') Then
  Begin
    PNext;
    Emit(opDup);
    Emit1(opPhp, psNotNull);
    Emit1(opJnz, 0);
    J := Here - 1;
    Emit(opPop);
    Dummy := PCoalesce;
    PatchAt(J, Here);
    PVarLoad := False;
    PCoalesce := TyVar;
  End;
End;

Function PTernary : LongInt;
Var T, J, J2 : LongInt;
Begin
  T := PCoalesce;
  While (CErr = '') And IsSym('?') Do
  Begin
    PNext;
    PVarLoad := False;
    If IsSym(':') Then
    Begin
      { a ?: b }
      PNext;
      Emit(opDup);
      Emit1(opPhp, psBool);
      Emit1(opJnz, 0);
      J := Here - 1;
      Emit(opPop);
      Dummy := PCoalesce;
      PatchAt(J, Here);
    End
    Else
    Begin
      PToBool(T);
      Emit1(opJz, 0);
      J := Here - 1;
      Dummy := PAssignE;
      PCopyIfVar;
      Emit1(opJmp, 0);
      J2 := Here - 1;
      PatchAt(J, Here);
      PExpect(':');
      Dummy := PAssignE;
      PCopyIfVar;
      PatchAt(J2, Here);
    End;
    T := TyVar;
  End;
  PTernary := T;
End;

Function PAssignE : LongInt;
Begin
  PAssignE := PTernary;
End;

Function PLowAnd : LongInt;
Var T, J : LongInt;
Begin
  T := PAssignE;
  While (CErr = '') And IsKw('AND') Do
  Begin
    PToBool(T);
    PNext;
    Emit(opDup);
    Emit1(opJz, 0);
    J := Here - 1;
    Emit(opPop);
    T := PAssignE;
    PToBool(T);
    PatchAt(J, Here);
    T := TyBool;
  End;
  PLowAnd := T;
End;

Function PLowXor : LongInt;
Var T : LongInt;
Begin
  T := PLowAnd;
  While (CErr = '') And IsKw('XOR') Do
  Begin
    PToBool(T);
    PNext;
    T := PLowAnd;
    PToBool(T);
    Emit(opXor);
    T := TyBool;
  End;
  PLowXor := T;
End;

Function PExpr : LongInt;
Var T, J : LongInt;
Begin
  T := PLowXor;
  While (CErr = '') And IsKw('OR') Do
  Begin
    PToBool(T);
    PNext;
    Emit(opDup);
    Emit1(opJnz, 0);
    J := Here - 1;
    Emit(opPop);
    T := PLowXor;
    PToBool(T);
    PatchAt(J, Here);
    T := TyBool;
  End;
  PExpr := T;
End;

{ ==================================================================== }
{ Instructions                                                          }
{ ==================================================================== }

Procedure PCond;
Var T : LongInt;
Begin
  PExpect('(');
  T := PExpr;
  PToBool(T);
  PExpect(')');
End;

{ instructions jusqu'a l'un des mots (syntaxe : ... endif;) }
Procedure PBlockUntil(S1, S2, S3 : String);
Begin
  While (CErr = '') And (Tok <> tkEof) Do
  Begin
    If (Tok = tkId) And ((TokS = S1) Or (TokS = S2) Or (TokS = S3)) Then Exit;
    PStatement;
  End;
  If (CErr = '') And (Tok = tkEof) Then CError(S1 + ' attendu (fin du fichier)');
End;

Procedure PIf;
Var J, EndCh, K : LongInt; Alt : Boolean;
Begin
  PNext;
  PCond;
  Emit1(opJz, 0);
  J := Here - 1;
  EndCh := -1;
  Alt := IsSym(':');
  If Alt Then
  Begin
    PNext;
    PBlockUntil('ELSEIF', 'ELSE', 'ENDIF');
    While (CErr = '') And IsKw('ELSEIF') Do
    Begin
      Emit1(opJmp, EndCh);
      EndCh := Here - 1;
      PatchAt(J, Here);
      PNext;
      PCond;
      Emit1(opJz, 0);
      J := Here - 1;
      PExpect(':');
      PBlockUntil('ELSEIF', 'ELSE', 'ENDIF');
    End;
    If IsKw('ELSE') Then
    Begin
      Emit1(opJmp, EndCh);
      EndCh := Here - 1;
      PatchAt(J, Here);
      J := -1;
      PNext;
      PExpect(':');
      PBlockUntil('ENDIF', 'ENDIF', 'ENDIF');
    End;
    PExpect('ENDIF');
    PSemi;
  End
  Else
  Begin
    PStatement;
    While (CErr = '') And (IsKw('ELSEIF') Or (IsKw('ELSE') And (PPeekSym = 'IF'))) Do
    Begin
      If IsKw('ELSE') Then PNext;
      Emit1(opJmp, EndCh);
      EndCh := Here - 1;
      PatchAt(J, Here);
      PNext;
      PCond;
      Emit1(opJz, 0);
      J := Here - 1;
      PStatement;
    End;
    If IsKw('ELSE') Then
    Begin
      Emit1(opJmp, EndCh);
      EndCh := Here - 1;
      PatchAt(J, Here);
      J := -1;
      PNext;
      PStatement;
    End;
  End;
  If J >= 0 Then PatchAt(J, Here);
  K := Here;
  PatchChain(EndCh, K);
End;

{ corps d'une boucle : instruction, bloc, ou syntaxe : ... EndW; }
Procedure PLoopBody(EndW : String);
Begin
  If IsSym(':') Then
  Begin
    PNext;
    PBlockUntil(EndW, EndW, EndW);
    PExpect(EndW);
    PSemi;
  End
  Else PStatement;
End;

Procedure PWhile;
Var L0, J : LongInt;
Begin
  PNext;
  L0 := Here;
  PCond;
  Emit1(opJz, 0);
  J := Here - 1;
  BeginLoop;
  PLoopBody('ENDWHILE');
  Emit1(opJmp, L0);
  PatchAt(J, Here);
  EndLoop(L0, Here);
End;

Procedure PDo;
Var L0, LC : LongInt;
Begin
  PNext;
  L0 := Here;
  BeginLoop;
  PStatement;
  LC := Here;
  PExpect('WHILE');
  PCond;
  Emit1(opJnz, L0);
  PSemi;
  EndLoop(LC, Here);
End;

Procedure PFor;
Var LCond, LStep, JEnd, JBody : LongInt; T : LongInt; HasCond : Boolean;
Begin
  PNext;
  PExpect('(');
  While (CErr = '') And Not IsSym(';') Do
  Begin
    Dummy := PExpr;
    Emit(opPop);
    If IsSym(',') Then PNext Else Break;
  End;
  PExpect(';');
  LCond := Here;
  HasCond := False;
  T := TyBool;
  While (CErr = '') And Not IsSym(';') Do
  Begin
    If HasCond Then Emit(opPop);
    T := PExpr;
    HasCond := True;
    If IsSym(',') Then PNext Else Break;
  End;
  PExpect(';');
  If HasCond Then PToBool(T) Else Emit1(opPushB, 1);
  Emit1(opJz, 0);
  JEnd := Here - 1;
  Emit1(opJmp, 0);
  JBody := Here - 1;
  LStep := Here;
  While (CErr = '') And Not IsSym(')') Do
  Begin
    Dummy := PExpr;
    Emit(opPop);
    If IsSym(',') Then PNext Else Break;
  End;
  PExpect(')');
  Emit1(opJmp, LCond);
  PatchAt(JBody, Here);
  BeginLoop;
  PLoopBody('ENDFOR');
  Emit1(opJmp, LStep);
  PatchAt(JEnd, Here);
  EndLoop(LStep, Here);
End;

Procedure PForeach;
Var Coll, Posn, L0, J, LC : LongInt; K1, K2 : String; HasKey : Boolean; D : TDes; Lst : Boolean;
    LNames : Array[0..7] Of String[40]; NL, I : LongInt; ByRef : Boolean;
Begin
  PNext;
  PExpect('(');
  Dummy := PExpr;
  PVarLoad := False;
  Coll := AllocVar(1); Posn := AllocVar(1);
  PopTmp(Coll);
  Emit1(opPushI, 0);
  PopTmp(Posn);
  PExpect('AS');
  { cle et valeur }
  HasKey := False; Lst := False; NL := 0;
  K1 := ''; K2 := ''; ByRef := False;
  If IsSym('&') Then
  Begin
    ByRef := True;
    PNext;
  End;
  If (Tok = tkVar) Then
  Begin
    K1 := TokS;
    PNext;
  End
  Else If IsSym('[') Or IsKw('LIST') Then
  Begin
    Lst := True;
  End
  Else CError('variable attendue apr'#138's as');
  If IsSym('=>') Then
  Begin
    PNext;
    HasKey := True;
    If IsSym('&') Then
    Begin
      ByRef := True;
      PNext;
    End;
    If Tok = tkVar Then
    Begin
      K2 := TokS;
      PNext;
    End
    Else If IsSym('[') Or IsKw('LIST') Then Lst := True
    Else CError('variable attendue apr'#138's =>');
  End;
  If Lst Then
  Begin
    { as [$a, $b] / list($a, $b) }
    If IsKw('LIST') Then PNext;
    PNext;
    While (CErr = '') And (Tok = tkVar) And (NL < 8) Do
    Begin
      LNames[NL] := TokS;
      Inc(NL);
      PNext;
      If IsSym(',') Then PNext Else Break;
    End;
    If IsSym(']') Then PNext Else PExpect(')');
  End;
  PExpect(')');
  L0 := Here;
  PushTmp(Coll); PushTmp(Posn);
  Emit1(opPhp, psEachNext);
  Emit(opDup);
  PopTmp(Posn);
  Emit1(opPushI, -1);
  Emit(opEq);
  Emit1(opJnz, 0);
  J := Here - 1;
  If HasKey Then
  Begin
    PushTmp(Coll); PushTmp(Posn);
    Emit1(opPhp, psEachKey);
    PVarDes(K1, D);
    PStore(D);
  End;
  PushTmp(Coll); PushTmp(Posn);
  Emit1(opPhp, psEachVal);
  If Lst Then
  Begin
    For I := 0 To NL - 1 Do
    Begin
      Emit(opDup);
      Emit1(opPushI, I);
      Emit1(opPhp, psGet);
      PVarDes(LNames[I], D);
      PStore(D);
    End;
    Emit(opPop);
  End
  Else
  Begin
    If HasKey Then PVarDes(K2, D) Else PVarDes(K1, D);
    PStore(D);
  End;
  BeginLoop;
  PLoopBody('ENDFOREACH');
  LC := Here;
  If ByRef And Not Lst Then
  Begin
    { foreach ($t as &$v) : la valeur revient dans le tableau a chaque tour }
    PushTmp(Coll);
    PushTmp(Coll); PushTmp(Posn);
    Emit1(opPhp, psEachKey);
    If HasKey Then PVarDes(K2, D) Else PVarDes(K1, D);
    PLoad(D);
    Emit1(opPhp, psSet);
    Emit(opPop);
  End;
  PushTmp(Posn);
  Emit1(opPushI, 1);
  Emit(opAdd);
  PopTmp(Posn);
  Emit1(opJmp, L0);
  PatchAt(J, Here);
  EndLoop(LC, Here);
End;

Procedure PSwitch;
Var V, JTest, JFall, JDefSkip, DBody, I : LongInt; Alt, HasDef, HasBody : Boolean; T : LongInt;
Begin
  PNext;
  PExpect('(');
  Dummy := PExpr;
  PVarLoad := False;
  PExpect(')');
  V := AllocVar(1);
  PopTmp(V);
  Alt := IsSym(':');
  If Alt Then PNext Else PExpect('{');
  { des fragments HTML (espaces) peuvent preceder le premier case }
  While Tok = tkHtml Do PNext;
  BeginLoop;
  JTest := -1; JFall := -1; HasDef := False; DBody := -1; HasBody := False;
  While (CErr = '') And (Tok <> tkEof) And Not IsSym('}') And Not IsKw('ENDSWITCH') Do
  Begin
    If IsKw('CASE') Then
    Begin
      PNext;
      { fin du corps precedent : il continue dans le corps suivant }
      If HasBody Then
      Begin
        Emit1(opJmp, JFall);
        JFall := Here - 1;
      End;
      HasBody := True;
      If JTest >= 0 Then PatchAt(JTest, Here);
      PushTmp(V);
      T := PExpr;
      PVarLoad := False;
      Emit(opEq);
      Emit1(opJz, 0);
      JTest := Here - 1;
      If IsSym(':') Or IsSym(';') Then PNext Else PExpect(':');
      PatchChain(JFall, Here);
      JFall := -1;
    End
    Else If IsKw('DEFAULT') Then
    Begin
      PNext;
      If IsSym(':') Or IsSym(';') Then PNext Else PExpect(':');
      If HasBody Then
      Begin
        Emit1(opJmp, JFall);
        JFall := Here - 1;
      End;
      HasBody := True;
      { un test qui echoue saute le corps de default }
      If JTest >= 0 Then PatchAt(JTest, Here);
      Emit1(opJmp, 0);
      JTest := Here - 1;
      DBody := Here;
      HasDef := True;
      PatchChain(JFall, Here);
      JFall := -1;
    End
    Else PStatement;
  End;
  { aucun cas : default (s'il existe) }
  Emit1(opJmp, 0);
  I := Here - 1;
  If JTest >= 0 Then
  Begin
    If HasDef Then PatchAt(JTest, DBody) Else PatchAt(JTest, Here);
  End;
  PatchAt(I, Here);
  PatchChain(JFall, Here);
  If Alt Then
  Begin
    PExpect('ENDSWITCH');
    PSemi;
  End
  Else PExpect('}');
  EndLoop(Here, Here);
  JDefSkip := 0;
End;

Procedure PBreakCont(IsBreak : Boolean);
Var N, L : LongInt;
Begin
  PNext;
  N := 1;
  If Tok = tkInt Then
  Begin
    N := TokI;
    PNext;
  End;
  PSemi;
  L := LoopDepth - N + 1;
  If (L < 1) Or (L > LoopDepth) Then
  Begin
    CError('break ou continue hors d''une boucle');
    Exit;
  End;
  If IsBreak Then
  Begin
    Emit1(opJmp, BreakChain[L]);
    BreakChain[L] := Here - 1;
  End
  Else
  Begin
    Emit1(opJmp, ContChain[L]);
    ContChain[L] := Here - 1;
  End;
End;

{ definition d'une fonction (deja connue du premier passage) }
Procedure PFunction;
Var S, K, J, Save, SLoc, SMax, SExit, SIn, EnterAt, T, P, Depth, SLoop : LongInt; Nm : String;
Begin
  PNext;
  If IsSym('&') Then PNext;
  Nm := TokS;
  PNext;
  S := PFindFn(Nm);
  If (S < 0) Or (CurLvl > 0) Then
  Begin
    CError('fonction : d'#130'finition impossible ici : ' + Nm);
    Exit;
  End;
  { parametres : deja connus ; sauter la liste }
  Depth := 0;
  Repeat
    If IsSym('(') Then Inc(Depth) Else If IsSym(')') Then Dec(Depth);
    PNext;
  Until (Depth = 0) Or (Tok = tkEof) Or (CErr <> '');
  { type de retour }
  If IsSym(':') Then
  Begin
    PNext;
    While (CErr = '') And Not IsSym('{') And (Tok <> tkEof) Do PNext;
  End;
  Emit1(opJmp, 0);
  J := Here - 1;
  Syms[S].Adr := Here;
  PatchChain(Syms[S].Patch, Here);
  Syms[S].Patch := -1;
  Save := NSym; SLoc := LocTop; SMax := LocMax; SExit := PFnExit; SIn := PInFn; SLoop := LoopDepth;
  Inc(CurLvl);
  PFnExit := -1; PInFn := S; LoopDepth := 0;
  LocTop := 4 + Syms[S].NPar; LocMax := LocTop;
  Emit2(opEnter, 0, Syms[S].NPar);
  EnterAt := Here - 2;
  For K := 0 To Syms[S].NPar - 1 Do
  Begin
    P := Syms[S].PBase + K;
    T := AddSym('$' + Copy(PName[P], 1, 30), skVar);
    Syms[T].Ty := TyVar; Syms[T].Lvl := CurLvl; Syms[T].Adr := 4 + K; Syms[T].Ref := PRef[P];
  End;
  PExpect('{');
  While (CErr = '') And (Tok <> tkEof) And Not IsSym('}') Do PStatement;
  PExpect('}');
  PatchChain(PFnExit, Here);
  Emit1(opRet, 1);
  PatchAt(EnterAt, LocMax);
  NSym := Save;
  Dec(CurLvl);
  LocTop := SLoc; LocMax := SMax; PFnExit := SExit; PInFn := SIn; LoopDepth := SLoop;
  PatchAt(J, Here);
End;

Procedure PGlobalStmt;
Var S : LongInt;
Begin
  PNext;
  Repeat
    If Tok <> tkVar Then
    Begin
      CError('variable attendue apr'#138's global');
      Exit;
    End;
    If CurLvl > 0 Then
    Begin
      S := AddSym('$' + Copy(TokS, 1, 30), skVar);
      Syms[S].Ty := TyVar; Syms[S].Lvl := 0; Syms[S].Adr := PGlobSlot(TokS);
    End;
    PNext;
    If IsSym(',') Then PNext Else Break;
  Until CErr <> '';
  PSemi;
End;

Procedure PStaticStmt;
Var S, Flag, Slot, J : LongInt; Nm, Fn : String; D : TDes;
Begin
  PNext;
  If PInFn >= 0 Then Fn := Syms[PInFn].Name Else Fn := '';
  Repeat
    If Tok <> tkVar Then
    Begin
      CError('variable attendue apr'#138's static');
      Exit;
    End;
    Nm := TokS;
    PNext;
    Slot := PGlobSlot('#S:' + Fn + ':' + Nm);
    Flag := PGlobSlot('#F:' + Fn + ':' + Nm);
    If CurLvl > 0 Then
    Begin
      S := AddSym('$' + Copy(Nm, 1, 30), skVar);
      Syms[S].Ty := TyVar; Syms[S].Lvl := 0; Syms[S].Adr := Slot;
    End;
    If IsSym('=') Then
    Begin
      PNext;
      Emit1(opLdG, Flag);
      Emit1(opJnz, 0);
      J := Here - 1;
      Dummy := PExpr;
      PCopyIfVar;
      Emit1(opStG, Slot);
      Emit1(opPushB, 1);
      Emit1(opStG, Flag);
      PatchAt(J, Here);
    End;
    If IsSym(',') Then PNext Else Break;
  Until CErr <> '';
  PSemi;
End;

Procedure PUnset;
Var T : TPTarget;
Begin
  PNext;
  PExpect('(');
  Repeat
    If Tok <> tkVar Then
    Begin
      CError('unset : variable attendue');
      Exit;
    End;
    PTarget(T);
    Case T.Kind Of
      1 :
        Begin
          Emit(opPushNil);
          PStore(T.D);
        End;
      2 : Emit1(opPhp, psUnset);
    Else
      CError('unset : cible impossible');
    End;
    If IsSym(',') Then PNext Else Break;
  Until CErr <> '';
  PExpect(')');
  PSemi;
End;

{ [$a, $b] = ... ; list($a, , $c) = ... }
Procedure PListAssign;
Var Names : Array[0..15] Of String[40]; N, I, Tmp : LongInt; Close : String; D : TDes;
Begin
  If IsKw('LIST') Then
  Begin
    PNext;
    Close := ')';
  End
  Else Close := ']';
  PNext;
  N := 0;
  While (CErr = '') And Not IsSym(Close) And (N < 16) Do
  Begin
    Names[N] := '';
    If Tok = tkVar Then
    Begin
      Names[N] := TokS;
      PNext;
    End;
    Inc(N);
    If IsSym(',') Then PNext Else Break;
  End;
  PExpect(Close);
  PExpect('=');
  Dummy := PExpr;
  PVarLoad := False;
  Tmp := AllocVar(1);
  PopTmp(Tmp);
  For I := 0 To N - 1 Do
    If Names[I] <> '' Then
    Begin
      PushTmp(Tmp);
      Emit1(opPushI, I);
      Emit1(opPhp, psGet);
      PVarDes(Names[I], D);
      PStore(D);
    End;
  PSemi;
End;

Procedure PSkipBlock;
Var Depth : LongInt;
Begin
  { bloc (accolades) compile mais jamais execute (catch) }
  Depth := 0;
  Emit1(opJmp, 0);
  Depth := Here - 1;
  PStatement;
  PatchAt(Depth, Here);
End;

Procedure PStatement;
Var Nm : String; N, S, J : LongInt; C : TCell; T : LongInt;
Begin
  If CErr <> '' Then Exit;
  EmitLine;
  If Tok = tkHtml Then
  Begin
    Emit2(opHtml, AddStrB(@Src.P^[TokOff], TokLen), TokLen);
    PNext;
    Exit;
  End;
  If Tok = tkEcho Then
  Begin
    PNext;
    Repeat
      Dummy := PExpr;
      PVarLoad := False;
      Emit1(opPushI, -1); Emit1(opPushI, -1);
      Emit(opWrite);
      If IsSym(',') Then PNext Else Break;
    Until CErr <> '';
    If IsSym(';') Then PNext;
    If Tok = tkEchoEnd Then PNext
    Else If Tok <> tkEof Then CError('''?>'' attendu');
    Exit;
  End;
  If (Tok = tkEchoEnd) Or IsSym(';') Then
  Begin
    PNext;
    Exit;
  End;
  If IsSym('{') Then
  Begin
    PNext;
    While (CErr = '') And (Tok <> tkEof) And Not IsSym('}') Do PStatement;
    PExpect('}');
    Exit;
  End;
  If IsSym('[') Then
  Begin
    { [$a, $b] = ... ? }
    If (PPeekSym = '') Then
    Begin
      PListAssign;
      Exit;
    End;
  End;
  If Tok = tkId Then
  Begin
    Nm := TokS;
    If (Nm = 'ECHO') Then
    Begin
      PNext;
      Repeat
        Dummy := PExpr;
        PVarLoad := False;
        Emit1(opPushI, -1); Emit1(opPushI, -1);
        Emit(opWrite);
        If IsSym(',') Then PNext Else Break;
      Until CErr <> '';
      PSemi;
      Exit;
    End;
    If Nm = 'IF' Then
    Begin
      PIf;
      Exit;
    End;
    If Nm = 'WHILE' Then
    Begin
      PWhile;
      Exit;
    End;
    If Nm = 'DO' Then
    Begin
      PDo;
      Exit;
    End;
    If Nm = 'FOR' Then
    Begin
      PFor;
      Exit;
    End;
    If Nm = 'FOREACH' Then
    Begin
      PForeach;
      Exit;
    End;
    If Nm = 'SWITCH' Then
    Begin
      PSwitch;
      Exit;
    End;
    If (Nm = 'BREAK') Or (Nm = 'CONTINUE') Then
    Begin
      PBreakCont(Nm = 'BREAK');
      Exit;
    End;
    If Nm = 'RETURN' Then
    Begin
      PNext;
      If CurLvl > 0 Then
      Begin
        If IsSym(';') Or (Tok = tkEchoEnd) Then Emit(opPushNil)
        Else
        Begin
          Dummy := PExpr;
          PCopyIfVar;
        End;
        Emit1(opStL, 3);
        Emit1(opJmp, PFnExit);
        PFnExit := Here - 1;
      End
      Else
      Begin
        If Not IsSym(';') And (Tok <> tkEchoEnd) Then
        Begin
          Dummy := PExpr;
          Emit(opPop);
        End;
        Emit(opHalt);
      End;
      PSemi;
      Exit;
    End;
    If (Nm = 'FUNCTION') And (PPeekSym <> '(') Then
    Begin
      PFunction;
      Exit;
    End;
    If Nm = 'GLOBAL' Then
    Begin
      PGlobalStmt;
      Exit;
    End;
    If (Nm = 'STATIC') And (PPeekSym = '') Then
    Begin
      PStaticStmt;
      Exit;
    End;
    If Nm = 'UNSET' Then
    Begin
      PUnset;
      Exit;
    End;
    If (Nm = 'LIST') And (PPeekSym = '(') Then
    Begin
      PListAssign;
      Exit;
    End;
    If Nm = 'CONST' Then
    Begin
      PNext;
      Repeat
        S := AddSym(TokS, skConst);
        Syms[S].Lvl := 0;
        PNext;
        PExpect('=');
        If ConstExprP(C) Then
        Begin
          Syms[S].CV := C;
          Syms[S].Ty := TyVar;
        End;
        If IsSym(',') Then PNext Else Break;
      Until CErr <> '';
      PSemi;
      Exit;
    End;
    If Nm = 'TRY' Then
    Begin
      PNext;
      PStatement;
      While (CErr = '') And IsKw('CATCH') Do
      Begin
        PNext;
        PExpect('(');
        While (CErr = '') And Not IsSym(')') And (Tok <> tkEof) Do PNext;
        PExpect(')');
        PSkipBlock;
      End;
      If IsKw('FINALLY') Then
      Begin
        PNext;
        PStatement;
      End;
      Exit;
    End;
    If Nm = 'THROW' Then
    Begin
      PNext;
      Dummy := PExpr;
      Emit1(opPhp, psThrow);
      PSemi;
      Exit;
    End;
    If (Nm = 'NAMESPACE') Or (Nm = 'USE') Or (Nm = 'DECLARE') Then
    Begin
      While (CErr = '') And Not IsSym(';') And (Tok <> tkEof) And Not IsSym('{') Do PNext;
      If IsSym(';') Then PNext;
      Exit;
    End;
    If (Nm = 'CLASS') Or (Nm = 'INTERFACE') Or (Nm = 'TRAIT') Or (Nm = 'ENUM') Or (Nm = 'ABSTRACT') Or
       (Nm = 'FINAL') Or (Nm = 'GOTO') Then
    Begin
      CError(PTokRaw + ' : non pris en charge par le moteur PHP du Serveur Web');
      Exit;
    End;
  End;
  { expression }
  T := PExpr;
  PVarLoad := False;
  Emit(opPop);
  PSemi;
End;

{ ==================================================================== }
{ Premier passage : les fonctions et leurs parametres                   }
{ ==================================================================== }

Procedure PPrescan;
Var S, N : LongInt; Nm : String; Ref : Boolean; C : TCell; Prev : String; Depth : LongInt;
Begin
  Prev := '';
  While (CErr = '') And (Tok <> tkEof) Do
  Begin
    If IsKw('FUNCTION') And (Prev <> '->') Then
    Begin
      PNext;
      If IsSym('&') Then PNext;
      If (Tok = tkId) And (PPeekSym = '(') Then
      Begin
        Nm := TokS;
        If PFindFn(Nm) >= 0 Then
        Begin
          CError('fonction d'#130'j'#133' d'#130'finie : ' + PTokRaw + '()');
          Exit;
        End;
        S := AddSym(Nm, skFunc);
        Syms[S].Adr := -1; Syms[S].PBase := NParT; Syms[S].Lvl := 0; Syms[S].RetTy := TyVar; Syms[S].Ty := TyVar;
        PNext;
        PNext;
        N := 0;
        While (CErr = '') And Not IsSym(')') And (Tok <> tkEof) Do
        Begin
          Ref := False;
          { types (?int, int|string, array...), attributs, ... }
          While (CErr = '') And (Tok <> tkVar) And Not IsSym(')') And (Tok <> tkEof) Do
          Begin
            If IsSym('&') Then Ref := True;
            PNext;
          End;
          If Tok = tkVar Then
          Begin
            If NParT >= MaxPar Then
            Begin
              CError('trop de param'#138'tres');
              Exit;
            End;
            PName[NParT] := Copy(TokS, 1, 31); PTy[NParT] := TyVar; PRef[NParT] := Ref; PDefK[NParT] := 0;
            PNext;
            If IsSym('=') Then
            Begin
              PNext;
              If IsSym('[') Then
              Begin
                PNext;
                PExpect(']');
                PDefK[NParT] := 2;
              End
              Else If IsKw('ARRAY') Then
              Begin
                PNext;
                PExpect('(');
                PExpect(')');
                PDefK[NParT] := 2;
              End
              Else If ConstExprP(C) Then
              Begin
                PDefC[NParT] := C;
                PDefK[NParT] := 1;
              End;
            End;
            Inc(NParT);
            Inc(N);
          End;
          If IsSym(',') Then PNext;
        End;
        Syms[S].NPar := N;
      End;
      Continue;
    End;
    If IsKw('CLASS') Then
    Begin
      CError('class : non pris en charge par le moteur PHP du Serveur Web');
      Exit;
    End;
    If (Tok = tkSym) Then Prev := TokS Else Prev := '';
    PNext;
  End;
End;

Function CompilePhp(K : LongInt; Path, Root : String) : String;
Var Done_ : String;
Begin
  CP := K;
  ResetPage(K);
  BufInit(Src);
  BufInit(PIRaw);
  CErr := ''; CErrLine := 0;
  SiteRoot := Root;
  SrcDir := Path;
  While (Length(SrcDir) > 0) And (SrcDir[Length(SrcDir)] <> '\') Do Delete(SrcDir, Length(SrcDir), 1);
  Done_ := '|' + UpStr(Path) + '|';
  If Not LoadPhpSource(Path, 0, Src, Done_) Then
  Begin
    CompilePhp := 'fichier illisible : ' + Path;
    Exit;
  End;
  CurLvl := 0; LocTop := 0; LocMax := 0; GlobTop := 0; CurFunc := -1; NExit := 0; LoopDepth := 0; NWith := 0;
  NPG := 0; PFnExit := -1; PInFn := -1; PVarLoad := False;
  PredefSyms;
  { premier passage }
  SPos := 0; SLine := 1; InHtml := True; InEcho := False;
  PNext;
  PPrescan;
  { compilation }
  If CErr = '' Then
  Begin
    SPos := 0; SLine := 1; InHtml := True; InEcho := False;
    PNext;
    While (CErr = '') And (Tok <> tkEof) Do PStatement;
  End;
  Emit(opHalt);
  Pages[K].NGlob := GlobTop;
  BufFree(Src);
  BufFree(PIRaw);
  If CErr <> '' Then
  Begin
    CompilePhp := 'ligne ' + IStr(CErrLine) + ' : ' + CErr;
    ResetPage(K);
  End
  Else
  Begin
    Pages[K].Used := True;
    CompilePhp := '';
  End;
End;
{ ==================================================================== }
{ Site Web par defaut : cree au premier demarrage (comme iisstart.htm)   }
{ ==================================================================== }

Procedure PageLine(Var B : TBuf; S : String);
Begin
  BufAdd(B, S + #10);
End;

Procedure MakeIndex(Var B : TBuf);
Begin
  PageLine(B, '<!DOCTYPE html>');
  PageLine(B, '<html lang="fr"><head><meta charset="utf-8"><title>Serveur Web d''OS/2-0</title>');
  PageLine(B, '<style>');
  PageLine(B, 'body{margin:0;font-family:Helv,Helvetica,Arial,sans-serif;background:#c0c0c0;color:#000}');
  PageLine(B, '.t{background:#000080;color:#fff;padding:6px 12px;font-weight:bold}');
  PageLine(B, '.c{margin:24px auto;max-width:720px;background:#fff;border:2px outset #e0e0e0;padding:0}');
  PageLine(B, '.b{padding:12px 22px}h1{font-size:22px;margin:6px 0 12px}');
  PageLine(B, 'a{color:#000080}code{background:#eee;padding:1px 4px}');
  PageLine(B, 'ul li{margin:4px 0}.f{font-size:12px;color:#444;border-top:1px solid #888;padding:8px 22px}');
  PageLine(B, '</style></head><body><div class="c"><div class="t">Serveur Web d''OS/2-0</div><div class="b">');
  PageLine(B, '<h1>Bienvenue !</h1>');
  PageLine(B, '<p>Le serveur Web d''<b>OS/2-0</b> fonctionne. Cette page est le document par d'#195#169'faut');
  PageLine(B, 'du <i>Site Web par d'#195#169'faut</i> ; remplacez-la par vos propres pages.</p>');
  PageLine(B, '<ul><li><a href="demo.psp">D'#195#169'monstration PSP</a> (Pascal Server Pages)</li>');
  PageLine(B, '<li><a href="demo.asp">D'#195#169'monstration ASP</a> (VBScript)</li>');
  PageLine(B, '<li><a href="demo.php">D'#195#169'monstration PHP</a> (PHP compil'#195#169')</li>');
  PageLine(B, '<li><a href="infos.psp">Variables du serveur</a> (Request.ServerVariables)</li></ul>');
  PageLine(B, '<p>Administration : <b>Outils r'#195#169'seau &rarr; Serveur Web</b> sur le bureau d''OS/2-0.</p>');
  PageLine(B, '</div><div class="f">OS2-0-WebSrv ' + AppVer + ' &mdash; HTTP/1.1, HTTPS (TLS 1.3), PSP, ASP, PHP</div>');
  PageLine(B, '</div></body></html>');
End;

Procedure MakeDemoPsp(Var B : TBuf);
Begin
  PageLine(B, '<%@ Language="PascalScript" %>');
  PageLine(B, '<!DOCTYPE html>');
  PageLine(B, '<html><head><meta charset="utf-8"><title>D'#195#169'monstration PSP</title></head>');
  PageLine(B, '<body style="font-family:Helv,Helvetica,Arial,sans-serif">');
  PageLine(B, '<h1>Pascal Server Pages sur OS/2-0</h1>');
  PageLine(B, '<%');
  PageLine(B, 'var');
  PageLine(B, '  i : Integer;');
  PageLine(B, '  nom : String;');
  PageLine(B, '');
  PageLine(B, 'function Factorielle(N : Integer) : LongInt;');
  PageLine(B, 'begin');
  PageLine(B, '  if N <= 1 then Factorielle := 1');
  PageLine(B, '  else Factorielle := N * Factorielle(N - 1);');
  PageLine(B, 'end;');
  PageLine(B, '');
  PageLine(B, 'begin');
  PageLine(B, '  nom := Request.QueryString(''nom'');');
  PageLine(B, '  if nom = '''' then nom := ''visiteur'';');
  PageLine(B, '  Session(''visites'') := Session(''visites'') + 1;');
  PageLine(B, 'end.');
  PageLine(B, '%>');
  PageLine(B, '<p>Bonjour <b><%= Server.HTMLEncode(nom) %></b> ! Il est <%= TimeToStr %> le <%= DateToStr %>.</p>');
  PageLine(B, '<p>Visites de cette session : <%= Session(''visites'') %></p>');
  PageLine(B, '<form method="get"><input name="nom" placeholder="Votre nom"> <input type="submit" value="Envoyer"></form>');
  PageLine(B, '<table border="1" cellpadding="4"><tr><th>n</th><th>n!</th><th>n&sup2;</th></tr>');
  PageLine(B, '<% for i := 1 to 10 do begin %>');
  PageLine(B, '<tr><td><%= i %></td><td><%= Factorielle(i) %></td><td><%= Sqr(i) %></td></tr>');
  PageLine(B, '<% end; %>');
  PageLine(B, '</table>');
  PageLine(B, '<p><a href="/">Retour</a></p>');
  PageLine(B, '</body></html>');
End;

Procedure MakeDemoAsp(Var B : TBuf);
Begin
  PageLine(B, '<%@ Language="VBScript" %>');
  PageLine(B, '<!DOCTYPE html>');
  PageLine(B, '<html><head><meta charset="utf-8"><title>D'#195#169'monstration ASP</title></head>');
  PageLine(B, '<body style="font-family:Helv,Helvetica,Arial,sans-serif">');
  PageLine(B, '<h1>Active Server Pages (VBScript) sur OS/2-0</h1>');
  PageLine(B, '<%');
  PageLine(B, 'Dim couleurs, c, i');
  PageLine(B, 'couleurs = Array("rouge", "vert", "bleu")');
  PageLine(B, 'Application.Lock');
  PageLine(B, 'Application("pages") = Application("pages") + 1');
  PageLine(B, 'Application.Unlock');
  PageLine(B, 'Function Titre(s)');
  PageLine(B, '  Titre = UCase(Left(s, 1)) & Mid(s, 2)');
  PageLine(B, 'End Function');
  PageLine(B, '%>');
  PageLine(B, '<p>Pages servies depuis le d'#195#169'marrage du serveur : <%= Application("pages") %></p>');
  PageLine(B, '<ul>');
  PageLine(B, '<% For Each c In couleurs %>');
  PageLine(B, '<li style="color:<%= c %>"><%= Titre(c) %></li>');
  PageLine(B, '<% Next %>');
  PageLine(B, '</ul>');
  PageLine(B, '<p><% For i = 1 To 5 : Response.Write i * i & " " : Next %></p>');
  PageLine(B, '<p>Navigateur : <%= Server.HTMLEncode(Request.ServerVariables("HTTP_USER_AGENT")) %></p>');
  PageLine(B, '<p><a href="/">Retour</a></p>');
  PageLine(B, '</body></html>');
End;

Procedure MakeDemoPhp(Var B : TBuf);
Begin
  PageLine(B, '<?php');
  PageLine(B, 'session_start();');
  PageLine(B, '$_SESSION[''vues''] = ($_SESSION[''vues''] ?? 0) + 1;');
  PageLine(B, '$nom = trim($_GET[''nom''] ?? '''');');
  PageLine(B, 'if ($nom === '''') $nom = ''visiteur'';');
  PageLine(B, 'function factorielle(int $n): int { return $n <= 1 ? 1 : $n * factorielle($n - 1); }');
  PageLine(B, '$fruits = [''pomme'' => 3, ''poire'' => 5, ''kiwi'' => 2];');
  PageLine(B, 'arsort($fruits);');
  PageLine(B, '?>');
  PageLine(B, '<!DOCTYPE html>');
  PageLine(B, '<html><head><meta charset="utf-8"><title>D'#195#169'monstration PHP</title></head>');
  PageLine(B, '<body style="font-family:Helv,Helvetica,Arial,sans-serif">');
  PageLine(B, '<h1>PHP compil'#195#169' sur OS/2-0</h1>');
  PageLine(B, '<p>Bonjour <b><?= htmlspecialchars($nom) ?></b> ! Nous sommes le <?= date(''d/m/Y'') ?>, il est <?= date(''H:i:s'') ?>.</p>');
  PageLine(B, '<p>Vues de cette page dans la session : <?= $_SESSION[''vues''] ?></p>');
  PageLine(B, '<form method="get"><input name="nom" placeholder="Votre nom"> <input type="submit" value="Envoyer"></form>');
  PageLine(B, '<table border="1" cellpadding="4"><tr><th>n</th><th>n!</th><th>n&sup2;</th></tr>');
  PageLine(B, '<?php for ($i = 1; $i <= 10; $i++): ?>');
  PageLine(B, '<tr><td><?= $i ?></td><td><?= factorielle($i) ?></td><td><?= $i ** 2 ?></td></tr>');
  PageLine(B, '<?php endfor; ?>');
  PageLine(B, '</table>');
  PageLine(B, '<ul>');
  PageLine(B, '<?php foreach ($fruits as $f => $q) echo "<li>" . ucfirst($f) . " : $q</li>\n"; ?>');
  PageLine(B, '</ul>');
  PageLine(B, '<p>Serveur : <?= htmlspecialchars($_SERVER[''SERVER_SOFTWARE''] ?? '''') ?>, PHP <?= PHP_VERSION ?></p>');
  PageLine(B, '<p><a href="/">Retour</a></p>');
  PageLine(B, '</body></html>');
End;

Procedure MakeInfos(Var B : TBuf);
Begin
  PageLine(B, '<!DOCTYPE html>');
  PageLine(B, '<html><head><meta charset="utf-8"><title>Variables du serveur</title></head>');
  PageLine(B, '<body style="font-family:Helv,Helvetica,Arial,sans-serif"><h1>Request.ServerVariables</h1>');
  PageLine(B, '<table border="1" cellpadding="3">');
  PageLine(B, '<%');
  PageLine(B, 'const');
  PageLine(B, '  Noms : array[1..14] of String = (''SERVER_SOFTWARE'', ''SERVER_NAME'', ''SERVER_PORT'', ''HTTPS'',');
  PageLine(B, '    ''LOCAL_ADDR'', ''REMOTE_ADDR'', ''REQUEST_METHOD'', ''URL'', ''QUERY_STRING'', ''PATH_TRANSLATED'',');
  PageLine(B, '    ''APPL_PHYSICAL_PATH'', ''INSTANCE_ID'', ''HTTP_HOST'', ''HTTP_USER_AGENT'');');
  PageLine(B, 'var');
  PageLine(B, '  i : Integer;');
  PageLine(B, 'begin');
  PageLine(B, '  for i := 1 to 14 do');
  PageLine(B, '    WriteLn(''<tr><td>'', Noms[i], ''</td><td>'',');
  PageLine(B, '            Server.HTMLEncode(Request.ServerVariables(Noms[i])), ''</td></tr>'');');
  PageLine(B, 'end.');
  PageLine(B, '%>');
  PageLine(B, '</table><p><a href="/">Retour</a></p></body></html>');
End;

{ creer le dossier racine du site par defaut s'il n'existe pas }
Procedure EnsureDefaultSite;
Var B : TBuf; R : String;
Begin
  If Not Sites[0].Used Then Exit;
  R := Sites[0].Root;
  If PExists(R) Then Exit;
  PMkDir(R);
  If Not PExists(R) Then Exit;
  BufInit(B); MakeIndex(B); Dummy := Ord(WriteFileBuf(R + '\index.html', B.P, B.Len)); BufFree(B);
  BufInit(B); MakeDemoPsp(B); Dummy := Ord(WriteFileBuf(R + '\demo.psp', B.P, B.Len)); BufFree(B);
  BufInit(B); MakeDemoAsp(B); Dummy := Ord(WriteFileBuf(R + '\demo.asp', B.P, B.Len)); BufFree(B);
  BufInit(B); MakeDemoPhp(B); Dummy := Ord(WriteFileBuf(R + '\demo.php', B.P, B.Len)); BufFree(B);
  BufInit(B); MakeInfos(B); Dummy := Ord(WriteFileBuf(R + '\infos.psp', B.P, B.Len)); BufFree(B);
  SysLog('Site Web par defaut cree dans ' + R);
End;

{ ==================================================================== }
{ Service : ecoute, boucle de select, etat partage avec la console      }
{ ==================================================================== }

{ memoire partagee \SHAREMEM\WEBSRV (Create : le service la cree) }
Function StatOpen(Create : Boolean) : Boolean;
{$IFDEF OS2PC}
Var P : LongInt;
Begin
  P := 0;
  StatOpen := False;
  If DosGetNamedSharedMem(LongInt(@P), Z('\SHAREMEM\WEBSRV'), $13) = 0 Then
  Begin
    Shm := Pointer(P);
    StatOpen := True;
    Exit;
  End;
  If Not Create Then
  Begin
    Shm := @StatLocal;
    Exit;
  End;
  If DosAllocSharedMem(LongInt(@P), Z('\SHAREMEM\WEBSRV'), 4096, $13) = 0 Then
  Begin
    Shm := Pointer(P);
    FillChar(Shm^, SizeOf(TStat), 0);
    StatOpen := True;
  End
  Else Shm := @StatLocal;
End;
{$ELSE}
Begin
  Shm := @StatLocal;
  StatOpen := Create;
End;
{$ENDIF}

{ le service tourne-t-il (son coeur bat) ? }
Function ServiceAlive : Boolean;
Begin
  ServiceAlive := False;
  If Shm = Nil Then Exit;
  If (Shm^.Magic <> StatMagic) Or (Shm^.Running = 0) Then Exit;
  {$IFDEF OS2PC}
  If KTaskCtl(3, Shm^.Pid, 0, 0) <> 1 Then Exit;
  {$ENDIF}
  ServiceAlive := True;
End;

Procedure StatUpdate;
Var I : LongInt;
Begin
  Shm^.Magic := StatMagic;
  Shm^.Heart := PTicks;
  Shm^.Requests := TotReq; Shm^.BytesOut := TotBytesOut; Shm^.BytesIn := TotBytesIn; Shm^.Errors := TotErr;
  Shm^.CurConn := CurConn; Shm^.MaxConn := MaxSeen;
  For I := 0 To MaxSites - 1 Do
  Begin
    Shm^.SiteReq[I] := Sites[I].Requests;
    Shm^.SiteOut[I] := Sites[I].BytesOut;
    Shm^.SiteId[I] := Sites[I].Id;
    If Not Sites[I].Used Then Shm^.SiteState[I] := 0
    Else If Sites[I].Status <> '' Then Shm^.SiteState[I] := 2
    Else If Sites[I].Started Then Shm^.SiteState[I] := 1
    Else Shm^.SiteState[I] := 0;
  End;
  Shm^.LastMsg := LogMsg;
End;

{ sockets d'ecoute : un par port des sites demarres }
Procedure OpenListeners;
Var I, J, K, F, S : LongInt; Need : Array[0..MaxListen - 1] Of Boolean; Found : Boolean;
Begin
  For K := 0 To NListen - 1 Do Need[K] := False;
  For I := 0 To MaxSites - 1 Do
  Begin
    Sites[I].Status := '';
    If Sites[I].Used And Sites[I].Started Then
    Begin
      CertLoad(I);
      If SiteHasTls(I) And Not CertOk[I] Then Sites[I].Status := CertMsg[I];
      For J := 0 To Sites[I].NB - 1 Do
      Begin
        F := -1;
        For K := 0 To NListen - 1 Do
          If LPort[K] = Sites[I].B[J].Port Then F := K;
        If (F >= 0) And (LTls[F] <> Sites[I].B[J].Tls) Then
        Begin
          Sites[I].Status := 'port ' + IStr(Sites[I].B[J].Port) + ' deja pris par l''autre protocole';
          Continue;
        End;
        If F < 0 Then
        Begin
          If NListen >= MaxListen Then Continue;
          S := PListen(Sites[I].B[J].Port);
          If S < 0 Then
          Begin
            Sites[I].Status := 'port ' + IStr(Sites[I].B[J].Port) + ' indisponible';
            SysLog('Site ' + IStr(Sites[I].Id) + ' : ' + Sites[I].Status);
            Continue;
          End;
          F := NListen;
          LSock[F] := S; LPort[F] := Sites[I].B[J].Port; LTls[F] := Sites[I].B[J].Tls; LIp[F] := 0;
          Need[F] := True;
          Inc(NListen);
          If LTls[F] Then SysLog('Ecoute sur le port ' + IStr(LPort[F]) + ' (https)')
          Else SysLog('Ecoute sur le port ' + IStr(LPort[F]) + ' (http)');
        End;
        Need[F] := True;
      End;
    End;
  End;
  { ports qui ne servent plus }
  K := 0;
  While K < NListen Do
  Begin
    If Not Need[K] Then
    Begin
      PSockClose(LSock[K]);
      SysLog('Fin de l''ecoute sur le port ' + IStr(LPort[K]));
      For J := 0 To MaxConn - 1 Do
        If (Conns[J].State <> csFree) And (Conns[J].LIdx > K) Then Dec(Conns[J].LIdx);
      For J := K To NListen - 2 Do
      Begin
        LSock[J] := LSock[J + 1]; LPort[J] := LPort[J + 1]; LTls[J] := LTls[J + 1]; Need[J] := Need[J + 1];
      End;
      Dec(NListen);
    End
    Else Inc(K);
  End;
  Found := False;
  For K := 0 To NListen - 1 Do Found := True;
  If Not Found Then SysLog('Aucun site demarre.');
End;

Procedure Pump(C : LongInt); Forward;

{ apres une reponse : requete suivante ou fermeture }
Procedure ResponseDone(C : LongInt);
Begin
  LogRequest(C);
  If Conns[C].Site >= 0 Then Sites[Conns[C].Site].BytesOut := Sites[Conns[C].Site].BytesOut + Conns[C].SentBytes;
  If Not Conns[C].KeepAlive Then
  Begin
    If Conns[C].IsTls Then
    Begin
      TlsAlert(C, 0);
      If Conns[C].TxLen > 0 Then Dummy := PSend(Conns[C].Sock, Conns[C].Tx, Conns[C].TxLen);
    End;
    ConnClose(C);
    Exit;
  End;
  NextRequest(C);
End;

{ lire ce qui est arrive sur la connexion }
Procedure OnRead(C : LongInt);
Var N, Room : LongInt; Again : Boolean;
Begin
  With Conns[C] Do
  Begin
    If IsTls Then
    Begin
      Room := RxCap - RxLen;
      If Room <= 0 Then
      Begin
        ConnClose(C);
        Exit;
      End;
      N := PRecv(Sock, @Rx^[RxLen], Room);
    End
    Else If State = csBody Then N := PRecv(Sock, @Body^[BodyGot], BodyLen - BodyGot)
    Else
    Begin
      Room := ReqCap - ReqLen;
      If Room <= 0 Then
      Begin
        ParseRequest(C);
        Exit;
      End;
      N := PRecv(Sock, @Req^[ReqLen], Room);
    End;
    If N = -1 Then Exit;
    If N <= 0 Then
    Begin
      ConnClose(C);
      Exit;
    End;
    TotBytesIn := TotBytesIn + N;
    TLast := PTicks;
    RandStir(N Xor TLast);
    If Not IsTls Then
    Begin
      If State = csBody Then BodyGot := BodyGot + N Else ReqLen := ReqLen + N;
      ParseRequest(C);
    End
    Else
    Begin
      RxLen := RxLen + N;
      Repeat
        TlsGotData := False;
        If Not TlsInput(C) Then
        Begin
          If TxLen > TxPos Then Dummy := PSend(Sock, @Tx^[TxPos], TxLen - TxPos);
          ConnClose(C);
          Exit;
        End;
        If (TlsSt = 2) And ((State = csRead) Or (State = csBody)) Then ParseRequest(C);
        Again := TlsGotData And ((State = csRead) Or (State = csBody)) And (RxLen >= 5);
      Until Not Again;
    End;
  End;
  If (Conns[C].State <> csFree) And (Conns[C].TxLen > Conns[C].TxPos) Then Pump(C);
End;

{ envoyer : Tx, puis le corps de la reponse par blocs }
Procedure Pump(C : LongInt);
Var N, R, Loops : LongInt;
Begin
  Loops := 0;
  While (Conns[C].State <> csFree) And (Loops < 8) Do
  Begin
    Inc(Loops);
    With Conns[C] Do
    Begin
      If TxPos < TxLen Then
      Begin
        R := PSend(Sock, @Tx^[TxPos], TxLen - TxPos);
        If R < 0 Then
        Begin
          ConnClose(C);
          Exit;
        End;
        If R > 0 Then TLast := PTicks;
        TotBytesOut := TotBytesOut + R;
        TxPos := TxPos + R;
        If TxPos < TxLen Then Exit;
        TxPos := 0; TxLen := 0;
      End;
      If State <> csSend Then Exit;
      If (BSrc = bsMem) And (BPos < BLen) Then
      Begin
        N := BLen - BPos;
        If N > ChunkSz Then N := ChunkSz;
        Dummy := Ord(ConnPut(C, @BMem^[BPos], N));
        BPos := BPos + N;
        SentBytes := SentBytes + N;
      End
      Else If (BSrc = bsFile) And (BLeft > 0) Then
      Begin
        N := BLeft;
        If N > ChunkSz Then N := ChunkSz;
        R := PRead(BFile, @Scratch, N);
        If R <= 0 Then
        Begin
          ConnClose(C);
          Exit;
        End;
        Dummy := Ord(ConnPut(C, @Scratch, R));
        BLeft := BLeft - R;
        SentBytes := SentBytes + R;
      End
      Else
      Begin
        { reponse finie }
        ResponseDone(C);
        If Conns[C].State = csFree Then Exit;
        { requete suivante deja recue (pipeline) }
        If Conns[C].IsTls Then
        Begin
          If Conns[C].RxLen >= 5 Then
          Begin
            If Not TlsInput(C) Then
            Begin
              ConnClose(C);
              Exit;
            End;
          End;
        End;
        If Conns[C].ReqLen > 0 Then ParseRequest(C);
        If Conns[C].State <> csSend Then Exit;
      End;
    End;
  End;
End;

Procedure AcceptAll(L : LongInt);
Var S, Ip, Port, Loc, K, C : LongInt;
Begin
  For K := 1 To 16 Do
  Begin
    S := PAccept(LSock[L], Ip, Port, Loc);
    If S < 0 Then Exit;
    C := ConnNew(S, L, Ip, Port, Loc);
  End;
End;


{ toutes les secondes : delais, journal, etat partage, commandes }
Procedure Housekeeping;
Var C, Idle, Lim : LongInt;
Begin
  LastHouse := PTicks;
  For C := 0 To MaxConn - 1 Do
    If Conns[C].State <> csFree Then
    Begin
      Idle := (PTicks - Conns[C].TLast) Div 1000;
      If (Conns[C].State = csRead) And (Conns[C].ReqLen = 0) And (Conns[C].NReq > 0) Then Lim := KeepAliveS
      Else If (Conns[C].State = csVm) Or (Conns[C].State = csWaitVm) Then Lim := ScriptTimeoutS + 30
      Else Lim := ConnTimeoutS;
      If Idle > Lim Then ConnClose(C);
    End;
  If PTicks - LastLogFlush > 2000 Then LogFlushAll;
  VmHouse;
  StatUpdate;
  If Shm^.CmdSeq <> Shm^.CmdAck Then
  Begin
    Shm^.CmdAck := Shm^.CmdSeq;
    If Shm^.Cmd = cmdStop Then
    Begin
      SysLog('Arret demande par la console.');
      Running := False;
    End
    Else If Shm^.Cmd = cmdReload Then
    Begin
      SysLog('Configuration relue.');
      CfgLoad;
      OpenListeners;
    End;
  End;
End;

Procedure ServiceLoop;
Var R, W : TFdMask; I, MaxFd, N, Ms : LongInt; Busy : Boolean;
Begin
  While Running Do
  Begin
    FdZero(R); FdZero(W);
    MaxFd := 0;
    For I := 0 To NListen - 1 Do
    Begin
      FdSet(R, LSock[I]);
      If LSock[I] + 1 > MaxFd Then MaxFd := LSock[I] + 1;
    End;
    For I := 0 To MaxConn - 1 Do
      With Conns[I] Do
        If State <> csFree Then
        Begin
          If (State = csTls) Or (State = csRead) Or (State = csBody) Then FdSet(R, Sock);
          If TxPos < TxLen Then FdSet(W, Sock);
          If Sock + 1 > MaxFd Then MaxFd := Sock + 1;
        End;
    If DbWaitSock >= 0 Then
    Begin
      FdSet(R, DbWaitSock);
      If DbWaitSock + 1 > MaxFd Then MaxFd := DbWaitSock + 1;
    End;
    Busy := VmBusy;
    For I := 0 To MaxConn - 1 Do
      If (Conns[I].State = csSend) And (Conns[I].TxLen = 0) Then Busy := True;
    If Busy Then Ms := 0 Else Ms := 200;
    N := PSelect(R, W, MaxFd, Ms);
    If N > 0 Then
    Begin
      For I := 0 To NListen - 1 Do
        If FdIsSet(R, LSock[I]) Then AcceptAll(I);
      For I := 0 To MaxConn - 1 Do
        If Conns[I].State <> csFree Then
        Begin
          If FdIsSet(R, Conns[I].Sock) Then OnRead(I);
          If (Conns[I].State <> csFree) And FdIsSet(W, Conns[I].Sock) Then Pump(I);
        End;
    End;
    For I := 0 To MaxConn - 1 Do
      If (Conns[I].State = csSend) And (Conns[I].TxLen = 0) Then Pump(I);
    VmStep;
    If PTicks - LastHouse >= 1000 Then Housekeeping;
    {$IFDEF OS2PC}
    If N > 0 Then Dummy := DosSleep(0);
    {$ENDIF}
  End;
End;

{ WEBSRV /SERVICE }
Procedure ServiceMain;
Var I : LongInt;
Begin
  ServiceMode := True;
  PickDirs;
  Dummy := Ord(StatOpen(True));
  If ServiceAlive And (Shm^.Pid <> 0) Then
  Begin
    {$IFDEF OS2PC}
    If Shm^.Pid <> KPid Then
    Begin
      SysLog('Le serveur Web tourne deja (PID ' + IStr(Shm^.Pid) + ').');
      Exit;
    End;
    {$ENDIF}
  End;
  {$IFDEF OS2PC}
  { classe "temps libre" : tranches de 10 ms, le reste du systeme ne
    ralentit pas }
  Dummy := DosSetPriority(0, 1, 0, 0);
  Shm^.Pid := KPid;
  {$ENDIF}
  CfgLoad;
  EnsureDefaultSite;
  TlsInitTables;
  GetMem(Pool, MaxConn * (RxCap + ReqCap + TxCap));
  If Pool = Nil Then
  Begin
    SysLog('Memoire insuffisante.');
    Exit;
  End;
  For I := 0 To MaxConn - 1 Do Conns[I].State := csFree;
  For I := 0 To MaxSites - 1 Do
  Begin
    BufInit(LogBuf[I]); BufInit(CertDer[I]);
  End;
  If Not PNetInit Then
  Begin
    SysLog('Reseau indisponible (TCPIP32.DLL : aucune carte ou adresse).');
    Shm^.Running := 0;
    Exit;
  End;
  SysLog('Serveur Web d''OS/2-0 ' + AppVer + ' : demarrage (' + IpStr(MyIpAddr) + ', ' + CfgPath + ').');
  NListen := 0; CurConn := 0;
  StartTick := PTicks; LastHouse := 0; LastLogFlush := PTicks;
  OpenListeners;
  Shm^.StartTime := NowUnix;
  Shm^.Running := 1;
  StatUpdate;
  Running := True;
  ServiceLoop;
  For I := 0 To MaxConn - 1 Do
    If Conns[I].State <> csFree Then ConnClose(I);
  For I := 0 To NListen - 1 Do PSockClose(LSock[I]);
  LogFlushAll;
  Shm^.Running := 0;
  StatUpdate;
  SysLog('Serveur Web arrete.');
End;

{ ==================================================================== }
{ Console d'administration (Presentation Manager), dans le style d'IIS  }
{ ==================================================================== }
{ Fenetre principale :
    - menus deroulants Fichier, Action, Affichage, Outils et ? ;
    - barre d'outils (Demarrer, Arreter, Redemarrer, Actualiser, Ajouter un
      site, Parcourir) ;
    - a gauche, l'arbre des connexions : le serveur, ses Sites (chaque site
      et ses categories de configuration), les Types MIME, les Parametres
      du serveur, la Surveillance et le Journal du serveur ;
    - au centre, le panneau qui suit l'arbre (accueil avec les icones des
      fonctionnalites, listes, formulaires de reglage) ;
    - a droite, le volet Actions d'IIS (liens selon la selection), cache
      quand la fenetre est etroite (les memes commandes sont dans les
      menus) ;
    - en bas, la barre d'etat (message, etat du serveur).
  Les listes (liaisons, documents, types MIME...) s'appliquent tout de
  suite ; les formulaires ont un bouton Appliquer. Appliquer enregistre
  WEBSRV.CFG et, si le serveur tourne, lui fait relire sa configuration.
  "Demarrer le serveur Web avec OS/2" ajoute ou retire la ligne
  RUN=...\WEBSRV.EXE /SERVICE de CONFIG.SYS (par defaut : non). }

{$IFDEF OS2PC}

Const
  WM_CREATE = $0001; WM_SIZE = $0007; WM_COMMAND = $0020; WM_PAINT = $0023; WM_TIMER = $0024;
  WM_CONTROL = $0030; WM_CLOSE = $0029; WM_MOUSEMOVE = $0070;
  WM_BUTTON1DOWN = $0071; WM_BUTTON1UP = $0072; WM_BUTTON1DBLCLK = $0073; WM_BUTTON2DOWN = $0074;
  WM_CHAR = $007A;
  FCF_TITLEBAR = 1; FCF_SYSMENU = 2; FCF_SIZEBORDER = 8; FCF_MINBUTTON = $10; FCF_MAXBUTTON = $20;
  FCF_DLGBORDER = $100; FCF_TASKLIST = $800;
  HWND_DESKTOP = 1; HWND_TOP = 3;
  SWP_SIZE = 1; SWP_MOVE = 2; SWP_ZORDER = 4; SWP_SHOW = 8; SWP_ACTIVATE = $80;
  MIS_TEXT = 1; MIS_SEPARATOR = 4; MIS_SUBMENU = $10;
  MIA_CHECKED = $2000; MIA_DISABLED = $4000; MM_SETITEMATTR = $0192;
  MB_OK = 0; MB_YESNO = 4; MB_INFORMATION = $30; MB_WARNING = $20; MB_ERROR = $40; MB_QUERY = $10;
  MB_MOVEABLE = $4000; MBID_YES = 6;
  KC_CHAR = 1; KC_VIRTUALKEY = 2; KC_SHIFT = 8; KC_CTRL = $10; KC_ALT = $20; KC_KEYUP = $40;
  VK_TAB = $06; VK_BACKTAB = $07; VK_NEWLINE = $08; VK_ESC = $0F; VK_PAGEUP = $11; VK_PAGEDOWN = $12; VK_END = $13; VK_HOME = $14;
  VK_LEFT = $15; VK_UP = $16; VK_RIGHT = $17; VK_DOWN = $18; VK_DELETE = $1B; VK_ENTER = $1E; VK_F1 = $20;
  VK_F5 = $24;
  WC_BUTTON = $FFFF0003; WC_STATIC = $FFFF0005; WC_ENTRYFIELD = $FFFF0006; WC_LISTBOX = $FFFF0007;
  WS_VISIBLE = $80000000; WS_TABSTOP = $00020000;
  BS_PUSHBUTTON = 0; BS_AUTOCHECKBOX = 2; BS_DEFAULT = $0400;
  ES_AUTOSCROLL = 4; ES_MARGIN = 8; ES_UNREADABLE = $80;
  EM_SETTEXTLIMIT = $0143;
  BM_QUERYCHECK = $0124; BM_SETCHECK = $0125;
  LM_INSERTITEM = $0161; LM_SELECTITEM = $0164; LM_QUERYSELECTION = $0165; LM_DELETEALL = $016E;
  LN_SELECT = 1; LN_ENTER = 5;
  { couleurs de PM }
  cBlue = 1; cRed = 2; cPink = 3; cGreen = 4; cCyan = 5; cYellow = 6; cGray = 8; cNavy = 9; cMaroon = 10;
  cDGreen = 12; cTeal = 13; cBrown = 14; cSilver = 15; cWhite = -2; cBlack = -1;
  { dimensions }
  TbH = 32; SbH = 22; HdrH = 46; RowH = 18; ActW0 = 204;
  { sortes de noeuds de l'arbre }
  nkServer = 1; nkSites = 2; nkSite = 3; nkMime = 4; nkSettings = 5; nkMonitor = 6; nkLogs = 7;
  nkBind = 20; nkBasic = 21; nkDocs = 22; nkBrowse = 23; nkErr = 24; nkHdr = 25; nkVDir = 26; nkAuth = 27;
  nkHand = 28; nkCert = 29; nkLog = 30;
  nkFirstCat = 20; nkLastCat = 30;
  { commandes }
  cmSave = 101; cmReloadCfg = 102; cmQuit = 103;
  cmStart = 111; cmStop = 112; cmRestart = 113; cmAddSite = 114; cmDelSite = 115; cmSiteOn = 116;
  cmSiteOff = 117; cmBrowse = 118; cmSiteProps = 119; cmEditSite = 120; cmGoBind = 121;
  cmActions = 131; cmRefresh = 132; cmExpand = 133; cmCollapse = 134;
  cmCert = 141; cmAutoStart = 142; cmOpenLogs = 143; cmOpenRoot = 144;
  cmHelp = 151; cmAbout = 152;
  { boutons des panneaux }
  cmApply = 201; cmCancel = 202; cmAdd = 203; cmEdit = 204; cmDel = 205; cmUp = 206; cmDown = 207;
  cmMakeCert = 208; cmClearLog = 209;
  { identifiants des controles }
  idCtl = 1000; idList = 1001;
  MaxNode = 220; MaxCtl = 40; MaxLbl = 24; MaxAct = 16; MaxTile = 12;

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
Function WinSetWindowText(H, P : LongInt) : LongInt; External 'PMWIN';
Function WinQueryWindowText(H, Cch, P : LongInt) : LongInt; External 'PMWIN';
Function WinMessageBox(HPar, HOwn, PText, PCap, Id, Fl : LongInt) : LongInt; External 'PMWIN';
Function WinPostMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinSendMsg(H, Msg, Mp1, Mp2 : LongInt) : LongInt; External 'PMWIN';
Function WinCreateMenu(HPar, P : LongInt) : LongInt; External 'PMWIN';
Function WinPopupMenu(HPar, HOwn, HMenu, X, Y, Id, Fs : LongInt) : LongInt; External 'PMWIN';
Function WinQuerySysValue(HD, Ix : LongInt) : LongInt; External 'PMWIN';
Function WinSetFocus(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinSetActiveWindow(HD, H : LongInt) : LongInt; External 'PMWIN';
Function WinWindowFromID(H, Id : LongInt) : LongInt; External 'PMWIN';
Function WinCalcFrameRect(H, P, FClient : LongInt) : LongInt; External 'PMWIN';
Function WinCreateWindow(HPar, PCls, PName, Style, X, Y, Cx, Cy, HOwn, HBehind, Id, PCtl, PPres : LongInt) : LongInt; External 'PMWIN';
Function WinEnableWindow(H, En : LongInt) : LongInt; External 'PMWIN';
Function WinStartTimer(Hab, H, Id, Dt : LongInt) : LongInt; External 'PMWIN';
Function WinAlarm(HD, Typ : LongInt) : LongInt; External 'PMWIN';
Function WinQueryFocus(HD : LongInt) : LongInt; External 'PMWIN';
Function WinSetPresParam(H, Id, Cb, P : LongInt) : LongInt; External 'PMWIN';
Function GpiSetColor(Hps, C : LongInt) : LongInt; External 'PMGPI';
Function GpiMove(Hps, P : LongInt) : LongInt; External 'PMGPI';
Function GpiLine(Hps, P : LongInt) : LongInt; External 'PMGPI';

Var
  Hab, Hmq, Frame, Client, MenuHw, Hps, CW, CH : LongInt;
  GQmsg : Array[0..7] Of LongInt;
  MenuT : Array[0..4095] Of Byte;
  MenuLen : LongInt;
  TxtBuf : Array[0..511] Of Byte;
  { arbre }
  NNode, NSel, NTop : LongInt;
  NKind, NSite, NLev : Array[0..MaxNode - 1] Of LongInt;
  NKids : Array[0..MaxNode - 1] Of Boolean;
  ExpServer, ExpSites : Boolean;
  ExpSite : Array[0..MaxSites - 1] Of Boolean;
  SelKind, SelSite : LongInt;
  TreeW, ActW : LongInt;
  ShowAct : Boolean;
  { controles du panneau }
  NCtl : LongInt;
  CtlH, CtlX, CtlY, CtlW, CtlHt, CtlFl, CtlId : Array[0..MaxCtl - 1] Of LongInt;
  CtlRx, CtlRy, CtlRw, CtlRh : Array[0..MaxCtl - 1] Of LongInt;   { position reelle (Y vers le bas) }
  NLbl : LongInt;
  LblX, LblY, LblC : Array[0..MaxLbl - 1] Of LongInt;
  LblS : Array[0..MaxLbl - 1] Of String[95];
  ListH : LongInt;           { liste du panneau (0 : aucune) }
  ListHdr : String;          { titres des colonnes }
  ListY : LongInt;
  { volet Actions et icones des fonctionnalites }
  NAct : LongInt;
  ActCmd, ActY : Array[0..MaxAct - 1] Of LongInt;
  ActS : Array[0..MaxAct - 1] Of String[47];
  NTile, TileW, TileH : LongInt;
  TileK, TileX, TileY : Array[0..MaxTile - 1] Of LongInt;
  { etat }
  StatusMsg : String;
  Dirty : Boolean;
  ReqHist, ConnHist : Array[0..59] Of LongInt;
  LastReqCnt, HistN : LongInt;
  LastAlive : Boolean;
  ConfigSys : String;
  { boite de saisie }
  DFrame, DClient, DN : LongInt;
  DDone, DOk : Boolean;
  DLab : Array[0..4] Of String[47];
  DlgV : Array[0..4] Of String;
  DEf : Array[0..4] Of LongInt;
  DChkS : String[63];
  DChk : Boolean;
  DChkH, DW, DH : LongInt;
  DPass : LongInt;           { champ masque (mot de passe) : numero + 1 }

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
  If V >= 32768 Then V := V - 65536;
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

Procedure PutZ(S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do TxtBuf[K - 1] := Ord(S[K]);
  TxtBuf[Length(S)] := 0;
End;

{ texte d'une fenetre (champ de saisie) }
Function WinText(H : LongInt) : String;
Var B : Array[0..299] Of Byte; N, K : LongInt; S : String;
Begin
  S := '';
  N := WinQueryWindowText(H, 255, LongInt(@B));
  If N > 255 Then N := 255;
  For K := 0 To N - 1 Do
  Begin
    If B[K] = 0 Then Break;
    S := S + Chr(B[K]);
  End;
  WinText := S;
End;

Procedure Msg(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Serveur Web'), 0, MB_OK Or MB_INFORMATION Or MB_MOVEABLE);
End;

Procedure MsgErr(S : String);
Begin
  Dummy := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Serveur Web'), 0, MB_OK Or MB_ERROR Or MB_MOVEABLE);
End;

Function Ask(S : String) : Boolean;
Begin
  Ask := WinMessageBox(HWND_DESKTOP, Frame, Z(S), Z2('Serveur Web'), 0, MB_YESNO Or MB_QUERY Or MB_MOVEABLE) =
         MBID_YES;
End;

{ --- dessin (coordonnees de la zone client, Y vers le bas) --- }

Procedure FBar(X1, Y1, X2, Y2, C : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If (X2 < X1) Or (Y2 < Y1) Then Exit;
  Rc[0] := X1; Rc[1] := CH - 1 - Y2; Rc[2] := X2 + 1; Rc[3] := CH - Y1;
  Dummy := WinFillRect(Hps, LongInt(@Rc), C);
End;

Procedure HLine(X1, X2, Y, C : LongInt);
Begin
  FBar(X1, Y, X2, Y, C);
End;

Procedure VLine(X, Y1, Y2, C : LongInt);
Begin
  FBar(X, Y1, X, Y2, C);
End;

Procedure DLine(X1, Y1, X2, Y2, C : LongInt);
Var P : Array[0..1] Of LongInt;
Begin
  Dummy := GpiSetColor(Hps, C);
  P[0] := X1; P[1] := CH - 1 - Y1;
  Dummy := GpiMove(Hps, LongInt(@P));
  P[0] := X2; P[1] := CH - 1 - Y2;
  Dummy := GpiLine(Hps, LongInt(@P));
End;

Procedure Box(X1, Y1, X2, Y2, C : LongInt);
Begin
  HLine(X1, X2, Y1, C); HLine(X1, X2, Y2, C);
  VLine(X1, Y1, Y2, C); VLine(X2, Y1, Y2, C);
End;

Procedure Edge(X1, Y1, X2, Y2, Lt, Dk : LongInt);
Begin
  HLine(X1, X2, Y1, Lt); VLine(X1, Y1, Y2, Lt);
  HLine(X1, X2, Y2, Dk); VLine(X2, Y1, Y2, Dk);
End;

{ relief d'OS/2 Warp (blanc en haut a gauche, gris fonce en bas a droite) }
Procedure Raised(X1, Y1, X2, Y2 : LongInt);
Begin
  FBar(X1, Y1, X2, Y2, cSilver);
  Edge(X1, Y1, X2, Y2, cWhite, cGray);
End;

Procedure Sunken(X1, Y1, X2, Y2, F : LongInt);
Begin
  FBar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1, F);
  Edge(X1, Y1, X2, Y2, cGray, cWhite);
End;

Procedure OutTxt(X, Y : LongInt; S : String; Fg, Bg : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  If S = '' Then Exit;
  PutZ(S);
  Rc[0] := X; Rc[1] := CH - Y - 16; Rc[2] := X + Length(S) * 8; Rc[3] := CH - Y;
  Dummy := WinDrawText(Hps, Length(S), LongInt(@TxtBuf), LongInt(@Rc), Fg, Bg, 0);
End;

{ titre (la police 8 x 16 de PM n'a pas de gras : meme dessin) }
Procedure OutBold(X, Y : LongInt; S : String; Fg, Bg : LongInt);
Begin
  OutTxt(X, Y, S, Fg, Bg);
End;

Function Fit(S : String; W : LongInt) : String;
Var N : LongInt;
Begin
  N := W Div 8;
  If N < 0 Then N := 0;
  If Length(S) > N Then
  Begin
    If N > 3 Then S := Copy(S, 1, N - 3) + '...' Else S := Copy(S, 1, N);
  End;
  Fit := S;
End;

Function PadR(S : String; N : LongInt) : String;
Begin
  If Length(S) >= N Then PadR := Copy(S, 1, N - 1) + ' '
  Else
  Begin
    While Length(S) < N Do S := S + ' ';
    PadR := S;
  End;
End;

{ --- icones (grille de 16 x 16, echelle Sc) --- }
Var
  IcX, IcY, IcS : LongInt;

Procedure IR(X1, Y1, X2, Y2, C : LongInt);
Begin
  FBar(IcX + X1 * IcS, IcY + Y1 * IcS, IcX + (X2 + 1) * IcS - 1, IcY + (Y2 + 1) * IcS - 1, C);
End;

Procedure IB(X1, Y1, X2, Y2, C : LongInt);
Begin
  IR(X1, Y1, X2, Y1, C); IR(X1, Y2, X2, Y2, C); IR(X1, Y1, X1, Y2, C); IR(X2, Y1, X2, Y2, C);
End;

Procedure IcoFolder(Open : Boolean);
Begin
  IR(1, 3, 6, 4, cBrown); IR(1, 4, 14, 13, cBrown);
  IR(2, 5, 13, 12, cYellow);
  If Open Then IR(3, 7, 15, 13, cYellow);
  IB(1, 4, 14, 13, cBlack);
End;

Procedure IcoGlobe;
Begin
  IR(4, 1, 11, 14, cBlue); IR(2, 3, 13, 12, cBlue); IR(1, 5, 14, 10, cBlue);
  IR(5, 3, 8, 6, cDGreen); IR(4, 4, 6, 8, cDGreen); IR(9, 8, 12, 11, cDGreen); IR(10, 7, 11, 12, cDGreen);
  IR(7, 1, 7, 14, cCyan); IR(1, 7, 14, 7, cCyan);
End;

Procedure IcoServer;
Begin
  IR(3, 0, 12, 15, cSilver); IB(3, 0, 12, 15, cBlack);
  IR(5, 2, 10, 3, cGray); IR(5, 5, 10, 6, cGray); IR(5, 8, 10, 9, cGray);
  IR(10, 12, 11, 13, cGreen); IR(5, 12, 7, 12, cBlack);
End;

Procedure IcoPage(Fg : LongInt);
Begin
  IR(3, 1, 12, 15, cWhite); IB(3, 1, 12, 15, cBlack);
  IR(5, 4, 10, 4, Fg); IR(5, 7, 10, 7, Fg); IR(5, 10, 10, 10, Fg); IR(5, 13, 8, 13, Fg);
End;

Procedure IcoGear(C : LongInt);
Begin
  IR(6, 1, 9, 14, C); IR(1, 6, 14, 9, C); IR(3, 3, 12, 12, C);
  IR(6, 6, 9, 9, cSilver); IB(6, 6, 9, 9, cBlack);
End;

Procedure IcoChart;
Begin
  IR(1, 1, 14, 14, cWhite); IB(1, 1, 14, 14, cBlack);
  IR(3, 9, 4, 13, cBlue); IR(6, 5, 7, 13, cRed); IR(9, 7, 10, 13, cDGreen); IR(12, 3, 13, 13, cNavy);
End;

Procedure IcoBook;
Begin
  IR(2, 1, 13, 14, cNavy); IR(4, 2, 13, 13, cWhite); IB(2, 1, 13, 14, cBlack);
  IR(6, 4, 11, 4, cGray); IR(6, 6, 11, 6, cGray); IR(6, 8, 11, 8, cGray); IR(6, 10, 9, 10, cGray);
End;

Procedure IcoLink;
Begin
  IB(1, 5, 7, 10, cNavy); IB(2, 6, 6, 9, cNavy);
  IB(8, 5, 14, 10, cNavy); IB(9, 6, 13, 9, cNavy);
  IR(5, 7, 10, 8, cGray);
End;

Procedure IcoKey;
Begin
  IR(1, 4, 6, 9, cBrown); IR(3, 6, 4, 7, cSilver); IB(1, 4, 6, 9, cBlack);
  IR(6, 6, 14, 7, cBrown); IR(11, 8, 12, 10, cBrown); IR(13, 8, 14, 9, cBrown);
End;

Procedure IcoLock;
Begin
  IB(5, 1, 10, 7, cGray); IB(6, 2, 9, 7, cGray);
  IR(3, 7, 12, 14, cYellow); IB(3, 7, 12, 14, cBlack); IR(7, 9, 8, 12, cBlack);
End;

Procedure IcoCert;
Begin
  IR(1, 2, 14, 11, cWhite); IB(1, 2, 14, 11, cBlack);
  IR(3, 4, 9, 4, cGray); IR(3, 6, 8, 6, cGray);
  IR(10, 6, 13, 10, cRed); IR(10, 11, 10, 14, cRed); IR(13, 11, 13, 14, cRed);
End;

Procedure IcoErr;
Var K : LongInt;
Begin
  IcoPage(cGray);
  For K := 0 To 6 Do
  Begin
    IR(5 + K, 6 + K, 6 + K, 6 + K, cRed); IR(11 - K, 6 + K, 12 - K, 6 + K, cRed);
  End;
End;

Procedure IcoVDir;
Begin
  IcoFolder(False);
  IR(6, 7, 10, 8, cNavy); IR(9, 6, 9, 9, cNavy); IR(10, 7, 11, 8, cNavy); IR(6, 9, 7, 11, cNavy);
End;

Procedure IcoDocs;
Begin
  IcoPage(cBlue);
  IR(10, 0, 15, 5, cYellow); IB(10, 0, 15, 5, cBrown);
End;

Procedure IcoBrowse;
Begin
  IcoFolder(False);
  IB(7, 6, 11, 10, cBlack); IR(8, 7, 10, 9, cWhite); IR(11, 11, 13, 13, cBlack);
End;

Procedure IcoHand;
Begin
  IcoPage(cDGreen);
  IR(8, 8, 15, 15, cNavy); IR(10, 10, 13, 13, cWhite); IR(11, 11, 12, 12, cNavy);
End;

Procedure IcoMime;
Begin
  IR(1, 3, 9, 14, cWhite); IB(1, 3, 9, 14, cBlack);
  IR(6, 1, 14, 12, cWhite); IB(6, 1, 14, 12, cBlack);
  IR(8, 4, 12, 4, cRed); IR(8, 7, 12, 7, cBlue); IR(8, 10, 11, 10, cDGreen);
End;

Procedure Icon(K, X, Y, Sc : LongInt; Off : Boolean);
Begin
  IcX := X; IcY := Y; IcS := Sc;
  Case K Of
    nkServer : IcoServer;
    nkSites : IcoFolder(True);
    nkSite : If Off Then
             Begin
               IcoGlobe; IR(9, 9, 15, 15, cRed); IR(10, 11, 14, 13, cWhite);
             End
             Else IcoGlobe;
    nkMime : IcoMime;
    nkSettings : IcoGear(cGray);
    nkMonitor : IcoChart;
    nkLogs, nkLog : IcoBook;
    nkBind : IcoLink;
    nkBasic : IcoGear(cTeal);
    nkDocs : IcoDocs;
    nkBrowse : IcoBrowse;
    nkErr : IcoErr;
    nkHdr : IcoPage(cNavy);
    nkVDir : IcoVDir;
    nkAuth : IcoKey;
    nkHand : IcoHand;
    nkCert : IcoCert;
  End;
End;

{ ==================================================================== }
{ Etat du serveur, configuration, CONFIG.SYS                            }
{ ==================================================================== }

Function Alive : Boolean;
Begin
  If Shm = @StatLocal Then Dummy := Ord(StatOpen(False));
  Alive := ServiceAlive;
End;

Function KindName(K : LongInt) : String;
Begin
  Case K Of
    nkServer : KindName := 'Serveur local';
    nkSites : KindName := 'Sites';
    nkMime : KindName := 'Types MIME';
    nkSettings : KindName := 'Param'#138'tres du serveur';
    nkMonitor : KindName := 'Surveillance';
    nkLogs : KindName := 'Journal du serveur';
    nkBind : KindName := 'Liaisons';
    nkBasic : KindName := 'Param'#138'tres de base';
    nkDocs : KindName := 'Document par d'#130'faut';
    nkBrowse : KindName := 'Exploration de r'#130'pertoire';
    nkErr : KindName := 'Pages d''erreurs';
    nkHdr : KindName := 'En-t'#136'tes de r'#130'ponse HTTP';
    nkVDir : KindName := 'R'#130'pertoires virtuels';
    nkAuth : KindName := 'Authentification';
    nkHand : KindName := 'Mappages de gestionnaires';
    nkCert : KindName := 'Certificat SSL';
    nkLog : KindName := 'Journalisation';
  Else
    KindName := '';
  End;
End;

Function KindHelp(K : LongInt) : String;
Begin
  Case K Of
    nkSites : KindHelp := 'Sites Web servis par cet ordinateur ; double-cliquez sur un site pour le g'#130'rer.';
    nkMime : KindHelp := 'Extensions de fichiers et type de contenu (Content-Type) envoy'#130' au navigateur.';
    nkSettings : KindHelp := 'R'#130'glages communs '#133' tous les sites (connexions, d'#130'lais, nom du serveur).';
    nkMonitor : KindHelp := 'Activit'#130' du serveur en direct : requ'#136'tes par seconde et connexions.';
    nkLogs : KindHelp := 'Messages du serveur (WEBSRV.LOG) : d'#130'marrages, arr'#136'ts, erreurs.';
    nkBind : KindHelp := 'Protocole, adresse IP, port et nom d''h'#147'te auxquels le site r'#130'pond.';
    nkBasic : KindHelp := 'Nom du site, dossier de ses pages (chemin physique) et '#130'tat.';
    nkDocs : KindHelp := 'Fichiers envoy'#130's quand l''adresse demand'#130'e est un dossier (dans l''ordre).';
    nkBrowse : KindHelp := 'Liste du contenu d''un dossier sans document par d'#130'faut.';
    nkErr : KindHelp := 'Pages personnalis'#130'es renvoy'#130'es pour les codes d''erreur HTTP.';
    nkHdr : KindHelp := 'En-t'#136'tes ajout'#130's '#133' toutes les r'#130'ponses du site.';
    nkVDir : KindHelp := 'Alias d''adresse menant '#133' un autre dossier du disque.';
    nkAuth : KindHelp := 'Acc'#138's anonyme ou authentification de base (utilisateur et mot de passe).';
    nkHand : KindHelp := 'Pages ex'#130'cut'#130'es par le serveur : PSP (Pascal Server Pages) et ASP (VBScript).';
    nkCert : KindHelp := 'Certificat des liaisons https (TLS 1.3, ECDSA P-256).';
    nkLog : KindHelp := 'Journal W3C des requ'#136'tes du site (un fichier par jour).';
  Else
    KindHelp := '';
  End;
End;

Function SiteBinds(I : LongInt) : String;
Var J : LongInt; S, T : String;
Begin
  S := '';
  For J := 0 To Sites[I].NB - 1 Do
  Begin
    If Sites[I].B[J].Tls Then T := 'https' Else T := 'http';
    If Sites[I].B[J].Ip = 0 Then T := T + ' *' Else T := T + ' ' + IpStr(Sites[I].B[J].Ip);
    T := T + ':' + IStr(Sites[I].B[J].Port);
    If Sites[I].B[J].Host <> '' Then T := T + ':' + Sites[I].B[J].Host;
    If S <> '' Then S := S + ', ';
    S := S + T;
  End;
  SiteBinds := S;
End;

Function SiteState(I : LongInt) : String;
Begin
  If Not Sites[I].Started Then SiteState := 'Arr'#136't'#130
  Else If Not LastAlive Then SiteState := 'D'#130'marr'#130' *'
  Else If Shm^.SiteState[I] = 2 Then SiteState := 'Erreur'
  Else SiteState := 'D'#130'marr'#130;
End;

{ enregistrer et faire relire la configuration au serveur }
Procedure SaveCfg;
Begin
  If Not CfgSave Then
  Begin
    MsgErr('Impossible d''enregistrer ' + CfgPath + '.');
    Exit;
  End;
  Dirty := False;
  If Alive Then
  Begin
    Shm^.Cmd := cmdReload;
    Inc(Shm^.CmdSeq);
    StatusMsg := 'Configuration enregistr'#130'e et relue par le serveur.';
  End
  Else StatusMsg := 'Configuration enregistr'#130'e (' + CfgPath + ').';
End;

{ CONFIG.SYS : chemin (lecteur d'amorcage) }
Function CfgSysPath : String;
Var S : String;
Begin
  S := PEnv('OS2_BOOTDRIVE');
  If S = '' Then S := 'C:';
  CfgSysPath := Copy(S, 1, 2) + '\CONFIG.SYS';
End;

Function MyExe : String;
Var S : String;
Begin
  S := ParamStr(0);
  If S = '' Then S := 'C:\WEBSRV.EXE';
  MyExe := UpStr(S);
End;

{ la ligne RUN=...WEBSRV.EXE /SERVICE est-elle dans CONFIG.SYS ? }
Function AutoStartOn : Boolean;
Var B : TBuf; K : LongInt; L : String; On_ : Boolean;
Begin
  On_ := False;
  If ReadFileBuf(CfgSysPath, B, 262144) Then
  Begin
    L := '';
    For K := 0 To B.Len Do
    Begin
      If (K = B.Len) Or (B.P^[K] = 10) Or (B.P^[K] = 13) Then
      Begin
        L := UpStr(Trim(L));
        If (Copy(L, 1, 4) = 'RUN=') And (Pos('WEBSRV', L) > 0) Then On_ := True;
        L := '';
      End
      Else If Length(L) < 250 Then L := L + Chr(B.P^[K]);
    End;
  End;
  BufFree(B);
  AutoStartOn := On_;
End;

{ ajouter ou retirer la ligne RUN= ; rend False en cas d'echec }
Function SetAutoStart(On_ : Boolean) : Boolean;
Var B, O : TBuf; K : LongInt; L, U : String; Done : Boolean;
Begin
  SetAutoStart := False;
  If Not ReadFileBuf(CfgSysPath, B, 262144) Then Exit;
  BufInit(O);
  L := ''; Done := False;
  For K := 0 To B.Len Do
  Begin
    If (K = B.Len) Or (B.P^[K] = 10) Then
    Begin
      If (Length(L) > 0) And (L[Length(L)] = #13) Then Delete(L, Length(L), 1);
      U := UpStr(Trim(L));
      If (Copy(U, 1, 4) = 'RUN=') And (Pos('WEBSRV', U) > 0) Then
      Begin
        If On_ And Not Done Then
        Begin
          BufAdd(O, 'RUN=' + MyExe + ' /SERVICE' + Crlf);
          Done := True;
        End;
      End
      Else If (K < B.Len) Or (L <> '') Then BufAdd(O, L + Crlf);
      L := '';
    End
    Else If Length(L) < 250 Then L := L + Chr(B.P^[K]);
  End;
  If On_ And Not Done Then BufAdd(O, 'RUN=' + MyExe + ' /SERVICE' + Crlf);
  SetAutoStart := WriteFileBuf(CfgSysPath, O.P, O.Len);
  BufFree(B); BufFree(O);
End;

{ lancer un programme (navigateur, explorateur) }
Procedure Launch(Exe, Arg : String);
Var Args : Array[0..299] Of Byte; Res : Array[0..1] Of LongInt; Fail : Array[0..259] Of Byte; P, K : LongInt;
Begin
  P := 0;
  For K := 1 To Length(Exe) Do
  Begin
    Args[P] := Ord(Exe[K]); Inc(P);
  End;
  Args[P] := 0; Inc(P);
  For K := 1 To Length(Arg) Do
  Begin
    Args[P] := Ord(Arg[K]); Inc(P);
  End;
  Args[P] := 0; Args[P + 1] := 0;
  If DosExecPgm(LongInt(@Fail), 260, 4, LongInt(@Args), 0, LongInt(@Res), Z(Exe)) <> 0 Then
    MsgErr('Impossible de lancer ' + Exe + '.');
End;

Function FindExe(Nm : String) : String;
Var S : String;
Begin
  FindExe := '';
  If PExists('C:\' + Nm) Then FindExe := 'C:\' + Nm
  Else
  Begin
    S := MyExe;
    While (Length(S) > 0) And (S[Length(S)] <> '\') Do Delete(S, Length(S), 1);
    If (S <> '') And PExists(S + Nm) Then FindExe := S + Nm;
  End;
End;

{ ==================================================================== }
{ Arbre                                                                 }
{ ==================================================================== }

Procedure AddNode(K, S, Lv : LongInt; Kids : Boolean);
Begin
  If NNode >= MaxNode Then Exit;
  NKind[NNode] := K; NSite[NNode] := S; NLev[NNode] := Lv; NKids[NNode] := Kids;
  Inc(NNode);
End;

Function NodeText(I : LongInt) : String;
Begin
  Case NKind[I] Of
    nkServer : NodeText := 'OS2-0 (serveur local)';
    nkSite : NodeText := Sites[NSite[I]].Name;
  Else
    NodeText := KindName(NKind[I]);
  End;
End;

Procedure BuildTree;
Var I, K : LongInt;
Begin
  NNode := 0;
  AddNode(nkServer, -1, 0, True);
  If ExpServer Then
  Begin
    AddNode(nkSites, -1, 1, True);
    If ExpSites Then
      For I := 0 To MaxSites - 1 Do
        If Sites[I].Used Then
        Begin
          AddNode(nkSite, I, 2, True);
          If ExpSite[I] Then
            For K := nkFirstCat To nkLastCat Do AddNode(K, I, 3, False);
        End;
    AddNode(nkMime, -1, 1, False);
    AddNode(nkSettings, -1, 1, False);
    AddNode(nkMonitor, -1, 1, False);
    AddNode(nkLogs, -1, 1, False);
  End;
  NSel := 0;
  For I := 0 To NNode - 1 Do
    If (NKind[I] = SelKind) And ((NSite[I] = SelSite) Or (SelSite < 0)) Then NSel := I;
End;

Function NodeOpen(I : LongInt) : Boolean;
Begin
  Case NKind[I] Of
    nkServer : NodeOpen := ExpServer;
    nkSites : NodeOpen := ExpSites;
    nkSite : NodeOpen := ExpSite[NSite[I]];
  Else
    NodeOpen := False;
  End;
End;

Procedure SetOpen(I : LongInt; V : Boolean);
Begin
  Case NKind[I] Of
    nkServer : ExpServer := V;
    nkSites : ExpSites := V;
    nkSite : ExpSite[NSite[I]] := V;
  End;
End;

Function TreeRows : LongInt;
Begin
  TreeRows := MaxI(1, (CH - TbH - SbH - 8) Div RowH);
End;

Procedure PaintTree;
Var I, Y, X, Rows, Y0, D : LongInt; S : String;
Begin
  Y0 := TbH;
  Sunken(0, Y0, TreeW - 1, CH - SbH - 1, cWhite);
  Rows := TreeRows;
  If NSel < NTop Then NTop := NSel;
  If NSel >= NTop + Rows Then NTop := NSel - Rows + 1;
  If NTop > MaxI(0, NNode - Rows) Then NTop := MaxI(0, NNode - Rows);
  If NTop < 0 Then NTop := 0;
  For I := NTop To MinI(NNode - 1, NTop + Rows - 1) Do
  Begin
    Y := Y0 + 4 + (I - NTop) * RowH;
    X := 6 + NLev[I] * 16;
    { traits pointilles d'OS/2 }
    If NLev[I] > 0 Then
    Begin
      D := 0;
      While D < 8 Do
      Begin
        FBar(X - 10 + D, Y + 8, X - 10 + D, Y + 8, cGray);
        Inc(D, 2);
      End;
    End;
    If NKids[I] Then
    Begin
      FBar(X - 14, Y + 4, X - 6, Y + 12, cWhite);
      Box(X - 14, Y + 4, X - 6, Y + 12, cGray);
      HLine(X - 12, X - 8, Y + 8, cBlack);
      If Not NodeOpen(I) Then VLine(X - 10, Y + 6, Y + 10, cBlack);
    End;
    If NKind[I] = nkSite Then Icon(nkSite, X, Y + 1, 1, Not Sites[NSite[I]].Started)
    Else Icon(NKind[I], X, Y + 1, 1, False);
    S := Fit(NodeText(I), TreeW - X - 24);
    If I = NSel Then
    Begin
      FBar(X + 19, Y, X + 21 + Length(S) * 8, Y + 17, cNavy);
      OutTxt(X + 20, Y + 1, S, cWhite, cNavy);
    End
    Else OutTxt(X + 20, Y + 1, S, cBlack, cWhite);
  End;
  { fleches de defilement }
  If NTop > 0 Then
  Begin
    For I := 0 To 3 Do HLine(TreeW - 12 + I - 3, TreeW - 12 + 3 - I, Y0 + 6 + I, cGray);
  End;
  If NTop + Rows < NNode Then
  Begin
    Y := CH - SbH - 10;
    For I := 0 To 3 Do HLine(TreeW - 12 + I - 3, TreeW - 12 + 3 - I, Y - I, cGray);
  End;
End;

{ ==================================================================== }
{ Panneau de droite : controles, etiquettes, actions                    }
{ ==================================================================== }

Function PanX0 : LongInt;
Begin
  PanX0 := TreeW + 4;
End;

Function PanX1 : LongInt;
Begin
  PanX1 := CW - ActW - 1;
End;

Function PanY0 : LongInt;
Begin
  PanY0 := TbH + HdrH;
End;

Function PanY1 : LongInt;
Begin
  PanY1 := CH - SbH - 1;
End;

{ position reelle d'un controle (indicateurs : 1 largeur jusqu'au bord,
  2 hauteur jusqu'en bas, 4 colle en bas) }
Procedure PlaceCtl(I : LongInt);
Var X, Y, W, H : LongInt;
Begin
  X := PanX0 + CtlX[I]; Y := PanY0 + CtlY[I]; W := CtlW[I]; H := CtlHt[I];
  If (CtlFl[I] And 4) <> 0 Then Y := PanY1 - CtlY[I];
  If (CtlFl[I] And 1) <> 0 Then W := PanX1 - 10 - X;
  If (CtlFl[I] And 2) <> 0 Then H := PanY1 - 40 - Y;
  If X + W > PanX1 - 10 Then W := PanX1 - 10 - X;
  If W < 20 Then W := 20;
  If H < 18 Then H := 18;
  Dummy := WinSetWindowPos(CtlH[I], 0, X, CH - Y - H, W, H, SWP_MOVE Or SWP_SIZE);
  CtlRx[I] := X; CtlRy[I] := Y; CtlRw[I] := W; CtlRh[I] := H;
End;

Function AddCtl(Cls, Style : LongInt; Txt : String; X, Y, W, H, Fl, Id : LongInt) : LongInt;
Var Hw, P : LongInt;
Begin
  AddCtl := 0;
  If NCtl >= MaxCtl Then Exit;
  If Cls = WC_ENTRYFIELD Then P := Z(Txt) Else P := Z(Txt);
  Hw := WinCreateWindow(Client, Cls, P, WS_VISIBLE Or WS_TABSTOP Or Style, 0, 0, W, H, Client, HWND_TOP, Id, 0, 0);
  If Hw = 0 Then Exit;
  CtlH[NCtl] := Hw; CtlX[NCtl] := X; CtlY[NCtl] := Y; CtlW[NCtl] := W; CtlHt[NCtl] := H; CtlFl[NCtl] := Fl;
  CtlId[NCtl] := Id;
  PlaceCtl(NCtl);
  Inc(NCtl);
  If Cls = WC_ENTRYFIELD Then Dummy := WinSendMsg(Hw, EM_SETTEXTLIMIT, 250, 0);
  AddCtl := Hw;
End;

Function CtlById(Id : LongInt) : LongInt;
Var I : LongInt;
Begin
  CtlById := 0;
  For I := 0 To NCtl - 1 Do If CtlId[I] = Id Then CtlById := CtlH[I];
End;

Procedure AddLbl(X, Y : LongInt; S : String; C : LongInt);
Begin
  If NLbl >= MaxLbl Then Exit;
  LblX[NLbl] := X; LblY[NLbl] := Y; LblS[NLbl] := S; LblC[NLbl] := C;
  Inc(NLbl);
End;

Procedure AddAct(Cmd : LongInt; S : String);
Begin
  { deux titres de suite : le second remplace le premier }
  If (Cmd = 0) And (NAct > 0) And (ActCmd[NAct - 1] = 0) Then Dec(NAct);
  If NAct >= MaxAct Then Exit;
  ActCmd[NAct] := Cmd; ActS[NAct] := S;
  Inc(NAct);
End;

{ champ etiquete : etiquette a gauche, champ a droite }
Var FieldN : LongInt;

Function Field(Lbl, Val : String; Y, W : LongInt; Pass : Boolean) : LongInt;
Var St : LongInt;
Begin
  AddLbl(12, Y + 2, Lbl, cBlack);
  St := ES_AUTOSCROLL Or ES_MARGIN;
  If Pass Then St := St Or ES_UNREADABLE;
  Field := AddCtl(WC_ENTRYFIELD, St, Val, 200, Y, W, 20, 0, idCtl + 10 + FieldN);
  Inc(FieldN);
End;

{ fond gris de la boite (PP_BACKGROUNDCOLORINDEX) }
Procedure GrayBg(H : LongInt);
Var C : LongInt;
Begin
  C := cSilver;
  Dummy := WinSetPresParam(H, 4, 4, LongInt(@C));
End;

Function Check(Lbl : String; On_ : Boolean; X, Y, Id : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := AddCtl(WC_BUTTON, BS_AUTOCHECKBOX, Lbl, X, Y, Length(Lbl) * 8 + 28, 20, 0, Id);
  GrayBg(H);
  If On_ Then Dummy := WinSendMsg(H, BM_SETCHECK, 1, 0);
  Check := H;
End;

Function Checked(Id : LongInt) : Boolean;
Begin
  Checked := WinSendMsg(CtlById(Id), BM_QUERYCHECK, 0, 0) = 1;
End;

Function FieldVal(N : LongInt) : String;
Begin
  FieldVal := Trim(WinText(CtlById(idCtl + 10 + N)));
End;

Procedure Btn(S : String; X, Cmd : LongInt);
Begin
  Dummy := AddCtl(WC_BUTTON, BS_PUSHBUTTON, S, X, 32, Length(S) * 8 + 24, 26, 4, Cmd);
End;

{ liste du panneau (police a chasse fixe : colonnes alignees) }
Procedure MakeList(Hdr : String; Y : LongInt);
Begin
  ListHdr := Hdr; ListY := Y;
  ListH := AddCtl(WC_LISTBOX, 0, '', 8, Y + 20, 100, 100, 3, idList);
End;

Procedure LAdd(S : String);
Begin
  Dummy := WinSendMsg(ListH, LM_INSERTITEM, -1, Z(S));
End;

Function LSel : LongInt;
Begin
  If ListH = 0 Then LSel := -1 Else LSel := WinSendMsg(ListH, LM_QUERYSELECTION, -1, 0);
End;

Procedure ClearPanel;
Var I : LongInt;
Begin
  For I := 0 To NCtl - 1 Do Dummy := WinDestroyWindow(CtlH[I]);
  NCtl := 0; NLbl := 0; NAct := 0; NTile := 0; ListH := 0; ListHdr := ''; FieldN := 0;
End;

Procedure Redraw;
Begin
  Dummy := WinInvalidateRect(Client, 0, 0);
End;

{ --- remplissage des listes --- }

Procedure FillList;
Var I, J : LongInt; S : String;
Begin
  If ListH = 0 Then Exit;
  Dummy := WinSendMsg(ListH, LM_DELETEALL, 0, 0);
  I := SelSite;
  Case SelKind Of
    nkSites :
      For J := 0 To MaxSites - 1 Do
        If Sites[J].Used Then
          LAdd(PadR(Sites[J].Name, 26) + PadR(IStr(Sites[J].Id), 4) + PadR(SiteState(J), 10) +
               PadR(SiteBinds(J), 34) + Sites[J].Root);
    nkBind :
      For J := 0 To Sites[I].NB - 1 Do
      Begin
        If Sites[I].B[J].Tls Then S := 'https' Else S := 'http';
        S := PadR(S, 7);
        If Sites[I].B[J].Host = '' Then S := S + PadR('(tous)', 26) Else S := S + PadR(Sites[I].B[J].Host, 26);
        S := S + PadR(IStr(Sites[I].B[J].Port), 7);
        If Sites[I].B[J].Ip = 0 Then S := S + '* (toutes)' Else S := S + IpStr(Sites[I].B[J].Ip);
        LAdd(S);
      End;
    nkDocs : For J := 0 To Sites[I].ND - 1 Do LAdd(Sites[I].Docs[J]);
    nkErr : For J := 0 To Sites[I].NE - 1 Do LAdd(PadR(IStr(Sites[I].ErrCode[J]), 8) + Sites[I].ErrPath[J]);
    nkHdr : For J := 0 To Sites[I].NH - 1 Do LAdd(Sites[I].Hdr[J]);
    nkVDir : For J := 0 To Sites[I].NV - 1 Do LAdd(PadR(Sites[I].VUrl[J], 24) + Sites[I].VPath[J]);
    nkMime : For J := 0 To NMime - 1 Do LAdd(PadR(MimeExt[J], 12) + MimeTyp[J]);
  End;
End;

{ dernieres lignes d'un fichier texte dans la liste }
Procedure ListTail(Name : String; Max : LongInt);
Var B : TBuf; K, St, N : LongInt; L : String;
Begin
  If ListH = 0 Then Exit;
  Dummy := WinSendMsg(ListH, LM_DELETEALL, 0, 0);
  If Not ReadFileBuf(Name, B, 4194304) Then
  Begin
    LAdd('(fichier absent : ' + Name + ')');
    Exit;
  End;
  { debut des Max dernieres lignes }
  St := B.Len; N := 0;
  While (St > 0) And (N <= Max) Do
  Begin
    Dec(St);
    If B.P^[St] = 10 Then Inc(N);
  End;
  If St > 0 Then Inc(St);
  L := '';
  For K := St To B.Len - 1 Do
    If B.P^[K] = 10 Then
    Begin
      LAdd(L); L := '';
    End
    Else If (B.P^[K] <> 13) And (Length(L) < 200) Then L := L + Chr(B.P^[K]);
  If L <> '' Then LAdd(L);
  BufFree(B);
End;

{ journal W3C le plus recent du site }
Function LastLog(I : LongInt) : String;
Var Dir, Nm, Best : String; Sz, Mt, BestT : LongInt; IsD : Boolean;
Begin
  Dir := WwwData + '\LOGS\W3SVC' + IStr(Sites[I].Id);
  Best := ''; BestT := 0;
  If PFindFirst(Dir, Nm, Sz, Mt, IsD) Then
    Repeat
      If (Not IsD) And (UpStr(Copy(Nm, Length(Nm) - 3, 4)) = '.LOG') And ((Best = '') Or (Mt >= BestT)) Then
      Begin
        Best := Dir + '\' + Nm; BestT := Mt;
      End;
    Until Not PFindNext(Nm, Sz, Mt, IsD);
  LastLog := Best;
End;

{ --- construction du panneau selon la selection de l'arbre --- }

Procedure ServerActions;
Begin
  If LastAlive Then
  Begin
    AddAct(cmStop, 'Arr'#136'ter');
    AddAct(cmRestart, 'Red'#130'marrer');
  End
  Else AddAct(cmStart, 'D'#130'marrer');
End;

Procedure SiteActions;
Begin
  AddAct(0, 'G'#130'rer le site');
  If Sites[SelSite].Started Then AddAct(cmSiteOff, 'Arr'#136'ter le site') Else AddAct(cmSiteOn, 'D'#130'marrer le site');
  AddAct(cmBrowse, 'Parcourir le site');
  AddAct(0, 'Modifier le site');
  AddAct(cmSiteProps, 'Param'#138'tres de base...');
  AddAct(cmGoBind, 'Liaisons...');
  AddAct(cmOpenRoot, 'Explorer le dossier');
  AddAct(cmDelSite, 'Supprimer le site');
End;

Procedure BuildPanel;
Var I, Y : LongInt; LogF : String;
Begin
  ClearPanel;
  LastAlive := Alive;
  I := SelSite;
  AddAct(0, 'Actions');
  Case SelKind Of
    nkServer :
      Begin
        Dummy := Check('D'#130'marrer le serveur Web avec OS/2 (CONFIG.SYS)', AutoStartOn, 12, 84, idCtl + 1);
        Dummy := AddCtl(WC_BUTTON, BS_PUSHBUTTON, 'D'#130'marrer', 12, 112, 100, 26, 0, cmStart);
        Dummy := AddCtl(WC_BUTTON, BS_PUSHBUTTON, 'Arr'#136'ter', 118, 112, 100, 26, 0, cmStop);
        Dummy := AddCtl(WC_BUTTON, BS_PUSHBUTTON, 'Red'#130'marrer', 224, 112, 110, 26, 0, cmRestart);
        ServerActions;
        AddAct(0, 'Configuration');
        AddAct(cmAddSite, 'Ajouter un site Web...');
        AddAct(cmCert, 'Certificat auto-sign'#130'...');
        AddAct(cmReloadCfg, 'Relire WEBSRV.CFG');
        NTile := 5;
        TileK[0] := nkSites; TileK[1] := nkMime; TileK[2] := nkSettings; TileK[3] := nkMonitor; TileK[4] := nkLogs;
      End;
    nkSites :
      Begin
        MakeList(PadR('Nom', 26) + PadR('ID', 4) + PadR(#144'tat', 10) + PadR('Liaisons', 34) + 'Chemin', 8);
        FillList;
        Btn('Ajouter un site...', 8, cmAddSite);
        Btn('Ouvrir', 172, cmEdit);
        Btn('Supprimer', 246, cmDelSite);
        AddAct(cmAddSite, 'Ajouter un site Web...');
        AddAct(cmEdit, 'G'#130'rer le site choisi');
        AddAct(cmDelSite, 'Supprimer le site choisi');
      End;
    nkSite :
      Begin
        NTile := nkLastCat - nkFirstCat + 1;
        For Y := 0 To NTile - 1 Do TileK[Y] := nkFirstCat + Y;
        SiteActions;
      End;
    nkBind, nkErr, nkHdr, nkVDir, nkMime, nkDocs :
      Begin
        Case SelKind Of
          nkBind : MakeList(PadR('Type', 7) + PadR('Nom d''h'#147'te', 26) + PadR('Port', 7) + 'Adresse IP', 8);
          nkErr : MakeList(PadR('Code', 8) + 'Chemin de la page', 8);
          nkHdr : MakeList('Nom: valeur', 8);
          nkVDir : MakeList(PadR('Alias', 24) + 'Chemin physique', 8);
          nkMime : MakeList(PadR('Extension', 12) + 'Type MIME', 8);
          nkDocs : MakeList('Nom du document (dans l''ordre de recherche)', 8);
        End;
        FillList;
        Btn('Ajouter...', 8, cmAdd);
        If SelKind <> nkDocs Then Btn('Modifier...', 112, cmEdit)
        Else
        Begin
          Btn('Monter', 112, cmUp);
          Btn('Descendre', 192, cmDown);
        End;
        Btn('Supprimer', 296, cmDel);
        AddAct(cmAdd, 'Ajouter...');
        If SelKind <> nkDocs Then AddAct(cmEdit, 'Modifier...');
        AddAct(cmDel, 'Supprimer');
        If SelKind <> nkMime Then
        Begin
          AddAct(0, 'Site');
          AddAct(cmBrowse, 'Parcourir le site');
        End;
      End;
    nkBasic :
      Begin
        Dummy := Field('Nom du site :', Sites[I].Name, 12, 260, False);
        Dummy := Field('Chemin physique :', Sites[I].Root, 40, 260, False);
        AddLbl(12, 72, 'Identificateur : ' + IStr(Sites[I].Id) + '   (journaux : LOGS\W3SVC' + IStr(Sites[I].Id) + ')',
               cGray);
        Dummy := Check('Site d'#130'marr'#130, Sites[I].Started, 12, 96, idCtl + 1);
      End;
    nkBrowse :
      Begin
        Dummy := Check('Exploration de r'#130'pertoire activ'#130'e', Sites[I].Browse, 12, 12, idCtl + 1);
        AddLbl(12, 44, 'Sans document par d'#130'faut, le serveur envoie la liste du dossier', cBlack);
        AddLbl(12, 62, '(nom, taille, date) au lieu de l''erreur 403.', cBlack);
      End;
    nkAuth :
      Begin
        Dummy := Check('Authentification de base (Basic)', Sites[I].AuthUser <> '', 12, 12, idCtl + 1);
        Dummy := Field('Nom d''utilisateur :', Sites[I].AuthUser, 44, 200, False);
        Dummy := Field('Mot de passe :', Sites[I].AuthPass, 72, 200, True);
        AddLbl(12, 104, 'D'#130'coch'#130'e : acc'#138's anonyme (comme IUSR d''IIS).', cGray);
        AddLbl(12, 122, 'En http, le mot de passe circule en clair : pr'#130'f'#130'rez https.', cGray);
      End;
    nkHand :
      Begin
        Dummy := Check('*.psp : Pascal Server Pages (moteur PSP int'#130'gr'#130')', Sites[I].Psp, 12, 12, idCtl + 1);
        Dummy := Check('*.asp : Active Server Pages (VBScript, moteur ASP int'#130'gr'#130')', Sites[I].Asp, 12, 40,
                       idCtl + 2);
        Dummy := Check('*.php : PHP (moteur PHP int'#130'gr'#130', mysqli, pg, PDO)', Sites[I].Php, 12, 68, idCtl + 3);
        AddLbl(12, 102, 'Les pages sont compil'#130'es une fois en code interm'#130'diaire et', cBlack);
        AddLbl(12, 120, 'ex'#130'cut'#130'es dans le serveur, par tranches, sans ralentir OS/2.', cBlack);
        AddLbl(12, 138, 'Objets : Request, Response, Server, Session, Application,', cGray);
        AddLbl(12, 156, 'Scripting.Dictionary, Scripting.FileSystemObject.', cGray);
      End;
    nkCert :
      Begin
        Dummy := Field('Fichier PEM :', Sites[I].Cert, 12, 280, False);
        AddLbl(12, 40, 'Vide : ' + CertFile(I), cGray);
        If PExists(CertFile(I)) Then AddLbl(12, 62, 'Certificat pr'#130'sent ; nom (CN) : ' + CertName(I), cDGreen)
        Else AddLbl(12, 62, 'Aucun certificat : il sera cr'#130#130' au d'#130'marrage (CN ' + CertName(I) + ').', cMaroon);
        If Not SiteHasTls(I) Then AddLbl(12, 80, 'Ce site n''a pas de liaison https.', cGray);
        Dummy := AddCtl(WC_BUTTON, BS_PUSHBUTTON, 'Cr'#130'er un certificat auto-sign'#130, 12, 106, 260, 26, 0, cmMakeCert);
        AddAct(cmMakeCert, 'Cr'#130'er un certificat...');
      End;
    nkLog :
      Begin
        Dummy := Check('Journalisation activ'#130'e (format W3C)', Sites[I].LogOn, 12, 8, idCtl + 1);
        AddLbl(12, 34, 'Dossier : ' + WwwData + '\LOGS\W3SVC' + IStr(Sites[I].Id), cGray);
        LogF := LastLog(I);
        MakeList('Derni'#138'res requ'#136'tes : ' + LogF, 54);
        If LogF = '' Then LAdd('(aucune requ'#136'te journalis'#130'e pour l''instant)') Else ListTail(LogF, 200);
        AddAct(cmRefresh, 'Actualiser');
        AddAct(cmOpenLogs, 'Explorer les journaux');
      End;
    nkSettings :
      Begin
        Dummy := Field('Nom du serveur :', ServerName, 12, 220, False);
        Dummy := Field('Connexions (max.) :', IStr(MaxConnCfg), 40, 80, False);
        Dummy := Field('Persistance (s) :', IStr(KeepAliveS), 68, 80, False);
        Dummy := Field('D'#130'lai connexion (s) :', IStr(ConnTimeoutS), 96, 80, False);
        Dummy := Field('D'#130'lai des scripts (s) :', IStr(ScriptTimeoutS), 124, 80, False);
        Dummy := Field('Sessions (min) :', IStr(SessionTimeoutM), 152, 80, False);
        AddLbl(12, 184, 'Connexions servies en m'#136'me temps : au plus ' + IStr(MaxConn) + '.', cGray);
      End;
    nkMonitor :
      Begin
        AddAct(cmRefresh, 'Actualiser');
      End;
    nkLogs :
      Begin
        MakeList(WwwData + '\WEBSRV.LOG', 8);
        ListTail(WwwData + '\WEBSRV.LOG', 300);
        AddAct(cmRefresh, 'Actualiser');
        AddAct(cmClearLog, 'Effacer le journal');
      End;
  End;
  If (SelKind = nkBasic) Or (SelKind = nkBrowse) Or (SelKind = nkAuth) Or (SelKind = nkHand) Or (SelKind = nkCert) Or
     (SelKind = nkLog) Or (SelKind = nkSettings) Then
  Begin
    Btn('Appliquer', 8, cmApply);
    Btn('Annuler', 112, cmCancel);
    AddAct(cmApply, 'Appliquer');
    AddAct(cmCancel, 'Annuler');
  End;
  If (SelKind >= nkFirstCat) And (SelKind <> nkBind) And (SelKind <> nkErr) And (SelKind <> nkHdr) And
     (SelKind <> nkVDir) And (SelKind <> nkDocs) Then
  Begin
    AddAct(0, 'Site');
    AddAct(cmBrowse, 'Parcourir le site');
  End;
  If SelKind <> nkServer Then
  Begin
    AddAct(0, 'Serveur');
    ServerActions;
  End;
  AddAct(0, 'Aide');
  AddAct(cmHelp, 'Aide');
  Redraw;
End;

{ ==================================================================== }
{ Dessin du panneau                                                     }
{ ==================================================================== }

Function Uptime : String;
Var S : LongInt;
Begin
  S := NowUnix - Shm^.StartTime;
  If S < 0 Then S := 0;
  Uptime := IStr(S Div 86400) + ' j ' + Pad2((S Div 3600) Mod 24) + ':' + Pad2((S Div 60) Mod 60) + ':' + Pad2(S Mod 60);
End;

Function NSites : LongInt;
Var I, N : LongInt;
Begin
  N := 0;
  For I := 0 To MaxSites - 1 Do If Sites[I].Used Then Inc(N);
  NSites := N;
End;

{ icones des fonctionnalites (vue Fonctionnalites d'IIS) }
Procedure PaintTiles(Y0 : LongInt);
Var I, X, Y, Cols, Tw, Th : LongInt; S, S2 : String; P : LongInt;
Begin
  Tw := 128; Th := 74;
  Cols := MaxI(1, (PanX1 - PanX0 - 16) Div Tw);
  TileW := Tw; TileH := Th - 4;
  If Y0 + ((NTile + Cols - 1) Div Cols) * Th > PanY1 Then
  Begin
    { peu de place : petites icones en colonnes (vue Liste) }
    Tw := 216; Th := 20;
    Cols := MaxI(1, (PanX1 - PanX0 - 16) Div Tw);
    TileW := Tw - 8; TileH := Th;
    For I := 0 To NTile - 1 Do
    Begin
      X := PanX0 + 8 + (I Mod Cols) * Tw;
      Y := Y0 + (I Div Cols) * Th;
      TileX[I] := X; TileY[I] := Y;
      Icon(TileK[I], X, Y + 1, 1, False);
      OutTxt(X + 22, Y + 1, Fit(KindName(TileK[I]), Tw - 30), cBlack, cSilver);
    End;
    Exit;
  End;
  For I := 0 To NTile - 1 Do
  Begin
    X := PanX0 + 8 + (I Mod Cols) * Tw;
    Y := Y0 + (I Div Cols) * Th;
    TileX[I] := X; TileY[I] := Y;
    Icon(TileK[I], X + (Tw - 32) Div 2, Y + 2, 2, False);
    S := KindName(TileK[I]);
    S2 := '';
    If Length(S) * 8 > Tw Then
    Begin
      P := Tw Div 8;
      While (P > 1) And (S[P] <> ' ') Do Dec(P);
      If P > 1 Then
      Begin
        S2 := Copy(S, P + 1, 255); S := Copy(S, 1, P - 1);
      End;
    End;
    S := Fit(S, Tw); S2 := Fit(S2, Tw);
    OutTxt(X + (Tw - Length(S) * 8) Div 2, Y + 38, S, cBlack, cSilver);
    If S2 <> '' Then OutTxt(X + (Tw - Length(S2) * 8) Div 2, Y + 54, S2, cBlack, cSilver);
  End;
End;

Procedure KeyVal(X, Y : LongInt; K, V : String);
Begin
  OutTxt(X, Y, K, cGray, cSilver);
  OutTxt(X + 168, Y, V, cBlack, cSilver);
End;

{ graphique d'activite (60 secondes) }
Procedure PaintGraph(X1, Y1, X2, Y2 : LongInt);
Var I, Mx, H, X, Y, PY, Pc, W : LongInt;
Begin
  Sunken(X1, Y1, X2, Y2, cBlack);
  For I := 1 To 3 Do HLine(X1 + 1, X2 - 1, Y1 + (Y2 - Y1) * I Div 4, cDGreen);
  For I := 1 To 5 Do VLine(X1 + (X2 - X1) * I Div 6, Y1 + 1, Y2 - 1, cDGreen);
  Mx := 10;
  For I := 0 To 59 Do
  Begin
    If ReqHist[I] > Mx Then Mx := ReqHist[I];
    If ConnHist[I] > Mx Then Mx := ConnHist[I];
  End;
  H := Y2 - Y1 - 4; W := X2 - X1 - 4;
  PY := -1; Pc := -1;
  For I := 0 To 59 Do
  Begin
    X := X1 + 2 + W * I Div 59;
    Y := Y2 - 2 - H * ReqHist[(HistN + I) Mod 60] Div Mx;
    If PY >= 0 Then DLine(X - W Div 59, PY, X, Y, cGreen);
    PY := Y;
    Y := Y2 - 2 - H * ConnHist[(HistN + I) Mod 60] Div Mx;
    If Pc >= 0 Then DLine(X - W Div 59, Pc, X, Y, cCyan);
    Pc := Y;
  End;
  OutTxt(X1 + 6, Y1 + 4, 'max. ' + IStr(Mx), cGreen, cBlack);
End;

Procedure PaintMonitor;
Var X, Y : LongInt;
Begin
  X := PanX0 + 12; Y := PanY0 + 8;
  If Not LastAlive Then
  Begin
    OutTxt(X, Y, 'Le serveur Web est arr'#136't'#130'.', cMaroon, cSilver);
    Y := Y + 24;
  End
  Else
  Begin
    KeyVal(X, Y, 'Requ'#136'tes servies :', IStr(Shm^.Requests)); Inc(Y, 18);
    KeyVal(X, Y, 'Connexions :', IStr(Shm^.CurConn) + '  (max. ' + IStr(Shm^.MaxConn) + ')'); Inc(Y, 18);
    KeyVal(X, Y, 'Octets envoy'#130's :', SizeStr(Shm^.BytesOut)); Inc(Y, 18);
    KeyVal(X, Y, 'Octets re'#135'us :', SizeStr(Shm^.BytesIn)); Inc(Y, 18);
    KeyVal(X, Y, 'Pages PSP/ASP :', IStr(Shm^.PspRuns) + '  (erreurs : ' + IStr(Shm^.PspErr) + ')'); Inc(Y, 18);
    KeyVal(X, Y, 'Erreurs :', IStr(Shm^.Errors)); Inc(Y, 22);
  End;
  OutTxt(X, Y, 'Requ'#136'tes par seconde', cDGreen, cSilver);
  OutTxt(X + 200, Y, 'Connexions', cTeal, cSilver);
  Inc(Y, 20);
  If PanY1 - 10 > Y + 40 Then PaintGraph(X, Y, PanX1 - 12, PanY1 - 10);
End;

Procedure PaintServer;
Var X, Y : LongInt; S : String;
Begin
  X := PanX0 + 12; Y := PanY0 + 8;
  If LastAlive Then
  Begin
    FBar(X, Y + 3, X + 9, Y + 12, cGreen); Box(X, Y + 3, X + 9, Y + 12, cBlack);
    OutBold(X + 16, Y, 'En marche (PID ' + IStr(Shm^.Pid) + ', depuis ' + Uptime + ')', cBlack, cSilver);
  End
  Else
  Begin
    FBar(X, Y + 3, X + 9, Y + 12, cRed); Box(X, Y + 3, X + 9, Y + 12, cBlack);
    OutBold(X + 16, Y, 'Arr'#136't'#130, cBlack, cSilver);
  End;
  Inc(Y, 22);
  If MyIpAddr <> 0 Then S := IpStr(MyIpAddr) Else S := '(voir IFCONFIG)';
  KeyVal(X, Y, 'Sites :', IStr(NSites)); Inc(Y, 18);
  KeyVal(X, Y, 'Configuration :', Fit(CfgPath, PanX1 - X - 180)); Inc(Y, 18);
  KeyVal(X, Y, 'Donn'#130'es :', WwwData);
  { case "Demarrer avec OS/2" a Y = 84, boutons a Y = 112, icones dessous }
  PaintTiles(PanY0 + 148);
End;

Procedure PaintSite;
Var X, Y, I : LongInt;
Begin
  I := SelSite;
  X := PanX0 + 12; Y := PanY0 + 6;
  KeyVal(X, Y, 'Liaisons :', Fit(SiteBinds(I), PanX1 - X - 180)); Inc(Y, 18);
  KeyVal(X, Y, 'Chemin physique :', Fit(Sites[I].Root, PanX1 - X - 180)); Inc(Y, 18);
  KeyVal(X, Y, #144'tat :', SiteState(I));
  If LastAlive Then
    OutTxt(X + 300, Y, IStr(Shm^.SiteReq[I]) + ' requ'#136'tes', cGray, cSilver);
  PaintTiles(PanY0 + 66);
End;

Procedure PaintActions;
Var X, Y, I : LongInt;
Begin
  If ActW = 0 Then Exit;
  X := CW - ActW;
  FBar(X, TbH, CW - 1, CH - SbH - 1, cSilver);
  VLine(X, TbH, CH - SbH - 1, cGray); VLine(X + 1, TbH, CH - SbH - 1, cWhite);
  Y := TbH + 4;
  For I := 0 To NAct - 1 Do
  Begin
    ActY[I] := Y;
    If ActCmd[I] = 0 Then
    Begin
      If I > 0 Then Inc(Y, 6);
      ActY[I] := Y;
      FBar(X + 4, Y, CW - 4, Y + 17, cNavy);
      OutBold(X + 8, Y + 1, Fit(ActS[I], ActW - 14), cWhite, cNavy);
      Inc(Y, 20);
    End
    Else
    Begin
      FBar(X + 12, Y + 6, X + 15, Y + 9, cNavy);
      OutTxt(X + 22, Y, Fit(ActS[I], ActW - 26), cBlue, cSilver);
      HLine(X + 22, X + 22 + Length(Fit(ActS[I], ActW - 26)) * 8 - 1, Y + 15, cBlue);
      Inc(Y, 18);
    End;
  End;
End;

Procedure PaintHeader;
Var X, Y : LongInt; T, S : String;
Begin
  X := PanX0; Y := TbH;
  FBar(X, Y, PanX1, Y + HdrH - 1, cWhite);
  HLine(X, PanX1, Y + HdrH - 1, cGray);
  If SelKind = nkSite Then Icon(nkSite, X + 8, Y + 7, 2, Not Sites[SelSite].Started)
  Else Icon(SelKind, X + 8, Y + 7, 2, False);
  Case SelKind Of
    nkServer : T := 'Accueil de OS2-0 (serveur local)';
    nkSite : T := 'Accueil de ' + Sites[SelSite].Name;
  Else
    T := KindName(SelKind);
    If SelSite >= 0 Then T := T + ' - ' + Sites[SelSite].Name;
  End;
  Case SelKind Of
    nkServer : S := 'Serveur Web d''OS/2-0 ' + AppVer + ' : HTTP/1.1, HTTPS (TLS 1.3), PSP, ASP.';
    nkSite : S := 'Choisissez une fonctionnalit'#130' du site (double-clic).';
  Else
    S := KindHelp(SelKind);
  End;
  OutBold(X + 50, Y + 6, Fit(T, PanX1 - X - 56), cNavy, cWhite);
  OutTxt(X + 50, Y + 24, Fit(S, PanX1 - X - 56), cGray, cWhite);
End;

Procedure PaintToolbar;
Var X : LongInt;

  Procedure TBtn(Ic : LongInt);
  Var J : LongInt;
  Begin
    Edge(X, 4, X + 25, TbH - 5, cWhite, cGray);
    IcX := X + 5; IcY := 8; IcS := 1;
    Case Ic Of
      1 : Begin   { demarrer }
            For J := 0 To 6 Do VLine(IcX + 4 + J, IcY + 1 + J, IcY + 14 - J, cGreen);
          End;
      2 : IR(3, 3, 12, 12, cRed);                                 { arreter }
      3 : Begin   { redemarrer }
            IR(2, 3, 4, 12, cNavy);
            For J := 0 To 5 Do VLine(IcX + 7 + J, IcY + 2 + J, IcY + 13 - J, cGreen);
          End;
      4 : Begin   { actualiser }
            IB(3, 3, 12, 12, cDGreen); IR(10, 1, 14, 5, cSilver); IR(11, 2, 13, 4, cDGreen); IR(8, 3, 9, 3, cDGreen);
          End;
      5 : Begin   { ajouter un site }
            IcoGlobe; IR(10, 0, 15, 5, cYellow); IB(10, 0, 15, 5, cBrown);
          End;
      6 : Begin   { parcourir }
            IcoGlobe; IR(9, 9, 15, 11, cBlack); IR(13, 7, 13, 13, cBlack);
          End;
    End;
    Inc(X, 28);
  End;

Begin
  FBar(0, 0, CW - 1, TbH - 1, cSilver);
  HLine(0, CW - 1, TbH - 1, cGray); HLine(0, CW - 1, 0, cWhite);
  X := 6;
  TBtn(1); TBtn(2); TBtn(3);
  Inc(X, 8); VLine(X - 5, 5, TbH - 6, cGray); VLine(X - 4, 5, TbH - 6, cWhite);
  TBtn(4);
  Inc(X, 8); VLine(X - 5, 5, TbH - 6, cGray); VLine(X - 4, 5, TbH - 6, cWhite);
  TBtn(5); TBtn(6);
  { etat du serveur a droite de la barre d'outils }
  If LastAlive Then
  Begin
    FBar(CW - 150, 11, CW - 141, 20, cGreen); OutTxt(CW - 134, 7, 'En marche', cBlack, cSilver);
  End
  Else
  Begin
    FBar(CW - 150, 11, CW - 141, 20, cRed); OutTxt(CW - 134, 7, 'Arr'#136't'#130, cBlack, cSilver);
  End;
  Box(CW - 150, 11, CW - 141, 20, cBlack);
End;

Procedure PaintStatus;
Var Y, X2 : LongInt; S : String;
Begin
  Y := CH - SbH;
  FBar(0, Y, CW - 1, CH - 1, cSilver);
  HLine(0, CW - 1, Y, cWhite);
  X2 := CW - 230;
  Sunken(2, Y + 2, X2 - 4, CH - 3, cSilver);
  S := StatusMsg;
  If Dirty Then S := '* ' + S;
  OutTxt(6, Y + 3, Fit(S, X2 - 14), cBlack, cSilver);
  Sunken(X2, Y + 2, CW - 3, CH - 3, cSilver);
  If LastAlive Then S := IStr(Shm^.CurConn) + ' conn., ' + IStr(Shm^.Requests) + ' req.'
  Else S := 'Serveur arr'#136't'#130;
  OutTxt(X2 + 4, Y + 3, Fit(S, CW - X2 - 10), cBlack, cSilver);
End;

Procedure PaintPanel;
Var K : LongInt;
Begin
  FBar(PanX0 - 3, TbH, PanX0 - 1, CH - SbH - 1, cSilver);
  FBar(PanX0, PanY0, PanX1, PanY1, cSilver);
  PaintHeader;
  Case SelKind Of
    nkServer : PaintServer;
    nkSite : PaintSite;
    nkMonitor : PaintMonitor;
  End;
  For K := 0 To NLbl - 1 Do
    OutTxt(PanX0 + LblX[K], PanY0 + LblY[K], Fit(LblS[K], PanX1 - PanX0 - LblX[K] - 4), LblC[K], cSilver);
  If ListHdr <> '' Then
  Begin
    Raised(PanX0 + 8, PanY0 + ListY, PanX1 - 10, PanY0 + ListY + 19);
    OutTxt(PanX0 + 14, PanY0 + ListY + 2, Fit(ListHdr, PanX1 - PanX0 - 26), cBlack, cSilver);
  End;
End;

Procedure Paint(H : LongInt);
Begin
  Hps := WinBeginPaint(H, 0, 0);
  PaintToolbar;
  PaintTree;
  PaintPanel;
  PaintActions;
  PaintStatus;
  Dummy := WinEndPaint(Hps);
End;

{ redessiner une bande (ordonnees Y vers le bas) }
Procedure InvalBand(X1, Y1, X2, Y2 : LongInt);
Var Rc : Array[0..3] Of LongInt;
Begin
  Rc[0] := X1; Rc[1] := CH - Y2; Rc[2] := X2; Rc[3] := CH - Y1;
  Dummy := WinInvalidateRect(Client, LongInt(@Rc), 0);
End;

{ ==================================================================== }
{ Selection, geometrie                                                  }
{ ==================================================================== }

Procedure Layout;
Var I : LongInt;
Begin
  TreeW := MinI(260, MaxI(170, CW * 27 Div 100));
  If ShowAct And (CW >= 720) Then ActW := ActW0 Else ActW := 0;
  For I := 0 To NCtl - 1 Do PlaceCtl(I);
End;

Procedure Select(N : LongInt);
Begin
  If (N < 0) Or (N >= NNode) Then Exit;
  NSel := N;
  SelKind := NKind[N]; SelSite := NSite[N];
  BuildPanel;
End;

{ aller a un noeud (en depliant ses parents) }
Procedure GoNode(K, S : LongInt);
Var I : LongInt;
Begin
  ExpServer := True;
  If (K = nkSite) Or ((K >= nkFirstCat) And (K <= nkLastCat)) Then ExpSites := True;
  If (K >= nkFirstCat) And (K <= nkLastCat) Then ExpSite[S] := True;
  SelKind := K; SelSite := S;
  BuildTree;
  For I := 0 To NNode - 1 Do
    If (NKind[I] = K) And (NSite[I] = S) Then NSel := I;
  Select(NSel);
End;

Procedure ToggleNode(I : LongInt);
Begin
  If Not NKids[I] Then Exit;
  SetOpen(I, Not NodeOpen(I));
  BuildTree;
  Redraw;
End;

{ ==================================================================== }
{ Boite de saisie (jusqu'a 5 champs et une case a cocher)               }
{ ==================================================================== }

Function DlgProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var P, Fl, Vk, K, X, Y : LongInt; Rc, Tr : Array[0..3] Of LongInt;
Begin
  DlgProc := 0;
  Case Msg_ Of
    WM_PAINT :
      Begin
        P := WinBeginPaint(H, 0, 0);
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        Dummy := WinFillRect(P, LongInt(@Rc), cSilver);
        For K := 0 To DN - 1 Do
        Begin
          PutZ(DLab[K]);
          Tr[0] := 12; Tr[1] := DH - 34 - K * 30; Tr[2] := 206; Tr[3] := Tr[1] + 18;
          Dummy := WinDrawText(P, -1, LongInt(@TxtBuf), LongInt(@Tr), cBlack, cSilver, 0);
        End;
        Dummy := WinEndPaint(P);
      End;
    WM_COMMAND :
      Begin
        If Lo16(Mp1) = 1 Then
        Begin
          For K := 0 To DN - 1 Do DlgV[K] := Trim(WinText(DEf[K]));
          If DChkH <> 0 Then DChk := WinSendMsg(DChkH, BM_QUERYCHECK, 0, 0) = 1;
          DOk := True;
        End;
        DDone := True;
      End;
    WM_BUTTON1DOWN :
      Begin
        { clic sur un champ : il prend le focus }
        X := S16(Mp1); Y := S16(Mp1 Shr 16);
        For K := 0 To DN - 1 Do
          If (X >= 210) And (X < DW - 14) And (Y >= DH - 36 - K * 30) And (Y < DH - 16 - K * 30) Then
            Dummy := WinSetFocus(HWND_DESKTOP, DEf[K]);
        DlgProc := 1;
      End;
    WM_CHAR :
      Begin
        Fl := Lo16(Mp1); Vk := Hi16(Mp2);
        If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_TAB) Or (Vk = VK_BACKTAB) Or
           (Vk = VK_DOWN) Or (Vk = VK_UP)) Then
        Begin
          { Tab, Maj+Tab, fleches : champ suivant ou precedent }
          P := WinQueryFocus(HWND_DESKTOP);
          X := -1;
          For K := 0 To DN - 1 Do If DEf[K] = P Then X := K;
          If DChkH = P Then X := DN;
          If (Vk = VK_BACKTAB) Or (Vk = VK_UP) Or ((Fl And KC_SHIFT) <> 0) Then Dec(X) Else Inc(X);
          If X < 0 Then X := DN;
          If (X > DN) Or ((X = DN) And (DChkH = 0)) Then X := 0;
          If X = DN Then Dummy := WinSetFocus(HWND_DESKTOP, DChkH)
          Else If DN > 0 Then Dummy := WinSetFocus(HWND_DESKTOP, DEf[X]);
        End
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_ENTER) Or (Vk = VK_NEWLINE)) Then
          Dummy := WinPostMsg(H, WM_COMMAND, 1, 0)
        Else If ((Fl And KC_KEYUP) = 0) And ((Fl And KC_VIRTUALKEY) <> 0) And (Vk = VK_ESC) Then DDone := True
        Else DlgProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
      End;
    WM_CLOSE : DDone := True;
  Else
    DlgProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

{ boite modale : DLab/DlgV[0..DN-1], DChkS (case, '' : aucune) }
Function InputBox(Title : String) : Boolean;
Var Fl, K, Fw, Fh, Sw, Sh, St : LongInt; Rc : Array[0..3] Of LongInt; Q : Array[0..7] Of LongInt;
Begin
  InputBox := False;
  DW := 510;
  DH := 60 + DN * 30;
  If DChkS <> '' Then Inc(DH, 28);
  Dummy := WinRegisterClass(Hab, Z('WEBSRVDLG'), LongInt(@DlgProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_DLGBORDER;
  DClient := 0;
  DFrame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('WEBSRVDLG'), Z2(Title), 0, 0, 0, LongInt(@DClient));
  If DFrame = 0 Then Exit;
  For K := 0 To DN - 1 Do
  Begin
    St := WS_VISIBLE Or WS_TABSTOP Or ES_AUTOSCROLL Or ES_MARGIN;
    If DPass = K + 1 Then St := St Or ES_UNREADABLE;
    DEf[K] := WinCreateWindow(DClient, WC_ENTRYFIELD, Z(DlgV[K]), St, 210, DH - 36 - K * 30, DW - 224, 20, DClient,
                              HWND_TOP, 10 + K, 0, 0);
    Dummy := WinSendMsg(DEf[K], EM_SETTEXTLIMIT, 250, 0);
  End;
  DChkH := 0;
  If DChkS <> '' Then
  Begin
    DChkH := WinCreateWindow(DClient, WC_BUTTON, Z(DChkS), WS_VISIBLE Or WS_TABSTOP Or BS_AUTOCHECKBOX, 12,
                             DH - 36 - DN * 30, DW - 30, 20, DClient, HWND_TOP, 9, 0, 0);
    GrayBg(DChkH);
    If DChk Then Dummy := WinSendMsg(DChkH, BM_SETCHECK, 1, 0);
  End;
  Dummy := WinCreateWindow(DClient, WC_BUTTON, Z('OK'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON Or BS_DEFAULT,
                           DW - 200, 10, 90, 26, DClient, HWND_TOP, 1, 0, 0);
  Dummy := WinCreateWindow(DClient, WC_BUTTON, Z('Annuler'), WS_VISIBLE Or WS_TABSTOP Or BS_PUSHBUTTON,
                           DW - 102, 10, 90, 26, DClient, HWND_TOP, 2, 0, 0);
  Rc[0] := 0; Rc[1] := 0; Rc[2] := DW; Rc[3] := DH;
  Dummy := WinCalcFrameRect(DFrame, LongInt(@Rc), 0);
  Fw := Rc[2] - Rc[0]; Fh := Rc[3] - Rc[1];
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Dummy := WinSetWindowPos(DFrame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, DFrame);
  If DN > 0 Then Dummy := WinSetFocus(HWND_DESKTOP, DEf[0]);
  Dummy := WinEnableWindow(Frame, 0);
  DDone := False; DOk := False;
  While Not DDone Do
  Begin
    If WinGetMsg(Hab, LongInt(@Q), 0, 0, 0) = 0 Then
    Begin
      DDone := True;
      Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    End
    Else Dummy := WinDispatchMsg(Hab, LongInt(@Q));
  End;
  Dummy := WinEnableWindow(Frame, 1);
  Dummy := WinDestroyWindow(DFrame);
  DFrame := 0;
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  InputBox := DOk;
End;

Procedure DlgReset;
Var K : LongInt;
Begin
  DN := 0; DChkS := ''; DChk := False; DPass := 0;
  For K := 0 To 4 Do
  Begin
    DLab[K] := ''; DlgV[K] := '';
  End;
End;

Procedure DlgField(L, V : String);
Begin
  If DN > 4 Then Exit;
  DLab[DN] := L; DlgV[DN] := V;
  Inc(DN);
End;

{ ==================================================================== }
{ Commandes                                                             }
{ ==================================================================== }

Function FreeSite : LongInt;
Var I : LongInt;
Begin
  FreeSite := -1;
  For I := MaxSites - 1 DownTo 0 Do If Not Sites[I].Used Then FreeSite := I;
End;

Function NextSiteId : LongInt;
Var I, M : LongInt;
Begin
  M := 0;
  For I := 0 To MaxSites - 1 Do If Sites[I].Used And (Sites[I].Id > M) Then M := Sites[I].Id;
  NextSiteId := M + 1;
End;

Procedure AddSite;
Var I, P : LongInt; Bd : TBind;
Begin
  I := FreeSite;
  If I < 0 Then
  Begin
    MsgErr('Pas plus de ' + IStr(MaxSites) + ' sites.');
    Exit;
  End;
  DlgReset;
  DlgField('Nom du site :', 'Nouveau site');
  DlgField('Chemin physique :', WwwData + '\SITE' + IStr(NextSiteId));
  DlgField('Port :', '8080');
  DlgField('Nom d''h'#147'te :', '');
  DChkS := 'Liaison https (SSL/TLS)';
  If Not InputBox('Ajouter un site Web') Then Exit;
  If DlgV[0] = '' Then Exit;
  P := SVal(DlgV[2]);
  If (P <= 0) Or (P > 65535) Then
  Begin
    MsgErr('Port incorrect : ' + DlgV[2]);
    Exit;
  End;
  SiteInit(Sites[I], NextSiteId);
  Sites[I].Name := Copy(DlgV[0], 1, 63);
  If DlgV[1] <> '' Then Sites[I].Root := Copy(DlgV[1], 1, 127);
  Bd.Tls := DChk; Bd.Ip := 0; Bd.Port := P; Bd.Host := LoStr(Copy(DlgV[3], 1, 63));
  Sites[I].NB := 1; Sites[I].B[0] := Bd;
  PMkDir(Sites[I].Root);
  SaveCfg;
  GoNode(nkSite, I);
End;

Procedure DelSite(I : LongInt);
Begin
  If (I < 0) Or Not Sites[I].Used Then Exit;
  If Not Ask('Supprimer le site "' + Sites[I].Name + '" ?' + #10 + '(ses fichiers restent sur le disque)') Then Exit;
  Sites[I].Used := False;
  SaveCfg;
  GoNode(nkSites, -1);
End;

{ site choisi : dans l'arbre, ou dans la liste des sites }
Function CurSite : LongInt;
Var K, J, N : LongInt;
Begin
  CurSite := SelSite;
  If (SelKind = nkSites) And (ListH <> 0) Then
  Begin
    K := LSel; N := 0; CurSite := -1;
    For J := 0 To MaxSites - 1 Do
      If Sites[J].Used Then
      Begin
        If N = K Then CurSite := J;
        Inc(N);
      End;
  End;
End;

Procedure StartSrv;
Begin
  If Alive Then
  Begin
    StatusMsg := 'Le serveur Web est d'#130'j'#133' en marche.';
    Exit;
  End;
  If Dirty Then SaveCfg;
  StatusMsg := StartService;
End;

Procedure StopSrv;
Var T : LongInt;
Begin
  If Not Alive Then
  Begin
    StatusMsg := 'Le serveur Web est d'#130'j'#133' arr'#136't'#130'.';
    Exit;
  End;
  Shm^.Cmd := cmdStop;
  Inc(Shm^.CmdSeq);
  T := PTicks;
  While Alive And (Shm^.Running <> 0) And (PTicks - T < 3000) Do PSleep(50);
  StatusMsg := 'Serveur Web arr'#136't'#130'.';
End;

Procedure BrowseSite(I : LongInt);
Var Exe, U, H : String; J : LongInt;
Begin
  If (I < 0) Or Not Sites[I].Used Then I := 0;
  If Sites[I].NB = 0 Then Exit;
  J := 0;
  If Sites[I].B[J].Tls Then U := 'https://' Else U := 'http://';
  H := Sites[I].B[J].Host;
  If H = '' Then H := 'localhost';
  U := U + H;
  If Not ((Sites[I].B[J].Port = 80) And Not Sites[I].B[J].Tls) And Not ((Sites[I].B[J].Port = 443) And
     Sites[I].B[J].Tls) Then U := U + ':' + IStr(Sites[I].B[J].Port);
  U := U + '/';
  Exe := FindExe('BROWSER.EXE');
  If Exe = '' Then MsgErr('Navigateur Web introuvable (BROWSER.EXE).') Else Launch(Exe, U);
  StatusMsg := 'Parcourir : ' + U;
End;

Procedure Explore(Dir : String);
Var Exe : String;
Begin
  Exe := FindExe('EXPLORER.EXE');
  If Exe = '' Then MsgErr('Explorateur introuvable (EXPLORER.EXE).') Else Launch(Exe, Dir);
End;

Procedure NewCert(I : LongInt);
Begin
  If (I < 0) Or Not Sites[I].Used Then I := 0;
  StatusMsg := 'Cr'#130'ation du certificat...';
  PaintStatus;
  If CreateCertFile(CertFile(I), CertName(I), MyIpAddr) Then
  Begin
    StatusMsg := 'Certificat auto-sign'#130' cr'#130#130' : ' + CertFile(I) + ' (CN ' + CertName(I) + ').';
    If Alive Then
    Begin
      Shm^.Cmd := cmdReload;
      Inc(Shm^.CmdSeq);
    End;
  End
  Else MsgErr('Impossible d''''crire ' + CertFile(I) + '.');
End;

{ Appliquer un formulaire }
Procedure Apply;
Var I : LongInt;
Begin
  I := SelSite;
  Case SelKind Of
    nkBasic :
      Begin
        If FieldVal(0) <> '' Then Sites[I].Name := Copy(FieldVal(0), 1, 63);
        If FieldVal(1) <> '' Then Sites[I].Root := Copy(FieldVal(1), 1, 127);
        Sites[I].Started := Checked(idCtl + 1);
      End;
    nkBrowse : Sites[I].Browse := Checked(idCtl + 1);
    nkAuth :
      If Checked(idCtl + 1) And (FieldVal(0) <> '') Then
      Begin
        Sites[I].AuthUser := Copy(FieldVal(0), 1, 31);
        Sites[I].AuthPass := Copy(WinText(CtlById(idCtl + 11)), 1, 31);
      End
      Else
      Begin
        Sites[I].AuthUser := ''; Sites[I].AuthPass := '';
      End;
    nkHand :
      Begin
        Sites[I].Psp := Checked(idCtl + 1);
        Sites[I].Asp := Checked(idCtl + 2);
        Sites[I].Php := Checked(idCtl + 3);
      End;
    nkCert : Sites[I].Cert := Copy(FieldVal(0), 1, 127);
    nkLog : Sites[I].LogOn := Checked(idCtl + 1);
    nkSettings :
      Begin
        If FieldVal(0) <> '' Then ServerName := Copy(FieldVal(0), 1, 63);
        MaxConnCfg := MaxI(1, MinI(MaxConn, SVal(FieldVal(1))));
        KeepAliveS := MaxI(1, SVal(FieldVal(2)));
        ConnTimeoutS := MaxI(5, SVal(FieldVal(3)));
        ScriptTimeoutS := MaxI(1, SVal(FieldVal(4)));
        SessionTimeoutM := MaxI(1, SVal(FieldVal(5)));
      End;
  End;
  SaveCfg;
  BuildTree;
  BuildPanel;
End;

{ ajouter ou modifier un element d'une liste }
Procedure EditItem(Add : Boolean);
Var I, K, P, N : LongInt; Bd : TBind; Ok : Boolean; S : String;
Begin
  I := SelSite;
  K := LSel;
  If (Not Add) And (K < 0) Then
  Begin
    StatusMsg := 'Choisissez d''abord un '#130'l'#130'ment de la liste.';
    PaintStatus;
    Exit;
  End;
  DlgReset;
  Case SelKind Of
    nkBind :
      Begin
        If Add Then
        Begin
          If Sites[I].NB >= MaxBind Then Exit;
          Bd.Tls := False; Bd.Ip := 0; Bd.Port := 80; Bd.Host := '';
        End
        Else Bd := Sites[I].B[K];
        If Bd.Ip = 0 Then S := '*' Else S := IpStr(Bd.Ip);
        DlgField('Adresse IP (* : toutes) :', S);
        DlgField('Port :', IStr(Bd.Port));
        DlgField('Nom d''h'#147'te :', Bd.Host);
        DChkS := 'https (SSL/TLS)'; DChk := Bd.Tls;
        If Not InputBox('Liaison de site') Then Exit;
        P := SVal(DlgV[1]);
        If (P <= 0) Or (P > 65535) Then
        Begin
          MsgErr('Port incorrect.');
          Exit;
        End;
        Bd.Tls := DChk; Bd.Port := P; Bd.Host := LoStr(Copy(DlgV[2], 1, 63));
        If (DlgV[0] = '') Or (DlgV[0] = '*') Then Bd.Ip := 0
        Else
        Begin
          Bd.Ip := ParseIp(DlgV[0]);
          If Bd.Ip = 0 Then
          Begin
            MsgErr('Adresse IP incorrecte : ' + DlgV[0] + ' (exemple : 10.0.2.15, ou * pour toutes).');
            Exit;
          End;
        End;
        For P := 0 To Sites[I].NB - 1 Do
          If (Add Or (P <> K)) And (Sites[I].B[P].Port = Bd.Port) And (Sites[I].B[P].Ip = Bd.Ip) And
             (Sites[I].B[P].Host = Bd.Host) Then
          Begin
            MsgErr('Cette liaison existe d'#130'j'#133'.');
            Exit;
          End;
        If Add Then
        Begin
          Sites[I].B[Sites[I].NB] := Bd; Inc(Sites[I].NB);
        End
        Else Sites[I].B[K] := Bd;
      End;
    nkDocs :
      Begin
        If Sites[I].ND >= MaxDocs Then Exit;
        DlgField('Nom du document :', 'default.psp');
        If Not InputBox('Document par d'#130'faut') Then Exit;
        If DlgV[0] = '' Then Exit;
        Sites[I].Docs[Sites[I].ND] := Copy(DlgV[0], 1, 31); Inc(Sites[I].ND);
      End;
    nkErr :
      Begin
        If Add Then
        Begin
          If Sites[I].NE >= MaxErrP Then Exit;
          DlgField('Code d'''#130'tat :', '404'); DlgField('Page (chemin du site) :', '/erreurs/404.htm');
        End
        Else
        Begin
          DlgField('Code d'''#130'tat :', IStr(Sites[I].ErrCode[K])); DlgField('Page (chemin du site) :',
                   Sites[I].ErrPath[K]);
        End;
        If Not InputBox('Page d''erreur personnalis'#130'e') Then Exit;
        P := SVal(DlgV[0]);
        If (P < 400) Or (P > 599) Or (DlgV[1] = '') Then
        Begin
          MsgErr('Code (400 '#133' 599) ou page incorrects.');
          Exit;
        End;
        If Add Then
        Begin
          K := Sites[I].NE; Inc(Sites[I].NE);
        End;
        Sites[I].ErrCode[K] := P; Sites[I].ErrPath[K] := Copy(DlgV[1], 1, 79);
      End;
    nkHdr :
      Begin
        If Add Then
        Begin
          If Sites[I].NH >= MaxHdrs Then Exit;
          DlgField('Nom :', 'X-Powered-By'); DlgField('Valeur :', 'OS/2-0');
        End
        Else
        Begin
          S := Sites[I].Hdr[K]; P := Pos(':', S);
          If P = 0 Then P := Length(S) + 1;
          DlgField('Nom :', Trim(Copy(S, 1, P - 1))); DlgField('Valeur :', Trim(Copy(S, P + 1, 255)));
        End;
        If Not InputBox('En-t'#136'te de r'#130'ponse HTTP') Then Exit;
        If DlgV[0] = '' Then Exit;
        If Add Then
        Begin
          K := Sites[I].NH; Inc(Sites[I].NH);
        End;
        Sites[I].Hdr[K] := Copy(DlgV[0] + ': ' + DlgV[1], 1, 127);
      End;
    nkVDir :
      Begin
        If Add Then
        Begin
          If Sites[I].NV >= MaxVDir Then Exit;
          DlgField('Alias :', '/docs'); DlgField('Chemin physique :', 'C:\');
        End
        Else
        Begin
          DlgField('Alias :', Sites[I].VUrl[K]); DlgField('Chemin physique :', Sites[I].VPath[K]);
        End;
        If Not InputBox('R'#130'pertoire virtuel') Then Exit;
        If (DlgV[0] = '') Or (DlgV[1] = '') Then Exit;
        If DlgV[0][1] <> '/' Then DlgV[0] := '/' + DlgV[0];
        If Add Then
        Begin
          K := Sites[I].NV; Inc(Sites[I].NV);
        End;
        Sites[I].VUrl[K] := Copy(DlgV[0], 1, 47); Sites[I].VPath[K] := Copy(DlgV[1], 1, 127);
      End;
    nkMime :
      Begin
        If Add Then
        Begin
          If NMime >= MaxMime Then Exit;
          DlgField('Extension :', '.'); DlgField('Type MIME :', 'application/octet-stream');
        End
        Else
        Begin
          DlgField('Extension :', MimeExt[K]); DlgField('Type MIME :', MimeTyp[K]);
        End;
        If Not InputBox('Type MIME') Then Exit;
        If (Length(DlgV[0]) < 2) Or (DlgV[1] = '') Then Exit;
        If DlgV[0][1] <> '.' Then DlgV[0] := '.' + DlgV[0];
        If Add Then
        Begin
          K := NMime; Inc(NMime);
        End;
        MimeExt[K] := LoStr(Copy(DlgV[0], 1, 11)); MimeTyp[K] := Copy(DlgV[1], 1, 63);
      End;
  Else
    Exit;
  End;
  SaveCfg;
  N := K;
  FillList;
  If Add Then N := 999;
  Dummy := WinSendMsg(ListH, LM_SELECTITEM, MinI(N, 998), 1);
  Redraw;
End;

Procedure DelItem;
Var I, K, J : LongInt;
Begin
  I := SelSite; K := LSel;
  If K < 0 Then Exit;
  Case SelKind Of
    nkBind :
      Begin
        If Sites[I].NB <= 1 Then
        Begin
          MsgErr('Un site doit garder au moins une liaison.');
          Exit;
        End;
        For J := K To Sites[I].NB - 2 Do Sites[I].B[J] := Sites[I].B[J + 1];
        Dec(Sites[I].NB);
      End;
    nkDocs :
      Begin
        For J := K To Sites[I].ND - 2 Do Sites[I].Docs[J] := Sites[I].Docs[J + 1];
        Dec(Sites[I].ND);
      End;
    nkErr :
      Begin
        For J := K To Sites[I].NE - 2 Do
        Begin
          Sites[I].ErrCode[J] := Sites[I].ErrCode[J + 1]; Sites[I].ErrPath[J] := Sites[I].ErrPath[J + 1];
        End;
        Dec(Sites[I].NE);
      End;
    nkHdr :
      Begin
        For J := K To Sites[I].NH - 2 Do Sites[I].Hdr[J] := Sites[I].Hdr[J + 1];
        Dec(Sites[I].NH);
      End;
    nkVDir :
      Begin
        For J := K To Sites[I].NV - 2 Do
        Begin
          Sites[I].VUrl[J] := Sites[I].VUrl[J + 1]; Sites[I].VPath[J] := Sites[I].VPath[J + 1];
        End;
        Dec(Sites[I].NV);
      End;
    nkMime :
      Begin
        For J := K To NMime - 2 Do
        Begin
          MimeExt[J] := MimeExt[J + 1]; MimeTyp[J] := MimeTyp[J + 1];
        End;
        Dec(NMime);
      End;
  Else
    Exit;
  End;
  SaveCfg;
  FillList;
  Redraw;
End;

Procedure MoveDoc(D : LongInt);
Var I, K : LongInt; S : String;
Begin
  I := SelSite; K := LSel;
  If (K < 0) Or (K + D < 0) Or (K + D >= Sites[I].ND) Then Exit;
  S := Sites[I].Docs[K]; Sites[I].Docs[K] := Sites[I].Docs[K + D]; Sites[I].Docs[K + D] := S;
  SaveCfg;
  FillList;
  Dummy := WinSendMsg(ListH, LM_SELECTITEM, K + D, 1);
  Redraw;
End;

Procedure About;
Begin
  Msg('Serveur Web d''OS/2-0 ' + AppVer + #10 + 'HTTP/1.1, HTTPS (TLS 1.3, ECDSA P-256), h'#147'tes virtuels,' + #10 +
      'PSP (Pascal Server Pages) et ASP (VBScript) int'#130'gr'#130's.' + #10 + 'Console dans le style d''IIS.' + #10 +
      'Copyright Gladir.com 2026');
End;

Procedure Help;
Begin
  Msg('Arbre de gauche : le serveur, ses sites et leurs fonctionnalit'#130's.' + #10 +
      'Panneau central : r'#130'glages de l'''#130'l'#130'ment choisi ; Appliquer enregistre' + #10 +
      'WEBSRV.CFG et le serveur en marche relit sa configuration.' + #10 +
      'Volet Actions (fen'#136'tre large) ou menu Action : d'#130'marrer, arr'#136'ter, ajouter un site.' + #10 +
      'Pages .htm/.html : statiques ; .psp : Pascal Server Pages ; .asp : VBScript.' + #10 +
      'Outils -> D'#130'marrer avec OS/2 : ligne RUN= de CONFIG.SYS (d'#130'sactiv'#130' par d'#130'faut).' + #10 +
      'Commandes : WEBSRV /START, /STOP, /STATUS, /PSP page.');
End;

Procedure SetMenuChk(Id : LongInt; On_ : Boolean);
Begin
  If On_ Then Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED Or (MIA_CHECKED Shl 16))
  Else Dummy := WinSendMsg(MenuHw, MM_SETITEMATTR, Id Or $10000, MIA_CHECKED);
End;

Procedure ToggleAutoStart(On_ : Boolean);
Begin
  If SetAutoStart(On_) Then
  Begin
    If On_ Then StatusMsg := 'Le serveur Web d'#130'marrera avec OS/2 (RUN= ajout'#130' '#133' ' + CfgSysPath + ').'
    Else StatusMsg := 'Le serveur Web ne d'#130'marrera plus avec OS/2 (' + CfgSysPath + ').';
  End
  Else MsgErr('Impossible de modifier ' + CfgSysPath + ' (lecture seule : OS/2-0 d'#130'marr'#130' du CD-ROM ?' + #10 +
              'Installez OS/2-0 sur le disque dur pour d'#130'marrer le serveur Web avec le syst'#138'me).');
  SetMenuChk(cmAutoStart, AutoStartOn);
  If SelKind = nkServer Then
  Begin
    On_ := AutoStartOn;
    Dummy := WinSendMsg(CtlById(idCtl + 1), BM_SETCHECK, Ord(On_), 0);
  End;
End;

Procedure Refresh;
Begin
  BuildTree;
  BuildPanel;
End;

Procedure DoCmd(C : LongInt);
Var I : LongInt;
Begin
  I := CurSite;
  If C < 0 Then
  Begin
    GoNode(-C, SelSite);
    Exit;
  End;
  Case C Of
    cmSave : SaveCfg;
    cmReloadCfg :
      Begin
        CfgLoad;
        Dirty := False;
        StatusMsg := 'Configuration relue : ' + CfgPath;
        If (SelSite >= 0) And Not Sites[SelSite].Used Then
        Begin
          SelKind := nkSites; SelSite := -1;
        End;
        Refresh;
      End;
    cmQuit : Dummy := WinPostMsg(Client, WM_CLOSE, 0, 0);
    cmStart : StartSrv;
    cmStop : StopSrv;
    cmRestart :
      Begin
        StopSrv;
        PSleep(300);
        StartSrv;
      End;
    cmAddSite : AddSite;
    cmDelSite : DelSite(I);
    cmSiteOn, cmSiteOff :
      If I >= 0 Then
      Begin
        Sites[I].Started := C = cmSiteOn;
        SaveCfg;
        Refresh;
      End;
    cmBrowse : BrowseSite(I);
    cmSiteProps : If I >= 0 Then GoNode(nkBasic, I);
    cmEditSite : If I >= 0 Then GoNode(nkSite, I);
    cmGoBind : If SelSite >= 0 Then GoNode(nkBind, SelSite);
    cmActions :
      Begin
        ShowAct := Not ShowAct;
        SetMenuChk(cmActions, ShowAct);
        Layout;
        If (Not ShowAct) Or (CW >= 720) Then Redraw
        Else StatusMsg := 'Le volet Actions demande une fen'#136'tre plus large (720 points).';
        Redraw;
      End;
    cmRefresh : Refresh;
    cmExpand :
      Begin
        ExpServer := True; ExpSites := True;
        For I := 0 To MaxSites - 1 Do ExpSite[I] := Sites[I].Used;
        BuildTree; Redraw;
      End;
    cmCollapse :
      Begin
        ExpSites := False;
        For I := 0 To MaxSites - 1 Do ExpSite[I] := False;
        If (SelKind <> nkServer) And (SelKind <> nkMime) And (SelKind <> nkSettings) And (SelKind <> nkMonitor) And
           (SelKind <> nkLogs) Then GoNode(nkSites, -1)
        Else
        Begin
          BuildTree; Redraw;
        End;
      End;
    cmCert : NewCert(I);
    cmMakeCert : NewCert(SelSite);
    cmAutoStart : ToggleAutoStart(Not AutoStartOn);
    cmOpenLogs : Explore(WwwData + '\LOGS');
    cmOpenRoot : If I >= 0 Then Explore(Sites[I].Root);
    cmHelp : Help;
    cmAbout : About;
    cmApply : Apply;
    cmCancel : BuildPanel;
    cmAdd : If SelKind = nkSites Then AddSite Else EditItem(True);
    cmEdit :
      If SelKind = nkSites Then
      Begin
        If I >= 0 Then GoNode(nkSite, I);
      End
      Else EditItem(False);
    cmDel : DelItem;
    cmUp : MoveDoc(-1);
    cmDown : MoveDoc(1);
    cmClearLog :
      If Ask('Effacer ' + WwwData + '\WEBSRV.LOG ?') Then
      Begin
        Dummy := Ord(PDelete(WwwData + '\WEBSRV.LOG'));
        BuildPanel;
      End;
  End;
  Redraw;
End;

{ ==================================================================== }
{ Souris, clavier, minuterie                                            }
{ ==================================================================== }

{ menu contextuel de l'arbre (bouton 2) : X, Y coordonnees de PM }
Var
  CtxMenu, CtxN : LongInt;

Procedure CtxIt(Id : LongInt; S : String);
Begin
  MnItem(MIS_TEXT, 0, Id, S);
  Inc(CtxN);
End;

Procedure CtxSep;
Begin
  MnItem(MIS_SEPARATOR, 0, 0, '');
  Inc(CtxN);
End;

Procedure TreePopup(X, Y : LongInt);
Var Fst : LongInt;
Begin
  MenuLen := 0; CtxN := 0;
  Dummy := MenuOpen;
  Fst := cmRefresh;
  Case SelKind Of
    nkServer, nkSites :
      Begin
        Fst := cmAddSite;
        CtxIt(cmAddSite, 'Ajouter un ~site Web...');
        CtxSep;
        If LastAlive Then
        Begin
          CtxIt(cmStop, '~Arr'#136'ter le serveur');
          CtxIt(cmRestart, '~Red'#130'marrer le serveur');
        End
        Else CtxIt(cmStart, '~D'#130'marrer le serveur');
        CtxSep;
        If SelKind = nkServer Then
        Begin
          CtxIt(cmCert, 'Cr'#130'er un ~certificat auto-sign'#130'...');
          If AutoStartOn Then MnItem(MIS_TEXT, MIA_CHECKED, cmAutoStart, 'D'#130'marrer avec ~OS/2')
          Else MnItem(MIS_TEXT, 0, cmAutoStart, 'D'#130'marrer avec ~OS/2');
          Inc(CtxN);
          CtxSep;
        End;
        CtxIt(cmExpand, 'D'#130'~velopper tout');
        CtxIt(cmCollapse, 'R'#130'~duire tout');
        CtxIt(cmRefresh, 'A~ctualiser' + #9 + 'F5');
      End;
    nkSite :
      Begin
        If Sites[SelSite].Started Then
        Begin
          Fst := cmSiteOff;
          CtxIt(cmSiteOff, '~Arr'#136'ter le site');
        End
        Else
        Begin
          Fst := cmSiteOn;
          CtxIt(cmSiteOn, '~D'#130'marrer le site');
        End;
        CtxIt(cmBrowse, '~Parcourir');
        CtxSep;
        CtxIt(cmSiteProps, 'Param'#138'tres de ~base...');
        CtxIt(cmGoBind, '~Liaisons...');
        CtxIt(cmOpenRoot, '~Explorer le dossier');
        CtxSep;
        CtxIt(cmAddSite, 'Ajouter un ~site Web...');
        CtxIt(cmDelSite, 'S~upprimer le site' + #9 + 'Suppr');
        CtxSep;
        CtxIt(cmRefresh, 'A~ctualiser' + #9 + 'F5');
      End;
    nkLogs :
      Begin
        CtxIt(cmRefresh, 'A~ctualiser' + #9 + 'F5');
        CtxIt(cmClearLog, '~Effacer le journal');
      End;
  Else
    Begin
      If SelSite >= 0 Then
      Begin
        Fst := cmBrowse;
        CtxIt(cmBrowse, '~Parcourir le site');
        CtxIt(cmEditSite, '~Accueil du site');
        CtxSep;
      End;
      CtxIt(cmRefresh, 'A~ctualiser' + #9 + 'F5');
    End;
  End;
  CtxSep;
  CtxIt(cmHelp, 'Ai~de' + #9 + 'F1');
  MenuClose(0, CtxN);
  If CtxMenu <> 0 Then Dummy := WinDestroyWindow(CtxMenu);
  CtxMenu := WinCreateMenu(HWND_DESKTOP, LongInt(@MenuT));
  If CtxMenu <> 0 Then Dummy := WinPopupMenu(Client, Client, CtxMenu, X, Y, Fst, 0);
End;

{ bouton 2 : choisir le noeud sous le pointeur, puis son menu }
Procedure RightClick(X, Y : LongInt);
Var R : LongInt;
Begin
  If (X >= TreeW) Or (Y < TbH) Or (Y >= CH - SbH) Then Exit;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  R := NTop + (Y - TbH - 4) Div RowH;
  If (R < 0) Or (R >= NNode) Then Exit;
  If R <> NSel Then Select(R);
  TreePopup(X, CH - 1 - Y);
End;

Procedure Click(X, Y : LongInt; Dbl : Boolean);
Var I, R, Xn, Cols : LongInt;
Begin
  { barre d'outils }
  If Y < TbH Then
  Begin
    If (Y >= 4) And (Y <= TbH - 5) Then
    Begin
      I := (X - 6) Div 28;
      If X >= 6 + 3 * 28 + 8 Then I := (X - 14) Div 28;
      If X >= 14 + 4 * 28 + 8 Then I := (X - 22) Div 28;
      Case I Of
        0 : DoCmd(cmStart);
        1 : DoCmd(cmStop);
        2 : DoCmd(cmRestart);
        3 : DoCmd(cmRefresh);
        4 : DoCmd(cmAddSite);
        5 : DoCmd(cmBrowse);
      End;
    End;
    Exit;
  End;
  If Y >= CH - SbH Then Exit;
  { arbre }
  If X < TreeW Then
  Begin
    Dummy := WinSetFocus(HWND_DESKTOP, Client);
    If (NTop > 0) And (Y < TbH + 14) And (X > TreeW - 20) Then
    Begin
      Dec(NTop); Redraw; Exit;
    End;
    If (Y > CH - SbH - 16) And (X > TreeW - 20) Then
    Begin
      Inc(NTop, 3); Redraw; Exit;
    End;
    R := NTop + (Y - TbH - 4) Div RowH;
    If (R < 0) Or (R >= NNode) Then Exit;
    Xn := 6 + NLev[R] * 16;
    If NKids[R] And (X >= Xn - 16) And (X < Xn - 2) Then
    Begin
      ToggleNode(R);
      Exit;
    End;
    If Dbl And NKids[R] Then
    Begin
      ToggleNode(R);
      Exit;
    End;
    If R <> NSel Then Select(R);
    Exit;
  End;
  { volet Actions }
  If (ActW > 0) And (X >= CW - ActW) Then
  Begin
    For I := 0 To NAct - 1 Do
      If (ActCmd[I] <> 0) And (Y >= ActY[I]) And (Y < ActY[I] + 17) Then
      Begin
        DoCmd(ActCmd[I]);
        Exit;
      End;
    Exit;
  End;
  { controle du panneau sous le clic : il prend le focus }
  For I := 0 To NCtl - 1 Do
    If (X >= CtlRx[I]) And (X < CtlRx[I] + CtlRw[I]) And (Y >= CtlRy[I]) And (Y < CtlRy[I] + CtlRh[I]) Then
    Begin
      Dummy := WinSetFocus(HWND_DESKTOP, CtlH[I]);
      Exit;
    End;
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  { icones des fonctionnalites }
  For I := 0 To NTile - 1 Do
    If (X >= TileX[I]) And (X < TileX[I] + TileW) And (Y >= TileY[I]) And (Y < TileY[I] + TileH) Then
    Begin
      If TileK[I] >= nkFirstCat Then GoNode(TileK[I], SelSite) Else GoNode(TileK[I], -1);
      Exit;
    End;
  Cols := 0;
End;

Function Key(Mp1, Mp2 : LongInt) : Boolean;
Var Fl, Vk, Ch_, F, K, I : LongInt;
Begin
  Key := False;
  Fl := Lo16(Mp1);
  If (Fl And KC_KEYUP) <> 0 Then Exit;
  Vk := Hi16(Mp2); Ch_ := Lo16(Mp2);
  If ((Fl And KC_VIRTUALKEY) <> 0) And ((Vk = VK_TAB) Or (Vk = VK_BACKTAB)) Then
  Begin
    { Tab : arbre -> controles du panneau -> arbre }
    F := WinQueryFocus(HWND_DESKTOP);
    K := -1;
    For I := 0 To NCtl - 1 Do If CtlH[I] = F Then K := I;
    If (Vk = VK_BACKTAB) Or ((Fl And KC_SHIFT) <> 0) Then
    Begin
      If K < 0 Then K := NCtl - 1 Else Dec(K);
    End
    Else Inc(K);
    If (K < 0) Or (K >= NCtl) Then Dummy := WinSetFocus(HWND_DESKTOP, Client)
    Else Dummy := WinSetFocus(HWND_DESKTOP, CtlH[K]);
    Key := True;
    Exit;
  End;
  { touches venues d'un controle du panneau : pas pour l'arbre }
  If WinQueryFocus(HWND_DESKTOP) <> Client Then Exit;
  If (Fl And KC_VIRTUALKEY) <> 0 Then
  Begin
    Key := True;
    Case Vk Of
      VK_UP : Select(MaxI(0, NSel - 1));
      VK_DOWN : Select(MinI(NNode - 1, NSel + 1));
      VK_HOME : Select(0);
      VK_END : Select(NNode - 1);
      VK_PAGEUP : Select(MaxI(0, NSel - TreeRows));
      VK_PAGEDOWN : Select(MinI(NNode - 1, NSel + TreeRows));
      VK_RIGHT : If NKids[NSel] And Not NodeOpen(NSel) Then ToggleNode(NSel)
                 Else If NSel + 1 < NNode Then Select(NSel + 1);
      VK_LEFT :
        If NKids[NSel] And NodeOpen(NSel) Then ToggleNode(NSel)
        Else
        Begin
          Vk := NSel;
          While (Vk > 0) And (NLev[Vk] >= NLev[NSel]) Do Dec(Vk);
          Select(Vk);
        End;
      VK_ENTER, VK_NEWLINE : If NKids[NSel] Then ToggleNode(NSel);
      VK_F5 : DoCmd(cmRefresh);
      VK_F1 : DoCmd(cmHelp);
      VK_DELETE : If SelKind = nkSite Then DoCmd(cmDelSite);
    Else
      Key := False;
    End;
    Exit;
  End;
  If (Fl And KC_CHAR) <> 0 Then
  Begin
    If (Ch_ = Ord('+')) And NKids[NSel] And Not NodeOpen(NSel) Then
    Begin
      ToggleNode(NSel); Key := True;
    End
    Else If (Ch_ = Ord('-')) And NKids[NSel] And NodeOpen(NSel) Then
    Begin
      ToggleNode(NSel); Key := True;
    End
    Else If ((Fl And KC_CTRL) <> 0) And ((Ch_ = 19) Or (Ch_ = Ord('s')) Or (Ch_ = Ord('S'))) Then
    Begin
      DoCmd(cmSave); Key := True;
    End;
  End;
End;

Procedure Tick;
Var Was : Boolean; R : LongInt;
Begin
  Was := LastAlive;
  LastAlive := Alive;
  If LastAlive Then R := Shm^.Requests Else R := LastReqCnt;
  If R < LastReqCnt Then LastReqCnt := R;
  ReqHist[HistN] := R - LastReqCnt;
  If LastAlive Then ConnHist[HistN] := Shm^.CurConn Else ConnHist[HistN] := 0;
  LastReqCnt := R;
  HistN := (HistN + 1) Mod 60;
  If Was <> LastAlive Then
  Begin
    If LastAlive Then StatusMsg := 'Serveur Web en marche (PID ' + IStr(Shm^.Pid) + ').'
    Else StatusMsg := 'Serveur Web arr'#136't'#130'.';
    BuildPanel;
    Exit;
  End;
  InvalBand(0, 0, CW, TbH);
  InvalBand(0, CH - SbH, CW, CH);
  If SelKind = nkMonitor Then InvalBand(PanX0, PanY0, PanX1 + 1, PanY1 + 1)
  Else If SelKind = nkServer Then InvalBand(PanX0, PanY0, PanX1 + 1, PanY0 + 22);
End;

Function ClientProc(H, Msg_, Mp1, Mp2 : LongInt) : LongInt;
Var Rc : Array[0..3] Of LongInt;
Begin
  ClientProc := 0;
  Case Msg_ Of
    WM_SIZE :
      Begin
        Dummy := WinQueryWindowRect(H, LongInt(@Rc));
        CW := Rc[2]; CH := Rc[3];
        Layout;
      End;
    WM_PAINT : Paint(H);
    WM_BUTTON1DOWN :
      Begin
        Click(S16(Mp1), CH - 1 - S16(Mp1 Shr 16), False);
        ClientProc := 1;
      End;
    WM_BUTTON1DBLCLK :
      Begin
        Click(S16(Mp1), CH - 1 - S16(Mp1 Shr 16), True);
        ClientProc := 1;
      End;
    WM_BUTTON2DOWN :
      Begin
        RightClick(S16(Mp1), CH - 1 - S16(Mp1 Shr 16));
        ClientProc := 1;
      End;
    WM_CHAR :
      If Key(Mp1, Mp2) Then ClientProc := 1
      Else ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
    WM_COMMAND :
      If Lo16(Mp1) = idCtl + 1 Then
      Begin
        { case "Demarrer avec OS/2" (accueil du serveur) }
        If SelKind = nkServer Then ToggleAutoStart(Checked(idCtl + 1));
      End
      Else DoCmd(Lo16(Mp1));
    WM_CONTROL :
      Begin
        If (Lo16(Mp1) = idCtl + 1) And (SelKind = nkServer) And (Hi16(Mp1) = 1) Then
          ToggleAutoStart(Checked(idCtl + 1))
        Else If (Lo16(Mp1) = idList) And (Hi16(Mp1) = LN_ENTER) Then DoCmd(cmEdit);
      End;
    WM_TIMER : Tick;
    WM_CLOSE :
      Begin
        If Dirty Then
          If Ask('Enregistrer les modifications de la configuration ?') Then SaveCfg;
        Dummy := WinPostMsg(H, $002A, 0, 0);
      End;
  Else
    ClientProc := WinDefWindowProc(H, Msg_, Mp1, Mp2);
  End;
End;

{ ==================================================================== }
{ Menus                                                                 }
{ ==================================================================== }

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
  MenuT[H + 4] := Count And 255; MenuT[H + 5] := (Count Shr 8) And 255;
End;

Procedure MnItem(Style, Attr, Id : LongInt; S : String);
Var K : LongInt;
Begin
  MW(Style); MW(Attr); MW(Id);
  If (Style And MIS_SEPARATOR) = 0 Then
  Begin
    For K := 1 To Length(S) Do MB(Ord(S[K]));
    MB(0);
  End;
End;

Procedure Sep;
Begin
  MnItem(MIS_SEPARATOR, 0, 0, '');
End;

Procedure BuildMenu;
Var H0, H1, A : LongInt;
Begin
  MenuLen := 0;
  H0 := MenuOpen;
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 90, '~Fichier');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmSave, '~Enregistrer la configuration' + #9 + 'Ctrl+S');
  MnItem(MIS_TEXT, 0, cmReloadCfg, '~Relire la configuration');
  Sep;
  MnItem(MIS_TEXT, 0, cmQuit, '~Quitter');
  MenuClose(H1, 4);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 91, '~Action');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmStart, '~D'#130'marrer le serveur');
  MnItem(MIS_TEXT, 0, cmStop, '~Arr'#136'ter le serveur');
  MnItem(MIS_TEXT, 0, cmRestart, '~Red'#130'marrer le serveur');
  Sep;
  MnItem(MIS_TEXT, 0, cmAddSite, 'Ajouter un ~site Web...');
  MnItem(MIS_TEXT, 0, cmSiteOn, 'D'#130'~marrer le site');
  MnItem(MIS_TEXT, 0, cmSiteOff, 'Arr'#136'~ter le site');
  MnItem(MIS_TEXT, 0, cmDelSite, 'S~upprimer le site');
  Sep;
  MnItem(MIS_TEXT, 0, cmBrowse, '~Parcourir le site');
  MnItem(MIS_TEXT, 0, cmSiteProps, 'Param'#138'tres de ~base...');
  MenuClose(H1, 11);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 92, 'A~ffichage');
  H1 := MenuOpen;
  If ShowAct Then A := MIA_CHECKED Else A := 0;
  MnItem(MIS_TEXT, A, cmActions, 'Volet ~Actions');
  Sep;
  MnItem(MIS_TEXT, 0, cmExpand, '~D'#130'velopper tout');
  MnItem(MIS_TEXT, 0, cmCollapse, '~R'#130'duire tout');
  Sep;
  MnItem(MIS_TEXT, 0, cmRefresh, 'A~ctualiser' + #9 + 'F5');
  MenuClose(H1, 6);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 93, '~Outils');
  H1 := MenuOpen;
  If AutoStartOn Then A := MIA_CHECKED Else A := 0;
  MnItem(MIS_TEXT, A, cmAutoStart, 'D'#130'marrer le serveur Web avec ~OS/2');
  Sep;
  MnItem(MIS_TEXT, 0, cmCert, 'Cr'#130'er un ~certificat auto-sign'#130'...');
  MnItem(MIS_TEXT, 0, cmOpenLogs, 'Explorer les ~journaux');
  MnItem(MIS_TEXT, 0, cmOpenRoot, 'Explorer le dossier du ~site');
  MenuClose(H1, 5);
  MnItem(MIS_TEXT Or MIS_SUBMENU, 0, 94, '~?');
  H1 := MenuOpen;
  MnItem(MIS_TEXT, 0, cmHelp, '~Aide' + #9 + 'F1');
  Sep;
  MnItem(MIS_TEXT, 0, cmAbout, '~A propos du Serveur Web...');
  MenuClose(H1, 3);
  MenuClose(H0, 5);
  MenuHw := WinCreateMenu(Frame, LongInt(@MenuT));
End;

{ ==================================================================== }
{ Console                                                               }
{ ==================================================================== }

Procedure Console;
Var Fl, Sw, Sh, Fw, Fh, I : LongInt;
Begin
  PickDirs;
  CfgLoad;
  Dummy := Ord(StatOpen(False));
  MyIpAddr := 0;
  Dummy := Ord(PNetInit);
  LastAlive := Alive;
  If LastAlive Then LastReqCnt := Shm^.Requests Else LastReqCnt := 0;
  For I := 0 To 59 Do
  Begin
    ReqHist[I] := 0; ConnHist[I] := 0;
  End;
  HistN := 0;
  ExpServer := True; ExpSites := True;
  For I := 0 To MaxSites - 1 Do ExpSite[I] := False;
  ExpSite[0] := Sites[0].Used;
  ShowAct := True;
  SelKind := nkServer; SelSite := -1;
  StatusMsg := 'Pr'#136't.';
  Dirty := False;
  NCtl := 0;
  Hab := WinInitialize(0);
  Hmq := WinCreateMsgQueue(Hab, 0);
  Dummy := WinRegisterClass(Hab, Z('WEBSRVCONSOLE'), LongInt(@ClientProc), 0, 0);
  Fl := FCF_TITLEBAR Or FCF_SYSMENU Or FCF_SIZEBORDER Or FCF_MINBUTTON Or FCF_MAXBUTTON Or FCF_TASKLIST;
  Client := 0;
  Frame := WinCreateStdWindow(HWND_DESKTOP, 0, LongInt(@Fl), Z('WEBSRVCONSOLE'),
                              Z2('Serveur Web - Gestionnaire des services Internet'), 0, 0, 0, LongInt(@Client));
  BuildMenu;
  Sw := WinQuerySysValue(HWND_DESKTOP, 20); Sh := WinQuerySysValue(HWND_DESKTOP, 21);
  Fw := MinI(Sw, 640); Fh := MinI(Sh - 30, 450);
  If Sw >= 1000 Then
  Begin
    Fw := 960; Fh := MinI(Sh - 60, 620);
  End
  Else If Sw >= 800 Then
  Begin
    Fw := 790; Fh := MinI(Sh - 40, 540);
  End;
  CW := Fw - 8; CH := Fh - 40;
  Dummy := WinSetWindowPos(Frame, HWND_TOP, MaxI(0, (Sw - Fw) Div 2), MaxI(0, (Sh - Fh) Div 2), Fw, Fh,
                           SWP_SIZE Or SWP_MOVE Or SWP_ZORDER Or SWP_SHOW Or SWP_ACTIVATE);
  BuildTree;
  Select(0);
  Dummy := WinStartTimer(Hab, Client, 1, 1000);
  Dummy := WinSetActiveWindow(HWND_DESKTOP, Frame);
  Dummy := WinSetFocus(HWND_DESKTOP, Client);
  While WinGetMsg(Hab, LongInt(@GQmsg), 0, 0, 0) <> 0 Do Dummy := WinDispatchMsg(Hab, LongInt(@GQmsg));
  Dummy := WinDestroyWindow(Frame);
End;

{$ENDIF}
{ ==================================================================== }
{ Programme principal                                                   }
{ ==================================================================== }

Var
  Arg1 : String;
  T0 : LongInt;

{ lancer le service detache (WEBSRV /SERVICE) ; rend un message }
Function StartService : String;
{$IFDEF OS2PC}
Var Args : Array[0..299] Of Byte; Res : Array[0..1] Of LongInt; Fail : Array[0..259] Of Byte; P, K, R : LongInt;
    Exe, Prm : String;
Begin
  Exe := ParamStr(0);
  If Exe = '' Then Exe := 'WEBSRV.EXE';
  Prm := '/SERVICE';
  P := 0;
  For K := 1 To Length(Exe) Do
  Begin
    Args[P] := Ord(Exe[K]); Inc(P);
  End;
  Args[P] := 0; Inc(P);
  For K := 1 To Length(Prm) Do
  Begin
    Args[P] := Ord(Prm[K]); Inc(P);
  End;
  Args[P] := 0; Args[P + 1] := 0;
  R := DosExecPgm(LongInt(@Fail), 260, 4, LongInt(@Args), 0, LongInt(@Res), Z(Exe));
  If R = 0 Then StartService := 'Serveur Web d'#130'marr'#130' (PID ' + IStr(Res[0]) + ').'
  Else StartService := 'Impossible de d'#130'marrer le serveur Web (erreur ' + IStr(R) + ').';
End;
{$ELSE}
Begin
  StartService := 'non disponible';
End;
{$ENDIF}

{ WEBSRV /PSP page [requete] : executer une page PSP ou ASP sans le reseau
  (essais) ; le resultat va sur la sortie standard }
Procedure RunPageCli(Path, Q, OutF : String);
Var K, N : LongInt; L : String; Asp : Boolean; Ob : TBuf;
Begin
  ServiceMode := False; Quiet := True;
  PickDirs;
  CfgLoad;
  Dummy := Ord(StatOpen(False));
  GetMem(Pool, RxCap + ReqCap + TxCap);
  FillChar(Conns[0], SizeOf(TConn), 0);
  With Conns[0] Do
  Begin
    Rx := @Pool^[0]; Req := @Pool^[RxCap]; Tx := @Pool^[RxCap + ReqCap];
    L := 'GET /' + Path;
    If Q <> '' Then L := L + '?' + Q;
    L := L + ' HTTP/1.0' + Crlf + 'Host: localhost' + Crlf + Crlf;
    Move(L[1], Req^[0], Length(L));
    ReqLen := Length(L); HdrEnd := ReqLen;
    Method := 'GET'; Uri := '/' + Path; Query := Q; Ver := 'HTTP/1.0'; Host := 'localhost';
    State := csWaitVm; Site := 0; BFile := -1; LocalIp := $7F000001; PeerIp := $7F000001; LocalPort := 80;
  End;
  K := Length(Path);
  While (K > 0) And (Path[K] <> '') And (Path[K] <> '/') Do Dec(K);
  If K > 0 Then Sites[0].Root := Copy(Path, 1, K - 1)
  Else Sites[0].Root := '.';
  Asp := UpStr(Copy(Path, Length(Path) - 3, 4)) = '.ASP';
  ScriptPath[0] := Path; ScriptAsp[0] := Asp;
  ScriptPhp[0] := UpStr(Copy(Path, Length(Path) - 3, 4)) = '.PHP';
  VmStart(0);
  While VmOn Do
  Begin
    VmRun(100000);
    If VmWait Then PSleep(1);
  End;
  If OutF <> '' Then
  Begin
    { /PSPOUT : resultat dans un fichier (Web Developer) }
    BufInit(Ob);
    If VmErr <> '' Then BufAdd(Ob, '*** erreur ligne ' + IStr(VmErrLine) + ' : ' + VmErr + Crlf)
    Else If Conns[0].State <> csVm Then BufAdd(Ob, '*** compilation : ' + CErr + ' (ligne ' + IStr(CErrLine) + ')' + Crlf);
    If VmOut.Len > 0 Then BufAddB(Ob, VmOut.P, VmOut.Len);
    Dummy := Ord(WriteFileBuf(OutF, Ob.P, Ob.Len));
    BufFree(Ob);
    Exit;
  End;
  If VmErr <> '' Then WriteLn('*** erreur ligne ', VmErrLine, ' : ', VmErr)
  Else If Conns[0].State <> csVm Then WriteLn('*** compilation : ', CErr, ' (ligne ', CErrLine, ')');
  For K := 0 To VmOut.Len - 1 Do Write(Chr(VmOut.P^[K]));
  WriteLn;
End;

BEGIN
  Quiet := False;
  ServiceMode := False;
  Arg1 := '';
  If ParamCount > 0 Then Arg1 := UpStr(ParamStr(1));
  If (Arg1 = '/PSP') And (ParamCount >= 2) Then
  Begin
    VmInit;
    If ParamCount >= 3 Then RunPageCli(ParamStr(2), ParamStr(3), '') Else RunPageCli(ParamStr(2), '', '');
  End
  Else If (Arg1 = '/PSPOUT') And (ParamCount >= 3) Then
  Begin
    VmInit;
    If ParamCount >= 4 Then RunPageCli(ParamStr(3), ParamStr(4), ParamStr(2))
    Else RunPageCli(ParamStr(3), '', ParamStr(2));
  End
  Else If Arg1 = '/DBTEST' Then DbSelfTest
  Else If (Arg1 = '/SERVICE') Or (Arg1 = '-SERVICE') Then
  Begin
    VmInit;
    ServiceMain;
  End
  Else If Arg1 = '/START' Then
  Begin
    PickDirs;
    Dummy := Ord(StatOpen(False));
    If ServiceAlive Then WriteLn('Le serveur Web d''OS/2-0 est deja en marche.')
    Else
    Begin
      WriteLn(StartService);
      { attendre qu'il ecoute (reseau, certificat) : 20 s au plus }
      T0 := PTicks;
      Repeat
        PSleep(200);
        If Shm = @StatLocal Then Dummy := Ord(StatOpen(False));
      Until ServiceAlive Or (PTicks - T0 > 20000);
      If ServiceAlive Then WriteLn('Le serveur Web est en marche.')
      Else WriteLn('Le serveur Web ne repond pas encore (voir WEBSRV.LOG).');
    End;
  End
  Else If (Arg1 = '/STOP') Or (Arg1 = '/STATUS') Then
  Begin
    PickDirs;
    Dummy := Ord(StatOpen(False));
    If Not ServiceAlive Then WriteLn('Le serveur Web d''OS/2-0 n''est pas en marche.')
    Else If Arg1 = '/STATUS' Then
    Begin
      WriteLn('Serveur Web d''OS/2-0 : en marche (PID ', Shm^.Pid, ')');
      WriteLn('  requetes : ', Shm^.Requests, ', connexions : ', Shm^.CurConn, ' (max. ', Shm^.MaxConn, ')');
      WriteLn('  octets envoyes : ', Shm^.BytesOut, ', recus : ', Shm^.BytesIn, ', erreurs : ', Shm^.Errors);
      WriteLn('  pages PSP/ASP executees : ', Shm^.PspRuns, ' (erreurs : ', Shm^.PspErr, ')');
    End
    Else
    Begin
      Shm^.Cmd := cmdStop;
      Inc(Shm^.CmdSeq);
      WriteLn('Arret du serveur Web demande.');
    End;
  End
  Else
  Begin
    {$IFDEF OS2PC}
    Console;
    {$ELSE}
    VmInit;
    ServiceMain;
    {$ENDIF}
  End;
END.
