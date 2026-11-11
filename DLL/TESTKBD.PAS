{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2026
  @website(https://www.gladir.com/os2-0)
  @abstract(Target: OS2PC -COS2)
  @description: Programme d'essai de KBDCALLS.DLL sous OS/2-0.
}

Program TESTKBD;

{$R-,S-,I-}

{ Compilation : OS2PC TESTKBD.PAS   (produit TESTKBD.EXE)

  TESTKBD        verifie les 25 fonctions de KBDCALLS.DLL ; la seconde
                 partie lit des touches. Taper, dans l'ordre :
                   a  Maj+a  Ctrl+c  F1  Alt+x  fleche haut (grise)
                   Maj+F2  Ctrl+fleche gauche (grise)  7 du pave
                   numerique (Verr num eteint)  z
                   a b c Retour-arriere d Entree
                   Maj+j F3 Entree
                   x F5 y
                   Maj (seule)
                   Verr maj  q  Verr maj
                   k
                 Avec QEMU (sendkey) : a shift-a ctrl-c f1 alt-x up
                 shift-f2 ctrl-left kp_7 z a b c backspace d ret shift-j
                 f3 ret x f5 y shift caps_lock q caps_lock k
  TESTKBD VOIR   affiche ensuite les touches lues (Echap pour
                 terminer). }

Function KbdSetCustXt(PTbl, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdInit : LongInt; External 'KBDCALLS';
Function KbdGetCp(Res, PCp, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdCharIn(PInfo, Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdSetCp(Res, Cp, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdLoadInstance : LongInt; External 'KBDCALLS';
Function KbdSynch(Wait : LongInt) : LongInt; External 'KBDCALLS';
Function KbdRegister(PMod, PEntry, Funs : LongInt) : LongInt; External 'KBDCALLS';
Function KbdStringIn(PCh, PIn, Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdGetStatus(PInfo, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdSetStatus(PInfo, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdGetFocus(Wait, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdFlushBuffer(Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdXlate(PTr, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdSwitchFgnd(Sess : LongInt) : LongInt; External 'KBDCALLS';
Function KbdShellInit : LongInt; External 'KBDCALLS';
Function KbdClose(Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdFreeFocus(Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdFree : LongInt; External 'KBDCALLS';
Function KbdDeRegister : LongInt; External 'KBDCALLS';
Function KbdSetFgnd : LongInt; External 'KBDCALLS';
Function KbdPeek(PInfo, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdOpen(PH : LongInt) : LongInt; External 'KBDCALLS';
Function KbdGetHWId(PId, Hkbd : LongInt) : LongInt; External 'KBDCALLS';
Function KbdSetHWId(PId, Hkbd : LongInt) : LongInt; External 'KBDCALLS';

Function ReplCalls : LongInt; External 'TESTVIOR';

Function DosQueryModuleHandle(PName, PHmod : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryProcAddr(H, Ord, PName, PPfn : LongInt) : LongInt; External 'DOSCALLS';
Function DosWrite(H, Buf, Cb, PActual : LongInt) : LongInt; External 'DOSCALLS';
Function DosSleep(Ms : LongInt) : LongInt; External 'DOSCALLS';
Function DosQueryCp(Cb, PCp, PcbActual : LongInt) : LongInt; External 'DOSCALLS';

Const
  ERROR_KBD_PARAMETER = 373;
  ERROR_KBD_INVALID_IOWAIT = 375;
  ERROR_KBD_INVALID_LENGTH = 376;
  ERROR_KBD_INVALID_ECHO_MASK = 377;
  ERROR_KBD_INVALID_INPUT_MASK = 378;
  ERROR_KBD_INVALID_ASCIIZ = 408;
  ERROR_KBD_INVALID_MASK = 409;
  ERROR_KBD_REGISTER = 410;
  ERROR_KBD_DEREGISTER = 411;
  ERROR_KBD_INVALID_HANDLE = 439;
  ERROR_KBD_FOCUS_REQUIRED = 445;
  ERROR_KBD_FOCUS_ALREADY_ACTIVE = 446;
  ERROR_KBD_INVALID_CODEPAGE = 448;
  ERROR_KBD_UNABLE_TO_FOCUS = 449;

Type
  PByte = ^Byte;
  PLong = ^LongInt;
  PWord = ^Word;

Var
  Ok, Fail, R, R2, I, N, H, A, B, Hk, Hk2, SysCp : LongInt;
  Name : Array[0..127] Of Byte;
  Name2 : Array[0..127] Of Byte;
  Ki : Array[0..15] Of Byte;          { KBDKEYINFO }
  Inf : Array[0..15] Of Byte;         { KBDINFO, KBDHWID }
  Tr : Array[0..31] Of Byte;          { KBDTRANS }
  Sb : Array[0..3] Of Byte;           { STRINGINBUF }
  Buf : Array[0..63] Of Byte;
  Xt : Array[0..1023] Of Byte;        { table de traduction personnalisee }
  CpBuf : Array[0..3] Of LongInt;
  OutBuf : Array[0..16383] Of Byte;
  OutLen : LongInt;

Function IStr(V : LongInt) : String;
Var T : String;
Begin
  Str(V, T);
  IStr := T;
End;

Function HStr(V : LongInt) : String;
Const Dg = '0123456789ABCDEF';
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 3 DownTo 0 Do T := T + Dg[((V Shr (K * 4)) And 15) + 1];
  HStr := T;
End;

Function RdW(A : LongInt) : LongInt;
Var P : PWord;
Begin
  P := Pointer(A);
  RdW := P^;
End;

Function RdB(A : LongInt) : LongInt;
Var P : PByte;
Begin
  P := Pointer(A);
  RdB := P^;
End;

Procedure WrW(A, V : LongInt);
Var P : PWord;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure WrB(A, V : LongInt);
Var P : PByte;
Begin
  P := Pointer(A);
  P^ := V;
End;

Procedure PutZ(A : LongInt; S : String);
Var K : LongInt;
Begin
  For K := 1 To Length(S) Do WrB(A + K - 1, Ord(S[K]));
  WrB(A + Length(S), 0);
End;

Function Z(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name), S);
  Z := LongInt(@Name);
End;

Function Z2(S : String) : LongInt;
Begin
  PutZ(LongInt(@Name2), S);
  Z2 := LongInt(@Name2);
End;

Procedure OutStr(T : String);
Var K : LongInt;
Begin
  For K := 1 To Length(T) Do
    If OutLen < 16380 Then
    Begin
      OutBuf[OutLen] := Ord(T[K]);
      Inc(OutLen);
    End;
End;

Procedure Check(What : String; Cond : Boolean);
Begin
  If Cond Then
  Begin
    Inc(Ok);
    OutStr('  OK     ' + What + Chr(13) + Chr(10));
  End
  Else
  Begin
    Inc(Fail);
    OutStr('  ECHEC  ' + What + '  (code ' + IStr(R) + ')' + Chr(13) + Chr(10));
  End;
End;

Function OrdIs(Ordinal : LongInt; S : String) : Boolean;
Var Pa, Pb : LongInt;
Begin
  Pa := 0; Pb := 0;
  DosQueryProcAddr(H, 0, Z(S), LongInt(@Pa));
  DosQueryProcAddr(H, Ordinal, 0, LongInt(@Pb));
  OrdIs := (Pa <> 0) And (Pa = Pb);
End;

{ KbdXlate : traduire Sc avec l'etat St (Pre = E0h pour une touche grise) }
Function Xl(Pre, Sc, St : LongInt) : LongInt;
Var K : LongInt;
Begin
  For K := 0 To 31 Do Tr[K] := 0;
  Tr[0] := Pre;
  Tr[1] := Sc;
  WrW(LongInt(@Tr) + 4, St);
  Xl := KbdXlate(LongInt(@Tr), 0);
End;

{ Lire une touche (avec attente) }
Procedure Key;
Begin
  R := KbdCharIn(LongInt(@Ki), 0, 0);
End;

Function KChr : LongInt;
Begin
  KChr := Ki[0];
End;

Function KScn : LongInt;
Begin
  KScn := Ki[1];
End;

Function KSt : LongInt;
Begin
  KSt := Ki[2];
End;

Function KDesc : String;
Begin
  KDesc := ' [' + HStr(KChr) + ' ' + HStr(KScn) + ' ' + HStr(KSt) + ' ' +
           HStr(RdW(LongInt(@Ki) + 4)) + ']';
End;

Function Status(Mask, Turn : LongInt) : LongInt;
Begin
  WrW(LongInt(@Inf), 10);
  WrW(LongInt(@Inf) + 2, Mask);
  WrW(LongInt(@Inf) + 4, Turn);
  WrW(LongInt(@Inf) + 6, 0);
  WrW(LongInt(@Inf) + 8, 0);
  Status := KbdSetStatus(LongInt(@Inf), 0);
End;

Function BufStr(Len : LongInt) : String;
Var T : String; K : LongInt;
Begin
  T := '';
  For K := 0 To Len - 1 Do T := T + Chr(Buf[K]);
  BufStr := T;
End;

BEGIN
  Ok := 0; Fail := 0; OutLen := 0;
  WriteLn('TESTKBD : essai de KBDCALLS.DLL');

  { --- module et ordinaux --- }
  R := DosQueryModuleHandle(Z('KBDCALLS'), LongInt(@H));
  Check('DosQueryModuleHandle KBDCALLS', R = 0);
  Check('ordinaux 1 a 9 (KbdSetCustXt ... KbdStringIn)',
        OrdIs(1, 'KbdSetCustXt') And OrdIs(2, 'KbdInit') And OrdIs(3, 'KbdGetCp') And
        OrdIs(4, 'KbdCharIn') And OrdIs(5, 'KbdSetCp') And OrdIs(6, 'KbdLoadInstance') And
        OrdIs(7, 'KbdSynch') And OrdIs(8, 'KbdRegister') And OrdIs(9, 'KbdStringIn'));
  Check('ordinaux 10 a 17 (KbdGetStatus ... KbdClose)',
        OrdIs(10, 'KbdGetStatus') And OrdIs(11, 'KbdSetStatus') And OrdIs(12, 'KbdGetFocus') And
        OrdIs(13, 'KbdFlushBuffer') And OrdIs(14, 'KbdXlate') And OrdIs(15, 'KbdSwitchFgnd') And
        OrdIs(16, 'KbdShellInit') And OrdIs(17, 'KbdClose'));
  Check('ordinaux 18 a 25 (KbdFreeFocus ... KbdSetHWId)',
        OrdIs(18, 'KbdFreeFocus') And OrdIs(19, 'KbdFree') And OrdIs(20, 'KbdDeRegister') And
        OrdIs(21, 'KbdSetFgnd') And OrdIs(22, 'KbdPeek') And OrdIs(23, 'KbdOpen') And
        OrdIs(24, 'KbdGetHWId') And OrdIs(25, 'KbdSetHWId'));

  { --- initialisation de session --- }
  Check('KbdShellInit', KbdShellInit = 0);
  Check('KbdLoadInstance', KbdLoadInstance = 0);
  Check('KbdSetFgnd', KbdSetFgnd = 0);
  Check('KbdSwitchFgnd(0)', KbdSwitchFgnd(0) = 0);
  Check('KbdInit', KbdInit = 0);
  R := KbdSynch(0);
  R2 := KbdSynch(5);
  Check('KbdSynch IO_WAIT, fWait invalide refuse', (R = 0) And (R2 = ERROR_KBD_INVALID_IOWAIT));

  { --- etat --- }
  WrW(LongInt(@Inf), 10);
  R := KbdGetStatus(LongInt(@Inf), 0);
  Check('KbdGetStatus : echo, mode ASCII, fin = 0Dh (' + HStr(RdW(LongInt(@Inf) + 2)) + ')',
        (R = 0) And (RdW(LongInt(@Inf) + 2) = $0009) And (RdW(LongInt(@Inf) + 4) = $0D));
  WrW(LongInt(@Inf), 4);
  R := KbdGetStatus(LongInt(@Inf), 0);
  Check('KbdGetStatus cb trop petit refuse', R = ERROR_KBD_INVALID_LENGTH);
  R := KbdGetStatus(LongInt(@Inf), 77);
  Check('KbdGetStatus handle invalide refuse', R = ERROR_KBD_INVALID_HANDLE);
  R := Status($0003, 0);
  Check('KbdSetStatus echo actif et inactif refuse', R = ERROR_KBD_INVALID_ECHO_MASK);
  R := Status($000C, 0);
  Check('KbdSetStatus binaire et ASCII refuse', R = ERROR_KBD_INVALID_INPUT_MASK);
  R := Status($0006, 0);
  WrW(LongInt(@Inf), 10);
  R2 := KbdGetStatus(LongInt(@Inf), 0);
  Check('KbdSetStatus mode binaire sans echo', (R = 0) And (RdW(LongInt(@Inf) + 2) = $0006));
  R := Status($0009 Or $0040, $1B);
  WrW(LongInt(@Inf), 10);
  R2 := KbdGetStatus(LongInt(@Inf), 0);
  Check('KbdSetStatus mode ASCII, echo, caractere de fin 1Bh',
        (R = 0) And (RdW(LongInt(@Inf) + 2) = $0009) And (RdW(LongInt(@Inf) + 4) = $1B));
  R := Status($0040, $0D);
  WrW(LongInt(@Inf), 10);
  WrW(LongInt(@Inf) + 2, $0010);
  WrW(LongInt(@Inf) + 8, $0040);
  R := KbdSetStatus(LongInt(@Inf), 0);
  WrW(LongInt(@Inf), 10);
  R2 := KbdGetStatus(LongInt(@Inf), 0);
  A := RdW(LongInt(@Inf) + 8);
  WrW(LongInt(@Inf), 10);
  WrW(LongInt(@Inf) + 2, $0010);
  WrW(LongInt(@Inf) + 8, 0);
  R2 := KbdSetStatus(LongInt(@Inf), 0);
  Check('KbdSetStatus fsState : Verr maj (fsState = ' + HStr(A) + ')', (R = 0) And ((A And $0040) <> 0));
  WrW(LongInt(@Inf), 6);
  R := KbdSetStatus(LongInt(@Inf), 0);
  Check('KbdSetStatus cb invalide refuse', R = ERROR_KBD_INVALID_LENGTH);

  { --- pages de codes --- }
  N := 0;
  SysCp := 437;
  If DosQueryCp(16, LongInt(@CpBuf), LongInt(@N)) = 0 Then SysCp := CpBuf[0];
  A := 0;
  R := KbdGetCp(0, LongInt(@A), 0);
  Check('KbdGetCp : page de codes du systeme (' + IStr(A) + ')', (R = 0) And (A = SysCp));
  R := KbdSetCp(0, 850, 0);
  R2 := KbdGetCp(0, LongInt(@A), 0);
  Check('KbdSetCp 850', (R = 0) And (A = 850));
  R := KbdSetCp(0, 1234, 0);
  Check('KbdSetCp page inconnue refusee', R = ERROR_KBD_INVALID_CODEPAGE);
  R := KbdGetCp(1, LongInt(@A), 0);
  Check('KbdGetCp ulReserved <> 0 refuse', R = ERROR_KBD_PARAMETER);
  R := KbdSetCp(0, 0, 0);
  R2 := KbdGetCp(0, LongInt(@A), 0);
  Check('KbdSetCp 0 : page du systeme', (R = 0) And (A = SysCp));

  { --- identification du materiel --- }
  For I := 0 To 15 Do Inf[I] := 0;
  WrW(LongInt(@Inf), 8);
  R := KbdGetHWId(LongInt(@Inf), 0);
  Check('KbdGetHWId : clavier etendu AB41h (' + HStr(RdW(LongInt(@Inf) + 2)) + ')',
        (R = 0) And (RdW(LongInt(@Inf)) = 8) And (RdW(LongInt(@Inf) + 2) = $AB41));
  WrW(LongInt(@Inf), 0);
  R := KbdGetHWId(LongInt(@Inf), 0);
  Check('KbdGetHWId cb = 0 refuse', R = ERROR_KBD_INVALID_LENGTH);
  WrW(LongInt(@Inf), 4);
  WrW(LongInt(@Inf) + 2, $1234);
  R := KbdSetHWId(LongInt(@Inf), 0);
  WrW(LongInt(@Inf), 4);
  WrW(LongInt(@Inf) + 2, 0);
  R2 := KbdGetHWId(LongInt(@Inf), 0);
  Check('KbdSetHWId 1234h', (R = 0) And (RdW(LongInt(@Inf) + 2) = $1234));
  WrW(LongInt(@Inf), 4);
  WrW(LongInt(@Inf) + 2, $AB41);
  R := KbdSetHWId(LongInt(@Inf), 0);

  { --- traduction --- }
  R := Xl(0, $1E, 0);
  Check('KbdXlate 1Eh -> a, fsXlate = 1', (R = 0) And (Tr[0] = Ord('a')) And (Tr[2] = $40) And
        (RdW(LongInt(@Tr) + 12) = 1));
  R := Xl(0, $1E, $0002);
  Check('KbdXlate 1Eh + Maj -> A', (R = 0) And (Tr[0] = Ord('A')));
  R := Xl(0, $1E, $0040);
  Check('KbdXlate 1Eh + Verr maj -> A', (R = 0) And (Tr[0] = Ord('A')));
  R := Xl(0, $1E, $0042);
  Check('KbdXlate 1Eh + Verr maj + Maj -> a', (R = 0) And (Tr[0] = Ord('a')));
  R := Xl(0, $02, $0040);
  Check('KbdXlate 02h + Verr maj -> 1 (pas une lettre)', (R = 0) And (Tr[0] = Ord('1')));
  R := Xl(0, $2E, $0004);
  Check('KbdXlate Ctrl+C -> 03h', (R = 0) And (Tr[0] = 3));
  R := Xl(0, $3B, $0008);
  Check('KbdXlate Alt+F1 -> 00h 68h etendu', (R = 0) And (Tr[0] = 0) And (Tr[1] = $68) And (Tr[2] = $42));
  R := Xl(0, $57, 0);
  Check('KbdXlate F11 -> 00h 85h', (R = 0) And (Tr[0] = 0) And (Tr[1] = $85));
  R := Xl(0, $03, $0008);
  Check('KbdXlate Alt+2 -> 00h 79h', (R = 0) And (Tr[0] = 0) And (Tr[1] = $79));
  R := Xl($E0, $48, 0);
  Check('KbdXlate fleche haut grise -> E0h 48h', (R = 0) And (Tr[0] = $E0) And (Tr[1] = $48));
  R := Xl($E0, $1C, 0);
  Check('KbdXlate Entree du pave -> 0Dh E0h', (R = 0) And (Tr[0] = $0D) And (Tr[1] = $E0));
  R := Xl(0, $4B, $0020);
  Check('KbdXlate 4Bh + Verr num -> 4', (R = 0) And (Tr[0] = Ord('4')));
  R := Xl(0, $4B, 0);
  Check('KbdXlate 4Bh -> 00h 4Bh (fleche gauche)', (R = 0) And (Tr[0] = 0) And (Tr[1] = $4B));
  R := Xl(0, $4B, $0004);
  Check('KbdXlate Ctrl+fleche gauche -> 00h 73h', (R = 0) And (Tr[0] = 0) And (Tr[1] = $73));
  R := Xl(0, $0F, $0002);
  Check('KbdXlate Maj+Tab -> 00h 0Fh', (R = 0) And (Tr[0] = 0) And (Tr[1] = $0F));
  R := Xl(0, $9E, 0);
  Check('KbdXlate touche relachee : aucun caractere', (R = 0) And (Tr[0] = 0) And (Tr[2] = 0) And
        (RdW(LongInt(@Tr) + 12) = 1));
  R := Xl(0, $2A, 0);
  Check('KbdXlate Maj gauche : touche de changement d''etat', (R = 0) And (Tr[2] = 1));
  R := KbdXlate(0, 0);
  Check('KbdXlate pointeur nul refuse', R = ERROR_KBD_PARAMETER);

  { --- table personnalisee : 1Eh -> q/Q, 10h -> a/A (AZERTY) --- }
  For I := 0 To 1023 Do Xt[I] := 0;
  WrW(LongInt(@Xt), 437);
  WrW(LongInt(@Xt) + 10, 40 + 128 * 7);
  WrW(LongInt(@Xt) + 12, 128);
  WrW(LongInt(@Xt) + 14, 7);
  A := LongInt(@Xt) + 40 + $1E * 7;
  WrW(A, 1); WrB(A + 2, Ord('q')); WrB(A + 3, Ord('Q')); WrB(A + 4, $11);
  A := LongInt(@Xt) + 40 + $10 * 7;
  WrW(A, 1); WrB(A + 2, Ord('a')); WrB(A + 3, Ord('A')); WrB(A + 4, $01);
  R := KbdSetCustXt(LongInt(@Xt), 0);
  R2 := Xl(0, $1E, 0);
  B := Tr[0];
  R2 := Xl(0, $10, $0002);
  Check('KbdSetCustXt : 1Eh -> q, Maj+10h -> A', (R = 0) And (B = Ord('q')) And (Tr[0] = Ord('A')));
  R2 := Xl(0, $11, 0);
  Check('KbdSetCustXt : touche absente de la table sans caractere', Tr[2] = 0);
  R := KbdSetCp(0, 0, 0);
  R2 := Xl(0, $1E, 0);
  Check('KbdSetCp : retour a la table standard', (R = 0) And (Tr[0] = Ord('a')));
  WrW(LongInt(@Xt) + 12, 0);
  R := KbdSetCustXt(LongInt(@Xt), 0);
  Check('KbdSetCustXt table invalide refusee', R <> 0);

  { --- claviers logiques et focus --- }
  Hk := 0; Hk2 := 0;
  R := KbdOpen(LongInt(@Hk));
  R2 := KbdOpen(LongInt(@Hk2));
  Check('KbdOpen deux claviers logiques (' + IStr(Hk) + ', ' + IStr(Hk2) + ')',
        (R = 0) And (R2 = 0) And (Hk >= 1) And (Hk2 >= 1) And (Hk <> Hk2));
  R := KbdOpen(0);
  Check('KbdOpen pointeur nul refuse', R = ERROR_KBD_PARAMETER);
  R := KbdGetFocus(0, Hk);
  Check('KbdGetFocus', R = 0);
  R := KbdGetFocus(1, Hk);
  Check('KbdGetFocus deja actif', R = ERROR_KBD_FOCUS_ALREADY_ACTIVE);
  R := KbdGetFocus(1, Hk2);
  Check('KbdGetFocus focus detenu par un autre clavier', R = ERROR_KBD_UNABLE_TO_FOCUS);
  R := KbdCharIn(LongInt(@Ki), 1, Hk2);
  Check('KbdCharIn sans le focus refuse', R = ERROR_KBD_FOCUS_REQUIRED);
  R := KbdFreeFocus(Hk2);
  Check('KbdFreeFocus sans le focus refuse', R = ERROR_KBD_FOCUS_REQUIRED);
  WrW(LongInt(@Inf), 10);
  WrW(LongInt(@Inf) + 2, $0004);
  R := KbdSetStatus(LongInt(@Inf), Hk);
  WrW(LongInt(@Inf), 10);
  R2 := KbdGetStatus(LongInt(@Inf), 0);
  Check('KbdSetStatus propre au clavier logique', (R = 0) And (RdW(LongInt(@Inf) + 2) = $0009));
  R := KbdCharIn(LongInt(@Ki), 1, Hk);
  Check('KbdCharIn IO_NOWAIT avec le focus : tampon vide', (R = 0) And (Ki[2] = 0));
  R := KbdFreeFocus(Hk);
  Check('KbdFreeFocus', R = 0);
  R := KbdClose(Hk2);
  R2 := KbdClose(Hk2);
  Check('KbdClose, puis handle ferme refuse', (R = 0) And (R2 = ERROR_KBD_INVALID_HANDLE));
  R := KbdClose(0);
  Check('KbdClose du clavier par defaut refuse', R = ERROR_KBD_INVALID_HANDLE);

  { --- remplacement --- }
  R := KbdRegister(Z('TESTVIOR'), Z2('VioReplace'), 0);
  Check('KbdRegister masque vide refuse', R = ERROR_KBD_INVALID_MASK);
  R := KbdRegister(0, Z2('VioReplace'), 2);
  Check('KbdRegister nom nul refuse', R = ERROR_KBD_INVALID_ASCIIZ);
  R := KbdRegister(Z('TESTVIOR'), Z2('Inexistante'), 2);
  Check('KbdRegister point d''entree inconnu refuse', R = ERROR_KBD_INVALID_ASCIIZ);
  A := ReplCalls;
  R := KbdRegister(Z('TESTVIOR'), Z2('VioReplace'), 2);
  R2 := KbdPeek(LongInt(@Ki), 0);
  Check('KbdRegister KR_KBDPEEK (le remplacant rend 99)', (R = 0) And (R2 = 99) And (ReplCalls = A + 1));
  R := KbdRegister(Z('TESTVIOR'), Z2('VioReplace'), 2);
  Check('KbdRegister deja enregistre refuse', R = ERROR_KBD_REGISTER);
  R := KbdDeRegister;
  R2 := KbdDeRegister;
  Check('KbdDeRegister, puis deja retire refuse', (R = 0) And (R2 = ERROR_KBD_DEREGISTER));

  { --- lecture des touches --- }
  R := KbdFlushBuffer(0);
  Check('KbdFlushBuffer', R = 0);
  R := KbdCharIn(LongInt(@Ki), 1, 0);
  Check('KbdCharIn IO_NOWAIT : aucune touche (fbStatus = 0)', (R = 0) And (Ki[2] = 0));
  R := KbdPeek(LongInt(@Ki), 0);
  Check('KbdPeek : aucune touche', (R = 0) And (Ki[2] = 0));
  R := KbdCharIn(LongInt(@Ki), 7, 0);
  Check('KbdCharIn fWait invalide refuse', R = ERROR_KBD_INVALID_IOWAIT);

  WriteLn('Tapez : a Maj+a Ctrl+c F1 Alt+x Haut Maj+F2 Ctrl+Gauche 7(pave) z');
  Key;
  Check('KbdCharIn a' + KDesc, (R = 0) And (KChr = Ord('a')) And (KScn = $1E) And (KSt = $40));
  Key;
  Check('KbdCharIn Maj+a -> A, fsState Maj' + KDesc, (KChr = Ord('A')) And ((RdW(LongInt(@Ki) + 4) And 3) <> 0));
  Key;
  Check('KbdCharIn Ctrl+c -> 03h' + KDesc, (KChr = 3) And (KScn = $2E) And ((RdW(LongInt(@Ki) + 4) And $0104) = $0104));
  Key;
  Check('KbdCharIn F1 -> 00h 3Bh etendu' + KDesc, (KChr = 0) And (KScn = $3B) And (KSt = $42));
  Key;
  Check('KbdCharIn Alt+x -> 00h 2Dh' + KDesc, (KChr = 0) And (KScn = $2D));
  Key;
  Check('KbdCharIn fleche haut grise -> E0h 48h' + KDesc, (KChr = $E0) And (KScn = $48));
  Key;
  Check('KbdCharIn Maj+F2 -> 00h 55h' + KDesc, (KChr = 0) And (KScn = $55));
  Key;
  Check('KbdCharIn Ctrl+fleche gauche grise -> E0h 73h' + KDesc, (KChr = $E0) And (KScn = $73));
  Key;
  Check('KbdCharIn 7 du pave (Verr num eteint) -> 00h 47h' + KDesc, (KChr = 0) And (KScn = $47));
  I := 0;
  Repeat
    R := KbdPeek(LongInt(@Ki), 0);
    If Ki[2] = 0 Then DosSleep(50);
    Inc(I);
  Until (Ki[2] <> 0) Or (I > 400);
  R2 := KbdPeek(LongInt(@Ki), 0);
  Check('KbdPeek z (deux fois, sans retrait)' + KDesc, (R = 0) And (R2 = 0) And (KChr = Ord('z')) And (KSt = $40));
  Key;
  Check('KbdCharIn z apres KbdPeek', KChr = Ord('z'));
  Check('KbdCharIn : heure de la touche (ms)', (Ki[6] Or Ki[7] Or Ki[8] Or Ki[9]) <> 0);

  { KbdStringIn mode ASCII }
  WriteLn('Tapez : a b c Retour-arriere d Entree');
  For I := 0 To 63 Do Buf[I] := 0;
  WrW(LongInt(@Sb), 40);
  WrW(LongInt(@Sb) + 2, 0);
  R := KbdStringIn(LongInt(@Buf), LongInt(@Sb), 0, 0);
  N := RdW(LongInt(@Sb) + 2);
  Check('KbdStringIn ASCII avec edition : "' + BufStr(N) + '"',
        (R = 0) And (N = 3) And (BufStr(3) = 'abd') And (Buf[3] = 13));
  WriteLn('Tapez : Maj+j F3 Entree');
  PutZ(LongInt(@Buf), 'hello');
  WrW(LongInt(@Sb), 40);
  WrW(LongInt(@Sb) + 2, 5);
  R := KbdStringIn(LongInt(@Buf), LongInt(@Sb), 0, 0);
  N := RdW(LongInt(@Sb) + 2);
  Check('KbdStringIn gabarit (F3) : "' + BufStr(N) + '"', (R = 0) And (N = 5) And (BufStr(5) = 'Jello'));
  R := KbdStringIn(LongInt(@Buf), LongInt(@Sb), 1, 0);
  Check('KbdStringIn ASCII IO_NOWAIT refuse', R = ERROR_KBD_INVALID_IOWAIT);
  WrW(LongInt(@Sb), 0);
  R := KbdStringIn(LongInt(@Buf), LongInt(@Sb), 0, 0);
  Check('KbdStringIn cb = 0 refuse', R = ERROR_KBD_INVALID_LENGTH);

  { KbdStringIn mode binaire }
  WriteLn('Tapez : x F5 y');
  R := Status($0004, 0);
  For I := 0 To 63 Do Buf[I] := 0;
  WrW(LongInt(@Sb), 4);
  WrW(LongInt(@Sb) + 2, 0);
  R := KbdStringIn(LongInt(@Buf), LongInt(@Sb), 0, 0);
  N := RdW(LongInt(@Sb) + 2);
  Check('KbdStringIn binaire : x, 00h 3Fh, y', (R = 0) And (N = 4) And (Buf[0] = Ord('x')) And
        (Buf[1] = 0) And (Buf[2] = $3F) And (Buf[3] = Ord('y')));
  WrW(LongInt(@Sb), 10);
  R := KbdStringIn(LongInt(@Buf), LongInt(@Sb), 1, 0);
  Check('KbdStringIn binaire IO_NOWAIT : rien de disponible', (R = 0) And (RdW(LongInt(@Sb) + 2) = 0));

  { rapport des touches de changement d'etat }
  WriteLn('Tapez : Maj (seule)');
  R := Status($0008 Or $0100, 0);
  WrW(LongInt(@Inf), 10);
  R2 := KbdGetStatus(LongInt(@Inf), 0);
  Check('KbdSetStatus rapport des changements d''etat', (R = 0) And ((RdW(LongInt(@Inf) + 2) And $0100) <> 0));
  Key;
  A := KScn; B := RdW(LongInt(@Ki) + 4);
  Check('rapport : Maj enfoncee' + KDesc, (KSt = 1) And (A = $2A) And ((B And 2) <> 0));
  Key;
  Check('rapport : Maj relachee' + KDesc, (KSt = 1) And (KScn = $AA) And ((RdW(LongInt(@Ki) + 4) And 2) = 0));
  R := Status($0008, 0);

  { verrouillage des majuscules }
  WriteLn('Tapez : Verr maj, q, Verr maj');
  Key;
  Check('Verr maj : q -> Q' + KDesc, (KChr = Ord('Q')) And ((RdW(LongInt(@Ki) + 4) And $0040) <> 0));
  I := 0;
  Repeat
    WrW(LongInt(@Inf), 10);
    R2 := KbdGetStatus(LongInt(@Inf), 0);
    If (RdW(LongInt(@Inf) + 8) And $0040) <> 0 Then DosSleep(50);
    Inc(I);
  Until ((RdW(LongInt(@Inf) + 8) And $0040) = 0) Or (I > 200);
  Check('Verr maj eteint (KbdGetStatus fsState)', (RdW(LongInt(@Inf) + 8) And $0040) = 0);

  { lecture par un clavier logique ayant le focus }
  WriteLn('Tapez : k');
  R := KbdGetFocus(0, Hk);
  R2 := KbdCharIn(LongInt(@Ki), 0, Hk);
  Check('KbdCharIn par un clavier logique : k' + KDesc, (R = 0) And (R2 = 0) And (KChr = Ord('k')));
  R := KbdFreeFocus(Hk);
  R2 := KbdClose(Hk);
  Check('KbdFreeFocus, KbdClose', (R = 0) And (R2 = 0));

  If (ParamCount > 0) And ((ParamStr(1) = 'VOIR') Or (ParamStr(1) = 'voir')) Then
  Begin
    WriteLn('Tapez des touches ; Echap pour terminer.');
    Repeat
      Key;
      WriteLn('  car ', HStr(KChr), '  code ', HStr(KScn), '  etat ', HStr(KSt), '  fsState ',
              HStr(RdW(LongInt(@Ki) + 4)));
    Until KChr = 27;
  End;

  Check('KbdFree', KbdFree = 0);

  DosWrite(1, LongInt(@OutBuf), OutLen, LongInt(@N));
  WriteLn;
  WriteLn('TESTKBD : ', Ok, ' reussi(s), ', Fail, ' echec(s).');
END.
