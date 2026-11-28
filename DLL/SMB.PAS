{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Pilote de systeme de fichiers installable distant SMB.IFS
                de OS/2-0 : lecteurs reseau (partages Windows et Samba)
                par SMB 2 et NTLMv2.
}

Library SMB;

{$R-,S-,I-}
{$IMAGEBASE $00F00000}

{ Compilation : OS2PC SMB.PAS SMB.IFS   (produit SMB.IFS)

  SMB.IFS est un FSD distant (FSA_REMOTE) d'OS/2, comme le redirecteur
  NETWKSTA du Requester de LAN Server : il n'a pas de volume sur un disque
  mais des unites ATTACHEES par DosFSAttach (FS_ATTACH) :

    DosFSAttach("Z:", "SMB", "\\serveur\partage" 0 "utilisateur" 0
                "mot de passe" 0, cb, FS_ATTACH)

  Le noyau le charge a la demande (C:\SMB.IFS) au premier DosFSAttach.
  Le client vient de celui de Pasdows 95 (VMM32, partie 16c) :
    - SMB 2.0.2 et 2.1 sur TCP 445 (Windows Server 2008 a 2022, Samba ;
      SMB1 est desactive depuis Windows Server 2019) ;
    - authentification NTLMv2 dans SPNEGO (comptes locaux du serveur ou
      DOMAINE\utilisateur), session anonyme sans nom d'utilisateur ;
    - signature HMAC-SHA256 des requetes quand le serveur l'exige ;
    - serveur par son nom (DNS de TCPIP32) ou son adresse IP ;
    - reconnexion automatique (le serveur coupe les sessions inactives) :
      le hachage NT du mot de passe est garde, jamais le mot de passe ;
      "#" suivi de 32 chiffres hexadecimaux donne ce hachage directement
      (connexions permanentes de l'Explorateur OS2-Zero).
  Les points d'entree FS_* sont ceux d'un FSD d'OS/2 (convention _System) ;
  le noyau les appelle avec le numero d'unite comme hVPB (3 = D:, 25 = Z:).
  Les sockets viennent de TCPIP32.DLL. SMBLASTERROR rend le texte de la
  derniere erreur (boites de l'Explorateur). SMBSTATUS decrit la connexion
  en cours (etape, durees, requetes et octets SMB) et SMBCANCEL l'abandonne
  (soabort de TCPIP32 : connect, recv, DNS et ARP s'arretent aussitot) :
  boite de progression de l'Explorateur, qui attache l'unite dans un fil. }

Const
  FS_NAME      = 'SMB';
  FS_ATTRIBUTE = 1;                   { FSA_REMOTE }

  NO_ERROR = 0; ERROR_INVALID_FUNCTION = 1; ERROR_FILE_NOT_FOUND = 2; ERROR_PATH_NOT_FOUND = 3;
  ERROR_TOO_MANY_OPEN_FILES = 4; ERROR_ACCESS_DENIED = 5; ERROR_INVALID_HANDLE = 6;
  ERROR_NOT_ENOUGH_MEMORY = 8; ERROR_INVALID_DRIVE = 15; ERROR_CURRENT_DIRECTORY = 16;
  ERROR_NO_MORE_FILES = 18; ERROR_NOT_READY = 21; ERROR_SHARING_VIOLATION = 32;
  ERROR_BAD_NETPATH = 53; ERROR_NETWORK_BUSY = 54; ERROR_UNEXP_NET_ERR = 59;
  ERROR_NETNAME_DELETED = 64; ERROR_NETWORK_ACCESS_DENIED = 65; ERROR_BAD_NET_NAME = 67;
  ERROR_FILE_EXISTS = 80; ERROR_INVALID_PASSWORD = 86; ERROR_INVALID_PARAMETER = 87;
  ERROR_INTERRUPT = 95;
  ERROR_DISK_FULL = 112; ERROR_BUFFER_OVERFLOW = 111; ERROR_INVALID_NAME = 123;
  ERROR_INVALID_LEVEL = 124; ERROR_DIR_NOT_EMPTY = 145; ERROR_ALREADY_EXISTS = 183;
  ERROR_OPEN_FAILED = 110; ERROR_NOT_SUPPORTED = 50; ERROR_ALREADY_ASSIGNED = 85;

  MaxNd = 26;                          { unites A: a Z: }
  MaxOpen = 64;
  MaxFind = 16;
  SmbBufSz = 69632;                    { 64 Ko de donnees + en-tetes }
  SmbChunk = 61440;                    { lecture et ecriture par requete }
  FindCap = 262144;                    { liste d'un dossier (une recherche) }
  SFD_MAGIC = $534D4246;               { 'FBMS' }
  { NTLMSSP_NEGOTIATE : UNICODE, REQUEST_TARGET, SIGN, NTLM, ALWAYS_SIGN,
    EXTENDED_SESSIONSECURITY, TARGET_INFO, 128, 56 }
  NtlmFlags = LongInt($A0888215);
  Md5K : Array[0..63] Of LongInt = (
    $D76AA478, $E8C7B756, $242070DB, $C1BDCEEE, $F57C0FAF, $4787C62A,
    $A8304613, $FD469501, $698098D8, $8B44F7AF, $FFFF5BB1, $895CD7BE,
    $6B901122, $FD987193, $A679438E, $49B40821, $F61E2562, $C040B340,
    $265E5A51, $E9B6C7AA, $D62F105D, $02441453, $D8A1E681, $E7D3FBC8,
    $21E1CDE6, $C33707D6, $F4D50D87, $455A14ED, $A9E3E905, $FCEFA3F8,
    $676F02D9, $8D2A4C8A, $FFFA3942, $8771F681, $6D9D6122, $FDE5380C,
    $A4BEEA44, $4BDECFA9, $F6BB4B60, $BEBFBC70, $289B7EC6, $EAA127FA,
    $D4EF3085, $04881D05, $D9D4D039, $E6DB99E5, $1FA27CF8, $C4AC5665,
    $F4292244, $432AFF97, $AB9423A7, $FC93A039, $655B59C3, $8F0CCC92,
    $FFEFF47D, $85845DD1, $6FA87E4F, $FE2CE6E0, $A3014314, $4E0811A1,
    $F7537E82, $BD3AF235, $2AD7D2BB, $EB86D391);
  Md5S : Array[0..15] Of Byte = (7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21);
  Md4S : Array[0..11] Of Byte = (3, 7, 11, 19, 3, 5, 9, 13, 3, 9, 11, 15);
  Md4K2 : Array[0..15] Of Byte = (0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15);
  Md4K3 : Array[0..15] Of Byte = (0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15);
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
  { SPNEGO : OID de SPNEGO puis mechTypes (NTLMSSP) }
  SpnOid : Array[0..7] Of Byte = ($06, $06, $2B, $06, $01, $05, $05, $02);
  SpnMech : Array[0..15] Of Byte = ($A0, $0E, $30, $0C, $06, $0A, $2B, $06, $01, $04, $01, $82, $37,
    $02, $02, $0A);

Type
  TBA = Array[0..$7FFFFFF] Of Byte;
  PBA = ^TBA;
  TMd = Record
    H : Array[0..3] Of LongInt;
    B : Array[0..63] Of Byte;
    N, Len : LongInt;
    Four : Boolean;                    { MD4 (sinon MD5) }
  End;
  TNetDrv = Record
    Used, Conn, Sign : Boolean;
    Sock, Tree, SessLo, SessHi, Mid, MaxRd, MaxWr : LongInt;
    FailT : LongInt;                   { dernier echec de connexion (KTicks) }
    SpcT, CSpc, CTot, CFree, CBps : LongInt;   { espace (FS_FSINFO), 5 s }
    Server, Share, User, Dom : String[63];
  End;
  TOpen = Record
    Used, Wr : Boolean;
    Drv, Size, Attr : LongInt;
    Fid : Array[0..3] Of LongInt;
  End;
  TFind = Record
    Used : Boolean;
    Drv, Buf, N, Pos, Attr : LongInt;
    Mask : String;
  End;

{ acces a la memoire par adresse (Mem[] n'ecrit pas hors du noyau) }
Type
  PB1 = ^Byte; PW2 = ^Word; PL4 = ^LongInt;

Function RB(A : LongInt) : LongInt;
Var Q : PB1;
Begin
  Q := Pointer(A);
  RB := Q^;
End;

Function RW(A : LongInt) : LongInt;
Var Q : PW2;
Begin
  Q := Pointer(A);
  RW := Q^;
End;

Function RL(A : LongInt) : LongInt;
Var Q : PL4;
Begin
  Q := Pointer(A);
  RL := Q^;
End;

Procedure WB(A, V : LongInt);
Var Q : PB1;
Begin
  Q := Pointer(A);
  Q^ := V And 255;
End;

Procedure WW(A, V : LongInt);
Var Q : PW2;
Begin
  Q := Pointer(A);
  Q^ := V And $FFFF;
End;

Procedure WL(A, V : LongInt);
Var Q : PL4;
Begin
  Q := Pointer(A);
  Q^ := V;
End;

Function SkInit : LongInt; External 'TCPIP32' Name 'sock_init';
Function SkSocket(Dom, Typ, Proto : LongInt) : LongInt; External 'TCPIP32' Name 'socket';
Function SkConnect(S, PAddr, Len : LongInt) : LongInt; External 'TCPIP32' Name 'connect';
Function SkSend(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function SkRecv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function SkClose(S : LongInt) : LongInt; External 'TCPIP32' Name 'soclose';
Function SkSystem(S : LongInt) : LongInt; External 'TCPIP32' Name 'sosystem';
Function SkHost(PName : LongInt) : LongInt; External 'TCPIP32' Name 'gethostbyname';
Function SkAbort(S : LongInt) : LongInt; External 'TCPIP32' Name 'soabort';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosAllocMem(PPb, Cb, Flag : LongInt) : LongInt; External 'DOSCALLS';
Function DosFreeMem(Pb : LongInt) : LongInt; External 'DOSCALLS';
Function KLocalTime(P : LongInt) : LongInt; External 'DOSCALLS' Name 'GetLocalTime';

Var
  Nd : Array[0..MaxNd - 1] Of TNetDrv;
  Keys : Array[0..MaxNd * 32 - 1] Of Byte;  { 32 octets par unite : hachage NT, cle de session }
  NdKeys : LongInt;
  Opens : Array[0..MaxOpen - 1] Of TOpen;
  Finds : Array[0..MaxFind - 1] Of TFind;
  TxBuf, RxBuf, SaveBuf : Array[0..SmbBufSz + 15] Of Byte;
  WkBuf : Array[0..16383] Of Byte;
  SmbTx, SmbRx, SmbWk, SmbSave : LongInt;
  SmbBusy, SmbInConn, InitDone : Boolean;
  SmbSt : LongInt;                     { dernier statut NT }
  LastMsg : String;                    { texte de la derniere erreur }
  { connexion en cours (SMBSTATUS) : etape 1 carte reseau, 2 nom du
    serveur, 3 TCP 445, 4 NEGOTIATE, 5 SESSION_SETUP (NTLMSSP NEGOTIATE),
    6 authentification NTLMv2, 7 TREE_CONNECT, 8 terminee }
  CnStep, CnBusy, CnT0, CnStepT, CnRes, CnIp, CnSock : LongInt;
  CnTxN, CnRxN, CnTxB, CnRxB : LongInt;
  CnMs : Array[0..9] Of LongInt;
  CnAbort : Boolean;
  ScFid : Array[0..3] Of LongInt;      { reponse de CREATE }
  ScAttr, ScSize, ScTime, ScAct, ScCLo, ScCHi : LongInt;
  ShH : Array[0..7] Of LongInt;        { SHA-256 }
  ShB : Array[0..63] Of Byte;
  ShN, ShT : LongInt;
  RndState : LongInt;
  NameZ : Array[0..299] Of Byte;

{ ==================================================================== }
{ Memoire et chaines                                                    }
{ ==================================================================== }

Procedure MoveMem(S, D, N : LongInt);
Begin
  If N > 0 Then Move(PBA(S)^[0], PBA(D)^[0], N);
End;

Procedure FillMem(D, N, V : LongInt);
Begin
  If N > 0 Then FillChar(PBA(D)^[0], N, V);
End;

Function MinL(A, B : LongInt) : LongInt;
Begin
  If A < B Then MinL := A Else MinL := B;
End;

Function UpStr(S : String) : String;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do
    If (S[I] >= 'a') And (S[I] <= 'z') Then S[I] := Chr(Ord(S[I]) - 32);
  UpStr := S;
End;

Function HexDig(V, N : LongInt) : String;
Const H : String[16] = '0123456789ABCDEF';
Var S : String; I : LongInt;
Begin
  S := '';
  For I := 1 To N Do
  Begin
    S := H[(V And 15) + 1] + S;
    V := V Shr 4;
  End;
  HexDig := S;
End;

Function GetZ(A : LongInt) : String;
Var S : String;
Begin
  S := '';
  If A <> 0 Then
    While (RB(A) <> 0) And (Length(S) < 255) Do
    Begin
      S := S + Chr(RB(A));
      Inc(A);
    End;
  GetZ := S;
End;

Procedure PutZ(A : LongInt; S : String; Cb : LongInt);
Var I : LongInt;
Begin
  If Cb <= 0 Then Exit;
  If Length(S) > Cb - 1 Then S := Copy(S, 1, Cb - 1);
  For I := 1 To Length(S) Do WB(A + I - 1, Ord(S[I]));
  WB(A + Length(S), 0);
End;

{ octets pseudo-aleatoires (defi du client, sel de NEGOTIATE) }
Procedure Random8(A, N : LongInt);
Var I : LongInt;
Begin
  If RndState = 0 Then RndState := KTicks Or 1;
  For I := 0 To N - 1 Do
  Begin
    RndState := RndState Xor (RndState Shl 13);
    RndState := RndState Xor ((RndState Shr 17) And $7FFF);
    RndState := RndState Xor (RndState Shl 5);
    RndState := RndState + KTicks;
    WB(A + I, (RndState Shr 8) And 255);
  End;
End;

{ ==================================================================== }
{ MD4, MD5 (RFC 1320 et 1321), HMAC-MD5, SHA-256, HMAC-SHA256          }
{ ==================================================================== }

Function MdRol(X, N : LongInt) : LongInt;
Begin
  MdRol := (X Shl N) Or ((X Shr (32 - N)) And ((1 Shl N) - 1));
End;

Procedure MdBlock(Var C : TMd);
Var M : Array[0..15] Of LongInt; X : Array[0..3] Of LongInt;
    I, T, A, B, Cc, D, F, G, S : LongInt;
Begin
  For I := 0 To 15 Do
    M[I] := C.B[I * 4] Or (C.B[I * 4 + 1] Shl 8) Or (C.B[I * 4 + 2] Shl 16) Or (C.B[I * 4 + 3] Shl 24);
  For I := 0 To 3 Do X[I] := C.H[I];
  If C.Four Then
    For I := 0 To 47 Do
    Begin
      T := (4 - (I And 3)) And 3;
      A := X[T]; B := X[(T + 1) And 3]; Cc := X[(T + 2) And 3]; D := X[(T + 3) And 3];
      If I < 16 Then
      Begin
        F := (B And Cc) Or ((Not B) And D); G := I; S := Md4S[I And 3];
      End
      Else If I < 32 Then
      Begin
        F := (B And Cc) Or (B And D) Or (Cc And D);
        F := F + $5A827999; G := Md4K2[I - 16]; S := Md4S[4 + (I And 3)];
      End
      Else
      Begin
        F := (B Xor Cc Xor D) + LongInt($6ED9EBA1); G := Md4K3[I - 32]; S := Md4S[8 + (I And 3)];
      End;
      X[T] := MdRol(A + F + M[G], S);
    End
  Else
    For I := 0 To 63 Do
    Begin
      T := (4 - (I And 3)) And 3;
      A := X[T]; B := X[(T + 1) And 3]; Cc := X[(T + 2) And 3]; D := X[(T + 3) And 3];
      If I < 16 Then
      Begin
        F := (B And Cc) Or ((Not B) And D); G := I;
      End
      Else If I < 32 Then
      Begin
        F := (D And B) Or ((Not D) And Cc); G := (5 * I + 1) And 15;
      End
      Else If I < 48 Then
      Begin
        F := B Xor Cc Xor D; G := (3 * I + 5) And 15;
      End
      Else
      Begin
        F := Cc Xor (B Or (Not D)); G := (7 * I) And 15;
      End;
      X[T] := B + MdRol(A + F + Md5K[I] + M[G], Md5S[(I Shr 4) * 4 + (I And 3)]);
    End;
  For I := 0 To 3 Do C.H[I] := C.H[I] + X[I];
End;

Procedure MdInit(Var C : TMd; Four : Boolean);
Begin
  C.H[0] := $67452301; C.H[1] := LongInt($EFCDAB89);
  C.H[2] := LongInt($98BADCFE); C.H[3] := $10325476;
  C.N := 0; C.Len := 0; C.Four := Four;
End;

Procedure MdAdd(Var C : TMd; A, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    C.B[C.N] := RB(A + I);
    Inc(C.N);
    If C.N = 64 Then
    Begin
      MdBlock(C);
      C.N := 0;
    End;
  End;
  C.Len := C.Len + N;
End;

Procedure MdDone(Var C : TMd; Out0 : LongInt);
Var Z : Array[0..7] Of Byte; L, I : LongInt;
Begin
  L := C.Len;
  Z[0] := $80;
  MdAdd(C, LongInt(@Z[0]), 1);
  Z[0] := 0;
  While C.N <> 56 Do MdAdd(C, LongInt(@Z[0]), 1);
  Z[0] := (L Shl 3) And 255; Z[1] := (L Shr 5) And 255;
  Z[2] := (L Shr 13) And 255; Z[3] := (L Shr 21) And 255;
  Z[4] := (L Shr 29) And 7; Z[5] := 0; Z[6] := 0; Z[7] := 0;
  MdAdd(C, LongInt(@Z[0]), 8);
  For I := 0 To 3 Do WL(Out0 + I * 4, C.H[I]);
End;

{ HMAC-MD5 (cle de 64 octets au plus) de Msg puis Msg2 }
Procedure HmacMd5(Key, KLen, Msg, MLen, Msg2, M2Len, Out0 : LongInt);
Var C : TMd; Pad : Array[0..63] Of Byte; In0 : Array[0..15] Of Byte; I : LongInt;
Begin
  For I := 0 To 63 Do
    If I < KLen Then Pad[I] := RB(Key + I) Xor $36 Else Pad[I] := $36;
  MdInit(C, False);
  MdAdd(C, LongInt(@Pad[0]), 64);
  MdAdd(C, Msg, MLen);
  If M2Len > 0 Then MdAdd(C, Msg2, M2Len);
  MdDone(C, LongInt(@In0[0]));
  For I := 0 To 63 Do Pad[I] := Pad[I] Xor ($36 Xor $5C);
  MdInit(C, False);
  MdAdd(C, LongInt(@Pad[0]), 64);
  MdAdd(C, LongInt(@In0[0]), 16);
  MdDone(C, Out0);
End;

{ decalage logique a droite (1 <= N <= 31) }
Function Sr(X, N : LongInt) : LongInt;
Begin
  Sr := (X Shr N) And ($7FFFFFFF Shr (N - 1));
End;

Function Ror(X, N : LongInt) : LongInt;
Begin
  Ror := Sr(X, N) Or (X Shl (32 - N));
End;

Procedure ShaInit;
Var I : LongInt;
Begin
  For I := 0 To 7 Do ShH[I] := ShIv[I];
  ShN := 0; ShT := 0;
End;

Procedure ShaBlock;
Var W : Array[0..63] Of LongInt; A, B, Cc, D, E, F, G, H, T1, T2, I, X : LongInt;
Begin
  For I := 0 To 15 Do
    W[I] := (ShB[I * 4] Shl 24) Or (ShB[I * 4 + 1] Shl 16) Or (ShB[I * 4 + 2] Shl 8) Or ShB[I * 4 + 3];
  For I := 16 To 63 Do
  Begin
    X := W[I - 15];
    T1 := Ror(X, 7) Xor Ror(X, 18) Xor Sr(X, 3);
    X := W[I - 2];
    T2 := Ror(X, 17) Xor Ror(X, 19) Xor Sr(X, 10);
    W[I] := W[I - 16] + T1 + W[I - 7] + T2;
  End;
  A := ShH[0]; B := ShH[1]; Cc := ShH[2]; D := ShH[3];
  E := ShH[4]; F := ShH[5]; G := ShH[6]; H := ShH[7];
  For I := 0 To 63 Do
  Begin
    T1 := H + (Ror(E, 6) Xor Ror(E, 11) Xor Ror(E, 25)) + ((E And F) Xor ((Not E) And G)) + ShK[I] + W[I];
    T2 := (Ror(A, 2) Xor Ror(A, 13) Xor Ror(A, 22)) + ((A And B) Xor (A And Cc) Xor (B And Cc));
    H := G; G := F; F := E; E := D + T1;
    D := Cc; Cc := B; B := A; A := T1 + T2;
  End;
  ShH[0] := ShH[0] + A; ShH[1] := ShH[1] + B; ShH[2] := ShH[2] + Cc; ShH[3] := ShH[3] + D;
  ShH[4] := ShH[4] + E; ShH[5] := ShH[5] + F; ShH[6] := ShH[6] + G; ShH[7] := ShH[7] + H;
End;

Procedure ShaByte(V : LongInt);
Begin
  ShB[ShN] := V And 255;
  Inc(ShN);
  If ShN = 64 Then
  Begin
    ShaBlock;
    ShN := 0;
  End;
End;

Procedure ShaUpd(A, N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do ShaByte(RB(A + K));
  ShT := ShT + N;
End;

Procedure ShaFinal(OutA : LongInt);
Var L, I, V : LongInt;
Begin
  L := ShT;
  ShaByte($80);
  While ShN <> 56 Do ShaByte(0);
  ShaByte(0); ShaByte(0); ShaByte(0);
  ShaByte(Sr(L, 29));
  V := L Shl 3;
  ShaByte(Sr(V, 24)); ShaByte(Sr(V, 16)); ShaByte(Sr(V, 8)); ShaByte(V);
  For I := 0 To 7 Do
  Begin
    V := ShH[I];
    WB(OutA + I * 4, Sr(V, 24) And 255); WB(OutA + I * 4 + 1, Sr(V, 16) And 255);
    WB(OutA + I * 4 + 2, Sr(V, 8) And 255); WB(OutA + I * 4 + 3, V And 255);
  End;
End;

{ HMAC-SHA256 (cle de 64 octets au plus) : signature SMB 2 }
Procedure HmacSha(KA, KN, MA, MN, OutA : LongInt);
Var K, In0 : Array[0..63] Of Byte; I : LongInt;
Begin
  For I := 0 To 63 Do
    If I < KN Then K[I] := RB(KA + I) Else K[I] := 0;
  ShaInit;
  For I := 0 To 63 Do ShaByte(K[I] Xor $36);
  ShT := 64;
  ShaUpd(MA, MN);
  ShaFinal(LongInt(@In0[0]));
  ShaInit;
  For I := 0 To 63 Do ShaByte(K[I] Xor $5C);
  ShT := 64;
  ShaUpd(LongInt(@In0[0]), 32);
  ShaFinal(OutA);
End;

{ Chaine (page de codes 850 ramenee a Latin-1) en UTF-16LE en A ; octets ecrits }
Function Uni(A : LongInt; S : String) : LongInt;
Var I : LongInt;
Begin
  For I := 1 To Length(S) Do WW(A + (I - 1) * 2, Ord(S[I]));
  Uni := Length(S) * 2;
End;

{ Hachage NT : MD4 du mot de passe en UTF-16LE }
Procedure NtHash(Pw : String; Out0 : LongInt);
Var C : TMd; B : Array[0..511] Of Byte; N : LongInt;
Begin
  N := Uni(LongInt(@B[0]), Pw);
  MdInit(C, True);
  MdAdd(C, LongInt(@B[0]), N);
  MdDone(C, Out0);
End;

Procedure HexTo(S : String; A, N : LongInt);
Var I, J, V, C : LongInt;
Begin
  For I := 0 To N - 1 Do
  Begin
    V := 0;
    For J := 1 To 2 Do
    Begin
      If I * 2 + J <= Length(S) Then C := Ord(UpCase(S[I * 2 + J])) Else C := 48;
      If C >= 65 Then C := C - 55 Else C := C - 48;
      V := V * 16 + (C And 15);
    End;
    WB(A + I, V);
  End;
End;

Function DaysFrom(Y, M, D : LongInt) : LongInt;
Var A, Era, Yoe, Doy, Doe : LongInt;
Begin
  { algorithme "days from civil" (calendrier gregorien) }
  If M <= 2 Then Y := Y - 1;
  Era := Y Div 400;
  Yoe := Y - Era * 400;
  If M > 2 Then A := M - 3 Else A := M + 9;
  Doy := (153 * A + 2) Div 5 + D - 1;
  Doe := Yoe * 365 + Yoe Div 4 - Yoe Div 100 + Doy;
  DaysFrom := Era * 146097 + Doe - 719468;
End;

Function UnixToDos(T : LongInt) : LongInt;
Var Days, Secs, Z, Era, Doe, Yoe, Y, Doy, Mp, D, M : LongInt;
Begin
  If T < 315532800 Then T := 315532800;     { 1er janvier 1980 }
  Days := T Div 86400;
  Secs := T Mod 86400;
  Z := Days + 719468;
  Era := Z Div 146097;
  Doe := Z - Era * 146097;
  Yoe := (Doe - Doe Div 1460 + Doe Div 36524 - Doe Div 146096) Div 365;
  Y := Yoe + Era * 400;
  Doy := Doe - (365 * Yoe + Yoe Div 4 - Yoe Div 100);
  Mp := (5 * Doy + 2) Div 153;
  D := Doy - (153 * Mp + 2) Div 5 + 1;
  If Mp < 10 Then M := Mp + 3 Else M := Mp - 9;
  If M <= 2 Then Inc(Y);
  If Y > 2107 Then Y := 2107;
  UnixToDos := ((((Y - 1980) Shl 9) Or (M Shl 5) Or D) Shl 16) Or
               (((Secs Div 3600) Shl 11) Or (((Secs Div 60) Mod 60) Shl 5) Or ((Secs Mod 60) Div 2));
End;

Function DosToUnix(T : LongInt) : LongInt;
Var Dt, Tm, Y, M, D : LongInt;
Begin
  Dt := (T Shr 16) And $FFFF;
  Tm := T And $FFFF;
  Y := 1980 + (Dt Shr 9);
  M := (Dt Shr 5) And 15;
  D := Dt And 31;
  If (M < 1) Or (M > 12) Then M := 1;
  If D < 1 Then D := 1;
  DosToUnix := DaysFrom(Y, M, D) * 86400 + (Tm Shr 11) * 3600 + ((Tm Shr 5) And 63) * 60 +
               (Tm And 31) * 2;
End;

{ heure d'un FILETIME (100 ns depuis 1601, UTC) -> date et heure DOS }
Function FtDos(Lo, Hi : LongInt) : LongInt;
Var F, L : Double;
Begin
  If (Lo = 0) And (Hi = 0) Then
  Begin
    FtDos := (1 Shl 21) Or (1 Shl 16);
    Exit;
  End;
  L := Lo;
  If L < 0 Then L := L + 4294967296.0;
  F := (Hi * 4294967296.0 + L) / 10000000.0 - 11644473600.0;
  If F < 315532800.0 Then F := 315532800.0;
  If F > 2147483000.0 Then F := 2147483000.0;
  FtDos := UnixToDos(Trunc(F));
End;

{ date et heure DOS -> FILETIME en A (8 octets) }
Procedure DosFt(T, A : LongInt);
Var F, H : Double; Hi, Lo : LongInt;
Begin
  F := (DosToUnix(T) + 11644473600.0) * 10000000.0;
  H := Int(F / 4294967296.0);
  Hi := Trunc(H);
  F := F - H * 4294967296.0;
  If F >= 2147483648.0 Then Lo := Trunc(F - 4294967296.0) Else Lo := Trunc(F);
  WL(A, Lo); WL(A + 4, Hi);
End;

{ ==================================================================== }
{ Transport (TCP 445, en-tete NetBIOS de 4 octets)                      }
{ ==================================================================== }

Procedure SmbEnter;
Begin
  While SmbBusy Do DosSleep(1);
  SmbBusy := True;
End;

Procedure SmbLeave;
Begin
  SmbBusy := False;
End;

{ etape suivante de la connexion (duree de la precedente) }
Procedure CnSet(K : LongInt);
Begin
  If (CnStep >= 0) And (CnStep <= 9) Then CnMs[CnStep] := KTicks - CnStepT;
  CnStep := K;
  CnStepT := KTicks;
End;

{ Annuler (boite de progression) : vrai, LastMsg en dit la raison }
Function CnCancelled : Boolean;
Begin
  CnCancelled := CnAbort;
  If CnAbort Then LastMsg := 'Connexion annulee par l''utilisateur.';
End;

Procedure NdDrop(N : LongInt);
Begin
  If Nd[N].Sock >= 0 Then SkClose(Nd[N].Sock);
  Nd[N].Sock := -1;
  Nd[N].Conn := False;
End;

Function SmbRecvAll(S, A, N : LongInt) : Boolean;
Var K, R : LongInt;
Begin
  SmbRecvAll := False;
  K := 0;
  While K < N Do
  Begin
    R := SkRecv(S, A + K, N - K, 0);
    If R <= 0 Then Exit;
    K := K + R;
  End;
  SmbRecvAll := True;
End;

{ En-tete SMB2 de la requete Cmd (SmbTx + 4) ; corps mis a zero }
Procedure SmbHdr(N, Cmd : LongInt);
Var A : LongInt;
Begin
  A := SmbTx + 4;
  FillMem(A, 64 + 160, 0);
  WL(A, $424D53FE);
  WW(A + 4, 64);
  WW(A + 12, Cmd);
  WW(A + 14, 64);
  WL(A + 32, $FEFF);
  WL(A + 36, Nd[N].Tree);
  WL(A + 40, Nd[N].SessLo);
  WL(A + 44, Nd[N].SessHi);
End;

Function NdConnect(N : LongInt) : LongInt; Forward;

{ Envoyer la requete (corps de BodyLen octets) ; reponse dans SmbRx (en-tete
  SMB2 en SmbRx, corps en SmbRx + 64) ; statut NT, -1 si la connexion est
  perdue (une fois retablie, la requete est renvoyee une fois) }
Function SmbCall(N, BodyLen : LongInt) : LongInt;
Var A, L, S, Mid, Try0 : LongInt; Sig : Array[0..31] Of Byte; Ok : Boolean;
Begin
  SmbCall := -1; SmbSt := -1;
  A := SmbTx + 4;
  L := 64 + BodyLen;
  For Try0 := 0 To 1 Do
  Begin
    If Not Nd[N].Conn And Not SmbInConn Then
    Begin
      MoveMem(SmbTx, SmbSave, L + 4);
      If NdConnect(N) <> 0 Then Exit;
      MoveMem(SmbSave, SmbTx, L + 4);
      WL(A + 36, Nd[N].Tree);
      WL(A + 40, Nd[N].SessLo);
      WL(A + 44, Nd[N].SessHi);
    End;
    S := Nd[N].Sock;
    Mid := Nd[N].Mid;
    Inc(Nd[N].Mid);
    WL(A + 24, Mid); WL(A + 28, 0);
    WL(A + 16, RL(A + 16) And Not 8);
    FillMem(A + 48, 16, 0);
    If Nd[N].Sign Then
    Begin
      WL(A + 16, RL(A + 16) Or 8);
      HmacSha(NdKeys + N * 32 + 16, 16, A, L, LongInt(@Sig[0]));
      MoveMem(LongInt(@Sig[0]), A + 48, 16);
    End;
    WB(SmbTx, 0);
    WB(SmbTx + 1, (L Shr 16) And 255);
    WB(SmbTx + 2, (L Shr 8) And 255);
    WB(SmbTx + 3, L And 255);
    If CnAbort And SmbInConn Then Exit;
    Ok := SkSend(S, SmbTx, L + 4, 0) = L + 4;
    If Ok Then
    Begin
      Inc(CnTxN);
      CnTxB := CnTxB + L + 4;
    End;
    While Ok Do
    Begin
      Ok := SmbRecvAll(S, SmbRx, 4);
      If Not Ok Then Break;
      L := (RB(SmbRx + 1) Shl 16) Or (RB(SmbRx + 2) Shl 8) Or RB(SmbRx + 3);
      If (L < 64) Or (L > SmbBufSz) Then
      Begin
        Ok := False;
        Break;
      End;
      Ok := SmbRecvAll(S, SmbRx, L);
      If Not Ok Then Break;
      Inc(CnRxN);
      CnRxB := CnRxB + L + 4;
      SmbSt := RL(SmbRx + 8);
      { reponse provisoire (STATUS_PENDING) ou message d'un autre numero
        (rupture d'oplock) : attendre la suivante }
      If (RL(SmbRx + 24) = Mid) And (SmbSt <> $103) Then
      Begin
        SmbCall := SmbSt;
        Exit;
      End;
    End;
    { echec : connexion fermee (le serveur coupe les sessions inactives) ;
      une seconde tentative si elle se retablit }
    NdDrop(N);
    If SmbInConn Then Exit;
    L := 64 + BodyLen;
  End;
End;

{ Statut NT -> erreur OS/2 }
Function SmbErr(St : LongInt) : LongInt;
Begin
  Case St Of
    0 : SmbErr := NO_ERROR;
    -1 : SmbErr := ERROR_UNEXP_NET_ERR;
    LongInt($C0000034), LongInt($C000000F) : SmbErr := ERROR_FILE_NOT_FOUND;
    LongInt($C000003A), LongInt($C0000033), LongInt($C0000039) : SmbErr := ERROR_PATH_NOT_FOUND;
    LongInt($C0000022), LongInt($C0000061), LongInt($C00000BA), LongInt($C0000056),
    LongInt($C0000121) : SmbErr := ERROR_ACCESS_DENIED;
    LongInt($C0000035) : SmbErr := ERROR_FILE_EXISTS;
    LongInt($C0000043), LongInt($C0000054) : SmbErr := ERROR_SHARING_VIOLATION;
    LongInt($C0000101) : SmbErr := ERROR_DIR_NOT_EMPTY;
    LongInt($C000007F) : SmbErr := ERROR_DISK_FULL;
    LongInt($C00000A2) : SmbErr := 19;                 { ERROR_WRITE_PROTECT }
    LongInt($C000006D), LongInt($C000006A), LongInt($C0000064), LongInt($C0000072),
    LongInt($C0000071) : SmbErr := ERROR_INVALID_PASSWORD;
    LongInt($C00000CC) : SmbErr := ERROR_BAD_NET_NAME;
    LongInt($C00000BB) : SmbErr := ERROR_NOT_SUPPORTED;
    LongInt($C0000033) : SmbErr := ERROR_INVALID_NAME;
  Else
    SmbErr := ERROR_UNEXP_NET_ERR;
  End;
End;

{ ==================================================================== }
{ SPNEGO (DER) et NTLMSSP                                               }
{ ==================================================================== }

{ Tag, longueur DER puis N octets de Src en Dst ; octets ecrits }
Function DerWrap(Tag, Src, N, Dst : LongInt) : LongInt;
Var H : LongInt;
Begin
  WB(Dst, Tag);
  If N < 128 Then
  Begin
    WB(Dst + 1, N); H := 2;
  End
  Else If N < 256 Then
  Begin
    WB(Dst + 1, $81); WB(Dst + 2, N); H := 3;
  End
  Else
  Begin
    WB(Dst + 1, $82); WB(Dst + 2, N Shr 8); WB(Dst + 3, N And 255); H := 4;
  End;
  MoveMem(Src, Dst + H, N);
  DerWrap := H + N;
End;

{ Jeton NTLMSSP (Tok, N) dans SPNEGO en Dst : NegTokenInit (Init) ou
  NegTokenResp ; octets ecrits. Tampons de travail : SmbWk }
Function SpnWrap(Tok, N, Dst : LongInt; Init : Boolean) : LongInt;
Var W1, W2, K : LongInt;
Begin
  W1 := SmbWk; W2 := SmbWk + 4096;
  K := DerWrap($04, Tok, N, W1);                 { OCTET STRING }
  K := DerWrap($A2, W1, K, W2);                  { [2] mechToken }
  If Init Then
  Begin
    MoveMem(LongInt(@SpnMech[0]), W1, 16);       { [0] mechTypes }
    MoveMem(W2, W1 + 16, K);
    K := DerWrap($30, W1, K + 16, W2);           { NegTokenInit }
    K := DerWrap($A0, W2, K, W1);
    MoveMem(LongInt(@SpnOid[0]), W2, 8);
    MoveMem(W1, W2 + 8, K);
    SpnWrap := DerWrap($60, W2, K + 8, Dst);
  End
  Else
  Begin
    K := DerWrap($30, W2, K, W1);                { NegTokenResp }
    SpnWrap := DerWrap($A1, W1, K, Dst);
  End;
End;

{ Debut du message NTLMSSP dans (A, N), 0 s'il n'y en a pas }
Function NtlmFind(A, N : LongInt) : LongInt;
Var I : LongInt;
Begin
  NtlmFind := 0;
  For I := 0 To N - 8 Do
    If (RL(A + I) = $4D4C544E) And (RL(A + I + 4) = $00505353) Then
    Begin
      NtlmFind := A + I;
      Exit;
    End;
End;

{ Champ (longueur, longueur, decalage) d'un message NTLMSSP }
Procedure NtlmField(M, F, Len, Ofs : LongInt);
Begin
  WW(M + F, Len); WW(M + F + 2, Len);
  WL(M + F + 4, Ofs);
End;

{ Message AUTHENTICATE (NTLMv2) en Dst, d'apres le message CHALLENGE C
  (CLen octets) ; octets ecrits. Cle de session en NdKeys (unite N) }
Function NtlmAuth(N, C, CLen, Dst : LongInt) : LongInt;
Var TI, TLen, P, K, Q, Id, Ln, Tmp, TmpN : LongInt;
    NtV2 : Array[0..15] Of Byte; Proof : Array[0..15] Of Byte;
    Ts : Array[0..7] Of Byte; Cc : Array[0..7] Of Byte;
    U : Array[0..299] Of Byte; Dom, Usr : String; Anon : Boolean;
Begin
  TLen := RW(C + 40); TI := C + RL(C + 44);
  If RL(C + 44) + TLen > CLen Then TLen := 0;
  Usr := Nd[N].User; Dom := Nd[N].Dom;
  Anon := Usr = '';
  { domaine : celui donne (DOMAINE\nom), sinon celui du serveur (comptes
    locaux d'un serveur autonome) }
  If (Dom = '') And Not Anon Then
  Begin
    K := RW(C + 12); Q := C + RL(C + 16);
    For P := 0 To MinL(K Div 2, 63) - 1 Do Dom := Dom + Chr(RB(Q + P * 2));
  End;
  { horodatage : MsvAvTimestamp du serveur, sinon son heure }
  FillMem(LongInt(@Ts[0]), 8, 0);
  P := 0;
  While P + 4 <= TLen Do
  Begin
    Id := RW(TI + P); Ln := RW(TI + P + 2);
    If Id = 0 Then Break;
    If (Id = 7) And (Ln = 8) Then MoveMem(TI + P + 4, LongInt(@Ts[0]), 8);
    P := P + 4 + Ln;
  End;
  If (RL(LongInt(@Ts[0])) = 0) And (RL(LongInt(@Ts[4])) = 0) Then
    MoveMem(NdKeys + N * 32 + 16, LongInt(@Ts[0]), 8);
  Random8(LongInt(@Cc[0]), 8);
  FillMem(Dst, 64, 0);
  WL(Dst, $4D4C544E); WL(Dst + 4, $00505353);
  WL(Dst + 8, 3);
  WL(Dst + 60, NtlmFlags And RL(C + 20));
  If Anon Then WL(Dst + 60, RL(Dst + 60) Or $800);
  P := 64;
  { domaine, utilisateur, poste }
  K := Uni(Dst + P, Dom); NtlmField(Dst, 28, K, P); P := P + K;
  K := Uni(Dst + P, Usr); NtlmField(Dst, 36, K, P); P := P + K;
  K := Uni(Dst + P, 'OS2-ZERO'); NtlmField(Dst, 44, K, P); P := P + K;
  If Anon Then
  Begin
    { session anonyme : reponse LM d'un octet nul, reponse NT vide }
    WB(Dst + P, 0); NtlmField(Dst, 12, 1, P); P := P + 1;
    NtlmField(Dst, 20, 0, P);
    NtlmField(Dst, 52, 0, P);
    FillMem(NdKeys + N * 32 + 16, 16, 0);
    NtlmAuth := P;
    Exit;
  End;
  { NTOWFv2 = HMAC_MD5(hachage NT, UNICODE(MAJ(utilisateur) + domaine)) }
  K := Uni(LongInt(@U[0]), UpStr(Usr));
  K := K + Uni(LongInt(@U[K]), Dom);
  HmacMd5(NdKeys + N * 32, 16, LongInt(@U[0]), K, 0, 0, LongInt(@NtV2[0]));
  { reponse LM : 24 zeros (horodatage present) }
  FillMem(Dst + P, 24, 0); NtlmField(Dst, 12, 24, P); P := P + 24;
  { reponse NT : NTProofStr + temp ; temp = 01 01 0 0 horodatage, defi du
    client, 0, informations du serveur, 0 }
  Tmp := Dst + P + 16;
  FillMem(Tmp, 28, 0);
  WB(Tmp, 1); WB(Tmp + 1, 1);
  MoveMem(LongInt(@Ts[0]), Tmp + 8, 8);
  MoveMem(LongInt(@Cc[0]), Tmp + 16, 8);
  MoveMem(TI, Tmp + 28, TLen);
  FillMem(Tmp + 28 + TLen, 4, 0);
  TmpN := 32 + TLen;
  HmacMd5(LongInt(@NtV2[0]), 16, C + 24, 8, Tmp, TmpN, LongInt(@Proof[0]));
  MoveMem(LongInt(@Proof[0]), Dst + P, 16);
  NtlmField(Dst, 20, 16 + TmpN, P); P := P + 16 + TmpN;
  NtlmField(Dst, 52, 0, P);
  { cle de session : HMAC_MD5(NTOWFv2, NTProofStr) }
  HmacMd5(LongInt(@NtV2[0]), 16, LongInt(@Proof[0]), 16, 0, 0, NdKeys + N * 32 + 16);
  NtlmAuth := P;
End;

{ ==================================================================== }
{ Connexion : NEGOTIATE, SESSION_SETUP, TREE_CONNECT                    }
{ ==================================================================== }

{ adresse IPv4 (ordre du reseau) du serveur : a.b.c.d ou nom (DNS) }
Function Resolve(Name : String; Var Ip : LongInt) : Boolean;
Var H, L, A : LongInt;
Begin
  Resolve := False;
  PutZ(LongInt(@NameZ), Name, 260);
  H := SkHost(LongInt(@NameZ));
  If H = 0 Then Exit;
  L := RL(H + 16);                  { h_addr_list }
  If L = 0 Then Exit;
  A := RL(L);
  If A = 0 Then Exit;
  Ip := RL(A);
  Resolve := True;
End;

Function IpStr(Ip : LongInt) : String;
Var S, T : String; I : LongInt;
Begin
  S := '';
  For I := 0 To 3 Do
  Begin
    Str((Ip Shr (I * 8)) And 255, T);
    If I > 0 Then S := S + '.';
    S := S + T;
  End;
  IpStr := S;
End;

Function HexStat(St : LongInt) : String;
Begin
  HexStat := HexDig(St, 8) + 'h';
End;

{ 0 ou erreur OS/2 (LastMsg : explication) }
Function NdConnect(N : LongInt) : LongInt;
Var IP, S, B, K, R, St, C, CL, E : LongInt; A : Array[0..15] Of Byte; Path : String; SignReq : Boolean;
Begin
  NdConnect := ERROR_BAD_NETPATH;
  NdDrop(N);
  CnSet(1);
  If SkInit <> 0 Then
  Begin
    LastMsg := 'Le reseau TCP/IP n''est pas pret (carte reseau, DHCP).';
    Exit;
  End;
  CnSet(2);
  If Not Resolve(Nd[N].Server, IP) Then
  Begin
    LastMsg := 'Serveur introuvable : ' + Nd[N].Server + ' (DNS).';
    If CnCancelled Then NdConnect := ERROR_INTERRUPT;
    Exit;
  End;
  CnIp := IP;
  If CnCancelled Then
  Begin
    NdConnect := ERROR_INTERRUPT;
    Exit;
  End;
  CnSet(3);
  S := SkSocket(2, 1, 6);
  If S < 0 Then
  Begin
    LastMsg := 'Plus de socket libre.';
    Exit;
  End;
  { socket du systeme : survit au programme qui a attache l'unite }
  If SkSystem(S) <> 0 Then
  Begin
    SkClose(S);
    LastMsg := 'Memoire insuffisante pour le socket.';
    Exit;
  End;
  FillMem(LongInt(@A[0]), 16, 0);
  A[0] := 16; A[1] := 2; A[2] := 445 Shr 8; A[3] := 445 And 255;
  WL(LongInt(@A[4]), IP);
  CnSock := S;
  If CnAbort Then SkAbort(S);
  If SkConnect(S, LongInt(@A[0]), 16) <> 0 Then
  Begin
    CnSock := -1;
    SkClose(S);
    LastMsg := 'Connexion impossible a ' + Nd[N].Server + ' (' + IpStr(IP) + ', port TCP 445).';
    If CnCancelled Then NdConnect := ERROR_INTERRUPT;
    Exit;
  End;
  Nd[N].Sock := S; Nd[N].Conn := True; Nd[N].Sign := False;
  Nd[N].Mid := 0; Nd[N].Tree := 0; Nd[N].SessLo := 0; Nd[N].SessHi := 0;
  SmbInConn := True;
  NdConnect := ERROR_UNEXP_NET_ERR;
  { NEGOTIATE : dialectes 2.0.2 et 2.1, signature possible }
  CnSet(4);
  SmbHdr(N, 0);
  B := SmbTx + 68;
  WW(B, 36); WW(B + 2, 2); WW(B + 4, 1);
  Random8(B + 12, 16);
  WW(B + 36, $0202); WW(B + 38, $0210);
  St := SmbCall(N, 40);
  If St <> 0 Then
  Begin
    If St = -1 Then LastMsg := 'Le serveur ne repond pas en SMB 2 (port TCP 445).'
    Else LastMsg := 'Le serveur refuse SMB 2 (NEGOTIATE ' + HexStat(St) + ').';
    If CnCancelled Then NdConnect := ERROR_INTERRUPT;
    SmbInConn := False; NdDrop(N); Exit;
  End;
  R := SmbRx + 64;
  { signature exigee : seulement apres SESSION_SETUP (cle de session) }
  SignReq := (RW(R + 2) And 2) <> 0;
  Nd[N].MaxRd := MinL(RL(R + 32), SmbChunk);
  Nd[N].MaxWr := MinL(RL(R + 36), SmbChunk);
  If Nd[N].MaxRd <= 0 Then Nd[N].MaxRd := 65536;
  If Nd[N].MaxWr <= 0 Then Nd[N].MaxWr := 65536;
  { heure du serveur (horodatage NTLMv2 s'il n'en donne pas) }
  MoveMem(R + 40, NdKeys + N * 32 + 16, 8);
  { SESSION_SETUP 1 : NTLMSSP NEGOTIATE }
  CnSet(5);
  SmbHdr(N, 1);
  B := SmbTx + 68;
  WW(B, 25); WB(B + 3, 1);
  C := SmbWk + 8192;
  FillMem(C, 32, 0);
  WL(C, $4D4C544E); WL(C + 4, $00505353);
  WL(C + 8, 1); WL(C + 12, NtlmFlags);
  K := SpnWrap(C, 32, B + 24, True);
  WW(B + 12, 88); WW(B + 14, K);
  St := SmbCall(N, 24 + K);
  If St <> LongInt($C0000016) Then
  Begin
    E := SmbErr(St);
    If St = 0 Then E := ERROR_INVALID_PASSWORD;
    LastMsg := 'Ouverture de session refusee (' + HexStat(St) + ').';
    NdConnect := E;
    If CnCancelled Then NdConnect := ERROR_INTERRUPT;
    SmbInConn := False; NdDrop(N); Exit;
  End;
  Nd[N].SessLo := RL(SmbRx + 40); Nd[N].SessHi := RL(SmbRx + 44);
  R := SmbRx + 64;
  C := NtlmFind(SmbRx + RW(R + 4), RW(R + 6));
  If C = 0 Then
  Begin
    LastMsg := 'Le serveur n''a pas envoye de defi NTLMSSP.';
    SmbInConn := False; NdDrop(N); Exit;
  End;
  CL := RW(R + 6) - (C - SmbRx - RW(R + 4));
  { copier le defi : SmbRx sera ecrase }
  If CL > 4096 Then CL := 4096;
  MoveMem(C, SmbWk + 12288, CL);
  { SESSION_SETUP 2 : NTLMSSP AUTHENTICATE }
  CnSet(6);
  K := NtlmAuth(N, SmbWk + 12288, CL, SmbWk + 8192);
  SmbHdr(N, 1);
  B := SmbTx + 68;
  WW(B, 25); WB(B + 3, 1);
  K := SpnWrap(SmbWk + 8192, K, B + 24, False);
  WW(B + 12, 88); WW(B + 14, K);
  St := SmbCall(N, 24 + K);
  If St <> 0 Then
  Begin
    E := SmbErr(St);
    If E = ERROR_UNEXP_NET_ERR Then E := ERROR_INVALID_PASSWORD;
    If E = ERROR_INVALID_PASSWORD Then
      LastMsg := 'Nom d''utilisateur ou mot de passe incorrect (' + HexStat(St) + ').'
    Else LastMsg := 'Authentification refusee (' + HexStat(St) + ').';
    NdConnect := E;
    If CnCancelled Then NdConnect := ERROR_INTERRUPT;
    SmbInConn := False; NdDrop(N); Exit;
  End;
  { invite ou session anonyme : pas de signature }
  Nd[N].Sign := SignReq And ((RW(SmbRx + 66) And 3) = 0) And (Nd[N].User <> '');
  { TREE_CONNECT \\serveur\partage }
  Path := '\\' + Nd[N].Server + '\' + Nd[N].Share;
  CnSet(7);
  SmbHdr(N, 3);
  B := SmbTx + 68;
  WW(B, 9); WW(B + 4, 72);
  K := Uni(B + 8, Path);
  WW(B + 6, K);
  St := SmbCall(N, 8 + K);
  SmbInConn := False;
  If St <> 0 Then
  Begin
    E := SmbErr(St);
    If St = LongInt($C0000022) Then E := ERROR_NETWORK_ACCESS_DENIED;
    If E = ERROR_BAD_NET_NAME Then LastMsg := 'Partage introuvable : ' + Path + '.'
    Else LastMsg := 'Acces au partage ' + Path + ' refuse (' + HexStat(St) + ').';
    NdConnect := E;
    If CnCancelled Then NdConnect := ERROR_INTERRUPT;
    NdDrop(N); Exit;
  End;
  Nd[N].Tree := RL(SmbRx + 36);
  LastMsg := '';
  CnSet(8);
  NdConnect := NO_ERROR;
End;

{ Unite prete (connexion etablie au besoin) ; erreur OS/2 sinon }
Function NdEnsure(N : LongInt) : LongInt;
Var R : LongInt;
Begin
  NdEnsure := NO_ERROR;
  If Nd[N].Conn Then Exit;
  { serveur injoignable il y a moins de 15 s : ne pas bloquer encore }
  If (Nd[N].FailT <> 0) And (KTicks - Nd[N].FailT < 15000) Then
  Begin
    NdEnsure := ERROR_NETNAME_DELETED;
    Exit;
  End;
  R := NdConnect(N);
  If R <> NO_ERROR Then Nd[N].FailT := KTicks Else Nd[N].FailT := 0;
  NdEnsure := R;
End;

{ ==================================================================== }
{ Requetes sur les fichiers                                             }
{ ==================================================================== }

Procedure PutFid(B : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 3 Do WL(B + I * 4, ScFid[I]);
End;

{ CREATE : statut ; ScFid, ScAttr, ScSize, ScTime, ScAct }
Function SmbCreate(N : LongInt; Rel : String; Acc, Attr, Disp, Opt : LongInt) : LongInt;
Var B, K, R, I : LongInt;
Begin
  SmbHdr(N, 5);
  B := SmbTx + 68;
  WW(B, 57);
  WL(B + 4, 2);                            { impersonation }
  WL(B + 24, Acc);
  WL(B + 28, Attr);
  WL(B + 32, 7);                           { partage complet }
  WL(B + 36, Disp);
  WL(B + 40, Opt);
  WW(B + 44, 120);
  K := Uni(B + 56, Rel);
  WW(B + 46, K);
  If K = 0 Then
  Begin
    WB(B + 56, 0); K := 1;
  End;
  SmbCreate := SmbCall(N, 56 + K);
  If SmbSt <> 0 Then Exit;
  R := SmbRx + 64;
  ScAct := RL(R + 4);
  ScCLo := RL(R + 8); ScCHi := RL(R + 12);
  ScTime := FtDos(RL(R + 24), RL(R + 28));
  ScSize := RL(R + 48);
  If (RL(R + 52) <> 0) Or (ScSize < 0) Then ScSize := $7FFFFFFF;
  ScAttr := RL(R + 56);
  For I := 0 To 3 Do ScFid[I] := RL(R + 64 + I * 4);
End;

Procedure SmbClose(N : LongInt);
Var B : LongInt;
Begin
  SmbHdr(N, 6);
  B := SmbTx + 68;
  WW(B, 24);
  PutFid(B + 8);
  SmbCall(N, 24);
End;

{ SET_INFO (classe de fichier Cls, Len octets de Src) sur ScFid }
Function SmbSetInfo(N, Cls, Src, Len : LongInt) : LongInt;
Var B : LongInt;
Begin
  SmbHdr(N, $11);
  B := SmbTx + 68;
  WW(B, 33); WB(B + 2, 1); WB(B + 3, Cls);
  WL(B + 4, Len); WW(B + 8, 96);
  PutFid(B + 16);
  MoveMem(Src, B + 32, Len);
  SmbSetInfo := SmbCall(N, 32 + Len);
End;

{ FileBasicInformation : heure de modification (DOS, 0 inchangee) et
  attributs (-1 inchanges) }
Function SmbSetBasic(N, MTime, Attr : LongInt) : LongInt;
Var I : Array[0..39] Of Byte;
Begin
  FillMem(LongInt(@I[0]), 40, 0);
  If MTime <> 0 Then DosFt(MTime, LongInt(@I[16]));
  If Attr >= 0 Then
  Begin
    WL(LongInt(@I[32]), Attr And $27);
    If (Attr And $27) = 0 Then WL(LongInt(@I[32]), $80);    { FILE_ATTRIBUTE_NORMAL }
  End;
  SmbSetBasic := SmbSetInfo(N, 4, LongInt(@I[0]), 40);
End;

{ ==================================================================== }
{ Chemins                                                                }
{ ==================================================================== }

{ Unite (0..25) d'une operation : CDFSI, sinon la lettre du chemin }
Function DrvOf(Pcdfsi, PName : LongInt) : LongInt;
Var D : LongInt;
Begin
  D := -1;
  If Pcdfsi <> 0 Then D := RL(Pcdfsi);
  If ((D < 0) Or (D >= MaxNd)) And (PName <> 0) Then
    If RB(PName + 1) = 58 Then D := Ord(UpCase(Chr(RB(PName)))) - 65;
  If (D < 0) Or (D >= MaxNd) Then D := -1
  Else If Not Nd[D].Used Then D := -1;
  DrvOf := D;
End;

{ Chemin complet (Z:\A\B) -> chemin dans le partage (A\B) }
Function RelOf(PName : LongInt) : String;
Var S : String;
Begin
  S := GetZ(PName);
  If (Length(S) >= 2) And (S[2] = ':') Then Delete(S, 1, 2);
  While (S <> '') And (S[1] = '\') Do Delete(S, 1, 1);
  While (S <> '') And (S[Length(S)] = '\') Do Delete(S, Length(S), 1);
  RelOf := S;
End;

Function HasWild(S : String) : Boolean;
Begin
  HasWild := (Pos('*', S) > 0) Or (Pos('?', S) > 0);
End;

{ comparaison avec jokers (sans casse), *.* : tout }
Function MatchMask(N, M : String) : Boolean;
Var I, J, SI, SJ : LongInt;
Begin
  If (M = '*.*') Or (M = '*') Then
  Begin
    MatchMask := True;
    Exit;
  End;
  N := UpStr(N); M := UpStr(M);
  I := 1; J := 1; SI := 0; SJ := 0;
  While I <= Length(N) Do
  Begin
    If (J <= Length(M)) And ((M[J] = '?') Or (M[J] = N[I])) Then Begin Inc(I); Inc(J); End
    Else If (J <= Length(M)) And (M[J] = '*') Then Begin SJ := J; SI := I; Inc(J); End
    Else If SJ > 0 Then Begin J := SJ + 1; Inc(SI); I := SI; End
    Else Begin MatchMask := False; Exit; End;
  End;
  While (J <= Length(M)) And ((M[J] = '*') Or (M[J] = '.')) Do Inc(J);
  MatchMask := J > Length(M);
End;

{ attributs d'OS/2 : caches, systeme et repertoires seulement s'ils sont demandes }
Function AttrOk(A, Want : LongInt) : Boolean;
Begin
  AttrOk := ((A And $16) And Not Want) = 0;
End;

{ informations d'un chemin (ScAttr, ScSize, ScTime) ; statut NT }
Function StatPath(N : LongInt; Rel : String) : LongInt;
Var St : LongInt;
Begin
  If Rel = '' Then
  Begin
    ScAttr := $10; ScSize := 0; ScTime := (1 Shl 21) Or (1 Shl 16);
    StatPath := 0;
    Exit;
  End;
  St := SmbCreate(N, Rel, $80, 0, 1, 0);           { FILE_READ_ATTRIBUTES }
  If St = 0 Then SmbClose(N);
  StatPath := St;
End;

{ FILESTATUS (niveau 1, 24 octets ; niveau 2 : + cbList, 28 octets) }
Function PutStatus(A, Cb, Level, Attr, Size, T : LongInt) : LongInt;
Begin
  PutStatus := NO_ERROR;
  If ((Level = 1) And (Cb < 24)) Or ((Level = 2) And (Cb < 28)) Then
  Begin
    PutStatus := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  WW(A, (T Shr 16) And $FFFF); WW(A + 2, T And $FFFF);
  WW(A + 4, (T Shr 16) And $FFFF); WW(A + 6, T And $FFFF);
  WW(A + 8, (T Shr 16) And $FFFF); WW(A + 10, T And $FFFF);
  WL(A + 12, Size);
  WL(A + 16, ((Size + 4095) Div 4096) * 4096);
  WL(A + 20, Attr And $37);
  If Level = 2 Then WL(A + 24, 4);
End;

{ ==================================================================== }
{ Points d'entree du FSD                                                }
{ ==================================================================== }

Function FS_INIT(PParm, PDevHlp, PMiniFsd : LongInt) : LongInt;
Var I : LongInt;
Begin
  If Not InitDone Then
  Begin
    For I := 0 To MaxNd - 1 Do
    Begin
      Nd[I].Used := False; Nd[I].Conn := False; Nd[I].Sock := -1;
    End;
    For I := 0 To MaxOpen - 1 Do Opens[I].Used := False;
    For I := 0 To MaxFind - 1 Do Finds[I].Used := False;
    SmbTx := (LongInt(@TxBuf) + 3) And Not 3;
    SmbRx := (LongInt(@RxBuf) + 3) And Not 3;
    SmbSave := (LongInt(@SaveBuf) + 3) And Not 3;
    SmbWk := LongInt(@WkBuf);
    NdKeys := LongInt(@Keys);
    SmbBusy := False; SmbInConn := False;
    CnStep := 0; CnBusy := 0; CnSock := -1; CnAbort := False; CnRes := 0; CnT0 := KTicks; CnStepT := CnT0;
    LastMsg := '';
    InitDone := True;
  End;
  FS_INIT := NO_ERROR;
End;

{ pas de volume sur un disque : un FSD distant ne reconnait aucun volume }
Function FS_MOUNT(Flag, PVpfsi, PVpfsd, HVpb, PBoot : LongInt) : LongInt;
Begin
  FS_MOUNT := ERROR_INVALID_FUNCTION;
End;

{ ---------------------------------------------------------------------
  FS_ATTACH(flag, pDev, pvpfsd, pcdfsd, pParm, pLen)
    flag 0 (FS_ATTACH) : attacher l'unite pDev ("Z:") ; pParm : ASCIIZ
    "\\serveur\partage", utilisateur ("DOMAINE\nom", vide : session
    anonyme), mot de passe (ou "#" et le hachage NT en hexadecimal), et
    des options facultatives ("L" : connexion differee) ; la connexion
    est etablie tout de suite (erreur si le serveur, le partage ou le
    compte est refuse), sauf avec L (lecteur permanent rattache par le
    bureau au demarrage : connexion au premier acces) ;
    1 (FS_DETACH) : detacher ;
    2 (FS_ATTACH_INFO) : pParm <- "\\serveur\partage" 0 "utilisateur" 0
    "#hachage" 0 (*pLen : taille du tampon, puis octets ecrits). }
Function FS_ATTACH(Flag, PDev, PVpfsd, PCdfsd, PParm, PLen : LongInt) : LongInt;
Var D, R, P, I, K : LongInt; Remote, User, Pass, S, Opt : String;
Begin
  FS_ATTACH := ERROR_INVALID_PARAMETER;
  If Not InitDone Then FS_INIT(0, 0, 0);
  If PDev = 0 Then Exit;
  D := Ord(UpCase(Chr(RB(PDev)))) - 65;
  If (D < 0) Or (D >= MaxNd) Then Exit;
  Case Flag Of
    0 :
      Begin
        If PParm = 0 Then Exit;
        If Nd[D].Used Then
        Begin
          FS_ATTACH := ERROR_ALREADY_ASSIGNED;
          Exit;
        End;
        Remote := GetZ(PParm);
        P := PParm + Length(Remote) + 1;
        User := GetZ(P); P := P + Length(User) + 1;
        Pass := GetZ(P); P := P + Length(Pass) + 1;
        { options (4e chaine, facultative) : L = connexion differee (lecteur
          permanent restaure a l'ouverture de session : la connexion se fait
          au premier acces, sans attendre un serveur eteint) }
        Opt := '';
        If (PLen <> 0) And (P - PParm < RL(PLen)) Then Opt := UpStr(GetZ(P));
        { \\serveur\partage }
        While (Remote <> '') And (Remote[Length(Remote)] = '\') Do Delete(Remote, Length(Remote), 1);
        If Copy(Remote, 1, 2) <> '\\' Then Exit;
        Delete(Remote, 1, 2);
        I := Pos('\', Remote);
        If (I < 2) Or (I = Length(Remote)) Then
        Begin
          LastMsg := 'Chemin reseau incorrect : il faut \\serveur\partage.';
          FS_ATTACH := ERROR_BAD_NETPATH;
          Exit;
        End;
        SmbEnter;
        Nd[D].Used := True; Nd[D].Conn := False; Nd[D].Sock := -1;
        Nd[D].FailT := 0; Nd[D].SpcT := 0;
        Nd[D].Server := Copy(Remote, 1, I - 1);
        Nd[D].Share := Copy(Remote, I + 1, 63);
        Nd[D].Dom := '';
        K := Pos('\', User);
        If K > 0 Then
        Begin
          Nd[D].Dom := Copy(User, 1, K - 1);
          User := Copy(User, K + 1, 255);
        End;
        Nd[D].User := User;
        FillMem(NdKeys + D * 32, 32, 0);
        If (Length(Pass) = 33) And (Pass[1] = '#') Then HexTo(Copy(Pass, 2, 32), NdKeys + D * 32, 16)
        Else NtHash(Pass, NdKeys + D * 32);
        If Pos('L', Opt) > 0 Then R := NO_ERROR
        Else
        Begin
          { connexion suivie par SMBSTATUS }
          CnBusy := 1; CnRes := 0; CnIp := 0; CnSock := -1;
          CnTxN := 0; CnRxN := 0; CnTxB := 0; CnRxB := 0;
          For I := 0 To 9 Do CnMs[I] := 0;
          CnStep := 0; CnT0 := KTicks; CnStepT := CnT0;
          R := NdConnect(D);
          CnSock := -1;
          If CnStep <= 9 Then CnMs[CnStep] := KTicks - CnStepT;
          CnRes := R;
          CnBusy := 0;
          CnAbort := False;
        End;
        If R <> NO_ERROR Then
        Begin
          NdDrop(D);
          Nd[D].Used := False;
        End;
        SmbLeave;
        FS_ATTACH := R;
      End;
    1 :
      Begin
        If Not Nd[D].Used Then
        Begin
          FS_ATTACH := ERROR_INVALID_DRIVE;
          Exit;
        End;
        SmbEnter;
        { fichiers et recherches encore ouverts sur l'unite : abandonnes }
        For I := 0 To MaxOpen - 1 Do If Opens[I].Used And (Opens[I].Drv = D) Then Opens[I].Used := False;
        For I := 0 To MaxFind - 1 Do
          If Finds[I].Used And (Finds[I].Drv = D) Then
          Begin
            DosFreeMem(Finds[I].Buf);
            Finds[I].Used := False;
          End;
        NdDrop(D);
        Nd[D].Used := False;
        SmbLeave;
        FS_ATTACH := NO_ERROR;
      End;
    2 :
      Begin
        If Not Nd[D].Used Then
        Begin
          FS_ATTACH := ERROR_INVALID_DRIVE;
          Exit;
        End;
        If (PParm = 0) Or (PLen = 0) Then Exit;
        S := '';
        For I := 0 To 15 Do S := S + HexDig(RB(NdKeys + D * 32 + I), 2);
        User := Nd[D].User;
        If Nd[D].Dom <> '' Then User := Nd[D].Dom + '\' + User;
        Remote := '\\' + Nd[D].Server + '\' + Nd[D].Share;
        K := Length(Remote) + Length(User) + 33 + 3;
        If RL(PLen) < K Then
        Begin
          WL(PLen, K);
          FS_ATTACH := ERROR_BUFFER_OVERFLOW;
          Exit;
        End;
        PutZ(PParm, Remote, 256);
        PutZ(PParm + Length(Remote) + 1, User, 256);
        PutZ(PParm + Length(Remote) + Length(User) + 2, '#' + S, 40);
        WL(PLen, K);
        FS_ATTACH := NO_ERROR;
      End;
  End;
End;

{ ---------------------------------------------------------------------
  FS_OPENCREATE : ouvrir ou creer (usOpenFlag : bits 0-3 si le fichier
  existe : 0 echec, 1 ouvrir, 2 remplacer ; bits 4-7 s'il n'existe pas :
  0 echec, 1 creer). }
Function FS_OPENCREATE(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Psffsi, Psffsd, OpenMode, OpenFlag,
                       PAction, Attr, PEABuf, PGenFlag : LongInt) : LongInt;
Var D, R, H, I, IfEx, IfNew, Disp, Acc, St, Act : LongInt; Rel : String; Wr : Boolean;
Begin
  D := -1;
  If Psffsi <> 0 Then D := RL(Psffsi + 4);
  If (D < 0) Or (D >= MaxNd) Or Not Nd[D].Used Then D := DrvOf(Pcdfsi, PName);
  If D < 0 Then
  Begin
    FS_OPENCREATE := ERROR_INVALID_DRIVE;
    Exit;
  End;
  Rel := RelOf(PName);
  If Rel = '' Then
  Begin
    FS_OPENCREATE := ERROR_ACCESS_DENIED;
    Exit;
  End;
  If HasWild(Rel) Then
  Begin
    FS_OPENCREATE := ERROR_INVALID_NAME;
    Exit;
  End;
  H := -1;
  For I := MaxOpen - 1 DownTo 0 Do If Not Opens[I].Used Then H := I;
  If H < 0 Then
  Begin
    FS_OPENCREATE := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  IfEx := OpenFlag And $0F;
  IfNew := (OpenFlag Shr 4) And $0F;
  If (IfEx = 1) And (IfNew = 0) Then Disp := 1          { FILE_OPEN }
  Else If (IfEx = 1) And (IfNew = 1) Then Disp := 3     { FILE_OPEN_IF }
  Else If (IfEx = 2) And (IfNew = 1) Then Disp := 5     { FILE_OVERWRITE_IF }
  Else If (IfEx = 2) And (IfNew = 0) Then Disp := 4     { FILE_OVERWRITE }
  Else If (IfEx = 0) And (IfNew = 1) Then Disp := 2     { FILE_CREATE }
  Else
  Begin
    FS_OPENCREATE := ERROR_INVALID_PARAMETER;
    Exit;
  End;
  Wr := (OpenMode And 7) <> 0;
  Acc := LongInt($80000000);                            { GENERIC_READ }
  If Wr Or (Disp <> 1) Then Acc := LongInt($C0000000);
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then
  Begin
    St := SmbCreate(D, Rel, Acc, (Attr And $27) Or $20, Disp, $40);
    { lecture seule sur le serveur : ouvrir en lecture }
    If (St = LongInt($C0000022)) And Not Wr And (Disp = 1) Then St := SmbCreate(D, Rel, $120089, 0, 1, $40);
    If (St = LongInt($C0000035)) Or (St = LongInt($C0000034)) Then R := ERROR_OPEN_FAILED
    Else R := SmbErr(St);
    If (R = NO_ERROR) And ((ScAttr And $10) <> 0) Then
    Begin
      SmbClose(D);
      R := ERROR_ACCESS_DENIED;
    End;
  End;
  SmbLeave;
  If R = NO_ERROR Then
  Begin
    Opens[H].Used := True; Opens[H].Drv := D; Opens[H].Wr := Wr;
    Opens[H].Size := ScSize; Opens[H].Attr := ScAttr And $37;
    For I := 0 To 3 Do Opens[H].Fid[I] := ScFid[I];
    If Disp >= 4 Then Opens[H].Size := 0;
    WL(Psffsd, H + 1);
    WL(Psffsd + 4, SFD_MAGIC);
    WL(Psffsi + 8, ScTime); WL(Psffsi + 12, ScTime); WL(Psffsi + 16, ScTime);
    WL(Psffsi + 20, Opens[H].Size);
    WL(Psffsi + 24, 0);
    WL(Psffsi + 52, Opens[H].Attr);
    Case ScAct Of
      1 : Act := 1;
      2 : Act := 2;
    Else
      Act := 3;
    End;
    If PAction <> 0 Then WL(PAction, Act);
    If PGenFlag <> 0 Then WL(PGenFlag, 0);
  End;
  FS_OPENCREATE := R;
End;

Function OpenOf(Psffsd : LongInt) : LongInt;
Var H : LongInt;
Begin
  OpenOf := -1;
  If Psffsd = 0 Then Exit;
  If RL(Psffsd + 4) <> SFD_MAGIC Then Exit;
  H := RL(Psffsd) - 1;
  If (H >= 0) And (H < MaxOpen) Then
    If Opens[H].Used Then OpenOf := H;
End;

Procedure OpenFid(H : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 3 Do ScFid[I] := Opens[H].Fid[I];
End;

Function FS_CLOSE(CType, IOFlag, Psffsi, Psffsd : LongInt) : LongInt;
Var H : LongInt;
Begin
  H := OpenOf(Psffsd);
  If H < 0 Then
  Begin
    FS_CLOSE := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If CType = 2 Then
  Begin
    SmbEnter;
    If Nd[Opens[H].Drv].Conn Then
    Begin
      OpenFid(H);
      SmbClose(Opens[H].Drv);
    End;
    SmbLeave;
    Opens[H].Used := False;
    WL(Psffsd + 4, 0);
  End;
  FS_CLOSE := NO_ERROR;
End;

Function FS_READ(Psffsi, Psffsd, PData, PLen, IOFlag : LongInt) : LongInt;
Var H, N, D, Pos0, N0, Done, C, B, K, St, R : LongInt;
Begin
  Done := 0; R := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else
  Begin
    D := Opens[H].Drv;
    N0 := RL(PLen);
    Pos0 := RL(Psffsi + 24);
    If Pos0 + N0 > Opens[H].Size Then N0 := Opens[H].Size - Pos0;
    SmbEnter;
    While Done < N0 Do
    Begin
      C := MinL(N0 - Done, Nd[D].MaxRd);
      SmbHdr(D, 8);
      B := SmbTx + 68;
      WW(B, 49); WB(B + 2, $50);
      WL(B + 4, C); WL(B + 8, Pos0 + Done);
      OpenFid(H);
      PutFid(B + 16);
      St := SmbCall(D, 49);
      If St <> 0 Then
      Begin
        If St <> LongInt($C0000011) Then R := SmbErr(St);
        Break;
      End;
      K := MinL(RL(SmbRx + 68), C);
      If K <= 0 Then Break;
      MoveMem(SmbRx + RB(SmbRx + 66), PData + Done, K);
      Done := Done + K;
      If K < C Then Break;
    End;
    SmbLeave;
    WL(Psffsi + 24, Pos0 + Done);
  End;
  WL(PLen, Done);
  FS_READ := R;
End;

Function FS_WRITE(Psffsi, Psffsd, PData, PLen, IOFlag : LongInt) : LongInt;
Var H, D, Pos0, N0, Done, C, B, K, St, R : LongInt;
Begin
  Done := 0; R := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else If Not Opens[H].Wr Then R := ERROR_ACCESS_DENIED
  Else
  Begin
    D := Opens[H].Drv;
    N0 := RL(PLen);
    Pos0 := RL(Psffsi + 24);
    SmbEnter;
    While Done < N0 Do
    Begin
      C := MinL(N0 - Done, Nd[D].MaxWr);
      SmbHdr(D, 9);
      B := SmbTx + 68;
      WW(B, 49); WW(B + 2, 112);
      WL(B + 4, C); WL(B + 8, Pos0 + Done);
      OpenFid(H);
      PutFid(B + 16);
      MoveMem(PData + Done, B + 48, C);
      St := SmbCall(D, 48 + C);
      If St <> 0 Then
      Begin
        R := SmbErr(St);
        Break;
      End;
      K := RL(SmbRx + 68);
      If K <= 0 Then Break;
      Done := Done + K;
      If K < C Then Break;
    End;
    SmbLeave;
    If Pos0 + Done > Opens[H].Size Then Opens[H].Size := Pos0 + Done;
    WL(Psffsi + 24, Pos0 + Done);
    WL(Psffsi + 20, Opens[H].Size);
  End;
  WL(PLen, Done);
  If (R <> NO_ERROR) And (Done > 0) Then R := NO_ERROR;
  FS_WRITE := R;
End;

Function FS_CHGFILEPTR(Psffsi, Psffsd, Offset, MType, IOFlag : LongInt) : LongInt;
Var H, NP : LongInt;
Begin
  FS_CHGFILEPTR := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then
  Begin
    FS_CHGFILEPTR := ERROR_INVALID_HANDLE;
    Exit;
  End;
  Case MType Of
    0 : NP := Offset;
    1 : NP := RL(Psffsi + 24) + Offset;
    2 : NP := Opens[H].Size + Offset;
  Else
    Begin
      FS_CHGFILEPTR := ERROR_INVALID_FUNCTION;
      Exit;
    End;
  End;
  If NP < 0 Then
  Begin
    FS_CHGFILEPTR := 131;                        { ERROR_NEGATIVE_SEEK }
    Exit;
  End;
  WL(Psffsi + 24, NP);
End;

Function FS_NEWSIZE(Psffsi, Psffsd, Len, IOFlag : LongInt) : LongInt;
Var H, D, R : LongInt; Q : Array[0..1] Of LongInt;
Begin
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else If Not Opens[H].Wr Then R := ERROR_ACCESS_DENIED
  Else
  Begin
    D := Opens[H].Drv;
    Q[0] := Len; Q[1] := 0;
    SmbEnter;
    OpenFid(H);
    R := SmbErr(SmbSetInfo(D, 20, LongInt(@Q[0]), 8));
    SmbLeave;
    If R = NO_ERROR Then
    Begin
      Opens[H].Size := Len;
      WL(Psffsi + 20, Len);
    End;
  End;
  FS_NEWSIZE := R;
End;

Function FS_COMMIT(CType, IOFlag, Psffsi, Psffsd : LongInt) : LongInt;
Var H, D, B : LongInt;
Begin
  FS_COMMIT := NO_ERROR;
  H := OpenOf(Psffsd);
  If H < 0 Then
  Begin
    FS_COMMIT := ERROR_INVALID_HANDLE;
    Exit;
  End;
  If Not Opens[H].Wr Then Exit;
  D := Opens[H].Drv;
  SmbEnter;
  SmbHdr(D, 7);                                  { FLUSH }
  B := SmbTx + 68;
  WW(B, 24);
  OpenFid(H);
  PutFid(B + 8);
  SmbCall(D, 24);
  SmbLeave;
End;

{ informations d'un fichier ouvert : niveau 1 (heures, attributs) }
Function FS_FILEINFO(Flag, Psffsi, Psffsd, Level, PData, CbData, IOFlag : LongInt) : LongInt;
Var H, D, R, T, A : LongInt;
Begin
  H := OpenOf(Psffsd);
  If H < 0 Then R := ERROR_INVALID_HANDLE
  Else If (Level <> 1) And (Level <> 2) Then R := ERROR_INVALID_LEVEL
  Else If (Flag And 1) = 0 Then
    R := PutStatus(PData, CbData, Level, Opens[H].Attr, Opens[H].Size, RL(Psffsi + 16))
  Else If CbData < 22 Then R := ERROR_BUFFER_OVERFLOW
  Else
  Begin
    D := Opens[H].Drv;
    T := (RW(PData + 8) Shl 16) Or RW(PData + 10);
    A := -1;
    If CbData >= 24 Then A := RL(PData + 20);
    SmbEnter;
    OpenFid(H);
    R := SmbErr(SmbSetBasic(D, T, A));
    SmbLeave;
    If R = NO_ERROR Then
    Begin
      If T <> 0 Then WL(Psffsi + 16, T);
      If A >= 0 Then Opens[H].Attr := A And $27;
    End;
  End;
  FS_FILEINFO := R;
End;

{ ouvrir Rel pour en changer les informations (FILE_WRITE_ATTRIBUTES) }
Function SetPathBasic(D : LongInt; Rel : String; T, A : LongInt) : LongInt;
Var St : LongInt;
Begin
  St := SmbCreate(D, Rel, $100, 0, 1, 0);
  If St = 0 Then
  Begin
    St := SmbSetBasic(D, T, A);
    SmbClose(D);
  End;
  SetPathBasic := SmbErr(St);
End;

Function FS_PATHINFO(Flag, Pcdfsi, Pcdfsd, PName, ICurDirEnd, Level, PData, CbData : LongInt) : LongInt;
Var D, R, T, A : LongInt; Rel, S : String;
Begin
  D := DrvOf(Pcdfsi, PName);
  If D < 0 Then
  Begin
    FS_PATHINFO := ERROR_INVALID_DRIVE;
    Exit;
  End;
  Rel := RelOf(PName);
  If HasWild(Rel) Then
  Begin
    FS_PATHINFO := ERROR_INVALID_NAME;
    Exit;
  End;
  R := NO_ERROR;
  If ((Level = 5) Or (Level = 7)) And ((Flag And 1) = 0) Then
  Begin
    S := Chr(65 + D) + ':\' + Rel;
    If Length(S) + 1 > CbData Then R := ERROR_BUFFER_OVERFLOW Else PutZ(PData, S, CbData);
    FS_PATHINFO := R;
    Exit;
  End;
  If (Level <> 1) And (Level <> 2) Then
  Begin
    FS_PATHINFO := ERROR_INVALID_LEVEL;
    Exit;
  End;
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then
  Begin
    If (Flag And 1) = 0 Then
    Begin
      R := SmbErr(StatPath(D, Rel));
      If R = NO_ERROR Then R := PutStatus(PData, CbData, Level, ScAttr, ScSize, ScTime);
    End
    Else If Rel = '' Then R := ERROR_ACCESS_DENIED
    Else If CbData < 22 Then R := ERROR_BUFFER_OVERFLOW
    Else
    Begin
      T := (RW(PData + 8) Shl 16) Or RW(PData + 10);
      A := -1;
      If CbData >= 24 Then A := RL(PData + 20);
      R := SetPathBasic(D, Rel, T, A);
    End;
  End;
  SmbLeave;
  FS_PATHINFO := R;
End;

Function FS_FILEATTRIBUTE(Flag, Pcdfsi, Pcdfsd, PName, ICurDirEnd, PAttr : LongInt) : LongInt;
Var D, R : LongInt; Rel : String;
Begin
  D := DrvOf(Pcdfsi, PName);
  If D < 0 Then
  Begin
    FS_FILEATTRIBUTE := ERROR_INVALID_DRIVE;
    Exit;
  End;
  Rel := RelOf(PName);
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then
  Begin
    If (Flag And 1) = 0 Then
    Begin
      R := SmbErr(StatPath(D, Rel));
      If R = NO_ERROR Then WW(PAttr, ScAttr And $37);
    End
    Else If Rel = '' Then R := ERROR_ACCESS_DENIED
    Else R := SetPathBasic(D, Rel, 0, RW(PAttr));
  End;
  SmbLeave;
  FS_FILEATTRIBUTE := R;
End;

{ supprimer un fichier ou un dossier vide (FileDispositionInformation) }
Function RemovePath(D : LongInt; Rel : String; Dir : Boolean) : LongInt;
Var R, St, Opt : LongInt; B : Byte;
Begin
  If Rel = '' Then
  Begin
    RemovePath := ERROR_ACCESS_DENIED;
    Exit;
  End;
  If Dir Then Opt := 1 Else Opt := $40;
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then
  Begin
    St := SmbCreate(D, Rel, $10080, 0, 1, Opt);
    If St = 0 Then
    Begin
      B := 1;
      St := SmbSetInfo(D, 13, LongInt(@B), 1);
      SmbClose(D);
    End;
    R := SmbErr(St);
    If Not Dir And (St = LongInt($C00000BA)) Then R := ERROR_ACCESS_DENIED;
  End;
  SmbLeave;
  RemovePath := R;
End;

Function FS_DELETE(Pcdfsi, Pcdfsd, PFile, ICurDirEnd : LongInt) : LongInt;
Var D : LongInt;
Begin
  D := DrvOf(Pcdfsi, PFile);
  If D < 0 Then FS_DELETE := ERROR_INVALID_DRIVE
  Else FS_DELETE := RemovePath(D, RelOf(PFile), False);
End;

Function FS_RMDIR(Pcdfsi, Pcdfsd, PName, ICurDirEnd : LongInt) : LongInt;
Var D : LongInt;
Begin
  D := DrvOf(Pcdfsi, PName);
  If D < 0 Then FS_RMDIR := ERROR_INVALID_DRIVE
  Else FS_RMDIR := RemovePath(D, RelOf(PName), True);
End;

Function FS_MKDIR(Pcdfsi, Pcdfsd, PName, ICurDirEnd, PEABuf, Flags : LongInt) : LongInt;
Var D, R, St : LongInt; Rel : String;
Begin
  D := DrvOf(Pcdfsi, PName);
  If D < 0 Then
  Begin
    FS_MKDIR := ERROR_INVALID_DRIVE;
    Exit;
  End;
  Rel := RelOf(PName);
  If (Rel = '') Or HasWild(Rel) Then
  Begin
    FS_MKDIR := ERROR_ACCESS_DENIED;
    Exit;
  End;
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then
  Begin
    St := SmbCreate(D, Rel, $100081, $10, 2, 1);
    If St = 0 Then SmbClose(D);
    R := SmbErr(St);
    If R = ERROR_FILE_EXISTS Then R := ERROR_ACCESS_DENIED;
  End;
  SmbLeave;
  FS_MKDIR := R;
End;

{ renommer ou deplacer dans le meme partage (FileRenameInformation) }
Function FS_MOVE(Pcdfsi, Pcdfsd, PSrc, ISrcEnd, PDst, IDstEnd, Flags : LongInt) : LongInt;
Var D, R, St, K : LongInt; I : Array[0..599] Of Byte; Src, Dst : String;
Begin
  D := DrvOf(Pcdfsi, PSrc);
  If D < 0 Then
  Begin
    FS_MOVE := ERROR_INVALID_DRIVE;
    Exit;
  End;
  If (PDst <> 0) And (RB(PDst + 1) = 58) Then
    If Ord(UpCase(Chr(RB(PDst)))) - 65 <> D Then
    Begin
      FS_MOVE := 17;                               { ERROR_NOT_SAME_DEVICE }
      Exit;
    End;
  Src := RelOf(PSrc); Dst := RelOf(PDst);
  If (Src = '') Or (Dst = '') Then
  Begin
    FS_MOVE := ERROR_ACCESS_DENIED;
    Exit;
  End;
  FillMem(LongInt(@I[0]), 20, 0);
  K := Uni(LongInt(@I[20]), Dst);
  WL(LongInt(@I[16]), K);
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then
  Begin
    St := SmbCreate(D, Src, $110080, 0, 1, 0);
    If St = 0 Then
    Begin
      St := SmbSetInfo(D, 10, LongInt(@I[0]), 20 + K);
      SmbClose(D);
    End;
    R := SmbErr(St);
    If R = ERROR_FILE_EXISTS Then R := ERROR_ACCESS_DENIED;
  End;
  SmbLeave;
  FS_MOVE := R;
End;

Function FS_COPY(Flag, Pcdfsi, Pcdfsd, PSrc, ISrcEnd, PDst, IDstEnd, NameType : LongInt) : LongInt;
Begin
  FS_COPY := ERROR_NOT_SUPPORTED;                  { le noyau copie lui-meme }
End;

{ verifier un repertoire courant (flag 0) }
Function FS_CHDIR(Flag, Pcdfsi, Pcdfsd, PDir, ICurDirEnd : LongInt) : LongInt;
Var D, R : LongInt;
Begin
  FS_CHDIR := NO_ERROR;
  If Flag <> 0 Then Exit;
  D := DrvOf(Pcdfsi, PDir);
  If D < 0 Then
  Begin
    FS_CHDIR := ERROR_INVALID_DRIVE;
    Exit;
  End;
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then
  Begin
    R := SmbErr(StatPath(D, RelOf(PDir)));
    If (R = NO_ERROR) And ((ScAttr And $10) = 0) Then R := ERROR_PATH_NOT_FOUND;
    If R = ERROR_FILE_NOT_FOUND Then R := ERROR_PATH_NOT_FOUND;
  End;
  SmbLeave;
  FS_CHDIR := R;
End;

{ ---- recherches : le dossier est lu en entier (QUERY_DIRECTORY,
  FileBothDirectoryInformation) dans un tampon de la recherche ;
  enregistrements : attributs, taille, heure DOS, nom (chaine Pascal) ---- }

Function ListDir(F : LongInt; Rel : String) : LongInt;
Var D, St, B, R, E, Nx, P, I, Sz, NL : LongInt; First : Boolean; Nm : String; Fid : Array[0..3] Of LongInt;
Begin
  D := Finds[F].Drv;
  St := SmbCreate(D, Rel, $100081, 0, 1, 1);
  If St <> 0 Then
  Begin
    St := SmbErr(St);
    If St = ERROR_FILE_NOT_FOUND Then St := ERROR_PATH_NOT_FOUND;
    ListDir := St;
    Exit;
  End;
  For I := 0 To 3 Do Fid[I] := ScFid[I];
  P := 0; First := True; Finds[F].N := 0;
  Repeat
    SmbHdr(D, $0E);
    B := SmbTx + 68;
    WW(B, 33); WB(B + 2, 3);
    If First Then WB(B + 3, 1);
    For I := 0 To 3 Do WL(B + 8 + I * 4, Fid[I]);
    WW(B + 24, 96); WW(B + 26, 2);
    WL(B + 28, SmbChunk);
    WW(B + 32, Ord('*'));
    St := SmbCall(D, 34);
    First := False;
    If St <> 0 Then Break;
    R := SmbRx + RW(SmbRx + 66);
    E := R;
    Repeat
      NL := RL(E + 60) Div 2;
      Nm := '';
      For I := 0 To MinL(NL, 255) - 1 Do
        If RW(E + 94 + I * 2) < 256 Then Nm := Nm + Chr(RW(E + 94 + I * 2)) Else Nm := Nm + '_';
      If Not (((Nm = '.') Or (Nm = '..')) And (Rel = '')) And (P + 300 + 13 < FindCap) Then
      Begin
        Sz := RL(E + 40);
        If (RL(E + 44) <> 0) Or (Sz < 0) Then Sz := $7FFFFFFF;
        WL(Finds[F].Buf + P, RL(E + 56) And $37);
        If (RL(E + 56) And $37) And $10 <> 0 Then Sz := 0;
        WL(Finds[F].Buf + P + 4, Sz);
        WL(Finds[F].Buf + P + 8, FtDos(RL(E + 24), RL(E + 28)));
        WB(Finds[F].Buf + P + 12, Length(Nm));
        MoveMem(LongInt(@Nm[1]), Finds[F].Buf + P + 13, Length(Nm));
        P := P + 13 + Length(Nm);
        Inc(Finds[F].N);
      End;
      Nx := RL(E);
      E := E + Nx;
    Until Nx = 0;
  Until False;
  { fin de la liste : enregistrement de nom vide }
  If P + 13 <= FindCap Then FillMem(Finds[F].Buf + P, 13, 0);
  For I := 0 To 3 Do ScFid[I] := Fid[I];
  SmbClose(D);
  Finds[F].Pos := 0;
  If (St = LongInt($80000006)) Or (St = 0) Then ListDir := NO_ERROR Else ListDir := SmbErr(St);
End;

{ entrees suivantes (niveaux 1 et 2) a partir de l'enregistrement Pos }
Function DoFind(F, PData, CbData, PcMatch, Level : LongInt) : LongInt;
Var Want, Cnt, FPos, Prev, P, A, Sz, T, NPos, Need, R : LongInt; Nm : String;
Begin
  If (Level <> 1) And (Level <> 2) Then
  Begin
    DoFind := ERROR_INVALID_LEVEL;
    Exit;
  End;
  Want := RL(PcMatch);
  If Want <= 0 Then Want := 1;
  If Level = 2 Then NPos := 32 Else NPos := 28;
  Cnt := 0; FPos := 0; Prev := -1;
  R := NO_ERROR;
  While Cnt < Want Do
  Begin
    { enregistrement suivant qui convient }
    Nm := '';
    While Finds[F].Pos >= 0 Do
    Begin
      If Finds[F].Pos + 13 > FindCap Then
      Begin
        Finds[F].Pos := -1;
        Break;
      End;
      P := Finds[F].Buf + Finds[F].Pos;
      If RB(P + 12) = 0 Then
      Begin
        Finds[F].Pos := -1;
        Break;
      End;
      Nm[0] := Chr(RB(P + 12));
      MoveMem(P + 13, LongInt(@Nm[1]), Length(Nm));
      A := RL(P); Sz := RL(P + 4); T := RL(P + 8);
      Finds[F].Pos := Finds[F].Pos + 13 + Length(Nm);
      If MatchMask(Nm, Finds[F].Mask) And AttrOk(A, Finds[F].Attr) Then Break;
      Nm := '';
    End;
    If Nm = '' Then Break;
    If Prev >= 0 Then FPos := (FPos + 3) And Not 3;
    Need := NPos + 2 + Length(Nm);
    If FPos + Need > CbData Then
    Begin
      { plus de place : l'entree sera rendue au prochain appel }
      Finds[F].Pos := Finds[F].Pos - 13 - Length(Nm);
      If Cnt = 0 Then R := ERROR_BUFFER_OVERFLOW;
      Break;
    End;
    WL(PData + FPos, 0);
    WW(PData + FPos + 4, (T Shr 16) And $FFFF); WW(PData + FPos + 6, T And $FFFF);
    WW(PData + FPos + 8, (T Shr 16) And $FFFF); WW(PData + FPos + 10, T And $FFFF);
    WW(PData + FPos + 12, (T Shr 16) And $FFFF); WW(PData + FPos + 14, T And $FFFF);
    WL(PData + FPos + 16, Sz);
    WL(PData + FPos + 20, ((Sz + 4095) Div 4096) * 4096);
    WL(PData + FPos + 24, A);
    If Level = 2 Then WL(PData + FPos + 28, 4);
    WB(PData + FPos + NPos, Length(Nm));
    PutZ(PData + FPos + NPos + 1, Nm, Length(Nm) + 1);
    If Prev >= 0 Then WL(PData + Prev, FPos - Prev);
    Prev := FPos;
    FPos := FPos + Need;
    Inc(Cnt);
  End;
  WL(PcMatch, Cnt);
  If (Cnt = 0) And (R = NO_ERROR) Then R := ERROR_NO_MORE_FILES;
  DoFind := R;
End;

Function FindOf(Pfsfsd : LongInt) : LongInt;
Var F : LongInt;
Begin
  FindOf := -1;
  If Pfsfsd = 0 Then Exit;
  If RL(Pfsfsd + 4) <> SFD_MAGIC Then Exit;
  F := RL(Pfsfsd) - 1;
  If (F >= 0) And (F < MaxFind) Then
    If Finds[F].Used Then FindOf := F;
End;

Procedure FindFree(F : LongInt);
Begin
  If Finds[F].Buf <> 0 Then DosFreeMem(Finds[F].Buf);
  Finds[F].Buf := 0;
  Finds[F].Used := False;
End;

Function FS_FINDFIRST(Pcdfsi, Pcdfsd, PName, ICurDirEnd, Attr, Pfsfsi, Pfsfsd, PData, CbData,
                      PcMatch, Level, Flags : LongInt) : LongInt;
Var D, R, F, I, K : LongInt; Rel, Dir, Mask : String;
Begin
  D := DrvOf(Pcdfsi, PName);
  If D < 0 Then
  Begin
    If PcMatch <> 0 Then WL(PcMatch, 0);
    FS_FINDFIRST := ERROR_INVALID_DRIVE;
    Exit;
  End;
  Rel := RelOf(PName);
  K := Length(Rel);
  While (K > 0) And (Rel[K] <> '\') Do Dec(K);
  Dir := Copy(Rel, 1, K - 1);
  If K = 0 Then Dir := '';
  Mask := Copy(Rel, K + 1, 255);
  If Mask = '' Then Mask := '*';
  F := -1;
  For I := MaxFind - 1 DownTo 0 Do If Not Finds[I].Used Then F := I;
  If F < 0 Then
  Begin
    WL(PcMatch, 0);
    FS_FINDFIRST := ERROR_TOO_MANY_OPEN_FILES;
    Exit;
  End;
  Finds[F].Used := True; Finds[F].Drv := D; Finds[F].Attr := Attr; Finds[F].Mask := Mask;
  Finds[F].Buf := 0;
  If DosAllocMem(LongInt(@Finds[F].Buf), FindCap, $13) <> 0 Then Finds[F].Buf := 0;
  If Finds[F].Buf = 0 Then
  Begin
    Finds[F].Used := False;
    WL(PcMatch, 0);
    FS_FINDFIRST := ERROR_NOT_ENOUGH_MEMORY;
    Exit;
  End;
  FillMem(Finds[F].Buf, 16, 0);
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then R := ListDir(F, Dir);
  SmbLeave;
  If R = NO_ERROR Then
  Begin
    WL(Pfsfsd, F + 1);
    WL(Pfsfsd + 4, SFD_MAGIC);
    R := DoFind(F, PData, CbData, PcMatch, Level);
  End
  Else WL(PcMatch, 0);
  If R <> NO_ERROR Then
  Begin
    FindFree(F);
    If Pfsfsd <> 0 Then WL(Pfsfsd + 4, 0);
  End;
  FS_FINDFIRST := R;
End;

Function FS_FINDNEXT(Pfsfsi, Pfsfsd, PData, CbData, PcMatch, Level, Flag : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := FindOf(Pfsfsd);
  If F < 0 Then FS_FINDNEXT := ERROR_INVALID_HANDLE
  Else FS_FINDNEXT := DoFind(F, PData, CbData, PcMatch, Level);
End;

Function FS_FINDFROMNAME(Pfsfsi, Pfsfsd, PData, CbData, PcMatch, Level, Position, PName, Flags : LongInt) : LongInt;
Begin
  FS_FINDFROMNAME := FS_FINDNEXT(Pfsfsi, Pfsfsd, PData, CbData, PcMatch, Level, Flags);
End;

Function FS_FINDCLOSE(Pfsfsi, Pfsfsd : LongInt) : LongInt;
Var F : LongInt;
Begin
  F := FindOf(Pfsfsd);
  If F >= 0 Then
  Begin
    FindFree(F);
    WL(Pfsfsd + 4, 0);
  End;
  FS_FINDCLOSE := NO_ERROR;
End;

{ niveau 1 : FSALLOCATE (FileFsSizeInformation) ; niveau 2 : FSINFO (nom
  du volume : le nom du partage) }
Function FS_FSINFO(Flag, HVpb, PData, CbData, Level : LongInt) : LongInt;
Var D, R, St, B, Q, I : LongInt; S : String;
Begin
  D := HVpb;
  If (D < 0) Or (D >= MaxNd) Or Not Nd[D].Used Then
  Begin
    FS_FSINFO := ERROR_INVALID_DRIVE;
    Exit;
  End;
  If (Flag And 1) <> 0 Then
  Begin
    FS_FSINFO := ERROR_ACCESS_DENIED;
    Exit;
  End;
  If Level = 2 Then
  Begin
    If CbData < 17 Then
    Begin
      FS_FSINFO := ERROR_BUFFER_OVERFLOW;
      Exit;
    End;
    FillMem(PData, 17, 0);
    S := UpStr(Copy(Nd[D].Share, 1, 11));
    WB(PData + 4, Length(S));
    For I := 1 To Length(S) Do WB(PData + 4 + I, Ord(S[I]));
    FS_FSINFO := NO_ERROR;
    Exit;
  End;
  If Level <> 1 Then
  Begin
    FS_FSINFO := ERROR_INVALID_LEVEL;
    Exit;
  End;
  If CbData < 18 Then
  Begin
    FS_FSINFO := ERROR_BUFFER_OVERFLOW;
    Exit;
  End;
  { valeurs de moins de 5 s (Lecteurs, DosQueryCurrentDisk) }
  If (Nd[D].SpcT <> 0) And (KTicks - Nd[D].SpcT < 5000) Then
  Begin
    WL(PData, 0);
    WL(PData + 4, Nd[D].CSpc); WL(PData + 8, Nd[D].CTot);
    WL(PData + 12, Nd[D].CFree); WW(PData + 16, Nd[D].CBps);
    FS_FSINFO := NO_ERROR;
    Exit;
  End;
  SmbEnter;
  R := NdEnsure(D);
  If R = NO_ERROR Then
  Begin
    St := SmbCreate(D, '', $100081, 0, 1, 1);
    R := SmbErr(St);
    If St = 0 Then
    Begin
      SmbHdr(D, $10);                              { QUERY_INFO }
      B := SmbTx + 68;
      WW(B, 41); WB(B + 2, 2); WB(B + 3, 3);
      WL(B + 4, 24);
      PutFid(B + 24);
      St := SmbCall(D, 41);
      R := SmbErr(St);
      If St = 0 Then
      Begin
        Q := SmbRx + RW(SmbRx + 66);
        WL(PData, 0);
        WL(PData + 4, RL(Q + 16));        { secteurs par unite }
        If (RL(Q + 4) <> 0) Or (RL(Q) < 0) Then WL(PData + 8, $7FFFFFFF)
        Else WL(PData + 8, RL(Q));
        If (RL(Q + 12) <> 0) Or (RL(Q + 8) < 0) Then WL(PData + 12, $7FFFFFFF)
        Else WL(PData + 12, RL(Q + 8));
        WW(PData + 16, RL(Q + 20));       { octets par secteur }
        Nd[D].CSpc := RL(PData + 4); Nd[D].CTot := RL(PData + 8);
        Nd[D].CFree := RL(PData + 12); Nd[D].CBps := RW(PData + 16);
        Nd[D].SpcT := KTicks;
      End;
      SmbClose(D);
    End;
  End;
  SmbLeave;
  { serveur injoignable : l'unite reste attachee (valeurs nulles) }
  If (R <> NO_ERROR) And (R <> ERROR_ACCESS_DENIED) Then
  Begin
    WL(PData, 0); WL(PData + 4, 1); WL(PData + 8, 0);
    WL(PData + 12, 0); WW(PData + 16, 512);
    R := NO_ERROR;
  End;
  FS_FSINFO := R;
End;

Function FS_FLUSHBUF(HVpb, Flag : LongInt) : LongInt;
Begin
  FS_FLUSHBUF := NO_ERROR;
End;

Function FS_FSCTL(PArgdat, IArgType, Func, PParm, LenParm, PLenParmIO, PData, LenData, PLenDataIO : LongInt) : LongInt;
Begin
  FS_FSCTL := ERROR_INVALID_FUNCTION;
End;

Function FS_EXIT(Uid, Pid, Pdb : LongInt) : LongInt;
Begin
  FS_EXIT := NO_ERROR;
End;

{ arret du systeme : fermer les connexions }
Function FS_SHUTDOWN(SType, Reserved : LongInt) : LongInt;
Var D : LongInt;
Begin
  If SType = 1 Then
    For D := 0 To MaxNd - 1 Do
      If Nd[D].Used Then NdDrop(D);
  FS_SHUTDOWN := NO_ERROR;
End;

{ texte de la derniere erreur (ASCIIZ, Cb octets au plus) ; rend sa longueur }
Function SmbLastError(PBuf, Cb : LongInt) : LongInt;
Begin
  If (PBuf <> 0) And (Cb > 0) Then PutZ(PBuf, LastMsg, Cb);
  SmbLastError := Length(LastMsg);
End;

{ connexion en cours ou derniere connexion (FS_ATTACH) : P[0] etape (voir
  CnStep), P[1] 1 pendant la connexion, P[2] ms depuis le debut, P[3] ms
  dans l'etape, P[4] requetes SMB envoyees, P[5] reponses recues, P[6]
  octets envoyes, P[7] octets recus, P[8] adresse IPv4 du serveur (ordre
  du reseau), P[9] resultat (erreur OS/2), P[10..19] duree de chaque etape
  (ms) ; Cb : taille du tampon }
Function SmbStatus(P, Cb : LongInt) : LongInt;
Var I, T : LongInt;
Begin
  SmbStatus := ERROR_INVALID_PARAMETER;
  If (P = 0) Or (Cb < 80) Then Exit;
  T := KTicks;
  WL(P, CnStep); WL(P + 4, CnBusy);
  If CnBusy <> 0 Then
  Begin
    WL(P + 8, T - CnT0); WL(P + 12, T - CnStepT);
  End
  Else
  Begin
    WL(P + 8, CnStepT - CnT0 + CnMs[CnStep]); WL(P + 12, 0);
  End;
  WL(P + 16, CnTxN); WL(P + 20, CnRxN); WL(P + 24, CnTxB); WL(P + 28, CnRxB);
  WL(P + 32, CnIp); WL(P + 36, CnRes);
  For I := 0 To 9 Do WL(P + 40 + I * 4, CnMs[I]);
  SmbStatus := NO_ERROR;
End;

{ Annuler la connexion en cours (appele par un autre fil que celui de
  DosFSAttach) }
Function SmbCancel : LongInt;
Begin
  SmbCancel := NO_ERROR;
  If CnBusy = 0 Then Exit;
  CnAbort := True;
  If CnSock >= 0 Then SkAbort(CnSock);
  SkAbort(-1);
End;

Exports
  FS_ATTACH, FS_ATTRIBUTE, FS_CHDIR, FS_CHGFILEPTR, FS_CLOSE, FS_COMMIT, FS_COPY, FS_DELETE,
  FS_EXIT, FS_FILEATTRIBUTE, FS_FILEINFO, FS_FINDCLOSE, FS_FINDFIRST, FS_FINDFROMNAME,
  FS_FINDNEXT, FS_FLUSHBUF, FS_FSCTL, FS_FSINFO, FS_INIT, FS_MKDIR, FS_MOUNT, FS_MOVE,
  FS_NAME, FS_NEWSIZE, FS_OPENCREATE, FS_PATHINFO, FS_READ, FS_RMDIR, FS_SHUTDOWN, FS_WRITE,
  SmbLastError Name 'SMBLASTERROR',
  SmbStatus Name 'SMBSTATUS',
  SmbCancel Name 'SMBCANCEL';

BEGIN
  InitDone := False;
  FS_INIT(0, 0, 0);
END.
