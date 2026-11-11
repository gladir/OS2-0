{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Bibliotheque OS/2 KBDCALLS.DLL de OS/2-0 (sous-systeme
                clavier : fonctions Kbd*).
}

Library KBDCALLS;

{$IMAGEBASE $00C80000}
{$R-,S-,I-}

{ Compilation : OS2PC KBDCALLS.PAS   (produit KBDCALLS.DLL)

  KBDCALLS.DLL est le sous-systeme clavier d'OS/2 : lecture des
  caracteres (avec ou sans attente, sans retrait), lecture d'une chaine
  avec edition et echo, etat du clavier (mode ASCII ou binaire, echo,
  caractere de fin, rapport des touches de changement d'etat,
  verrouillages), claviers logiques et focus, pages de codes, tables de
  traduction (standard ou personnalisee), identification du materiel et
  remplacement du sous-systeme.

  Les codes de balayage sont recus par le noyau OS2KRNL (IRQ 1), qui les
  range dans son tampon avec l'etat des touches au moment de la frappe et
  l'heure ; la DLL les lit par KrnKbdRead et les traduit elle-meme avec
  la table de traduction du clavier logique (codes etendus compatibles
  avec ceux du BIOS et d'OS/2 : 00h ou E0h suivi du code de balayage).

  Convention _System (comme DOSCALLS.DLL) : valeurs de 32 bits, pointeurs
  lineaires. Un pointeur vers une valeur simple (phkbd, pidCP) designe un
  LongInt ; les structures gardent leur disposition d'OS/2 :
    KBDKEYINFO   chChar (1), chScan (1), fbStatus (1), bNlsShift (1),
                 fsState (2), time (4, ms)                   = 10 octets
    STRINGINBUF  cb (2), cchIn (2)
    KBDINFO      cb (2, = 10), fsMask, chTurnAround, fsInterim, fsState
    KBDHWID      cb (2), idKbd, usReserved1, usReserved2      = 8 octets
    KBDTRANS     KBDKEYINFO (10), fsDD (2), fsXlate (2), fsShift (2),
                 sZero (2)                                    = 18 octets
  Exemple :
    Function KbdCharIn(PKeyInfo, Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS';

  fbStatus : 01h touche de changement d'etat (rapport), 02h code etendu
  (chChar = 00h ou E0h), 40h caractere final, 80h caractere provisoire.
  fsState : 0001h Maj droite, 0002h Maj gauche, 0004h Ctrl, 0008h Alt,
  0010h Arret defil, 0020h Verr num, 0030h Verr maj, 0080h Inser (etats
  actifs), 0100h Ctrl gauche, 0200h Alt gauche, 0400h Ctrl droite,
  0800h Alt droite, 1000h/2000h/4000h touches de verrouillage
  enfoncees, 8000h Syst.
  fsMask (KBDINFO) : 0001h echo, 0002h sans echo, 0004h binaire,
  0008h ASCII, 0010h changer fsState, 0020h changer fsInterim,
  0040h changer chTurnAround, 0080h caractere de fin de 2 octets,
  0100h rapport des touches de changement d'etat.

  Table de traduction (KbdSetCustXt, KbdXlate) : en-tete de 40 octets
  (XTableID = page de codes, XTableFlags1, XTableFlags2, KbdType,
  KbdSubType, XtableLen, EntryCount, EntryWidth, Country, TableTypeID,
  SubCountryID (4), Reserved (16)) suivi de EntryCount entrees de
  EntryWidth octets (7) ; l'entree n correspond au code de balayage n.
  Entree : XlateOp (2 ; bits 0 a 6 = type de touche), Char1 (normal),
  Char2 (Maj), Char3 (Ctrl), Char4 (Alt), Char5 (Alt Gr). Types : 1
  lettre (Verr maj inverse Char1 et Char2), 2 touche speciale, 6 touche
  de fonction, 7 pave numerique (Char1 avec Verr num), 12 touche de
  changement d'etat, 0 sans caractere. Un caractere 00h donne un code
  etendu (00h ou E0h et code de balayage etendu), FFh aucune touche.
  KbdXlate : chScan = code de balayage (bit 7 : touche relachee),
  chChar = E0h a l'entree pour une touche precedee de E0h, fsState =
  etat des touches ; a la sortie fsXlate = 1 (traduction terminee).

  Claviers logiques : le handle 0 est le clavier par defaut ; KbdOpen
  cree un clavier logique (etat, page de codes et table propres) qui doit
  obtenir le focus (KbdGetFocus) pour lire le clavier.

  Remplacement (KbdRegister) : pour chaque fonction choisie par
  FunMask (bits KR_* d'OS/2 : 0 KbdCharIn, 1 KbdPeek, 2 KbdFlushBuffer,
  3 KbdGetStatus, 4 KbdSetStatus, 5 KbdStringIn, 6 KbdOpen, 7 KbdClose,
  8 KbdGetFocus, 9 KbdFreeFocus, 10 KbdGetCp, 11 KbdSetCp, 12 KbdXlate,
  13 KbdSetCustXt, 14 KbdGetHWId, 15 KbdSetHWId), la fonction de
  remplacement est appelee (_System) par Entree(Fonction, pParametres,
  Nombre) ; si elle rend -1, la fonction de base est executee, sinon sa
  valeur est rendue.

  Fonctions exportees (ordinaux d'origine de KBDCALLS.DLL) :
     1 KbdSetCustXt      10 KbdGetStatus      19 KbdFree
     2 KbdInit           11 KbdSetStatus      20 KbdDeRegister
     3 KbdGetCp          12 KbdGetFocus       21 KbdSetFgnd
     4 KbdCharIn         13 KbdFlushBuffer    22 KbdPeek
     5 KbdSetCp          14 KbdXlate          23 KbdOpen
     6 KbdLoadInstance   15 KbdSwitchFgnd     24 KbdGetHWId
     7 KbdSynch          16 KbdShellInit      25 KbdSetHWId
     8 KbdRegister       17 KbdClose
     9 KbdStringIn       18 KbdFreeFocus

  Organisation :
    Partie 1 - Constantes et variables
    Partie 2 - Services du noyau, de DOSCALLS.DLL et de VIOCALLS.DLL
    Partie 3 - Utilitaires
    Partie 4 - Table de traduction standard
    Partie 5 - Traduction des codes de balayage
    Partie 6 - Lecture des touches
    Partie 7 - Remplacement du sous-systeme
    Partie 8 - Fonctions Kbd*
    Exportations et initialisation }

{ ==================================================================== }
{ Partie 1 - Constantes et variables                                   }
{ ==================================================================== }

Const
  NO_ERROR                     = 0;
  ERROR_INVALID_PARAMETER      = 87;
  ERROR_KBD_PARAMETER          = 373;
  ERROR_KBD_NO_DEVICE          = 374;
  ERROR_KBD_INVALID_IOWAIT     = 375;
  ERROR_KBD_INVALID_LENGTH     = 376;
  ERROR_KBD_INVALID_ECHO_MASK  = 377;
  ERROR_KBD_INVALID_INPUT_MASK = 378;
  ERROR_KBD_SMG_ONLY           = 407;
  ERROR_KBD_INVALID_ASCIIZ     = 408;
  ERROR_KBD_INVALID_MASK       = 409;
  ERROR_KBD_REGISTER           = 410;
  ERROR_KBD_DEREGISTER         = 411;
  ERROR_KBD_INVALID_HANDLE     = 439;
  ERROR_KBD_NO_MORE_HANDLE     = 440;
  ERROR_KBD_INVALID_CODEPAGE_ID = 443;
  ERROR_KBD_FOCUS_REQUIRED     = 445;
  ERROR_KBD_FOCUS_ALREADY_ACTIVE = 446;
  ERROR_KBD_INVALID_CODEPAGE   = 448;
  ERROR_KBD_UNABLE_TO_FOCUS    = 449;

  IO_WAIT   = 0;
  IO_NOWAIT = 1;

  { fsMask }
  KM_ECHO_ON    = $0001;
  KM_ECHO_OFF   = $0002;
  KM_BINARY     = $0004;
  KM_ASCII      = $0008;
  KM_STATE      = $0010;
  KM_INTERIM    = $0020;
  KM_TURNAROUND = $0040;
  KM_2B_TURN    = $0080;
  KM_SHIFTREP   = $0100;

  { fbStatus }
  ST_SHIFT    = $01;
  ST_EXTENDED = $02;
  ST_FINAL    = $40;
  ST_INTERIM  = $80;

  { bits KR_* (KbdRegister) }
  KB_CHARIN = 0;     KB_PEEK = 1;       KB_FLUSHBUFFER = 2;  KB_GETSTATUS = 3;
  KB_SETSTATUS = 4;  KB_STRINGIN = 5;   KB_OPEN = 6;         KB_CLOSE = 7;
  KB_GETFOCUS = 8;   KB_FREEFOCUS = 9;  KB_GETCP = 10;       KB_SETCP = 11;
  KB_XLATE = 12;     KB_SETCUSTXT = 13; KB_GETHWID = 14;     KB_SETHWID = 15;

  MaxH     = 8;              { claviers logiques 1..MaxH (0 = defaut) }
  XtHdr    = 40;             { en-tete d'une table de traduction }
  XtWidth  = 7;
  XtCount  = 128;
  DefKbdId = $AB41;          { clavier etendu 101/102 touches }

  { types de touches de la table }
  KT_NONE  = 0;
  KT_ALPHA = 1;
  KT_SPEC  = 2;
  KT_FUNC  = 6;
  KT_PAD   = 7;
  KT_SHIFT = 12;

Type
  PLong = ^LongInt;
  PWord = ^Word;
  PByte = ^Byte;

Var
  { claviers logiques ; indice 0 = clavier par defaut }
  HUsed     : Array[0..MaxH] Of Boolean;
  HPid      : Array[0..MaxH] Of LongInt;
  HEcho     : Array[0..MaxH] Of Boolean;
  HBinary   : Array[0..MaxH] Of Boolean;
  HShiftRep : Array[0..MaxH] Of Boolean;
  HTurn     : Array[0..MaxH] Of LongInt;   { caractere de fin (et code) }
  HTurn2    : Array[0..MaxH] Of Boolean;   { caractere de fin de 2 octets }
  HInterim  : Array[0..MaxH] Of LongInt;
  HCp       : Array[0..MaxH] Of LongInt;
  HXt       : Array[0..MaxH] Of LongInt;   { adresse de la table }
  Focus     : LongInt;                     { clavier logique ayant le focus, -1 }
  FocusPid  : LongInt;

  DefXt     : Array[0..XtHdr + XtCount * XtWidth] Of Byte;
  DefXtAdr  : LongInt;
  SysCp     : LongInt;
  HwId      : LongInt;
  HwRes1, HwRes2 : LongInt;
  FgPid, FgSess  : LongInt;
  ShellPid  : LongInt;
  Present   : Boolean;

  { touche lue : resultat de la traduction }
  KChar, KScan, KStatus, KState, KTime : LongInt;
  KRaw      : Array[0..2] Of LongInt;      { KrnKbdRead : touche, etat, heure }

  { remplacement }
  RegEntry, RegFuns : LongInt;
  InHook    : Boolean;
  HookRet   : LongInt;
  Prm       : Array[0..7] Of LongInt;
  FailName  : Array[0..63] Of Byte;
  CpBuf     : Array[0..7] Of LongInt;
  EchoBuf   : Array[0..7] Of Byte;
  TmplBuf   : Array[0..255] Of Byte;       { gabarit de KbdStringIn }
  KeyLowV, KeyHighV : String;              { copies des tables (indexation fiable) }

{ ==================================================================== }
{ Partie 2 - Services du noyau, de DOSCALLS.DLL et de VIOCALLS.DLL     }
{ ==================================================================== }

Function KrnKbdRead(P, Flags : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnKbdRead';
Function KrnKbdCtl(Op, V : LongInt) : LongInt; External 'DOSCALLS' Name 'KrnKbdCtl';
Function KGetCurrentProcessId : LongInt; External 'DOSCALLS' Name 'GetCurrentProcessId';
Function KBeep(Freq, Dur : LongInt) : LongInt; External 'DOSCALLS' Name 'Beep';
Function DosLoadModule(PFail, CbFail, PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DcQueryCp(Cb, PCp, PcbActual : LongInt) : LongInt; External 'DOSCALLS' Name 'DosQueryCp';
Function VioWrtTty(P, N, H : LongInt) : LongInt; External 'VIOCALLS' Name 'VioWrtTty';

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

Function MyPid : LongInt;
Begin
  MyPid := KGetCurrentProcessId;
End;

{ Le handle est-il valide pour le processus ? (0 = clavier par defaut) }
Function HErr(H : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := ERROR_KBD_INVALID_HANDLE;
  If H = 0 Then R := NO_ERROR
  Else If (H >= 1) And (H <= MaxH) Then
    If HUsed[H] And (HPid[H] = MyPid) Then R := NO_ERROR;
  HErr := R;
End;

{ Le clavier logique peut-il lire le clavier ? }
Function FocusErr(H : LongInt) : LongInt;
Var R : LongInt;
Begin
  R := HErr(H);
  If (R = NO_ERROR) And (H <> 0) And (Focus <> H) Then R := ERROR_KBD_FOCUS_REQUIRED;
  FocusErr := R;
End;

{ Etat par defaut d'un clavier logique }
Procedure ResetHandle(H : LongInt);
Begin
  HEcho[H] := True;
  HBinary[H] := False;
  HShiftRep[H] := False;
  HTurn[H] := $0D;
  HTurn2[H] := False;
  HInterim[H] := 0;
  HCp[H] := SysCp;
  HXt[H] := DefXtAdr;
End;

{ Mode du noyau : rapport des touches de changement d'etat }
Procedure SyncMode(H : LongInt);
Var D : LongInt;
Begin
  If HShiftRep[H] Then D := KrnKbdCtl(2, 1) Else D := KrnKbdCtl(2, 0);
End;

Function CpOk(Cp : LongInt) : Boolean;
Begin
  CpOk := (Cp = 437) Or (Cp = 850) Or (Cp = 852) Or (Cp = 857) Or (Cp = 860) Or
          (Cp = 861) Or (Cp = 863) Or (Cp = 865) Or (Cp = 866);
End;

{ ==================================================================== }
{ Partie 4 - Table de traduction standard                              }
{ ==================================================================== }

Const
  { clavier americain, codes de balayage 00h a 39h }
  KeyLow  = 'XX1234567890-=XXqwertyuiop[]XXasdfghjkl;''`X\zxcvbnm,./X*X ';
  KeyHigh = 'xx!@#$%^&*()_+xxQWERTYUIOP{}xxASDFGHJKL:"~x|ZXCVBNM<>?x*x ';

Procedure SetKey(Sc, Typ, C1, C2, C3, C4, C5 : LongInt);
Var A : LongInt;
Begin
  A := XtHdr + Sc * XtWidth;
  DefXt[A] := Typ And $FF;
  DefXt[A + 1] := 0;
  DefXt[A + 2] := C1 And $FF;
  DefXt[A + 3] := C2 And $FF;
  DefXt[A + 4] := C3 And $FF;
  DefXt[A + 5] := C4 And $FF;
  DefXt[A + 6] := C5 And $FF;
End;

Procedure SetHdrW(Off, V : LongInt);
Begin
  DefXt[Off] := V And $FF;
  DefXt[Off + 1] := (V Shr 8) And $FF;
End;

Procedure BuildDefXt(Cp : LongInt);
Var I, Sc, C1, C2, C3 : LongInt;
Begin
  For I := 0 To XtHdr + XtCount * XtWidth Do DefXt[I] := 0;
  SetHdrW(0, Cp);                       { XTableID }
  SetHdrW(6, 1);                        { KbdType : clavier etendu }
  SetHdrW(10, XtHdr + XtCount * XtWidth);
  SetHdrW(12, XtCount);
  SetHdrW(14, XtWidth);
  SetHdrW(16, Ord('U') Or (Ord('S') Shl 8));
  SetHdrW(18, 1);
  DefXt[20] := Ord('1'); DefXt[21] := Ord('0'); DefXt[22] := Ord('3'); DefXt[23] := Ord(' ');
  KeyLowV := KeyLow;
  KeyHighV := KeyHigh;
  For Sc := 2 To $39 Do
  Begin
    C1 := Ord(KeyLowV[Sc + 1]);
    C2 := Ord(KeyHighV[Sc + 1]);
    If (C1 <> Ord('X')) And (Sc <> $37) Then
    Begin
      If (C1 >= Ord('a')) And (C1 <= Ord('z')) Then
        SetKey(Sc, KT_ALPHA, C1, C2, C1 - $60, 0, 0)
      Else
      Begin
        C3 := $FF;
        Case C1 Of
          Ord('[') : C3 := $1B;
          Ord('\') : C3 := $1C;
          Ord(']') : C3 := $1D;
          Ord('6') : C3 := $1E;
          Ord('-') : C3 := $1F;
          Ord('2') : C3 := 0;
          Ord(' ') : C3 := $20;
        End;
        If C1 = Ord(' ') Then SetKey(Sc, KT_SPEC, C1, C2, C3, $20, 0)
        Else SetKey(Sc, KT_SPEC, C1, C2, C3, 0, 0);
      End;
    End;
  End;
  SetKey($01, KT_SPEC, $1B, $1B, $1B, 0, 0);       { Echap }
  SetKey($0E, KT_SPEC, $08, $08, $7F, 0, 0);       { Retour arriere }
  SetKey($0F, KT_SPEC, $09, 0, 0, 0, 0);           { Tab (Maj : 00h 0Fh) }
  SetKey($1C, KT_SPEC, $0D, $0D, $0A, 0, 0);       { Entree }
  SetKey($37, KT_SPEC, Ord('*'), Ord('*'), 0, 0, 0);
  SetKey($4A, KT_SPEC, Ord('-'), Ord('-'), 0, 0, 0);
  SetKey($4E, KT_SPEC, Ord('+'), Ord('+'), 0, 0, 0);
  For Sc := $3B To $44 Do SetKey(Sc, KT_FUNC, 0, 0, 0, 0, 0);
  SetKey($57, KT_FUNC, 0, 0, 0, 0, 0);
  SetKey($58, KT_FUNC, 0, 0, 0, 0, 0);
  SetKey($47, KT_PAD, Ord('7'), 0, 0, 0, 0);
  SetKey($48, KT_PAD, Ord('8'), 0, 0, 0, 0);
  SetKey($49, KT_PAD, Ord('9'), 0, 0, 0, 0);
  SetKey($4B, KT_PAD, Ord('4'), 0, 0, 0, 0);
  SetKey($4C, KT_PAD, Ord('5'), 0, 0, 0, 0);
  SetKey($4D, KT_PAD, Ord('6'), 0, 0, 0, 0);
  SetKey($4F, KT_PAD, Ord('1'), 0, 0, 0, 0);
  SetKey($50, KT_PAD, Ord('2'), 0, 0, 0, 0);
  SetKey($51, KT_PAD, Ord('3'), 0, 0, 0, 0);
  SetKey($52, KT_PAD, Ord('0'), 0, 0, 0, 0);
  SetKey($53, KT_PAD, Ord('.'), 0, 0, 0, 0);
  SetKey($1D, KT_SHIFT, 0, 0, 0, 0, 0);
  SetKey($2A, KT_SHIFT, 0, 0, 0, 0, 0);
  SetKey($36, KT_SHIFT, 0, 0, 0, 0, 0);
  SetKey($38, KT_SHIFT, 0, 0, 0, 0, 0);
  SetKey($3A, KT_SHIFT, 0, 0, 0, 0, 0);
  SetKey($45, KT_SHIFT, 0, 0, 0, 0, 0);
  SetKey($46, KT_SHIFT, 0, 0, 0, 0, 0);
End;

{ ==================================================================== }
{ Partie 5 - Traduction des codes de balayage                          }
{ ==================================================================== }

{ Code de balayage etendu (BIOS) selon le modificateur :
  0 normal, 1 Maj, 2 Ctrl, 3 Alt }
Function ExtScan(Sc, Md : LongInt; Gray : Boolean) : LongInt;
Var R : LongInt;
Begin
  R := Sc;
  If (Sc >= $3B) And (Sc <= $44) Then
  Begin
    Case Md Of
      1 : R := Sc + $19;
      2 : R := Sc + $23;
      3 : R := Sc + $2D;
    End;
  End
  Else If (Sc = $57) Or (Sc = $58) Then
  Begin
    R := Sc + $2E + Md * 2;            { F11 : 85h 87h 89h 8Bh }
  End
  Else If Md = 2 Then
  Begin
    Case Sc Of
      $0F : R := $94;  $37 : R := $96;
      $47 : R := $77;  $48 : R := $8D;  $49 : R := $84;  $4A : R := $8E;
      $4B : R := $73;  $4C : R := $8F;  $4D : R := $74;  $4E : R := $90;
      $4F : R := $75;  $50 : R := $91;  $51 : R := $76;  $52 : R := $92;
      $53 : R := $93;
    End;
  End
  Else If Md = 3 Then
  Begin
    If (Sc >= $02) And (Sc <= $0D) Then R := Sc + $76
    Else If Sc = $0F Then R := $A5
    Else If Gray And (Sc >= $47) And (Sc <= $53) Then R := Sc + $50
    Else If Gray And (Sc = $1C) Then R := $A6
    Else If Gray And (Sc = $35) Then R := $A4;
  End;
  ExtScan := R;
End;

{ Traduire le code de balayage Sc (Gray : precede de E0h) avec l'etat
  St et la table Xt ; rend dans KChar, KScan, KStatus. Faux si la touche
  ne produit aucun caractere. }
Function Translate(Xt, Sc : LongInt; Gray : Boolean; St : LongInt) : Boolean;
Var A, Typ, C, Md, N : LongInt; Ok, Shf, AltGr : Boolean;
Begin
  Ok := True;
  KScan := Sc;
  KChar := 0;
  KStatus := ST_FINAL;
  N := RdW(Xt + 12);
  If (Sc < 1) Or (Sc >= N) Then
    Typ := KT_NONE
  Else
  Begin
    A := Xt + XtHdr + Sc * RdW(Xt + 14);
    Typ := RdW(A) And $7F;
  End;
  AltGr := ((St And $0800) <> 0) And ((St And $0200) = 0) And (Typ <> KT_NONE);
  If AltGr Then
    If RdB(A + 6) = 0 Then AltGr := False;
  Md := 0;
  If (St And $0008) <> 0 Then Md := 3
  Else If (St And $0004) <> 0 Then Md := 2
  Else If (St And $0003) <> 0 Then Md := 1;
  Case Typ Of
    KT_ALPHA, KT_SPEC :
      Begin
        If AltGr Then C := RdB(A + 6)
        Else If Md = 3 Then C := RdB(A + 5)
        Else If Md = 2 Then C := RdB(A + 4)
        Else
        Begin
          Shf := Md = 1;
          If (Typ = KT_ALPHA) And ((St And $0040) <> 0) Then Shf := Not Shf;
          If Shf Then C := RdB(A + 3) Else C := RdB(A + 2);
        End;
        If C = $FF Then Ok := False
        Else If C = 0 Then
        Begin
          KScan := ExtScan(Sc, Md, Gray);
          KStatus := ST_FINAL Or ST_EXTENDED;
        End
        Else
        Begin
          KChar := C;
          If Gray Then KScan := $E0;    { Entree et / du pave numerique }
        End;
        If Gray And (Md = 3) Then
        Begin
          KChar := 0;
          KScan := ExtScan(Sc, Md, Gray);
          KStatus := ST_FINAL Or ST_EXTENDED;
        End;
      End;
    KT_FUNC :
      Begin
        KScan := ExtScan(Sc, Md, Gray);
        KStatus := ST_FINAL Or ST_EXTENDED;
      End;
    KT_PAD :
      Begin
        Shf := ((St And $0020) <> 0) Xor ((St And $0003) <> 0);
        If (Not Gray) And (Md <= 1) And Shf Then
          KChar := RdB(A + 2)          { chiffre (Verr num) }
        Else If Md = 3 Then
        Begin
          If Gray Then
          Begin
            KScan := ExtScan(Sc, 3, True);
            KStatus := ST_FINAL Or ST_EXTENDED;
          End
          Else
            Ok := False;
        End
        Else
        Begin
          { fleches et touches d'edition }
          If Md = 2 Then KScan := ExtScan(Sc, 2, Gray);
          If Gray Then KChar := $E0;
          KStatus := ST_FINAL Or ST_EXTENDED;
        End;
      End;
  Else
    Ok := False;
  End;
  Translate := Ok;
End;

{ ==================================================================== }
{ Partie 6 - Lecture des touches                                       }
{ ==================================================================== }

{ Touche suivante pour le clavier logique H. Remove : la retirer du
  tampon ; Wait : attendre. Les relachements et les touches sans
  caractere sont ecartes ; les changements d'etat ne sont rendus qu'en
  mode de rapport. Rend vrai si une touche est rendue dans KChar,
  KScan, KStatus, KState, KTime. }
Function NextKey(H : LongInt; Remove, Wait : Boolean) : Boolean;
Var F, X, D : LongInt; Got, Done, Keep : Boolean;
Begin
  SyncMode(H);
  Got := False;
  Done := False;
  Repeat
    F := 0;
    If Not Remove Then F := 1;
    If Wait Then F := F Or 2;
    If KrnKbdRead(LongInt(@KRaw), F) = 0 Then
      Done := True
    Else
    Begin
      X := KRaw[1];
      KState := X And $FFFF;
      KTime := KRaw[2];
      Keep := False;
      If (X And $40000) <> 0 Then
      Begin
        { changement d'etat (Maj, Ctrl, Alt, verrouillages) }
        If HShiftRep[H] Then
        Begin
          KChar := 0;
          KScan := (KRaw[0] Shr 8) And $7F;
          If (X And $20000) <> 0 Then KScan := KScan Or $80;
          KStatus := ST_SHIFT;
          Keep := True;
        End;
      End
      Else If ((X And $20000) = 0) And ((X And $80000) <> 0) Then
      Begin
        { touche rendue par les moniteurs de KBD$ (MONCALLS.DLL) : deja
          traduite, fbStatus dans les bits 24 a 31 }
        KChar := KRaw[0] And $FF;
        KScan := (KRaw[0] Shr 8) And $FF;
        KStatus := (X Shr 24) And $FF;
        If (KStatus And (ST_FINAL Or ST_INTERIM)) = 0 Then KStatus := KStatus Or ST_FINAL;
        Keep := True;
      End
      Else If (X And $20000) = 0 Then
        Keep := Translate(HXt[H], (KRaw[0] Shr 8) And $7F, (X And $10000) <> 0, KState);
      If Keep Then
      Begin
        Got := True;
        Done := True;
      End
      Else If Not Remove Then
        D := KrnKbdRead(LongInt(@KRaw), 0);   { ecarter la touche }
    End;
  Until Done;
  NextKey := Got;
End;

{ Ecrire KBDKEYINFO }
Procedure PutKeyInfo(P : LongInt; Got : Boolean);
Begin
  If Got Then
  Begin
    WrB(P, KChar);
    WrB(P + 1, KScan);
    WrB(P + 2, KStatus);
    WrB(P + 3, 0);
    WrW(P + 4, KState);
    WrL(P + 6, KTime);
  End
  Else
  Begin
    WrB(P, 0);
    WrB(P + 1, 0);
    WrB(P + 2, 0);
    WrB(P + 3, 0);
    WrW(P + 4, KrnKbdCtl(0, 0));
    WrL(P + 6, 0);
  End;
End;

Procedure Echo1(C : LongInt);
Var D : LongInt;
Begin
  EchoBuf[0] := C;
  D := VioWrtTty(LongInt(@EchoBuf), 1, 0);
End;

Procedure EchoBack;
Var D : LongInt;
Begin
  EchoBuf[0] := 8; EchoBuf[1] := 32; EchoBuf[2] := 8;
  D := VioWrtTty(LongInt(@EchoBuf), 3, 0);
End;

{ ==================================================================== }
{ Partie 7 - Remplacement du sous-systeme                              }
{ ==================================================================== }

Function CallPtr3(F, A1, A2, A3 : LongInt) : LongInt;
Var R : LongInt;
Begin
  asm
    push ebx
    push esi
    push edi
    mov eax,A3
    push eax
    mov eax,A2
    push eax
    mov eax,A1
    push eax
    mov eax,F
    call eax
    add esp,12
    mov R,eax
    pop edi
    pop esi
    pop ebx
  end;
  CallPtr3 := R;
End;

{ La fonction Bit est-elle remplacee ? Si oui, appeler le remplacant ;
  vrai si sa valeur (HookRet) doit etre rendue a l'appelant }
Function Hooked(Bit, N, A1, A2, A3, A4 : LongInt) : Boolean;
Var R : LongInt; Res : Boolean;
Begin
  Res := False;
  If (Not InHook) And (RegEntry <> 0) And (((RegFuns Shr Bit) And 1) <> 0) Then
  Begin
    Prm[0] := A1; Prm[1] := A2; Prm[2] := A3; Prm[3] := A4;
    InHook := True;
    R := CallPtr3(RegEntry, Bit, LongInt(@Prm), N);
    InHook := False;
    If R <> -1 Then
    Begin
      HookRet := R;
      Res := True;
    End;
  End;
  Hooked := Res;
End;

{ ==================================================================== }
{ Partie 8 - Fonctions Kbd*                                            }
{ ==================================================================== }

{ ---------------------------------------------------------------------
  KbdCharIn(pkbci, fWait, hkbd) : lire un caractere (KBDKEYINFO).
  fWait IO_WAIT (0) : attendre une touche ; IO_NOWAIT (1) : fbStatus = 0
  si aucune touche n'est disponible }
Function KbdCharIn(PInfo, Wait, Hkbd : LongInt) : LongInt;
Var R : LongInt; Got : Boolean;
Begin
  If Hooked(KB_CHARIN, 3, PInfo, Wait, Hkbd, 0) Then
  Begin
    KbdCharIn := HookRet;
    Exit;
  End;
  R := FocusErr(Hkbd);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_KBD_PARAMETER;
  If (R = NO_ERROR) And (Wait <> IO_WAIT) And (Wait <> IO_NOWAIT) Then R := ERROR_KBD_INVALID_IOWAIT;
  If R = NO_ERROR Then
  Begin
    Got := NextKey(Hkbd, True, Wait = IO_WAIT);
    PutKeyInfo(PInfo, Got);
  End;
  KbdCharIn := R;
End;

{ ---------------------------------------------------------------------
  KbdPeek(pkbci, hkbd) : consulter la touche suivante sans la retirer
  (fbStatus bit 6 = 1 si une touche est disponible) }
Function KbdPeek(PInfo, Hkbd : LongInt) : LongInt;
Var R : LongInt; Got : Boolean;
Begin
  If Hooked(KB_PEEK, 2, PInfo, Hkbd, 0, 0) Then
  Begin
    KbdPeek := HookRet;
    Exit;
  End;
  R := FocusErr(Hkbd);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_KBD_PARAMETER;
  If R = NO_ERROR Then
  Begin
    Got := NextKey(Hkbd, False, False);
    PutKeyInfo(PInfo, Got);
  End;
  KbdPeek := R;
End;

{ ---------------------------------------------------------------------
  KbdFlushBuffer(hkbd) : vider le tampon du clavier }
Function KbdFlushBuffer(Hkbd : LongInt) : LongInt;
Var R, D : LongInt;
Begin
  If Hooked(KB_FLUSHBUFFER, 1, Hkbd, 0, 0, 0) Then
  Begin
    KbdFlushBuffer := HookRet;
    Exit;
  End;
  R := FocusErr(Hkbd);
  If R = NO_ERROR Then D := KrnKbdCtl(3, 0);
  KbdFlushBuffer := R;
End;

{ Le caractere lu est-il le caractere de fin ? }
Function IsTurn(H : LongInt) : Boolean;
Begin
  If HTurn2[H] Then
    IsTurn := (KChar = (HTurn[H] And $FF)) And (KScan = ((HTurn[H] Shr 8) And $FF))
  Else
    IsTurn := (KChar <> 0) And (KChar <> $E0) And (KChar = (HTurn[H] And $FF)) Or
              ((KChar = $0D) And (KScan = $E0) And ((HTurn[H] And $FF) = $0D));
End;

{ ---------------------------------------------------------------------
  KbdStringIn(pch, pchIn, fWait, hkbd) : lire une chaine.
  pchIn^ : STRINGINBUF (cb = taille du tampon, 1 a 255 ; cchIn = a
  l'entree longueur du gabarit deja dans pch, a la sortie nombre de
  caracteres lus).
  Mode ASCII : edition (Retour arriere, Echap, F1 et fleche droite
  copient un caractere du gabarit, F3 le reste), echo si demande, fin
  sur le caractere de fin (rangee dans le tampon si la place le permet,
  non comptee) ; fWait doit etre IO_WAIT.
  Mode binaire : cb caracteres sans edition (les codes etendus occupent
  2 octets) ; avec IO_NOWAIT, seulement les caracteres disponibles. }
Function KbdStringIn(PCh, PIn, Wait, Hkbd : LongInt) : LongInt;
Var R, Cb, N, T, I, TPos : LongInt; Done, Got, Ext, Ec : Boolean;
Begin
  If Hooked(KB_STRINGIN, 4, PCh, PIn, Wait, Hkbd) Then
  Begin
    KbdStringIn := HookRet;
    Exit;
  End;
  R := FocusErr(Hkbd);
  If (R = NO_ERROR) And ((PCh = 0) Or (PIn = 0)) Then R := ERROR_KBD_PARAMETER;
  If (R = NO_ERROR) And (Wait <> IO_WAIT) And (Wait <> IO_NOWAIT) Then R := ERROR_KBD_INVALID_IOWAIT;
  If R = NO_ERROR Then
  Begin
    Cb := RdW(PIn);
    If (Cb < 1) Or (Cb > 255) Then R := ERROR_KBD_INVALID_LENGTH
    Else If (Not HBinary[Hkbd]) And (Wait <> IO_WAIT) Then R := ERROR_KBD_INVALID_IOWAIT;
  End;
  If R = NO_ERROR Then
  Begin
    N := 0;
    If HBinary[Hkbd] Then
    Begin
      { mode binaire }
      Done := False;
      While (N < Cb) And Not Done Do
      Begin
        Got := NextKey(Hkbd, True, Wait = IO_WAIT);
        If Not Got Then Done := True
        Else If (KStatus And ST_SHIFT) = 0 Then
        Begin
          Ext := (KStatus And ST_EXTENDED) <> 0;
          If Ext Then
          Begin
            If N + 2 <= Cb Then
            Begin
              WrB(PCh + N, KChar);
              WrB(PCh + N + 1, KScan);
              N := N + 2;
            End
            Else Done := True;
          End
          Else
          Begin
            WrB(PCh + N, KChar);
            Inc(N);
          End;
        End;
      End;
    End
    Else
    Begin
      { mode ASCII : edition et echo }
      Ec := HEcho[Hkbd];
      T := RdW(PIn + 2);
      If T > Cb Then T := Cb;
      For I := 0 To T - 1 Do TmplBuf[I] := RdB(PCh + I);
      TPos := 0;
      Done := False;
      While Not Done Do
      Begin
        Got := NextKey(Hkbd, True, True);
        If Got And ((KStatus And ST_SHIFT) = 0) Then
        Begin
          Ext := (KStatus And ST_EXTENDED) <> 0;
          If IsTurn(Hkbd) Then
          Begin
            If N < Cb Then WrB(PCh + N, KChar);
            If Ec Then
            Begin
              Echo1(13);
              Echo1(10);
            End;
            Done := True;
          End
          Else If Ext Then
          Begin
            If (KScan = $3B) Or (KScan = $4D) Then
            Begin
              { F1, fleche droite : un caractere du gabarit }
              If (TPos < T) And (N < Cb - 1) Then
              Begin
                WrB(PCh + N, TmplBuf[TPos]);
                If Ec Then Echo1(TmplBuf[TPos]);
                Inc(N); Inc(TPos);
              End;
            End
            Else If KScan = $3D Then
            Begin
              { F3 : le reste du gabarit }
              While (TPos < T) And (N < Cb - 1) Do
              Begin
                WrB(PCh + N, TmplBuf[TPos]);
                If Ec Then Echo1(TmplBuf[TPos]);
                Inc(N); Inc(TPos);
              End;
            End;
          End
          Else If (KChar = 8) And (KScan = $0E) Then
          Begin
            If N > 0 Then
            Begin
              Dec(N);
              If TPos > 0 Then Dec(TPos);
              If Ec Then EchoBack;
            End;
          End
          Else If KChar = 27 Then
          Begin
            { Echap : annuler la ligne }
            While N > 0 Do
            Begin
              Dec(N);
              If Ec Then EchoBack;
            End;
            TPos := 0;
          End
          Else If N < Cb - 1 Then
          Begin
            WrB(PCh + N, KChar);
            If Ec Then Echo1(KChar);
            Inc(N);
            If TPos < T Then Inc(TPos);
          End
          Else
            I := KBeep(880, 60);          { tampon plein }
        End;
      End;
    End;
    WrW(PIn + 2, N);
  End;
  KbdStringIn := R;
End;

{ ---------------------------------------------------------------------
  KbdGetStatus(pkbdinfo, hkbd) : etat du clavier logique (KBDINFO,
  cb = 10) }
Function KbdGetStatus(PInfo, Hkbd : LongInt) : LongInt;
Var R, M : LongInt;
Begin
  If Hooked(KB_GETSTATUS, 2, PInfo, Hkbd, 0, 0) Then
  Begin
    KbdGetStatus := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_KBD_PARAMETER;
  If (R = NO_ERROR) And (RdW(PInfo) < 10) Then R := ERROR_KBD_INVALID_LENGTH;
  If R = NO_ERROR Then
  Begin
    If HEcho[Hkbd] Then M := KM_ECHO_ON Else M := KM_ECHO_OFF;
    If HBinary[Hkbd] Then M := M Or KM_BINARY Else M := M Or KM_ASCII;
    If HTurn2[Hkbd] Then M := M Or KM_2B_TURN;
    If HShiftRep[Hkbd] Then M := M Or KM_SHIFTREP;
    WrW(PInfo, 10);
    WrW(PInfo + 2, M);
    WrW(PInfo + 4, HTurn[Hkbd]);
    WrW(PInfo + 6, HInterim[Hkbd]);
    WrW(PInfo + 8, KrnKbdCtl(0, 0));
  End;
  KbdGetStatus := R;
End;

{ ---------------------------------------------------------------------
  KbdSetStatus(pkbdinfo, hkbd) : changer l'etat (selon fsMask) : echo,
  mode ASCII ou binaire, etat des verrouillages (fsState), fsInterim,
  caractere de fin (de 1 ou 2 octets), rapport des changements d'etat }
Function KbdSetStatus(PInfo, Hkbd : LongInt) : LongInt;
Var R, M, D : LongInt;
Begin
  If Hooked(KB_SETSTATUS, 2, PInfo, Hkbd, 0, 0) Then
  Begin
    KbdSetStatus := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (PInfo = 0) Then R := ERROR_KBD_PARAMETER;
  If (R = NO_ERROR) And (RdW(PInfo) <> 10) Then R := ERROR_KBD_INVALID_LENGTH;
  If R = NO_ERROR Then
  Begin
    M := RdW(PInfo + 2);
    If (M And (KM_ECHO_ON Or KM_ECHO_OFF)) = (KM_ECHO_ON Or KM_ECHO_OFF) Then
      R := ERROR_KBD_INVALID_ECHO_MASK
    Else If (M And (KM_BINARY Or KM_ASCII)) = (KM_BINARY Or KM_ASCII) Then
      R := ERROR_KBD_INVALID_INPUT_MASK
    Else If (M And $FE00) <> 0 Then
      R := ERROR_KBD_PARAMETER
    Else If ((M And KM_ECHO_ON) <> 0) And (((M And KM_BINARY) <> 0) Or
            (HBinary[Hkbd] And ((M And KM_ASCII) = 0))) Then
      R := ERROR_KBD_INVALID_ECHO_MASK;   { pas d'echo en mode binaire }
  End;
  If R = NO_ERROR Then
  Begin
    If (M And KM_ECHO_ON) <> 0 Then HEcho[Hkbd] := True;
    If (M And KM_ECHO_OFF) <> 0 Then HEcho[Hkbd] := False;
    If (M And KM_BINARY) <> 0 Then
    Begin
      HBinary[Hkbd] := True;
      HEcho[Hkbd] := False;
    End;
    If (M And KM_ASCII) <> 0 Then HBinary[Hkbd] := False;
    If (M And KM_STATE) <> 0 Then D := KrnKbdCtl(1, RdW(PInfo + 8));
    If (M And KM_INTERIM) <> 0 Then HInterim[Hkbd] := RdW(PInfo + 6);
    If (M And KM_TURNAROUND) <> 0 Then
    Begin
      HTurn2[Hkbd] := (M And KM_2B_TURN) <> 0;
      If HTurn2[Hkbd] Then HTurn[Hkbd] := RdW(PInfo + 4)
      Else HTurn[Hkbd] := RdW(PInfo + 4) And $FF;
    End;
    If (M And KM_SHIFTREP) <> 0 Then HShiftRep[Hkbd] := True
    Else If (M And (KM_BINARY Or KM_ASCII)) <> 0 Then HShiftRep[Hkbd] := False;
  End;
  KbdSetStatus := R;
End;

{ ---------------------------------------------------------------------
  KbdOpen(phkbd) : creer un clavier logique ; *phkbd <- handle }
Function KbdOpen(PH : LongInt) : LongInt;
Var R, I, F : LongInt;
Begin
  If Hooked(KB_OPEN, 1, PH, 0, 0, 0) Then
  Begin
    KbdOpen := HookRet;
    Exit;
  End;
  R := NO_ERROR;
  If PH = 0 Then R := ERROR_KBD_PARAMETER
  Else
  Begin
    F := 0;
    For I := MaxH DownTo 1 Do
      If Not HUsed[I] Then F := I;
    If F = 0 Then R := ERROR_KBD_NO_MORE_HANDLE
    Else
    Begin
      HUsed[F] := True;
      HPid[F] := MyPid;
      ResetHandle(F);
      WrL(PH, F);
    End;
  End;
  KbdOpen := R;
End;

{ ---------------------------------------------------------------------
  KbdClose(hkbd) : fermer un clavier logique (le focus est libere) }
Function KbdClose(Hkbd : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(KB_CLOSE, 1, Hkbd, 0, 0, 0) Then
  Begin
    KbdClose := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (Hkbd = 0) Then R := ERROR_KBD_INVALID_HANDLE;
  If R = NO_ERROR Then
  Begin
    If Focus = Hkbd Then Focus := -1;
    HUsed[Hkbd] := False;
  End;
  KbdClose := R;
End;

{ ---------------------------------------------------------------------
  KbdGetFocus(fWait, hkbd) : attacher le clavier physique au clavier
  logique. fWait IO_WAIT ou IO_NOWAIT ; un processus n'ayant qu'un
  seul fil, l'attente d'un focus detenu par un autre clavier logique ne
  peut aboutir : ERROR_KBD_UNABLE_TO_FOCUS }
Function KbdGetFocus(Wait, Hkbd : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(KB_GETFOCUS, 2, Wait, Hkbd, 0, 0) Then
  Begin
    KbdGetFocus := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (Wait <> IO_WAIT) And (Wait <> IO_NOWAIT) Then R := ERROR_KBD_INVALID_IOWAIT;
  If R = NO_ERROR Then
  Begin
    If Focus = Hkbd Then R := ERROR_KBD_FOCUS_ALREADY_ACTIVE
    Else If Focus >= 0 Then R := ERROR_KBD_UNABLE_TO_FOCUS
    Else
    Begin
      Focus := Hkbd;
      FocusPid := MyPid;
    End;
  End;
  KbdGetFocus := R;
End;

{ ---------------------------------------------------------------------
  KbdFreeFocus(hkbd) : liberer le focus }
Function KbdFreeFocus(Hkbd : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(KB_FREEFOCUS, 1, Hkbd, 0, 0, 0) Then
  Begin
    KbdFreeFocus := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (Focus <> Hkbd) Then R := ERROR_KBD_FOCUS_REQUIRED;
  If R = NO_ERROR Then Focus := -1;
  KbdFreeFocus := R;
End;

{ ---------------------------------------------------------------------
  KbdGetCp(ulReserved, pidCP, hkbd) : page de codes du clavier logique
  (ulReserved = 0) }
Function KbdGetCp(Res, PCp, Hkbd : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(KB_GETCP, 3, Res, PCp, Hkbd, 0) Then
  Begin
    KbdGetCp := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And ((Res <> 0) Or (PCp = 0)) Then R := ERROR_KBD_PARAMETER;
  If R = NO_ERROR Then WrL(PCp, HCp[Hkbd]);
  KbdGetCp := R;
End;

{ ---------------------------------------------------------------------
  KbdSetCp(usReserved, idCP, hkbd) : changer la page de codes (0 = page
  de codes du systeme) ; la table de traduction standard est reprise }
Function KbdSetCp(Res, Cp, Hkbd : LongInt) : LongInt;
Var R : LongInt;
Begin
  If Hooked(KB_SETCP, 3, Res, Cp, Hkbd, 0) Then
  Begin
    KbdSetCp := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (Res <> 0) Then R := ERROR_KBD_PARAMETER;
  If R = NO_ERROR Then
  Begin
    If Cp = 0 Then Cp := SysCp;
    If Not CpOk(Cp) Then R := ERROR_KBD_INVALID_CODEPAGE
    Else
    Begin
      HCp[Hkbd] := Cp;
      HXt[Hkbd] := DefXtAdr;
    End;
  End;
  KbdSetCp := R;
End;

{ ---------------------------------------------------------------------
  KbdSetCustXt(pusTransTbl, hkbd) : installer une table de traduction
  personnalisee (voir l'en-tete ; la table doit rester en memoire) }
Function KbdSetCustXt(PTbl, Hkbd : LongInt) : LongInt;
Var R, N, W : LongInt;
Begin
  If Hooked(KB_SETCUSTXT, 2, PTbl, Hkbd, 0, 0) Then
  Begin
    KbdSetCustXt := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (PTbl = 0) Then R := ERROR_KBD_PARAMETER;
  If R = NO_ERROR Then
  Begin
    N := RdW(PTbl + 12);
    W := RdW(PTbl + 14);
    If (N < 1) Or (N > 256) Or (W < 7) Then R := ERROR_KBD_INVALID_CODEPAGE_ID
    Else HXt[Hkbd] := PTbl;
  End;
  KbdSetCustXt := R;
End;

{ ---------------------------------------------------------------------
  KbdXlate(pkbdtrans, hkbd) : traduire un code de balayage (KBDTRANS)
  en caractere avec la table du clavier logique }
Function KbdXlate(PTr, Hkbd : LongInt) : LongInt;
Var R, Sc, St : LongInt; Ok, Gray : Boolean;
Begin
  If Hooked(KB_XLATE, 2, PTr, Hkbd, 0, 0) Then
  Begin
    KbdXlate := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (PTr = 0) Then R := ERROR_KBD_PARAMETER;
  If R = NO_ERROR Then
  Begin
    Sc := RdB(PTr + 1);
    St := RdW(PTr + 4);
    Gray := RdB(PTr) = $E0;
    If (Sc And $80) <> 0 Then
    Begin
      { touche relachee : aucun caractere }
      WrB(PTr, 0);
      WrB(PTr + 2, 0);
    End
    Else
    Begin
      Ok := Translate(HXt[Hkbd], Sc, Gray, St);
      If Ok Then
      Begin
        WrB(PTr, KChar);
        WrB(PTr + 1, KScan);
        WrB(PTr + 2, KStatus);
      End
      Else
      Begin
        WrB(PTr, 0);
        WrB(PTr + 2, 0);
        If Sc < RdW(HXt[Hkbd] + 12) Then
          If (RdW(HXt[Hkbd] + XtHdr + Sc * RdW(HXt[Hkbd] + 14)) And $7F) = KT_SHIFT Then
            WrB(PTr + 2, ST_SHIFT);
      End;
    End;
    WrB(PTr + 3, 0);
    WrW(PTr + 12, 1);              { fsXlate : traduction terminee }
    WrW(PTr + 14, St);             { fsShift }
    WrW(PTr + 16, 0);
  End;
  KbdXlate := R;
End;

{ ---------------------------------------------------------------------
  KbdGetHWId(pkbdhwid, hkbd) : identification du clavier (KBDHWID ;
  cb = taille a remplir, au moins 2, rendue a jour) }
Function KbdGetHWId(PId, Hkbd : LongInt) : LongInt;
Var R, Cb : LongInt;
Begin
  If Hooked(KB_GETHWID, 2, PId, Hkbd, 0, 0) Then
  Begin
    KbdGetHWId := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (PId = 0) Then R := ERROR_KBD_PARAMETER;
  If R = NO_ERROR Then
  Begin
    Cb := RdW(PId);
    If Cb < 2 Then R := ERROR_KBD_INVALID_LENGTH
    Else
    Begin
      If Cb > 8 Then Cb := 8;
      Cb := Cb And $FE;
      If Cb >= 4 Then WrW(PId + 2, HwId);
      If Cb >= 6 Then WrW(PId + 4, HwRes1);
      If Cb >= 8 Then WrW(PId + 6, HwRes2);
      WrW(PId, Cb);
    End;
  End;
  KbdGetHWId := R;
End;

{ ---------------------------------------------------------------------
  KbdSetHWId(pkbdhwid, hkbd) : changer l'identification du clavier
  (cb >= 4) }
Function KbdSetHWId(PId, Hkbd : LongInt) : LongInt;
Var R, Cb : LongInt;
Begin
  If Hooked(KB_SETHWID, 2, PId, Hkbd, 0, 0) Then
  Begin
    KbdSetHWId := HookRet;
    Exit;
  End;
  R := HErr(Hkbd);
  If (R = NO_ERROR) And (PId = 0) Then R := ERROR_KBD_PARAMETER;
  If R = NO_ERROR Then
  Begin
    Cb := RdW(PId);
    If Cb < 4 Then R := ERROR_KBD_INVALID_LENGTH
    Else
    Begin
      HwId := RdW(PId + 2);
      If Cb >= 6 Then HwRes1 := RdW(PId + 4);
      If Cb >= 8 Then HwRes2 := RdW(PId + 6);
    End;
  End;
  KbdSetHWId := R;
End;

{ ---------------------------------------------------------------------
  KbdSynch(fWait) : synchroniser l'acces au pilote du clavier (les
  appels sont deja serialises : rend immediatement) }
Function KbdSynch(Wait : LongInt) : LongInt;
Begin
  If (Wait <> IO_WAIT) And (Wait <> IO_NOWAIT) Then KbdSynch := ERROR_KBD_INVALID_IOWAIT
  Else KbdSynch := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  KbdRegister(pszModName, pszEntryPt, FunMask) : remplacer les fonctions
  choisies (bits KR_*) par la fonction pszEntryPt du module pszModName
  (voir l'en-tete) }
Function KbdRegister(PMod, PEntry, Funs : LongInt) : LongInt;
Var R, H, E : LongInt;
Begin
  R := NO_ERROR;
  If RegEntry <> 0 Then R := ERROR_KBD_REGISTER
  Else If (PMod = 0) Or (PEntry = 0) Then R := ERROR_KBD_INVALID_ASCIIZ
  Else If (Funs = 0) Or ((Funs And Not $FFFF) <> 0) Then R := ERROR_KBD_INVALID_MASK
  Else
  Begin
    E := 0;
    If DosLoadModule(LongInt(@FailName), 64, PMod, LongInt(@H)) <> NO_ERROR Then R := ERROR_KBD_INVALID_ASCIIZ
    Else If (DosQueryProcAddr(H, 0, PEntry, LongInt(@E)) <> NO_ERROR) Or (E = 0) Then
      R := ERROR_KBD_INVALID_ASCIIZ;
    If R = NO_ERROR Then
    Begin
      RegEntry := E;
      RegFuns := Funs;
    End;
  End;
  KbdRegister := R;
End;

{ ---------------------------------------------------------------------
  KbdDeRegister : retirer le remplacement }
Function KbdDeRegister : LongInt;
Begin
  If RegEntry = 0 Then KbdDeRegister := ERROR_KBD_DEREGISTER
  Else
  Begin
    RegEntry := 0;
    RegFuns := 0;
    KbdDeRegister := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  KbdFree : liberer les claviers logiques et le focus du processus ; le
  clavier par defaut reprend son etat initial }
Function KbdFree : LongInt;
Var I, Pid : LongInt;
Begin
  Pid := MyPid;
  For I := 1 To MaxH Do
    If HUsed[I] And (HPid[I] = Pid) Then
    Begin
      If Focus = I Then Focus := -1;
      HUsed[I] := False;
    End;
  If (Focus = 0) And (FocusPid = Pid) Then Focus := -1;
  ResetHandle(0);
  SyncMode(0);
  KbdFree := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  KbdInit : initialiser le sous-systeme pour la session (claviers
  logiques fermes, focus libre, etat par defaut, tampon vide) }
Function KbdInit : LongInt;
Var I, D : LongInt;
Begin
  For I := 1 To MaxH Do HUsed[I] := False;
  Focus := -1;
  ResetHandle(0);
  SyncMode(0);
  D := KrnKbdCtl(3, 0);
  KbdInit := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  KbdShellInit : le processus appelant devient l'interpreteur de
  commandes de la session (le clavier par defaut est reinitialise) }
Function KbdShellInit : LongInt;
Begin
  ShellPid := MyPid;
  ResetHandle(0);
  SyncMode(0);
  KbdShellInit := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  KbdLoadInstance : charger les donnees d'instance du processus (le
  sous-systeme est partage : rien a charger) }
Function KbdLoadInstance : LongInt;
Begin
  If Not Present Then KbdLoadInstance := ERROR_KBD_NO_DEVICE
  Else KbdLoadInstance := NO_ERROR;
End;

{ ---------------------------------------------------------------------
  KbdSwitchFgnd(usScreenGrp) : passage d'une session au premier plan
  (gestionnaire de sessions) : le focus est libere et le tampon vide }
Function KbdSwitchFgnd(Sess : LongInt) : LongInt;
Var D : LongInt;
Begin
  If Sess < 0 Then KbdSwitchFgnd := ERROR_KBD_PARAMETER
  Else
  Begin
    If Sess <> FgSess Then
    Begin
      Focus := -1;
      D := KrnKbdCtl(3, 0);
    End;
    FgSess := Sess;
    KbdSwitchFgnd := NO_ERROR;
  End;
End;

{ ---------------------------------------------------------------------
  KbdSetFgnd : le processus appelant passe au premier plan (le
  rapport des touches suit son clavier par defaut) }
Function KbdSetFgnd : LongInt;
Begin
  FgPid := MyPid;
  SyncMode(0);
  KbdSetFgnd := NO_ERROR;
End;

{ ==================================================================== }
{ Exportations et initialisation                                       }
{ ==================================================================== }

exports
  KbdSetCustXt Index 1, KbdInit Index 2, KbdGetCp Index 3,
  KbdCharIn Index 4, KbdSetCp Index 5, KbdLoadInstance Index 6,
  KbdSynch Index 7, KbdRegister Index 8, KbdStringIn Index 9,
  KbdGetStatus Index 10, KbdSetStatus Index 11, KbdGetFocus Index 12,
  KbdFlushBuffer Index 13, KbdXlate Index 14, KbdSwitchFgnd Index 15,
  KbdShellInit Index 16, KbdClose Index 17, KbdFreeFocus Index 18,
  KbdFree Index 19, KbdDeRegister Index 20, KbdSetFgnd Index 21,
  KbdPeek Index 22, KbdOpen Index 23, KbdGetHWId Index 24,
  KbdSetHWId Index 25;

Var
  InitI, InitN : LongInt;

BEGIN
  SysCp := 437;
  InitN := 0;
  If DcQueryCp(8, LongInt(@CpBuf), LongInt(@InitN)) = NO_ERROR Then
    If CpOk(CpBuf[0]) Then SysCp := CpBuf[0];
  BuildDefXt(SysCp);
  DefXtAdr := LongInt(@DefXt);
  For InitI := 0 To MaxH Do
  Begin
    HUsed[InitI] := False;
    HPid[InitI] := 0;
    ResetHandle(InitI);
  End;
  HUsed[0] := True;
  Focus := -1;
  FocusPid := 0;
  HwId := DefKbdId;
  HwRes1 := 0; HwRes2 := 0;
  FgPid := 0; FgSess := 0; ShellPid := 0;
  RegEntry := 0; RegFuns := 0;
  InHook := False;
  Present := True;
END.
