{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 MONCALLS.DLL de OS/2-0 (moniteurs de
                peripheriques : DosMonOpen, DosMonReg, DosMonRead,
                DosMonWrite, DosMonClose).
}

Library MONCALLS;

{$IMAGEBASE $00CB0000}
{$R-,S-,I-}

{ Compilation : OS2PC MONCALLS.PAS   (produit MONCALLS.DLL)

  Un moniteur s'insere dans le flux de donnees d'un peripherique de
  caracteres : chaque paquet du peripherique passe par la chaine des
  moniteurs enregistres (DosMonReg) avant d'atteindre son destinataire
  habituel. Chaque moniteur lit les paquets dans son tampon d'entree
  (DosMonRead), peut les modifier, les supprimer ou en ajouter, et les
  rend au flux par son tampon de sortie (DosMonWrite) : ils vont au
  tampon d'entree du moniteur suivant, ou au peripherique apres le
  dernier.

  Peripheriques :
    KBD$     frappes du clavier, avant KBDCALLS.DLL et la console ;
    MOUSE$   paquets de la souris PS/2, avant MOUCALLS.DLL ;
    LPT1, LPT2, LPT3 (PRN = LPT1)
             donnees ecrites sur l'imprimante, avant le port parallele.
  Le noyau OS2KRNL detourne ces flux vers la chaine tant qu'elle compte
  au moins un moniteur (KrnMonIo) ; a la fin du processus qui l'a
  ouverte, la chaine est arretee et les paquets en attente rendus au
  peripherique. Les processus s'executant un a la fois, c'est le
  moniteur lui-meme qui fait avancer la chaine a chaque DosMonRead et
  DosMonWrite (avec DCWW_WAIT, DosMonRead interroge le peripherique
  toutes les 10 ms).

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires ; pcbDataBuf (DosMonRead) designe un LongInt. Les tampons de
  moniteur gardent la disposition d'OS/2 (MONIN, MONOUT) : cb (mot,
  taille totale du tampon, 64 octets au moins), 18 octets reserves au
  systeme, puis la zone des paquets. Exemple :
    Function DosMonRead(PInBuf, Wait, PData, PcbData : LongInt) : LongInt; External 'MONCALLS';

  Paquets :
    KBD$    14 octets : fsMonFlags (mot ; octet fort = code de balayage
            d'origine, bit 7 = touche relachee), KBDKEYINFO (chChar,
            chScan, fbStatus, bNlsShift, fsState, time), fsDD (mot :
            bits 0 a 5 = 0 caractere, 7 touche de changement d'etat ;
            40h touche relachee ; 80h prefixe E0h).
    MOUSE$  12 octets : fsMonFlags (mot), fs (mot, evenements comme
            MOUEVENTINFO), time (double mot, ms), row et col (mots
            signes : deplacement en mickeys).
    LPTn    fsMonFlags (mot) suivi des donnees (1 a 64 octets).
  Une touche modifiee par un moniteur (fbStatus <> 0) est rendue telle
  quelle a KBDCALLS.DLL et a la console ; un paquet du clavier avec
  fbStatus = 0 est retraduit a partir du code de balayage d'origine.

  Fonctions exportees (ordinaux d'origine de MONCALLS.DLL) :
     1 DosMonWrite    2 DosMonRead    3 DosMonClose    4 DosMonOpen
     5 DosMonReg

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services du noyau et de KBDCALLS.DLL
    Partie 3 - Utilitaires
    Partie 4 - Tampons de moniteur
    Partie 5 - Conversion des paquets
    Partie 6 - Chaines de moniteurs
    Partie 7 - Fonctions DosMon*
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR                   = 0;
  ERROR_TOO_MANY_OPEN_FILES  = 4;
  ERROR_NOT_ENOUGH_MEMORY    = 8;
  ERROR_MON_INVALID_PARMS    = 379;
  ERROR_MON_INVALID_DEVNAME  = 380;
  ERROR_MON_INVALID_HANDLE   = 381;
  ERROR_MON_BUFFER_TOO_SMALL = 382;
  ERROR_MON_BUFFER_EMPTY     = 383;
  ERROR_MON_DATA_TOO_LARGE   = 384;

  DCWW_WAIT       = 0;
  DCWW_NOWAIT     = 1;
  MONITOR_DEFAULT = 0;
  MONITOR_BEGIN   = 1;
  MONITOR_END     = 2;

  NDev    = 5;               { 0 KBD$, 1 MOUSE$, 2 a 4 LPT1 a LPT3 }
  MaxH    = 16;              { handles de DosMonOpen }
  MaxR    = 16;              { enregistrements (DosMonReg) }
  HdrSize = 20;              { cb + 18 octets reserves }
  MinBuf  = 64;
  Sig     = $4E4D;           { 'MN' : tampon enregistre }

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  HUsed  : Array[1..MaxH] Of Boolean;
  HDev   : Array[1..MaxH] Of LongInt;
  HPid   : Array[1..MaxH] Of LongInt;

  RUsed  : Array[1..MaxR] Of Boolean;
  RH     : Array[1..MaxR] Of LongInt;    { handle }
  RDev   : Array[1..MaxR] Of LongInt;
  RIn    : Array[1..MaxR] Of LongInt;    { tampon d'entree }
  ROut   : Array[1..MaxR] Of LongInt;    { tampon de sortie }
  RPos   : Array[1..MaxR] Of LongInt;    { MONITOR_DEFAULT, _BEGIN, _END }
  RPid   : Array[1..MaxR] Of LongInt;

  { chaines : Chain[Dev * MaxR + k], du peripherique vers le destinataire }
  Chain  : Array[0..NDev * MaxR - 1] Of LongInt;
  ChainN : Array[0..NDev - 1] Of LongInt;

  KRaw   : Array[0..23] Of LongInt;      { paquet du noyau }
  Pk     : Array[0..127] Of Byte;        { paquet de moniteur }
  Tr     : Array[0..31] Of Byte;         { KBDTRANS }

{ ==================================================================== }
{ Partie 2 - Services du noyau et de KBDCALLS.DLL                      }
{ ==================================================================== }

Function KrnMonIo(Dev, Op, P : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnMonIo';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KSleep(Ms : LongInt) : LongInt; External 'DOSCALLS' Name 'Sleep';
Function KbdXlate(PTr, Hkbd : LongInt) : LongInt; External 'KBDCALLS' Name 'KbdXlate';

{ ==================================================================== }
{ Partie 3 - Utilitaires                                               }
{ ==================================================================== }

Function RdL(A : LongInt) : LongInt;
Var P : PLong;
Begin
  P := Pointer(A);
  RdL := P^;
End;

Procedure WrL(A, V : LongInt);
Var P : PLong;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FFFF;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  If A = 0 Then Exit;
  P := Pointer(A);
  P^ := V And $FF;
End;

{ Copier N octets (vers le debut : les zones peuvent se chevaucher) }
Procedure CopyB(Src, Dst, N : LongInt);
Var I : LongInt;
Begin
  For I := 0 To N - 1 Do WrB(Dst + I, RdB(Src + I));
End;

{ Mot signe de 16 bits }
Function SW(V : LongInt) : LongInt;
Begin
  V := V And $FFFF;
  If V >= $8000 Then V := V - $10000;
  SW := V;
End;

Function GetZ(A : LongInt) : String;
Var S : String; N : LongInt;
Begin
  S := '';
  If A <> 0 Then
  Begin
    N := 0;
    While (RdB(A + N) <> 0) And (N < 255) Do
    Begin
      S := S + UpCase(Chr(RdB(A + N)));
      Inc(N);
    End;
  End;
  GetZ := S;
End;

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ Taille maximale d'un paquet du peripherique }
Function PktMax(Dev : LongInt) : LongInt;
Begin
  If Dev = 0 Then PktMax := 14
  Else If Dev = 1 Then PktMax := 12
  Else PktMax := 66;
End;

{ ==================================================================== }
{ Partie 4 - Tampons de moniteur                                       }
{ ==================================================================== }

{ Disposition (MONIN, MONOUT) : +0 cb ; zone reservee : +2 signature,
  +4 octets occupes, +6 nombre de paquets, +8 enregistrement ; +20
  paquets, chacun precede de sa longueur (mot). }

Function BufCount(B : LongInt) : LongInt;
Begin
  BufCount := RdW(B + 6);
End;

Function BufFits(B, N : LongInt) : Boolean;
Begin
  BufFits := RdW(B + 4) + 2 + N <= RdW(B) - HdrSize;
End;

Function BufPut(B, Src, N : LongInt) : Boolean;
Var U : LongInt;
Begin
  BufPut := False;
  If Not BufFits(B, N) Then Exit;
  U := RdW(B + 4);
  WrW(B + HdrSize + U, N);
  CopyB(Src, B + HdrSize + U + 2, N);
  WrW(B + 4, U + 2 + N);
  WrW(B + 6, RdW(B + 6) + 1);
  BufPut := True;
End;

{ Longueur du premier paquet (-1 : tampon vide) }
Function BufPeek(B : LongInt) : LongInt;
Begin
  If BufCount(B) = 0 Then BufPeek := -1
  Else BufPeek := RdW(B + HdrSize);
End;

{ Retirer le premier paquet (copie dans Dst si Dst <> 0) ; rend sa
  longueur }
Function BufGet(B, Dst : LongInt) : LongInt;
Var N, U : LongInt;
Begin
  N := BufPeek(B);
  If N >= 0 Then
  Begin
    If Dst <> 0 Then CopyB(B + HdrSize + 2, Dst, N);
    U := RdW(B + 4) - 2 - N;
    CopyB(B + HdrSize + 2 + N, B + HdrSize, U);
    WrW(B + 4, U);
    WrW(B + 6, RdW(B + 6) - 1);
  End;
  BufGet := N;
End;

Procedure BufInit(B, R : LongInt);
Var I : LongInt;
Begin
  For I := 2 To HdrSize - 1 Do WrB(B + I, 0);
  WrW(B + 2, Sig);
  WrW(B + 8, R);
End;

{ ==================================================================== }
{ Partie 5 - Conversion des paquets                                    }
{ ==================================================================== }

{ Paquet du noyau (KRaw) -> paquet de moniteur (Pk) ; rend sa longueur }
Function FromKernel(Dev : LongInt) : LongInt;
Var V, X, Sc, Fl, Dd, Ch, Scn, St, Fs, B, N, D, I : LongInt; Gray, Rel : Boolean;
Begin
  For I := 0 To 15 Do Pk[I] := 0;
  If Dev = 0 Then
  Begin
    V := KRaw[0];
    X := KRaw[1];
    Sc := (V Shr 8) And $7F;
    Gray := (X And $10000) <> 0;
    Rel := (X And $20000) <> 0;
    Fl := Sc;
    If Rel Then Fl := Fl Or $80;
    Dd := 0;
    If Gray Then Dd := $80;
    Ch := 0; Scn := Sc; St := 0;
    If (X And $40000) <> 0 Then
    Begin
      Dd := Dd Or 7;                     { touche de changement d'etat }
      St := $01;
      If Rel Then Dd := Dd Or $40;
    End
    Else If Rel Then
      Dd := Dd Or $40
    Else
    Begin
      For I := 0 To 31 Do Tr[I] := 0;
      If Gray Then Tr[0] := $E0;
      Tr[1] := Sc;
      Tr[4] := X And $FF;
      Tr[5] := (X Shr 8) And $FF;
      D := KbdXlate(LongInt(@Tr), 0);
      If D = 0 Then
      Begin
        Ch := Tr[0]; Scn := Tr[1]; St := Tr[2];
      End;
    End;
    WrW(LongInt(@Pk), Fl Shl 8);
    Pk[2] := Ch; Pk[3] := Scn; Pk[4] := St; Pk[5] := 0;
    WrW(LongInt(@Pk) + 6, X And $FFFF);
    WrL(LongInt(@Pk) + 8, KRaw[2]);
    WrW(LongInt(@Pk) + 12, Dd);
    FromKernel := 14;
  End
  Else If Dev = 1 Then
  Begin
    B := KRaw[2];
    Fs := 0;
    If (KRaw[0] <> 0) Or (KRaw[1] <> 0) Then
    Begin
      If (B And 1) <> 0 Then Fs := Fs Or $02;
      If (B And 2) <> 0 Then Fs := Fs Or $08;
      If (B And 4) <> 0 Then Fs := Fs Or $20;
      If Fs = 0 Then Fs := $01;
    End
    Else
    Begin
      If (B And 1) <> 0 Then Fs := Fs Or $04;
      If (B And 2) <> 0 Then Fs := Fs Or $10;
      If (B And 4) <> 0 Then Fs := Fs Or $40;
    End;
    WrW(LongInt(@Pk), 0);
    WrW(LongInt(@Pk) + 2, Fs);
    WrL(LongInt(@Pk) + 4, KRaw[3]);
    WrW(LongInt(@Pk) + 8, KRaw[1]);
    WrW(LongInt(@Pk) + 10, KRaw[0]);
    FromKernel := 12;
  End
  Else
  Begin
    N := KRaw[0];
    If N > 64 Then N := 64;
    WrW(LongInt(@Pk), 0);
    CopyB(LongInt(@KRaw) + 4, LongInt(@Pk) + 2, N);
    FromKernel := N + 2;
  End;
End;

{ Paquet de moniteur (Pk, longueur N) -> paquet du noyau (KRaw) }
Procedure ToKernel(Dev, N : LongInt);
Var Fl, Org, Dd, St, X, Fs, B : LongInt;
Begin
  If Dev = 0 Then
  Begin
    Fl := RdW(LongInt(@Pk));
    Org := (Fl Shr 8) And $FF;
    Dd := RdW(LongInt(@Pk) + 12);
    St := Pk[4];
    X := RdW(LongInt(@Pk) + 6);
    If (Dd And $80) <> 0 Then X := X Or $10000;
    If (Dd And $3F) = 7 Then
    Begin
      KRaw[0] := (Org And $7F) Shl 8;
      X := X Or $40000;
      If ((Org And $80) <> 0) Or ((Dd And $40) <> 0) Then X := X Or $20000;
    End
    Else If (Dd And $40) <> 0 Then
    Begin
      KRaw[0] := (Org And $7F) Shl 8;
      X := X Or $20000;
    End
    Else If St = 0 Then
      KRaw[0] := (Org And $7F) Shl 8       { retraduite par le destinataire }
    Else
    Begin
      KRaw[0] := (Pk[3] Shl 8) Or Pk[2];
      X := X Or $80000 Or (St Shl 24);
    End;
    KRaw[1] := X;
    KRaw[2] := RdL(LongInt(@Pk) + 8);
  End
  Else If Dev = 1 Then
  Begin
    Fs := RdW(LongInt(@Pk) + 2);
    B := 0;
    If (Fs And $06) <> 0 Then B := B Or 1;
    If (Fs And $18) <> 0 Then B := B Or 2;
    If (Fs And $60) <> 0 Then B := B Or 4;
    KRaw[0] := SW(RdW(LongInt(@Pk) + 10));
    KRaw[1] := SW(RdW(LongInt(@Pk) + 8));
    KRaw[2] := B;
    KRaw[3] := RdL(LongInt(@Pk) + 4);
  End
  Else
  Begin
    KRaw[0] := N - 2;
    CopyB(LongInt(@Pk) + 2, LongInt(@KRaw) + 4, N - 2);
  End;
End;

{ ==================================================================== }
{ Partie 6 - Chaines de moniteurs                                      }
{ ==================================================================== }

Function ChainAt(Dev, K : LongInt) : LongInt;
Begin
  ChainAt := Chain[Dev * MaxR + K];
End;

{ Rang de l'enregistrement R dans sa chaine (-1 : absent) }
Function ChainIdx(R : LongInt) : LongInt;
Var K, Q : LongInt;
Begin
  Q := -1;
  For K := 0 To ChainN[RDev[R]] - 1 Do
    If ChainAt(RDev[R], K) = R Then Q := K;
  ChainIdx := Q;
End;

{ Remettre un paquet (Pk, N) a l'etape K de la chaine : tampon d'entree
  du K-ieme moniteur, ou le peripherique si K = nombre de moniteurs }
Function Deliver(Dev, K, N : LongInt) : Boolean;
Begin
  If K >= ChainN[Dev] Then
  Begin
    ToKernel(Dev, N);
    Deliver := KrnMonIo(Dev, 2, LongInt(@KRaw)) <> 0;
  End
  Else
    Deliver := BufPut(RIn[ChainAt(Dev, K)], LongInt(@Pk), N);
End;

{ Faire avancer la chaine du peripherique Dev }
Procedure PumpDev(Dev : LongInt);
Var K, R, N, D : LongInt; Moved, Stop : Boolean;
Begin
  If ChainN[Dev] = 0 Then Exit;
  Repeat
    Moved := False;
    { des tampons de sortie vers l'etape suivante (la fin d'abord) }
    For K := ChainN[Dev] - 1 DownTo 0 Do
    Begin
      R := ChainAt(Dev, K);
      Stop := False;
      While (BufCount(ROut[R]) > 0) And Not Stop Do
      Begin
        N := BufPeek(ROut[R]);
        CopyB(ROut[R] + HdrSize + 2, LongInt(@Pk), N);
        If Deliver(Dev, K + 1, N) Then
        Begin
          D := BufGet(ROut[R], 0);
          Moved := True;
        End
        Else
          Stop := True;
      End;
    End;
    { du peripherique vers le premier moniteur }
    R := ChainAt(Dev, 0);
    Stop := False;
    While BufFits(RIn[R], PktMax(Dev)) And Not Stop Do
    Begin
      If KrnMonIo(Dev, 1, LongInt(@KRaw)) = 0 Then Stop := True
      Else
      Begin
        N := FromKernel(Dev);
        If BufPut(RIn[R], LongInt(@Pk), N) Then Moved := True;
      End;
    End;
  Until Not Moved;
End;

Procedure Pump(Dev : LongInt);
Var D : LongInt;
Begin
  If Dev >= 2 Then
  Begin
    For D := 2 To NDev - 1 Do PumpDev(D);
  End
  Else
    PumpDev(Dev);
End;

{ La chaine du peripherique est-elle active ? (surveillance du noyau) }
Procedure SyncKernel(Dev : LongInt);
Var D : LongInt;
Begin
  If ChainN[Dev] > 0 Then D := KrnMonIo(Dev, 0, 1)
  Else D := KrnMonIo(Dev, 0, 0);
End;

{ Retirer l'enregistrement R ; ses paquets en attente (sortie, puis
  entree) passent a l'etape suivante }
Procedure RemoveReg(R : LongInt);
Var Dev, K, I, N : LongInt; Ok : Boolean;
Begin
  Dev := RDev[R];
  K := ChainIdx(R);
  If K >= 0 Then
  Begin
    { retirer de la chaine : l'etape suivante devient K }
    For I := K To ChainN[Dev] - 2 Do Chain[Dev * MaxR + I] := Chain[Dev * MaxR + I + 1];
    Dec(ChainN[Dev]);
    While BufCount(ROut[R]) > 0 Do
    Begin
      N := BufGet(ROut[R], LongInt(@Pk));
      Ok := Deliver(Dev, K, N);
    End;
    While BufCount(RIn[R]) > 0 Do
    Begin
      N := BufGet(RIn[R], LongInt(@Pk));
      Ok := Deliver(Dev, K, N);
    End;
  End;
  WrW(RIn[R] + 2, 0);
  WrW(ROut[R] + 2, 0);
  RUsed[R] := False;
  SyncKernel(Dev);
End;

{ Ecarter les handles et enregistrements des processus termines }
Procedure Purge;
Var I : LongInt;
Begin
  For I := 1 To MaxR Do
    If RUsed[I] Then
      If KrnMonIo(0, 4, RPid[I]) = 0 Then RemoveReg(I);
  For I := 1 To MaxH Do
    If HUsed[I] Then
      If KrnMonIo(0, 4, HPid[I]) = 0 Then HUsed[I] := False;
End;

Function RegByBuf(B : LongInt; IsOut : Boolean) : LongInt;
Var I, R : LongInt;
Begin
  R := 0;
  If B <> 0 Then
    For I := 1 To MaxR Do
      If RUsed[I] Then
      Begin
        If IsOut And (ROut[I] = B) Then R := I;
        If (Not IsOut) And (RIn[I] = B) Then R := I;
      End;
  RegByBuf := R;
End;

Function BufInUse(B : LongInt) : Boolean;
Var I : LongInt; U : Boolean;
Begin
  U := False;
  For I := 1 To MaxR Do
    If RUsed[I] And ((RIn[I] = B) Or (ROut[I] = B)) Then U := True;
  BufInUse := U;
End;

Function HErr(H : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := ERROR_MON_INVALID_HANDLE;
  If (H >= 1) And (H <= MaxH) Then
    If HUsed[H] And (HPid[H] = MyPid) Then R := NO_ERROR;
  HErr := R;
End;

{ ==================================================================== }
{ Partie 7 - Fonctions DosMon*                                         }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  DosMonOpen(pszDevName, phmon) : ouvrir le peripherique "KBD$",
  "MOUSE$", "LPT1" a "LPT3" ou "PRN" pour le surveiller ; *phmon <-
  handle }
Function DosMonOpen(PName, PH : LongInt) : LongInt;
Var R, Dev, I, F : LongInt; S : String;
Begin
  Purge;
  R := NO_ERROR;
  S := GetZ(PName);
  If (Length(S) > 1) And (S[Length(S)] = ':') Then S := Copy(S, 1, Length(S) - 1);
  Dev := -1;
  If S = 'KBD$' Then Dev := 0
  Else If S = 'MOUSE$' Then Dev := 1
  Else If (S = 'PRN') Or (S = 'LPT1') Then Dev := 2
  Else If S = 'LPT2' Then Dev := 3
  Else If S = 'LPT3' Then Dev := 4;
  If PH = 0 Then R := ERROR_MON_INVALID_PARMS
  Else If Dev < 0 Then R := ERROR_MON_INVALID_DEVNAME
  Else If KrnMonIo(Dev, 5, 0) = 0 Then R := ERROR_MON_INVALID_DEVNAME   { absent }
  Else
  Begin
    F := 0;
    For I := MaxH DownTo 1 Do
      If Not HUsed[I] Then F := I;
    If F = 0 Then R := ERROR_TOO_MANY_OPEN_FILES
    Else
    Begin
      HUsed[F] := True;
      HDev[F] := Dev;
      HPid[F] := MyPid;
      WrL(PH, F);
    End;
  End;
  DosMonOpen := R;
End;

{ ---------------------------------------------------------------------
  DosMonReg(hmon, pbInBuf, pbOutBuf, fPosition, usIndex) : enregistrer
  les tampons d'entree et de sortie (MONIN, MONOUT : premier mot = taille,
  64 octets au moins) et commencer la surveillance.
  fPosition : MONITOR_DEFAULT (0), MONITOR_BEGIN (1, au plus pres du
  peripherique), MONITOR_END (2, au plus pres du destinataire).
  usIndex : session (0 ou 1, la session courante) pour KBD$ et MOUSE$,
  0 pour l'imprimante. }
Function DosMonReg(H, PIn, POut, Pos, Index : LongInt) : LongInt;
Var R, Dev, I, F, K, Need : LongInt;
Begin
  Purge;
  R := HErr(H);
  If R = NO_ERROR Then
  Begin
    Dev := HDev[H];
    Need := HdrSize + 2 + PktMax(Dev);
    If Need < MinBuf Then Need := MinBuf;
    If (PIn = 0) Or (POut = 0) Or (PIn = POut) Then R := ERROR_MON_INVALID_PARMS
    Else If (Pos < MONITOR_DEFAULT) Or (Pos > MONITOR_END) Then R := ERROR_MON_INVALID_PARMS
    Else If (Dev <= 1) And (Index <> 0) And (Index <> 1) Then R := ERROR_MON_INVALID_PARMS
    Else If (Dev >= 2) And (Index <> 0) Then R := ERROR_MON_INVALID_PARMS
    Else If BufInUse(PIn) Or BufInUse(POut) Then R := ERROR_MON_INVALID_PARMS
    Else If (RdW(PIn) < Need) Or (RdW(POut) < Need) Then R := ERROR_MON_BUFFER_TOO_SMALL;
  End;
  If R = NO_ERROR Then
  Begin
    F := 0;
    For I := MaxR DownTo 1 Do
      If Not RUsed[I] Then F := I;
    If F = 0 Then R := ERROR_NOT_ENOUGH_MEMORY
    Else
    Begin
      RUsed[F] := True;
      RH[F] := H;
      RDev[F] := Dev;
      RIn[F] := PIn;
      ROut[F] := POut;
      RPos[F] := Pos;
      RPid[F] := MyPid;
      BufInit(PIn, F);
      BufInit(POut, F);
      { place dans la chaine }
      If Pos = MONITOR_BEGIN Then K := 0
      Else If Pos = MONITOR_END Then K := ChainN[Dev]
      Else
      Begin
        K := ChainN[Dev];
        For I := ChainN[Dev] - 1 DownTo 0 Do
          If RPos[ChainAt(Dev, I)] = MONITOR_END Then K := I;
      End;
      For I := ChainN[Dev] DownTo K + 1 Do Chain[Dev * MaxR + I] := Chain[Dev * MaxR + I - 1];
      Chain[Dev * MaxR + K] := F;
      Inc(ChainN[Dev]);
      SyncKernel(Dev);
    End;
  End;
  DosMonReg := R;
End;

{ ---------------------------------------------------------------------
  DosMonRead(pbInBuf, fWaitFlag, pbDataBuf, pcbDataBuf) : lire le paquet
  suivant de la chaine dans le tampon d'entree. fWaitFlag DCWW_WAIT (0)
  : attendre un paquet ; DCWW_NOWAIT (1) : ERROR_MON_BUFFER_EMPTY s'il
  n'y en a pas. *pcbDataBuf : taille du tampon de donnees a l'entree,
  longueur du paquet a la sortie. }
Function DosMonRead(PIn, Wait, PData, PcbData : LongInt) : LongInt;
Var R, Rg, N, D : LongInt;
Begin
  Purge;
  R := NO_ERROR;
  Rg := RegByBuf(PIn, False);
  If (Rg = 0) Or (PData = 0) Or (PcbData = 0) Then R := ERROR_MON_INVALID_PARMS
  Else If (Wait <> DCWW_WAIT) And (Wait <> DCWW_NOWAIT) Then R := ERROR_MON_INVALID_PARMS
  Else If RPid[Rg] <> MyPid Then R := ERROR_MON_INVALID_PARMS;
  If R = NO_ERROR Then
  Begin
    Pump(RDev[Rg]);
    While (BufCount(PIn) = 0) And (Wait = DCWW_WAIT) Do
    Begin
      D := KSleep(10);
      Pump(RDev[Rg]);
    End;
    N := BufPeek(PIn);
    If N < 0 Then R := ERROR_MON_BUFFER_EMPTY
    Else If N > RdL(PcbData) Then R := ERROR_MON_DATA_TOO_LARGE
    Else
    Begin
      N := BufGet(PIn, PData);
      WrL(PcbData, N);
      Pump(RDev[Rg]);
    End;
  End;
  DosMonRead := R;
End;

{ ---------------------------------------------------------------------
  DosMonWrite(pbOutBuf, pbDataBuf, cbDataBuf) : rendre un paquet au flux
  par le tampon de sortie ; il passe au moniteur suivant ou au
  peripherique. Si le tampon de sortie est plein, la chaine est d'abord
  avancee ; s'il le reste (moniteur suivant qui ne lit pas),
  ERROR_MON_DATA_TOO_LARGE. Paquets : 14 octets pour KBD$, 12 pour
  MOUSE$, 2 a 66 pour l'imprimante. }
Function DosMonWrite(POut, PData, Cb : LongInt) : LongInt;
Var R, Rg, Dev : LongInt; Ok : Boolean;
Begin
  Purge;
  R := NO_ERROR;
  Rg := RegByBuf(POut, True);
  If (Rg = 0) Or (PData = 0) Then R := ERROR_MON_INVALID_PARMS
  Else If RPid[Rg] <> MyPid Then R := ERROR_MON_INVALID_PARMS
  Else
  Begin
    Dev := RDev[Rg];
    If Cb > PktMax(Dev) Then R := ERROR_MON_DATA_TOO_LARGE
    Else If (Dev <= 1) And (Cb <> PktMax(Dev)) Then R := ERROR_MON_INVALID_PARMS
    Else If Cb < 2 Then R := ERROR_MON_INVALID_PARMS;
  End;
  If R = NO_ERROR Then
  Begin
    If Not BufFits(POut, Cb) Then Pump(Dev);
    Ok := BufPut(POut, PData, Cb);
    If Not Ok Then R := ERROR_MON_DATA_TOO_LARGE
    Else Pump(Dev);
  End;
  DosMonWrite := R;
End;

{ ---------------------------------------------------------------------
  DosMonClose(hmon) : terminer la surveillance par ce handle (tous ses
  tampons sont retires de la chaine ; leurs paquets continuent vers le
  peripherique) }
Function DosMonClose(H : LongInt) : LongInt;
Var R, I : LongInt;
Begin
  Purge;
  R := HErr(H);
  If R = NO_ERROR Then
  Begin
    For I := 1 To MaxR Do
      If RUsed[I] And (RH[I] = H) Then RemoveReg(I);
    HUsed[H] := False;
  End;
  DosMonClose := R;
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  DosMonWrite Index 1, DosMonRead Index 2, DosMonClose Index 3,
  DosMonOpen Index 4, DosMonReg Index 5;

Var
  InitI : LongInt;

BEGIN
  For InitI := 1 To MaxH Do HUsed[InitI] := False;
  For InitI := 1 To MaxR Do RUsed[InitI] := False;
  For InitI := 0 To NDev - 1 Do ChainN[InitI] := 0;
END.
