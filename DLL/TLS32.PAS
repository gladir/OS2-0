{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque TLS32.DLL de OS/2-0 : connexions chiffrees TLS
                1.3 et TLS 1.2 (https://) sur les sockets de TCPIP32.DLL.
}

Library TLS32;

{$IMAGEBASE $00800000}
{$R-,S-,I-}

{ Compilation : OS2PC TLS32.PAS   (produit TLS32.DLL)

  Couche TLS (Transport Layer Security) au-dessus d'une socket TCP deja
  connectee de TCPIP32.DLL ; utilisee par le Navigateur Web (BROWSER.EXE)
  et WGET pour les adresses https://.

  Protocoles et algorithmes (tous ecrits ici, en Pascal) :
    - TLS 1.3 (RFC 8446) : suite TLS_AES_128_GCM_SHA256, echange de cles
      X25519, programme des cles HKDF-SHA256, messages chiffres de la
      poignee de main, NewSessionTicket ignores, KeyUpdate ;
    - TLS 1.2 (RFC 5246) si le serveur ne connait pas TLS 1.3 : suites
      ECDHE-RSA-AES128-GCM-SHA256 et ECDHE-ECDSA-AES128-GCM-SHA256 (C02Fh,
      C02Bh), courbe X25519, PRF de SHA-256 ;
    - SHA-256 (FIPS 180-4), HMAC (RFC 2104), HKDF (RFC 5869), AES-128
      (FIPS 197), GCM (SP 800-38D), X25519 (RFC 7748, arithmetique en
      base 2^8 d'apres l'implantation de reference de D. J. Bernstein) ;
    - extensions envoyees : server_name (SNI), supported_groups,
      ec_point_formats, signature_algorithms, supported_versions,
      key_share, psk_key_exchange_modes, renegotiation_info.
  La chaine de certificats du serveur est recue mais n'est PAS verifiee
  (pas de magasin d'autorites de certification) : la connexion est
  chiffree et protegee contre l'ecoute, pas contre un intermediaire
  actif qui se ferait passer pour le serveur. Les messages Finished des
  deux cotes sont verifies (integrite de la poignee de main).
  Les nombres aleatoires (cle privee X25519, nombres aleatoires du
  client) viennent d'un generateur SHA-256 alimente par le compteur de
  cycles du processeur (RDTSC) et l'horloge du systeme.
  Une connexion a la fois (le navigateur charge ses ressources l'une
  apres l'autre).

  Points d'entree (convention _System) :
    TLSOPEN(Sock, PHost)       poignee de main sur la socket connectee
                               Sock ; PHost : nom du serveur (ASCIIZ,
                               pour SNI) ; rend 1 (poignee de connexion)
                               ou -1 (TLSERROR donne la raison)
    TLSSEND(H, PBuf, Len)      envoie Len octets ; rend Len ou -1
    TLSRECV(H, PBuf, Len)      recoit au plus Len octets ; rend le nombre
                               d'octets, 0 a la fin (close_notify ou
                               fermeture TCP), -1 en cas d'erreur
    TLSCLOSE(H)                envoie close_notify (la socket reste a
                               fermer par soclose)
    TLSERROR(PBuf, Cb)         texte de la derniere erreur (ASCIIZ)
    TLSINFO(H)                 version (0304h TLS 1.3, 0303h TLS 1.2)
                               shl 16 or suite (1301h, C02Fh, C02Bh) }

Function Send(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'send';
Function Recv(S, B, L, F : LongInt) : LongInt; External 'TCPIP32' Name 'recv';
Function KTicks : LongInt; External 'DOSCALLS' Name 'GetTickCount';

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

Function NetSend(S, A, N : LongInt) : LongInt;
Begin
  NetSend := Send(S, A, N, 0);
End;

Function NetRecv(S, A, N : LongInt) : LongInt;
Begin
  NetRecv := Recv(S, A, N, 0);
End;

{ compteur de cycles du processeur (bits de poids faible) }
Function Rdtsc : LongInt;
Var V : LongInt;
Begin
  V := 0;
  asm
    db 0Fh, 31h
    mov V,eax
  end;
  Rdtsc := V;
End;

Function Ticks : LongInt;
Begin
  Ticks := KTicks;
End;

{ --- NOYAU TLS : debut (partage avec l'essai sur l'hote) --- }

{ ==================================================================== }
{ Constantes et variables                                               }
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
  { SHA-256("HelloRetryRequest") : nombre aleatoire d'un HelloRetryRequest }
  HrrRand : Array[0..31] Of Byte = (
    $CF, $21, $AD, $74, $E5, $9A, $61, $11, $BE, $1D, $8C, $02, $1E, $65, $B8, $91,
    $C2, $A2, $11, $16, $7A, $BB, $8C, $5E, $07, $9E, $09, $E2, $C8, $A8, $33, $9C);

  NCTX = 8;            { contextes SHA-256 }
  RECMAX = 18432;      { corps d'un enregistrement TLS (16 Ko + 2 Ko) }
  NETCAP = 20480;
  HSCAP = 65536;

  { decalages dans Sec : secrets de la connexion }
  SC_HS = 0; SC_CHS = 32; SC_SHS = 64; SC_MS = 96; SC_CAP = 160; SC_SAP = 192; SC_EMPTY = 224;

Type
  TBlk = Array[0..15] Of Byte;
  TFe = Array[0..31] Of LongInt;

Var
  { SHA-256 }
  ShH : Array[0..63] Of LongInt;
  ShB : Array[0..511] Of Byte;
  ShN, ShT : Array[0..7] Of LongInt;
  { HMAC, HKDF, PRF }
  HmK : Array[0..63] Of Byte;
  HmIn : Array[0..31] Of Byte;
  HkInfo : Array[0..319] Of Byte;
  HkT : Array[0..95] Of Byte;
  HkM : Array[0..415] Of Byte;
  PrS : Array[0..255] Of Byte;
  PrA : Array[0..31] Of Byte;
  PrM : Array[0..319] Of Byte;
  PrO : Array[0..127] Of Byte;
  { AES et GCM (0 : ecriture du client, 1 : lecture) }
  Xt2 : Array[0..255] Of Byte;
  AesRk : Array[0..351] Of Byte;
  GH : Array[0..7] Of LongInt;
  GX : Array[0..3] Of LongInt;
  GIv : Array[0..23] Of Byte;
  GSeq : Array[0..1] Of LongInt;
  GNonce : Array[0..15] Of Byte;
  GAad : Array[0..15] Of Byte;
  { aleatoire }
  RPool : Array[0..31] Of Byte;
  RTmp : Array[0..63] Of Byte;
  RCnt : LongInt;
  { connexion }
  TSock, TVer, TSuite, TState : LongInt;
  TErr : String;
  WEnc, REnc, CertReq, TEof, RecV1 : Boolean;
  CRand, SRand, SessId : Array[0..31] Of Byte;
  XPriv, XPub, XPeer, XShared : Array[0..31] Of Byte;
  Sec : Array[0..255] Of Byte;
  THash, TVd : Array[0..31] Of Byte;
  KBuf : Array[0..63] Of Byte;
  Zero32 : Array[0..31] Of Byte;
  NetB : Array[0..NETCAP - 1] Of Byte;
  NetP, NetN : LongInt;
  RecB : Array[0..RECMAX + 63] Of Byte;
  PlB : Array[0..RECMAX + 63] Of Byte;
  PlP, PlN : LongInt;
  HsB : Array[0..HSCAP - 1] Of Byte;
  HsN : LongInt;
  TxB : Array[0..RECMAX + 63] Of Byte;
  HsOut : Array[0..1023] Of Byte;
  SniName : String;

{ ==================================================================== }
{ Operations de 32 bits                                                 }
{ ==================================================================== }

{ decalage logique a droite (1 <= N <= 31) }
Function Sr(X, N : LongInt) : LongInt;
Begin
  Sr := (X Shr N) And ($7FFFFFFF Shr (N - 1));
End;

Function Ror(X, N : LongInt) : LongInt;
Begin
  Ror := Sr(X, N) Or (X Shl (32 - N));
End;

Procedure MoveB(S, D, N : LongInt);
Var K : LongInt;
Begin
  If (D > S) And (D < S + N) Then
  Begin
    For K := N - 1 DownTo 0 Do WrB(D + K, RdB(S + K));
  End
  Else
    For K := 0 To N - 1 Do WrB(D + K, RdB(S + K));
End;

Function SameB(A, B, N : LongInt) : Boolean;
Var K, D : LongInt;
Begin
  D := 0;
  For K := 0 To N - 1 Do D := D Or (RdB(A + K) Xor RdB(B + K));
  SameB := D = 0;
End;

{ ==================================================================== }
{ SHA-256                                                               }
{ ==================================================================== }

Procedure ShaInit(C : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 7 Do ShH[C * 8 + I] := ShIv[I];
  ShN[C] := 0; ShT[C] := 0;
End;

Procedure ShaBlock(C : LongInt);
Var W : Array[0..63] Of LongInt;
    A, B, Cc, D, E, F, G, H, T1, T2, I, P, X : LongInt;
Begin
  P := C * 64;
  For I := 0 To 15 Do
    W[I] := (ShB[P + I * 4] Shl 24) Or (ShB[P + I * 4 + 1] Shl 16) Or (ShB[P + I * 4 + 2] Shl 8) Or ShB[P + I * 4 + 3];
  For I := 16 To 63 Do
  Begin
    X := W[I - 15];
    T1 := Ror(X, 7) Xor Ror(X, 18) Xor Sr(X, 3);
    X := W[I - 2];
    T2 := Ror(X, 17) Xor Ror(X, 19) Xor Sr(X, 10);
    W[I] := W[I - 16] + T1 + W[I - 7] + T2;
  End;
  P := C * 8;
  A := ShH[P]; B := ShH[P + 1]; Cc := ShH[P + 2]; D := ShH[P + 3];
  E := ShH[P + 4]; F := ShH[P + 5]; G := ShH[P + 6]; H := ShH[P + 7];
  For I := 0 To 63 Do
  Begin
    T1 := H + (Ror(E, 6) Xor Ror(E, 11) Xor Ror(E, 25)) + ((E And F) Xor ((Not E) And G)) + ShK[I] + W[I];
    T2 := (Ror(A, 2) Xor Ror(A, 13) Xor Ror(A, 22)) + ((A And B) Xor (A And Cc) Xor (B And Cc));
    H := G; G := F; F := E; E := D + T1;
    D := Cc; Cc := B; B := A; A := T1 + T2;
  End;
  ShH[P] := ShH[P] + A; ShH[P + 1] := ShH[P + 1] + B; ShH[P + 2] := ShH[P + 2] + Cc;
  ShH[P + 3] := ShH[P + 3] + D; ShH[P + 4] := ShH[P + 4] + E; ShH[P + 5] := ShH[P + 5] + F;
  ShH[P + 6] := ShH[P + 6] + G; ShH[P + 7] := ShH[P + 7] + H;
End;

Procedure ShaByte(C, V : LongInt);
Begin
  ShB[C * 64 + ShN[C]] := V And 255;
  Inc(ShN[C]);
  If ShN[C] = 64 Then
  Begin
    ShaBlock(C);
    ShN[C] := 0;
  End;
End;

Procedure ShaUpd(C, A, N : LongInt);
Var K : LongInt;
Begin
  For K := 0 To N - 1 Do ShaByte(C, RdB(A + K));
  ShT[C] := ShT[C] + N;
End;

Procedure ShaFinal(C, OutA : LongInt);
Var L, I, V : LongInt;
Begin
  L := ShT[C];
  ShaByte(C, $80);
  While ShN[C] <> 56 Do ShaByte(C, 0);
  ShaByte(C, 0); ShaByte(C, 0); ShaByte(C, 0);
  ShaByte(C, Sr(L, 29));
  V := L Shl 3;
  ShaByte(C, Sr(V, 24)); ShaByte(C, Sr(V, 16)); ShaByte(C, Sr(V, 8)); ShaByte(C, V);
  For I := 0 To 7 Do
  Begin
    V := ShH[C * 8 + I];
    WrB(OutA + I * 4, Sr(V, 24)); WrB(OutA + I * 4 + 1, Sr(V, 16));
    WrB(OutA + I * 4 + 2, Sr(V, 8)); WrB(OutA + I * 4 + 3, V);
  End;
End;

Procedure ShaCopy(D, S : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 7 Do ShH[D * 8 + I] := ShH[S * 8 + I];
  For I := 0 To 63 Do ShB[D * 64 + I] := ShB[S * 64 + I];
  ShN[D] := ShN[S]; ShT[D] := ShT[S];
End;

{ condensat de la transcription (contexte 0) sans la clore }
Procedure TransHash(OutA : LongInt);
Begin
  ShaCopy(7, 0);
  ShaFinal(7, OutA);
End;

{ ==================================================================== }
{ HMAC-SHA256, HKDF (TLS 1.3), PRF (TLS 1.2)                            }
{ ==================================================================== }

Procedure Hmac(KA, KN, MA, MN, OutA : LongInt);
Var I : LongInt;
Begin
  For I := 0 To 63 Do HmK[I] := 0;
  If KN > 64 Then
  Begin
    ShaInit(3); ShaUpd(3, KA, KN); ShaFinal(3, LongInt(@HmK));
  End
  Else
    For I := 0 To KN - 1 Do HmK[I] := RdB(KA + I);
  ShaInit(1);
  For I := 0 To 63 Do ShaByte(1, HmK[I] Xor $36);
  ShT[1] := 64;
  ShaUpd(1, MA, MN);
  ShaFinal(1, LongInt(@HmIn));
  ShaInit(2);
  For I := 0 To 63 Do ShaByte(2, HmK[I] Xor $5C);
  ShT[2] := 64;
  ShaUpd(2, LongInt(@HmIn), 32);
  ShaFinal(2, OutA);
End;

{ HKDF-Expand-Label(Secret, Label, Context, L) ; L <= 64 }
Procedure ExpandLabel(SecA : LongInt; Lbl : String; CtxA, CtxN, OutA, L : LongInt);
Var N, I, K, M : LongInt; S : String;
Begin
  S := 'tls13 ' + Lbl;
  HkInfo[0] := L Shr 8; HkInfo[1] := L And 255;
  HkInfo[2] := Length(S);
  For I := 1 To Length(S) Do HkInfo[2 + I] := Ord(S[I]);
  N := 3 + Length(S);
  HkInfo[N] := CtxN; Inc(N);
  For I := 0 To CtxN - 1 Do HkInfo[N + I] := RdB(CtxA + I);
  N := N + CtxN;
  { T(1) = HMAC(secret, info | 01), T(2) = HMAC(secret, T(1) | info | 02) }
  K := 0; M := 0;
  While K < L Do
  Begin
    Inc(M);
    I := 0;
    If M > 1 Then
    Begin
      For I := 0 To 31 Do HkM[I] := HkT[(M - 2) * 32 + I];
      I := 32;
    End;
    MoveB(LongInt(@HkInfo), LongInt(@HkM) + I, N);
    HkM[I + N] := M;
    Hmac(SecA, 32, LongInt(@HkM), I + N + 1, LongInt(@HkT) + (M - 1) * 32);
    K := K + 32;
  End;
  MoveB(LongInt(@HkT), OutA, L);
End;

{ P_SHA256(secret, label | seed), L <= 128 octets }
Procedure Prf(SecA, SecN : LongInt; Lbl : String; SeedA, SeedN, OutA, L : LongInt);
Var N, I, K : LongInt;
Begin
  For I := 1 To Length(Lbl) Do PrS[I - 1] := Ord(Lbl[I]);
  N := Length(Lbl);
  MoveB(SeedA, LongInt(@PrS) + N, SeedN);
  N := N + SeedN;
  { A(1) = HMAC(secret, seed) }
  Hmac(SecA, SecN, LongInt(@PrS), N, LongInt(@PrA));
  K := 0;
  While K < L Do
  Begin
    MoveB(LongInt(@PrA), LongInt(@PrM), 32);
    MoveB(LongInt(@PrS), LongInt(@PrM) + 32, N);
    Hmac(SecA, SecN, LongInt(@PrM), 32 + N, LongInt(@PrO) + K);
    Hmac(SecA, SecN, LongInt(@PrA), 32, LongInt(@PrA));
    K := K + 32;
  End;
  MoveB(LongInt(@PrO), OutA, L);
End;

{ ==================================================================== }
{ AES-128 (chiffrement seulement : mode compteur de GCM)                }
{ ==================================================================== }

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

Procedure AesKey(D, KA : LongInt);
Var I, P, J : LongInt; T : Array[0..3] Of Byte; Rc, X : LongInt;
Begin
  P := D * 176;
  For I := 0 To 15 Do AesRk[P + I] := RdB(KA + I);
  Rc := 1;
  I := 16;
  While I < 176 Do
  Begin
    For J := 0 To 3 Do T[J] := AesRk[P + I - 4 + J];
    If (I Mod 16) = 0 Then
    Begin
      X := T[0];
      T[0] := SBox[T[1]] Xor Rc; T[1] := SBox[T[2]]; T[2] := SBox[T[3]]; T[3] := SBox[X];
      Rc := Xt2[Rc];
    End;
    For J := 0 To 3 Do AesRk[P + I + J] := AesRk[P + I - 16 + J] Xor T[J];
    I := I + 4;
  End;
End;

Procedure AesEnc(D : LongInt; Var S : TBlk);
Var T : TBlk; R, C, P, A0, A1, A2, A3, I : LongInt;
Begin
  P := D * 176;
  For I := 0 To 15 Do S[I] := S[I] Xor AesRk[P + I];
  For R := 1 To 10 Do
  Begin
    { SubBytes + ShiftRows }
    For C := 0 To 3 Do
    Begin
      T[C * 4] := SBox[S[C * 4]];
      T[C * 4 + 1] := SBox[S[((C + 1) And 3) * 4 + 1]];
      T[C * 4 + 2] := SBox[S[((C + 2) And 3) * 4 + 2]];
      T[C * 4 + 3] := SBox[S[((C + 3) And 3) * 4 + 3]];
    End;
    If R < 10 Then
    Begin
      { MixColumns }
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
    For I := 0 To 15 Do S[I] := S[I] Xor AesRk[P + R * 16 + I];
  End;
End;

{ ==================================================================== }
{ GCM : GHASH dans GF(2^128) et mode compteur                           }
{ ==================================================================== }

Procedure GcmInit(D, KA : LongInt);
Var B : TBlk; I : LongInt;
Begin
  AesKey(D, KA);
  For I := 0 To 15 Do B[I] := 0;
  AesEnc(D, B);
  For I := 0 To 3 Do
    GH[D * 4 + I] := (B[I * 4] Shl 24) Or (B[I * 4 + 1] Shl 16) Or (B[I * 4 + 2] Shl 8) Or B[I * 4 + 3];
End;

{ GX := GX * H }
Procedure GfMul(D : LongInt);
Var Z0, Z1, Z2, Z3, V0, V1, V2, V3, W, I, J, L : LongInt;
Begin
  Z0 := 0; Z1 := 0; Z2 := 0; Z3 := 0;
  V0 := GH[D * 4]; V1 := GH[D * 4 + 1]; V2 := GH[D * 4 + 2]; V3 := GH[D * 4 + 3];
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
      If L <> 0 Then V0 := V0 Xor $E1000000;
    End;
  End;
  GX[0] := Z0; GX[1] := Z1; GX[2] := Z2; GX[3] := Z3;
End;

{ ajouter un bloc (N <= 16 octets, complete par des zeros) }
Procedure GhashBlk(D, A, N : LongInt);
Var B : TBlk; I : LongInt;
Begin
  For I := 0 To 15 Do
    If I < N Then B[I] := RdB(A + I) Else B[I] := 0;
  For I := 0 To 3 Do
    GX[I] := GX[I] Xor ((B[I * 4] Shl 24) Or (B[I * 4 + 1] Shl 16) Or (B[I * 4 + 2] Shl 8) Or B[I * 4 + 3]);
  GfMul(D);
End;

{ chiffrer (Dec faux) ou dechiffrer (Dec vrai) N octets de InA vers OutA
  (InA = OutA permis) avec le nombre a usage unique de GNonce (12
  octets) et les donnees associees AadA ; etiquette en TagA (ecrite au
  chiffrement, comparee au dechiffrement) }
Function GcmRun(D, AadA, AadN, InA, N, OutA, TagA : LongInt; Dec : Boolean) : Boolean;
Var Ctr, E : TBlk; K, I, M, C : LongInt;
Begin
  GX[0] := 0; GX[1] := 0; GX[2] := 0; GX[3] := 0;
  K := 0;
  While K < AadN Do
  Begin
    M := AadN - K;
    If M > 16 Then M := 16;
    GhashBlk(D, AadA + K, M);
    K := K + 16;
  End;
  C := 2;
  K := 0;
  While K < N Do
  Begin
    M := N - K;
    If M > 16 Then M := 16;
    If Dec Then GhashBlk(D, InA + K, M);
    For I := 0 To 11 Do Ctr[I] := GNonce[I];
    Ctr[12] := Sr(C, 24); Ctr[13] := Sr(C, 16) And 255; Ctr[14] := Sr(C, 8) And 255; Ctr[15] := C And 255;
    AesEnc(D, Ctr);
    For I := 0 To M - 1 Do WrB(OutA + K + I, RdB(InA + K + I) Xor Ctr[I]);
    If Not Dec Then GhashBlk(D, OutA + K, M);
    Inc(C);
    K := K + 16;
  End;
  { longueurs en bits }
  GX[0] := GX[0] Xor Sr(AadN, 29); GX[1] := GX[1] Xor (AadN Shl 3);
  GX[2] := GX[2] Xor Sr(N, 29); GX[3] := GX[3] Xor (N Shl 3);
  GfMul(D);
  For I := 0 To 11 Do E[I] := GNonce[I];
  E[12] := 0; E[13] := 0; E[14] := 0; E[15] := 1;
  AesEnc(D, E);
  For I := 0 To 3 Do
  Begin
    E[I * 4] := E[I * 4] Xor Sr(GX[I], 24);
    E[I * 4 + 1] := E[I * 4 + 1] Xor (Sr(GX[I], 16) And 255);
    E[I * 4 + 2] := E[I * 4 + 2] Xor (Sr(GX[I], 8) And 255);
    E[I * 4 + 3] := E[I * 4 + 3] Xor (GX[I] And 255);
  End;
  GcmRun := True;
  If Dec Then
  Begin
    M := 0;
    For I := 0 To 15 Do M := M Or (E[I] Xor RdB(TagA + I));
    GcmRun := M = 0;
  End
  Else
    For I := 0 To 15 Do WrB(TagA + I, E[I]);
End;

{ ==================================================================== }
{ X25519 (base 2^8, 32 chiffres)                                        }
{ ==================================================================== }

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

Procedure FeSq(Var O : TFe; Var A : TFe);
Begin
  FeMul(O, A, A);
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

{ O := Z^(p-2) = 1/Z }
Procedure FeInv(Var O : TFe; Var Z : TFe);
Var Z2, Z9, Z11, Z50, Z100, Z200, Z250, T0, T1 : TFe; I : LongInt;
Begin
  FeSq(Z2, Z);                       { 2 }
  FeSq(T1, Z2);                      { 4 }
  FeSq(T0, T1);                      { 8 }
  FeMul(Z9, T0, Z);                  { 9 }
  FeMul(Z11, Z9, Z2);                { 11 }
  FeSq(T0, Z11);                     { 22 }
  FeMul(Z50, T0, Z9);                { 2^5 - 1 }
  T0 := Z50;
  For I := 1 To 5 Do FeSq(T0, T0);
  FeMul(Z100, T0, Z50);              { 2^10 - 1 }
  T0 := Z100;
  For I := 1 To 10 Do FeSq(T0, T0);
  FeMul(Z200, T0, Z100);             { 2^20 - 1 }
  T0 := Z200;
  For I := 1 To 20 Do FeSq(T0, T0);
  FeMul(T1, T0, Z200);               { 2^40 - 1 }
  For I := 1 To 10 Do FeSq(T1, T1);
  FeMul(Z250, T1, Z100);             { 2^50 - 1 }
  T0 := Z250;
  For I := 1 To 50 Do FeSq(T0, T0);
  FeMul(Z200, T0, Z250);             { 2^100 - 1 }
  T0 := Z200;
  For I := 1 To 100 Do FeSq(T0, T0);
  FeMul(T1, T0, Z200);               { 2^200 - 1 }
  For I := 1 To 50 Do FeSq(T1, T1);
  FeMul(T0, T1, Z250);               { 2^250 - 1 }
  For I := 1 To 5 Do FeSq(T0, T0);   { 2^255 - 2^5 }
  FeMul(O, T0, Z11);                 { 2^255 - 21 }
End;

{ Q := X25519(N, P) ; adresses de 32 octets }
Procedure X25519(QA, NA, PA : LongInt);
Var E : Array[0..31] Of Byte;
    U, Xm, Zm, Xm1, Zm1, Xb, Zb, Xb1, Zb1, A0x, A0z, A1x, A1z, B0x, B0z, B1x, B1z,
    C1x, C1z, R, S, T, Uu, Xn, Zn, Xn1, Zn1 : TFe;
    J, Pos, Bit : LongInt;
Begin
  For J := 0 To 31 Do E[J] := RdB(NA + J);
  E[0] := E[0] And 248;
  E[31] := (E[31] And 127) Or 64;
  For J := 0 To 31 Do
  Begin
    U[J] := RdB(PA + J);
    Xm1[J] := U[J]; Zm1[J] := 0; Xm[J] := 0; Zm[J] := 0;
  End;
  U[31] := U[31] And 127; Xm1[31] := U[31];
  Zm1[0] := 1; Xm[0] := 1;
  For Pos := 254 DownTo 0 Do
  Begin
    Bit := (E[Pos Div 8] Shr (Pos And 7)) And 1;
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
    FeSq(B0x, A0x);
    FeSq(B0z, A0z);
    FeMul(B1x, A1x, A0z);
    FeMul(B1z, A1z, A0x);
    FeAdd(C1x, B1x, B1z);
    FeSub(C1z, B1x, B1z);
    FeSq(R, C1z);
    FeSub(S, B0x, B0z);
    FeMul121665(T, S);
    FeAdd(Uu, T, B0x);
    FeMul(Xn, B0x, B0z);
    FeMul(Zn, S, Uu);
    FeSq(Xn1, C1x);
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
  For J := 0 To 31 Do WrB(QA + J, R[J]);
End;

{ ==================================================================== }
{ Nombres aleatoires                                                    }
{ ==================================================================== }

Procedure RandStir;
Var V, I : LongInt;
Begin
  ShaInit(4);
  ShaUpd(4, LongInt(@RPool), 32);
  For I := 1 To 4 Do
  Begin
    V := Rdtsc;
    ShaByte(4, V); ShaByte(4, Sr(V, 8)); ShaByte(4, Sr(V, 16)); ShaByte(4, Sr(V, 24));
  End;
  V := Ticks;
  ShaByte(4, V); ShaByte(4, Sr(V, 8)); ShaByte(4, Sr(V, 16)); ShaByte(4, Sr(V, 24));
  Inc(RCnt);
  ShaByte(4, RCnt); ShaByte(4, Sr(RCnt, 8));
  ShT[4] := ShT[4] + 26;
  ShaFinal(4, LongInt(@RPool));
End;

Procedure RandFill(A, N : LongInt);
Var K, I, M : LongInt;
Begin
  K := 0;
  While K < N Do
  Begin
    RandStir;
    ShaInit(4);
    ShaUpd(4, LongInt(@RPool), 32);
    ShaByte(4, $5A); ShT[4] := ShT[4] + 1;
    ShaFinal(4, LongInt(@RTmp));
    M := N - K;
    If M > 32 Then M := 32;
    For I := 0 To M - 1 Do WrB(A + K + I, RTmp[I]);
    K := K + 32;
  End;
End;

{ ==================================================================== }
{ Enregistrements TLS                                                   }
{ ==================================================================== }

Procedure Fail(S : String);
Begin
  If TErr = '' Then TErr := S;
  TState := 0;
End;

Function SendAll(A, N : LongInt) : Boolean;
Var K, R : LongInt;
Begin
  SendAll := False;
  K := 0;
  While K < N Do
  Begin
    R := NetSend(TSock, A + K, N - K);
    If R <= 0 Then
    Begin
      Fail('Envoi impossible (connexion fermee).');
      Exit;
    End;
    K := K + R;
  End;
  SendAll := True;
End;

{ nombre a usage unique : IV xor numero de sequence (TLS 1.3) ou sel
  et numero explicite (TLS 1.2) }
Procedure MakeNonce(D : LongInt);
Var I, S : LongInt;
Begin
  S := GSeq[D];
  If TVer = $0304 Then
  Begin
    For I := 0 To 11 Do GNonce[I] := GIv[D * 12 + I];
    GNonce[8] := GNonce[8] Xor Sr(S, 24);
    GNonce[9] := GNonce[9] Xor (Sr(S, 16) And 255);
    GNonce[10] := GNonce[10] Xor (Sr(S, 8) And 255);
    GNonce[11] := GNonce[11] Xor (S And 255);
  End
  Else
  Begin
    For I := 0 To 3 Do GNonce[I] := GIv[D * 12 + I];
    For I := 4 To 7 Do GNonce[I] := 0;
    GNonce[8] := Sr(S, 24); GNonce[9] := Sr(S, 16) And 255; GNonce[10] := Sr(S, 8) And 255; GNonce[11] := S And 255;
  End;
End;

{ un enregistrement de type Typ (donnees : N octets en A, N <= 16384) }
Function SendRec(Typ, A, N : LongInt) : Boolean;
Var L : LongInt;
Begin
  SendRec := False;
  If Not WEnc Then
  Begin
    TxB[0] := Typ; TxB[1] := 3; TxB[2] := 3;
    If RecV1 Then TxB[2] := 1;
    TxB[3] := N Shr 8; TxB[4] := N And 255;
    MoveB(A, LongInt(@TxB) + 5, N);
    SendRec := SendAll(LongInt(@TxB), N + 5);
    Exit;
  End;
  MakeNonce(0);
  If TVer = $0304 Then
  Begin
    { TLSInnerPlaintext : donnees, type ; enregistrement application_data }
    MoveB(A, LongInt(@TxB) + 5, N);
    TxB[5 + N] := Typ;
    L := N + 1 + 16;
    TxB[0] := 23; TxB[1] := 3; TxB[2] := 3; TxB[3] := L Shr 8; TxB[4] := L And 255;
    GcmRun(0, LongInt(@TxB), 5, LongInt(@TxB) + 5, N + 1, LongInt(@TxB) + 5, LongInt(@TxB) + 5 + N + 1, False);
  End
  Else
  Begin
    { nonce explicite (8 octets) | chiffre | etiquette ; AAD : sequence,
      type, version, longueur }
    L := 8 + N + 16;
    TxB[0] := Typ; TxB[1] := 3; TxB[2] := 3; TxB[3] := L Shr 8; TxB[4] := L And 255;
    MoveB(LongInt(@GNonce) + 4, LongInt(@TxB) + 5, 8);
    MoveB(A, LongInt(@TxB) + 13, N);
    MoveB(LongInt(@GNonce) + 4, LongInt(@GAad), 8);
    GAad[8] := Typ; GAad[9] := 3; GAad[10] := 3; GAad[11] := N Shr 8; GAad[12] := N And 255;
    GcmRun(0, LongInt(@GAad), 13, LongInt(@TxB) + 13, N, LongInt(@TxB) + 13, LongInt(@TxB) + 13 + N, False);
  End;
  Inc(GSeq[0]);
  SendRec := SendAll(LongInt(@TxB), L + 5);
End;

{ avoir au moins Need octets dans NetB }
Function NetFill(Need : LongInt) : Boolean;
Var R : LongInt;
Begin
  NetFill := False;
  If NetN - NetP >= Need Then
  Begin
    NetFill := True;
    Exit;
  End;
  If NetP > 0 Then
  Begin
    MoveB(LongInt(@NetB) + NetP, LongInt(@NetB), NetN - NetP);
    NetN := NetN - NetP; NetP := 0;
  End;
  While NetN < Need Do
  Begin
    R := NetRecv(TSock, LongInt(@NetB) + NetN, NETCAP - NetN);
    If R <= 0 Then Exit;
    NetN := NetN + R;
  End;
  NetFill := True;
End;

{ lire un enregistrement : texte clair en PlB[0..Len-1], Typ (type
  interieur en TLS 1.3) ; faux a la fin de la connexion ou en cas
  d'erreur (TErr) }
Function ReadRec(Var Typ, Len : LongInt) : Boolean;
Var L, I, T : LongInt;
Begin
  ReadRec := False;
  Repeat
    If Not NetFill(5) Then
    Begin
      TEof := True;
      Exit;
    End;
    T := NetB[NetP];
    L := (NetB[NetP + 3] Shl 8) Or NetB[NetP + 4];
    If (L > RECMAX) Or (T < 20) Or (T > 24) Then
    Begin
      Fail('Enregistrement TLS non valable (type ' + Chr(48 + T Div 10) + Chr(48 + T Mod 10) + ').');
      Exit;
    End;
    If Not NetFill(5 + L) Then
    Begin
      TEof := True;
      Fail('Connexion fermee au milieu d''un enregistrement TLS.');
      Exit;
    End;
    For I := 0 To 4 Do GAad[I] := NetB[NetP + I];
    MoveB(LongInt(@NetB) + NetP + 5, LongInt(@RecB), L);
    NetP := NetP + 5 + L;
    { TLS 1.3 : ChangeCipherSpec de compatibilite ignore }
  Until Not ((T = 20) And (TVer = $0304));
  If (T = 20) Or Not REnc Then
  Begin
    MoveB(LongInt(@RecB), LongInt(@PlB), L);
    Typ := T; Len := L;
    ReadRec := True;
    Exit;
  End;
  MakeNonce(1);
  If TVer = $0304 Then
  Begin
    If (T <> 23) Or (L < 17) Then
    Begin
      Fail('Enregistrement TLS 1.3 non chiffre recu.');
      Exit;
    End;
    If Not GcmRun(1, LongInt(@GAad), 5, LongInt(@RecB), L - 16, LongInt(@PlB), LongInt(@RecB) + L - 16, True) Then
    Begin
      Fail('Enregistrement TLS altere (etiquette GCM incorrecte).');
      Exit;
    End;
    I := L - 17;
    While (I >= 0) And (PlB[I] = 0) Do Dec(I);
    If I < 0 Then
    Begin
      Fail('Enregistrement TLS 1.3 sans type.');
      Exit;
    End;
    Typ := PlB[I]; Len := I;
  End
  Else
  Begin
    If L < 24 Then
    Begin
      Fail('Enregistrement TLS 1.2 trop court.');
      Exit;
    End;
    For I := 0 To 7 Do GNonce[4 + I] := RecB[I];
    For I := 0 To 3 Do GAad[I] := 0;
    I := GSeq[1];
    GAad[4] := Sr(I, 24); GAad[5] := Sr(I, 16) And 255; GAad[6] := Sr(I, 8) And 255; GAad[7] := I And 255;
    GAad[8] := T; GAad[9] := 3; GAad[10] := 3;
    GAad[11] := (L - 24) Shr 8; GAad[12] := (L - 24) And 255;
    If Not GcmRun(1, LongInt(@GAad), 13, LongInt(@RecB) + 8, L - 24, LongInt(@PlB), LongInt(@RecB) + L - 16, True) Then
    Begin
      Fail('Enregistrement TLS altere (etiquette GCM incorrecte).');
      Exit;
    End;
    Typ := T; Len := L - 24;
  End;
  Inc(GSeq[1]);
  ReadRec := True;
End;

Function AlertText(D : LongInt) : String;
Var S : String;
Begin
  Case D Of
    0 : S := 'close_notify';
    10 : S := 'unexpected_message';
    20 : S := 'bad_record_mac';
    40 : S := 'handshake_failure';
    42 : S := 'bad_certificate';
    47 : S := 'illegal_parameter';
    50 : S := 'decode_error';
    51 : S := 'decrypt_error';
    70 : S := 'protocol_version';
    71 : S := 'insufficient_security';
    80 : S := 'internal_error';
    109 : S := 'missing_extension';
    110 : S := 'unsupported_extension';
    112 : S := 'unrecognized_name';
  Else
    S := '';
  End;
  If S = '' Then S := 'code ' + Chr(48 + (D Div 100) Mod 10) + Chr(48 + (D Div 10) Mod 10) + Chr(48 + D Mod 10);
  AlertText := S;
End;

{ message de la poignee de main suivant : type en HsB[0], longueur en
  HsB[1..3], corps en HsB[4..] }
Function HsNext(Var MT, BLen : LongInt) : Boolean;
Var Typ, Len : LongInt;
Begin
  HsNext := False;
  While (HsN < 4) Or (HsN < 4 + ((HsB[1] Shl 16) Or (HsB[2] Shl 8) Or HsB[3])) Do
  Begin
    If Not ReadRec(Typ, Len) Then
    Begin
      If TErr = '' Then Fail('Le serveur a ferme la connexion pendant la poignee de main TLS.');
      Exit;
    End;
    If Typ = 21 Then
    Begin
      If Len >= 2 Then Fail('Le serveur refuse la connexion TLS (alerte ' + AlertText(PlB[1]) + ').')
      Else Fail('Alerte TLS du serveur.');
      Exit;
    End;
    If Typ = 20 Then
    Begin
      { TLS 1.2 : ChangeCipherSpec du serveur, la suite est chiffree }
      REnc := True;
      GSeq[1] := 0;
    End
    Else If Typ = 22 Then
    Begin
      If HsN + Len > HSCAP Then
      Begin
        Fail('Message de poignee de main TLS trop grand.');
        Exit;
      End;
      MoveB(LongInt(@PlB), LongInt(@HsB) + HsN, Len);
      HsN := HsN + Len;
    End
    Else
    Begin
      Fail('Message inattendu pendant la poignee de main TLS.');
      Exit;
    End;
  End;
  MT := HsB[0];
  BLen := (HsB[1] Shl 16) Or (HsB[2] Shl 8) Or HsB[3];
  HsNext := True;
End;

{ retirer le message courant (et l'ajouter a la transcription) }
Procedure HsDone(Trans : Boolean);
Var L : LongInt;
Begin
  L := 4 + ((HsB[1] Shl 16) Or (HsB[2] Shl 8) Or HsB[3]);
  If Trans Then ShaUpd(0, LongInt(@HsB), L);
  MoveB(LongInt(@HsB) + L, LongInt(@HsB), HsN - L);
  HsN := HsN - L;
End;

{ envoyer un message de la poignee de main (HsOut, N octets avec en-tete) }
Function SendHs(N : LongInt) : Boolean;
Begin
  ShaUpd(0, LongInt(@HsOut), N);
  SendHs := SendRec(22, LongInt(@HsOut), N);
End;

{ ==================================================================== }
{ Poignee de main                                                       }
{ ==================================================================== }

Procedure Put2(Var N : LongInt; V : LongInt);
Begin
  HsOut[N] := Sr(V, 8) And 255; HsOut[N + 1] := V And 255;
  N := N + 2;
End;

Procedure Put1(Var N : LongInt; V : LongInt);
Begin
  HsOut[N] := V And 255;
  Inc(N);
End;

Function IsIpLiteral(S : String) : Boolean;
Var I : LongInt; Ok : Boolean;
Begin
  Ok := Length(S) > 0;
  For I := 1 To Length(S) Do
    If Not (((S[I] >= '0') And (S[I] <= '9')) Or (S[I] = '.') Or (S[I] = ':')) Then Ok := False;
  IsIpLiteral := Ok;
End;

Function SendClientHello : Boolean;
Var N, E, L, I, LP : LongInt;
Begin
  N := 0;
  Put1(N, 1); Put1(N, 0); Put2(N, 0);          { type, longueur (plus loin) }
  Put2(N, $0303);
  For I := 0 To 31 Do Put1(N, CRand[I]);
  Put1(N, 32);
  For I := 0 To 31 Do Put1(N, SessId[I]);
  Put2(N, 6); Put2(N, $1301); Put2(N, $C02F); Put2(N, $C02B);
  Put1(N, 1); Put1(N, 0);
  LP := N; Put2(N, 0);                         { longueur des extensions }
  E := N;
  If (SniName <> '') And Not IsIpLiteral(SniName) Then
  Begin
    L := Length(SniName);
    Put2(N, 0); Put2(N, L + 5); Put2(N, L + 3); Put1(N, 0); Put2(N, L);
    For I := 1 To L Do Put1(N, Ord(SniName[I]));
  End;
  { groupes : X25519 (le seul de l'echange de cles) ; P-256 et P-384
    pour les certificats ECDSA des serveurs TLS 1.2 }
  Put2(N, $000A); Put2(N, 8); Put2(N, 6); Put2(N, $001D); Put2(N, $0017); Put2(N, $0018);
  Put2(N, $000B); Put2(N, 2); Put1(N, 1); Put1(N, 0);
  Put2(N, $000D); Put2(N, 20); Put2(N, 18);
  Put2(N, $0403); Put2(N, $0804); Put2(N, $0401); Put2(N, $0503); Put2(N, $0805);
  Put2(N, $0501); Put2(N, $0806); Put2(N, $0601); Put2(N, $0201);
  Put2(N, $002B); Put2(N, 5); Put1(N, 4); Put2(N, $0304); Put2(N, $0303);
  Put2(N, $0033); Put2(N, 38); Put2(N, 36); Put2(N, $001D); Put2(N, 32);
  For I := 0 To 31 Do Put1(N, XPub[I]);
  Put2(N, $002D); Put2(N, 2); Put1(N, 1); Put1(N, 1);
  Put2(N, $FF01); Put2(N, 1); Put1(N, 0);
  L := N - E;
  HsOut[LP] := L Shr 8; HsOut[LP + 1] := L And 255;
  L := N - 4;
  HsOut[1] := Sr(L, 16) And 255; HsOut[2] := Sr(L, 8) And 255; HsOut[3] := L And 255;
  SendClientHello := SendHs(N);
End;

{ cle et IV de trafic TLS 1.3 du secret en Sec + Off pour la direction D }
Procedure Keys13(D, Off : LongInt);
Begin
  ExpandLabel(LongInt(@Sec) + Off, 'key', 0, 0, LongInt(@KBuf), 16);
  ExpandLabel(LongInt(@Sec) + Off, 'iv', 0, 0, LongInt(@KBuf) + 16, 12);
  GcmInit(D, LongInt(@KBuf));
  MoveB(LongInt(@KBuf) + 16, LongInt(@GIv) + D * 12, 12);
  GSeq[D] := 0;
End;

{ Finished : HMAC(cle de fin du secret Off, condensat de la transcription) }
Procedure FinishedMac(Off : LongInt);
Begin
  ExpandLabel(LongInt(@Sec) + Off, 'finished', 0, 0, LongInt(@KBuf), 32);
  TransHash(LongInt(@THash));
  Hmac(LongInt(@KBuf), 32, LongInt(@THash), 32, LongInt(@TVd));
End;

Function Handshake13 : Boolean;
Var MT, BL, I : LongInt;
Begin
  Handshake13 := False;
  { secret partage et programme des cles }
  X25519(LongInt(@XShared), LongInt(@XPriv), LongInt(@XPeer));
  I := 0;
  For MT := 0 To 31 Do I := I Or XShared[MT];
  If I = 0 Then
  Begin
    Fail('Cle X25519 du serveur non valable.');
    Exit;
  End;
  { secret precoce = HKDF-Extract(0, 0) }
  Hmac(LongInt(@Zero32), 32, LongInt(@Zero32), 32, LongInt(@Sec) + SC_HS);
  ShaInit(5); ShaFinal(5, LongInt(@Sec) + SC_EMPTY);
  ExpandLabel(LongInt(@Sec) + SC_HS, 'derived', LongInt(@Sec) + SC_EMPTY, 32, LongInt(@KBuf), 32);
  Hmac(LongInt(@KBuf), 32, LongInt(@XShared), 32, LongInt(@Sec) + SC_HS);
  TransHash(LongInt(@THash));
  ExpandLabel(LongInt(@Sec) + SC_HS, 'c hs traffic', LongInt(@THash), 32, LongInt(@Sec) + SC_CHS, 32);
  ExpandLabel(LongInt(@Sec) + SC_HS, 's hs traffic', LongInt(@THash), 32, LongInt(@Sec) + SC_SHS, 32);
  ExpandLabel(LongInt(@Sec) + SC_HS, 'derived', LongInt(@Sec) + SC_EMPTY, 32, LongInt(@KBuf), 32);
  Hmac(LongInt(@KBuf), 32, LongInt(@Zero32), 32, LongInt(@Sec) + SC_MS);
  Keys13(0, SC_CHS);
  Keys13(1, SC_SHS);
  REnc := True;
  { EncryptedExtensions, CertificateRequest, Certificate,
    CertificateVerify, Finished }
  Repeat
    If Not HsNext(MT, BL) Then Exit;
    If MT = 20 Then
    Begin
      FinishedMac(SC_SHS);
      If (BL <> 32) Or Not SameB(LongInt(@TVd), LongInt(@HsB) + 4, 32) Then
      Begin
        Fail('Message Finished du serveur incorrect.');
        Exit;
      End;
    End
    Else If MT = 13 Then CertReq := True
    Else If Not ((MT = 8) Or (MT = 11) Or (MT = 15)) Then
    Begin
      Fail('Message de poignee de main TLS 1.3 inattendu.');
      Exit;
    End;
    HsDone(True);
  Until MT = 20;
  { secrets de trafic : transcription jusqu'au Finished du serveur }
  TransHash(LongInt(@THash));
  ExpandLabel(LongInt(@Sec) + SC_MS, 'c ap traffic', LongInt(@THash), 32, LongInt(@Sec) + SC_CAP, 32);
  ExpandLabel(LongInt(@Sec) + SC_MS, 's ap traffic', LongInt(@THash), 32, LongInt(@Sec) + SC_SAP, 32);
  { ChangeCipherSpec de compatibilite, puis Certificate vide si demande,
    puis Finished du client }
  HsOut[0] := 1;
  If Not SendRec(20, LongInt(@HsOut), 1) Then Exit;
  WEnc := True;
  If CertReq Then
  Begin
    HsOut[0] := 11; HsOut[1] := 0; HsOut[2] := 0; HsOut[3] := 4;
    HsOut[4] := 0; HsOut[5] := 0; HsOut[6] := 0; HsOut[7] := 0;
    If Not SendHs(8) Then Exit;
  End;
  FinishedMac(SC_CHS);
  HsOut[0] := 20; HsOut[1] := 0; HsOut[2] := 0; HsOut[3] := 32;
  MoveB(LongInt(@TVd), LongInt(@HsOut) + 4, 32);
  If Not SendHs(36) Then Exit;
  Keys13(0, SC_CAP);
  Keys13(1, SC_SAP);
  Handshake13 := True;
End;

Function Handshake12 : Boolean;
Var MT, BL, I : LongInt; Have : Boolean;
Begin
  Handshake12 := False;
  Have := False;
  Repeat
    If Not HsNext(MT, BL) Then Exit;
    If MT = 12 Then
    Begin
      { ServerKeyExchange ECDHE : courbe nommee X25519 }
      If (HsB[4] <> 3) Or (HsB[5] <> 0) Or (HsB[6] <> $1D) Or (HsB[7] <> 32) Then
      Begin
        Fail('Le serveur TLS 1.2 n''utilise pas la courbe X25519.');
        Exit;
      End;
      MoveB(LongInt(@HsB) + 8, LongInt(@XPeer), 32);
      Have := True;
    End
    Else If MT = 13 Then CertReq := True
    Else If Not ((MT = 11) Or (MT = 14) Or (MT = 22)) Then
    Begin
      Fail('Message de poignee de main TLS 1.2 inattendu.');
      Exit;
    End;
    HsDone(True);
  Until MT = 14;
  If Not Have Then
  Begin
    Fail('Echange de cles TLS 1.2 absent (ServerKeyExchange).');
    Exit;
  End;
  If CertReq Then
  Begin
    HsOut[0] := 11; HsOut[1] := 0; HsOut[2] := 0; HsOut[3] := 3;
    HsOut[4] := 0; HsOut[5] := 0; HsOut[6] := 0;
    If Not SendHs(7) Then Exit;
  End;
  HsOut[0] := 16; HsOut[1] := 0; HsOut[2] := 0; HsOut[3] := 33; HsOut[4] := 32;
  MoveB(LongInt(@XPub), LongInt(@HsOut) + 5, 32);
  If Not SendHs(37) Then Exit;
  X25519(LongInt(@XShared), LongInt(@XPriv), LongInt(@XPeer));
  { secret maitre et bloc de cles }
  MoveB(LongInt(@CRand), LongInt(@KBuf), 32);
  MoveB(LongInt(@SRand), LongInt(@KBuf) + 32, 32);
  Prf(LongInt(@XShared), 32, 'master secret', LongInt(@KBuf), 64, LongInt(@Sec) + SC_MS, 48);
  MoveB(LongInt(@SRand), LongInt(@KBuf), 32);
  MoveB(LongInt(@CRand), LongInt(@KBuf) + 32, 32);
  Prf(LongInt(@Sec) + SC_MS, 48, 'key expansion', LongInt(@KBuf), 64, LongInt(@Sec) + SC_CAP, 40);
  GcmInit(0, LongInt(@Sec) + SC_CAP);
  GcmInit(1, LongInt(@Sec) + SC_CAP + 16);
  MoveB(LongInt(@Sec) + SC_CAP + 32, LongInt(@GIv), 4);
  MoveB(LongInt(@Sec) + SC_CAP + 36, LongInt(@GIv) + 12, 4);
  GSeq[0] := 0; GSeq[1] := 0;
  HsOut[0] := 1;
  If Not SendRec(20, LongInt(@HsOut), 1) Then Exit;
  WEnc := True;
  TransHash(LongInt(@THash));
  HsOut[0] := 20; HsOut[1] := 0; HsOut[2] := 0; HsOut[3] := 12;
  Prf(LongInt(@Sec) + SC_MS, 48, 'client finished', LongInt(@THash), 32, LongInt(@HsOut) + 4, 12);
  If Not SendHs(16) Then Exit;
  { ChangeCipherSpec (HsNext) puis Finished du serveur }
  If Not HsNext(MT, BL) Then Exit;
  If Not REnc Then
  Begin
    Fail('ChangeCipherSpec du serveur absent.');
    Exit;
  End;
  TransHash(LongInt(@THash));
  Prf(LongInt(@Sec) + SC_MS, 48, 'server finished', LongInt(@THash), 32, LongInt(@TVd), 12);
  If (MT <> 20) Or (BL <> 12) Or Not SameB(LongInt(@TVd), LongInt(@HsB) + 4, 12) Then
  Begin
    Fail('Message Finished du serveur incorrect.');
    Exit;
  End;
  HsDone(True);
  I := 0;
  Handshake12 := True;
End;

Function TlsHandshake(Sock : LongInt; Host : String) : Boolean;
Var MT, BL, P, E, X, XL, I, SidL : LongInt;
Begin
  TlsHandshake := False;
  TSock := Sock; TVer := 0; TSuite := 0; TState := 0; TErr := '';
  WEnc := False; REnc := False; CertReq := False; TEof := False;
  NetP := 0; NetN := 0; PlP := 0; PlN := 0; HsN := 0;
  GSeq[0] := 0; GSeq[1] := 0;
  For I := 0 To 31 Do Zero32[I] := 0;
  SniName := Host;
  RandFill(LongInt(@CRand), 32);
  RandFill(LongInt(@SessId), 32);
  RandFill(LongInt(@XPriv), 32);
  For I := 0 To 31 Do RTmp[I] := 0;
  RTmp[0] := 9;
  X25519(LongInt(@XPub), LongInt(@XPriv), LongInt(@RTmp));
  ShaInit(0);
  RecV1 := True;
  If Not SendClientHello Then Exit;
  RecV1 := False;
  { ServerHello }
  If Not HsNext(MT, BL) Then Exit;
  If (MT <> 2) Or (BL < 38) Then
  Begin
    Fail('Reponse du serveur TLS non valable (ServerHello attendu).');
    Exit;
  End;
  MoveB(LongInt(@HsB) + 6, LongInt(@SRand), 32);
  If SameB(LongInt(@SRand), LongInt(@HrrRand), 32) Then
  Begin
    Fail('Le serveur TLS demande un autre groupe que X25519 (HelloRetryRequest).');
    Exit;
  End;
  TVer := (HsB[4] Shl 8) Or HsB[5];
  SidL := HsB[38];
  P := 39 + SidL;
  TSuite := (HsB[P] Shl 8) Or HsB[P + 1];
  P := P + 3;
  E := 4 + BL;
  XL := 0;
  If P + 2 <= E Then
  Begin
    P := P + 2;
    While P + 4 <= E Do
    Begin
      X := (HsB[P] Shl 8) Or HsB[P + 1];
      XL := (HsB[P + 2] Shl 8) Or HsB[P + 3];
      If (X = $002B) And (XL = 2) Then TVer := (HsB[P + 4] Shl 8) Or HsB[P + 5]
      Else If X = $0033 Then
      Begin
        If (HsB[P + 4] <> 0) Or (HsB[P + 5] <> $1D) Or (HsB[P + 7] <> 32) Then
        Begin
          Fail('Le serveur TLS a choisi un groupe autre que X25519.');
          Exit;
        End;
        MoveB(LongInt(@HsB) + P + 8, LongInt(@XPeer), 32);
      End;
      P := P + 4 + XL;
    End;
  End;
  HsDone(True);
  If TVer = $0304 Then
  Begin
    If TSuite <> $1301 Then
    Begin
      Fail('Suite TLS 1.3 non prise en charge.');
      Exit;
    End;
    If Not Handshake13 Then Exit;
  End
  Else If TVer = $0303 Then
  Begin
    If (TSuite <> $C02F) And (TSuite <> $C02B) Then
    Begin
      Fail('Suite TLS 1.2 non prise en charge par le serveur.');
      Exit;
    End;
    If Not Handshake12 Then Exit;
  End
  Else
  Begin
    Fail('Version de TLS non prise en charge (TLS 1.2 ou 1.3 requis).');
    Exit;
  End;
  TState := 1;
  TlsHandshake := True;
End;

{ donnees de l'application ; 0 : fin ; -1 : erreur }
Function TlsRead(A, N : LongInt) : LongInt;
Var Typ, Len, M, K : LongInt;
Begin
  TlsRead := -1;
  If TState <> 1 Then
  Begin
    If TEof Then TlsRead := 0;
    Exit;
  End;
  While PlP >= PlN Do
  Begin
    PlP := 0; PlN := 0;
    If Not ReadRec(Typ, Len) Then
    Begin
      If TEof And (TErr = '') Then
      Begin
        TState := 2;
        TlsRead := 0;
      End;
      Exit;
    End;
    If Typ = 23 Then PlN := Len
    Else If Typ = 21 Then
    Begin
      If (Len >= 2) And (PlB[1] = 0) Then
      Begin
        TEof := True;
        TState := 2;
        TlsRead := 0;
      End
      Else If Len >= 2 Then Fail('Alerte TLS du serveur (' + AlertText(PlB[1]) + ').')
      Else Fail('Alerte TLS du serveur.');
      Exit;
    End
    Else If (Typ = 22) And (TVer = $0304) And (Len >= 4) And (PlB[0] = 24) Then
    Begin
      { KeyUpdate : nouveau secret de lecture ; repondre si demande }
      ExpandLabel(LongInt(@Sec) + SC_SAP, 'traffic upd', 0, 0, LongInt(@Sec) + SC_SAP, 32);
      Keys13(1, SC_SAP);
      If (Len >= 5) And (PlB[4] = 1) Then
      Begin
        HsOut[0] := 24; HsOut[1] := 0; HsOut[2] := 0; HsOut[3] := 1; HsOut[4] := 0;
        If Not SendRec(22, LongInt(@HsOut), 5) Then Exit;
        ExpandLabel(LongInt(@Sec) + SC_CAP, 'traffic upd', 0, 0, LongInt(@Sec) + SC_CAP, 32);
        Keys13(0, SC_CAP);
      End;
    End;
    { autres messages (NewSessionTicket...) ignores }
  End;
  M := PlN - PlP;
  If M > N Then M := N;
  For K := 0 To M - 1 Do WrB(A + K, PlB[PlP + K]);
  PlP := PlP + M;
  TlsRead := M;
End;

Function TlsWrite(A, N : LongInt) : LongInt;
Var K, M : LongInt;
Begin
  TlsWrite := -1;
  If TState <> 1 Then Exit;
  K := 0;
  While K < N Do
  Begin
    M := N - K;
    If M > 16384 Then M := 16384;
    If Not SendRec(23, A + K, M) Then Exit;
    K := K + M;
  End;
  TlsWrite := N;
End;

Procedure TlsShut;
Begin
  If TState = 1 Then
  Begin
    HsOut[0] := 1; HsOut[1] := 0;
    SendRec(21, LongInt(@HsOut), 2);
  End;
  TState := 0;
End;

Procedure TlsInitTables;
Var I : LongInt;
Begin
  AesInitTables;
  For I := 0 To 31 Do RPool[I] := I;
  RCnt := 0;
  TState := 0; TErr := '';
End;

{ --- NOYAU TLS : fin --- }

{ ==================================================================== }
{ Points d'entree                                                       }
{ ==================================================================== }

Function GetZ(A : LongInt) : String;
Var S : String; C : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    C := RdB(A);
    While (C <> 0) And (Length(S) < 250) Do
    Begin
      S := S + Chr(C);
      Inc(A);
      C := RdB(A);
    End;
  End;
  GetZ := S;
End;

Function TlsOpen(Sock, PHost : LongInt) : LongInt;
Begin
  If TlsHandshake(Sock, GetZ(PHost)) Then TlsOpen := 1 Else TlsOpen := -1;
End;

Function TlsSend(H, PBuf, Len : LongInt) : LongInt;
Begin
  TlsSend := TlsWrite(PBuf, Len);
End;

Function TlsRecv(H, PBuf, Len : LongInt) : LongInt;
Begin
  TlsRecv := TlsRead(PBuf, Len);
End;

Function TlsClose(H : LongInt) : LongInt;
Begin
  TlsShut;
  TlsClose := 0;
End;

Function TlsError(PBuf, Cb : LongInt) : LongInt;
Var K : LongInt;
Begin
  K := 0;
  While (K < Length(TErr)) And (K < Cb - 1) Do
  Begin
    WrB(PBuf + K, Ord(TErr[K + 1]));
    Inc(K);
  End;
  If Cb > 0 Then WrB(PBuf + K, 0);
  TlsError := K;
End;

Function TlsInfo(H : LongInt) : LongInt;
Begin
  TlsInfo := (TVer Shl 16) Or TSuite;
End;

Exports
  TlsOpen Index 1 Name 'TLSOPEN',
  TlsSend Index 2 Name 'TLSSEND',
  TlsRecv Index 3 Name 'TLSRECV',
  TlsClose Index 4 Name 'TLSCLOSE',
  TlsError Index 5 Name 'TLSERROR',
  TlsInfo Index 6 Name 'TLSINFO';

BEGIN
  TlsInitTables;
END.
